# Thomas — Claude Code runtime supplement

**Read `.agents/roles/thomas.md` (the base contract) first.** This file carries only what
differs when dispatching to Claude Code builders.

## Dispatch routing

Before every dispatch, invoke both skills to load the protocol:

```
Skill(skill: "dispatch-ticket")
Skill(skill: "dispatch-ticket-claude")
```

Follow the loaded instructions. Do not dispatch from memory or reasoning alone.

After submitting the brief and confirming `working`, start the watcher immediately:

```bash
<repo-root>/scripts/herdr-watch-terminal.sh <pane-id> 3 3600 120
```

This is the ONLY way to monitor a dispatched pane. Do not write your own loop.

## Simplify artifact verification

One marker per increment. A `Pass:` line that starts with `Skill(skill: "simplify")` is the
pass — with or without a fallback suffix. Both of these are valid:

```
Pass: Skill(skill: "simplify")
Pass: Skill(skill: "simplify") — fork unavailable, ran four corners directly
```

The second form means the skill ran but its internal fan-out could not fork (measured: a
Builder dispatched into a Herdr pane is a forked worker, and nested forks are unavailable
there). Running the four review corners directly inside the invocation is degraded completion,
not a substitute (AST-089). A `Pass:` line that does not start with `Skill(skill: "simplify")`
is a substitute, and an absent one is unverified. Both go back to the Builder.

A subject alone cannot tell them apart, and a Builder whose invocation errored fell back to
another tool, committed the same marker, and passed every check after it (AST-055). A
handback describing a pass that left no marker is a substitute too, and reads as honest
because it is (AST-051).
