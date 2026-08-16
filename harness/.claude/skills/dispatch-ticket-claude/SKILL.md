---
name: dispatch-ticket-claude
description: "Claude Code-specific launcher and verification for dispatch-ticket. Covers the launcher matrix, pre-dispatch adapter verification, herdr agent start template, and Claude-specific runtime facts. Read dispatch-ticket for the shared protocol."
---

# Dispatch a ticket — Claude Code runtime

**Read `dispatch-ticket` for the shared protocol** (binding identity, inputs/resolution,
worktree law, brief format, submission, watching, simplify, cleanup). This skill adds only
the Claude Code-specific launcher and verification.

## Launcher matrix — Claude rows

```text
builder  → claude --dangerously-skip-permissions --agent builder --model <row: Model> --effort <row: Effort>
shaper   → claude --dangerously-skip-permissions --agent shaper --model <row: Model> --effort <row: Effort>
rin      → claude --agent rin --model <row: Model> --effort <row: Effort>
qa       → claude --agent qa --model <row: Model> --effort <row: Effort>
```

Model and effort come from the role's `orchestrator.md` row, never from memory.

Add `--effort` only when the row sets it (`low|medium|high|xhigh|max`); blank means the
runtime default. **Rin runs without `--dangerously-skip-permissions`**: a gate runs under
permissions, and rin has no fallback row, so no other runtime is legal here.

## Pre-dispatch verification

Verify the adapter exists in the worktree before launching:

```bash
test -f <worktree-path>/.claude/agents/<role>.md || echo "STOP: adapter missing"
```

A missing adapter means the payload was not committed or was gitignored (AST-036). The
shared protocol's worktree-visibility check catches this too, but this is the exact file
`claude --agent <role>` will try to load.

## Launch

For **builder** and **shaper** (write roles):

```bash
herdr agent start "<role>-<ticket-id>" --kind claude --pane <pane-id> --timeout 60000 \
  -- --dangerously-skip-permissions --agent <role> --model <row: Model> --effort <row: Effort>
```

For **rin** and **qa** (review roles — no `--dangerously-skip-permissions`):

```bash
herdr agent start "<role>-<artifact-key>" --kind claude --pane <pane-id> --timeout 60000 \
  -- --agent <role> --model <row: Model> --effort <row: Effort>
```

## Measured runtime facts

**Claude idle rule.** `prompt_box_body` at priority 950 matches `"❯\n"`, so **an empty
Claude composer reads as idle**. This means:

- A multi-line brief sitting unsent in the composer reports `idle` — the dispatcher trusts
  it and concludes the Builder finished instantly (AST-032, AST-037).
- After submission, the start guard must observe `working` before trusting any later `idle`.

**Runtime detection quality.** Claude tops out at `osc_title` 1100 then falls to text
regions. `working` and `blocked` are rule-backed; `idle` is rule-backed but its evidence is
weak (the empty-composer match above). Verify by artifact.
