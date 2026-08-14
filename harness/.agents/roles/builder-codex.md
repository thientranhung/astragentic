# Builder — Codex runtime supplement

**Read `.agents/roles/builder.md` (the base contract) first.** This file carries only what
differs on the Codex runtime.

## Simplify

**On this runtime, `Skill(skill: "simplify")` does not exist.** The simplify phase is
SKIPPED, not substituted. Record it as:

```bash
git commit --allow-empty -m 'simplify(increment): SKIPPED — runtime codex has no simplify built-in

Pass: SKIPPED (runtime does not provide Skill(skill: "simplify"))'
```

This is a documented absence, not a failure. Do not reach for a substitute — a substitute
leaves the same marker shape, so every check after it reads as satisfied (AST-055).

The commit subject still starts with `simplify(increment):` so Thomas's artifact grep
finds it.

## Context management

This runtime has no `/compact` or `/clear`. Context grows until the session ends.
When the conversation grows long, write a durable checkpoint — branch and SHA, WIP state,
criteria passed, exact validation results, blockers, next action — into the tracker or the
handoff artifact, then re-ground from it plus `git log` and the current diff.
