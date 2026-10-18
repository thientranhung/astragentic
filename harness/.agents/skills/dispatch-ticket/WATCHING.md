# Watcher operational reference

Companion to `dispatch-ticket`. The pipe table and the workspace watchdog apply to every pane.
The per-turn watcher is for a pane without the mod: a QA gate pane or a junior pane
(`dispatch-junior`). A mod pane reports its own turn end (`dispatch-ticket-claude`) and draws
no pane alert at all.

## Pipes swallow exit codes

Any command piped through `tail`, `grep`, `head` or similar loses the original exit code and
reports the last command's status, for any command Thomas runs.

| shape | status |
| :--- | :--- |
| `cmd … \| tail -3` | always lost |
| `cmd … \|\| true` / `\|\| echo "failed"` | lost exactly when the command fails, so a real failure becomes 0 |
| `echo "$(cmd …)"`, `export v=$(…)`, `local v=$(…)` | lost |
| `v=$(cmd …)` (bare assignment) | preserved |
| `cmd … && rhs` | preserved on failure; a success is overwritten by `rhs` |

The rule reaches past pipes: any status not taken from the command you care about is some
other command's status, and the substitute defaults to success. A backgrounded Bash block
reports its LAST command, so `make itest-local …; grep …` arrives as *"exit code 0"* on a red
suite. Take the status inside the block:

```bash
cmd … > /tmp/out.log 2>&1; status=$?; tail -25 /tmp/out.log; exit $status
```

## The per-turn watcher

`<repo-root>/scripts/herdr-watch-terminal.sh <pane-id> 3 3600 120` watches a newly submitted
turn: it waits to observe `working` first, so an already-idle pane returns `NO_START`. Run it
by absolute path, alone on its line, immediately after the submit, once per turn. A fold sent
after a gate or an answer to a blocked pane is a new turn and needs a new watcher. A hand-rolled
status-poll loop or a bare `herdr agent wait` drops `TIMEOUT` and `NO_START`, and goes deaf.

Branch on `$?` and the payload:

- `0` + `TERMINAL:done pane=<id>` — the turn ended, not necessarily the work (below).
- `0` + `TERMINAL:idle pane=<id>` — check git log; it may have stopped early.
- `0` + `TERMINAL:blocked pane=<id>` — read the pane and answer now, then restart the watcher.
- `1` + `TIMEOUT after <max>s pane=<id>` — exceeded the cap; inspect the pane.
- `2` + `NO_START pane=<id>` — never started working; read the pane for an unsent composer.

`120` is the first-arm `start_max_s`. Re-arming over a Builder already seen working, between
turns of a background suite, needs one long enough to cover it:
`… <pane-id> 3 3600 1800`.

**`done` means the turn ended.** Before concluding finished, check two sources for background
work: OS processes (`pgrep` for runners whose argv contains the worktree path) and the status
line (`herdr agent read <pane-id>` names the shells and monitors the runtime tracks). A
disagreement between them is a signal: read the pane. Work running means PARKED. All quiet
and no new commits since your last instruction: read the pane, since the turn may have
crashed. All quiet and new commits: verify by artifact (`check-simplify-markers.sh`).

**Stopping a watch takes the process group.** On macOS the watcher re-execs under
`caffeinate`, so killing the visible PID orphans the wrapped shell:

```bash
pgid=$(ps -o pgid= -p <watch-pid> | tr -d ' ')
kill -TERM -"$pgid"
pgrep -g "$pgid" >/dev/null && echo SURVIVORS || echo clean
```

## The workspace watchdog

Required before the first dispatch (`thomas.md` § Watchdog). Preflight, scoped to this
workspace by the lock the watchdog holds:

```bash
LOCK="/tmp/herdr-watchdog-<workspace-label>.lock"
if [ -f "$LOCK" ] && kill -0 "$(cat "$LOCK")" 2>/dev/null; then
  echo "watchdog: running for this workspace"
else
  echo "STOP: no watchdog for this workspace — start it before dispatching"; exit 1
fi
```

Start and stop:

```bash
nohup scripts/herdr-watchdog.sh 300 900 6 &   # interval, cooldown, max-alerts/hr
scripts/herdr-watchdog.sh stop
```

It reads `workspace-label` from `orchestrator.md`; `stop` verifies the PID at the lock.

**The lock is a hint, not a census: sweep by process.** A launch is not idempotent: two
watchdogs ran on one workspace with the lock naming only the younger. Derive the label from
`orchestrator.md`, sweep, and read each cwd before killing:

```bash
ps -Ao pid,ppid,etime,args | awk '/[h]erdr-watchdog\.sh/ {p[$1]=1; l[$1]=$0; pp[$1]=$2}
  END {for (i in p) if (!(pp[i] in p)) print l[i]}'
lsof -a -p <pid> -d cwd -Fn | grep '^n'   # -a is load-bearing
```

Two different ages is the duplicate signature; a parent and its child is not. `rm` a stale
lock only after the sweep.

Every alert fires once per episode, for panes without the mod only. `STUCK` and
`NEVER_STARTED` each ask about one pane and need two polls.

| Alert | What it means | Action |
|---|---|---|
| `BLOCKED` | Pane asking a question | Read, answer, restart the watcher |
| `WATCHER_LOST` | Pane working, nobody watching | Re-arm the watcher now |
| `STUCK` | This pane worked, then sat idle across two polls | Check whether its next step started; handback or re-dispatch |
| `NEVER_STARTED` | Dispatched, never observed working | Read the pane: the brief never ran as a turn |
| `THOMAS_CRASHED` | The router's process is gone | Desktop notification substitutes |

A pane that ends its turn with a test run in the background reads `done`. The project answers
with `.astraler/project/work-in-flight.sh`: exit 0 while something heavy runs, 1 when nothing
does. Without the plug `STUCK` fires on pane state alone, so read the pane before acting.

A pane launched with `herdr pane run` and never renamed carries no agent name, is never
counted as dispatched and emits nothing; the launch registers a name for that reason.
