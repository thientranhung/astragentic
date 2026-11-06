---
name: codex-astra-ui
description: "Audit, polish or redesign a rendered Astragentic surface against the project design guidance and ticket Glance/States."
---

# Rendered UI pass

Name intent: audit reports, polish makes bounded improvements, redesign changes the
composition only when authorized. Read project design tokens/typography/spacing,
component conventions and ticket Glance/States before rendering. Existing design
rules win over generic taste. Audit never silently turns into implementation.

Use the project's available browser/render tooling. Inspect each changed surface
at a stated viewport and data state. Check must-see hierarchy, every applicable
state, responsive behavior where affected, accessibility and consistency. DOM can
answer structural questions; visual judgement needs rendered evidence. A diff alone
is insufficient. Missing rendering capability is a coverage gap.

Return findings with surface/state, evidence path or observation, violated design
rule, severity and proposed remedy. If delegated, use astragentic_astra_ui_lens only when the
helper is available and authorized; its advice is not QA's verdict. Do not invent
helper results. Fold authorized findings before correctness review and rerun affected
checks. Record explicit reasons for any inapplicable surface/state.
