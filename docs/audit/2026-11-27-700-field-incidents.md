# Field incidents — batch after 7.0.0 (opened 2026-11-27)

Batch file for the release after 7.0.0. Rows 30–37 are in `2026-11-27-6130-field-incidents.md`.
Each row: `số đo | nguồn`. A report is a lead; the numbers below are re-measured here.

| # | Defect | số đo | nguồn | Layer | Status |
|---|---|---|---|---|---|
| 38 | **An owner-launched role added upstream fails the project's reachability check until the project's own README names its launcher.** `check-reachability.py` check 5 reads the PROJECT's `README.md` for `--agent <role>` for each role in `OWNER_LAUNCHED` (`thomas`, `ba`, `quick-builder`, `dev`); the README is the project's file, and neither the 6.1.29 nor the 7.0.0 by-hand list told the project to add the `dev` row | nizzy upgrade 6.1.28 → 7.0.0: check-reachability FAIL (check 5) until Thomas added Dev and PR Reviewer rows to the README (`580947186`); `OWNER_LAUNCHED` at `harness/scripts/check-reachability.py:486` | nizzy Thomas report (a), 2026-11-27; nizzy git log | upstream (release note by-hand list, or the check's source of truth) | open: next batch |
| 39 | nizzy's own marker tools (`tools/check-marker-message.sh:43`, `tools/git-hooks/commit-msg:14`) list `arm(slice)` and not `arm(integration)`, so a 7.0.0 integration-review marker message is not validated by them | 0 `arm(integration)` markers yet; grep of the two files | nizzy working tree, read-only | project (its own tools) | fixed by nizzy (`7f70a3fd7`). Planted in a scratch clone: a malformed `arm(integration):` message exits 0 before and after, and so does a malformed `arm(slice):` with the old script, because the checker treats the milestone kinds as advisory. So the gap had no effect; the fix keeps the two names alike |
