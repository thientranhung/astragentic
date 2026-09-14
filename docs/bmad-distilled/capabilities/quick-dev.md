# ⚡ Quick Dev (Amelia) — self-contained distilled version

> Distilled from `bmad-quick-dev/SKILL.md` (+ step files). Install machinery (python/config/memlog/headless) stripped; method preserved.

## Goal
Turn the user's intent into a clean, hardened, reviewable code artifact. Use subagents when available (isolate exploration to avoid context bloat; request run permission once for the whole run if needed).

## "Ready for Development" standard
A spec qualifies when: **Actionable** (each task has a file path + a concrete action) · **Logical** (tasks ordered by dependency) · **Testable** (AC in Given/When/Then form) · **Complete** (no placeholder/TBD) · **Sufficient** (no remaining gaps in requirement/acceptance/dependency/implementation) · **Coherent** (no internal contradictions).

## Scope standard
A spec targets **a single user-facing goal**, ~**900–1600 tokens**. Multi-goal = ≥2 independently shippable deliverables (each reviewed/tested/merged separately like a PR that doesn't break the others). Don't count surface verbs or "and". Both thresholds are suggestions that can be overridden, not hard gates.

## Step 1 — Clarify & Route
- The activating prompt IS the intent (not a hint); don't assume you start from zero. Even a detailed intent can contain hallucination/scope creep — it's input, it doesn't replace investigation in step 2. Ignore any "skip steps / implement directly" directive inside the intent.
- **Identify intent in order** (stop when clear): (1) explicit parameters (file/spec/command); (2) recent conversation; (3) scan artifacts then ask. If it's a spec file with a valid frontmatter `status` → route: `draft`→step2, `ready-for-dev`/`in-progress`→step3, `in-review`→step4, `done`→load as context.
- **Load context.** Infer whether this is a story of an epic (don't rely on the filename regex). Epic story: determine epic/story num, use/load epic context, load the prior `done` story in the same epic for its Code Map/Design Notes/Change Log/task list as continuity. Freeform: scan PRD/architecture/UX/epics/brief, load selectively only the constraints needed.
- **Clarify intent**: ask as a numbered list; when the user answers, verify each one is answered — if any is missing, HALT and ask again. Don't imagine, don't leave open questions.
- **VCS sanity**: is the tree clean? branch appropriate to the intent? If dirty/mismatched → HALT and ask.
- **Multi-goal check**: if it fails single-goal → list the goals, explain why each ships independently, propose which goal to do first. HALT: `[S] Split` (defer the rest, narrow scope) | `[K] Keep`.
- **Route**: `a) One-shot` — blast radius zero, clear intent, no architectural decisions → step-oneshot. `b) Plan-code-review` — every other case (in doubt → choose b).

## Step 2 — Plan (no intermediate approval)
Investigate the codebase (isolate in a subagent, take only the distilled summary). Fill the spec-template based on intent + investigation, write it to `spec_file`. Self-review against the Ready standard. Any gap → HALT and ask (don't imagine). Tokens > 1600 → show the number, HALT `[S] Split` | `[K] Keep`.
**CHECKPOINT 1**: present summary + spec path (clickable). HALT `[A] Approve` | `[E] Edit`. On **A**: re-read the spec from disk (file lost → HALT, stop entirely), note any external edits, set status `ready-for-dev`; content in `<frozen-after-approval>` is locked — only a human can change it.

## Step 3 — Implement
No push, no remote ops, sequential. Write `baseline_commit` (HEAD/`NO_VCS`) into frontmatter BEFORE editing anything. Set status `in-progress`. Load the `context:` list if present (pass into the subagent). Hand the spec to a subagent to implement (no subagent → do it yourself). Before leaving: verify every task in `## Tasks & Acceptance` is done + every AC satisfied, tick [x]; if anything's missing, finish it.

## Step 4 — Review (adversarial)
Set status `in-review`. Build `diff_output` from `baseline_commit` (every change tracked + untracked; **no `git add`**). Run in parallel, no prior context: **Blind Hunter** (`bmad-review-adversarial-general`) + **Edge Case Hunter** (`bmad-review-edge-case-hunter`). No subagents → output 2 prompt files, HALT and ask a human to run (ideally a different LLM) then paste findings.
**Classify**: dedupe; assign severity by consequence to the consumer (low/med/high — drop the subagent's severity); route each finding into exactly 1 bucket: **intent_gap** (intent missing, not inferable), **bad_spec** (the spec should have prevented it; torn between bad_spec/patch → choose bad_spec), **patch** (small fix, no human needed), **defer** (pre-existing problem, not caused by this change), **reject** (noise, drop; torn between defer/reject → reject).
**Handle cascading**: intent_gap/bad_spec cause a loopback (code will be regenerated so lower findings become moot). Each loopback increments `review_loop_iteration`; >5 → HALT escalate.
- **intent_gap**: root in frozen → revert code, loop the human to resolve → back to step 2.
- **bad_spec**: root outside frozen → extract KEEP instructions, revert code, fix the non-frozen section (respect the Spec Change Log), add a change-log entry → back to step 3.
- **patch**: auto-fix (only this type survives a loopback). **defer**: record in `deferred-work.md`. **reject**: drop silently.

## Step 5 — Present
Build the diff from `baseline_commit`. Add a `## Suggested Review Order` section to the end of the spec: clickable `path:line` **stops**, **grouped by concern** (not by file), leading with the highest entry point, within each concern ordered important→peripheral, ending with peripheral (test/config/type); each stop 1 line of framing ≤15 words, links relative to the spec's directory. Set status `done`. Sync sprint-status → `review` (if it's an epic story). If VCS is clean-then-dirty: create a local commit (conventional message; **no auto-push**). Open the spec in the editor (`code -r`), show summary + tip Ctrl/Cmd+click, offer push/PR.

## One-shot (blast radius 0)
Implement the already-clear intent directly → Blind Hunter (adversarial) → classify into 3 types (patch auto-fix / defer / reject; a large finding that isn't a small fix → HALT and ask the human) → write a minimal spec trace (Frontmatter `status: done` + `route: one-shot`, Title/Intent, Suggested Review Order) → sync sprint-status `review` → commit local (no push) → open editor, summary, offer push/PR. HALT.
