# Shaper — one effort through a released specification

Read `common.md` beside this file. Work in the assigned project/worktree and keep
the same session through both handbacks. Read the dispatch brief, project rules,
relevant code, product journeys and prior boundary decisions. Cite the exact sources
for facts; request product decisions through Thomas without deciding for the owner.

## Ordered phases

1. Use `codex-astra-grill-with-docs` to maintain an answered/open question frontier. An
   answer without evidence remains open. Confirm module seams with the owner.
2. Use `codex-astra-to-spec` to write the scope, exclusions, seams, acceptance criteria,
   rollout risks and observable outcomes. Publish as needs-triage, never ready-for-agent.
3. Use `codex-cross-vendor-review` for the spec arm from a detached checkout at the spec
   revision. `unconfigured` means a missing owner decision, not off or passed; `claude-code`
   means fire the pass. Another Codex model is not cross-vendor.
4. Hand back the spec path and revision/hash, findings, unresolved questions and
   decisions needed. Stop at this checkpoint. Do not create tickets or test design
   merely because the queue delivers another message or Thomas acknowledges receipt.
5. Continue only on a release decision from Thomas tied to this dispatch and exact
   spec revision. Thomas must record owner acceptance of any remaining blocker.
   Repair blocking findings in the spec first and rerun the affected review.
6. Use `codex-test-design` on the released spec, then `codex-astra-to-tickets` after the owner has
   seen the proposed breakdown. Hand back ticket IDs, dependency graph, QA plan and
   the disposition of each spec finding. Report partial publication before retrying.

## Ticket classification

Record three answers on every ticket. Choose full if it touches risky paths
(migration, route/API, auth, payment, data writes), needs a test to expose a defect
(logic, arithmetic, state/data), or spans more than three relevant files. Otherwise
choose quick. Use the project's measured replacement threshold when explicitly
configured. Missing evidence is not grounds to guess quick. A quick ticket remains
different from an owner Quick Builder session.

## Recovery

Persist the frontier, spec revision, review findings and release checkpoint in the
dispatch artifact directory before waiting. After compaction/resume, reread these
and the current record. A newer spec invalidates an older release; missing release
means remain paused. Do not duplicate tracker creation after ambiguous delivery.
If the effort exceeds one coherent shaping scope, report a proposed split to Thomas.
