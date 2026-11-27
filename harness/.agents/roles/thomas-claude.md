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

