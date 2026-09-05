---
title: "Astragentic"
description: "Why I built this coordination layer, what I chose, and what each choice costs."
acts:
  - id: act-1
    eyebrow: "AST-016 · promoted 2026-07-11"
    headline: "Three agents on one checkout lose work without throwing an error."
  - id: act-2
    eyebrow: "SEVEN STAGES"
    headline: "Seven stages mark seven places where something already fell out."
  - id: act-3
    eyebrow: "harness/.agents/memory/INDEX.md"
    headline: "Every ledger line links to a file you can check."
  - id: act-4
    eyebrow: "RELEASE-NOTES.md:393"
    headline: "This loop has never run all the way through on live work."
---

## act-1

I ran three sessions against one checkout and nothing threw an error. An afternoon of work
vanished, and it took me another afternoon to find the cause.

I took the blunt fix: every spawned agent that can run state-changing git gets its own
checkout, including the ones that only read. The read-only exemption was the assumption I had
believed, and it was wrong. The cost is one more worktree on disk per Builder and a few seconds
of setup. I pay it, because that afternoon cost more.

## act-2

The process started with two stages: the agent builds, I review. Review ran five to fourteen
rounds, and most of the later rounds went on clearing up what the earlier ones left behind. The
reviewer was not where it broke. It broke further upstream: decisions that had never been
settled went straight into code, and got settled at the most expensive point in the process.

I moved the loop to the front and cut what was left into seven named stages. The seven stages
are named so that every measured failure attaches to exactly one of them; without names, the
next failure lands somewhere nobody can point at. The cost is a longer pipeline, and three of
the seven are still empty because I have not measured a failure in them.

## act-3

Every time something breaks, I write a line into the ledger. Writing it down is cheap and close
to useless. A line is only worth something once it is bound to a file that makes someone act
differently today: an always-on rule, a Known failures section in a skill, or a check that runs.

The table has a column stating which lines are bound and which are not. {{meta.cited}} of
{{meta.total}} have a file carrying them. The other {{meta.orphan}} point nowhere yet. I keep
the unbound part in the table instead of filtering it out, because a ledger that only shows the
finished half cannot be used to check yourself. Click a row with an arrow and it takes you to
the file, with no command to run.

## act-4

I wrote that line in my own release notes, and I pulled it up here because at the bottom of a
page it reads as modesty for show.

It draws one boundary precisely: proving the tooling is correct and proving the loop is correct
are two different claims, and I have only done the first. No ticket has gone from dispatch to
merge with the gates firing on live work inside this repo. The six failures you just read were
measured downstream or while building this, not inside one closed loop.

I am leaving that gap open. If you install this and it breaks somewhere I have not measured,
that is data I do not have.
