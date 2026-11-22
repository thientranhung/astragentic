---
source: "harness/.claude/skills/, harness/.claude/skills/codex-arm/, harness/.agents/roles/, RELEASE-NOTES.md 5.0.0, 6.1.18, 6.1.19"
title: "Approach"
description: "The approach behind Astragentic: the orchestrator-agent model, an issue tracker that holds state, why orchestration does not belong in subagents, cross-review between two AI vendors, and a self-repairing scaffold."
---

Astragentic aims at autonomous coding: a team of AI agents runs the building, while humans keep
direction and decisions.

Every team has its own way of working, and no process imports intact. So Astragentic is a
scaffold: a frame that has already solved the hard parts, with every component in it open for you
to customize.

The six parts below are the six biggest design decisions of the scaffold: the mechanism, the
measured evidence, and the trade-off. These are my choices on my project, not a mandatory template.

## why-astragentic

Coding agents today are capable of taking over the building: receive the work, write code, run
tests, return the result.

What is left for you is not writing code. It is two other things, and they consume all the time:
answering the questions the agent raises while working, and reviewing the quality of what comes
back.

Both share one bottleneck. The agent's technical questions often exceed the operator's expertise.
The common workaround is to carry the question to another AI and carry the answer back. The human
is then only a relay, and the decision has in practice been made by the AI.

Astragentic removes that relay with two mechanisms.

### Thomas, the team's representative

Thomas holds the project context and stands between you and the agents:

- **Reads the artifacts** the agents return, instead of pushing raw logs on to you.
- **Evaluates options** and the proposed tech stack.
- **Answers technical questions** on the spot.
- **Escalates to you** what belongs to your authority: product direction, user experience,
  priorities.

You work as the client of a development shop: set requirements, follow progress, and step in when
you see the team drift.

### A team that operates in the open

Each agent is a named session with its own pane in herdr, and its work history stays in that
session. You can observe what each agent does. Thomas can trace back when something goes wrong. How
the agents coordinate becomes data you can use to improve the scaffold itself.

Subagents and agent teams inside a runtime run hidden in the parent process. There is nothing to
look at.

**Trade-off.** One more toolset to install, understand and upgrade, and every upgrade is an event
the project has to absorb. So far I have only proven that each tool runs correctly; the whole loop
from dispatch to merge with every gate on real work is still being measured.

## why-tracker

Work state needs to live outside the agent's context, and be readable the moment you open it. An
issue tracker is the only place that satisfies both.

The common approach before this was to have the AI cut work into markdown files and track it with
checkboxes. It fails at both ends: the agent has to remember to come back and edit, and you have to
open the file to read.

| | Markdown file | Issue tracker |
|---|---|---|
| Updating state | The agent must remember to come back and edit a checkbox | One status field, changed with one command |
| Viewing progress | Open the file, read a few hundred lines | Open the board, look at the columns |
| Dependencies between work | Buried in wording | A blocking edge, queryable |
| Two agents take the same work | Nothing stops it | The assignee acts as the claim, written and readable back |
| Machine operation | Free-form text edits | Official CLI and MCP |
| Approve or request changes | A message somewhere else | A comment right on the ticket |
| Several people give input | Edit one shared file, contend with each other | One comment each, named and ordered |
| The agent asks back | No place to ask | Ask right in the ticket, anyone can answer, then the agent continues |
| When the session closes | State is lost with the context | The board stays intact |

The two rows about comments are where the way of working changes most visibly. The agent no longer
waits for exactly one person: it asks on the ticket, whoever on the team can answer does, and it
carries on. The AI works like a member of the team rather than a tool you have to sit and watch.

One easily missed detail: the list of work that can be done now, called the frontier, must be
written down. If it is only computed in the agent's context, you do not see it when you open the
board, and a ticket whose blockers are all done still looks blocked. So the contract carries both
halves: once computed, write the answer back to the tracker, and never read the readiness label as
if it were state.

**Trade-off.** Astragentic inherits the limits of the tracker you use. No tracker has an assignee
field designed to hold `builder/<ticket-id>`. GitHub Issues has no real status field, so status
lives in labels and the Project board column is only a copy that must be kept in sync. And because
the tracker holds state rather than being a passive record, it can drift from reality;
`reconcile-tracker` measures the tracker against git.

## why-not-subagents

Claude Code has subagents and agent teams. Both work well inside one session, and Astragentic still
uses them: Builder spawns subagents for reading and reporting, and Thomas uses both when it needs to
survey or plan.

The common question is: with those two already there, why one more orchestrator.

The boundary is scope. Subagents and agent teams coordinate work **inside one session**. What a
team needs is coordination **across many sessions**, with each session observable one by one. For
the way of working I want, seeing what an agent is doing, where it is wrong, when it drifted, a
process running hidden is not enough.

When orchestration is put inside a subagent, the four things below are missing, and they are
missing in the same way: when something goes wrong, no signal is raised.

- **A shared checkout.** A subagent runs in the same worktree as its parent session, so several
  agents pull each other's HEAD around. I caught a read-only reviewer doing `git switch` on
  someone else's checkout.
- **Shared context.** A fork inherits the parent's whole context, including what no one meant to
  hand over. Once a fork inherited the parent's model, so work that should have run on a cheap model
  ran on the most expensive one. Another time, a fork inside a Builder sent the end-of-work report,
  called a handback, to the dispatcher below under the Builder's own name, and the Builder never saw
  it. And one fork signed a `simplify(increment):` marker on code it had just committed itself, in
  exactly the permitted form.
- **No tracker holding state.** A subagent's state lives in the parent session's context, is lost
  when the session compacts, and while it exists you cannot read it.
- **No pane to look at.** Once a dispatch was only narrated in words and never actually invoked. A
  pane in Herdr or Orca is something you can count; a subagent inside a process is not.

And one more thing: Claude's subagents are still Claude, so there is no cross-review from another
vendor.

So Astragentic lets subagents do exactly their job, inside one session, with one rule: a fork must
have `isolation: "worktree"` and must not message the dispatcher.

**Trade-off.** You have to install a terminal host (Herdr or Orca) and configure a tracker, two
dependencies a subagent does not need. Each Builder costs a worktree on disk and a few seconds of
setup. Each dispatch costs one write and one read on the tracker. The process is longer, with more
names to remember. I chose to pay that price because a silent failure costs far more.

## why-astra-skills

The development method belongs to the harness itself: seven `astra-*` skills, each tied to exactly
the role and the phase that uses it. Since 5.0.0, the payload names no outside method plugin.

| skill | role | phase |
|---|---|---|
| `astra-ux` | Thomas, with the owner | journey and actor, before the spec |
| `astra-grill-with-docs` | Shaper | ask until no branch is left open |
| `astra-to-spec` | Shaper | spec onto the tracker |
| `astra-to-tickets` | Shaper | tracer-bullet tickets, with prerequisite edges |
| `astra-implement-with-tdd` | Builder | red test first, code after |
| `astra-ui` | Builder, QA | check the surface against the design spine |
| `astra-review` | Builder | three lenses, one triage pass |

The reason lies in where the loop is placed.

- **Loop at the start.** `astra-grill-with-docs` asks until no open question remains: the agent
  goes to find facts, the owner makes decisions, every answer carries its source. The spec is
  settled before code is written, so every review after that is a bounded pass.
- **No loop at the end.** A decision left unsettled and carried into code can only be settled at
  review, the most expensive stage, and the number of review rounds has no natural stopping point.

Why write them instead of installing an existing skill set: the harness's mod and gates read skill
names directly. A Builder brief is recognised by its skill name (4 regexes in the mod), and the TDD
gate reads skill names from the record. When those names belong to an outside plugin, one rename
upstream makes the gate wrong with no error reported. Two open sources, Matt Pocock's skill set and
the BMAD Method (both MIT), were distilled into the repo as reference material and are not installed
into projects: the first is concise but has no actors or states, the second has the right
philosophy but is verbose.

**Measurement.** The skills loaded into a full Builder pane went from 18.2k to 14.5k bytes, because
the Builder accounts for 95% of a project's tokens.

**Trade-off.** The harness keeps the method itself, so it pays the cost of maintaining it. Each
skill has a size limit and each change goes through the selftest like any other rule.

## why-cross-vendor

After Claude finishes writing and reviews itself, a model from another vendor re-reads the diff.
Here that is OpenAI's Codex.

That re-read is called the arm, and it is cross-review, not debate: the two models do not argue to
persuade anyone, each reads and concludes independently, and both conclusions are kept.

The mechanism is simple: the arm reads the whole repository, while the author reads only the
ticket. So the arm catches contradictions with the project's own declared standards, which the code
author struggles to notice because they are following the ticket's requirements.

- **A defect that slipped past the same-vendor round**: it brought a live secret and a buyer's PII
  into a tracked file. The other vendor's read caught it and ranked it P1.
- **Two lenses catch two different kinds of defect**, so they run in parallel rather than
  replacing each other.
- **One case on a large diff.** 6,904 added lines across 31 files passed a same-vendor read that
  missed three empty tests. A ticket-scope read on a smaller diff caught a real deadlock that the
  previous pass's patch had just created.

Since 6.1.18, the arm is a single read-only `codex exec` call made directly, with no plugin:
gpt-6.2-astra at medium effort, the edge lens at ticket and slice, the adversarial lens at spec.
Details and measurements are on the [review](/review/) page.

**Measurement.** Measured blind on 7 replayed tickets: the Codex edge lens finds 21 real defects
per run, precision 0.77. Of 34 real defects, the Codex runs together found 29 and the Claude runs
found 17.

**Trade-off.** The arm depends on the other vendor's quota. When quota runs out, the arm writes
`NOT RUN` with the reason, never counted as a pass, and the ticket falls back to Claude's
adversarial lens on Opus. The most dangerous thing is still scope: an empty range stops the command
before it runs, and every read prints the range line before the verdict is trusted.

## why-self-repair

An incident that is not recorded comes back. That is not a remark about agents; it is a remark about
every system without a memory that outlives the working session.

For a team of agents this is sharper than for a human team at exactly one point: when the session
ends, the context is gone. A Builder that has just made a mistake and understood why it was wrong
will not carry that understanding into the next ticket, because there is no "it" that carries on. A
person at least remembers vaguely.

The mechanism is a ledger, and a path from the ledger into the contract.

**The ledger.** Each incident is one line in an append-only file with a fixed code: `AST-136` is
still `AST-136` after a hundred more entries. Never renumbered, never deleted, even after the bug
has been fixed. Old entries move to an archive file instead of being deleted; the open ledger
currently holds {{meta.total}} entries.

**The path.** A line that yields a rule does not leave that rule sitting in the ledger. It is
written into a file the agent actually reads: a role's contract, a skill, or a hook. The ledger is
the evidence; the contract is where the evidence takes effect.

**The loop closes at merge**, not at the end of a sprint and not when someone remembers. The merge
commit carries a `Ledger:` line saying what was just written to the ledger. `Ledger: none` is valid;
omitting the line entirely is not: "this round taught nothing" is a conclusion, while no line at all
is a skipped step, and from outside the two look identical unless declaring is mandatory.

**No build step, and nobody has to reload.** Each role's system prompt is only a few lines, and one
of them is the command to read its own contract. The next session that opens already carries the new
rule. A hook handles the rest: after a session is compacted, the contract is reloaded, because what
sits outside the system prompt is what compaction summarizes away first.

**An entry goes into the ledger only after it has happened more than once.** `AST-136` was written
after three occurrences of the same mistake in three different shells: one wrong escape that made a
script report STOP for the wrong reason, one read of 23 markers as 193, one that made a marker that
really existed report as never written. Those three were many releases apart, and could be seen only
because all three were in the ledger.

**Trade-off.** The ledger grows and never shrinks. It is not something to read from start to finish,
but something to look up when a rule in a contract makes you wonder *why this rule exists*. And every
rule added to a contract is tokens paid at every session of that role, so a rule must prove it
blocks a failure that **has happened**, not one that could happen.
