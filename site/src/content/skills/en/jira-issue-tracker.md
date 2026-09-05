---
title: jira-issue-tracker
oneLiner: "Drive Jira as the harness tracker, where a status is a numbered transition you must read before you take it."
group: adapter
order: 5
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/jira-issue-tracker/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

`jira-issue-tracker` is one of three tracker adapters. `.agents/tracker-contract.md` states the
five things the pipeline requires of any tracker; this file is the HOW for Jira — status as
transitions, the two coordinates a session cannot discover, issue links and their invertible
direction, whole-field description writes, and what only a human can change. The project half
stays in the project: the site, the `cloudId`, the project key and the transition-id table live
in that project's `docs/agents/issue-tracker.md`. Jira is reached through the Atlassian MCP
tools. Everything here was measured on a live team-managed project that moved from Linear to
Jira on 2026-08-21.
<!-- source: harness/.agents/skills/jira-issue-tracker/SKILL.md -->

The single biggest difference from every other tracker is that **you do not assign a status, you
take a transition** — and transitions are identified by numeric ids that are project-specific,
non-sequential and not guessable, with states added later taking low ids. So a remembered
transition id is a valid write to a state you did not mean: it succeeds, nothing errors, and no
query flags it. Read the transitions every time; the extra call *is* the guard, and it is cheaper
than the class of bug it prevents. Jira's compensating advantage is real: `Blocks` is expressible
in one JQL query, so the frontier is one call rather than the N+1 loop GitHub forces.
<!-- source: harness/.agents/skills/jira-issue-tracker/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| The project's `issue-tracker.md` names Jira | `Skill(skill: "jira-issue-tracker")`, and only that one |
| A status change | `getTransitionsForJiraIssue`, then `transitionJiraIssue` with an id from *that* response |
| A description to patch | Read it, substitute, send the whole field back — there is no partial update |
| A state the project does not have | Stop; adding one is an owner action in the Jira UI, and the MCP tools cannot touch a workflow |
| A duplicate | A `Duplicate` link plus the cancelled state, never a status of its own |

<!-- source: harness/.agents/skills/jira-issue-tracker/SKILL.md -->

## Prerequisites

- **The `cloudId` is written down.** It appears in no URL a human pastes, so without it every
  session starts by hunting for it through `getAccessibleAtlassianResources`.
- **The project key is quoted in JQL.** A key that is also a JQL word makes `project = <KEY>`
  fail to parse, and the error does not say to quote it.
- **You know whether the project is team-managed or company-managed**, because that decides
  whether the statuses *are* the board or map to it.
- **The accountId used for the claim is resolved once** with `lookupJiraAccountId` and then
  carried in the project's `issue-tracker.md`.

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The claim | The `assignee` field, set to your own accountId |
| The Builder identity | `.astraler/state/dispatch-record.json`, because `assignee` takes an accountId and cannot hold `builder/<ticket-id>` |
| The frontier | A single JQL query: unassigned, not done, minus anything with an unfinished `is blocked by` link |
| The blocking graph | Native issue links, whose rendered wording is the thing to read back |
| Migration provenance | A provenance label and a first description line pointing back, neither of which is ever stripped |

<!-- source: harness/.agents/skills/jira-issue-tracker/SKILL.md -->

## Known failures

Pulled from `harness/.agents/memory/recurring-failure-modes.md`. Both are marked `promoted`.

- **AST-057**: a frontier that is only computed is invisible to the one person who cannot
  compute. The readiness state exists for the human, and an agent will not notice it missing
  because it re-derives readiness on demand. Fixed in the contract: write the computed answer
  back as state, in the same action that closes the last blocker, and never read a readiness
  label as a blocker. Readiness plus an open `is blocked by` link is a contradiction, so move the
  ticket back in the same breath as adding the link.
- **AST-074**: a tracker measured only against itself cannot detect its own drift — four tickets
  claimed and in-progress after their code had merged, nothing errored, and the drift lived in
  the tracker's content where no reachability check can see it. Fixed: `reconcile-tracker`
  measures the tracker against git, and it is read-only by a recorded ruling, because the join
  key is a ticket id in a commit subject and a citation is not a completion.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- Every transition id came from a fresh `getTransitionsForJiraIssue`, never from a table or from
  memory.
- Every new link was verified by reading the **rendered wording** back, so a backwards `Blocks`
  cannot corrupt the frontier silently.
- No description was retyped from memory, and every JSON payload was built programmatically.
- `Relates` links were kept out; a mention in the body carries the same information where it is
  readable.
- A blocker that is not an issue was given an issue — a decision ticket is first-class, is never
  dispatched to an agent, and closes when the owner answers.

<!-- source: harness/.agents/skills/jira-issue-tracker/SKILL.md -->

## Where it fits

`thomas.md` reads the project's `issue-tracker.md` at session start → that file names this
adapter → the frontier is one JQL query → `dispatch-ticket` claims the winner by setting the
assignee, then git decides any same-second race → merge takes the Done transition and moves
whatever it unblocked into the readiness state → `reconcile-tracker` measures the result against
git. Its siblings are `github-issue-tracker` and `linear-issue-tracker`, and
`.agents/tracker-contract.md` sits above all three.
