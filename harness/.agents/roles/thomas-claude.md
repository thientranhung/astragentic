# Thomas — Claude Code runtime supplement

**Read `.agents/roles/thomas.md` (the base contract) first.** This file carries only what
differs when dispatching to Claude Code builders.

## Dispatch routing

Use `dispatch-ticket` (shared protocol) then `dispatch-ticket-claude` (Claude launcher).

## Simplify artifact verification

One marker per increment. A `Pass:` line naming `Skill(skill: "simplify")` is the pass;
anything else is a substitute, and an absent one is unverified. Both go back to the Builder.

A subject alone cannot tell them apart, and a Builder whose invocation errored fell back to
another tool, committed the same marker, and passed every check after it (AST-055). A
handback describing a pass that left no marker is a substitute too, and reads as honest
because it is (AST-051).
