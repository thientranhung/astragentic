---
name: jira-issue-tracker
description: Operating mechanics for a project whose tracker is Jira — status as numbered transitions, cloudId and JQL quoting, issue links and their invertible direction, whole-field description writes, and what only a human can change. Load it when the project's docs/agents/issue-tracker.md names Jira. Read tracker-contract.md for what the pipeline requires of any tracker.
---

# Tracker adapter: Jira

**Measured on a live project that moved Linear → Jira on 2026-08-21**, team-managed. Every trap below cost that project a run or a correction. What the pipeline
requires of *any* tracker is `.agents/tracker-contract.md`; this file is the HOW for one of them.

**The project half stays in the project.** This adapter carries no site, no `cloudId`, no project
key, no transition-id table — the project's `docs/agents/issue-tracker.md` owns those, and they
are per-project by nature. Substitute as you read.

Reach it through the **Atlassian MCP tools**.

## Two coordinates a session cannot discover

**`cloudId` appears in no URL a human pastes.** It must be written down in the project half, or
every session starts by hunting for it (`getAccessibleAtlassianResources`).

**A project key can collide with a JQL keyword — always quote it.** A two-letter key that is
also a JQL word makes `project = <KEY>` fail to parse; `project = "<KEY>"` works. This bites once per session otherwise, and the error does not
say "quote your key".

## Status is a TRANSITION, taken by a number

This is the single biggest difference from every other tracker: you do not assign a status, you
take a transition, and transitions are identified by **numeric ids that are project-specific,
non-sequential and not guessable**. States added later take low ids.

**So a remembered transition id is a valid write to a state you did not mean.** It succeeds,
nothing errors, and no query flags it.

```
getTransitionsForJiraIssue   →   transitionJiraIssue with an id FROM THAT RESPONSE
```

**Read the transitions every time. The extra call IS the guard**, and it is cheaper than the
class of bug it prevents. A transition-id table in the project half is a convenience for humans
reading it, never the thing a session writes from.

**Adding or renaming a state is an OWNER action in the Jira UI, on both project types**, and the
MCP tools cannot touch a workflow at all — they create, edit, transition and link issues, nothing
more. A session that needs a state which does not exist is blocked on a human; say so rather than
improvising with labels.

*How the UI gets there differs, and only one half is measured.* On **company-managed**, the state
is added in Project settings → Workflows and is invisible to the API until the workflow is
**published** — that vocabulary is company-managed's, and this claim is inherited rather than
measured here. On **team-managed**, a status is added as a board column and there is no publish
step. **Re-measure before relying on either.**

**Team-managed vs company-managed changes what the board is.** On a **team-managed** (next-gen)
project the statuses **are** the board — there is no separate status→column mapping to keep in
sync, and requirement 5 is met by the product. On a **company-managed** project a status mapped
to no board column is invisible on the board, which is a second place for truth to live. Know
which one the project is before reasoning about its board.

**There is no need for a `Duplicate` state.** Jira carries duplication as a LINK, which is
strictly better than a status because it names *which* ticket absorbed this one: move the
absorbed ticket to the cancelled state, link it, comment on both.

## Dependencies are links, and the direction is silently invertible

| Relationship | Link type | How |
|---|---|---|
| A must finish before B | `Blocks` | `createIssueLink`, `inwardIssue` = A (the blocker), `outwardIssue` = B (the blocked) |
| A is absorbed by B | `Duplicate` | `inwardIssue` = A (the duplicate), `outwardIssue` = B (the survivor) |
| A and B merely touch | `Relates` | **prefer a sentence in the body over a link** |

**The inward/outward order is genuinely confusing and easy to invert, and a backwards `Blocks`
link corrupts the frontier query silently.** Create the link, then read the issue back and check
the **rendered wording** says what you meant — `X` must read *"is blocked by Y"*, not the
reverse. Reading back the payload you just sent proves nothing; read the rendering.

**`Relates` is noise at volume.** One migration measured **189 candidate `relatedTo` edges
against 8 real blocking edges** — carrying them all would have put nine entries in one ticket's
Linked issues panel while saying nothing about sequencing. A mention in the body renders as a
live key and carries the same information where it is readable.

**Jira's advantage, and the reason to pick it:** `Blocks` is expressible in **one JQL query**, so
the frontier is one call rather than the N+1 loop GitHub forces.

## `editJiraIssue` replaces `description` WHOLE

There is no partial update. Anything you do not send back is deleted. Two consequences, both
measured:

- **Never retype a description you meant to patch.** Read it, substitute, send the whole field
  back. An agent recomposing prose from memory silently drops words — it happened to a
  Vietnamese sentence and to a diacritic, and neither showed up in any error.
- **Build the JSON payload programmatically.** Hand-typed escape sequences corrupted `Ưu tiên`
  into `Ư u tiên` on the first attempt at exactly this task. This bites any project whose
  content is not ASCII.

## The readiness state exists for the human

Whatever the project calls it (`To Do`, `Ready`), the claimable-and-unclaimed state is
requirement 5 made visible, and three rules keep it honest:

1. **Write it when the ticket becomes UNBLOCKED, not when it is claimed.** Move it in the same
   action that closes its last blocker. Writing it and then moving to in-progress moments later
   is a state nobody could have read. A ticket already unblocked and shaped when filed is
   **created** in that state.
2. **Readiness plus an open `is blocked by` link is a contradiction.** When you add a blocking
   link to a ready ticket, move it back in the same breath.
3. **A blocker that is not an issue does not exist.** Create an entity for the real constraint —
   a decision, a credential, a deploy — and link at it. **A decision ticket is first-class and is
   NEVER dispatched to an agent**; it closes when the owner answers. Say so in its body.

## Two things that arrive with a Jira project

**Forms.** A ticket arriving with `form` / `form-*` labels and an empty description is a real
request from a real person, not noise. Triage it; never delete it.

**Migration provenance.** Where tickets came from another tracker, they carry a provenance label
and a first description line pointing back. **Do not strip either** — they are the only way back
to the original when a migrated ticket reads oddly. Expect attachments not to have survived a
Linear → Jira move: Linear's image URLs are short-lived signed links.

## What the project's `issue-tracker.md` must carry

Site URL · `cloudId` · project key, name, id, and **team-managed or company-managed** · board
URL · issue types · priorities · link types · the state table with its transition ids (as a
human's reference, not a session's source) · the ticket prefix · that project's own decisions.
