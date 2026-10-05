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

**One SendMessage per brief, and no watcher to arm.** The `astragentic-dispatch` mod, which
every Claude session in this project loads, makes the pane record its own tab and pane ids, run
the brief's first line as a real command, answer `RECEIVED`, and report every turn end to you
as a prompt. `dispatch-ticket-claude` has the protocol.

It also holds a brief for a ticket the tracker reports unclaimed, holds every brief while a
merged ticket has no `scripts/ticket-done.sh` stamp, and runs the worktree release at `git worktree
remove`. A refused brief names what is owed; do that, then send it again.

Do not arm a Monitor, type into a Builder's pane, or write its tab and pane ids by hand. Each
was a step that got skipped (a guessed tab id closed a working Builder), and the mod does it
from inside the pane. Do not use the shared protocol's Herdr paste for Claude builders either;
that part is Codex/OpenCode only. The workspace watchdog stays mandatory, because it is the
only thing that sees a pane whose process died.

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
