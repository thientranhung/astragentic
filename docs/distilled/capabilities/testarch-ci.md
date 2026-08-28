# ⚙️ CI/CD Quality Pipeline (Murat/TEA) — self-contained distilled version

> Distilled from `bmad-testarch-ci/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Posture
You are the Master Test Architect. Scaffold a **production-ready CI/CD quality pipeline**: test execution, **burn-in loops** to detect flakiness, **parallel sharding**, artifact collection, notifications. If you need to resume, keep a simple append-only markdown log.

## Step 1 — Preflight
Detect `ci_platform` and stack (frontend/backend/fullstack) + test framework. Confirm there's a test suite to run.

## Step 2 — Generate pipeline
Pick the output path + template by platform:
- **github-actions** → `.github/workflows/test.yml`
- **gitlab-ci** → `.gitlab-ci.yml`
- **jenkins** → `Jenkinsfile`
- **azure-devops** → `azure-pipelines.yml`
- **harness** → `.harness/pipeline.yaml`
- **circle-ci** → `.circleci/config.yml` (generate from first principles)
Adapt the template to `test_stack_type` + `test_framework`. Enable parallel sharding and artifact collection.

**🚨 Security — script injection prevention (mandatory)**: treat `${{ inputs.* }}` and all `${{ github.event.* }}` as **unsafe by default**. Two rules for `run:` blocks:
1. **No direct interpolation** — route through `env:` intermediaries, reference `"$ENV_VAR"` (double-quoted).
2. **Inputs are DATA, not COMMANDS** — don't take command-shaped inputs (e.g. `inputs.install-command`) and execute them; use fixed commands (`npm ci`, `npx playwright test`), passing the input only as an argument.

## Step 3 — Configure quality gates
- **Burn-in (flaky detection)**: run an N-iteration burn-in, gate promotion on stability. **Stack-conditional**: FE/fullstack **on by default** (UI flakiness: race, selector, timing); backend-only **skip by default** (unit/integration/API deterministic) — unless the user overrides. The reusable burn-in workflow must also follow the script-injection rules.
- **Quality gates**: min pass rates **P0 = 100%, P1 ≥ 95%**; fail CI on critical failures; optionally require traceability/nfr output before release.
- **Contract testing gate** (if Pact is enabled): **determinism gate must pass** (run the suite N times, fail if pact JSON is byte-different before publish) · can-i-deploy must pass before deploy · block the pipeline if verification fails · consumer publish failure = CI failure · provider verification passes for every consumer pact before merge · staleness alert (a silent webhook is usually an expired PAT).
- **Notifications**: failure alerts (Slack/email) + artifact links.

## Step 4 — Validate & summary
Validate the pipeline against the checklist; summarize the gates + burn-in config + platform. **Next**: do a trial run of the pipeline, or `testarch-trace`/`testarch-nfr` to wire gate outputs into the release.
