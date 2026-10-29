#!/usr/bin/env bash
# pre-push-ticket-done.sh — git pre-push hook: a push that lands a ticket's merge on the base
# branch needs that ticket's ticket-done stamp.
#
#   Wire it as the project's pre-push hook (in the `core.hooksPath` directory if one is set,
#   else .git/hooks/pre-push), or call it from the existing pre-push:
#       scripts/pre-push-ticket-done.sh "$@"
#
# WHY A GIT HOOK, AFTER TWO RELEASES OF THE SAME RULE IN hook-git-guard.py. The guard reads the
# command line a session is about to run, and it declares itself a lint: it stays silent on any
# line holding a heredoc, a `$(...)` or a `( ... )`. Measured downstream on one day's log, that
# was 84 of 319 commands (26%), and the one push it should have stopped went through inside a
# heredoc: a ticket's merge reached origin/main about a minute before its stamp existed. A
# command line is a guess at what will be pushed. Git hands this hook the exact refs and SHAs,
# for every push, however it was typed, by any runtime or by a person. The guard keeps the rule
# as an early reminder; this is the gate.
#
# WHAT IT CHECKS, the same rule as hook-git-guard.py's push check, kept in step by hand: every
# FIRST-PARENT merge commit in the pushed range whose subject leads with a ticket id (`Merge
# ABC-12: …`, or git's default naming a builder branch) needs `<stamp root>/harness-ticket-done/
# <id>`, written by scripts/ticket-done.sh. The stamp root is the repository's git common dir
# (`astraler-stamps/`), the same default ticket-done.sh writes, and HARNESS_STAMP_ROOT overrides
# both. Squash merges carry no merge commit and are not seen, as before. First-parent only, as
# the guard since 4.0.3: a merge INSIDE a builder branch (main synced in, another branch pulled
# in) is not a merge onto the base and owes no stamp.
#
# A MERGE THAT CLOSES NO TICKET OWES NO STAMP (5.0.4 in the guard, 5.0.6 here). A Shaper lands
# its spec, QA plan and records under `shaper/<epic>` while the epic stays open by design, and
# ticket-done.sh refuses an open ticket, so this hook asked for a stamp nobody could make. 5.0.4
# put the three exemptions in the guard and planted its cases on the guard; this file stayed
# byte-identical and `git push` kept refusing (inception, 2026-10-29). Exempt, in step with the
# guard: a merge whose dispatch record (`.astraler/state/dispatch-record.json`) gives the id a
# role other than builder; a subject carrying `shaper/`, `shaper `, `qa/`, `qa:`; a body with a
# `Ticket-done: n/a — <why>` trailer. A Builder's merge with no stamp is refused as before.
#
# Bypassing it takes `git push --no-verify`, which is a person's deliberate act, recorded in
# their shell history, and not something an agent reaches for by accident.
set -uo pipefail

REMOTE="${1:-origin}"
ZERO="0000000000000000000000000000000000000000"

BASE="${BASE_BRANCH:-}"
if [ -z "$BASE" ]; then
  head_ref="$(git symbolic-ref --quiet --short "refs/remotes/$REMOTE/HEAD" 2>/dev/null || true)"
  BASE="${head_ref#"$REMOTE"/}"
fi
BASE="${BASE:-main}"

CD="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
SR="${HARNESS_STAMP_ROOT:-${CD:+$CD/astraler-stamps}}"; SR="${SR:-/tmp}"
STAMPS="$SR/harness-ticket-done"

# The dispatch record, as `<id> <role>` lines; empty when the file or python3 is missing, which
# reads as "builder" below, the refusing side. bash 3.2 (macOS) has no associative arrays.
TOP="$(git rev-parse --show-toplevel 2>/dev/null || true)"
ROLES=""
if [ -n "$TOP" ] && [ -f "$TOP/.astraler/state/dispatch-record.json" ]; then
  ROLES="$(python3 -I -c '
import json, sys
try:
    rec = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(0)
for k, v in rec.items():
    if isinstance(v, dict):
        print(k, str(v.get("role") or ""))
' "$TOP/.astraler/state/dispatch-record.json" 2>/dev/null || true)"
fi
role_of() { printf '%s\n' "$ROLES" | awk -v id="$1" '$1 == id { print $2; exit }'; }

missing=()
while read -r local_ref local_sha remote_ref remote_sha; do
  [ -n "${remote_ref:-}" ] || continue
  [ "$remote_ref" = "refs/heads/$BASE" ] || continue
  [ "$local_sha" = "$ZERO" ] && continue                       # deleting the branch
  if [ "$remote_sha" = "$ZERO" ]; then
    shas="$(git log --merges --first-parent --format=%H "$local_sha" --not --remotes="$REMOTE" 2>/dev/null)"
  else
    shas="$(git log --merges --first-parent --format=%H "$remote_sha..$local_sha" 2>/dev/null)"
  fi
  while IFS= read -r sha; do
    [ -n "$sha" ] || continue
    body="$(git show -s --format=%B "$sha" 2>/dev/null)"
    subject="${body%%$'\n'*}"
    # `Ticket-done: n/a — <why>` declares the merge lands no ticket's work.
    printf '%s\n' "$body" | grep -qiE '^Ticket-done:[[:space:]]*n/a([^A-Za-z0-9]|$)' && continue
    # The branch shape: a Shaper's or QA's merge closes no ticket.
    printf '%s\n' "$subject" | grep -qiE '(^|[^A-Za-z0-9])(shaper|qa)[ /:-]' && continue
    # The FIRST ticket-shaped id is the ticket; later ones are citations (`… (AST-069)`).
    [[ "$subject" =~ ([A-Z][A-Z0-9]*-[0-9]+) ]] || continue
    id="${BASH_REMATCH[1]}"
    role="$(role_of "$id")"
    case "$role" in ""|builder) ;; *) continue ;; esac          # the record says not a Builder's
    [ -e "$STAMPS/$id" ] && continue
    case " ${missing[*]:-} " in *" $id "*) ;; *) missing+=("$id") ;; esac
  done <<< "$shas"
done

if [ "${#missing[@]}" -gt 0 ]; then
  {
    echo "pre-push: REFUSED — this push lands merge(s) for ${missing[*]} on '$BASE' with no ticket-done stamp."
    echo "  For each: scripts/ticket-done.sh <id> --moved \"<ids the write-back promoted, or none>\""
    echo "  It checks the work is on $BASE and the tracker says closed and released, then stamps"
    echo "  $STAMPS/<id>. A ticket is not done before its tracker says so (AST-057, AST-157)."
  } >&2
  exit 1
fi
exit 0
