---
title: dispatch-ticket
oneLiner: "Hand one claimed ticket to one Builder in a visible pane on Herdr or Orca, with its own worktree and branch."
group: main-flow
order: 10
runtimes: [claude]
source: harness/.claude/skills/dispatch-ticket/SKILL.md
rented: false
diagram: ticket-lifecycle
lang: en
updated: 2026-11-22
harness: v6.1.19
---

## What it does

**`dispatch-ticket` is the shared protocol Thomas follows to take a ticket from "claimed" to "a Builder is working".** Each ticket gets one Builder, one worktree, one branch and one pane. The launcher, the mod and the pre-dispatch check live in `dispatch-ticket-claude`; read both skills.

Eight steps, in a fixed order:

- **Preflight** on the session's first dispatch: watchdog running, payload committed.
- **Resolve the role row** in `orchestrator.md`: runtime, model, effort; collect the write-set.
- **Claim, then create the branch and worktree.**
- **Resolve the workspace**, create the tab and pane, pass the cwd gate.
- **Print the resolved dispatch**, launch, read the record back.
- **Send the brief**: its first line is the phase's slash command.
- **Branch on the turn end**: `TURN-END` for a mod pane, the watcher's exit for a gate or junior pane.
- **Verify by artifact**, then clean up.

The binding identity is `ticket → assignee (claim) → pane → worktree → branch → PR`, each link one-to-one. The claim precedes the worktree, so two Thomas sessions cannot pick the same ticket.

**Measurement.** A small ticket (20 non-test lines or fewer) through a Builder pane cost a median 114 model calls and 8 minutes of pane time; 5 such tickets merged between 2026-10-27 and 11-12. That number is why the Quick Builder exists.

**Cost.** Every dispatch needs a committed payload, a workspace, a tab, a pane and a record. Work too small for that goes to the Quick Builder (below).
<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## Host: Herdr or Orca, one host per session

**`ORCA_PANE_KEY` set means Orca; otherwise `HERDR_ENV=1` means Herdr.** The pane, watching and cleanup steps take their Orca form from `ORCA.md`, and no `herdr` command runs in an Orca session. Since 6.1.0 the mod refuses a `herdr` command in an Orca session and an `orca` command in a Herdr session.

| Situation | Rule |
|---|---|
| Session started in Herdr | `herdr` only; tab `ticket:<id>`, pane `builder:<id>` |
| Session started in Orca | `orca` only; handles per `ORCA.md` |
| A command of the other host | Refused by the mod |

<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md; harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A ticket on the frontier with no assignee | `dispatch-ticket` (claim first, worktree after) |
| The dispatch itself, after the claim | `dispatch-ticket` plus `dispatch-ticket-claude` |
| A pane for a Shaper or QA | Same skill; only the tab prefix differs (`spec:`, `qa:`) |
| A small change the owner judges by eye | A Quick Builder pane, no ticket |
| A pane that sits still or stalls mid-turn | `WATCHING.md` (accompanying document) |
| The Builder has handed back; time to remove the worktree | `CLEANUP.md` (accompanying document) |

<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## Prerequisites

- **A running watchdog** for the workspace, confirmed on the session's first dispatch (`WATCHING.md`).
- **A committed, un-ignored payload.** A worktree holds tracked content only; `PAYLOAD NOT VISIBLE` is a stop.
- **A real row for the role in `orchestrator.md`.** `<set-me>`, a missing row or an ambiguous one is a stop; never borrow another role's model.
- **A current base**: `git rev-parse <base>` equals `origin/<base>` before the worktree exists.
- **The ticket's write-set**, and the write-set of every other live ticket while any other dispatch is live.
- **For a UI brief**: the `design-spine` and `anti-slop-skills` plugs under `.astraler/project/` (5.1.0).

<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## The brief

**The first line of the brief is the phase's slash command**: `/astra-implement-with-tdd <ticket>` for a Builder, `/astra-grill-with-docs` or `/astra-to-tickets <spec-id>` for a Shaper. The flow skills are `disable-model-invocation: true`, so only text arriving as a user turn reaches them.

- **`FLOW:`** lists the Skill calls in order: the project's anti-slop skill then `astra-ui` (UI ticket), `astra-review`, `simplify`, the arm. TDD sits inside `astra-implement-with-tdd`.
- **`quick` / `full`** is the ticket's tracker label (4.6.0), never a brief line. The mod reads it at the send and writes `kind` on the record. A quick ticket runs the built-in `code-review` only and owes no markers.
- **`QA: walk|probe|verify|none`** and `QA plan: docs/qa/plan-<slug>.md`: the mod refuses a brief without the plan.
- **A UI brief pastes the ticket's `## Glance`, `## States` and `## Criteria` verbatim** (5.0.0). With any of the three missing, the brief is not sent.
- **A Shaper brief carries a `UX:` line** (5.0.9): `UX: docs/prd.md — UJ-1, UJ-2`, or `UX: n/a — <why>`. The PRD must be committed on the base.
- **`Owned elsewhere:`** turns a merge conflict into a handback note; **`ADDRESSED TO:`** is the second line so a fork does not take the role.

**Measurement.** Before the design plugs, a prose rule asking the Builder to read the anti-slop skill ran on 1 of 14 UI merges (2026-10-28 to 11-01).
<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## The Quick Builder: work that is not a ticket

A change the owner judges by looking at the result (`thomas.md`: Not a ticket) goes to a Quick Builder pane: no issue, no claim, no record entry, no marker at merge. The pane makes its own `ops/<slug>` worktree and fast-forwards into main; the git guard holds it to that shape. Model and effort come from the `builder-quick` row.

Thomas sends the owner's words in one SendMessage; the pane answers with a before/after. Work that needs tests or review becomes a ticket on the owner's word. The pane is not a lane: it has no TURN-END bell and no watchdog, so a silent pane is read, not waited on.

**Cost.** Thomas's word is a turn on the root checkout, so his local base must equal origin and no merge may wait unpushed before he gives it.
<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The claim | The tracker assignee, or `identity` in the record when the assignee cannot hold `builder/<id>` |
| The dispatch | `.astraler/state/dispatch-record.json`, keyed by ticket: branch, worktree, workspace, tab, pane, runtime, write-set, `kind` |
| Worktree and branch | `<repo-root>/.claude/worktrees/<branch-slug>`, gitignored, removed at cleanup |
| Which flow the pane ran | `skills_run` in the record; `TURN-END` carries a `Skills run:` line |
| The Builder's work | Commits on the ticket branch, pushed before handback |

Cleanup closes the tab named by `tab_id`, and deletes the entry once the worktree and branch are gone.

<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## Known failures

From `harness/.agents/memory/recurring-failure-modes.md`; all three are `promoted`.

- **AST-097.** `TERMINAL:done` means the turn ended, not that the work finished. Hence `TURN-END` is a bell, and verification is by artifact.
- **AST-107.** A long `herdr agent wait` can go deaf and never fire. A mod pane replaces the watcher with `TURN-END`.
- **AST-154.** Re-sending a brief after `NO_START` appends to the unsent composer and submits both. Read the composer first; clear it with `esc esc`.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- Every open ticket has an entry in `dispatch-record.json`, with its write-set.
- Tab and pane carry the role prefix (`ticket:`, `spec:`, `qa:`); a prefix outside the watchdog's `TITLE_PREFIXES` dispatches unmonitored, with no error.
- The record read back has a `pane_id` equal to the pane just created.
- A UI brief has Glance, States and Criteria, and the project declared both plugs.
- Cleanup removes the worktree only after `git status --short` is empty.

<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## Where it fits

Frontier query → claim → **`dispatch-ticket`** (+ `dispatch-ticket-claude`) → Builder runs `astra-implement-with-tdd` → `astra-ui` → `astra-review` → simplify → arm (`codex-arm`) → handback → `dispatch-qa-walk` → merge → `CLEANUP.md`. The role contracts are `thomas.md` and `builder.md`.
