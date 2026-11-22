---
term: Harness
oneLiner: "The orchestration layer that coordinates several agents on one codebase without letting them collide."
order: 1
related: [role, tracker, worktree]
updated: 2026-11-22
harness: v6.1.19
---

**The harness is the framework Astragentic ships: the six roles, the `astra-*` skills, and the dispatch mechanics that let several AI agents build software on the same codebase without stepping on each other.**

It is not a product feature or a runtime — it's the thing you install into a repo. `get.sh` stages a tagged release into `<target>/.astraler/releases/<version>/`, and the current agent session then reads `ADAPT-RUNTIME.md` and wires it in. Once installed, the harness owns the parts that make concurrency safe: it assigns a [tracker](/dictionary/tracker/) ticket to a [role](/dictionary/role/) as a claim before that ticket gets a worktree, and it keeps every agent's writes isolated to its own checkout.

The distinction the README draws matters for reading anything else on this site: this repo is the **package** — it produces the harness. A project the harness gets installed into is the **adapted project**, and it keeps its own tracker, its own ledger of measured history, and its own project-specific decisions in files like `docs/agents/issue-tracker.md`. The harness carries the coordination mechanics; the project carries the facts about itself.

## Why it matters here

Running agents alone doesn't need this — one agent, one branch, no coordination problem. The moment you run several concurrently on a real codebase, the failure modes are specific and repeatable: agents overwrite each other's work, reviews loop for many rounds, nobody can say what actually ran. The harness exists to make those failures structurally hard rather than something you review for every time. The cost is real: it's another layer a project has to adopt and keep current — upgrading it is itself an event a project has to absorb, through `.astraler/astragentic.sh update`.

## Seen in:

- `README.md` — top-level description and quickstart (`get.sh`, `ADAPT-RUNTIME.md`)
- `harness/.claude/agents/` — the six roles

## Usage:

"Wait, is this bug in the harness or in our own tracker setup?" — "Harness. `dispatch-ticket` is claiming before the worktree exists, that's core mechanics, not our config."
