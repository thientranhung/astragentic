---
name: atdd
description: Use before implementing a ticket that has clear acceptance criteria. Writes red acceptance tests from those criteria, at the level the stack calls for, in the framework the project already has, then hands to tdd as the inner loop. Halts when the criteria are unclear.
---

# ATDD: red acceptance tests before the code

Distilled from the BMAD Method (BMad Code, LLC, MIT), adapted for Astragentic.

**An acceptance test written before the code cannot be shaped by the code.** A test written
afterwards from the same side is green by construction: it proves only that the code does what it
does. So the ticket's criteria become failing tests first, and the implementation is whatever
turns them green.

## When it runs

In the Builder session, before `mattpocock-skills:implement`, for a ticket whose acceptance
criteria are clear. The case list in the ticket's brief, copied from the plan under `docs/qa/`,
is the starting point.

**It halts, and hands the question to Thomas, when:**

- a criterion cannot be turned into an observable pass or fail;
- the project has no test framework to write into (a framework is a ticket of its own);
- the criteria contradict each other or the spec.

A ticket without clear criteria skips this step and the handback says why: `ATDD: n/a — <why>`.

## Method

1. **Detect the stack** from the manifests: frontend, backend, fullstack.
2. **Use the framework the project already has**, in its existing layout and style. Read two
   neighbouring tests before writing one.
3. **Map each criterion to scenarios.** One criterion, one or more scenarios. Add negative and
   edge cases where the plan marks the risk high.
4. **Pick one level per scenario, and never duplicate across levels:**
   - frontend or fullstack: end-to-end for a critical journey, component for UI behaviour, API for
     a business rule or contract;
   - backend: integration for service, data store and middleware, API for endpoint schema;
   - pure functions: unit. A purely backend ticket has no end-to-end test.
5. **Test at the interface.** The seam is the public boundary a caller really crosses, and the
   test observes behaviour there. No mocks of internal modules, no private details, no side
   channels. If a criterion can only be reached past the interface, report the module's shape to
   Thomas rather than test around it.
6. **Derive expected values from the criterion**, a literal or a worked example in the ticket.
   Never recompute them the way the code will.
7. **Write the scaffolds red.** Run them and watch each fail for the reason the criterion names. A
   test that passes now is wrong or redundant. A test that fails on an import error has not
   started.
8. **Record it, do not commit it yet.** The Builder's pane refuses a content commit before
   `mattpocock-skills:tdd` has run, so the red scaffolds stay in the working tree and go into the
   first commit `tdd`'s loop makes, still red. Name the files in the handback beside the `tdd`
   record.

## Hand to the inner loop

Hand to `mattpocock-skills:tdd`. It owns the loop: one seam, one test, one minimal implementation
per cycle, red before green. The acceptance tests are the outer ring that goes green last. `tdd`'s
tests are the inner ring that gets them there. Both are recorded in the handback.

## What it never does

- **Never writes passing tests.** A scaffold that is green before the implementation is a defect.
- **Never writes implementation code**, fixtures that stand in for it, or stubs that make a test
  pass.
- **Never invents a criterion.** A behaviour the ticket does not state is a question for Thomas.
- **Never adds a framework** or restructures the test layout.
- **Never reads the plan as a licence to cover everything.** It covers this ticket's criteria.
