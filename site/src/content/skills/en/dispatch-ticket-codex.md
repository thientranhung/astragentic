---
title: dispatch-ticket-codex
oneLiner: "Launch a Codex pane from the owner's machine-local profile, after checking it matches the configured row."
group: adapter
order: 2
runtimes: [codex]
source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

`dispatch-ticket-codex` is the Codex half of `dispatch-ticket`. The shared skill owns binding
identity, input resolution, the worktree law, the brief format, submission, watching, simplify
and cleanup. This adapter adds three things and no more: the launcher matrix for Codex rows, the
pre-dispatch profile verification, and the measured facts about how Codex reports its own state.
It is the thinnest of the three runtime adapters, and that is deliberate. For Codex the shared
skill already owns submission and watching; that was verified rather than assumed, during a doc
sweep looking for stale instructions.
<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md, RELEASE-NOTES.md -->

What is different here is where the configuration lives. On Claude the model and effort ride on
the command line; on Codex they do not. The profiles behind `codex --profile <role>` are
**machine-local** files under `${CODEX_HOME:-$HOME/.codex}/`, effort is a TOML field
(`model_reasoning_effort`) because Codex has no `--effort` flag, and `--yolo` has been stale
since v0.147.0 in favour of `--dangerously-bypass-approvals-and-sandbox`. So the pre-dispatch
check is not ceremony: it is the only place the owner's runtime choices and the
`orchestrator.md` row are ever compared.
<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A claimed ticket, and `orchestrator.md` says the agent in this role runs on Codex | `dispatch-ticket` + `dispatch-ticket-codex` |
| A Builder, Shaper or QA pane on Codex | `codex --profile <role> --dangerously-bypass-approvals-and-sandbox` |
| A `rin` row naming Codex | Stop. A Codex root cannot host the gate (`codex-claude-arm`) |
| The profile is missing or has drifted from the template | Hand the owner the exact copy and diff commands; never provision silently |
| A `.codex/agents/*.toml` file that looks like the answer | It is not. That is a spawnable subagent, not a role pane |

<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Prerequisites

- **The machine-local profile exists** at `${CODEX_HOME:-$HOME/.codex}/<role>.config.toml`. The
  harness ships owner-scoped templates at `.codex/profiles/<role>.config.toml`, and those
  templates are the source of truth for a pane launch.
- **The profile matches its template**, or the drift is reported to the owner rather than
  silently repaired.
- **The model and effort in the TOML agree with the `orchestrator.md` row.** Two places, one
  answer, and nothing else compares them.
- **The pane's cwd is the worktree**, per the shared protocol's cwd gate.

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The launch | `herdr agent start "<role>-<ticket-id>" --kind codex`, with the profile flag |
| The role identity, model and effort | The machine-local profile TOML, not the command line |
| A drift finding | A report to the owner, with the copy and diff commands, before any dispatch |
| Everything else, meaning brief, watch, verdict and cleanup | The shared `dispatch-ticket` protocol |

<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Known failures

The ledger names no entry against this skill file. The two below are bound to
`harness/.codex/profiles/*.config.toml`, the templates this skill's pre-dispatch check reads,
and both are marked `promoted`.

- **AST-040**: the package shipped `model = "gpt-5.1-codex"` in all four Codex profiles. It
  resolves on no account, and it failed at neither install, adaptation nor any doctor run,
  because the template and the profile copied from it agreed perfectly. It failed at the first
  cross-vendor call, at end of phase, looking like the provider being down. Fixed: ship no id,
  `model = ""` plus a comment naming where the real one comes from, and a doctor that misses on
  empty.
- **AST-041**: a file called "the owner's" that also ships in the payload has two homes, and the
  shipped one wins. Fixed: the profiles are scaffold, written when absent and never overwritten.
  That is why this skill reports drift instead of correcting it.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- The profile was read from `${CODEX_HOME:-$HOME/.codex}/`, and its absence stopped the dispatch
  rather than triggering a silent copy.
- The `diff -q` against the shipped template ran, and any drift reached the owner in words.
- The launcher carried `--dangerously-bypass-approvals-and-sandbox`, never the retired `--yolo`.
- No effort was passed on the command line, because Codex has no flag for it.
- No Builder was routed through a `.codex/agents/*.toml` subagent, because it shares the parent
  session's topology and gets no worktree allocation.

<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Where it fits

`dispatch-ticket` claims the ticket and builds the worktree, tab and pane → `dispatch-ticket-codex`
verifies the profile and launches the runtime → the shared protocol delivers the brief, arms the
watch and reads the verdict → on a Codex root the cross-vendor pass is `codex-claude-arm`, and
the gate stays on a Claude root. Its counterparts are `dispatch-ticket-claude` and
`dispatch-ticket-opencode`.
