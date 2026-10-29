---
name: astra-implement-with-tdd
description: "Build one ticket test-first in a Builder pane: one failing test per criterion before the code that passes it, at the seams the spec agreed, mocks only at system boundaries, the diff judged against the ticket before handback. Opens a Builder brief as its first line."
disable-model-invocation: true
---

# Implement, test-first

The brief's first line is `/astra-implement-with-tdd <ticket>`. Fetch the ticket from the
tracker, state its title, and read **What to build, Criteria, Must not change**, and for a UI
ticket **Glance and States**, before any file is opened. The ticket distills the spec; open
the spec only for a seam or FR the ticket cites. Ambiguous ticket: hand back, do not guess.

## Seams

A **seam** is the public boundary a test observes behaviour through. Test at the seams the
spec's Testing decisions agreed. A behaviour no agreed seam can see is a finding for the
handback (the module's shape, not a workaround); test it at the nearest public interface and
say so. Never at a private method, an internal collaborator, or a side channel (a `SELECT`
after `createUser` instead of `getUser`).

## The loop, one criterion at a time

Work in **vertical slices**: one criterion → one test → the least code that passes it → next.
Never all tests first, never all code first.

1. **Red.** Write the one smallest assertion that defines the criterion and **must fail now**.
   Run it and watch it fail; the test-run log is how the harness knows red happened. A red test
   that passes means the behaviour already exists: say so in the handback, do not invent a
   failing assertion.
2. **Green.** Only the code that makes that assertion pass. No speculative feature, no second
   criterion's code.
3. **Commit the slice.** Refactoring is **not** in the loop; `simplify` runs once at the end.

**Never weaken a test to pass**: no `skip`, `fixme`, expected-failure marks, loosened
assertions, raised timeouts, or a mock that fakes the system under test's success. A test
that disagrees with a criterion → fix the code; the criterion is ambiguous → stop and hand
back.

## What a test is

It verifies behaviour through the public interface, reads like the criterion ("<actor> can
checkout with a valid cart"), survives a refactor that changes no behaviour, holds one
logical assertion, and takes its expected value from an independent source (a literal, a
worked example, the spec), never recomputed the way the code computes it. Test names use the
glossary's words.

Red flags: mocks internals · tests private methods · asserts call counts or order · name says
HOW · checks through a side channel · recomputes the expectation (tautology).

**Mock only at system boundaries**: external APIs, time, randomness, a real test database
over a mocked one. Never your own modules. Design for it: inject the client, one function per
external operation.

## Before handback: judge the diff, not your memory

Stage the full diff since the base, untracked files included, and read it. For **every
criterion**: the test that proves it **ran and passed** in the final full run; an unregistered,
filtered, skipped or disabled test counts as missing. For every **Must not change** line: the
behaviour still holds, and you can name how you know. For a UI ticket: each Glance line and
each State rendered and looked at (then `astra-ui` when the FLOW names it). Typecheck
throughout, single test files per slice, the **full suite once at the end**.

## Stop and hand back, do not guess, when

- the work needs a dependency the project does not have;
- the same test has failed three times in a row;
- the ticket left out something the owner would notice (a state, an actor, an edge the
  criteria do not cover): write the gap as a question, hand back;
- a criterion and the code disagree in a way only the owner can settle.

Then the FLOW line continues: `astra-ui` [UI] → `astra-review` → `simplify` → arm.
