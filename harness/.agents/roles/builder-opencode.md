# Builder — opencode runtime supplement

**Read `.agents/roles/builder.md` (the base contract) first.** This file carries only what
differs on the opencode runtime.

## Simplify

**On this runtime, `Skill(skill: "simplify")` does not exist.** The simplify phase is
SKIPPED, not substituted. Record it as:

```bash
git commit --allow-empty -m 'simplify(increment): SKIPPED — runtime opencode has no simplify built-in

Pass: SKIPPED (runtime does not provide Skill(skill: "simplify"))'
```

This is a documented absence, not a failure. Do not reach for a substitute — a substitute
leaves the same marker shape, so every check after it reads as satisfied (AST-055).

The commit subject still starts with `simplify(increment):` so Thomas's artifact grep
finds it.

## Context management

No `/compact` or `/clear` on this runtime. opencode's TUI manages context by scrolling.
Write a durable checkpoint when conversation grows long (same as base contract).
