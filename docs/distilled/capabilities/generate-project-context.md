# 📐 Generate Project Context (Paige / Amelia) — self-contained distilled version

> Distilled from `bmad-generate-project-context/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Overview / posture
**Goal:** create a concise, LLM-optimized **`project-context.md`** containing the critical rules, patterns, and guidelines AI agents must follow when implementing code — focused on the **unobvious details LLMs need reminding of**, not things a competent model already knows.

**Role:** a technical facilitator working with a peer. You are a **facilitator, not a content generator** — never generate content without user input; treat it as collaborative discovery between technical peers. Keep content **lean** (context efficiency is the point). **No time estimates.** Speak in the user's language; write the artifact in the configured output language.

## Step 1 — Discovery & initialization
- **Check for an existing `project-context.md`.** If found, read it fully and ask: update this or create new?
- **Discover the tech stack** — read the architecture doc (technology choices + versions, decisions affecting implementation), package files (`package.json`, `requirements.txt`, `Cargo.toml`, …; exact versions, dev vs prod), and config files (language config e.g. `tsconfig.json`, build tools, lint/format, testing config).
- **Identify existing code patterns** — naming conventions (files, components, functions, tests), code organization (component structure, where utilities/services live, test organization), documentation patterns.
- **Extract critical implementation rules AI agents might miss** — language-specific (strict mode, import/export, async patterns, error handling), framework-specific (hooks usage, API routes, middleware, state management), testing (structure, mocks, unit vs integration boundaries, coverage), workflow (branch naming, commit format, PR requirements, deploy).
- **Present a discovery summary** (tech stack with versions, patterns/conventions/rules found, key areas for context rules) and **halt** for the user to confirm before generating.

## Step 2 — Collaborative rule generation
Show your analysis before acting. Generate specific, critical rules **collaboratively**, walking these categories:
1. **Technology stack & versions** — exact stack + critical version constraints. Adapt depth to the user's skill level (expert / intermediate / beginner framing).
2. **Language-specific rules** — unobvious patterns the language demands.
3. **Framework-specific rules** — project-specific conventions (React/Vue/Angular/Next/Express/…).
4. **Testing rules** — structure, mocks, coverage, unit-vs-integration boundaries.
5. **Code quality & style** — lint/format rules, organization, naming, documentation requirements.
6. **Development workflow** — git/branch, commit format, PR requirements, deploy considerations.
7. **Critical don't-miss rules** — anti-patterns to avoid, edge cases to handle, security rules, performance gotchas (with concrete examples).

After each category, show the drafted markdown and offer a choice, then **halt** for selection:
- **A (Advanced Elicitation)** — explore nuanced rules for the category more deeply.
- **P (Party Mode)** — bring multiple perspectives to surface edge cases.
- **C (Continue)** — save this category's content and move on.

Only **save on C**. Append each accepted category directly to `project-context.md`. Do not proceed to finalize until every category is done and the user has chosen C for each.

## Step 3 — Finalize
Complete the file, confirm all sections are captured, and hand off the LLM-optimized `project-context.md`.

## Failure modes to avoid
Including obvious rules agents already know; verbose content that wastes context; missing anti-patterns or edge cases; skipping user validation per category; vague versions/configs; generating content instead of facilitating.

> Persistence: keep a simple append-only markdown log (completed categories) if you need to resume.
