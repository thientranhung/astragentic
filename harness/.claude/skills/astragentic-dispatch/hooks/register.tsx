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
//   - A pane whose tab label is `ticket:` / `spec:` / `qa:` / `resident:` writes its own tab and
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
// `.astraler/project/tracker-state.sh` (or the declared reader) reports unclaimed (assignee `-`, or
// state `closed`, `done` or `unclaimed`) is not sent. Neither is any brief while a Builder ticket has reached the base with
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

// The Builder flow, as the skill names the engine reports at `skill.prompt` (5.0.0: the
// harness's own `astra-*` skills; the built-in `code-review` arrives bare and is called from
// inside `astra-review`, so both keys land on the record). The record is the pane's own
// observation of the call, which a commit message cannot forge the way a `Pass:` line can
// (AST-055, AST-130). `tdd` is not a skill call: the commit gate measures a test file and a
// RED run, and the merge gate reads that stamp (4.1.0, 4.5.2).
const FLOW: ReadonlyArray<readonly [string, string]> = [
  ['astra-implement-with-tdd', 'tdd'],
  ['astra-review', 'astra-review'],
  ['code-review', 'built-in code-review'],
  ['simplify', 'simplify'],
]

// A record is a file anyone can edit; a `skills_run` that is not an object must read as empty,
// not throw (a throwing gate is a skipped gate).
function skillsRun(entry: Entry): Record<string, unknown> {
  const run = entry?.skills_run
  return run && typeof run === 'object' && !Array.isArray(run) ? run : {}
}

// What the station owes a ticket before merge, declared on its brief (`QA: walk|probe|verify`)
// and answered by a QA pane keyed `qa:<key>` that ended a turn AFTER the Builder's last one.
// Measured on the first adopter: 27 QA reports in a month but 4 markers at merge — the walk
// ran, and nothing at the merge could say for which ticket. 'none' and an undeclared brief owe
// nothing; a declared mode with no QA turn after the Builder's last is the gap named here.
function qaOwed(rec: Record<string, Entry>, key: string): string | null {
  const b = rec[key]
  const mode = typeof b?.qa_required === 'string' ? b.qa_required : null
  if (!mode || mode === 'none') return null
  const q = rec[`qa:${key}`]
  const qaEnd = Math.max(Number(q?.last_turn_end_at ?? 0), Number(b?.qa_last_turn_end_at ?? 0))
  const builderEnd = Number(b?.last_turn_end_at ?? 0)
  return qaEnd > 0 && qaEnd >= builderEnd ? null : mode
}

// EVERY SKILL CALL, IN ORDER (4.5.2). `skills_run` keeps the first call and `skills_last` the
// latest; neither can say whether tdd ran before or after the first content commit, which is
// the question the owner's ruling of 2026-10-26 asks (61 of 161 downstream tickets committed
// code first, 15 never called tdd). `skills_log` is the list, capped at the last 400 calls.
function skillsLog(entry: Entry): Array<{ skill: string; at: number }> {
  const log = entry?.skills_log
  return Array.isArray(log) ? log.filter(x => x && typeof x.skill === 'string' && typeof x.at === 'number') : []
}
// The test-run log `scripts/hook-test-run.py` (PostToolUse) writes: `<ms>\t<status>\t<cmd>` per
// test command, one file per git toplevel under /tmp/harness-test-runs/. A RED run is a
// non-zero status after `since`.
function testRunLogPath(dir: string): string {
  return `/tmp/harness-test-runs/${dir.replace(/[^A-Za-z0-9]+/g, '_').replace(/^_+|_+$/g, '')}.log`
}
type TestRun = { at: number; status: string; cmd: string }
async function testRunsAfter($: any, dir: string, since: number): Promise<TestRun[]> {
  // The hook names the file by the REAL path of the git toplevel (macOS: /var is /private/var);
  // the record may hold the path as typed, so both spellings are read.
  let real = dir
  try { const r = await $.process.run(['realpath', dir], { timeoutMs: 5_000 }); if (r.exitCode === 0 && r.stdout.trim()) real = r.stdout.trim() } catch {}
  const text = [await overlayFile($, testRunLogPath(real)), real === dir ? '' : await overlayFile($, testRunLogPath(dir))].join('\n')
  const out: TestRun[] = []
  for (const line of text.split('\n')) {
    const [ms, status, ...rest] = line.split('\t')
    const at = Number(ms)
    if (Number.isFinite(at) && at > since && status !== undefined) out.push({ at, status: status.trim(), cmd: rest.join('\t') })
  }
  return out.sort((a, b) => a.at - b.at)
}
// A red run has its OWN non-zero exit code; `masked` (4.5.3: the test was followed by `;`, `|`
// or a newline, so the tool reported another command's code) is neither red nor green.
async function redRunAfter($: any, dir: string, since: number): Promise<number | null> {
  for (const r of await testRunsAfter($, dir, since)) { const st = Number(r.status); if (Number.isFinite(st) && st !== 0) return r.at }
  return null
}

async function lastRunLine($: any, dir: string, since: number): Promise<string> {
  const runs = await testRunsAfter($, dir, since)
  const last = runs[runs.length - 1]
  if (!last) return 'no test run logged since the brief'
  return `${runs.length} run(s) logged since the brief, last: exit ${last.status} — ${last.cmd.slice(0, 120)}`
}

function flowGaps(entry: Entry): string[] {
  const run = skillsRun(entry)
  return FLOW.filter(([name]) => !(name in run)).map(([, label]) => label)
}

// THE STEP IN PROGRESS (4.3.2). `skills_run` holds the FIRST call of each skill, which is what
// the gates and the TURN-END line read. The band needs the LATEST call: the step a Builder is
// at is the one it invoked most recently, and it stays there until the pane ends a turn with
// nothing live or invokes the next step. Measured downstream (one ticket, 2026-10-22): the
// built-in code-review went green at its invocation while its four review agents still ran,
// the step after it lit yellow as "next", and the owner read the pane as hung on that step.
// `skills_last` is written on every call; a record from before 4.3.2 falls back to the first.
function latestInvoked(entry: Entry): { name: string; at: number } | null {
  const steps = FLOW_BY_ROLE[String(entry?.role ?? '')] ?? []
  const first = skillsRun(entry)
  const lastRaw = entry?.skills_last
  const last: Record<string, unknown> = lastRaw && typeof lastRaw === 'object' && !Array.isArray(lastRaw) ? lastRaw : {}
  let best: { name: string; at: number } | null = null
  for (const [name] of steps) {
    const keys = name === 'codex-arm' ? ['codex-arm', 'codex-claude-arm'] : [name]
    for (const k of keys) {
      const at = Number(last[k] ?? first[k] ?? 0)
      // `>=`: two steps stamped in the same millisecond (measured downstream, 2026-10-22: the
      // 4.3.2 selftest on a fast box) resolve to the later one in flow order, which is the
      // one called second. A strict `>` left the earlier step lit.
      if (at > 0 && (!best || at >= best.at)) best = { name, at }
    }
  }
  return best
}
const PANE = 'dispatch-board'
const RECORD = '.astraler/state/dispatch-record.json'

// The project's own rules live outside the payload, so a release never overwrites them.
// `overlays/<role>.md` joins the role's system prompt at every render (measured 2026-10-09 on
// 2.1.294: a `prompt.compose` section added here was read on the first turn), and
// `overlays/dispatch-brief.md` joins every brief this mod sends. Measured downstream before this
// existed: 64 payload files edited in place and re-applied after every upgrade.
const OVERLAYS = '.astraler/project/overlays'

// THE TEST-FILE PATTERN, ONE HOME (4.1.3). The commit gate (4.1.0) and the merge gate read the
// same regex: `.astraler/project/test-file-pattern` (one line) or the default. Two copies
// disagreed downstream (the project adds `-selftest\.sh$`) and a stale copy is a gate that lies.
async function testFileRe($: any, root: string): Promise<RegExp> {
  const projPat = (await overlayFile($, `${root}/.astraler/project/test-file-pattern`)).split('\n')[0]?.trim()
  try { return new RegExp(projPat || String.raw`(^|/)(tests?|__tests__|spec)/|[._-](test|spec)s?\.[A-Za-z0-9]+$|_test\.go$`) } catch { return /(^|\/)(tests?|__tests__|spec)\/|[._-](test|spec)s?\.[A-Za-z0-9]+$|_test\.go$/ }
}

// Does the branch carry a test file the dispatch base did not? The question the commit gate
// asks of the index, asked of a ref at merge. `null` when git cannot answer (no base recorded,
// a ref that is not local): a gate that fires on its own missing data is noise.
async function branchCarriesTest($: any, root: string, entry: Entry, ref: string): Promise<boolean | null> {
  const base = typeof entry.start_sha === 'string' && entry.start_sha ? entry.start_sha : ''
  if (!base || !ref) return null
  const r = await run($, ['git', 'diff', '--name-only', '--diff-filter=ACMR', base, ref, '--'], 30_000, root)
  if (r.code !== 0) return null
  const re = await testFileRe($, root)
  return r.out.split('\n').filter(Boolean).some(p => re.test(p))
}

async function overlayFile($: any, path: string): Promise<string> {
  try {
    return (await $.fs.read(path)).trim()
  } catch {
    return ''
  }
}

// THE ARM IS A ROW THE OWNER CAN TURN OFF (4.0.2). `orchestrator.md` § Cross-vendor arm carries
// one row per scope (ticket, spec, slice); `no` turns that scope's arm off for the project — a
// machine with no Codex, or a Builder the owner wants faster. The role that owns the scope reads
// it here, as a system-prompt section (measured 2026-10-09: a prompt.compose section is read on
// the first turn), its band drops the chip, and the handback says `Arm: off (orchestrator)`.
// Absent table, absent row, anything but `no`: the arm is on, as it always was.
const ARM_SCOPE_BY_ROLE: Record<string, string> = { builder: 'ticket', shaper: 'spec', thomas: 'slice' }
// Read at most once every few seconds: ui.render asks on every render, the file changes when the
// owner edits it, and a dispatch picks the change up at the next brief either way.
const armCache = new Map<string, { at: number; off: Set<string> }>()
async function armOff($: any, root: string): Promise<Set<string>> {
  const now = Date.now()
  const hit = armCache.get(root)
  if (hit && now - hit.at < 5_000) return hit.off
  const off = await armOffRead($, root)
  armCache.set(root, { at: now, off })
  return off
}
async function armOffRead($: any, root: string): Promise<Set<string>> {
  const orch = await overlayFile($, `${root}/.agents/orchestrator.md`)
  const sect = orch.match(/^##\s*Cross-vendor arm\s*$([\s\S]*?)(?=^##\s|(?![\s\S]))/m)
  const off = new Set<string>()
  if (!sect) return off
  for (const m of sect[1].matchAll(/^\|\s*(ticket|spec|slice)\s*\|\s*(\w+)\s*\|/gm)) {
    if (m[2].toLowerCase() === 'no') off.add(m[1])
  }
  return off
}

function overlay($: any, root: string, name: string): Promise<string> {
  return overlayFile($, `${root}/${OVERLAYS}/${name}.md`)
}
const ACK_GRACE_MS = 90_000
// A held turn end (agents still running) that nobody has refreshed for this long is read as a
// stuck pane: eight code-review finders that never returned held a Builder's bell for four
// hours, and the owner noticed before the dispatcher did (measured downstream, 2026-10-13).
const HOLD_STALE_MS = 20 * 60_000
// True when dotted version `a` is newer than `b` (numeric per field; '' never is).
function isNewer(a: string, b: string): boolean {
  if (!a || !b) return false
  const x = a.split('.').map(n => parseInt(n, 10) || 0), y = b.split('.').map(n => parseInt(n, 10) || 0)
  for (let i = 0; i < Math.max(x.length, y.length); i++) { const d = (x[i] ?? 0) - (y[i] ?? 0); if (d !== 0) return d > 0 }
  return false
}

// The newest v-tag at the package remote, or '' when unreachable. One `git ls-remote` at the
// dispatcher's session start, so the band can say a newer release exists (3.3.0); the project's
// `.astraler/astragentic.sh update` is the same question answered in full.
async function latestRelease($: any): Promise<string> {
  const repo = (await $.env.get('ASTRAGENTIC_REPO')) || 'https://github.com/thientranhung/astragentic.git'
  const r = await run($, ['git', 'ls-remote', '--tags', '--refs', repo], 15_000)
  if (r.code !== 0) return ''
  let best = ''
  for (const line of r.out.split('\n')) {
    const v = line.match(/refs\/tags\/v(\d+(?:\.\d+)*)\s*$/)?.[1]
    if (v && (!best || isNewer(v, best))) best = v
  }
  return best
}

// Session names the dispatch record has held in this process; see refreshBoard.
const onceNamed = new Set<string>()
const TICKET = /^[A-Z][A-Z0-9]*-[0-9]+$/
// `resident:` is a long-lived pane the owner keeps (a deploy agent, a design partner): it gets
// no brief and reports no turn end, but it is recorded, shown on the board and protected from
// a close like any dispatched pane. Measured downstream: resident panes were invisible to the
// board and the one place a wrong close could not be refused.
const ROLE_BY_PREFIX: Record<string, string> = { ticket: 'builder', spec: 'shaper', qa: 'qa', resident: 'resident' }

const board = atom({ plugin: 'astragentic-dispatch', key: 'board' } as const, [] as BoardRow[])
// The always-on band: branch and worktree of the dispatcher's checkout, plus one line the
// project composes (`.astraler/project/status-line.sh`: tracker counts, who holds the gate
// token, whatever it measured it needed on screen). Measured downstream: the tracker table was
// injected into context at session start and never shown, and two gate runs collided while
// nobody could see who held the token.
const banner = atom({ plugin: 'astragentic-dispatch', key: 'banner' } as const, { branch: '', extra: '', version: '', latest: '' } as Banner)
// The Builder pane's own band: which FLOW steps have run, read from the same record the gates
// read, so the person watching the pane sees the step the Builder is at without reading the
// transcript (owner's ask, 2026-10-09).
const flow = atom({ plugin: 'astragentic-dispatch', key: 'flow' } as const, { ran: [], latest: null, lastTurnEndAt: 0, tddNa: false, reviewNa: false, simplifyNa: false, uxOwed: null, redRun: false, kind: null, refusals: 0, lastRefusal: null, qaMode: null } as Flow)

// One step list per dispatched role, in the order the contract names the phases, each step
// the skill name the engine reports at `skill.prompt`. Builder's is the gated flow with two
// optional step (ui: owed when the brief's FLOW names astra-ui, 4.5.3/5.0.0); Shaper's is its five phases. QA runs its plan in the product and calls no
// skill, so its band carries the role chip and the mode chip. The owner's ask (2026-10-10): see
// on every dispatched pane which step it is at, so a dropped step shows as a gap in the order.
// `red-run` (5.0.0) is not a skill: one Skill expansion yields one record line, and
// `astra-implement-with-tdd` is the expansion, so the tdd chip lights from the RED run in the
// test-run log — the thing the commit gate measures — not from a call.
type Step = readonly [string, string, boolean?]   // skill name, chip label, optional
const RED_RUN = 'red-run'
const FLOW_BY_ROLE: Record<string, ReadonlyArray<Step>> = {
  builder: [
    ['astra-implement-with-tdd', 'implement'],
    [RED_RUN, 'tdd'],
    ['astra-ui', 'ui', true],
    ['astra-review', 'review'],
    ['simplify', 'simplify'],
    ['codex-arm', 'arm'],
  ],
  shaper: [
    ['astra-grill-with-docs', 'align'],
    ['astra-to-spec', 'spec'],
    ['codex-arm', 'arm:spec'],
    ['test-design', 'test-design'],
    ['astra-to-tickets', 'tickets'],
  ],
  qa: [],
}

async function refreshFlow($: any, root: string, key: string): Promise<void> {
  const entry = ((await readRecord($, root)) ?? {})[key] ?? {}
  const refusals = Array.isArray(entry.refusals) ? entry.refusals : []
  const last = refusals.length ? refusals[refusals.length - 1] : null
  // the tdd chip: a RED run logged since the brief (the commit gate's stamp once it passed, the
  // log itself before that), in the pane's worktree
  // Builder panes only: a Shaper or QA pane carries a brief too and owes no red run, and the
  // read spawns `realpath` (one process per refresh, never on the band's tick: refreshFlow runs
  // on a skill call, a brief, a turn end, a refusal)
  const briefAt = entry.role === 'builder' ? Number(entry.last_brief_received_at ?? 0) : 0
  const dir = typeof entry.worktree === 'string' && entry.worktree ? entry.worktree : root
  const redRun = typeof entry.red_run_at === 'number' || (briefAt > 0 && (await redRunAfter($, dir, briefAt).catch(() => null)) !== null)
  await update($, flow, () => ({
    ran: Object.keys(skillsRun(entry)),
    redRun,
    latest: latestInvoked(entry),
    lastTurnEndAt: Number(entry.last_turn_end_at ?? 0),
    tddNa: Boolean(entry.tdd_na),
    reviewNa: Boolean(entry.review_na),
    simplifyNa: Boolean(entry.simplify_na),
    kind: entry.kind === 'quick' || entry.kind === 'full' ? entry.kind : null,
    uxOwed: typeof entry.ux_owed === 'boolean' ? entry.ux_owed : null,
    refusals: refusals.length,
    lastRefusal: last && typeof last === 'object' ? { gate: String(last.gate ?? ''), at: Number(last.at ?? 0) } : null,
    qaMode: typeof entry.qa_mode === 'string' ? entry.qa_mode : null,
  }))
}

// A refusal is an event, and until 2.21.2 it left no trace: the first measured dispatch under
// the gates could say the steps ended up in order, not whether a gate had fired. Each refusal
// is appended to the record entry and to the machine's hook log, and the band shows it red for
// two minutes.
async function logRefusal($: any, root: string, key: string, gate: string, detail: string): Promise<void> {
  const at = await $.clock.now()
  const entry = ((await readRecord($, root)) ?? {})[key] ?? {}
  const prior = Array.isArray(entry.refusals) ? entry.refusals : []
  await patchRecord($, root, key, { refusals: [...prior, { at, gate, detail: detail.slice(0, 200) }] })
  // APPEND, never read-then-write. The earlier form read the whole log and wrote it back with
  // one line added; a read that failed (or raced another writer) wrote the file back as that
  // one line, and the shared log lost its history. nizzy-ecom measured the file starting on
  // 2026-10-15 on a box booted 10-05 (4.0.2). The shell's `>>` is the append the fs API lacks.
  try {
    const line = `${new Date(at).toISOString()} astragentic-dispatch REFUSED ${gate} key=${key} ${detail.slice(0, 200)}`
    await $.process.run(['sh', '-c', 'printf "%s\\n" "$1" >> /tmp/harness-hook-events.log', '_', line], { timeoutMs: 5_000 })
  } catch {}
  await refreshFlow($, root, key)
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

// A `$(…)`, backtick or process substitution anywhere the shell would run it: inside double
// quotes it still runs, inside single quotes it is text, and a backslash escapes the next
// character. An apostrophe inside double quotes is a character, not a quote (arm pass 11).
function hasSubstitution(command: string): boolean {
  let q: string | null = null
  for (let i = 0; i < command.length; i++) {
    const ch = command[i] ?? ''
    if (q === "'") { if (ch === "'") q = null; continue }
    if (ch === '\\') { i++; continue }
    if (q === '"') { if (ch === '"') { q = null; continue } }
    else if (ch === '"' || ch === "'") { q = ch; continue }
    if (ch === '`') return true
    if ((ch === '$' || ch === '<' || ch === '>') && command[i + 1] === '(') return true
  }
  return false
}

// `2>&1`, `>&2`, `1<&0`: a redirection that duplicates a descriptor opens no file, so it is
// neither a step nor a write the replay misses. Dropped before the gate reads the call; it was
// split at its `&` and refused every `git commit … 2>&1` (measured on nizzy 2026-10-20:
// ten refusals and a stalled handback).
function dropFdDups(command: string): string {
  let out = ''
  let q: string | null = null
  for (let i = 0; i < command.length; i++) {
    const ch = command[i] ?? ''
    if (q) { out += ch; if (ch === q) q = null; continue }
    if (ch === '"' || ch === "'") { q = ch; out += ch; continue }
    if (ch === '\\') { out += ch + (command[i + 1] ?? ''); i++; continue }
    if ((ch === '>' || ch === '<') && command[i + 1] === '&') {
      const m = /^(\d+|-)(?=$|[\s;|&()])/.exec(command.slice(i + 2))
      const fd = /(^|[\s;|&()])(\d*)$/.exec(out)
      if (m && fd) { out = out.slice(0, out.length - (fd[2] ?? '').length); i += 1 + m[0].length; continue }
    }
    out += ch
  }
  return out
}

// `-m "$(cat <<'EOF' … EOF)"` is Claude Code's own commit recipe. A QUOTED heredoc expands
// nothing and `cat` alone writes nothing, so inside double quotes the substitution is the
// message text: it is read as one literal word. Outside double quotes it is word-split (a body
// of `-a` becomes a flag), so that, an unquoted tag or a second command still refuses. Measured on nizzy 2026-10-21: two fresh Builders refused on their first commit.
function literalCatHeredocs(command: string): string {
  let out = ''
  let q: string | null = null
  for (let i = 0; i < command.length; i++) {
    const ch = command[i] ?? ''
    if (q === "'") { out += ch; if (ch === "'") q = null; continue }
    if (ch === '\\') { out += ch + (command[i + 1] ?? ''); i++; continue }
    if (q === '"') { if (ch === '"') q = null }
    else if (ch === '"' || ch === "'") { q = ch; out += ch; continue }
    if (q === '"' && ch === '$' && command[i + 1] === '(') {
      const head = /^\$\(\s*cat\s+<<(-?)\s*(['"])([A-Za-z_][A-Za-z0-9_]*)\2[ \t]*\n/.exec(command.slice(i))
      if (head) {
        const isTabbed = head[1] === '-'
        let at = i + head[0].length
        let end = -1
        while (at <= command.length) {
          const nl = command.indexOf('\n', at)
          const line = command.slice(at, nl < 0 ? command.length : nl)
          if ((isTabbed ? line.replace(/^\t+/, '') : line) === head[3]) {
            const close = /^\s*\)/.exec(command.slice(nl < 0 ? command.length : nl))
            if (close) end = (nl < 0 ? command.length : nl) + close[0].length
            break
          }
          if (nl < 0) break
          at = nl + 1
        }
        if (end > 0) { out += 'heredoc-message'; i = end - 1; continue }
      }
    }
    out += ch
  }
  return out
}

// An unquoted `<` or `>` in a segment: a redirection writes or reads a file the replay does
// not see (`git show HEAD:x.test.js > x.test.js` restores a test before the commit) (arm pass 13).
function hasRedirection(segment: string): boolean {
  let q: string | null = null
  for (let i = 0; i < segment.length; i++) {
    const ch = segment[i] ?? ''
    if (q) { if (ch === q) q = null; continue }
    if (ch === '\\') { i++; continue }
    if (ch === '"' || ch === "'") { q = ch; continue }
    if (ch === '<' || ch === '>') return true
  }
  return false
}

// The same split, with the operator that precedes each segment: `&&` and `;`/newline run the
// next segment in a way a replay can follow (a failing step refuses the call); `||`, `|`, `&`,
// a subshell or a backtick do not, and a staging step behind one is not judged (arm pass 9).
function segmentsWithOps(command: string): Array<{ op: string; seg: string }> {
  const out: Array<{ op: string; seg: string }> = []
  let cur = ''
  let q: string | null = null
  let op = ''
  for (let i = 0; i < command.length; i++) {
    const ch = command[i] ?? ''
    if (q) { cur += ch; if (ch === q) q = null; continue }
    if (ch === '"' || ch === "'") { q = ch; cur += ch; continue }
    // a `#` that starts a word is a comment to the end of the line: the shell never runs what
    // follows it, so neither may the replay (arm pass 12)
    if (ch === '#' && (i === 0 || /[\s;&|()]/.test(command[i - 1] ?? ''))) {
      while (i + 1 < command.length && command[i + 1] !== '\n') i++
      continue
    }
    if (ch === '&' && (command[i + 1] === '>' || command[i - 1] === '>' || command[i - 1] === '<')) { cur += ch; continue }
    if (ch === '\n' || ch === ';' || ch === '&' || ch === '|' || ch === '(' || ch === ')' || ch === '`') {
      if (cur.trim()) out.push({ op, seg: cur.trim() })
      cur = ''
      let tok = ch
      if ((ch === '&' || ch === '|') && command[i + 1] === ch) { tok = ch + ch; i++ }
      op = tok === '\n' ? ';' : tok
      continue
    }
    cur += ch
  }
  if (cur.trim()) out.push({ op, seg: cur.trim() })
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
    if (ch === '&' && (command[i + 1] === '>' || command[i - 1] === '>' || command[i - 1] === '<')) { cur += ch; continue }
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
// skipped; returns the words after `commit` and the `-C` directory if one was given, or null.
// THE TREE A CALL WILL COMMIT, computed BY GIT in a scratch index (4.1.0, arm passes 4–5).
// `git commit -a` commits the working tree of tracked files; `git commit -- <paths>` commits
// the working-tree versions of those paths on top of HEAD; a `git add`/`git rm` earlier in the
// same call changes the index first; a pathspec is git's to resolve, a short-option cluster
// (`-am x`, `-mchange`) is git's grammar. Five arm passes found a hole in every hand-written
// model of these, so the gate no longer models them: it copies the index, replays the call's
// index-changing steps and the commit's own staging mode against the copy with git, and diffs
// that copy against the dispatch base. Nothing touches the real index or the working tree
// (`git rm` is replayed as `git rm --cached`).
type CommitShape = { all: boolean; include: boolean; only: boolean; amend: boolean; paths: string[]; dir: string | null; steps: Array<{ argv: string[]; dir: string | null }>; unsafe: string | null; commits: number }
const COMMIT_SHORT_VALUE = new Set(['m', 'F', 'C', 'c', 't'])
const COMMIT_LONG_VALUE = new Set(['--message', '--file', '--author', '--date', '--reuse-message', '--reedit-message', '--fixup', '--squash', '--trailer', '--cleanup', '--template'])
// the long options a commit may carry and still be judged; git also accepts any unique
// prefix (`--pathspec-from` for `--pathspec-from-file`, `--al` for `--all`), so an option
// not spelled in full here is refused rather than ignored (arm pass 12)
const COMMIT_LONG_FLAG = new Set(['--all', '--include', '--only', '--amend', '--no-verify', '--verify', '--no-edit', '--edit', '--quiet', '--verbose', '--signoff', '--no-signoff', '--allow-empty', '--allow-empty-message', '--no-status', '--status', '--reset-author', '--no-gpg-sign', '--gpg-sign', '--no-post-rewrite', '--long', '--short', '--branch', '--no-ahead-behind'])
function commitShape(command: string, commitArgs: string[], worktree: string | null): CommitShape {
  const shape: CommitShape = { all: false, include: false, only: false, amend: false, paths: [], dir: null, steps: [], unsafe: null, commits: 0 }
  let dd = false
  for (let i = 0; i < commitArgs.length; i++) {
    const a = commitArgs[i] ?? ''
    if (dd) { shape.paths.push(a); continue }
    if (a === '--') { dd = true; continue }
    if (a.startsWith('--')) {
      const name = a.split('=')[0] ?? a
      if (a === '--all') shape.all = true
      else if (a.startsWith('--pathspec-from-file') || a.startsWith('--pathspec-file-nul')) shape.unsafe ??= '`git commit --pathspec-from-file`'
      else if (a === '--include') shape.include = true
      else if (a === '--only') shape.only = true
      else if (a === '--amend') shape.amend = true
      else if (COMMIT_LONG_VALUE.has(a)) i++
      else if (COMMIT_LONG_VALUE.has(name) && a.includes('=')) { /* --message=… */ }
      else if (!COMMIT_LONG_FLAG.has(name)) shape.unsafe ??= `\`git commit ${name}\` (not an option this gate reads in full)`
      continue
    }
    if (a.startsWith('-') && a.length > 1) {
      // a cluster is read left to right; a value-taking letter eats the rest of the token or
      // the next token, and nothing after it is a flag (`-mchange` is a message, not `-a`)
      for (let k = 1; k < a.length; k++) {
        const ch = a[k] ?? ''
        if (COMMIT_SHORT_VALUE.has(ch)) { if (k === a.length - 1) i++; break }
        if (ch === 'a') shape.all = true
        else if (ch === 'i') shape.include = true
        else if (ch === 'o') shape.only = true
      }
      continue
    }
    shape.paths.push(a)
  }
  // Each segment's effective directory: `cd` across segments and `-C` on the command, the way
  // commitsInWorktree reads them. A `cd` this cannot resolve leaves the directory unknown, and
  // unknown is unsafe here: a replay at the wrong directory judges the wrong files.
  const join = (base: string, p: string) => p.startsWith('/') ? p : `${base}/${p}`.replace(/\/\.(?=\/|$)/g, '')
  // A substitution runs BEFORE the commit it sits in, even inside double quotes:
  // `git commit -m "fix $(git reset HEAD -- x.test.js)"` unstages the judged test after the
  // judgment. Only single quotes keep one literal (arm pass 10).
  if (hasSubstitution(command)) shape.unsafe ??= 'a command substitution'
  let cwd: string | null = worktree
  for (const { op, seg } of segmentsWithOps(command)) {
    const w = shellWords(seg)
    if (shape.commits === 0 && (op === '||' || op === '|' || op === '&' || op === '(' || op === ')' || op === '`')) { shape.unsafe ??= `a step behind \`${op}\``; continue }
    if (shape.commits === 0 && hasRedirection(seg)) { shape.unsafe ??= 'a redirection to or from a file'; continue }
    if (w[0] === 'cd' || w[0] === 'pushd') {
      const target = w[1] ?? ''
      cwd = !target || target === '-' || /[$`~]/.test(target) ? null : cwd === null ? null : join(cwd, target)
      continue
    }
    // `git` in the executable position only: `echo git add x` stages nothing (arm pass 9).
    let j = (w[0] === 'git' || (w[0] ?? '').endsWith('/git')) ? 0 : -1
    // Before the commit, only `cd` and the replayable git steps may stand: any other segment
    // (`false && git add …`, `test -f x && git add x`, `|| true`) makes whether a staging step
    // RAN depend on shell control flow the replay does not evaluate (arm pass 8).
    if (j < 0) { if (shape.commits === 0) shape.unsafe ??= `a non-git step (\`${(w[0] ?? '').slice(0, 20)}\`)`; continue }
    j++
    let dir = cwd
    while (j < w.length && (w[j] ?? '').startsWith('-')) {
      if (w[j] === '-C') { const d = w[j + 1] ?? ''; dir = dir === null || /[$`~]/.test(d) ? null : join(dir, d); j += 2; continue }
      // any other global option (`--work-tree`, `--git-dir`, `-c core.x=y`, `--namespace`)
      // points git at a tree or index the replay does not model: refused (arm pass 10)
      shape.unsafe ??= `\`git ${w[j]}\``
      break
    }
    const sub = w[j]
    if (sub === 'commit') {
      shape.commits++
      if (shape.commits === 1) shape.dir = dir
      continue
    }
    if (shape.commits > 0) continue
    if (sub === 'add') shape.steps.push({ argv: [sub, ...w.slice(j + 1)], dir })
    else if (sub === 'rm' && w.slice(j + 1).includes('--cached')) {
      // the replay is BUILT, never copied: `--cached` plus `-r`/`-q`/`--` and paths. Any other
      // flag (`-f`, `--no-cached`, `--ignore-unmatch`) is a removal the gate cannot promise
      // stays in the index (arm pass 9).
      const rest = w.slice(j + 1)
      const flags = rest.filter(a => a.startsWith('-') && a !== '--')
      if (flags.every(a => a === '--cached' || a === '-r' || a === '-q' || a === '--quiet')) shape.steps.push({ argv: ['rm', ...flags.filter(a => a !== '--cached'), '--', ...rest.filter(a => !a.startsWith('-'))], dir })
      else shape.unsafe ??= `\`git rm\` with ${flags.filter(a => a !== '--cached').join(' ')}`
    }
    else if (sub === 'status' || sub === 'diff' || sub === 'log' || sub === 'show' || sub === 'rev-parse' || sub === 'branch' || sub === 'ls-files') { /* read-only: stages nothing */ }
    else shape.unsafe ??= `\`git ${sub ?? ''}\``
  }
  return shape
}

function gitCommitArgs(segment: string): { args: string[]; dir: string | null } | null {
  const w = shellWords(segment)
  let i = w.findIndex(t => t === 'git' || t.endsWith('/git'))
  if (i < 0) return null
  i++
  let dir: string | null = null
  while (i < w.length) {
    const t = w[i] ?? ''
    // every `-C` applies in turn, each relative to the one before (`git -C /repo -C src`):
    // keeping only the last one resolved `src` against the shell's cwd (arm pass 7)
    if (t === '-C') { const d = w[i + 1] ?? ''; dir = d.startsWith('/') || dir === null ? d : `${dir}/${d}`; i += 2; continue }
    // any other global option: whether it takes a separate value (`--config-env k=V`) is git's
    // business, not this reader's. If `commit` stands anywhere after it, this IS a commit and
    // commitShape refuses the option; a mis-read that hid the commit was the hole (arm pass 11).
    if (t.startsWith('-')) {
      const k = w.indexOf('commit', i + 1)
      return k < 0 ? null : { args: w.slice(k + 1), dir }
    }
    break
  }
  return w[i] === 'commit' ? { args: w.slice(i + 1), dir } : null
}

// The commits in a call that land INSIDE the given worktree, following `cd` across segments
// and `-C` on the command. The first measured refusal (2.21.2) was a fixture commit in a
// throwaway clone under /tmp — a Builder building a mutation fixture — so a commit elsewhere
// is not this gate's business. The pane's shell starts in the worktree, so the cwd begins
// there. A `cd` this hook cannot resolve (a variable, `~`, `cd -`) leaves the location UNKNOWN,
// and unknown is gated: a commit whose place cannot be read is treated as a worktree commit,
// so `cd $X && git commit` is not a way around the gate. Only a commit at a readable path
// outside the worktree is let through.
function commitsInWorktree(command: string, worktree: string): string[][] {
  const inside = (p: string) => p === worktree || p.startsWith(worktree + '/')
  const join = (base: string, p: string) => p.startsWith('/') ? p : `${base}/${p}`.replace(/\/\.(?=\/|$)/g, '')
  let cwd: string | null = worktree
  const out: string[][] = []
  for (const seg of simpleCommands(command)) {
    const w = shellWords(seg)
    if (w[0] === 'cd' || w[0] === 'pushd') {
      const target = w[1] ?? ''
      cwd = !target || target === '-' || /[$`~]/.test(target) ? null : cwd === null ? null : join(cwd, target)
      continue
    }
    const c = gitCommitArgs(seg)
    if (!c) continue
    let at: string | null
    if (c.dir && /[$`~]/.test(c.dir)) at = null
    else if (c.dir && c.dir.startsWith('/')) at = c.dir
    else if (c.dir) at = cwd === null ? null : join(cwd, c.dir)
    else at = cwd
    if (at === null || inside(at)) out.push(c.args)
  }
  return out
}

function printable(text: string, max = 300): string {
  return text.replace(/\x1b\[[0-9;?]*[ -\/]*[@-~]/g, '').replace(/[\x00-\x09\x0b-\x1f\x7f]/g, '').trim().slice(0, max)
}


type Me = { role: string; key: string; tab: string; pane: string }
type Envelope = { from: string; fromName: string; inner: string }

// A session name as the dispatcher must type it when two sessions share a prefix: SendMessage
// refuses "builder-in-92" and demands "builder-in-92-32 [1c2d95]". The ack comes back with the
// bare name in `from-name`, so a send keyed by the typed string never matched its ack and the
// band read "not confirmed received" on 6 of 6 lanes (measured downstream, 2026-10-13).
function addressName(to: string): string {
  return to.replace(/\s*\[[0-9a-f]{4,}\]\s*$/i, '').trim()
}
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
  const m = String(got?.result?.tab?.label ?? '').match(/^(ticket|spec|qa|resident):(.+)$/)
  const role = ROLE_BY_PREFIX[m?.[1] ?? '']
  // A QA pane walks a Builder's ticket, so its record entry is keyed `qa:<key>`: the same key as
  // the Builder's would overwrite the Builder's entry (role, pane, skills) at QA's session start.
  const key = m?.[2] ? (role === 'qa' ? `qa:${m[2]}` : m[2]) : undefined
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
    $.ui.status(`${RECORD} is not valid JSON; not written`)
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

async function run($: any, argv: string[], timeoutMs = 10_000, cwd?: string, env?: Record<string, string>): Promise<{ code: number; out: string }> {
  try {
    const r = await $.process.run(argv, { timeoutMs, ...(cwd ? { cwd } : {}), ...(env ? { env } : {}) })
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
  const reader = await trackerReader($, root)
  const argv = (await exists($, plug)) ? [plug, id] : reader ? ['bash', reader, 'state', id] : null
  if (!argv) return null
  const r = await run($, argv, 30_000, root)
  const line = (r.out.split('\n')[0] ?? '').trim()
  const [state = '', assignee = ''] = line.split(/\s+/)
  // A plug that fails, prints nothing, or says the tracker is `unreachable` (ADAPT-HARNESS
  // tells a project with no shell route to print that) cannot answer, and a check that cannot
  // answer must not refuse every brief: it is treated as the empty socket.
  if (r.code !== 0 || !state || /^unreachable$/i.test(state)) return null
  return { state, assignee, line }
}

// THE TICKET'S KIND, FROM ITS LABELS (4.6.0). A `quick` label on the tracker exempts the Builder
// pane from tdd, Matt's code-review, simplify and ux (owed: the code, the project's own tests,
// the built-in code-review, the handback); `full` is the loop as it was. Two readers, two
// strengths, the split tracker-state already has: the project's own
// `.astraler/project/tracker-labels.sh <id>` (labels on stdout, whitespace-separated) is the
// opt-in that ENFORCES — a ticket with neither label is not sent; the package reader
// (`scripts/tracker.sh labels`, Jira through twg) only INFORMS — it sets the kind when a label is
// there and says nothing otherwise, because one downstream project reads Jira for display and
// never enforces it (owner ruling 2026-10-24). null when nothing can answer. Measured on the
// backlog this came from: 15–32% of one project's tickets were quick-shaped, each paid as a
// full loop (2026-10-25).
async function trackerLabels($: any, root: string, id: string): Promise<{ labels: string[]; enforcing: boolean } | null> {
  const plug = `${root}/.astraler/project/tracker-labels.sh`
  const hasPlug = await exists($, plug)
  const reader = hasPlug ? null : await trackerReader($, root)
  const argv = hasPlug ? [plug, id] : reader ? ['bash', reader, 'labels', id] : null
  if (!argv) return null
  let out = '', code = -1
  try { const r = await $.process.run(argv, { timeoutMs: 30_000, cwd: root }); out = String(r.stdout ?? ''); code = r.exitCode } catch { return null }
  if (code !== 0) return null
  const labels = out.split(/\s+/).map(l => l.trim().toLowerCase()).filter(Boolean)
  if (labels.includes('unreachable')) return null
  return { labels, enforcing: hasPlug }
}
function kindOf(labels: string[]): 'quick' | 'full' | null {
  return labels.includes('quick') ? 'quick' : labels.includes('full') ? 'full' : null
}

// The package's tracker reader (4.4.0), for a project that declares its tracker in
// `.astraler/project/tracker` (`jira <KEY>`) and writes no plug. null when nothing is declared.
async function readerPath($: any, root: string): Promise<string | null> {
  for (const p of [`${root}/scripts/tracker.sh`, `${root}/harness/scripts/tracker.sh`]) if (await exists($, p)) return p
  return null
}
async function trackerReader($: any, root: string): Promise<string | null> {
  return (await exists($, `${root}/.astraler/project/tracker`)) ? readerPath($, root) : null
}

// THE TRACKER IS READ ON EVENTS, NEVER ON THE CLOCK (owner's ruling, 2026-10-24). The band
// refreshes every 30 s; a Jira count through `twg` takes 5.4 s (measured), longer than the band's
// 5 s plug budget, and on the clock it would be ≈2,880 calls a day per dispatcher. So the counts
// are a cached chip, read at dispatcher session start, after a delivered Builder brief, after a
// merge, and on /tracker-refresh; one downstream project's 66 merges in 30 days put that near
// seven calls a day. Never awaited by the event that triggers it: a slow tracker does not slow a
// brief or a merge. A project with neither plug nor declaration gets no chip and no call.
let trackerBusy = false
async function refreshTracker($: any, root: string): Promise<void> {
  if (trackerBusy) return
  const plug = `${root}/.astraler/project/tracker-status.sh`
  const reader = await readerPath($, root)
  if (!reader || !((await exists($, plug)) || (await exists($, `${root}/.astraler/project/tracker`)))) return
  trackerBusy = true
  try {
    const r = await run($, ['bash', reader, 'counts'], 30_000, root)
    const line = r.code === 0 ? printable(r.out.split('\n')[0] ?? '').slice(0, 160) : 'tracker unreadable'
    await update($, banner, b => ({ ...b, tracker: line }))
  } catch {} finally { trackerBusy = false }
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

function lastReceivedAt(entry: Entry): number {
  return Number(entry.last_message_received_at ?? entry.last_brief_received_at ?? 0)
}

function isMidTurn(entry: Entry): boolean {
  const got = lastReceivedAt(entry)
  return got > 0 && got > (entry.last_turn_end_at ?? 0)
}

async function refreshBoard($: any, root: string | null, sends: Map<string, number>) {
  const now = await $.clock.now()
  const rec = root ? ((await readRecord($, root)) ?? {}) : {}
  const rows: BoardRow[] = []
  const named = new Set<string>()
  const owed = root ? await owedTickets($, root) : []
  for (const entry of Object.values(rec)) if (entry?.session_name) named.add(entry.session_name)
  // A lane the record once named and no longer holds was retired: its ack can never come, so
  // its send is forgotten with the entry (three such chips outlived their panes, measured
  // downstream, 2026-10-13). A send to a name the record never held stays: a mis-keyed brief.
  for (const name of sends.keys()) if (onceNamed.has(name) && !named.has(name)) sends.delete(name)
  for (const name of named) onceNamed.add(name)
  for (const [key, entry] of Object.entries(rec)) {
    if (!isLive(entry)) continue
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
      rows.push({ key, role, state: 'ended', since: entry.turn_end_pending.at ?? now, note: role === 'qa' ? 'turn end read from record (a QA pane runs under permissions; the record is its path)' : 'turn end read from record: its message was blocked, check that pane mode' })
      continue
    }
    const owedQa = role === 'builder' ? qaOwed(rec, key) : null
    const qaNote = owedQa ? `qa ○ ${owedQa}` : (role === 'builder' && entry.qa_required && entry.qa_required !== 'none' ? `qa ✓ ${entry.qa_required}` : undefined)
    if (owed.includes(key)) {
      rows.push({ key, role, state: 'merged', since: entry.merged_at ?? entry.last_turn_end_at ?? now, note: 'tracker not closed' })
    } else if (sentAt !== undefined) {
      const isLate = now - sentAt > ACK_GRACE_MS
      rows.push({ key, role, state: 'sent', since: sentAt, note: isLate ? 'not confirmed received' : undefined })
    } else if (isMidTurn(entry)) {
      const w = entry.waiting_on
      const stale = w && now - (w.at ?? now) > HOLD_STALE_MS
      rows.push({ key, role, state: 'working', since: lastReceivedAt(entry), note: w ? `${w.n} agent(s) still running, turn end held${stale ? ` ${ago(now - w.at)} — stale, read that pane` : ''}` : undefined })
    } else if (entry.last_turn_end_at) {
      rows.push({ key, role, state: 'ended', since: entry.last_turn_end_at, note: [entry.last_turn_reason, qaNote].filter(Boolean).join(' · ') || undefined })
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
    // The applied harness version, for an owner who runs several projects and needs to see at a
    // glance which one is behind (owner's ask, 2026-10-10).
    let version = ''
    try { version = (await $.fs.read(`${root}/.astraler/state/applied-version`)).trim() } catch {}
    await update($, banner, b => ({ ...b, branch, extra, version, latest: b.latest ?? '' }))
  }
}

// The second delivery path for a turn end (see turn.complete on the dispatched side): an entry
// whose pane could not send its TURN-END has it in the record, and the dispatcher's own mod
// submits the same prompt from there, once. Measured latency bound: the 30 s poll.
async function wakeFromRecord($: any, root: string, bell: (text: string) => void): Promise<void> {
  const rec = (await readRecord($, root)) ?? {}
  const now = await $.clock.now()
  // EVERY session at the project root without a dispatched tab runs this poll, not only
  // Thomas's: a BA or Quick pane does too, and the first poll to see a bell stamps it rung for
  // all. Measured downstream 2026-10-23: a Builder's held-stale bell rang in the BA pane and
  // never reached Thomas. An entry names the session that briefed it; only that session rings
  // for it. A dispatcher whose socket is gone (a restart) no longer owns its entries, so any
  // root session rings for them, as before.
  const sock = await $.env.get('CLAUDE_CODE_MESSAGING_SOCKET')
  const self = sock ? `uds:${sock}` : null
  for (const [key, entry] of Object.entries(rec)) {
    const owner = typeof entry?.dispatcher === 'string' ? entry.dispatcher : null
    if (self && owner && owner !== self && owner.startsWith('uds:') && await exists($, owner.slice(4))) continue
    // A hold past the ceiling rings once, as its own reason. The pane that holds cannot ring
    // for itself: nothing fires in it while its agents stay silent.
    const w = entry?.waiting_on
    if (w && isLive(entry) && !w.stale_rung_at && now - (w.at ?? now) > HOLD_STALE_MS) {
      await patchRecord($, root, key, { waiting_on: { ...w, stale_rung_at: now } })
      const what = Array.isArray(w.what) && w.what.length ? ` (${w.what.join('; ')})` : ''
      bell(`${MARK} ${entry.role ?? 'agent'} ${key} has held its turn end for ${ago(now - w.at)} (reason=held-stale): ${w.n} agent(s) still running${what} and nothing from the pane since. A stuck pane and a quiet one look the same from here: read that pane, and steer it to stop waiting if its agents are gone.`)
    }
    const pending = entry?.turn_end_pending
    if (!pending || pending.woken_at) continue
    // An entry with a pending turn end and no pane is a stub a retired pane wrote back after
    // cleanup removed its lane (measured downstream, 2026-10-13: two bells after merge and
    // worktree removal, both undelivered because the dispatcher had restarted). Not a lane.
    if (!isLive(entry)) { await deleteRecordKey($, root, key); continue }
    const mark = parseMark(String(pending.text ?? ''))
    await patchRecord($, root, key, { turn_end_pending: { ...pending, woken_at: await $.clock.now() } })
    const role = entry.role ?? 'agent'
    bell(`${MARK} ${role} ${key} ended its turn (${mark?.reason ?? 'unknown'}) — read from the record: its TURN-END message was not delivered (${pending.reason}). A bell, not proof: verify by artifact before acting.\n\nIts last words:\n${mark?.body ?? ''}`)
  }
}

// Whether this session's main turn is running (turn.start … turn.complete). Module-level so
// the bell functions below are plain declarations, as the engine's reader requires.
let isBusy = false
// A CEILING ON A DISPATCHED PANE'S CONTEXT (4.0.4). Builders run the whole flow in one context
// and the engine's window is 1M, so nothing trimmed: measured on one project over one night,
// 4,800 Builder calls at a median 400–550k tokens of context each, 2.3B cache-read tokens
// against 2.4M of output — cost is calls × context, and context only grew. A turn that ends
// over the ceiling is compacted before the next one, keeping what the next phase needs. 300k,
// not 200k: the standing load (project files, contracts, tool schemas) is ~90k and is never
// compacted, context grows ~1.2k per call, so 200k leaves ~90 calls between compactions
// (eleven per thousand-call ticket); 300k leaves ~170 (five). Tune with ASTRAGENTIC_CONTEXT_CEILING.
let compactDue = false
let contextCeiling = 300_000
const COMPACT_INSTRUCTIONS = 'Keep, verbatim where short: the ticket id and its brief (acceptance criteria, validation commands, Base, write-set, Owned elsewhere), the phase you are in and which flow steps have run, the current branch and HEAD, open review findings not yet folded, the agent IDs of your subagents still running (after a compaction SendMessage reaches a subagent by ID, not by name — Claude Code 2.1.299), and anything you owe the handback. Drop test output, file contents you can re-read, and finished tool results.'

// Bells that arrived while the dispatcher's own turn was running (a gate pass, a picker
// waiting on the owner). Each would have become a turn of its own once the session went
// idle: the owner read a row of "still waiting" answers after sleeping through a picker
// (2026-10-12). They are flushed as one prompt when the turn ends.
const heldBells: string[] = []
function bell($: any, text: string): void {
  if (isBusy) {
    heldBells.push(text)
    $.ui.status(`${heldBells.length} bell(s) held until this turn ends`)
    return
  }
  void $.prompt.submit({ text })
}
function flushBells($: any): void {
  if (heldBells.length === 0) return
  const texts = heldBells.splice(0)
  // The status line stays until something replaces it: on nizzy (2026-10-20) "2 bell(s) held"
  // sat under an idle dispatcher for hours after the flush had delivered them.
  $.ui.status(undefined)
  const text = texts.length === 1 ? texts[0] : `${MARK} ${texts.length} turn ends arrived while you were busy; read them together.\n\n${texts.join('\n\n---\n\n')}`
  void $.prompt.submit({ text })
}

// The agents of this session that are still at work: a background review's sub-agents, a
// fork. A turn that ends while any of these runs is a pause, not a turn end worth a bell
// (measured downstream: two bells in a row that said "still waiting on code-review"). A team
// mate waiting for a message is `idle` and does not count.
async function liveAgents($: any): Promise<Array<{ description: string; status: string }>> {
  try {
    const list = await $.agent.list()
    return (list ?? []).filter((a: any) => a.status === 'pending' || a.status === 'running' || a.status === 'waiting')
  } catch {
    return []
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
  let dispatcherName = ''
  let isNoticeTurn = false
  // The dispatched pane's own red line: set when a TURN-END send fails, cleared by the next
  // one that lands. The footer status alone was missed for ten minutes (measured downstream).
  let undelivered = ''
  // The applied harness version, shown on every pane's band — not only the dispatcher's — so an
  // owner with several projects and many panes reads it wherever they look (2026-10-10).
  let appliedVersion = ''
  const sends = new Map<string, number>()

  on('session.start', async ($, e, next) => {
    root = await repoRoot($)
    me = await whoAmI($)
    if (root) { try { appliedVersion = (await $.fs.read(`${root}/.astraler/state/applied-version`)).trim() } catch {} }
    if (!me && root && appliedVersion) {
      void latestRelease($).then(async latest => {
        if (!isNewer(latest, appliedVersion)) return
        await update($, banner, b => ({ ...b, latest }))
        $.ui.status(`release ${latest} exists (this project applied ${appliedVersion}) — .astraler/astragentic.sh update says what changed`)
      }).catch(() => {})
    }
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
      // A toast, not the status line: the registration is a one-time fact, and the band's first
      // chip carries the role and key for as long as the pane lives (owner's ask, 2026-10-09).
      $.ui.toast(`${me.role} ${me.key} recorded (tab ${me.tab}, pane ${me.pane})`)
      await refreshFlow($, root, me.key)
      const envCeiling = Number(await $.env.get('ASTRAGENTIC_CONTEXT_CEILING'))
      if (Number.isFinite(envCeiling) && envCeiling >= 50_000) contextCeiling = envCeiling
      $.clock.every(15_000, async () => {
        if (!compactDue || isBusy) return
        try {
          const r = await $.session.compact({ instructions: COMPACT_INSTRUCTIONS })
          compactDue = false
          $.ui.status(r?.skip ? `compaction skipped (${String(r.skip)})` : `context compacted at the ${Math.round(contextCeiling / 1000)}k ceiling`)
        } catch {}
      })
    } else if (root) {
      await $.command.register({ name: 'dispatch-board', description: 'Show live dispatches in a pane' })
      await $.command.register({ name: 'tracker-refresh', description: 'Read the tracker counts on the band now' })
      await refreshBoard($, root, sends)
      void refreshTracker($, root)
      const at = root
      $.clock.every(30_000, async () => {
        await refreshBoard($, at, sends)
        await wakeFromRecord($, at, text => bell($, text))
      })
    }
    return next(e)
  })

  on('turn.start', ($, e, next) => {
    // Since Claude Code 2.1.299 this hook also hears subagents' and teammates' turns, told
    // apart by `agentId` (absent on the main loop). Only the main loop's turn holds bells: a
    // background subagent starting after the main turn ended would otherwise hold every bell
    // until the next main turn completed.
    if ((e as any).agentId !== undefined) return next(e)
    isBusy = true
    // A dispatched pane that starts a turn is working: whatever it held at its last turn end
    // is over. The hold was left standing through the turns that followed, so the dispatcher's
    // ceiling read a pane committing every few minutes as stuck, twice, naming review agents
    // long finished (measured downstream, 2026-10-14).
    if (me && me.role !== 'resident' && root) {
      void (async () => {
        const own = ((await readRecord($, root!)) ?? {})[me!.key]
        if (own?.pane_id === me!.pane && own.waiting_on) {
          await patchRecord($, root!, me!.key, { waiting_on: null })
          $.ui.status(undefined)
          await refreshFlow($, root!, me!.key)
        }
      })().catch(() => {})
    }
    return next(e)
  })

  // A dispatched pane reads its role's overlay; any other Claude session in the repo is the
  // dispatcher's and reads `thomas.md`. The section is `session`-scoped: after the cache
  // boundary, so a project's text never breaks the shared prefix.
  on('prompt.compose', async ($, e, next) => {
    const res = await next(e)
    if (!root) return res
    let text = await overlay($, root, me?.role ?? 'thomas')
    const off = await armOff($, root)
    const scope = me ? ARM_SCOPE_BY_ROLE[me.role] : undefined
    if (me && scope && off.has(scope)) {
      text = `${text ? text + '\n\n' : ''}ARM: off — .agents/orchestrator.md § Cross-vendor arm has \`${scope}: no\`. Skip the arm phase at ${scope} scope: no codex-arm call, no \`arm(${scope}):\` receipt, and do not pass --marker 'arm(${scope})' to check-simplify-markers.sh. Write \`Arm: off (orchestrator)\` where the handback would cite the receipt.`
    } else if (!me && off.size > 0) {
      // The dispatcher runs the marker check at merge and fires the slice arm: it has to know
      // every scope that is off, not only its own, or it STOPs a merge for a receipt never owed.
      const scopes = ['ticket', 'spec', 'slice'].filter(s => off.has(s))
      text = `${text ? text + '\n\n' : ''}ARM: off at ${scopes.join(', ')} — .agents/orchestrator.md § Cross-vendor arm. ${scopes.map(s => `Do not pass --marker 'arm(${s})' at merge and expect no arm(${s}): receipt; the handback says Arm: off (orchestrator)`).join('. ')}${off.has('slice') ? '. Fire no slice arm; the ten-merge count does not apply' : ''}.`
    }
    // A QUICK TICKET'S SHAPE REACHES THE PANE AS A SECTION (4.6.0), from the record the gates
    // read, so the Builder and its band agree on what is owed; the dispatcher's copy lists the
    // live quick lanes so its merge does not STOP on a marker never owed.
    if (root) {
      const rec = (await readRecord($, root)) ?? {}
      if (me?.role === 'builder' && rec[me.key]?.kind === 'quick') {
        text = `${text ? text + '\n\n' : ''}KIND: quick — the tracker labels this ticket quick (builder.md § A quick ticket). Owed: the code, the project's existing tests run green, the built-in code-review (Skill(skill: "code-review"), findings folded), commit, push, handback. Not owed, and the pane's gates are set so: tdd, astra-review, astra-ui, simplify, the arm; write no simplify(increment) or arm(ticket) marker. If the work reaches past the label (a risky path, logic only a test would catch, more files than the project's ceiling), say so in the handback and stop: Thomas relabels it full.`
      } else if (!me) {
        const live = Object.entries(rec).filter(([, en]) => en?.role === 'builder' && isLive(en) && !en.worktree_removed_at)
        const quick = live.filter(([, en]) => en.kind === 'quick').map(([k]) => k)
        const noSimplify = live.filter(([, en]) => en.kind !== 'quick' && en.simplify_na).map(([k]) => k)
        if (quick.length > 0) text = `${text ? text + '\n\n' : ''}QUICK LANES: ${quick.join(', ')} — labelled quick on the tracker. At their merge pass no --marker 'simplify(increment)' and no --marker 'arm(ticket)' to check-simplify-markers.sh; the record's built-in code-review is the gate. A handback that says the work outgrew the label: relabel full and re-brief.`
        if (noSimplify.length > 0) text = `${text ? text + '\n\n' : ''}SIMPLIFY: n/a LANES: ${noSimplify.join(', ')} — their briefs exempt simplify; at their merge pass no --marker 'simplify(increment)'.`
      }
    }
    if (me && me.role !== 'resident' && dispatcher) {
      // The one address a written reply may go to, in the pane's own words: the role name is
      // not an address, and another project's session may carry it.
      const who = dispatcherName ? `${dispatcherName} (${dispatcher})` : dispatcher
      text = `${text ? text + '\n\n' : ''}Your dispatcher is the session ${who}. A written reply goes there and nowhere else: SendMessage to any other name is readdressed to it. "thomas" is a role, not an address.`
    }
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
      if (rec[mark.key]?.pane_id !== mark.pane) {
        // A TURN-END from a lane the record no longer holds — its worktree removed, its entry
        // reaped — read as live work when it fell through here as a plain message (measured
        // downstream: a recap bell after merge and tab close, 2026-10-12). A RECEIVED from an
        // unknown pane still passes through, so a mis-keyed brief is seen.
        if (mark.kind === 'TURN-END') {
          $.ui.status(`a turn end from ${mark.key} (pane ${mark.pane}) arrived after its lane was retired — dropped`)
          return { consumed: `astragentic-dispatch: ${mark.key} turn end from a retired lane` }
        }
        return next(e)
      }
      sends.delete(env.fromName)
      if (mark.kind === 'RECEIVED') {
        await patchRecord($, root, mark.key, { session_name: env.fromName, acked_at: await $.clock.now() })
        await refreshBoard($, root, sends)
        return { consumed: `astragentic-dispatch: ${mark.key} confirmed receipt` }
      }
      await refreshBoard($, root, sends)
      if (rec[mark.key]?.turn_end_pending) await patchRecord($, root, mark.key, { turn_end_pending: null })
      const role = rec[mark.key]?.role ?? 'agent'
      bell($, `${MARK} ${role} ${mark.key} ended its turn (${mark.reason}). A bell, not proof: verify by artifact before acting.\n\nIts last words:\n${mark.body}`)
      return { consumed: `astragentic-dispatch: ${mark.key} turn end handed to the dispatcher` }
    }

    if (env.inner.startsWith(MARK)) return next(e)
    dispatcher = env.from
    dispatcherName = env.fromName
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
    // `SIMPLIFY: n/a — <why>` (4.6.0): the one-pass simplify is not owed; the merge gate reads it.
    const simplifyNa = isBriefText ? unfenced.match(/^[ \t]*SIMPLIFY[ \t]*:[ \t]*n\/a\b[^\n]*/im)?.[0]?.trim() ?? null : undefined
    // UX IS OWED OR IT IS NOT (4.5.3). The ux step was "optional" and its chip dim `· ux`, which
    // reads as waiting (one downstream ticket, 2026-10-26: the owner asked why the Builder skipped
    // UX on a ticket with no UI). The brief's FLOW line already says: it names `astra-ui` on a UI
    // ticket and omits it otherwise; `UX: n/a — <why>` says no out loud. Owed → a required chip;
    // not owed → a grey `n/a ux`; a brief with no FLOW line says nothing and the chip is dropped.
    const flowLine = isBriefText ? unfenced.match(/^[ \t]*FLOW[ \t]*:[^\n]*(?:\n[ \t]+[^\n]*)*/im)?.[0] ?? null : null
    const uxNa = isBriefText ? /^[ \t]*UX[ \t]*:[ \t]*n\/a\b/im.test(unfenced) : false
    const uxOwed = isBriefText ? (uxNa ? false : flowLine === null ? null : /\bastra-ui\b/.test(flowLine)) : undefined
    // `QA: walk|probe|verify|none — <why>` on a Builder's brief is the dispatcher's declaration of
    // what the station owes this ticket before merge; `Mode: walk|probe|verify` on a QA brief is
    // which of the three the pane runs. Both are read here, from the delivered brief only.
    const qaLine = isBriefText ? unfenced.match(/^[ \t]*QA[ \t]*:[ \t]*(walk|probe|verify|none)\b[^\n]*/im) : null
    const qaPlan = isBriefText ? unfenced.match(/^[ \t]*QA plan[ \t]*:[ \t]*(\S+)/im)?.[1] ?? null : undefined
    const qaRequired = qaLine ? qaLine[1]?.toLowerCase() ?? null : undefined
    const qaMode = isBriefText ? unfenced.match(/^[ \t]*Mode[ \t]*:[ \t]*(walk|probe|verify)\b/im)?.[1]?.toLowerCase() ?? null : undefined
    if (root) {
      // A STEER IS NOT A BRIEF (4.5.4). `last_brief_received_at` was stamped on every inbound
      // message, and the tdd-order gate reads it as "the brief": a plain steering message after
      // the first content commit moved the mark past that commit, and the next commit was asked
      // for a fresh tdd call and a fresh red run (one downstream ticket, 2026-10-26: TDD done at
      // 19:39, steer at 21:50, a forced second tdd cycle at 21:56). The brief mark moves only on
      // a brief; `last_message_received_at` is what the board's "working since" reads.
      const patch: Entry = { dispatcher: env.from, dispatcher_name: env.fromName, last_message_received_at: now }
      if (isBriefText) {
        patch.last_brief_received_at = now
        patch.tdd_na = tddNa; patch.review_na = reviewNa; patch.ux_owed = uxOwed; patch.simplify_na = simplifyNa
        // a new brief starts the tdd question over: the stamp of the previous brief's red run goes too (5.0.0)
        if (me.role === 'builder') { patch.qa_required = qaRequired; patch.qa_plan = qaPlan; patch.first_content_commit_at = null; patch.red_run_at = null }
        if (me.role === 'qa') patch.qa_mode = qaMode
      }
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
  // names (tdd → ux → both reviews → simplify) is read from what ran, not from what the handback
  // says ran. Measured downstream before this existed: implement 44/44, tdd 0/44. A fork's
  // call is recorded under the Builder too, which is the same attribution git gives it.
  // Writes are chained: two skills expanding in one turn (a fork's beside the Builder's) would
  // otherwise read the same map and the second write would erase the first (found by the
  // 2.18.0 gate).
  let skillWrites: Promise<void> = Promise.resolve()
  on('skill.prompt', async ($, e, next) => {
    if (me && me.role !== 'resident' && root) {
      const { key } = me
      const at = root
      skillWrites = skillWrites.then(async () => {
        const entry = ((await readRecord($, at)) ?? {})[key] ?? {}
        const prior = entry.skills_run ?? {}
        const now = await $.clock.now()
        const patch: Entry = { skills_last: { ...(entry.skills_last ?? {}), [e.skill]: now } }
        patch.skills_log = [...skillsLog(entry), { skill: e.skill, at: now }].slice(-400)
        if (!(e.skill in prior)) {
          // Where the skill came from, beside when it ran (Claude Code 2.1.299 carries source,
          // plugin and path on the event). A field audit counted a skill at 0 because the pane
          // had read its SKILL.md instead of calling it; the source column tells those apart.
          const ev: any = e
          const from = [ev.source, ev.pluginName, ev.path].filter(Boolean).join(':')
          const sources = { ...(entry.skills_source ?? {}), ...(from ? { [e.skill]: from } : {}) }
          patch.skills_run = { ...prior, [e.skill]: now }; patch.skills_source = sources
        }
        await patchRecord($, at, key, patch)
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
      flushBells($)
      return res
    }
    const usage = await $.session.usage().catch(() => null)
    if ((usage?.context?.tokens ?? 0) >= contextCeiling) compactDue = true
    // Every turn after the first brief is reported, so a Builder that backgrounds its work and
    // finishes it in a later turn (measured: the result came one turn after the "done") is
    // still heard. Turns that only read a cross-session delivery notice are skipped; reporting
    // those woke the dispatcher three times for one task.
    const isSkipped = isNoticeTurn
    isNoticeTurn = false
    if (isSkipped) return res
    // A turn that ends while this pane's own agents still run is a pause. The built-in
    // code-review and a backgrounded Agent call end the main turn and wake it again per
    // notification; each wake ended in a bell that said "still waiting" (measured downstream, 2026-10-12).
    // The record notes what is waited on, the board shows it, and the one TURN-END goes when
    // the first turn ends with nothing live. An aborted or errored turn is sent as it is.
    if (e.reason === 'answer' && me.role !== 'resident') {
      const live = await liveAgents($)
      if (live.length > 0) {
        if (root) {
          await patchRecord($, root, me.key, { waiting_on: { n: live.length, at: await $.clock.now(), what: live.slice(0, 3).map(a => a.description) } })
          await refreshFlow($, root, me.key)
        }
        $.ui.status(`${live.length} agent(s) still running — TURN-END held until they finish`)
        return res
      }
    }
    // The lane is retired when its entry has left the record (cleanup) or names another pane:
    // writing here would recreate a stub entry, and the turn end would reach the dispatcher as
    // a recap of finished work (measured downstream, 2026-10-13).
    if (root && me.role !== 'resident') {
      const own = ((await readRecord($, root)) ?? {})[me.key]
      if (own?.pane_id !== me.pane) {
        $.ui.status(`${me.key} is no longer in the record (lane retired) — turn end not reported`)
        return res
      }
    }
    if (!dispatcher) {
      // No address: the brief did not come through the mod (a held delivery, a brief typed in
      // by `herdr agent prompt`). Measured downstream: a gate pane in auto mode ended its turn
      // and nothing reached the dispatcher for minutes. The record is the path that needs no
      // address; the dispatcher's poll wakes from it.
      if (root && me.role !== 'resident') {
        await patchRecord($, root, me.key, { last_turn_end_at: await $.clock.now(), last_turn_reason: e.reason,
          turn_end_pending: { at: await $.clock.now(), reason: 'no dispatcher address (brief did not arrive through the mod)', text: `${MARK} TURN-END key=${me.key} pane=${me.pane} reason=${e.reason}\n${e.answer.slice(-1500)}` } })
        await refreshFlow($, root, me.key)
      }
      return res
    }
    if (root) {
      await patchRecord($, root, me.key, { last_turn_end_at: await $.clock.now(), last_turn_reason: e.reason, waiting_on: null })
      await refreshFlow($, root, me.key)
    }
    // A QA pane's entry goes with its worktree at cleanup, so the fact that QA ended a turn is
    // also written onto the ticket's own entry (`qa:<key>` → `<key>`), where the owed check and
    // the board read it after the QA pane is gone (found by the 3.0.0 gate).
    if (root && me.role === 'qa' && me.key.startsWith('qa:')) {
      const own = ((await readRecord($, root)) ?? {})[me.key] ?? {}
      await patchRecord($, root, me.key.slice(3), { qa_last_turn_end_at: await $.clock.now(), qa_last_mode: own.qa_mode ?? null })
    }
    const answer = e.answer.length > 1500 ? `…${e.answer.slice(-1500)}` : e.answer
    let flow = ''
    if (me.role !== 'resident' && root) {
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
      $.ui.status(`TURN-END not delivered — ${sent.reason}; recorded for the dispatcher to pick up`)
      if (root) await patchRecord($, root, me.key, { turn_end_pending: { at: await $.clock.now(), reason: String(sent.reason ?? ''), text } })
    }
    return res
  })

  // ---- dispatcher side -------------------------------------------------------------------

  on('session.send', async ($, e, next) => {
    // A dispatched pane's own written reply goes to its dispatcher, whatever name the model
    // typed. The cross-session namespace is flat across projects: a Builder answered its
    // dispatcher's question by sending to "thomas", and another project on the machine ran a
    // session named exactly that, which received it (measured downstream, 2026-10-12). The
    // pane knows its dispatcher's address from the brief's envelope; a send to any other name
    // that no agent of this session carries (a team mate's name still routes) is readdressed.
    if (me && me.role !== 'resident' && dispatcher && e.origin.kind === 'model' && e.agentId === undefined
        && e.to !== dispatcher && addressName(e.to) !== dispatcherName) {
      const to = addressName(e.to)
      // THE PANE'S OWN FORKS ARE ITS AGENTS (4.3.1). A Skill fork is addressed by its NAME and a
      // short ref ("code-review [ce2df1]"); this test knew ids and teammate ids only, so a
      // Builder's "report your findings" to its own code-review fork went to the dispatcher,
      // twice, and the review round was lost (measured downstream 2026-10-22). The name, the id,
      // and the ref against the id all say "mine".
      const ref = (e.to.match(/\[([0-9a-f]{4,})\]\s*$/i)?.[1] ?? '').toLowerCase()
      const mine = await $.agent.list().catch(() => [])
      const isAgent = (mine ?? []).some((a: any) => {
        const id = String(a.id ?? '')
        return id === to || a.name === to || a.teammateId === to || a.teammateId?.split('@')[0] === to
          || (ref !== '' && id.toLowerCase().includes(ref))
      })
      if (!isAgent) {
        $.ui.status(`message to "${e.to}" went to the dispatcher (${dispatcherName || dispatcher}) instead — a pane's sends reach its dispatcher and its own agents only`)
        return next({ ...e, to: dispatcher })
      }
    }
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
      // BUILDER-TARGET IS READ HERE, NOT BY THOMAS (4.1.0). `orchestrator.md` has carried the row
      // since 2.x and no code read it: the first adopter's Thomas counted lanes by hand at every
      // merge (field audit 2026-10-18, §4). A Builder brief is refused while as many Builders are
      // live as the row allows; a live Builder is a recorded entry with a pane that has not been
      // merged or had its worktree removed. Absent row: 4, as thomas.md has always said.
      if (/^\/astra-implement-with-tdd\b/.test(first)) {
        const target = Number(orch.match(/^\|\s*builder-target\s*\|\s*`?(\d+)`?\s*\|/m)?.[1] ?? 4)
        const rec0 = (await readRecord($, root)) ?? {}
        // The destination pane registered itself before this brief (that is the protocol), so
        // its own entry is not one of the lanes the brief competes with; nor is a retry to it.
        // The arm's probe: target 1 refused the first Builder its first brief (4.1.0 pass 2).
        const dest = first.split(/\s+/).slice(1).find(w => TICKET.test(w))
        const live = Object.entries(rec0).filter(([k, en]) => k !== dest && en?.role === 'builder' && isLive(en) && !en.merged_at && !en.worktree_removed_at && !k.startsWith('qa:'))
        if (live.length >= target) {
          return {
            isDelivered: false,
            reason: `${MARK} not sent. ${live.length} Builder(s) are live (${live.map(([k]) => k).join(', ')}) and builder-target in .agents/orchestrator.md is ${target}. Merge or retire one, or raise the row, then send this brief again.`,
          }
        }
      }
      // The claim check is a BUILDER brief's: the ticket is the argument of `implement`. A Shaper
      // brief whose first line merely names the tickets it plans for was refused on one of them
      // (measured downstream, 3.0.0's first day), so the role is read from the command, not the
      // id from any word.
      const isBuilderBrief = /^\/astra-implement-with-tdd\b/.test(first)
      const id = isBuilderBrief ? first.split(/\s+/).slice(1).find(word => TICKET.test(word)) : undefined
      const ts = id ? await trackerState($, root, id) : null
      if (id && ts && (ts.assignee === '-' || ts.assignee === '' || /^(closed|done|unclaimed)$/i.test(ts.state))) {
        return {
          isDelivered: false,
          reason: `${MARK} not sent. The tracker says ${id} is "${ts.line}", so it is not claimed. ` +
            `Claim it first (thomas.md § The claim protocol: assignee written and read back; status or label per ` +
            `docs/agents/issue-tracker.md), then send this brief again.`,
        }
      }
      // THE KIND IS READ HERE AND WRITTEN ON THE RECORD BEFORE THE BRIEF GOES (4.6.0). The
      // pane's gates and band read `kind` from its own entry, and that entry exists already (the
      // pane registered itself first, that is the protocol), so a patch before the send is
      // never a write the pane's own registration overwrites. The enforcing reader (the
      // project's plug) sends an unlabelled ticket back to whoever cut it; the informing one
      // (the package's, Jira through twg) only sets what it finds.
      if (id) {
        const tl = await trackerLabels($, root, id)
        const kind = tl ? kindOf(tl.labels) : null
        if (tl?.enforcing && kind === null) {
          return {
            isDelivered: false,
            reason: `${MARK} not sent. ${id} carries neither the \`quick\` nor the \`full\` label (.astraler/project/tracker-labels.sh says: ${tl.labels.join(' ') || 'no labels'}). ` +
              `The label is written by whoever cut the ticket (Shaper at to-tickets, or the BA) with its three evidence lines — risky paths touched, how a defect would be seen, files the ticket's words reach — and a ticket without it goes back there (thomas.md § Quick or full). Never classify it here.`,
          }
        }
        await patchRecord($, root, id, { kind })
      }
    }
    // NO QA PLAN, NO DISPATCH — the owner's rule (2026-10-10), replacing the payload's earlier
    // default where QA inferred a plan and capped its verdict at CONCERNS. A Builder brief
    // carries `QA: walk|probe|verify|none — <why>` and, unless none, `QA plan: <path>` naming a
    // committed docs/qa/plan-*.md that exists in this checkout. A loose ticket with no spec gets
    // its plan from test-design run over its acceptance criteria; a ticket with no surface gets a
    // plan line saying none. The gate is here because the brief is the one moment every dispatch
    // passes through.
    if (!me && root && e.origin.kind === 'model' && e.agentId === undefined && /^\/astra-implement-with-tdd\b/.test(first)) {
      const body = e.text.replace(/```[\s\S]*?```/g, '')
      const qa = body.match(/^[ \t]*QA[ \t]*:[ \t]*(walk|probe|verify|none)\b/im)?.[1]?.toLowerCase()
      const plan = body.match(/^[ \t]*QA plan[ \t]*:[ \t]*(\S+)/im)?.[1]?.replace(/^['"`]|['"`]$/g, '')
      if (!qa) {
        return { isDelivered: false, reason: `${MARK} not sent. The brief carries no "QA: walk|probe|verify|none — <why>" line. Every Builder brief declares what the station owes the ticket before merge (dispatch-ticket-claude § The station owes QA).` }
      }
      if (qa !== 'none') {
        if (!plan) {
          return { isDelivered: false, reason: `${MARK} not sent. QA: ${qa} is declared but no "QA plan: docs/qa/plan-<slug>.md" line names the plan. No QA plan, no dispatch: run test-design over the spec, or over the ticket's acceptance criteria when it has no spec, commit the plan, then send this brief again.` }
        }
        const planPath = plan.startsWith('/') ? plan : `${root}/${plan}`
        if (!(await exists($, planPath))) {
          return { isDelivered: false, reason: `${MARK} not sent. QA plan: ${plan} does not exist in this checkout. Commit the plan test-design wrote, then send this brief again.` }
        }
      }
      // A UI TICKET CARRIES GLANCE, STATES AND CRITERIA (5.0.0). The brief's FLOW line naming
      // `astra-ui` is the dispatcher's own declaration that a surface changes; the three sections
      // are what the Builder, the UI pass and QA's walk read (astra-to-tickets § Write each
      // ticket). The mod sees the brief, never the tracker, so `dispatch-ticket` pastes them.
      // Measured on the first adopter before this existed: 101 of 202 UI tickets skipped the UI
      // pass and nobody saw it; 65 of 209 UI merges were corrections of an earlier UI merge.
      const flowDecl = body.match(/^[ \t]*FLOW[ \t]*:[^\n]*(?:\n[ \t]+[^\n]*)*/im)?.[0] ?? ''
      if (/\bastra-ui\b/.test(flowDecl)) {
        const missing = ['## Glance', '## States', '## Criteria'].filter(h => !new RegExp(`^[ \\t]*${h}\\b`, 'm').test(body))
        if (missing.length > 0) {
          return { isDelivered: false, reason: `${MARK} not sent. FLOW names astra-ui (a UI ticket) and the brief lacks ${missing.join(', ')}. A UI ticket carries Glance, States and Criteria (astra-to-tickets § Write each ticket): paste the ticket's three sections into the brief, or send the ticket back to the Shaper to add them.` }
        }
      }
    }
    const isBrief = !me && root && e.origin.kind === 'model' && e.agentId === undefined && first.startsWith('/')
    const brief = isBrief && root ? await overlay($, root, 'dispatch-brief') : ''
    const res = await next(brief ? { ...e, text: `${e.text.trimEnd()}\n\n${brief}` } : e)
    // The role goes on the record at dispatch, not only when the pane registers itself: a field
    // audit found 129 of 131 entries without one (stubs the dispatcher's own patches created
    // before any pane wrote), so lanes could not be counted by role (4.1.0).
    if (isBrief && root && res.isDelivered) {
      const builderId = /^\/astra-implement-with-tdd\b/.test(first) ? first.split(/\s+/).slice(1).find(w => TICKET.test(w)) : undefined
      if (builderId) {
        await patchRecord($, root, builderId, { role: 'builder', dispatched_at: await $.clock.now() })
        void refreshTracker($, root)
      }
    }
    if (me || !root || e.origin.kind !== 'model' || e.agentId !== undefined || !res.isDelivered) return res
    const rec = (await readRecord($, root)) ?? {}
    const to = addressName(e.to)
    const isKnown = Object.values(rec).some(entry => entry?.session_name === to)
    if (isKnown || e.text.trimStart().startsWith('/')) {
      sends.set(to, await $.clock.now())
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

  // A dispatched pane waits by ending its turn, never by scheduling one. Measured downstream
  // (2026-10-27): 3 of 4 Builder panes backgrounded a job (an audit fork, the built-in review,
  // the arm) and called ScheduleWakeup to wait for it — the call refused (`prompt` is required
  // outside /loop), the wait never came, and one pane kept a 30-minute heartbeat ringing after
  // its handback. No harness role runs /loop. `stop: true` passes so an armed heartbeat can be
  // turned off.
  on('tool.call', { tool: 'ScheduleWakeup' }, async ($, e, next) => {
    if (!me || me.role === 'resident') return next(e)
    const ev: any = e
    if (ev.stop === true || ev.input?.stop === true) return next(e)
    return {
      deny: `astragentic-dispatch: a dispatched pane (${me.role} ${me.key}) does not schedule its own wakeups. To wait on a fork or sub-agent, end the turn: your TURN-END is held while any agent of yours runs, and the agent's completion re-invokes you. A backgrounded shell job is not an agent and does not hold the turn — run gates in the foreground. Nothing here is a /loop.`,
    }
  })

  // THE TWO GATES. Measured on the first two real dispatches after the FLOW line shipped: one
  // Builder skipped tdd, the other skipped the built-in review, and neither named n/a. A note at
  // merge made the skip visible; it did not make it impossible. So the skip is refused at the
  // moment it becomes real — the first commit with content, and the arm — and the dispatcher's
  // exemption is read from the brief, never from the Builder's own handback.
  // COMMANDS A DISPATCHED PANE MUST NEVER RUN — the project's list, refused here (4.0.3).
  // `.astraler/project/refused-in-dispatched-panes`: one regex per line, `#` comments, tested
  // against the whole command text of every Bash call a Builder, Shaper or QA pane makes. The
  // owner's resident pane is not a dispatched pane and keeps every command. Measured downstream:
  // a Builder ran `make db-down` after its tests and stopped the machine-wide shared test
  // Postgres (AST-115 guarded the cleanup path, not an agent mid-ticket); the only defence was
  // a sentence in a brief, which the Builder generalised the wrong way.
  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    if (!me || !root || me.role === 'resident') return next(e)
    const plug = `${root}/.astraler/project/refused-in-dispatched-panes`
    // A `# reason:` line directly above a pattern is the refusal's text instead of the default (a
    // marker, so a project's existing comments keep their meaning): a project that lists its
    // whole-suite test command (the station runs it) is not refusing something shared, and "the
    // owner runs it" sent the Builder the wrong way (one downstream ask, 2026-10-22).
    let reason = ''
    for (const line of (await overlayFile($, plug)).split('\n').map(l => l.trim())) {
      if (!line) { reason = ''; continue }
      if (line.startsWith('#')) { reason = line.match(/^#+\s*reason:\s*(.+)$/i)?.[1] ?? ''; continue }
      const pat = line, why = reason
      reason = ''
      let re: RegExp
      try { re = new RegExp(pat, 'm') } catch { continue }
      if (re.test(e.command)) {
        await logRefusal($, root, me.key, 'refused-command', `${pat} :: ${e.command.slice(0, 120)}`)
        return { deny: why
          ? `astragentic-dispatch: this command matches "${pat}" in .astraler/project/refused-in-dispatched-panes — ${why}`
          : `astragentic-dispatch: this command matches "${pat}" in .astraler/project/refused-in-dispatched-panes — a command the project refuses in a dispatched pane (it touches something shared beyond your worktree). Say in your handback what you wanted it for; the owner runs it from a resident pane if it is needed.` }
      }
    }
    return next(e)
  })

  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    if (me?.role !== 'builder' || !root) return next(e)
    // Every simple command in the call, heredoc bodies included; a commit is a content commit
    // unless that same command carries `--allow-empty` as a whole word (a marker). One exempt
    // commit never exempts another in the same call.
    const entry = ((await readRecord($, root)) ?? {})[me.key] ?? {}
    const worktree = typeof entry.worktree === 'string' && entry.worktree ? entry.worktree : null
    const command = dropFdDups(literalCatHeredocs(e.command))
    const commits = worktree
      ? commitsInWorktree(command, worktree)
      : simpleCommands(command).map(gitCommitArgs).filter((c): c is { args: string[]; dir: string | null } => c !== null).map(c => c.args)
    const contentCommits = commits.filter(a => !a.includes('--allow-empty'))
    if (contentCommits.length === 0) return next(e)
    // A QUICK TICKET OWES NO TEST (4.6.0): its kind came from the tracker's label, written on the
    // record by the dispatcher before the brief went (see trackerLabels).
    if (entry.tdd_na || entry.kind === 'quick') return next(e)
    // THE GATE MEASURES A TEST, NOT A SKILL CALL (4.1.0). Until then it asked whether
    // the tdd skill had been called; measured on the first adopter, 48 refusals, 48
    // skill calls right after, and a test file edited before the next commit in 2. So it now
    // asks git: is a test file staged for this commit, or already on this branch since the
    // dispatch? The pattern is the project's (`.astraler/project/test-file-pattern`, one regex)
    // or the default below; `TDD: n/a — <why>` on the brief still exempts the ticket.
    const testRe = await testFileRe($, root)
    const cwd = worktree ?? root
    // ONE diff: the index (the tree this commit will make) against the dispatch base, added /
    // copied / modified / renamed only. It answers "will the branch carry a test file the base
    // did not" for the tree as it is about to be committed, so a test committed after dispatch
    // and staged for deletion in this commit is not there (the arm's pass-3 probe: two lists
    // joined let that through), and a deleted test is not a test (pass 2). No base recorded:
    // the index against HEAD.
    const base = typeof entry.start_sha === 'string' && entry.start_sha ? entry.start_sha : 'HEAD'
    const shape = commitShape(command, contentCommits[0] ?? [], worktree)
    // Boundaries this gate does not model, said plainly instead of guessed (arm pass 6): a call
    // that moves, restores, resets or checks out BEFORE committing changes the working tree or
    // HEAD, which a scratch index cannot replay without doing it for real; two content commits in
    // one call would need the first to exist before the second is judged; a directory the call
    // changes into that this hook cannot resolve. Each is one refusal with the split to make.
    const refuse = async (why: string, how: string) => {
      await logRefusal($, root, me.key, 'tdd-gate', `${why}: ${contentCommits[0]?.join(' ') ?? ''}`)
      return { deny: `astragentic-dispatch: ${why}. ${how}` }
    }
    if (shape.unsafe === 'a command substitution') return refuse('this call runs a command substitution in or before its commit, which the gate cannot replay', "Put the message in a file and commit with `git commit -F <file>`, or pass it as `-m '…'`; `-m \"$(cat <<'EOF' … EOF)\"` with a quoted tag and `cat` alone is read as the message.")
    if (shape.unsafe) return refuse(`this call runs ${shape.unsafe} before its commit, which changes the working tree or HEAD (or names paths the gate cannot read)`, 'Run that step as its own call, then commit in the next one, so each is judged as it stands; `git rm --cached` is the one removal the gate can replay.')
    if (shape.commits > 1) return refuse('this call makes more than one content commit', 'One content commit per call: the gate judges the tree each commit makes, and the second does not exist yet.')
    if (shape.dir === null || shape.steps.some(s => s.dir === null)) return refuse('this call changes into a directory the gate cannot resolve before committing', 'Use a literal path (no variable, `~` or `cd -`), or commit from the worktree root.')
    const lines = (r: { out: string }) => r.out.split('\n').filter(Boolean)
    const realIndex = (await run($, ['git', 'rev-parse', '--git-path', 'index'], 15_000, cwd)).out
    // A private directory outside the working tree, one per call: a scratch index inside the
    // worktree was a file a concurrent `git add -A` could stage (arm pass 7).
    const tmpd = (await run($, ['mktemp', '-d', '-t', 'astragentic-tdd-gate'], 10_000)).out
    if (!tmpd.startsWith('/')) return refuse('the gate could not allocate a scratch directory', 'Retry the commit; if this persists, the temp directory is unwritable.')
    const scratch = `${tmpd}/index`
    const g = (argv: string[], dir: string) => run($, ['git', ...argv], 30_000, dir, { GIT_INDEX_FILE: scratch })
    const commitDir = shape.dir ?? cwd
    let willCarry: string[] = []
    try {
      if (shape.only && shape.paths.length === 0) {
        // `--only` with no paths (an amend form): HEAD's tree, the index ignored
        await g(['read-tree', 'HEAD'], commitDir)
      } else {
        // the effective index: the real one, with the call's earlier steps replayed; a step that
        // fails in replay fails for real too, and the gate says so rather than guess what follows
        await $.process.run(['cp', realIndex.startsWith('/') ? realIndex : `${cwd}/${realIndex}`, scratch], { timeoutMs: 10_000 })
        for (const step of shape.steps) {
          const [sub, ...args] = step.argv
          // no `--ignore-unmatch`: a removal of a path git does not know fails for real, and the
          // step after `&&` never runs, so the replay must fail there too (arm pass 9)
          const r = sub === 'rm'
            ? await g(['rm', '--cached', ...args], step.dir ?? cwd)
            : await g(['add', ...args], step.dir ?? cwd)
          if (r.code !== 0) return refuse(`a staging step in this call fails (\`git ${step.argv.join(' ')}\`: ${r.out.split('\n')[0] ?? ''})`, 'Run the staging step on its own and read its error, then commit.')
        }
        if (shape.paths.length > 0 && !shape.include) {
          // a path-limited commit: HEAD, plus the working-tree versions (deletions included) of
          // exactly the files the effective index KNOWS under the paths — an untracked file under
          // the path is not committed by git and must not be judged (arm pass 8)
          const eligible = lines(await g(['ls-files', '--full-name', '--', ...shape.paths], commitDir))
          await g(['read-tree', 'HEAD'], commitDir)
          if (eligible.length > 0) await g(['add', '-A', '--', ...eligible], cwd)
        } else {
          if (shape.all) await g(['add', '-u'], commitDir)
          if (shape.include && shape.paths.length > 0) await g(['add', '-A', '--', ...shape.paths], commitDir)
        }
      }
      willCarry = lines(await g(['diff', '--cached', '--name-only', '--diff-filter=ACMR', base], cwd))
    } finally {
      await $.process.run(['rm', '-rf', tmpd], { timeoutMs: 10_000 }).catch(() => {})
    }
    const hasTest = willCarry.some(p => testRe.test(p))
    if (hasTest) {
      // TDD IS ALSO AN ORDER (4.5.2, owner's ruling 2026-10-26). A test file beside the code
      // passed this gate while the tdd skill was called after the commit (one downstream
      // ticket: commit 12:19, tdd 12:25 after the dispatcher steered; 61 of 161 tickets). The
      // FIRST content commit after a brief needs a test run that went RED after that brief
      // (hook-test-run.py's log): a red run is what TDD is. 5.0.0 dropped the skill-name half
      // of this question — `astra-implement-with-tdd` is the brief's own expansion, so a call
      // after the brief would always be true and a call by any other name always false. Later
      // commits on the same brief are not asked again; `TDD: n/a` exempted the whole gate
      // above; a pane with no brief delivered through the mod has no "after the brief" to measure.
      const brief = typeof entry.last_brief_received_at === 'number' ? entry.last_brief_received_at : 0
      const seen = typeof entry.first_content_commit_at === 'number' ? entry.first_content_commit_at : 0
      if (brief > 0 && !(seen > brief)) {
        const redAt = await redRunAfter($, cwd, brief)
        if (redAt === null) {
          await logRefusal($, root, me.key, 'tdd-order', `first content commit with no RED test run since the brief: ${contentCommits[0]?.join(' ') ?? ''}`)
          return {
            deny: `astragentic-dispatch: this is the first content commit since the brief and no test run has gone RED since it (${await lastRunLine($, cwd, brief)}; log: ${testRunLogPath(cwd)}, written by the PostToolUse hook for go test / pytest / vitest / jest / npm test / cargo test …, or the project's .astraler/project/test-command-pattern). Run the failing test ALONE in the foreground — a test followed by \`;\`, \`|\` or a newline reports the other command's exit code and is logged masked — then commit; or ask the dispatcher for "TDD: n/a — <why>".`,
          }
        }
        await patchRecord($, root, me.key, { first_content_commit_at: await $.clock.now(), red_run_at: redAt })
      }
      return next(e)
    }
    await logRefusal($, root, me.key, 'tdd-gate', `content commit with no test file staged or on the branch: ${contentCommits[0]?.join(' ') ?? ''}`)
    return {
      deny: `astragentic-dispatch: no test file is staged for this commit or committed on this branch since dispatch (pattern: ${testRe.source}), and the brief declares no "TDD: n/a — <why>". A content commit before the red test is the defect this gate exists for: write the failing test, stage it with the change, then commit. A project whose tests live elsewhere names its pattern in .astraler/project/test-file-pattern; a ticket with no seam gets the TDD: n/a line from the dispatcher.`,
    }
  })

  // THE WAITER RULE. Four Builders in a row, two of them with the brief saying the rule in so
  // many words, waited on backgrounded work with a loop that cannot end: a name-keyed wait
  // (`until ! pgrep -f <name>` matches its own shell's argv; `until ! ps | grep <name>` matches a
  // sibling) or a body with no sleep (`do :; done` greps /dev/null at full CPU). Each parked the
  // pane for ten minutes and was found by a person. The shape is refused; the deny carries the
  // one-liner that works.
  const brokenWait = (cmd: string): string | null => {
    const c = cmd.replace(/\s+/g, ' ')
    if (/\buntil\s+!\s*(pgrep|ps\b)/.test(c) || /\b(until|while)\b[^;]*\bps\b[^;]*\|\s*grep/.test(c)) return 'a wait keyed on a process NAME (pgrep -f / ps | grep) matches its own shell or a sibling and never ends'
    if (/\b(until|while)\b[^\n]*?\bdo\s*(:|true)\s*;?\s*done/.test(c)) return 'a loop body with no sleep spins at full CPU'
    if (/\b(until|while)\b[^\n]*?\bdo\b(?:(?!\bdone\b)(?!\bsleep\b)(?!\bwait\b)(?!\bread\b).)*\bdone\b/.test(c) && /\b(until|while)\s+!?\s*(kill\s+-0|grep|test|\[)/.test(c)) return 'a polling loop with no sleep spins at full CPU'
    return null
  }
  const WAIT_FIX = 'Key the wait on the pid you launched: `cmd & pid=$!; while kill -0 $pid 2>/dev/null; do sleep 10; done; wait $pid`, or run it in the foreground with a timeout.'
  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    if (!me || me.role === 'resident' || !root) return next(e)
    const why = brokenWait(e.command)
    if (!why) return next(e)
    await logRefusal($, root, me.key, 'wait-gate', e.command.slice(0, 120))
    return { deny: `astragentic-dispatch: refused — ${why}. ${WAIT_FIX}` }
  })

  on('tool.call', { tool: 'Skill' }, async ($, e: any, next) => {
    if (me?.role !== 'builder' || !root) return next(e)
    if (!/^(codex-arm|codex-claude-arm)$/.test(String(e.skill ?? ''))) return next(e)
    const entry = ((await readRecord($, root)) ?? {})[me.key] ?? {}
    const ran = skillsRun(entry)
    if ('code-review' in ran || entry.review_na) return next(e)
    await logRefusal($, root, me.key, 'arm-gate', `arm requested: ${String(e.skill ?? '')}`)
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
    // `worktree` immediately followed by `add`, as words: a segment with `add` anywhere and
    // `worktree` anywhere matched `git worktree list` once (measured downstream on the apply
    // turn) and the path parse fell through to the first word, "git".
    const addSeg = simpleCommands(e.command).find(seg => {
      const w = shellWords(seg)
      const i = w.indexOf('worktree')
      return i >= 0 && w[i + 1] === 'add'
    })
    if (addSeg) {
      const ran = await next(e)
      // Not the call's exit status: `git worktree add … && herdr agent start …` in one call can
      // exit 1 on the LATER command with the worktree already created, and the plug then never
      // ran (measured downstream: a Builder found its worktree unseeded mid-ticket). What decides
      // is whether the worktree now exists at the parsed path.
      if (ran.deny !== undefined) return ran
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
      const addAt = w.indexOf('add', i)
      if (addAt < 0) return ran
      i = addAt + 1
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
      if (!(await exists($, wt))) return ran
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
    if (!merge) return next(e)
    const isPr = /\bgh\s+pr\s+merge\b/.test(e.command)
    // A PR merged on the remote never reaches the local base, so ancestry cannot see it.
    // Mark the entries the command names, by ticket id or by the PR's head branch.
    const pr = isPr ? e.command.match(/\bgh\s+pr\s+merge\s+(\S+)/)?.[1] : undefined
    const head = pr && !pr.startsWith('-')
      ? (await run($, ['gh', 'pr', 'view', pr, '--json', 'headRefName', '-q', '.headRefName'], 30_000)).out
      : ''
    // Whole-token matches only: `feature/foo` must not claim `gh pr merge feature/foo-fix`
    // (found by the 2.18.0 gate), and a ticket id must not match inside a longer one.
    const words = e.command.split(/\s+/)
    const named = Object.entries(rec).filter(([key, entry]) =>
      words.includes(key) || (head && entry?.branch === head) ||
      (typeof entry?.branch === 'string' && entry.branch.length > 0 && words.includes(entry.branch)))
    // THE RECORD IS THE EVIDENCE, AND IT REFUSES THE MERGE (4.0.2). Until now a merge whose
    // Builder pane recorded no run of a flow step got a NOTE after the fact, while the marker
    // script read the `Pass:` line in the commit — a line anyone can type. Measured downstream
    // (one downstream ticket, 2026-10-16): forged `Pass: Skill(simplify)` markers passed the marker gate and Thomas
    // caught them by reading this record by hand. So the merge is refused BEFORE it runs when
    // a pane the mod itself registered, and that recorded at least one skill, has a required
    // step with no record and no n/a line on its brief. A pane without the mod (a junior pane)
    // records nothing and keeps the marker script as its evidence; an entry with an empty
    // record (a dispatcher restart, a stub) is not judged either — a gate that fires on its own
    // missing data is noise, and the note below still names the gap.
    // TDD IS A TEST FILE, AT MERGE AS AT COMMIT (4.1.3). 4.1.0 made the commit gate ask git for a
    // test file and left this gate asking the record for the tdd skill; measured
    // downstream (one ticket, 2026-10-22): 5 content commits each carrying test files passed the commit
    // gate, then the merge was refused "no record of: tdd" after the whole build cycle. One
    // question, asked twice: a test file on the branch since the dispatch base, or `TDD: n/a`.
    const mergeGaps = async (entry: Entry, ref: string): Promise<string[]> => {
      const out: string[] = []
      // A QUICK TICKET (4.6.0, the tracker's label) owes the built-in code-review and nothing
      // else here; `SIMPLIFY: n/a` on the brief exempts simplify alone.
      const quick = entry.kind === 'quick'
      for (const label of flowGaps(entry)) {
        if (label === 'built-in code-review' && entry.review_na) continue
        if (label === 'simplify' && (quick || entry.simplify_na)) continue
        if (label === 'astra-review' && quick) continue
        if (label === 'tdd') {
          if (entry.tdd_na || quick) continue
          const carries = await branchCarriesTest($, root, entry, ref)
          if (carries === false) { out.push('tdd (no test file on the branch since dispatch)'); continue }
          // 4.5.2/5.0.0: the record says whether a RED run came before the first content commit of the last brief
          const brief = typeof entry.last_brief_received_at === 'number' ? entry.last_brief_received_at : 0
          const first = typeof entry.first_content_commit_at === 'number' ? entry.first_content_commit_at : 0
          if (brief > 0 && first > brief) {
            const redAt = typeof entry.red_run_at === 'number' ? entry.red_run_at : null
            if (redAt === null || redAt > first) out.push('tdd (no RED test run before the first content commit)')
          }
          continue
        }
        out.push(label)
      }
      return out
    }
    const refOf = (entry: Entry): string => (typeof entry?.branch === 'string' && entry.branch) ? entry.branch : (head || '')
    for (const [key, entry] of named) {
      if (entry?.role !== 'builder' || !entry.session_id || Object.keys(skillsRun(entry)).length === 0) continue
      const gaps = await mergeGaps(entry, refOf(entry))
      if (gaps.length > 0) {
        await logRefusal($, root, key, 'merge-gate', `no record of: ${gaps.join(', ')}`)
        return {
          deny: `astragentic-dispatch: ${key} has no record of: ${gaps.join(', ')}. The Builder's pane records every Skill call; a marker or Pass: line claiming a step the record lacks is a step that did not run in that pane. Have the Builder run the missing step(s) and commit a fresh marker; for tdd, a test file on the branch since dispatch (pattern: .astraler/project/test-file-pattern) or the \`TDD: n/a — <why>\` line on the brief; for the built-in review, \`REVIEW: n/a — <why>\` on the brief. The record is .astraler/state/dispatch-record.json["${key}"].skills_run.`,
        }
      }
    }
    const ran = await next(e)
    if (ran.deny !== undefined || ran.isError) return ran
    void refreshTracker($, root)
    const notes: string[] = []
    for (const [key, entry] of named) {
      if (isPr) await patchRecord($, root, key, { merged_at: await $.clock.now() })
      // Only a pane the mod itself registered (it has a session_id) is judged: a pane without
      // the mod (a junior pane) records nothing here and keeps the marker script as its evidence.
      if (entry?.role === 'builder' && entry.session_id) {
        const gaps = await mergeGaps(entry, refOf(entry))
        if (gaps.length > 0) {
          notes.push(`${MARK} ${key} merged with no record of: ${gaps.join(', ')}. A step the handback names n/a with its reason is fine; any other is a step that did not run.`)
        }
        const owedQa = qaOwed(rec, key)
        if (owedQa) {
          notes.push(`${MARK} ${key} merged owing a QA ${owedQa} (declared on its brief) with no QA turn after the Builder's last. Dispatch it on the merged head (dispatch-qa-walk) or record why not.`)
        }
        if (entry.kind === 'quick') {
          notes.push(`${MARK} ${key} is a quick ticket (tracker label): no simplify(increment) marker and no arm(ticket) receipt were owed, so do not pass those --marker flags to check-simplify-markers.sh for it.`)
        } else if (entry.simplify_na) {
          notes.push(`${MARK} ${key} carried "${String(entry.simplify_na).slice(0, 80)}" on its brief: no simplify(increment) marker was owed, so do not pass --marker 'simplify(increment)' to check-simplify-markers.sh for it.`)
        }
      }
    }
    const owed = await owedTickets($, root)
    await refreshBoard($, root, sends)
    if (owed.length > 0) notes.push(`${MARK} ${owedText(owed)} The next brief will not be sent until this is done.`)
    if (notes.length === 0) return ran
    return { ...ran, context: [...(ran.context ?? []), ...notes] }
  })

  on('command.run', { command: 'tracker-refresh' }, async $ => {
    if (!root) return { text: 'Not in a repository.' }
    await refreshTracker($, root)
    const b = await read($, banner)
    return { text: b.tracker ? `Tracker: ${b.tracker}` : 'No tracker plug and no .astraler/project/tracker declaration: nothing to read.' }
  })

  on('command.run', { command: 'dispatch-board' }, async $ => {
    await refreshBoard($, root, sends)
    await $.ui.open({ id: PANE, title: 'Dispatches' })
    return { text: 'Dispatch board opened.' }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const rows = await read($, board)
    const b = await read($, banner)
    const now = await $.clock.now()
    return (
      <Box flexDirection="column">
        <Text dimColor>{[b.version ? `astragentic ${b.version}` : '', b.branch ? `⎇ ${b.branch}` : ''].filter(Boolean).join(' · ')}</Text>
        {rows.length === 0 && <Text dimColor>No live dispatches.</Text>}
        {rows.map(r => (
          <Text color={r.note === 'not confirmed received' || r.state === 'merged' || (r.note ?? '').includes('— stale') ? 'red' : undefined}>
            {r.key.padEnd(14)} {r.role.padEnd(8)} {r.state.padEnd(10)} {ago(now - r.since).padStart(4)} {r.note ?? ''}
          </Text>
        ))}
      </Box>
    )
  })

  // The bands, as pills. A terminal has no CSS; what it has is a Text with a background, so
  // each fact is one chip: a step that completed is green (✓), the step in progress is yellow
  // (…, with the pane's live agent count), the next step is neutral (→), a step the brief
  // exempted is grey (n/a), a pending one is dim (○). Red is reserved for what needs a person.
  // The owner asked for this shape after watching the first measured dispatch (2026-10-09), and
  // for the running/next split after reading a yellow "next" as "running" (2026-10-22). In
  // progress = the step invoked most recently, while the pane has agents live or has not ended a
  // turn since the call; the list is session-wide, so the count is the pane's, not the step's.
  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const { Box, Text } = $.ui.resolve(e)
    const Chip = ({ bg, fg, dim, label }: { bg?: string; fg?: string; dim?: boolean; label: string }) => (
      <Box marginRight={1}>
        <Text backgroundColor={bg} color={fg} dimColor={dim} bold={Boolean(bg)}>{' '}{label}{' '}</Text>
      </Box>
    )
    if (me) {
      if (e.props.hasSurvey) return next(e)
      const armScope = ARM_SCOPE_BY_ROLE[me.role]
      const steps = FLOW_BY_ROLE[me.role] && armScope && (await armOff($, root)).has(armScope)
        ? FLOW_BY_ROLE[me.role]!.filter(([name]) => name !== 'codex-arm')
        : FLOW_BY_ROLE[me.role]
      const f = steps ? await read($, flow) : null
      if (!undelivered && !f && !appliedVersion) return next(e)
      // A QA pane runs under permissions by contract (launcher matrix: no
      // --dangerously-skip-permissions), so its direct TURN-END send gets no classifier verdict
      // on every turn (measured downstream 2026-10-27: 6 of 6 QA turn ends) and the record is
      // its delivery path, not a fault. The bypass hint is for a pane that was launched with
      // bypass and toggled out of it.
      const isMode = /auto mode|classifier|permission/i.test(undelivered)
      const isQa = me.role === 'qa'
      const hint = isMode && !isQa ? ' This pane is not in bypass-permissions mode: press shift+tab until it is.' : ''
      // Running is a matter of time, never of the agent list: a held turn end leaves
      // `last_turn_end_at` where it was, so the step stays; an agent spawned after a clean turn
      // end (a follow-up brief, no new step) must not re-light the step that finished before it.
      const running = f?.latest && f.latest.at > f.lastTurnEndAt ? f.latest.name : null
      const live = running ? await liveAgents($) : []
      let isCurrentMarked = running !== null
      // TWO ROWS (4.6.0): who and what kind on the first, the steps on the second. A quick
      // ticket's exempt steps leave the row — what is shown is what is owed; a full ticket keeps
      // its grey n/a chips as 4.5.3 shipped them.
      const kind = f?.kind ?? null
      const quickDrop = new Set([RED_RUN, 'astra-ui', 'simplify', 'codex-arm'])
      const shown = kind === 'quick' ? (steps ?? []).filter(([name]) => !quickDrop.has(name)) : (steps ?? [])
      return (
        <Box flexDirection="column">
          {undelivered && isQa && isMode ? (
            <Text dimColor>
              TURN-END goes to the dispatcher by the record: a QA pane runs under permissions, and its direct send has no classifier verdict ({undelivered}).
            </Text>
          ) : undelivered ? (
            <Text color="error" bold>
              TURN-END not delivered to the dispatcher ({undelivered}).{hint} The record carries it meanwhile.
            </Text>
          ) : null}
          {f ? (
            <Box flexDirection="column">
              <Box flexDirection="row" flexWrap="wrap">
                <Chip bg="claude" fg="inverseText" label={`${me.role} ${me.key}`} />
                {kind ? <Chip bg={kind === 'quick' ? 'warning' : 'subtle'} fg={kind === 'quick' ? 'inverseText' : undefined} label={kind} /> : null}
                {f.lastRefusal && (await $.clock.now()) - f.lastRefusal.at < 120_000
                  ? <Chip bg="error" fg="inverseText" label={`⛔ ${f.lastRefusal.gate} refused`} />
                  : null}
                {me.role === 'qa' && f.qaMode ? <Chip bg="claude" fg="inverseText" label={`mode ${f.qaMode}`} /> : null}
                {appliedVersion ? <Chip dim label={`astragentic ${appliedVersion}`} /> : null}
              </Box>
              {shown.length > 0 ? (
                <Box flexDirection="row" flexWrap="wrap">
                  {shown.map(([name, label, isOptional]) => {
                    // the tdd chip lights from the RED run; a quick ticket's review chip from the built-in alone (5.0.0)
                    const isRan = name === RED_RUN ? f.redRun : f.ran.includes(name) || (name === 'codex-arm' && f.ran.includes('codex-claude-arm')) || (name === 'astra-review' && kind === 'quick' && f.ran.includes('code-review'))
                    // an optional step is shown only once the brief has said whether it is owed (4.5.3)
                    if (isOptional && !isRan && f.uxOwed === null) return null
                    const isNa = (name === RED_RUN && f.tddNa) || (name === 'astra-review' && f.reviewNa) || (name === 'simplify' && f.simplifyNa) || (isOptional && f.uxOwed === false)
                    if (name === running) return <Chip bg="warning" fg="inverseText" label={`… ${label}${live.length ? ` (${live.length} agent${live.length === 1 ? '' : 's'})` : ''}`} />
                    if (isRan) return <Chip bg="success" fg="inverseText" label={`✓ ${label}`} />
                    if (isNa) return <Chip bg="inactive" fg="inverseText" label={`n/a ${label}`} />
                    if (!isCurrentMarked) { isCurrentMarked = true; return <Chip bg="subtle" label={`→ ${label}`} /> }
                    return <Chip dim label={`○ ${label}`} />
                  })}
                </Box>
              ) : null}
            </Box>
          ) : (appliedVersion ? (
            <Box flexDirection="row">
              <Chip bg="claude" fg="inverseText" label={`${me.role} ${me.key}`} />
              <Chip dim label={`astragentic ${appliedVersion}`} />
            </Box>
          ) : null)}
        </Box>
      )
    }
    if (!root || e.props.hasSurvey) return next(e)
    const rows = await read($, board)
    const b = await read($, banner)
    const now = await $.clock.now()
    const alarmOf = (r: BoardRow) => r.note === 'not confirmed received' || r.state === 'merged' || (r.note ?? '').startsWith('turn end read from record') || (r.note ?? '').includes('— stale')
    const colorOf = (r: BoardRow) => alarmOf(r) ? 'error' : r.state === 'working' ? 'success' : r.state === 'sent' ? 'warning' : undefined
    // THE DISPATCHER'S BAND IS A HEADER AND ONE ROW PER LANE (4.6.0, the owner's ask of
    // 2026-10-26): the first row is the checkout's state (branch, version with `↑` when a newer
    // release exists, tracker counts, lane count); each lane below in straight columns, the same
    // layout the /dispatch-board pane has. The update one-liner left the band: `.astraler/astragentic.sh update` is the answer the `↑` chip points at.
    return (
      <Box flexDirection="column">
        <Box flexDirection="row" flexWrap="wrap">
          {b.branch ? <Chip bg="claude" fg="inverseText" label={`⎇ ${b.branch}`} /> : null}
          {b.version ? (b.latest
            ? <Chip bg="warning" fg="inverseText" label={`astragentic ${b.version} ↑${b.latest}`} />
            : <Chip dim label={`astragentic ${b.version}`} />) : null}
          {b.tracker ? <Chip dim label={b.tracker} /> : null}
          <Chip dim label={rows.length === 0 ? 'no dispatches' : `${rows.length} lane${rows.length === 1 ? '' : 's'}`} />
          {b.extra ? <Chip dim label={b.extra} /> : null}
        </Box>
        {rows.map(r => (
          <Text color={colorOf(r)} dimColor={colorOf(r) === undefined}>
            {`${r.key.padEnd(14)} ${r.role.padEnd(8)} ${r.state.padEnd(10)} ${ago(now - r.since).padStart(4)}${r.note ? `  ${r.note}` : ''}`}
          </Text>
        ))}
      </Box>
    )
  })
}
