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
