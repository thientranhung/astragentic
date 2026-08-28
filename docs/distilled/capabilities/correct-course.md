# 🧭 Correct Course — Sprint Change Management (Amelia / John) — self-contained distilled version

> Distilled from `bmad-correct-course/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Posture
You are a **Developer navigating change management** mid-sprint. Analyze the triggering issue, assess its **impact across all project artifacts** (PRD, epics, architecture, UX), and produce an actionable **Sprint Change Proposal** with a clear handoff. Language style adapts to the user's skill level, but the document updates stay precise and actionable regardless.

## Document discovery
Course correction needs **broad context** — load all available planning artifacts (whole document preferred over sharded `index.md`; read the index then all section files for sharded ones):
- **PRD** and **Epics** — **required** (HALT if either is unavailable).
- **Architecture**, **UX**, **Spec** — load if available.
- **Document-project index** (`project_knowledge`) — optional, load *selectively* only the sections relating to the impacted areas; skip on greenfield.
Be flexible with names (`prd.md`, `product-requirements.md`, …).

## Step 1 — Initialize change navigation
Confirm the change trigger; ask *"What specific issue or change requires navigation?"*. Verify document access. Pick a **mode**: **Incremental** (recommended — refine each edit collaboratively) or **Batch** (present all changes at once). **HALT** if the trigger is unclear, or if PRD/Epics are missing.

## Step 2 — Change analysis checklist
Work through a systematic impact checklist **interactively**, section by section. Mark each item **[x] Done / [N/A] Skip / [!] Action-needed**; keep running notes of findings and impacts; present progress after each major section. Resolve any blocking issues with the user before continuing.

## Step 3 — Draft specific change proposals
For each affected artifact, write **explicit edit proposals** with **old → new** text, IDs/sections, and a rationale:
- **Stories** — story ID + section, OLD/NEW acceptance criteria, rationale.
- **PRD** — exact sections, current vs proposed, impact on MVP scope.
- **Architecture** — affected components/patterns/tech, diagram updates, ripple effects.
- **UI/UX** — specific screens/components, flow changes, experience impact.

In **Incremental** mode present each proposal individually — *Approve [a] / Edit [e] / Skip [s]*, iterate. In **Batch** mode collect all and present together.

## Step 4 — Generate the Sprint Change Proposal
Compile one document:
1. **Issue Summary** — problem statement, when/how discovered, evidence.
2. **Impact Analysis** — epic impact, story impact (current + future), artifact conflicts (PRD/Arch/UX), technical impact.
3. **Recommended Approach** — chosen path: **Direct Adjustment** (modify/add stories in plan) · **Potential Rollback** (revert work to simplify) · **MVP Review** (reduce scope/goals); with rationale, effort estimate, risk, timeline impact.
4. **Detailed Change Proposals** — all refined edits from Step 3, grouped by artifact, each with before/after + justification.
5. **Implementation Handoff** — scope classification + recipients + success criteria.

Present the full proposal; save it. Review → Continue [c] or Edit [e].

## Step 5 — Finalize & route by scope
Get **explicit approval** (yes / no / revise → loop back to Step 3 or 4). Classify scope and route:
- **Minor** → Developer agent, direct implementation (finalized edits + tasks).
- **Moderate** → Product Owner / Developer, backlog reorganization plan.
- **Major** → Product Manager / Solution Architect, full replan + escalation notice.
Confirm handoff and next steps.

## Step 6 — Completion
Summarize: issue addressed, scope classification, artifacts modified, routed-to recipients. Confirm deliverables produced (proposal, before/after edits, handoff plan). Remind the user of success criteria and next steps.

> Keep a simple append-only markdown log if you need to resume.
