---
name: codex-dispatch-ticket-codex
description: "Dispatch and observe Codex workers using native Herdr commands and Codex queue, with a Markdown handoff record."
---

# Dispatch a Codex worker

Read [Codex dispatch](../../../.codex/DISPATCH.md) for the executable procedure.
Use the project orchestrator's model and capacity choices. This is a skill workflow,
not a custom dispatch command or a background scheduler.

Prepare the brief and record, create the isolated worktree, start Codex through
Herdr, obtain the worker's own UUID, then queue the brief once. Observe ACK and actual
work. On return, inspect the artifact and required evidence before integration.
For Junior, use its shared-worktree exception with one writer at a time.

Keep the exact project/pane/session/event identities across waits and resume. A
startup timeout does not authorize relaunch. Queue acceptance is not delivery; a
terminal state is not a verdict. Do not bypass owner interruption or broaden sandbox
permissions to make transport succeed. Preserve reports before owned-resource cleanup.
