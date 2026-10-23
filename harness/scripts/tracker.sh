#!/usr/bin/env bash
# tracker.sh — one reader for the tracker, asked only at the moments that need it (4.4.0).
#
#   tracker.sh state <ticket-id>   one line: `<state> <assignee-or-dash>`
#   tracker.sh counts              one line: open tickets per status
#
# WHY IT EXISTS. The band refreshed every 30 s and ran `status-line.sh` each time; a project that
# put its tracker counts there queried the tracker on the clock (one downstream plug: `gh issue
# list` every 120 s through its own cache, ≈720 calls a day). A Jira project could not count at
# all: its plugs printed `unreachable -` because only the MCP reached Jira, so the claim check
# and the ticket-done tracker half were skipped on every ticket. `twg` reads Jira from a shell
# (measured 2026-10-24: `workitem get` 1.5 s, a 22-ticket JQL count 5.4 s, both native, no Rovo
# credit), and 5.4 s is longer than the band's 5 s budget, so on the clock it would fail every
# tick. The owner's ruling (2026-10-24): the tracker is read on events, never on an interval, and
# the package calls `twg` only for a project that uses Jira. The callers are the dispatch mod
# (claim check at a brief; counts at session start, after a brief, after a merge, on
# /tracker-refresh), `ticket-done.sh`, and `hook-tracker-status.py`.
#
# WHICH TRACKER. A project plug wins when it exists: `.astraler/project/tracker-state.sh` for
# `state`, `.astraler/project/tracker-status.sh` for `counts` (its first table condensed to one
# line). Otherwise `.astraler/project/tracker` declares one, first word the kind:
#
#   jira <PROJECT-KEY>     read with `twg` (its own login, `~/.config/twg`)
#
# Nothing declared and no plug: exit 3, the empty socket; every caller already handles that.
# `twg` absent, logged out, slow or refusing: `state` prints `unreachable -` (ticket-done stamps
# UNVERIFIED, the mod skips its claim check), `counts` prints nothing and exits 1.
#
# THE STATE TOKEN is one word, because both consumers split the line on whitespace: Jira's
# status NAMES carry spaces (`To Do` read as state `To`, assignee `Do`), so `state` prints the
# status CATEGORY key: `new`, `indeterminate` or `done`. `done` is what ticket-done accepts.
#
# Every call that reaches a tracker leaves one line in /tmp/harness-hook-events.log, so the
# rate is a count, not a claim: `grep -c 'tracker.sh' /tmp/harness-hook-events.log`.
set -uo pipefail

OP="${1:-}"; ID="${2:-}"
case "$OP" in
  state) [ -n "$ID" ] || { echo "usage: tracker.sh state <ticket-id>" >&2; exit 2; } ;;
  counts) ;;
  *) echo "usage: tracker.sh state <ticket-id> | tracker.sh counts" >&2; exit 2 ;;
esac

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"; ROOT="${ROOT:-${CLAUDE_PROJECT_DIR:-$PWD}}"
P="$ROOT/.astraler/project"
TIMEOUT_MS="${TRACKER_TIMEOUT_MS:-20000}"

log() { printf '%s tracker.sh %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> /tmp/harness-hook-events.log 2>/dev/null || true; }

# 1. the project's own plug
if [ "$OP" = state ] && [ -x "$P/tracker-state.sh" ]; then
  out="$("$P/tracker-state.sh" "$ID")"; rc=$?
  log "state $ID via=plug rc=$rc"
  printf '%s\n' "$out"; exit "$rc"
fi
if [ "$OP" = counts ] && [ -x "$P/tracker-status.sh" ]; then
  out="$("$P/tracker-status.sh" 2>/dev/null)"; rc=$?
  log "counts via=plug rc=$rc"
  [ "$rc" -eq 0 ] && [ -n "$out" ] || exit 1
  # A markdown table (header row, separator, values row) becomes `header value · …`; anything
  # else gives its first line.
  printf '%s' "$out" | python3 -c '
import sys
rows = [l.strip() for l in sys.stdin.read().splitlines() if l.strip()]
cells = lambda l: [c.strip() for c in l.strip("|").split("|")]
for i, l in enumerate(rows):
    if l.startswith("|") and i + 2 < len(rows) and set(rows[i + 1].replace("|", "").strip()) <= set("-: "):
        h, v = cells(l), cells(rows[i + 2])
        print(" · ".join("%s %s" % (a, b) for a, b in zip(h, v))); break
else:
    print(rows[0] if rows else "")'
  exit 0
fi

# 2. the declared tracker
KIND=""; KEY=""
[ -f "$P/tracker" ] && read -r KIND KEY _ < <(grep -vE '^\s*(#|$)' "$P/tracker" | head -1)
case "$KIND" in
  "") exit 3 ;;
  jira) ;;
  *) echo "tracker.sh: .astraler/project/tracker declares '$KIND'; the package reads only jira. Write the project plug instead." >&2; exit 3 ;;
esac

if ! command -v twg >/dev/null 2>&1; then
  log "$OP $ID kind=jira rc=no-twg"
  [ "$OP" = state ] && { echo "unreachable -"; exit 0; } || exit 1
fi

if [ "$OP" = state ]; then
  json="$(twg jira workitem get "$ID" -o json --output-summary none --timeout-ms "$TIMEOUT_MS" 2>/dev/null)"; rc=$?
  log "state $ID kind=jira rc=$rc"
  line=""
  [ "$rc" -eq 0 ] && line="$(printf '%s' "$json" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)["data"]
    d = d[0] if isinstance(d, list) else d
    cat = ((d.get("status") or {}).get("statusCategory") or d.get("statusCategory") or {}).get("key")
    who = (d.get("assignee") or {}).get("accountId") or "-"
    print("%s %s" % (cat, who) if cat else "")
except Exception:
    print("")' 2>/dev/null)"
  [ -n "$line" ] && echo "$line" || echo "unreachable -"
  exit 0
fi

[ -n "$KEY" ] || { echo "tracker.sh: .astraler/project/tracker says 'jira' with no project key (write 'jira <KEY>')" >&2; exit 1; }
json="$(twg jira workitem query --jql "project = \"$KEY\" AND statusCategory != Done" --limit 500 \
  -o json --output-summary none --timeout-ms "$TIMEOUT_MS" 2>/dev/null)"; rc=$?
log "counts kind=jira key=$KEY rc=$rc"
[ "$rc" -eq 0 ] || exit 1
printf '%s' "$json" | python3 -c '
import json, sys
from collections import Counter
try:
    items = json.load(sys.stdin)["data"]["issues"]
except Exception:
    sys.exit(1)
c = Counter(((i.get("status") or {}).get("name") or "?") for i in items)
print("open %d · " % len(items) + " · ".join("%s %d" % (k, n) for k, n in sorted(c.items(), key=lambda kv: -kv[1])))'
