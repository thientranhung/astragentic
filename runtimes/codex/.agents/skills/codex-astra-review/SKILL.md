---
name: codex-astra-review
description: "Review an Astragentic full-ticket increment for correctness, owner intent and project standards, then verify and route each finding."
---

# Three review axes

Pin base/head/tree and current dirty state. Read the full ticket intent and applicable
project standards. Do not hide untracked or unstaged changes. For committed work the
native correctness entrypoint is `codex review --base <base>`; confirm installed help
before invocation. `--uncommitted` covers staged, unstaged and untracked changes;
for a mixed committed-plus-dirty increment inspect both ranges and record the final
tree. Do not silently drop either range. Native correctness review is optional when
the authorized helper already provides that lens; avoid duplicate inference for the
same scope. Never pass an incompatible option combination or treat process
exit alone as a clean review. Save the report and check the reviewed artifact matches.

Use `astragentic_reviewer` in separate contexts for correctness, intent and standards
when native helpers are available and delegation is authorized. Otherwise use native `codex review` for correctness when authorized and available.
Inspect intent and standards locally to find defects, but record their independent
coverage as incomplete until separately reviewed in authorized contexts. A local
inspection never substitutes for an independent required lens. Correctness examines defects/reachable states.
Intent maps every criterion and Must-not-change to actual test and behavior coverage.
Standards cites applicable project rules, excluding issues already enforced by lint.
Helpers inspect only: no edits, no test runs, no recursive delegation. If a required
lens cannot run, report incomplete coverage; do not label the result clean.

Number findings by lens. Verify each at its line, including callers/guards and whether
the unwanted state is reachable. Assign high (data loss/security/silently wrong result),
medium (broken behavior or verification gap), low, false, or undecidable with needed
evidence. Severity is impact, not fix cost. Group surviving shared root causes while
keeping per-axis verdicts. Missing-test claims require searching and reading tests.

Route unambiguous in-scope defects to patch and rerun covering checks; ambiguous owner
intent to decision_needed; pre-existing or undecidable findings to explicit defer.
Do not defer a verified defect introduced by this change. Record every disposition.
Finish with per-axis status and artifact identity, then run codex-simplify. Quick tickets
need correctness review only. A failed lens is not zero findings.
