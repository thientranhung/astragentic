---
title: astra-to-spec
oneLiner: "Turn the answered Align frontier and the code into a spec and publish it to the tracker."
group: shaping
order: 3
runtimes: [claude]
source: harness/.claude/skills/astra-to-spec/SKILL.md
rented: false
lang: en
harness: v6.1.19
updated: 2026-11-22
---

## What it does

`astra-to-spec` is the Shaper's Spec phase. It synthesizes the answered frontier and the code into a spec; it does not reopen the interview. A question that stayed open becomes an open question in the spec.

The one thing it checks with the owner is the test seams: which ones, why each, and what a test at each proves. It writes only after that answer returns. The spec has Problem, Solution, Requirements (`FR-n`, each with a testable consequence), Implementation decisions, Testing decisions, Non-goals, Open questions and References.

**Cost.** The spec carries no file paths or code snippets, except a prototype snippet that is the decision itself. Nothing is written as the owner's that was not said or accepted in Align.

## When it is used

| What is in front of you | Reach for |
|---|---|
| The Align frontier is answered | `astra-to-spec` |
| The work changes a surface and the PRD has no journey | Say so in the handback: `/skills/astra-ux` has not run |
| A frontier question is still open | Write it under Open questions, not a new round |

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The spec | The tracker, through its `*-issue-tracker` skill, at `needs-triage` |
| Requirement ids `FR-n` | The spec, never renumbered; tickets cite them |
| Handback | Spec id, the seams as agreed, open questions with reasons, the three decisions it is least sure of |

It then stops. Thomas promotes the spec after the spec arm has run.

## It's working if

- Actor names and `UJ-n` ids match the PRD verbatim.
- Every FR has at least one testable consequence and no "gracefully" or "reasonable".
- The seams in Testing decisions are the ones the owner agreed.
- The spec is at `needs-triage`, never `ready-for-agent`.

## Where it fits

`/skills/astra-grill-with-docs` → `astra-to-spec` → spec arm → `/skills/test-design` → `/skills/astra-to-tickets`.
