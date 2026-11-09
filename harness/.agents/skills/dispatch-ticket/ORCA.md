# Dispatch on Orca (6.1.0)

Read when `ORCA_PANE_KEY` is set in your environment. One host per session (owner, 2026-11-09):
a session started in Orca never runs `herdr`, and one started in Herdr never runs `orca`. The mod
refuses the other host's commands; this file is the Orca form of each step `SKILL.md`, `GATE.md`,
`WATCHING.md` and `CLEANUP.md` write for Herdr. Everything host-neutral (worktree, branch, brief,
record, handback, tracker, merge) is unchanged and not restated here.

## The check

```sh
if [ -n "${ORCA_PANE_KEY:-}" ]; then HOST=orca     # first: an Orca opened from a Herdr pane may inherit HERDR_*
elif [ "${HERDR_ENV:-}" = "1" ]; then HOST=herdr
else echo "no host: stop and report"; fi
```

Measured in an Orca pane, 2026-11-09: `ORCA_PANE_KEY`, `ORCA_TAB_ID`, `ORCA_TERMINAL_HANDLE`,
`ORCA_CLI_BIN_DIR` set; `HERDR_ENV`, `HERDR_TAB_ID`, `HERDR_PANE_ID` unset.

## The pane (SKILL.md § Tab and pane)

There is no workspace step: the tab opens under the worktree Orca already shows for this repo.
The role rides in the launch command's environment, because Orca rewrites tab titles while the
agent runs (measured: `.` became the brief's first words). The mod reads `ASTRA_DISPATCH`, never
the title.

```bash
orca terminal create --worktree "path:<base-checkout>" --title "<tab>" --json \
  --command "cd <worktree-path> && ASTRA_DISPATCH=<tab> <launcher argv from dispatch-ticket-claude, executable included>"
# result.terminal.handle is the pane's address; record it as terminal= in the dispatch line
orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 60000 --json   # readiness
```

`--worktree` names the base checkout's workspace, the one in the sidebar; the worktree is reached by
the `cd` inside the command. `active` resolves to the innermost Orca workspace around the shell's cwd,
and a git worktree under `.claude/worktrees/` is such a workspace to the CLI while the sidebar never
lists it: a pane created there has no UI host, is never attached (daemon log: 0 `session-attached`
against 21 for a sidebar pane), and reads `orphaned: true, connected: true` in `terminal show` while
its agent runs on (nizzy 2026-11-10, 3 of 3 Codex panes; reproduced once with `path:<worktree>`).
`terminal switch` answers `navigated: true` and `worktree activate` `activated: true` without showing
it. Such a pane is driven by `read`, `send`, `wait` only; no CLI call reattaches it.

`<tab>` is the same `ticket:<id>` / `spec:<id>` / `qa:<id>` as on Herdr. The argv includes
`claude`: there is no `--kind` to supply it. The pane records `host=orca` and `terminal=<handle>`
beside `tab_id` (`ORCA_TAB_ID`) and `pane_id` (`ORCA_PANE_KEY`). The cwd gate is the `cd` in the
command; a pane whose first `orca terminal read` shows another directory is a STOP.

The dispatch line reads `topology=orca terminal=<handle>` in place of `workspace=… tab=… pane=…`.

## The brief and the turn end

Unchanged on a Claude root: one SendMessage, `RECEIVED`, `TURN-END` (measured in Orca: 3 s and
1 s round trip, both sessions in bypass; a pane in auto mode HELD the message, Claude's
permission-class rule, as on Herdr). A pane without the mod (QA gate, junior) is briefed by file:
write the brief to a path outside the gate worktree, then send a one-line pointer as two calls,
text then Enter. Measured 2026-11-09: `--text` bodies past about 1,260 characters returned
`accepted: true` and never reached the TUI (1,300 and 2,400 chars 0/2), a 2,400-char file plus a
63-char pointer arrived 2/2; the combined text-and-Enter form is refused with
`agent_prompt_blocked` while a prompt is on screen.

```bash
orca terminal send --terminal <handle> --text "Read <brief-path> completely and carry it out." --json
orca terminal send --terminal <handle> --enter --json
```

## Watching (WATCHING.md)

No watcher and no watchdog on Orca: `herdr-watch-terminal.sh` and `herdr-watchdog.sh` are Herdr
programs and are not started. The turn end arrives by the mod (Claude root) or by the record (gate
pane). A pane that died shows on the board from its own record entry; Orca has no notification
command (`orca --help`, 1.4.254), so there is no desktop alert on Orca: read the board.

## Cleanup (CLEANUP.md)

```bash
# 1. read the handle from the record (a separate call: the mod reads the close before the shell runs)
python3 -c "import json;print(json.load(open('.astraler/state/dispatch-record.json'))['<KEY>']['terminal'])"
# 2. close with the handle written out; `--terminal $(…)` is refused (6.1.1)
orca terminal show --terminal term_… --json         # alive? `connected: false` means already closed
orca terminal close --terminal term_… --tab --json
```

The mod refuses the close while the pane is mid-turn, as it does `herdr tab close`, and only when it
can read the handle literally: a substituted handle matched no entry, so the guard and the record
both missed (inception, 2026-11-09: 7 of 8 closes, six entries left behind). Orca closes the tab with
its last pane; `show` on a closed handle still exits 0, with `connected: false`, which the mod reads as
gone at `git worktree remove`. `orphaned: true` alone is not closed: it says no UI pane hosts the
PTY (§ The pane), and a closed terminal shows it too. No workspace to close.

## Not measured

Mod in an Orca pane end to end (C1, C4), a QA gate pane on Orca (C5), a pane dying or an Orca
restart with a live dispatch (C6), `HERDR_*` inherited inside Orca. Until C1 and C4 pass on a
fixture, dispatch Claude Builders on Herdr.
