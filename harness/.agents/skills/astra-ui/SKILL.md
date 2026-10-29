---
name: astra-ui
description: "A UI pass on one rendered surface against the project's DESIGN.md and the ticket's Glance and States: audit what reads wrong, polish with the smallest fixes, or propose an upgrade as a question. Use when a Builder's FLOW names it, when QA's walk finds a surface that reads wrong, or when the owner asks for a UI pass. Advises only; never a gate, never a design tool."
---

# A UI pass

**Three intents, name one.** `audit` reports what is wrong and why; `polish` the smallest
changes that fix what the audit found; `upgrade` a direction the current design cannot reach by
polishing, put as a question with two or three options, the pick is the owner's. Unnamed = audit.

```
Skill(skill: "astra-ui", args: "audit <surface>")      # a route, a component, a flow, or "the dashboard"
Skill(skill: "astra-ui", args: "polish <surface>")
Skill(skill: "astra-ui", args: "upgrade <surface>")
```

## What the pass reads first

**`DESIGN.md` wins.** The project's design spine (tokens, typography, spacing, components,
Do's and Don'ts) is the standard; a finding is a gap between the surface and a section of it,
cited. No `DESIGN.md`: the first finding is that the project has no written standard, and the
pass judges against the UI system the code names (shadcn, MUI, an internal kit) with that
caveat on every finding.

**The ticket's Glance and States are the checklist.** Each Glance line: does the must-see win
in two seconds in that actor's seat, does the rest recede? A must-see that loses is **P0**,
not polish. Each States line: rendered, looked at, matches the ticket's words. A state the
ticket lists and the surface cannot show is a finding; a state the surface has and the ticket
does not list is a question for the ticket's author.

**The surface, rendered.** A diff is not a surface. Record what was looked at, at what
viewport, and what was seen. Where the repo offers no way to render it, stop and report that
(QA's walk carries the same rule).

## How it runs

**In the session, as a lens**: findings first, each with its evidence (the `DESIGN.md`
section, the Glance or States line, the viewport, what was seen), ordered by what the actor
hits first; then the questions only the owner can answer; no summary paragraph. Never
volunteer colours, patterns or directions the owner did not ask for.

**Fanned out, mid-ticket**: a Builder or QA that wants the pass without spending its own
context calls `Skill(astra-ui)` first, then spawns the lens read-only from within it:

```
Agent(subagent_type: "astragentic-dispatch:astra-ui-lens", isolation: "worktree",
      prompt: "audit <surface>. Read and report only — no edits, no commits, no builds, no test runs. Report to me only.")
```

The report returns to the caller, who decides. Only the `Skill(astra-ui)` call is recorded in
`skills_run` and lights the `ui` chip; an `Agent` spawn alone leaves no record.

## What this pass is not

- **Not a gate.** Findings, never a verdict; `astra-review` hunts bugs and QA's walk judges
  the product. A disputed finding goes to Thomas in one reply.
- **Not a design tool.** It writes no `DESIGN.md`, no mock, no component. A `polish` is a list
  of changes for the Builder to make under its own loop.
- **Not the project's design plugin.** Where one ships (`impeccable`, a Figma bridge), name it
  as the executor and stop at the findings.
