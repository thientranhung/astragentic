---
name: dispatch-ticket-claude
description: "Claude Code-specific dispatch protocol. Covers the astragentic-dispatch mod (the pane records itself, runs its brief, reports its turn end), the launcher matrix, pre-dispatch verification, and Claude runtime facts. Read dispatch-ticket for the shared protocol."
---

# Dispatch a ticket — Claude Code runtime

**Read `dispatch-ticket` for the shared protocol** (binding identity, inputs/resolution,
worktree law, brief format, simplify, cleanup). This skill adds the Claude Code launcher and
the mod that does three steps of a dispatch for you.

## The mod does the steps that got skipped

Writing the dispatch record, arming the watch, and typing the slash command into the pane
were each a rule in prose, and each was skipped in production on the same day. A guessed tab
id closed a working Builder, and a hand-rolled `while true; sleep` loop stood in for the
watcher. A rule read at hour zero loses to the tool description in front of you at hour five
(AST-041, AST-069). So on a Claude root these steps are no longer yours. The mod
`.claude/skills/astragentic-dispatch/` ships in the payload, and every Claude session in the
project loads it with no flag and no setup:

| Step | Before | Now |
|---|---|---|
| Record tab and pane ids | copied by hand from the create output | the pane writes them at session start, from herdr's own environment |
| Deliver the slash command | SendMessage for the body, type the command into the pane, confirm the echo | **one SendMessage**; the pane runs the first line as a real command |
| Confirm delivery | read the pane for a phrase only the brief had | the pane answers `RECEIVED` |
| Watch the turn | a Monitor wrapping the watcher script, re-armed for every turn | the pane reports `TURN-END` at every turn end, and the mod wakes you with a prompt |
| Protect a working pane | nothing | `herdr tab\|pane\|workspace close` on a mid-turn pane is refused |
| Claim on the tracker before the brief | prose in `thomas.md` | a brief for a ticket the tracker reports unclaimed is not sent |
| Tracker write-back after a merge | refused only at a push of the base | the merge result carries the note, the line turns red, and no brief is sent until `scripts/ticket-done.sh` has stamped it |
| Release a worktree's resources | `release-worktree-resources.sh` by hand before removal | runs at `git worktree remove`, and the record entry goes with the worktree |

Measured 2026-10-05 on Claude Code 2.1.289 and herdr 0.9.1, with a Builder in its own
worktree. The record carried the right tab and pane ids. A phrase that existed only in the
brief body came back in the Builder's answer. Wake-up arrived under one second after the turn
ended, where pane-state polling was 67 s late (AST-097). A `herdr tab close` on the working
Builder's tab was refused.

**Three preconditions, all checkable:**

- **Claude Code 2.1.289 or later.** `check-requirements.sh` refuses older versions. Below the
  floor the mod does not load, and nothing else watches the pane.
- **The tab label is set before launch.** The mod reads `ticket:` / `spec:` / `qa:` / `rin:`
  from its tab at session start. A pane labelled after launch never records itself.
- **The mod is committed on the branch the worktree checks out.** The pane loads the copy in
  its own worktree, so a payload that is not committed is not there (AST-036).

**After launch, read the record back.** `.astraler/state/dispatch-record.json` must carry this
key with `pane_id` equal to the pane you created. If it is absent, one of the three
preconditions failed. STOP: a pane the mod does not know about is unwatched, exactly like a
missing Monitor used to be.

## Submitting: one SendMessage

```
SendMessage({
  to: "<builder-session-name>",          // from ListAgents
  message: "/mattpocock-skills:implement ABC-123\n\nWorktree: … · Branch: … · Base: …\nAcceptance criteria: …"
})
```

**The first line is the slash command, and everything below it arrives as the command's
arguments.** A peer message is not a user turn, so it cannot invoke a `disable-model-invocation`
skill (AST-112). The pane's mod takes the message and runs the first line through
`$.command.run`, which is a real user command. No typing into the pane, no echo check.

**Steering is a plain SendMessage too.** To an idle pane it becomes a user turn. To a pane
mid-turn it is delivered the normal way, so the running turn can read it.

**Do not arm a Monitor, type into the pane, or write tab and pane ids by hand.** Each of those
is now a second copy of something the mod does, and a second copy is where the two drift.

## What comes back

- **`RECEIVED`** is consumed silently. The line above your prompt moves the dispatch to
  `working`.
- **`TURN-END`** arrives as a prompt in your session: *"builder ABC-123 ended its turn
  (answer). Its last words: …"*. **It is a bell, not proof.** A turn ending is not the work
  finishing (AST-097). A Builder that backgrounds its work sends one TURN-END when it parks and
  another when the background work lands, and both were measured. Verify by artifact.
- **`reason=command-failed`** means the pane refused the first line, usually an unknown command
  name. Fix the brief and send again.
- **No `RECEIVED` within 90 s** turns the line red, and your next prompt carries a note naming
  the pane. Read that pane: the message may be held or lost. The sender's `{"success": true}`
  is true even for a held message (measured), so it proves nothing.
- **`/dispatch-board`** opens a pane listing every live dispatch with its state and age.

## The tracker: claimed before the brief, closed before the next one

Both ends of a ticket's tracker state were remembered sometimes. A dispatched ticket stayed in
its ready state, and a merged one stayed in progress (AST-074). The brief is the one moment every
dispatch passes through, so the checks sit there, on the answer of the project's own plug
`.astraler/project/tracker-state.sh <id>`: one line, `<state> <assignee-or-dash>`, the same plug
`ticket-done.sh` asks.

- **Claimed before the brief.** A brief whose first line names a ticket the plug reports with
  assignee `-`, or with state `closed` or `unclaimed`, is not sent. The refusal says why. A
  project whose claim is a status or a label makes its plug print `unclaimed` until that is
  set; the vocabulary stays the project's.
- **Closed before the next brief.** A Builder ticket whose branch has commits of its own and
  reached the base, or that a `gh pr merge` merged, with no ticket-done stamp, holds every
  brief. The note arrives in the merge command's own result, so it lands in the same turn as the
  merge. `scripts/ticket-done.sh <id>` clears it, and it asks the same plug that the ticket is
  closed and released. The base-push guard missed `gh pr merge` and merge-and-hold, which is
  where the write-back was forgotten (AST-057).
- **A harness upgrade still half-applied holds every brief.** `install.sh --apply` that stops on
  conflicts leaves `.astraler/state/apply-incomplete`, and the unreconciled files are the role
  contracts the next agent reads. While the marker exists, no brief is sent, and the refusal
  lists the paths. Reconcile them, stamp `applied-version`, then delete the marker.
- **Payload edited but not committed holds every brief.** A worktree checks out HEAD, so a
  payload file edited in the main checkout (a role contract, `orchestrator.md`) reaches the
  dispatcher and never the agent (AST-036). While any file of the applied release's payload is
  modified or untracked here, no brief is sent, and the refusal lists them with what to do.
  Commit or revert; or, when this brief does not depend on them, add a line
  `Uncommitted-payload: <why this brief is unaffected>`, which goes through and reaches the
  agent with the brief. Measured downstream: about one commit in six passes through this state
  in ordinary work, so a gate with no way through except committing half-written rules would
  teach committing them. `check-requirements.sh` reports the same state, but only at
  adaptation: after the first upgrade it was measured letting the first dispatch through.
  **This check is a lint, not a boundary.** When it cannot read the applied version, the
  release tree or `git status`, it lets the brief go rather than block every dispatch on a
  transient failure. Do not cite it as proof that a dirty payload cannot be dispatched. Scoping it
  to what each role reads was rejected: that source exists only as prose in each contract's Load
  table, and a gate whose correctness depends on how a markdown table is formatted fails in a
  direction nobody can predict.
- **No answer, no check.** An absent plug, one that fails, and one that prints `unreachable` are
  an empty socket: briefs go, and `scripts/ticket-done.sh` stamps the tracker half as unverified, as before.
  A check that cannot answer must not refuse every dispatch.

Measured 2026-10-05: a brief for a ticket reporting `open -` was refused, and the Builder received
nothing. After the merge, the note arrived with the merge result, the line turned red, and the
next brief was refused until the dispatcher closed the ticket and ran `scripts/ticket-done.sh`. It did that
at once, in the turn that read the note.

## Cleanup: the release runs at removal

`git worktree remove <path>` on a recorded worktree runs `release-worktree-resources.sh <path>`
first: it reaps processes rooted there, runs the project's teardown plug and stamps the path.
It runs only when the worktree's agent is not mid-turn and its tree is clean, or `--force` was
given. The release tears down live state, so it must never run for a removal the git guard is
about to refuse (AST-115). If the release fails, the removal is refused with its output.

The release reaps the agent in that worktree, and herdr closes a tab whose last pane exited. The
tab is usually gone before you close it, so a `tab close` answering not-found is expected. The
record entry is deleted once the worktree and the tab are both gone. Measured: release ran,
stamp written, Builder reaped, tab closed, entry gone, with no step besides the removal.

## What the mod cannot see

- **A pane whose process died.** The mod dies with it. The workspace watchdog still covers this
  (`dispatch-ticket/WATCHING.md`), and it stays mandatory.
- **A pane that never recorded itself.** See the read-back above.
- **Codex and OpenCode panes.** They run no Claude mod, so they keep the watcher script and its
  protocol in `dispatch-ticket`.

**Trust boundary.** A consumed message skips the receiver's `crossSessionInbound` hold. On the
dispatcher side the mod consumes only its own marked messages whose key and pane match the
record. On a dispatched pane it consumes every peer message, which is the same trust a pane
launched with `--dangerously-skip-permissions` already extends to its dispatcher.

## Launcher matrix — Claude rows

```text
builder  → claude --dangerously-skip-permissions --agent builder --model <row: Model> <--effort only when the row sets one>
shaper   → claude --dangerously-skip-permissions --agent shaper --model <row: Model> <--effort only when the row sets one>
rin      → claude --agent rin --model <row: Model> <--effort only when the row sets one>
qa       → claude --agent qa --model <row: Model> <--effort only when the row sets one>
```

Model and effort come from the role's `orchestrator.md` row, never from memory.

Add `--effort` only when the row sets it (`low|medium|high|xhigh|max`); blank means the
runtime default. **Rin runs without `--dangerously-skip-permissions`**: a gate runs under
permissions, and rin has no fallback row, so no other runtime is legal here.

## Pre-dispatch verification

Verify the adapter exists in the worktree before launching:

```bash
test -f <worktree-path>/.claude/agents/<role>.md || echo "STOP: adapter missing"
```

A missing adapter means the payload was not committed or was gitignored (AST-036). The
shared protocol's worktree-visibility check catches this too, but this is the exact file
`claude --agent <role>` will try to load.

Verify the mod is in the worktree too. Without it the pane runs, but nothing records it,
delivers its command, or reports its turn end:

```bash
test -f <worktree-path>/.claude/skills/astragentic-dispatch/hooks/register.tsx || echo "STOP: dispatch mod missing"
```

## Launch

For **builder** and **shaper** (write roles):

```bash
herdr agent start "<role>-<ticket-id>" --kind claude --pane <pane-id> --timeout 60000 \
  -- --dangerously-skip-permissions --agent <role> --model <row: Model> <--effort only when the row sets one>
```

For **rin** and **qa** (review roles — no `--dangerously-skip-permissions`):

```bash
herdr agent start "<role>-<artifact-key>" --kind claude --pane <pane-id> --timeout 60000 \
  -- --agent <role> --model <row: Model> <--effort only when the row sets one>
```

## Measured runtime facts

These describe how herdr reads a Claude pane. The mod does not depend on them, but the
workspace watchdog still does.

**Claude idle rule.** `prompt_box_body` at priority 950 matches `"❯\n"`, so **an empty
Claude composer reads as idle**. This means:

- A multi-line brief sitting unsent in the composer reports `idle` — the dispatcher trusts
  it and concludes the Builder finished instantly (AST-032, AST-037).
- A pane read as `idle` has not necessarily started. The watchdog's `NEVER_STARTED` exists for this.

**Runtime detection quality.** Claude tops out at `osc_title` 1100 then falls to text
regions. `working` and `blocked` are rule-backed; `idle` is rule-backed but its evidence is
weak (the empty-composer match above). Verify by artifact.
