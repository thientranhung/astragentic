# TDD — distilled

> From `skills/engineering/tdd/SKILL.md` + `tests.md` + `mocking.md` (model-invocable). TDD is the
> red → green loop; this is the reference that makes the loop produce tests worth keeping. Read
> GLOSSARY.md so test names match the domain language; respect ADRs in the area.

## What a good test is
Verifies behaviour through public interfaces, not implementation details. Reads like a
specification ("user can checkout with valid cart"), survives refactors, describes WHAT not HOW,
one logical assertion. Expected values come from an independent source of truth (a known literal,
a worked example, the spec), never recomputed the way the code computes them.

## Seams: where tests go
A **seam** is the public boundary you test at. **Test only at pre-agreed seams**: before any test,
write down the seams under test and confirm them with the user; no test at an unconfirmed seam.
Ask: "What's the public interface, and which seams should we test?" with a one-line note per seam
on what it catches and misses. When the interface's shape is itself in question, consult the
`codebase-design` vocabulary (module, interface, depth, seam, adapter, leverage, locality).

## Anti-patterns
- **Implementation-coupled**: mocks internal collaborators, tests private methods, verifies through a
  side channel (querying the DB instead of the interface). Tell: breaks on refactor without a
  behaviour change.
- **Tautological**: the assertion recomputes the expected value the way the code does; passes by
  construction.
- **Horizontal slicing**: all tests first, then all implementation; tests imagined behaviour. Work in
  **vertical slices**: one test → one implementation → repeat, each a **tracer bullet**.

## Rules of the loop
- **Red before green.** Failing test first, then only enough code to pass it. No speculative features.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to the review stage.

## Mocking (mocking.md)
Mock at **system boundaries** only: external APIs, databases (prefer a test DB), time/randomness,
file system (sometimes). Never mock your own modules or internal collaborators. Design boundaries for
mockability: **dependency injection** (pass the client in), **SDK-style interfaces** (one function per
external operation, each independently mockable) over a generic fetcher with conditional logic.

## Good vs bad (tests.md)
Red flags: mocking internals, testing private methods, asserting call counts or order, test name says
HOW, verification bypasses the interface (`SELECT` after `createUser` instead of `getUser`).
