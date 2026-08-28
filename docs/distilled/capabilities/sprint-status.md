# 📊 Sprint Status (Amelia) — self-contained distilled version

> Distilled from `bmad-sprint-status/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Posture
Provide clear, actionable sprint visibility. **No time estimates** — focus only on status, risks, next step. There are 3 modes: `interactive` (default), `data` (return variables for another flow), `validate` (only check the file is valid).

## Step 1 — Locate file
Try `{implementation_artifacts}/sprint-status.yaml`. Not found → report "run sprint-planning to generate it, then rerun". Exit.

## Step 2 — Read & parse
Read the ENTIRE file. Parse metadata (generated, last_updated, project, project_key, tracking_system, story_location) + map `development_status`. **Classify keys**: epic (`epic-*`, not `-retrospective`), retrospective (`*-retrospective`), story (the rest, e.g. `1-2-login-form`).
- Map legacy: story `drafted → ready-for-dev`, epic `contexted → in-progress`.
- Count stories (backlog/ready-for-dev/in-progress/review/done), epics (backlog/in-progress/done), retrospectives (optional/done). Parse `action_items` if present → `open_action_items` = entries with status `open`/`in-progress`.
- **Validate status** against valid values; on an unknown status → list it, ask how to fix (or "skip"); if the user fixes it → update the file then re-parse.

**Detect risks**: a story in `review` → suggest `code-review`. An `in-progress` story but no `ready-for-dev` → advise keeping focus on the running story. Every epic `backlog` + no story `ready-for-dev` → suggest `create-story`. `last_updated` > 7 days (fall back to `generated` if missing) → warn the file may be stale. Story key not matching an epic (story `5-1-…` but no `epic-5`) → warn orphaned. An epic `in-progress` with no stories → warn.

## Step 3 — Choose the next recommendation (priority)
When picking the "first" story: sort by epic num then story num (1-1 before 1-2 before 2-1).
1. Has an `in-progress` story → `dev-story` for the first in-progress story.
2. Else has `review` → `code-review` for the first review story.
3. Else has `ready-for-dev` → `dev-story`.
4. Else has `backlog` → `create-story`.
5. Else has a retrospective `optional` → `retrospective`.
6. Else → every implementation item is done; congratulate the user.

## Step 4 — Display summary
Show: Project/Tracking/Status file · **Stories** (count per status) · **Epics** (count) · **Next Recommendation** (workflow + story id) · **Open Action Items** (if any: action — status, epic, owner) · **Risks** (if any).

## Step 5 — Offer actions
`1) Run the recommended workflow now` (provide the command + set `story_key` if needed) · `2) Show all stories grouped by status` · `3) Show raw sprint-status.yaml` · `4) Exit`.

## Data mode
Parse as in Step 2, compute the recommendation as in Step 3, return to the caller: `next_workflow_id`, `next_story_id`, the story/epic counts, `open_action_items`, `risks`.

## Validate mode
Check: the file exists; required metadata present (generated, project, project_key, tracking_system, story_location; `last_updated` optional); `development_status` exists & has ≥1 entry; every status valid. Return `is_valid` + `error`/`suggestion` (or `message` when valid).
