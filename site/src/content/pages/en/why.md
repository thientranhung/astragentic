---
title: "Approach"
description: "The approach behind Astragentic, a scaffold for autonomous coding: the orchestrator agent model, the issue tracker as state, why coordination does not live in subagents, the mattpocock-skills method, and the second-vendor read."
---

Astragentic is built for autonomous coding: a team of AI agents runs the build on its own, while
people keep direction and decisions.

Every team works its own way, and no process can be imported intact. So Astragentic is a scaffold:
the hard parts are settled, and every component is open for you to adapt.

The five parts below are the five largest design decisions in that scaffold: the mechanism, the
evidence on record, and the trade-off. These are my choices on my own projects, not a template you
have to follow.

Codes like `AST-057` are incident numbers from the project's own defect log. Each one is a failure
that was measured, dated and fixed; the [Lessons](/failures) page tells the six worth reading.

## why-astragentic

A coding agent today can carry the build: it takes work, writes code, runs tests, returns results.

What is left for you is not writing code. It is two other things, and they eat the time: answering
the questions an agent raises while it works, and reviewing the quality of what comes back.

Both share one bottleneck. An agent's technical questions usually exceed the expertise of the
person directing it. The common workaround is to take the question to another AI and relay the
answer back. At that point the human is a relay, and the decision has in practice been made by AI.

Astragentic removes that relay with two mechanisms.

### Thomas, the team's representative

Thomas holds the project context and stands between you and the agents:

- **Reads the artifacts** agents return, instead of pushing raw logs at you.
- **Weighs the options** and tech stacks they propose.
- **Answers technical questions** on the spot.
- **Escalates to you** what is yours to decide: product direction, user experience, priorities.

You work as the client of a development unit: set requirements, follow progress, and step in when
the team drifts.

### A team operating in the open

Every agent is a named session with its own pane in herdr, and its work history stays in that
session. You can watch what each agent does. Thomas can trace an incident. The way agents
coordinate becomes data for improving the scaffold itself.

Subagents and agent teams inside a runtime run hidden in the parent process. There is nothing to
look at.

**Trade-off.** One more toolset to install, understand and upgrade, and every upgrade is an event the
project has to absorb. So far I have proven that each tool runs correctly; the whole loop from
dispatch to merge with every gate firing on real work is still being measured.

## why-tracker

The state of the work has to sit outside an agent's context, and you have to be able to open and
read it. An issue tracker is the only place that does both.

The common approach before this was to let the AI slice work into markdown files and track it with
checkboxes. That breaks at both ends: the agent has to remember to go back and edit, and you have
to open a file to read it.

| | Markdown file | Issue tracker |
|---|---|---|
| Updating status | The agent must remember to tick the box | One status field, changed by one command |
| Checking progress | Open the file, read a few hundred lines | Open the board, look at the columns |
| Dependencies | Written into prose | A blocking edge, queryable |
| Two agents taking one job | Nothing stops them | The assignee is a claim, written and read back |
| Machine access | Free-form text editing | Official CLI and MCP |
| Approving or asking for changes | A message somewhere else | A comment on the ticket itself |
| Several people weighing in | Editing one file, stepping on each other | One comment each, attributed and ordered |
| An agent asking back | Nowhere to ask | It asks inside the ticket, anyone can answer, then it carries on |
| When a session closes | State goes with the context | The board is still there |

Those two comment rows are where the way of working changes most. The agent no longer waits for
one specific person: it asks on the ticket, whoever on the team can answer does, and it carries on.
The AI works as a member of the group rather than a tool you have to sit and watch.

**Evidence.** On a real project (`AST-057`), one ticket looked blocked for hours after both of its
blockers had merged, and four tickets wore a ready label while still blocked. The list of work that
can start now, called the frontier, was computed correctly but existed only in the agent's
context. So the contract carries both halves: once
computed, write the answer back to the tracker, and never read a ready label as if it were state.

**Trade-off.** Astragentic inherits the limits of the tracker you use. No tracker has an assignee field
designed to hold `builder/<ticket-id>`. GitHub Issues has no real status field, so status lives in
labels and the Project board column is a copy that has to be kept in sync. And because the tracker
holds state rather than passively recording it, it can drift; `reconcile-tracker` measures the
tracker against git.

## why-not-subagents

Claude Code has subagents and agent teams, and they work well for work inside one session.

They are not enough to coordinate a team. The four things missing share one trait: when something
goes wrong, nothing signals it.

- **A shared checkout.** A subagent runs in the same worktree as its parent session, so several
  agents drag each other's HEAD around. One measurement (`AST-016`) caught a read-only reviewer running `git switch` on
  someone else's checkout.
- **A shared context.** A fork inherits its parent's whole context, including what nobody meant to
  hand over. Once (`AST-006`), a fork inherited the parent's model, so a job meant for a cheap model ran on
  the most expensive one. Another time (`AST-119`), a fork inside a Builder sent the
  end-of-work report, called a handback, to the dispatcher under the Builder's own name, and the
  Builder never saw it. And (`AST-130`) a fork signed a
  `simplify(increment):` marker onto code it had just committed itself, in the permitted form.
- **No tracker holding state.** A subagent's state lives in the parent session's context,
  disappears when the session compacts, and while it exists you cannot read it.
- **No pane to look at.** One measurement (`AST-018`): a dispatch was narrated in words and never actually called. A
  pane in herdr can be counted; an in-process subagent cannot.
- **No AI from another vendor.** A Claude subagent is still Claude, so there is no cross review.

Astragentic still uses forks inside a Builder for report-only work, under one rule: the fork must
have `isolation: "worktree"` and must never message the dispatcher.

**Trade-off.** You have to install herdr and configure a tracker, two dependencies a subagent does not
need. Each Builder costs a worktree on disk and a few seconds of setup. Each dispatch costs one
write and one read on the tracker. The process is longer and there are more names to remember. I
pay that because silent failures cost far more.

## why-mattpocock

Astragentic does not write its own method. The craft is `mattpocock-skills`: `wayfinder`,
`grill-with-docs`, `to-spec`, `to-tickets`, `implement`, `code-review`. Astragentic wraps
coordination around it.

The reason is where the loop sits.

- **This method loops at the start.** `grilling` keeps asking until no open question is left, so
  the spec is settled before any code is written. Every review after that is a bounded pass.
- **The common way loops at the end.** Unsettled decisions go into the code and get settled in
  review. That is the most expensive point, and the number of rounds has no natural stop.

**Evidence.** On the projects I measured, a plan run the second way went through 5 to 14 review
rounds, most of the later ones cleaning up what the earlier ones left behind. The reviewer was not
the cause; decisions settled too late were.

**On Superpowers**, the question usually asked alongside: it is a good system and my team uses it
on other projects. It packs method and coordination into one session, keeps state in a plan file on
the branch, and has nothing equivalent to `to-tickets` producing tickets with blocking edges on the
tracker. Running both in one repo is two coordinators managing the same state, so Astragentic does
not combine them.

**Trade-off.** This is a real dependency. `check-requirements.sh` stops hard without
`mattpocock-skills >= 1.2.3`. Skill names sit directly in the contracts, so changing the method
means rewriting contracts. And Astragentic can only patch the seams, not the plugin: when a defect
sits inside `to-tickets`, the right answer is to have the contract account for it rather than fork
a patch.

## why-cross-vendor

After Claude has written and self-reviewed, a model from another vendor reads the diff. Here that
is OpenAI's Codex.

That second read is called the arm. The mechanism is simple: the arm reads the whole repository
while the author only reads the ticket. So the arm
catches contradictions with the project's own declared standards, which the author can hardly see
while working to the ticket.

- **A defect slipped through the same-vendor round** (`AST-015`): it put a live secret and buyer
  PII into a tracked file. The other vendor's pass caught it and filed it as P1.
- **Two lenses catch two classes of defect** (`AST-012`), so they run side by side rather than
  replace each other.
- **One case on a large diff.** 6,904 added lines across 31 files went through a same-vendor read
  that missed three empty tests. A ticket-scoped read on a smaller diff caught a real deadlock the
  previous round's patch had just created.

**Trade-off.** Friction at call time. Quoting and argv differ between runtimes. `codex exec` has hung
silently before, so it needs a timeout and a dispatcher watching. The most dangerous part is scope:
if `--base` and `HEAD` resolve differently, the companion compares a branch with itself and returns
clean on zero commits. So every read prints its range line before the verdict is trusted.
