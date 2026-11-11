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

To check a red against the tree without your change, never use a bare `git stash pop` or
`drop`: the stash stack is shared by every worktree and the top entry may be another
Builder's. `git stash push -u -m "red <ticket>"`, read your entry's SHA (`git stash list
--format='%H %gs'`), `git stash apply <sha>`, then drop the `stash@{n}` that SHA sits at now
(`git stash list --format='%gd %H'`); `git stash drop <sha>` is refused.

When deleting or replacing tests, record each removed behavior, its requirement,
whether production still supports it, and the replacement test or explicit retirement
reason. A file or component rename is not evidence the behavior is retired. Preserve
independent link/accessibility/empty/limit guards when removing obsolete derivation
assertions from the same file. Review the deletion diff, not only the green remainder.

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
change. Run exactly the commands the brief's validation line names, nothing more, recording
argv/cwd/exit and output artifact, plus normal commit hooks; the station runs the rest. Run
single test files per slice and the full suite once at the end.
Report coverage gaps, pre-existing failures and justified TDD exemptions separately.
Stop for a write-set expansion, dependency change, a test failing three times in a row or a
product decision requiring new authority; continue independent authorized criteria while waiting.
