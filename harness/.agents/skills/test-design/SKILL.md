---
name: test-design
description: Use when a spec is finalized and tickets are about to be cut, or when loose tickets with acceptance criteria and no spec are about to be dispatched. Writes docs/qa/plan-<slug>.md, the risk-ranked plan of journeys, endpoints and jobs that QA later runs against, with the cases each ticket must carry. Plans only; writes no tests and cuts no tickets.
---

# Test design: the plan exists before the tickets do

Distilled from the BMAD Method (BMad Code, LLC, MIT), adapted for Astragentic.

**A plan written after the build lists what was built. A plan written before it lists what could
go wrong.** QA's run reads this file as its oracle, so a journey, endpoint or job missing here is
one nobody exercises. Without it QA derives the oracle from the source and the verdict loses
confidence: an inferred oracle never earns an unconditional pass.

## When it runs

In the Shaper session, after `to-spec` and the spec arm, before `to-tickets`; and, since no
ticket is dispatched without a plan, over a set of loose tickets that have no spec. Two inputs,
one of them required:

- **A committed spec** with its acceptance criteria: the plan covers it whole (BMAD's system
  mode and epic mode, folded into one unit).
- **Loose tickets with no spec** (a gate's follow-ups, small fixes): the input is each ticket's
  acceptance criteria plus the source it cites (a gate report, a defect record). The plan has one
  section per ticket, and a ticket with no surface gets its line: `QA: none — <why>`.

An input with no stated way to know it works — a spec without criteria, a ticket with none —
halts the skill. Name what is missing and hand back.

## Method

1. **Detect the surfaces.** Frontend, backend or fullstack from the manifests. List what the spec
   adds or changes by kind: screens and journeys, endpoints, jobs and data flows. Each kind selects
   an execution mode for QA: walk, probe or verify.
2. **Read what already exists.** Scan the repo for tests, fixtures and flaky areas. A case the
   suite already covers at a level is not planned again at another.
3. **Find the risks before the cases.** Classify each as technical, security, performance, data,
   business or operational. Score probability (1 to 3) times impact (1 to 3). Six or more is high
   and needs a mitigation and a timing.
4. **Rank every journey, endpoint and job P0 to P3.** P0 blocks core use, is high risk and has no
   workaround. P1 covers critical paths with medium or high risk. P2 is secondary. P3 is
   exploratory.
5. **Decompose into atomic cases, one level each.** End to end, API, integration or unit. Never the
   same behaviour at two levels without a stated reason.
6. **Attach the mandatory checks per mode.** These are required, not optional (see below).
7. **Thresholds are measured or unknown.** Take a number from the spec, never from a guess. A
   missing threshold goes to Open questions as UNKNOWN.
8. **Assign cases to tickets.** Where the ticket boundaries are not yet drawn, group cases by the
   spec section they belong to so `to-tickets` can cut along them.

## The file: `docs/qa/plan-<slug>.md`

`<slug>` is the spec's slug. Five sections, in this order.

- **Surfaces.** Per surface: kind, the mode QA will use, what is unchanged but shows the same
  concept. A surface with no way to exercise it is listed as a finding.
- **Journeys, endpoints and jobs.** One table: item, priority P0 to P3, risk and score, level, the
  expected result stated as an observable.
- **Per-ticket cases.** Per ticket (or per spec section): the cases it must carry, with the
  priority of each. Thomas copies a ticket's cases into its brief and names this file as their
  source, so each case reads without the rest of the plan.
- **Mandatory checks per mode.** Walk: numbers agree across every screen showing a concept,
  deeplinks open the exact record, end-of-journey links reach their target. Probe: contract and
  schema, status codes and error paths, permission-denied paths, data after the call. Verify: the
  job ran, data landed where it should, logs clean, numbers agree with the source. Say which
  concepts, links and jobs each applies to.
- **Open questions.** Unknown thresholds, unreachable surfaces, cases whose expected result the
  spec does not state. Each with the evidence that would answer it.

The skill ends when every P0 journey, endpoint and job has at least one case with an observable
expected result.

## Full persona method

Spawn `astragentic-dispatch:bmad-murat` when the session wants the Test Architect's full method:
risk scoring, level choice and gap hunting beyond the steps above. The spawn is **read-only**.
The persona reads the spec and the repo and returns findings; you write the plan. It never writes
a file, runs a test or fires a gate.

## What it never does

- **Writes no tests.** Red acceptance tests belong to the Builder, through `atdd`.
- **Cuts no tickets.** `to-tickets` does, from the spec and this plan.
- **Does not edit the spec.** A gap in the spec is an Open question, repaired by the Shaper in the
  spec itself.
- **Invents no thresholds, and does not pad.** A P3 list that exists to look complete is noise
  QA will have to read.
