---
title: astra-grill-with-docs
oneLiner: "Stress-test a plan with the owner in numbered rounds until the design tree has no unvisited branch."
group: shaping
order: 2
runtimes: [claude]
source: harness/.claude/skills/astra-grill-with-docs/SKILL.md
rented: false
lang: en
harness: v6.1.19
updated: 2026-11-22
---

## What it does

`astra-grill-with-docs` is the Shaper's Align phase. The effort is a design tree, and the skill visits every branch with the owner instead of filling it from its own judgement.

It asks the whole frontier in one round (every decision whose prerequisites are settled), numbered, each with a recommended answer and its source, then waits. Facts are the agent's to look up; decisions are the owner's. An answer with no source leaves the question open.

**Cost.** A yes to a whole round settles nothing: each question is settled by its own answer. Alternatives must be named beside the recommendation, and the skill does not pick the owner's MVP cut or phasing.

## When it is used

| What is in front of you | Reach for |
|---|---|
| A plan, direction or effort the owner wants stress-tested before a spec | `astra-grill-with-docs`, as the Shaper's first phase |
| A question that needs a fact from code, config, log or web | Not asked: look it up, then ask only what follows from it |
| Spec already written | Not this skill; open questions go into the spec |

## What it leaves behind

| What happened | Where it lands |
|---|---|
| A term resolved | `GLOSSARY.md`, updated at once, never batched |
| A hard-to-reverse, surprising trade-off | `docs/adr/NNNN-<slug>.md`, only when all three conditions hold |
| The answered tree | Handed to the Spec phase: decisions with sources, open questions with reasons |

## It's working if

- Every question carries a recommendation and "yes" accepts it.
- Every answer names a source: file and line, ADR, research note, or the owner's words this round.
- A term used against the glossary's definition is challenged at once.
- The spec is not written until the owner confirms the shared understanding.

## Where it fits

`/skills/astra-ux` → `astra-grill-with-docs` → `/skills/astra-to-spec`. It runs in the Shaper's context, in one continuous session with the next two skills.
