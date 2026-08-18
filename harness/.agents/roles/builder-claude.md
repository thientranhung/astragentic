# Builder — Claude Code runtime supplement

**Read `.agents/roles/builder.md` (the base contract) first.** This file carries only what
differs on the Claude Code runtime.

## Simplify

**Each increment gets one simplify pass over its own diff, after the build is green.**
**Invoke `Skill(skill: "simplify")`** — model-invocable, and
`/simplify` <!-- addr-ok: wrong form, cited --> is the human's form, which you cannot type.

**The name carries no plugin prefix, because it comes from another system.** The rows above it
are the plugin's; `simplify` ships with Claude Code, so `mattpocock-skills:simplify` does not
exist and the call errors — measured, on a Builder that had just invoked
`mattpocock-skills:implement` and generalised the namespace one row down.

**If the invocation fails, the failure IS the finding.** Report the exact error to Thomas and
stop; do not reach for the `code-simplifier` agent, another skill, or your own pass — a
substitute leaves the same marker, so every check after it reads as satisfied (AST-055).

**A fan-out failure inside a started invocation is not an invocation failure.** If
`Skill(skill: "simplify")` runs but its internal parallel review cannot fork — measured as
`Fork is not available inside a forked worker`, from a Builder dispatched into a Herdr pane —
running the four review corners directly, inside that same invocation, is the skill completing
degraded, not you substituting for it. The `Pass:` line still names the skill, with the
fallback named:

```
Pass: Skill(skill: "simplify") — fork unavailable, ran four corners directly
```

Only a total invocation failure — the skill never starts, or errors before any review runs —
triggers the stop-and-report rule above (AST-089).

The artifact is a commit on your branch, and its body names what ran:

```bash
git commit -m 'simplify(increment): <what was cleaned>

Pass: Skill(skill: "simplify")'
```

A pass that finds nothing takes the same body with `--allow-empty`, subject
`simplify(increment): no findings on <base>..<head>`. An empty pass is legitimate; the marker is
the artifact because an empty and an absent pass are otherwise indistinguishable in the tree.
Thomas verifies by artifact —
`git log <base>..<head> --grep '^simplify(increment):' --format='%h %s%n%b'`.

**Write in `Pass:` what actually ran, not what was supposed to.** Every measured failure here
ended with an honest handback and a silent artifact, and this line is where that honesty has to
land: prose is not what the gate reads.

The skill carries what counts as a cleanup; two limits are this contract's. Anything that would
change behaviour is a **finding for Thomas**, and a cleanup touching a floor item's construction
line is reported instead.

## Long tickets

When the conversation grows long, write a durable checkpoint **before** `/compact` — branch and
SHA, WIP state, criteria passed, exact validation results, blockers, next action — into the
tracker or the handoff artifact, then re-ground from it plus `git log` and the current diff.
Auto-compaction carries the same requirement. `/clear` belongs between tickets: inside one it
discards the working thread, and it is not cwd, branch, worktree or lifecycle cleanup.
