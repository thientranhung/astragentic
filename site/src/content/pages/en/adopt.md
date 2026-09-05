---
title: "Install it into your repo"
description: "The installer stages an immutable release and stops. Integration is done by an agent that has read your real project first."
---

This installer deliberately does not modify your project. `./install.sh` stages an immutable
release into `.astraler/releases/<version>` and stops there. The integration is done by an
agent running inside your own repo, after it has read your build commands, your agent
config, and your real Git state.

I split it in two because a copy-over installer will always overwrite the wrong thing. It
cannot tell what belongs to the harness from what belongs to the project and what the owner
owns. The cost is that you run one more agent session and sit and read what it intends to
do, instead of typing one command and going for coffee.

## brownfield

These four skills exist because real repos are rarely clean. `bootstrap-glossary` pulls
domain vocabulary out of the code itself, each term carrying the file it was read from and
marked unreviewed until the owner confirms it. The rule is extract, never invent, because a
glossary an agent imagined but wrote in a confident voice is more dangerous than no glossary
at all.

`batch-triage` takes an inherited backlog in one pass instead of one item at a time.
`legacy-testing` builds a seam into code that offers nothing to test against. `untangle` is
for repos with no module boundaries left to improve, where a clean restructure would arrive
as one diff nobody can review.

The shared cost for all four: this is work you finish before the first ticket can run.
