# Orchestrator — role → runtime, model, effort

**This file is the owner's**, and it is the single home for which runtime each role runs on and
with what model. Role contracts carry no model IDs; dispatch reads its answers from here. Thomas
reads it at session start, and an edit takes effect at the next dispatch.

**Scaffold, not payload.** An install writes this file only when it is absent; an upgrade leaves
it alone. Row *values* are yours and survive an upgrade untouched; the table's *structure*
follows the package, so an upgrade may add rows or columns while carrying your values across.
Where the shape changes, a release reports the difference and you merge it (AST-041).

**Fill every `<set-me>` with a real id for your account before dispatching.**
The package ships no model id on purpose: a placeholder that looks real resolves nowhere and
fails at the first cross-vendor call, looking like the provider being down.

## Workspace identity

| Field | Value |
|---|---|
| workspace-label | `<set-me>` |
| builder-target | `4` |

`workspace-label` is this project's herdr name, read before dispatch.

`builder-target` is how many Builders may be live at once. The mod reads it at every brief
(4.1.0): a Builder brief is refused while that many recorded Builders are live and unmerged.
**Absent, it defaults to 4**; the row tunes it, not enables it. Thomas tops the frontier up to it
after every merge, handback and report.

**One project, one workspace.** `herdr workspace list` → match label → reuse; no match →
`herdr workspace create --label <workspace-label>`. Never a nickname, never a duplicate.

| Tab creator | Pattern | Example |
|---|---|---|
| Thomas | `thomas` | `thomas` |
| Builder | `ticket:<id>` | `ticket:ABC-129` |
| Shaper | `spec:<id>` | `spec:ABC-128` |
| QA | `qa:<id>` | `qa:ABC-130` |
| Owner (BA) | `ba` | `ba` |
| Owner (manual) | anything | `deploy` |

**Owner tabs are not yours** — always create a fresh tab rather than splitting, renaming or
closing one.

## Active assignments

| Role | Runtime | Model | Effort | Advisor |
|---|---|---|---|---|
| thomas | claude | claude-opus-5 | medium | fable |
| shaper | claude | claude-opus-5 | high | fable |
| builder | claude | claude-sonnet-5 | medium | opus |
| qa | claude | claude-sonnet-5 | low | opus |

## Junior

| Role | Runtime | Model | Effort |
|---|---|---|---|
| builder | none | | |

`none` means the Builder implements alone. Naming a runtime hands the typing to a junior pane
the Builder opens beside itself, briefs, waits on and reads back (`dispatch-junior`); review,
simplify, the arm and the handback stay the Builder's. The runtime names the supplement the
junior reads, `.agents/roles/junior-<runtime>.md`, so a runtime with no such file is a
misconfigured row, not a new option. Shipped: `grok` (Grok Build; Model e.g. `grok-4.7`, Effort
`high`). Per project, per situation; blank it back to `none` to return the typing to the Builder.

## Cross-vendor arm

| Scope | Enabled |
|---|---|
| ticket | yes |
| spec | yes |
| slice | yes |

`no` turns that scope's arm off for this project: the role skips the phase, commits no
`arm(<scope>):` receipt, and writes `Arm: off (orchestrator)` in its handback; the merge does
not ask for the marker. A machine without Codex sets all three; a Builder the owner wants
faster sets `ticket` only and keeps `slice`, the one read every ten merges that sees across
tickets. Absent row or table means `yes`.

## How the columns are read

**Runtime** picks the launcher; `dispatch-ticket` owns the matrix. A row naming a runtime with
no dispatch path for that role is a misconfigured row: take it to the owner. Moving a role to
another runtime is a role-contract change — it needs a dispatch path and an adapter — not a row
tune.

**Model** travels on the command line, so this table is its only home — nothing mirrors it
and nothing can disagree with it.

**Effort** is `low|medium|high|xhigh|max` on Claude. A junior row takes its runtime's values
(`dispatch-junior` names them).

**Advisor** (Claude only): `--advisor <value>` when the cell is set, blank means none. It must
rank at or above the main model: Opus rows take `fable` (usage credits; one `/model fable`
consent per machine), Sonnet rows `opus`. Junior rows have no advisor.

**Every role runs on Claude Code.** Another runtime enters only as a junior under the Builder,
never as a role of its own.
