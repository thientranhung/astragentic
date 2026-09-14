# 🔴 ATDD — Red-Phase Acceptance Tests (Murat/TEA) — self-contained distilled version

> Distilled from `bmad-testarch-atdd/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Posture
You are the Master Test Architect. Generate **red-phase acceptance test scaffolds BEFORE implementation** (TDD red-green-refactor: you write the RED part), plus an implementation checklist. Tests must **fail before implementation** and be marked `test.skip()` — do **not** generate passing/active tests. If you need to resume, keep a simple append-only markdown log.

## Step 1 — Preflight & context
- **Detect stack** (frontend / backend / fullstack via manifests).
- **Hard prerequisites** (missing → HALT): an approved story with **clear acceptance criteria**; framework config exists (`playwright.config.*`/`cypress.config.*` for FE; `conftest.py`/`src/test`/`*_test.go`/`.rspec` for BE).
- Load story: extract acceptance criteria + constraints; derive `story_key`/`story_id` from filename/metadata.

## Step 2 — Generation mode
- **AI generation (default)**: when AC are clear and scenarios are standard (CRUD, auth, API, navigation). Backend always uses AI generation (from API docs / OpenAPI / source), no browser recording needed.
- **Recording (optional, FE/fullstack only)**: when UI interactions need to be verified in a real browser — snapshot selectors, capture structure. No tool available → fall back to AI generation from documentation.

## Step 3 — Test strategy
- **Map each acceptance criterion → test scenarios**; add negative & edge cases where risk is high.
- **Choose test level per stack** — do not duplicate coverage:
  - FE/fullstack: **E2E** for critical journeys · **API** for business logic/contracts · **Component** for UI behavior.
  - BE/fullstack: **Unit** for pure functions/logic/edge · **Integration** for service/DB/middleware · **API/Contract** for endpoint schema + Pact. Pure backend: **no E2E**.
- **Prioritize P0–P3** by risk + business impact.
- **Confirm red phase**: every test is designed to **fail before implementation**.

## Step 4 — Generate red-phase scaffolds
Generate API and/or E2E failing scaffolds with a consistent output contract. Include supporting fixtures & helpers. Inviolable rule: **red-phase only**, use `test.skip()`, do not generate passing tests. If using contract testing (Pact), build a Provider Endpoint Map and scrutinize the provider.

## Step 5 — Validate & complete
Validate against the checklist: prerequisites ok · test files correct · checklist matches AC · tests are red-phase scaffolds with `test.skip()` · story metadata + handoff paths captured · CLI sessions cleaned up (no orphaned browsers) · temp artifacts live in the test-artifacts directory. Polish output (remove duplication, keep it consistent). Completion summary: test files, checklist path, story handoff, key risks/assumptions. **Next: `dev-story`** (implement to move red→green); `testarch-automate` comes after implementation.
