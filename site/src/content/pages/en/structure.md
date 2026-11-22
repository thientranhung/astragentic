---
title: "Structure"
description: "Four layers: the runtime runs the agents, the harness holds roles and rules, coordination holds state, and at the bottom is your repo. Astragentic sits only in the middle."
harness: v6.1.19
source: "harness/.claude/agents/, harness/.claude/skills/, harness/.claude/settings.json, harness/.agents/roles/, runtimes/codex/"
---

Astragentic is not a runtime, and it is not a method. It sits between the two: below it is Claude
Code (or Codex) running the model, above it is your real repo. What Astragentic writes is the
orchestration and the `astra-*` skills each role uses, and only that.

I split it into four layers because each layer answers a different question, and that question
decides who owns which file. The runtime layer answers "what does this agent run on". The harness
layer answers "what is it allowed to do". The coordination layer answers "where are the agents".
The last layer answers "what is this project", and that is the part Astragentic must never answer
for you.

## runtime

Two runtimes, and each role's model and effort are one line in `.agents/orchestrator.md`, your
file, which an upgrade never overwrites.

- **Claude Code is the reference runtime.** Every role runs here as a custom agent, with hooks,
  skills, subagents and the `astragentic-dispatch` mod. A rule for another runtime is checked
  against the Claude lane before it changes.
- **Codex is the second runtime.** A separate overlay in `runtimes/codex/`: its own roles, 20
  `codex-*` entrypoints, its own host guard and Stop hook. It does not replace the Claude payload.
- **Codex is also the witness.** On the Claude lane, the cross-vendor arm calls a read-only
  `codex exec` so a model from another vendor re-reads the artifact.
- **Junior.** Builder can hand the typing of code to a junior pane on another runtime (Grok first),
  set per project; review, simplify and handback remain Builder's work.

**Trade-off.** One runtime keeps enforcement uniform across all roles, but a junior pane on another
runtime sits outside it. The dispatch mod and `hook-git-guard.py` read Claude's tool names, so the
junior's boundary is its own job, and Builder checks it from the log. Claude itself can also run
with hooks off. So the rule on cleanup order must live in the contract first and in a hook second.
The hook stands behind it; it is not the fence.

## harness

The release brings six roles, 19 skills (one of them the dispatch mod), hooks for six Claude Code events plus one mod, and the
failure ledger into your repo. Roles are not split by title but by session lifetime, because session
lifetime decides what the agent in that role can still remember.

- **Thomas.** The session that runs resident.
- **BA.** Opened by the owner when needed, read-only.
- **Shaper.** Exactly one unbroken session.
- **Builder.** One session per ticket.
- **QA.** One session per walk.
- **Quick Builder.** One session per small task, no ticket.

Each role has two files, and where a rule lives matters more than what it says.
`.claude/agents/<role>.md` is the system prompt and carries only three to five "survives
compaction" rules. `.agents/roles/<role>.md` is the full contract, entering the session through the
Read tool, so it sits in context as a tool result.

This difference decides which rules still hold after a compact: what is in the system prompt
survives, what is outside does not, and the agent has no idea it just lost the rules. This is not an
inattentive agent; it is the context budget working as designed. So that list is kept short, and the
rest is reloaded by the `SessionStart` hook (matcher `compact`) rather than by a reminder.

## coordination

Three things keep many agents running at once without contention: the tracker, the panes of the
terminal host (Herdr or Orca), and git worktrees. What they share is that they sit outside the
agent's context. Anything that exists only in one session's context disappears when that session
compacts, and no one knows it is gone.

- **The tracker holds work state.** Astragentic ships no tracker of its own; it ships adapters for
  GitHub Issues, Jira and Linear, so you keep the board you already use. With state living there,
  "which ticket is ready" is a query, not a memory.
- **The host holds the panes.** Herdr is the default host, Orca runs alongside since 6.1.0, and each
  session uses exactly one host: the other host's commands are refused. Every Builder has a visible
  pane, and this is not cosmetic: I measured a dispatch that was only narrated in words and never
  ran, with no signal to tell the two apart. A pane is something you can count.
- **git worktree holds the write boundary.** One checkout per ticket, and Builder is the only
  writer in it. Another time I measured the opposite: with several agents sharing one checkout, one
  agent's HEAD gets moved by another, and even a read-only reviewer can `git switch` someone else's
  checkout.

**Trade-off.** Three outside dependencies: a tracker to configure, a terminal host to install, and
disk for each worktree.

## project

The bottom layer is your repo, and the rule here is that Astragentic knows nothing about it beyond
what you declare yourself.

- **Tracker.** Which tracker you use is in `docs/agents/issue-tracker.md`.
- **Runtime and model.** Which runtime and which model each role's agent uses is in
  `.agents/orchestrator.md`.
- **Domain vocabulary.** `GLOSSARY.md` holds the shared domain vocabulary.
- **Settled decisions.** ADRs hold the decisions already made.

No release overwrites any of those files.

I learned this boundary where it cost the most: cleaning up a worktree. The harness knows exactly
one thing every worktree allocates, which is the processes whose cwd is inside it. Everything else
belongs to the project: databases, registered ports, containers, brokers, leases on a shared
cluster. The harness cannot name any of those without naming the stack of exactly one project.

The concrete risk: a cleanup step hard-coded to one project's stack reads correctly but frees
nothing on a project using a different stack. Orphaned processes and spare databases then pile up
silently until the machine runs out of resources.

So now the project declares its own cleanup step as a runnable plug at
`.astraler/project/cleanup-worktree.sh`, and `release-worktree-resources.sh` calls it after it has
reaped the processes. A project that allocates nothing beyond git must still write a file that
says exactly that, because a silent no-op cannot be told apart from a successful release.

## good-parts

### The failure ledger: the harness's self-learning mechanism

Each time something breaks, the incident is written as one line in an append-only file with a fixed
code, never renumbered or deleted. When a line yields a rule, that rule goes into a file the agents
actually read, so next time the whole team does it differently. A line that has yielded nothing yet
stays where it is rather than being filtered out.

This is where the harness learns from its own failures: a failure does not vanish with memory, it
becomes a rule or a pending record.

### The cross-vendor arm locks on the exact SHA

After Claude finishes writing, a model from another vendor re-reads the diff and leaves a receipt
bound to the exact SHA it read. The reason is not diversity for its own sake: a model re-reading its
own diff also re-reads its own assumptions, and a model from another vendor does not carry them.

### The tracker is the substrate holding state

Work state is stored on the project's own tracker, not in a plan file on a branch. The difference is
verifiable: a plan file cannot answer "which ticket is ready right now", while a query over blocking
edges and assignees can.

### The claim runs before the worktree is created

The order is: write the assignee on the tracker, read it back, then `git worktree add -b`. That way
two sessions see each other on the tracker itself instead of discovering a collision after both have
written code, with no lock file or central dispatcher needed.

### Review runs exactly one round

Every full ticket passes three tiers exactly once: `astra-review` with three parallel lenses
(correctness, intent, standards), then `simplify` once, then the cross-read by another vendor. The
three tiers have clear edges, so rigor stays the same while the number of rounds does not multiply
by itself. Details are on the [review](/review/) page.
