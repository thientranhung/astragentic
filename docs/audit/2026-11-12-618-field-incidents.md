# 6.1.8 field incidents (batched, one release on the owner's go)

Each row carries `số đo | nguồn`. Rows without a number go to a count first, not into a plan.

## I-1 — an Orca restart restores a Builder pane without `ASTRA_DISPATCH`; the pane runs as a root session

Reported 2026-11-12 by nizzy Thomas (etsy-fulfillment-thanh, Orca, 6.1.8):
`.scratch/harness-issues/report-to-astragentic-2026-11-12-orca-restart-lost-turn-ends.md`.
The report's suspected cause (the `dispatcher` stamp names the dead session) is not the cause: the
dead-socket rule in `wakeFromRecord` already lets any root session ring. The pane never wrote a turn end.

| số đo | nguồn |
|---|---|
| Builders restored by Orca as `claude --dangerously-skip-permissions --effort medium --resume <id>` at 07:35:56 +07: 2 of 2 (pid 18005 TRA-1406, pid 18014 TRA-1405) | `ps -axo pid,lstart,command`, 2026-11-12 09:23 +07 |
| `ASTRA_DISPATCH` in those processes' environment: 0 of 2; `ORCA_PANE_KEY` and `ORCA_TAB_ID` equal to the record's `pane_id`/`tab_id`: 2 of 2; `--resume` id equal to the record's `session_id`: 2 of 2 | `ps eww -p 18005,18014`; nizzy `.astraler/state/dispatch-record.json` |
| terminal handle at dispatch (`term_e576e8ad…`, `term_7edcb99c…`) against the live processes' `ORCA_TERMINAL_HANDLE` (`term_50fa18c4…`, `term_27d953ac…`): 2 of 2 differ | the report for the old handles (not re-measured: the record was repaired by hand); `ps eww` for the new |
| `last_turn_end_at` on the record for 2 handbacks (07:49, 08:27 +07): 0 of 2; `[astragentic-dispatch]` turns in either Builder transcript after the resume: 0 | record; transcripts `19069e47…`, `834cb46b…` |
| commits after the resume made with no pane gate loaded: 5 (TRA-1405: 1, TRA-1406: 4); how many a gate would have refused: chưa đo (both entries carry `first_content_commit_at` and `red_run_at` from before the restart) | same transcripts, `git commit` Bash calls after 00:35:57Z |
| Skill calls after the resume missing from `skills_log`: 3 of 3 (TRA-1406: astra-review, code-review, simplify) | transcript against the record |
| bells the resumed Builders took as root sessions: 0 | same transcripts |
| handbacks found by reading panes: ~70 min after the first | the report |
| `orca terminal create --help` (1.4.256): no option that persists environment across a restore | CLI help |
| released mod in the driver, pane key + session id + no `ASTRA_DISPATCH`: pane gate `pass:ran`, no turn end on the record | `mod-drive.cjs orcaresume` against `HEAD:register.tsx` |
| patched mod, same driver: gate `deny:held`, terminal `term_old` → `term_5`, turn end on the record; another session id and no entry stay root; planted pane-key-only match gives the other session the role | selftest `orca resume (6.1.9)` |
| dispatcher side, driver: a root session whose socket differs from the entry's dead `dispatcher` socket rings the pending turn end 1 time, sets `woken_at`, keeps the entry; planted poll that skips every foreign owner: 0 bells | selftest `orca dispatcher`, `restartBell` |
| stablyai/orca issues on restore dropping launch environment: 1 related, open (#24752, cold restore runs `claude --resume <id>` without the session's `CLAUDE_CONFIG_DIR`, Windows/WSL, 1.4.209); none for an inline `VAR=… claude` in `--command` | `gh issue list --repo stablyai/orca --search "resume in:title"`, 2026-11-12 |
| live fixture pane in Orca (2.1.322): launched with `ASTRA_DISPATCH=ticket:FX-1`, exit, bare `claude --resume <id>`: `ASTRA_DISPATCH` in env 0, staled `terminal` rewritten to the live handle, `turn_end_pending` written with the restart reason: 1 of 1 | `/private/tmp/ast619-live`, 2026-11-12 |

Layer: upstream harness (`whoAmI` trusted the launch environment only). Orca rebuilding the command at
restore is the runtime's behaviour (#24752 is the same family); the harness no longer depends on it.

Fix (6.1.9): on Orca, with no `ASTRA_DISPATCH`, the mod takes role and key from the record entry whose
`pane_id` equals `ORCA_PANE_KEY` and whose `session_id` equals the session's id. `session.start` then
rewrites `terminal` as it always did. The turn end goes by the record (the old dispatcher address died
with the old process) and the restarted dispatcher's poll rings it.

Not covered, chưa đo:
- an actual Orca restart with the patched mod (the fixture resumed in the same terminal; nizzy had live lanes);
- a Codex pane after an Orca restart (`runtimes/codex` does not read `ASTRA_DISPATCH`);
- a Herdr restart (identity is the tab label, read from Herdr at session start);
- the dispatcher re-stamping `dispatcher` on its entries after its own restart; today the dead-socket rule
  lets any root session of the project ring.

By hand downstream: none after the upgrade.
