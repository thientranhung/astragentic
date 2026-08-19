# Builder — Claude Code runtime supplement

**Read `.agents/roles/builder.md` (the base contract) first.** This file carries only what
differs on the Claude Code runtime.

## Simplify — Claude Code invocation

**Invoke `Skill(skill: "simplify")`** — model-invocable.
`/simplify` <!-- addr-ok: wrong form, cited --> is the human's form, which you cannot type.

**No plugin prefix.** `simplify` ships with Claude Code, so `mattpocock-skills:simplify`
does not exist and the call errors (AST-051).

**If the invocation fails, the failure IS the finding.** Report the exact error to Thomas and
stop — a substitute leaves the same marker, so every check reads as satisfied (AST-055).

**Fan-out failure is not invocation failure.** Two measured variants:
- **Fork unavailable** — `Fork is not available inside a forked worker`.
- **Forks return narration** — forks return the coordinator's status chatter (AST-098).

Running the four corners directly inside that same invocation is the skill completing
degraded. The `Pass:` line names the reason after ` — `. Only a total invocation failure
triggers stop-and-report (AST-089).

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

**Run gates in the foreground.** Do not background a command whose result YOU need to finish
your work. Background is for work where SOMEONE ELSE consumes the result. A turn that ends
while waiting becomes PARKED, and Thomas must rescue it (AST-097).

**If `ScheduleWakeup` errors, do not park.** A failed schedule means the notification will
never arrive. Read the result directly, retry, or report to Thomas (AST-097).

## Long tickets

`/compact` and `/clear` are CLI commands, not skills. Write a durable checkpoint before
`/compact`; `/clear` belongs between tickets, not inside one.
