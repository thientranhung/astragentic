---
term: Tracker
oneLiner: "The issue tracker a project already runs, treated as the one place ticket state actually lives."
order: 3
related: [frontier, claim, blocking-edge, ledger]
updated: 2026-09-04
---

**The tracker is the project's own issue tracker — GitHub Issues, Jira, or Linear — and the harness treats it as the single source of truth for ticket state instead of inventing its own.**

The harness doesn't ship a tracker; it ships adapters that describe how to drive the one a project already has. `harness/.agents/skills/github-issue-tracker/SKILL.md`, `jira-issue-tracker/SKILL.md`, and `linear-issue-tracker/SKILL.md` each carry the operating mechanics for one backend: how status is represented, how the [claim](/dictionary/claim/) is written, how a [blocking-edge](/dictionary/blocking-edge/) is expressed. What every adapter has to provide is fixed by `.agents/tracker-contract.md` — the "five things the pipeline needs of any tracker" — so Thomas can read `docs/agents/issue-tracker.md`, find out which adapter a project uses, and drive it the same way regardless of backend. GitHub Issues, for instance, has no native status field, so status lives in a label — `backlog`, `todo`, or `in-progress` — with the label as truth and a Project board column as a mirror somebody has to keep in sync.

Because the tracker is the coordination substrate rather than a passive record, it's also the thing that can drift from reality — a ticket can say `in-progress` with a live assignee long after its branch already merged. That's what `reconcile-tracker` exists to catch: it measures the tracker against git, never against itself, because a wrong tracker state is perfectly self-consistent and only an independent oracle can catch it.

## Why it matters here

Adopting the project's existing tracker instead of a purpose-built one means the harness inherits every one of that tracker's limitations — no tracker's assignee field was designed to hold `builder/<ticket-id>` as a claim marker, and GitHub Issues genuinely has no status field at all. The cost is that every adapter carries its own workarounds and its own measured traps (`github-issue-tracker/SKILL.md` opens by naming a project that moved Linear to GitHub and hit every one of them). The upside is that nobody has to migrate their existing backlog into a new system to use the harness.

## Seen in:

- `harness/.agents/skills/github-issue-tracker/SKILL.md`, `jira-issue-tracker/SKILL.md`, `linear-issue-tracker/SKILL.md`
- `harness/.agents/skills/reconcile-tracker/SKILL.md`
- `docs/adr/0001-rebuild-the-method-around-matt-pocock-skills.md` — "the tracker is the coordination substrate"
- `RELEASE-NOTES.md` (2.8.0) — the tracker write-back and `tracker-state.sh` plug

## Usage:

"Which adapter is this repo on?" — "Check `docs/agents/issue-tracker.md` first, don't guess — GitHub, Jira and Linear each carry the claim differently."
