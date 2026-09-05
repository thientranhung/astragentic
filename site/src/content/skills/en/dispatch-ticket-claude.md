---
title: dispatch-ticket-claude
oneLiner: "Launch, brief and watch a Claude Code pane, in the one order that cannot fake a finished turn."
group: adapter
order: 1
runtimes: [claude]
source: harness/.agents/skills/dispatch-ticket-claude/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

`dispatch-ticket-claude` is the Claude Code half of `dispatch-ticket`. The shared skill owns
binding identity, input resolution, the worktree law, the brief format, submission, watching,
simplify and cleanup; this one adds the launcher matrix, the pre-dispatch check, the submission
order and the measured runtime facts for Claude. It is an adapter, not a second protocol — read
`dispatch-ticket` first, and everything not stated here comes from there.
<!-- source: harness/.agents/skills/dispatch-ticket-claude/SKILL.md -->

The spine of the file is four actions in one fixed order: body via `SendMessage`, the bare slash
command typed into the pane, confirm it echoed, then arm the Monitor. Getting them out of order
produces a false terminal state that every downstream check reads as healthy. The source of that
order is two separate defects landing on the same four steps — a peer message is not a user turn,
so the slash command never fired (AST-112); and a body-only `SendMessage` still produces a turn,
so a watch armed too early sees *that* turn end and reports idle on a Builder that has not
started (AST-114). The order is now stated at the point of use rather than left to inference.
<!-- source: harness/.agents/skills/dispatch-ticket-claude/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A claimed ticket, and `orchestrator.md` says the role runs on Claude | `dispatch-ticket` + `dispatch-ticket-claude` |
| The same, on Codex or OpenCode | `dispatch-ticket-codex` / `dispatch-ticket-opencode` |
| A Builder or Shaper — a write role | Launch with `--dangerously-skip-permissions` |
| Rin or QA — a review role | Launch without it; Rin has no fallback row |
| Monitor reported `blocked` | Read the pane, answer via `SendMessage`, arm a **new** Monitor |

<!-- source: harness/.agents/skills/dispatch-ticket-claude/SKILL.md -->

## Prerequisites

- **The role adapter exists in the worktree**: `test -f <worktree-path>/.claude/agents/<role>.md`.
  A miss means the payload was not committed or was gitignored, and it is the exact file
  `claude --agent <role>` will try to load.
- **The `orchestrator.md` row for this role is decided**, with a model and, only where the row
  sets one, an effort. Model and effort come from the row, never from memory.
- **The Builder's session name is discoverable** via `ListAgents`, because `SendMessage`
  addresses a session by name.
- **`herdr-watch-terminal.sh` is what goes inside the Monitor.** Monitor is the delivery
  channel; the script is the watch.

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The brief body | The Builder's session, delivered by `SendMessage` |
| The phase invocation | A real user turn in the pane: one plugin-qualified slash command plus Enter |
| Proof it arrived | The command echoed in the pane, read back before anything else happens |
| The watch | One Monitor per pane, `description: "builder-<ticket-id> status"`, `timeout_ms` and `persistent` both explicit |
| The verdict line | `TERMINAL:done` / `blocked` / `idle`, `TIMEOUT`, or `NO_START`, each naming its pane |

<!-- source: harness/.agents/skills/dispatch-ticket-claude/SKILL.md -->

## Known failures

Pulled from `harness/.agents/memory/recurring-failure-modes.md`. All are marked `promoted`.

- **AST-112**: the skill told Thomas to send the whole brief, slash command included, with one
  `SendMessage`, on the stated ground that it arrives as a user turn. That sentence was false,
  and it shipped for four releases. Fixed: the body travels by `SendMessage`, the command is
  typed.
- **AST-055**: the same defect in the same round produced a loud refusal in the Builder pane and
  a silent substitute in the Shaper pane, because one contract carried "the failure IS the
  finding" and its sibling did not. Both carry it now, and this is why the echo check is
  positive evidence rather than a courtesy.
- **AST-114**: splitting submission into two steps left the watch armed against the wrong one.
  Fixed: arm after the echo, never after the body.
- **AST-107**: a bare `herdr agent wait` inside a Monitor stayed alive and went deaf — measured
  sitting 10m25s against a pane that was already idle while an identical wait in the same minute
  returned in 0s. Fixed: the Monitor wraps the watcher script, which slices the wait and takes
  every verdict from a fresh `herdr agent get`.
- **AST-108**: a Monitor with no `timeout_ms` caps an hour-long watch at five minutes, so the
  bigger the ticket the likelier the watch is already gone. Fixed: both fields explicit in every
  template, and a `Monitor timed out` notification means re-arm, not noise.
- **AST-097**: `TERMINAL:done` means the turn ended, not that the work finished.
- **AST-036**: a worktree carries tracked content only, which is what the adapter check above
  exists to catch.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- The four actions happened in order, and the echo was read before the Monitor was armed.
- Three Builders in flight means three Monitors, one per pane, each with its own description.
- Review roles were launched without `--dangerously-skip-permissions`, and write roles with it.
- Every notification was re-checked with `herdr agent get <pane-id>` before anyone acted on it.
- No `idle` was believed until the start guard had first observed `working` — an empty Claude
  composer matches the idle rule, so an unsent brief reads as a Builder who finished instantly.

<!-- source: harness/.agents/skills/dispatch-ticket-claude/SKILL.md -->

## Where it fits

`dispatch-ticket` claims the ticket and builds the worktree, tab and pane → `dispatch-ticket-claude`
launches the runtime, delivers the brief and arms the watch → the Builder runs its own closed
loop and hands back → the shared skill's `WATCHING.md` and `CLEANUP.md` own what happens on each
verdict line. Its two siblings are `dispatch-ticket-codex` and `dispatch-ticket-opencode`; all
three are adapters under one protocol.
