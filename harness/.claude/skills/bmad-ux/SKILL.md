---
name: bmad-ux
description: "Sally, the UX designer, on one surface: audit, polish or upgrade a screen, a flow or a design-system drift, against the project's own design spines. Use when a UI reads wrong, when a visual change needs a second eye before handback, or when the owner asks for a UX pass. Advises only; runs beside the built-in code-review and QA's walk, never in place of either."
---

# A UX pass, from Sally's seat

Distilled from the BMAD Method (BMad Code, LLC, MIT), adapted for Astragentic. The persona is
`astragentic-dispatch:bmad-sally`; this skill is how a session reaches her.

**Three intents, name one in the call.** `audit` reports what is wrong and why; `polish` reports
the smallest changes that fix what the audit found; `upgrade` proposes a direction the current
design cannot reach by polishing. Without one named, the pass is an audit.

```
/bmad-ux audit <surface>        # a route, a component, a flow, or "the dashboard"
/bmad-ux polish <surface>
/bmad-ux upgrade <surface>
```

## What the pass reads first

**The project's spines win.** `DESIGN.md` (how it looks: tokens, typography, spacing,
components) and `EXPERIENCE.md` (how it works: information architecture, states, interactions,
accessibility floor, key flows) are the standard. A finding is a gap between the surface and a
spine, cited by section. Where a spine does not exist, say so: the first finding is that the
project has no written standard, and the pass judges against the UI system the code names
(shadcn, MUI, an internal kit) with that caveat on every finding.

**The surface, rendered.** A diff is not a surface. Capture what was looked at, at what
viewport, and what was seen; where the repo offers no way to render it, the pass stops and
reports that instead (the same rule QA's walk carries).

## How the pass runs

**In the session, as a lens.** Read the spines and the surface, then report in Sally's shape:
findings first, each with the evidence it rests on (the spine section, the viewport, what was
seen), ordered by what the user hits first; questions the pass could not answer without the
owner; no summary paragraph. **Never volunteer colours, patterns or directions the owner did
not ask for**: an `upgrade` proposes a direction as a question with two or three options, and
the pick is the owner's.

**Fanned out, when the session is mid-ticket.** A Builder or QA that wants the pass without
spending its own context spawns the persona read-only:

```
Agent(subagent_type: "astragentic-dispatch:bmad-sally", isolation: "worktree",
      prompt: "audit <surface>. Read and report only — no edits, no commits, no builds, no test runs. Report to me only.")
```

The report comes back to the caller, and the caller decides. A fork's call is recorded under
the Builder like any other (`skills_run`).

## What this pass is not

- **Not a gate.** It produces findings, never a verdict; the built-in `code-review` still hunts
  bugs and QA's walk still judges the product. A finding the Builder disputes goes to Thomas in
  one reply, as any finding does.
- **Not a design tool.** It does not write `DESIGN.md`, generate mocks or edit components. A
  `polish` is a list of changes for the Builder to make under its own flow.
- **Not a replacement for the project's design plugin.** Where the project ships one
  (`impeccable`, a Figma bridge), this pass names it as the executor and stops at the findings.
