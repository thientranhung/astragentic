#!/usr/bin/env bash
# herdr-watchdog.sh — monitors harness agents in this project's workspace
#
# Usage: herdr-watchdog.sh [interval=120] [cooldown=900] [max-alerts/hr=6]
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

INTERVAL="${1:-120}"
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
# ---------------------------------------------------------------------------
LOCK_STATUS_FILE="/tmp/.herdr-watchdog-lock-status.$$"
rm -f "$LOCK_STATUS_FILE"
python3 -c '
import fcntl, os, sys, time
pid, lockfile, statusfile = int(sys.argv[1]), sys.argv[2], sys.argv[3]
f = open(lockfile, "a+")
try:
    fcntl.flock(f.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
except OSError:
    open(statusfile, "w").write("busy")
    sys.exit(0)
f.seek(0)
f.truncate()
f.write(str(pid))
f.flush()
open(statusfile, "w").write("ok")
while True:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        sys.exit(0)
    except PermissionError:
        pass
    time.sleep(1)
' "$$" "$LOCK_FILE" "$LOCK_STATUS_FILE" &

lock_status=""
for _ in $(seq 1 40); do
  [ -s "$LOCK_STATUS_FILE" ] && { lock_status=$(cat "$LOCK_STATUS_FILE" 2>/dev/null); break; }
  sleep 0.05
done
rm -f "$LOCK_STATUS_FILE"
if [ "$lock_status" != "ok" ]; then
  existing_pid=$(cat "$LOCK_FILE" 2>/dev/null || true)
  echo "STOP: watchdog already running for workspace $WORKSPACE_LABEL (pid ${existing_pid:-unknown})" >&2
  exit 3
fi

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

trap 'exit 0' INT TERM

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >> "$LOG"; }

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

# Only these pane-title prefixes are harness-owned dispatches. "builder:"
# and "rin:" are what dispatch-ticket and review-with-rin actually rename
# the pane to today (AST-072); "ticket:", "spec:" and "qa:" are the tab
# label convention in orchestrator.md, kept here so a future QA/Shaper
# dispatch that renames its pane to match is recognized without a further
# change here. Anything else — including an owner tab created by hand —
# is never treated as a dispatched pane.
DISPATCH_PREFIXES = ("builder:", "ticket:", "spec:", "qa:", "rin:")

def is_dispatched(name):
    return any(name.startswith(p) for p in DISPATCH_PREFIXES)

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

# Thomas working = system active
if tstatus == "working":
    sys.exit(0)

# Thomas idle/done — check dispatched panes in this workspace
dispatched = [a for a in ws_agents
              if a["pane_id"] != tpane
              and is_dispatched(a.get("terminal_title_stripped") or "")]
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
        has_w = True

    if dstatus == "blocked":
        print(f"BLOCKED|{dpane}_blocked|workspace={ws_label} thomas={tpane}(idle) {dname}={dpane}(blocked) — builder asking a question, read pane and answer")
    elif dstatus in ("idle", "done") and not has_w and not any_working:
        print(f"STUCK|{dpane}_stuck|workspace={ws_label} thomas={tpane}(idle) {dname}={dpane}({dstatus}) watcher=none — no pane working")
    elif dstatus == "working" and not has_w:
        print(f"WATCHER_LOST|{dpane}_wlost|workspace={ws_label} thomas={tpane}(idle) {dname}={dpane}(working) watcher=none")
' 2>/dev/null
}

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
log "started — workspace=$WORKSPACE_LABEL project=$PROJECT_ROOT interval=${INTERVAL}s cooldown=${COOLDOWN}s max=$MAX_ALERTS_HOUR/hr"

while true; do
  raw=$(herdr agent list 2>/dev/null) || {
    log "herdr agent list failed"
    sleep "$INTERVAL"
    continue
  }

  output=$(echo "$raw" | analyze) || {
    log "analyze failed"
    sleep "$INTERVAL"
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

  sleep "$INTERVAL"
done
