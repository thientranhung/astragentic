---
name: astra-to-spec
description: "Turn an answered Align frontier and the codebase into a spec and publish it to the project's tracker: what is built, from whose seat, how it will be known to work. Synthesis, not a new interview; the one thing it checks with the owner is the test seams. Shaper's Spec phase."
disable-model-invocation: true
---

# To spec

Write from what the Align phase settled and the code shows. **Do not reopen the frontier**:
a question that stayed open goes into the spec as an open question, not into a new round.

## 1. Read before writing

- The **PRD** (`docs/prd.md` or the project's own): actor names and journeys `UJ-n` are used
  verbatim; a synonym is a defect. Where the PRD has a Glossary, its terms win.
  No PRD and the work changes a surface someone looks at → say so in the handback; `astra-ux`
  has not run and the spec will name actors nobody agreed on.
- The code the work touches: a spec with no citations was written from memory. Respect ADRs in
  the area; use the glossary's vocabulary.

## 2. Seams first, and check them with the owner

Sketch where the behaviour will be tested. Prefer seams that exist; use the highest seam that
still sees the behaviour; the fewer seams across the codebase the better, the ideal number is
one. **Put the seams to the owner before writing**: which ones, why each, what a test at each
one proves. Write only after the answer comes back through the pane that dispatched you.

## 3. Write the spec

Capabilities, not implementation. Every sentence carries load. **No file paths or code
snippets**; exception: a prototype snippet that IS the decision (state machine, schema, type
shape), trimmed to the decision-rich part.

```markdown
## Problem
From the actor's seat: what is wrong or missing today.

## Solution
From the actor's seat: what is true when this ships.

## Requirements
FR-1. <Actor> can <capability> <under conditions>. Realizes UJ-x.
  Consequences (testable): <what is observable when it holds>; <what fails when it does not>.
FR-2. …
(numbered once, never renumbered or reused; tickets cite these ids)

## Implementation decisions
Modules built or changed and their interfaces; schema changes; API contracts; architectural
decisions and what each gave up. WHAT, then the one decision on HOW where it binds.

## Testing decisions
The seams agreed in §2, what a good test at each proves (external behaviour only), prior art
in the codebase.

## Non-goals
What is deliberately not built, each with its one-line reason. This is what stops "the
nearby thing" from entering a ticket.

## Open questions
Every frontier question that stayed open, with why, numbered. They become tickets, research or
owner decisions, never silent gaps.

## References
Design: `DESIGN.md` section, PRD journey ids, ADRs. Opened before cited.
```

Rules the template cannot carry:

- **Requirements are rules with a failure path**, bounded, never "gracefully", "reasonable",
  "user-friendly". At least one testable consequence per FR, or it is not a requirement.
- **A UI spec links its design in References and keeps the requirements functional.** How a
  screen looks lives in `DESIGN.md`; what each actor must see first is cut per ticket (Glance),
  not written here.
- A decision made in Align is written as a decision, with what it traded away. "Balances"
  everything is a sign nothing was decided.

## 4. Publish and stop

Publish to the project's tracker through its `*-issue-tracker` skill at **`needs-triage`**,
never `ready-for-agent`: the spec arm has not run and Thomas promotes after he classifies it.
Then hand back the spec id, the seams as agreed, and the open questions with their reasons,
and **stop** (`shaper.md` § STOP after Spec). The arm, `test-design` and `astra-to-tickets`
read the spec as committed.
