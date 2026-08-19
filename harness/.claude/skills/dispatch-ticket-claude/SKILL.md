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

**Do not confirm `working` yourself — arm the watch and let it answer.** The watcher script
carries its own start guard and returns `NO_START` when the turn never began, which is the
same question a hand-rolled `herdr agent wait --until working` asks. Asking it twice delays
the script's start, and a builder that finishes inside that delay makes the script miss
`working` and report `NO_START` on work that actually happened — a second guard buying a new
false negative. On `NO_START`, read the pane and fall back to Herdr paste.

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

## Watching — Monitor delivers, the watcher script decides

**Claude runtime uses Monitor as the delivery channel and `herdr-watch-terminal.sh` as the
watch itself.** Monitor turns each stdout line into a notification; the script decides what
a line means. Through 2.3.3 this section told Thomas to put a bare `herdr agent wait` inside
Monitor — that shape went deaf in the field, twice in two sessions (AST-107).

Immediately after sending the brief, start a Monitor:

```
Monitor({
  command: "<repo-root>/scripts/herdr-watch-terminal.sh <pane-id> 3 3600 120",
  description: "builder-<ticket-id> status",
  timeout_ms: 3600000,
  persistent: false
})
```

**Never put a bare `herdr agent wait --timeout 3600000` in a Monitor.** Measured 2026-08-19:
the waiter sat 10m25s against a pane that was already `idle` and returned nothing, while an
identical wait issued in the same minute against the same pane returned in 0s with 634 bytes
of state. `pgrep` reported it running the whole time, so the operator believed the watch was
live — a signal that cannot fire, wearing the costume of a healthy one (AST-032). The script
slices the wait and takes its verdict from a fresh `herdr agent get`, so a deaf waiter costs
60 seconds instead of the session.

**Branch on the line the script emits** — same contract as the shared protocol:

- `TERMINAL:done pane=<id>` → builder's turn ended, **not necessarily finished** — check for background processes (AST-097) before concluding
- `TERMINAL:blocked pane=<id>` → read the pane immediately, answer via SendMessage, start a NEW Monitor
- `TERMINAL:idle pane=<id>` → check git log — may be finished or may have stopped early
- `TIMEOUT after <max>s pane=<id>` → builder exceeded the cap, inspect the pane
- `NO_START pane=<id>` → builder never reached `working`, re-read the pane; the brief may not have arrived

**Three builders in flight means three Monitors, one per pane — not one Monitor for all.**
Verified 2026-08-19: three concurrent Monitors were armed and all three delivered, each with
its own task id, and the notification carries the Monitor's `description`, so
`description: "builder-<ticket-id> status"` is what tells you which builder reported. Every
line the script emits also names its pane.

Do not multiplex three panes into one watch. A gathered watch is a single point of failure
for every builder behind it — the failure this release exists to fix, multiplied by three —
and it needs a hand-rolled loop, which is where that failure came from. One dispatch, one
pane, one Monitor. `TaskStop` cancels exactly one.

**On notification, the same debounce applies**: re-check with `herdr agent get <pane-id>`
before acting. The notification is the bell, not the verdict.

**To cancel a Monitor**, use `TaskStop` — no PID management, no process group kill.

**Caffeinate IS needed, and the script carries it.** A Monitor command is an ordinary shell
process, not an in-process native watch, so an idle sleep kills it exactly as it killed five
hand-rolled watchers in one session. Releases through 2.3.3 stated the opposite; that was
wrong. Use the script rather than a hand-rolled Monitor command and you inherit the
`caffeinate -i` wrapper, the start guard, the debounce, the cap, and the wait slicing — a
hand-rolled command has none of the five.

## Measured runtime facts

**Claude idle rule.** `prompt_box_body` at priority 950 matches `"❯\n"`, so **an empty
Claude composer reads as idle**. This means:

- A multi-line brief sitting unsent in the composer reports `idle` — the dispatcher trusts
  it and concludes the Builder finished instantly (AST-032, AST-037).
- After submission, the start guard must observe `working` before trusting any later `idle`.

**Runtime detection quality.** Claude tops out at `osc_title` 1100 then falls to text
regions. `working` and `blocked` are rule-backed; `idle` is rule-backed but its evidence is
weak (the empty-composer match above). Verify by artifact.
