# Field incidents after 6.1.15 (batch for 6.1.16)

| id | lead | số đo | nguồn | layer and outcome |
|---|---|---|---|---|
| M-1 | nizzy 2026-11-16: walks run the plan's happy path; nothing makes a write surface get misuse cases | 19 walk reports mention the Design Library surface (10-15 to 11-16), 0 carry a re-drop or filename-collision case; the first run with an edge list (E1–E13 in its brief) found 1 P1 (one colliding filename in a second drop discards every pending tile) and 2 P2 | nizzy `.scratch/qa/*.md` grep; `.scratch/qa/edge-upload-1116-walk-81ec792dd.md`; `.scratch/harness-issues/report-to-astragentic-2026-11-16-qa-walk-lens.md` | upstream, plan method. `test-design` and `codex-test-design`: a surface that writes data gets misuse cases named for it, on the ticket that changes it, with the mutations named. **Fixed in text** |
| M-2 | the same edge walk reported CONCERNS with a failing P0 row (E3) | 1 of 1 edge walks; `qa.md` says FAIL for a failing P0 | report lines 55 and 167–176 | upstream, role text. `qa.md` (both runtimes): no reading overrides the verdict rule. **Fixed in text** |
| M-3 | proposal: a required `Lens:` brief line refused by the mod, a per-lens counter, an exploratory lens | chưa đo: the P1 came from the cases listed in the brief, not from a label | as M-1 | not built. Count first: write surfaces in nizzy's next 5 plans, how many carry misuse cases, what those cases find |

Field after ad250b7 (nizzy, 2026-11-16): M-2 re-judged to FAIL, commits `496f84177` (report) and `ff88970b2` (marker); no merge rested on the old verdict, F-E3 is TRA-1504. M-3 count open in nizzy `.scratch/harness-issues/misuse-case-count.md`: plan 1 of 5, 1 write surface, 1 with misuse cases, result pending.

nizzy on 6.1.16 (2026-11-16): `applied-version` 6.1.16, commit `d7db60e61`, 3 files taken, 0 conflicts, reachability exit 0; read upstream from its checkout: the misuse rule is in both test-design copies, the verdict sentence in `.agents/roles/qa.md`. Owed: per plan, whether a Shaper plan under 6.1.16 carries misuse cases unasked (5-plan total).

Not covered: live chưa đo (text only). Cost per firing: the edge run covered 5 of 13 cases, 4 partial, 4 not run for budget, so the misuse set rides on the ticket that changes the surface, not on every incremental walk.

## inception 2026-11-21: a Claude review in place of an arm that is off

Lead: inception Thomas (`workspace-app-inception-c2`), on the owner's request. Arm off for ticket, spec and slice since 2026-11-11; asks for a Claude sub-agent review in each scope's place, model per scope, receipt marked not cross-vendor.

| id | lead | số đo | nguồn | layer and outcome |
|---|---|---|---|---|
| N-1 | "nothing independent reads a ticket's diff" | 8 of 8 slice-1121 tickets ran `code-review` plus fresh-context Intent and Standards lenses, all `claude-sonnet-5`; none named the 6 slice findings | Builder transcripts IN-474..479, 487, 488 | false as stated: same-vendor lenses run; what is missing is an adversarial read |
| N-2 | the slice fan-out ran on Opus by accident | 21 `astra-slice-reviewer` transcripts since 11-11: 15 `claude-opus-5-5` (parent's model), 6 `claude-sonnet-5` (11-12, within 13 min); 14 `arm(slice)` markers in the same days, so the 21 over-counts | inception transcripts `agent-*.meta.json`; git log | Opus is what the owner suggests for slice; no change |
| N-3 | would a ticket-scope adversarial read catch what the slice found | replay of IN-474 alone (tree from `git archive` at its merge, no later history), slice-reviewer method: Opus 4 findings, 109k tokens, 23 tool calls, 2.5 min; Sonnet 6 findings, 90k, 22, 1.7 min. Of the 2 slice findings rooted in IN-474 (#4 skip never fires on restart, #5 MaxAttempts on queued jobs): 0 named exactly, 1 same symptom by both (the skip does not stop a re-call, through the 1-min consumer lag). Both name defects no lens or slice reported; real or not chưa đo | `/tmp/upstream-check/replay474/`; agent reports | n=1; findings sent to inception to verify |
| N-4 | `isolation: "worktree"` lenses diff a stale range (IN-479, IN-488) | chưa đo: not found in the two Builders' transcripts by keyword; 4 of 8 tickets ran the lenses with `isolation: "worktree"` | as N-1 | asked inception for the lines |
| N-5 | `astra-document` review on Sonnet when `review.codex` is off | 0 payload files | the plugin is not in `harness/` | not ours; returned |

Prior ruling (6.1.7): a Claude pass on a Claude diff is never an arm receipt; a dated `no` row is the sanctioned degraded state; reopen with a second sustained outage's numbers. inception's 10 days (140 merges, 14 slice gates, fan-out only) is that outage; the decision to substitute is the owner's.
