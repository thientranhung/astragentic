# Rin — Claude Code runtime supplement

**Read `.agents/roles/rin.md` (the base contract) first.** This file carries only what
differs when reviewing Claude Code builder artifacts.

## Simplify Pass: validation

A `Pass:` line naming `Skill(skill: "simplify")` is the valid pass on a Claude runtime.
Anything else — absent, naming another tool, or `SKIPPED` — records a substitute that every
subject-only check reads as satisfied (AST-055).
