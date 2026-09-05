---
title: "Vibe coding gives you speed. Vibe engineering keeps it."
description: "What happened when I stopped running one AI coding agent and started running three, and what it took to make that actually work."
date: 2026-09-04
readingMinutes: 10
---

The first time I used a coding agent that was actually good, the distance between an idea and working software just collapsed.

I'd describe what I wanted in plain language. The agent read the codebase, found the right files, wrote the component, fixed the bug, ran the tests. Work that used to take a few hours took a few minutes. The small loops — change a state, add an endpoint, fix an interaction — got fast enough that the friction basically disappeared. That feeling is addictive: you think of something, you say it, code shows up. That's the real value of vibe coding — it strips out a huge chunk of the cost of turning intent into code.

Then I tried it on a real feature. Not a button, not a single function — a feature with ten tickets, real dependencies between them, touching existing code, needing more than one sitting to finish. I opened three agents at once.

One finished early. One was waiting on something the first hadn't merged yet. The third had stopped partway through, and nothing told me it had stopped. Two of them had touched the same module. Five questions landed in my lap at almost the same moment — one I could answer in seconds, one that needed me to re-read code, one that was actually a product decision from the week before.

I wasn't building the product anymore. I'd become the router, the project manager, the reviewer, the debugger, and the shared memory for a team of AI agents I'd just created.

## A good agent doesn't add up to a good team

One coding agent can be genuinely good at one task. But a real product is never one task.

A feature moves through a bunch of states — idea, clarify the requirement, spec, split into tasks, manage dependencies, implement, review, merge, QA — and an agent sitting inside "implement" doesn't naturally know where it stands in that sequence, doesn't know another agent is editing the same file right now, doesn't know which questions it can answer itself versus send back to a human, and doesn't know who's going to check its own "done" message, or how.

If all you do is spin up more agents, you get more capacity to produce code. You don't automatically get more capacity to run engineering.

That's the line I ended up drawing between vibe coding and vibe engineering:

| Vibe coding | Vibe engineering |
|---|---|
| Optimizes for one prompt | Optimizes for the whole feature lifecycle |
| Produces code fast | Ships changes safely |
| One agent, one context | Multiple roles, multiple sessions |
| Trusts the answer it gets | Verifies with an artifact |
| "Done" when the agent says so | "Done" when code, tests, review, and QA all have evidence |
| Context is the memory | The tracker and git are the memory |
| A human coordinates by hand | A system coordinates by protocol |

Vibe coding isn't wrong. It just stops too early. It solves the moment code gets written extremely well, but when the rate of code production goes up, the rest of engineering doesn't go away — ownership, isolation, coordination, review, observability, provenance, and recovery all matter *more*, not less.

## A team of agents still needs project management

In a real engineering team, nobody hands over one sentence and lets everyone start writing code. A team gets a rough spec, or a feature request missing detail, or sometimes just an idea. Before anyone builds anything, someone has to work out the actual goal, what's out of scope, how the existing system behaves, and which modules, data, and user journeys the feature will touch.

Then the work gets split. What can run independently, what's blocked, do two tasks with no business dependency still touch the same module, what proves a task is actually finished, who does it, and who unblocks it if it stalls?

That's project management in its most ordinary form, and a team of agents doesn't get to skip it. A smarter model doesn't remove the need for it — it just makes project management the next bottleneck that has to be designed on purpose.

The process, stripped down, looks like this:

1. Take in the spec: understand the owner's intent and desired outcome.
2. Analyze: read the codebase, find the seams, constraints, dependencies, blast radius.
3. Split into tasks: small enough for one session, with checkable acceptance criteria.
4. Track them: state, blocking edges, ownership, expected area of change.
5. Dispatch: only work that's ready and doesn't collide with something in flight.
6. Watch for stalls: an agent waiting, stopped, or needing a decision.
7. Integrate: review, QA, merge in dependency order, then open up what that unblocks.

At that point orchestration stops meaning "call several agents at once." Orchestration is project management, encoded as a protocol.

## Astragentic, in one sentence

Astragentic is an operating framework for running multiple AI coding agents against one real codebase. It doesn't introduce a new model and doesn't replace Claude Code, Codex, or OpenCode — those are still where the actual thinking, reading, and editing happen. What it adds is structure: roles, boundaries, and a lifecycle a ticket moves through, built to answer how agents work in parallel without colliding, how the owner sees what's happening, how only the decisions that genuinely need a human reach one, and how you know a step really ran instead of trusting that an agent said so.

The shape of it, top to bottom: the owner and the issue tracker, Thomas as the orchestration layer, then Shaper, Builder, Rin, and QA as the working roles, running on Claude Code, Codex, or OpenCode, backed by git worktrees, a terminal workspace, tests, and a browser for verification. The tracker holds what's supposed to happen; git holds what actually happened; commits, test output, and gate reports are the evidence something real occurred.

## From a feature to a dependency graph

Back to the ten-ticket feature. The easy failure mode is handing the whole thing to one agent and asking it to "make a plan" — a plan can look clean and still leave the real decisions open, and if those decisions get pushed into implementation, whoever reviews it later deals with them at the most expensive point.

That's the reasoning behind ADR 0001: put the loop at the front, not the back. A prior version of this method measured plans and slices taking **5 to 14 review-gate rounds** — round two would add a safeguard, round three would decide it was false comfort and remove it, and later rounds spent their time cleaning up after earlier ones. The exit condition belonged to whichever side could always find one more thing to flag, while the decisions that should have been settled up front never had been.

So the loop moved to the front. Foggy, multi-session effort starts at wayfinding; anything that already fits one session goes straight to Shaper clarifying the requirement, holding the spec and the whole ticket graph in one continuous session so the full picture doesn't get lost partway through. Every answer that matters needs a source — codebase, prior decision, research, prototype, or the owner — or it stays an open question rather than a guess dressed up as one.

The spec gets reviewed before any ticket is cut — a bad seam costs a paragraph to fix in a spec, and a whole slice to fix once ten tickets are already built on it. Once it holds up, it splits into tickets sized for one session, wired by blocking edges into a dependency graph, from which the system computes the frontier: every ticket with no open blockers and no one holding it.

## Claim before worktree, then five roles

With more than one Builder running, "who's working on this ticket?" can't live in a chat message. The assignee field on the tracker *is* the claim — written before a worktree exists, then read back to confirm it landed, before a branch and worktree get created. Each Builder gets its own chain: ticket → assignee → pane → worktree → branch → PR, and is the only thing writing inside that worktree; Thomas and everyone else only read it.

Worktrees solve the collision at checkout time, not at merge time — two tickets with no business dependency can still touch the same module. So each dispatch also carries a write-set, the area of code it's expected to change, and overlapping write-sets get sequenced instead of run in parallel. A prompt telling an agent "don't conflict with the other agent" doesn't create an atomic claim, a separate checkout, or visibility into what another worktree is touching. That's the difference between a prompt and a mechanism.

The five roles that carry this out aren't split by seniority — they're split by session boundary and by the kind of context each phase needs.

**Thomas** stays alive across tickets and phases — manages the frontier, claims work, dispatches agents, tracks state, and verifies artifacts before merging. It's also the filter for decisions: anything answerable from convention or the codebase gets resolved and sourced, anything that changes scope, product behavior, or risk goes back to the owner. The goal isn't removing humans from the loop; it's pulling them in only where their judgment is worth the most.

**Shaper** runs clarification, writes the spec, and cuts tickets in one continuous session, so seam and module-boundary decisions get made while the whole feature is still in context, rather than leaving each Builder to make a locally optimal call that doesn't add up to a coherent whole.

**Builder** knows one ticket deeply instead of ten vaguely — one branch, one worktree, one pane, one clear definition of done. It implements, tests, reviews its own increment, simplifies, and produces browser evidence for anything a user would see.

**Rin** reviews from a detached worktree at the exact commit under review, never inside the Builder's own checkout — a second opinion, plus a check that the process left the traces it's supposed to.

**QA** doesn't read the diff — it uses the running product. A green test suite only proves the things someone thought to assert; it won't catch a control nobody can see, or two screens quietly disagreeing about the same number.

## Review without an infinite loop

Every ticket goes through the same short ladder once: review against the repo's real standards, review against the spec, a simplify pass with its own provenance in the commit, then a cross-vendor arm before merge — plus one more gate from Rin at a milestone. If a Builder ran on one vendor, the arm has the other vendor read the same diff: not a contest between models, but a check against a system grading its own homework from the angle it wrote it in. A design-level blocker doesn't trigger more rounds; it becomes a question for the owner, because no review step substitutes for a human product decision.

## "The agent said it ran" is not evidence

One of the harder things to internalize running agents this way: confident-sounding text is not the same as a true state. An agent can say tests passed, say a review came back clean, say "done" while the change is still uncommitted — and a pane going idle doesn't prove anything finished either.

So the system leans on artifacts instead of self-reports: the git SHA pinning down what was reviewed, the diff showing what actually changed, test output tied to the command that produced it, a marker commit recording the simplify pass, a gate report written to a file instead of a terminal's scrollback, and the tracker reconciled against git instead of trusted on its own say-so. A pane's status is a bell, not a verdict.

This sounds overly rigid until an agent reports finished work that was never committed, and a cleanup step removes the worktree on the strength of that report — the work only ever existed on disk, and it disappears with the worktree. No amount of better prompting fixes that. A check that runs before cleanup does.

## Built from failure, not just from principle

This system keeps an append-only ledger of the failure modes it has actually observed — agents sharing a checkout and landing a commit on the wrong branch, review looping for many rounds because decisions never got resolved up front, an agent reporting done on work never committed. Each entry follows the same path: a real failure, the rule it justifies, the mechanism that enforces the rule going forward. The count isn't a vanity metric — what matters is that every guardrail traces back to the failure that produced it.

## Vibe coding is still where it starts

I don't think vibe engineering replaces vibe coding. Vibe coding is still a real step forward — it unlocks speed, exploration, and the plain enjoyment of turning an idea into something that runs. But a demo that runs and a change that can ship are two different claims.

Once you're running multiple agents, runtimes, and tickets in parallel, the interesting question stops being "how good is this model at writing code" and becomes "what system lets all of that capability produce one correct product." Maybe the next stretch of software engineering isn't one developer talking to a smarter model — it's several agents with clear roles, working in parallel toward the same goal, leaving behind evidence a person can check, and pulling a human in only where one is genuinely needed.

Vibe coding gives you speed. Vibe engineering is what turns that speed into a system.
