---
title: astra-ui
oneLiner: "A UI pass on one rendered surface against DESIGN.md and the ticket's Glance and States: audit, polish or upgrade."
group: main-flow
order: 0
runtimes: [claude]
source: harness/.claude/skills/astra-ui/SKILL.md
rented: false
lang: en
harness: v6.1.19
updated: 2026-11-22
---

## What it does

`astra-ui` reads one rendered surface against the project's written design standard and the ticket's Glance and States. It takes one of three intents: `audit` reports what is wrong, `polish` lists the smallest fixes, `upgrade` puts a direction the current design cannot reach as a question with two or three options. An unnamed intent is `audit`.

The design spine wins. Its paths are the lines of `.astraler/project/design-spine`; a finding is a gap between the surface and a cited section. Each Glance line is a checklist item: a must-see that loses is P0, not polish.

**Cost.** It advises only. It is never a gate, writes no `DESIGN.md`, no mock and no component. A `polish` is a list the Builder applies under its own loop. A diff is not a surface: where the repo offers no way to render it, the pass stops and says so.

## When it is used

| What is in front of you | Reach for |
|---|---|
| The Builder's FLOW names it on a UI ticket | `astra-ui audit <surface>` |
| QA's walk finds a surface that reads wrong | `astra-ui` |
| The owner asks for a UI pass | `astra-ui` |
| A Builder wants the pass without spending its own context | `Skill(astra-ui)`, then the `astra-ui-lens` subagent read-only |

## What it leaves behind

| What happened | Where it lands |
|---|---|
| Findings with evidence (spine section, Glance line, viewport, what was seen) | The report to the caller |
| The call itself | `skills_run` on the record; it lights the `ui` chip |
| A fanned-out lens report | Back to the caller, who decides |

An `Agent` spawn alone leaves no record; only the `Skill(astra-ui)` call does.

## It's working if

- Every finding cites a spine section or a Glance or States line.
- The report names the viewport and what was seen.
- Every browser tab the pass opened is closed before it reports.
- No colours, patterns or directions appear that the owner did not ask for.

## Where it fits

`astra-implement-with-tdd` → anti-slop read → `astra-ui audit` → `astra-review`. Neighbours: the `astra-ui-lens` subagent and QA's walk.
