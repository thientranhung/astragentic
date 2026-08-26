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

### Jira — the status is a transition, and the transition has a number

You do not assign a status. You ask which transitions are available from where the issue is
*now*, and take one:

```
getTransitionsForJiraIssue   → what is reachable from HERE
transitionJiraIssue          → take one, BY ITS NUMERIC ID
```

**Never remember a transition id.** They are project- and workflow-specific and **not
sequential**: three of inception's were added at migration and took low ids, so id order does
not follow state order. A hardcoded or remembered id is a **valid write to the wrong state** —
it succeeds, nothing errors, no query flags it. That is the structural twin of GitHub's skipped
second write: in both trackers the damaging failure is a **wrong-but-legal write**, not a
rejected one. Read the transitions every time; the extra call *is* the guard.

**Adding a state is an OWNER action, not an agent's.** New statuses are created in the Jira UI
and stay invisible to the API until the workflow is published — the MCP tools create, edit,
transition and link issues and cannot touch a workflow. A session that needs a state which does
not exist is **blocked on a human**, and must ask rather than improvise with labels. This is the
part of Jira's setup cost that matters to a contract; the older claim in this file — that a
status must be separately mapped to a board column — is a **company-managed** trait and was
wrong for inception's team-managed project, where the statuses *are* the board. What is real in
both flavours is which STATUS a ticket sits in: `Backlog` is not on the surface the owner reads,
`To Do` is.

Three more that cost a run each, all measured:

- **Link direction is silently invertible.** `createIssueLink`'s `inwardIssue`/`outwardIssue`
  order is genuinely confusing, and a backwards `Blocks` link corrupts the frontier without an
  error. **Create it, then read the issue back and check the rendered wording** — the payload
  you sent will not tell you.
- **`editJiraIssue` replaces `description` WHOLE.** There is no partial update; anything you do
  not send back is deleted. Read it, substitute, send the whole thing. An agent recomposing
  prose from memory drops words silently.
- **Build non-ASCII payloads programmatically.** Hand-typed JSON escapes corrupted `Ưu tiên`
  into `Ư u tiên`. This owner writes Vietnamese and the tickets are bilingual, so it is not an
  edge case. A plain-markdown GitHub body has no equivalent failure surface.

Duplication is carried as a **link**, not a status — strictly better, because it names *which*
ticket absorbed this one.

### GitHub — two fields, no sync, every time

**GitHub Issues has no status field at all.** Labels are the status, so the harness owns an
invariant the tracker will not enforce: **exactly one of `backlog` / `todo` / `in-progress`,
and changing status means removing the old label as well as adding the new one.**

It is not true that GitHub has no columns — GitHub *Projects* has a `Status` column and this
repo uses it. What is true, and costs more than the missing field, is that **nothing connects
the two.** Editing a label does not move the card; moving the card does not edit the label. So
every status write is two writes:

```bash
gh issue edit <n> --remove-label todo --add-label in-progress
.agents/skills/github-issue-tracker/project-status-sync.sh --apply   # the second half; skipping it is invisible
```

Skipping the second half fails **silently and in the owner's direction** — the queries stay
right, and only the human sees the lie. The board field also needs the `project`
OAuth scope, absent from `gh`'s default set, and without it `--json projectItems` returns `[]`
rather than an error — an emptiness that reads exactly like "this issue is on no board".

Dependencies are native and real, keyed by the blocker's numeric **database id** (not `#number`,
not `node_id`), and the read-back **lies for about two seconds** after the write. There is no
query language, so the frontier is a list call plus one API call per candidate. Full mechanics:
the `github-issue-tracker` skill.

### Linear — the shape the other two are approximating

Native workflow states, a first-class status field, the board following it with no second write,
native relations, native assignee. All five requirements met by the product, and the adapter is
thin.

**Both projects still had to leave it.** The free tier stopped accepting new issues —
`"You've exceeded the free issue limit"` — which does not degrade a pipeline, it **stops** one:
a harness that cannot cut a ticket cannot dispatch one.

The lesson generalises past Linear: **requirements 1–5 are about a tracker's model, but a
tracker also has to accept a write.** Check the ceiling of the tier you are on before building a
pipeline whose first step is `create`.

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

## The one rule that outlives whichever tracker you pick

Inception's harness put it best, and it covers both projects' worst bug:

> **Find every place the tracker stores the same truth twice, and make the pipeline write both
> in one function.** Status is one field in Jira and two unsynced fields in GitHub — and in
> BOTH trackers, the readiness the board shows and the readiness the dependency edges imply are
> separate claims that nothing reconciles for you.

The second half is the one to sit with. A ticket marked ready with an open blocker link reads
READY to anyone trusting the board, on Jira and on GitHub alike. Move a ticket back out of the
ready state in the same breath as adding a blocker to it.
