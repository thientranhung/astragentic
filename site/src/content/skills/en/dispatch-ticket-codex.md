---
title: dispatch-ticket-codex
oneLiner: "Launch a Codex pane with the role's identity on the command line, verified against the launcher's own parser."
group: adapter
order: 2
runtimes: [codex]
source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

`dispatch-ticket-codex` is the Codex half of `dispatch-ticket`. The shared skill owns:

- **Binding identity and input resolution.**
- **The worktree law.**
- **The brief format, submission and watching.**
- **Simplify and cleanup.**

This adapter adds three things and no more: the launcher matrix for Codex rows, the pre-dispatch
profile verification, and the measured facts about how Codex reports its own state. It is the
thinnest of the three runtime adapters, and that is deliberate. For Codex the shared skill already
owns submission and watching; that was verified rather than assumed, during a doc sweep looking
for stale instructions.
<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md, RELEASE-NOTES.md -->

Model and effort ride on the command line for Codex now, the same as Claude. What travels
differently is the role identity: it arrives as a `-c developer_instructions=...` value built
from `.codex/profiles/<role>.md`, a plain-text file tracked in the repository — not a
machine-local TOML under `$CODEX_HOME`.

- **`.codex/profiles/<role>.md` is the pane's system prompt.** Plain text, in the repository,
  tracked in git. It carries instructions only — no model, no effort, no commentary about
  itself.
- **Model and effort have exactly one home**: the role's codex row in `.agents/orchestrator.md`.
  Nothing else can disagree with the table.
- **`--profile` was never the mechanism.** `codex --help` states it layers
  `$CODEX_HOME/<name>.config.toml` on top of the base config — a namespace shared by every
  project on the machine. A repo's `.codex/profiles/` was never read by it.
- **`--yolo` has been stale since v0.147.0**, in favour of
  `--dangerously-bypass-approvals-and-sandbox`.

So the pre-dispatch check is not ceremony: it asks the launcher's own parser to render the
prompt and diffs it against the role file. That proves delivery, and only delivery — never
correctness.
<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A claimed ticket, and `orchestrator.md` says the agent in this role runs on Codex | `dispatch-ticket` + `dispatch-ticket-codex` |
| A Builder, Shaper or QA pane on Codex | `codex -m <model> -c model_reasoning_effort="<effort>" -c developer_instructions="$(cat .codex/profiles/<role>.md)" --dangerously-bypass-approvals-and-sandbox` |
| A `rin` row naming Codex | Stop. A Codex root cannot host the gate (`codex-claude-arm`) |
| `.codex/profiles/<role>.md` is missing, empty, or fails the prompt-input diff | Stop before dispatch; an unrecognised `-c` key is accepted in silence, exit 0 |
| A `.codex/agents/*.toml` file that looks like the answer | It is not. That is a spawnable subagent, not a role pane |

<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Prerequisites

- **`.codex/profiles/<role>.md` exists and is non-empty.** It is the pane's system prompt,
  tracked in git — there is no per-machine copy step to fall back on.
- **Model and effort come only from the role's codex row in `.agents/orchestrator.md`.** A row
  still reading `<set-me>` is not a value: stop and ask the owner.
- **`codex debug prompt-input` was run against the role file**, and its rendered text diffed
  byte-for-byte against `.codex/profiles/<role>.md`.
- **The pane's cwd is the worktree**, per the shared protocol's cwd gate.

**The launch is two steps, and both are load-bearing.** `herdr agent start … -- <args>`, the form
the shared protocol asks for everywhere else, refuses this launch outright — measured on herdr
0.9.1, it returns `invalid_agent_argument: agent arguments cannot be encoded safely for the
target shell`. The cause is the newlines inside the role identity, not its length: the same
call with a single-line `-c developer_instructions` value gets past encoding and only then fails
on the pane id. Every role file is multi-line, so `agent start` refuses every real dispatch.
`herdr pane run <pane-id>` takes the whole command as one shell string instead, and does not.
`pane run` alone is only half the job: it leaves the pane with no registered agent name, invisible
to the watchdog that counts dispatched agents, so `herdr agent rename <pane-id>
"<role>-<ticket-id-lowercased>"` has to follow it. The name must start with a lowercase letter —
a project with uppercase ticket ids fails at that last step, with the agent already up and
unregistered.
<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The launch | Two steps: `herdr pane run <pane-id>` with the full `-m`/`-c`/`-c` command line, then `herdr agent rename <pane-id> "<role>-<ticket-id-lowercased>"` |
| The role identity | `.codex/profiles/<role>.md`, in the repository |
| The model and effort | The role's codex row in `.agents/orchestrator.md`, and nowhere else |
| A delivery check | `codex debug prompt-input` output diffed against the role file, before any dispatch |
| Everything else, meaning brief, watch, verdict and cleanup | The shared `dispatch-ticket` protocol |

<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Known failures

The ledger names no entry against this skill file. The two below are bound to the retired
`harness/.codex/profiles/*.config.toml` mechanism — the machine-local templates a launch used
to read before the launcher moved to a plain command line — and both are marked `promoted`.

- **A profile shipped with a matching model id.** The package shipped `model = "gpt-5.1-codex"` in all four Codex profiles. It
  resolves on no account, and it failed at neither install, adaptation nor any doctor run,
  because the template and the profile copied from it agreed perfectly. It failed at the first
  cross-vendor call, at end of phase, looking like the provider being down. Fixed at the time:
  ship no id, `model = ""` plus a comment naming where the real one comes from, and a doctor that
  misses on empty. The class of failure is now closed a different way: model and effort have
  exactly one home, the role's codex row in `.agents/orchestrator.md`, so no file can ship a
  competing value.
- **A scaffold file got overwritten.** A file called "the owner's" that also shipped in the
  payload had two homes, and the shipped one won. Fixed at the time: the profiles were scaffold,
  written when absent and never overwritten, and the skill reported drift instead of correcting
  it. That class of failure is also closed now: `.codex/profiles/<role>.md` lives in the
  repository under git, not under a scaffolded machine-local path, so there is no second home
  left to drift against.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- The role file was read from `.codex/profiles/<role>.md` in the repository, and its absence or
  emptiness stopped the dispatch before launch.
- `codex debug prompt-input` rendered the file back byte-for-byte; a mismatch stopped the
  dispatch rather than launching on faith.
- Model and effort came only from the role's codex row in `.agents/orchestrator.md`, never from
  a file the role file itself might disagree with.
- The launcher carried `--dangerously-bypass-approvals-and-sandbox`, never the retired `--yolo`.
- No Builder was routed through a `.codex/agents/*.toml` subagent, because it shares the parent
  session's topology and gets no worktree allocation.

<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Where it fits

`dispatch-ticket` claims the ticket and builds the worktree, tab and pane → `dispatch-ticket-codex`
verifies the role file's delivery and launches the runtime → the shared protocol delivers the
brief, arms the watch and reads the verdict → on a Codex root the cross-vendor pass is
`codex-claude-arm`, and the gate stays on a Claude root. Its counterparts are
`dispatch-ticket-claude` and `dispatch-ticket-opencode`.
