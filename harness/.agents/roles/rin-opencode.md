# Rin — opencode runtime supplement

**Read `.agents/roles/rin.md` (the base contract) first.** This file carries only what
differs when reviewing opencode builder artifacts.

## Simplify Pass: validation

On an opencode runtime, `Skill(skill: "simplify")` does not exist. The valid `Pass:` line is:

`Pass: SKIPPED (runtime does not provide Skill(skill: "simplify"))`

This is a documented absence, not a substitute. An absent `Pass:` line, or one naming a
different tool, is still a substitute (AST-055).
