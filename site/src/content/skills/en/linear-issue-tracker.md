---
title: linear-issue-tracker
oneLiner: "Drive Linear as the harness tracker, and check the tier's issue ceiling before building a pipeline on it."
group: adapter
order: 6
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/linear-issue-tracker/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

`linear-issue-tracker` is one of three tracker adapters. `.agents/tracker-contract.md` states the
five things the pipeline requires of any tracker; this file is the HOW for Linear. It is the thin
one, and the reason is a compliment to the product: native workflow states, a real status field,
a board that follows it with no second write, native relations, native assignee. All five
requirements met, so most of what the other two adapters spend their length on does not exist
here. Reach it through the `linear-server` MCP tools rather than a CLI. Measured on a live
project that ran Linear until 2026-08-21.
<!-- source: harness/.agents/skills/linear-issue-tracker/SKILL.md -->

Two things are worth knowing before choosing it, and the first is not about the model at all.
**The free tier stops accepting new issues.** `save_issue` returns *"You've exceeded the free
issue limit"*, and that does not degrade a pipeline — it stops one, because the first step of the
method is `create`. A project hit this and had to migrate the same day. Requirements 1 to 5 are
about a tracker's model; a tracker also has to accept a write, so check the ceiling of the tier
you are on first. The second is the claim protocol, which is weaker here than the method assumes,
and git is what carries it.
<!-- source: harness/.agents/skills/linear-issue-tracker/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| The project's `issue-tracker.md` names Linear | `Skill(skill: "linear-issue-tracker")`, and only that one |
| Creating, reading, labelling, relating or closing | `save_issue`, which is nearly all of the surface |
| A map document for one effort | `save_document` on the Linear project — a first-class primitive, not the GitHub workaround |
| A ticket that reads ready while its parent epic is blocked | Filter on parent status too; blocking is not inherited |
| Searching your own issues | `list_issues` with `query`; `search_documentation` is Linear's product docs |

<!-- source: harness/.agents/skills/linear-issue-tracker/SKILL.md -->

## Prerequisites

- **The tier accepts writes.** Check the issue ceiling before the pipeline depends on `create`.
- **The project's `issue-tracker.md` carries** the workspace, team name and key, project name and
  id, the ticket prefix, any id ambiguity from its own history, and **which seats exist**, since
  the claim protocol depends on it.
- **The state vocabulary is mapped onto the method's language**: open is anything not `Done`,
  `Canceled` or `Duplicate`; in flight is `In Progress` or `In Review`.
- **`Todo` is treated as a state that must be written**, not as a state that will happen.

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The claim | `assignee: "me"` plus state `In Progress`, as the session's first write |
| The Builder identity | The dispatch record and a comment, because `assignee` resolves to a real workspace member |
| The frontier, materialised | The `Todo` state, written when the last blocker closes |
| The blocking graph | Native relations via `save_issue`'s `blockedBy` |
| The effort's map | A Linear project document holding Notes, Decisions-so-far and Fog, one per effort |

<!-- source: harness/.agents/skills/linear-issue-tracker/SKILL.md -->

## Known failures

Pulled from `harness/.agents/memory/recurring-failure-modes.md`. Both are marked `promoted`.

- **AST-057**: a frontier that is only computed is invisible to the one person who cannot
  compute. Measured on this workspace: **zero issues had ever entered `Todo`**, and a ticket sat
  in `Backlog` for hours after both its blockers merged. The upstream cause is a plugin skill
  writing a readiness *label* at creation and never revisiting it, so two representations of
  readiness sit side by side and neither answers the dispatcher's question. Fixed in the
  contract: write the computed answer back as state, and never read a readiness label as a
  blocker.
- **AST-074**: frontier promotion computed from blocking edges alone is over-inclusive, measured
  again on Linear where three tickets surfaced as claimable during an earlier phase — a
  sub-issue with zero blockers reads ready even when its parent epic is blocked. Fixed: promotion
  stays the router's judgement, stated directly in `thomas.md`, not a query result.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- A ticket entered `Todo` in the same action that closed its last blocker, rather than skipping
  from `Backlog` to `In Progress`.
- Every invisible blocker — a deploy, a credential, a decision — was given an issue and an edge,
  because a blocker that is not an issue is invisible and the graph lies confidently.
- The claim was released by confirming the branch and worktree are gone, not by reading the
  assignee back, which cannot tell whose claim it read.
- Parent status was part of the readiness filter, not just `blockedBy`.
- Nobody treated `list_agent_skills` as writable; that shelf is authored by the owner in Linear's
  own interface.

<!-- source: harness/.agents/skills/linear-issue-tracker/SKILL.md -->

## Where it fits

`thomas.md` reads the project's `issue-tracker.md` at session start → that file names this
adapter → the frontier is `list_issues` with no assignee, a non-terminal state and no unfinished
`blockedBy` → `dispatch-ticket` claims the winner with `assignee: "me"`, and `git worktree add -b`
decides any same-second race → merge moves the ticket to `Done` and whatever it unblocked to
`Todo` → `reconcile-tracker` measures the result against git. Its siblings are
`github-issue-tracker` and `jira-issue-tracker`, and `.agents/tracker-contract.md` sits above all
three.
