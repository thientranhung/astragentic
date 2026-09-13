---
term: Gate
oneLiner: "A review a merge cannot pass without, checked by a script rather than a memory."
order: 10
related: [pass-marker, cross-vendor-arm, worktree, ledger]
updated: 2026-09-04
---

**A gate is a review that has to pass — and produce a checkable artifact — before a merge is allowed to happen.**

Astragentic runs gates at more than one scope: a per-ticket gate the Builder self-fires plus an independent one, and a milestone gate Rin dispatches at a ticket or epic close. Rin's [role](/dictionary/role/) file distinguishes `mode=adversarial` (a finalized spec) from `mode=code-review` (a ticket/PR or epic close) — two gate modes, not the same check run twice. What makes a gate real rather than aspirational is the same thing that makes a [pass-marker](/dictionary/pass-marker/) real: a physical artifact a script the router already runs refuses to proceed without. `thomas.md` now states the merge order explicitly — commit, then gate on the committed SHA — since the earlier reading let a check certify history predating the code it reviewed.

The gate that measured this hardest is the milestone one. A downstream project counted 35 `arm(ticket):` markers and 22 `simplify(increment):` markers against zero Rin rounds across 107 merges and 33 tickets — the "more than 10 merges since the last round is a STOP" rule that nothing was ever computing, because Rin's report file lived outside every checkout with no marker in the merge range and no reader in the gating script. The fix wasn't a stronger warning; it was giving the milestone gate the artifact the ticket gate already had.

## Why it matters here

Astragentic gates on artifacts instead of on an agent's say-so because the gates that fire are demonstrably the ones with something a script can refuse to proceed without — everything else goes quiet under its own weight without anyone noticing. The cost is that every gate needs its own marker convention, its own reader wired into a checked script, and a fixed point in the merge sequence relative to the commit — skip any of those three and the gate can pass while reading a tree that predates the work it's meant to certify.

## Seen in:

- `harness/.agents/roles/rin.md` (spec vs milestone gate modes)
- `harness/.agents/skills/dispatch-ticket/MARKERS.md` (`rin(gate):`, `qa(walk):` shapes and the 107-merges-zero-rounds measurement)
- `RELEASE-NOTES.md` — "Gate on the committed SHA" (2.8.0)
- `harness/.agents/memory/recurring-failure-modes.md` — AST-001, AST-057

## Usage:

"Can we skip the milestone gate this once, it's a small ticket?" — "That's exactly the shape that went silent for 107 merges last time. Fire it, empty commit's fine if it's clean."
