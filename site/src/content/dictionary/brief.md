---
term: Brief
oneLiner: "The text a dispatched agent gets instead of a conversation."
order: 8
related: [worktree, role, tracker, claim]
updated: 2026-09-04
---

**A brief is the block of text handed to a dispatched agent in place of a conversation — everything it needs arrives once, in that one message.**

The brief's first line is a fixed shape: the phase's slash command, plugin-qualified (`/mattpocock-skills:<name>`), because what actually reaches the agent's pane is text arriving as a user turn, not a function call with named arguments. Everything after that first line is the rest of the instructions — the ticket, its spec, the owner intent, the workspace label, the ticket ID, branch, base, worktree path. `dispatch-ticket` treats submitting the brief as its own step, separate from writing it, because a multi-line brief pasted into a pane composer lands without submitting — the paste consumes the newlines that would normally hit Enter, and the pane sits reporting `idle` with an unsent brief still in the box.

That's also why a brief carries a `Base:` field as a required field rather than a rule left in prose: a boundary an agent has to remember is a boundary it eventually forgets, but a field that has to arrive with the brief gets checked mechanically. Downstream, the [Builder](/dictionary/role/) is told to pass `code-review` the exact `Base:` the brief carried, because "the increment" on its own is not a git ref anyone can resolve later.

## Why it matters here

Astragentic writes the brief as one complete artifact instead of a back-and-forth because the agent on the other end doesn't keep a memory between turns the way a person would — a brief that's missing a field doesn't get clarified mid-task, it gets guessed. The cost is that every brief has to be self-contained: no assuming shared context, no "as discussed earlier," and every dispatch needs its own watcher for the reply, because a new turn gets a new watcher, not just the first brief.

## Seen in:

- `harness/.agents/skills/dispatch-ticket/SKILL.md` (brief submission mechanics, the composer-paste failure mode)
- `harness/.agents/roles/thomas.md` (grill-with-docs brief for `to-tickets`)
- `harness/.agents/roles/builder.md` (`Base:` field, brief as the source of the ticket and owner intent)

## Usage:

"Builder's just sitting there idle." — "Check the composer — the brief probably pasted without hitting Enter. Happens with multi-line ones."
