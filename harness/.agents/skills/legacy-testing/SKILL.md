---
name: legacy-testing
description: How to get existing untested code under test — characterisation tests that pin current behaviour, and creating a seam before TDD can attach. Use when you need to change code that has no tests, when the code under a ticket has no seam to test through, when a test would require the whole system to run, or when tdd cannot start because there is nothing to write a test against.
---

# Getting legacy code under test

`tdd` writes a failing test first. That assumes a **seam** — a place where you can substitute
what the code depends on. Existing code often has none: the function reaches straight for the
clock, the network, the database, or a module-level singleton. `tdd` says nothing about that
case, and this is that case.

The order is fixed, and it is the opposite of greenfield:

```text
characterise what it does now  →  create a seam  →  then tdd
```

## 1. Characterisation tests — pin what it does, including the bugs

A characterisation test records **current** behaviour. It is not a specification, and it
passes on day one by construction.

Write one by calling the code with real inputs, observing what comes back, and asserting
exactly that. Where the output surprises you, **assert the surprising value anyway** and mark
it:

```
// CHARACTERISATION: returns "" for a missing user rather than throwing.
// Pinned as-is; behaviour not yet judged correct. See ticket ABC-123.
```

That comment is the whole discipline. A characterisation test that quietly asserts what the
code *should* do fails immediately and tells you nothing about what is safe to change — and
one that silently blesses a bug as intended is how a bug becomes a requirement. Recording it
as pinned-but-unjudged keeps both readings alive.

**Pick inputs by coverage, not by intuition.** Run the suite with coverage and aim your
inputs at the branches the change will touch. Characterising the whole file is rarely worth
it; characterising the paths your change can break always is.

These tests are scaffolding with a real lifespan: they protect the refactor, then most of
them are replaced by the behavioural tests `tdd` produces once a seam exists.

## 2. Create the seam

A seam is where you can change behaviour without editing the code under test. Reach for the
smallest one that unblocks the ticket:

| Technique | Use when | Cost |
|---|---|---|
| **Parameterise** the dependency (pass the clock, the client, the config in) | the call site is reachable and few | lowest |
| **Extract an interface** over the collaborator | several call sites, one collaborator | low |
| **Sprout** — write the new logic in a fresh, tested function and call it from the old code | the old function resists testing entirely | low, leaves the tangle |
| **Wrap** — put a tested layer around the untestable unit | the unit is genuinely immovable | medium |
| **Break the static dependency** (singleton, module-level state, direct `new`) | that is the only thing preventing substitution | highest |

**Make the seam change under characterisation tests, and make it behaviour-preserving.**
Seam creation and behaviour change in one commit is the move that makes a regression
impossible to locate: if the tests break, you want to know it was the seam.

**A seam is a design decision, so it is the Shaper's when it is large.** A parameter added to
one function is yours. A new interface that several modules will depend on shapes the module
boundaries, and that belongs where the whole picture is in context — report it to Thomas
rather than deciding it inside one ticket. `codebase-design` is the vocabulary for that
conversation.

## 3. Then TDD

With a seam and characterisation tests in place, `tdd` works normally: red, green, refactor,
with the characterisation tests as the net underneath. As behavioural tests take over a
path, retire the characterisation tests covering it — and where one of them was pinning a
bug, that pinned comment is now a ticket rather than a deletion.

## When to stop and report

Some code cannot be seamed inside one ticket: the dependency is a framework the whole app
boots through, the untested surface is far larger than the change, or the seam would commit
the project to an architecture nobody has agreed. **Say so to Thomas with what you found** —
the paths, the blocker, and the smallest seam you can see. That is a real result. Forcing a
seam under ticket pressure produces the architecture nobody agreed, and it arrives without
anyone noticing it was decided.

For a repo where this is the normal case rather than the exception, the tangle itself is the
problem: `untangle` is the path for that.
