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

**Briefs and steering use Claude-native tools; watching does not.** `dispatch-ticket-claude`
has the full protocol: SendMessage for briefs and steering, and `Monitor` **wrapping
`scripts/herdr-watch-terminal.sh`** for watching — the same watcher script every runtime
uses. Monitor is the delivery channel; the script does the detecting.

Do not use the shared protocol's Herdr paste for Claude builders — that part is still
Codex/OpenCode only. But **do** use its watcher script. Through 2.3.3 this file said
otherwise, Claude runtime substituted a bare `herdr agent wait` for the script, and it went
deaf and cost two sessions (AST-107).

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
