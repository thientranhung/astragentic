# Cleanup reference

Companion to `dispatch-ticket`. Read when the Builder has handed back, before removing a
worktree, branch, tab or workspace. The stopping is yours, in the order below, on every
runtime. On a Claude root `scripts/hook-git-guard.py` refuses a removal while a dirty tree, a
live process or a bound broker remains; it releases nothing.

## The simplify pass

Each increment runs one simplify pass over its own diff, after the build is green. The artifact
is a `simplify(increment):` commit on the ticket branch, real or `--allow-empty` reading
`no findings on <base>..<head>`. Its body carries the `Pass:` line (`builder-claude.md`). Behaviour
changes are findings for Thomas, not changes. Thomas verifies by `scripts/check-simplify-markers.sh
<base> <head>` and never by a hand-rolled `git log --grep`, which matches bodies. The marker
rules, retraction with `Supersedes:` and the head check are in [`MARKERS.md`](MARKERS.md).

## Review and cleanup

The Builder pushes and returns the artifact. Thomas reads the real diff and alone decides
merge. A settled Herdr status does not authorize cleanup: capture the final transcript and
verify the merge or an explicit owner-approved abandonment first. Herdr refuses to close the
last tab in a workspace, so resolve the topology first:

```bash
herdr tab list --workspace <returned-workspace-id>
herdr pane list --workspace <returned-workspace-id>
```

- Another tab remains: `herdr tab close <tab_id>`, with `tab_id` read from this ticket's entry
  in `.astraler/state/dispatch-record.json`. On a Claude root the mod refuses the close while
  the pane is mid-turn, which means the Builder is still working. After the worktree removal
  the release has reaped the Builder and herdr has usually closed the tab: not-found is expected.
- The ticket tab is last AND the inherited `workspace_managed_by_root=true` AND no owner
  resource or active ticket remains: `herdr workspace close <returned-workspace-id>`.
- The ticket tab is last and ownership is false, missing or ambiguous: STOP, record the
  survivor and ask whether to close or retain it.

Re-list the workspace and confirm the pane is absent before removing the checkout.

## Two checks before removing a worktree

Both must pass; failing either is STOP.

**Check 1: uncommitted work.** `git status --short` inside `<worktree-path>`. Non-empty output
is work that exists only on disk and that removal deletes silently. Report the file list and
ticket id to the owner and wait: commit and continue, or discard explicitly.

**Check 2: markers and provenance.**

```bash
<repo-root>/scripts/check-simplify-markers.sh <base> [head]
```

Exit 0 is green. Exit 1 prints one `STOP:` line per reason. A ticket labelled `quick`, or a
brief carrying `SIMPLIFY: n/a`, owes no marker and is not checked (`MARKERS.md`). Otherwise zero markers is a STOP: send the
Builder back to run simplify. A superseded marker is green. The counts are a filter, not a
verdict: read the bodies.

## Release, remove, verify

Release the worktree's resources BEFORE removing it: anything bound to the directory (a
process by cwd, a resource named from the path) cannot be matched once it is gone. Scope
everything to THIS worktree. What a worktree allocates beyond git is the project's: it
declares its release step at `.astraler/project/cleanup-worktree.sh`, which the script runs
after reaping processes and names as absent when missing. The script also refuses the stamp
while a Compose stack rooted in the worktree still holds a container, a labelled volume or
the image it built (`down -v` leaves that image; `down -v --rmi local` does not). It deletes
nothing. Never answer a leak with `docker system prune`, `docker volume prune` or `docker
builder prune`: each is machine-wide.

```bash
# 1. processes first; matched by real cwd as a path prefix, never by argv
scripts/release-worktree-resources.sh <worktree-path>   # stamps the path on a clean run;
                                                        # hook-git-guard.py refuses removal without it
# 2. then the worktree, then the branch
git worktree remove <worktree-path>
git branch -d <ticket-branch>
# 3. prune, and verify; this is the post-condition
git worktree prune
git worktree list; git branch --list '<ticket-branch>'   # both must be gone
```

On a Claude root the mod runs the release itself at `git worktree remove`
(`dispatch-ticket-claude` § Cleanup). Never `rm -rf` a worktree: it leaves the registration,
and a stale `.git/worktrees/<name>/` makes the next `add` refuse.

`git branch -d` refuses after a squash merge. Confirm the work is on the base with
`git log <base> --oneline --grep '<ticket-id>'`, then `-D` and record the ticket id as the
reason. `-D` without that confirmation is for an owner-approved abandonment only.

Close only what this dispatch created. Cleanup is complete when the Herdr tab, the worktree
and the branch are retired and step 3 shows them gone, or an exact retained-state reason is
recorded for each survivor.
