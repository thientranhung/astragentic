# 📅 Sprint Planning (Amelia) — self-contained distilled version

> Distilled from `bmad-sprint-planning/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Goal
Generate/maintain `sprint-status.yaml` from the epics files: parse every epic + story, detect the current status, output a complete, structured tracking file.

## Document discovery — load ALL epics
Sprint planning needs EVERY epic + story for full tracking coverage.
1. Look for a whole doc first: `epics.md`, `bmm-epics.md`, or any `*epic*.md`.
2. None → look for a sharded version `epics/index.md`; read the index then read ALL section files (`epic-1.md`, `epic-2.md`…).
3. Both exist → prefer the whole doc.
4. Fuzzy-match the name (`epics.md`, `user-stories.md`…).

## Step 1 — Parse epics, extract every work item
For each epic file, extract: epic number (`## Epic 1:`), story ID + title (`### Story 1.1: User Authentication`).
**Convert to key**: `Story 1.1: User Authentication` → replace `.`=`-` → `1-1`, title kebab-case → final key `1-1-user-authentication`. Build a full inventory of every epic + story.

## Step 2 — Build the sprint status structure
For each epic, create entries in order:
1. **Epic** — key `epic-{num}`, default `backlog`.
2. **Stories** — key `{epic}-{story}-{title}`, default `backlog`.
3. **Retrospective** — key `epic-{num}-retrospective`, default `optional`.

## Step 3 — Detect status intelligently
- If the story file exists (`{story-key}.md` in the stories directory) → raise status to ≥ `ready-for-dev`.
- **Preservation**: if the old `sprint-status.yaml` has a higher status → keep it. **Never downgrade** (don't change `done` back to `ready-for-dev`). If the old file has an `action_items` section → carry it over intact.

**State machine**: Epic `backlog → in-progress → done`. Story `backlog → ready-for-dev → in-progress → review → done`. Retrospective `optional ↔ done`. Action item `open → in-progress → done`.

## Step 4 — Generate the file
Write/update `sprint-status.yaml`. **Metadata appears TWICE**: once as `#` comments (documentation, including STATUS DEFINITIONS + WORKFLOW NOTES) and once as YAML key:value (for parsing). Item order: epic → its stories → retrospective → next epic… If the old file has `action_items` → rewrite it intact after `development_status`.

File skeleton:
```yaml
generated: {date}
last_updated: {date}
project: {project_name}
tracking_system: file-system
story_location: {implementation_artifacts}

development_status:
  epic-1: backlog
  1-1-user-authentication: backlog
  1-2-account-management: backlog
  epic-1-retrospective: optional
```

## Step 5 — Validate & report
Checklist: every epic/story in the epics file is present; each epic has a retrospective entry; no stray item that isn't in the epics file; `action_items` (if any) kept intact; every status valid per the state machine; YAML valid.
Count: total epics, total stories, epics in-progress, stories done. Show the summary + next steps (review the file, use it to track, agents will update it as they work, re-run to refresh auto-detect).

## Guidelines
An epic → `in-progress` when its first story begins. Default to sequential stories but support parallelism (multiple `in-progress` stories if capacity allows). A story should pass through `review` before `done`. Dev usually creates the next story after the previous one is `done` to absorb learnings.

*No time: this is a status tracking file, not an estimate.*
