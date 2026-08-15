---
name: dispatch-ticket-opencode
description: "OpenCode-specific launcher and verification for dispatch-ticket. Covers the launcher matrix, pre-dispatch adapter verification, herdr agent start template, and measured opencode runtime facts (idle fabrication, transcript limits, effort unreachable). Read dispatch-ticket for the shared protocol."
---

# Dispatch a ticket — OpenCode runtime

**Read `dispatch-ticket` for the shared protocol** (binding identity, inputs/resolution,
worktree law, brief format, submission, watching, simplify, cleanup). This skill adds only
the OpenCode-specific launcher and verification.

## Launcher matrix — OpenCode rows

```text
builder  → opencode --agent builder -m <row: Model> --auto
shaper   → opencode --agent shaper -m <row: Model> --auto
```

Model comes from the role's `orchestrator.md` row, never from memory. **The Model value
must include the provider prefix** — opencode requires `<provider>/<model>` format (e.g.,
`opencode-go/deepseek-v4-flash`). Passing the bare model name without prefix throws
`ProviderModelNotFoundError`. If the model is already the opencode default, `-m` can be
omitted entirely.

**No `--effort` flag** — effort is unreachable on opencode (fact 2 below), so an opencode
Effort cell must be blank. A non-blank one is a misconfigured row: stop and ask the owner.

`--auto` auto-approves permissions that are not explicitly denied. With the agent's
`permission: { "*": allow }` frontmatter, `--auto` effectively means unrestricted.

## Pre-dispatch verification

Verify the adapter exists in the worktree:

```bash
test -f <worktree-path>/.opencode/agents/<role>.md || echo "STOP: adapter missing"
```

**Do NOT verify with `opencode agent list --pure`** — it does not show project agents
(display-level bug, verified on v1.18.18). Use `opencode debug agent <role>` from the
worktree cwd instead to confirm resolution.

OpenCode walks CWD upward to find `.opencode/agents/`, so the pane's cwd must be the
worktree root or a child of it. The mandatory cwd gate in the shared protocol covers this.

## Launch

```bash
herdr agent start "<role>-<ticket-id>" --kind opencode --pane <pane-id> --timeout 60000 \
  -- --agent <role> -m <row: Model> --auto
```

## Measured runtime facts

Re-measured on herdr 0.8.0 and opencode 1.18.11:

1. **`herdr agent start --kind opencode` works** on 0.8.0 — exit 0, agent detected, process
   confirmed alive with `pgrep` rather than by trusting `interactive_ready`. `agent start`
   is the launch for all three runtimes.
2. **Effort is unreachable.** `opencode run` requires a positional message, so it cannot
   start a message-less persistent executor; the TUI form is the persistent one and has no
   `--variant`. The `--variant` form is invisible to herdr. Effort and orchestration
   visibility are mutually exclusive on opencode, and visibility wins — which is why opencode
   Effort stays blank.
3. **opencode's `idle` is FABRICATED.** `herdr agent explain` reports
   `fallback_reason: default_known_agent_idle_fallback`, and `agent wait --until idle`
   returned rc=0 in 8 ms on a pane nobody had touched. Its manifest carries 3 rules
   (claude 12, codex 7), covering only `blocked` and `working`. So on opencode `working`
   and `blocked` are OBSERVED while idle is ASSUMED: the watcher's start guard still works,
   terminal-state detection does not, and a verdict must come from an artifact (AST-032).
4. **Runtime detection quality is a ladder.** Codex's top rules are `osc_title` (1100, 1050)
   — the agent's own title, which beats scraping. Claude tops out at `osc_title` 1100 then
   falls to text regions. opencode establishes idle not at all. Verify by artifact on every
   runtime; on opencode it is the only thing that works.
5. **Transcript reads return only the input box and footer.** Reading an opencode TUI
   transcript via `herdr agent read` returns only the input box and footer. Tolerable under
   verify-by-artifact — review diffs, not pane narration.
6. **Model requires provider prefix.** `-m deepseek-v4-flash` fails with
   `ProviderModelNotFoundError`. The correct form is `-m opencode-go/deepseek-v4-flash`.
   The `orchestrator.md` Model column for opencode rows must carry the full
   `<provider>/<model>` string. Measured on opencode 1.18.18.
