---
title: reconcile-tracker
oneLiner: "Measure the tracker against git and report the four drift classes between them."
group: upkeep
order: 1
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/reconcile-tracker/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

`reconcile-tracker` pulls two independent facts and compares them: what the tracker says a
ticket's state is, and what git actually shows happened to that ticket.

The git half comes from `scripts/ticket-git-facts.sh` (pure shell, no network, no tracker call).
That script counts commits on the base branch whose subject matches a ticket id, finds the local
branch if one still exists, and reports the unmerged count. The tracker half comes from whatever
read tool the project's tracker exposes.

Thomas joins the two rows by hand, because the join needs judgement a script cannot supply, and
reports four drift classes:

- **Lagging.** Merged but the tracker never heard.
- **Phantom done.** Tracker says shipped, git shows nothing.
- **Stale claim.** An assignee with no branch behind it.
- **Unclaimed in-progress.** A ticket stuck in the working state with no one holding it.

This skill never writes to the tracker, it only reports.
<!-- source: harness/.agents/skills/reconcile-tracker/SKILL.md -->

The failure this skill is built against is specific: a tracker checked only against itself.
In-progress with a live assignee looks exactly the same whether the ticket is genuinely in
flight or whether the merge that finished it was never written back.

The state is internally consistent either way, so the tracker alone cannot tell you which one you
are looking at. Git is the second, independent source that breaks the tie, the same way a test's
expected value has to live outside the code it is checking.

The skill exists because a live project measured this directly: four tickets sat in-progress with
a live assignee after their code had already merged, the oldest by a full day, and nothing in the
pipeline ever errored to say so.
<!-- source: harness/.agents/skills/reconcile-tracker/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A merge just landed | Run it immediately, because this is where drift is born, and the merge step already requires re-running the frontier and reporting what moved |
| A new session is starting | Run it to catch whatever the previous session left mid-dispatch |
| The owner asks "is the tracker accurate?" | Run it. The answer has to be measured, never recalled |
<!-- source: harness/.agents/skills/reconcile-tracker/SKILL.md -->

## Prerequisites

`TICKET_PREFIX` has to be set. It has no default, and a bare `[A-Z]+-[0-9]+` sweep catches ADR
ids and spec ids along with real tickets. Read that value from the project's session-start
instructions (`AGENTS.md` / `CLAUDE.md`), and an unset value is a stop rather than a guess. Pull
the tracker's ticket ids first, then pass them to the script explicitly. The bare form of
`ticket-git-facts.sh` derives its list from subjects already on the base branch, so a ticket that
has never merged does not appear at all, and those in-flight tickets are exactly what the
stale-claim class is checking for. Which tracker adapter is in play (`github-issue-tracker`,
`jira-issue-tracker`, or `linear-issue-tracker`) decides how the tracker half gets read, but
`reconcile-tracker` itself is tracker-agnostic, because it only needs `id`, `status` and
`assignee`.
<!-- source: harness/.agents/skills/reconcile-tracker/SKILL.md -->

## Known failures

- **Self-comparison hid the drift.** A tracker measured only against itself cannot detect its own drift. Four tickets
  sat in-progress with a live assignee after their code had already merged, and nothing errored,
  because in-progress with an assignee is indistinguishable from a real in-flight ticket without
  a second source. The shipped fix is `reconcile-tracker` itself plus `ticket-git-facts.sh`,
  deliberately read-only so a wrong-but-tidy tracker never gets marked done on a fuzzy join key.
  <!-- source: harness/.agents/memory/recurring-failure-modes.md -->
- **The doc's own example was wrong.** The runnable example in this skill's own doc called `ticket-git-facts.sh` without
  `TICKET_PREFIX` and labelled it "ALWAYS this form," eight lines above the sentence saying the
  variable is required, a command the script itself refuses. Fixed 2026-08-20. An earlier note
  blaming an adapted project for copying the bad example was itself wrong and was corrected in
  the same entry. <!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- Every run states `TICKET_PREFIX` explicitly rather than falling back to a guess.
- The tracker's ids are pulled before `ticket-git-facts.sh` runs, not after.
- Every one of the four drift classes gets reported, including `none` for the ones that are
  empty. An unreported class reads identically to an unchecked one.
- A healthy in-flight ticket, meaning unmerged commits, a live branch and a worktree, is never
  flagged as drift.
- Nothing gets written to the tracker as a result of this skill's own run. Every fix is a
  separate, later action Thomas takes by hand.
<!-- source: harness/.agents/skills/reconcile-tracker/SKILL.md -->

## Where it fits

`dispatch-ticket` claims a ticket and hands it to a Builder → the merge step re-runs the frontier
and writes back what moved → `reconcile-tracker` checks, right after that merge and again at
session start, that the write-back actually happened. The tracker being read
(`github-issue-tracker`, `jira-issue-tracker`, or `linear-issue-tracker`) supplies the HOW for
one specific product, while `reconcile-tracker` is the check that runs the same way regardless of
which one is in play. Where it finds phantom done or a stale claim, that becomes Thomas's own
fix, applied by hand, outside the skill's run.
