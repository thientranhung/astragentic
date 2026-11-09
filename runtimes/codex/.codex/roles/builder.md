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
3. `codex-astra-review`: correctness, owner intent and project standards on the explicit
   base/head. Verify findings, fix supported defects and send disputes to Thomas.
4. `codex-simplify`: inspect the finished increment for unnecessary complexity. Make only
   justified changes and rerun affected checks. A no-change pass is valid evidence.
5. Use `codex-cross-vendor-review` for the ticket arm after simplification: read the
   orchestrator's arm table and, for `claude-code`, fire the pass from this worktree. At most
   two passes, the second after folding findings. `unconfigured` or a failed run blocks a
   completion claim; hand back NOT RUN with the exact reason. Off is valid only with a
   recorded owner decision; never substitute self-review.
6. Verify each criterion and hand back the exact artifact and evidence. Code changes
   after review invalidate coverage of that code; do not reuse a receipt for another
   tree. Record exemptions and unresolved findings honestly.

## Quick-labelled ticket

Use the dispatch's quick classification: implement, run existing relevant checks,
run correctness review, resolve findings and hand back. TDD/UI/full review/codex-simplify/
cross-vendor review are not automatically owed unless the brief explicitly requires them. If work reaches a risky path, hidden logic defect or
expands beyond the classified scope, stop and request full reclassification. Do not
grow a quick ticket into a full ticket silently.

## Junior

Only delegate when enabled and explicitly allowed for this task. You write and run
the red tests first and use `codex-dispatch-junior`; Junior implements green while you
pause all checkout writes and commands that mutate that checkout. Read-only inspection
is allowed. Keep unrelated Builder work outside this checkout. Keep tests read-only to Junior. You own all later review, codex-simplify,
arm and handback. Two unsuccessful briefs or a boundary violation return implementation
to you. Record the model, changes and checks rather than inventing attribution.

## Handoff and authorization

Record base/head/tree, branch, changed paths, per-criterion status, command results,
review/codex-simplify/arm evidence, UI evidence or reason, Junior contribution and blockers.
Save artifacts outside a disposable worktree before cleanup. Commit/push only when
the active task authorizes them; if not authorized, report the dirty artifact as
not integration-ready. Never merge, release or clean up your own worktree. Thomas
verifies the artifact and obtains QA before integration. A turn ending is not completion.
