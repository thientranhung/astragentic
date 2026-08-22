# Builder — Claude Code runtime supplement

**Read `.agents/roles/builder.md` (the base contract) first.** This file carries only what
differs on the Claude Code runtime.

## Simplify — Claude Code invocation

**Invoke `Skill(skill: "simplify")`** — model-invocable, no plugin prefix.
`/simplify` <!-- addr-ok: wrong form, cited --> is the human's form, which you cannot type;
`mattpocock-skills:simplify` does not exist and the call errors (AST-051).

**A failed invocation IS the finding.** Report the exact error to Thomas and stop — a
substitute leaves the same marker, so every check downstream reads as satisfied (AST-055).

**Fan-out failure is not invocation failure.** Two measured variants: fork unavailable
(`Fork is not available inside a forked worker`), and forks returning the coordinator's
narration (AST-098). In both, run the four corners directly inside that same invocation —
the skill completing degraded — and name the reason after ` — ` on the `Pass:` line. Only a
total invocation failure triggers stop-and-report (AST-089).

**Commit first, then fan out — and every report-only fork gets `isolation: "worktree"`.**
The two halves are one rule and shipping either alone trades one silent failure for another.

```
Agent(subagent_type: "...", isolation: "worktree", prompt: "...")   # report-only fan-out
```

A fork spawned into your checkout can write to it, and the write lands under your name on
your branch. Measured seven times, most recently a fork that committed the implementation
itself and then wrote a `simplify(increment):` marker over it carrying a **sanctioned
degraded `Pass:` line quoting the real runtime error string** — well-formed, unmalformed,
indistinguishable from a correct marker by inspection, caught by no check. The Builder
noticed a commit it had not made (AST-130). `isolation: "worktree"` puts the fork in its own
checkout, so an out-of-scope commit lands somewhere nobody merges.

**And that is exactly why the commit comes first.** A worktree carries content **at HEAD**,
so a fork reviewing uncommitted work sees an empty diff and returns clean — a vacuous pass
that looks identical to a real one (AST-036). Isolating the fork without committing first
swaps a forgery hole for a hole nobody can see at all. Commit, then fan out, every time.

**Your forks must never message anyone.** `isolation: "worktree"` closes the write path and
does nothing to the talk path. A fork inherits your session context including Thomas's
address; its `SendMessage` arrives on the same socket under your name, and **you cannot see
it**. Report-only means report-only on the talk path as well as the write path. State this in
the fan-out instruction; a fork reporting that it messaged someone is itself the finding —
say so and stop (AST-119).

**A marker whose parent carries implementation you did not narrate is the signal.** Forks
share your git identity, so no script can attribute a commit; this one is yours to ask
before you hand back (AST-130).

**Copy the `Pass:` line exactly** — Thomas verifies mechanically (AST-055, AST-090).

```bash
# Clean
git commit -m 'simplify(increment): <what was cleaned>

Pass: Skill(skill: "simplify")'

# Degraded — append reason after " — "
git commit -m 'simplify(increment): <what was cleaned>

Pass: Skill(skill: "simplify") — fork unavailable, ran four corners directly'

git commit -m 'simplify(increment): <what was cleaned>

Pass: Skill(skill: "simplify") — forks returned narration (AST-098), ran four corners directly'

# Empty (no findings)
git commit --allow-empty -m 'simplify(increment): no findings on <base>..<head>

Pass: Skill(skill: "simplify")'
```

## Background work

**Run gates in the foreground.** Background is for work someone else consumes; a turn that
ends while waiting on a result YOU need becomes PARKED, and Thomas must rescue it (AST-097).

**If `ScheduleWakeup` errors, do not park** — the notification will never arrive. Read the
result directly, retry, or report to Thomas (AST-097).

## Long tickets

`/compact` and `/clear` are CLI commands, not skills. Write a durable checkpoint before
`/compact`; `/clear` belongs between tickets, not inside one.
