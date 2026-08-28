# 🧭 Checkpoint Preview (Amelia) — self-contained distilled version

> Distilled from `bmad-checkpoint-preview/SKILL.md` (+ steps). Install machinery (python/config/memlog/headless) stripped; method preserved.

## Posture
Guide a human through reviewing a change — from purpose & context down into detail. Four legs: `Orientation → Walkthrough → Detail Pass → Testing` (→ Wrap-Up).

## Global rules (every step)
- **Path:line** — every code reference uses `path:line` CWD-relative (no leading `/`) so it's clickable in a terminal IDE.
- **Front-load then shut up** — present a step's entire output in ONE coherent message; don't ask mid-way, don't drip-feed.
- Conversation language follows config; file output follows the document's language.

## Step 1 — Orientation
**Find the change** by cascade (stop when clear): (1) explicit arg — PR (`gh pr view`), commit/branch/spec used directly; (2) recent conversation; (3) sprint tracking (`sprint-status.yaml`, story `review`: 1 → suggest & confirm, multiple → number); (4) current git state (confirm HEAD `<sha>` on `<branch>`); (5) ask — after 3 turns still unclear → HALT.
**Enrich**: has spec → take frontmatter `baseline_commit` as baseline; has commit/branch → find a spec whose `baseline_commit` is an ancestor. Use both if available.
**Determine what you have**: set `change_type` (PR/commit/branch/user's wording, default `change`). Set `review_mode`: `full-trail` (spec has `## Suggested Review Order`) / `spec-only` (spec but no trail) / `bare-commit` (no spec; intent from the commit message, if terse infer one sentence from the diff, tag `[inferred]`).
**Produce orientation**: **Intent Summary** (from spec Intent → verbatim; other sources → verbatim if ≤200 tokens, longer then distill; format `> **Intent:** …`). **Surface Area Stats** (best-effort from the diff, baseline in order: spec `baseline_commit` → merge-base vs main → `HEAD~1..HEAD` → skip if no git): `N files changed · M modules · ~L lines of logic · B boundary crossings · P new public interfaces`; drop metrics you can't compute, don't guess.
If not `full-trail` → generate a trail from the diff (fallback) then continue.

## Step 2 — Walkthrough
Engage **design judgment**, not correctness checking. Organize **by concern, not by file** (a concern = one cohesive design intent: "input validation", "state management", "API contract"; a file can span multiple concerns).
- Has Suggested Review Order → resolve each stop to `path:line`, read the diff to understand the effect, group by concern. None → take the diff, identify concerns (functional grouping, architectural layer, design decision) + key locations.
- **Order for comprehension**: top-down, highest first then drill down; lead with the natural entry point (public API/config/UI). Each concern: **Heading** (design-intent name), **Why** (1–2 sentences: the problem it solves, why this approach vs alternatives — reference a rejected alternative if the spec records one), **Stops** (`path:line` + descriptive phrase ≤15 words). Aim for 2–5 concerns (>7 signals scope too large, still present it).
- End the message: invite the human to click through the stops, suggest "advanced elicitation"/"party mode" on a specific aspect, say **next** to move to the riskiest spot.

## Step 3 — Detail Pass
Surface what the human should **think about**, not what the code got wrong (correctness is handled by machine hardening). The LLM detects risk by pattern, the human judges meaning — **don't assign severity/scores**; ordering by blast radius is just for easier reading.
Scan the diff for 2–5 spots with the highest blast radius (where being wrong is most costly, not most complex). Tag: `[auth]`, `[public API]`, `[schema]`, `[billing]`, `[infra]`, `[security]`, `[config]`, `[other]`. Put high-blast-radius first; >5 → top 5 + note N remaining. No matching spot → say plainly "No high-risk spots — the diff speaks for itself", don't fabricate.
**Machine hardening**: if the spec has a `## Spec Change Log` with an entry → surface what the review loop flagged that the human should know (not bugs already fixed). None → drop it entirely.
End: menu — `"dig into [area]"` (deep-dive correctness mode: read full context outside the hunk, trace edge case/boundary/error/off-by-one/race/leak; if the area isn't in the diff → say so) or `"next"`.

## Step 4 — Testing
**Experiential**, not analytical: "you can see X with your own eyes". Don't prescribe — the human decides whether it's worth the time. Don't repeat the CI/test suite (assume it exists & ran) — this is manual observation.
Scan the diff/spec for observable behavior: UI changes, CLI/terminal output, API responses, state changes (DB/file/config), error paths. Each: **Do** (a specific action) / **Expect** (the confirming result) / **Why bother** (one phrase, drop if obvious). Aim for 2–5; no visible behavior → say "this change is internal — the diff & tests tell the whole story".

## Step 5 — Wrap-Up
Prompt for a decision on `change_type`: **Approve** (ship; may patch interactively first; if it's a PR offer `gh pr review --approve` but confirm first) / **Rework** (ask what's wrong — approach/spec/implementation; help decide next step, draft feedback tagged `path:line`) / **Discuss** (open, then return to the prompt). HALT until the user chooses.

## Early exit
At any step where the human signals they want to decide ("let's ship it" / "needs a rethink" / "I'm done reviewing") → confirm intent, go straight to Wrap-Up (approve or rework); if you misread → apologize & continue the current step.
