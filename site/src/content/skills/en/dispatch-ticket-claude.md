---
title: dispatch-ticket-claude
oneLiner: "The Claude Code launcher, the dispatch mod's behaviour and the pre-dispatch checks for a dispatched pane."
group: adapter
order: 1
runtimes: [claude]
source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md
rented: false
lang: en
updated: 2026-11-22
harness: v6.1.19
---

## What it does

**`dispatch-ticket-claude` is the Claude Code half of `dispatch-ticket`: the launcher, and the mod that does the steps a dispatcher kept skipping.** The shared protocol (identity, worktree law, brief format, cleanup) lives in `dispatch-ticket`. The `astragentic-dispatch` mod ships in the payload, and every Claude session in the project loads it with no flag and no setup.

The mod replaces these manual steps:

- **Record the pane's tab and pane ids** at session start, from the host's environment (Herdr's tab label, or Orca's `ORCA_*` plus `ASTRA_DISPATCH`, 6.1.0).
- **Deliver the slash command in one SendMessage**: the pane runs the first line as a real command and answers `RECEIVED`.
- **Report `TURN-END`** when a turn ends with none of its agents still running, and wake the dispatcher.
- **Protect a working pane**: closing a tab, pane or terminal that is mid-turn is refused; a command of the other host is refused outright (one host per session).
- **Refuse `ScheduleWakeup`** in a dispatched pane (4.6.1).
- **Show a band** of step chips: Builder implement · tdd · ui · review · simplify · arm; Shaper align · spec · arm:spec · test-design · tickets; QA the role chip only.

**Measurement.** From a turn ending to the dispatcher waking: under one second, against the 67 s gap of polling pane state (AST-097, AST-107).

**Cost.** The mod is a bell, not proof: `TURN-END` says a turn ended. It cannot see a pane whose process died (the workspace watchdog does), and it does not cover a gate pane or a junior pane, which run no mod.
<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md; harness/.claude/skills/astragentic-dispatch/hooks/register.tsx -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A claimed ticket, role runs on Claude | `dispatch-ticket` plus `dispatch-ticket-claude` |
| A QA gate pane or a junior pane | The watcher script in `dispatch-ticket`; a junior pane adds `dispatch-junior` |
| A write role (Builder, Shaper) | Launch with `--dangerously-skip-permissions --allowedTools Grep,Glob` |
| QA | Launch without `--dangerously-skip-permissions`: a gate runs under permissions |
| A ticket labelled `quick` | The `builder-quick` launcher row |

<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## Prerequisites

- **Claude Code 2.1.294 or later.** `check-requirements.sh` refuses older versions; below the floor the mod does not load.
- **The tab label is set before launch**: the mod reads `ticket:`, `spec:`, `qa:` from the tab at session start.
- **The mod is committed on the branch** the worktree checks out.
- **Two files exist in the worktree**: `.claude/agents/<role>.md` and `.claude/skills/astragentic-dispatch/hooks/register.tsx`.

After launch, read the record back: `.astraler/state/dispatch-record.json` must carry the ticket's key with a `pane_id` equal to the pane just created. If not, a precondition failed; stop, because a pane the mod does not know about is unwatched.
<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## The launcher, by role

Each row is the argv after `--`; `herdr agent start --kind claude` supplies the `claude` executable itself.

| Role | Flags |
|---|---|
| builder, shaper | `--dangerously-skip-permissions --allowedTools Grep,Glob --agent <role> --model <Model> --autocompact 300000` |
| qa | `--agent qa --model <Model> --autocompact 300000` |
| builder, ticket `quick` | the `builder-quick` row if `orchestrator.md` has one, else the `builder` row |

`--effort` and `--advisor` are added only when the role's row sets a value. Model and effort come from `orchestrator.md`, never from memory.

- **`--allowedTools Grep,Glob` travels with `--dangerously-skip-permissions`.** The bypass flag alone drops the `Grep` and `Glob` tools from the pane (Claude Code 2.1.318, measured 2026-11-04).
- **`--autocompact 300000` is the context ceiling, and it is not optional.** The engine's window is 1M and a pane runs its whole flow in one context. One project's Builders ran a median 400–550k tokens of context per call. The mod also compacts a pane that ends a turn over the ceiling (`ASTRAGENTIC_CONTEXT_CEILING` changes it).
- **Pasting `claude` in front of a row** launches `claude claude --agent …`; the mod refuses that launch.

<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## The brief and what comes back

The brief goes in one `SendMessage` to the session name from `ListAgents`; its first line is the slash command. Do not arm a Monitor, type into the pane or write tab and pane ids by hand: each is a second copy of what the mod does.

- **`RECEIVED`** is consumed silently. Absent for 90 s, the line turns red.
- **`TURN-END`** arrives as a prompt with the pane's last words and `Skills run:`. Read that line before trusting the handback.
- **A turn that ends while the pane's own sub-agents still run is held**; the ceiling is 20 minutes, then a `reason=held-stale` bell and a red row.
- **`reason=command-failed`**: the pane refused the first line, usually an unknown command name.
- **A QA pane's TURN-END always arrives from the record** within 30 s, because it runs under permissions (measured 2026-10-27: 6 of 6).
- **`/dispatch-board`** opens a list of every live dispatch.
- **`AskUserQuestion` is refused** in a dispatched pane.

<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## Steps that are refused, not noted

| What is blocked | Until |
|---|---|
| The Builder's first content commit | A test file is staged and a test run has gone RED after the brief (4.5.2) |
| The arm (`codex-arm`) | The built-in `code-review` is in the record |
| A Builder brief with no `QA plan:` | A committed `docs/qa/plan-<slug>.md` exists |
| A Shaper brief with no `UX:` | The PRD is committed on the base with a `### UJ-n` heading per id (5.0.9) |
| A brief for a ticket the tracker reports unclaimed | The ticket is claimed |
| Every brief, while a merge has no ticket-done stamp | `scripts/ticket-done.sh <id>` runs |
| Every brief, while the payload is edited but uncommitted | Commit, or an `Uncommitted-payload: <why>` line |
| A Bash wait keyed on a process name (`until ! pgrep -f …`) or a loop with no sleep | Use `cmd & pid=$!; while kill -0 $pid …; wait $pid` |

The exemption belongs to the dispatcher and travels in the brief: `TDD: n/a`, `REVIEW: n/a`, `SIMPLIFY: n/a`, `UX: n/a`, each with a reason. A ticket labelled `quick` is exempt from tdd, `astra-review`, simplify and the ui pass as a whole; the built-in review stays owed at the arm and at merge. The mod reads exemptions from the brief it delivers, never from the handback.

A project adds refusals in `.astraler/project/refused-in-dispatched-panes`: one regex per line, and a `# reason:` line directly above is the refusal's text.
<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## Cleanup and overlays

`git worktree remove <path>` on a recorded worktree runs `release-worktree-resources.sh <path>` first: it reaps processes rooted there, runs the project's teardown plug and stamps the path. The path must be literal; one with `$`, a backtick or `~` is refused. The record entry goes once the worktree and the tab are both gone.

`.astraler/project/overlays/` belongs to the project and no release writes into it: `overlays/<role>.md` is appended to that role's system prompt on every render, `overlays/thomas.md` does the same in the dispatcher's session, and `overlays/dispatch-brief.md` is appended to every brief. An overlay adds to the contract and never overrides it; a rule that must refuse belongs in a plug script, because prose instructs and only a hook stops.
<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## It's working if

- The record read back carries a `pane_id` that matches the pane just created.
- The launch has no stray `claude` and includes `--autocompact 300000`.
- `TURN-END` carries `Skills run:` and a merge names no missing step.
- Every refused gate leaves a trace in the entry's `refusals` and in `~/.local/state/astragentic/harness-hook-events.log`.
- A QA pane runs without `--dangerously-skip-permissions`.

<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## Where it fits

`dispatch-ticket` (shared protocol) → **`dispatch-ticket-claude`** (launcher, mod, pre-checks) → Builder pane → `TURN-END`. The mod is the `astragentic-dispatch` plugin, which has its own page. Gate and junior panes sit outside the mod.
