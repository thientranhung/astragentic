# Astragentic on Orca: design proposal (draft for the owner, nothing implemented)

Rule: Astragentic owns WHAT is true and required; the host owns HOW agents run and talk. Today the two are mixed: Herdr
appears in 34 files, 319 lines (grep over harness + runtimes/codex, excluding selftest). Orca 1.4.254, Codex 0.167.

## 1. Who owns what

| Concern | Today | On Orca | Number | Source |
|---|---|---|---|---|
| Roles, gates, skills, tracker, ledger | Astragentic | Astragentic, unchanged | - | - |
| Start worktree + agent + brief | DISPATCH.md, dispatch-ticket | `orchestration worker-start --spec-file --model --effort` | DISPATCH.md 574 lines | wc |
| Worker finished | turn-end.sh bell (6.0.5) | `worker_done` with task and dispatch id | 0 polls, woken 19 s after worker file, n=1 | ORCA-PROBE |
| Thomas watching panes | `agent get/wait` | Removed | 157 of 518 calls on nizzy | coordinator rollout |
| Watchdog | herdr-watchdog.sh + herdr-watch-terminal.sh | Heartbeat + escalation + dashboard | 929 lines could go | wc; behaviour chua do |
| Worker question | queue + ACK table | `orchestration ask` | chua do | Orca guide |
| Thomas ends with work unfinished | Stop hook (6.0.8) | STAYS: Orca wakes only on new mail | 2 stalls, 1 h 50 min and 3 h 46 min | STALL docs |
| Merge gate, markers, tdd gate | Claude mod, scripts | STAYS | register.tsx 2,633 lines, 20 herdr lines | wc, grep |
| Review inside Builder | helpers (6.0.9) | Same | 3/3 ran, effort followed parent | ORCA-PROBE |
| Worktree deps and .env | project setup scripts | `orca.yaml`, `.worktreeinclude` | chua do | Orca docs |
| Status for the owner | Herdr tab labels | `worktree set --comment --workspace-status`, dashboard | chua do | Orca docs |

The ticket stays in the tracker. An Orca Task is one dispatch attempt, never a second backlog.

## 2. The seam

Owner ruling: DISPATCH.md stays the one authority; the host is chosen by environment variable, not by splitting the file.

DISPATCH.md opens with one host check, and only the sections that truly differ branch on it:

```sh
if [ -n "${ORCA_PANE_KEY:-}" ]; then HOST=orca      # checked first: an Orca opened from a Herdr pane may inherit HERDR_*
elif [ "${HERDR_ENV:-}" = "1" ]; then HOST=herdr
else echo "no host: stop and report"; fi
```

Owner ruling 2026-11-09: **a session started in one host follows that host's dispatch only.** On Orca, zero `herdr`
calls, even though the `herdr` CLI answers from an Orca pane (measured: 8 workspaces listed). Measured 2026-11-09: 6.0.9's
DISPATCH.md names Herdr in 33 lines and Orca in 0, so a Thomas opened in Orca today would create its Builders in Herdr.
Until 6.1.0 ships, a Codex Thomas runs in Herdr. In 6.1.0 the host check is a hard stop, not a hint: `HOST=orca` with no
Orca branch, or an Orca pane that is about to run `herdr …`, stops and reports; the Claude mod denies `herdr` commands
when `ORCA_PANE_KEY` is set, and `orca` commands when `HERDR_ENV=1` (a `tool.call` rule beside the existing close guard).

Host-neutral text (identity, write-set, brief, handback contents, close-out) has no branch. Branching sections: launch,
observe, worker reply, owner alert, release. The Herdr text stays as it is. The same variables serve the Claude mod later:
it already reads `HERDR_TAB_ID` and `HERDR_PANE_ID`.
Limits: the check is prose an agent follows, so `launch.py` also prints the host it resolved; workers started by Orca do not
pass through `launch.py` and read it themselves. Reading both branches costs tokens in every session, chua do.
Measured: this Orca pane has `ORCA_PANE_KEY` set and 0 `HERDR_*`; inherited `HERDR_*` inside Orca chua do.

## 3. Order

1. **Host-neutral fixes, 6.0.9:** Builder commits per phase, QA on a SHA, whole-ticket briefs, no ACK table, helper
   effort. Valid on both hosts. Baseline: 83 sends, 0 commits, 47 and 58 dirty files, 0 merges for 2 tickets in 16 h.
2. **Codex on Orca, 6.1.0:** the host check and the Orca branches in DISPATCH.md. Herdr text unchanged.
3. **Claude on Orca, also 6.1.0 (owner, 2026-11-09):** section 7. The mod still gates; it reads the host from the environment.
   Herdr stays the default until C1 to C6 pass; Claude has no measured stall on Herdr at 10 to 29 merges a day.
4. **Retire Herdr** only after 3, by owner decision.

## 4. Conflicts to settle on Orca

| Orca default | Astragentic rule | Proposal |
|---|---|---|
| Yolo: 6/6 probe sessions `never` + `danger-full-access` | Yolo only by owner choice | Owner picks; Auto proposed, then measure |
| Auto-trust folder wrote 2 entries to ~/.codex/config.toml | Trust is owner-controlled | Owner decision; leave on for workers, hook trust still manual |
| Per-tab Codex server | `codex queue` between sessions | No queue on Orca; keep default |
| Hibernation resumes idle sessions after 30 min | No auto-resume of an owner pause | Docs: not while a dispatch is unsettled; Thomas chua do |
| Orca Stop hook in ~/.codex/hooks.json beside ours | Our Stop must be able to block | M2 |
| Project hooks ignored in linked worktrees (#27133) | Stop hook is Thomas-only | Coordinator checkout only |

## 5. Measurements before 6.1.0 ships (each chua do)

| Id | Question | Pass |
|---|---|---|
| M1 | Wake under Auto permissions | woken, 0 polls, no approval stall |
| M2 | Our Stop hook blocks with Orca's Stop hook present, and Codex really creates the continuation | one continuation; also closes the 6.0.8 gap |
| M3 | Wake when Thomas is mid-turn, and when the owner is typing | mail not lost, text not interleaved |
| M4 | Worker stops without `worker_done` | Thomas gets an escalation |
| M5 | Orca restart with a live dispatch | Run and mail survive |
| M6 | Overlay doctor and helper discovery in an Orca-created worktree | files intact, helpers listed |
| M7 | One real ticket end to end | sends per ticket and hours to merge against the baseline |

M1 to M6 use child worktrees under astragentic (`worktree create --parent-worktree active`), not `repo add`.
M7 needs a project's go; on nizzy that is the owner's call.

## 6. Owner decisions

1. Permission level on Orca.
2. Whether Codex on Orca becomes the default for new Codex projects after M7.
3. Claude section 7: the choice in 7.3.

## 7. Claude on Orca (6.1.0, draft)

Status: design only, no code changed, nothing below run except where a source says so.

### 7.1 Detecting the host

| Variable | Set in this Orca pane | Use | Source |
|---|---|---|---|
| `ORCA_PANE_KEY` | yes, `<tab>:<leaf>` | host check, pane id | env, this pane, n=1 |
| `ORCA_TAB_ID` | yes | tab id in the record | env, this pane |
| `ORCA_TERMINAL_HANDLE` | yes, `term_...` | target for `orca terminal show/close` | env, this pane |
| `ORCA_WORKTREE_ID` | yes | where the pane lives | env, this pane |
| `ORCA_CLI_BIN_DIR` | yes | the CLI path, as `HERDR_BIN_PATH` is today | env, this pane |
| `HERDR_ENV`, `HERDR_TAB_ID`, `HERDR_PANE_ID`, `HERDR_BIN_PATH` | all unset | Herdr branch | printenv, this pane |

The Orca check comes first, as in section 2; `HERDR_*` inherited inside Orca is chua do.

### 7.2 What the mod does per host

The mod gets one small adapter. All gates, the record, bells and the board above it stay the same.

| Mod need | Herdr | Orca | Risk | Source |
|---|---|---|---|---|
| Which host | `HERDR_TAB_ID` + `HERDR_PANE_ID` | `ORCA_PANE_KEY` | - | register.tsx:779-781 |
| Which role and ticket | tab label `ticket:KEY` | launch env `ASTRA_DISPATCH=ticket:KEY`, not the title | Orca titles change: `.` became `Owner-authorized disposable...` and gained spinner glyphs; AST-084 hit the same trap | terminal list this session; register.tsx:782-787 |
| Is the tab alive | `herdr tab get` | `orca terminal show --terminal` | exit code on a closed handle chua do | register.tsx:2272 |
| Alert the owner, pane died | `herdr notification show` | no notification command found in `orca --help`; fallback chua do | gap | register.tsx:1566 |
| Refuse closing a mid-turn pane | regex on `herdr tab/pane/workspace close` | add `orca terminal close` | handles differ from record ids, so record the handle | register.tsx:2185-2192 |
| Launch argv guard | `herdr agent start --kind` | not needed for `--command` | - | register.tsx:2175 |
| Message becomes a turn; TURN-END | SendMessage + `command.run` | Same if SendMessage works across Orca panes | C2 | register.tsx:15-22 |

Today's behaviour in Orca, read from code, not run: `whoAmI` returns null, so a Builder there has no record entry, no TURN-END
and runs as if it were a dispatcher. **Until 6.1.0, do not dispatch Claude Builders into Orca panes.**

### 7.3 The one design choice: Orca's mail or the mod's bell

| | A: Orca is only the pane host (recommended) | B: Orca Runs (`worker-start`, `worker_done`) as on Codex |
|---|---|---|
| Wake | Mod TURN-END, under 1 s measured on Herdr | About 19 s, n=1, Codex |
| Record, gates, band | Unchanged | Two sources of truth, or a rewrite of the bell half of 2,633 lines |
| Worker start | `orca terminal create --command` or `agent launch` | `worker-start --agent claude`; its Task/Dispatch preamble meets the mod's brief path, chua do |
| Watchdog | herdr-watchdog.sh has no Orca path: off at first, port its read layer to `orca terminal list` only if C6 shows a need | Heartbeat + escalation replace it, chua do |

A changes the fewest measured parts. Codex stays on Orca Runs because it has no mod.

### 7.4 Scope

The Claude lane holds Herdr in 24 files, 265 lines (git grep over harness). Code: register.tsx 20 lines, hook-git-guard.py
2 patterns, herdr-watch-terminal.sh, herdr-watchdog.sh, reap-worktree-processes.sh (comment), selftest. Prose: dispatch-ticket,
GATE, WATCHING, CLEANUP, dispatch-ticket-claude, dispatch-junior. Prose takes one host table in dispatch-ticket, the same
seam as section 2, with QA's `herdr agent prompt` mapped to `orca terminal send` as text, then Enter as a separate call
(Orca refused the combined form with `agent_prompt_blocked`, this session).

### 7.5 Measurements, each chua do

| Id | Question | Pass |
|---|---|---|
| C1 | The mod loads in an Orca pane beside Orca's global Claude hooks (16 events in ~/.claude/settings.json) | selftest stub + one live pane writes its record entry |
| C2 | SendMessage between two Claude panes in Orca, brief becomes a turn, TURN-END wakes the dispatcher | wake under 5 s, n=5 |
| C3 | `ASTRA_DISPATCH` survives `orca terminal create --command` and `agent launch` | mod reads it, n=2 |
| C4 | Gates in Orca: merge, tdd, commit, git guard | a planted violation is refused on each |
| C5 | QA gate pane: launch, brief, turn end by the record, close | one walk to a report |
| C6 | Pane dies with an API error, and an Orca restart with a live dispatch | the dispatcher hears; the record stays true |

ListAgents from this Orca pane listed 13 peers, Herdr panes among them, so C2 may hold across hosts too; listing is not delivery.
Rollback: Herdr path unchanged, so a project stays on Herdr by not opening panes in Orca.
