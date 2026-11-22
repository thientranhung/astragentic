---
title: "Astragentic"
description: "Astragentic is a scaffold for running a team of AI agents on the orchestrator model: you talk to one representative, and work goes through an issue tracker."
acts:
  - id: act-1
    eyebrow: "AST-016 · made a rule 2026-07-11"
    headline: "Two sessions on one checkout lose commits without throwing an error."
  - id: act-2
    eyebrow: "SEVEN STAGES"
    headline: "Seven named stages, four of them with a measured failure."
  - id: act-3
    eyebrow: "harness/.agents/memory/INDEX.md"
    headline: "Every ledger entry names the file carrying its rule."
harness: v6.1.19
---

## act-1

Two root sessions shared one checkout. One ran `git switch` while the other was committing,
three commits landed on the wrong branch and vanished when it switched back. No error was thrown,
because each session was correct in isolation.

The fix: every spawned agent that can run state-changing git gets its own checkout, including
the ones that only read. The read-only exemption was the assumption behind AST-016: a read-only
reviewer ran `git switch` on someone else's HEAD. The cost is one more worktree on disk per Builder.

## act-2

The earlier system measured 5 to 14 gate rounds per artifact, and a large share of the later
rounds went on repairing what the earlier ones left behind (RELEASE-NOTES.md, release 1.0.0). The
reviewer was not where it broke. It broke further upstream: decisions that had never been
settled went straight into code, and got settled at the most expensive point in the process.

I moved the loop to the front and cut what was left into seven named stages. The seven stages
are named so that every measured failure attaches to exactly one of them; without names, the
next failure lands somewhere nobody can point at. The trade-off: a longer pipeline, and three of
the seven are still empty because I have not measured a failure in them.

## act-3

Every time something breaks, I write an entry into the ledger. Writing it down is cheap and close
to useless. An entry is only worth something once it is bound to a file that makes someone act
differently today: a role's contract, a skill, a hook, or a check that runs.

`harness/.agents/memory/INDEX.md` has a **Cited by** column stating which entries are bound and
which are not. {{meta.cited}} of {{meta.total}} have a file citing them; the other {{meta.orphan}}
point nowhere yet. I keep the unbound part in the table instead of filtering it out, because a
ledger that only shows the finished half cannot be used to check yourself.
