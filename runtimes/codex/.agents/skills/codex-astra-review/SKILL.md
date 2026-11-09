---
name: codex-astra-review
description: "Review an Astragentic full-ticket increment for correctness, owner intent and project standards, then verify and route each finding."
---

# Three review axes

Commit first, then pin base/head/tree; review a committed head. Read the full ticket intent and applicable
project standards. Do not hide untracked or unstaged changes. Save the report and check the
reviewed artifact matches.

The Builder spawns `astragentic_reviewer` three times with `spawn_agent` from its own session, one
lens each, all three before reading any result, and collects them with `wait_agent`. A lens is a
helper, not a Herdr pane, and Thomas is not in the loop. If `spawn_agent` fails, write the exact
error and record coverage as incomplete. A local inspection never substitutes for a required lens.
Correctness is the built-in review: its message starts `Use $review-agent to review <base>..<head>`.
Intent maps every criterion and Must-not-change to actual test and behavior coverage.
Standards cites applicable project rules, excluding issues already enforced by lint.
Helpers inspect only: no edits, no test runs, no recursive delegation. If a required
lens cannot run, report incomplete coverage; do not label the result clean.

Number findings by lens. Verify each at its line, including callers/guards and whether
the unwanted state is reachable. Assign high (data loss/security/silently wrong result),
medium (broken behavior or verification gap), low, false, or undecidable with needed
evidence. Severity is impact, not fix cost. Group surviving shared root causes while
keeping per-axis verdicts. Missing-test claims require searching and reading tests.
For removed tests, independently reconcile the behavior-retirement inventory against
production behavior and replacement assertions. For validation, compare actual command
receipts to the BASE-owned scoped obligation map; do not infer a required guard ran
because a nearby lint command passed. For interface changes inspect executable wiring
and generated consumers, not only the package that declares the interface.

Route unambiguous in-scope defects to patch and rerun covering checks; ambiguous owner
intent to decision_needed; pre-existing or undecidable findings to explicit defer.
Do not defer a verified defect introduced by this change. Record every disposition.
Finish with per-axis status and artifact identity, then run astra-codex-simplify. Quick tickets
need correctness review only. A failed lens is not zero findings.
