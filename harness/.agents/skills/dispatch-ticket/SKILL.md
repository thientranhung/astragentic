---
name: dispatch-ticket
description: Dispatch one claimed ticket as a visible Herdr pane on any supported runtime (Claude Code, Codex, opencode) — one Builder, one worktree, one branch, one pane. Runtime/model/effort resolve from .agents/orchestrator.md; runtime=claude|codex|opencode is an explicit per-dispatch override. Use when Thomas has a ticket on the frontier, assigned, and ready to build.
---

# Dispatch a ticket — one Builder, one worktree, one pane

Role contract: `.agents/roles/builder.md`. Runtime, model and effort per role:
`.agents/orchestrator.md` (owner-editable; Thomas reads it at session start; edits take
effect at the next dispatch). Runtime changes the executables. The roles, the worktree, the
Herdr topology and the artifact contract stay identical across all three.

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

**An override re-resolves the WHOLE row, not just the Runtime cell (AST-030).** The role uses
the `orchestrator.md` row that already targets that runtime — runtime, model and effort
together. Where no row targets the overridden runtime, stop and ask the owner.

**Resolution order:** the active row → if that runtime is genuinely unavailable (CLI
missing, auth failed, quota exhausted), the role's Fallback row, with the degradation
REPORTED to the owner. Degradation is per-session and stays out of the file.

**A missing row is an answer, not a gap to fill.** An absent fallback means that role has no
fallback, so an unavailable active runtime is a STOP. Where `orchestrator.md` itself is
missing or a row is ambiguous, Thomas asks the owner for the model and scaffolds the file
before dispatching — inferring a runtime from installed binaries or from the task text
produces a confident wrong answer.

Launcher matrix — model and effort come from the role's row:

```text
claude   → claude --dangerously-skip-permissions --agent builder --model <row: Model> --effort <row: Effort>
codex    → codex --profile builder --yolo
opencode → opencode --agent builder -m <row: Model> --auto        (TUI form)
```

Add `--effort` on Claude only when the row sets it (`low|medium|high|xhigh|max`); blank
means the runtime default. Codex effort lives in the machine profile TOML as
`model_reasoning_effort`, not on the command line. **opencode rows leave Effort blank** —
it is unreachable there (fact 2 below), so a non-blank opencode Effort cell is a
misconfigured row: stop and ask the owner.

`visibility=headless` is legal only when explicitly requested with a resolved runtime of
codex; route to `codex-dispatch-headless`. Claude headless implementation is unsupported.

For a codex-resolved role, verify `${CODEX_HOME:-$HOME/.codex}/builder.config.toml` exists,
matches the tracked template `.codex/profiles/builder.config.toml`, and agrees with the
row's Model/Effort. Where it is absent or drifted, give the owner the exact copy and diff
commands and get explicit confirmation. opencode roles need no machine profile — the model
travels on the command line, and the adapters are project-tracked `.opencode/agents/*.md`;
confirm they list via `opencode agent list --pure` from the worktree (`--pure` skips
external plugins, which otherwise filter project agents out of the listing).

## Measured runtime facts that decide what a signal is worth

Re-measured on herdr 0.8.0 and opencode 1.18.11:

1. `herdr agent start --kind opencode` works on 0.8.0 — exit 0, agent detected, process
   confirmed alive with `pgrep` rather than by trusting `interactive_ready`. `agent start`
   is the launch for all three runtimes.
2. `opencode run` requires a positional message, so it cannot start a message-less
   persistent executor; the TUI form is the persistent one and has no `--variant`. The
   `--variant` form is invisible to herdr. Effort and orchestration visibility are mutually
   exclusive on opencode, and visibility wins — which is why opencode Effort stays blank.
3. **opencode's `idle` is FABRICATED.** `herdr agent explain` reports
   `fallback_reason: default_known_agent_idle_fallback`, and `agent wait --until idle`
   returned rc=0 in 8 ms on a pane nobody had touched. Its manifest carries 3 rules
   (claude 12, codex 7), covering only `blocked` and `working`. So on opencode `working`
   and `blocked` are OBSERVED while idle is ASSUMED: the watcher's start guard still works,
   terminal-state detection does not, and a verdict must come from an artifact (AST-032).
4. Runtime detection quality is a ladder. Codex's top rules are `osc_title` (1100, 1050) —
   the agent's own title, which beats scraping. Claude tops out at `osc_title` 1100 then
   falls to text regions, including `prompt_box_body` at 950 whose evidence is `"❯\n"`, so
   **an empty Claude composer reads as idle**. opencode establishes idle not at all.
   Verify by artifact on every runtime; on opencode it is the only thing that works.
5. Reading an opencode TUI transcript via `herdr agent read` returns only the input box and
   footer. Tolerable under verify-by-artifact — review diffs, not pane narration.

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
`<repo-parent>/<repo-dir-name>.worktrees/<branch-slug>` (branch `/` → `-`), outside the repo
checkout and outside system tmp (AST-028). A relative path once resolved through a stale
shell cwd to a location INSIDE the repo, which is why the absolute form is fixed here.

```bash
git worktree list
git worktree add -b <ticket-branch> <worktree-path> <base>   # ABSOLUTE
git worktree list   # verify the new entry is exactly <worktree-path>
herdr workspace list
```

Resolve the project/epic workspace from `herdr workspace list`. Reuse an exact existing
workspace only where it represents the same project/epic and its durable record matches the
returned ID. Otherwise create one rooted at the repo, and record
`workspace_managed_by_root=true` at workspace level immediately:

```bash
herdr workspace create --label "<workspace-label>" --cwd <repo-root> --no-focus
```

The workspace is project-scoped and outlives any one ticket, while a ticket's worktree is
removed at cleanup — so the workspace cwd stays at repo-root rather than binding to the
first worktree.

A new workspace already owns an initial tab and root pane. Read the create response, then
`herdr tab list` / `herdr pane list`, and rename that initial tab and pane for the first
ticket rather than creating a redundant shell:

```bash
herdr tab rename <returned-initial-tab-id> "ticket:<ticket-id>"
herdr pane rename <returned-root-pane-id> "builder:<ticket-id>"
herdr pane send-text <returned-root-pane-id> "cd <worktree-path>"
herdr pane send-keys <returned-root-pane-id> Enter
```

Where the workspace already exists, create exactly one additional tab for the new ticket and
read its returned pane ID — its other tabs may be owner-owned or hold an active ticket:

```bash
herdr tab create --workspace <workspace-id> --label "ticket:<ticket-id>" \
  --cwd <worktree-path> --no-focus
herdr pane rename <returned-root-pane-id> "builder:<ticket-id>"
```

**Mandatory cwd gate before launch.** `--cwd` on create is not guaranteed to stick, and
`claude --agent <name>` resolves the agent definition FROM the cwd — launched from `$HOME`
it errors "agent not found" or runs an unintended default. Confirm the pane's
`foreground_cwd` equals `<worktree-path>` via `herdr pane get <pane-id>`; a mismatch is a
STOP (fix with `herdr pane run <pane-id> "cd <worktree-path>"`, then re-verify).

**Agent names and pane labels are different strings.** `herdr agent start` accepts lowercase
letters, digits, `-` and `_` — no `:` — while pane labels take `:`. So the agent is
`builder-<ticket-id>` while the pane is `builder:<ticket-id>`. Passing a pane label as an
agent name fails the dispatch.

Print the resolved dispatch before launching:

```text
role=builder
runtime=<claude|codex|opencode from orchestrator.md (or explicit override)>
topology=herdr
executable=<exact launcher command>
ticket=<ticket id>            worktree=<absolute path>
branch=<ticket branch>        workspace=<returned workspace id>
workspace_managed_by_root=<true|false inherited from the durable record>
tab=<returned tab id>         pane=<returned pane id>
```

Then launch:

```bash
herdr agent start "builder-<ticket-id>" --kind claude --pane <pane-id> --timeout 60000 \
  -- --dangerously-skip-permissions --agent builder --model <row: Model> --effort <row: Effort>

herdr agent start "builder-<ticket-id>" --kind codex --pane <pane-id> --timeout 60000 \
  -- --profile builder --yolo

herdr agent start "builder-<ticket-id>" --kind opencode --pane <pane-id> --timeout 60000 \
  -- --agent builder -m <row: Model> --auto
```

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
slash command itself, and the rest of the brief follows it:

```text
/implement TICKET-123

Worktree: … · Branch: … · Base: …
Acceptance criteria: …
Owner intent: …
Validation: …
```

This is what "an agent playing the human at that step" means mechanically. Verify by
artifact that the skill actually ran — its own output in the transcript — rather than by the
brief having been sent.

### Submitting it

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

**`--wait` collapses submit, start-guard and settle into one call, and it is trustworthy
ONLY on a pane whose turn you just opened.** Herdr's own help says it "does not track turns:
if the agent is already working, that active turn's completion may match". Underneath that,
`--until idle` is satisfied by whatever the runtime's rules call idle — and measured on
0.8.0, `agent prompt --wait --until idle` returned SUCCESS on a Claude pane whose prompt had
not run, because an empty composer matches `prompt_box_body`. On opencode nothing
establishes idle at all. Either way you get a signal incapable of failing (AST-032).

**So for any pane you did not prompt in that same call** — watching another role's pane,
resuming after a break, waiting on an artifact — the start guard
`scripts/herdr-watch-terminal.sh` stays MANDATORY. It observes `working` for THIS turn
before it blesses anything, and `working` is rule-backed on all three runtimes.

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
the worktree it owns and replies with the path. A READ-ONLY agent (Rin, `code-scout`)
returns its report and the DISPATCHER persists it — which keeps an artifact out of a
disposable gate worktree that cleanup is about to delete (AST-031, AST-032).

**herdr fails loudly, so its EXIT STATUS is trustworthy — it is the status FIELD that
lies.** Measured on 0.8.0, each exits 1 with a JSON `error`: an over-viewport read on a
working pane gives `agent_not_idle` with the fix named, a bad target `agent_not_found`, a
`--wait` with no state change `timeout`. Treat a non-zero herdr exit as a real failure worth
reading, and keep the scepticism for the `agent_status` it returns on success.

**Watching.** `scripts/herdr-watch-terminal.sh` watches a NEWLY SUBMITTED turn: it waits to
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
artifact is a `simplify(increment):` commit on the ticket branch — real cleanup, or
`git commit --allow-empty -m "simplify(increment): no findings on <base>..<head>"` where the
pass finds nothing. An empty pass is legitimate; an ABSENT marker and an empty one are
otherwise indistinguishable in the tree, which is why the marker is the artifact.

Behaviour-preserving only: dead code and orphans, duplication that appeared because two
changes touched one seam, wrong-altitude fixes, comments that no longer describe the code.
Anything that would change behaviour is a finding for Thomas rather than a change, and a
cleanup that would touch a floor item's construction line is reported instead.

Thomas verifies by artifact before the milestone gate —
`git log --oneline <base>..<head> --grep '^simplify(increment):'` — rather than by asking
whether the pass ran.

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

```bash
git worktree remove <worktree-path>
git branch -d <ticket-branch>
git worktree prune
```

`-D` is for an explicitly owner-approved abandonment. Close only what this dispatch created.
Cleanup is complete when the Herdr tab and the Git worktree and branch are all retired, or
an exact retained-state reason is recorded for each survivor.
