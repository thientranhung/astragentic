---
term: Frontier
oneLiner: "Every ticket whose blockers are all done and whose assignee is empty — the query that answers what's ready to dispatch."
order: 4
related: [tracker, claim, blocking-edge]
diagram: frontier-query
updated: 2026-09-04
---

**The frontier is every ticket whose blockers are all done and whose assignee is empty — the answer to "what's ready to work on right now."**

Thomas's role contract defines it in exactly those terms, and runs the query at session start and again whenever a ticket closes. It isn't something a Builder or the owner computes ad hoc from memory; it's a live read over the [tracker](/dictionary/tracker), driven by [blocking-edge](/dictionary/blocking-edge) state, and Thomas's contract is explicit that the frontier is one of the three things (alongside the [claim](/dictionary/claim) and merge) that isn't packaged as a skill — it's a judgement he applies every session, because the raw edge-based rule alone is over-inclusive. A live project measured this directly: computing the frontier purely from blocking edges surfaced epics, a phase whose parent hadn't started, and a ticket explicitly marked deferred, all as "ready." Parent/child sequencing carries information a blocking-edge rule can't see on its own.

The other half of the concept is that a frontier only computed and never written down is invisible to the person who can't run the query themselves — the owner. So Thomas writes the answer back to the tracker's claimable-and-unclaimed state after every computation, rather than holding it in his head. RELEASE-NOTES.md names this failure directly: `thomas.md` originally defined the frontier as a query and never said to write the answer back, which is exactly the gap `tracker-frontier-audit` now checks for.

## Why it matters here

Querying the frontier fresh every time instead of trusting a cached "ready" label costs a real read against the tracker every session and at every ticket close — and it still isn't fully mechanical, since Thomas has to apply judgement over what the raw query returns. The payoff is that "ready" never silently goes stale the way a static label does: a spec's tickets, for instance, only become claimable after Thomas classifies `arm: spec` — the readiness label a ticket was created with is never re-read as truth.

## Seen in:

- `harness/.agents/roles/thomas.md` — "## The frontier"
- `harness/.agents/skills/reconcile-tracker/SKILL.md` — the over-inclusive-promotion finding
- `RELEASE-NOTES.md` — "A frontier that is only computed is invisible to the person who cannot compute it," `tracker-frontier-audit`

## Usage:

"Why isn't ticket 214 in the frontier yet?" — "Its blocker just closed but nobody re-ran the query — Thomas does that at session start and at every merge, not continuously."
