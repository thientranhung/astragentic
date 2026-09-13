---
term: Cross-vendor arm
oneLiner: "A second review from a different vendor's model, because same-vendor blind spots repeat."
order: 11
related: [gate, pass-marker, worktree, role]
diagram: cross-vendor-arm
updated: 2026-09-04
---

**The cross-vendor arm is a review pass fired from a different vendor's model against a completed artifact — Codex reviewing Claude's diff, or the mirrored direction — so the review isn't reading its own kind of blind spot.**

Who fires it and from where depends on scope: the [Builder](/dictionary/role/) fires `arm: ticket` from inside its own [worktree](/dictionary/worktree/), standing in the tree that holds the reviewed commits, so `HEAD` resolves correctly with no gate worktree or path disambiguator needed. Thomas fires `arm: spec` and `arm: slice` from the base checkout instead, where the two can disagree — so those scopes resolve the head explicitly and review from a detached checkout at that SHA. On a Claude root it runs through the plugin runtime (`codex-companion.mjs`); on a non-Claude root it's `codex exec review` directly, and the direct form has been observed to hang, so it needs a timeout and a watching dispatcher.

The arm wins at internal inconsistency against a project's own stated standard, because the arm reads the repository while the author reads the ticket. One measured case: a slice-scope payload of 6,904 added lines across 31 files passed a same-vendor skim that missed three hollow tests in a day; a ticket-scope pass on a smaller diff caught a real deadlock the fix from pass one had just introduced. Getting the range wrong is a documented failure on its own — if `--base` and resolved `HEAD` disagree, the companion can compare a branch to itself and return clean on zero commits reviewed, so every scope prints a range header before trusting the verdict.

## Why it matters here

Astragentic pays for a second model's review, rather than running the same model twice, because two vendors catch different defect classes — a downstream measurement found a same-vendor correctness pass let a secrets-in-export defect through that the cross-vendor pass caught as P1. The cost is real invocation friction: quoting and argv differences between runtimes, a direct-exec path that can hang silently, and a range check that has to run before every verdict is trusted, or the gate can pass having reviewed nothing.

## Seen in:

- `harness/.agents/skills/codex-arm/SKILL.md`
- `harness/.agents/skills/codex-claude-arm/SKILL.md`
- `harness/.agents/memory/INDEX.md` — AST-095, AST-103
- `RELEASE-NOTES.md` — "the cross-vendor arm fires per ticket, not once at a phase end"

## Usage:

"Same-vendor review came back clean, ship it?" — "Fire the cross-vendor arm first — it's the one that's caught the P1s the same-vendor pass missed."
