# Field incidents after 6.1.15 (batch for 6.1.16)

| id | lead | số đo | nguồn | layer and outcome |
|---|---|---|---|---|
| M-1 | nizzy 2026-11-16: walks run the plan's happy path; nothing makes a write surface get misuse cases | 19 walk reports mention the Design Library surface (10-15 to 11-16), 0 carry a re-drop or filename-collision case; the first run with an edge list (E1–E13 in its brief) found 1 P1 (one colliding filename in a second drop discards every pending tile) and 2 P2 | nizzy `.scratch/qa/*.md` grep; `.scratch/qa/edge-upload-1116-walk-81ec792dd.md`; `.scratch/harness-issues/report-to-astragentic-2026-11-16-qa-walk-lens.md` | upstream, plan method. `test-design` and `codex-test-design`: a surface that writes data gets misuse cases named for it, on the ticket that changes it, with the mutations named. **Fixed in text** |
| M-2 | the same edge walk reported CONCERNS with a failing P0 row (E3) | 1 of 1 edge walks; `qa.md` says FAIL for a failing P0 | report lines 55 and 167–176 | upstream, role text. `qa.md` (both runtimes): no reading overrides the verdict rule. **Fixed in text** |
| M-3 | proposal: a required `Lens:` brief line refused by the mod, a per-lens counter, an exploratory lens | chưa đo: the P1 came from the cases listed in the brief, not from a label | as M-1 | not built. Count first: write surfaces in nizzy's next 5 plans, how many carry misuse cases, what those cases find |

Field after ad250b7 (nizzy, 2026-11-16): M-2 re-judged to FAIL, commits `496f84177` (report) and `ff88970b2` (marker); no merge rested on the old verdict, F-E3 is TRA-1504. M-3 count open in nizzy `.scratch/harness-issues/misuse-case-count.md`: plan 1 of 5, 1 write surface, 1 with misuse cases, result pending.

nizzy on 6.1.16 (2026-11-16): `applied-version` 6.1.16, commit `d7db60e61`, 3 files taken, 0 conflicts, reachability exit 0; read upstream from its checkout: the misuse rule is in both test-design copies, the verdict sentence in `.agents/roles/qa.md`. Owed: per plan, whether a Shaper plan under 6.1.16 carries misuse cases unasked (5-plan total).

Not covered: live chưa đo (text only). Cost per firing: the edge run covered 5 of 13 cases, 4 partial, 4 not run for budget, so the misuse set rides on the ticket that changes the surface, not on every incremental walk.
