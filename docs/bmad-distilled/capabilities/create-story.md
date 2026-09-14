# 📝 Create Story (Amelia) — self-contained distilled version

> Distilled from `bmad-create-story/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Posture — you are a "story context engine"
The purpose is NOT to copy from epics — but to create an optimal, comprehensive story file that gives the DEV agent EVERYTHING it needs to implement perfectly.
- **LLM dev failures to prevent**: reinventing the wheel, wrong library, wrong file location, breaking regression, ignoring UX, ambiguous implementation, lying about completion, not learning from prior work.
- **Exhaustive analysis**: you must thoroughly analyze EVERY artifact — don't be lazy / skim. This is the most important function of the whole dev process.
- Use parallel subagents/subprocesses to analyze multiple artifacts at once.
- **Save questions for the end** (after the story is written). **Zero user intervention** except the initial epic/story selection or missing docs.

## Step 1 — Identify target story
- User gives a path or epic-story number (2-4 / 1.6 / "epic 1 story 5") → parse `epic_num`, `story_num`, `story_key` → go to step 2.
- No sprint-status file → offer: run sprint-planning (recommended) / provide epic-story number / provide docs path / quit.
- Auto-discover: read the FULL `sprint-status.yaml` in order, find the FIRST story with status `backlog` (key `N-M-name`, not epic/retrospective). None → offer sprint-planning / correct-course to add a story / retrospective; HALT.
- Extract `epic_num` / `story_num` / `story_title` from the key. If it's the first story of an epic (`{epic}-1-*`): epic `backlog` (or legacy `contexted`) → `in-progress`; epic `done` → ERROR HALT (don't create a story in a finished epic); unexpected status → ERROR HALT.

## Step 2 — Load & analyze core artifacts (🔬 exhaustive)
Load epics/prd/architecture/ux (the epics file should hold most; prd/arch/ux are fallback) + project-context facts. From epics extract:
- **Epic analysis**: business goal & value, ALL stories in the epic (cross-story context), requirements/constraints/dependencies, source hints to origin docs.
- **Story foundation**: user story (As a/I want/so that), detailed AC (already BDD), the story's own technical requirements, success criteria.
- **Previous story intelligence** (if `story_num>1`): load the previous story in the same epic (highest number < current) → extract dev notes/learnings, review feedback, files & patterns created, what tested effectively/didn't, problems & solutions, code patterns established.
- **Git intelligence** (if there's a previous story + git): view the 5 most recent commits → files, patterns/conventions, dependencies added/changed, architectural decisions, testing approach → extract actionable insight.

## Step 3 — Architecture analysis (🏗️ guardrails for dev)
Load architecture (single or sharded index). For each section, determine whether it's relevant to the story: **Tech stack** (language/framework/lib + version), **Code structure** (folder/naming/file pattern), **API patterns**, **DB schemas**, **Security**, **Performance**, **Testing standards**, **Deployment**, **Integration**. Extract every requirement the dev MUST follow; identify architectural decisions that override old patterns.
- **📂 READ modified files — non-negotiable**: identify every file marked UPDATE (not NEW) that the story will touch, read each file IN FULL. Record in dev notes: current state (what it does today), what the story changes, what MUST be preserved (behavior that must not break). The story must keep the system running end-to-end — not just satisfy the stated AC. Behavior needed for the feature to work correctly within the existing system is a requirement even if unwritten.

## Step 4 — Web research (🌐 avoid outdated implementation)
Identify libs/APIs/frameworks from architecture that need latest-version knowledge; research: latest stable version & breaking changes, security vulnerabilities/updates, deprecations, best practices for the current version. Put into the story: specific version & reason chosen, endpoints + params + auth, recent security patches, performance optimizations, migration notes.

## Step 5 — Create comprehensive story file
Start from the template. Fill in: story header, story requirements, **developer_context_section (the most important part)** → technical requirements, architecture compliance, library/framework requirements, file structure requirements, testing requirements; previous_story_intelligence (if any), git_intelligence_summary (if any), latest_tech_information (if any), project_context_reference, story_completion_status. Set Status = **`ready-for-dev`**.

## Step 6 — Finalize
Validate the new story against the checklist, fix before finalizing; save the story. If there's a sprint-status: verify current status is `backlog`, update `development_status[{story_key}] = ready-for-dev`, `last_updated`, keep comments/STATUS DEFINITIONS intact. Report completion: Story ID/key/file/status + next steps (review story, `dev-story`, `code-review` when done, optional TEA `automate`).
