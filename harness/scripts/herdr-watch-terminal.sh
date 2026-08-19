#!/bin/bash
# herdr-watch-terminal.sh <pane_id> [debounce_s] [max_s] [start_max_s] [wait_slice_s]
#
# Herdr watcher for a newly submitted turn (floor 0.8.0). Exit contract:
#   0 + TERMINAL:<done|blocked|idle> pane=<id>
#   1 + TIMEOUT ... pane=<id>
#   2 + NO_START pane=<id>
#
# Every line names its own pane. With three builders in flight there are three watches
# emitting into one stream, and "TERMINAL:done" with no source is three identical lines the
# reader cannot tell apart. The state goes FIRST so prefix matching on TERMINAL:done still
# works for callers that branch on the payload.
#
# Native `herdr agent wait` supports repeated --until values with OR semantics. The
# watcher still keeps the proven safety floors:
# - stale-task start guard: a previous idle/done cannot complete a new dispatch;
# - terminal flicker debounce: require the same settled state twice;
# - blocked is a wake-up state for Thomas, not a failure;
# - status is a bell, never proof that the artifact is correct;
# - the watch holds its OWN idle-sleep assertion (see SELF-CAFFEINATE below);
# - and NO single `herdr agent wait` is trusted to fire (see WAIT_SLICE below).
#
# WAIT_SLICE — why the long wait is sliced (AST-107, measured 2026-08-19).
# A single `herdr agent wait --timeout 3600000` was observed ALIVE and DEAF: the pane had
# been `idle` for minutes, `pgrep` showed the waiter running, and it never returned. An
# identical wait launched in the same minute against the same pane returned in 0s with the
# state. So the long-lived waiter misses the transition and then waits forever on a state
# that already happened — a signal that cannot fire, wearing the costume of a signal that is
# healthy, which is worse than a dead one because `pgrep` says it is fine (AST-032).
#
# The fix is to stop trusting `wait` for the verdict. Each iteration waits at most
# WAIT_SLICE seconds, and the VERDICT ALWAYS COMES FROM A FRESH `herdr agent get`. The wait
# is now only an interruptible sleep: if it fires, detection is instant; if it is deaf, the
# next poll catches the state within WAIT_SLICE. Do not "simplify" this back into one long
# wait, and do not treat a slice expiring as a timeout — that is the normal case.
set -u

PANE="${1:?usage: herdr-watch-terminal.sh <pane_id> [debounce_s] [max_s] [start_max_s] [wait_slice_s]}"
DEBOUNCE="${2:-3}"
MAX="${3:-3600}"
START_MAX="${4:-120}"
WAIT_SLICE="${5:-60}"

# SELF-CAFFEINATE (investigated 2026-08-04, after five watchers died in one session).
# macOS renews its sleep-prevention assertion in ~300s windows tied to SESSION ACTIVITY.
# This watcher is deliberately silent for up to MAX seconds, so it renews nothing: the
# machine takes an idle sleep and the watch dies mid-run. Measured: a watch started 09:19
# died to a system sleep at 09:50, 30 minutes into a 35-minute cap; every watch that
# COMPLETED ran entirely inside an awake window. A dead watcher is worse than a slow one —
# it reads as a quiet agent rather than a broken signal.
#
# `-i` blocks IDLE sleep only: the display still sleeps, and closing the lid still sleeps
# the machine. `exec` replaces this process so the exit contract above is preserved
# EXACTLY — caffeinate propagates the child's exit status, so 0/1/2 still mean what the
# header says. HERDR_WATCH_NO_CAFFEINATE=1 opts out. Linux equivalent, if this harness ever
# moves: systemd-inhibit --what=idle.
#
# STOPPING A WATCH — killing the `caffeinate` PID is NOT enough (AST-032, and this script is
# the harness's own example of it). Verified 2026-08-05: with the wrapper live, `kill <pid
# of caffeinate>` left the wrapped shell running and orphaned, still polling herdr. The
# whole watch shares ONE process group, so signal the GROUP and then CHECK:
#
#   pgid=$(ps -o pgid= -p <watch-pid> | tr -d ' ')
#   kill -TERM -"$pgid"          # leading '-' targets the GROUP, not a pid
#   pgrep -g "$pgid" >/dev/null && echo SURVIVORS || echo clean
#
# Use `pgrep`, NOT `ps | grep herdr-watch-terminal`: that grep matches its own command line,
# so it can never return empty — a check incapable of passing, which is the same defect
# class as a signal incapable of failing. (`grep '[h]erdr-watch-terminal'` also works; the
# brackets stop the pattern matching itself, so do not "simplify" them away.)
#
# Check the PGID before killing it: if the watch was launched inline from a caller's shell,
# the group may contain THAT SHELL too. A watch you intend to kill by group should be
# started in its own group.
#
# A cleanup command that RAN is not a cleanup that WORKED: always re-check for survivors.
if [ -z "${HERDR_WATCH_CAFFEINATED:-}" ] && [ -z "${HERDR_WATCH_NO_CAFFEINATE:-}" ] \
   && command -v caffeinate >/dev/null 2>&1; then
  export HERDR_WATCH_CAFFEINATED=1
  exec caffeinate -i -- "$0" "$@"
fi

status_from_json() {
  python3 -c "import json,sys; print(json.load(sys.stdin)['result']['agent']['agent_status'])" 2>/dev/null
}

read_status() {
  herdr agent get "$PANE" 2>/dev/null | status_from_json || echo unknown
}

# Start guard: require an observed working state for this turn. If a very fast task
# completes before Herdr exposes working, return NO_START rather than falsely blessing a
# stale terminal state; Thomas then reads the pane and judges the artifact.
# Sliced for the same reason as the main loop (AST-107): a deaf 120s wait would report
# NO_START on a builder that started normally. The wait catches the transition; the poll
# catches the state the wait missed.
start_deadline=$(( $(date +%s) + START_MAX ))
saw_working=0
while [ "$(date +%s)" -lt "$start_deadline" ]; do
  left=$(( start_deadline - $(date +%s) ))
  slice="$WAIT_SLICE"
  [ "$left" -lt "$slice" ] && slice="$left"
  [ "$slice" -le 0 ] && break
  herdr agent wait "$PANE" --until working --timeout "$((slice * 1000))" >/dev/null 2>&1 || true
  if [ "$(read_status)" = "working" ]; then
    saw_working=1
    break
  fi
done
if [ "$saw_working" -eq 0 ]; then
  echo "NO_START pane=$PANE"
  exit 2
fi

started_at="$(date +%s)"
while :; do
  now="$(date +%s)"
  elapsed=$((now - started_at))
  remaining=$((MAX - elapsed))
  if [ "$remaining" -le 0 ]; then
    echo "TIMEOUT after ${MAX}s pane=$PANE (last=$(read_status))"
    exit 1
  fi

  slice="$WAIT_SLICE"
  [ "$remaining" -lt "$slice" ] && slice="$remaining"

  # Interruptible sleep, not the verdict. A slice that expires without firing is normal:
  # either nothing happened, or the waiter went deaf (AST-107). Either way, re-poll.
  herdr agent wait "$PANE" \
    --until done --until blocked --until idle \
    --timeout "$((slice * 1000))" >/dev/null 2>&1 || true

  first="$(read_status)"

  case "$first" in
    done|blocked|idle)
      sleep "$DEBOUNCE"
      second="$(read_status)"
      if [ "$second" = "$first" ]; then
        echo "TERMINAL:$first pane=$PANE"
        exit 0
      fi
      ;;
    *) ;;
  esac
done
