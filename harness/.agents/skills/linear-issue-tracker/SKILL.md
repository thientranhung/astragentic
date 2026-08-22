---
name: linear-issue-tracker
description: Operating mechanics for a project whose tracker is Linear — native states and relations, the claim protocol where assignee cannot hold a Builder identity, wayfinding primitives, and the free-tier issue ceiling that stops a pipeline outright. Load it when the project's docs/agents/issue-tracker.md names Linear. Read tracker-contract.md for what the pipeline requires of any tracker.
---

# Tracker adapter: Linear

**Measured on etsy-fulfillment-thanh, which ran Linear until 2026-08-21.** What the pipeline
requires of *any* tracker is `.agents/tracker-contract.md`; this file is the HOW for one of them.

**The project half stays in the project.** Workspace, team key, project id and the ticket prefix
live in the project's `docs/agents/issue-tracker.md`.

Reach it through the **`linear-server` MCP tools**. Do not shell out to a CLI.

## Read this before choosing Linear

**The free tier stops accepting new issues.** `save_issue` returns
`"You've exceeded the free issue limit"`, and that does not degrade a pipeline — it **stops**
one, because the first step of the method is `create`. A project hit this and had to migrate the
same day.

Requirements 1–5 are about a tracker's *model*. A tracker also has to accept a write. **Check the
ceiling of the tier you are on before building a pipeline on it.**

That aside, Linear is the shape the other two adapters approximate: native workflow states, a
real status field, a board that follows it with no second write, native relations, native
assignee. All five requirements met by the product, which is why this adapter is the thin one.

## Conventions

- **Create** — `save_issue` with `team`, `project`, `title`, markdown `description`. Omit `id`.
- **Read** — `get_issue` with the identifier, then `list_comments` for the discussion.
- **List** — `list_issues` filtered by `team`, `project`, `state`, `label`, `assignee`.
- **Comment** — `save_comment` with `issueId`.
- **Labels / state / relations** — all `save_issue`: the `labels` array, `state`, `blockedBy`.
- **Close** — move to `Done`, or `Canceled` for won't-fix. **Linear has no separate close verb.**
- **Search** — `list_issues` with `query`. `search_documentation` is Linear's own product docs,
  not your issues.

States are `Backlog` → `Todo` → `In Progress` → `In Review` → `Done`, plus `Canceled` and
`Duplicate` as terminal. Map the method's language onto them: "open" = anything not
`Done`/`Canceled`/`Duplicate`; "in flight" = `In Progress` or `In Review`.

## `Todo` is the frontier materialised — do not skip it

The frontier query computes who is ready, and **that computation must be written back as state**.
`Todo` is where it goes.

| state | means |
|---|---|
| `Backlog` | blocked, or not yet shaped |
| `Todo` | every blocker closed; claimable now; nobody holds it |
| `In Progress` | a Builder holds it — worktree, branch and pane all exist |

An agent never needs `Todo` — it re-derives readiness from `blockedBy` on demand, which is
exactly why an agent will not notice the state missing. The owner re-derives nothing. Measured on
one workspace: **zero issues had ever entered `Todo`**, and a ticket sat in `Backlog` for hours
after both its blockers merged.

**When a merge unblocks something, move it to `Todo` in the same breath as closing the ticket
that unblocked it.**

## Two things the relation graph cannot tell you

1. **Blocking is not inherited from the parent.** A sub-issue with zero `blockedBy` reads READY
   even when its parent epic is blocked — three tickets surfaced as claimable during an earlier
   phase exactly this way. Filter on parent status too, or draw the edges explicitly.
2. **A blocker that is not an issue is invisible, and the graph lies confidently.** One ticket
   reported READY to every query while waiting on a deployed server — and a server is not a
   Linear entity. Give the invisible thing a ticket and draw the edge. An absent blocker is worse
   than a wrong one: nothing on the board contradicts it.

## The claim protocol is WEAKER here, and git is what carries it

The method writes the assignee as a Builder identity (`builder/<ticket-id>`). **Linear cannot
hold that** — `assignee` resolves to a real workspace member. On a workspace with one human, every
dispatcher writes the same assignee.

- **The claim** is `assignee: "me"`. That is what removes the ticket from the frontier.
- **The frontier query** is `list_issues` with `assignee: null`, state not terminal, dropping
  anything with an unfinished `blockedBy`.
- **The Builder identity** goes in the dispatch record and as a comment, since no field holds it.
- **The readback interlock is weakened; the git one is not.** A readback cannot tell whose claim
  it read, so `git worktree add -b <ticket-branch>` failing is the *only* thing that decides a
  same-second race. Losing it means leaving the assignee exactly as you found it.
- **Releasing a claim**: "clear only when a fresh readback shows your own" cannot be evaluated
  here. Confirm the branch and worktree are gone instead — the worktree, not the tracker, is what
  says a Builder is still live.

**So concurrency on a single-seat workspace rests entirely on git.** If it grows past a couple of
panes, the fix is one Linear seat per Builder identity, not a looser protocol.

## Wayfinding has first-class primitives — do not emulate the GitHub workaround

- **Map** — a Linear project **document** (`save_document`) holding the Notes / Decisions-so-far /
  Fog body. One per effort.
- **Child ticket** — a normal issue with the map document linked from its description; a label
  carries the ticket type.
- **Blocking** — native relations via `save_issue`. Unblocked when every blocker is `Done` or
  `Canceled`.
- **Claim** — `save_issue` setting `assignee: "me"` and state `In Progress`, as the session's
  first write.
- **Resolve** — comment the answer, move to `Done`, append a pointer to the map's
  Decisions-so-far.

## Linear's own agent-skill shelf

`list_agent_skills` / `get_agent_skill` expose a workspace-level skill store. **The MCP surface is
read-only** — there is no `create_agent_skill`, so those are authored by the owner in Linear's UI.

Worth knowing what it would buy: a skill defined there travels with the **tracker**, so any agent
touching the workspace reads it, including agents with no checkout. This adapter travels with the
harness instead. Neither replaces the other.

## What the project's `issue-tracker.md` must carry

Workspace · team name and key · project name and id · the ticket prefix · any id ambiguity from
its own history · the PR-as-request-surface decision · which seats exist, since the claim
protocol depends on it.
