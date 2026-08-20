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
# e.g. `feat(scope): summary (TRA-124)` or `docs(TRA-130): handback`.
#
# THE KEY IS STILL NOT EXACT, WHICH IS WHY NOTHING HERE WRITES. A commit naming
# a ticket is not proof the ticket is complete — a partial fix, a revert, or a
# forward-citation all produce a hit. Auto-closing on this signal would mark
# unfinished work done, and a tracker that is wrong AND tidy is trusted, which is
# strictly worse than one that is wrong and visibly messy.
#
# Usage:
#   TICKET_PREFIX=TRA scripts/ticket-git-facts.sh              # every ticket named on base
#   TICKET_PREFIX=TRA scripts/ticket-git-facts.sh TRA-130 TRA-126  # only these
#
# Output: TSV with a header. Columns:
#   ticket            the id
#   subject_commits   commits on the base branch whose SUBJECT names it
#   newest_subject    subject of the most recent such commit ("-" if none)
#   local_branch      a local branch whose name contains the id, lowercased
#   unmerged_commits  commits on that branch not on base ("-" if no branch)
#   worktree          a checked-out worktree for that branch
set -uo pipefail

# No default on TICKET_PREFIX on purpose. A bare [A-Z]+-[0-9]+ sweep also
# catches ADR ids, spec ids and any other kebab-tagged history the repo
# carries as noise that is not a tracker ticket — a live project's first run
# returned a third noise on exactly this mistake. Guessing a prefix produces
# a confident wrong answer; an unset value is a STOP.
PREFIX="${TICKET_PREFIX:?TICKET_PREFIX must be set to the tracker prefix this project uses, e.g. TRA}"
# A literal prefix only — no regex metacharacters, since PREFIX is interpolated
# straight into grep -E patterns below. Rejects the unset-but-truthy footgun too
# (a prefix of "." or "*" would match everything).
case "$PREFIX" in
  [A-Z]*) [[ "$PREFIX" =~ ^[A-Z][A-Z0-9]*$ ]] || { echo "ticket-git-facts: TICKET_PREFIX must be letters/digits only, got '$PREFIX'" >&2; exit 1; } ;;
  *) echo "ticket-git-facts: TICKET_PREFIX must start with an uppercase letter, got '$PREFIX'" >&2; exit 1 ;;
esac
cd "$(git rev-parse --show-toplevel)" || exit 1

# BASE_BRANCH does default, unlike TICKET_PREFIX: origin's default branch is
# a real fact this repo already knows, not a guess across an open namespace.
# A live project on `master` measured the old hardcoded `main` failing its
# very first run — auto-detect first, and "main" is the last resort only
# when origin/HEAD is not set (a fresh clone before its first fetch).
BASE="${BASE_BRANCH:-$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')}"
BASE="${BASE:-main}"

# Ticket ids: from argv, else every id named in a subject on the base branch.
# Validated against PREFIX before BASE is even checked, so a caller who got
# both wrong sees the more specific error first rather than only ever
# learning about the base branch.
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
fi

# `refs/heads/$BASE` specifically, not bare `$BASE` — a bare name also
# resolves against tags, HEAD and commit hashes, so a repo with a tag
# named the same as a nonexistent branch (measured: a "main" tag on a repo
# whose actual branch was "trunk") would pass this check while every
# following `git log "$BASE"` read the wrong history.
#
# BASE_REF, not bare $BASE, in every read below too — a live project's own
# arm pass caught the first version of this fix verifying the branch and
# then reading the bare name anyway: a repo with BOTH a branch and a tag
# named "main" passes the check above (the branch exists) and then every
# `git log "$BASE"` reads the TAG instead, because git's own bare-name
# resolution does not favor the ref this script just verified. Naming the
# hazard in a comment and not applying it to the reads is the same defect
# as not naming it at all.
if ! git rev-parse --verify --quiet "refs/heads/$BASE" >/dev/null; then
  echo "ticket-git-facts: base branch '$BASE' does not exist (set BASE_BRANCH to override the default)" >&2
  exit 1
fi
BASE_REF="refs/heads/$BASE"

if [ -z "$tickets" ]; then
  # Case-insensitive: a commit subject written as "fix(tra-42): ..." is a
  # real reference, and the branch match below already treats case as
  # irrelevant. A case-sensitive discovery pass here would drop such a
  # ticket before it ever reaches the per-ticket count below — not merely
  # undercount it, but never see it at all.
  tickets=$(
    git log "$BASE_REF" --format='%s' \
      | grep -oiE "${PREFIX}-[0-9]+" \
      | tr '[:lower:]' '[:upper:]' \
      | sort -u -t- -k2 -n
  )
fi

if [ -z "$tickets" ]; then
  echo "ticket-git-facts: no ticket ids found on '$BASE' and none given" >&2
  exit 1
fi

printf 'ticket\tsubject_commits\tnewest_subject\tlocal_branch\tunmerged_commits\tworktree\n'

for t in $tickets; do
  # \b so a shorter id never matches inside a longer one. Case-insensitive
  # to match the branch-slug search below, which already lowercases before
  # matching — a case-sensitive search here was blind to any commit written
  # as "fix(tra-42): ..." and reported it PHANTOM-DONE downstream (measured:
  # a whole slice of lowercase-subject commits, zero case-sensitive matches,
  # all four-or-five case-insensitive).
  n=$(git log "$BASE_REF" --format='%s' | grep -ciE "${t}\b" || true)

  if [ "$n" -gt 0 ]; then
    newest=$(git log "$BASE_REF" --format='%s' | grep -iE "${t}\b" | head -1)
  else
    newest="-"
  fi

  slug=$(printf '%s' "$t" | tr '[:upper:]' '[:lower:]')
  branch=$(git branch --format='%(refname:short)' | grep -iE "(^|/)[^/]*${slug}([^0-9]|$)" | head -1)
  branch=${branch:-"-"}

  if [ "$branch" != "-" ]; then
    unmerged=$(git rev-list --count "${BASE_REF}..${branch}" 2>/dev/null || echo "?")
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
