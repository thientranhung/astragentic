---
title: astra-review
oneLiner: "Review a change on three axes, each in its own context, then verify every finding at its line and route it."
group: gate
order: 0
runtimes: [claude]
source: harness/.claude/skills/astra-review/SKILL.md
rented: false
lang: en
harness: v6.1.19
updated: 2026-11-22
---

## What it does

`astra-review` runs after the tests and the UI pass, before `simplify`, on a full ticket. A quick ticket runs the built-in `code-review` alone. The diff is `git diff <base>...HEAD`, untracked files included, staged to a temp file outside the repo; an empty diff stops the skill.

Three lenses launch together, before any result is read:

- **Correctness.** The built-in `code-review` on the diff, called by the reviewer itself, never inside a subagent. It reads without the intent, so it finds what is missing.
- **Intent.** A read-only subagent given the ticket and the diff: per criterion the test that proves it and whether it ran, behaviour nobody asked for, each Must not change line.
- **Standards.** A read-only subagent given the repo's coding standards and a smell baseline: violations cite file and rule.

A fourth lens, adversarial (`astra-adversarial-lens`, Opus), runs only when the arm row `ticket` is `no` or the arm did not run. It is not an arm and writes no arm receipt.

**Measurement.** Blind-verified on seven replayed tickets: Opus found 13 real high or medium defects at 0.71 precision, Sonnet 7 at 0.46, at about 109k tokens per ticket.

## Triage and routing

Findings are numbered R1, R2… and each is verified at its cited line, callers and guards included. Each gets one verdict with one sentence of evidence: `high`, `medium`, `low`, `false` or maybe false. Survivors group by root cause into F1, F2…. Standards and intent findings are never reranked against each other.

| Route | When |
|---|---|
| patch | The fix is unambiguous and adds no public surface: fix, re-run covering tests, re-stage |
| decision_needed | The fix depends on what the owner meant: options and a recommendation into the handback |
| defer | Pre-existing, or all maybe false: one line with what would settle it |

**Cost.** A finding this change caused, with a verified verdict, is never deferred. Zero findings plus a failed lens reads "may be incomplete", never clean.

## What it leaves behind

| What happened | Where it lands |
|---|---|
| One line per axis: findings and worst verdict | The handback |
| The call, and the built-in `code-review` inside it | `skills_run` on the record; the merge gate reads it |
| Decisions needed and deferrals | The handback |

## It's working if

- The three lenses were launched in one message, and each lens's result is on record, failed ones reported as failed.
- Every finding has a verdict and a sentence of evidence.
- No patch added public surface or guarded a state nobody showed reachable.
- `simplify` runs once, after this.

## Where it fits

`astra-implement-with-tdd` → `astra-ui` → `astra-review` → `simplify` → arm. Neighbour: `codex-arm`, which falls back to the adversarial lens on quota failure.
