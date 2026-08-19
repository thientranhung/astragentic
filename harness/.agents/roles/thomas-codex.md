# Thomas — Codex runtime supplement

**Read `.agents/roles/thomas.md` (the base contract) first.** This file carries only what
differs when dispatching to Codex builders.

## Dispatch routing

Before every dispatch, invoke both skills to load the protocol:

```
Skill(skill: "dispatch-ticket")
Skill(skill: "dispatch-ticket-codex")
```

Follow the loaded instructions. Do not dispatch from memory or reasoning alone.

Immediately after submitting the brief, start the watcher — do not confirm `working`
first, the script's own start guard is that step and answers `NO_START`:

```bash
<repo-root>/scripts/herdr-watch-terminal.sh <pane-id> 3 3600 120
```

This is the ONLY way to monitor a dispatched pane. Do not write your own loop.

## Simplify artifact verification

On Codex, `Skill(skill: "simplify")` does not exist, so the builder records a documented
skip. The valid `Pass:` line is:

`Pass: SKIPPED (runtime does not provide Skill(skill: "simplify"))`

Accept this as valid. `SKIPPED` on a Claude row is still a substitute (it means the builder
avoided the available tool); on a Codex row it is the correct outcome.
