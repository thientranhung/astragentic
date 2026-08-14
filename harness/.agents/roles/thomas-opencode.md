# Thomas — opencode runtime supplement

**Read `.agents/roles/thomas.md` (the base contract) first.** This file carries only what
differs when dispatching to opencode builders.

## Dispatch routing

Use `dispatch-ticket` (shared protocol) then `dispatch-ticket-opencode` (opencode launcher).

## Simplify artifact verification

On opencode, `Skill(skill: "simplify")` does not exist, so the builder records a documented
skip. The valid `Pass:` line is:

`Pass: SKIPPED (runtime does not provide Skill(skill: "simplify"))`

Accept this as valid. `SKIPPED` on a Claude row is still a substitute (it means the builder
avoided the available tool); on an opencode row it is the correct outcome.
