---
name: dispatch-qa-walk
description: Thomas-only recipe to dispatch QA's product walk — the gate that uses the running system instead of reading the diff. Arrange an app at the reviewed SHA in its own worktree, pack the plan inputs (persona, data state, surfaces including unchanged ones, contracts, journeys, the previous verified-clean list), collect the report, then stop the app. Use before a PR, a merge or a release.
---

# Dispatch a QA product walk

Role contract: `.agents/roles/qa.md`. The gate-file setup, the pane form and the collection
checks are identical to `review-with-rin` §2–3 and are **not restated here** — that skill is
their one home. This skill owns only what a walk needs and the other gates do not.

## When it fires — count, do not judge

**Before a PR, a merge or a release**, on anything with a user-visible surface or a public
endpoint. That is a judgement about your own workload, and a gate that fires on a judgement
starves exactly as one that fires on a sentence does. It has been measured three times, on
three designs: a browser walker shipped across releases and **never ran once** (AST-045,
AST-057), and nine fold rounds with one merge in half a day where **QA was never dispatched at
all** (AST-135).

So carry the same counter Rin's gate carries: **more than 10 merges touching a user-visible
surface since the last walk is a STOP** — dispatch the walk, or write down why not. `none
touched a surface` is a valid answer; not having counted is not.

## The sequence

1. **Create the gate worktree** at the reviewed SHA — never the Builder's checkout. The
   command is `review-with-rin` §2, which names it `gate-<artifact-key>`; this skill used to
   call it `gate-walk-…`, and the skill that owns the command wins.
2. **Start the app there** with the project's own command.
3. **Pack the brief** — `review-with-rin` §1 plus the five below.
4. **Dispatch as a gate pane** and collect the report — mechanics are `review-with-rin` §2–3.
5. **Stop the app and confirm the port is free**, then remove the worktree.

Step 5 is the one this gate adds; a surviving dev server binds a port the next walk needs.

## The running app

The other two modes read a detached worktree. A walk needs the product **running** at the
reviewed SHA, which makes it the only gate with an environment to arrange.

**Not the Builder's checkout.** Independence is the same rule as always, and a running app
writes caches, logs and local state — sharing the author's tree would corrupt what is being
judged. Create `gate-walk-<artifact-key>` at the reviewed SHA and start the app there with
the project's own command. The project's entry doc records that command as the rendering
path; where a repo has none, a walk cannot run and that is a finding for the owner, not a
reason to approximate one.

**One walk covers a batch.** When several tickets land together toward one PR or one
release, dispatch one walk at the batch head SHA rather than one per merge — the verdict is
valid for the SHA it walked, and that SHA carries every ticket in the batch. Scope the brief
to the union of their surfaces.

The brief carries §1's contents plus five more:

- **The walk depth** — incremental (the default, before a PR or a merge) or full (at a
  release or a slice close). `qa.md` § Two walk depths owns what each covers.

- **Persona and data state.** Who QA acts as, and what the data looks like. A walk on empty
  data and a walk on realistic volume find different defects, so the verdict is only
  interpretable against the state that produced it. Where the repo has a seed command, name
  it — a stale seed once produced a 500 that read as a code bug and was an environment
  artifact, with a real production implication hiding behind it.
- **Surfaces in scope.** What this work changed, **plus every surface showing the same
  concept.** Naming only the changed ones guarantees the walk cannot find the class of defect
  it exists to find.
- **The design guidelines**, by path. Without them a finding is an observation rather than a
  violation, and QA will say so.
- **`$VERIFIED_CLEAN_FILE`** — an absolute path outside every checkout, for this walk's
  output, alongside `$GATE_FILE`. QA's cwd is the gate worktree you force-remove at cleanup,
  so a relative path writes the one artifact that is supposed to compound into the thing about
  to be deleted. **Derive it from the same per-dispatch token `$GATE_FILE` uses, and verify it
  does not already exist before you dispatch** — a reused path lets a walk that never wrote
  its list pass a `test -s` on the previous walk's file and overwrite durable coverage with
  stale coverage. Same reasoning as the gate file's uniqueness, same failure if skipped.
- **The previous walk's verified-clean list**, its contents packed into the brief from
  `.astraler/state/qa-verified-clean.md` in the BASE checkout. Where there is none, say so —
  QA runs full rather than guessing what was covered.
- **Browser consent, and every authorized mutation, named exactly.** `qa.md` calls this a
  required dispatch field and this list is where it becomes one: a rule a careful operator
  forgets within the hour needs a slot that blocks the launch, not a sentence elsewhere
  (AST-056). Without it QA declines and records a COVERAGE GAP, and a declined walk is
  indistinguishable from a clean one to everything downstream.

Findings route as every gate's do (`thomas.md` §Review): QA advises, **you classify**, the Builder fixes,
and a design-level blocker goes to the owner through `to-questionnaire`. A walk finding that
is a *product* decision — two labels that disagree because the concepts genuinely differ — is
the owner's, not a bug to assign.

## 4. Write `.astraler/state/gate-history/walk-<artifact-key>-<short-sha>.md`

The walk report, copied out of `$GATE_FILE` by `review-with-rin` §3 before any cleanup. Same
archive as every other gate's, so "why did we merge this SHA" has one place to look. **You read
it** — the findings become your work orders and the COVERAGE GAPS section tells you what the
walk did not cover, which is the half a green verdict hides.

**The verified-clean list is written separately**, by QA, to `$VERIFIED_CLEAN_FILE`. **Collect
it before cleanup**, in the same breath as the report — it is the only artifact of a walk that
compounds, and the gate worktree it was written beside is about to be removed:

```bash
# before dispatch — the path must be unique and must NOT already exist
VERIFIED_CLEAN_FILE="/tmp/qa-verified-clean-<artifact-key>-<short-sha>.md"
[ -e "$VERIFIED_CLEAN_FILE" ] && { echo "STOP: $VERIFIED_CLEAN_FILE exists — a previous walk's
  list, or a concurrent walk on the same SHA; take it to the owner"; exit 1; }

# after the pane reports, BEFORE cleanup — all fail-closed
set -euo pipefail
test -s "$VERIFIED_CLEAN_FILE"                       # this walk wrote it, not a previous one
DEST="$(git rev-parse --show-toplevel)/.astraler/state/qa-verified-clean.md"
mkdir -p "$(dirname "$DEST")"
cp "$VERIFIED_CLEAN_FILE" "$DEST"
test -s "$DEST"                                      # MUST pass before cleanup
rm -f "$VERIFIED_CLEAN_FILE"                         # only this dispatch's unique source
```

A walk whose list did not land is a walk whose next incremental run silently re-covers
everything, or skips on coverage it cannot prove.

## 5. Cleanup — ordered, and different from every other gate's

A walk is the most resource-bearing operation in the harness: it starts an app. `review-with-rin`
removes its worktree with a plain `git worktree remove` and explains why that succeeds — *"Rin
writes nothing inside the gate worktree"*. **That reasoning does not transfer.** A running app
writes caches, logs and local state, so the plain form refuses on untracked files, and the
refusal is this gate's NORMAL outcome rather than a signal.

Order matters, and the reason is that a resource bound by `--cwd` or by a compose label derived
from the directory cannot be matched once the directory is gone (AST-100, AST-101):

```bash
kill "$APP_PID"                                     # the pid you captured at step 2
lsof -ti :"$APP_PORT" | xargs -r kill               # confirm the port is actually free
proj=$(basename "$GATE_WORKTREE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g')
ids=$(docker ps -q --filter "label=com.docker.compose.project=$proj")
[ -n "$ids" ] && docker stop $ids                   # THIS worktree's containers only
git worktree remove --force "$GATE_WORKTREE"        # --force: the app dirtied the tree
git worktree prune
```

**Never a blanket `docker compose down`.** One scoped-looking `db-down` stopped the shared test
container every live Builder was standing on (AST-115). Scope by the compose label this worktree
produced, or stop nothing.

On a Claude root `scripts/hook-git-guard.py` **refuses the removal while the broker or the
containers are still up** — it does not stop them for you, because a `PreToolUse` hook acting
would be a side effect of a command that has not been permitted yet. The block above is the
contract on every runtime; the hook only declines to let you skip it.

