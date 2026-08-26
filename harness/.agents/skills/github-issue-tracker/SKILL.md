---
name: github-issue-tracker
description: Operating mechanics for a project whose tracker is GitHub Issues — status as labels, the claim, native dependencies keyed by database id, the frontier loop, and the Projects board mirror. Load it when the project's docs/agents/issue-tracker.md names GitHub. Read tracker-contract.md for what the pipeline requires of any tracker.
---

# Tracker adapter: GitHub Issues

**Measured on a live project that moved Linear → GitHub on 2026-08-21.** Every trap
below cost that project a run. What the pipeline requires of *any* tracker is
`.agents/tracker-contract.md`; this file is the HOW for one of them.

**The project half stays in the project.** This adapter carries nothing project-specific — the
project's `docs/agents/issue-tracker.md` owns: the `<owner>/<repo>`, the ticket prefix, the
label→board-column names, and that project's own decisions. Substitute those as you read.

**The one fact that shapes everything:** GitHub Issues has **no status field**, so status lives
in two unsynced places — the label, which is the truth, and the Project `Status` column, which is
a mirror somebody has to write.

Reach it with the **`gh` CLI**, not an MCP server. `gh` is already authenticated wherever PRs are
already being driven, and an unproven tool path fails silently.

## Status is labels, and exactly one of them

| Meaning | How it is stored |
|---|---|
| Backlog — not on the frontier | open + label `backlog` |
| Todo — on the frontier, unclaimed | open + label `todo` |
| In Progress — claimed | open + label `in-progress` + **assignee** |
| Done | **closed** |
| Won't fix | closed `--reason "not planned"` + label `wontfix` |
| Duplicate | closed `--reason "not planned"` + label `duplicate` |

Exactly one of `backlog` / `todo` / `in-progress` at a time, so a status change is two writes:

```bash
gh issue edit <n> --remove-label todo --add-label in-progress
```

## The claim protocol is WEAKER here, and git is what carries it

**Assigning is the claim**, written before the worktree exists. But `gh issue edit <n>
--add-assignee @me` writes a real GitHub login, and **a login is one identity for every
dispatcher** — the method's `builder/<ticket-id>` is not a login and cannot be stored. So
requirement 3 is **not** met natively, and a readback here cannot tell whose claim it read.

- **The claim** is `--add-assignee @me`. That is what removes the ticket from the frontier.
- **The Builder identity** goes in the dispatch record
  (`.astraler/state/dispatch-record.json`), since no field holds it.
- **The readback interlock is weakened; the git one is not.** `git worktree add -b
  <ticket-branch>` failing is the *only* thing that decides a same-second race. Losing it
  means leaving the assignee exactly as you found it.
- **Releasing a claim**: "clear only when a fresh readback shows your own" cannot be evaluated
  here. Confirm the branch and worktree are gone instead — the worktree, not the tracker, is
  what says a Builder is still live.

**So concurrency on one login rests entirely on git.** If it grows past a couple of panes, the
fix is one GitHub account per Builder identity, not a looser protocol.

**GitHub has no priority field.** Urgency belongs in the body and in the router's ordering. Do
not simulate it with labels — a label nobody sorts by is noise.

## Identifiers: the title token is the id, the issue number is not

The project's ticket prefix (`<PREFIX>-<n>`) leads every title:

```
<PREFIX>-251 — <what the ticket does>
```

That token is what keeps citations in code comments, docs, ledgers and commit messages
resolving. A GitHub issue number (`#42`) is a **second** identifier living alongside it, useful
for `gh` and PR linking, never a replacement. Running two id vocabularies at once is a
collision class, not a convenience.

Allocate the next id by reading the highest that exists. Never remember it across a compaction:

```bash
gh issue list --limit 500 --state all --json title \
  | grep -oE '<PREFIX>-[0-9]+' | grep -oE '[0-9]+' | sort -n | tail -1
```

## Blocking edges: native, and keyed by the DATABASE id

Native issue dependencies are the machine gate, and they render in the UI — which is how
requirement 5 gets met without a second surface.

```bash
# add an edge — the blocker's numeric DATABASE id, NOT its #number, NOT its node_id
bid=$(gh api repos/<owner>/<repo>/issues/<blocker> --jq .id)
gh api --method POST repos/<owner>/<repo>/issues/<blocked>/dependencies/blocked_by -F issue_id=$bid

# read them — two endpoints, and they do NOT agree immediately after a write
gh api repos/<owner>/<repo>/issues/<n>/dependencies/blocked_by --jq '.[]|{number,state,title}'
gh api repos/<owner>/<repo>/issues/<n> --jq '.issue_dependencies_summary'   # .blocked_by = OPEN blockers
```

**The summary field LAGS the write by about two seconds; the list endpoint does not.** Measured:
straight after the POST, `issue_dependencies_summary.blocked_by` read `0`, and two seconds later
`1`, while `.../dependencies/blocked_by` was accurate immediately.

**So the rule is not "sleep and retry" — it is "read back through the endpoint that is not
lagging."** Retrying is what makes duplicate edges. The summary is still the right field for the
frontier query, where the write is long past; it is the wrong one for a read-back.

Parent → child is **sub-issues**, also UI-visible, also keyed by database id:

```bash
cid=$(gh api repos/<owner>/<repo>/issues/<child> --jq .id)
gh api --method POST repos/<owner>/<repo>/issues/<parent>/sub_issues -F sub_issue_id=$cid
```

**Never create an edge you have not verified against the source.** A wrong edge silently
withholds a ticket from the frontier and nothing reports it — strictly worse than a missing one.

## The frontier is an N+1 loop, by construction

GitHub has no query language, so there is no one-call frontier:

```bash
gh issue list --limit 500 --state open --json number,title,assignees,labels \
  --jq '.[]|select(.assignees|length==0)|select(.labels|map(.name)|index("todo"))|[.number,.title]|@tsv' \
| while IFS=$'\t' read -r n t; do
    b=$(gh api repos/<owner>/<repo>/issues/$n --jq '.issue_dependencies_summary.blocked_by')
    [ "$b" = "0" ] && echo "FRONTIER  $t"
  done
```

**When a merge unblocks something, write `todo` in the same breath as closing the ticket that
unblocked it.** An agent re-derives the frontier on demand and never needs the label; the owner
opens the board and looks.

## The board mirror — every label write is two writes

**The label is the truth. The Project `Status` column is a one-way mirror of it**, takes part in
no query, and decides nothing. It exists so the one person who does not run queries can see what
is true.

**Changing a label does not move the card.** Nothing in GitHub syncs one to the other, so pair
every label write with a Status write. `project-status-sync.sh`, shipped beside this file, does
the pairing: read-only by default, `--apply` to write.

Run it at claim, at the merge write-back, and at session start beside `reconcile-tracker`.

**It needs the `project` OAuth scope, which is not in `gh`'s default set:**

```bash
gh auth status | grep scopes          # must list 'project'
gh auth refresh -s project            # the OWNER runs this once; it opens a browser
```

Without that scope `--json projectItems` returns **`[]` rather than an error** — indistinguishable
from "this issue is on no board". Measured: a board held 71 items with 68 reading `Backlog`,
three of them with live Builders, while every query the harness ran was correct. Status had been
written once at import and never again.

## Commands

```bash
# create — ALWAYS --body-file, never --body
gh issue create --title "<PREFIX>-276 — <title>" --body-file /tmp/body.md --label todo

gh issue view <n>                                        # by GitHub number
gh issue list --search "<PREFIX>-251 in:title" --state all   # by ticket id

gh issue edit <n> --add-assignee @me
gh issue close <n> --comment "Merged in #<pr>"
```

**Always `--body-file`.** Bodies carry backticks, quotes, `$` and newlines; `--body "..."`
mangles them, and a mangled spec is a ticket that lies about what to build.

## Arriving from another tracker

Only active work moves; completed tickets stay behind in the old tracker as an archive. So a
blocker named in a body with no counterpart in GitHub is **satisfied, not missing** — read it the
other way and real frontier tickets freeze in the direction nobody investigates. Keep the
`**Blocked by:** <ids>` text line in bodies for exactly this reason: it names blockers that
cannot be linked natively because they never came across.

Also gone, and worth saying out loud rather than reinventing: a separate `In Review` state (an
open PR *is* that state), and any priority field.

## What the project's `issue-tracker.md` must carry

`<owner>/<repo>` · the ticket prefix · the label→board-column names · which tracker it came from
and when · any id ambiguity from its own history · the PR-as-request-surface decision.
