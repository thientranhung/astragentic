# 6.1.0 field incidents (batched, one release on the owner's go)

Each row carries `số đo | nguồn`. Rows without a number go to a count first, not into a plan.

## I-1 — old retired Builder worktree collides with installed release payload on merge of upgraded main

Reported 2026-11-10 by Nizzy Thomas (etsy-fulfillment-thanh), coordinator thread
`01a1c15f-811d-7b40-91b9-3f9476216b4e`. Report only; no fix requested in the project.

| số đo | nguồn |
|---|---|
| worktree TRA-1344 at `a77a5a119`; base merged `4a61506` | `.scratch/codex/resume-20261110/HARNESS-RESUME-COLLISION.md` |
| 17 tracked harness copies matching `90e72a845`, reconciled first | same report |
| 44 untracked 6.0.3 payload files; `git merge --no-edit` exit 2 "untracked files would be overwritten" | `merge-main-1344.log` |
| 44/44 collisions byte-identical to main | `untracked-harness-collisions.json` |
| 27 product files SHA256 unchanged after merge; doctor files-intact 44/44 | `merge-main-1344-reconciled.log`, `preparation.json` |

Classification: runbook gap for old worktrees that carry an installed, untracked release payload.
Not an installer bug. The 5.0.5 doctor already skips `.claude/worktrees/` (RELEASE-NOTES 833–841),
so nothing in the harness touches a retired worktree today.

Candidate (unmeasured, stays out of the plan until counted): a documented step in the update
runbook — inventory untracked collisions, compare bytes to main, move identical ones aside,
then merge. Count needed first: how many retired worktrees on nizzy and inception carry an
untracked payload (`git -C <wt> status --porcelain | grep '^??' | grep -c '.astraler\|.claude\|.codex'`).

## I-2 — "Builder panes park on idle sub-agents" (inception IN-333, IN-334 on Orca): measured as a false parked bell, not a park

Reported 2026-11-10 by inception Thomas (`workspace-app-inception-97`): two Builder turn ends said
"waiting on an agent" with `Agents: 0 running, 6 idle — an idle teammate does not wake this pane`,
"both needed a Thomas steer". Measured against the Builder transcripts
(`~/.claude/projects/…workspace-app-inception--claude-worktrees-builder-IN-33{3,4}/*.jsonl`) and the
dispatcher transcripts of both projects (script `/tmp/astra-i2/bells3.py`).

| số đo | nguồn |
|---|---|
| IN-333: Stop 18:50:43.648Z, awaited `simplify-efficiency` result delivered 18:50:43.654Z (+6 ms, already queued), Builder's own first action +3.7 s, Thomas steer +15.3 s | IN-333 transcript ms ordering |
| IN-334: Stop 19:11:04Z, awaited `simplify-altitude` result +0.006 s, first own action +18.2 s (model latency), steer +20.2 s | IN-334 transcript |
| working named teammates read `running` in ListAgents (simplify-efficiency `running` at 18:50:21/25/30/35/41) → the mod's hold does engage; the bell fires in the gap after the last one finishes | IN-333 ListAgents results |
| bells carrying the idle line, both projects since 5.1.2: 81; with the pane's words saying wait: 23; matched to a stop: 20 | bells3.py |
| 20/20 matched bells: the awaited thing woke the pane itself before any steer (teammate message 11×, +0.004–0.03 s; task-notification 9×, +3–124 s: those were backgrounded Bash/Monitor jobs, IN-282/283/298, pre-6.1.0 Herdr) | bells3.py |
| steers after such a bell: 7, all landed after the pane had resumed (+6.4 s … +29.8 s); steers before the pane's own first action: 0 | bells3.py |
| not Orca-specific: same shape on IN-259/269/276/282–313 (Herdr, 2026-11-03…08) | bells3.py |
| lens results delivered: yes; the compaction 0.5 s after IN-333's efficiency findings kept them (summary at 19:10:22 names invertHashIndex, altURLs) and commit 5f07dd1c triaged both with reasons | IN-333 transcript, `git show 5f07dd1c` |
| real parks (pane never woke on its own) since 5.1.2: 0 (TRA-1321, 374 min, was before) | bells3.py |

Classification: the 5.1.2 line is true (an idle teammate never wakes its parent) and misleading
where it is shown: on every bell after a fan-out (81), including the one that fires in the ms
between the last agent finishing and its queued result starting the next turn. The dispatcher
reads "0 running + waiting" as parked and steers a pane that is already working.

Candidate fix at the mod's fact (for the batch, with a planted selftest): in `turn.complete`,
when 0 agents run but the pane has idle agents and reason=answer, hold the TURN-END for a short
grace (5 s covers 11/11 teammate wakes at ≤30 ms; a real park is delayed 5 s of its hours) and
drop it if the main loop's `turn.start` fires inside the grace — the queued result was the wake.
Text when it does go out: "no message woke this pane within 5 s of the turn end". Plant: idle
roster + turn.start inside the grace → no send; idle roster + nothing → one send after the grace.
thomas.md § Steer keeps "0 running + waiting = parked" only for a bell that survived the grace.

Staged on main 2026-11-10 (not tagged; VERSION 6.1.0 until the owner's go): mod grace + 4 planted
selftest cases (fail on the 6.1.0 mod: `parkedHeld:false, parkedWakeDropped:false`) + thomas.md and
builder-claude.md lines + RELEASE-NOTES 6.1.1.

| số đo | nguồn |
|---|---|
| 0-running bells with `ended` and no `idle`: 151 inception, 55 nizzy; with wait-words 12, all backgrounded Bash/Monitor jobs (IN-308/320/327, TRA-1340), 0 awaited forks → grace arms on idle only | dispatcher transcripts |
| grace live in the engine (`$` and `setTimeout` after the hook returned): chưa đo — one fixture pane, one fan-out, bell ≈5 s after Stop; one teammate result inside the grace, no bell | owed before tag |
| Codex coordinator Stop hook, same race: chưa đo | owed |

## I-3 — QA gate-pane turn ends on Orca (C5) "never reached" the dispatcher: the bells arrived and were eaten by dead turns

Reported 2026-11-10 by inception Thomas. Measured in its own transcript.

| số đo | nguồn |
|---|---|
| `qa:slice1110-walk` bell prompt at 21:09:15Z, next assistant turn 21:09:16Z = "Your organization has disabled Claude subscription access…" (API error); `-verify` at 21:16:15Z, same at 21:16:16Z | inception Thomas transcript |
| record `turn_end_pending.woken_at` 1794258555881 / 1794258975963 = the same seconds → the record path worked; the prompt's turn died | `.astraler/state/dispatch-record.json` (inception) |
| bell prompts answered by an API-error turn: inception 12/937, nizzy 12/1307; 2 QA record-path bells, 1 "4 turn ends arrived while you were busy" bundle | both dispatcher transcripts, script in session |

Fix staged (6.1.1): the mod remembers the bell it submitted, matches the turn that starts, re-holds the
bell when that turn ends on error/refusal, and never flushes into a dead turn. Planted in the
default driver mode (3 cases). Open: a re-held bell needs some clean turn end to ring; chưa đo how
often nothing else wakes the dispatcher after an outage.

## I-4 — record entries outlive their worktrees on Orca (IN-333…IN-339)

| số đo | nguồn |
|---|---|
| 6 Builder entries with `worktree_removed_at` set, `tab_closed_at` null, worktree gone | inception record |
| `orca terminal close --terminal $(python3 …)` 7 of 8 closes → the mod's close regex needs a literal `term_…`; no entry matched, no `tab_closed_at`, no mid-turn guard | inception Thomas transcript |
| mid-turn at those closes: 0 of 7 (`last_turn_end_at` > `last_message_received_at` on all six) | inception record |
| `orca terminal show --terminal <closed>` → exit 0, `orphaned: true, connected: false`; live → `orphaned: false, connected: true` | CLI probe 2026-11-10 |
| → at `git worktree remove`, `isTabAlive` read non-null as alive, kept the entry | register.tsx 6.1.0 |

Fix staged (6.1.1): substituted handle refused with the literal recipe; `orphaned: true` is not
alive. Planted in a new `orcadisp` driver mode (3 cases); the `orphaned` branch rests on the CLI probe
(the driver has no real worktree). The six stale entries are inception's to delete.
