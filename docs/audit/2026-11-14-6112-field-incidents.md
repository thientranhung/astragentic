# Field incidents after 6.1.12 (batch for the next release)

Source: nizzy Thomas, cross-session message 2026-11-14 and
`etsy-fulfillment-thanh/.scratch/harness-issues/report-to-astragentic-2026-11-14-orders-ux-session.md`
(harness 6.1.11, Orca host, one session). Every row below is the project's own number: a lead, not yet
reproduced upstream. Nothing here is planned until its `chưa đo` is replaced.

| id | lead (nizzy's number) | upstream measurement | layer |
|---|---|---|---|
| L-1 | a base-form `orca terminal create` (`path:<base>` + `cd` in `--command`) read `orphaned: true` in 1 of 2 panes, minutes apart; suspected: the base workspace was not the one open in the Orca window | chưa đo; asked nizzy for `orphaned`/`connected` over its next 10 creates | chưa đo (harness recipe or Orca) |
| L-2 | the ticket-done nag fires on a local merge before the gate and the push: about 25 repeats, and it blocked the next brief while a gate was red (`git reset --keep origin/main` to get out) | chưa đo | upstream (mod) |
| L-3 | the Builder cap counts a handed-back, unretired Builder; deadlocked once together with L-2 | chưa đo | upstream |
| L-4 | review sub-agents die and the Builder parks 20 min (TRA-1440, TRA-1453); `held-stale` is the only signal | chưa đo | upstream (mod) or runtime |
| L-5 | gate failures from box load: DB-connect timeouts and swap when a QA stack starts beside a gate run; `box-pressure-check` runs once at start | chưa đo | upstream gate or project stack |
| L-6 | a Builder committed evidence PNGs showing buyer names and cities from a prod-seeded dashboard; caught by its own review, by no gate | chưa đo | upstream guard or project data |
| L-7 | PostToolUse "masked run" notice on `cmd > file; echo rc=$?` at every gate rerun | chưa đo | upstream (recorder) |
| K-2 | carried from the 6.1.11 batch: 45 type warnings from `claude plugin validate` 2.1.323; `BoardRow` lacks `'dead'` | measured there | upstream (mod) |

Owed from 6.1.12: the refusal in a live Orca session (asked nizzy to report the refusal text after it upgrades).
