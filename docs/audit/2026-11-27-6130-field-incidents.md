# Field incidents — batch after 6.1.29 (opened 2026-11-27)

Batch file for the release after 6.1.29. Rows 1–29 are in `2026-11-22-6120-field-incidents.md`.
Each row: `số đo | nguồn`. A report is a lead; the numbers below are re-measured here.

## Intake: nizzy BA report "where Builder time goes" (2026-11-27, cross-session, owner's word)

Population re-measured: 28 first-parent merges into nizzy main since 2026-11-26 (the report counted
14 tickets / 154 commits); test-run logs `/tmp/harness-test-runs/*.log` since 2026-11-26T00Z;
hook log `~/.local/state/astragentic/harness-hook-events.log`.

| # | Defect | số đo | nguồn | Layer | Status |
|---|---|---|---|---|---|
| 30 | **Empty simplify restates the checker did not ask for.** `builder.md` § verify says "a marker that is not your head is a pass that did not cover the code"; the checker itself accepts a non-head marker inside the fold allowance and a clean base merge at the tip (5.0.9). | 67 `simplify(increment)` markers on 23 tickets; 42 empty; replaying `check-simplify-markers.sh` at the commit before each empty marker: **25 of 42 already passed** (17 content-follow, 4 clean main merge, 3 regen, 1 simplify). 17 were forced: 7 non-test lines after the marker, 6 conflicted main merges, 4 first "no findings" markers. Report's "22 restates, all forced by main moving" does not hold: 11 of 42 follow a main merge, 5 of those 11 merges were clean. | nizzy git log, merges 2026-11-26..27; replay in a `--no-hardlinks` clone at `/tmp/nizzy-upgrade-sim` with the 6.1.29 checker | upstream prose (`builder.md`) | to build: restate only on a checker STOP |
| 31 | **tdd-order first-commit refusal** (known: 4.5.2/4.5.3). New count only. | 17 refusals on 14 keys since 2026-11-26; time from first refusal to the next commit: 1 min on 10 keys, 2–7 min on 3, 33 on 1 (TRA-1682, next commit is a QA walk). The report's "one redo round" is about 1 minute. | hook log `REFUSED tdd-order`; nizzy `git log --all` | — | no change: the gate is cheap and right |
| 32 | **Masked test runs** (known: 4.5.3). New count only. | 554 of 1,496 logged runs (37%) masked since 2026-11-26; 247 end in `\| tail`, 32 `\| grep`, 9 `\| head`. The masked notice reaches the pane (18–82 occurrences per transcript in TRA-1683/1690/1695/1700/1701) and is not followed. 10 of the 14 refused keys had masked runs before the refusal. Re-run cost per masked run: `chưa đo`. | test-run logs; Builder transcripts `*worktrees-builder-TRA-16xx/*.jsonl` | upstream (`hook-test-run.py`) | measure re-run cost before any pre-call change; `\| head` cannot be treated like `\| tail` (SIGPIPE) |
| 33 | **hook-test-run matches the test pattern inside non-test commands** (commit messages, heredoc file writes, `herdr agent prompt` text). A status-1 line from such a command reads as a RED run. | 34 of the logged lines since 2026-11-26 start with `git commit`, `cat >`, `herdr`, `orca` or `gh`; 4 of them logged status `1`. | test-run logs | upstream (`hook-test-run.py`) | to build: drop heredoc bodies and quoted text before matching, as the guard does; plant a commit message containing `go test` |
| — | Report items 1, 2 and (d): steps vs commands, ~60% reads, re-read counts, a code-map brief slot. 30–40% saving estimate. | `chưa đo` (the report's own estimate is inferred, not measured) | — | — | measure per-path Read counts in the TRA-1668 transcript before designing |
