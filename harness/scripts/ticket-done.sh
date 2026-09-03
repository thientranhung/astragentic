#!/usr/bin/env bash
# ticket-done.sh — the ONE call that closes a ticket's obligations, and the evidence it ran.
#
#   scripts/ticket-done.sh <ticket-id> [--moved "<ids the write-back promoted, or none>"]
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

ID="${1:?usage: ticket-done.sh <ticket-id> [--moved \"<ids or none>\"]}"; shift || true
MOVED=""
while [ $# -gt 0 ]; do case "$1" in --moved) MOVED="${2:-}"; shift 2;; *) echo "ticket-done: unknown argument $1" >&2; exit 2;; esac; done
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
if [ -n "$branch" ]; then
  if git merge-base --is-ancestor "$branch" "refs/heads/$BASE" 2>/dev/null; then merged=yes; notes+=("git: branch $branch is an ancestor of $BASE"); fi
fi
if [ "$merged" = no ]; then
  n="$(git log "refs/heads/$BASE" --format='%s' | grep -ciE "\\b${ID}\\b" || true)"
  if [ "${n:-0}" -gt 0 ]; then merged=yes; notes+=("git: $n commit(s) on $BASE name $ID in the subject (branch gone)"); fi
fi
if [ "$merged" = no ]; then
  echo "ticket-done: STOP — nothing on $BASE carries $ID: no branch is an ancestor and no subject names it. A ticket is not done before its work has landed." >&2; exit 1
fi

# 2. tracker half — the project's plug
TS="$ROOT/.astraler/project/tracker-state.sh"
if [ -x "$TS" ]; then
  line="$("$TS" "$ID" 2>/dev/null | head -1)"
  state="${line%% *}"; assignee="${line#* }"; [ "$assignee" = "$line" ] && assignee="-"
  case "$state" in
    closed|done|Done|DONE|completed|Completed)
      if [ "$assignee" != "-" ] && [ -n "$assignee" ]; then
        echo "ticket-done: STOP — tracker says $ID is $state but still assigned to '$assignee'; release the claim (thomas.md § claim), then re-run." >&2; exit 1
      fi
      notes+=("tracker: $state, unassigned (via tracker-state.sh)") ;;
    "") echo "ticket-done: STOP — tracker-state.sh printed nothing for $ID; the plug must print '<state> <assignee-or-dash>'." >&2; exit 1 ;;
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
if [ -x "$TD" ]; then
  "$TD" "$ID" && notes+=("project plug: ran") || { echo "ticket-done: WARN project plug exited $? for $ID" >&2; rc=1; }
elif [ -e "$TD" ]; then
  echo "ticket-done: STOP — $TD exists but is not executable" >&2; exit 1
else
  notes+=("project plug: none declared (empty socket)")
fi

# 4. evidence — only on a clean run
if [ "$rc" -eq 0 ]; then
  D="${HARNESS_STAMP_ROOT:-/tmp}/harness-ticket-done"; mkdir -p "$D"
  { printf '%s %s base=%s moved=%s\n' "$(date -u +%FT%TZ)" "$ID" "$BASE" "${MOVED:-unreported}"; printf '  %s\n' "${notes[@]}"; } > "$D/$ID"
  [ -n "$MOVED" ] || echo "ticket-done: NOTE — --moved not given; the frontier write-back report is 'unreported' in the stamp (AST-057: none is a report, silence is not)"
  echo "ticket-done: stamped $D/$ID — the git guard now admits pushing $BASE with $ID's merge"
  printf '  %s\n' "${notes[@]}"
else
  echo "ticket-done: NOT stamped (exit $rc)" >&2
fi
exit $rc
