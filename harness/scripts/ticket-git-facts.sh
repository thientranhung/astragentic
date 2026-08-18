#!/usr/bin/env bash
# ticket-git-facts.sh — emit what GIT knows about each ticket, as evidence.
#
# This is one HALF of tracker reconciliation. It never touches the tracker and it
# never decides anything: it reports facts. The other half (tracker state) is
# pulled by the agent through the tracker's own read tools, and the join is owned
# by .claude/skills/reconcile-tracker/SKILL.md.
#
# WHY GIT IS THE ORACLE. The tracker records what was SUPPOSED to happen — it is a
# claim. Git records what DID happen — it is evidence. Checking the tracker against
# itself detects nothing, because a wrong state is perfectly consistent with
# itself; that is the same defect class as a test comparing a constant to itself,
# or a parity denominator derived from the thing it measures. An oracle must be
# independent of what it measures.
#
# MATCHING IS BY COMMIT SUBJECT, NEVER THE BODY. A live project measured a body
# grep returning commits that only cited a ticket in a handback; subject-only
# matching returned exactly the genuine set. This relies on a real, consistent
# convention in the commit history — the ticket id appears in the subject line,
# e.g. `feat(scope): summary (TRA-176)` or `docs(TRA-159): handback`.
#
# THE KEY IS STILL NOT EXACT, WHICH IS WHY NOTHING HERE WRITES. A commit naming
# a ticket is not proof the ticket is complete — a partial fix, a revert, or a
# forward-citation all produce a hit. Auto-closing on this signal would mark
# unfinished work done, and a tracker that is wrong AND tidy is trusted, which is
# strictly worse than one that is wrong and visibly messy.
#
# Usage:
#   TICKET_PREFIX=TRA scripts/ticket-git-facts.sh              # every ticket named on base
#   TICKET_PREFIX=TRA scripts/ticket-git-facts.sh TRA-159 TRA-84  # only these
#
# Output: TSV with a header. Columns:
#   ticket            the id
#   subject_commits   commits on the base branch whose SUBJECT names it
#   newest_subject    subject of the most recent such commit ("-" if none)
#   local_branch      a local branch whose name contains the id, lowercased
#   unmerged_commits  commits on that branch not on base ("-" if no branch)
#   worktree          a checked-out worktree for that branch
set -uo pipefail

BASE="${BASE_BRANCH:-main}"
# No default on purpose. A bare [A-Z]+-[0-9]+ sweep also catches ADR ids, spec
# ids and any other kebab-tagged history the repo carries as noise that is not
# a tracker ticket — a live project's first run returned a third noise on
# exactly this mistake. Guessing a prefix produces a confident wrong answer;
# an unset value is a STOP.
PREFIX="${TICKET_PREFIX:?TICKET_PREFIX must be set to the tracker prefix this project uses, e.g. TRA}"
# A literal prefix only — no regex metacharacters, since PREFIX is interpolated
# straight into grep -E patterns below. Rejects the unset-but-truthy footgun too
# (a prefix of "." or "*" would match everything).
case "$PREFIX" in
  [A-Z]*) [[ "$PREFIX" =~ ^[A-Z][A-Z0-9]*$ ]] || { echo "ticket-git-facts: TICKET_PREFIX must be letters/digits only, got '$PREFIX'" >&2; exit 1; } ;;
  *) echo "ticket-git-facts: TICKET_PREFIX must start with an uppercase letter, got '$PREFIX'" >&2; exit 1 ;;
esac
cd "$(git rev-parse --show-toplevel)" || exit 1

if ! git rev-parse --verify --quiet "$BASE" >/dev/null; then
  echo "ticket-git-facts: base branch '$BASE' does not exist" >&2
  exit 1
fi

# Ticket ids: from argv, else every id named in a subject on the base branch.
#
# NOT `mapfile`. macOS ships bash 3.2 (2007, a GPLv3 licensing decision) which
# has no `mapfile` and no `readarray` — a live project's first real run died on
# this with `tickets[@]: unbound variable`, a message naming the symptom and
# not the cause. `while read` is portable to both.
tickets=""
if [ "$#" -gt 0 ]; then
  # Explicit ids still get validated against PREFIX — a caller passing an id
  # from another namespace (an ADR id, a typo) must not be silently treated
  # as a tracker ticket and joined against git as if it were one.
  for arg in "$@"; do
    [[ "$arg" =~ ^${PREFIX}-[0-9]+$ ]] || {
      echo "ticket-git-facts: '$arg' does not match ${PREFIX}-<number>, refusing to guess" >&2
      exit 1
    }
  done
  tickets="$*"
else
  tickets=$(
    git log "$BASE" --format='%s' \
      | grep -oE "${PREFIX}-[0-9]+" \
      | sort -u -t- -k2 -n
  )
fi

if [ -z "$tickets" ]; then
  echo "ticket-git-facts: no ticket ids found on '$BASE' and none given" >&2
  exit 1
fi

printf 'ticket\tsubject_commits\tnewest_subject\tlocal_branch\tunmerged_commits\tworktree\n'

for t in $tickets; do
  # \b so a shorter id never matches inside a longer one.
  n=$(git log "$BASE" --format='%s' | grep -cE "${t}\b" || true)

  if [ "$n" -gt 0 ]; then
    newest=$(git log "$BASE" --format='%s' | grep -E "${t}\b" | head -1)
  else
    newest="-"
  fi

  slug=$(printf '%s' "$t" | tr '[:upper:]' '[:lower:]')
  branch=$(git branch --format='%(refname:short)' | grep -iE "(^|/)[^/]*${slug}([^0-9]|$)" | head -1)
  branch=${branch:-"-"}

  if [ "$branch" != "-" ]; then
    unmerged=$(git rev-list --count "${BASE}..${branch}" 2>/dev/null || echo "?")
    wt=$(git worktree list --porcelain \
         | awk -v b="refs/heads/$branch" '/^worktree /{p=$2} /^branch /{if($2==b) print p}' \
         | head -1)
    wt=${wt:-"-"}
  else
    unmerged="-"
    wt="-"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$t" "$n" "$newest" "$branch" "$unmerged" "$wt"
done
