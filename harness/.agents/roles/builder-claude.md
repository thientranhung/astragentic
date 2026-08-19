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

**A fan-out failure inside a started invocation is not an invocation failure.** Two measured
variants:
- **Fork unavailable** — `Fork is not available inside a forked worker`, from a Builder
  dispatched into a Herdr pane.
- **Forks return narration** — forks launch but return the coordinator's own turn-by-turn
  status chatter instead of doing the assigned review (AST-098). Three builders in one
  session hit this on three unrelated tickets.

In both cases: running the four review corners directly, inside that same invocation, is the
skill completing degraded, not you substituting for it. The `Pass:` line still names the
skill, with the reason after a ` — `:

```
Pass: Skill(skill: "simplify") — fork unavailable, ran four corners directly
Pass: Skill(skill: "simplify") — forks returned narration (AST-098), ran four corners directly
```

Only a total invocation failure — the skill never starts, or errors before any review runs —
triggers the stop-and-report rule above (AST-089).

The artifact is a commit on your branch. **Copy the `Pass:` line below exactly** — Thomas
verifies it mechanically, and anything that does not start with `Skill(skill: "simplify")`
fails verification and comes back to you (AST-055).

**Clean run** (fan-out worked, or no fan-out needed):

```bash
git commit -m 'simplify(increment): <what was cleaned>

Pass: Skill(skill: "simplify")'
```

**Degraded run** (fork unavailable or forks returned narration — append the reason after ` — `):

```bash
git commit -m 'simplify(increment): <what was cleaned>

Pass: Skill(skill: "simplify") — fork unavailable, ran four corners directly'
```

```bash
git commit -m 'simplify(increment): <what was cleaned>

Pass: Skill(skill: "simplify") — forks returned narration (AST-098), ran four corners directly'
```

**Empty run** (no findings):

```bash
git commit --allow-empty -m 'simplify(increment): no findings on <base>..<head>

Pass: Skill(skill: "simplify")'
```

The `Pass:` line is what the gate reads. Not `/simplify` <!-- addr-ok: wrong form, cited --> (the human's form), not `DEGRADED`
(a description of the situation), not prose about what you did — the literal tool-call
spelling above. Two out of three Builders who ran the pass correctly wrote it a different way
and were bounced on typography (AST-090). Copy it; do not rephrase it.

The skill carries what counts as a cleanup; two limits are this contract's. Anything that would
change behaviour is a **finding for Thomas**, and a cleanup touching a floor item's construction
line is reported instead.

## Background work

**Run gates in the foreground.** Do not background a command whose result YOU need to
finish your work — tests you must pass before committing, builds you must verify before
pushing. Background is for work where SOMEONE ELSE consumes the result. A turn that ends
while waiting for its own gate result becomes PARKED, and Thomas must rescue it — measured
on two independent builders (TRA-207, TRA-170) in one session, both pushing `make
itest-local` to the background then parking to wait for a notification. Neither had anything
broken; the model naturally backgrounds long-running commands. The cost: a running turn is
one Thomas can see; a turn that ended while waiting is one Thomas has to go find and save
(AST-097).

**If `ScheduleWakeup` or any scheduling/notification mechanism errors, do not park.** A
failed schedule command means the notification will never arrive — parking to wait for it
creates a permanently-parked state indistinguishable from normal PARKED (AST-097). Read the
result directly, retry the operation, or report to Thomas. A builder that says "I'll wait
for the notification" after the scheduling call errored is committed to waiting forever.

## Long tickets

When the conversation grows long, write a durable checkpoint **before** `/compact` — branch and
SHA, WIP state, criteria passed, exact validation results, blockers, next action — into the
tracker or the handoff artifact, then re-ground from it plus `git log` and the current diff.
Auto-compaction carries the same requirement. `/clear` belongs between tickets: inside one it
discards the working thread, and it is not cwd, branch, worktree or lifecycle cleanup.
