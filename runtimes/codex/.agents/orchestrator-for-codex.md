# Orchestrator for Codex

Owner-editable model assignments. This file belongs to the Codex runtime overlay.
The source launcher reads this table for owner sessions (thomas, ba, quick-builder).
Thomas reads worker rows when invoking native Herdr/Codex commands. Helper TOMLs
are generated from the same table at installation. Values apply to new sessions.

## Model assignments

| Role | Model | Effort |
|---|---|---|
| thomas | gpt-6-astra | medium |
| ba | gpt-6-astra | high |
| shaper | gpt-6-astra | high |
| builder | gpt-6-astra | medium |
| builder-quick | gpt-6-astra | low |
| quick-builder | gpt-6-astra | low |
| qa | gpt-6-astra | medium |
| junior | gpt-6-astra | high |
| reviewer | gpt-6-astra | high |
| simplify | gpt-6-astra | medium |
| astra-slice-reviewer | gpt-6-astra | high |
| astra-test-architect | gpt-6-astra | high |
| astra-ui-lens | gpt-6-astra | medium |
| explorer | gpt-6-astra | high |

## Selection and execution rules

- These rows configure model selection, not authorization to spawn helpers or enable junior.
- A full Builder uses builder; a quick-labelled ticket uses builder-quick. The owner-opened quick-builder is a separate role.
- QA uses the qa row for walk, probe and verify. astra-ui-lens is visual advice, not the QA verdict.
- reviewer is a separate correctness review context; simplify remains a pass in the Builder session unless explicitly delegated. The simplify row configures a separately launched pass only.
- Cross-vendor review is separate from reviewer: another OpenAI model does not count as another vendor.
- No automatic model fallback or mid-session switching. If a selected model cannot run, report the exact failure rather than silently substituting.
- Do not default to max or ultra. The latter advertises automatic delegation in the current catalog, which must not silently change the role topology.
- Helper TOML model settings must be generated from these rows or omit duplicate defaults; never maintain conflicting model tables.

## Operating policy

- Coordinator: one Thomas per project frontier.
- Builder capacity: two independent tickets, provided their write-sets do not overlap.
  Start with one until the project's test environment supports concurrent runs.
- Junior: disabled by default; enabling is an owner choice, not implied by a model row.
  When enabled, Builder pauses writes while Junior owns the assigned subset.
- Cross-vendor arm: read the table below. Owner-authorized bounded pre-arm work may
  proceed with pending policy, NOT RUN and an explicit stop point in its brief; stricter
  project policy wins. Unconfigured never means off. Do not manufacture a passing receipt.
- Review/disposition: required checks are run with native tools and the project's
  existing verification commands. Thomas inspects evidence; there is no additional
  Astragentic state machine or claimed automatic merge enforcement.

## Cross-vendor arm

| Scope | Reviewer | Model |
|---|---|---|
| ticket | claude-code | claude-sonnet-5-5 |
| spec | claude-code | claude-sonnet-5-5 |
| slice | claude-code | claude-sonnet-5-5 |

Reviewer is `claude-code` (the Claude Code CLI, invoked per `codex-cross-vendor-review`),
`no` (owner's recorded off decision for that scope: no receipt owed, handback says
`Arm: off (orchestrator)`), or `unconfigured` (decision still missing: the role stops at
that gate and records NOT RUN). Another OpenAI model is never a reviewer value here. Model
is the Claude model id the pass runs with; it travels on the command line and has no other
home. This table is not read by `launch.py`; the roles read it.

## Evidence

Chosen against codex-cli 0.166.0 catalog from codex debug models; all 14 model/effort pairs validated against that output.
Catalog presence is not a completed inference/access test for each model. Workload quality and cost on Astragentic are not measured yet.
Guidance: https://developers.openai.com/api/docs/guides/model-selection
Owner decision 2026-11-08: every role runs gpt-6-astra; the earlier Astra/Sol/Luna/Terra split was an unmeasured starting point and is retired. Efforts are unchanged.
The allocation is an engineering starting point, not a benchmark claim.
