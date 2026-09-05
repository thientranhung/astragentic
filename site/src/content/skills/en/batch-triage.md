---
title: batch-triage
oneLiner: "Read an inherited backlog against the code in one pass, then leave tickets with labels and blocking edges."
group: entry
order: 2
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/batch-triage/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

`batch-triage` is the one-pass version of triage, for a backlog that arrived with the repo. The
plugin's `mattpocock-skills:triage` handles one item arriving now. An inherited backlog is a
different shape: a hundred items of unknown age, written by people who are not here, about code
that has moved since. This skill classifies each item by reading the item's own text and the code
it names, dedupes what the wording hides, marks the dead, and creates tracker tickets carrying
labels and blocking edges. Its rule is **extract, never invent**: every classification cites the
item's own text or the code it names, and an item that cannot be classified from evidence lands
as `NEEDS-OWNER`, which is a real outcome and costs one line.
<!-- source: harness/.agents/skills/batch-triage/SKILL.md -->

The friction it removes is the one Thomas hits on day one of an adopted repo: **an inherited
backlog with no edges has no frontier.** The frontier query is every ticket whose blockers are
all done and whose assignee is empty, so a backlog where nothing blocks anything makes every
ticket look ready at once, and the ordering falls back to guesswork. The skill also carries a
correction measured in this harness. It used to ask for *"the code map"* in prose, which is how
`CODE-MAP.md` survived for weeks as an artifact a filename grep called an orphan while a shipped
skill wanted it every run (AST-071). It now resolves each item against the current tree with `rg`
and `git log` instead — which is what it should have said, since a map is stale exactly where
triage needs it, on code that moved or died.
<!-- source: RELEASE-NOTES.md (Astraler Harness 1.6.1), harness/.agents/memory/recurring-failure-modes.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A repo you are adopting arrives with an existing backlog | `batch-triage`, invoked by name, once per repo |
| One new item just landed in the inbox | Not this. `mattpocock-skills:triage` is the one-at-a-time shape |
| The backlog is larger than one pass can finish | `batch-triage` batched **by area**, reporting where you stopped |
| An empty repo with no backlog at all | Skip it. It reads something that does not exist yet |
| The tracker and git have drifted since | `reconcile-tracker`, which measures state rather than classifying items |

<!-- source: harness/.agents/roles/thomas.md, README.md, harness/.agents/skills/batch-triage/SKILL.md -->

## Prerequisites

- `docs/agents/triage-labels.md` exists and is loaded first. The label set is the project's,
  produced by `setup-matt-pocock-skills`, and inventing a parallel vocabulary inside this skill
  would fork it. <!-- source: harness/.agents/skills/batch-triage/SKILL.md -->
- The current tree, not a map of it. Most triage decisions turn on whether the code an item names
  still exists, so each item resolves against `rg` and `git log` at the tree as it stands now.
  <!-- source: harness/.agents/skills/batch-triage/SKILL.md -->
- Thomas owns this as a phase. It is user-invoked, run once per repo and again when stale, and it
  ends on owner review — a user-invoked skill cannot reach another, which is why the role exists.
  <!-- source: harness/.agents/roles/thomas.md -->
- A tracker adapter is in play, since the live items become real tickets. Which one
  (`github-issue-tracker`, `jira-issue-tracker`, `linear-issue-tracker`) does not change the
  classification, only how the tickets get written. <!-- source: harness/.agents/roles/thomas.md -->

## What it leaves behind

| What happened | Where it lands |
|---|---|
| Counts per class | The report, before the tracker is touched, so the owner sees the shape of what they inherited |
| `STALE` and `DONE` items with their evidence | The report only. **Closures wait for the owner** — closing something that was real is the expensive mistake here |
| Duplicate groups | The report, grouped by code path and symptom rather than by title |
| A live item | A real tracker ticket, labelled from the project's vocabulary, sized as one ticket or as an effort needing `wayfinder` |
| A dependency one item plainly has on another | A blocking edge on the tracker, which is what the frontier query reads |
| An item the evidence cannot settle | `NEEDS-OWNER` in the report, one line, no guess |
| The assignee field on everything created | Left **empty**. Assignment is the claim and it belongs to Thomas at dispatch time |

<!-- source: harness/.agents/skills/batch-triage/SKILL.md -->

## Known failures

Pulled from `harness/.agents/memory/recurring-failure-modes.md`.

- **AST-071** · promoted. Seven reachability checks asked whether a thing was named, whether a
  path existed, whether an address was callable — none asked whether anything read what the
  package produced. `batch-triage` is the entry's counter-example: it asked for "the code map" in
  prose, so a filename grep declared that artifact an orphan while a shipped skill wanted it every
  run. **A grep for a name is not a search for a consumer.** Fixed: check 8 requires a hand-written
  registry row naming a reader, and `batch-triage` reads the tree directly rather than a map.
- **AST-050** · promoted. Not this skill's own defect, but it landed on the file this skill loads
  first: a blanket regex rewriting `/triage` also rewrote three `docs/agents/triage-labels.md`
  paths into nonsense, because `\b` matched mid-path. Caught by reading the diff, not by any check.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- Every classification cites the item's own text or the code it names, and nothing was classified
  from the title alone.
- The counts-per-class report reached the owner **before** any ticket was created or closed.
- No `STALE` or `DONE` item was closed by this run. Those are proposals awaiting the owner.
- Blocking edges are set wherever one item plainly depends on another, because an edge left out is
  a ticket that becomes ready too early.
- Every created ticket is unassigned, and Thomas can run the frontier query against the result
  immediately.

<!-- source: harness/.agents/skills/batch-triage/SKILL.md -->

## Where it fits

`batch-triage` runs early, beside the other bootstrap phase Thomas owns: `/skills/bootstrap-glossary`
seeds the vocabulary from the code, `batch-triage` reads the backlog against the same code. Both
are invoked by name, run once per repo, and end on owner review, so neither becomes work everyone
assumes someone else ran. What it produces feeds straight into the frontier query in `thomas.md`,
which is what `/skills/dispatch-ticket` claims from. An item too big for one ticket goes to
`mattpocock-skills:wayfinder` and a Shaper session instead; a single new item arriving later goes
to `mattpocock-skills:triage`, not back here.
