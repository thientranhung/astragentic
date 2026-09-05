---
term: Claim
oneLiner: "Assigning a ticket on the tracker before its worktree exists — the one atomic act that keeps two agents off the same work."
order: 5
related: [tracker, frontier, worktree]
diagram: ticket-states
updated: 2026-09-04
---

**The claim is assigning a ticket to an agent on the tracker, and it happens before that ticket's worktree is created.**

Thomas's role contract states the ordering directly: "assigning a ticket is the claim, and it happens before its worktree exists." That ordering is what makes concurrency work at all — two sessions picking off the same [frontier](/dictionary/frontier) see each other's claims on the tracker itself, rather than discovering a collision only after both have started writing code. `dispatch-ticket/SKILL.md` puts the whole chain as one identity: ticket → assignee (the claim) → pane → worktree → branch → PR, each link one-to-one. The claim isn't the whole safety mechanism, though — Thomas's contract also notes a blocking edge expresses order, not exclusion, so two unordered tickets can still be unsafe to run together; the write-set collected during dispatch is what actually makes concurrency safe rather than merely parallel.

A claim can also go stale: the tracker shows an assignee with no branch behind it, which looks identical to a Builder mid-ticket. `reconcile-tracker` catches that gap by measuring the tracker against git rather than against itself. Every tracker adapter has its own weak point here too — no tracker's assignee field was built to hold a value like `builder/<ticket-id>`, and RELEASE-NOTES.md records GitHub Issues claiming "Requirement 3 is met natively" while its assign command silently dropped the field.

## Why it matters here

Claiming before the worktree exists costs an extra tracker write on every dispatch, and it only works if every session actually reads the ticket back afterward to confirm the assignee shown is its own — Thomas's contract calls this out explicitly, since a readback interlock can't otherwise tell whose claim it's looking at. The payoff is that several Builders can work the frontier at once without a lock file, a queue, or a central dispatcher deciding who goes first — the tracker itself is the lock.

## Seen in:

- `harness/.agents/roles/thomas.md` — "## The claim protocol", "## Releasing a claim"
- `harness/.agents/skills/dispatch-ticket/SKILL.md` — "Claim, then create branch and worktree"
- `harness/.agents/skills/reconcile-tracker/SKILL.md` — stale-claim detection
- `RELEASE-NOTES.md` — "Requirement 3 is met by no tracker, and two adapters said otherwise"

## Usage:

"Can I just start on ticket 88, I already know what it needs?" — "Claim it first — if you write code before the tracker shows your name on it, someone else can pick it up too."
