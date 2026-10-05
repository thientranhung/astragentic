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
# WHAT IT CHECKS, the same as the guard always did: every merge commit in the pushed range whose
# subject leads with a ticket id (`Merge ABC-12: …`, or git's default naming a builder branch)
# needs `<stamp root>/harness-ticket-done/<id>`, written by scripts/ticket-done.sh. The stamp
# root is the repository's git common dir (`astraler-stamps/`), the same default ticket-done.sh
# writes, and HARNESS_STAMP_ROOT overrides both. Squash merges carry no merge commit and are not
# seen, as before.
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

missing=()
while read -r local_ref local_sha remote_ref remote_sha; do
  [ -n "${remote_ref:-}" ] || continue
  [ "$remote_ref" = "refs/heads/$BASE" ] || continue
  [ "$local_sha" = "$ZERO" ] && continue                       # deleting the branch
  if [ "$remote_sha" = "$ZERO" ]; then
    subjects="$(git log --merges --format=%s "$local_sha" --not --remotes="$REMOTE" 2>/dev/null)"
  else
    subjects="$(git log --merges --format=%s "$remote_sha..$local_sha" 2>/dev/null)"
  fi
  while IFS= read -r subject; do
    # The FIRST ticket-shaped id is the ticket; later ones are citations (`… (AST-069)`).
    [[ "$subject" =~ ([A-Z][A-Z0-9]*-[0-9]+) ]] || continue
    id="${BASH_REMATCH[1]}"
    [ -e "$STAMPS/$id" ] && continue
    case " ${missing[*]:-} " in *" $id "*) ;; *) missing+=("$id") ;; esac
  done <<< "$subjects"
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
