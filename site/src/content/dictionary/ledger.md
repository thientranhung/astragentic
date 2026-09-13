---
term: Ledger
oneLiner: "The append-only file of every measured failure mode, so a mistake never has to be found again silently."
order: 12
related: [gate, pass-marker, tracker, cross-vendor-arm]
updated: 2026-09-04
---

**The ledger is `recurring-failure-modes.md` — an append-only record of every failure mode Astragentic has measured while operating itself, each one numbered `AST-<n>` and never renumbered or deleted.**

Entries stay short: the finding plus its binding surface, a few lines, with fuller incident narratives left in git history rather than bloating the entry itself. Status moves through `open → proposed → promoted → closed`, or gets marked `superseded` / `reverted` in place when a later measurement proves an earlier entry wrong — text and number stay, because that's what lets an entry still be cited as evidence years later. The IDs were `FW-0xx` until renamed to `AST-` at 1.1.0, because a project the harness installs into already used `FW-` for its own ledger, and one measured repo had six IDs meaning different things across 235 citations, told apart only by a paragraph a reader had to already know existed.

The ledger is explicit that it's advisory rather than authoritative — code, docs and ADRs are stronger truth, and where an entry conflicts with current code, the code wins. It turned its own claim about itself into a case study: the README once stated "50 entries" while the file held 66, because the staleness audit compared the README's count to the ledger without reading the ledger's own header claim. That's now checked by `docs-staleness-audit.sh` against a plain `grep -c "^### AST-"` on the file.

## Why it matters here

Astragentic keeps one append-only ledger instead of editing entries in place because a silently corrected mistake is one that gets made again under a different name — the point of `AST-` numbers is that a [gate](/dictionary/gate/) or a rule can point at a specific measured incident rather than a vague "we've learned this before." The cost is volume: as of this writing the file runs 136 entries (AST-001 through AST-137, one withdrawn) across roughly 3,600 lines, and reading it in full is deliberately not how it's meant to be consumed — grep the section you need.

## Seen in:

- `harness/.agents/memory/recurring-failure-modes.md` (the ledger itself — header states "136 entries (AST-001 … AST-137, 067 withdrawn)")
- `harness/.agents/memory/INDEX.md` (indexed view of ledger entries with citation counts)
- `harness/.agents/memory/RULES.md` (rules that cite specific `AST-` entries as their evidence)

## Usage:

"Feels like we're about to repeat that worktree mixup." — "Grep the ledger first — if it's happened it's already AST-something, and there's a bound rule for it."
