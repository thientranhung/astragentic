# Verification markers — the mechanics

One home for how a marker is written, retracted and checked. `builder.md` writes them,
`thomas.md` and `rin.md` read them at merge, and `CLEANUP.md` counts them before a worktree is
removed. Three readers, one set of rules — restating them in each was how the prior package's
gate law drifted apart in five places.

The script is the arbiter, on every runtime:

```bash
scripts/check-simplify-markers.sh <base> <head> \
    --marker 'simplify(increment)' --marker 'arm(ticket)'   # exit 0 = green, 1 = STOP
```

`--marker` is repeatable and the kind is **data**, so a new marker kind costs a flag rather
than a second script.

## Existence is not relationship

**A marker that is not the head is the same finding wearing a green shirt.** Commits sitting on
top of it are code the pass never read, and **every per-field check passes on them** (AST-122).
Re-run the pass over the current head and commit a fresh marker. Markers may be empty, so this
costs exactly one commit — cheaper than arguing the fold was small.

## Retraction happens in the open

**If a marker you already committed is wrong, retract it in the open**: a new marker carrying
the real pass plus `Supersedes: <sha>`.

**Never retype a SHA — copy it from `git log --format=%H`.** A `Supersedes:` trailer once
shipped naming a commit that did not exist: correct short prefix, wrong trailing digits. A
hand-typed hash inside a machine-checked chain is a fabrication waiting to happen.

Retraction is a green state on Thomas's side and deliberately cheaper than rewriting history:
**the record showing you were wrong is worth more than a record that looks clean** (AST-121).

## Reading the counts

The counts are a **filter, not a verdict** — `markers == wellformed + superseded` says the shape
is right and says nothing about whether the superseding pass covered the same increment as the
marker it retracts. Read the bodies. A protocol that prices honesty above concealment gets
concealment, which is why retraction is cheap here rather than a documented exception (AST-121).

## Self-check before handback

Zero markers means the pass was skipped. **A step that does not self-check is a step that can be
silently skipped** (AST-094, the same shape as AST-092). The Builder runs the script above
before returning; Thomas runs it again at merge, because the mechanism that causes the skip also
displaces the self-check.

## The `arm(ticket):` receipt

The receipt is an **empty** commit at your head, so its parent is the tree the gate read.
`check-simplify-markers.sh` owns the rules; this is the shape:

```
arm(ticket): <ticket-id> — <verdict>, <n> passes

Range: <n> commits, <m> files (<base>..<head>)
Reviewed: <sha of the tree the gate read>
Vendor: <vendor>   Tests: RAN|NOT RUN <prose>   Pass: <n>
Unreviewed-delta: <from>..<to> — <n> lines, <m> files: <what changed, why it is safe>
```

**`Reviewed:` is this commit's parent, OR `Unreviewed-delta:` declares the gap. Never neither**
(AST-134): a fold moves the tree past what any pass read, so the equality is legitimately false
and the omission is the failure.

## `rin(gate)` and `qa(walk)` — the milestone receipts

**Why these exist, and it is the sharpest thing a downstream project has told this package.**
It counted, over 200 commits in one repo: 35 `arm(ticket):`, 22 `simplify(increment):`, and
**zero Rin rounds across 107 merges and 33 tickets**. Then it asked what separates the gates
that fire from the one that does not, and the answer is neither the trigger sentence nor the
counter:

> the gates that fire are the ones with a **physical artifact** that a script the router
> **already runs** refuses to proceed without.

Nobody remembers `arm(ticket)` or `simplify(increment)`; nobody can merge without them. Rin's
gate had a report file at a path outside every checkout, no marker in the merge range, and no
reader in the gating script — so *"more than 10 merges since the last Rin round is a STOP"* was
a quantity **nothing computed**, judged by a resident session whose context compacts, about an
event with no machine-detectable trace. That project had to invent a commit-subject grep to get
any number at all, and the closest match for "the last Rin round" turned out to be the ledger
entry recording that the gate had gone quiet.

The counter answered *"the router did not know the number."* The measured problem was
*"nothing was ever going to tell it."* Keep the counter; this is its emitter.

`qa(walk)` is here for the same reason and **before** the same evidence arrives: QA was given
that counter too, has a report file, and had no marker and no reader — the identical shape.

**Shape** — an empty commit at the reviewed or walked head:

```
rin(gate): <artifact-key> — <verdict>

Scope: <spec | ticket | slice> <what>
Verdict: PASS | BLOCKING | NON-BLOCKING (<n> blocking, <m> non-blocking)
Report: <absolute $GATE_FILE path, and its archived copy>
```

`qa(walk):` is identical in shape and carries the walk's verdict and report.

**Both are ADVISORY, and both are measured ON THE BASE — not in the merge range.** A milestone
marker cannot appear in a ticket branch, so "none in this range" is true by construction at
every merge. A project measured sixteen such lines across eight merges, every one structurally
guaranteed, and named the cost exactly: a line that is always right is wallpaper within a week,
and then it teaches its reader that absence is normal — which is what makes the one meaningful
absence invisible. **Loud-and-always is the same as silent.**

So the number reported is **merges on the base since the last marker of that kind**:

```
[rin(gate)] last on main: e479de492 (2026-08-27) — 5 merge(s) since (advisory)
[rin(gate)] never recorded on main — 42 merge(s) of history, no round
```

That figure rises with every merge and returns to zero when a round runs, so it can **cross a
threshold** — which `NONE in range` never could. It is what `thomas.md`'s "more than 10 merges
since the last Rin round" was asking for and nothing computed.
