---
title: github-issue-tracker
oneLiner: "Drive GitHub Issues as the harness tracker, with status in labels and the board as a mirror you write."
group: adapter
order: 4
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/github-issue-tracker/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

`github-issue-tracker` is one of three tracker adapters. `.agents/tracker-contract.md` states the
five things the pipeline requires of *any* tracker, no more. This file is the HOW for one of the
three: status as labels, the claim, native dependencies, the frontier loop, and the Projects
board mirror. The project half stays in the project: the `<owner>/<repo>`, the ticket prefix and
the label-to-column names live in that project's `docs/agents/issue-tracker.md`. I reach the
tracker with the `gh` CLI rather than an MCP server, because `gh` is already authenticated
wherever pull requests are already being driven.
<!-- source: harness/.agents/skills/github-issue-tracker/SKILL.md -->

One fact decides everything else: **GitHub Issues has no status field.** Status lives in two
unsynced places. The label is the truth, and the Project `Status` column is a mirror somebody has
to write. GitHub syncs neither to the other, so every status change is two writes, forever. That
is the standing cost of the cheapest tracker to start on. Every trap on this page was paid for on
a live project that moved from Linear to GitHub on 2026-08-21.
<!-- source: harness/.agents/skills/github-issue-tracker/SKILL.md, harness/.agents/tracker-contract.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| The project's `issue-tracker.md` names GitHub | `Skill(skill: "github-issue-tracker")`, and no other adapter |
| Choosing a tracker, or moving between two | `.agents/tracker-contract.md` |
| A status change | Two writes: the label, then `project-status-sync.sh` for the board |
| A blocking edge to add | The blocker's numeric **database id**, not its `#number` and not its node id |
| A tracker that disagrees with git | `reconcile-tracker` |

<!-- source: harness/.agents/skills/github-issue-tracker/SKILL.md -->

## Prerequisites

- **`gh` carries the `project` OAuth scope**, which is not in its default set. Without that scope,
  `--json projectItems` returns `[]` rather than an error, and that result is indistinguishable
  from "this issue is on no board". The owner runs `gh auth refresh -s project` once.
- **The project's `issue-tracker.md` exists** and carries the repo, the ticket prefix, the
  label-to-column names, the name of the tracker it came from, and the
  pull-request-as-request-surface decision.
- **Exactly one of `backlog` / `todo` / `in-progress`** on every open issue, so a status change is
  a remove plus an add.
- **`GH_PROJECT_OWNER` and `GH_PROJECT_NUMBER` are set** for `project-status-sync.sh`, which
  refuses to guess either value.

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The claim | `--add-assignee @me`, written before the worktree exists |
| The Builder identity | `.astraler/state/dispatch-record.json`, because no GitHub field can hold `builder/<ticket-id>` |
| The stable id | The `<PREFIX>-<n>` token leading the issue title, which is what keeps citations resolving |
| The blocking graph | Native dependencies and sub-issues, both UI-visible, both keyed by database id |
| The owner's view | The Project `Status` column, written by `project-status-sync.sh`, read-only by default and `--apply` to write |

<!-- source: harness/.agents/skills/github-issue-tracker/SKILL.md -->

## Known failures

Pulled from `harness/.agents/memory/recurring-failure-modes.md`. Both are marked `promoted`.

- **AST-057**: a frontier that is only computed is invisible to the one person who cannot
  compute it. An agent re-runs the query on demand and never notices anything missing, while the
  owner opens the board and looks. Measured on a live project: zero issues had ever entered the
  unstarted state across the project's whole life. The contract fixes this in two halves. First,
  write the computed answer back as state. Second, never read a readiness label as a blocker.
  A merge step then has to be reported, where `none` is a valid report and silence is not.
- **AST-074**: a tracker measured only against itself cannot detect its own drift. Four tickets
  sat claimed and in-progress with a live assignee after their code had merged, the oldest by a
  full day, and nothing errored. A wrong state is still perfectly consistent with itself, so the
  oracle has to be independent of what it measures. The fix is `reconcile-tracker` plus
  `scripts/ticket-git-facts.sh`, read-only by a recorded ruling rather than by omission.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- `gh auth status` lists `project`, checked before any emptiness on a board query is believed.
- Every label write was paired with a board write in the same action.
- Blocking edges were read back through `.../dependencies/blocked_by`, never through
  `issue_dependencies_summary`, which lags a write by about two seconds.
- Every issue body was created with `--body-file`, never `--body`.
- The ticket id in the title is the identifier every citation uses, and the GitHub number is
  never treated as a replacement for it.

<!-- source: harness/.agents/skills/github-issue-tracker/SKILL.md -->

## Where it fits

`thomas.md` reads the project's `issue-tracker.md` at session start → that file names this
adapter → the frontier query runs as a list call plus an N+1 loop, because GitHub has no query
language → `dispatch-ticket` claims the winner with `--add-assignee @me` → merge closes the issue
and writes `todo` on whatever it unblocked, in the same pass → `reconcile-tracker` measures the
result against git. The two adapters in the same group are `jira-issue-tracker` and
`linear-issue-tracker`, and `.agents/tracker-contract.md` sits above all three.
