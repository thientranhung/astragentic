---
term: Pass-marker
oneLiner: "An empty commit that proves a review actually ran, not just that it should have."
order: 9
related: [gate, worktree, cross-vendor-arm, ledger]
updated: 2026-09-04
---

**A pass-marker is an empty commit at the reviewed head that records a check ran, naming what ran and what it found, so "it should have passed" never has to be taken on faith.**

The shape is fixed across marker kinds — `arm(ticket):`, `simplify(increment):`, `rin(gate):`, `qa(walk):` — and `check-simplify-markers.sh` reads them, not a hand-rolled `git log --grep`. That distinction matters because `--grep` matches any line in the whole commit message, so a squash or merge commit that merely quotes a marker subject in its body counts as carrying one; measured downstream at 193 matches over 23 real markers. The commit body carries a `Pass:` line naming what ran, since the subject alone can't tell a sanctioned pass from a substitute — itself a measured failure, with a two-in-three miss rate among Builders who ran the pass correctly.

Markers may be empty — a `simplify(increment):` reading "no findings on `<base>..<head>`" is legitimate, not a skipped step, and the marker is what makes an absent pass and an empty one distinguishable in the tree at all. If a committed marker turns out wrong, it's retracted in the open with a fresh marker carrying `Supersedes: <sha>`, rather than rewritten — a record showing a mistake beats a tree that looks clean. `rin(gate):` and `qa(walk):` markers are advisory and measured on the base rather than a ticket's range, since a milestone marker can't appear inside a ticket branch by construction.

## Why it matters here

Astragentic ties merge readiness to a marker instead of a status report because a [gate](/dictionary/gate/) with a physical artifact a script already checks is one that actually blocks a merge — a milestone gate with no marker and no reader in the gating script went silent for over a hundred merges before anyone noticed. The cost is discipline: every pass has to end in a real commit, empty ones included, and a marker that isn't at the current head is worthless — a fold that moves the tree past what the pass read makes the marker a green shirt on a stale diff.

## Seen in:

- `harness/.agents/skills/dispatch-ticket/MARKERS.md`
- `harness/.agents/skills/dispatch-ticket/CLEANUP.md` (`Pass:` line, the 193-vs-23 grep measurement)
- `harness/.agents/roles/rin.md` (`rin(gate):` marker requirement)
- `harness/.agents/memory/recurring-failure-modes.md` — AST-089, AST-090, AST-099, AST-133, AST-136

## Usage:

"Simplify pass says clean, but I don't trust it." — "Read the `Pass:` line, not just the subject — that's the one that's actually been wrong before."
