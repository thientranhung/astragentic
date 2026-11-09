---
name: astra-codex-simplify
description: "Simplify a finished Astragentic increment on the Codex runtime after review, without changing its behavior or expanding scope."
---

# Simplify the finished increment

Codex has no built-in simplify, so this skill is the pass. It covers the increment only: pin the
brief's base and current head/tree, and read that diff and the review findings.

## Before changing anything

For each candidate, know what the code is responsible for, what calls it, and which tests define
it. If you cannot say why it was written that way, read further or leave it alone.

## What to look for

- **Structure**: deep nesting, a function doing several jobs, nested ternaries, boolean flag
  arguments, the same condition repeated.
- **Names**: generic, abbreviated or misleading; a comment restating the line below it. Keep
  comments that explain why.
- **Redundancy**: duplicated logic, dead code, a wrapper that adds nothing, an abstraction with one
  user and no second in sight.

Match the project's conventions. Clear beats short: do not inline a helper whose name carries a
concept, or merge two simple functions into one complicated one.

## Apply

One change at a time inside the authorized write-set, with no new dependency; run the covering
tests after each. Behavior stays identical: inputs, outputs, errors, side effects and their order.
If a test must change for a simplification to pass, that simplification changed behavior: revert it.
Removing or weakening error handling is never a simplification.

Commit what remains as `simplify(increment): <what changed>` and push. A pass that changes nothing
is valid and creates no commit: record that in the report. Review is not re-fired for these changes.
Record what was inspected, what changed and why, command results and the
final artifact identity. Loading this skill is not a receipt.
