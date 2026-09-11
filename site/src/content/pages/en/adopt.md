---
title: "Install it into your repo"
description: "The installer stages an immutable release and stops. Integration is done by an agent that has read your real project first."
---

This installer deliberately does not modify your project. `./install.sh` stages an immutable
release into `.astraler/releases/<version>` and stops there. The integration is done by an
agent running inside your own repo, after it has read your build commands, your agent config,
and your real Git state.

I split it into two steps because a copy-over installer always overwrites the wrong file. It
cannot tell what belongs to the harness from what belongs to the project and what the owner
owns.

**Trade-off.** You run one more agent session and read what it intends to do, instead of typing one
command and walking away.

## brownfield

These four skills exist because real repos are rarely clean.

- **`bootstrap-glossary`.** Pulls domain vocabulary out of the code itself; each term carries the
  file it was read from and stays marked unreviewed until the owner confirms it. The rule is
  extract, never invent: a glossary an agent imagined but wrote in a confident voice is more
  dangerous than no glossary at all.
- **`batch-triage`.** Takes an inherited backlog in one pass instead of one ticket at a time.
- **`legacy-testing`.** Builds a seam into code that offers nothing to test against.
- **`untangle`.** For repos with no module boundaries left to improve, where a clean restructure
  would arrive as one diff nobody can review.

**Trade-off.** Shared across all four: this is work you finish before the first ticket can run.
