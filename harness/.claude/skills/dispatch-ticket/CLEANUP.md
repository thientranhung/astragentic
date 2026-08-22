# Cleanup reference

Companion to `dispatch-ticket`. Read when the Builder has handed back, before removing a
worktree, branch, tab or workspace.

## The simplify pass

**Each increment runs one simplify pass over its own diff, after the build is green.** The
artifact is a `simplify(increment):` commit on the ticket branch — real cleanup, or an
`--allow-empty` one reading `no findings on <base>..<head>` where the pass finds nothing. An
empty pass is legitimate; an ABSENT marker and an empty one are otherwise indistinguishable
in the tree, which is why the marker is the artifact.

**The commit body carries a `Pass:` line naming what ran**, because the subject cannot
distinguish the sanctioned pass from a substitute that produced the same string. The Builder
contract owns the exact form.

Behaviour-preserving only: dead code and orphans, duplication that appeared because two
changes touched one seam, wrong-altitude fixes, comments that no longer describe the code.
Anything that would change behaviour is a finding for Thomas rather than a change, and a
cleanup that would touch a floor item's construction line is reported instead.

Thomas verifies by artifact before the milestone gate —
`git log <base>..<head> --grep '^simplify(increment):' --format='%h %s%n%b'` — rather than by
asking whether the pass ran, and reads the `Pass:` line rather than only the subject.

## Review and cleanup

The Builder pushes and returns the artifact. Thomas reads the real diff, dispatches Rin's
milestone gate, and alone decides merge. A settled Herdr status does not authorize cleanup:
capture the final transcript and verify the merge or an explicit owner-approved abandonment
first. Herdr refuses to close the last tab in a workspace, so resolve the topology rather
than calling `tab close` blindly:

```bash
herdr tab list --workspace <returned-workspace-id>
herdr pane list --workspace <returned-workspace-id>
```

- Another tab remains → close the exact ticket tab: `herdr tab close <returned-tab-id>`.
- The ticket tab is last AND the inherited `workspace_managed_by_root=true` AND no owner
  resource or active ticket remains → close the exact workspace instead:
  `herdr workspace close <returned-workspace-id>`.
- The ticket tab is last and workspace ownership is false, missing or ambiguous → STOP.
  Record the survivor and ask whether to close or retain it. A dummy shell created to hide
  an orphan reports success while leaving the orphan.

Re-list the workspace and confirm the pane is absent before removing the checkout.

**Two checks before removing a worktree.** Both must pass — failing either is STOP.

**Check 1: uncommitted work** (AST-092). A Builder that stops before committing leaves work
that exists only on disk — `git worktree remove` deletes it silently.

```bash
cd <worktree-path>
git status --short
```

Non-empty output (staged, modified, or untracked files) — **STOP**. The worktree has work
that was not committed. Report to the owner with the file list and ticket id, and wait for a
decision: commit and continue, or discard explicitly.

**Check 2: simplify markers AND provenance** (AST-094, AST-099). A Builder that commits and
pushes correctly can still skip the simplify pass, or run a manual review and commit with
the correct subject but without invoking the skill.

```bash
<repo-root>/scripts/check-simplify-markers.sh <base> [head]
```

Exit 0 is green. Exit 1 prints every reason, one `STOP:` line each. Zero markers is a STOP —
send the Builder back to run simplify (AST-094).

**A marker may be superseded, and that is a GREEN state, not a shortfall.** A Builder
retracting its own earlier false or premature `Pass:` line in the open is the check WORKING,
and it reads as the check failing (AST-121). So a later marker may name the one it replaces:

```
Supersedes: <sha of the marker this replaces>
```

**Five rules, and the attack each one closes** (AST-122):

1. **At most one `Supersedes:` per marker.** Without it, one genuine pass launders an unbounded
   number of fabricated markers by listing their SHAs.
2. **A marker that supersedes must itself be well-formed.** Without it, rule 1 is evaded by
   chaining fabricated markers, each superseding the last.
3. **The named SHA must be a marker IN RANGE**, named by only one marker.
4. **Every LIVE marker — one nothing supersedes — is well-formed.**
5. **The newest live marker IS the head being merged.** Existence is not relationship: a marker
   whose every field is true, with a later commit sitting on top of it, is a pass that did not
   cover the code — and rules 1-4 all pass on it. Send the Builder back for a fresh marker; an
   empty one is valid, so a re-mark after a fold costs one commit.

**Residual, stated because it is not closed**: markers carry no increment identity — the
subject is free prose. Nothing proves the superseding pass covers the SAME increment as the
marker it retracts, so a Builder with two increments can still retract one using the other's
real pass. **The counts are a filter, not a verdict — read the bodies.** A protocol that
prices honesty above concealment gets concealment, which is why retraction is a cheap
mechanism here rather than a documented exception (AST-121). The Builder carries its own
self-check (`builder.md`), but the mechanism that causes the skip also displaces the
self-check, so Thomas verifies independently.

**Only when both checks pass** — `git status` empty AND `markers == wellformed + superseded`
with every named SHA verified — is
removal safe:

```bash
git worktree remove <worktree-path>
git branch -d <ticket-branch>
git worktree prune
```

`-D` is for an explicitly owner-approved abandonment. Close only what this dispatch created.
Cleanup is complete when the Herdr tab and the Git worktree and branch are all retired, or
an exact retained-state reason is recorded for each survivor.
