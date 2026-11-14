# Field incidents after 6.1.12 (batch for 6.1.13)

Source: nizzy Thomas, cross-session messages 2026-11-14 and
`etsy-fulfillment-thanh/.scratch/harness-issues/report-to-astragentic-2026-11-14-orders-ux-session.md`
(harness 6.1.11, Orca host, one Thomas session `99caf986`). Each row was a lead; the second column is what
was measured upstream from the project's transcripts, git log and a read-only run in its checkout.

| id | lead (nizzy) | số đo | nguồn | layer and outcome |
|---|---|---|---|---|
| L-1 | a base-form `orca terminal create` read `orphaned: true` in 1 of 2 panes | chưa đo; nizzy logs `orphaned`/`connected` over its next 10 creates | — | open |
| L-2 | the ticket-done note fires on a local merge before the gate; it refused a brief while a gate was red | 65 notes on prompts, 2 briefs not sent, `git reset --keep origin/main` twice (2026-11-13 16:44Z, 11-14 00:52Z) | session `99caf986`: user records carrying "no ticket-done evidence", Bash calls | upstream, mod. `thomas.md` § Merge says commit the merge, then gate; the mod counted the local base. **Fixed** |
| L-3 | the Builder cap counted a handed-back Builder and deadlocked once with L-2 | 1 occurrence, by the report; the cap rule is by design | report item 3 | no change: the deadlock needed L-2's refusal |
| L-4 | review sub-agents die and the Builder parks 20 min | 4 held-stale bells in one day (TRA-1423 01:41Z, TRA-1440 12:05Z and 12:36Z, TRA-1453 21:21Z). Every agent the bell lists as `[running]` had ended `end_turn` 19 to 20 min earlier; for 3 of the 4 bells they were children (`spawnDepth: 1`, `requestShape: background`) of a review sub-agent that ended before them (1440: parent 11:41:17Z, children 11:42 to 11:46Z) | Builder transcripts `*builder-TRA-{1423,1440,1453}*/**/agent-*.jsonl` and `.meta.json`; bell text in `99caf986` | runtime first (Claude Code 2.1.323: `$.agent.list()` reads a finished child of an ended sub-agent as running); the mod trusts it. **Open**: what a list entry carries for such an agent is chưa đo, so no rule is written |
| L-5 | gate failures from box load beside a QA stack; `box-pressure-check` runs once at start | `box-pressure-check`: 0 files in the payload | `git grep box-pressure -- harness` | project: its own gate script and stack. Returned to nizzy |
| L-6 | a Builder committed evidence PNGs with buyer names from a prod-seeded dashboard | 13 image blobs added under `.scratch/evidence` since 2026-11-01; 0 lines in the payload govern evidence images | nizzy `git log --diff-filter=A -- '*.png' '*.jpg'`; `git grep` over roles, skills, scripts | project: its data and its evidence plug. Returned to nizzy |
| L-7 | "masked run" notice on `cmd > file; echo rc=$?` at every gate rerun | 17 notices in the session | `99caf986`, records carrying "logged as `masked`" | upstream, recorder. **Fixed** |
| L-8 | `check-reachability.py` prints 16 `[FAIL 10]` in the adapted project | nizzy at 6.1.12: exit 1, 16 findings (`prompts/ADAPT-HARNESS.md` 6, `thomas.md` 4, `builder.md` 2, four others 1 each); upstream repo exit 0. The walk for known file names started at the project's parent, which could not be listed | read-only run in nizzy's checkout; `os.listdir("..")` there: Operation not permitted | upstream, checker. **Fixed** |
| K-2 | `claude plugin validate` 2.1.323: 45 type warnings; `BoardRow` lacks `'dead'` | 45 warnings, exit 0 | validator run at 6.1.12 | upstream, mod types. `'dead'` added: 43 warnings. The other 43 and whether the band should alarm on a dead lane stay open |

## Fixes and their proof

**L-2, dispatch mod.** A merged Builder ticket with no ticket-done stamp is owed once its work is on
`origin/<base>`; a checkout with no such ref keeps the local base. The merge's own result still names the
ticket and says to gate first. The push guard is unchanged.

| proof | 6.1.12 mod | this mod |
|---|---|---|
| driver case `owedWhen` (default mode): local merge, unstamped — note on the prompt / brief refused | true / true | false / false |
| the merge's own result names the ticket and says "Gate the merge first" | false | true |
| after the work is on origin: note / brief refused | true / true | true / true |

**L-7, `hook-test-run.py`.** When the first command after the test is `echo <label>=$?` and stdout carries
`<label>=<n>`, the run is logged with `<n>` and no notice is printed. With no code on stdout it stays `masked`.

| proof | 6.1.12 | this |
|---|---|---|
| `go test ./... > log 2>&1; echo rc=$?; grep -n FAIL log`, stdout `rc=1` | logged `masked`, notice | logged `1`, no notice |
| the same with no stdout | `masked` | `masked` |

**L-8, `check-reachability.py`.** In project layout the known file names come from the project and from
`.astraler/releases/<applied>/`, never from the folder above.

| proof | 6.1.12 checker | this checker |
|---|---|---|
| hand-built project fixture, parent folder mode 111 | exit 1, 15 `[FAIL 10]` | exit 0 |
| the same, parent listable | exit 0 | exit 0 |
| nizzy checkout, read-only | exit 1, 16 findings | exit 0 |
| a binding to a file that exists nowhere (planted in `selftest.sh`) | — | exit 1, 1 `[FAIL 10]` naming it |

Not covered: Codex has no mod and no recorder hook, so L-2 and L-7 are Claude lane only; L-8 covers both
(one checker). Live: none of the three ran in a live downstream session before the tag.

Owed from 6.1.12: the refusal text from a live Orca session (nizzy, after its Thomas restarts).
