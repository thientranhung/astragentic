---
name: dispatch-ticket
description: "Shared protocol for dispatching one claimed ticket as a visible Herdr pane — one Builder, one worktree, one branch, one pane. Covers the binding identity, inputs/resolution, worktree law, brief format, submission, watching, simplify artifact contract, and cleanup. Runtime-specific launcher and verification live in dispatch-ticket-claude, dispatch-ticket-codex or dispatch-ticket-opencode."
---

# Dispatch a ticket — shared protocol

Role contract: `.agents/roles/builder.md`. Runtime, model and effort per role:
`.agents/orchestrator.md` (owner-editable; Thomas reads it at session start; edits take
effect at the next dispatch). Runtime changes the executables. The roles, the worktree, the
Herdr topology and the artifact contract stay identical across all three.

**The runtime-specific launcher, pre-dispatch verification and measured runtime facts live in
the companion skill**: `dispatch-ticket-claude`, `dispatch-ticket-codex` or
`dispatch-ticket-opencode`. Read both this skill and the runtime-specific one.

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
Herdr pane, because the owner seeing work in flight is what this package sells — a topology
nobody can observe is trusted on the dispatcher's word, which is the thing panes exist to
remove. A `visibility=headless` request is a STOP: say it is unsupported and dispatch
normally, or take it to the owner. The bounded exception this package used to ship went three
weeks across two active projects without one request (AST-070).

## One checkout, one driver

**At most ONE session treats the repository's main checkout as its workspace** — the resident
router's. Every session you dispatch gets its own worktree, without exception, including
read-only ones with a shell.

The incident behind this is not hypothetical: two root sessions shared a main checkout, one
ran `git switch` while the other was committing, and three commits landed on the wrong branch
and then vanished when it switched back. Nothing errored. Both sessions were behaving
correctly in isolation (AST-016, AST-027).

**Every session verifies `git branch --show-current` before each commit**, and stops if it is
not the branch it was dispatched onto. That check costs nothing and is the only thing that
catches a checkout moving underneath you, because the symptom appears later and somewhere
else.

## The payload must be COMMITTED before the first dispatch

**A git worktree contains tracked content and nothing else.** So a harness whose files are
untracked — gitignored, or merely staged-but-uncommitted — is invisible inside every Builder
worktree, including `.agents/roles/builder.md`, the file the Builder's adapter tells it to
read first. The Builder starts with no contract and no sign that anything is missing.

Two conditions, and both are needed (AST-036):

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
git worktree list
git worktree add -b <ticket-branch> <worktree-path> <base>   # ABSOLUTE
git worktree list   # verify the new entry is exactly <worktree-path>
herdr workspace list
```

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

Immediately after create, `herdr workspace list` again and confirm exactly one workspace now
carries this label — a second session racing the same create can otherwise leave two. Record
`workspace_managed_by_root=true` at workspace level right away: it is this dispatch's only
durable statement that it owns the workspace, and cleanup below has no other source for it.
Where the label already matched an existing workspace, read that workspace's own
`workspace_managed_by_root` from its prior record — never assume it, and never overwrite an
existing `false` with `true`.

**One project, one workspace.** Never create a second workspace for the same project. Never
invent a label — always read it from `orchestrator.md`.

The workspace is project-scoped and outlives any one ticket, while a ticket's worktree is
removed at cleanup — so the workspace cwd stays at repo-root rather than binding to the
first worktree.

**The commands below show a Builder dispatch. Substitute the tab/pane prefix for the role
actually being dispatched** — tab `ticket:<id>`/pane `builder:<id>` for a Builder, but tab
AND pane both `spec:<id>` for a Shaper, `qa:<id>` for QA, `rin:<id>` for Rin — per the table
right after them. This same skill
dispatches a Shaper too (`thomas.md`: "same mechanics as any dispatch"), and copying the
literal `builder:`/`ticket:` shown here for a Shaper renames its pane to something the
watchdog's `DISPATCH_PREFIXES` does not recognize, so it dispatches unmonitored — measured
directly: a Shaper pane renamed `shaper:<id>` by reflex was invisible to the watchdog end to
end, silently, until the mismatch was noticed by hand.

A new workspace already owns an initial tab and root pane. Read the create response, then
`herdr tab list` / `herdr pane list`, and rename that initial tab and pane for the first
ticket rather than creating a redundant shell:

```bash
herdr tab rename <returned-initial-tab-id> "ticket:<ticket-id>"
herdr pane rename <returned-root-pane-id> "builder:<ticket-id>"
herdr pane send-text <returned-root-pane-id> "cd <worktree-path>"
herdr pane send-keys <returned-root-pane-id> Enter
```

Where the workspace already exists, **always create a new tab** — never split into or reuse
an existing tab. Tabs you did not create belong to the owner or another dispatch; splitting
into them renames the tab in herdr UI and creates confusion.

```bash
herdr tab create --workspace <workspace-id> --label "ticket:<ticket-id>" \
  --cwd <worktree-path> --no-focus
herdr pane rename <returned-root-pane-id> "builder:<ticket-id>"
```

Tab AND pane label follow the convention in `orchestrator.md` § Workspace identity —
`ticket:<id>` for builders, `spec:<id>` for shapers, `qa:<id>` for QA, `rin:<id>` for Rin —
for BOTH commands above, not the tab alone: a Shaper's pane is `spec:<id>`, never
`shaper:<id>` or `builder:<id>`.

**Mandatory cwd gate before launch.** `--cwd` on create is not guaranteed to stick, and
agent resolution depends on cwd — launched from `$HOME` it errors "agent not found" or runs
an unintended default. Confirm the pane's `foreground_cwd` equals `<worktree-path>` via
`herdr pane get <pane-id>`; a mismatch is a STOP (fix with
`herdr pane run <pane-id> "cd <worktree-path>"`, then re-verify).

**Agent names and pane labels are different strings.** `herdr agent start` accepts lowercase
letters, digits, `-` and `_` — no `:`, no uppercase — while pane labels take `:`. So the
agent is `builder-<ticket-id-lowercased>` while the pane is `builder:<ticket-id>`.
**Lowercase the ticket ID in the agent name** (`TRA-169` → `builder-tra-169`); passing
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
cannot reach them at all, so an agent that is *told about* `implement` in prose will read the
prose and start coding without the skill.

What does reach them is **text arriving as a user turn**. So the brief's first line is the
slash command itself, **written in its plugin-qualified form** — `/mattpocock-skills:<name>`
— and the rest of the brief follows it. A bare `/implement` <!-- addr-ok: wrong form, cited -->
resolves today only because
nothing else claims that word yet; the qualified form is correct whatever gets installed
later (AST-050). Claude Code's own `/compact` and `/clear` keep their bare names: they are CLI
commands rather than skills, so no agent can reach them and a typed form is the only form.

**A built-in that IS a skill is the opposite case.** `simplify` carries no
`disable-model-invocation`, so an agent invokes it as `Skill(skill: "simplify")` and never
needs a user turn. Writing it as `/simplify` <!-- addr-ok: cited as the wrong form --> hands
an agent an address it cannot use, and a
Builder given an unusable address rolls its own pass instead — measured on two tickets
(AST-051). Slash form for what only a human can type; Skill form for what the model can.

```text
/mattpocock-skills:implement TICKET-123

Worktree: … · Branch: … · Base: …
Acceptance criteria: …
Owner intent: …
Validation: …
Owned elsewhere: TRA-38 owns docs/…/WIRE-CONTRACT.md — do not edit it; report what you
would have changed.
```

**The `Owned elsewhere:` line is what converts a merge conflict into a handback note**, and it
costs one sentence. Omit it only when no other dispatch is live.

Derive this ticket's own write-set from its body plus whatever the repo's docs-sync rule drags
in, record it against the ticket, and read the other live tickets' write-sets back out to find
the overlap. **A Builder that edits a file another ticket owns is obeying a correct rule** —
usually the docs-sync one — so nothing in the ticket itself can carry the boundary; it has to
arrive with the brief.

Measured twice in one day: once on a shared document, once on `routes.go` and its test an hour
later, dispatched by the operator who had just diagnosed the first occurrence and did not
generalise it. That is why this is a field rather than a rule in prose — a boundary a careful
dispatcher forgets that fast needs a slot that blocks the launch (AST-056).

This is what "an agent playing the human at that step" means mechanically. Verify by
artifact that the skill actually ran — its own output in the transcript — rather than by the
brief having been sent.

### Submitting it

**Claude runtime: use SendMessage** — see `dispatch-ticket-claude` for direct message
delivery. The Herdr paste method below is for **Codex and OpenCode only**.

```bash
herdr agent prompt <pane-id> "<brief>" --wait --until working --timeout 30000
```

**A multi-line brief lands in the composer WITHOUT submitting.** Measured: `herdr pane run`
and `agent prompt` both send text plus Enter, but a multi-line block is pasted as a unit and
the Enter is consumed by the paste — the transcript shows `[Pasted text #1 +N lines]` sitting
in an unsent composer. Every real dispatch brief is multi-line, so this is the default case,
not the edge case.

**And the pane reports `idle` while it sits there**, because an empty-looking composer
matches Claude's idle rule — a signal incapable of failing (AST-032, AST-037). A dispatcher
that trusts that `idle` concludes the Builder finished instantly.

So a multi-line brief takes an explicit second step, then a positive confirmation:

```bash
herdr pane run <pane-id> "<multi-line brief>"
herdr pane send-keys <pane-id> Enter        # the brief is pasted; THIS submits it
herdr agent wait <pane-id> --until working --timeout 30000
```

**`working` is the confirmation that the turn started.** Reaching `idle` or `done` without
having observed `working` means the brief never ran — re-read the pane before concluding
anything about the work.

### Start the watcher — mandatory, immediately after submit

**Every dispatched pane gets a watcher. No exceptions, no hand-rolled loops.**

**Claude runtime: use Monitor** — see `dispatch-ticket-claude` for the Monitor-based
watching section. The watcher script below is for **Codex and OpenCode only**.

```bash
<repo-root>/scripts/herdr-watch-terminal.sh <pane-id> 3 3600 120
```

Run this immediately after confirming `working`. For Codex/OpenCode, it is the ONLY
sanctioned way to monitor a dispatched builder. Do NOT write your own polling loop, do NOT
use `herdr agent wait --until idle` as a substitute, do NOT use `sleep` + `herdr agent get`
in a loop. The script has caffeinate (machine cannot sleep and kill the watch), a start
guard, debounce, and a 3600-second cap — hand-rolled alternatives lack all four.

Branch on `$?` **and the payload** when it returns:

- `0` + `TERMINAL:done` → builder's turn ended, **not necessarily finished** — check for background processes before concluding (see below)
- `0` + `TERMINAL:idle` → builder idle, check git log — may be finished or may have stopped early
- `0` + `TERMINAL:blocked` → builder is asking a question, **read pane immediately and answer** — do NOT proceed to artifact verification, the builder is waiting for you
- `1` + `TIMEOUT` → builder exceeded cap, inspect pane
- `2` + `NO_START` → builder never started working, re-read pane

**Read the payload, not just the exit code.** Exit 0 has four meanings now. `blocked` means
the builder hit a decision it cannot make alone — read the pane, answer the question, then
restart the watcher. Jumping straight to artifact verification on `blocked` leaves the
builder waiting indefinitely.

**`done` means the turn ended, not that the work finished** (AST-097). A builder that
launches background work and parks while waiting for a notification reads as `done` while its
artifact is still being built — measured three times on one pane in one session. Before
concluding finished: check TWO sources for active background work:

1. **OS processes** — `pgrep` for test runners, build tools, or the builder's own monitors
   whose argv contains the worktree path.
2. **Runtime status line** — `herdr agent read <pane-id>` renders the pane's status bar,
   which names shells and monitors the runtime itself tracks (ScheduleWakeup, Monitor).
   These are invisible to `pgrep`.

The two sources can disagree: measured on nizzy-ecom, `pgrep` returned 0 while the pane
status line read "1 shell, 1 monitor still running" — the builder had called ScheduleWakeup,
the call failed, and it parked waiting for a notification that would never arrive. Trusting
`pgrep` alone would have read STUCK; the status line read PARKED; the truth was
PARKED-permanently. **Disagreement between the two sources is itself a signal — read the
pane** (AST-097).

Processes or runtime tasks still running → PARKED, wait for exit, then re-check. All
quiet on BOTH sources AND no new commits since the last instruction → read the pane before
concluding — the turn may have crashed (529, OOM, context limit) with the error visible on
screen (AST-097). All quiet AND new commits since the last instruction → proceed to artifact
verification.

**`--wait` collapses submit, start-guard and settle into one call, and it is trustworthy
ONLY on a pane whose turn you just opened.** Herdr's own help says it "does not track turns:
if the agent is already working, that active turn's completion may match". Underneath that,
`--until idle` is satisfied by whatever the runtime's rules call idle — and measured on
0.8.0, `agent prompt --wait --until idle` returned SUCCESS on a Claude pane whose prompt had
not run, because an empty composer matches `prompt_box_body`. On opencode nothing
establishes idle at all. Either way you get a signal incapable of failing (AST-032).

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
visible ROW COUNT, and no `--lines` value gets past it — measured, `--lines 200` and
`--lines 1000` both returned 78 rows on a 78-row pane, and a socket read of 5000 lines
returned `truncated:false` and still only the screen. The read reports SUCCESS, so anything
longer than the viewport comes back silently cut. **Truncation is detectable**: `tab create`
and `agent get` expose `scroll.viewport_rows`, and a read returning exactly that many lines
is the signal — compare the count rather than judging by eye.

**Who writes the file follows the role.** An agent that may write (the Builder) writes into
the worktree it owns and replies with the path. A READ-ONLY agent (Rin)
returns its report and the DISPATCHER persists it — which keeps an artifact out of a
disposable gate worktree that cleanup is about to delete (AST-031, AST-032).

**herdr fails loudly, so its EXIT STATUS is trustworthy — it is the status FIELD that
lies.** Measured on 0.8.0, each exits 1 with a JSON `error`: an over-viewport read on a
working pane gives `agent_not_idle` with the fix named, a bad target `agent_not_found`, a
`--wait` with no state change `timeout`. Treat a non-zero herdr exit as a real failure worth
reading, and keep the scepticism for the `agent_status` it returns on success.

### Watcher script operational details (Codex/OpenCode only)

**Claude runtime uses Monitor — skip this section.** See `dispatch-ticket-claude`.

`<repo-root>/scripts/herdr-watch-terminal.sh` watches a NEWLY SUBMITTED turn: it waits to
observe `working` first, so pointing it at an already-idle pane returns `NO_START` —
truthful output rather than a fault. Point it at the pane whose turn you just opened. Any
role may read or watch any pane, and concurrent watchers are fine (three simultaneous waits
on one pane ran independently and timed out cleanly). Its exit status IS the signal
(`0`+`TERMINAL:<state>` / `1`+`TIMEOUT` / `2`+`NO_START`), so call it by absolute path,
alone on its own line, and branch on `$?`. Measured, these shapes discard it:

| shape | status |
| :--- | :--- |
| `watch.sh … \| tail -3` | **always lost** — the pipeline reports the last command |
| `watch.sh … \|\| true` / `\|\| echo "failed"` | **lost exactly when the watcher FAILS**, since that is when the right side runs; both failure codes are non-zero, so a real TIMEOUT or NO_START becomes 0 |
| `echo "$(watch.sh …)"`, `export v=$(…)`, `local v=$(…)` | lost |
| `v=$(watch.sh …)` (bare assignment) | preserved |
| `watch.sh … && rhs` | preserved on FAILURE; a success is overwritten by `rhs` |

`||` is the one to watch for: it is the shape people reach for when they are being careful,
and it converts precisely the failures you needed to hear about into silence (AST-032).

**Stopping a watch takes the process GROUP.** On macOS the watcher re-execs under
`caffeinate`, so `caffeinate` is the visible PID and killing it orphans the wrapped shell,
still polling. Signal the group, then confirm:

```bash
pgid=$(ps -o pgid= -p <watch-pid> | tr -d ' ')   # read it first — see below
kill -TERM -"$pgid"                              # leading '-' targets the GROUP
pgrep -g "$pgid" >/dev/null && echo SURVIVORS || echo clean
```

Verify with `pgrep` rather than `ps | grep herdr-watch-terminal`: that grep matches its own
command line, so it can never return empty — a check incapable of passing, the mirror of a
signal incapable of failing (AST-032). (`grep '[h]erdr-watch-terminal'` works too; the
brackets are what stop the pattern matching itself.) Read the PGID before signalling: a
watch launched inline from your own shell may share that shell's group, so a watch you
intend to group-kill belongs in its own.

Status is a bell. The verdict comes from branch movement, the diff, the tests, the final SHA
and the reported artifact. **Observation is unrestricted — reading or watching any pane is
always legal, and verify-by-artifact requires it. Only TASKING is restricted**, and Thomas
tasks the Builder directly, since there is no intermediate role.

## Long tickets

Keep one ticket in its assigned session. When the conversation grows long, write a durable
checkpoint BEFORE `/compact`: branch and SHA, clean or intentional WIP state, completed
acceptance criteria, exact validation results, blockers, next action — into the tracker or
the handoff artifact. Then `/compact` and re-ground from that artifact plus `git log` and
the current diff. Runtime auto-compaction carries the same re-grounding requirement.

`/clear` starts a fresh chat and discards the working thread, so it belongs between tickets
rather than inside one — and a new ticket takes a fresh pane and worktree anyway. It is not
cwd, branch, worktree, process or lifecycle cleanup.

## The simplify pass

**Each increment runs one simplify pass over its own diff, after the build is green.** The
artifact is a `simplify(increment):` commit on the ticket branch — real cleanup, or an
`--allow-empty` one reading `no findings on <base>..<head>` where the pass finds nothing. An
empty pass is legitimate; an ABSENT marker and an empty one are otherwise indistinguishable
in the tree, which is why the marker is the artifact.

**The commit body carries a `Pass:` line naming what ran**, because the subject cannot
distinguish the sanctioned pass from a substitute that produced the same string. The Builder
contract owns the exact form.

Behaviour-preserving only: dead code and orphans, duplication that appeared because two
changes touched one seam, wrong-altitude fixes, comments that no longer describe the code.
Anything that would change behaviour is a finding for Thomas rather than a change, and a
cleanup that would touch a floor item's construction line is reported instead.

Thomas verifies by artifact before the milestone gate —
`git log <base>..<head> --grep '^simplify(increment):' --format='%h %s%n%b'` — rather than by
asking whether the pass ran, and reads the `Pass:` line rather than only the subject.

## Review and cleanup

The Builder pushes and returns the artifact. Thomas reads the real diff, dispatches Rin's
milestone gate, and alone decides merge. A settled Herdr status does not authorize cleanup:
capture the final transcript and verify the merge or an explicit owner-approved abandonment
first. Herdr refuses to close the last tab in a workspace, so resolve the topology rather
than calling `tab close` blindly:

```bash
herdr tab list --workspace <returned-workspace-id>
herdr pane list --workspace <returned-workspace-id>
```

- Another tab remains → close the exact ticket tab: `herdr tab close <returned-tab-id>`.
- The ticket tab is last AND the inherited `workspace_managed_by_root=true` AND no owner
  resource or active ticket remains → close the exact workspace instead:
  `herdr workspace close <returned-workspace-id>`.
- The ticket tab is last and workspace ownership is false, missing or ambiguous → STOP.
  Record the survivor and ask whether to close or retain it. A dummy shell created to hide
  an orphan reports success while leaving the orphan.

Re-list the workspace and confirm the pane is absent before removing the checkout.

**Two checks before removing a worktree.** Both must pass — failing either is STOP.

**Check 1: uncommitted work** (AST-092). A Builder that stops before committing leaves work
that exists only on disk — `git worktree remove` deletes it silently.

```bash
cd <worktree-path>
git status --short
```

Non-empty output (staged, modified, or untracked files) — **STOP**. The worktree has work
that was not committed. Report to the owner with the file list and ticket id, and wait for a
decision: commit and continue, or discard explicitly.

**Check 2: simplify markers AND provenance** (AST-094, AST-099). A Builder that commits and
pushes correctly can still skip the simplify pass, or run a manual review and commit with
the correct subject but without invoking the skill.

```bash
MARKERS=$(git log <base>..HEAD --grep '^simplify(increment):' --oneline | wc -l | tr -d ' ')
WELLFORMED=$(git log <base>..HEAD --grep '^simplify(increment):' --format='%b' | grep -c '^Pass: Skill(skill: "simplify")' || true)
echo "markers=$MARKERS wellformed=$WELLFORMED"
```

Zero markers — **STOP** (AST-094). Send the Builder back to run simplify. Markers present
but well-formed fewer than markers — **STOP** (AST-099): some commits carry the simplify
subject without the skill's provenance. The two counts carry information only when they
disagree — print both, read both, act in a separate step. The Builder carries its own
self-check (`builder.md`), but the mechanism that causes the skip — the ticket checklist
displacing the contract — also displaces the self-check, so Thomas verifies independently.

**Only when both checks pass** — `git status` empty AND markers equal well-formed — is
removal safe:

```bash
git worktree remove <worktree-path>
git branch -d <ticket-branch>
git worktree prune
```

`-D` is for an explicitly owner-approved abandonment. Close only what this dispatch created.
Cleanup is complete when the Herdr tab and the Git worktree and branch are all retired, or
an exact retained-state reason is recorded for each survivor.
