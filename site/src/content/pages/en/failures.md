---
harness: v6.1.19
title: "Six lessons I measured"
description: "Six real dated incidents, ordered by the stage they fell out of. Each one with the fix I chose and what that fix costs."
---

None of the six below is a hypothetical risk. Each has a date, a count of how many times it was
measured, and a file carrying the rule that came out of it. I ordered them by the stage they
fell out of rather than by severity, because what matters is where the lifecycle keeps leaking.
The part worth reading is the fix and what it costs. None of the fixes was free.

## AST-131

Twelve claimable tickets were waiting while two of four Builder slots sat idle, and nothing
errored. The router's loop was notification, verify, merge, report, wait, and no step in it asks
how many Builders are working.

I fixed it by giving the frontier query a target rather than only a trigger: after every merge
the router has to ask how many more tickets it should claim, not only which ones are claimable.

The default target is 4 Builders, and `.agents/orchestrator.md` carries the owner's override.

**Trade-off.** Every merge, handback and report to the owner now carries a pane count. I take that
trade, because an idle slot produces no signal at all.

## AST-097

A Builder started a long background process and ended its turn while waiting. The pane read
`done`, the watcher reported `TERMINAL:done`, and `dispatch-ticket`'s branch table said the
builder had finished. I came close to reporting that ticket abandoned while the Builder was
twenty minutes into honest work.

What saved this was not the protocol but the artifact contradicting itself: the modified file
contained one added comment and nothing else, which is not what an abandoning Builder leaves.

I fixed `dispatch-ticket`'s branch table: `done` no longer means finished. Before concluding, check
for background processes in the worktree; if they have exited and there are no new commits since
the last instruction, read the pane, and only new commits lead on to artifact verification. The
git guard refuses `git worktree remove` while a process is still alive in the worktree.

**Trade-off.** Every `done` costs one extra check of background processes and commits.

## AST-092

The same word again, and this time it cost more. A Builder wrote the code and stopped before
committing, the pane settled to `done`, and cleanup ran `git worktree remove` over the top of
it. Five instances across three sessions, 93 to 433 uncommitted lines each time. All five were caught
before the loss, by Thomas's habit of running `git status`, which was not yet in the contract.

I put the guard at the dangerous step rather than relying on that habit. Cleanup reads
`git status --short` on the worktree before removing it; anything dirty stops and is reported to
the owner. The Builder's handback also became three explicit actions: commit, push, then return.

**Trade-off.** Every dirty worktree blocks cleanup until someone deals with it. Next to losing a day
of work, that price is cheap.

## AST-015

An export step committed live secrets and buyer PII into a tracked file. The same-vendor
correctness review read it and passed it. The cross-vendor round caught it and filed it P1.

That is why the phase still ends with an arm round run on a different vendor, even though it
costs more money and more time. The two lenses catch different classes of defect, and the class
same-vendor misses is the expensive one to let through.

**Trade-off.** A value that has touched a tracked file is burned and has to be rotated. Downstream
there is nothing cheaper.

## AST-074

Four tickets sat in progress with a live assignee after their code had merged, the oldest by a
full day. Nothing errored: the merge ran, the frontier write-back after it did not, and no
artifact recorded the omission.

No tracker-only check catches this, because a wrong state is perfectly consistent with itself.
The tracker has to be reconciled against Git after every merge instead of confirming itself.

**Trade-off.** One more read after every merge and at session start. `reconcile-tracker` is
read-only, so every fix is still applied by Thomas by hand.

## AST-056

Two tickets had no blocking edge between them, correct by every rule I had written, and both
edited the same three rows of one file. The first merged. The second was based on the commit
before that merge, produced two conflict blocks, and a merge in the wrong direction would have
reverted reviewed work with no signal.

One worktree per Builder solves the checkout collision and nothing else. It relocates the
collision to the merge, where it is found late and by hand. The write-set is now a required field of every concurrent dispatch: the brief carries an
`Owned elsewhere:` line listing the files other tickets hold, so a merge conflict becomes a handback
note.

**Trade-off.** Each dispatch with another ticket live has to derive a write-set from the ticket body
plus the repo's docs-sync rule, and record it in the dispatch record.
