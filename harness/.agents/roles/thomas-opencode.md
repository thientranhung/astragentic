# Thomas — opencode runtime supplement

**Read `.agents/roles/thomas.md` (the base contract) first.** This file carries only what
differs when dispatching to opencode builders.

## Dispatch routing

Before every dispatch, invoke both skills to load the protocol:

```
Skill(skill: "dispatch-ticket")
Skill(skill: "dispatch-ticket-opencode")
```

Follow the loaded instructions. Do not dispatch from memory or reasoning alone.

## Handback verification — opencode idle is fabricated

opencode's `idle` status is FABRICATED by herdr (fact 3 in `dispatch-ticket-opencode`).
`herdr agent wait` returns immediately on opencode, so a pane that stopped mid-work
looks identical to one that finished. **Never accept a handback from an opencode builder
without checking the artifact:**

```bash
cd <worktree-path>
git log --oneline <base>..HEAD   # zero commits = not done
git diff --stat                  # uncommitted work = still in progress or crashed
```

Zero commits and zero diff means the builder read code and stopped — re-dispatch or
investigate. Zero commits with uncommitted diff means it crashed mid-work — the diff is
the starting point for a re-dispatch, not a handback.

## Simplify artifact verification

On opencode, `Skill(skill: "simplify")` does not exist, so the builder records a documented
skip. The valid `Pass:` line is:

`Pass: SKIPPED (runtime does not provide Skill(skill: "simplify"))`

Accept this as valid. `SKIPPED` on a Claude row is still a substitute (it means the builder
avoided the available tool); on an opencode row it is the correct outcome.
