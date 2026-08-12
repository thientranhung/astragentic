---
name: tracker-frontier-audit
description: Audit a tracker for the ways it answers READY with confidence about things it cannot represent — an unmaterialised frontier, preconditions that are not issues, and parent blocking a tracker does not inherit. Reports and proposes exact writes; never mass-edits. Use when a board "looks wrong" to the owner, when onboarding a repo onto the harness, or after a run of merges.
---

# Audit a tracker's frontier

**The frontier query answers confidently about things the tracker has no way to say.** That is
the one law here, and the three checks below are its instances. Each fails the same way: no
entity contradicts the answer, so the query is not merely wrong — it is *unopposed*. **An
absent edge beats a wrong edge.**

**And the failure is asymmetric, which is why it survives.** An agent treats the frontier as a
QUERY and re-runs it on demand, so it is never wrong for long and never notices anything
missing. The owner cannot re-run anything: he opens the board and looks. A board can therefore
be useless to the human while serving every agent perfectly, and nobody is positioned to
notice. Measured on one project, 2026-08-12: **zero issues had ever entered the unstarted
state** across the project's whole life, and one ticket sat blocked-looking for hours after
both its blockers merged. The owner found it by eye, comparing two boards.

**Report first. Never apply writes without the owner's word** — the board is his, and a bulk
state change is hard to walk back.

## Run it against any project

Resolve the team and project from the repo's own `docs/agents/issue-tracker.md`, or from the
tracker's own project list. Do not assume: two projects can share a workflow-state set and
differ only in how they use it, which is exactly what this skill exists to find.

### Check 1 — is the frontier materialised, or only computed?

Count issues that have **ever** entered the unstarted state, not issues sitting there now. A
project can be at zero right now and be healthy, because everything ready was just claimed —
so read state history on a sample rather than a current count.

| finding | verdict |
|---|---|
| never any unstarted state, while the backlog holds issues whose blockers are all done | **AFFECTED** — dispatch jumps backlog → in-progress |
| the state exists but is stale: open blockers sitting in it, or unblocked work still in backlog | **PARTIALLY** |
| it tracks unblocked-and-unclaimed | **NOT AFFECTED** — say so and move on |

### Check 2 — preconditions that are not issues

**This is the one worth the audit.** A precondition with no entity on the tracker is invisible,
so the query reports READY at full confidence.

For every issue the frontier calls ready, read the description and ask whether the prose names
a real precondition that no blocking edge represents. The recurring shapes: a deployed server
or environment; credentials, an account, or third-party approval; a release the team does not
control; a decision only a person can make.

Report each as: id, what it actually waits on, and whether any entity represents that thing.

### Check 3 — parent blocking is not inherited

Trackers generally do not propagate blocking from a parent to its children, so a sub-issue with
zero blockers reads READY while its parent epic is blocked. Confirm the behaviour for the
tracker in front of you rather than assuming it — then find every issue whose own blockers are
clear but whose parent or grandparent is blocked, or belongs to a phase that has not started.

## Output

Under 50 lines. No issue descriptions pasted back. Per check: **AFFECTED / PARTIALLY / NOT
AFFECTED**, with the concrete evidence.

Then the fix as a numbered list of the exact writes you WOULD make — `id → new state`,
`id → new blocking edge`, or `create an issue representing X` — and stop.

**Where a fix means inventing a ticket for something that is not code work, say so plainly.**
That ticket exists to make a real constraint visible; it must never be dispatched to an agent.
Label it for a human and leave it out of the frontier.

## Why this recurs, and what the package can and cannot fix

`mattpocock-skills:to-tickets` draws the blocking edges and, at the same moment, writes
`Status: ready-for-agent` — a **label**, applied once at creation. It sets no workflow state,
and nothing revisits the label when a blocker is later added or cleared. Two representations of
readiness end up side by side, and neither answers what a dispatcher asks:

| | means | written |
|---|---|---|
| label `ready-for-agent` | shaped well enough to hand over | at creation, then never again |
| unstarted state | no open blockers, unclaimed | not at all |

**That skill belongs to the plugin, so this package cannot fix it** — 1.0.0 exists to stop
vendoring the plugin's skills, and a patched copy here would be a second home for one fact. Two
things follow, and both are already in place: the frontier query **never reads the label**
(`thomas.md`), and this audit is the compensating control.

**Fixing a board once is worth little** — it drifts back within a day of merging. The mechanism
is the **frontier write-back**: Thomas's merge step moves every ticket that merge unblocked and
reports which ones moved. This audit is its backstop, so read every check above as one question —
*which merges skipped the write-back, and what did that hide?* Where a project maps the states
in its own `docs/agents/issue-tracker.md`, read that mapping first; the board is the human's
only interface to the frontier.
