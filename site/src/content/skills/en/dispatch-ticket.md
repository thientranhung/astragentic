---
title: dispatch-ticket
oneLiner: "Hand one ready ticket to one Builder in its own worktree."
group: main-flow
order: 1
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/dispatch-ticket/SKILL.md
rented: false
diagram: ticket-lifecycle
lang: en
updated: 2026-09-04
---

## What it does

`dispatch-ticket` is the sequence Thomas runs every time a ticket goes from "claimable" to "a
Builder is actually working on it." Nine steps, always in that order:

- **Preflight** on the session's first dispatch: watchdog running, payload committed.
- **Resolve the orchestrator row**: runtime, model, effort, and the write-set.
- **Claim the ticket, then cut the branch and worktree**, in that order.
- **Open a Herdr tab and pane**, gated on `foreground_cwd`.
- **Print the resolved dispatch**, then launch through the runtime's own skill.
- **Hand over the brief**, its first line the phase's slash command.
- **Arm the watcher right after submitting**: those are one action, not two.
- **Branch on the watcher's exit status**, never on pane status alone.
- **Verify by artifact**, then clean up.

A step nobody checks is a step that gets skipped silently, and this harness runs several of these
sequences in parallel, so silently here means a Builder idle in a pane nobody is watching.
<!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->

What is different about it is where the boundary sits: **the claim happens before the worktree
exists.** A ticket gets assigned on the tracker first, so two Thomas sessions picking off the same
frontier see each other's claims instead of racing to create the same branch. The problem behind
this rule was two sessions sharing one checkout and silently losing commits to a concurrent
`git switch`. One worktree per session is the fix, and that isolation covers every command that
writes to disk, not only git. <!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A ticket on the frontier with an empty assignee | `dispatch-ticket` (claim, then worktree) |
| The dispatch itself, once claimed | `dispatch-ticket` + the runtime-specific companion (`dispatch-ticket-claude`, `-codex`, `-opencode`) |
| A Shaper, QA or Rin needs a pane, not just a Builder | Same skill, same mechanics; only the tab and pane label prefix changes |
| A pane went idle or blocked mid-turn | `WATCHING.md` (companion reference, not a separate skill) |
| The Builder handed back and it is time to remove the worktree | `CLEANUP.md` (companion reference) |

<!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->

## Prerequisites

- The workspace watchdog is running for this project. A dispatch with no watchdog is a hard
  stop, not a warning (`exit 1`, not an `echo`).
  <!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->
- The harness payload is committed, not just allow-listed past `.gitignore`. A worktree only
  contains tracked content, so an untracked `.agents/roles/builder.md` means the Builder starts
  with no contract at all. <!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->
- `.agents/orchestrator.md` has a real row (runtime, model, effort) for the role being
  dispatched. A row reading `<set-me>` is undecided, and undecided is a stop at dispatch time.
  <!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->
- Read the contract for the dispatched role first (`builder.md` for a Builder), since this skill
  only carries the mechanics, not what the role is supposed to do with them.
  <!-- source: harness/.agents/roles/builder.md -->

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The claim | The tracker's assignee field: `builder/<ticket-id>` |
| The dispatch itself | `.astraler/state/dispatch-record.json`, keyed by ticket id: branch, worktree, workspace, tab, pane, runtime, write-set |
| The worktree and branch | `<repo-root>/.claude/worktrees/<branch-slug>`, gitignored, removed at cleanup |
| The brief | Sent as the first line, a plugin-qualified slash command (`/mattpocock-skills:implement <ticket>`) |
| The Builder's own work | Commits on the ticket branch, pushed before handback |

<!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->

## Known failures

Pulled from `harness/.agents/memory/recurring-failure-modes.md`. Everything below is marked
`promoted`: fixed and already in the contract this page describes.

- **AST-016 / AST-027**: two root sessions sharing one checkout silently lost commits to a
  concurrent `git switch`. Fixed: one worktree per session, no exceptions.
- **AST-036**: a harness allow-listed but not committed is invisible inside every Builder
  worktree. Fixed: a commit check before the first dispatch.
- **AST-032 / AST-037**: a multi-line brief pastes into the composer without submitting, and the
  pane reports `idle` while it sits unsent. Fixed: an explicit Enter after the paste, plus
  requiring the watcher to observe `working` before believing the turn began.
- **AST-097**: `TERMINAL:done` means the turn ended, not that the work finished; a Builder
  parked on background work reads as done. Fixed: check OS processes and the runtime status line
  before concluding it finished.
- **AST-124**: the per-turn watcher covers one turn and exits; nothing re-arms it, and the
  re-arm is the step skipped right after a long task. Fixed: every new turn gets a new watcher.
- **AST-092**: a Builder that stops before committing leaves work that only exists on disk;
  `git worktree remove` deletes it silently. Fixed: "commit, push, then return" as three
  separate actions.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- The watchdog was confirmed running before the first dispatch of the session, not assumed.
- `.astraler/state/dispatch-record.json` has an entry for every live ticket, with a write-set.
- Every submitted brief has a watcher armed against it within the same action, not as a separate
  step done afterwards.
- A pane's tab and pane labels match the role dispatched (`builder:<id>` versus `spec:<id>`,
  `qa:<id>`, `rin:<id>`), because a wrong prefix is invisible to the watchdog.
- Cleanup only removes a worktree after `git status --short` is empty and
  `check-simplify-markers.sh` is green.

<!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md, CLEANUP.md -->

## Where it fits

The frontier query (in `thomas.md`) decides which ticket is next → `dispatch-ticket` claims it
and puts a `builder` role into a pane → the Builder runs its own closed loop (`implement` →
review → simplify → `/skills/codex-arm`) and hands back → `dispatch-ticket`'s `CLEANUP.md`
retires the worktree once the artifact is verified → a milestone gate goes through
`/skills/review-with-rin` before merge. `thomas` and `builder` are the two role contracts this
skill sits between.
