---
title: test-design
oneLiner: "Write the risk-ranked QA plan before the tickets are cut."
group: shaping
order: 5
runtimes: [claude]
source: harness/.claude/skills/test-design/SKILL.md
rented: false
lang: en
harness: v6.1.19
updated: 2026-11-22
---

## What it does

`test-design` writes `docs/qa/plan-<slug>.md`, the plan QA later runs against. A plan written after the build lists what was built; a plan written before it lists what could go wrong. Without it QA derives the oracle from the source and its verdict loses confidence.

Method: detect surfaces (walk, probe or verify mode), read existing tests, score risk as probability times impact (six or more is high), rank every journey, endpoint and job P0 to P3, and decompose into atomic cases, one level each. A surface that writes data also gets misuse cases. Thresholds come from the spec or are recorded as UNKNOWN.

**Measurement.** 19 walks on one upload surface ran no misuse case; the first run that did found a P1, where one colliding filename in a second drop discarded every pending tile.

**Cost.** An input with no stated way to know it works halts the skill. It writes no tests, cuts no tickets and does not edit the spec.

## When it is used

| What is in front of you | Reach for |
|---|---|
| A finalized spec, tickets about to be cut | `test-design`, in the Shaper session after the spec arm |
| Loose tickets with acceptance criteria and no spec | `test-design`, one section per ticket |
| A full risk and coverage method wanted | Spawn `astragentic-dispatch:astra-test-architect`, read-only |

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The plan | `docs/qa/plan-<slug>.md`: Surfaces, Journeys/endpoints/jobs, Per-ticket cases, Mandatory checks per mode, Open questions |
| Cases per ticket | Copied by Thomas into the ticket's brief, naming the plan as source |

## It's working if

- Every P0 journey, endpoint and job has a case with an observable expected result.
- No behaviour is planned at two levels without a stated reason.
- Unknown thresholds sit in Open questions, not invented.

## Where it fits

`/skills/astra-to-spec` → spec arm → `test-design` → `/skills/astra-to-tickets`; later read by `/skills/dispatch-qa-walk`.
