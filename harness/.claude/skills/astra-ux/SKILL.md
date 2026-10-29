---
name: astra-ux
description: "Capture the owner's user journeys before any spec is written: who the actors are, what each one does on which surface, what they must see, and the states a surface can be in. Writes journeys UJ-n and actors into the project's PRD so the Shaper and every ticket use the same names. Use in the pane where the owner speaks (BA or Thomas) when an effort changes a surface someone looks at. Captures, never authors."
---

# UX: journeys from the owner's mouth

Journeys are **captured, not authored**. The owner narrates a real session; you structure it.
Never volunteer colours, patterns or a direction; if seeing helps, ask the owner for a
screenshot or a sketch, do not make one.

## When to run, when to skip

Run when the effort changes a surface a person looks at and the PRD has no journey for it, or
has one that no longer matches what the owner describes. Skip only when the owner says the
surface is an internal single-operator tool and names that operator; write that line in the PRD.

## Rounds

Use the frontier rounds of `astra-grill-with-docs`: ask the whole frontier, numbered, each
with a recommended reading of what the owner just said, so "yes" confirms it. Facts are yours
(what the code renders today, which routes exist); decisions are the owner's.

1. **Who.** Each actor by the name the project already uses. A new actor gets a name here and
   nowhere else; more than four is a sign of persona theatre, ask which two matter.
2. **The session.** "Tell me about the last time <actor> did this": entry state, the path in
   three to five beats, the climax (the moment the job is done or fails), the resolution.
   Persona context lives inline at the beats where it matters, never in a separate section.
3. **Form factor and stakes.** Desktop, mobile, extension, print; hobby, internal, launch,
   regulated. This decides how heavy the PRD gets.
4. **What must win.** For each surface in the journey: the one thing <actor> must see in two
   seconds, and what recedes. Two must-sees mean two surfaces or an undecided priority.
5. **States.** For each surface: empty, loading, error, partial, permission-denied, and any the
   owner names. What the actor sees in each. "Cannot happen" is an answer, with why.

## Write to the PRD

`docs/prd.md`, or the project's existing PRD. Create it with the sections below when there is
none; otherwise update in place, **ids never renumbered or reused**.

```markdown
# PRD — <project>
## Journeys
### UJ-1 · <Actor> <doing the thing>
<Actor>, <context in one line>. Entry: … Path: 1 … 2 … 3 … Climax: … Resolution: …
Surfaces: <name> — must see <X> first; states: empty …, loading …, error …, partial …, permission-denied ….
## Glossary
<term> — <definition>   (every domain noun once; FRs and tickets use it verbatim)
## Requirements
FR-1. <Actor> can <capability> <under conditions>. Realizes UJ-1.
## Non-goals
## Open questions
```

Requirements are written by the Spec phase; here you add only the FR lines the owner states
outright. Everything you could not get from the owner is an `Open question`, numbered.

## Hand off

Return the PRD path, the UJ ids touched, the actor names, and the open questions. The Shaper's
`astra-to-spec` reads the PRD for actor names; `astra-to-tickets` turns "must see" and
"states" into each ticket's Glance and States. You write no `DESIGN.md`, no mock, no ticket.
