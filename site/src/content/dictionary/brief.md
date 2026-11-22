---
term: Brief
oneLiner: "The text a dispatched agent gets instead of a conversation."
order: 8
related: [worktree, role, tracker, claim]
updated: 2026-11-22
harness: v6.1.19
---

**A brief is the block of text handed to a dispatched agent in place of a conversation — everything it needs arrives once, in that one message.**

The brief's first line is a fixed shape: the phase's slash command (`/astra-implement-with-tdd <ticket>` for a Builder, `/astra-grill-with-docs` or `/astra-to-tickets <spec-id>` for a Shaper), because what reaches the agent's pane is text arriving as a user turn, not a function call with named arguments. Everything after that first line is the rest of the instructions — the ticket, its spec, the owner intent, the workspace label, the ticket ID, branch, base, worktree path. `dispatch-ticket` treats submitting the brief as its own step: a Builder, Shaper or QA pane takes it over SendMessage, and the dispatch mod turns it into a real user turn. A pane without the mod can receive a brief that lands in the composer unsent, so the dispatcher reads the composer before re-sending.

That's also why a brief carries a `Base:` field as a required field rather than a rule left in prose: a boundary an agent has to remember is a boundary it eventually forgets, but a field that has to arrive with the brief gets checked mechanically. Downstream, the [Builder](/dictionary/role/) pins `astra-review` to the exact `Base:` the brief carried, because "the increment" on its own is not a git ref anyone can resolve later.

## Why it matters here

Astragentic writes the brief as one complete artifact instead of a back-and-forth because the agent on the other end doesn't keep a memory between turns the way a person would — a brief that's missing a field doesn't get clarified mid-task, it gets guessed. The cost is that every brief has to be self-contained: no assuming shared context, no "as discussed earlier," and every brief expects an answer: a mod pane reports its own `TURN-END`, and the dispatcher verifies by artifact.

## Seen in:

- `harness/.agents/skills/dispatch-ticket/SKILL.md` (the brief, its required lines, submission)
- `harness/.agents/roles/thomas.md` (Shaper briefs: `astra-grill-with-docs`, `astra-to-tickets`)
- `harness/.agents/roles/builder.md` (`Base:` field, brief as the source of the ticket and owner intent)

## Usage:

"Builder's just sitting there idle." — "Read the composer. The brief may have landed unsent in a pane without the mod."
