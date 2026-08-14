# Thomas — Codex runtime supplement

**Read `.agents/roles/thomas.md` (the base contract) first.** This file carries only what
differs when dispatching to Codex builders.

## Dispatch routing

Use `dispatch-ticket` (shared protocol) then `dispatch-ticket-codex` (Codex launcher).

## Simplify artifact verification

On Codex, `Skill(skill: "simplify")` does not exist, so the builder records a documented
skip. The valid `Pass:` line is:

`Pass: SKIPPED (runtime does not provide Skill(skill: "simplify"))`

Accept this as valid. `SKIPPED` on a Claude row is still a substitute (it means the builder
avoided the available tool); on a Codex row it is the correct outcome.
