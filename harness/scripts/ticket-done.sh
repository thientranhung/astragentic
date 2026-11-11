#!/usr/bin/env bash
# ticket-done.sh — the ONE call that closes a ticket's obligations, and the evidence it ran.
#
#   scripts/ticket-done.sh <ticket-id> [--moved "<ids the write-back promoted, or none>"]
#                                      [--late "<why the merge was not declared in time>"]
#
# THE MOMENT. A ticket is done when its work is on the base branch AND the tracker says so.
# Everything owed at that moment — the frontier write-back, the assignee released, the ledger
# line, the project's own after-close step — was until 2.8 a list of remembered instructions in
# thomas.md, and a live project measured the split exactly: every ticket merged-and-pushed in
# one turn was written back, every ticket merged-and-held for a gate was not (AST-057). Nothing
# reported the omission, so nothing could tell it had been skipped.
#
# THIS IS A SOCKET. The harness knows the git half and asks the project for the rest:
#   1. git half        — the ticket's branch tip is an ancestor of the base, or the branch is
#                        gone and a commit on the base names the ticket in its SUBJECT. By
#                        ancestry first, never by grepping a subject alone (AST-133).
#   2. tracker half    — `.astraler/project/tracker-state.sh <id>` prints one line:
#                        `<state> <assignee-or-dash>` (e.g. `closed -`). How to read the
#                        tracker from a shell is the project's answer (gh, a Jira CLI, an API
#                        token); the harness only checks the answer says closed and unassigned.
#   3. project's part  — `.astraler/project/ticket-done.sh <id>` for whatever this project owes
#                        at close: a deploy trigger, a changelog line, a notification.
#   4. evidence        — a stamp under /tmp/harness-ticket-done/<id>. hook-git-guard.py refuses
#                        `git push` of the base branch while a merge commit in the pushed range
#                        names a ticket without one. Same pattern as the worktree stamp.
#
# An absent plug is reported as an EMPTY SOCKET, never as clean. Step 2 absent means the
# tracker half is unverified — stated in the stamp, and the guard admits the push with that
# stated, because refusing every project that has not yet written the plug would block the
# upgrade that asks for it. Step 2 present and wrong REFUSES: the ticket is not done.
set -uo pipefail

# --late "<reason>" (6.1.8): A MERGE ALREADY ON THE REMOTE CANNOT BE AMENDED. One downstream
# ticket was merged GitHub-side with no `Ledger:` line; the project's plug refuses that merge,
# the commit was on origin, and nothing could ever stamp it (1 of 12 GitHub-side ticket merges
# on that project). `--late` declares it after the fact. Admitted only when every commit naming the ticket is already on `origin/<base>`:
# while one is still local it can be amended, and the fix is the amend. The tracker half is
# asked as always. The plug runs with TICKET_DONE_LATE=<reason> in its environment (unset on
# every other run, whatever the caller's shell held) and still decides: a plug that checks a
# trailer relaxes that one check when the variable is set, and keeps the rest. The reason goes
# in the stamp.
ID="${1:?usage: ticket-done.sh <ticket-id> [--moved \"<ids or none>\"] [--late \"<reason>\"]}"; shift || true
MOVED=""; LATE=""
while [ $# -gt 0 ]; do case "$1" in
  --moved) MOVED="${2:-}"; shift 2;;
  --late) LATE="$(printf '%s' "${2:-}" | tr '\r\n' '  ')"; [ -n "${LATE// /}" ] || { echo "ticket-done: --late needs a reason" >&2; exit 2; }; shift 2;;
  *) echo "ticket-done: unknown argument $1" >&2; exit 2;;
esac; done
[[ "$ID" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ ]] || { echo "ticket-done: '$ID' is not a ticket id (PREFIX-number)" >&2; exit 2; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"; ROOT="${ROOT:-${CLAUDE_PROJECT_DIR:-$PWD}}"
BASE="${BASE_BRANCH:-$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')}"; BASE="${BASE:-main}"
git rev-parse --verify --quiet "refs/heads/$BASE" >/dev/null || { echo "ticket-done: base branch '$BASE' not found (set BASE_BRANCH)" >&2; exit 1; }
rc=0; notes=()
echo "ticket-done: $ID on base $BASE"

# 1. git half — ancestry first
slug="$(printf '%s' "$ID" | tr '[:upper:]' '[:lower:]')"
branch="$(git branch --format='%(refname:short)' | grep -iE "(^|/)[^/]*${slug}([^0-9]|$)" | head -1 || true)"
merged=no
# Ancestry alone also holds for a branch that never had a commit of its own: its tip is a base
# commit. Measured 2026-10-05, a ticket whose Builder committed nothing was stamped done. So the
# tip must be the branch's own work: different from the commit it started at, where the
# dispatch record kept one, and otherwise off the base's first-parent line, where a --no-ff
# merge leaves it. A fast-forward lands on that line too and falls through to the subject test.
if [ -n "$branch" ]; then
  if git merge-base --is-ancestor "$branch" "refs/heads/$BASE" 2>/dev/null; then
    tip="$(git rev-parse "$branch")"
    start="$(python3 -c 'import json,sys
try: print(json.load(open(sys.argv[1])).get(sys.argv[2], {}).get("start_sha", ""))
except Exception: print("")' "$ROOT/.astraler/state/dispatch-record.json" "$ID" 2>/dev/null || true)"
    if [ -n "$start" ]; then
      [ "$tip" != "$start" ] && own=yes || own=no
    # Counted, never `grep -q`: with pipefail, -q exits on the first match and rev-list can take
    # SIGPIPE while still writing, so the pipeline fails exactly when the tip is the newest base
    # commit (the empty-branch case) and the branch read as merged. Flaked once in selftest.
    elif [ "$(git rev-list --first-parent "refs/heads/$BASE" | grep -cx "$tip")" -gt 0 ]; then
      own=no
    else
      own=yes
    fi
    if [ "$own" = yes ]; then merged=yes; notes+=("git: branch $branch is an ancestor of $BASE"); fi
  fi
fi
if [ "$merged" = no ]; then
  n="$(git log "refs/heads/$BASE" --format='%s' | grep -ciE "\\b${ID}\\b" || true)"
  if [ "${n:-0}" -gt 0 ]; then merged=yes; notes+=("git: $n commit(s) on $BASE name $ID in the subject (branch gone)"); fi
fi
if [ "$merged" = no ]; then
  echo "ticket-done: STOP — nothing on $BASE carries $ID: no branch is an ancestor and no subject names it. A ticket is not done before its work has landed." >&2; exit 1
fi

# Is the ticket's merge beyond amending? Yes when origin/<base> carries the work (the branch tip
# as an ancestor, or a subject naming the id) and no commit naming the id is still local-only.
# Read from the remote-tracking ref as it stands, no fetch: a stale ref errs on the refusing side.
# Counted with `grep -c`, never `-q`, for the pipefail reason above.
UP="refs/remotes/origin/$BASE"
on_origin=no
if git rev-parse --verify --quiet "$UP" >/dev/null; then
  local_only="$(git log "$UP..refs/heads/$BASE" --format='%s' | grep -ciE "\\b${ID}\\b" || true)"
  if [ "${local_only:-0}" -eq 0 ]; then
    if [ -n "$branch" ] && git merge-base --is-ancestor "$branch" "$UP" 2>/dev/null; then on_origin=yes
    elif [ "$(git log "$UP" --format='%s' | grep -ciE "\\b${ID}\\b" || true)" -gt 0 ]; then on_origin=yes; fi
  fi
fi
if [ -n "$LATE" ]; then
  if [ "$on_origin" != yes ]; then
    echo "ticket-done: STOP — --late is for a merge already on origin/$BASE, which cannot be amended. $ID's is not there by this checkout's origin/$BASE (\`git fetch origin\` if that is stale). A merge still local is fixed by amending it; then run without --late." >&2; exit 1
  fi
  notes+=("late: $LATE (the merge was already on origin/$BASE; declared after the fact)")
fi

# 2. tracker half — the project's plug
TS="$ROOT/.astraler/project/tracker-state.sh"
# 4.4.0: with no plug, a project that declares its tracker (`.astraler/project/tracker`, e.g.
# `jira IN`) is read by the package's own reader, which prints the same line.
READER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tracker.sh"
if [ ! -e "$TS" ] && [ -f "$ROOT/.astraler/project/tracker" ] && [ -f "$READER" ]; then
  TS="$READER"
fi
if [ -x "$TS" ] || [ "$TS" = "$READER" ]; then
  if [ "$TS" = "$READER" ]; then line="$(bash "$READER" state "$ID" 2>/dev/null | head -1)"
  else line="$("$TS" "$ID" 2>/dev/null | head -1)"; fi
  state="${line%% *}"; assignee="${line#* }"; [ "$assignee" = "$line" ] && assignee="-"
  case "$state" in
    closed|done|Done|DONE|completed|Completed)
      if [ "$assignee" != "-" ] && [ -n "$assignee" ]; then
        echo "ticket-done: STOP — tracker says $ID is $state but still assigned to '$assignee'; release the claim (thomas.md § claim), then re-run." >&2; exit 1
      fi
      notes+=("tracker: $state, unassigned (via tracker-state.sh)") ;;
    "") echo "ticket-done: STOP — tracker-state.sh printed nothing for $ID; the plug must print '<state> <assignee-or-dash>'." >&2; exit 1 ;;
    # ADAPT-HARNESS asks a project whose tracker no shell can reach (an MCP-only Jira or Linear)
    # to write a plug that prints `unreachable -`. Until 3.2.1 this branch refused that answer
    # as "not closed", so every ticket on such a project was undone and every base push was
    # blocked — a project measured it and said so. Unreachable is the empty socket spelled out:
    # the tracker half is unverified, said in the stamp, and the push is admitted with that said.
    unreachable|Unreachable|UNREACHABLE)
      notes+=("tracker: UNVERIFIED — tracker-state.sh reports the tracker unreachable from a shell (ADAPT-HARNESS §3); the write-back is on the agent's word")
      echo "ticket-done: NOTE — tracker half unverified: the plug reports the tracker unreachable from a shell. Record the write-back in the handback." ;;
    *)  echo "ticket-done: STOP — tracker says $ID is '$state' (assignee '$assignee'). The write-back has not landed: move it to the done state and release the assignee, then re-run." >&2; exit 1 ;;
  esac
elif [ -e "$TS" ]; then
  echo "ticket-done: STOP — $TS exists but is not executable (chmod +x it)" >&2; exit 1
else
  notes+=("tracker: UNVERIFIED — no plug at .astraler/project/tracker-state.sh (empty socket; ADAPT-HARNESS §3)")
  echo "ticket-done: NOTE — tracker half unverified: no .astraler/project/tracker-state.sh. The write-back is on your word alone until the project writes that plug."
fi

# 3. the project's own after-close step
TD="$ROOT/.astraler/project/ticket-done.sh"
# Set or cleared on every run: a value inherited from the caller's shell is not a declaration.
if [ -n "$LATE" ]; then export TICKET_DONE_LATE="$LATE"; else unset TICKET_DONE_LATE; fi
if [ -x "$TD" ]; then
  plug_out="$("$TD" "$ID" 2>&1 | tee /dev/stderr | tail -1)"; plug_rc=${PIPESTATUS[0]}
  if [ "$plug_rc" -eq 0 ]; then notes+=("project plug: ran — ${plug_out:-(printed nothing)}")   # its last line is the evidence
  else echo "ticket-done: WARN project plug exited $plug_rc for $ID" >&2; rc=1; fi
elif [ -e "$TD" ]; then
  echo "ticket-done: STOP — $TD exists but is not executable" >&2; exit 1
else
  notes+=("project plug: none declared (empty socket)")
fi

# 4. evidence — only on a clean run
if [ "$rc" -eq 0 ]; then
  # Inside the repository's git dir, not /tmp: a reboot emptied /tmp and every finished ticket
  # read as unfinished to the push guard (measured downstream: 0 stamps after a restart). The
  # common dir is shared by every worktree, survives a reboot, and is never committed.
  CD="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
  SR="${HARNESS_STAMP_ROOT:-${CD:+$CD/astraler-stamps}}"; SR="${SR:-/tmp}"
  D="$SR/harness-ticket-done"; mkdir -p "$D"
  { printf '%s %s base=%s moved=%s\n' "$(date -u +%FT%TZ)" "$ID" "$BASE" "${MOVED:-unreported}"; printf '  %s\n' "${notes[@]}"; } > "$D/$ID"
  [ -n "$MOVED" ] || echo "ticket-done: NOTE — --moved not given; the frontier write-back report is 'unreported' in the stamp (AST-057: none is a report, silence is not)"
  echo "ticket-done: stamped $D/$ID — the git guard now admits pushing $BASE with $ID's merge"
  printf '  %s\n' "${notes[@]}"
else
  echo "ticket-done: NOT stamped (exit $rc)" >&2
  if [ -z "$LATE" ] && [ "$on_origin" = yes ]; then
    echo "ticket-done: $ID's merge is already on origin/$BASE and cannot be amended. If that is why the plug refused: \`ticket-done.sh $ID --late \"<reason>\"\` (the plug must honour TICKET_DONE_LATE)." >&2
  fi
fi
exit $rc
