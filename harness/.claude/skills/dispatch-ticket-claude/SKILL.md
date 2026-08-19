---
name: dispatch-ticket-claude
description: "Claude Code-specific dispatch protocol. Covers SendMessage brief delivery, Monitor-based watching, launcher matrix, pre-dispatch verification, and Claude runtime facts. Read dispatch-ticket for the shared protocol."
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

## Brief submission — SendMessage

**Claude builders receive briefs via SendMessage, not Herdr paste.** The shared protocol's
paste-based submission (AST-037) applies to Codex/OpenCode only.

After launching the builder with `herdr agent start`, discover its session name via
`ListAgents`, then send the brief directly:

```
SendMessage({
  to: "<builder-session-name>",
  message: "<full brief including slash command>"
})
```

One call. No paste, no Enter, no idle false-positive. The brief arrives as a user-turn
message in the builder's session.

**Confirm `working` after sending**: use `herdr agent wait <pane-id> --until working
--timeout 30000` to verify the builder started. If it does not reach `working`, the
message may not have been received — fall back to Herdr paste.

**Steering on BLOCKED**: when Monitor reports `blocked`, read the pane to understand the
question, then reply via SendMessage:

```
SendMessage({
  to: "<builder-session-name>",
  message: "<answer to the builder's question>"
})
```

Then start a new Monitor for the resumed work.

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

## Watching — Monitor replaces watcher script

**Claude builders use Monitor, not `herdr-watch-terminal.sh`.** The shared protocol's
watcher section applies to Codex/OpenCode only.

After submitting the brief and confirming `working`, start a Monitor:

```
Monitor({
  command: "herdr agent wait <pane-id> --until done --until blocked --until idle --timeout 3600000",
  description: "builder-<ticket-id> status"
})
```

Monitor wraps the command and delivers each stdout line as a notification to Thomas.
When the builder reaches a terminal state, `herdr agent wait` outputs the state and exits,
and Monitor delivers it.

**On notification, the same debounce applies**: re-check with `herdr agent get <pane-id>`
before acting. The notification is the bell, not the verdict.

**Branch on the reported state** — same logic as the shared protocol's watcher:

- `done` → check for background processes (AST-097) before concluding finished
- `blocked` → read pane immediately, answer the question, start a NEW Monitor
- `idle` → check git log — may be finished or stopped early

**To cancel a Monitor**, use `TaskStop` — no PID management, no process group kill.

**Caffeinate is not needed.** Monitor is a native Claude Code tool, not a shell process
subject to idle sleep (AST-032).

## Measured runtime facts

**Claude idle rule.** `prompt_box_body` at priority 950 matches `"❯\n"`, so **an empty
Claude composer reads as idle**. This means:

- A multi-line brief sitting unsent in the composer reports `idle` — the dispatcher trusts
  it and concludes the Builder finished instantly (AST-032, AST-037).
- After submission, the start guard must observe `working` before trusting any later `idle`.

**Runtime detection quality.** Claude tops out at `osc_title` 1100 then falls to text
regions. `working` and `blocked` are rule-backed; `idle` is rule-backed but its evidence is
weak (the empty-composer match above). Verify by artifact.
