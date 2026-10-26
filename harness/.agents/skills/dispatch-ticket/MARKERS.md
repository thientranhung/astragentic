# Verification markers — the mechanics

The one home for how a marker is written, retracted and checked. `builder.md` writes them and
runs the script before handback, `thomas.md` reads them at merge, and `CLEANUP.md` counts them
before a worktree is removed. The script is the arbiter, on every runtime:

```bash
scripts/check-simplify-markers.sh <base> <head> --marker 'simplify(increment)'   # exit 0 = green, 1 = STOP
scripts/check-simplify-markers.sh <base> <head> --marker 'arm(ticket)'   # omit when orchestrator.md arm row ticket = no
```

`--marker` is repeatable and the kind is data, so a new kind costs a flag, not a script. The
script prints one `STOP:` line per reason. The counts are a filter, not a verdict:
`markers == wellformed + superseded` says the shape is right, so read the bodies.

## The head check

**Existence is not relationship.** The newest marker of each kind must cover the head's tree,
within a fold allowance: up to 100 non-test content lines, cumulative over `<marker>..<head>`,
sit on top of a `simplify(increment)` marker without owing the pass again (the script prints
the delta as a NOTE; measured on 119 downstream merges, 106 fell inside it). Over the
allowance, the commits are code the pass never read, and every per-field check passes on them.
The answer to that STOP is one more pass (`/simplify <marker>..<head>`
<!-- addr-ok: the typed form, cited --> then a fresh marker), never an explanation. Markers may
be empty, so it costs one commit. Test files (the project's `test-file-pattern`) and
`marker-evidence-paths.txt` globs are outside the count.

The comparison is of trees, not commit counts: an empty `arm(ticket)` receipt committed after
`simplify(increment)` leaves the tree unchanged, so both kinds may be named in one call. A
committed arm log above the marker is declared in
`.astraler/project/marker-evidence-paths.txt` as a glob, and the script exempts it.
`arm(slice)` and `qa(walk)` stack on top of anything and are exempt.

## Retraction happens in the open

A marker you committed and now know is wrong is retracted by a new marker carrying the real
pass plus `Supersedes: <sha>`. Copy the SHA from `git log --format=%H`, never retype it. The
script enforces the chain: at most one `Supersedes:` per marker, a superseding marker must
itself be well-formed, the named SHA must be a marker in range named by only one marker, every
live marker is well-formed, and the newest live marker is the head. Retraction is green on
Thomas's side, deliberately cheaper than rewriting history.

## The `arm(ticket):` receipt

An **empty** commit at your head, so its parent is the tree the gate read:

```
arm(ticket): <ticket-id> — <verdict>, <n> passes

Range: <n> commits, <m> files (<base>..<head>)
Reviewed: <sha of the tree the gate read>
Vendor: <vendor>   Tests: RAN|NOT RUN <prose>   Pass: <n>
Unreviewed-delta: <from>..<to> — <n> lines, <m> files: <what changed, why it is safe>
```

`Pass: <n>` records the passes the arm ran (`builder.md` § arm caps it at two).

`Tests:` attests whether a GATE RUN stands behind this SHA, not whether the arm ran tests.
`RAN — <citation>` covers a gate that already covers this exact SHA, including a docs-only
diff ("RAN — <what you ran>; no code package touched, so no suite applies"). `NOT RUN —
<reason>` means a gate applies and none stands behind this SHA, so a merge on it is the
owner's call. Never write `NOT RUN` for "nothing applicable".

`Reviewed:` is this commit's parent, OR `Unreviewed-delta:` declares the gap. Never neither: a
fold moves the tree past what any pass read.

## `arm(slice)` and `qa(walk)` — the milestone receipts

`arm(slice)` is the receipt of the slice gate (the slice arm plus the adversarial fan-out).
`qa(walk)` is the receipt of QA's run. Each is an empty commit at the reviewed or walked head:

```
arm(slice): <slice-key> — <verdict>

Scope: slice <what>
Vendor: <vendor that ran the arm>
Verdict: PASS | BLOCKING | NON-BLOCKING (<n> blocking, <m> non-blocking)
Report: <absolute $GATE_FILE path, or where the arm and fan-out findings were folded>
```

`qa(walk):` has the same shape without `Vendor:`, plus `Mode: walk | probe | verify`, and its
`Verdict:` is the trace matrix's: `PASS | CONCERNS | FAIL`.

A milestone marker cannot appear in a ticket branch, so "none in this range" is true by
construction at every merge. Both are therefore advisory and measured ON THE BASE: the number
reported is merges on the base since the last marker of that kind.

```
[arm(slice)] last 3f9a1c2b0 (2026-08-27) — 5 merge(s) since it; scanned over main (advisory)
[arm(slice)] no marker found — scanned over main, which holds 42 merge(s) of history.
```

That figure rises with every merge and returns to zero when a round runs, so it can cross the
threshold `thomas.md` sets.
