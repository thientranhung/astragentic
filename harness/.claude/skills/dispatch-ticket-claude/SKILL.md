---
name: dispatch-ticket-claude
description: "Claude Code-specific dispatch protocol. Covers SendMessage brief delivery, Monitor-based watching, launcher matrix, pre-dispatch verification, and Claude runtime facts. Read dispatch-ticket for the shared protocol."
---

# Dispatch a ticket — Claude Code runtime

**Read `dispatch-ticket` for the shared protocol** (binding identity, inputs/resolution,
worktree law, brief format, submission, watching, simplify, cleanup). This skill adds only
the Claude Code-specific launcher and verification.

## The submission order

Four actions, in this order. Getting them out of order produces a false terminal state that
every downstream check reads as healthy (AST-032, AST-037).

1. **Body via `SendMessage`** — everything except the slash command.
2. **Slash command typed into the pane** as real input, plugin-qualified, single line.
3. **Confirm it echoed in the pane.** Positive evidence, because a refusal or a substitute is
   a real turn that ends `TERMINAL:done`, exit 0.
4. **Arm the Monitor** — after step 3, never after step 1. A body-only `SendMessage` produces
   its own turn; a watch armed before the command sees THAT turn end and reports
   `TERMINAL:idle` on a builder that has not started.

Detail for each is below.

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

## Brief submission — SendMessage carries the body, the pane receives the command

**Claude builders receive the brief BODY via SendMessage, not Herdr paste.** The shared
protocol's paste-based submission (AST-037) applies to Codex/OpenCode only.

**SendMessage cannot deliver the phase's slash command.** A message to another Claude session
arrives wrapped as `<cross-session-message from="...">` — a tool-delivered peer message, **not a
user turn** — and the flow skills are `disable-model-invocation: true`, so a user turn is the
only thing that reaches them (AST-112).

**Step 1 — body via SendMessage.** Discover the session name via `ListAgents`, then:

```
SendMessage({
  to: "<builder-session-name>",
  message: "<brief body — everything except the slash command>"
})
```

**Step 2 — the bare slash command, TYPED into the pane as real input:**

```bash
herdr pane run <pane-id> '/mattpocock-skills:implement TRA-123'
herdr pane send-keys <pane-id> Enter
```

**Step 3 — confirm it echoed in the pane.** The command needs no arguments beyond the ticket
id, since the body is already in context, so it stays a single line and avoids the
multi-line-paste problem SendMessage exists to solve (AST-037).

**This failure does NOT surface as `NO_START`** — a refusal or a substitute is a real turn that
starts, runs and ends `TERMINAL:done`, exit 0. Nothing in the watching apparatus can see it,
which is why step 3 is positive evidence rather than a courtesy.

**Two dispatches, same round, same defect, two outcomes** (measured 2026-08-19):

| Pane | Command | Outcome |
|---|---|---|
| builder | `/mattpocock-skills:implement` | **Loud** — invocation refused, builder stopped without touching the worktree, cited its own rule, asked for a human to type it. One round trip lost. |
| shaper | `/mattpocock-skills:grill-with-docs` | **Silent** — began `cat`-ing the plugin's own skill files from the cache and proceeding from prose. Produces something shaped like a spec, indistinguishable from a real invocation. |

Same runtime, same command shape. The builder's contract carried "the failure IS the finding"
and the shaper's did not, so one defect surfaced and one hid (AST-055). Both carry it now.

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

**Monitor is the delivery channel; `herdr-watch-terminal.sh` is the watch.** Monitor turns
each stdout line into a notification; the script decides what a line means. A bare
`herdr agent wait` inside Monitor goes deaf — measured twice in two sessions (AST-107).

**Step 4 — arm the Monitor**, after the echo is confirmed:

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

**One dispatch, one pane, one Monitor.** A gathered watch is a single point of failure for
every builder behind it, and it needs a hand-rolled loop — which is where that failure class
came from. `TaskStop` cancels exactly one.

**On notification, the same debounce applies**: re-check with `herdr agent get <pane-id>`
before acting. The notification is the bell, not the verdict.

**To cancel a Monitor**, use `TaskStop` — no PID management, no process group kill.

**Caffeinate IS needed, and the script carries it.** A Monitor command is an ordinary shell
process, not an in-process native watch, so an idle sleep kills it — measured on five
hand-rolled watchers in one session. The script gives you `caffeinate -i`, the start guard,
the debounce, the cap and the wait slicing; a hand-rolled Monitor command has none of the
five.

## Measured runtime facts

**Claude idle rule.** `prompt_box_body` at priority 950 matches `"❯\n"`, so **an empty
Claude composer reads as idle**. This means:

- A multi-line brief sitting unsent in the composer reports `idle` — the dispatcher trusts
  it and concludes the Builder finished instantly (AST-032, AST-037).
- After submission, the start guard must observe `working` before trusting any later `idle`.

**Runtime detection quality.** Claude tops out at `osc_title` 1100 then falls to text
regions. `working` and `blocked` are rule-backed; `idle` is rule-backed but its evidence is
weak (the empty-composer match above). Verify by artifact.
