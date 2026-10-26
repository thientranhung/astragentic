---
name: dispatch-ticket-claude
description: "Claude Code-specific dispatch protocol. Covers the astragentic-dispatch mod (the pane records itself, runs its brief, reports its turn end), the launcher matrix, pre-dispatch verification, and Claude runtime facts. Read dispatch-ticket for the shared protocol."
---

# Dispatch a ticket — Claude Code runtime

**Read `dispatch-ticket` for the shared protocol** (binding identity, worktree law, brief
format, cleanup). This skill adds the Claude Code launcher and the mod that does the steps a
dispatcher kept skipping. The mod `.claude/skills/astragentic-dispatch/` ships in the payload,
and every Claude session in the project loads it with no flag and no setup.

| Step | What the mod does |
|---|---|
| Record tab and pane ids | the pane writes them at session start, from herdr's own environment |
| Deliver the slash command | **one SendMessage**; the pane runs the first line as a real command |
| Confirm delivery | the pane answers `RECEIVED` |
| Watch the turn | the pane reports `TURN-END` when a turn ends with none of its agents still running, and wakes you with a prompt |
| Route a reply to you | the pane's overlay names your session; a SendMessage from it to any name no agent of its own carries is readdressed to you |
| Announce a newer release | at your session start the mod asks the package remote for its newest tag once and shows a chip on your band; `.astraler/astragentic.sh update` prints the gap and the one-liner. Applying stays the owner's call |
| Protect a working pane | `herdr tab\|pane\|workspace close` on a mid-turn pane is refused |
| Claim before the brief | a brief for a ticket the tracker reports unclaimed is not sent |
| Tracker write-back after a merge | the merge result carries the note, the line turns red, and no brief is sent until `scripts/ticket-done.sh` has stamped it |
| Release a worktree's resources | `release-worktree-resources.sh` runs at `git worktree remove`; the record entry goes with the worktree |
| Show which step a pane is at | the band shows chips from the record the gates read. Builder: implement · tdd · ux · review:matt · review:built-in · simplify · arm; Shaper: align · spec · tickets; QA: the role chip only. `✓` the step completed; `…` the step invoked most recently, in progress until a later step is invoked or a turn ends with nothing live, with the pane's live agent count (session-wide, not the step's own); `→` the next step; `○` pending; `n/a` exempted by the brief (`TDD: n/a`, `REVIEW: n/a`, `UX: n/a`, or a `FLOW:` line without `bmad-ux`); the ux chip appears only once a brief has said whether it is owed (4.5.3) |
| Seed a new worktree | `.astraler/project/setup-worktree.sh <path>` runs after a successful `git worktree add`; a failure is named in the result and the worktree is not to be dispatched into |
| Record which flow steps ran | every Skill call the Builder makes, as the engine expands it; `TURN-END` carries the list and a merge names the steps with no record |

**Three preconditions, all checkable:**

- **Claude Code 2.1.294 or later.** `check-requirements.sh` refuses older versions; below the
  floor the mod does not load and nothing else watches the pane.
- **The tab label is set before launch.** The mod reads `ticket:` / `spec:` / `qa:` from its tab
  at session start.
- **The mod is committed on the branch the worktree checks out.** The pane loads the copy in its
  own worktree.

**After launch, read the record back.** `.astraler/state/dispatch-record.json` must carry this
key with `pane_id` equal to the pane you created. If it is absent, a precondition failed:
STOP, because a pane the mod does not know about is unwatched.

## Submitting: one SendMessage

```
SendMessage({
  to: "<builder-session-name>",          // from ListAgents
  message: "/mattpocock-skills:implement ABC-123\n\nWorktree: … · Branch: … · Base: …\nAcceptance criteria: …"
})
```

**The first line is the slash command, and everything below it arrives as the command's
arguments.** A peer message is not a user turn, so it cannot invoke a
`disable-model-invocation` skill. The pane's mod runs the first line through `$.command.run`.
Steering is a plain SendMessage too: to an idle pane it becomes a user turn, to a mid-turn
pane it is delivered the normal way.

**Do not arm a Monitor, type into the pane, or write tab and pane ids by hand.** Each is a
second copy of something the mod does. The shared protocol's `herdr agent prompt` is for a pane
without the mod (a QA gate pane, a junior pane).

## What comes back

- **`RECEIVED`** is consumed silently; the line above your prompt moves the dispatch to `working`.
- **`TURN-END`** arrives as a prompt: *"builder ABC-123 ended its turn (answer). Its last
  words: …"*. It is a bell, not proof: a Builder that backgrounds its work sends one when it
  parks and another when the work lands. Read the last; verify by artifact. It carries
  `Skills run:`, so read that before the handback's claims.
- **A turn that ends while the pane's own sub-agents still run is held.** The board row reads
  *N agent(s) still running, turn end held*, and the one TURN-END comes when nothing is live.
  The hold has a ceiling of 20 minutes: past it your mod rings once with
  `reason=held-stale`, naming the agent count and age, and the row turns red. Read that pane
  and steer it to stop waiting.
- **`reason=command-failed`** means the pane refused the first line, usually an unknown command
  name. Fix the brief and send again.
- **Bells wait for your turn to end.** While you run a gate pass or hold a picker, arriving turn
  ends are held (the footer counts them) and flushed as one prompt.
- **A refused gate leaves a trace**: the refusal is appended to the record entry under
  `refusals`, written to `/tmp/harness-hook-events.log`, and shown red on the Builder's band for
  two minutes. "Did the gate fire" is answered from the record.
- **A TURN-END the pane could not send still arrives from the record within 30 s**, marked
  *read from the record*. Do not toggle a dispatched pane's permission mode: the launcher's
  `--dangerously-skip-permissions` keeps the message path open.
- **No `RECEIVED` within 90 s** turns the line red and your next prompt names the pane. Read
  it: the sender's `{"success": true}` is true even for a held message.
- **`/dispatch-board`** opens a pane listing every live dispatch with its state and age.
- **The band above the prompt** shows `⎇ <branch>`, the live dispatches (residents included),
  and one line from `.astraler/project/status-line.sh`. The plug prints one line and exits 0; a
  failing plug shows `status-line.sh failed`; absent, the band shows branch and dispatches only.
- **`AskUserQuestion` is refused in a dispatched pane.** The model decides from its evidence or
  reports the question in its handback.

## The project's rules travel as overlays

`.astraler/project/overlays/` is the project's, and no release writes into it.

| File | Where it lands |
|---|---|
| `overlays/<role>.md` (`builder`, `shaper`, `qa`) | appended to that role's system prompt on every render, so it survives compaction |
| `overlays/thomas.md` | the same, in the dispatcher's own session |
| `overlays/dispatch-brief.md` | appended to every brief the mod sends |

An overlay adds to the contract; where it would contradict one, the contract wins and the
conflict goes upstream. A rule that must refuse belongs in a plug script (`ticket-done.sh`, the
pre-push hook), not an overlay: prose can instruct, only a hook can stop.

## Two steps are refused, not noted

The Builder's pane refuses a content commit until a test file is staged with it or
already on the branch since dispatch (pattern: `.astraler/project/test-file-pattern`, or the
default `_test.`/`.test.`/`.spec.`/`tests/`/`__tests__/`); refuses the FIRST content commit
after a brief until `mattpocock-skills:tdd` has been called after that brief and a test run has
gone RED after it (4.5.2, from the PostToolUse hook's log; every Skill call is kept in the
record's `skills_log` with its time, so the merge gate reads the order too); and refuses the
arm (`codex-arm`) until the built-in `code-review` is in its record. The merge gate asks the same two questions of the
branch and the record, so a commit the pane let through is not refused at merge. **The
exemption is the dispatcher's and travels in the brief**: a line `TDD: n/a — <why>` (docs-only,
no seam), `REVIEW: n/a — <why>`, or `UX: n/a — <why>` (also implied by a `FLOW:` line that omits `bmad-ux`). The mod reads it from the brief it delivers, never from the Builder's
handback. A brief delivered outside the mod carries no exemption the mod can see, so on a
pane prompted by hand the gate holds until the brief is re-sent through SendMessage.

## The station owes QA, and the brief says which

**No QA plan, no dispatch.** A Builder brief is not sent until a committed
`docs/qa/plan-<slug>.md` covers the ticket. The brief names it on a `QA plan: <path>` line, and
the mod refuses a brief whose `QA:` mode is not `none` without one, or whose path does not
exist in this checkout. A loose ticket gets its plan from `test-design` over its acceptance
criteria; a ticket with no surface gets `QA: none — <why>` and needs no plan line.

**A Builder's brief carries `QA: walk|probe|verify|none — <why>`.** The board shows `qa ○ walk`
on that ticket until a QA pane keyed `qa:<key>` ends a turn after the Builder's last, then
`qa ✓ walk`; a merge without it carries a red note naming the mode owed. `none` with a reason
owes nothing.

**A QA pane is recorded under `qa:<key>`**, never the ticket's own key, which would overwrite
the Builder's entry. Its brief carries `Mode: walk|probe|verify`, which the mod records and
shows as a chip on the QA pane's band.

## A wait that cannot end is refused

In any dispatched pane the mod refuses a Bash command whose wait is keyed on a process name
(`until ! pgrep -f …`, `until ! ps … | grep …`: it matches its own shell and never exits) or
whose loop body has no sleep. The refusal carries the wait that works:
`cmd & pid=$!; while kill -0 $pid 2>/dev/null; do sleep 10; done; wait $pid`.

A project can add refusals: `.astraler/project/refused-in-dispatched-panes`, one regex per
line, `#` comments. A dispatched pane's Bash command matching one is denied. A `# reason: …` line
directly above a pattern is the refusal's text (e.g. `# reason: the station runs the whole suite;
run only your touched packages`); other comments are not, and a pattern with no reason line gets
the default, which says the owner runs it.

## The flow is read from what ran

The brief's `FLOW:` line names the Skill calls in order: `mattpocock-skills:tdd`, `bmad-ux`
(UI ticket), `mattpocock-skills:code-review`, the built-in `code-review`, `simplify`. The Builder's pane
records each at the moment the engine expands it, under `skills_run` in its record entry. A
plugin skill is recorded qualified, a built-in bare, so the two reviews that share a word are
told apart.

- **`TURN-END` carries `Skills run: …`.**
- **A merge names the gaps**: *"ABC-123 merged with no record of: tdd, built-in code-review"*.
  It is a note, not a refusal. A step the handback names `n/a` with its reason is legitimate,
  and the mod cannot read reasons. Any other gap is a step that did not run.
- **Only a pane the mod registered is judged.** A junior pane has no `session_id` in its entry;
  its evidence is the `Implemented-by:` trailers.
- **A fork's call is recorded under the Builder.**

## The tracker: claimed before the brief, closed before the next one

The checks sit at the brief, on the answer of the project's plug
`.astraler/project/tracker-state.sh <id>`: one line, `<state> <assignee-or-dash>`, the same plug
`ticket-done.sh` asks.

- **Claimed before the brief.** A brief whose first line names a ticket the plug reports with
  assignee `-`, or with state `closed` or `unclaimed`, is not sent, and the refusal says why. A
  project whose claim is a status or a label makes its plug print `unclaimed` until that is set.
- **Closed before the next brief.** A Builder ticket whose branch has commits of its own and
  reached the base, or that a `gh pr merge` merged, with no ticket-done stamp, holds every
  brief. The note arrives in the merge command's own result. `scripts/ticket-done.sh <id>`
  clears it after the plug confirms the ticket is closed and released.
- **A half-applied harness upgrade holds every brief.** `install.sh --apply` that stops on
  conflicts leaves `.astraler/state/apply-incomplete`; while it exists no brief is sent and
  the refusal lists the unreconciled paths. Reconcile, stamp `applied-version`, delete the marker.
- **Payload edited but not committed holds every brief.** A worktree checks out HEAD, so a
  payload file edited in the main checkout reaches the dispatcher and never the agent. While
  any file of the applied release's payload is modified or untracked, no brief is sent, and the
  refusal lists them. Commit or revert; or add a line `Uncommitted-payload: <why this brief is
  unaffected>`, which goes through and reaches the agent. This check is a lint, not a boundary:
  when it cannot read the applied version, the release tree or `git status`, it lets the
  brief go. `check-requirements.sh` reports the same state, but only at adaptation.
- **No answer, no check.** An absent plug, a failing one, and one that prints `unreachable`
  are an empty socket: briefs go, and `scripts/ticket-done.sh` stamps the tracker half as
  unverified.

## Cleanup: the release runs at removal

**Pass the worktree as a literal path.** A path with `$`, a backtick or `~`, or one that
`git worktree list` does not know, is refused: the hook runs before the shell expands
variables, and an expanded form once slipped past every protection below.

`git worktree remove <path>` on a recorded worktree runs `release-worktree-resources.sh <path>`
first: it reaps processes rooted there, runs the project's teardown plug and stamps the path.
It runs only when the worktree's agent is not mid-turn and its tree is clean, or `--force` was
given; if the release fails, the removal is refused with its output. The release reaps the
agent, and herdr closes a tab whose last pane exited, so `tab close` answering not-found is
expected. The record entry is deleted once the worktree and the tab are both gone.

## What the mod cannot see

- **A pane whose process died.** The mod dies with it; the workspace watchdog is what sees it
  (`dispatch-ticket/WATCHING.md`).
- **A pane that never recorded itself.** See the read-back above.
- **A resident pane without a `resident:` label.** A long-lived pane the owner keeps is
  recorded, shown on the board and refused a close only when its tab is labelled
  `resident:<name>` before launch.
- **A QA gate pane or a junior pane.** They run no Claude mod, so they keep the watcher script
  (`dispatch-ticket/WATCHING.md`).

**Trust boundary.** A consumed message skips the receiver's `crossSessionInbound` hold. On the
dispatcher side the mod consumes only its own marked messages whose key and pane match the
record. On a dispatched pane it consumes every peer message, the trust a pane launched with
`--dangerously-skip-permissions` already extends to its dispatcher.

## Launcher matrix — Claude rows

```text
builder  → claude --dangerously-skip-permissions --agent builder --model <row: Model> --autocompact 300000 <--effort only when the row sets one> <--advisor only when the row sets one>
shaper   → claude --dangerously-skip-permissions --agent shaper --model <row: Model> --autocompact 300000 <--effort only when the row sets one> <--advisor only when the row sets one>
qa       → claude --agent qa --model <row: Model> --autocompact 300000 <--effort only when the row sets one> <--advisor only when the row sets one>
```

Model and effort come from the role's `orchestrator.md` row, never from memory. **QA runs
without `--dangerously-skip-permissions`**: a gate runs under permissions.

**`--autocompact 300000` is the context ceiling, and it is not optional.** The engine's window
for these models is 1M and a dispatched pane runs its whole flow in one context, so nothing
else trims it: one project's Builders ran a median 400–550k tokens of context per call. The
flag makes the engine compact at 300k; the mod compacts a pane that ends a turn over the same
ceiling (`ASTRAGENTIC_CONTEXT_CEILING` changes it) in case a launch forgot the flag. About 90k
of every call is standing load compaction cannot touch, and context grows about 1.2k per call,
so 300k compacts every ~170 calls where 200k would compact every ~90. Pass the same window as
the pane's environment too, `herdr pane split … --env CLAUDE_CODE_AUTO_COMPACT_WINDOW=300000`;
the env var overrides a forgotten or mistyped flag.

Add `--effort` only when the row sets it (`low|medium|high|xhigh|max`). Add `--advisor <value>`
only when the row's Advisor cell is set (pairing rules: `orchestrator.md`); a session that
could not attach the advisor says `cannot advise` at launch and runs without it.

## Pre-dispatch verification

Both files must exist in the worktree before launching. A missing adapter means the payload was
not committed or was gitignored; without the mod the pane runs but nothing records it,
delivers its command, or reports its turn end.

```bash
test -f <worktree-path>/.claude/agents/<role>.md || echo "STOP: adapter missing"
test -f <worktree-path>/.claude/skills/astragentic-dispatch/hooks/register.tsx || echo "STOP: dispatch mod missing"
```

## Launch

For **builder** and **shaper** (write roles):

```bash
herdr agent start "<role>-<ticket-id-lowercased>" --kind claude --pane <pane-id> --timeout 60000 \
  -- --dangerously-skip-permissions --agent <role> --model <row: Model> --autocompact 300000 <--effort only when the row sets one> <--advisor only when the row sets one>
```

For **qa** (no `--dangerously-skip-permissions`):

```bash
herdr agent start "<role>-<artifact-key-lowercased>" --kind claude --pane <pane-id> --timeout 60000 \
  -- --agent <role> --model <row: Model> --autocompact 300000 <--effort only when the row sets one> <--advisor only when the row sets one>
```

`agent start` refuses an argument containing a newline (`invalid_agent_argument`). A launch it
cannot encode goes through `herdr pane run` plus `herdr agent rename`; either way the pane ends
with a registered agent name.

## Measured runtime facts

These describe how herdr reads a Claude pane. The mod does not depend on them; the watchdog
does. `prompt_box_body` at priority 950 matches `"❯\n"`, so **an empty Claude composer reads as
idle**: a multi-line brief sitting unsent reports `idle`, and a pane read as `idle` has not
necessarily started (the watchdog's `NEVER_STARTED` exists for this). `working` and `blocked`
are rule-backed; `idle` is rule-backed on weak evidence. Verify by artifact.
