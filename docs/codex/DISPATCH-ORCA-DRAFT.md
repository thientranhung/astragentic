# Codex DISPATCH — Orca branch draft for 6.1.0

Draft only; not installed runtime policy or release approval. Evidence: [ORCA-610-2026-11-09.md](ORCA-610-2026-11-09.md), M6/M1/S1. Existing Herdr dispatch text stays byte-identical. Host-neutral identity, write-set, review, arm, commit/push and QA obligations remain in force.

## 1. Mandatory host check

Run in the actual session environment before any host operation. Never infer host from cwd, focus, installed binaries or terminal titles; never manufacture a variable to pass this check.

```bash
if [ -n "${ORCA_PANE_KEY:-}" ]; then
  ASTRA_HOST=orca
elif [ "${HERDR_ENV:-}" = 1 ]; then
  ASTRA_HOST=herdr
else
  printf '%s\n' 'STOP: no recognized session host; report startup gap.' >&2
  exit 2
fi
```

Orca takes precedence if both variables exist. An Orca-started session never executes `herdr`, including indirectly through helpers. A Herdr-started session never executes `orca`; follow the unchanged Herdr branch. Missing selected CLI/branch or contradictory identity is a hard stop, never fallback to the other host. The shell check is not a global command interceptor.

H2 is **not** a proven live-deny gate: trusted PreToolUse fired on controls; deny logic passed synthetic tests; no planted call reached it because tool input was malformed. Do not advertise host-command enforcement from those results.

## 2. Bind workspace, checkout and policy

Record the actual checkout path/branch/base, selected orchestrator hash, role, model/effort, owner-selected permission mode, authorized origin and durable brief/report paths. Separately record the Orca workspace ID and runtime-issued terminal handle returned by launch. A terminal in an existing Orca workspace may run `codex --cd /private/tmp/fixture`; its workspace ID remains the returned host workspace, not that checkout path.

Install the selected overlay in the exact worker checkout, preserve owner configuration, run doctor and inspect helper discovery there. M6: 2/2 doctor (44 files intact), 2/2 discovery (5/5 catalog entries). Neither proves actual helper inference. No `repo add` or `new-top-level` for these fixtures; native review helpers are not separate business-role dispatches.

## 3. Controlled launch and adoption

Load the version-matched Orca guides. A Task is one dispatch attempt, not a second product backlog. Put the full self-contained brief in a durable file: criteria, write-set, stack/fixtures, QA plan, models/permissions, origin limits, evidence paths and completion obligations.

```bash
orca orchestration run-create --objective "$OBJECTIVE" --from "$COORDINATOR_HANDLE" --json
# Record RUN_ID from its receipt.
orca orchestration task-create --run "$RUN_ID" --from "$COORDINATOR_HANDLE" \
  --task-title "$TASK_TITLE" --spec "Read $BRIEF_PATH" --json
# Record TASK_ID from its receipt.
```

Encode argv with `shlex.join` or an equivalent boundary-preserving encoder. Do not concatenate arbitrary brief text into shell code. Launch an idle TUI; adoption delivers the Task once.

```python
argv = ["codex", "--cd", worktree, "--model", model,
        "-c", 'model_reasoning_effort="' + effort + '"', "-c", "notify=[]"]
if permission_mode == "yolo":
    argv += ["--dangerously-bypass-approvals-and-sandbox"]
elif permission_mode != "default":
    raise ValueError("STOP: unknown owner-selected permission mode")
command = shlex.join(argv)
```

Yolo requires recorded owner authorization; model/effort follows the selected role row. No implicit substitution. Proposed `notify=[]` disables the competing notification route **for this worker only**, without global config edits. This override still needs integration validation: M1 deliberately measured the stock bell enabled.

```bash
orca terminal create --worktree "path:$BASE_CHECKOUT" --title "$DISPLAY_NAME" --command "$COMMAND" --json
# Record TERMINAL_HANDLE and WORKSPACE_ID from this exact response.
# --worktree names the base checkout's workspace (the one in the sidebar); $COMMAND carries the `cd` into the
# worktree. `active` from a shell whose cwd is inside .claude/worktrees/<lane> picks the worktree's own
# workspace, which the sidebar never lists: the pane runs but no one sees it, `terminal show` reads
# `orphaned: true, connected: true` (nizzy 2026-11-10, 3 of 3 panes; 0 session-attached in the daemon log).
orca terminal show --terminal "$TERMINAL_HANDLE" --json
orca terminal read --terminal "$TERMINAL_HANDLE" --screen --json
# Require recognized Codex, ready TUI, and no trust/permission menu.
orca orchestration worker-start --task "$TASK_ID" --terminal "$TERMINAL_HANDLE" \
  --worktree "id:$WORKSPACE_ID" --run "$RUN_ID" --from "$COORDINATOR_HANDLE" --json
```

These are bounded startup checks, not ongoing observation. No polling loop or `agent wait`. M1's immediate adoption failed `agent_unconfigured` before any Dispatch existed; the same terminal/Task succeeded after readiness was established. On failed/unknown mutation, read recovery guidance, retain request IDs and exact resources, and follow its prescribed action. Never launch a replacement or inject the task again merely because time elapsed.

For folder/hook trust, run `orca terminal switch --terminal "$TERMINAL_HANDLE" --json`, report **TRUST NEEDED** naming the terminal and folder/hook, and let the owner decide. Never answer the menu or edit trust storage for them.

Record Task/Dispatch/Run IDs from successful adoption. Follow its `next`; after starting independent authorized workers, **end the coordinator turn**. Do not keep it alive with sleep/watch loops.

## 4. Observe, complete and ask through Orca mail

Use **Orca mail only** for adopted workers: no `herdr`, `codex queue`, TURN-END bell, `agent wait`, terminal watches or recurring `check`. Idle is not completion. When Orca wakes the coordinator with a named `orchestration check`, run it once; a full chat mail needs no extra check. Inbox history is audit/recovery, not a polling mechanism.

The worker follows the exact Task/Dispatch/sender/capability binding in its injected preamble:

```bash
orca orchestration send --type worker_done --subject "$SUBJECT" \
  --task-id "$TASK_ID" --dispatch-id "$DISPATCH_ID" \
  --outcome succeeded --report-path "$HANDBACK_PATH"
# Add the injected --from/capability arguments when required, then end the turn.
```

Report `failed` for a failed attempt. Authentic completion still needs artifact/check/coverage evidence. An escalation without worker_done is not success and does not authorize blind relaunch. Coordinator steering uses `orchestration send --to dispatch:...`, not a working worker's terminal.

```bash
orca orchestration ask --question "$QUESTION" --json
# Follow injected sender binding; end the worker turn, without --wait.
# Coordinator responds to received mail when existing authority supplies the answer:
orca orchestration reply --id "$MESSAGE_ID" --body "$ANSWER"
```

M1: 2/2 worker_done and wakes; 0.856/2.407 s from second-resolution mailbox creation (up to 1 s uncertainty). Stock notify also queued 4 signals for 2 workers, including 2 title-shaped JSON payloads. Bell observation included turn-boundary delays, not pure transport latency. Two overlapping routes add noise; Orca mail supplies bound Task/Dispatch outcomes. Both measured workers were `never`/`danger-full-access`, not Auto.

## 5. QA: file plus one-line pointer

QA gets an isolated checkout at the exact pushed SHA; verify HEAD and exercised build/runtime provenance. Never QA a dirty Builder tree. Keep reports outside the checkout. The full brief names mode/depth/persona, scope, fixture provenance, consent, authorized mutations, checks, SHA and report/clean-list paths; explain N/A surfaces.

Write the full QA brief to a file. For the owner-required initial **unassigned QA TUI** bootstrap, send only its one-line pointer, in two calls:

```bash
orca terminal send --terminal "$QA_HANDLE" --text "Read $QA_BRIEF_PATH" --json
orca terminal send --terminal "$QA_HANDLE" --enter --json
```

That bootstrap file tells QA to read context and end its bootstrap turn, without executing/reporting QA until its Task/Dispatch arrives. Once bootstrap completion is established, adopt the same terminal with a Task to execute that prepared brief. No duplicate assignment. An already-adopted worker receives later pointers through Orca mail, never terminal steering.

Do not inline the full brief or combine the two calls. S1: raw split delivery was mixed at 1,279 characters and failed 2/2 at 1,300/2,400 despite acceptance. Combined paste and a delayed split succeeded at 2,400: no universal cap was established. A 2,400-character file via 63-character pointer succeeded 2/2. `accepted`/`bytesWritten` is not delivery; preserve ambiguous receipts and diagnose without blindly resending. Pointer transport is measured; the complete QA bootstrap/adoption lifecycle is not yet measured.

## 6. Release and evidence

After authentic worker_done, inspect the report and bind its result to the exact artifact. Preserve required evidence outside disposable checkouts before cleanup.

```bash
orca orchestration worker-release --dispatch "$DISPATCH_ID" --json
# Inspect the receipt before any additional action.
```

`released`/`already_released` needs no close. Follow exact recovery for `release_pending`/`release_unknown`; never force-close on silence. `retained` can mean a reused/user-kept terminal and is not permission to close it. Only for a proven settled terminal this coordinator created for the disposable task, with cleanup authority:

```bash
orca terminal close --terminal "$TERMINAL_HANDLE" --json
```

M1's explicitly kept-open fixture terminals returned retained/user_requested twice; authorized exact closes then returned ptyKilled=true twice. Never bulk-close unrelated panes or reset orchestration history to tidy it.

## Validation still owed

M7' remains NOT RUN: one unassisted ticket through the integrated Orca branch, code to isolated QA. Prior A6 did not exercise this lifecycle. Also unmeasured: live H2 denial, disabled-notify integration, ask/reply, unknown/dual-host cases, restart recovery and complete QA bootstrap/adoption. This draft is not release readiness.
