---
title: astra-ux
oneLiner: "Capture the owner's user journeys and actors into the PRD before any spec is written."
group: shaping
order: 1
runtimes: [claude]
source: harness/.claude/skills/astra-ux/SKILL.md
rented: false
lang: en
harness: v6.1.19
updated: 2026-11-22
---

## What it does

`astra-ux` records the owner's user journeys `UJ-n` and actors in the project's PRD (`docs/prd.md`). It captures and never authors: the owner narrates a real session and the skill structures it.

It asks in rounds, numbered, each with a recommended reading so "yes" confirms it: who the actors are, the session in three to five beats, form factor and stakes, the one thing each surface must show in two seconds, and the states (empty, loading, error, partial, permission-denied).

**Cost.** It skips only when the owner says the surface is an internal single-operator tool and names the operator; that line goes in the PRD. More than four actors is treated as persona theatre and the owner is asked which two matter.

## When it is used

| What is in front of you | Reach for |
|---|---|
| The effort changes a surface someone looks at, and the PRD has no journey for it | `astra-ux`, in the pane where the owner speaks (BA or Thomas) |
| The PRD journey no longer matches what the owner describes | `astra-ux`, update in place |
| An internal single-operator tool | Skip, and write the operator's name in the PRD |

## What it leaves behind

| What happened | Where it lands |
|---|---|
| Journeys and actors | `docs/prd.md`: `UJ-n` ids, never renumbered or reused |
| Domain nouns | The PRD Glossary, one definition each |
| What the owner did not say | Numbered Open questions in the PRD |
| Handback | PRD path, the UJ ids touched, actor names, open questions |

It writes no `DESIGN.md`, no mock and no ticket.

## It's working if

- Every actor in the PRD is named once, by the name the project already uses.
- Each surface has exactly one must-see and its five states answered ("cannot happen" with a reason counts).
- No colour, pattern or direction appears that the owner did not give.
- Gaps are Open questions, not filled guesses.

## Where it fits

`astra-ux` → `/skills/astra-grill-with-docs` → `/skills/astra-to-spec` → `/skills/astra-to-tickets`. The spec reads the PRD for actor names; the tickets turn "must see" and "states" into Glance and States.
