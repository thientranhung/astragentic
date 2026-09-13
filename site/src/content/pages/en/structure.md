---
title: "Structure"
description: "Four layers: the runtime that runs the agent, the harness holding roles and rules, the coordination that holds state, and your own repo underneath. Astragentic is the middle."
---

Astragentic is not a runtime and it is not a method. It sits between the two: underneath it,
Claude Code or Codex or OpenCode running a model; above it, your real repository; and the method
comes from `mattpocock-skills`. What Astragentic writes itself is the coordination, and only
that.

I split it into four layers because each one answers a different question, and the question
decides who owns which file. The runtime layer answers "what is this agent running on." The
harness layer answers "what is it allowed to do." The coordination layer answers "where is every
agent." The last one answers "what is this project actually," and that is the part Astragentic
must never answer on your behalf.

## runtime

Three runtimes, and which runtime the agent in each role runs on is a row in
`.agents/orchestrator.md`, your own file, never overwritten by an upgrade. Claude Code is the
root runtime: agents in all five roles run here. Codex and OpenCode are optional, and they are
present for specific reasons rather than to make a list longer.

Codex is there to be a witness. The cross-vendor arm needs a model from a different vendor to
read the diff back, so with one runtime that arm does not exist. OpenCode is a third option for
the Builder role when you want it.

**Trade-off.** Standing on three runtimes makes enforcement uneven. `hook-git-guard.py` is registered
on Claude Code through `.claude/settings.json` and on Codex through `.codex/hooks.json`. An
OpenCode Builder has no equivalent hook, and either Claude or Codex may be running with hooks
disabled or untrusted. So the cleanup-ordering rule has to live in the contract first and in the
hook second. The hook comes after, not a fence.

## harness

`install.sh` brings into your repo five roles, sixteen skills, four hooks, and the failure
ledger. Roles are split by session lifetime rather than by seniority, because session lifetime
decides what a role can still remember.

- **Thomas.** Resident.
- **Shaper.** Exactly one unbroken session.
- **Builder.** One session per ticket.
- **Rin.** One session per milestone.
- **QA.** One session per walk.

Each role has two files, and where a rule sits matters more than what it says.
`.claude/agents/<role>.md` is the system prompt and carries four lines. `.agents/roles/<role>.md`
is the full contract, and it enters the session through the Read tool, so it lives in context as
a tool result.

That difference decides which rules survive a compaction: what sits in the system prompt does,
what sits outside it does not, and the agent has no way of knowing it just lost a rule. That is not
an attention failure, it is the context budget behaving exactly as built. So those four lines stay
fixed at four, and the rest is re-armed by a hook rather than by a reminder.

## coordination

Three things keep several agents running at once without a collision: the tracker, herdr's
panes, and git worktrees. What they have in common is that all three sit outside an agent's
context. Anything that exists only in one session's context disappears when that session
compacts, and nobody finds out that it went.

- **The tracker holds work state.** Astragentic ships no tracker of its own; it ships adapters
  for GitHub Issues, Jira and Linear, so you keep the board you already run. State living there
  means "which ticket is ready" is a query rather than a memory.
- **herdr holds the pane.** Each Builder gets a visible pane, and that is not cosmetic: I
  measured a dispatch that was narrated in text and never actually called, with no liveness
  signal to tell the two apart. A pane is something you can count.
- **git worktrees hold the write boundary.** One checkout per ticket, and the Builder is the
  sole writer in it. Another measurement showed the opposite: agents sharing one checkout move HEAD under
  each other, and even a read-only reviewer managed to `git switch` somebody else's checkout.

**Trade-off.** Three external dependencies: a tracker you have to configure, herdr you have to
install, and disk for every worktree.

## project

The bottom layer is your repository, and the rule here is that Astragentic knows nothing about
it beyond what you declare.

- **Tracker.** `docs/agents/issue-tracker.md` names which tracker.
- **Runtime and model.** `.agents/orchestrator.md` names which runtime and model the agent in
  each role runs on.
- **Domain vocabulary.** `CONTEXT.md` holds the shared domain vocabulary.
- **Settled decisions.** The ADRs hold the decisions already settled.

No release overwrites any of them.

The most expensive place I learned this boundary was worktree cleanup. The harness knows exactly
one thing every worktree can allocate: processes rooted in it. Everything else belongs to the
project: a database, a port registration, a container, a broker, a lease on a shared cluster. The
harness cannot name any of those without naming one project's stack.

The concrete risk: a cleanup step hardwired to one project's stack reads as correct on another
one and releases nothing. Orphaned processes and leftover databases then pile up quietly until the
machine runs out of room.

So the project now declares its own release step as an executable plug at
`.astraler/project/cleanup-worktree.sh`, and `release-worktree-resources.sh` calls it after the
reap. A project that allocates nothing beyond git still has to write a file saying so, because a
silent no-op is indistinguishable from a successful release.

## good-parts

### The defect ledger: how the harness learns

Every time something breaks, the incident is written as one line in an append-only file, with a
fixed id, never renumbered and never deleted. A line that yields a rule puts that rule into a file
agents actually read, so the whole team behaves differently next time. A line that yields nothing
yet stays in the table rather than being filtered out.

This is where the harness learns from its own failures: a failure does not fade with memory, it
becomes either a rule or an open record.

### The cross-vendor arm binds to one SHA

After Claude finishes, a model from a different vendor reads the diff back and leaves a receipt
bound to the exact SHA it read. The reason is not variety for its own sake: a model re-reading
its own diff re-reads its own assumptions along with it, and a model from another vendor does
not carry those assumptions.

### The tracker is the state substrate

Work state lives on the project's own tracker, not in a plan file inside a branch. The
difference is checkable: a plan file cannot answer "which ticket is ready right now," and a
query over blocking edges and assignees can.

### The claim runs before the worktree

The order is: write the assignee on the tracker, read it back, and only then `git worktree add
-b`. That is how two sessions see each other on the tracker itself instead of discovering the
collision after both have written code, and it needs no lock file and no central dispatcher.

### Review runs exactly one round

Every ticket passes three layers exactly once: `code-review` on both axes, Standards and Spec;
then the simplify pass; then the cross-vendor read. Three bounded passes keep the rigour without
letting the number of rounds multiply.
