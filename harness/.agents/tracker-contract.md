# The tracker contract — what the harness needs, and what each tracker charges for it

This is the layer **above** any one tracker: what the pipeline requires, so a project can be
wired to a tracker without re-deriving it, and so a move between trackers is a swap of one
adapter rather than a rewrite of the method.

**Three files, three jobs, and keeping them apart is the point:**

| | |
|---|---|
| this file | what the pipeline needs of ANY tracker |
| one adapter skill per tracker | the mechanics and traps of that tracker, identical for every project on it |
| the project's `docs/agents/issue-tracker.md` | which adapter to load, this project's coordinates and ids, its status map, its own decisions |

Three adapters ship. Load the one this project's `issue-tracker.md` names, and only that one:

| Tracker | Load |
|---|---|
| GitHub Issues | `Skill(skill: "github-issue-tracker")` |
| Jira | `Skill(skill: "jira-issue-tracker")` |
| Linear | `Skill(skill: "linear-issue-tracker")` |

A project writing tracker mechanics into its own `issue-tracker.md` is paying, alone, for a
trap another project already paid for. Two projects did exactly that on the same day.

> **Evidence.** GitHub is measured on **`etsy-fulfillment-thanh`**, which moved Linear → GitHub
> on 2026-08-21. Jira is measured on **`workspace-app-inception`**, which moved Linear → Jira
> (project `IN`) the same day. Linear is measured on `etsy-fulfillment-thanh`'s own pre-migration
> history. Where a claim is inference rather than measurement it says so inline.

## The five things the pipeline requires

`thomas.md` is the consumer. Strip it to what it touches and a tracker owes exactly five
things — nothing else in the method reads the tracker at all.

| # | Requirement | Who reads it | Breaks how, if missing |
|---|---|---|---|
| 1 | **A stable ticket id in the TITLE** | every doc, ledger, commit and code comment | citations across the repo stop resolving; the id cannot be re-minted after the fact |
| 2 | **A status with five states** — Backlog / Todo / In Progress / Done / Won't fix | the frontier query, the owner's board | the frontier cannot be derived; the owner cannot see the pipeline |
| 3 | **An assignee, written and read back atomically** | the claim protocol | two dispatchers claim one ticket and two Builders write one tree |
| 4 | **Every precondition as a queryable EDGE** | the frontier query | see below — the loudest failure of the five |
| 5 | **A surface the OWNER can open and read without running a query** | the owner | the pipeline becomes invisible to the one person who cannot query it |

**Requirement 5 is the one that gets dropped**, because every agent satisfies itself with
requirement 2 and never notices 5 is unmet. Measured on a GitHub project: the board
said `Backlog` on 68 of 71 items — three with live Builders — while every query the harness ran
was correct. Inception derived the same rule independently and states it better: *"`To Do`
exists for the HUMAN, and that is the whole point. An agent does not need it — it recomputes
what is ready whenever it wants, which is exactly why an agent will not notice the state
missing."*

**Requirement 4 says EDGE, and the word is load-bearing.** A precondition written as prose —
waiting on a decision, a credential, a third party, a deploy — is invisible to every frontier
query, so the ticket reads **READY with full confidence** and nothing on the board contradicts
it. That is worse than a wrong edge. Measured on inception, and its rule is the one to copy:
**a blocker that is not an issue does not exist** — create an entity for the real constraint
and link at it. A decision ticket is a first-class ticket that is never dispatched to an agent;
it closes when the owner answers.

**And edges fail the other way too, which is the half a project usually meets second.** Blocking
edges alone are *over*-inclusive: epics, unstarted phases and deferred tickets all pass a
blockers-are-closed test, and parent/child sequencing does not appear in them at all — a
sub-issue with zero blockers reads READY while its parent epic is blocked. Promotion to the
frontier stays the router's judgement, not a query result (`AST-074`, measured again on Linear
where three tickets surfaced as claimable during an earlier phase exactly this way).

Related, and cheap to enforce: **a ticket in the ready state with an open blocker link is a
contradiction.** Move it back in the same breath as adding the blocker.

## The question that decides everything: how many places does status live?

That is the whole difference between the three. Everything below follows from it.

| | Jira | GitHub | Linear |
|---|---|---|---|
| **Where status lives** | workflow status (1 field) | **labels + Project `Status` (2 fields, unsynced)** | workflow state (1 field) |
| **Writes per status change** | 1 write, **2 calls** — read the transitions, then take one | **2 writes — label AND board, always** | 1 |
| **How you write it** | by a **numeric transition id** that is project-specific, non-sequential and not guessable | set a value by name | set a value by name |
| **Set-up cost, once** | **high, and it is a HUMAN's** — states are added in the Jira UI and are invisible to the API until the workflow is published; the MCP tools cannot touch a workflow | low — create the labels | **none** — states ship with the team |
| **Owner's board** | native, follows the status | **separate object; follows nothing** | native, follows the state |
| **Blocking edges** | native issue links, **JQL-queryable in one query** | native dependencies — real, but no query language, so the frontier is a list call plus an N+1 loop | native relations |
| **Priority field** | yes | **none** — do not simulate it with labels | yes |
| **Opaque ids a session must be TOLD** | `cloudId` (in no URL a human pastes) + a project key that may need quoting in JQL | owner/repo, inferred from `git remote` | team key |
| **The trap** | a remembered transition id is a **valid write to a state you did not mean** | the two fields drift the moment one write is skipped | the free tier stops accepting new issues |

**One line for each:**

- **Jira** — the setup is a human's and the model then holds; what it charges is per-write
  indirection, forever.
- **GitHub** — cheap to start, and it charges you **on every status write, forever**. The label
  is truth; the board is a mirror nothing polishes.
- **Linear** — the cheapest to operate and the one that stopped letting us write.

## Per tracker

**The mechanics live in the adapters, and nowhere else.** This section used to restate them —
799 words repeating ten facts the three adapter skills already carry — and it drifted twice
while doing so: it retracted its own board-mapping claim as wrong for one project, and it
prescribed a script path this package does not ship, which no check could see because this
file was outside every checker's scope. `SPEC-1.0.0.md` forbids exactly this: **one home per
rule, everywhere else links.**

| Tracker | Adapter | What it charges you for, in one line |
|---|---|---|
| GitHub Issues | `Skill(skill: "github-issue-tracker")` | status is labels, so every state change is two writes; the board is a second write forever, and it takes part in no query |
| Jira | `Skill(skill: "jira-issue-tracker")` | status is a numbered transition, not a value; `description` is replaced whole; link direction is silently invertible |
| Linear | `Skill(skill: "linear-issue-tracker")` | native states and relations, and a free-tier issue ceiling that stops a pipeline rather than degrading it |

**Requirement 3 is met natively by none of them.** No tracker's assignee field can hold
`builder/<ticket-id>`, so on all three the readback interlock is advisory and `git worktree add
-b` is what decides a race. Each adapter carries that paragraph; the pipeline's safety claim is
stated honestly in `thomas.md`.

## Choosing one

Inception's rule, and it is the right first question:

> **Does the pipeline compute a frontier from dependency edges, or is the tracker a to-do list
> joined to PRs?**

- **Frontier-computing** → Jira has the advantage, because `Blocks` is expressible in **one JQL
  query** while GitHub needs an N+1 loop over candidates.
- **Otherwise, and the repo is on GitHub** → GitHub Issues + Projects, for one auth, one
  identity, and the native issue ↔ PR ↔ commit join that Jira only reaches through integration.

Both of us land on the tracker we are on, for these reasons rather than by inertia.

## Moving between trackers

Done twice now — this repo Linear → GitHub, inception Linear → Jira, both on 2026-08-21.

**Requirement 1 is what makes a move payable at all.** Every issue carried its id token in the
TITLE, so hundreds of commit messages, code comments, ledger entries and docs kept resolving
after the tracker changed underneath them. A tracker's own number (`#42`, `IN-54`) is a *second*
identifier that lives alongside the token, never a replacement.

Four things to expect, each of them measured:

- **Budget an ORACLE SCRIPT, not a review pass.** On inception's migration, **six subagents all
  reported success while three distinct corruptions had occurred** — two wrong-but-real ticket
  keys, silently stripped markup, a dropped Vietnamese word. None appeared in any report. A
  wrong-but-real key is invisible to a reader precisely because it resolves. Self-report is
  weak evidence even from an honest reporter, and the only
  thing that caught it was a purpose-built independent checker.
- **Only active work moves.** Completed tickets stay behind as an archive, so a blocker named in
  a body with no counterpart in the new tracker is **satisfied, not missing**. Reading it the
  other way freezes real frontier tickets in the direction nobody investigates.
- **Some losses are permanent.** Linear's attachments did not transfer to Jira — its image URLs
  are short-lived signed links — so image evidence on 63 tickets is gone. Decide what you are
  willing to lose *before* the move, not after.
- **Native edges are recreated by hand, and a wrong edge is worse than a missing one** — it
  withholds a ticket from the frontier and nothing ever reports it. Never create an edge you have
  not verified against the source.

**And nothing checks edges.** `reconcile-tracker` measures tracker state against git; no oracle
anywhere reads the blocking graph and asks whether it is TRUE. That gap is stated here rather
than left to be discovered, because the failure it produces is the confident kind: a ticket
reading READY to every query while the thing it waits on is not an issue at all, and nothing on
the board contradicting it.

**The cheapest partial oracle is the owner's eye, once per slice.** Print the frontier and the
blocking graph side by side at a slice close and read them together — an edge that surprises you
is the finding. It is not a check and this file does not pretend it is; it is the one review
that has ever caught this class.

## The one rule that outlives whichever tracker you pick

Inception's harness put it best, and it covers both projects' worst bug:

> **Find every place the tracker stores the same truth twice, and make the pipeline write both
> in one function.** Status is one field in Jira and two unsynced fields in GitHub — and in
> BOTH trackers, the readiness the board shows and the readiness the dependency edges imply are
> separate claims that nothing reconciles for you.

The second half is the one to sit with. A ticket marked ready with an open blocker link reads
READY to anyone trusting the board, on Jira and on GitHub alike. Move a ticket back out of the
ready state in the same breath as adding a blocker to it.
