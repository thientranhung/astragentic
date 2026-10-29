# 🕵️ Adversarial Review (General) → the `adversarial` lens / Blind Hunter (upstream main 61e01f8, 2026-10-18)

> `bmad-review-adversarial-general` became a lens in v6.11.0 (`CHANGELOG.md:71`). Distilled from `skills/bmad-review/references/lens-adversarial.md`, `skills/bmad-review/SKILL.md`, and the **Blind Hunter** lens in `skills/bmad-code-review/customize.toml:88-105`. Baseline: `docs/bmad-distilled/capabilities/review-adversarial-general.md`.

## What changed
The "cynical, jaded reviewer … clueless weasel" persona is gone: A/B piloting on Claude and Codex showed the framing made no difference to residual-bug hit rate, while **requiring at least ten concrete findings and asking what is missing** did (`CHANGELOG.md:107`). The method is the persona now.

## The lens (any content: diff, document, ticket, plan)
Conduct a review of the provided content.
**Look for what's missing, not only what's wrong.**
Find **at least ten** issues to fix or improve.
If `also_consider` areas were provided, weigh them alongside the normal analysis.
If the content is empty, stop and say so.
If you have zero findings, **re-check and keep thinking; do not stop with an empty list.**

## Blind Hunter variant (code review, thorough set)
Same instruction on a diff, with a **size-scaled finding floor**: `N = min(floor(sqrt(kB) + 1), 10)` where kB is the diff file's size; state the arithmetic in one line, then find at least N. Context-free: no intent, no plan, no claims — "blind" means blind to intent, not to the codebase. Review by inspection only; do not modify code, run tests, invoke skills, or spawn subagents; return findings as text.

## Findings shape
Canonical fields, one per finding:
- `location` — file:line for code; section or heading for documents; "general" when it spans the artifact
- `trigger_condition` — the problem, in one line
- `guard_snippet` — the concrete fix or improvement
- `potential_consequence` — what goes wrong if it ships unaddressed

**No severity, priority, or ranking** — the caller's triage grades (see `code-review.md`). Overlap with another lens is signal, not duplication.

## Inside `bmad-review`
One review skill, many lenses (`adversarial`, `edge-case-hunter`, `verification-gap`, `structure`, `prose`; teams add or replace by code). Content is staged once as a file; independent lenses run in parallel, each seeing content and `also_consider` and **never another lens's findings**; a dependent lens (`prose` after `structure`) runs on the named lens's findings. The claims file goes to the edge-case lens alone. Invoked only when the user says "review" or another skill directs it; never on edits you just made. "Report what is real — never pad to look thorough" applies to every lens except this one, which treats an empty list as a signal to re-check.
