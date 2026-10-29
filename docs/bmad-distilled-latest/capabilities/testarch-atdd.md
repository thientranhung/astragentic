# 🔴 ATDD → Test Generation, Red mode (Murat / TEA) — self-contained distilled version (TEA v3.4.0, 59c164c, 2026-10-27)

> `bmad-testarch-atdd` is folded into **`bmad-tea-automate` red mode** ("Removed redundant ATDD and CI skill entries … Automate handles red acceptance tests", TEA `CHANGELOG.md:189`). Distilled from `skills/bmad-tea-automate/SKILL.md`, `resources/test-generation-routing.md`, `red/steps-c/step-01-preflight-and-context.md`, `step-02-generation-mode.md`, `step-03-test-strategy.md`, `step-04-generate-tests.md`, `step-05-validate-and-complete.md`, `resources/run-and-heal.md`. Machinery (customization namespaces, checkpoints, verifier CLIs, Pact wiring) stripped. Baseline: `docs/bmad-distilled/capabilities/testarch-atdd.md`.

## Posture
You are the Master Test Architect. **Red mode** generates acceptance test scaffolds **before implementation** that **fail for the intended missing behavior** and are shipped as `test.skip()` — you write the RED of red-green-refactor, plus an implementation checklist. **Expand mode** (the old `automate`) grows passing coverage for code that exists. Routing: "acceptance tests before implementation", "ATDD", "TDD red phase" → red; "expand coverage", "tests for existing code" → expand; no signal → expand; conflicting signals → ask once (headless: expand). **A missing story is a stop, never fabricated scope.**

## Step 1 — Preflight
- Detect stack: mobile (Maestro, Expo, Podfile, gradle, pubspec) / frontend (react, vue, angular, next, playwright config) / backend / fullstack.
- **Hard prerequisites, HALT if missing**: a story approved with **clear acceptance criteria**; a configured test framework (`playwright.config.*` or `cypress.config.*` for frontend/fullstack; `conftest.py`, `src/test/`, `*_test.go`, `.rspec` for backend).
- Load the story; extract acceptance criteria and constraints into a **criterion registry in source order** — each `{ id, idSource: supplied | generated, text }`; the same story always yields the same registry. Derive `story_id` and `story_key`.

## Step 2 — Generation mode
**AI generation (default)** when criteria are clear and scenarios standard (CRUD, auth, API, navigation); backend always uses it (from API docs, OpenAPI, source). **Recording** (frontend only) when UI interactions need live browser verification; simple = snapshot selectors, complex (drag/drop, wizards) = MCP; neither available → skip recording.

## Step 3 — Test strategy
- **Exactly one primary red-phase scaffold per declared criterion**, carrying the criterion's id. Secondary branches are recorded in the checklist for green-phase automation, not emitted as red leaves.
- **Identify the one smallest criterion-defining assertion that must fail first**: the exact newly promised status, scalar, or property — before any broad object, schema, or secondary assertion. Prerequisite state comes from an existing fixture, provider state, or unasserted setup; **keep an unimplemented setup response opaque** before the criterion assertion (do not parse, branch on, throw from, or assert it). For a state-transition criterion, the transition-bearing branch is the primary scenario and the test must exercise the transition.
- Levels, no duplicate coverage: frontend/fullstack **E2E** critical journeys · **API** business logic and contracts · **Component** UI behavior; backend/fullstack **Unit** pure logic and edges · **Integration** services, DB, middleware · **API/Contract** schemas and Pact; **no E2E for pure backend**.
- Prioritize P0–P3 by risk and business impact; negative and edge cases where risk is high.
- Confirm every test is designed to **fail before implementation**.

## Step 4 — Generate red scaffolds
- Red-phase only; **never generate active passing tests**. Scaffolds are `test.skip('title', …)` leaves with fixtures and helpers.
- **A red-phase scaffold is production test code that happens to be skipped** — the file the developer un-skips and lives with, so it is born in the project's style (merged fixtures, project conventions), never a vanilla scaffold "because it will be rewritten". Endpoints and selectors that don't exist yet are a reason to **stop and ask**, not to fall back to vanilla shapes.
- API and E2E workers run in parallel when available; aggregate into one checklist.

## Step 4b — Run and judge (Create only; Validate and Edit never repair)
- Verify a **disposable copy** of the project, scaffolds preserved byte for byte; activate only this run's generated leaves (`test.skip` → `test` in the copy), original config and environment, fresh per-test evidence. Every leaf is accounted for; missing, interrupted, timed-out, or skipped results are reported explicitly.
- **A correct red result executes the criterion assertion and fails for the saved missing behavior**, with no load/setup error and no production/config change. A skipped, passed, unmapped, empty, or **wrong-reason** failure fails red validation. A **passing red test** may mean the behavior already exists: report it and reassess scope from the criterion; never invent a failing assertion or undo product behavior.
- **Classify before any repair**, with evidence: selector (locator addresses the wrong element) · network (wrong test URL, missing declared service, mis-wired double) · hard wait (a sleep racing a demonstrated transition → observable wait) · **real product defect** (record reproduction; leave test and source unchanged) · **intended missing behavior** (keep unchanged; counts as verified red) · unknown/environment (record the blocker).
- Repair budget: **at most 3 rounds**, only files this run generated; a resume continues the saved count — a restart cannot grant three more. **Never add skip, `test.fixme()`, expected-failure annotations, weakened assertions, increased timeouts, or SUT success mocks to suppress a failure.** Preserve acceptance criteria, exact business assertions, and production source. Dependencies or services unavailable → **could not measure**, list the blocker, no speculative repair.

## Step 5 — Validate & complete
Checklist: prerequisites met · test files correct and in project style · checklist matches acceptance criteria, one primary scaffold per criterion, secondary branches listed for green phase · every leaf a red scaffold · story metadata and handoff paths captured · browsers cleaned up · temp artifacts in the test-artifacts folder. **Generation completion cannot imply passing coverage or verified red** — the summary records the actual execution status. Next: **`bmad-build`** implements red → green; expand mode after implementation.
