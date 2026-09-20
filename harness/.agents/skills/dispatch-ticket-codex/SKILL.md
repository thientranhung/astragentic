---
name: dispatch-ticket-codex
description: "Codex-specific launcher and verification for dispatch-ticket. Covers the launcher matrix, the in-repo role instruction files, project-local custom agents and hooks, herdr agent start template, and Codex-specific runtime facts. Read dispatch-ticket for the shared protocol."
---

# Dispatch a ticket — Codex runtime

**Read `dispatch-ticket` for the shared protocol** (binding identity, inputs/resolution,
worktree law, brief format, submission, watching, simplify, cleanup). This skill adds only
the Codex-specific launcher and verification.

## Launcher matrix — Codex rows

```text
<role> → codex -m <model> -c model_reasoning_effort="<effort>" \
           -c developer_instructions="$(cat .codex/profiles/<role>.md)" \
           --dangerously-bypass-approvals-and-sandbox
```

`<role>` is `builder`, `shaper`, `qa` or `thomas`. **`<model>` and `<effort>` come from that
role's codex row in `.agents/orchestrator.md`** — the row is the only home for both. A row
still reading `<set-me>` is not a value: STOP and ask the owner.

**Everything the pane needs travels on this one command line.** There is no per-machine file
to provision, nothing to copy into `$CODEX_HOME`, and nothing to keep in sync afterwards.

**`--profile` is not the mechanism and never was.** `codex --help` states what it does: *layer
`$CODEX_HOME/<name>.config.toml` on top of the base user config*. A repo's `.codex/profiles/`
is never read by it, and `$CODEX_HOME` is one namespace shared by every project on the machine
— two repos adapting this harness would both want `builder`, and the second silently wins.

**`--yolo` is stale since v0.147.0** — the flag is now `--dangerously-bypass-approvals-and-sandbox`.
Codex has no `--effort` flag; effort is the config key above.

## Pre-dispatch verification

The role instruction file is `.codex/profiles/<role>.md`, in the repository, tracked in git.
It **is** the pane's system prompt: whatever is in it is said to the agent, so it carries
instructions only — no commentary about itself, no model, no effort.

Three facts make "it launched" worthless as evidence, all measured on codex-cli 0.155.1:

- An unrecognised `-c` key is **accepted in silence**, exit 0. A typo in
  `developer_instructions` costs you a Builder with no contract and no error.
- `-c` parses its value as TOML **first**, and only falls back to the literal string when that
  fails. Prose survives verbatim — headings, `$`, backticks, quotes, markdown links. A file
  that is one quoted line loses its quotes; a file containing only `true` is rejected with
  *invalid type: boolean, expected a string*.
- `model_reasoning_effort` is recognised, and a wrong value fails at the API with HTTP 400 —
  at first call, not at launch.

So verify against the launcher's own parser rather than by reading. `codex debug prompt-input`
renders the model-visible prompt without spending a model call:

```bash
ROLE=builder
PROFILE=".codex/profiles/${ROLE}.md"
test -s "$PROFILE" || { echo "STOP: $PROFILE is missing or empty"; exit 1; }

codex debug prompt-input -c developer_instructions="$(cat "$PROFILE")" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)[0]["content"][0]["text"])' \
  | diff -q - "$PROFILE" \
  || { echo "STOP: the pane would not receive $PROFILE verbatim"; exit 1; }
```

What this proves is **delivery, and only delivery**: the pane receives those bytes. It cannot
tell you the bytes are right. A file that still describes a mechanism the CLI stopped
performing passes this check and is read by the agent as instruction —
`scripts/check-requirements.sh` carries that half.

Do not confuse the instruction file with `.codex/agents/*.toml`. Those are project-local
**custom subagent types** that a running Codex session may spawn. They do not launch a pane,
do not allocate a branch or worktree, and do not replace a visible Herdr role pane. Astragentic
ships only read-only-intent helpers there; lifecycle roles still use the launcher above.

`sandbox_mode = "read-only"` in a custom-agent file is a requested default, not Astragentic's
isolation boundary. Codex reapplies a parent's live permission overrides to children, so a
parent launched with bypass can weaken that default. The instructions still forbid writes,
but worktree/branch allocation and a visible Herdr pane remain the only accepted boundary for
write-heavy role work.

## Launch

```bash
herdr agent start "<role>-<ticket-id>" --kind codex --pane <pane-id> --timeout 60000 \
  -- -m <model> -c model_reasoning_effort="<effort>" \
     -c developer_instructions="$(cat .codex/profiles/<role>.md)" \
     --dangerously-bypass-approvals-and-sandbox
```

The `$(cat …)` expands in the dispatching shell, so the file's `$`, backticks and quotes reach
the pane unchanged — measured downstream on a live herdr pane, where the launched Builder
quoted back a line containing both.

## Measured runtime facts

**Codex detection quality.** Codex's top rules are `osc_title` (1100, 1050) — the agent's
own title, which beats scraping. `working` and `blocked` are OBSERVED. `idle` is rule-backed
via `osc_title`, making it the most reliable of the three runtimes for terminal-state
detection. Still verify by artifact.

**Three Codex configuration surfaces have three different jobs.** `AGENTS.md` carries project
instructions, `.codex/agents/*.toml` defines spawnable custom subagents, and `.codex/hooks.json`
registers project-local lifecycle hooks. The pane's role identity is none of those: it arrives
as `developer_instructions` on the launch command line. Never route a Builder through a custom
subagent merely because both surfaces use TOML — the custom subagent shares the parent session
topology and has no Astragentic worktree allocation.
