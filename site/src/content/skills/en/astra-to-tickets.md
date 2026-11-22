---
title: astra-to-tickets
oneLiner: "Cut a committed spec into tracer-bullet tickets with prerequisite edges and publish them in build order."
group: shaping
order: 4
runtimes: [claude]
source: harness/.claude/skills/astra-to-tickets/SKILL.md
rented: false
lang: en
harness: v6.1.19
updated: 2026-11-22
---

## What it does

`astra-to-tickets` is the Shaper's Tickets phase, opened by Thomas with `/astra-to-tickets <spec-id>`. It cuts the spec as committed after the arm into tracer-bullet tickets: narrow but complete paths through every layer, sized for one Builder session in one fresh context.

Edges are prerequisites only, because Thomas's frontier query reads them. Each ticket carries What to build, Criteria (given, when, then, citing an FR), Must not change, Evidence and a `quick` or `full` label. A ticket that changes a surface also carries Glance (exactly one must-see per screen) and States.

**Cost.** A UI ticket without Glance and States is not cut, because the dispatch mod refuses to brief it. Nothing reaches the tracker until the owner answers the quiz (granularity, edges, merge or split).

## When it is used

| What is in front of you | Reach for |
|---|---|
| A committed spec past its arm, plus the QA plan | `astra-to-tickets`, on Thomas's release line |
| A change whose blast radius fans across the codebase | Sequence expand, migrate, contract |
| A "for now" or "placeholder" in a draft ticket | Split into a second ticket, never shrink |

## What it leaves behind

| What happened | Where it lands |
|---|---|
| Tickets in build order | The tracker, with native blocking relations, sub-issues of the spec where available, readiness `needs-triage` |
| `quick` / `full` | A tracker label |
| Handback | Ticket ids with edges, the plan path, the set check, how each spec-stage finding was resolved |
| Later changes | In place, ids kept; a dropped ticket gets a `Dropped:` note |

## It's working if

- Every spec requirement and plan case lands in a ticket or a named deferral.
- Each `Given` opens with the PRD's actor name.
- Every ticket has a label, and tests are inside the tickets.
- The spec and its parents are never closed or edited.

## Where it fits

`/skills/astra-to-spec` → `/skills/test-design` → `astra-to-tickets` → `/skills/dispatch-ticket`.
