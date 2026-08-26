---
name: dispatch-ticket
description: "Dispatch one claimed ticket as a visible Herdr pane — one Builder, one worktree, one branch, one pane. Use when launching a Builder, a Shaper, QA or Rin into a pane. Pair with dispatch-ticket-claude, dispatch-ticket-codex or dispatch-ticket-opencode for the launcher."
---

# Dispatch a ticket — shared protocol

Role contract: `.agents/roles/builder.md`. Runtime, model and effort per role:
`.agents/orchestrator.md` (owner-editable; Thomas reads it at session start; edits take
effect at the next dispatch). Runtime changes the executables. The roles, the worktree, the
Herdr topology and the artifact contract stay identical across all three.

**The runtime-specific launcher, pre-dispatch verification and measured runtime facts live in
the companion skill**: `dispatch-ticket-claude`, `dispatch-ticket-codex` or
`dispatch-ticket-opencode`. Read both this skill and the runtime-specific one.

## The sequence

Every dispatch runs these in order. Each names where its detail lives.

1. **Preflight, first dispatch of the session only** — watchdog running, payload committed.
2. **Resolve the row** — runtime, model, effort from `orchestrator.md`; write-set collected.
3. **Claim, then create branch and worktree** — the claim precedes the worktree (`thomas.md`).
4. **Resolve or create the workspace**, then create the tab and pane, and gate on `foreground_cwd`.
5. **Print the resolved dispatch**, then launch via the runtime-specific skill.
6. **Submit the brief** — first line is the phase's plugin-qualified slash command.
7. **Arm the watcher immediately** — submitting and arming are one action, not two.
8. **Branch on the watcher's exit status and payload**, never on pane status alone.
9. **Verify by artifact**, then cleanup — [`CLEANUP.md`](CLEANUP.md).

A step that reports nothing is a step nobody can tell was skipped.

## The binding identity

```text
ticket → assignee (the claim) → pane → worktree → branch → PR
```

Each of those is one-to-one, and the chain is what lets several Builders work the frontier
at once. **The claim comes first**: a ticket is assigned on the tracker BEFORE its worktree
exists, so two sessions picking from the same frontier see each other's claims. Upstream
applies this to decision tickets; here it extends to build tickets, and it is the whole
concurrency mechanism.

**The Builder is the sole writer in its worktree.** Everyone else — Thomas, Rin, a reviewer,
another Builder — reads. The branch and worktree are the real isolation boundary; Herdr is
the visible control surface over it.

Parallel tickets get their own pane, session, worktree and branch. Sequential tickets may
reuse an existing project/epic workspace and still take fresh tabs and sessions: `/clear`
turns an old pane into an empty pane, not an isolated ticket.

## Inputs and resolution

- runtime/model/effort from `.agents/orchestrator.md` (the default source)
- `runtime=claude|codex|opencode` — an explicit per-dispatch override, never written back
- `visibility=herdr|headless` (default `herdr`)
- workspace label, ticket ID, branch, base, worktree path, the ticket body, owner intent,
  acceptance criteria, validation commands, expected artifact
- **write-set** — the files this ticket will write, and the files each other live ticket
  already owns. **Required whenever another dispatch is live**, the way browser consent is
  required of a QA dispatch: a field the dispatcher must fill before the pane launches cannot
  be skipped by being busy.

**An override re-resolves the WHOLE row, not just the Runtime cell (AST-030).** The role uses
the `orchestrator.md` row that already targets that runtime — runtime, model and effort
together. Where no row targets the overridden runtime, stop and ask the owner.

**Resolution order:** the active row → if that runtime is genuinely unavailable (CLI
missing, auth failed, quota exhausted), the role's Fallback row, with the degradation
REPORTED to the owner. Degradation is per-session and stays out of the file.

**A row reading `<set-me>` is UNDECIDED, and undecided is a STOP at dispatch, not before.**
The owner picks a runtime per project and per situation, so a table with a runtime left open
is a normal resting state — the doctor says so and moves on. But resolving a role ONTO that
runtime means using a model id nobody has chosen: stop, name the role and the row, and ask.
Never substitute another role's model to keep the dispatch moving.

**A missing row is an answer, not a gap to fill.** An absent fallback means that role has no
fallback, so an unavailable active runtime is a STOP. Where `orchestrator.md` itself is
missing or a row is ambiguous, Thomas asks the owner for the model and scaffolds the file
before dispatching — inferring a runtime from installed binaries or from the task text
produces a confident wrong answer.

**Headless implementation is not supported, on any runtime.** Every Builder runs in a visible
Herdr pane: a topology nobody can observe is trusted on the dispatcher's word, which is the
thing panes exist to remove. A `visibility=headless` request is a STOP — say it is unsupported
and dispatch normally, or take it to the owner (AST-070).

## One checkout, one driver

**At most ONE session treats the repository's main checkout as its workspace** — the resident
router's. Every session you dispatch gets its own worktree, without exception, including
read-only ones with a shell.

Two root sessions sharing a main checkout have silently lost commits to a concurrent
`git switch` (AST-016, AST-027).

**Every session verifies `git branch --show-current` before each commit**, and stops if it is
not the branch it was dispatched onto. That check costs nothing and is the only thing that
catches a checkout moving underneath you, because the symptom appears later and somewhere
else.

**Isolation covers all disk activity, not only git** (AST-106): running tests or builds in a
worktree you do not own causes the same collision class. Apply the one-driver rule to any
command that writes to disk — the arm already does, one detached worktree per pass.

## The watchdog must be RUNNING before the first dispatch

```bash
pgrep -f 'herdr-watchdog.sh' >/dev/null \
  || echo "STOP: watchdog is not running — start it before dispatching"
```

**A dispatch with no watchdog is not permitted.** Start it if it is not up (`thomas.md`
§Watchdog has the invocation), then dispatch.

A gate rather than advice because **an unwatched pane and a quiet healthy pane produce
identical evidence: nothing** (AST-124). With the watchdog up, a missed re-arm costs latency;
without it, silence.

**Coverage**: the watchdog's `STUCK` rule requires that NO pane is working, so an active Thomas
suppresses it — a Builder that finishes while Thomas is busy still pings nothing. The per-turn
watcher and the watchdog cover different halves; neither replaces the other.

## The payload must be COMMITTED before the first dispatch

**A git worktree contains tracked content and nothing else.** A harness whose files are
untracked — gitignored, or merely staged-but-uncommitted — is invisible inside every Builder
worktree, including `.agents/roles/builder.md`. The Builder starts with no contract and no
sign that anything is missing.

Two conditions, both needed (AST-036):

1. **Nothing in the payload is gitignored.** A repo with a broad `.agents/*` or `.claude/*`
   ignore rule needs allow-list entries for the harness paths.
2. **The payload is committed.** Allow-listing alone leaves the files untracked, so the
   worktree is still empty. This is the step that is easy to believe is done.

Confirm it the only way that answers the question, before the first dispatch of a session:

```bash
git worktree add --detach /tmp/harness-check HEAD
test -f /tmp/harness-check/.agents/roles/builder.md && echo OK || echo "PAYLOAD NOT VISIBLE"
git worktree remove --force /tmp/harness-check
```

A `PAYLOAD NOT VISIBLE` result is a STOP: dispatching into it produces a Builder that
improvises, which is harder to notice than a Builder that fails.

## Worktree and named tab

`<worktree-path>` is the ABSOLUTE path
`<repo-root>/.claude/worktrees/<branch-slug>` (branch `/` → `-`), inside the repo but
gitignored (AST-028). A relative path once resolved through a stale shell cwd to an
unexpected location, which is why the absolute form is fixed here.

```bash
git worktree prune                                           # FIRST — see below
git worktree add -b <ticket-branch> <worktree-path> <base>   # ABSOLUTE, output visible
git worktree list   # verify the new entry is exactly <worktree-path>
herdr workspace list
```

**`prune` comes first, and the `add` runs with its output visible.** A previous removal can
leave `.git/worktrees/<name>/` registered; `add` then refuses — and a redirected `>/dev/null`
throws away the one line that says so, leaving a dispatch that looks launched (AST-096). On a
Claude root `scripts/hook-git-guard.sh` runs the prune for you and refuses a relative path or a
redirected add; it is a `PreToolUse` hook and does not exist on Codex or opencode, so the two
rules above are the contract on every runtime.

Resolve the project workspace from `herdr workspace list` by matching the `workspace-label`
field in `orchestrator.md`.

**A label of `<set-me>` or empty is a STOP, not a dispatch.** The owner has not named this
project yet; ask rather than inventing or falling back to the folder name.

**Exactly one match → reuse it. Two or more matches → STOP and ask the owner** which is the
real one — silently picking the first hides a workspace a prior session already left running.
No match → create one rooted at the repo:

```bash
herdr workspace create --label "<workspace-label from orchestrator.md>" --cwd <repo-root> --no-focus
```

Immediately after create, `herdr workspace list` again and confirm exactly one workspace
carries this label — a racing session can otherwise leave two. Record
`workspace_managed_by_root=true` at workspace level right away: it is this dispatch's only
durable statement that it owns the workspace, and cleanup has no other source for it. Where the
label matched an existing workspace, read that workspace's own `workspace_managed_by_root` from
its prior record; an existing `false` stands.

The workspace is project-scoped and outlives any one ticket, while a ticket's worktree is
removed at cleanup — so the workspace cwd stays at repo-root rather than binding to the
first worktree.

**The commands below show a Builder dispatch. Substitute the tab/pane prefix for the role
actually being dispatched** — tab `ticket:<id>`/pane `builder:<id>` for a Builder, but tab
AND pane both `spec:<id>` for a Shaper, `qa:<id>` for QA, `rin:<id>` for Rin — per the table
right after them. This same skill dispatches a Shaper too (`thomas.md`: "same mechanics as
any dispatch"). An invented prefix — `shaper:<id>` — is one the watchdog's
`TITLE_PREFIXES` does not recognize, so that pane dispatches unmonitored, silently.

A new workspace already owns an initial tab and root pane. Read the create response, then
`herdr tab list` / `herdr pane list`, and rename that initial tab and pane for the first
ticket rather than creating a redundant shell:

```bash
herdr tab rename <returned-initial-tab-id> "ticket:<ticket-id>"
herdr pane rename <returned-root-pane-id> "builder:<ticket-id>"
herdr pane send-text <returned-root-pane-id> "cd <worktree-path>"
herdr pane send-keys <returned-root-pane-id> Enter
```

Where the workspace already exists, **always create a new tab**. Tabs you did not create
belong to the owner or another dispatch, and splitting into one renames it in the herdr UI.

```bash
herdr tab create --workspace <workspace-id> --label "ticket:<ticket-id>" \
  --cwd <worktree-path> --no-focus
herdr pane rename <returned-root-pane-id> "builder:<ticket-id>"
```

Both commands above carry a label, and **for a Builder the two DIFFER**: tab `ticket:<id>`,
pane `builder:<id>`, exactly as written. `orchestrator.md` § Workspace identity is a **tab**
table — it does not name pane labels. For a Shaper, QA and Rin the two coincide, and the
substitution applies to BOTH commands, not the tab alone: a Shaper's pane is `spec:<id>`, never
`shaper:<id>`. `builder:` and `ticket:` are both in the watchdog's `TITLE_PREFIXES`, so the
Builder's two labels differing is safe; `shaper:` is not in it, which is the whole finding
(AST-082).

**Mandatory cwd gate before launch.** `--cwd` on create is not guaranteed to stick, and
agent resolution depends on cwd — launched from `$HOME` it errors "agent not found" or runs
an unintended default. Confirm the pane's `foreground_cwd` equals `<worktree-path>` via
`herdr pane get <pane-id>`; a mismatch is a STOP (fix with
`herdr pane run <pane-id> "cd <worktree-path>"`, then re-verify).

**Agent names and pane labels are different strings.** `herdr agent start` accepts lowercase
letters, digits, `-` and `_` — no `:`, no uppercase — while pane labels take `:`. So the
agent is `builder-<ticket-id-lowercased>` while the pane is `builder:<ticket-id>`.
**Lowercase the ticket ID in the agent name** (`TRA-123` → `builder-tra-123`); passing
uppercase or a pane label as an agent name fails the dispatch silently.

Print the resolved dispatch before launching:

```text
role=builder
runtime=<claude|codex|opencode from orchestrator.md (or explicit override)>
topology=herdr
executable=<exact launcher command from the runtime-specific dispatch skill>
ticket=<ticket id>            worktree=<absolute path>
branch=<ticket branch>        workspace=<returned workspace id>
workspace_managed_by_root=<true|false inherited from the durable record>
tab=<returned tab id>         pane=<returned pane id>
```

Then launch using the `herdr agent start` command from the runtime-specific dispatch skill
(`dispatch-ticket-claude`, `dispatch-ticket-codex` or `dispatch-ticket-opencode`).

Where `agent start` fails readiness, inspect with `herdr agent read`, then fall back to
`herdr pane run <pane-id> "<exact launcher command>"`. Launch into the pane this dispatch
created — the owner's active tab stays theirs, and a hidden subagent is not a substitute for
a visible pane.

## Brief, watch, and steer

### The brief opens with the phase's slash command

**The plugin's flow skills are `disable-model-invocation: true`** — `implement`, `triage`,
`wayfinder`, `to-spec`, `to-tickets`, `grill-with-docs`, `setup-matt-pocock-skills`. A model
cannot reach them at all, so an agent merely *told about* `implement` in prose reads the prose
and starts coding without the skill.

What reaches them is **text arriving as a user turn**. So the brief's first line is the slash
command itself, **plugin-qualified** — `/mattpocock-skills:<name>` — with the rest of the brief
below it. A bare `/implement` <!-- addr-ok: wrong form, cited --> resolves today only because
nothing else claims that word yet (AST-050). Claude Code's own `/compact` and `/clear` keep
their bare names: they are CLI commands, so a typed form is the only form.

**Slash form for what only a human can type; Skill form for what the model can.** `simplify`
carries no `disable-model-invocation`, so an agent invokes it as `Skill(skill: "simplify")`.
Writing it as `/simplify` <!-- addr-ok: cited as the wrong form --> hands an agent an address
it cannot use, and a Builder given an unusable address rolls its own pass instead (AST-051).

```text
/mattpocock-skills:implement TICKET-123

Worktree: … · Branch: … · Base: …
Acceptance criteria: …
Owner intent: …
Validation: …
Owned elsewhere: TRA-127 owns docs/…/WIRE-CONTRACT.md — do not edit it; report what you
would have changed.
Source of truth: the codebase, not this ticket — verify every claim against the actual code.
```

**The `Owned elsewhere:` line is what converts a merge conflict into a handback note**, and it
costs one sentence. Omit it only when no other dispatch is live.

Derive this ticket's own write-set from its body plus whatever the repo's docs-sync rule drags
in, record it against the ticket, and read the other live tickets' write-sets back out to find
the overlap. **A Builder that edits a file another ticket owns is obeying a correct rule** —
usually the docs-sync one — so nothing in the ticket itself can carry the boundary; it has to
arrive with the brief. It is a required field rather than a rule in prose because a boundary a
careful dispatcher forgets needs a slot that blocks the launch (AST-056).

This is what "an agent playing the human at that step" means mechanically. Verify by
artifact that the skill actually ran — its own output in the transcript — rather than by the
brief having been sent.

### Submitting it

**Claude runtime: use SendMessage** — see `dispatch-ticket-claude` for direct message
delivery. The Herdr paste method below is for **Codex and OpenCode only**.

```bash
herdr agent prompt <pane-id> "<brief>"
```

No `--wait --until working` here either: the watcher's start guard is the one place that
question gets asked, on every runtime and every submit form.

**A multi-line brief lands in the composer WITHOUT submitting** — the paste consumes the
Enter, the transcript shows `[Pasted text #1 +N lines]` in an unsent composer, **and the pane
reports `idle` while it sits there** (AST-032, AST-037). Every real dispatch brief is
multi-line, so this is the default case. It takes an explicit second step:

```bash
herdr pane run <pane-id> "<multi-line brief>"
herdr pane send-keys <pane-id> Enter        # the brief is pasted; THIS submits it
```

**Do not hand-roll the `working` confirmation — start the watcher and let it answer.** Its
start guard asks the same question a separate `herdr agent wait --until working` would, and
asking twice delays the watcher into missing `working` on a fast builder. On `NO_START`, read
the pane: an unsent brief sitting in the composer is the likeliest cause, and the fix is to
send Enter again.

### Start the watcher — mandatory, immediately after submit

**Every dispatched pane gets a watcher, from the script below.**

**And every NEW turn gets a NEW watcher — not just the first brief.** The watcher watches one
submitted turn and exits when that turn reaches terminal, correctly. A fold sent after a gate,
an answer to a blocked Builder, any further work on the same pane: each is a new turn, each
needs a new watcher, and nothing re-arms one for you — the re-arm is the step that gets
skipped, because it comes right after a long absorbing task (AST-124).

**Sending work and arming the watch are one action, not two adjacent ones.** If you have typed
a message to a pane and not armed a watcher, the dispatch is not finished.

**All runtimes run the same watcher script**; they differ only in how its output reaches
the dispatcher. Claude runtime wraps it in `Monitor` so each line arrives as a notification —
see `dispatch-ticket-claude`, which also covers the one-Monitor-per-builder rule. Codex and
OpenCode run it directly and branch on `$?`, as below. A bare `herdr agent wait` is not a
substitute; it goes deaf (AST-107).

```bash
<repo-root>/scripts/herdr-watch-terminal.sh <pane-id> 3 3600 120
```

Run this immediately after submitting the brief — the script's own start guard is the
confirm-`working` step. For Codex/OpenCode it is the ONLY sanctioned monitor: it carries
caffeinate (the machine cannot sleep and kill the watch), a start guard, debounce, a
3600-second cap, and wait slicing so a deaf `herdr agent wait` cannot stall it (AST-107).
The script is the sanctioned monitor because hand-rolled loops, `herdr agent wait --until
idle`, and `sleep` + `herdr agent get` carry none of the five.

Branch on `$?` **and the payload** when it returns:

- `0` + `TERMINAL:done pane=<id>` → builder's turn ended, **not necessarily finished** — check for background processes before concluding (see below)
- `0` + `TERMINAL:idle pane=<id>` → builder idle, check git log — may be finished or may have stopped early
- `0` + `TERMINAL:blocked pane=<id>` → builder is asking a question, **read pane immediately and answer** — do NOT proceed to artifact verification, the builder is waiting for you
- `1` + `TIMEOUT after <max>s pane=<id>` → builder exceeded cap, inspect pane
- `2` + `NO_START pane=<id>` → builder never started working, re-read pane

**Read the payload, not just the exit code** — exit 0 carries four meanings. On `blocked`,
read the pane, answer the question, then restart the watcher; the builder is waiting on you.

**`done` means the turn ended, not that the work finished** (AST-097). A builder that
launches background work and parks waiting for a notification reads as `done` while its
artifact is still being built. Before concluding finished, check TWO sources for active
background work:

1. **OS processes** — `pgrep` for test runners, build tools, or the builder's own monitors
   whose argv contains the worktree path.
2. **Runtime status line** — `herdr agent read <pane-id>` renders the pane's status bar,
   which names shells and monitors the runtime itself tracks (ScheduleWakeup, Monitor).
   These are invisible to `pgrep`.

**Disagreement between the two sources is itself a signal — read the pane** (AST-097): a
`pgrep`-quiet pane whose status line still names a monitor may be parked permanently on a
notification that will never arrive.

Processes or runtime tasks still running → PARKED, wait for exit, then re-check. All
quiet on BOTH sources AND no new commits since the last instruction → read the pane before
concluding — the turn may have crashed (529, OOM, context limit) with the error visible on
screen (AST-097). All quiet AND new commits since the last instruction → proceed to artifact
verification.

**`--wait` collapses submit, start-guard and settle into one call, and it is trustworthy
ONLY on a pane whose turn you just opened.** Herdr does not track turns, and `--until idle`
is satisfied by whatever the runtime's rules call idle — an unsent composer on Claude, and
nothing at all on opencode: a signal incapable of failing (AST-032).

**So for any pane you did not prompt in that same call** — watching another role's pane,
resuming after a break, waiting on an artifact — the start guard stays MANDATORY.
**Claude runtime**: use Monitor (see `dispatch-ticket-claude`).
**Codex/OpenCode**: use `<repo-root>/scripts/herdr-watch-terminal.sh`.
Both observe `working` for THIS turn before blessing anything, and `working` is rule-backed
on all three runtimes.

On `agent_prompt_stalled` or a blocking modal, inspect first, resolve the modal, then use
the low-level submission fallback (`send-text` + `send-keys` can drop input, so it is a last
resort; for shell commands use `pane run`):

```bash
herdr agent read <pane-id> --source recent-unwrapped --lines 80
herdr pane send-text <pane-id> "<brief>" && herdr pane send-keys <pane-id> Enter
```

Where a documented subcommand appears missing, check `herdr --version` against the 0.8.0
floor before diagnosing the app.

**A pane is for OBSERVATION; artifacts travel as files.** A pane read returns only the
visible ROW COUNT — no `--lines` value gets past it — and reports SUCCESS, so anything longer
than the viewport comes back silently cut. **Truncation is detectable**: `tab create` and
`agent get` expose `scroll.viewport_rows`, and a read returning exactly that many lines is
the signal — compare the count rather than judging by eye.

**Who writes the file follows the role.** An agent that may write (the Builder) writes into
the worktree it owns and replies with the path. A READ-ONLY agent (Rin)
returns its report and the DISPATCHER persists it — which keeps an artifact out of a
disposable gate worktree that cleanup is about to delete (AST-031, AST-032).

**herdr fails loudly, so its EXIT STATUS is trustworthy — it is the status FIELD that
lies.** Treat a non-zero herdr exit as a real failure worth reading, and keep the scepticism
for the `agent_status` it returns on success.

**Watcher operational reference** — the exit contract in full, `NO_START` semantics,
stopping a watch by process group, and the pipe-swallows-exit-code table that applies to every
command Thomas runs: [`WATCHING.md`](WATCHING.md). Read it when a watch returns something you
did not expect, before diagnosing herdr.

## Long tickets

Keep one ticket in its assigned session. When the conversation grows long, write a durable
checkpoint BEFORE `/compact`: branch and SHA, clean or intentional WIP state, completed
acceptance criteria, exact validation results, blockers, next action — into the tracker or
the handoff artifact. Then `/compact` and re-ground from that artifact plus `git log` and
the current diff. Runtime auto-compaction carries the same re-grounding requirement.

`/clear` starts a fresh chat and discards the working thread, so it belongs between tickets
rather than inside one — and a new ticket takes a fresh pane and worktree anyway. It is not
cwd, branch, worktree, process or lifecycle cleanup.

## 10. Write `.astraler/state/dispatch-record.json`

**The durable half of a dispatch.** `thomas.md` names this record beside the tracker and the
frontier and nothing defined it: no path, no shape, no owner. Four rules read it and could
not — the write-set overlap check above, cleanup's exact IDs, a later session finishing a
dispatch this one started, and, on every tracker whose `assignee` cannot hold
`builder/<ticket-id>`, the Builder identity itself.

**Path:** `<repo-root>/.astraler/state/dispatch-record.json`. Operational state, not payload:
it names machine-local pane and tab ids, so it is not committed and a project that gitignores
`.astraler/` is correct to.

**Shape** — one object per live ticket, keyed by ticket id:

```json
{
  "TRA-129": {
    "branch":    "builder/TRA-129",
    "worktree":  "/abs/path/.claude/worktrees/builder-TRA-129",
    "workspace": "my-project",
    "tab":       "ticket:TRA-129",
    "pane":      "pane_01H…",
    "runtime":   "claude",
    "identity":  "builder/TRA-129",
    "write_set": ["src/posting/post.ts", "docs/agents/CONTEXT.md"],
    "claimed_at": "2026-08-26T09:41:00Z"
  }
}
```

**Written at step 6 of the claim**, before the brief is submitted — a dispatch the record does
not know about is one no later session can finish or clean up.
**Read** whenever another dispatch is live, to collect the other tickets' `write_set` values.
**The entry is deleted during cleanup**, after the worktree and branch are gone and before the
assignee is released.

**`identity` is load-bearing where the tracker cannot hold it.** Linear's `assignee` resolves
to a real workspace member, and GitHub's `--add-assignee @me` is one login for every
dispatcher, so on both the readback interlock cannot tell whose claim it read. This field is
where `builder/<ticket-id>` actually lives, and it is what a later session matches to decide
whether a claim is its own.

**A stale entry is an entry whose branch is gone.** That is the readable form of a stale claim,
and it is checkable without the tracker: `git rev-parse --verify <branch>` failing while an
entry survives means the dispatch ended and cleanup did not finish.

## Cleanup

**Cleanup protocol** — the simplify-pass artifact contract, the two pre-removal checks
(uncommitted work, simplify markers and provenance), the `Supersedes:` rules, and Herdr tab /
workspace / worktree retirement: [`CLEANUP.md`](CLEANUP.md). Read it when the Builder has
handed back, before removing anything.
