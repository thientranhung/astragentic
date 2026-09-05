---
title: "Why"
description: "Five questions I had to answer for myself: why this layer, why I rent the method from mattpocock, why subagents are not the coordination layer, why the tracker, why a second vendor."
---

These five are the questions I get asked most, and they are also the five places I have changed
my mind at least once. Every answer states its cost, because a choice with no cost is usually a
choice nobody has tried.

## why-astragentic

One agent working alone needs no coordination layer. One agent, one branch, no coordination
problem, and if that is where you are, stay there.

The trouble starts with the second and third agents, on a real codebase. The failures at that
point are quiet: agents overwrite each other with no exception thrown, review runs round after
round, and by the end nobody can say exactly what actually ran. I lost an afternoon of work in
precisely that way: three sessions against one checkout, no errors, work gone, and then another
afternoon spent working out the cause.

Astragentic exists to make those failures structurally hard rather than something you watch for
by eye every time. Isolation is a git worktree, not a house rule. The claim is a row on a
tracker, not a sentence in a chat. The evidence is a commit and a receipt, not the report of the
agent that just did the work.

The cost comes in two parts. First: this is another layer to install, understand and upgrade,
and every upgrade is an event the project has to absorb. Second, and it matters more: this loop
has never run all the way through, from dispatch to merge with every gate firing, on live work
inside this repo. Proving the tooling is correct and proving the loop is correct are two
different claims, and I have only done the first.

## why-mattpocock

Astragentic writes no method of its own. It rents `mattpocock-skills` for the whole craft layer
(`wayfinder`, `grill-with-docs`, `to-spec`, `to-tickets`, `implement`, `code-review`) and wraps
the coordination layer around it. Version 1.0.0 removed the 19 skills that had been vendored
into this repo so the upstream plugin could own them, and ADR-0001 records that decision.

The reason is one short line in that ADR: that method loops at the front of the process, and I
had been looping at the end. Two weeks of field use produced plans that took 5 to 14 review-gate
rounds. Round 2 added a lock, round 3 cut it as false comfort, and round 8 was still repairing a
sentence round 2 had left behind. The reviewer was not where it broke. It broke upstream:
decisions that had never been settled went straight into code and got settled at the most
expensive point in the process. In that system `grilling` runs until the frontier of open
decisions is empty, and every review is a single bounded pass with no convergence condition.

On Superpowers, since that question always arrives attached to this one: it is a very good
system and my team genuinely uses it on another project. It simply sits at a different layer. It
packs the method and the coordination into one session: 14 skills, no roles, one `SessionStart`
hook, and work state living in a plan file inside the branch. Astragentic puts the state on a
tracker and splits roles along session boundaries. Superpowers carries the back half of the
spine well, and in places better; the front half has no equivalent of `to-tickets` producing
tracker tickets with blocking edges, and that tracker is the coordination substrate here.
Running both in one repo is not a problem of surplus skills either. It is two orchestrators
reaching for the same place: two worktree schemes, two state substrates, and a bootstrap that
teaches "do not pause to check in with your human partner" running straight into the handback
protocol here.

Renting has a real cost. `check-requirements.sh` fails hard without `mattpocock-skills >=
1.2.3`. The address `/mattpocock-skills:<name>` is hardcoded across the contracts, so changing
method means rewriting contracts rather than editing config. And I can patch the seam but not
the plugin: AST-057 is a defect inside `to-tickets`, and the right answer here was to teach the
contract to live with it rather than to fork a patched copy.

## why-not-subagents

Claude Code has subagents and it has agent teams, and they work. The question is not whether
they are usable, it is whether they can be the coordination layer. I tried, and the five missing
things are missing in the same way: none of them raise a signal when they go wrong.

The checkout is shared. A subagent runs in the same worktree as its parent session. AST-016
measured the consequence: agents sharing one checkout pull each other's HEAD around, and the
case that caught it was a read-only reviewer that `git switch`ed somebody else's checkout. "This
one only reads" was the exemption I had believed, and it was wrong. Isolation became
unconditional after that.

The context window is shared too. A fork inherits the parent's whole context, and with it things
I did not mean to hand over. AST-006: a fork inherited the parent's model too, overriding the
declared model ladder, so work that deserved a cheap model ran on the most expensive one with
nobody declaring anything. Worse, a fork inherits the dispatcher's address. AST-119 records a
fork inside a Builder sending the dispatcher a handback that arrived on that socket under that
name, and the Builder could not see it happen. The message carried a true technical fact about
the branch that the Builder itself did not know, so it could neither be dismissed as noise nor
trusted as testimony. AST-130 is the next step of the same class: a fork signed a
`simplify(increment):` marker over code it had committed itself, in the sanctioned form, caught
by no check, noticed only because the Builder saw a commit it had not made.

No tracker holds the state. A subagent's state lives in the parent session's context, which
means it vanishes when the session compacts, and while it is alive the owner cannot see it. The
owner does not run queries. They open the board and look. A frontier that is only computed and
never written back serves every agent perfectly and is invisible to the one person who cannot
compute it (AST-057).

There is no pane to look at, and this is the one that hurts most because it is the quietest.
AST-018 measured a dispatch that was narrated in text and never called; narrating a tool call is
not calling it, and no liveness signal separated the two. In one long downstream session that
compacted once, a ticket was dispatched as an in-process subagent instead of a visible pane, and
nobody noticed until the owner asked. A pane is countable. An in-process subagent is not.

And there is no second vendor: a subagent of Claude is still Claude. The cross-vendor arm needs
a model from another vendor to read the artifact, and no spawn mechanism inside one runtime
produces that.

Astragentic still uses forks inside a Builder for report-only work, and the rule that comes with
them is that such a fork gets `isolation: "worktree"` and must never message the dispatcher.
Subagents do useful work. They are just the wrong place to put the coordination layer.

This way costs more, and it costs plainly. You have to install herdr and you have to have a
properly configured tracker, two external dependencies a subagent does not need. Every Builder
costs a worktree on disk and a few seconds of setup. Every dispatch costs an extra tracker write
and a readback. There is also a cost no instrument measures: a longer pipeline and more names to
hold in your head. I pay it, because that vanished afternoon cost more.

## why-tracker

Work state has to live somewhere an agent cannot hold in its context and the owner can open and
look at. The tracker is the only place that satisfies both, which is why ADR-0001 calls it the
coordination substrate rather than a record.

Three things come from it. Blocking edges give a dependency graph, so "what is waiting on what"
is data rather than memory. The frontier query answers "what is ready right now." And the
assignee is the claim: writing a name onto a ticket before its worktree exists is what keeps two
concurrent sessions off each other, with no lock file, no queue, and no central dispatcher
deciding who goes first.

But a frontier that is only computed is invisible to whoever cannot compute it. AST-057 measured
this on a live project: across that project's entire life, no issue had ever entered the
unstarted state, and one ticket sat looking blocked for hours after both its blockers had
merged. Four tickets wore the ready label while blocked. No check the harness runs had ever
looked there; the owner caught it by comparing two boards by eye. So the contract now carries
both halves: write the computed answer back as state, and never read a readiness label as a
blocker.

The cost is that I inherit every limitation of whichever tracker you already run. No tracker has
an assignee field designed to hold `builder/<ticket-id>`. GitHub Issues has no real status
field, so status lives in a label and the Project board column is a mirror somebody has to keep
in sync. Every adapter therefore carries its own workarounds and its own measured traps. And
because the tracker is a substrate rather than a passive record, it can drift from reality: a
ticket can say `in-progress` with a live assignee long after its branch merged. That is what
`reconcile-tracker` is for, and it measures the tracker against git, never against itself,
because a wrong tracker state is perfectly self-consistent.

## why-cross-vendor

After Claude has finished and reviewed its own work, a model from a different vendor reads the
diff. That sounds redundant until you have the numbers.

AST-015: a same-vendor correctness review passed a defect that committed live secrets and buyer
PII into a tracked file, and the cross-vendor pass caught it and filed it P1. AST-012 draws the
general form: the two lenses catch different classes of defect, so they exist alongside each
other rather than replacing each other. Another case, measured on a large diff: a slice-scope
payload of 6,904 added lines across 31 files went through a same-vendor skim that missed three
hollow tests in a day, while a ticket-scope pass on a smaller diff caught a real deadlock that
the previous pass's own fix had just introduced.

The mechanism is simple: the arm reads the repository while the author reads the ticket. So what
it wins at is internal inconsistency against a project's own stated standard, which is exactly
what the person who wrote the code cannot see, because they are looking from the requirement
side.

The cost is invocation friction, and that friction is real. Quoting and argv differ between
runtimes. The direct `codex exec` path has been observed to hang silently, so it needs a timeout
and a dispatcher watching it. The sharpest one is scope: if `--base` and the resolved `HEAD`
disagree, the companion can compare a branch to itself and come back clean having reviewed zero
commits. So every scope prints its range header before anyone is allowed to trust the verdict.
