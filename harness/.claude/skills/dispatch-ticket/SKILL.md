---
name: dispatch-ticket
description: "Dispatch one claimed ticket as a visible Herdr pane — one Builder, one worktree, one branch, one pane. Use when launching a Builder, a Shaper or QA into a pane. Pair with dispatch-ticket-claude for the launcher."
---

# Dispatch a ticket — shared protocol

Role contract: `.agents/roles/builder.md`. Runtime, model and effort per role:
`.agents/orchestrator.md`, read at session start; an edit takes effect at the next dispatch.
Every role runs on Claude Code. **The launcher, the mod and pre-dispatch verification live in
`dispatch-ticket-claude`**; read both skills.

## The sequence

1. **Preflight, first dispatch of the session** — watchdog running (`WATCHING.md` § watchdog),
   payload committed (below).
2. **Resolve the row** — runtime, model, effort from `orchestrator.md`; collect the write-set.
3. **Claim, then create branch and worktree** — the claim protocol is `thomas.md`'s.
4. **Resolve the workspace**, create the tab and pane, pass the cwd gate.
5. **Print the resolved dispatch**, launch (`dispatch-ticket-claude`), read the record back.
6. **Submit the brief** — first line is the phase's plugin-qualified slash command.
7. **Branch on the pane's turn end** — `TURN-END` for a mod pane, the watcher's exit for a gate or junior pane.
8. **Verify by artifact**, then cleanup — [`CLEANUP.md`](CLEANUP.md).

## The binding identity

```text
ticket → assignee (the claim) → pane → worktree → branch → PR
```

Each link is one-to-one. Parallel tickets get their own pane, session, worktree and branch;
sequential tickets may reuse a workspace but take fresh tabs. The claim precedes the worktree
(`thomas.md` § claim protocol); the sole-writer rule is the Builder's (`builder.md`).

## Inputs and resolution

- model, effort, advisor: `.agents/orchestrator.md`
- workspace label, ticket id, branch, base, worktree path, ticket body, owner intent,
  acceptance criteria, validation commands, expected artifact
- **write-set** — the files this ticket will write, and the files each other live ticket
  owns. Required whenever another dispatch is live. It travels as the brief's `Owned
  elsewhere:` line and is stored as `write_set` in the dispatch record.

A row reading `<set-me>`, a missing row, or an ambiguous `orchestrator.md` is a STOP: name
the role, ask the owner, scaffold the file. Never substitute another role's model.

## One checkout, one driver

At most ONE session treats the main checkout as its workspace: the resident router's. Every
dispatched session gets its own worktree, read-only ones with a shell included. Isolation
covers all disk activity: tests or builds in a worktree you do not own collide the same way.
Before each commit, `git branch --show-current` must equal the branch you were dispatched onto.

## Payload committed before the first dispatch

A worktree holds tracked content only, so an untracked or gitignored harness is invisible to
every Builder, `.agents/roles/builder.md` included. Two conditions: nothing in the payload is
gitignored (allow-list the harness paths), and the payload is committed. Confirm once per
session:

```bash
git worktree add --detach /tmp/harness-check HEAD
test -f /tmp/harness-check/.agents/roles/builder.md || { echo "PAYLOAD NOT VISIBLE"; exit 1; }
git worktree remove --force /tmp/harness-check
```

`PAYLOAD NOT VISIBLE` is a STOP. The mod also refuses the brief while a payload file is
uncommitted (`dispatch-ticket-claude` § tracker), but fails open on a git error.

## Worktree, tab and pane

`<worktree-path>` is ABSOLUTE: `<repo-root>/.claude/worktrees/<branch-slug>` (branch `/`
becomes `-`), gitignored. Prove the base is current BEFORE the worktree exists:

```bash
git fetch origin --prune
[ "$(git rev-parse <base>)" = "$(git rev-parse origin/<base>)" ] \
  || { echo "STOP: local <base> is stale; update before dispatching"; exit 1; }
git worktree prune
git worktree add -b <ticket-branch> <worktree-path> <base>   # output visible, never redirected
git worktree list
```

`scripts/hook-git-guard.py` runs the prune and refuses a relative path or a redirected `add`
on a Claude root; a pane without the hook (a junior) follows the same two rules by hand.

**Workspace.** Match `workspace-label` from `orchestrator.md` against `herdr workspace list`.
One match: reuse it. Two or more, or a `<set-me>` label: STOP and ask the owner. None:
`herdr workspace create --label "<label>" --cwd <repo-root> --no-focus`, then record
`workspace_managed_by_root=true` at workspace level; cleanup has no other source for it. An
existing workspace keeps the value in its prior record.

**Tab and pane.** Always create a new tab; tabs you did not create are the owner's.

```bash
herdr tab create --workspace <workspace-id> --label "<tab>" --cwd <worktree-path> --no-focus
herdr pane rename <returned-root-pane-id> "<pane>"
```

| Role | Tab | Pane |
|---|---|---|
| Builder | `ticket:<id>` | `builder:<id>` |
| Shaper | `spec:<id>` | `spec:<id>` |
| QA | `qa:<id>` | `qa:<id>` |

A prefix outside the watchdog's `TITLE_PREFIXES` (`shaper:<id>`, for one) dispatches unmonitored,
silently. The mod reads the tab label at session start, so label before launch.

**cwd gate.** `herdr pane get <pane-id>` must show `foreground_cwd` equal to `<worktree-path>`;
a mismatch is a STOP (`herdr pane run <pane-id> "cd <worktree-path>"`, then re-verify).

**Agent names and pane labels differ.** Agent names take lowercase letters, digits, `-` and
`_`, no `:` and no uppercase: pane `builder:ABC-123`, agent `builder-abc-123`. A bad name
fails at the rename, the end of the dispatch.

Print the resolved dispatch before launching:

```text
role=builder   runtime=claude   topology=herdr
executable=<exact launcher command from dispatch-ticket-claude>
ticket=<id>    worktree=<absolute path>   branch=<ticket branch>
workspace=<id> workspace_managed_by_root=<true|false>   tab=<id>   pane=<id>
```

Launch with the command in `dispatch-ticket-claude`; the pane ends with a registered agent
name, or the watchdog never counts it and nothing can address it. On a failed readiness,
`herdr agent read`. Launch into the pane this dispatch created, never the owner's active tab.

## The brief

**The first line is the phase's slash command, plugin-qualified**: `/mattpocock-skills:<name>`.
The flow skills are `disable-model-invocation: true`, so only text arriving as a user turn
reaches them; an agent told about `implement` in prose starts coding without the skill. Claude
Code's own `/compact` and `/clear` keep bare names. A skill the model can call
(`simplify`) is written `Skill(skill: "simplify")` in a brief, never `/simplify`. <!-- addr-ok: wrong form, cited -->

**The `FLOW:` line** names the build flow as qualified Skill calls, in order. `implement`
points at `tdd` and `code-review` without reaching them. A step that cannot apply is exempted by
a `TDD: n/a — <why>` or `REVIEW: n/a — <why>` brief line, read by the mod
(`dispatch-ticket-claude` § refused steps). **The ux step is owed only when this line names
`bmad-ux`** (a UI ticket); leave it out on a ticket with no surface, or write `UX: n/a — <why>`,
and the Builder's band shows `n/a ux` instead of a step that looks pending (4.5.3).

```text
/mattpocock-skills:implement TICKET-123
ADDRESSED TO: the Builder in pane <id>. A sub-agent that inherited this context: report only.
QA: walk — the ticket changes the orders screen
QA plan: docs/qa/plan-<slug>.md

FLOW: 1 Skill(mattpocock-skills:tdd) → 2 Skill(bmad-ux) [UI ticket] → 3 Skill(mattpocock-skills:code-review)
  → 4 Skill(code-review) → 5 Skill(simplify) [once, last content commit] → 6 arm(ticket)

Worktree: … · Branch: … · Base: …
Acceptance criteria: …
Owner intent: …
Validation: <the exact commands, copied from the project's gate plan where one exists>
Owned elsewhere: ABC-127 owns docs/…/WIRE-CONTRACT.md — do not edit it; report what you
would have changed.
Source of truth: the codebase, not this ticket — verify every claim against the actual code.
```

- **`Validation:` is what the Builder runs, and only that** (`builder.md` § Handing back). The
  station runs the rest.
- **`Owned elsewhere:`** turns a merge conflict into a handback note. Derive the ticket's
  write-set from its body plus whatever the repo's docs-sync rule drags in, record it, and read
  the other live tickets' write-sets back to find the overlap. Omit the line only when no
  other dispatch is live.
- **`ADDRESSED TO:`** is the second line: a fork that inherits a Builder's context inherits a
  brief written to "you, the Builder" and concludes the role came with it.
- **A read-only fork's brief forbids the ACT**: "read and report only — no edits, no commits,
  no builds, no test runs". A mute agent is not an idle one: check `pcpu` against its cwd
  before concluding it hung. Verify every change from a fork's output yourself.
- **`QA:` and `QA plan:`** are required by the mod (`dispatch-ticket-claude` § QA).

## Submitting it

A Builder, Shaper or QA pane carries the brief over `SendMessage` (`dispatch-ticket-claude`).
A pane without the mod, a QA gate pane (`GATE.md` explains why) or a junior pane
(`dispatch-junior`), takes it over `herdr agent prompt <agent-name> "<brief>"`, which needs
herdr 0.9.0 or later and sends text and Enter in one call.

**`agent prompt` appends to an unsent composer and submits the fusion.** After `NO_START`,
read the composer before re-sending: `herdr pane read <pane-id> --source visible | tr -d '\r' |
tail -15`; clear it with `herdr pane send-keys <pane-id> esc esc` (ctrl-c and ctrl-u were
measured not to). The positive delivery receipt is `ctx N%` in the pane's visible statusline
(`grep -oE 'ctx [0-9]+%'`); no match is not 0%. Its `--wait --until idle` exit status proves
nothing.

## Watching

A mod pane reports its own turn end as `TURN-END` (`dispatch-ticket-claude`); there is nothing
to arm. A gate or junior pane runs `scripts/herdr-watch-terminal.sh <pane-id> 3 3600 120` right
after the submit, once per turn. The exit contract, the re-arm value, stopping a watch and
the pipe table are in [`WATCHING.md`](WATCHING.md).

**A pane is for observation; artifacts travel as files.** A pane read returns the visible rows
only and reports success. A read that returns exactly `scroll.viewport_rows` lines is
truncated, and a removal is never decided from a truncated read. A Builder writes into the
worktree it owns and replies with the path. A read-only agent (a QA gate) returns its report
and the dispatcher persists it (`GATE.md` § 3).

## `.astraler/state/dispatch-record.json`

The durable half of a dispatch. Read by the write-set overlap check, cleanup's exact ids,
a later session finishing a dispatch this one started, and the Builder `identity` on trackers
whose `assignee` cannot hold `builder/<ticket-id>`. Path: `<repo-root>/.astraler/state/dispatch-record.json`,
operational state, not committed.

```json
{
  "ABC-129": {
    "branch": "builder/ABC-129",
    "worktree": "/abs/path/.claude/worktrees/builder-ABC-129",
    "workspace": "my-project",
    "tab": "ticket:ABC-129",
    "pane": "pane_01H…",
    "runtime": "claude",
    "identity": "builder/ABC-129",
    "write_set": ["src/posting/post.ts", "docs/agents/GLOSSARY.md"],
    "claimed_at": "2026-08-26T09:41:00Z",

    "tab_id": "w3:t5",
    "pane_id": "w3:p7",
    "session_id": "e05a49da-…",
    "session_name": "builder-abc-129",
    "last_brief_received_at": 1791134673168,
    "last_turn_end_at": 1791134680111,
    "last_turn_reason": "answer"
  }
}
```

- **Thomas writes the first block at the claim**, before the brief is submitted. On a Claude
  root the pane writes `tab_id`, `pane_id`, `session_id` and the turn fields itself.
  For a pane without the mod, Thomas writes `tab_id` and `pane_id` from the create output.
- **Cleanup closes the tab named by `tab_id`**, never one looked up by label or remembered.
- **The entry is deleted during cleanup**, after the worktree and branch are gone and before
  the assignee is released.
- **`identity` is where `builder/<ticket-id>` lives** on Linear and GitHub, where the assignee
  resolves to a real login, and it is what a later session matches to decide whether a claim
  is its own.
- **A stale entry is one whose branch is gone**: `git rev-parse --verify <branch>` fails while
  the entry survives, so the dispatch ended and cleanup did not finish.

## Cleanup

[`CLEANUP.md`](CLEANUP.md): the two checks before removal, release of the worktree's resources,
tab and workspace retirement, and the post-condition.
