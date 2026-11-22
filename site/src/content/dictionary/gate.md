---
term: Gate
oneLiner: "A review a merge cannot pass without, checked by a script rather than a memory."
order: 10
related: [pass-marker, cross-vendor-arm, worktree, ledger]
updated: 2026-11-22
harness: v6.1.19
---

**A gate is a review that has to leave a checkable artifact before a merge is allowed to happen.**

Astragentic runs gates at three scopes. At ticket scope the Builder runs `astra-review`, `simplify` once, and the cross-vendor arm, then records `simplify(increment):` and `arm(ticket):`. Thomas runs `qa(walk):` before the merge when the ticket changes a surface. At slice close Thomas runs the slice gate: the slice arm plus the `astra-slice-reviewer` fan-out, recorded as `arm(slice):`.

What makes a gate real is the same thing that makes a [pass-marker](/dictionary/pass-marker/) real. `check-simplify-markers.sh` refuses the merge when the `simplify(increment)` or `arm(ticket)` receipt is missing, and Thomas verifies the rest by artifact at the merge. A quick ticket owes only the built-in `code-review`.

**Measurement.** Slice gates are advisory in the script: it reports merges on the base since the last `arm(slice)` marker, and more than 10 is a STOP in `thomas.md`.

## Why it matters here

Astragentic gates on artifacts instead of an agent's say-so because a check a script can refuse to proceed without keeps firing, and a rule in prose goes quiet. The cost is that every gate needs its own marker convention, a reader wired into a checked script, and a fixed point in the merge sequence: commit first, then gate on the committed SHA.

## Seen in:

- `harness/.agents/roles/thomas.md` (merge verification, slice gate)
- `harness/.claude/skills/dispatch-ticket/MARKERS.md` (`arm(slice):`, `qa(walk):` shapes)
- `harness/.claude/skills/astra-review/SKILL.md`

## Usage:

"Can we skip the slice gate this once, it's a small slice?" — "More than 10 merges since the last `arm(slice)` is a STOP. Run it, or write down why not."
