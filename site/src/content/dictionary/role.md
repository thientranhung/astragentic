---
term: Role
oneLiner: "A fixed job description, with its own session shape and its own file it can write."
order: 2
related: [harness, worktree, claim, gate]
updated: 2026-11-22
harness: v6.1.19
---

**A role is one of six fixed jobs an agent plays in the harness, each a Claude Code custom agent with a different session lifetime and a different thing it may write.**

- **Thomas** is the owner's deputy and the resident session. He holds the tracker, the [frontier](/dictionary/frontier/) query, the [claim](/dictionary/claim/), dispatch and merge.
- **BA** sits in the user's seat, reads the repo and walks the running product without writing. The owner opens it; Thomas never dispatches it.
- **Shaper** runs `astra-grill-with-docs`, `astra-to-spec` and `astra-to-tickets` in one unbroken context.
- **Builder** takes one ticket, one [worktree](/dictionary/worktree/), and is the sole writer there.
- **QA** walks the running product as a user, read-only by default, and writes one report.
- **Quick Builder** makes small owner-asked changes on an `ops/*` branch, with no ticket and no loop.

A session boundary is also a scope boundary, so the roles are not swappable personas. Each contract lives twice: `harness/.agents/roles/<role>.md` is the long form read at session start, and `harness/.claude/agents/<role>.md` is the short system prompt that survives compaction. Every role runs on Claude Code, on either terminal host, Herdr or Orca, one host per session.

## Why it matters here

Six contracts cost upkeep: each rule change touches more than one file. Astragentic pays it because Builder's exclusive write access, QA's independence and Thomas's persistence all come from session shape being fixed rather than improvised.

## Seen in:

- `harness/.agents/roles/thomas.md`, `ba.md`, `shaper.md`, `builder.md`, `qa.md`, `quick-builder.md`
- `harness/.claude/agents/` (one file per role)

## Usage:

"Who fixes the walk finding, QA or the Builder?" — "QA advises, Thomas classifies, the Builder fixes. QA never edits."
