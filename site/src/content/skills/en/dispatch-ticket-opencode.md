---
title: dispatch-ticket-opencode
oneLiner: "Launch an OpenCode pane and report which checks of the shared protocol degrade on this runtime."
group: adapter
order: 3
runtimes: [opencode]
source: harness/.agents/skills/dispatch-ticket-opencode/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

`dispatch-ticket-opencode` is the OpenCode half of `dispatch-ticket`. The shared skill owns
binding identity, input resolution, the worktree law, the brief format, submission, watching,
simplify and cleanup. This adapter adds the launcher matrix, the adapter check, and six measured
runtime facts. Only two of the six are conveniences. The other four are limits, and I state them
as limits rather than working around them.
<!-- source: harness/.agents/skills/dispatch-ticket-opencode/SKILL.md -->

The fact that decides this whole page is that **OpenCode's `idle` is fabricated.** `herdr agent
explain` reports `fallback_reason: default_known_agent_idle_fallback`, and `agent wait --until
idle` returned rc=0 in 8 ms on a pane nobody had touched. Its manifest carries three rules
against Claude's twelve and Codex's seven, covering only `blocked` and `working`. So idle is not
detected, it is what is left when no rule matches. The first consequence: the start guard still
works, terminal-state detection does not. The second one costs more: a transcript read here
returns only the input box and the footer, so the shared protocol's two-source background check
collapses to `pgrep` alone. This adapter exists to report that collapse instead of letting it
pass as a normal answer.
<!-- source: harness/.agents/skills/dispatch-ticket-opencode/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A claimed ticket, and `orchestrator.md` says the role runs on OpenCode | `dispatch-ticket` + `dispatch-ticket-opencode` |
| A Builder or Shaper pane | `opencode --agent <role> -m <provider>/<model> --auto` |
| An OpenCode row with a non-blank Effort cell | Stop and ask the owner, because effort is unreachable here |
| A pane that reports `idle` | Read the artifact, because that state carries no rule behind it |
| A worktree about to be removed on a single-source answer | Get the second source another way, or hand back instead of removing |

<!-- source: harness/.agents/skills/dispatch-ticket-opencode/SKILL.md -->

## Prerequisites

- **The role adapter exists in the worktree**: `test -f <worktree-path>/.opencode/agents/<role>.md`.
  Confirm resolution with `opencode debug agent <role>` from the worktree cwd, never with
  `opencode agent list --pure`, which does not list project agents.
- **The pane's cwd is the worktree root or a child of it**, because OpenCode walks the working
  directory upward to find `.opencode/agents/`.
- **The Model value carries its provider prefix.** A bare model name throws
  `ProviderModelNotFoundError`. Where the model is already the default, omit `-m` entirely.
- **The Effort cell for this row is blank**, because effort and orchestration visibility are
  mutually exclusive on OpenCode, and visibility takes priority.

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The launch | `herdr agent start "<role>-<ticket-id>" --kind opencode`, agent detected, process confirmed alive with `pgrep` |
| The permission posture | `--auto` plus the agent's own `permission: { "*": allow }`, which together mean unrestricted |
| A degraded finish check | A reported degradation, worded like a runtime fallback, not a quiet single-source verdict |
| Everything else: brief, watch, verdict, cleanup | The shared `dispatch-ticket` protocol |

<!-- source: harness/.agents/skills/dispatch-ticket-opencode/SKILL.md -->

## Known failures

Pulled from `harness/.agents/memory/recurring-failure-modes.md`. Both are marked `promoted`.

- **AST-032**: a signal that cannot fail is not evidence. OpenCode supplies the purest instance
  in the ledger: a fabricated `idle`, and a dead OpenCode process that still answered
  `interactive_ready: true` for at least one poll interval. The rule this earned is general.
  Detection quality is a per-runtime property that must be checked rather than assumed, and where
  a state has no rule behind it, verify-by-artifact is the only instrument that works.
- **AST-097**: `TERMINAL:done` means the turn ended, not that the work finished, and `pgrep` is
  the source that answered wrong in the field. That matters more here than anywhere, because the
  transcript source that was supposed to corroborate it returns nothing on OpenCode.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- The adapter was verified with `opencode debug agent <role>` from the worktree, not from a
  list command.
- The `-m` value reads `<provider>/<model>`, or `-m` is absent because the model is the default.
- No verdict rests on `idle` alone, and every finish claim points at an artifact.
- A single-source background check was reported as a degradation, in words, at the moment it
  happened.
- No worktree was removed on a single-source answer.

<!-- source: harness/.agents/skills/dispatch-ticket-opencode/SKILL.md -->

## Where it fits

`dispatch-ticket` claims the ticket and builds the worktree, tab and pane →
`dispatch-ticket-opencode` verifies the adapter and launches the runtime → the shared protocol
delivers the brief and arms the watch, and here its verdict is weaker than on the other two
runtimes → the artifact, not the pane, decides whether the ticket is done. The two adapters in
the same group are `dispatch-ticket-claude` and `dispatch-ticket-codex`.
