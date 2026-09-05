---
title: "Six failures I measured"
description: "Six real dated failures, ordered by the stage they fell out of. Each one with the fix I chose and what that fix costs."
---

None of the six below is a hypothetical risk. Each has a date, a count of how many times it was
measured, and a file carrying the rule that came out of it. I ordered them by the stage they
fell out of rather than by severity: what I need to remember is where the lifecycle keeps
leaking. The part worth reading is the fix and what it costs. None of them was free.

## AST-131

Twelve claimable tickets were waiting and two of four Builder slots sat idle. Nothing errored.
The router's loop was notification, verify, merge, report, wait, and no step in it asks how many
Builders are working.

I fixed it by giving the frontier query a target, not just a trigger: after every merge the
router has to ask how many more it should claim, not only which ones are claimable. The cost is
a busier router that sometimes over-claims. I take that trade, because an idle slot produces no
signal at all.

## AST-097

A Builder started a long background process and ended its turn while waiting. The pane read
`done`, the watcher reported `TERMINAL:done`, and `dispatch-ticket`'s branch table said the
builder had finished. I came close to reporting that ticket abandoned while the Builder was
twenty minutes into honest work.

What saved it was not the protocol. It was the artifact contradicting itself: the modified file
contained one added comment and nothing else. I dropped my trust in pane status entirely after
that, and every `done` now has to read the diff before concluding anything. The cost is one
extra pass every time a ticket closes.

## AST-092

The same word again, and this time it cost more. A Builder wrote the code and stopped before
committing, the pane settled to `done`, and cleanup ran `git worktree remove` over the top of
it. Five instances across three sessions, 93 to 433 lines each time, none recovered.

I put the guard at the dangerous step rather than relying on Builders to commit more carefully.
Cleanup reads `git status` on the worktree before removing it, and anything dirty stops and goes
back to a person. The cost is orphaned worktrees piling up and the occasional manual sweep. Next
to losing a day, that is cheap.

## AST-015

An export step committed live secrets and buyer PII into a tracked file. A same-vendor
correctness review read it and passed it. The cross-vendor round caught it and filed it P1.

That is why the phase still ends with an arm round run on a different vendor, even though it
costs more money and more time. The two lenses catch different classes, and the class same-
vendor misses is the expensive one to let through. A value that has touched a tracked file is
burned and has to be rotated. Downstream there is nothing cheaper.

## AST-074

Four tickets sat in progress with a live assignee after their code had merged, the oldest by a
full day. Nothing errored: the merge ran, the frontier write-back after it did not, and no
artifact recorded the omission.

No tracker-only check catches this: a wrong state is perfectly consistent with itself. The fix
was to reconcile the tracker against Git after every merge instead of letting it confirm itself.
The cost is a reconcile step nobody enjoys running, and most of the time it finds nothing.

## AST-056

Two tickets had no blocking edge between them, correct by every rule I had written, and both
edited the same three rows of one file. The first merged. The second was based on the commit
before that merge, produced two conflict blocks, and a merge in the wrong direction would have
reverted reviewed work with no signal.

One worktree per Builder solves the checkout collision and nothing else. It relocates the
collision to the merge, where it is found late and by hand. Tickets now declare a write-set, and
two tickets whose write-sets overlap are serialised even when nothing orders them. The cost is
fewer tickets running at once, which is the exact thing this whole system exists to increase.
