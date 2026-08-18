# Orchestrator — role → runtime, model, effort

> **Scaffold, not payload.** An install writes this file only when it is absent. An upgrade
> leaves it alone: the values here are the owner's, and no release may overwrite them. Where
> the table's *shape* changes, a release reports the difference and the owner merges it
> (AST-041). A harness that ships a competing copy of a file it calls the owner's has two
> homes for one fact, and the shipped one wins by accident.

**This file is the owner's.** It is the single home for which runtime each role runs on and
with what model. Role contracts describe what a role does and carry no model IDs; dispatch
reads its answers from here. Thomas reads it at session start, and an edit takes effect at
the next dispatch.

**Fill every `<set-me>` with a real id for your account before dispatching to that runtime.**
The package deliberately ships no model id: a placeholder that looks real resolves nowhere
and fails at the first cross-vendor call, looking like the provider being down.

## Workspace identity

| Field | Value |
|---|---|
| workspace-label | `<set-me>` |

The workspace label is the single name for this project in herdr. Thomas reads it before
any dispatch and uses it to find or create the project workspace.

**One project, one workspace.** `herdr workspace list` → match by label → reuse. No match
→ `herdr workspace create --label <workspace-label>`. Never invent a nickname, never derive
from the folder name, never create a second workspace for the same project.

**Tabs inside the workspace follow a fixed convention:**

| Creator | Label pattern | Example |
|---|---|---|
| Thomas (own session) | `thomas` | `thomas` |
| Dispatch builder | `ticket:<ticket-id>` | `ticket:TRA-139` |
| Dispatch shaper | `spec:<effort-id>` | `spec:TRA-87` |
| Dispatch QA | `qa:<ticket-id>` | `qa:TRA-125` |
| Dispatch Rin | `rin:<ticket-id>` | `rin:TRA-125` |
| Owner (manual) | anything | `deploy`, `ssh` |

**Owner-created tabs are not yours.** Do not split into them, rename them, or close them.
Always `herdr tab create` a new tab for a dispatch — never reuse an existing tab whose
label does not match the pattern above.

## Active assignments

| Role | Runtime | Model | Effort |
|---|---|---|---|
| thomas | claude | claude-opus-5 | medium |
| shaper | claude | claude-opus-5 | high |
| builder | claude | claude-sonnet-5 | medium |
| rin | claude | claude-opus-4-8 | medium |
| qa | claude | claude-sonnet-5 | low |

## Fallback providers

Used when a role's active runtime is genuinely unavailable — CLI missing, auth failed, quota
exhausted. Falling back is per-session, is reported to the owner as a degradation, and is
never written back into this file.

| Role | Runtime | Model | Effort |
|---|---|---|---|
| thomas | codex | <set-me> | high |
| shaper | codex | <set-me> | high |
| builder | codex | <set-me> | medium |
| qa | codex | <set-me> | medium |

**Removing a role's codex row means that role does not run on Codex** — no fallback, no
machine profile, and the doctor stops asking about one. That is how you decline a runtime
deliberately, rather than leaving `<set-me>` in place and being warned about it every run.
Re-add the row when you want it back.

**`rin` has no fallback row, and its absence is the correct state.** The gate is a Herdr pane
on the root provider's runtime, and no Codex or opencode adapter can host it, so any fallback
would name a runtime that cannot gate. No available Claude root means STOP and ask the owner,
rather than a degraded gate. A project that has re-added the row has regressed.

## How the columns are read

**Runtime** picks the launcher; `dispatch-ticket` owns the matrix. A row naming a runtime
with no dispatch path for that role is a misconfigured row: take it to the owner rather than
substituting. Moving a role to another runtime is a role-contract change — it needs a
dispatch path and an adapter — not a row tune.

**Model** travels on the command line for Claude and opencode. For Codex it lives in the
machine-local profile at `${CODEX_HOME:-$HOME/.codex}/<role>.config.toml`, which mirrors this
table; a profile that disagrees with its row is drift to report. **opencode requires
`provider/model` format** (e.g. `opencode-go/deepseek-v4-flash`, not bare `deepseek-v4-flash`)
— a bare model name produces `ProviderModelNotFoundError` at launch with no suggestion,
looking like a missing model rather than a format problem.

**Effort** is `low|medium|high|xhigh|max` on Claude. Codex carries it as
`model_reasoning_effort` in the same profile TOML. **opencode leaves it blank** — the
persistent TUI form has no `--variant`, and the form that does is invisible to herdr, so
effort and orchestration visibility are mutually exclusive there and visibility wins. A
non-blank opencode Effort cell is a misconfigured row.

**Mixing runtimes across roles is legal** — a Claude Shaper with a Codex Builder is a valid
configuration. Each pane launches from its own row.

Row *values* are yours and survive an upgrade untouched. The table's *structure* follows the
package, so an upgrade may add rows or columns while carrying your values across.
