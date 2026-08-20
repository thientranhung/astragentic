---
name: reconcile-tracker
description: Reconcile the tracker against git — detect tickets whose recorded state contradicts what actually merged, plus stale claims. Read-only; it reports drift and never writes to the tracker. Use at session start, immediately after every merge, and whenever the tracker's accuracy is in question.
---

# Reconcile the tracker against git

**The tracker is a claim. Git is evidence. This skill measures the distance.**

Thomas owns the tracker, so this is Thomas's check. It is **read-only by design** — see
"Why nothing here writes" before proposing to automate the fix.

## When it runs

| Moment | Why |
|---|---|
| **Immediately after every merge** | This is where drift is BORN. The merge step already requires re-running the frontier and reporting what moved; this is the check that proves the write-back actually happened. |
| **At session start** | Catches whatever the previous session left behind — including one that ended mid-dispatch. |
| On the owner asking whether the tracker is accurate | The answer must be measured, never recalled. |

A live project measured this the first time it wired the check in: four tickets sat
in-progress with a live assignee **after their code was on the base branch**, the oldest by a
full day. Nothing errored. The merge ran; the write-back did not; no artifact recorded the
omission. That is AST-057 — *a step nothing reports is one nobody can tell was skipped.*

## Why git is the oracle, and not the tracker itself

A wrong ticket state is **perfectly consistent with itself**. In-progress with an assignee and
no other evidence is exactly what a real in-flight ticket looks like; from inside the tracker
the two are indistinguishable. So a check that reads only the tracker can detect nothing.

**An oracle must be independent of what it measures.** Applied to the tracker, that means git —
the same law behind the standing rule that a test's expected value must never be derived from
the code under test, and that a parity or coverage denominator must come from an independent
enumeration, never from the thing being measured.

## The two halves, and why they are split

Neither half can do this alone, and pretending otherwise is how it breaks:

1. **Git facts** — `scripts/ticket-git-facts.sh`. Pure shell, no network, no tracker call.
   Emits TSV: subject-matched commit count on the base branch, newest such subject, local
   branch, unmerged commit count, worktree path.
2. **Tracker state** — pulled by the agent through the tracker's own read tools (per
   `docs/agents/issue-tracker.md`). Where the tracker has no token in the shell, this half
   genuinely cannot be scripted — say so explicitly rather than let the next session try.

You join them. The skill owns the join because the join needs judgement.

**Pull the tracker state FIRST, then pass its ids to the script.** Run in that order — the
bare form derives its ticket list from subjects on the base branch, so **a ticket that has
never merged does not appear at all**, and those are exactly the in-flight ones the
stale-claim class is about. A live project measured this on its first real run: a ticket
mid-flight with eleven unmerged commits was simply absent from the output. The gap is silent —
the script cannot report a ticket it was never told about.

```bash
TICKET_PREFIX=<prefix> scripts/ticket-git-facts.sh $(<tracker ids>)   # ALWAYS this form
TICKET_PREFIX=<prefix> scripts/ticket-git-facts.sh                    # merged tickets only — audit use, not reconcile
```

List the tracker with its lightest read call, and request only `id`, `status` and `assignee`
— the default payload on most trackers carries full descriptions and floods context. Then
compare row by row.

**`TICKET_PREFIX` has no default and is required.** A bare `[A-Z]+-[0-9]+` sweep also catches
ADR ids, spec ids and any other kebab-tagged history the repo carries — a live project's
first run returned a third noise on exactly this mistake. Read it from this project's
session-start instructions (`AGENTS.md` / `CLAUDE.md`), where adaptation records it; an unset
value is a STOP, not a guess.

## Matching is by commit SUBJECT, never the body

A live project measured a body grep for one ticket id returning commits that only *cited* it
in a handback — subject-only matching returned exactly the genuine set. The script already
does this; the rule is recorded here because anyone re-deriving the check by hand reaches for
a body grep first. Use `\b` so a shorter id never matches inside a longer one.

## The three drift classes

| Class | Signal | Meaning |
|---|---|---|
| **Lagging** | `subject_commits > 0`, no branch, tracker state not completed | merged but never written back. The common case, and the harmless-looking one. |
| **Phantom done** | tracker state completed, `subject_commits = 0` | **the dangerous direction.** The tracker says shipped; nothing shipped. Investigate before touching anything. |
| **Stale claim** | assignee set, no branch, no worktree | a claim with no Builder behind it. This blocks the ticket from ever being re-dispatched, because a live assignee must never be cleared by someone who does not own it. |

A ticket with `subject_commits = 0` **and** a branch with unmerged commits **and** a worktree
is not drift — that is a healthy in-flight ticket. Do not report it.

## Why nothing here writes

The join key is a ticket id in a commit subject, and **that key is not exact.** A commit
naming a ticket is not proof the ticket is finished: a partial fix, a revert, a review-pass
fold and a forward-citation all produce a hit. A live project's own first real run flagged a
phase ticket as "merged" on three commits that were spec work *naming* the phase without
completing it — the fuzzy-key failure arriving on the very first run, exactly where it is
cheapest to see and most tempting to wave off.

So auto-closing on this signal would eventually mark unfinished work done. That is the
**phantom-done** direction, and it is worse than lag in a specific way: a tracker that is
wrong and *messy* still invites suspicion, while a tracker that is wrong and *tidy* gets
believed — by the one reader who cannot re-run the frontier query, which is the owner.

**Report only; Thomas applies each fix by hand.** Do not let a tidy-looking automation absorb
this ruling — the join key stays approximate no matter how many drift classes get added.

## What stays Thomas's judgement, and is NOT a rule

- **Frontier promotion is over-inclusive if computed from blocking edges alone.** A live
  project measured this the same day: the raw rule returned claimable tickets that included
  epics, a phase whose parent had not started, a ticket explicitly marked deferred, and a
  production incident that wanted a priority rather than a queue position. Parent/child
  sequencing carries information the blocking-edge rule cannot see. Promotion stays a
  judgement, not a rule — see `## The frontier` in `thomas.md`.
- **A finding-ticket is not a build-ticket.** A ticket whose own body already carries its
  conclusion ("no fix required") needs a disposition from Thomas, not a Builder. Only a
  ticket that still names real work belongs in the claimable state.
- **Whether a phantom-done is a tracker error or a lost merge.** These look identical from the
  data and resolve completely differently — read the ticket and the commit before deciding.

## Delegate the fan-out — for context, not for judgement

Reading blocking edges across a full backlog means one read call per ticket, and most
trackers' payloads carry entire descriptions. A live project measured this costing tens of
thousands of tokens in-session for a few dozen tickets — precisely why it belongs in a
subagent. Dispatch a **read-only** agent, tell it to request only the fields it needs and to
quote no descriptions, and take back the conclusion. No new agent type is needed for this —
an existing read-only agent does the job.

That agent earns its place a second way: a fresh reader looking at the whole board at once can
see structure — like the parent/child sequencing above — that a row-by-row check cannot.
**It never writes to the tracker.** The fan-out is delegated; the ruling is not.

## Reporting

**This skill ends at the report — it writes nothing, ever, under any finding.** Report every
class, and report `none` explicitly where a class is empty; an unreported class is
indistinguishable from an unchecked one, which is the failure this whole skill exists to
catch.

Any fix is a **separate, later action**, outside this skill's own run, using the normal
tracker-write capability Thomas already has — never something this skill or its invocation
performs. If that later action changes the tracker, report what changed at that time, not
here.

## A tool that has never run is not evidence

Build it, commit it, then **run it against real data before trusting a line of it.** The
project this skill was adapted from did exactly that and the exercise failed three separate
ways on the first real run: a shell builtin the design assumed was portable was not, on the
platform actually in use; the id pattern above was not scoped and swept up unrelated ids; and
deriving the ticket list from the wrong side of the history made every unmerged ticket
invisible, silently. None of the three was visible from reading the script. Adopt this rule
with the tool, not as a footnote to it.
