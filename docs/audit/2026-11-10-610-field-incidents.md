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

Fix staged (6.1.1): substituted handle refused with the literal recipe; `connected: false` is not
alive (the first cut keyed on `orphaned`, wrong per I-5). Planted in a new `orcadisp` driver mode
(5 cases: two real worktrees removed, connected-false reaped, orphaned-connected kept). The six stale
entries are inception's to delete.

## I-5 — nizzy's Codex Builders on Orca run but the owner cannot see them: `orphaned: true, connected: true`

Reported 2026-11-10 by nizzy Thomas (`.scratch/codex/resume-20261110/ORCA-ORPHANED-VISIBILITY.md`):
builder-TRA-1344 and builder-TRA-1345 receive dispatches and complete them, `terminal switch` says
`navigated: true`, nothing shows. Asked for a safe reattachment, no stop/relaunch/duplicate.

| số đo | nguồn |
|---|---|
| both terminals `orphaned: true, connected: true, writable: true`, `recordedPaneKey` set, `paneRuntimeId: -1`; PIDs 75489 (00:39) and 97052 (00:50) alive at 06:2x; `lastOutputAt` 06:13 | `orca terminal list/show --json`, `ps -p` |
| their `worktreeId` is the child worktree (`…/.claude/worktrees/builder-TRA-1344`); `worktree show path:<child>` returns a record (not archived); `worktree list` and `worktree ps` list 3 main checkouts only | orca CLI 1.4.255 |
| daemon log `session-attached`: Thomas pane 21, inception builder 1–2, a60ce46b 0, 64fd0ceb 0, qa 4217765b 0 | `~/Library/Application Support/orca/logs/daemon.log` |
| the creates: nizzy 3 of 3 (Codex, `--worktree active`, ran inside the worktree) orphaned; inception 36 of 36 (`active` from the base) attached | Codex rollouts, inception transcripts, terminal list |
| probe A: `terminal create --worktree path:<child>` → `surface: visible`, 0 attached; after `terminal switch` (`navigated: true`) → `orphaned: true`, `recordedPaneKey`; `worktree activate` → `activated: true`, still orphaned; after `close` → `orphaned: true, connected: false` | this repo, probe-orphan, 23:17–23:20Z |
| probe B: `terminal create --worktree path:<base> --command "cd <child> && …"` → `session-attached` +80 ms, `orphaned: false`, `paneRuntimeId: 1` | this repo, probe-orphan2, 23:24Z |
| `paneRuntimeId: -1`, `rendererGraphEpoch: 0` on probe A before any switch, while healthy | probe A |
| why `active` resolved to the child on nizzy (cwd of the Codex shell call): chưa đo, not in the rollout | rollout 01a1c15f |

Classification: a pane created in a workspace the sidebar does not list has no UI host; Orca keeps
the PTY and the CLI drives it. No CLI reattachment exists (switch, activate, create tested). The
staged I-4 reading of `orphaned` as closed would have deleted such a lane's record entry at
`git worktree remove`; fixed to `connected`. Recipe: name the base checkout's workspace, `cd` in the
command (ORCA.md § The pane, Codex draft). Advice to nizzy: keep driving by `read`/`send`/`wait`,
close with the literal handle when done, never relaunch for visibility. A sidebar toggle for hidden
discovered worktrees (Orca 1.4.250 release notes) is a lead for the owner: chưa đo.

## I-6 — QA gate bells lost again on inception, no outage: another root session consumed them

Reported 2026-11-10 by inception Thomas (`workspace-app-inception-97`): `qa:batch1110b-walk` and
`-verify` finished, `woken_at` set, no prompt reached the idle dispatcher from 06:47 to 08:00.

| số đo | nguồn |
|---|---|
| wake prompts "by the record, a gate pane's path" for batch1110b: 3, all in session `b8277907` (first user turn 2026-10-30T13:04Z, cwd inception root = `workspace-app-inception-c9`, still listed alive); 0 in `1e9ff244` (the briefing Thomas) | inception transcripts |
| times: 23:52:17Z (walk), 23:55:47Z, 00:12:17Z (verify, the "routine third tick" turn end) | `b8277907` transcript, record `turn_end_pending` |
| record-path bells per receiving session since 10-30: inception 7 sessions (`b8277907` 10 across 11 days), nizzy 3 sessions | both transcripts dirs |
| QA entries carry no `dispatcher` (briefed by file, no mod message) | inception record |
| mod rule since 2026-10-23: skip an entry whose `dispatcher` socket is another live session; unowned entries ring in any root session | register.tsx `wakeFromRecord` |

Fix staged (6.1.1): the dispatcher claims the key at `orca terminal create … ASTRA_DISPATCH=…`
(`dispatcher`, `claimed_at`, `role`), before the shell runs. Planted in `orcadisp` (qa and ticket).
Herdr launches: chưa đo, not claimed. Advice to inception: close the 10-day root session; until the
release, polling the gate file is right.

## I-7 — nizzy's two Codex Builders stop at review: "no callable spawn_agent", twice, after the one steer

Reported 2026-11-10 by nizzy Thomas (Codex coordinator `01a1c352`, run `run_362765c066b0`,
`ASTRAGENTIC-BLOCKERS.md` § A). TRA-1353 (`7ba3f3d`) and TRA-1355 (`baf67ce`) built, tested and
committed locally, then both reported no `spawn_agent`/`wait_agent` declaration, the steer from
thomas.md was sent once per worker, both repeated the report, both handed back `failed`.

| số đo | nguồn |
|---|---|
| tool namespaces declared at startup, both rollouts, line 3 `additional_tools`: `functions`, `clock`, `collaboration`, `mcp__cua_repl`; `collaboration` carries `spawn_agent`, `wait_agent`, `followup_task`, `interrupt_agent`, `list_agents` | `~/.codex/sessions/2026/11/10/rollout-…01a1c35a-00b0…` and `…01a1c35a-01bb…` |
| direct `function_call` items in both rollouts: 0; every tool use is `custom_tool_call` `exec` (71 in TRA-1355) | same |
| TRA-1353's search: `ALL_TOOLS.filter(/spawn_agent\|wait_agent\|review.agent/)` inside `exec` returned `[]` (line 277) | TRA-1353 rollout |
| sessions that called `spawn_agent` as a direct `function_call`: 3 of 3 succeeded (`/root/correctness` …), 11-09 Orca probe `01a1bfd3-759b` (3 spawns, 3 waits) and rehearsal `01a1c058`, `01a1c05b`; 0 sessions ever called it through `exec` | 11-09 rollouts |
| the Builder's own tool list in its stop note: `functions` (exec, wait, request_user_input…), `clock`, `mcp__cua_repl`; `collaboration` omitted | `native-review-retry.md`, `report.md` |
| how the steer arrived: as `exec` output of `orca orchestration check` (TRA-1353 line 747), after a user turn that said only "You have 1 orchestration message"; 11-09's 2 of 2 successes were Herdr `agent prompt`, a user turn | both rollouts, RELEASE-NOTES 6.1.0 |
| `multi_agent` stable true, `multi_agent_v2` false on this box; openai/codex #26753 concerns v2 only | `codex features list` |
| whether `collaboration` was still in the two workers' tool list at the stop turn | chưa đo by any runtime record: a rollout records tools once. The names-only probe (nizzy's hand, 1 follow-up per idle worker) returned the same list from both: `functions` (wait, request_user_input, request_user_input_async, exec), `clock.sleep`, `mcp__cua_repl`, 13 `tools.*` nested under exec, 20 deferred `mcp__*` namespaces, and no `collaboration`. Self-report, consistent across two sessions; TRA-1353 had compacted once (line 692), TRA-1355 had not (236k of 258k window) | both rollouts after the probe turn (TRA-1353 line 767, TRA-1355 line 650), `TOOL-INVENTORY-RESULTS.md` |
| sessions carrying Orca's "You are a dispatched worker" prompt that ever spawned a helper: 0 of 3 (M7' 11-09, TRA-1353, TRA-1355); sessions without it: 3 of 3 (probe `01a1bfd3`, rehearsal `01a1c058`, `01a1c05b`), all `collaboration` declared at line 3 | the six rollouts |
| upstream: no issue describes the namespace vanishing mid-session; openai/codex #34919 and #41590 are about `exec --json` omitting spawn events; magpie #130 is a gateway dropping the namespace (not this box, provider openai direct) | GitHub search 2026-11-10 |

Read: `ALL_TOOLS` is the `exec` tool's own catalog of code-mode tools; the `collaboration` tools are
direct tools beside `exec` and never appear in it, so the Builders searched the wrong catalog and
read the empty result as absence. The steer wording "call it directly, not through exec or ALL_TOOLS"
worked only as a user turn. Staged (6.1.2): common.md and builder.md name the namespace and say the
search is void; thomas.md's steer gives the call's shape, the "2 of 2" claim is replaced by the counts
(2 of 2 Herdr, 0 of 2 Orca), and a second stop sends the namespace probe and reports failed with the
list attached instead of a second steer. Text only; the Builder's read of its own tool list is not
ours to change, and the probe decides between runtime drop and Builder defect.

## I-8 — a Codex Builder's truthful simplify marker is refused by the shipped checker

Same report, § B. `scripts/check-simplify-markers.sh` (nizzy's copy identical to harness) required
the literal `Pass: Skill(skill: "simplify")`; the Codex pass runs `astra-codex-simplify`, and the
skill text named no `Pass:` line at all.

| số đo | nguồn |
|---|---|
| refusal: `STOP: (this marker): missing Pass: Skill(skill: "simplify") (AST-099)` on `simplify(increment): …` at the commit-msg hook | `builder-TRA-1355/.scratch/codex/tra-1355-20261110/marker-refusal.log` |
| `marker-kinds.json` merges `required` by union (checker lines 292–297), so no project file could drop the Claude string | checker source |
| Codex-form marker on the 6.1.1 checker: NOT GREEN; on the staged checker: GREEN; Claude form and its degraded " — reason" form: GREEN; `Pass: ran the four corners by hand`: NOT GREEN naming both forms; no `Pass:`: `missing 'Pass:'` | `/tmp/cm-probe`, selftest block "6.1.2 — the Codex lane's provenance line" |

Staged (6.1.2): `simplify(increment)` keeps `Pass:` as a token field with two allowed starts,
`Skill(skill: "simplify")` and `$astra-codex-simplify`; `astra-codex-simplify/SKILL.md` writes the
line. The field stays self-reported in both lanes, as it was.

## Owed items measured 2026-11-10

| số đo | nguồn |
|---|---|
| grace live: probe mod, Orca pane, Haiku; timer armed in `turn.complete` fired at +5,015 ms, `$.fs.write` ok, `$.ui.status` ok | `/tmp/probe-grace-1-t{0,1}.json`, pane status line |
| Codex coordinator Stop hook on the dead-turn race | chưa đo |
