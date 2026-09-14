---
term: Role
oneLiner: "A fixed job description — Thomas, Shaper, Builder, QA, or Rin — with its own session shape and its own file it can write."
order: 2
related: [harness, worktree, claim, gate]
updated: 2026-09-04
---

**A role is one of five fixed jobs an agent plays in the harness — Thomas, Shaper, Builder, QA, or Rin — each with a different session lifetime and a different thing it's allowed to write.**

The five aren't interchangeable personas you can swap at will; they're defined by session shape as much as by task. Thomas is resident — one session spans many tickets and phases, because he's the only one still around when a [worktree](/dictionary/worktree/) closes, so the durable state (tracker, [frontier](/dictionary/frontier/), dispatch record) is his to keep. Shaper is one unbroken session from align through `to-tickets`, no `/compact` or `/clear` in between, because the whole point is that the full picture stays in context. Builder is one session per ticket, and the sole writer inside its own worktree — everyone else, including other Builders, only reads it. QA runs one session per walk, with the product actually running, judging the live system rather than the diff. Rin runs one session per milestone, dispatched fresh each time with no memory of the last round, in a detached worktree at the exact reviewed SHA — that isolation is what the review [gate](/dictionary/gate/) depends on.

Each role's contract lives in two places: `harness/.agents/roles/<role>.md`, the long-form doc read at session start, and `harness/.claude/agents/<role>.md`, the short system-prompt version that survives context compaction. That split exists on purpose — a role's operating rules used to live only in a doc a tool call returns, and compaction is the first thing that summarizes a tool result away.

## Why it matters here

Splitting a big job into five roles instead of one general "coding agent" costs you: five contracts to keep in sync, five files to update when a rule changes, and role contracts drifting out of alignment with each other if nobody's watching. Astragentic pays that cost because a session boundary is also a scope boundary — Rin's independence, Builder's exclusive write access, Thomas's persistence, all come from a role's session shape being fixed rather than improvised per task.

## Seen in:

- `harness/.agents/roles/thomas.md`, `shaper.md`, `builder.md`, `qa.md`, `rin.md`
- `harness/.claude/agents/thomas.md`, `shaper.md`, `builder.md`, `qa.md`, `rin.md`
- `docs/bmad-distilled/roster.md` — the earlier, vendored role-kit this method grew alongside

## Usage:

"Who reviews this, Builder or Rin?" — "Rin — fresh session, detached worktree, no memory of the last round. That's the whole point of the role."
