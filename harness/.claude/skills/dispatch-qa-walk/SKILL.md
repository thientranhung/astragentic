---
name: dispatch-qa-walk
description: Thomas-only recipe to dispatch QA, the gate that uses the running system instead of reading the diff. Pick the mode from the ticket's surface (walk for UI, probe for API, verify for a job), arrange the target at the reviewed SHA in its own worktree, pack the plan and the brief, collect the trace report and commit it, then stop what you started. Use at your station before a PR, a merge or a release.
---

# Dispatch QA: walk, probe or verify

Role contract: `.agents/roles/qa.md`. The gate worktree, the pane, the brief's common fields and
the collection checks are in `dispatch-ticket/GATE.md` and are **not restated here**. That file is
their one home. This skill owns what a QA run needs and the other gates do not.

## When it fires: count, do not judge

**Before a PR, a merge or a release**, on anything with a user-visible surface or a public
endpoint. Whether a change touched a surface is a judgement about your own workload, and a gate
that fires on a judgement starves. Measured three times on three designs: a browser walker that
shipped across releases and never ran once, and nine fold rounds in half a day with one merge in
which QA was never dispatched at all.

So carry a counter. **More than 10 merges touching a user-visible surface or a public endpoint
since the last run is a STOP.** Dispatch QA, or write down why not. "None touched a surface" is a
valid answer. Not having counted is not.

A project with no user-visible surface, no public endpoint and no job or pipeline anyone
depends on skips, and says so. A jobs-only product is not that project: it gets `verify`.

## Pick the mode from the ticket's surface

One plan, three modes. Read the surface from the plan, not from the diff's file names.

| The ticket changes | Mode | QA does |
|---|---|---|
| screens, journeys, links | walk | uses the UI as the user: journeys, numbers across screens, deeplinks, end-of-journey links |
| an endpoint or a service contract | probe | calls the API: contract, status codes, error and denied paths, data after the call |
| a job, a pipeline or data movement | verify | checks the job ran, data landed, logs are clean, numbers match the source |

A batch can need several. Dispatch one run per mode that applies, each with its own report. **One
run covers a batch**: when several tickets land together toward one PR or release, dispatch at the
batch head SHA rather than one per merge, and scope the brief to the union of their surfaces.

## The sequence

1. **Create the gate worktree** at the reviewed SHA, never the Builder's checkout. The command is
   in `dispatch-ticket/GATE.md` §2.
2. **Start the target there**, for `walk` and `probe` only. Use the project's own command from its
   entry doc. A repo with none cannot be run, and that is a finding for the owner, not a reason to
   approximate one.
3. **Pack the brief**: `dispatch-ticket/GATE.md` §1 plus the fields below.
4. **Dispatch as a gate pane** and collect the report: `dispatch-ticket/GATE.md` §2 and §3.
5. **Commit the report and the marker**, then **stop what you started** and confirm the port is
   free.

## The brief

- **The plan path**, `docs/qa/plan-<slug>.md`, and the items of it this run covers. The plan is
  the oracle. Where there is none, say so and QA derives the journeys from the source at lower
  confidence.
- **The mode**: walk, probe or verify.
- **The depth**: incremental by default before a PR or a merge, full at a release or a slice
  close. `qa.md` owns what each covers.
- **Persona and data state.** Who QA acts as, and what the data looks like. A run on empty data
  and a run on realistic volume find different defects, so a verdict only reads against the state
  that produced it. Name the seed command. A stale seed once produced a 500 that read as a code
  bug and was an environment artifact with a real production implication behind it.
- **Surfaces in scope**: what this work changed, **plus every surface showing the same concept**.
  Naming only the changed ones guarantees QA cannot find the class of defect it exists to find.
- **Journeys, endpoints or jobs**, from the plan, and what correct means for each.
- **The reference material**: the design guidelines for `walk`, the API description for `probe`,
  the job definition and the source of truth for `verify`. Without a reference a finding is an
  observation rather than a violation.
- **The previous verified-clean list**, its contents packed into the brief from
  `.astraler/state/qa-verified-clean.md` in the base checkout. Where there is none, say so and QA
  runs full.
- **Consent, and every authorized mutation, named exactly.** `qa.md` calls consent a required
  dispatch field, and this list is where it becomes one. Without it QA declines and records a
  COVERAGE GAP, and a declined run looks clean to everything downstream.
- **Two absolute paths outside every checkout**: `$GATE_FILE` and `$VERIFIED_CLEAN_FILE`. The
  committed report path (Collection, below) is inside the repo; you copy `$GATE_FILE` into it. Derive `$VERIFIED_CLEAN_FILE` from the same per-dispatch token
  as `$GATE_FILE`, and verify it does not already exist. A reused path lets a run that never wrote
  its list pass a `test -s` on the previous run's file.

## The running target

`walk` and `probe` need the product running at the reviewed SHA, which makes them the only gates
with an environment to arrange. It runs in the gate worktree because a running app writes caches,
logs and local state, and sharing the author's tree would corrupt what is being judged.

`verify` starts nothing. It reads the environment the job ran in: the run record, the target
store, the logs, the source. It needs the worktree only for the job definition.

## Collection

**The report path.** Resolve it before dispatch. A project may redirect it with the plug
`.astraler/project/qa-report-path.sh <key> <sha> <mode>`, which prints one path. Absent the plug,
the path is `.scratch/qa/<key>-<mode>-<sha>.md`: a walk and a probe on one SHA are two reports. It must be inside the repo and not gitignored:
`git check-ignore` on it must print nothing. Measured: an adopter's reports lived under the system
temp folder and were gone after a reboot.

```bash
KEY="<artifact-key>"; SHA="<reviewed-sha>"
if [ -x .astraler/project/qa-report-path.sh ]; then
  REPORT="$(.astraler/project/qa-report-path.sh "$KEY" "$SHA")"
else
  REPORT=".scratch/qa/$KEY-$SHA.md"
fi
test -n "$REPORT"
! git check-ignore -q "$REPORT"
```

**After the pane reports, before any cleanup:**

1. Collect `$GATE_FILE` as `dispatch-ticket/GATE.md` §3 says: non-empty, copied, source removed.
2. Copy it to `$REPORT` in the base checkout and commit it alone. That commit changes nothing
   else, so the tree QA walked is intact beneath it.
3. **Read the trace matrix.** Plan item, coverage (covered, partial or none), result. Then the
   verdict: PASS, CONCERNS or FAIL. Then COVERAGE GAPS, which tell you what the run did not
   cover, the half a green verdict hides. Findings become your work orders.
4. **Commit the marker**, an empty commit after the report:

```
qa(walk): <artifact-key> — <verdict>

Mode: walk|probe|verify
Scope: <what was in scope>
Verdict: PASS|CONCERNS|FAIL
Report: <the committed report path>
```

One marker kind covers all three modes. The `Mode:` line names which one. A run that leaves only
a report file leaves nothing the merge gate can count.

**The verified-clean list is collected in the same breath.** It is the one artifact of a run that
compounds, and the worktree it was written beside is about to be removed. It is headed by its SHA
and rebuilt at every full run.

```bash
set -euo pipefail
test -s "$VERIFIED_CLEAN_FILE"                       # this run wrote it, not a previous one
DEST="$(git rev-parse --show-toplevel)/.astraler/state/qa-verified-clean.md"
mkdir -p "$(dirname "$DEST")"
cp "$VERIFIED_CLEAN_FILE" "$DEST"
test -s "$DEST"                                      # MUST pass before cleanup
rm -f "$VERIFIED_CLEAN_FILE"
```

Findings route as every gate's do: QA advises, **you classify**, the Builder fixes, and a
design-level blocker goes to the owner through `to-questionnaire`. A finding that is a product
decision, two labels that disagree because the concepts differ, is the owner's, not a bug to
assign.

## Cleanup: ordered, and different from the read-only gates

A run that starts an app is the most resource-bearing operation in the harness. The plain
`git worktree remove` in `dispatch-ticket/GATE.md` §4 refuses on untracked files, and for this gate
that refusal is the normal outcome. Order matters, because a resource bound to the directory by
cwd, or by a name derived from the path, cannot be matched once the directory is gone:

```bash
[ -n "${APP_PID:-}" ] && kill "$APP_PID"             # the pid you captured at step 2; verify starts nothing
[ -n "${APP_PORT:-}" ] && { lsof -ti :"$APP_PORT" | xargs -r kill; }   # confirm the port is actually free
scripts/release-worktree-resources.sh "$GATE_WORKTREE"  # processes, then the project's own plug
git worktree remove --force "$GATE_WORKTREE"        # --force: the app dirtied the tree
git worktree prune
```

**The project's plug must scope to this worktree, never to a project-level target.** One
scoped-looking teardown target once stopped the shared test container every live Builder was
standing on. Release what this worktree allocated, or release nothing.

On a Claude root the git-guard hook refuses the removal while the broker or its containers are
still up. It does not stop them for you. The block above is the contract on every runtime. The
hook only declines to let you skip it.
