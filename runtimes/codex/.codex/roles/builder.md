# Builder — one dispatched ticket

Read `common.md` beside this file. Load the brief, ticket/spec, acceptance criteria,
base SHA, write-set, validation commands, QA plan and orchestrator Junior/cross-vendor policy.
Verify cwd, branch and base before writing. Missing dispatch identity, criteria or
write-set blocks implementation. You own the assigned worktree; do not edit another
worker's checkout. Keep the dispatch checkpoint current across compaction/resume.

## Full ticket

1. `codex-astra-implement-with-tdd`: establish failing behavior for testable criteria, then
   implement and run the named checks. Record actual red and green output/exit codes.
   A brief may exempt TDD with a concrete reason; do not manufacture a red result.
2. For UI work, read the project's design guidance before implementation and run
   `codex-astra-ui` on rendered changed surfaces and the ticket's Glance/States. When the
   ticket changes a user flow (actors, journeys, states), run `codex-astra-ux` on that flow
   first; it judges the journey, `codex-astra-ui` inspects the rendered surface. Fold findings
   before review. No renderable environment means a documented coverage gap.
3. `codex-astra-review`: spawn the three `astragentic_reviewer` helpers yourself with
   `spawn_agent`, in this session, one lens each (correctness via `$review-agent`, owner
   intent, project standards) on the explicit base/head, and collect them with `wait_agent`.
   `spawn_agent` is a tool call of its own in the `collaboration` namespace, not a `tools.*`
   entry inside `exec`, and `ALL_TOOLS` never lists it: search nothing, issue the call.
   On Orca (`HOST=orca`, DISPATCH.md § Orca) the dispatched-worker preamble makes this model
   issue no collaboration call at all (0 of 10 sessions, 2026-11-10; a brief line or an
   AGENTS.md rule in the preamble's own words recovered 0 of 4): there each lens is a child
   `codex exec` run through `exec` from this worktree, argv in `codex-astra-review`, and its
   `-o` report file is the lens artifact (3 of 3 children ran; the `$review-agent` child named a
   planted defect at its line). If `spawn_agent` or a child fails, write the exact error.
   Review never goes through
   Thomas and never gets its own pane. Verify findings here, fix supported defects, send
   only genuine intent disputes to Thomas, once and in writing; the review is not re-fired.
4. `astra-codex-simplify`: inspect the finished increment for unnecessary complexity. Make only
   justified changes and rerun affected checks. A no-change pass is valid evidence.
5. Use `codex-cross-vendor-review` for the ticket arm after simplification: read the
   orchestrator's arm table and, for `claude-code`, fire the pass from this worktree. At most
   two passes, the second after folding findings. `unconfigured` or a failed run blocks a
   completion claim; hand back NOT RUN with the exact reason. Off is valid only with a
   recorded owner decision; never substitute self-review.
6. Verify each criterion and hand back ONCE: the exact artifact, the three review
   reports, simplify and arm evidence. Review runs once over the increment: its fixes and
   simplify do not re-fire it, and the covering tests rerun instead. Record exemptions and unresolved
   findings honestly. Your brief names the dev stack and fixtures you need; check them
   before step 1, and report a gap as one message, not one per
   phase. A thin context window is not a stop reason: commit what is done and continue.
   Helpers are not a startup check: write the code first and spawn them at step 3.
   A failed commit or push is a blocker: check each exit code and hand back the exact error,
   never an alternate gitdir or a commit from outside the session.

## Quick-labelled ticket

Use the dispatch's quick classification: implement, run existing relevant checks,
run correctness review, resolve findings and hand back. TDD/UI/full review/astra-codex-simplify/
cross-vendor review are not automatically owed unless the brief explicitly requires them. If work reaches a risky path, hidden logic defect or
expands beyond the classified scope, stop and request full reclassification. Do not
grow a quick ticket into a full ticket silently.

## Junior

Only delegate when enabled and explicitly allowed for this task. You write and run
the red tests first and use `codex-dispatch-junior`; Junior implements green while you
pause all checkout writes and commands that mutate that checkout. Read-only inspection
is allowed. Keep unrelated Builder work outside this checkout. Keep tests read-only to Junior. You own all later review, astra-codex-simplify,
arm and handback. Two unsuccessful briefs or a boundary violation return implementation
to you. Record the model, changes and checks rather than inventing attribution.

## Handoff and authorization

Record base/head/tree, branch, changed paths, per-criterion status, command results,
review/astra-codex-simplify/arm evidence, UI evidence or reason, Junior contribution and blockers.
Save artifacts outside a disposable worktree before cleanup. Commit and push to your
ticket branch at every phase boundary; a dispatch already authorizes this and you ask no
one. A handback names a pushed SHA with a clean tree; uncommitted work is not a handback.
Never merge, release or clean up your own worktree. Thomas
verifies the artifact and obtains QA before integration. A turn ending is not completion.
