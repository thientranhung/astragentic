---
name: codex-cross-vendor-review
description: "Apply Astragentic cross-vendor review policy from a Codex session without misrepresenting another OpenAI model as another provider."
---

# Cross-vendor arm from Codex

Read spec/ticket/slice policy in orchestrator-for-codex.md. Explicit off is a recorded
exemption. Unconfigured is a decision still missing, not off. Enabled requires a
configured, available other-provider reviewer when that gate is reached.
Owner-authorized bounded pre-arm phases may proceed under `codex-dispatch-ticket`
with pending policy/availability and NOT RUN recorded; stricter project policy wins.
Stop at the first owed gate before dependent phases, completion or acceptance.
Ask for the missing decision/adapter there; prior bounded authorization is not a waiver. Never use Codex review or another
OpenAI model as evidence that cross-vendor ran.

Pin the exact base/head/tree or spec revision. Include owner intent, must-not-break
constraints and review scope. For a code range, verify nonempty relevant change and
that reviewer cwd resolves to the intended head. Use an isolated read-only review
context; do not modify personal configuration or launch a new broker/daemon.

Use the configured adapter's actual interface and save output. Record provider/model,
range, command/outcome and findings. Missing output, config error or failed execution
is NOT RUN even if process exit is zero. Classify findings with evidence. Fold supported
fixes and, if needed, run one second pass over the revised whole artifact. Remaining
blockers require owner decision; never waive them because two passes were consumed.

Report exact coverage and final disposition. Clean only resources this invocation
created after preserving output and confirming no other session owns them. Do not
emit legacy marker commits or pretend the old runtime's receipt machinery ran.
