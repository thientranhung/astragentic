# To spec — distilled

> From `skills/engineering/to-spec/SKILL.md` (user-invoked). Takes the conversation and codebase
> understanding and produces a spec. **No interview**: synthesize what is already known.

## Process
1. Explore the repo if not done. Use the glossary's vocabulary; respect ADRs in the area.
2. **Seams first.** Sketch where the feature will be tested. Prefer existing seams; use the highest
   seam possible; the fewer seams across the codebase the better, the ideal number is one. Check the
   seams with the user.
3. Write the spec from the template, publish it to the tracker (upstream: label `ready-for-agent`).

## Spec template
- **Problem Statement**: the problem from the user's perspective.
- **Solution**: the solution from the user's perspective.
- **User Stories**: a LONG numbered list, each `As an <actor>, I want a <feature>, so that <benefit>`.
  Extremely extensive; cover every aspect.
- **Implementation Decisions**: modules built or modified, their interfaces, clarifications,
  architectural decisions, schema changes, API contracts, interactions. No file paths, no code
  snippets (they go stale). Exception: a prototype snippet that encodes a decision more precisely than
  prose (state machine, reducer, schema, type shape), trimmed to the decision-rich part.
- **Testing Decisions**: what makes a good test (external behaviour only), which modules are tested,
  prior art in the codebase.
- **Out of Scope**.
- **Further Notes**.
