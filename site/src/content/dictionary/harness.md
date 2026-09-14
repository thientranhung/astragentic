---
term: Harness
oneLiner: "The orchestration layer that coordinates several agents on one codebase without letting them collide."
order: 1
related: [role, tracker, worktree]
updated: 2026-09-04
---

**The harness is the framework Astragentic ships: the roles, skills, and dispatch mechanics that let several AI agents build software on the same codebase without stepping on each other.**

It is not a product feature or a runtime — it's the thing you install into a repo. `install.sh` stages it into `<target>/.astraler/releases/<version>/`, and from there an adaptive installer, `ADAPT-HARNESS.md`, inspects the project and wires it in. Once installed, the harness owns the parts that make concurrency safe: it assigns a [tracker](/dictionary/tracker/) ticket to a [role](/dictionary/role/) as a claim before that ticket gets a worktree, and it keeps every agent's writes isolated to its own checkout.

The distinction the README draws matters for reading anything else on this site: this repo is the **package** — it produces the harness. A project the harness gets installed into is the **adapted project**, and it keeps its own tracker, its own ledger of measured history, and its own project-specific decisions in files like `docs/agents/issue-tracker.md`. The harness carries the coordination mechanics; the project carries the facts about itself.

## Why it matters here

Running agents alone doesn't need this — one agent, one branch, no coordination problem. The moment you run several concurrently on a real codebase, the failure modes are specific and repeatable: agents overwrite each other's work, reviews loop for many rounds, nobody can say what actually ran. The harness exists to make those failures structurally hard rather than something you review for every time. The cost is real: it's another layer a project has to adopt and keep current — there's an `UNINSTALL-HARNESS.md` mirror for a reason, and upgrading it (2.7.15, 2.8.0, and so on) is itself an event a project has to absorb, sometimes uncovering defects the previous version's assumptions didn't hold.

## Seen in:

- `README.md` — top-level description and quickstart (`install.sh`, `ADAPT-HARNESS.md`)
- `docs/adr/0001-rebuild-the-method-around-matt-pocock-skills.md` — "this harness contributes... this harness extends the claim to build tickets"
- `docs/bmad-distilled/README.md` — the role-kit half of the method the harness builds on

## Usage:

"Wait, is this bug in the harness or in our own tracker setup?" — "Harness. `dispatch-ticket` is claiming before the worktree exists, that's core mechanics, not our config."
