# Codex dispatch — native commands and one Markdown record

Read for worker dispatch, follow-up, recovery and cleanup. Thomas is the only writer
of the dispatch record. Workers write their own reports. There is no custom scheduler,
receipt service or lifecycle engine. Checks below are coordinator responsibilities;
only Git's branch/worktree checks and the native tools enforce their own invariants.

## Before launch

Use one Thomas per project frontier. Resolve tracker readiness, parent/dependency
status, authorization and available capacity from the project's
`.agents/orchestrator-for-codex.md` (or the owner's explicit launch-selected Codex
override). Re-read it before each launch; record its absolute path, hash and role
row. Do not use `.agents/orchestrator.md`, a Claude adapter, bundled defaults or a
hard-coded model as a fallback when the selected table is missing or invalid.
This procedure starts Codex workers, regardless of other runtimes installed in the
project. Missing model/effort decisions must be resolved before dispatch. Resolve
operating policy before launch except for owner-authorized bounded pre-arm work under
`codex-dispatch-ticket`: record pending cross-vendor policy/availability, NOT RUN,
allowed phases and the first owed gate as the stop point. Stricter project/owner
policy wins; this exception never waives the gate or permits acceptance without it.
Builders may run concurrently only with disjoint write-sets and independent prerequisites.
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
Selected Codex orchestrator absolute path / SHA-256 / role row:
Model / effort:
Worker CLI permission mode (default | yolo) / owner selection source:
Brief path / SHA-256:
Write-set / forbidden paths:
QA plan and cases (Builder/QA); effort scope (Shaper):
Junior and cross-vendor policy:
Current phase / last observed time:
Spec revision / release decision (Shaper only):
Report path / reviewed HEAD / validation:
Close-out disposition / evidence path / retained resources and capacity impact:

| Event ID | Direction | Purpose | Sent | ACK | Result |
|---|---|---|---|---|---|
```

Write a separate brief with intent, criteria, write-set, exact base, validation commands,
QA plan/cases, UI Glance/States where applicable, authorized mutations and handback
path. Shaper produces its QA plan after Spec release; do not require that future plan
at shaping startup. Resolve the base to a SHA before launch, not a moving branch name.

## Verified thread identity

Herdr environment pane/tab IDs are hints, not verified bindings. Before advertising a
return address, compare live `herdr pane get <explicit-id>` cwd and the pane transcript
with this session. If `--current` follows a stale environment ID, it repeats the error;
focus/title alone also cannot prove identity. Reconcile the raw thread UUID against
its own session metadata and current transcript before binding it to the live pane.
Record a mismatch and retain the verified binding; never send a probe to an unrelated
pane to discover who owns it or silently rewrite shared runtime configuration.

When authoring a checkpoint, report or outbound message, obtain self identity in that
same shell operation from `CODEX_THREAD_ID`; do not type or copy a UUID from narrative
text. Validate syntax and reject nil UUIDs before writing identity metadata. For example:

```sh
python3 - <<'PY_IDENTITY'
import json, os, uuid
thread = uuid.UUID(os.environ['CODEX_THREAD_ID'])
if thread.int == 0:
    raise SystemExit('Refuse nil CODEX_THREAD_ID; reconcile identity before writing')
print(json.dumps({'self_thread_uuid': str(thread)}))
PY_IDENTITY
```

Use that validated value directly when serializing the record in the same operation.
Missing/invalid identity blocks that metadata write/send; it is not a reason to invent
a placeholder or restart a worker. Before sending, validate the peer UUID as non-nil
and compare it to the independently captured startup binding (observed pane plus the
peer's shell-reported identity). Before startup binding exists, mark it `not yet bound`
and do not send; never populate a UUID field with all-zero text. Generated checkpoints,
reports and messages cannot overwrite a verified binding. On mismatch, preserve the
binding and reconcile via the same observed session and pinned brief. Record a correction
event without replaying work. An agent-authored metadata mistake does not establish
queue/runtime corruption. This is procedure validation, not a new identity service.

## Permission propagation

A new Herdr pane starts a separate Codex process: it does not inherit Thomas's CLI
flags. Resolve `WORKER_PERMISSION_MODE` from the owner's launcher bootstrap (`yolo`
only when --yolo was explicitly selected) or a later explicit owner instruction.
Without that evidence use `default`. Do not infer yolo from environment variables,
installed binaries, tool access, a worker request, or a transport failure.

For an authorized dispatch, copy that selection and its source into the record and
worker bootstrap. It applies to Shaper, Builder (quick/full), QA, any separately
launched review/simplify pass and Builder → Junior. A narrower owner choice wins.
Yolo does not authorize a new role, task, write-set, commit, merge or external action;
QA/reviewer remain behaviorally read-only. Quick Builder still cannot dispatch.

Native helper agents spawned by Codex are not launched through this CLI template. Their permissions are governed by Codex; do not invent a yolo
spawn argument or claim independent read-only sandboxing. Helpers retain their
contract boundaries. This propagation is a coordinator procedure, not an enforced
scheduler: verify the actual child argv and observed permissions when claiming it.

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
from the recorded selected Codex orchestrator: full tickets use the `builder` row;
quick-labelled tickets use `builder-quick` with the Builder contract, never the
owner-only `quick-builder` row. Shaper, QA, Junior and separately launched review
passes use their respective rows from that same file. Verify MODEL/EFFORT against
that row immediately before executing the command; yolo must not change them. Do not invent `codex --agent` for a business role. Start the native CLI:

Use a stable agent launch name with letters, digits, hyphens or underscores; the
installed Herdr rejects dots in agent names. Keep native ticket IDs unchanged in
the brief/record and store the separate launch name, rather than passing a ticket
such as `acpt-22g.2` directly as the Herdr agent name.

Put the full bootstrap instructions in a file inside the worker checkout and keep
the terminal bootstrap argument short, for example `Read /absolute/path/bootstrap.md`.
Herdr's terminal line limit can reject a long command before Codex starts; inspect
the same pane before correcting that command, rather than launching a second agent.

```sh
# Run this block with bash (arrays preserve argv boundaries).
PERMISSION_ARGS=()
case "${WORKER_PERMISSION_MODE:?record default or yolo before launch}" in
  default) ;;
  yolo) PERMISSION_ARGS=(--dangerously-bypass-approvals-and-sandbox) ;;
  *) echo "Unknown worker permission mode" >&2; exit 2 ;;
esac
ENDPOINT_ARGS=()
# Set this only from the recorded owner-selected endpoint, never ambient inference.
if [ -n "${CODEX_LIFECYCLE_ENDPOINT:-}" ]; then
  case "$CODEX_LIFECYCLE_ENDPOINT" in
    unix:///*) test -S "${CODEX_LIFECYCLE_ENDPOINT#unix://}" || exit 2 ;;
    *) echo "Expected verified local Unix Codex endpoint" >&2; exit 2 ;;
  esac
  ENDPOINT_ARGS=(--remote "$CODEX_LIFECYCLE_ENDPOINT")
fi
herdr agent start "$DISPATCH_ID" --kind codex --pane "$PANE_ID" --timeout 30000 -- \
  "${PERMISSION_ARGS[@]}" "${ENDPOINT_ARGS[@]}" --cd "$WORKTREE" --model "$MODEL" -c "model_reasoning_effort=\"$EFFORT\"" "$BOOTSTRAP"
```

BOOTSTRAP names the absolute Codex role/common contract, orchestrator and Codex skill
root, dispatch ID, durable brief path, worker permission mode and its owner-selection
source, plus the selected lifecycle endpoint when present. Clear the endpoint variable
for the default route; do not inherit an unrelated shell value. A Builder carries
the recorded selections to an authorized Junior dispatch. Ask the worker to print its own
`CODEX_THREAD_ID` from a shell command, verify cwd/branch/base, then end the turn. It must not
guess another session's UUID. Read the result with Herdr and bind it to this pane in
the record. Thomas likewise obtains its own UUID from its own environment.

A recipient awaiting messages ends its turn; it must not run a sleep/poll loop.
Queued messages are consumed at a turn boundary. Coordinator observation of a
running worker is a separate activity, not a recipient waiting for its own queue.

A startup timeout does not prove failure. Inspect the same pane with `herdr agent get`
and `herdr agent read --source visible`; do not relaunch while it is alive. Unexpected
trust or capacity prompts are reported; do not add bypasses beyond the recorded owner choice. Model substitution needs owner approval.

Junior is the exception to worktree creation: launch a sibling pane in the Builder's
worktree, and pause Builder writes until Junior returns. Never run both writers there.
QA of an uncommitted artifact can also inspect the existing worker worktree read-only
with all artifact writers paused, as specified in `codex-dispatch-qa-walk`. Pin its
file manifest/hashes, include untracked inputs, and keep reports outside that tree.
Do not create a temporary commit or check out the base SHA and call it the dirty target.

## Queue and observation

### Separate-session native coordination

When the owner selects separate Codex sessions, keep Thomas, each Builder, QA and
reviewer as separately bound sessions. Native child helpers do not silently replace
this topology. Use the selected orchestrator rows for model/effort and its capacity
limit. Two Builders require independent worktrees, non-overlapping write-sets and a
test environment that supports their concurrent work. Track each dispatch separately.

Before using native resume, record the exact recipient UUID/cwd/role/pane, its
model/effort/permission selection, lifecycle endpoint and continuation authority.
Distinguish a normal ended turn from an owner pause: idle alone is not authorization
to resume. If ownership or pause state is unknown, stop and reconcile it. Never start
a second CLI process for a UUID already owned by a live session. Do not resume a
thread through a different server merely because it was not found on this server.

For a verified native endpoint that already owns the eligible recipient, send once:

```sh
codex queue --remote "$CODEX_ENDPOINT" \
  --thread "$RECIPIENT_UUID" --message "$(cat "$MESSAGE_FILE")" --resume
```

The measured local route is `unix:///absolute/path/to/app-server-control.sock`.
Use the endpoint's existing authentication configuration; an authenticated WebSocket
endpoint additionally requires its configured `--remote-auth-token-env` name, never
the token value in briefs or reports. Without `--remote`, Codex uses its local daemon path. Validate that
path separately before adoption: success with an isolated remote endpoint does not
prove a Herdr-launched local session will wake. Do not bootstrap/restart a shared
daemon or broaden worker permissions as an implicit transport fallback.

Capture exit code, stdout and stderr. `--resume` can warn about a failed resume while
queue still exits successfully. Record queue acceptance, observed working transition,
recipient ACK and verified artifact completion separately. Neither exit zero nor ACK
is a completion gate. A sender sandbox must permit access to the selected endpoint;
if denied, preserve the error and use the existing durable-report observation path.

Each worker returns its event ID and artifact pointer to the recorded Thomas UUID.
An eligible ended Thomas may be resumed through the same verified native route.
For the remote branch, both directions must use the recorded endpoint and its
authentication configuration. The local queue examples below do not apply to this
branch. Include `--resume` only under the recipient eligibility checks above; do not
silently send a remote session's return message through the local daemon.
Thomas reconciles per-dispatch results and already-sent follow-ups before releasing
the next authorized step; it must not wait for the other Builder unnecessarily or
lose the other Builder's pending result. Duplicate messages must not repeat completed
operations. This is an agent procedure, not a native exactly-once delivery guarantee.

Roll out only lifecycle branches measured in an isolated fixture for that endpoint
and permission mode. Loaded-ended, busy, unloaded and owner-paused are separate cases;
do not infer one from another. Keep existing sessions and completed review evidence
unchanged until the owner-authorized safe adoption checkpoint.

For an already verified NEW disposable or owner-released daemon-owned session, a
Herdr TUI can attach with `codex resume --remote "$CODEX_ENDPOINT" "$RECIPIENT_UUID"`.
This attaches to the same endpoint; it is not permission to migrate an old independent
TUI session. Verify the exact UUID/cwd, model/effort, effective permissions, unique
writer ownership and absence of an extra turn. Read enough visible terminal lines
to include the whole viewport when checking returned output. Closing the tab does
not prove the daemon-owned thread stopped: read its lifecycle state, preserve the
report, and archive only an owned idle/finished thread when cleanup is authorized.

### Coordinator continuation while helpers or workers are pending

When Thomas starts direct native helpers, record their returned handles, the reviewed
artifact/revision, any worker paused for their result, and the next action Thomas owns.
Use the available native collaboration wait/result tools to collect those helpers'
returns and disposition the findings. A wait timeout is not completion or permission
to respawn the review. Reconcile completed returns before requesting more work.

If a worker is paused awaiting Thomas's review decision, collecting helper results
and sending the authorized disposition remains Thomas's work. Do not end the turn
with only "review in progress" or imply unattended progress without a verified
continuation mechanism. Continue through result collection and the permitted worker
handoff, or report the concrete blocker. Release only supported fixes within existing
authority; an owner pause or owed gate still requires its actual decision/evidence.

If interruption, unavailable tools or an external decision prevents continuation,
save the pending handles/results, worker identity and pause reason, exact next action,
and who will perform the next observation and on what trigger in the dispatch record.
State explicitly when owner continuation is required; a saved checkpoint alone does
not schedule a wake-up. On return, reconcile current results and prior send receipts
before acting, so recovered results do not replay an already released follow-up.

This is coordinator-owned observation, distinct from a recipient waiting for a new
incoming queue message. Keep that recipient's checkpoint-and-end-turn rule. Do not
add self-queue polling, sleep keepalive loops, automatic owner-pause resumption, or a
custom scheduler to simulate continuation. These instructions are procedural, not an
enforced runtime wake guarantee.

Save each short message to a file. Include dispatch ID, unique event ID, sender,
recipient role, purpose and artifact path/hash. Prefix it as agent coordination,
not owner approval. Before sending, check the record for an existing event attempt.

For the separately validated local/Herdr route (not the remote branch above):

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

For that local route, the worker sends ACK/questions/handback pointers back with
`codex queue --thread <coordinator-UUID> --message <message>` where its permissions
allow it. Remote workers instead use the recorded remote endpoint/authentication
in both directions, with resume eligibility checked as above. If queue cannot
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

## Exact merge-message boundary

Before an owner-authorized GitHub merge, prepare the subject and body from project
policy, including its required trailers. Use the installed wrapper below from the
verified candidate checkout. This command validates message/HEAD and does not publish
unless `--execute` is present. Supply every project-required trailer; `Ledger` here is
an example, not a universal project policy. If the project requires semantic message
checks, provide `--validator /absolute/project-owned-executable`: it receives the full
message file as its sole argument and must exit zero without changing it.

```sh
python3 .codex/astragentic/merge.py --project "$CANDIDATE_CHECKOUT" \
  --repo "$GITHUB_OWNER_REPO" --pr "$PR_NUMBER" --head "$REVIEWED_HEAD" --subject "$MERGE_SUBJECT" \
  --body-file "$MERGE_BODY_FILE" --require-trailer Ledger
```

After all review/QA/station and owner authorization requirements are satisfied, add
`--execute` to the same command. It revalidates and sends the exact subject/body and expected head SHA through
`gh api` to GitHub.com REST immediate merge (`PUT /repos/OWNER/REPO/pulls/N/merge`).
The explicit repo/host prevent ambient GH_REPO/GH_HOST from redirecting the request.
It never enables auto-merge, enqueues work, bypasses protection or cleans branches.
Queue-required branches need their own project procedure; a refusal here is a blocker. A nonzero/ambiguous merge outcome requires remote readback, never blind retry.
On success also read back published commit/message/tree before ticket-done and cleanup.
Do not use this route for a different merge strategy without a supported procedure.

This is enforcement inside this wrapper only, not a global hook or a substitute for
project gates. Direct `gh pr merge` bypasses it and is not this Codex procedure. A
missing required project validator is a blocker, not permission to omit it. Preserve
an existing project's stricter merge command instead if it already enforces the exact
message and head; document that binding during adaptation.

## Coordinator close-out before done or refill

A compact delta handback can reference an immutable prior checkpoint by path/hash and
list only changed artifact pins, new event/ACK/result receipts, invalidated/carried
coverage and the next action with owner/trigger. Never replace the original evidence
or carry a verdict across changed behavior without explicit scope reconciliation.
This reduces repeated narrative; it does not schedule a wake-up.

Integration/tracker closure and resource close-out are separate facts. Before reporting
the dispatch fully done or refilling its capacity, Thomas must save a close-out section
in the existing dispatch record; do not create a new lifecycle service or marker gate.
Inventory all resources recorded for this dispatch, including Builder, QA and station
resources, not only the main worker. Preserve reports/evidence first and apply the
ownership, idle-state and dirty-file checks above before any release.

| Resource / exact owned identity | Disposition | Evidence / retention reason | Follow-up owner / next checkpoint | Capacity impact |
|---|---|---|---|---|
| Herdr panes/tabs | released / retained / not applicable | | | |
| Worktree-owned processes/dev stack | released / retained / not applicable | | | |
| Worktrees, including station/snapshot | released / retained / not applicable | | | |
| Owned branches | released / retained / not applicable | | | |

Use one row per concrete resource where needed. `released` requires observed success
and readback of absence/inactivity, not merely a command being issued. A shared,
active, dirty, uncertain or unauthorized-to-remove resource is retained with its exact
reason and follow-up owner/checkpoint; never force cleanup to fill the table. Mark
not applicable only with a reason. Do not stop shared services or touch another ticket.

An unresolved retention is not free capacity. If resources remain, report
“integrated; resources retained” with their disposition, not unqualified close-out.
Refill only independently available capacity after recording this disposition and
rechecking conflicts/prerequisites; a documented retention need not block unrelated
work. On resume, reconcile recorded dispositions against current state without
replaying successful cleanup. These are coordinator instructions, not runtime enforcement.

## Resume permission selection

Record the selected mode in the checkpoint before ending a turn. Resume the exact
thread with the same recorded choice: for yolo use native
`codex resume --dangerously-bypass-approvals-and-sandbox <thread-UUID>` from the recorded checkout; for default use
`codex resume <thread-UUID>` with any explicitly selected scoped profile preserved.
These bare examples are for the local route. For an explicitly bound endpoint,
include its recorded `--remote <endpoint>` on resume; never move the UUID to a
different endpoint or resume an owner-paused session implicitly.
Do not assume a resumed process restores old CLI flags. If the owner revokes or
narrows permissions, do not keep passing the old flag; reconcile the active session
and checkpoint first. Changing argv in a record does not alter an already running
worker. A missing or contradictory selection needs reconciliation before resume.
