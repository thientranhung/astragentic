# BMAD Method — distilled from upstream main, 2026-10-29

> Distilled from the **BMAD Method**, Copyright (c) 2025 BMad Code, LLC, MIT licensed
> (`/tmp/bmad-latest/LICENSE:1-3`). Upstream: <https://github.com/bmad-code-org/BMAD-METHOD>.
> The three `testarch-*` files come from the separate **BMad Test Architect** repository,
> <https://github.com/bmad-code-org/bmad-method-test-architecture-enterprise>, also Copyright (c) 2025
> BMad Code, LLC, MIT (`/tmp/bmad-tea-latest/LICENSE:1-3`).
> Same treatment as `docs/bmad-distilled/` (the 2026-08-28 baseline, left untouched): install
> machinery stripped (`uv run`, `render_skill.py`, `tickets.py`, memlog, customize.toml, Jinja
> routes, headless, HTML reports, HALT menus), method preserved, terse.

## Source versions

| Repo | Clone | HEAD | Commit date | Latest tag | Note |
|---|---|---|---|---|---|
| BMAD-METHOD | `git clone --depth 1` → `/tmp/bmad-latest` | `61e01f82644c4bb533750cfa0d6d61ab61d2cc9b` | 2026-10-18 | `v6.12.4` at `eecafe9d` | HEAD is past the tag: `CHANGELOG.md:3` reads `## Unreleased`, "a first draft for v7". No root `package.json` (only `docs-site/package.json`). |
| bmad-method-test-architecture-enterprise (TEA) | `git clone --depth 1` → `/tmp/bmad-tea-latest` | `59c164c80f34a118fe33b84b1f6c5770d6b43389` | 2026-10-27 | `v3.4.0` | `package.json` version `3.4.0` |

The layout changed since the baseline: one flat `skills/` folder of 32 entries (`bmad-*` skills, `bmad-agent-*` agents, `bmod-*` module records). `skills/bmod-method/retired.toml` lists 48 removed and 2 renamed skill ids; six of the fourteen capabilities below are among them.

## Capabilities

Bytes measured with `wc -c` on 2026-10-29. Old = `docs/bmad-distilled/capabilities/`, new = `capabilities/` here.

| Capability | Old | New | Upstream source now | What changed (one line) |
|---|---|---|---|---|
| [prd](capabilities/prd.md) | 4286 | 9229 | `skills/bmad-prd/` | Ticket read first and its Requirements settled; Glossary section; FR form `[Actor] can [capability] [under conditions]` + testable Consequences; counter-metrics; 7-dimension judgment rubric replaces the checklist; next step is Sofia, not epics |
| [create-epics-and-stories](capabilities/create-epics-and-stories.md) | 4571 | 9673 | retired → `skills/bmad-agent-po/references/{spec,slice,validate-checks}.md` | Requirements lines `R<n> (source ids)`, Spec Law; epics by deployment boundary, written thin then refined; stories are entries (no file), tracer bullet first, refactor sweep last, "split never shrink"; UX-DR enumeration replaced by adopted companions |
| [create-story](capabilities/create-story.md) | 5157 | 6241 | retired → `skills/bmad-agent-po/references/ticket.md` + `assets/*-template.md` | Story file optional; Description one sentence; criteria Given/When/Then `(R<m>)` as a rule with failure path; no `As a` form; bug = reproduction + hypothesis, never a fix; risk on every ticket; the "context engine" moved into the build plan's Code Map |
| [dev-story](capabilities/dev-story.md) | 5450 | 10053 | retired → `skills/bmad-build/` | Plan with `<frozen-after-approval>` intent, 900–1600 tokens, oneshot ≤100 LOC; implementation handed to a context-free subagent; judge the diff not the report; Matrix Test Audit; review loopbacks intent_gap / bad_plan / patch / defer; ends at `built`. RED/GREEN/REFACTOR per task and the "NO LYING" gate are gone |
| [code-review](capabilities/code-review.md) | 5818 | 10365 | `skills/bmad-code-review/` | Five verdicts high/medium/low/false/maybe-false with evidence; `dismiss` gone; routes decision_needed / patch / defer; Verification Gap lens (pre-verified, fixed medium, stale-verification shape); Intent Alignment Auditor replaces Acceptance Auditor; Blind Hunter floor `min(floor(sqrt(kB)+1),10)`; claims file to the edge lens only; never changes plan status |
| [ux](capabilities/ux.md) | 5153 | 9603 | `skills/bmad-ux/` | Ticket first, Requirements are the brief, never re-derive from PRD; Google design.md token table in full; 8-category rubric (flow, token, component, state, visual-reference coverage + bloat, inheritance, shape); key-screen mock rules; next step asks Sofia to adopt the spines |
| [advanced-elicitation](capabilities/advanced-elicitation.md) | 3895 | 5247 | `skills/bmad-advanced-elicitation/` | Pick 2–4 categories then five methods from different angles; Apply/Reject per method, never change without acceptance; full 71-method catalog with output patterns |
| [review-adversarial-general](capabilities/review-adversarial-general.md) | 1673 | 2821 | lens in `skills/bmad-review/references/lens-adversarial.md` + Blind Hunter in `bmad-code-review/customize.toml` | Persona dropped (A/B showed no effect); ≥10 findings and "what is missing" kept; canonical 4-field findings shape; size-scaled floor in Blind Hunter |
| [review-edge-case-hunter](capabilities/review-edge-case-hunter.md) | 4036 | 5608 | `skills/bmad-code-review/review-prompts/edge-case-hunter.md` + `bmad-review/references/lens-edge-case-hunter.md` | Two new sweeps (handle lifetime, call-site contract incl. tests); Claims Check step reads the narrative only after tracing; applies to tickets and plans too |
| [testarch-test-design](capabilities/testarch-test-design.md) | 4115 | 6802 | TEA `skills/bmad-tea-test-design/` | One scored risk per gap statement; bare-integer P×I cells, bands high ≥6 / 3–4 / 1–2; one coverage row per risk at the level where the failure first shows; P0 needs critical impact **and** no safe workaround; validation reopens on any fix |
| [testarch-atdd](capabilities/testarch-atdd.md) | 3041 | 6652 | TEA `skills/bmad-tea-automate/red/` (+ `resources/run-and-heal.md`) | ATDD folded into Automate red mode; one primary scaffold per criterion with the smallest criterion-defining assertion first; scaffolds in project style; run-and-heal: disposable copy, classify before repair, ≤3 rounds, never skip/fixme/weaken; "verified red" is an execution result, not a generation result |
| [testarch-trace](capabilities/testarch-trace.md) | 3250 | 5122 | TEA `skills/bmad-tea-trace/` | Oracle ledger with authoritative priorities; a test earns its place only by establishing part of the criterion; UNIT-ONLY/INTEGRATION-ONLY redefined; live-evidence cap at CONCERNS; WAIVED never derived, no default expiry |
| [check-implementation-readiness](capabilities/check-implementation-readiness.md) | 4055 | 6018 | retired → `skills/bmad-agent-po/references/validate.md` + `validate-checks.md` | READY/NEEDS WORK/NOT READY report gone; Ticket / Set / Tree / Dependencies / Closure checks run by fresh subagents; findings sorted fix / suggest / ask; closure by implementation evidence, not child status |
| [correct-course](capabilities/correct-course.md) | 4049 | 3286 | retired → `skills/bmad-agent-po/references/replan.md` | Sprint Change Proposal, checklist, Incremental/Batch, Minor/Moderate/Major routing all gone; five steps: name the change, re-derive requirements with ids kept, re-slice, drop with a `Dropped:` line, record a dated `Decision:`; never edit an in-progress plan or a companion |
| **Total** | **58549** | **96720** | | +65%: the new sources carry more rules per capability (rubrics, verdict tables, check sections); nothing was padded, but these are source text for `astra-*`, not the skills themselves |

## Roles (what the baseline roster called them)

| Baseline role | Now | Evidence |
|---|---|---|
| John (PM) | still owns `bmad-prd`; role text "a validated PRD that Sofia the Product Owner distills" | `skills/bmad-agent-pm/customize.toml:40` |
| John / Winston on epics & stories | **Sofia, Product Owner** (`bmad-agent-po`): SPEC, TICKETS, REFINE, BOARD, VALIDATE, REPLAN, STORE | `skills/bmad-agent-po/customize.toml:37-70`, `bmod-method/roster.toml:27-33` |
| Sally (UX) | unchanged, menu item `CU` → `bmad-ux` | `skills/bmad-agent-ux-designer/customize.toml:56-58` |
| Amelia (Dev) | `BD` build, `QA`, `CR` code review, `ER` | `skills/bmad-agent-dev/customize.toml:60-75` |
| Murat (TEA) | separate repo, 8 skills; ATDD and CI folded into Automate and Framework | TEA `CHANGELOG.md:189` |
| Paige (Tech Writer) | retired in v6.11.0 | `CHANGELOG.md:76` |

## Folder

```
bmad-distilled-latest/
├── README.md             ← this file
└── capabilities/         ← 14 files, same names as the baseline
```

Audit with per-capability diff, fit for `astra-*`, and the unverified list: `docs/audit/2026-10-29-bmad-latest-distill.md`.
