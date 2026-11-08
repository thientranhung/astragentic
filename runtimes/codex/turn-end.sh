#!/bin/bash
# Astragentic Codex TURN-END bell. Installed at .codex/astragentic/turn-end.sh and
# named in a dispatched worker's argv as
#   -c 'notify=["bash","<abs>/turn-end.sh","<DISPATCH_ID>","<THOMAS_UUID>"[,"<unix:///endpoint>"]]'
# Codex appends its JSON payload as the last argument when the worker's turn ends.
# The script queues one short TURN-END line to the coordinator and exits. It is a
# received signal, not completion: Thomas still reads the record and artifact.
# Rules: no --resume, one message per (dispatch, worker, turn), silent when the
# coordinator's pause marker exists, never a retry loop.
set -u
usage() { echo "turn-end.sh DISPATCH_ID THOMAS_UUID [unix:///endpoint] <codex-json>" >&2; exit 2; }
[ "$#" -ge 3 ] || usage
PAYLOAD="${*: -1}"
DISPATCH="$1"; THOMAS="$2"; ENDPOINT=""
[ "$#" -ge 4 ] && ENDPOINT="$3"
STATE="${ASTRAGENTIC_BELL_STATE:-$PWD/.astraler/codex/state}"
LOG="$STATE/turn-end.log"
mkdir -p "$STATE" 2>/dev/null || exit 0

log() { printf '%s\t%s\t%s\t%s\n' "$(date +%s.%N 2>/dev/null || date +%s)" "$DISPATCH" "$1" "$2" >> "$LOG"; }

# Parse once; print "type thread turn last" or nothing.
read -r KIND WORKER TURN LAST <<< "$(printf '%s' "$PAYLOAD" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
last = (d.get("last-assistant-message") or "").split("\n")[0][:60].replace("\t", " ")
print(d.get("type", ""), d.get("thread-id", ""), d.get("turn-id", ""), last or "-")
' 2>/dev/null)" || true

[ "${KIND:-}" = "agent-turn-complete" ] || { log skip "type=${KIND:-unparsed}"; exit 0; }

UUID_RE='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
NIL='00000000-0000-0000-0000-000000000000'
for id in "$THOMAS" "$WORKER" "$TURN"; do
  [[ "$id" =~ $UUID_RE && "$id" != "$NIL" ]] || { log skip "bad-uuid=$id"; exit 0; }
done
case "$ENDPOINT" in ''|unix:///*) ;; *) log skip "bad-endpoint=$ENDPOINT"; exit 0 ;; esac

# Owner or Thomas creates this marker before pausing the coordinator; the bell cannot infer a pause.
[ -e "$STATE/bell-off" ] && { log skip "bell-off"; exit 0; }

KEY="$DISPATCH $WORKER $TURN"
SEEN="$STATE/turn-end.seen"
touch "$SEEN"
grep -qxF -- "$KEY" "$SEEN" && { log skip "duplicate turn=$TURN"; exit 0; }
printf '%s\n' "$KEY" >> "$SEEN"

MSG="TURN-END dispatch=$DISPATCH worker=$WORKER turn=$TURN last=$LAST"
ARGS=(queue --thread "$THOMAS" --message "$MSG")
[ -n "$ENDPOINT" ] && ARGS=(queue --remote "$ENDPOINT" --thread "$THOMAS" --message "$MSG")
OUT="$(codex "${ARGS[@]}" 2>&1)"; RC=$?
log "sent rc=$RC turn=$TURN" "$(printf '%s' "$OUT" | tr '\n\t' '  ' | cut -c1-200)"
exit 0
