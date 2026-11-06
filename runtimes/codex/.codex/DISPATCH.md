# Codex dispatch — native commands and one Markdown record

Read for worker dispatch, follow-up, recovery and cleanup. Thomas is the only writer
of the dispatch record. Workers write their own reports. There is no custom scheduler,
receipt service or lifecycle engine. Checks below are coordinator responsibilities;
only Git's branch/worktree checks and the native tools enforce their own invariants.

## Before launch

Use one Thomas per project frontier. Resolve tracker readiness, parent/dependency
status, authorization and available capacity from the Codex orchestrator. Builders
may run concurrently only with disjoint write-sets and independent prerequisites.
Use a deterministic ticket branch so a duplicate `git worktree add -b` fails instead
of creating another writer. Do not delete a conflicting branch to make it succeed.

Create `.scratch/codex/<dispatch-id>.md` in the coordinator checkout. Record:

```markdown
# Dispatch <id>
Role / ticket / kind:
Project / base SHA:
Branch / worktree:
Herdr workspace / tab / pane:
Coordinator thread UUID / worker thread UUID:
Model / effort:
Brief path / SHA-256:
Write-set / forbidden paths:
QA plan and cases (Builder/QA); effort scope (Shaper):
Junior and cross-vendor policy:
Current phase / last observed time:
Spec revision / release decision (Shaper only):
Report path / reviewed HEAD / validation:

| Event ID | Direction | Purpose | Sent | ACK | Result |
|---|---|---|---|---|---|
```

Write a separate brief with intent, criteria, write-set, exact base, validation commands,
QA plan/cases, UI Glance/States where applicable, authorized mutations and handback
path. Shaper produces its QA plan after Spec release; do not require that future plan
at shaping startup. Resolve the base to a SHA before launch, not a moving branch name.

## Launch

Check `HERDR_ENV=1`, current installed `herdr agent start --help`, and the project's
explicit workspace ID from `herdr workspace list`. Never infer IDs from UI focus.
For an isolated worker, use these native operations with the resolved values:

```sh
git worktree add -b "$TICKET_BRANCH" "$WORKTREE" "$BASE_SHA"
```

When Herdr's native worktree API is the authorized creation surface, inspect its
installed help and use `herdr worktree create --cwd <repo-parent-checkout> --branch
<ticket-branch> --base <base-SHA> --path <worktree> --label <dispatch-id> --no-focus`.
Herdr rejects a linked worktree as the source; resolve the repository parent through
its worktree inventory, not by guessing a directory. Record the returned workspace,
tab and pane and reuse them instead of creating another tab below. Do not add
`--trust-repository` or change trust to make creation pass.

Install the Codex overlay in the new worktree before starting it. A worktree created
from an older base does not inherit the coordinator's uncommitted installed files.
Use the source harness's `runtimes/codex/install.py install --project "$WORKTREE" --apply`.
Carry the coordinator's owner-config snapshot into a fresh worktree before installation
when that config is absent; if an existing config differs, resolve the difference
explicitly rather than silently overwriting it. Run the installer doctor there. Skills
and helper TOMLs must be discoverable in the worker checkout, not only its parent.

```sh
herdr tab create --workspace "$WORKSPACE_ID" --cwd "$WORKTREE" --label "$DISPATCH_ID" --no-focus
```

Read tab/pane IDs from the response and record them immediately. Select model/effort
from `orchestrator-for-codex.md`; builder-quick uses the Builder contract but the quick
model row. Do not invent `codex --agent` for a business role. Start the native CLI:

Use a stable agent launch name with letters, digits, hyphens or underscores; the
installed Herdr rejects dots in agent names. Keep native ticket IDs unchanged in
the brief/record and store the separate launch name, rather than passing a ticket
such as `acpt-22g.2` directly as the Herdr agent name.

Put the full bootstrap instructions in a file inside the worker checkout and keep
the terminal bootstrap argument short, for example `Read /absolute/path/bootstrap.md`.
Herdr's terminal line limit can reject a long command before Codex starts; inspect
the same pane before correcting that command, rather than launching a second agent.

```sh
herdr agent start "$DISPATCH_ID" --kind codex --pane "$PANE_ID" --timeout 30000 -- \
  --cd "$WORKTREE" --model "$MODEL" -c "model_reasoning_effort=\"$EFFORT\"" "$BOOTSTRAP"
```

BOOTSTRAP names the absolute Codex role/common contract, orchestrator and Codex skill
root, dispatch ID and durable brief path. Ask the worker to print its own
`CODEX_THREAD_ID` from a shell command, verify cwd/branch/base, then end the turn. It must not
guess another session's UUID. Read the result with Herdr and bind it to this pane in
the record. Thomas likewise obtains its own UUID from its own environment.

A recipient awaiting messages ends its turn; it must not run a sleep/poll loop.
Queued messages are consumed at a turn boundary. Coordinator observation of a
running worker is a separate activity, not a recipient waiting for its own queue.

A startup timeout does not prove failure. Inspect the same pane with `herdr agent get`
and `herdr agent read --source visible`; do not relaunch while it is alive. Trust or
capacity prompts are reported, not bypassed. Model substitution needs owner approval.

Junior is the exception to worktree creation: launch a sibling pane in the Builder's
worktree, and pause Builder writes until Junior returns. Never run both writers there.
QA of an uncommitted artifact can also inspect the existing worker worktree read-only
with all artifact writers paused, as specified in `codex-dispatch-qa-walk`. Pin its
file manifest/hashes, include untracked inputs, and keep reports outside that tree.
Do not create a temporary commit or check out the base SHA and call it the dirty target.

## Queue and observation

Save each short message to a file. Include dispatch ID, unique event ID, sender,
recipient role, purpose and artifact path/hash. Prefix it as agent coordination,
not owner approval. Before sending, check the record for an existing event attempt.

```sh
codex queue --thread "$WORKER_UUID" --message "$(cat "$MESSAGE_FILE")"
herdr agent get "$PANE_ID"
```

Record queue acceptance as unconfirmed. Recipient replies `ACK <dispatch-id> <event-id>`
and includes that ID in its report/checkpoint. It checks its prior checkpoint before
acting on repeated events: continue unfinished work, never start a second copy or
repeat completed external operations. ACK means received, not finished.

If outbound queue fails before acceptance with a definite local startup error (for
example, `failed to start embedded app server: Operation not permitted`), preserve
the error and verify the same recipient pane. The approved Herdr transport may send
that same event once with `herdr agent prompt <pane-id> <message>`; record the failed
queue attempt and fallback attempt separately. This is not successful queue delivery.
Never use this fallback on timeout, an accepted/queued response, or an ambiguous
outcome; inspect the same session/checkpoint instead of replaying the task.

Observe a new working transition after sending. Once working has been observed, use
bounded `herdr agent wait "$PANE_ID" --until idle --until done --until blocked --timeout 30000`,
then fresh `agent get` and `agent read --source recent-unwrapped --lines 160`. A timeout
requires another observation of that same handle, not a duplicate dispatch. Idle/done
alone never satisfies a ticket. Record blocked questions and request the actual decision.

The worker sends ACK/questions/handback pointers back with `codex queue --thread
<coordinator-UUID> --message <message>` where its permissions allow it. If queue cannot
run inside its sandbox, it writes the durable report and prints its pointer; Thomas
reads it through the observed pane. Do not broaden sandbox rights to force queue.
Do not claim automatic wake-up in this fallback: Thomas must keep observing the worker.
This requires Thomas's actual execution environment to permit the Herdr socket.
If it cannot call Herdr, report the missing host capability. Host-driven observation
is not evidence that native Thomas can observe or orchestrate autonomously; do not
broaden permissions or silently substitute a host controller to claim that result.

After interruption, pending messages may stay queued. Do not replay the task through
Herdr. If owner authorizes continuation, a recovery prompt may tell the recipient to
process its existing queue/checkpoint; it must not contain a second copy of the operation.
Resume an existing Codex session by its recorded UUID using the installed CLI's resume
interface. Never use --last. Recheck project/cwd and current artifact before continuing.

## Handoff, checks and cleanup

Worker reports exact base/head, dirty status, changed paths, per-criterion evidence,
validation commands/results, review findings/dispositions, applicable UI/codex-simplify/arm,
and unresolved blockers. Save full logs/reports in files. Shaper stops after Spec and
only proceeds on a release naming the exact revision; a changed Spec needs new release.

Thomas inspects actual diff/status, compares changed paths to the write-set, reads the
reports and checks that tests/reviews cover this head. Missing or stale evidence blocks
integration. QA exercises the exact target with its plan/consent. Do not substitute a
claimed skill invocation or idle pane for evidence. Run existing project checks where
compatible; do not manufacture legacy marker commits to satisfy another runtime.

Before cleanup preserve reports in the coordinator checkout and confirm the owned
worker is idle/finished. Close only the recorded pane/tab. Release only resources
known to belong to this worktree. Inspect tracked, untracked and ignored files before
`git worktree remove`; do not use --force to discard work. Delete only an owned branch
that is proven integrated or contains no unique work. Record retained resources and
why they remain. Do not clear tracker claims on ambiguous cleanup or delivery.
