---
title: "Why"
description: "Five questions about the design of Astragentic, a scaffold for autonomous coding: why it is needed, why the tracker holds the state, why subagents do not coordinate the team, why mattpocock-skills, why a second vendor reads the diff."
---

Astragentic is built for autonomous coding: a team of AI agents runs the build on its own, while
people keep direction and decisions. Every team works its own way, and no process can be imported
intact, so Astragentic is designed as a scaffold: a frame for running a team of AI agents that has
the hard parts settled, with every component open for you to adapt.

The five questions below are the five largest design decisions in that scaffold. Every answer
follows the same frame: a one-line answer, the mechanism, the measurement on record where there
is one, and the cost. Measurements carry an AST-xxx code and have a matching lesson on the Lessons page.

## why-astragentic

A coding agent today can carry the build: it takes work, writes code, runs tests, returns results.
The engineer moves into a directing role. Two tasks still take most of the time: answering the
questions an agent raises while it works, and reviewing the quality of what comes back.

Both converge on one bottleneck. An agent's technical questions usually exceed the expertise of
the person directing it, so the common workaround is to take the question to another AI and relay
the answer. The human becomes a relay, and the decision is in practice made by AI. Astragentic
removes that relay.

The first mechanism: Thomas, the team's representative. Thomas holds the project context, reads
the artifacts agents return, weighs the proposed options and tech stacks, answers technical
questions, and escalates only the decisions that are yours to make: product direction, user
experience, priorities. You work as the client of a development unit: set requirements, follow
progress, and step in when the team drifts.

The second mechanism: a team with roles, operating in the open. Every agent is a named session
with its own pane in herdr, and its work history stays in that session. You can watch what each
agent does, Thomas can trace an incident, and the way agents coordinate becomes data for improving
the scaffold itself. Subagents and agent teams inside a runtime run hidden in the parent process
and show none of this.

Both mechanisms rest on one design principle: Astragentic is a scaffold, not a closed process.
The scaffold settles inter-agent communication, SDLC discipline through skills, isolation through
worktrees, state on the tracker, gates before merge and cross-vendor review. Roles, contracts,
skills and hooks are files in your repo, so the scaffold adapts to how your team operates.

Cost: one more toolset to install, understand and upgrade, and every upgrade is an event the
project has to absorb. And so far I have proven that each tool runs correctly; the whole loop from
dispatch to merge with every gate firing on real work is still being measured.

## why-tracker

The state of the work has to live somewhere an agent cannot keep in its context and you can open
and read. The tracker is the only place that satisfies both, which is why ADR-0001 calls it the
team's coordination substrate, not a notebook.

Astragentic takes three things from the tracker. Blocking edges form a dependency graph, so
"what is waiting on what" is data rather than memory. The frontier query answers "what is ready
right now". The assignee is the claim: writing a name on the ticket before creating the worktree
is what keeps two concurrent sessions apart, with no lock file, no queue, and no dispatcher in
the middle deciding who goes first.

Measurement: AST-057, on a real project, one ticket looked blocked for hours after both of its
blockers had merged, and four tickets wore a ready label while blocked. The frontier was computed
correctly but only inside the agent's head. So the contract carries both halves: once computed,
write the answer back to the tracker, and never read a ready label as if it were state.

Cost: Astragentic inherits every limit of the tracker you use. No tracker has an assignee field
designed to hold `builder/<ticket-id>`. GitHub Issues has no real status field, so status lives
in labels and the Project board column is a copy that has to be kept in sync. Each adapter
therefore has its own workaround. And because the tracker holds state rather than passively
recording it, it can drift from reality; `reconcile-tracker` measures the tracker against git,
never against the tracker itself.

## why-not-subagents

Claude Code has subagents and agent teams, and they work well for work inside one session. They
are not enough to coordinate a team, because the four things missing are missing in the same
way: they give no signal when something goes wrong.

A shared checkout. A subagent runs in the same worktree as its parent session, so several agents
drag each other's HEAD around. AST-016 caught a read-only reviewer running `git switch` on
someone else's checkout.

A shared context. A fork inherits its parent's whole context, including things nobody meant to
hand over. AST-006: a fork inherited the parent's model too, so a job meant for a cheap model ran
on the most expensive one. AST-119: a fork inside a Builder sent a handback to the dispatcher
under the Builder's own name, and the Builder never saw it. AST-130: a fork signed a
`simplify(increment):` marker onto code it had just committed itself, in the permitted form, and
it only surfaced because the Builder saw a commit it had not made.

No tracker holding state. A subagent's state lives in the parent session's context, disappears
when the session compacts, and while it lives you cannot see it.

No pane to look at. AST-018: a dispatch was narrated in words and never actually called, and
nothing distinguished the two. A pane in herdr can be counted; an in-process subagent cannot.

And no second vendor: a Claude subagent is still Claude, so there is no cross-vendor review.

Astragentic still uses forks inside a Builder for report-only work, under one rule: the fork
must have `isolation: "worktree"` and must never message the dispatcher.

Cost: you have to install herdr and configure a tracker, two dependencies a subagent does not
need. Each Builder costs a worktree on disk and a few seconds of setup; each dispatch costs one
write and one read on the tracker. The process is longer and there are more names to remember. I
pay that because silent failures cost far more.

## why-mattpocock

Astragentic does not write its own method. The craft, from survey to spec, tickets, implement
and code review, is `mattpocock-skills` (`wayfinder`, `grill-with-docs`, `to-spec`,
`to-tickets`, `implement`, `code-review`). Astragentic wraps coordination around it. Release
1.0.0 removed 19 skills once vendored into the repo to make room for the upstream plugin;
ADR-0001 records that decision.

The reason is where the loop sits. This method loops at the start of the process: `grilling`
runs until no open question is left, and every review after that is a bounded pass. The old way
looped at the end: unsettled decisions went straight into code and were settled in review, the
most expensive point.

Measurement: two weeks of real use produced plans that went through 5 to 14 review rounds. Round
2 added a lock, round 3 removed it as false comfort, and round 8 was still fixing a sentence
round 2 left behind. The reviewer was not the fault; decisions settled too late were.

On Superpowers, the question usually asked alongside: it is a good system and my team uses it on
other projects. It packs method and coordination into one session, keeps state in a plan file on
the branch, and has nothing equivalent to `to-tickets` producing tickets with blocking edges on
the tracker. Running both in one repo is two coordinators fighting over the same ground, so
Astragentic does not combine them.

Cost: a real dependency. `check-requirements.sh` fails hard without `mattpocock-skills >=
1.2.3`. The `/mattpocock-skills:<name>` addresses live in the contracts, so changing the method
means rewriting contracts. And Astragentic can only patch the seams, not the plugin: AST-057 is
a defect inside `to-tickets`, and the right answer is to teach the contract to live with it, not
to fork a patch.

## why-cross-vendor

After Claude has written and self-reviewed, a model from another vendor reads the diff. The
mechanism: the arm reads the repository while the author reads the ticket, so it catches
contradictions with the project's own declared standards, which the author cannot see while
looking from the requirements side.

Measurement: AST-015, a same-vendor review let through a defect that put a live secret and buyer
PII into a tracked file; the cross-vendor pass caught it and filed it as P1. AST-012 draws the
general point: two lenses catch two classes of defect, so they run side by side rather than
replace each other. Another case on a large diff: 6,904 added lines across 31 files went through
a same-vendor read that missed three empty tests, while a ticket-scoped read on a smaller diff
caught a real deadlock the previous round's patch had just created.

Cost: friction at call time. Quoting and argv differ between runtimes. `codex exec` has hung
silently before, so it needs a timeout and a dispatcher standing watch. The most dangerous part
is scope: if `--base` and `HEAD` resolve differently, the companion compares a branch with itself
and returns clean on zero commits. So every read prints its range line before the verdict is
trusted.
