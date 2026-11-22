---
term: Pass-marker
oneLiner: "An empty commit that proves a review actually ran, not just that it should have."
order: 9
related: [gate, worktree, cross-vendor-arm, ledger]
updated: 2026-11-22
harness: v6.1.19
---

**A pass-marker is an empty commit at the reviewed head that records a check ran, naming what ran and what it found, so "it should have passed" never has to be taken on faith.**

Four kinds exist: `simplify(increment):` and `arm(ticket):` come from the Builder, `arm(slice):` and `qa(walk):` from Thomas. `check-simplify-markers.sh` reads them, not a hand-rolled `git log --grep`, because `--grep` matches any line of a message and a squash that quotes a subject counts as carrying one. The newest marker must cover the head's tree, within an allowance of 100 non-test content lines; over it, the answer is one more pass.

**Measurement.** The 100-line allowance was set on 119 downstream merges, 106 of which fell inside it.

Markers may be empty: a `simplify(increment):` reading "no findings" is a legitimate pass. A wrong marker is retracted in the open by a new one with `Supersedes: <sha>`, never rewritten. `arm(slice):` and `qa(walk):` are advisory and measured on the base, since a milestone marker cannot appear inside a ticket branch.

## Why it matters here

Astragentic ties merge readiness to a marker instead of a status report because a [gate](/dictionary/gate/) with an artifact a script checks actually blocks. The cost is discipline: every pass ends in a real commit, empty ones included, and a marker that is not at the current head says nothing.

## Seen in:

- `harness/.claude/skills/dispatch-ticket/MARKERS.md`
- `harness/.claude/skills/dispatch-ticket/CLEANUP.md`
- `harness/.agents/roles/builder.md` (marker order at handback)

## Usage:

"Simplify pass says clean, but I don't trust it." — "Run `check-simplify-markers.sh <base> <head> --marker 'simplify(increment)'`. Exit 0 means the marker is well formed and covers the head."
