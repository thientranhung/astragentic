---
title: dispatch-qa-walk
oneLiner: "Start the app in its own worktree and let QA use it as a user would, before a PR, a merge or a release."
group: gate
order: 3
runtimes: [claude]
source: harness/.claude/skills/dispatch-qa-walk/SKILL.md
rented: false
lang: en
updated: 2026-11-22
harness: v6.1.19
---

## What it does

`dispatch-qa-walk` is Thomas's recipe for dispatching QA, the gate that judges the running system instead of the diff. It picks the mode from the ticket's surface, arranges the target at the reviewed SHA in its own worktree, packs the plan and the brief, collects the report and commits it.

Reading a diff and using a product are different acts, and a green suite proves neither. QA runs in a gate pane on either host, Herdr or Orca, and the gate mechanics live in `dispatch-ticket/GATE.md`.

| The ticket changes | Mode | QA does |
|---|---|---|
| screens, journeys, links | walk | uses the UI: journeys, numbers across screens, deeplinks |
| an endpoint or a service contract | probe | calls the API: contract, status codes, error and denied paths |
| a job, a pipeline or data movement | verify | checks the job ran, data landed, logs are clean |

**Measurement.** A browser walker once shipped across releases and never ran, and one half-day had nine fold rounds with a merge where QA was never dispatched. So the skill carries a counter: more than 10 merges touching a user-visible surface or public endpoint since the last run is a STOP. "None touched a surface" is a valid answer; "not counted" is not.

**Cost.** A walk that starts an app is the most resource-bearing operation in the harness. Cleanup is ordered: kill the app, confirm the port is free, release the worktree's resources, then `git worktree remove --force`.

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A PR or merge touching a surface or public endpoint | `dispatch-qa-walk`, incremental depth |
| A release or a slice closing | `dispatch-qa-walk`, full depth |
| More than 10 surface merges since the last run | `dispatch-qa-walk`; this is a STOP |
| Several tickets landing in one PR | one run at the batch head SHA, scoped to the union of surfaces |
| No user-visible surface, endpoint or job | Nothing; write that it does not apply |

## Prerequisites

- **Thomas only.** The recipe belongs to the station, not to a Builder.
- **A way to run the project.** A repo with none cannot be walked, and that is a finding for the owner.
- **Consent and every authorized mutation, named exactly.** Without them QA declines and records a COVERAGE GAP.
- **The plan** `docs/qa/plan-<slug>.md` as the oracle; without it QA derives journeys from the source at lower confidence.

## What it leaves behind

| What happened | Where it lands |
|---|---|
| QA's report | `.scratch/qa/<key>-<mode>-<sha>.md`, committed alone, or the path of the `qa-report-path.sh` plug |
| The trace matrix and verdict | in the report: PASS, CONCERNS or FAIL, then COVERAGE GAPS |
| That the run happened | an empty commit `qa(walk): <key> — <verdict>` with `Mode:`, `Scope:`, `Verdict:`, `Report:` |
| The verified-clean list | `.astraler/state/qa-verified-clean.md`, copied before cleanup |

One marker kind covers all three modes. A run that leaves only a report leaves nothing the merge gate can count.

## It's working if

- The app ran in its own worktree at the reviewed SHA, never in the Builder's checkout.
- Both `$GATE_FILE` and `$VERIFIED_CLEAN_FILE` exist, are non-empty and were copied out before the worktree was removed.
- The brief names every surface showing the changed concept, not only the changed ones.
- The app was killed and its port confirmed free before the removal.
- A `qa(walk):` marker sits at the walked head.

## Where it fits

`dispatch-ticket` → Builder handback → `dispatch-qa-walk` → `qa(walk):` marker → merge. QA advises, Thomas classifies, the Builder fixes, and a product decision goes to the owner.
