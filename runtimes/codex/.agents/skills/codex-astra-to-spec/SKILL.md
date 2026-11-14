---
name: codex-astra-to-spec
description: "Turn an aligned Astragentic effort into a sourced specification and pause for revision-specific release before ticketing."
---

# Specification and checkpoint

Read the answered frontier, owner-confirmed seams, product journeys, relevant code,
ADRs and glossary. Confirm interface/module boundaries before choosing implementation.
Write Problem, Solution, Requirements with stable FR IDs, Implementation decisions,
Testing decisions, Non-goals, Open questions and References. Requirements state
observable behavior and failures; testing decisions state how each will be known to
work. Agent-facing documents put each fact in one home and say when it is loaded.

Keep unresolved decisions visible. Do not fill a threshold or interface choice from
assumption. Record code/spec conflicts. Save a reviewable revision and its hash or
commit SHA under the task's authorization. Use the configured tracker adapter only
when publication is authorized. Published specs start needs-triage, not claimable.

Use `codex-cross-vendor-review` for the configured spec policy. Unconfigured needs
an owner decision; report it as blocked, never off or passed. Then hand Thomas the exact revision,
findings, open questions and the three decisions you are least sure of. Stop before codex-test-design/tickets. Release must name this
revision; a revised spec needs a renewed release. Only an owner decision can accept
an unresolved blocker. Invocation of this skill, queue delivery is not release.
