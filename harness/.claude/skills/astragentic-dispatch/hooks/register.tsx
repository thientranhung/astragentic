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

import type { BoardRow, Banner, Flow } from '../types'

const MARK = '[astragentic-dispatch]'

// The Builder flow, as the skill names the engine reports at `skill.prompt`. Measured
// 2026-10-09 on Claude Code 2.1.294: a plugin skill arrives qualified (`mattpocock-skills:tdd`),
// a built-in bare (`code-review`), so the two reviews that share a word are told apart here
// where the brief's prose could not (AST-050). The record is the pane's own observation of the
// call, which a commit message cannot forge the way a `Pass:` line can (AST-055, AST-130).
const FLOW: ReadonlyArray<readonly [string, string]> = [
  ['mattpocock-skills:tdd', 'tdd'],
  ['mattpocock-skills:code-review', "Matt's code-review"],
  ['code-review', 'built-in code-review'],
  ['simplify', 'simplify'],
]

// A record is a file anyone can edit; a `skills_run` that is not an object must read as empty,
// not throw (a throwing gate is a skipped gate).
function skillsRun(entry: Entry): Record<string, unknown> {
  const run = entry?.skills_run
  return run && typeof run === 'object' && !Array.isArray(run) ? run : {}
}

function flowGaps(entry: Entry): string[] {
  const run = skillsRun(entry)
  return FLOW.filter(([name]) => !(name in run)).map(([, label]) => label)
}
const PANE = 'dispatch-board'
const RECORD = '.astraler/state/dispatch-record.json'

// The project's own rules live outside the payload, so a release never overwrites them.
// `overlays/<role>.md` joins the role's system prompt at every render (measured 2026-10-09 on
// 2.1.294: a `prompt.compose` section added here was read on the first turn), and
// `overlays/dispatch-brief.md` joins every brief this mod sends. Measured downstream before this
// existed: 64 payload files edited in place and re-applied after every upgrade.
const OVERLAYS = '.astraler/project/overlays'

async function overlayFile($: any, path: string): Promise<string> {
  try {
    return (await $.fs.read(path)).trim()
  } catch {
    return ''
  }
}

function overlay($: any, root: string, name: string): Promise<string> {
  return overlayFile($, `${root}/${OVERLAYS}/${name}.md`)
}
const ACK_GRACE_MS = 90_000
const TICKET = /^[A-Z][A-Z0-9]*-[0-9]+$/
// `resident:` is a long-lived pane the owner keeps (a deploy agent, a design partner): it gets
// no brief and reports no turn end, but it is recorded, shown on the board and protected from
// a close like any dispatched pane. Measured downstream: resident panes were invisible to the
// board and the one place a wrong close could not be refused.
const ROLE_BY_PREFIX: Record<string, string> = { ticket: 'builder', spec: 'shaper', qa: 'qa', rin: 'rin', resident: 'resident' }

const board = atom({ plugin: 'astragentic-dispatch', key: 'board' } as const, [] as BoardRow[])
// The always-on band: branch and worktree of the dispatcher's checkout, plus one line the
// project composes (`.astraler/project/status-line.sh`: tracker counts, who holds the gate
// token, whatever it measured it needed on screen). Measured downstream: the tracker table was
// injected into context at session start and never shown, and two gate runs collided while
// nobody could see who held the token.
const banner = atom({ plugin: 'astragentic-dispatch', key: 'banner' } as const, { branch: '', extra: '' } as Banner)
// The Builder pane's own band: which FLOW steps have run, read from the same record the gates
// read, so the person watching the pane sees the step the Builder is at without reading the
// transcript (owner's ask, 2026-10-09).
const flow = atom({ plugin: 'astragentic-dispatch', key: 'flow' } as const, { ran: [], tddNa: false, reviewNa: false } as Flow)

const FLOW_STEPS: ReadonlyArray<readonly [string, string]> = [
  ['mattpocock-skills:implement', 'implement'],
  ['mattpocock-skills:tdd', 'tdd'],
  ['mattpocock-skills:code-review', 'review:matt'],
  ['code-review', 'review:built-in'],
  ['simplify', 'simplify'],
  ['codex-arm', 'arm'],
]

async function refreshFlow($: any, root: string, key: string): Promise<void> {
  const entry = ((await readRecord($, root)) ?? {})[key] ?? {}
  await update($, flow, () => ({ ran: Object.keys(entry.skills_run ?? {}), tddNa: Boolean(entry.tdd_na), reviewNa: Boolean(entry.review_na) }))
}

// Minimal shell reading for the gates: split on unquoted command separators, then tokens with
// quotes honoured. No expansion, no heredoc bodies dropped — a heredoc fed to `bash` is a
// command that runs, so its body is read like any other line (the 2.21.0 gate found the
// heredoc-stripping reader let `bash <<'EOF' … git commit … EOF` through).
function shellWords(segment: string): string[] {
  const out: string[] = []
  let cur = ''
  let q: string | null = null
  let has = false
  for (const ch of segment) {
    if (q) {
      if (ch === q) q = null
      else cur += ch
      continue
    }
    if (ch === '"' || ch === "'") { q = ch; has = true; continue }
    if (/\s/.test(ch)) {
      if (has) { out.push(cur); cur = ''; has = false }
      continue
    }
    cur += ch; has = true
  }
  if (has) out.push(cur)
  return out
}

function simpleCommands(command: string): string[] {
  const parts: string[] = []
  let cur = ''
  let q: string | null = null
  for (let i = 0; i < command.length; i++) {
    const ch = command[i] ?? ''
    if (q) { cur += ch; if (ch === q) q = null; continue }
    if (ch === '"' || ch === "'") { q = ch; cur += ch; continue }
    if (ch === '\n' || ch === ';' || ch === '&' || ch === '|' || ch === '(' || ch === ')' || ch === '`') {
      if (cur.trim()) parts.push(cur.trim())
      cur = ''
      continue
    }
    if (ch === '$' && command[i + 1] === '(') { if (cur.trim()) parts.push(cur.trim()); cur = ''; i++; continue }
    cur += ch
  }
  if (cur.trim()) parts.push(cur.trim())
  return parts
}

// A `git … commit` simple command, with `-c k=v`, `-C <dir>` and other leading options
// skipped; returns the words after `commit`, or null.
function gitCommitArgs(segment: string): string[] | null {
  const w = shellWords(segment)
  let i = w.findIndex(t => t === 'git' || t.endsWith('/git'))
  if (i < 0) return null
  i++
  while (i < w.length) {
    const t = w[i] ?? ''
    if (t === '-c' || t === '-C' || t === '--git-dir' || t === '--work-tree' || t === '--namespace') { i += 2; continue }
    if (t.startsWith('-')) { i++; continue }
    break
  }
  return w[i] === 'commit' ? w.slice(i + 1) : null
}

function printable(text: string, max = 300): string {
  return text.replace(/\x1b\[[0-9;?]*[ -\/]*[@-~]/g, '').replace(/[\x00-\x09\x0b-\x1f\x7f]/g, '').trim().slice(0, max)
}

function flowLine(f: Flow): string {
  return FLOW_STEPS.map(([name, label]) => {
    const isRan = f.ran.includes(name) || (name === 'codex-arm' && f.ran.includes('codex-claude-arm'))
    const isNa = (name === 'mattpocock-skills:tdd' && f.tddNa) || (name === 'code-review' && f.reviewNa)
    return `${isRan ? '✓' : isNa ? 'n/a' : '○'} ${label}`
  }).join(' · ')
}

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
  const m = String(got?.result?.tab?.label ?? '').match(/^(ticket|spec|qa|rin|resident):(.+)$/)
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
  const pinned = await $.env.get('HARNESS_STAMP_ROOT')
  if (pinned) return pinned
  // Same home as ticket-done.sh writes: the git common dir, which survives a reboot.
  const r = await run($, ['git', 'rev-parse', '--path-format=absolute', '--git-common-dir'])
  return r.code === 0 && r.out ? `${r.out}/astraler-stamps` : '/tmp'
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

// The payload paths are the files of the release this checkout applied. `git status` runs
// without pathspecs because a pathspec through a symlinked skill directory is refused outright,
// and with --no-renames because a rename prints `old -> new`, which matches no path: a moved
// contract file would read as clean (found by the reviewer; check-visual-evidence downstream
// paid for the same root cause).
//
// FAILS OPEN, deliberately. No readable applied-version, no release tree, a git error or a
// 15 s timeout all return [], and the brief goes. Blocking every dispatch on a transient git
// failure is worse than missing one dirty file. That makes this a lint, not a boundary, in the
// sense this package already uses for hook-git-guard: it catches accidental misuse and promises
// nothing when it cannot read. The watchdog's work-in-flight call fails the other way on
// purpose, because there a wrong answer mutes alerts.
async function dirtyPayload($: any, root: string): Promise<string[]> {
  let applied = ''
  try {
    applied = (await $.fs.read(`${root}/.astraler/state/applied-version`)).trim()
  } catch {
    return []
  }
  const rel = `${root}/.astraler/releases/${applied}/harness`
  const listed = await run($, ['find', rel, '-type', 'f', '!', '-name', '.DS_Store'])
  if (!applied || listed.code !== 0) return []
  const payload = new Set(listed.out.split('\n').filter(Boolean).map(p => p.slice(rel.length + 1)))
  // Not through run(): it trims, and the first porcelain line starts with a status space.
  let out = ''
  try {
    const r = await $.process.run(['git', '-C', root, 'status', '--porcelain', '--untracked-files=all', '--no-renames'], { timeoutMs: 15_000 })
    if (r.exitCode !== 0) return []
    out = r.stdout
  } catch {
    return []
  }
  return out.split('\n')
    .map(line => ({ code: line.slice(0, 2), path: line.slice(3).replace(/^"|"$/g, '') }))
    .filter(entry => payload.has(entry.path))
    .map(entry => `${entry.code} ${entry.path}`)
}

// The part of a Bash command that runs. Heredoc bodies are text, not commands: writing a
// ledger entry that quotes `git worktree remove $(pwd)/$W` was refused as if it were that
// removal (measured downstream, while writing up the very incident). Bodies are dropped, and
// each rule below matches a command only where a command can start: the beginning of a line or
// after ; & | ( — never inside a quoted sentence. The failure direction of each rule is unchanged.
function runnable(command: string): string {
  const lines = command.split('\n')
  const out: string[] = []
  let until: { word: string; isTabbed: boolean } | null = null
  for (const line of lines) {
    if (until) {
      const probe = until.isTabbed ? line.replace(/^\t+/, '') : line
      if (probe === until.word) until = null
      continue
    }
    out.push(line)
    const m = line.match(/<<(-?)\s*(['"]?)([A-Za-z_][A-Za-z0-9_]*)\2/)
    if (m && m[3]) until = { word: m[3], isTabbed: m[1] === '-' }
  }
  return out.join('\n')
}

const AT_COMMAND = String.raw`(?:^|[\n;&|(])\s*`

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
    let sentAt = entry.session_name ? sends.get(entry.session_name) : undefined
    // The record outranks this process's memory. A pane can answer RECEIVED within tens of
    // milliseconds (34 ms measured), before the send hook has noted the send, so the note lands
    // after the ack that should have cleared it and stays forever: the live dispatch read "No
    // RECEIVED" while the record held the ack. An ack recorded at or just before the send
    // settles it; the window only absorbs that race.
    if (sentAt !== undefined && typeof entry.acked_at === 'number' && entry.acked_at >= sentAt - 10_000) {
      sends.delete(entry.session_name)
      sentAt = undefined
    }
    const role = entry.role ?? 'agent'
    if (role === 'resident') {
      rows.push({ key, role, state: 'registered', since: entry.registered_at ?? now, note: 'resident' })
      continue
    }
    if (entry.turn_end_pending) {
      rows.push({ key, role, state: 'ended', since: entry.turn_end_pending.at ?? now, note: 'turn end read from record: its message was blocked, check that pane mode' })
      continue
    }
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
  if (root) {
    const branch = (await run($, ['git', '-C', root, 'rev-parse', '--abbrev-ref', 'HEAD'])).out
    let extra = ''
    const plug = `${root}/.astraler/project/status-line.sh`
    if (await exists($, plug)) {
      try {
        const r = await $.process.run(['bash', plug], { cwd: root, timeoutMs: 5_000 })
        // One line, printable only: a plug that colours its output or rewrites the line with
        // carriage returns would otherwise paint the band.
        const raw = r.exitCode === 0 ? String(r.stdout ?? '').split('\n')[0] ?? '' : 'status-line.sh failed'
        extra = raw.replace(/\x1b\[[0-9;?]*[ -\/]*[@-~]/g, '').replace(/[\x00-\x1f\x7f]/g, '').trim().slice(0, 160)
      } catch {
        extra = 'status-line.sh failed'
      }
    }
    await update($, banner, () => ({ branch, extra }))
  }
}

// The second delivery path for a turn end (see turn.complete on the dispatched side): an entry
// whose pane could not send its TURN-END has it in the record, and the dispatcher's own mod
// submits the same prompt from there, once. Measured latency bound: the 30 s poll.
async function wakeFromRecord($: any, root: string): Promise<void> {
  const rec = (await readRecord($, root)) ?? {}
  for (const [key, entry] of Object.entries(rec)) {
    const pending = entry?.turn_end_pending
    if (!pending || pending.woken_at) continue
    const mark = parseMark(String(pending.text ?? ''))
    await patchRecord($, root, key, { turn_end_pending: { ...pending, woken_at: await $.clock.now() } })
    const role = entry.role ?? 'agent'
    void $.prompt.submit({
      text: `${MARK} ${role} ${key} ended its turn (${mark?.reason ?? 'unknown'}) — read from the record: its TURN-END message was not delivered (${pending.reason}). A bell, not proof: verify by artifact before acting.\n\nIts last words:\n${mark?.body ?? ''}`,
    })
  }
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
  // The dispatched pane's own red line: set when a TURN-END send fails, cleared by the next
  // one that lands. The footer status alone was missed for ten minutes (measured downstream).
  let undelivered = ''
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
      await refreshFlow($, root, me.key)
    } else if (root) {
      await $.command.register({ name: 'dispatch-board', description: 'Show live dispatches in a pane' })
      await refreshBoard($, root, sends)
      const at = root
      $.clock.every(30_000, async () => {
        await refreshBoard($, at, sends)
        await wakeFromRecord($, at)
      })
    }
    return next(e)
  })

  on('turn.start', ($, e, next) => {
    isBusy = true
    return next(e)
  })

  // A dispatched pane reads its role's overlay; any other Claude session in the repo is the
  // dispatcher's and reads `thomas.md`. The section is `session`-scoped: after the cache
  // boundary, so a project's text never breaks the shared prefix.
  on('prompt.compose', async ($, e, next) => {
    const res = await next(e)
    if (!root) return res
    const text = await overlay($, root, me?.role ?? 'thomas')
    if (!text) return res
    return { sections: [...res.sections, { id: 'astragentic-dispatch:overlay', text, scope: 'session' as const }] }
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
      if (rec[mark.key]?.turn_end_pending) await patchRecord($, root, mark.key, { turn_end_pending: null })
      const role = rec[mark.key]?.role ?? 'agent'
      void $.prompt.submit({
        text: `${MARK} ${role} ${mark.key} ended its turn (${mark.reason}). A bell, not proof: verify by artifact before acting.\n\nIts last words:\n${mark.body}`,
      })
      return { consumed: `astragentic-dispatch: ${mark.key} turn end handed to the dispatcher` }
    }

    if (env.inner.startsWith(MARK)) return next(e)
    dispatcher = env.from
    const now = await $.clock.now()
    // The dispatcher's declared exemptions ride in the brief, so the gates below read them from
    // the one text the mod knows is the brief: `TDD: n/a — <why>` and `REVIEW: n/a — <why>`.
    // Only a BRIEF (first line a slash command) carries exemptions; a steering message never
    // touches them (the 2.21.0 gate found a follow-up clearing a valid exemption). Fenced blocks
    // are dropped first so a quoted example does not grant one.
    const isBriefText = env.inner.trimStart().startsWith('/')
    const unfenced = env.inner.replace(/```[\s\S]*?```/g, '')
    const tddNa = isBriefText ? unfenced.match(/^[ \t]*TDD[ \t]*:[ \t]*n\/a\b[^\n]*/im)?.[0]?.trim() ?? null : undefined
    const reviewNa = isBriefText ? unfenced.match(/^[ \t]*REVIEW[ \t]*:[ \t]*n\/a\b[^\n]*/im)?.[0]?.trim() ?? null : undefined
    if (root) {
      const patch: Entry = { dispatcher: env.from, dispatcher_name: env.fromName, last_brief_received_at: now }
      if (isBriefText) { patch.tdd_na = tddNa; patch.review_na = reviewNa }
      await patchRecord($, root, me.key, patch)
      await refreshFlow($, root, me.key)
    }
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

  // A Builder's skill calls are recorded as the engine expands them, so the flow the brief
  // names (tdd → both reviews → simplify) is read from what ran, not from what the handback
  // says ran. Measured downstream before this existed: implement 44/44, tdd 0/44. A fork's
  // call is recorded under the Builder too, which is the same attribution git gives it.
  // Writes are chained: two skills expanding in one turn (a fork's beside the Builder's) would
  // otherwise read the same map and the second write would erase the first (found by the
  // 2.18.0 gate).
  let skillWrites: Promise<void> = Promise.resolve()
  on('skill.prompt', async ($, e, next) => {
    if (me?.role === 'builder' && root) {
      const { key } = me
      const at = root
      skillWrites = skillWrites.then(async () => {
        const prior = ((await readRecord($, at)) ?? {})[key]?.skills_run ?? {}
        if (!(e.skill in prior)) await patchRecord($, at, key, { skills_run: { ...prior, [e.skill]: await $.clock.now() } })
        await refreshFlow($, at, key)
      }).catch(() => {})
      await skillWrites
    }
    return next(e)
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
    if (isSkipped) return res
    if (!dispatcher) {
      // No address: the brief did not come through the mod (a held delivery, a brief typed in
      // by `herdr agent prompt`). Measured downstream: a gate pane in auto mode ended its turn
      // and nothing reached the dispatcher for minutes. The record is the path that needs no
      // address; the dispatcher's poll wakes from it.
      if (root && me.role !== 'resident') {
        await patchRecord($, root, me.key, { last_turn_end_at: await $.clock.now(), last_turn_reason: e.reason,
          turn_end_pending: { at: await $.clock.now(), reason: 'no dispatcher address (brief did not arrive through the mod)', text: `${MARK} TURN-END key=${me.key} pane=${me.pane} reason=${e.reason}\n${e.answer.slice(-1500)}` } })
      }
      return res
    }
    if (root) await patchRecord($, root, me.key, { last_turn_end_at: await $.clock.now(), last_turn_reason: e.reason })
    const answer = e.answer.length > 1500 ? `…${e.answer.slice(-1500)}` : e.answer
    let flow = ''
    if (me.role === 'builder' && root) {
      const entry = ((await readRecord($, root)) ?? {})[me.key] ?? {}
      const ran = Object.keys(entry.skills_run ?? {})
      flow = `Skills run: ${ran.length ? ran.join(', ') : 'none'}\n`
    }
    const text = `${MARK} TURN-END key=${me.key} pane=${me.pane} reason=${e.reason}\n${flow}${answer}`
    const sent = await $.session.send({ to: dispatcher, text })
    undelivered = sent.isDelivered ? '' : String(sent.reason ?? 'not delivered')
    if (!sent.isDelivered) {
      // The message path can be closed by something outside this mod: measured downstream, a
      // pane toggled into auto mode had its SendMessage classified with no verdict, and the
      // dispatcher learned of the finished turn from the owner, ten minutes late. The record
      // is a second path the dispatcher already reads every 30 s, so the turn end goes there
      // too and the dispatcher's own mod wakes it from the file.
      $.ui.status(`astragentic-dispatch: TURN-END not delivered — ${sent.reason}; recorded for the dispatcher to pick up`)
      if (root) await patchRecord($, root, me.key, { turn_end_pending: { at: await $.clock.now(), reason: String(sent.reason ?? ''), text } })
    }
    return res
  })

  // ---- dispatcher side -------------------------------------------------------------------

  on('session.send', async ($, e, next) => {
    // A brief is a send whose first line is a slash command. Two things are checked at the one
    // moment every dispatch passes through, because both were skipped when they were prose:
    // the previous merge's tracker write-back, and this ticket's claim.
    const first = e.text.trimStart().split('\n')[0] ?? ''
    if (!me && root && e.origin.kind === 'model' && e.agentId === undefined && first.startsWith('/')) {
      // A harness upgrade that stopped on conflicts leaves this marker, and the unreconciled
      // files are the role contracts the next agent reads. Only the doctor read it, at
      // adaptation; the brief is where it has to refuse.
      const pending = `${root}/.astraler/state/apply-incomplete`
      if (await exists($, pending)) {
        let detail = ''
        try {
          detail = (await $.fs.read(pending)).split('\n').slice(0, 12).join('\n')
        } catch {}
        return {
          isDelivered: false,
          reason: `${MARK} not sent. A harness upgrade stopped part-way (${pending}); its conflicts are unreconciled, ` +
            `so the contracts an agent would read are half old. Reconcile them, stamp applied-version, delete the marker, ` +
            `then send this brief again.\n${detail}`,
        }
      }
      // A release that adds a launcher column cannot write it: orchestrator.md is the owner's
      // scaffold. So the column is required at the one moment every dispatch passes through, and
      // the cells stay the owner's — a blank cell launches without an advisor. Unreadable file:
      // the brief goes; a missing table is check-requirements' finding, not this one.
      const orch = await overlayFile($, `${root}/.agents/orchestrator.md`)
      const active = orch.match(/^[ \t]*##[ \t]*Active assignments[ \t#]*$([\s\S]*?)(?=^[ \t]*##[ \t]|$(?![\s\S]))/m)?.[1] ?? ''
      const header = active.split('\n').find(l => /^\s*\|\s*Role\s*\|/i.test(l)) ?? ''
      if (header && !/\|\s*Advisor\s*\|/i.test(header)) {
        return {
          isDelivered: false,
          reason: `${MARK} not sent. 2.18.0 added an Advisor column to the Active assignments table in .agents/orchestrator.md, ` +
            `and the launcher reads it; this table has none. Add the column (header "Advisor", a cell per row: opus, fable, or ` +
            `blank for none — orchestrator.md § How the columns are read has the pairing), then send this brief again.`,
        }
      }
      // Same harm, second shape: payload content edited in the main checkout and not committed.
      // A worktree checks out HEAD, so the agent reads the committed contract while the
      // dispatcher reads the edited one (AST-036). check-requirements reports it, but only at
      // adaptation; it was measured passing silently into the first dispatch after an upgrade.
      //
      // Measured downstream: about one commit in six passes through this state in ordinary work,
      // mostly a rule half-written into thomas.md. A gate whose only way through is committing
      // something unfinished teaches committing rubbish, so it takes a named acknowledgment: a
      // brief line `Uncommitted-payload: <why this brief is unaffected>` goes through, and the
      // line reaches the agent with the brief. Empty, it does not count.
      const dirty = await dirtyPayload($, root)
      const ack = e.text.match(/^Uncommitted-payload:[ \t]*(\S.*)$/m)
      if (dirty.length > 0 && !ack) {
        const hint = (line: string) =>
          /\.agents\/memory\/(INDEX|RULES)\.md$/.test(line)
            ? `${line}   <- generated: run scripts/ledger-index.sh and scripts/ledger-rules.py, then commit`
            : `${line}   <- the agent reads the committed copy, not this one`
        return {
          isDelivered: false,
          reason: `${MARK} not sent. Payload files are edited or untracked in this checkout, and a worktree sees ` +
            `only HEAD, so the agent would read a different contract than you do (AST-036). Commit or revert them; ` +
            `or, if this brief does not depend on them, add a line "Uncommitted-payload: <why>" and send again:\n` +
            dirty.slice(0, 12).map(hint).join('\n'),
        }
      }
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
    const isBrief = !me && root && e.origin.kind === 'model' && e.agentId === undefined && first.startsWith('/')
    const brief = isBrief && root ? await overlay($, root, 'dispatch-brief') : ''
    const res = await next(brief ? { ...e, text: `${e.text.trimEnd()}\n\n${brief}` } : e)
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

  // A dispatched pane has no human at it. A picker there blocks the turn until the dispatcher
  // notices and types into the pane. Measured downstream: Builders kept raising pickers after
  // the contract banned them; a rule in prose lost to the tool in front of the model.
  on('tool.call', { tool: 'AskUserQuestion' }, async ($, e, next) => {
    // A resident pane has its owner at it, and a subagent's picker is its parent's to answer.
    if (!me || me.role === 'resident' || e.agentId !== undefined) return next(e)
    return {
      deny: `astragentic-dispatch: no human is at this pane (${me.role} ${me.key}). Decide from the evidence you have, or report the question to the dispatcher in your handback; a picker here blocks the turn.`,
    }
  })

  // THE TWO GATES. Measured on the first two real dispatches after the FLOW line shipped: one
  // Builder skipped tdd, the other skipped the built-in review, and neither named n/a. A note at
  // merge made the skip visible; it did not make it impossible. So the skip is refused at the
  // moment it becomes real — the first commit with content, and the arm — and the dispatcher's
  // exemption is read from the brief, never from the Builder's own handback.
  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    if (me?.role !== 'builder' || !root) return next(e)
    // Every simple command in the call, heredoc bodies included; a commit is a content commit
    // unless that same command carries `--allow-empty` as a whole word (a marker). One exempt
    // commit never exempts another in the same call.
    const commits = simpleCommands(e.command).map(gitCommitArgs).filter((a): a is string[] => a !== null)
    const contentCommits = commits.filter(a => !a.includes('--allow-empty'))
    if (contentCommits.length === 0) return next(e)
    const entry = ((await readRecord($, root)) ?? {})[me.key] ?? {}
    const ran = skillsRun(entry)
    if ('mattpocock-skills:tdd' in ran || entry.tdd_na) return next(e)
    return {
      deny: `astragentic-dispatch: no record of mattpocock-skills:tdd in this pane, and the brief declares no "TDD: n/a — <why>". A content commit before the red test is the defect this gate exists for. Call Skill(skill: "mattpocock-skills:tdd") first; if this ticket genuinely has no seam, ask the dispatcher to add the TDD: n/a line to the brief.`,
    }
  })

  on('tool.call', { tool: 'Skill' }, async ($, e: any, next) => {
    if (me?.role !== 'builder' || !root) return next(e)
    if (!/^(codex-arm|codex-claude-arm)$/.test(String(e.skill ?? ''))) return next(e)
    const entry = ((await readRecord($, root)) ?? {})[me.key] ?? {}
    const ran = skillsRun(entry)
    if ('code-review' in ran || entry.review_na) return next(e)
    return {
      deny: `astragentic-dispatch: no record of the built-in code-review (Skill(skill: "code-review"), bare name) in this pane, and the brief declares no "REVIEW: n/a — <why>". The arm reads a tree the bug review has not; run it first, then arm.`,
    }
  })

  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    if (me || !root) return next(e)
    const rec = (await readRecord($, root)) ?? {}
    const cmd = runnable(e.command)

    // -- closing a pane, tab or workspace that holds a mid-turn agent ---------------------
    const close = cmd.match(new RegExp(AT_COMMAND + String.raw`herdr\s+(tab|pane|workspace)\s+close\s+['"]?([A-Za-z0-9:_-]+)`))
    if (close) {
      const [, kind, id] = close
      // A resident pane is never mid-turn in the record (it gets no brief), and it is the pane
      // with the most context to lose, so it is refused while it is recorded at all.
      const hit = Object.entries(rec).find(([, entry]) =>
        isLive(entry) && (isMidTurn(entry) || entry.role === 'resident') &&
        (kind === 'tab' ? entry.tab_id === id : kind === 'pane' ? entry.pane_id === id : String(entry.tab_id).startsWith(`${id}:`)),
      )
      if (hit) {
        const [key, entry] = hit
        return {
          deny: entry.role === 'resident'
            ? `astragentic-dispatch: resident pane ${key} lives in ${kind} ${id}. Closing it is the owner's call, not yours.`
            : `astragentic-dispatch: ${entry.role} ${key} is mid-turn in ${kind} ${id} (brief received, no TURN-END since). Closing it kills a working agent. Wait for its TURN-END, or ask the owner.`,
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
    const remove = cmd.match(new RegExp(AT_COMMAND + String.raw`git\s+(?:-C\s+\S+\s+)?worktree\s+remove\s+((?:-f\s+|--force\s+)*)(['"]?)([^\s'"]+)`))
    if (remove) {
      const isForced = Boolean(remove[1])
      // `git worktree remove /p; git worktree prune` arrives with `;` glued to the path, and the
      // refusal then blamed the path (found downstream). An UNQUOTED token loses the operator
      // glued to it; a quoted one is taken as written (a path may legitimately end in `;`).
      const raw = remove[2] ? (remove[3] ?? '') : (remove[3] ?? '').replace(/[;&|)]+$/, '')
      // UNREADABLE IS REFUSED HERE, NOT ALLOWED. This hook runs before the shell, so
      // `git worktree remove $(pwd)/$W` arrives with the variables unexpanded, matches no record,
      // and used to fall through every protection below — the mid-turn refusal included. Measured
      // downstream on the command Thomas actually typed. Removal destroys work and cannot be
      // undone, so a path this hook cannot resolve to a worktree git lists is refused, with the
      // remedy: pass it as a literal path. There is no pre-worktree-remove git hook to move this to.
      const listed = await run($, ['git', '-C', root, 'worktree', 'list', '--porcelain'])
      const known = listed.code === 0
        ? listed.out.split('\n').filter(l => l.startsWith('worktree ')).map(l => l.slice('worktree '.length))
        : []
      const knownReal = await Promise.all(known.map(k => realpath($, k)))
      if (/[$`~]/.test(raw)) {
        return { deny: `astragentic-dispatch: cannot tell which worktree "${raw}" is — it is expanded by the shell after this check runs. Pass the worktree as a literal absolute path.` }
      }
      const target = await realpath($, raw)
      // When `git worktree list` itself fails this check is skipped and the record lookup below
      // decides: a chosen fail-open for a git that cannot list, stated rather than discovered.
      if (listed.code === 0 && !knownReal.includes(target)) {
        return { deny: `astragentic-dispatch: "${raw}" resolves to ${target}, which is not a worktree of this repository (git worktree list). Pass the worktree's literal absolute path, as the only command in the call.` }
      }
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

    // -- a worktree add: the project's setup plug runs right after, in the new worktree --------
    // Mirrors release-worktree-resources.sh → cleanup-worktree.sh at removal. Measured downstream:
    // a project whose worktrees need seeding (env files, a local database) seeded them by hand
    // from prose, and the step was the one skipped. Absent plug: nothing. Failing plug: the
    // result says so; the worktree stays.
    const addSeg = simpleCommands(e.command).find(seg => /\bworktree\b/.test(seg) && shellWords(seg).includes('add'))
    if (addSeg) {
      const ran = await next(e)
      if (ran.deny !== undefined || ran.isError) return ran
      // Tokens with quotes honoured; `-C <dir>` sets the base a relative path resolves against.
      // The shell's own cwd is not visible here, so a relative path with no -C resolves against
      // the repo root, which is where a dispatcher runs this (stated, not assumed silently).
      const w = shellWords(addSeg)
      let base = root
      let i = w.findIndex(t => t === 'git' || t.endsWith('/git')) + 1
      while (i < w.length && w[i] !== 'worktree') {
        if (w[i] === '-C') base = (w[i + 1] ?? '').startsWith('/') ? (w[i + 1] ?? '') : `${root}/${w[i + 1] ?? ''}`
        i += (w[i] === '-C' || w[i] === '-c') ? 2 : 1
      }
      i = w.indexOf('add', i) + 1
      let path = ''
      for (; i < w.length; i++) {
        const t = w[i] ?? ''
        if (t === '-b' || t === '-B') { i++; continue }
        if (t.startsWith('-')) continue
        path = t
        break
      }
      const plug = `${root}/.astraler/project/setup-worktree.sh`
      if (!path || /[$`~]/.test(path) || !(await exists($, plug))) return ran
      const wt = path.startsWith('/') ? path : `${base}/${path}`
      try {
        const r = await $.process.run(['bash', plug, wt], { cwd: root, timeoutMs: 120_000 })
        const note = r.exitCode === 0
          ? `${MARK} setup-worktree.sh ran for ${wt}.`
          : `${MARK} setup-worktree.sh FAILED (exit ${r.exitCode}) for ${wt}: ${printable(String(r.stderr ?? r.stdout ?? '').trim().split('\n').slice(-3).join(' / '))}. The worktree exists; do not dispatch into it until the plug passes.`
        return { ...ran, context: [...(ran.context ?? []), note] }
      } catch (err) {
        return { ...ran, context: [...(ran.context ?? []), `${MARK} setup-worktree.sh could not run for ${wt}: ${String(err)}`] }
      }
    }

    // -- a merge: the tracker write-back is owed from this moment, so say so in the result -----
    const merge = new RegExp(AT_COMMAND + String.raw`(?:git\s+(?:-C\s+\S+\s+)?merge\b|gh\s+pr\s+merge\b)`).test(cmd)
    const ran = await next(e)
    if (!merge || ran.deny !== undefined || ran.isError) return ran
    const isPr = /\bgh\s+pr\s+merge\b/.test(e.command)
    // A PR merged on the remote never reaches the local base, so ancestry cannot see it.
    // Mark the entries the command names, by ticket id or by the PR's head branch.
    const pr = isPr ? e.command.match(/\bgh\s+pr\s+merge\s+(\S+)/)?.[1] : undefined
    const head = pr && !pr.startsWith('-')
      ? (await run($, ['gh', 'pr', 'view', pr, '--json', 'headRefName', '-q', '.headRefName'], 30_000)).out
      : ''
    const notes: string[] = []
    for (const [key, entry] of Object.entries(rec)) {
      // Whole-token matches only: `feature/foo` must not claim `gh pr merge feature/foo-fix`
      // (found by the 2.18.0 gate), and a ticket id must not match inside a longer one.
      const words = e.command.split(/\s+/)
      const isNamed = words.includes(key) || (head && entry?.branch === head) ||
        (typeof entry?.branch === 'string' && entry.branch.length > 0 && words.includes(entry.branch))
      if (!isNamed) continue
      if (isPr) await patchRecord($, root, key, { merged_at: await $.clock.now() })
      // Only a pane the mod itself registered (it has a session_id) is judged: a Codex or
      // OpenCode Builder records nothing here and keeps the marker script as its evidence.
      if (entry?.role === 'builder' && entry.session_id) {
        const gaps = flowGaps(entry)
        if (gaps.length > 0) {
          notes.push(`${MARK} ${key} merged with no record of: ${gaps.join(', ')}. A step the handback names n/a with its reason is fine; any other is a step that did not run.`)
        }
      }
    }
    const owed = await owedTickets($, root)
    await refreshBoard($, root, sends)
    if (owed.length > 0) notes.push(`${MARK} ${owedText(owed)} The next brief will not be sent until this is done.`)
    if (notes.length === 0) return ran
    return { ...ran, context: [...(ran.context ?? []), ...notes] }
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
    if (me) {
      if (e.props.hasSurvey) return next(e)
      const { Box, Text } = $.ui.resolve(e)
      const f = me.role === 'builder' ? await read($, flow) : null
      if (!undelivered && !f) return next(e)
      const isMode = /auto mode|classifier|permission/i.test(undelivered)
      const hint = isMode ? ' This pane is not in bypass-permissions mode: press shift+tab until it is.' : ''
      return (
        <Box flexDirection="column">
          {undelivered ? (
            <Text color="red">
              TURN-END not delivered to the dispatcher ({undelivered}).{hint} The record carries it meanwhile.
            </Text>
          ) : null}
          {f ? <Text dimColor>flow {me.key}: {flowLine(f)}</Text> : null}
        </Box>
      )
    }
    if (!root || e.props.hasSurvey) return next(e)
    const rows = await read($, board)
    const b = await read($, banner)
    const { Text } = $.ui.resolve(e)
    const isAlarm = rows.some(r => r.note === 'not confirmed received' || r.state === 'merged' || (r.note ?? '').startsWith('turn end read from record'))
    const parts = [
      b.branch ? `⎇ ${b.branch}` : '',
      rows.length ? `dispatch: ${boardLine(rows, await $.clock.now())}` : 'dispatch: none',
      b.extra,
    ].filter(Boolean)
    return (
      <Text dimColor={!isAlarm} color={isAlarm ? 'red' : undefined}>
        {parts.join(' · ')}
      </Text>
    )
  })
}
