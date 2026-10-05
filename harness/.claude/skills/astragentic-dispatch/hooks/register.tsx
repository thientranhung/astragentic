// astragentic-dispatch — the dispatch steps a dispatcher kept forgetting, done by the panes
// themselves.
//
// WHY A MOD. Three steps of a dispatch had no lock and were skipped in production on the same
// day: writing the dispatch record (a guessed tab id then closed a working Builder), arming the
// watcher (a hand-rolled `while true; sleep` loop instead), and typing the slash command into
// the pane (a peer message cannot invoke a `disable-model-invocation` skill, AST-112). Every
// one was a rule in prose read hours earlier. This module removes the steps instead of
// policing them:
//
//   - A pane whose tab label is `ticket:` / `spec:` / `qa:` / `rin:` writes its own tab and
//     pane ids into `.astraler/state/dispatch-record.json` at session start. The ids come from
//     herdr's environment, never from anyone's memory.
//   - A message from the dispatcher becomes a real user turn: a first line starting with `/`
//     runs through `$.command.run` with the rest of the brief as its arguments, anything else
//     through `$.prompt.submit`. The pane answers RECEIVED at once, so the dispatcher learns
//     delivery from the receiver. The sender's `isDelivered` is true even for a message the
//     receiver HELD (measured 2026-10-05), so it proves nothing.
//   - When a turn that a dispatcher message started ends, the pane sends TURN-END with its last
//     words. The dispatcher's copy of this module consumes it and wakes the dispatcher with a
//     prompt. This replaces the herdr watcher and its Monitor: measured under one second from
//     turn end to wake, against the 67 s gap of pane-state polling (AST-097, AST-107).
//
// The dispatcher side also draws one line above the prompt with each live dispatch, adds a note
// to the next prompt when a message was sent and never confirmed, and refuses `herdr tab|pane
// close` on a pane whose turn is still running.
//
// THE TRACKER AND THE TEARDOWN, the two other steps that were remembered sometimes. A brief is
// the one moment every dispatch passes through, so two checks sit on it. A ticket the project's
// `.astraler/project/tracker-state.sh` reports unclaimed (assignee `-`, or state `closed` or
// `unclaimed`) is not sent. Neither is any brief while a Builder ticket has reached the base with
// no ticket-done stamp: the base-push guard missed `gh pr merge` and merge-and-hold, which is
// where the write-back was forgotten (AST-057, AST-074). The merge result itself carries the
// note, so the reminder lands in the same turn as the merge. `git worktree remove` on a recorded,
// clean worktree whose agent is not mid-turn runs `release-worktree-resources.sh` first, the
// step the git guard refused when it was skipped. The record entry goes once the worktree and
// the tab are gone. The git guard and git hooks stay the gate; this only removes the steps.
//
// WHAT IT DOES NOT DO. It is a bell, not proof: TURN-END says a turn ended, never that the work
// is right, so verifying by artifact stays the dispatcher's job. It cannot report a pane whose
// process died, since the module dies with it; the workspace watchdog still covers that. A
// consumed message skips the receiver's crossSessionInbound hold, so a MARK message is consumed
// only when its key and pane match the record. Anything else takes the normal, held path.

import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { BoardRow } from '../types'

const MARK = '[astragentic-dispatch]'
const PANE = 'dispatch-board'
const RECORD = '.astraler/state/dispatch-record.json'
const ACK_GRACE_MS = 90_000
const TICKET = /^[A-Z][A-Z0-9]*-[0-9]+$/
const ROLE_BY_PREFIX: Record<string, string> = { ticket: 'builder', spec: 'shaper', qa: 'qa', rin: 'rin' }

const board = atom({ plugin: 'astragentic-dispatch', key: 'board' } as const, [] as BoardRow[])

type Me = { role: string; key: string; tab: string; pane: string }
type Envelope = { from: string; fromName: string; inner: string }
type Entry = Record<string, any>

function parseEnvelope(text: string): Envelope | null {
  const m = text.match(/<cross-session-message\s+([^>]*)>\n?([\s\S]*?)\n?<\/cross-session-message>/)
  const attrs = m?.[1]
  if (attrs === undefined) return null
  const from = attrs.match(/\bfrom="([^"]*)"/)?.[1]
  if (!from) return null
  return { from, fromName: attrs.match(/\bfrom-name="([^"]*)"/)?.[1] ?? '', inner: (m?.[2] ?? '').trim() }
}

function parseMark(inner: string): { kind: string; key: string; pane: string; reason: string; body: string } | null {
  const [head = '', ...rest] = inner.split('\n')
  const m = head.match(/^\[astragentic-dispatch\] (RECEIVED|TURN-END) key=(\S+) pane=(\S+)(?: reason=(\S+))?/)
  if (!m || !m[1] || !m[2] || !m[3]) return null
  return { kind: m[1], key: m[2], pane: m[3], reason: m[4] ?? '', body: rest.join('\n').trim() }
}

function ago(ms: number): string {
  const s = Math.max(0, Math.round(ms / 1000))
  return s < 90 ? `${s}s` : s < 5400 ? `${Math.round(s / 60)}m` : `${Math.round(s / 3600)}h`
}

async function herdrJson($: any, args: string[]): Promise<any | null> {
  const bin = (await $.env.get('HERDR_BIN_PATH')) ?? 'herdr'
  try {
    const r = await $.process.run([bin, ...args], { timeoutMs: 10_000 })
    return r.exitCode === 0 ? JSON.parse(r.stdout) : null
  } catch {
    return null
  }
}

async function whoAmI($: any): Promise<Me | null> {
  const tab = await $.env.get('HERDR_TAB_ID')
  const pane = await $.env.get('HERDR_PANE_ID')
  if (!tab || !pane) return null
  const got = await herdrJson($, ['tab', 'get', tab])
  const m = String(got?.result?.tab?.label ?? '').match(/^(ticket|spec|qa|rin):(.+)$/)
  const role = ROLE_BY_PREFIX[m?.[1] ?? '']
  const key = m?.[2]
  return role && key ? { role, key, tab, pane } : null
}

async function repoRoot($: any): Promise<string | null> {
  try {
    const r = await $.process.run(['git', 'rev-parse', '--path-format=absolute', '--git-common-dir'], { timeoutMs: 10_000 })
    return r.exitCode === 0 ? r.stdout.trim().replace(/\/\.git\/?$/, '') : null
  } catch {
    return null
  }
}

// Missing is an empty record; unreadable JSON is null, and null is never written over.
async function readRecord($: any, root: string): Promise<Record<string, Entry> | null> {
  let text: string
  try {
    text = await $.fs.read(`${root}/${RECORD}`)
  } catch {
    return {}
  }
  try {
    const parsed = JSON.parse(text)
    return parsed && typeof parsed === 'object' ? parsed : null
  } catch {
    return null
  }
}

async function patchRecord($: any, root: string, key: string, patch: Entry): Promise<boolean> {
  const rec = await readRecord($, root)
  if (rec === null) {
    $.ui.status(`astragentic-dispatch: ${RECORD} is not valid JSON; not written`)
    return false
  }
  rec[key] = { ...(rec[key] ?? {}), ...patch }
  await $.fs.write(`${root}/${RECORD}`, JSON.stringify(rec, null, 2) + '\n')
  return true
}

async function deleteRecordKey($: any, root: string, key: string): Promise<void> {
  const rec = await readRecord($, root)
  if (rec === null || !(key in rec)) return
  delete rec[key]
  await $.fs.write(`${root}/${RECORD}`, JSON.stringify(rec, null, 2) + '\n')
}

async function run($: any, argv: string[], timeoutMs = 10_000): Promise<{ code: number; out: string }> {
  try {
    const r = await $.process.run(argv, { timeoutMs })
    return { code: r.exitCode, out: `${r.stdout}${r.stderr}`.trim() }
  } catch (err) {
    return { code: -1, out: String(err) }
  }
}

async function exists($: any, path: string): Promise<boolean> {
  return (await run($, ['test', '-e', path])).code === 0
}

async function realpath($: any, path: string): Promise<string> {
  const r = await run($, ['realpath', path])
  return r.code === 0 ? r.out : path
}

// The project's answer to "what does the tracker say about <id>": one line, `<state>
// <assignee-or-dash>`, the same plug ticket-done.sh asks. null is an empty socket.
async function trackerState($: any, root: string, id: string): Promise<{ state: string; assignee: string; line: string } | null> {
  const plug = `${root}/.astraler/project/tracker-state.sh`
  if (!(await exists($, plug))) return null
  const r = await run($, [plug, id], 30_000)
  const line = (r.out.split('\n')[0] ?? '').trim()
  const [state = '', assignee = ''] = line.split(/\s+/)
  // A plug that fails, prints nothing, or says the tracker is `unreachable` (ADAPT-HARNESS
  // tells a project with no shell route to print that) cannot answer, and a check that cannot
  // answer must not refuse every brief: it is treated as the empty socket.
  if (r.code !== 0 || !state || /^unreachable$/i.test(state)) return null
  return { state, assignee, line }
}

async function stampRoot($: any): Promise<string> {
  return (await $.env.get('HARNESS_STAMP_ROOT')) ?? '/tmp'
}

async function baseBranch($: any, root: string): Promise<string> {
  const pinned = await $.env.get('BASE_BRANCH')
  if (pinned) return pinned
  const r = await run($, ['git', '-C', root, 'symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD'])
  return r.code === 0 && r.out.includes('/') ? r.out.slice(r.out.indexOf('/') + 1) : 'main'
}

// A Builder ticket whose work reached the base and has no ticket-done stamp: the tracker
// write-back is owed. Merged is either seen locally (branch tip is an ancestor of the base) or
// recorded when the mod watched a merge command succeed (a `gh pr merge` lands remotely).
async function owedTickets($: any, root: string): Promise<string[]> {
  const rec = (await readRecord($, root)) ?? {}
  const base = await baseBranch($, root)
  const stamps = `${await stampRoot($)}/harness-ticket-done`
  const owed: string[] = []
  for (const [key, entry] of Object.entries(rec)) {
    if (entry?.role !== 'builder' || !TICKET.test(key)) continue
    if (await exists($, `${stamps}/${key}`)) continue
    let isMerged = Boolean(entry.merged_at)
    if (!isMerged && typeof entry.branch === 'string' && entry.last_turn_end_at) {
      // A branch with no commit of its own is an ancestor of the base too. Measured: the board
      // read "merged" for a Builder that had committed nothing, so work must exist first.
      const tip = await run($, ['git', '-C', root, 'rev-parse', '--verify', '--quiet', `refs/heads/${entry.branch}`])
      isMerged = tip.code === 0 && tip.out !== entry.start_sha &&
        (await run($, ['git', '-C', root, 'merge-base', '--is-ancestor', entry.branch, base])).code === 0
    }
    if (isMerged) owed.push(key)
  }
  return owed
}

function owedText(owed: string[]): string {
  return `${owed.join(', ')} reached the base but ${owed.length > 1 ? 'have' : 'has'} no ticket-done evidence. ` +
    `Owed now: set the tracker to closed and release the assignee (docs/agents/issue-tracker.md), ` +
    `then \`scripts/ticket-done.sh <id> --moved "<ids promoted, or none>"\`.`
}

function isLive(entry: Entry): boolean {
  return typeof entry?.pane_id === 'string'
}

function isMidTurn(entry: Entry): boolean {
  const got = entry.last_brief_received_at ?? 0
  return got > 0 && got > (entry.last_turn_end_at ?? 0)
}

async function refreshBoard($: any, root: string | null, sends: Map<string, number>) {
  const now = await $.clock.now()
  const rec = root ? ((await readRecord($, root)) ?? {}) : {}
  const rows: BoardRow[] = []
  const named = new Set<string>()
  const owed = root ? await owedTickets($, root) : []
  for (const [key, entry] of Object.entries(rec)) {
    if (!isLive(entry)) continue
    if (entry.session_name) named.add(entry.session_name)
    const sentAt = entry.session_name ? sends.get(entry.session_name) : undefined
    const role = entry.role ?? 'agent'
    if (owed.includes(key)) {
      rows.push({ key, role, state: 'merged', since: entry.merged_at ?? entry.last_turn_end_at ?? now, note: 'tracker not closed' })
    } else if (sentAt !== undefined) {
      const isLate = now - sentAt > ACK_GRACE_MS
      rows.push({ key, role, state: 'sent', since: sentAt, note: isLate ? 'not confirmed received' : undefined })
    } else if (isMidTurn(entry)) {
      rows.push({ key, role, state: 'working', since: entry.last_brief_received_at })
    } else if (entry.last_turn_end_at) {
      rows.push({ key, role, state: 'ended', since: entry.last_turn_end_at, note: entry.last_turn_reason })
    } else {
      rows.push({ key, role, state: 'registered', since: entry.registered_at ?? now, note: 'no brief yet' })
    }
  }
  for (const [name, sentAt] of sends) {
    if (named.has(name)) continue
    const isLate = now - sentAt > ACK_GRACE_MS
    rows.push({ key: name, role: '?', state: 'sent', since: sentAt, note: isLate ? 'not confirmed received' : undefined })
  }
  await update($, board, () => rows)
}

function boardLine(rows: BoardRow[], now: number): string {
  return rows
    .map(r => `${r.key} ${r.state} ${ago(now - r.since)}${r.note ? ` (${r.note})` : ''}`)
    .join(' · ')
}

export const register: Register = on => {
  let me: Me | null = null
  let root: string | null = null
  let dispatcher: string | null = null
  let isBusy = false
  let isNoticeTurn = false
  const sends = new Map<string, number>()

  on('session.start', async ($, e, next) => {
    root = await repoRoot($)
    me = await whoAmI($)
    if (me && root) {
      // session.start fires again on every reload and resume. The start commit is kept from the
      // first registration: rewritten at a reload after the Builder committed, it equalled the
      // tip and hid the merge (measured).
      const prior = ((await readRecord($, root)) ?? {})[me.key] ?? {}
      const branch = (await run($, ['git', 'rev-parse', '--abbrev-ref', 'HEAD'])).out
      const isSameDispatch = prior.branch === branch && typeof prior.start_sha === 'string'
      await patchRecord($, root, me.key, {
        role: me.role,
        tab_id: me.tab,
        pane_id: me.pane,
        session_id: await $.session.id(),
        worktree: e.cwd,
        branch,
        start_sha: isSameDispatch ? prior.start_sha : (await run($, ['git', 'rev-parse', 'HEAD'])).out,
        registered_at: isSameDispatch && prior.registered_at ? prior.registered_at : await $.clock.now(),
      })
      $.ui.status(`dispatched ${me.role} ${me.key} — recorded tab ${me.tab}, pane ${me.pane}`)
    } else if (root) {
      await $.command.register({ name: 'dispatch-board', description: 'Show live dispatches in a pane' })
      await refreshBoard($, root, sends)
      $.clock.every(30_000, () => refreshBoard($, root, sends))
    }
    return next(e)
  })

  on('turn.start', ($, e, next) => {
    isBusy = true
    return next(e)
  })

  // ---- dispatched side -------------------------------------------------------------------

  on('session.receive', async ($, e, next) => {
    const env = parseEnvelope(e.text)
    if (!env || e.agentId !== undefined) return next(e)

    if (!me) {
      // dispatcher side: consume only MARK messages that match the record
      const mark = parseMark(env.inner)
      if (!mark || !root) return next(e)
      const rec = (await readRecord($, root)) ?? {}
      if (rec[mark.key]?.pane_id !== mark.pane) return next(e)
      sends.delete(env.fromName)
      if (mark.kind === 'RECEIVED') {
        await patchRecord($, root, mark.key, { session_name: env.fromName, acked_at: await $.clock.now() })
        await refreshBoard($, root, sends)
        return { consumed: `astragentic-dispatch: ${mark.key} confirmed receipt` }
      }
      await refreshBoard($, root, sends)
      const role = rec[mark.key]?.role ?? 'agent'
      void $.prompt.submit({
        text: `${MARK} ${role} ${mark.key} ended its turn (${mark.reason}). A bell, not proof: verify by artifact before acting.\n\nIts last words:\n${mark.body}`,
      })
      return { consumed: `astragentic-dispatch: ${mark.key} turn end handed to the dispatcher` }
    }

    if (env.inner.startsWith(MARK)) return next(e)
    dispatcher = env.from
    const now = await $.clock.now()
    if (root) await patchRecord($, root, me.key, { dispatcher: env.from, dispatcher_name: env.fromName, last_brief_received_at: now })
    await $.session.send({ to: env.from, text: `${MARK} RECEIVED key=${me.key} pane=${me.pane}` })

    // Mid-turn steering goes the normal way so the running turn can read it.
    if (isBusy) return next(e)

    const [first = '', ...rest] = env.inner.split('\n')
    if (first.startsWith('/')) {
      const [command, ...words] = first.slice(1).trim().split(/\s+/)
      const args = [words.join(' '), rest.join('\n').trim()].filter(Boolean).join('\n\n')
      const key = me.key
      const pane = me.pane
      const to = env.from
      $.command.run({ command, args } as any).catch((err: unknown) =>
        $.session.send({ to, text: `${MARK} TURN-END key=${key} pane=${pane} reason=command-failed\n/${command}: ${String(err)}` }),
      )
    } else {
      void $.prompt.submit({ text: env.inner })
    }
    return { consumed: `astragentic-dispatch: dispatcher message run as a user turn` }
  })

  on('turn.complete', async ($, e, next) => {
    const res = await next(e)
    if (e.agentId !== undefined) return res
    isBusy = false
    if (!me) {
      if (root) await refreshBoard($, root, sends)
      return res
    }
    // Every turn after the first brief is reported, so a Builder that backgrounds its work and
    // finishes it in a later turn (measured: the result came one turn after the "done") is
    // still heard. Turns that only read a cross-session delivery notice are skipped; reporting
    // those woke the dispatcher three times for one task.
    const isSkipped = isNoticeTurn
    isNoticeTurn = false
    if (!dispatcher || isSkipped) return res
    if (root) await patchRecord($, root, me.key, { last_turn_end_at: await $.clock.now(), last_turn_reason: e.reason })
    const answer = e.answer.length > 1500 ? `…${e.answer.slice(-1500)}` : e.answer
    const sent = await $.session.send({ to: dispatcher, text: `${MARK} TURN-END key=${me.key} pane=${me.pane} reason=${e.reason}\n${answer}` })
    if (!sent.isDelivered) $.ui.status(`astragentic-dispatch: TURN-END not delivered — ${sent.reason}`)
    return res
  })

  // ---- dispatcher side -------------------------------------------------------------------

  on('session.send', async ($, e, next) => {
    // A brief is a send whose first line is a slash command. Two things are checked at the one
    // moment every dispatch passes through, because both were skipped when they were prose:
    // the previous merge's tracker write-back, and this ticket's claim.
    const first = e.text.trimStart().split('\n')[0] ?? ''
    if (!me && root && e.origin.kind === 'model' && e.agentId === undefined && first.startsWith('/')) {
      const owed = await owedTickets($, root)
      if (owed.length > 0) {
        return { isDelivered: false, reason: `${MARK} not sent. ${owedText(owed)} Then send this brief again.` }
      }
      const id = first.split(/\s+/).slice(1).find(word => TICKET.test(word))
      const ts = id ? await trackerState($, root, id) : null
      if (id && ts && (ts.assignee === '-' || ts.assignee === '' || /^(closed|unclaimed)$/i.test(ts.state))) {
        return {
          isDelivered: false,
          reason: `${MARK} not sent. The tracker says ${id} is "${ts.line}", so it is not claimed. ` +
            `Claim it first (thomas.md § The claim protocol: assignee written and read back; status or label per ` +
            `docs/agents/issue-tracker.md), then send this brief again.`,
        }
      }
    }
    const res = await next(e)
    if (me || !root || e.origin.kind !== 'model' || e.agentId !== undefined || !res.isDelivered) return res
    const rec = (await readRecord($, root)) ?? {}
    const isKnown = Object.values(rec).some(entry => entry?.session_name === e.to)
    if (isKnown || e.text.trimStart().startsWith('/')) {
      sends.set(e.to, await $.clock.now())
      await refreshBoard($, root, sends)
    }
    return res
  })

  on('prompt.submit', async ($, e, next) => {
    if (me) {
      isNoticeTurn = e.text.startsWith('[Cross-session delivery notice]')
      return next(e)
    }
    if (!root) return next(e)
    await refreshBoard($, root, sends)
    const notes: string[] = []
    const late = (await read($, board)).filter(r => r.note === 'not confirmed received')
    if (late.length > 0) {
      notes.push(`${MARK} No RECEIVED came back for: ${late.map(r => r.key).join(', ')}. The message may be held or lost; read that pane before assuming it is working.`)
    }
    const owed = await owedTickets($, root)
    if (owed.length > 0) notes.push(`${MARK} ${owedText(owed)}`)
    if (notes.length === 0) return next(e)
    return next({ ...e, context: [...(e.context ?? []), ...notes] })
  })

  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    if (me || !root) return next(e)
    const rec = (await readRecord($, root)) ?? {}

    // -- closing a pane, tab or workspace that holds a mid-turn agent ---------------------
    const close = e.command.match(/\bherdr\s+(tab|pane|workspace)\s+close\s+['"]?([A-Za-z0-9:_-]+)/)
    if (close) {
      const [, kind, id] = close
      const hit = Object.entries(rec).find(([, entry]) =>
        isLive(entry) && isMidTurn(entry) &&
        (kind === 'tab' ? entry.tab_id === id : kind === 'pane' ? entry.pane_id === id : String(entry.tab_id).startsWith(`${id}:`)),
      )
      if (hit) {
        const [key, entry] = hit
        return {
          deny: `astragentic-dispatch: ${entry.role} ${key} is mid-turn in ${kind} ${id} (brief received, no TURN-END since). Closing it kills a working agent. Wait for its TURN-END, or ask the owner.`,
        }
      }
      const ran = await next(e)
      if (ran.deny === undefined && !ran.isError && kind === 'tab') {
        for (const [key, entry] of Object.entries(rec)) {
          if (entry?.tab_id !== id) continue
          if (entry.worktree && (await exists($, entry.worktree))) await patchRecord($, root, key, { tab_closed_at: await $.clock.now() })
          else await deleteRecordKey($, root, key)
        }
        await refreshBoard($, root, sends)
      }
      return ran
    }

    // -- removing a worktree: release its resources first, then let the guard judge ---------
    // The release used to be a step Thomas ran by hand before `git worktree remove`, and the
    // git guard refused the removal when it was skipped (AST-100, AST-101; the WorktreeRemove
    // hook never fired, AST-102). Here it runs at the moment of removal. It only runs for a
    // recorded worktree whose agent is not mid-turn and whose tree is clean, because the
    // release reaps processes and runs the project's teardown: doing that to a worktree the
    // guard is about to refuse for uncommitted work would tear down live state (AST-115).
    const remove = e.command.match(/\bgit\s+(?:-C\s+\S+\s+)?worktree\s+remove\s+((?:-f\s+|--force\s+)*)['"]?([^\s'"]+)/)
    if (remove) {
      const isForced = Boolean(remove[1])
      const target = await realpath($, remove[2] ?? '')
      const hit = Object.entries(rec).find(([, entry]) => typeof entry?.worktree === 'string' && entry.worktree === target)
      if (hit && (await exists($, target))) {
        const [key, entry] = hit
        if (isMidTurn(entry)) {
          return { deny: `astragentic-dispatch: ${entry.role} ${key} is mid-turn in ${target}. Removing its worktree destroys work in progress. Wait for its TURN-END.` }
        }
        const isClean = isForced || (await run($, ['git', '-C', target, 'status', '--short'])).out === ''
        if (isClean) {
          const script = (await exists($, `${root}/scripts/release-worktree-resources.sh`))
            ? `${root}/scripts/release-worktree-resources.sh`
            : `${root}/harness/scripts/release-worktree-resources.sh`
          const released = await run($, ['bash', script, target], 600_000)
          if (released.code !== 0) {
            return {
              deny: `astragentic-dispatch: releasing ${target} failed, so it was not removed:\n${released.out.split('\n').slice(-15).join('\n')}`,
            }
          }
        }
      }
      const ran = await next(e)
      if (hit && ran.deny === undefined && !ran.isError && !(await exists($, target))) {
        const [key, entry] = hit
        // The release reaps the agent rooted in the worktree, and herdr closes a tab whose last
        // pane exited, so the tab is usually gone before anyone closes it (measured). Ask herdr.
        const isTabAlive = Boolean(entry.tab_id) && !entry.tab_closed_at && (await herdrJson($, ['tab', 'get', entry.tab_id])) !== null
        if (!isTabAlive) await deleteRecordKey($, root, key)
        else await patchRecord($, root, key, { worktree_removed_at: await $.clock.now() })
        await refreshBoard($, root, sends)
      }
      return ran
    }

    // -- a merge: the tracker write-back is owed from this moment, so say so in the result -----
    const merge = /\bgit\s+(?:-C\s+\S+\s+)?merge\b|\bgh\s+pr\s+merge\b/.test(e.command)
    const ran = await next(e)
    if (!merge || ran.deny !== undefined || ran.isError) return ran
    if (/\bgh\s+pr\s+merge\b/.test(e.command)) {
      // A PR merged on the remote never reaches the local base, so ancestry cannot see it.
      // Mark the entries the command names, by ticket id or by the PR's head branch.
      const pr = e.command.match(/\bgh\s+pr\s+merge\s+(\S+)/)?.[1]
      const head = pr && !pr.startsWith('-')
        ? (await run($, ['gh', 'pr', 'view', pr, '--json', 'headRefName', '-q', '.headRefName'], 30_000)).out
        : ''
      for (const [key, entry] of Object.entries(rec)) {
        if (e.command.includes(key) || (head && entry?.branch === head)) {
          await patchRecord($, root, key, { merged_at: await $.clock.now() })
        }
      }
    }
    const owed = await owedTickets($, root)
    await refreshBoard($, root, sends)
    if (owed.length === 0) return ran
    return { ...ran, context: [...(ran.context ?? []), `${MARK} ${owedText(owed)} The next brief will not be sent until this is done.`] }
  })

  on('command.run', { command: 'dispatch-board' }, async $ => {
    await refreshBoard($, root, sends)
    await $.ui.open({ id: PANE, title: 'Dispatches' })
    return { text: 'Dispatch board opened.' }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const rows = await read($, board)
    const now = await $.clock.now()
    return (
      <Box flexDirection="column">
        {rows.length === 0 && <Text dimColor>No live dispatches.</Text>}
        {rows.map(r => (
          <Text color={r.note === 'not confirmed received' || r.state === 'merged' ? 'red' : undefined}>
            {r.key.padEnd(14)} {r.role.padEnd(8)} {r.state.padEnd(10)} {ago(now - r.since).padStart(4)} {r.note ?? ''}
          </Text>
        ))}
      </Box>
    )
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (me) return next(e)
    const rows = await read($, board)
    if (rows.length === 0 || e.props.hasSurvey) return next(e)
    const { Text } = $.ui.resolve(e)
    const isAlarm = rows.some(r => r.note === 'not confirmed received' || r.state === 'merged')
    return (
      <Text dimColor={!isAlarm} color={isAlarm ? 'red' : undefined}>
        dispatch: {boardLine(rows, await $.clock.now())}
      </Text>
    )
  })
}
