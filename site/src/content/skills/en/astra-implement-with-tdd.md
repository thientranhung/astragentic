---
title: astra-implement-with-tdd
oneLiner: "Build one ticket test-first: one failing test per criterion before the code that passes it."
group: main-flow
order: 0
runtimes: [claude]
source: harness/.claude/skills/astra-implement-with-tdd/SKILL.md
rented: false
lang: en
harness: v6.1.19
updated: 2026-11-22
---

## What it does

`astra-implement-with-tdd` is the first line of every Builder brief: `/astra-implement-with-tdd <ticket>`. The Builder fetches the ticket, reads What to build, Criteria and Must not change (plus Glance and States on a UI ticket), and only then opens a file.

The loop runs one criterion at a time: one red test, the least code that turns it green, one commit. Tests observe behaviour at the seams the spec agreed, never at a private method.

**Measurement.** The harness knows red happened from the test-run log, not from the handback. The commit gate measures a test file and a red run, and the merge gate reads that stamp.

**Cost.** The skill is `disable-model-invocation: true`, so it only starts when the brief arrives as a user turn. A brief that describes it in prose starts coding without it.

## When it is used

| What is in front of you | Reach for |
|---|---|
| A dispatched Builder brief on a full ticket | `astra-implement-with-tdd` (first line of the brief) |
| The ticket is ambiguous | Hand back; do not guess |
| A test disagrees with a criterion | Fix the code; if the criterion is ambiguous, stop and hand back |

## What it leaves behind

| What happened | Where it lands |
|---|---|
| A red run, then green, per criterion | The test-run log the hook records |
| One commit per slice | The ticket branch |
| A seam no agreed boundary could see | A finding in the handback |
| A red test that passed at once | A line in the handback: the behaviour already existed |

## It's working if

- Every criterion has a test that ran and passed in the final full run.
- No test carries `skip`, `fixme`, a loosened assertion or a raised timeout.
- Mocks sit only at system boundaries: external APIs, time, randomness.
- Every Must not change line has a named reason it still holds.
- The full suite ran once, at the end; single files ran per slice.

## Where it fits

`astra-to-tickets` → `dispatch-ticket` → `astra-implement-with-tdd` → `astra-ui` (UI ticket) → `astra-review` → `simplify` → arm.
