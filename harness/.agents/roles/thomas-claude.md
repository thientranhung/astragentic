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

The mod does the arming, typing and id-recording from inside the pane
(`dispatch-ticket-claude` § Submitting).

## Simplify artifact verification

One marker per increment. A `Pass:` line that starts with `Skill(skill: "simplify")` is the
pass — with or without a fallback suffix. Both of these are valid:

```
Pass: Skill(skill: "simplify")
Pass: Skill(skill: "simplify") — fork unavailable, ran four corners directly
```

The second form means the skill ran but its internal fan-out could not fork. Running the four
review corners directly inside the invocation is degraded completion, not a substitute. A
`Pass:` line that does not start with `Skill(skill: "simplify")` is a substitute, and an
absent one is unverified. Both go back to the Builder. The subject alone cannot tell them
apart, and a handback describing a pass with no marker on the branch is a substitute too.
