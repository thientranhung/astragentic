# 🏗️ Test Framework Setup (Murat/TEA) — self-contained distilled version

> Distilled from `bmad-testarch-framework/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Posture
You are the Master Test Architect. Bootstrap a **production-ready test framework** with fixtures, helpers, config, and best practices. If you need to resume, keep a simple append-only markdown log.

## Step 1 — Preflight
- **Detect stack** (frontend / backend / fullstack via manifests).
- **Validate prerequisites** (missing → HALT): FE needs `package.json` + **no** existing E2E framework (`playwright.config.*`/`cypress.config.*`); BE needs at least 1 project manifest + no conflicting test framework.
- Gather context: read the manifest to identify language/framework/bundler/deps; check architecture/tech-spec docs; note auth & APIs.

## Step 2 — Select framework
- **FE/fullstack (browser)**: default **Playwright** unless there is a strong reason to choose Cypress. Playwright when: large/complex repo, multi-browser, heavy API+UI, need CI speed/parallelism. Cypress when: small team prioritizing DX, focus on component testing, simple setup.
- **BE (no browser)** — by language: Python→**pytest** · Java/Kotlin→**JUnit 5** · Go→**go test** · C#/.NET→**xUnit** · Ruby→**RSpec** · Rust→**cargo test**.
- **Fullstack**: pick both a browser framework and a backend framework. Respect `test_framework` if the user set it explicitly.

## Step 3 — Scaffold framework
Generate directory structure + config + fixtures + factories + helpers + sample tests:
- **Directory**: FE `{test_dir}/e2e/`, `support/fixtures/`, `support/helpers/`; BE by language convention (e.g. Go `*_test.go` next to source + `testdata/`).
- **Config**: `playwright.config.ts`/`cypress.config.ts` (FE) or idiomatic config (pytest, JUnit gradle/maven, RSpec `.rspec`+helpers…); `.env.example` with `TEST_ENV`/`BASE_URL`/`API_URL`; version file for the language.
- **Fixtures & factories**: fixture index with `mergeTests`; **Faker-based data factories with overrides**; patterns from the knowledge base (fixture-architecture, data-factories, network-first, playwright-config, test-quality). Contract testing on → scaffold Pact structure + `pool: 'forks'`/`singleFork` + determinism gate.
- **Sample tests & helpers**: examples illustrating the **data-testid selector strategy**, factory usage, isolation, cleanup.

## Step 4 — Docs & scripts
- `tests/README.md`: setup, how to run (local/headed/debug), architecture (fixtures/factories/helpers), best practices (selectors, isolation, cleanup), CI notes, knowledge refs.
- **Test scripts**: FE add `test:e2e` to `package.json`; BE add idiomatic commands (`pytest`/`pytest --cov`; `./gradlew test`/`mvn verify`; `go test ./...`/`-race`/`-cover`; `dotnet test`; `bundle exec rspec`).

## Step 5 — Validate & summary
Validate against the checklist; summarize the chosen framework + the structure created. **Next: `testarch-ci` (pipeline) then `testarch-atdd`/`testarch-automate` to write tests.**
