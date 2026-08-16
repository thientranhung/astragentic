---
name: dispatch-ticket-codex
description: "Codex-specific launcher and verification for dispatch-ticket. Covers the launcher matrix, machine-local profile verification, herdr agent start template, and Codex-specific runtime facts (effort in TOML, --yolo stale). Read dispatch-ticket for the shared protocol."
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

Codex profiles are **machine-local only** at `${CODEX_HOME:-$HOME/.codex}/<role>.config.toml`.
They are NOT project-tracked (Codex does not load project-level config). The harness ships
templates in `.codex/profiles/<role>.config.toml` — these are the source of truth.

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

**`AGENTS.md` is the project-level instruction mechanism.** Codex does NOT load
project-level config TOML — profiles live only at `${CODEX_HOME:-$HOME/.codex}/`.
Project-level instructions go through `AGENTS.md` at the repo root, which Codex loads as a
user-role message. The profile's `developer_instructions` field carries the role identity and
the pointer to `.agents/roles/<role>.md`.
