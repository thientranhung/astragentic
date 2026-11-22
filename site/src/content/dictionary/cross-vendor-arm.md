---
term: Cross-vendor arm
oneLiner: "A second review from a different vendor's model, because same-vendor blind spots repeat."
order: 11
related: [gate, pass-marker, worktree, role]
diagram: cross-vendor-arm
updated: 2026-11-22
harness: v6.1.19
---

**The cross-vendor arm is one direct, read-only `codex exec` call over a completed artifact, so the review is not reading its own vendor's blind spots.**

It needs no plugin. The model is `gpt-6.2-astra` at medium effort, set explicitly. The [Builder](/dictionary/role/) fires `arm: ticket` from its own [worktree](/dictionary/worktree/) with the edge lens, the Shaper fires `arm: spec` with the adversarial lens, and Thomas fires `arm: slice` with the edge lens from a detached checkout at the slice head. At ticket scope the receipt is the `arm(ticket):` [pass-marker](/dictionary/pass-marker/).

**Measurement.** Blind verification over 7 replayed tickets, 72 runs and 336 findings: the edge lens found 21 real defects per run at precision 0.77 and about 79k tokens. Codex found 29 of 34 real defects and Claude 17. The spec and slice lenses are `chưa đo`.

When Codex is out of quota or returns no schema-valid output, the arm is `NOT RUN` with the reason, never a pass. At ticket scope `astra-review` then runs its Opus adversarial lens, recorded as same-vendor and advisory. Only the owner may accept proceeding without the arm.

## Why it matters here

Astragentic pays for a second vendor because the two catch different defect classes. The cost is about 160k Codex tokens per ticket when pass 2 runs, and a rule that a missing output fails closed.

## Seen in:

- `harness/.claude/skills/codex-arm/SKILL.md`
- `harness/.claude/skills/astra-review/SKILL.md` (the Opus fallback lens)
- `RELEASE-NOTES.md` — 6.1.18 and 6.1.19

## Usage:

"Same-vendor review came back clean, ship it?" — "Fire the arm first. If it prints NOT RUN, that is not a pass."
