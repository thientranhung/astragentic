#!/usr/bin/env bash
# herdr-watchdog.sh — monitors harness agents in this project's workspace
#
# Usage: herdr-watchdog.sh [interval=300] [cooldown=900] [max-alerts/hr=6]
#        herdr-watchdog.sh stop
#
# Run from project root. Reads workspace-label from .agents/orchestrator.md,
# resolves the workspace, and only monitors agents whose pane belongs to it.
# Multiple projects never interfere.
#
# One instance per workspace-label, enforced by a kernel-managed `flock`
# held by a dedicated holder process (AST-076, fourth and final revision).
# Three earlier designs (bare mkdir, mkdir plus mv-based eviction, mkdir
# plus a reclaim-mutex) each closed one race and left another; a fourth
# attempt traded all of it for the simplest possible mkdir lock, accepting
# "two watchdogs alert twice" as the worst case — until a review measured
# what that worst case actually is: `stop` kills whichever instance holds
# the CURRENT lock and deletes it, leaving the OTHER instance alive with no
# lock, no name, and nothing left able to stop it. Not a nuisance — an
# orphan. `flock` closes it without needing any of the reclaim logic every
# earlier design got wrong, because there is no "stale lock" state to
# reclaim: the kernel releases the lock the instant the holding descriptor
# closes, for any reason, including SIGKILL. The one thing that took a
# dedicated holder process to get right: bash spawns children constantly
# (`sleep`, `herdr`, the analyze() python call) that inherit open file
# descriptors by default, so a bare fd held in this script's own process
# leaks the lock to whichever child is still alive when this process dies.
# A holder that spawns nothing itself cannot leak it to anything.
#
# Lock file:     /tmp/herdr-watchdog-<workspace-label>.lock      (flock + PID)
# Log file:      /tmp/herdr-watchdog-<workspace-label>.log       (alerts only)
# State dir:     /tmp/herdr-watchdog-<workspace-label>.state     (heartbeat, counters)
#
# THE PROCESS TABLE, THE PID FILE AND CPU TIME ALL FAIL TO PROVE THIS SCRIPT IS
# ALIVE. A live project measured all three failing on the same instance: it was
# in `ps`, its own pid file had been deleted while it kept running, and its
# permanent `caffeinate` child made "has a child process" true whether the loop
# was working or wedged. None of the three can go false when the loop hangs. A
# timestamp that only advances when the loop COMPLETES can — that is what the
# heartbeat file is, rewritten in place every HEARTBEAT_EVERY-th poll so it
# never buries the alert log it sits beside. Check its mtime, not its presence.
#
# Exit:
#   0  — stopped by signal, by `stop`, or workspace gone
#   2  — config error (no orchestrator.md, no workspace-label, not in git repo)
#   3  — another instance already holds the lock for this workspace
#
# LAUNCH IT AS A PLAIN BACKGROUND JOB YOU DO NOT WRAP — `nohup ... &`, nothing
# else in the pipeline. Isolating into its own process group (below) protects
# it from a signal sent to the CALLER's group; it does nothing against a
# signal a launcher sends to this script's PID directly, which is exactly
# what a wrapper with its own timeout does once that timeout fires. Measured:
# a watchdog started from inside a tool call that itself later timed out and
# was killed exited within the same second — cleanly, via `trap 'exit 0' INT
# TERM` below, with nothing in the log to say why, because a clean exit trap
# and a real one look identical from the log alone. After launching, confirm
# with `ps -o ppid= -p <pid>` reading `1` — a live PID with no error printed
# is not the same claim as "actually detached and still running."
set -u

# ---------------------------------------------------------------------------
# Project root & workspace-label
# ---------------------------------------------------------------------------
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "STOP: not in a git repo" >&2; exit 2
}
ORCH_FILE="$PROJECT_ROOT/.agents/orchestrator.md"

WORKSPACE_LABEL=$(python3 -c "
import re
try:
    text = open('$ORCH_FILE').read()
    m = re.search(r'workspace-label\s*\|\s*\x60([^\x60]+)\x60', text)
    label = m.group(1) if m else ''
    print('' if label == '<set-me>' else label)
except Exception:
    print('')
")
[ -z "$WORKSPACE_LABEL" ] && {
  echo "STOP: no workspace-label set in .agents/orchestrator.md" >&2; exit 2
}

LOCK_FILE="/tmp/herdr-watchdog-${WORKSPACE_LABEL}.lock"
LOG="/tmp/herdr-watchdog-${WORKSPACE_LABEL}.log"
STATE_DIR="/tmp/herdr-watchdog-${WORKSPACE_LABEL}.state"
# Rewritten in place every HEARTBEAT_EVERY-th poll, so its own mtime is the
# check — a stale timestamp is what a wedged loop looks like, and separate
# from LOG so a heartbeat on every poll never buries the alert history.
HEARTBEAT_FILE="$STATE_DIR/alive"

# A recorded PID counts as "us" only if it is alive AND its command line
# still names this script — never trust the PID number alone, since PIDs are
# reused. One `ps` call for both fields, not two: a second call moments
# later is a second chance for the process to have already exited between
# them, and the pgid is needed only when the identity check already passed.
WATCHDOG_PGID=""
is_watchdog_process() {
  local pid="$1" line pgid rest cmd script
  [ -n "$pid" ] || return 1
  line=$(ps -o pgid=,args= -p "$pid" 2>/dev/null) || return 1
  # `read` splits on runs of whitespace and discards leading/trailing blanks
  # itself — unlike `${line%% *}`, which returns EMPTY when BSD/macOS `ps`
  # right-pads the pgid column with leading spaces (it does, routinely).
  read -r pgid rest <<< "$line"
  [[ "$pgid" =~ ^[0-9]+$ ]] || return 1
  # A SUBSTRING match on the whole command line (the earlier form of this
  # check) also matches `tail -f herdr-watchdog.sh`, an editor with the file
  # open, or a shell with the path in its history buffer — measured: a
  # `tail -f` on this exact file passed it. Combined with PID reuse after a
  # crash that bypassed the EXIT trap, that hands `stop` a live but
  # unrelated process to send a process-group TERM to. Require the shape of
  # our own invocation instead: argv[0] a bash interpreter, argv[1] a path
  # ending in this filename — not merely present anywhere in the line.
  read -r cmd script _ <<< "$rest"
  case "$cmd" in bash|*/bash) ;; *) return 1 ;; esac
  case "$script" in herdr-watchdog.sh|*/herdr-watchdog.sh) ;; *) return 1 ;; esac
  WATCHDOG_PGID="$pgid"
  return 0
}

# ---------------------------------------------------------------------------
# stop subcommand
# ---------------------------------------------------------------------------
if [ "${1:-}" = "stop" ]; then
  pid=$(cat "$LOCK_FILE" 2>/dev/null || true)
  if ! is_watchdog_process "$pid"; then
    echo "no live watchdog for workspace $WORKSPACE_LABEL" >&2
    exit 0
  fi
  if [ -n "$WATCHDOG_PGID" ]; then
    kill -TERM -"$WATCHDOG_PGID" 2>/dev/null
  else
    kill -TERM "$pid" 2>/dev/null
  fi
  # No lock to remove: `flock` releases itself the instant the signaled
  # process's fd closes, whether it exits cleanly or is killed. LOCK_FILE's
  # PID content is left in place — informational only, overwritten by
  # whoever next acquires the lock, never read as a claim of ownership by
  # anything other than that acquisition.
  exit 0
fi

INTERVAL="${1:-300}"
COOLDOWN="${2:-900}"
MAX_ALERTS_HOUR="${3:-6}"

# ---------------------------------------------------------------------------
# Isolate into our own process group, so `stop` can signal the whole group
# without ever touching the caller's shell/pane. setsid(2) replaces the
# process image in place (same PID throughout), so this is the only
# re-exec in the whole startup path.
# ---------------------------------------------------------------------------
if [ -z "${HERDR_WATCHDOG_ISOLATED:-}" ]; then
  export HERDR_WATCHDOG_ISOLATED=1
  # setsid(2) raising EPERM means we are ALREADY a process-group leader —
  # it does NOT mean we are alone in that group. A shell pipeline's first
  # stage is also a group leader while sharing the group with every other
  # stage, so this failure is proof only that a new session could not be
  # created, not proof of isolation. Catching it and proceeding is still
  # correct for the one path that normally produces it here — re-running
  # this exec after `HERDR_WATCHDOG_ISOLATED` is already set, where we are
  # already alone. A watchdog launched as a pipeline stage instead of the
  # documented plain background job (`nohup ... &`) is a real but narrow
  # gap this does not close: a runtime member-count check was tried and
  # measured unreliable (three different counting strategies gave three
  # different member counts on the same isolated process, because the
  # counting itself forks concurrent subprocesses that transiently share
  # the group being counted). Stays a documented assumption about how this
  # script is invoked, not a guarantee the code enforces.
  exec python3 -c '
import os, sys
try:
    os.setsid()
except OSError:
    pass
os.execvp(sys.argv[1], sys.argv[1:])
' "$0" "$@"
fi

# ---------------------------------------------------------------------------
# Single-instance lock, held by a DEDICATED holder process — never by a
# file descriptor open in this bash process itself (see the header note on
# why a bare fd here leaks the lock to this script's own children).
#
# The watch is BIDIRECTIONAL, and each direction is armed BEFORE it is
# trusted:
#
# - The holder watches this process via getppid() reparenting, not a
#   PID-liveness poll — a dead-but-unreaped parent is still a zombie that
#   os.kill(pid, 0) reports as alive, and a recycled PID would fool a poll
#   that only remembers a number; reparenting to the OS's subreaper happens
#   the instant the parent exits, immune to both. But reparenting can ALSO
#   happen before the holder ever checks — a crash between the fork and the
#   holder's first getppid() call reparents it before it looks, and it would
#   then arm against the subreaper and hold the flock forever. So the holder
#   is handed the PID it is meant to watch and refuses to arm unless its
#   OWN first getppid() still matches it.
# - This process watches the holder the same way in reverse: `kill -0`
#   alone repeats the zombie problem (a dead holder we have not reaped
#   still answers as alive), so the check reads process STATE and treats a
#   zombie as gone. And it does not only run between iterations of the main
#   loop — a `herdr` call hanging mid-iteration would otherwise widen the
#   detection window unboundedly — a separate reaper process watches the
#   holder independently of whatever the main loop is doing and signals
#   this process the moment it is gone.
#
# LOCK_FILE and the status file are both opened with O_NOFOLLOW, so a
# symlink pre-planted at either predictable path is refused rather than
# followed. The status file's PATH is no longer predictable at all — it
# lives inside a directory `mktemp -d` creates fresh, unique and
# owner-only (mode 0700) for this one acquisition attempt, so there is
# nothing for a local attacker to pre-plant into ahead of time, and no
# `rm -f` race against a file someone else may already own.
# ---------------------------------------------------------------------------
LOCK_STATUS_DIR=$(mktemp -d "${TMPDIR:-/tmp}/herdr-watchdog-status.XXXXXXXX") || {
  echo "STOP: could not create a private status directory" >&2
  exit 2
}
LOCK_STATUS_FILE="$LOCK_STATUS_DIR/status"
python3 -c '
import fcntl, os, sys, time

expected_pid, lockfile, statusfile = int(sys.argv[1]), sys.argv[2], sys.argv[3]

def write_status(path, msg):
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, "w") as sf:
        sf.write(msg)

# Arm only if we are, right now, still a direct child of the process we were
# told to watch. A crash between the fork that made us and this line
# reparents us to the subreaper before we ever check — proceeding anyway
# would mean watching the wrong process forever and holding the flock past
# the watchdog it was acquired for.
if os.getppid() != expected_pid:
    write_status(statusfile, "busy")
    sys.exit(0)

try:
    fd = os.open(lockfile, os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
except OSError:
    write_status(statusfile, "busy")
    sys.exit(0)
f = os.fdopen(fd, "r+")
try:
    fcntl.flock(f.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
except OSError:
    write_status(statusfile, "busy")
    sys.exit(0)
f.seek(0)
f.truncate()
f.write(str(expected_pid))
f.flush()
write_status(statusfile, "ok")
while os.getppid() == expected_pid:
    time.sleep(1)
' "$$" "$LOCK_FILE" "$LOCK_STATUS_FILE" &
HOLDER_PID=$!

lock_status=""
for _ in $(seq 1 40); do
  [ -s "$LOCK_STATUS_FILE" ] && { lock_status=$(cat "$LOCK_STATUS_FILE" 2>/dev/null); break; }
  sleep 0.05
done
rm -rf "$LOCK_STATUS_DIR"
if [ "$lock_status" != "ok" ]; then
  existing_pid=$(cat "$LOCK_FILE" 2>/dev/null || true)
  echo "STOP: watchdog already running for workspace $WORKSPACE_LABEL (pid ${existing_pid:-unknown})" >&2
  exit 3
fi

trap 'exit 0' INT TERM

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >> "$LOG"; }

# A zombie still answers `kill -0` as alive — it is a dead process not yet
# reaped, not a live one — so the state column is what actually says
# whether the holder is gone. PID reuse after that state finally clears
# stays an accepted, documented gap: the same shape and the same call as
# the setsid/EPERM gap above, on a check re-run every second.
holder_alive() {
  local state
  state=$(ps -o state= -p "$HOLDER_PID" 2>/dev/null) || return 1
  [[ "$state" != Z* ]]
}

holder_gone_die() {
  if ! holder_alive; then
    log "lock holder (pid $HOLDER_PID) is gone — exiting so a fresh start can safely take the lock"
    exit 0
  fi
}

# Sleeps in 1s steps, checking the holder each step, instead of one long
# sleep — so a dead holder is noticed within about a second, not up to a
# whole poll interval later.
sleep_or_die() {
  local remaining="$1"
  while (( remaining > 0 )); do
    holder_gone_die
    sleep 1
    remaining=$(( remaining - 1 ))
  done
}

# Runs independently of the main loop, so a dead holder is still caught
# within about a second even while that loop is stuck inside a slow or
# hung `herdr` call — sleep_or_die alone only checks between iterations.
# Logs before signalling: this reaper wins the race against
# holder_gone_die's own log line almost every time (measured: zero holder-
# death runs ever hit the sleep_or_die path first), so without this line
# the operator sees a watchdog that vanished with nothing in the log to
# explain why.
( while holder_alive; do sleep 1; done
  log "lock holder (pid $HOLDER_PID) is gone — signalling this process to exit"
  kill -TERM "$$" 2>/dev/null ) &
REAPER_PID=$!

# caffeinate as a background helper we launch, never a wrapper we exec into.
# `-w $$` makes it wait on and track our own PID and exit on its own once
# we do — no child of it ever becomes the process this script's identity
# depends on.
if [ -z "${HERDR_WATCHDOG_NO_CAFFEINATE:-}" ] && command -v caffeinate >/dev/null 2>&1; then
  caffeinate -i -w $$ &
fi

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
[ -L "$STATE_DIR" ] && rm -f "$STATE_DIR"   # refuse a pre-planted symlink
mkdir -p "$STATE_DIR"
echo 0  > "$STATE_DIR/alert_count"
date +%s > "$STATE_DIR/alert_reset"
HEARTBEAT_EVERY="${HEARTBEAT_EVERY:-5}"

# ---------------------------------------------------------------------------
# Rate-limit & cooldown helpers
# ---------------------------------------------------------------------------
can_alert() {
  local now count reset
  now=$(date +%s); count=$(cat "$STATE_DIR/alert_count"); reset=$(cat "$STATE_DIR/alert_reset")
  if (( now - reset >= 3600 )); then
    echo 0    > "$STATE_DIR/alert_count"
    echo "$now" > "$STATE_DIR/alert_reset"
    count=0
  fi
  (( count < MAX_ALERTS_HOUR ))
}

incr_alert() {
  local c; c=$(cat "$STATE_DIR/alert_count"); echo $(( c + 1 )) > "$STATE_DIR/alert_count"
}

on_cooldown() {
  local key="$1" san="${1//[^a-zA-Z0-9]/_}" now
  now=$(date +%s)
  [[ -f "$STATE_DIR/cd_$san" ]] && (( now - $(cat "$STATE_DIR/cd_$san") < COOLDOWN ))
}

set_cooldown() {
  local san="${1//[^a-zA-Z0-9]/_}"
  date +%s > "$STATE_DIR/cd_$san"
}

# ---------------------------------------------------------------------------
# Alerting — send to Thomas pane if found, else desktop notification
# ---------------------------------------------------------------------------
send_alert() {
  local atype="$1" details="$2" thomas_pane="${3:-}"
  if ! can_alert; then
    log "RATE_LIMITED [$atype] $details"
    return 1
  fi
  if [ -n "$thomas_pane" ] \
     && herdr agent prompt "$thomas_pane" "WATCHDOG ALERT [$atype]: $details" 2>/dev/null; then
    incr_alert
    log "ALERTED [$atype] $details"
  else
    herdr notification show "WATCHDOG [$WORKSPACE_LABEL]" \
      --body "[$atype] $details" \
      --sound request 2>/dev/null
    log "NOTIFY_FALLBACK [$atype] $details"
  fi
}

# ---------------------------------------------------------------------------
# Anomaly analysis — workspace-scoped
# ---------------------------------------------------------------------------
analyze() {
  python3 -c '
import json, sys, subprocess, os, re

raw = sys.stdin.read()
try:
    agents = json.loads(raw)["result"]["agents"]
except (json.JSONDecodeError, KeyError):
    sys.exit(1)

ws_label = "'"$WORKSPACE_LABEL"'"
project_root = "'"$PROJECT_ROOT"'"

# Two independent signals can name a dispatched pane, checked in order.
#
# The herdr AGENT NAME, set once at `herdr agent start "<role>-<id>"`
# (dispatch-ticket-<runtime>, review-with-rin) and never touched again by
# anything the harness controls, is the primary signal. `terminal_title` /
# `terminal_title_stripped`, set by `herdr pane rename "<role>:<id>"`, is a
# fallback only — measured directly on a real, running dispatch: a
# Claude-runtime Builder had its `name` still reading `builder-tra-180` unchanged
# while its `terminal_title_stripped` had been overwritten by the runtime
# itself to a bare `builder` (no colon, no ticket id), because the Claude
# runtime writes its own terminal title after launch and does not honor a
# rename that predates it. Title-only matching is blind to every such
# pane: it never enters `dispatched`, so the watchdog never fires BLOCKED,
# STUCK or WATCHER_LOST for it — heartbeats normally, reports nothing, a
# guard that cannot fail (the AST-072 class, one level up: a coordination
# primitive trusted at launch time and never re-checked for whether the
# runtime it targets still lets it be seen).
AGENT_NAME_PREFIXES = ("builder-", "shaper-", "qa-", "rin-")
# "ticket:", "spec:" and "qa:" are the TAB label convention in
# orchestrator.md, kept in the title fallback so a pane a dispatcher
# renamed to match a tab label is still recognized without a further
# change here. Anything else — including an owner tab created by hand —
# is never treated as a dispatched pane.
TITLE_PREFIXES = ("builder:", "ticket:", "spec:", "qa:", "rin:")

def is_dispatched(agent_name, title):
    if agent_name and any(agent_name.startswith(p) for p in AGENT_NAME_PREFIXES):
        return True
    return any(title.startswith(p) for p in TITLE_PREFIXES)

# Resolve workspace ID by label
try:
    ws_raw = subprocess.check_output(
        ["herdr", "workspace", "list"], stderr=subprocess.DEVNULL, timeout=5)
    workspaces = json.loads(ws_raw)["result"]["workspaces"]
    ws = next((w for w in workspaces if w.get("label") == ws_label), None)
    if not ws:
        print(f"__EXIT__|1|workspace {ws_label} not found")
        sys.exit(0)
    ws_id = ws["workspace_id"]
except Exception:
    sys.exit(1)

# Filter agents to this workspace by pane_id prefix
ws_agents = [a for a in agents if a["pane_id"].startswith(ws_id + ":")]
if not ws_agents:
    sys.exit(0)

# Skip if paused
if os.path.exists(os.path.join(project_root, ".agents", ".paused")):
    sys.exit(0)

# Find Thomas in this workspace (title may have spinner prefix like "◑ thomas")
# Match the herdr agent NAME first, title second. AST-084 measured Claude overwriting the pane
# title, and its fix was applied to is_dispatched() twelve lines below and not here — so one
# overwritten title reached the sys.exit(0) underneath and silenced every pane alert that poll.
thomas = next((a for a in ws_agents
               if (a.get("name") or "").lower().endswith("thomas")), None)
if thomas is None:
    thomas = next((a for a in ws_agents
                   if (a.get("terminal_title_stripped") or "").endswith("thomas")), None)

if not thomas:
    try:
        print(f"THOMAS_CRASHED|thomas_crashed|workspace={ws_label} — no thomas agent found")
    except Exception:
        pass
    sys.exit(0)

tpane   = thomas["pane_id"]
tstatus = thomas["agent_status"]

# Emit Thomas pane for alerting
print(f"__THOMAS__|{tpane}")

# THOMAS_CRASHED — agent entry exists but its runtime process is gone. The
# expected process name is read from orchestrator.md, not hard-coded, since
# Thomas may be dispatched on claude, codex or opencode (AST-072).
if tstatus == "idle":
    try:
        orch_text = open(os.path.join(project_root, ".agents", "orchestrator.md")).read()
        m = re.search(r"^\|\s*thomas\s*\|\s*([a-zA-Z]+)\s*\|", orch_text, re.MULTILINE)
        runtime = m.group(1) if m else "claude"
        pi = json.loads(subprocess.check_output(
            ["herdr", "pane", "process-info", "--pane", tpane],
            stderr=subprocess.DEVNULL, timeout=5))
        procs = pi["result"]["process_info"]["foreground_processes"]
        if not any(p.get("name") == runtime for p in procs):
            print(f"THOMAS_CRASHED|{tpane}_crashed|workspace={ws_label} thomas={tpane} — no {runtime} process")
            sys.exit(0)
    except Exception:
        pass

# Thomas working = system active. This used to exit here, silencing EVERY alert while the
# dispatcher was busy — and "the dispatcher is busy" is precisely the window the alerts exist
# for. Measured: a dispatcher spent 5-15 minutes per gate pass with Builders live, and the
# WATCHER_LOST check sitting below this line never ran once in nine hours (AST-125).
#
# Only STUCK depends on system liveness ("nothing is working, so nothing is moving"). BLOCKED
# and WATCHER_LOST are facts about a DISPATCHED pane and are true regardless of what the
# dispatcher is doing — a Builder asking a question is still asking it, and a Builder running
# with nobody watching is still unwatched. Suppressing them by the state of the dispatcher was
# scoping an alert by the wrong subject.
thomas_busy = (tstatus == "working")

# Thomas idle/done — check dispatched panes in this workspace
dispatched = [a for a in ws_agents
              if a["pane_id"] != tpane
              and is_dispatched(a.get("name") or "", a.get("terminal_title_stripped") or "")]
if not dispatched:
    sys.exit(0)

any_working = any(d["agent_status"] == "working" for d in dispatched)

for d in dispatched:
    dpane   = d["pane_id"]
    dstatus = d["agent_status"]
    dname   = d.get("name", d.get("terminal_title_stripped", "unknown"))

    # For the heartbeat pane count below — a marker line, not an alert.
    print(f"__seen|{dpane}")

    try:
        has_w = subprocess.run(
            ["pgrep", "-f", f"herdr-watch-terminal.sh {dpane}"],
            capture_output=True, timeout=5).returncode == 0
    except Exception:
        # Fail CLOSED. A pgrep that raised told us nothing, and defaulting to True turned an
        # unanswered question into an all-clear — the AST-032 shape inside the watchdog itself.
        has_w = False
    if dstatus == "blocked":
        print(f"BLOCKED|{dpane}_blocked|workspace={ws_label} thomas={tpane}({tstatus}) {dname}={dpane}(blocked) — builder asking a question, read pane and answer")
    elif dstatus in ("idle", "done") and not has_w and not any_working and not thomas_busy:
        print(f"STUCK|{dpane}_stuck|workspace={ws_label} thomas={tpane}({tstatus}) {dname}={dpane}({dstatus}) watcher=none — no pane working")
    elif dstatus == "working" and not has_w:
        print(f"WATCHER_LOST|{dpane}_wlost|workspace={ws_label} thomas={tpane}({tstatus}) {dname}={dpane}(working) watcher=none — re-arm the watch")
' 2>/dev/null
}

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
log "started — workspace=$WORKSPACE_LABEL project=$PROJECT_ROOT interval=${INTERVAL}s cooldown=${COOLDOWN}s max=$MAX_ALERTS_HOUR/hr"

while true; do
  raw=$(herdr agent list 2>/dev/null) || {
    log "herdr agent list failed"
    sleep_or_die "$INTERVAL"
    continue
  }

  output=$(echo "$raw" | analyze) || {
    log "analyze failed"
    sleep_or_die "$INTERVAL"
    continue
  }

  # Check for workspace-gone exit signal
  if echo "$output" | grep -q '^__EXIT__'; then
    msg=$(echo "$output" | grep '^__EXIT__' | cut -d'|' -f3)
    log "exiting — $msg"
    herdr notification show "WATCHDOG [$WORKSPACE_LABEL] stopped" \
      --body "$msg" --sound request 2>/dev/null
    exit 0
  fi

  # Extract Thomas pane for alerting
  thomas_pane=$(echo "$output" | grep '^__THOMAS__' | cut -d'|' -f2)

  # Process anomalies (skip internal lines)
  while IFS='|' read -r atype key details; do
    [[ -z "$atype" ]] && continue
    [[ "$atype" == __* ]] && continue
    if ! on_cooldown "$key"; then
      send_alert "$atype" "$details" "$thomas_pane"
      set_cooldown "$key"
    fi
  done <<< "$output"

  # Heartbeat — see the header comment for why nothing else here proves the
  # loop is alive. Written every HEARTBEAT_EVERY-th poll, in place rather
  # than appended.
  beat=$(( ${beat:-0} + 1 ))
  if (( beat % HEARTBEAT_EVERY == 0 )); then
    # `grep -c` PRINTS the count and STILL exits 1 when the count is zero, so
    # a naive `|| echo` fallback fires alongside it and emits two lines.
    # `|| true` keeps the count and the exit code both harmless.
    seen=$(echo "$output" | grep -c '^__seen' || true)
    printf '[%s] alive — poll #%s, %s dispatched pane(s)\n' \
      "$(date '+%H:%M:%S')" "$beat" "${seen:-0}" \
      > "$HEARTBEAT_FILE"
  fi

  sleep_or_die "$INTERVAL"
done
