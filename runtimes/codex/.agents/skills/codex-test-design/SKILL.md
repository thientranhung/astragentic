---
name: codex-test-design
description: "Write an Astragentic risk-ranked QA plan from a released spec or criteria-bearing loose tickets before implementation."
---

# Plan observable verification

Require a released spec with criteria or loose tickets with criteria and cited source.
Read existing tests/fixtures and relevant product interfaces. No stated observable
success means an open question, not an invented oracle. Do not write tests or tickets
and do not repair the spec inside this skill.

List screens/journeys, endpoints, jobs/data flows and unchanged surfaces sharing a
concept. Assign walk/probe/verify modes. Identify technical/security/performance/data/
business/operational risks; score probability 1–3 times impact 1–3 (risk-based testing). Scores at least
six need mitigation and timing. Rank P0 core high-risk/no workaround, P1 critical,
P2 secondary and P3 exploratory. Choose one suitable test level per atomic case (test pyramid);
duplicate levels only with a stated reason. A surface that writes data also gets misuse
cases named for it, one group per standard technique: state transitions (add/remove/replace/re-add
input); concurrency and idempotency (a second action in flight, a double submit, a second tab);
interruption (reload or leave mid-action; on mobile also backgrounding and network loss); boundary
values and equivalence classes (too few/many, duplicate names, wrong type, empty); authorization (a
role that may not write, played from the restricted account the project's entry doc names with how
a browser or app signs in as it; none named: a COVERAGE GAP and a finding for the owner, never
dropped); UI–server consistency (the screen after the write without reload). They join the cases of
the ticket that changes the surface, with the mutations each needs named. Thresholds come from the spec or remain
UNKNOWN. Optional astragentic_astra_test_architect advice stays read-only and requires available,
authorized delegation.

Write docs/qa/plan-<slug>.md: Surfaces; risk-ranked items with observable expected
results; per-ticket/spec-section cases; mandatory checks per mode; Open questions.
Walk checks cross-screen values, exact-record deeplinks and final journey links.
Probe checks schema, errors, denied paths and independent effect readback. Verify
checks unique expected run, complete data, log baseline and source reconciliation.
Name which items each check covers and required environment/consent. No surface is
silently omitted; justified QA-none differs from an unreachable surface finding.

Finish only when every P0 has a case and observable expectation, or hand back a
blocked plan identifying the missing decision. Tickets inherit these cases.
