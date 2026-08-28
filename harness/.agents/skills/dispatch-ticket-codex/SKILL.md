---
name: dispatch-ticket-codex
description: "Codex-specific launcher and verification for dispatch-ticket. Covers the launcher matrix, machine-local launch profiles, project-local custom agents and hooks, herdr agent start template, and Codex-specific runtime facts. Read dispatch-ticket for the shared protocol."
---

# Dispatch a ticket — Codex runtime

**Read `dispatch-ticket` for the shared protocol** (binding identity, inputs/resolution,
worktree law, brief format, submission, watching, simplify, cleanup). This skill adds only
the Codex-specific launcher and verification.

## Launcher matrix — Codex rows

```text
builder  → codex --profile builder --dangerously-bypass-approvals-and-sandbox
shaper   → codex --profile shaper --dangerously-bypass-approvals-and-sandbox
qa       → codex --profile qa --dangerously-bypass-approvals-and-sandbox
```

Model comes from the machine profile TOML (`model` field). **`--yolo` is stale since
v0.147.0** — the flag is now `--dangerously-bypass-approvals-and-sandbox`.

**Effort lives in the TOML as `model_reasoning_effort`**, not on the command line. Codex has
no `--effort` CLI flag.

## Pre-dispatch verification

The profiles used by `codex --profile <role>` are **machine-local launch profiles** at
`${CODEX_HOME:-$HOME/.codex}/<role>.config.toml`. The harness ships owner-scoped templates in
`.codex/profiles/<role>.config.toml`; those templates are the source of truth for pane launch.

Do not confuse them with `.codex/agents/*.toml`. Those are project-local **custom subagent
types** that a running Codex session may spawn. They do not make `--profile builder` resolve,
do not allocate a branch or worktree, and do not replace a visible Herdr role pane. Astragentic
ships only read-only-intent helpers there; lifecycle roles still use the launcher below.

`sandbox_mode = "read-only"` in a custom-agent file is a requested default, not Astragentic's
isolation boundary. Codex reapplies a parent's live permission overrides to children, so a
parent launched with bypass can weaken that default. The instructions still forbid writes,
but worktree/branch allocation and a visible Herdr pane remain the only accepted boundary for
write-heavy role work.

Before dispatch, verify:

```bash
PROFILE="${CODEX_HOME:-$HOME/.codex}/<role>.config.toml"
TEMPLATE=".codex/profiles/<role>.config.toml"

# 1. Profile exists
test -f "$PROFILE" || { echo "STOP: profile missing — copy from $TEMPLATE"; exit 1; }

# 2. Profile matches template (or report drift)
diff -q "$PROFILE" "$TEMPLATE" || echo "DRIFT: profile differs from template — show owner"

# 3. Model/Effort agree with orchestrator.md row
# Read the model from TOML and compare with the orchestrator row
```

Where the profile is absent or drifted, give the owner the exact copy and diff commands and
get explicit confirmation. **Never provision silently** — the profile carries the owner's
runtime and model choices.

## Launch

```bash
herdr agent start "<role>-<ticket-id>" --kind codex --pane <pane-id> --timeout 60000 \
  -- --profile <role> --dangerously-bypass-approvals-and-sandbox
```

## Measured runtime facts

**Codex detection quality.** Codex's top rules are `osc_title` (1100, 1050) — the agent's
own title, which beats scraping. `working` and `blocked` are OBSERVED. `idle` is rule-backed
via `osc_title`, making it the most reliable of the three runtimes for terminal-state
detection. Still verify by artifact.

**Three Codex configuration surfaces have three different jobs.** `AGENTS.md` carries project
instructions. `.codex/agents/*.toml` defines spawnable custom subagents, and
`.codex/hooks.json` registers project-local lifecycle hooks. The machine-local profile selected
by `--profile` carries the top-level pane's role identity, model and effort. Never route a
Builder through a custom subagent merely because both surfaces use TOML: the custom subagent
shares the parent session topology and has no Astragentic worktree allocation.
