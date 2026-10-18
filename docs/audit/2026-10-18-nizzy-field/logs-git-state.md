# nizzy-ecom harness measurement (logs, git, state)

Repo: /Users/tranthien/Documents/2.DEV/2.PRIVATE/etsy-fulfillment-thanh. Measured 2026-10-18 ~10:40 +07, read-only. Window: `--since="30 days ago"` = 2026-09-18..2026-10-18 (first commit in window 2026-09-20 16:03).
Scripts: /tmp/nizzy-audit/a.py (git), c.py (hook log). Per-ticket rows (312): /tmp/nizzy-audit/per-ticket.md. Raw: a.json, deny.json, qa-cover.json, payload-diff.txt.
Verdict column is empty on purpose.

## A. Git, merged tickets

Unit: first-parent commit on main whose subject starts `Merge TRA-n` or `TRA-n:` (6 are squash-style `TRA-n: ... (#PR)`, no branch to count). Sync merges (`Merge origin/main into builder/...`) excluded. 312 merge events = 303 distinct tickets (9 merged twice: TRA-822, 945, 948, 949, 953, 957, 1114, 1122, 1124, typically a station-gate fix as a second merge).
Source: `git -C <repo> log main --first-parent --since="30 days ago"`, branch commits = `git rev-list <p1>..<p2>` per merge. Counts are per merge, summed.

| ISO week | merges | branch commits | simplify(increment) | arm(ticket) | arm(slice) on ticket branches | qa(walk) on ticket branches | Supersedes: | Pass: lines | Pass: citing Skill(...) | Implemented-by: | Ledger absent | Ledger: none | Arm: off | verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-W38 (partial) | 2 | 26 | 10 | 3 | 0 | 0 | 1 | 11 | 11 | 0 | 0 | 1 | 0 | |
| 2026-W39 | 71 | 807 | 200 | 136 | 0 | 0 | 66 | 215 | 194 | 0 | 0 | 23 | 0 | |
| 2026-W40 | 99 | 1078 | 281 | 144 | 0 | 0 | 25 | 288 | 283 | 0 | 4 | 85 | 0 | |
| 2026-W41 | 79 | 724 | 210 | 98 | 0 | 1 | 4 | 234 | 212 | 0 | 0 | 51 | 0 | |
| 2026-W42 (to 10-18) | 61 | 672 | 173 | 76 | 0 | 0 | 8 | 199 | 178 | 2 | 0 | 53 | 13 | |
| TOTAL | 312 | 3307 | 874 | 457 | 0 | 1 | 104 | 947 | 878 (93%) | 2 | 4 | 213 | 13 | |

Notes on the table.
- Commits per merge: median 10, mean 10.6, max 34. 11 merges have no simplify(increment) commit; 24 have no arm(ticket) commit.
- `Pass:` lines are in branch commit bodies (simplify markers), not in the merge message. Globally across `--all`: 952 `^Pass:` lines, 883 cite `Skill(skill: "simplify")`, 69 are bare (`Pass: 1/2/3`) or other text. Many Skill lines carry a note "ran the four corners directly / fork unavailable", so a Skill citation is not proof of a fan-out.
- `Supersedes:` falls from 66 (W39) to 4-8 (W41-42). Regex `^Supersedes:` over branch bodies plus merge message.
- `Ledger: none` is the dominant value (213 of 312 = 68%). Merges with NO Ledger trailer: TRA-957, 953, 948 (09-30), TRA-949 (09-29). Zero since 09-30.
- `Arm:` line on the merge message: absent on 233 of 312. Where present: `Arm: off (orchestrator)` 8, codex pass N needs-attention/approve ~15, others free text. Arm-off merges counted by regex `Arm:\s*off` = 13, all W42.
- Implemented-by (junior lane): 1 ticket, TRA-1131 (10-17), 2 commits, `grok/grok-4.7`.
- Reverts: 2 (TRA-835 on 09-22, TRA-902 on 09-28) as `Revert ...` subjects. `git log --all` shows 2.
- "fold-ish" subjects (regex fold|review|simplif|finding in branch commit subjects) = 1754. Crude: it also matches every simplify(increment) subject. Do not read it as a fold count. Per-ticket values are in per-ticket.md.
- Marker commits OUTSIDE ticket merges, `--all` in window: arm(slice) 8, arm(spec) 7 (first-parent 6 + 3), qa(walk) 16, qa(report) 4, rin(gate) 13 (last 2026-10-10, Rin retired in 3.0.0), `ledger` 15, `thomas:`/`chore(thomas)`/`orchestrator` resume commits 31 on main, `harness:` fold commits 65 on first-parent main.
- arm(slice) dates: 10-11, 10-12 (x2, both BLOCKING), 10-13, 10-15 (x2), 10-17, 10-18. Owed per last resume: "arm(slice) owed (12 merges)" (commit `thomas: resume`, 2026-10-18).

### Branches and worktrees

| item | count | source |
|---|---|---|
| local `builder/*` branches | 18, all merged into main | `git branch --merged main \| grep -c builder/` |
| remote `origin/builder/*` | 35, all merged, 0 unmerged | `git branch -r --merged main`, `git branch -a --no-merged main \| grep builder/` returns nothing |
| other local branches | 7 `spec/*`, 9 `ticket/*`, 3 `gate/*`, 2 `shaper/*`, 8 `worktree-agent-*`, 5 `*-review`/`tmp-review`/`tra*-work`, archive, backup-467-stack, chore, discussion, evidence, fix | `git branch -a` |
| `git worktree list` | 10 entries (main + 9) | `git worktree list` |
| builder worktrees | 0 (all cleaned) | `.claude/worktrees/` has no `builder-*` |
| stale worktrees | 6 `agent-*` (5 detached at 0d829a524 / a50d28363, 1 on `review-TRA-1143`), created 10-17..10-18, clean; plus `deploy-agent` (10-08, 3 dirty files), `design-partner` (10-04, 1 dirty), `harness-partner` (10-08, 1 dirty), all detached; 0 flagged prunable | `git worktree list --porcelain`, `git -C <wt> status --porcelain` |

## B. Stamps

Source: `.git/astraler-stamps/harness-ticket-done/` (134 files, first mtime 2026-10-05) and `harness-released/` (299 files). A stamp holds one line `<ts> TRA-n base=main moved=none` plus git/tracker/plug lines.

| measure | value | verdict |
|---|---|---|
| distinct tickets merged in window | 303 | |
| merged on/after 2026-10-05 (stamps exist from then) | 137 | |
| of those without a stamp | 4: TRA-994, 996, 998, 999 | |
| stamps for a ticket not merged via ticket merge | 1: TRA-1130 (spec merge) | |
| stamps per day (10-05..10-18) | 3,14,17,11,4,12,14,11,13,4,9,8,4,10 | |
| merged before 10-05 | 166, no stamp possible (stamp store starts 10-05, or earlier ones lived in /tmp/harness-ticket-done) | |

## C. Hook log /tmp/harness-hook-events.log

Source: `/tmp/harness-hook-events.log`, 2.3 MB, 20129 lines = 15898 timestamped entries (rest are continuation lines of multi-line commands). First entry 2026-10-15T08:34:06Z, last 2026-10-18T02:45:04Z (mtime 10-18 09:45 +07). It was recreated mid-window, so it covers 3.3 days, not 30.
IMPORTANT: the log is machine-wide, shared by every project and by the astragentic repo's own selftests. Only a minority of lines name nizzy. Attribution by path text in the git-guard command: nizzy 1890, inception 142, astragentic 20, unattributed 11797. Dispatch keys `IN-*` (inception) and `AB-*` (astragentic selftest) are not nizzy.

| kind | total | 10-15 | 10-16 | 10-17 | 10-18 (to 02:45Z) | verdict |
|---|---|---|---|---|---|---|
| hook-git-guard (all verdicts) | 13883 | 3903 | 2472 | 6465 | 1043 | |
| hook-tracker-status | 1104 | 21 | 20 | 907 | 156 | |
| hook-agent-isolation-guard | 327 | 56 | 76 | 175 | 20 | |
| hook-contract-reload FIRED | 292 | 2 | 0 | 246 | 44 | |
| hook-contract-reload INERT | 208 | 6 | 12 | 162 | 28 | |
| astragentic-dispatch REFUSED merge-gate | 52 | 0 | 0 | 38 | 14 | |
| astragentic-dispatch REFUSED tdd-gate | 19 | 6 | 3 | 9 | 1 | |
| astragentic-dispatch REFUSED refused-command | 12 | 0 | 0 | 0 | 12 | |
| astragentic-dispatch REFUSED arm-gate | 1 | 0 | 1 | 0 | 0 | |
| `HOOK: SubagentStop` lines (project-side, settings.json:45-51) | 1194 (`grep -c "HOOK: SubagentStop"`, appended to the preceding line without a newline, so the parser did not count them as entries) | | | | | |

hook-git-guard verdicts (13883): allow 12032 (86.7%); no-opinion 1823 total = unreadable-construct 977, assignment-prefix 307, reserved-or-wrapper:find 302, :bash 79, :for 59, :xargs 27, :nohup 15, :timeout 9, :while 4, :until 4, untokenizable 3, :env 2, :command 1; DENY 28 (0.2%). `base-guessed` appears 34 times (grep count of the string `base-guessed(main: no`), kept as stated in the lead's list but it is not a separate entry kind in the parser.
DENY per day: 10-15 6, 10-16 9, 10-17 9, 10-18 4. The log prints the command but not the rule name. Classified by command text (my inference):

| command text | DENY count | likely rule | verdict |
|---|---|---|---|
| `git add -A` / `git add -A <dir>` | 12 | 4.0.2 pathspec-aware add guard | |
| `git push origin main` | 4 | push needs ticket stamp / owner | |
| `git worktree remove` | 3 | worktree removal | |
| `gh issue close ...` | 3 | close only via ticket-done.sh | |
| `scripts/release-worktree-resources.sh ...` | 3 | cleanup script guard | |
| `git branch -D` / `rm -rf` | 1 / 1 | destructive | |

hook-agent-isolation-guard (327): allow(agent,read-only-type) 142, allow(agent,isolated:worktree) 90, allow(agent,outside-builder-worktree) 2, DENY 93 (28%), all text "Agent call with subagent_type=X and no isolation, dispatched from ...". One DENY names `astragentic-dispatch:bmad-sal...`.
hook-contract-reload: FIRED 292 vs INERT 208. FIRED lines include `role=../../etc/passwd` and `role=?` (selftest probes), only 15 of the 499 reload lines have a root naming the etsy repo; the rest are astragentic and tmp-dir selftests, so this row is mostly NOT nizzy. INERT = SessionStart with `source=startup`, no compact, as designed.
hook-tracker-status: injected N chars 534 (439 + 95 variant), `no plug at .astraler/project/tracker-status.sh (empty socket)` 190, `exited N (offline, unauthenticated...)` 95, `printed nothing` 95, `is not executable` 95, `stdin was not JSON` 95. The 95-fold repeats are a selftest block.
REFUSED lines naming TRA keys (nizzy): tdd-gate TRA-1114, 1116, 1117, 1120, 1124, 1125, 1131, 1132, 1134, 1135, 1136, 1138, 1139, 1141, 1144, 1140 = 16 (one each, all on `content commit:`); arm-gate TRA-1124 (10-16 13:41, "arm requested: codex-arm"). So nizzy: 16 tdd-gate + 1 arm-gate = 17 REFUSED. Not nizzy: merge-gate AB-6 x52 (`no record of: simplify`), refused-command AB-5 x12 (`make db-down`), tdd-gate IN-137/139/140 x3.

## D. Watchdog

Sources: /tmp/herdr-watchdog-nizzy-ecom.log (87 lines, 23 KB, last write 10-14 15:06), -inception.log, -wdedge.log, and `*.state/` dirs. Lines carry `[HH:MM:SS]` only, no date. The nizzy log spans several days; alert_reset epoch 1791965177 = 2026-10-14 15:06:17, which is the last alert.

| alert kind (nizzy-ecom log) | count | verdict |
|---|---|---|
| STUCK | 65 (shaper-tra-* 39, builder-tra-* 23, rin-* 3, + thomas idle/done variants) | |
| RECORD_UNREADABLE (dispatch-record.json unreadable as JSON) | 6 (01:34, 01:52, 02:09, 02:27, 02:44, 03:02) | |
| WATCHER_LOST | 2 (17:18, 17:23, first poll after start) | |
| BLOCKED | 1 (14:25, shaper-tra-1021) | |
| NOTIFY_FALLBACK THOMAS_CRASHED | 4 (20:47, 21:04, ...) | |
| started (restarts) | 7 | |
| lock holder gone / exiting-workspace-not-found | 1 / 1 | |

Panes named (STUCK/BLOCKED/WATCHER_LOST): shaper-tra-1078 x26, shaper-tra-1021 x10, shaper-tra-1045 x4, builder-tra-1061 x4, builder-tra-1074 x3, builder-tra-1064/1065/1019 x2, 12 more builders once, rin-batch-1035-1044, rin-catalog-routing-slice, rin-deploy-batch-1015-1034, rin-provider-account-routing. These are 10-12..10-14 lanes, so this log mostly predates 3.2.0 (watchdog silent on mod-recorded panes) landing.
Current state: `alive: [10:33:20] alive — poll #960, 0 dispatched pane(s)`; alert_count_main 0. Processes: 4 `herdr-watchdog.sh 300 900 6` running (pids 11099, 11160 since Wed 3PM = 10-14; 99854, 99879 since Mon 10PM = 10-12). inception log: 3 THOMAS_CRASHED fallbacks. wdedge log: 1 NEVER_STARTED, a selftest (interval=1s, tmp repo).
No watchdog alert after 10-14 15:06 in the nizzy log, i.e. none in the 4 days of the 4.0.x work.

## E. State

| item | value | source | verdict |
|---|---|---|---|
| applied-version | 4.0.2 (mtime 10-17 18:37) | .astraler/state/applied-version | |
| CANDIDATE | 4.0.2 (same) | .astraler/CANDIDATE | |
| releases dir | 119 dirs; 15 are >=3.0.0 | .astraler/releases | |
| releases fetched in window (dir mtime) | 3.0.0 10-10, 3.0.1, 3.0.3, 3.1.0 and 3.1.1 (10-10, 22:21 and 22:30), 3.2.0 10-12, 3.2.1 10-12, 3.2.2 10-12, 3.2.4 10-12/13, 3.2.5 10-13, 3.2.6 10-13, 3.3.0 10-14, 3.3.1 10-15, 4.0.1 10-17 09:47, 4.0.2 10-17 18:36 | `stat` | |
| 4.0.0 | no release dir; folded into 4.0.1 (commit e99e76ab9) | git log | |
| ADAPTATION-REPORT.md | mtime 10-14, last receipt = 3.3.0. NO receipt for 3.3.1, 4.0.1, 4.0.2 although applied (commits 0e64afa4e, e99e76ab9, 38c1f90be) | .astraler/state/ADAPTATION-REPORT.md:1 | |
| dispatch-record.json | 102 KB, 131 top-level entries (1 `workspace`, 108 `TRA-n`, rest QA-/RIN-/ARM-/SPEC-/DEPLOYER/standing_agents/_owner_rulings/dispatches); 21 with no `status`; waiting_on: 0 entries; refusals arrays: 0 | python json load | |
| record fields | status 110, worktree 93, pane 93, tab 90, workspace 85, runtime 85, retired_at 84, branch 82, write_set 80, base 79, agent 68, issue 67, session 67, monitor 67, model 65, effort 60, identity 44, dispatched_at 39, merged_sha 33, gate 15, handback_sha 18; ~60 one-off ad-hoc fields (pass1, pass2, arm_marker, fold_sha, draft_b09f0397...) | | |
| record entries with `role` field | 2 of 131 | | |
| last 3 entries | contain only qa_last_turn_end_at / qa_last_mode (qa_last_mode = "None") | | |
| gate-history/ | 9+ files, e.g. batch-1035-1044-0651f725e.md 45 KB, last write 10-09 | .astraler/state/gate-history | |
| qa-verified-clean.md | 135 lines, 9.3 KB, 10-16 | | |
| native-dispatch/ | dir mtime 09-20 | | |

Plugs in .astraler/project/ (mtime): cleanup-worktree.sh 09-27 (20 KB), marker-evidence-paths.txt 10-09, marker-kinds.json 10-09, marker-output-check.sh 10-09, not-a-skill.txt 09-21, role-budgets.txt 10-09 (thomas 3930 words, builder 1960), setup-worktree.sh 10-09 (7.1 KB), shared-compose-projects 10-13, status-line.sh 10-09, ticket-done.sh 09-27 (8.1 KB), tracker-state.sh 10-05, tracker-status.sh 09-21, watchdog-probe.sh 10-09, work-in-flight.sh 10-05; overlays/ builder.md 14 KB, thomas.md 18 KB, dispatch-brief.md 1.5 KB (dir mtime 10-10). No `refused-in-dispatched-panes` file exists (the 4.0.x refusal list is not project-configured; the db-down refusal was done as repo tool tools/agent-pane-db-guard.sh, commit 2e3075d74 TRA-1147).

## F. What this project changed or bypassed in the payload

Payload copy used: .astraler/releases/4.0.2/harness/ (92 files). Comparison: every payload path vs the same path in the repo (`cmp`). Result: 89 identical, 3 differ, 0 missing. Source: /tmp/nizzy-audit/payload-diff.txt.

| # | where | change | kind |
|---|---|---|---|
| 1 | .claude/settings.json:2-5 | `enabledPlugins` block (agent-skills false, ponytail true) not in payload | added |
| 2 | .claude/settings.json:13-14, 28-29 | extra PreToolUse hook on matcher `Agent` and a second one under the Bash matcher, running project file tools/hook-agent-isolation-guard.py (not a payload file) | added |
| 3 | .claude/settings.json:24 | `"onFailure": "block"` on hook-git-guard (payload has none). The ADAPTATION-REPORT:5 records it as an owner decision | modified |
| 4 | .claude/settings.json:45-51 | SubagentStop hook appends a line to /tmp/harness-hook-events.log (payload has this too, order differs) | reordered |
| 5 | .agents/orchestrator.md:11-17 | `<set-me>` workspace-label filled `nizzy-ecom`; builder-target `2` instead of 4 | config |
| 6 | .agents/orchestrator.md:21-25 and 27-48 | rewritten builder-target paragraph plus 22 added lines of owner rulings (2026-09-23 one lane, 10-11 two lanes, 10-13 two lanes) | project prose in payload file |
| 7 | .agents/orchestrator.md:60-61, 89, 93-95 | further small edits | modified |
| 8 | .agents/memory/INDEX.md | generated file, 6 differing lines | regenerated |
| 9 | ADAPTATION-REPORT.md:4 | "eight owner-kept paths": orchestrator.md, settings.json, four codex profiles, .opencode builder, INDEX.md. 4.0.1 commit cbc4ad2c3 dropped `.opencode/` | declared |

Project-side machinery that sits next to or in front of the payload:
- core.hooksPath = tools/git-hooks (commit-msg 52 lines, pre-commit 105, pre-push 119). pre-push refuses a ticket branch not shown as claimed (tools/git-hooks/pre-push:2-8) and calls `gh issue` 3 times; commit-msg checks marker trailers (commit-msg:2-8, TRA-625).
- tools/: agent-pane-db-guard.sh, hook-agent-isolation-guard.py, check-payload-drift.sh, payload-drift-manifest.json (3 entries, 0 symlinks), ticket-claim.sh, mark-deployed.sh, strip-status-labels.sh, gate-plan.sh, tracker-state-selftest.sh etc.
- Plugs: 14 files in .astraler/project/ listed under E. Three override payload defaults: role-budgets.txt (thomas 3930, builder 1960 words), marker-evidence-paths.txt (`.scratch/gates/*.md`), shared-compose-projects.
- AGENTS.md: 704 lines, 61 headings. Mentions (case-insensitive, per line): worktree 21, arm 18, Ledger 14, claim 7, marker 5, TURN-END 0.
- .claude/rules/: 9 files, total ~34.5 KB: dev-stack-per-worktree.md 10.2 KB, tracker-status-is-a-required-field.md 5.2 KB, manual-sku-is-live-seller-protection.md 4.4 KB, marker-tail-order.md 4.2 KB, verify-on-local-not-on-production.md 3.9 KB, worker-system-truth.md 3.3 KB, seller-visual-first.md 1.6 KB, dashboard-tables.md 1.2 KB, no-secrets-in-exports.md 0.7 KB (sizes from `ls -la`).
- Overlays: builder.md 14,117 B, thomas.md 18,118 B, dispatch-brief.md 1,482 B = 33.7 KB project text loaded on top of payload roles.
- docs/agents/: domain.md, issue-tracker.md, merge-station.md, tracker-contract.md, triage-labels.md (5 files).

## G. QA

| measure | value | source | verdict |
|---|---|---|---|
| docs/qa/plan-*.md | 13 files, 10-10..10-16, 0.1..39 KB | `ls docs/qa` | |
| QA walk/probe reports added in window | 14, all in .scratch/qa/ (10 walk, 3 probe, 1 slice-close pair counted as 2): dates 10-11 x1, 10-13 x4, 10-14 x2, 10-15 x5, 10-16 x2 | `git log --diff-filter=A` | |
| `qa(walk):` verdict commits | 16 (verdicts seen: PASS and CONCERNS) | `git log --all --grep` | |
| `qa(report)` / `qa:` report commits | 4 / ~14 | | |
| Builder visual evidence | 57 new files under .scratch/evidence/ in window | | |
| verified-clean list | .astraler/state/qa-verified-clean.md, 135 lines | | |
| tickets named by a QA report | 23 of 303 merged (7.6%); of 84 merged on/after 10-10 (3.0.0 QA chain) 23 (27%) | qa-cover.json | |
| report committed AFTER the ticket merge | 22 of 23; 1 before | | |
| report after Builder's last commit and before merge | 0 to 1 | | |

QA is run on batches or slices after merge, never gating a single ticket merge. QA reports first appear 10-11. Before that the QA lane was Rin (rin(gate) commits 13, last 10-10).

## H. Tracker (GitHub Issues)

| measure | value | source | verdict |
|---|---|---|---|
| `gh issue` occurrences | 70 lines across tools/, scripts/, .astraler/project/. Top: strip-status-labels-selftest.sh 14, tracker-state-selftest.sh 9, strip-status-labels.sh 9, mark-deployed-selftest.sh 7, tracker-state.sh 7, ticket-claim-selftest.sh 6, mark-deployed.sh 6, ticket-claim.sh 5, pre-push 3 | `grep -rc "gh issue"` | |
| last 30 closed issues | span 2026-10-15 18:02Z..10-18 01:48Z; 26 COMPLETED, 4 NOT_PLANNED | `gh issue list --state closed --limit 30` | |
| of the 30, ticket ids with a stamp | 26 of 30 | stamps | |
| closed without stamp | TRA-1126, 1127, 1128, 1129 (the 4 NOT_PLANNED, still labelled); TRA-1130 (spec, issue 1191) has a stamp but no ticket merge | | |
| issues that merged but are still open | 0 | open list x merges | |
| open issues | 13: parked 9, debt 2, todo 2, backlog 2 | `gh issue list --state open` | |
| write-back | working: every merged ticket in the sample is closed; the 4 unstamped closures are not-planned cancellations | | |

## Sources that are missing or truncated

- Hook log: starts 2026-10-15 08:34Z (recreated); covers 3.3 of 30 days. Shared across projects, no project field, so only ~14% of git-guard lines (1890 of 13883) can be attributed to nizzy by path text. DENY lines do not print the rule that fired.
- Hook log multi-line commands: continuation lines are not timestamped, so line counts (20129) exceed entry counts (15898).
- Watchdog logs: no dates, only HH:MM:SS. The nizzy log stops at 10-14 15:06 although the process is still alive. Four watchdog processes run concurrently (two started 10-12, two 10-14), unusual for one workspace; the lock file names pid 11099.
- Stamps: store begins 2026-10-05; 166 earlier merges cannot be checked. Earlier stamps lived under /tmp/harness-ticket-done/ (per pre-push:5-6) and are not in this measurement.
- `/tmp/harness-ticket-done` and `harness-released` content not interpreted beyond counts.
- ADAPTATION-REPORT.md has no receipt for 3.3.1, 4.0.1, 4.0.2. 4.0.0 has no release dir.
- dispatch-record.json: 21 entries without status; there is no `role` field in 129 of 131 entries, so lanes by role cannot be counted from it. Watchdog logged it as unreadable JSON six times at 01:34-03:02 on an unknown day.
- Git "fold" count is a regex proxy and overstates. `Pass:` counts include both trailer-like lines in all branch commits and are not de-duplicated across merges that merged the same branch twice.
- Branch commits per merge count reachable-from-branch-not-from-main; commits made on main between sync merges are excluded.
- Squash-style merges (6) show 1 commit, not the real branch size.
- QA coverage matched by ticket id in filename, commit subject and first 1500 bytes of the report; batch reports named by range (e.g. 1121-1123) expand to every id in the range.
- Transcript-only traces (skill invocations, forks, subagent counts) are out of scope here.
