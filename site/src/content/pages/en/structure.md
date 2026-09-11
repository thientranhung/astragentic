---
title: "Structure"
description: "Four layers: a runtime that runs the agent, a harness that holds the roles and the rules, a coordination layer that holds the state, and your repo underneath. Astragentic is only the middle."
---

Astragentic is not a runtime and it is not a method. It sits between the two: underneath it,
Claude Code or Codex or OpenCode running a model; above it, your real repository; and the method
is rented from `mattpocock-skills`. What Astragentic writes itself is the coordination, and only
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

**Evidence.** I measured this on one long session that compacted once: the four lines in the
system prompt were obeyed all session, every rule outside it was violated, and none of the
violations was noticed until the owner asked. The correlation was total. That is not an attention
failure, it is the context budget behaving exactly as built. So those four lines stay fixed at
four, and the rest is re-armed by a hook rather than by a reminder.

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

**Evidence.** For four releases it did exactly that: a compose label and a broker process
hardwired at five separate call sites. A project on a different stack read "cleanup exists" and
released nothing. Measured downstream in one night: 43 orphaned processes, 3,405 leftover
databases taking 25 GB, load average 123, one Builder killed by the OS.

So the project now declares its own release step as an executable plug at
`.astraler/project/cleanup-worktree.sh`, and `release-worktree-resources.sh` calls it after the
reap. A project that allocates nothing beyond git still has to write a file saying so, because a
silent no-op is indistinguishable from a successful release.

## good-parts

### An append-only failure ledger

Every time something breaks I write a line into an append-only file, each one numbered
`AST-<n>`, never renumbered and never deleted. There are {{meta.total}} lines today, and
{{meta.cited}} of them are bound to a file that makes someone act differently now. The rest stay
in the table rather than being filtered out.

### The cross-vendor arm binds to one SHA

After Claude finishes, a model from a different vendor reads the diff back and leaves a receipt
bound to the exact SHA it read. This is not variety for its own sake: a same-vendor correctness
review once passed a defect that committed live secrets and buyer PII into a tracked file, and
the cross-vendor pass is what caught it as a P1.

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
then the simplify pass; then the cross-vendor arm. The prior system measured 5 to 14 review
rounds per ticket, with most of the later ones clearing up what the earlier ones left behind. I
removed the loop and kept the weight.
