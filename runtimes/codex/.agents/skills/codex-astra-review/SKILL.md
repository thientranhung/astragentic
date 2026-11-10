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

## On Orca: a lens is a child process

An Orca dispatched worker's preamble reads "Do only this task, yourself: no subagents or helper
workers unless the task asks" and defines helpers as `orca orchestration worker-start`. Under that
text this model emitted no `spawn_agent` call in 10 of 10 sessions (2026-11-10: 4 field workers on a Codex
project incl. a fresh 6.1.2 probe, 6 fixture runs), 4 of 4 without it the same hour; a task line
or an AGENTS.md rule saying the task asks for native sub-agents lifted it 0 of 4. So on Orca each
lens is one `codex exec` child run through `exec` from the worktree, all three started before any
report is read, the `-o` file being the lens artifact. The argv is encoded, never concatenated:

```python
argv = ["codex", "exec", "--cd", worktree, "--model", model,
        "-c", 'model_reasoning_effort="' + effort + '"', "-c", "notify=[]",
        "-o", report_path, lens_message]            # lens_message as above, e.g. "Use $review-agent to review <base>..<head> …"
if permission_mode == "yolo":                       # the parent's recorded owner selection
    argv.insert(2, "--dangerously-bypass-approvals-and-sandbox")
```

Measured on a fixture under the full preamble (2026-11-10): 2 of 2 children answered; 1 of 1
`$review-agent` child pinned base and head and named a planted defect at `stats.py:3`. A child
reaches the provider itself: measured under `danger-full-access` only; a `network_access: false`
sandbox is chưa đo. A child that exits non-zero or writes no report is a failed lens: quote its
stderr, record coverage as incomplete.

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
