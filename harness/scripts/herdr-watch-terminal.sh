#!/bin/bash
# herdr-watch-terminal.sh <pane_id> [debounce_s] [max_s] [start_max_s]
#
# Herdr watcher for a newly submitted turn (floor 0.8.0). Exit contract:
#   0 + TERMINAL:<done|blocked|idle>
#   1 + TIMEOUT
#   2 + NO_START
#
# Native `herdr agent wait` supports repeated --until values with OR semantics. The
# watcher still keeps the proven safety floors:
# - stale-task start guard: a previous idle/done cannot complete a new dispatch;
# - terminal flicker debounce: require the same settled state twice;
# - blocked is a wake-up state for Thomas, not a failure;
# - status is a bell, never proof that the artifact is correct;
# - the watch holds its OWN idle-sleep assertion (see SELF-CAFFEINATE below).
set -u

PANE="${1:?usage: herdr-watch-terminal.sh <pane_id> [debounce_s] [max_s] [start_max_s]}"
DEBOUNCE="${2:-3}"
MAX="${3:-3600}"
START_MAX="${4:-120}"

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
# STOPPING A WATCH — killing the `caffeinate` PID is NOT enough (FW-032, and this script is
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
if ! herdr agent wait "$PANE" --until working --timeout "$((START_MAX * 1000))" >/dev/null 2>&1; then
  echo "NO_START"
  exit 2
fi

started_at="$(date +%s)"
while :; do
  now="$(date +%s)"
  elapsed=$((now - started_at))
  remaining=$((MAX - elapsed))
  if [ "$remaining" -le 0 ]; then
    echo "TIMEOUT after ${MAX}s (last=$(read_status))"
    exit 1
  fi

  wait_json="$(
    herdr agent wait "$PANE" \
      --until done --until blocked --until idle \
      --timeout "$((remaining * 1000))" 2>/dev/null
  )" || {
    echo "TIMEOUT after ${MAX}s (last=$(read_status))"
    exit 1
  }
  first="$(printf '%s' "$wait_json" | status_from_json || echo unknown)"

  case "$first" in
    done|blocked|idle)
      sleep "$DEBOUNCE"
      second="$(read_status)"
      if [ "$second" = "$first" ]; then
        echo "TERMINAL:$first"
        exit 0
      fi
      ;;
    *) ;;
  esac
done
