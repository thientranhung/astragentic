# Codex skill use on nizzy (etsy-fulfillment-thanh), measured 2026-11-08

Source: ~/.codex/sessions rollouts whose session_meta cwd is under the nizzy checkout: 29 sessions
(2026-11-05 → 11-08, overlay 6.0.3 installed+adapted). Counted per skill: tool calls whose
arguments read `skills/<name>/SKILL.md` (a real load), and assistant messages naming the skill.
The 33-per-skill "user" mentions are the catalog Codex injects into every session and are not use.

| codex-* skill | SKILL.md reads | assistant mentions | named by role/DISPATCH |
|---|---|---|---|
| codex-astra-review | 49 | 16 | yes |
| codex-dispatch-qa-walk | 23 | 6 | yes |
| codex-cross-vendor-review | 21 | 3 | yes |
| codex-github-issue-tracker | 21 | 3 | **no** |
| codex-dispatch-ticket-codex | 15 | 5 | other skill only |
| codex-dispatch-ticket | 12 | 8 | yes |
| codex-astra-ui | 4 | 0 | yes |
| codex-astra-implement-with-tdd | 4 | 2 | yes |
| codex-simplify | 4 | 3 | yes |
| codex-astra-ux, codex-batch-triage, codex-bootstrap-glossary, codex-jira-issue-tracker, codex-linear-issue-tracker, codex-reconcile-tracker | 0 | 0 | no |
| codex-astra-grill-with-docs, codex-astra-to-spec, codex-astra-to-tickets, codex-test-design, codex-dispatch-junior | 0 | 0 | yes |

Shared: astragentic-update-install 23 reads. Non-overlay skills also loaded: golang-implement 25,
dispatch-ticket-claude 18, herdr 16, frontend-implement 9, astraler-ui-anti-slop 7.
