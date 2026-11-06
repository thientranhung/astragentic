---
name: codex-astra-implement-with-tdd
description: "Implement an Astragentic full ticket one acceptance criterion at a time with measured red/green behavior and bounded write ownership."
---

# Criterion to red to green

Load the dispatch brief, exact base, ticket criteria, write-set, validation commands
and project guidance. Confirm the current worktree/branch. Clarify contradictory
criteria; do not choose product behavior yourself. Quick tickets use their smaller
loop instead of manufacturing TDD evidence.

For each testable criterion: choose an observable seam, write the smallest meaningful
failing behavior test, run it and record the expected assertion failure, implement,
then run green. An import/setup error is not evidence of missing behavior. Avoid
batching a speculative test suite ahead of learning from the first real failure.
Mock only actual system boundaries such as external services/time/randomness.
A source-string assertion or a mock-call count alone does not prove the user behavior.
Do not weaken assertions, skip tests or alter fixtures merely to make green.

If Junior is enabled and allowed, Builder owns the red tests; delegate only bounded
green implementation through `codex-dispatch-junior` while pausing checkout writes. Read back Junior's diff and
rerun the criteria. Otherwise implement directly.

At a coherent behavioral slice, inspect criteria coverage and interface seams before
starting the next dependent slice. When separately authorized and available, use
`astragentic_astra_slice_reviewer` read-only with the slice diff, criteria, base/tree
and measured checks. Verify its findings before patching; it does not replace the
finished-ticket review. Apply `codex-cross-vendor-review` only when the slice policy
owes it. Unconfigured required policy is a missing owner decision, not a clean slice.
Keep unfinished slices explicit rather than claiming a complete ticket from one green test.

Before handback inspect the actual diff and evaluate each criterion plus Must not
change. Run the brief's named checks, recording argv/cwd/exit and output artifact.
Report coverage gaps, pre-existing failures and justified TDD exemptions separately.
Stop for a write-set expansion, dependency change or product decision requiring
new authority; continue independent authorized criteria while waiting.
