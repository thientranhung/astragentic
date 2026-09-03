#!/bin/bash
# reap-worktree-processes.sh
#
# ADOPTED FROM A DOWNSTREAM PROJECT, which wrote it, measured it and caught its first version's
# defect in review. The package shipped a prose block and an lsof one-liner instead; that
# one-liner carried TWO of the bugs documented below — exact-path matching, and no realpath on
# either side, so on macOS it compared `/tmp/...` against lsof's `/private/tmp/...` and matched
# nothing, ever. It was never run before shipping. This is the version that was.
# Measurements this package did not make are cited by their ledger entry, never by a downstream
# ticket id or project name — the payload names no project (SPEC invariant, AST-123).
#
#   scripts/reap-worktree-processes.sh <worktree-path>
#
# Retiring a worktree (`git worktree remove`) does not touch processes still running inside
# it. Measured: a `boundary.test` binary from a merged, removed ticket worktree spun 18h18m
# at 85% of a core, `PPID 1` (reparented to launchd, its Builder session long gone), ignoring
# SIGTERM — its own 10-minute `-test.timeout` never fired. `dispatch-ticket/CLEANUP.md` §
# "Reaping orphans" is the doc form of this; this script is the runnable form Thomas (or a
# Builder retiring its own worktree) actually calls, so the reap is a single command rather
# than a bash snippet re-typed by hand each time.
#
# SCOPE, ON PURPOSE: exactly ONE worktree, named explicitly on the command line. This is a
# process killer running on a box other Builders' live work shares — another ticket's worktree, gate worktrees
# under /tmp, unrelated projects. It never widens to "all worktrees" or "all orphans"; that is
# the *standing sweep* in herdr-watchdog.sh, which only ALERTS and never kills. See CLEANUP.md
# for why the two are split.
#
# MATCH ON THE PROCESS'S REAL cwd, RESOLVED VIA lsof — never on argv. A command-line grep also
# matches a monitor script, an editor with the file open, or a shell with the path in its
# history. Measured 2026-08-24: `ps | grep -- '--cwd <path>'` reported "none" while a live
# broker rooted in a deleted worktree had been running for three hours; `lsof -a -d cwd` found
# it immediately.
#
# THE MATCH MUST BE A PATH-PREFIX WITH A `/` BOUNDARY, NOT AN EXACT PATH, AND NOT A NAME
# FILTER PASSED TO `lsof`. `lsof -a -d cwd -- "$WORKTREE"` (this script's first version) only
# matches processes whose cwd IS the worktree root — and Go test binaries run with cwd set to
# THEIR OWN PACKAGE DIRECTORY, always, several levels below it (`.../worktree/apps/server/
# internal/boundary` in the incident that opened this ticket). That first version could not
# have found the very process that motivated it. Caught in review before merge (thanks to a
# peer's reproduction, not just re-reading the code) — reproduced independently below:
#
#   mkdir -p /tmp/lsoftest/sub/deep && (cd /tmp/lsoftest/sub/deep && sleep 300 &)
#   lsof -a -d cwd -- /tmp/lsoftest        # -> nothing. MISS.
#   lsof -a -d cwd | grep <pid>            # -> /private/tmp/lsoftest/sub/deep. FOUND.
#
# So this enumerates cwd for every process on the box (cheap — `lsof -a -d cwd` alone, no
# `+D` directory-tree walk, which would be slow and its own hazard against a worktree
# carrying `node_modules` / Go build output) and matches by PREFIX with an explicit `/`
# boundary: `$WORKTREE` itself, or anything starting `$WORKTREE/`. The boundary is
# load-bearing — without it, a worktree named `foo` would also match a sibling `foo-2`, and
# reaping the wrong ticket's live process is a worse outcome than the orphan this script
# exists to clean up.
#
# Both sides of the comparison go through `realpath` (or an ancestor-walk fallback for a path
# already removed — see `resolve_path`) so a symlink alias (macOS `/tmp` is `/private/tmp`;
# `lsof` reports the resolved form) can't defeat the match or the boundary, including for the
# documented "after removal" call in CLEANUP.md, once the worktree directory itself is gone.
#
# Self-test (a project-side script; the package ships none) — nested cwd, prefix-sharing sibling,
# unrelated worktree, a mid-loop race, and a post-removal /tmp-aliased path, each as a real
# spawned process, not a read of this file. Run it after touching the matching logic; a manual
# one-time check described in a commit message cannot be re-run by the next person.
set -euo pipefail

WORKTREE_ARG="${1:-}"
if [ -z "$WORKTREE_ARG" ]; then
  echo "usage: $0 <worktree-path>" >&2
  exit 2
fi

# realpath(1) resolves symlinks in whatever prefix of the path currently exists. For a path
# that's already fully gone (the common case — this runs as part of retiring it) `realpath`
# itself fails outright rather than resolving the part that DOES exist, so a naive fallback to
# the raw string leaves a symlink alias unresolved right where it matters most: the arm's own
# pass-1 review (folded here) found that a removed `/tmp/<worktree>/...` compares unequal to
# what lsof reports (`/private/tmp/<worktree>/...` on macOS, where /tmp is itself a symlink),
# silently missing every process left behind by a JUST-removed worktree — the exact moment the
# "after removal" call in CLEANUP.md exists for. So on failure, walk up to the longest
# ancestor that still exists, resolve THAT (catching the alias), and re-append the missing
# suffix.
resolve_path() {
  local p="$1"
  # An EMPTY input means "no path was read at all" (a per-pid lsof lookup that came back empty
  # because the process is already gone, or raced). Folded from the arm's pass-2 review (HIGH):
  # the ancestor-walk below, given "", walked to `basename ""` = "." and resolved that to THIS
  # SCRIPT's own current directory — a plausible-looking path that is not evidence of anything.
  # If the operator happened to invoke this script from inside the target worktree, that
  # fabricated path would satisfy cwd_matches and a replacement pid could be signaled on missing
  # identity evidence, not on cwd evidence. Fail closed instead: empty in, error out, never a
  # guess. Every call site below already treats a failed resolve_path as "no match."
  [ -n "$p" ] || return 1
  command -v realpath >/dev/null 2>&1 || { printf '%s\n' "$p"; return; }

  local resolved
  resolved=$(realpath "$p" 2>/dev/null) && { printf '%s\n' "$resolved"; return; }

  local ancestor="$p" suffix=""
  while [ "$ancestor" != "/" ] && [ "$ancestor" != "." ] && [ ! -e "$ancestor" ]; do
    suffix="/$(basename "$ancestor")$suffix"
    ancestor="$(dirname "$ancestor")"
  done
  local resolved_ancestor
  resolved_ancestor=$(realpath "$ancestor" 2>/dev/null) || resolved_ancestor="$ancestor"
  printf '%s\n' "${resolved_ancestor%/}$suffix"
}

WORKTREE="$(resolve_path "$WORKTREE_ARG")"
# Strip any trailing slash so the boundary check below never has to special-case "//".
WORKTREE="${WORKTREE%/}"

echo "reap-worktree-processes: scanning cwd-prefix=$WORKTREE (and everything under it)"

# cwd_matches PATH — true iff PATH equals WORKTREE or starts with "WORKTREE/". Deliberately a
# case-pattern, not a substring test: `case` globbing with a literal `/` suffix is the `/`
# boundary that keeps a sibling worktree ("$WORKTREE-2") from matching.
cwd_matches() {
  case "$1" in
    "$WORKTREE") return 0 ;;
    "$WORKTREE"/*) return 0 ;;
    *) return 1 ;;
  esac
}

# process_identity PID — echoes "<cwd>\t<start-time>" for PID, or nothing if it's gone. The
# start time (full precision including seconds, via `ps -o lstart=`) is what a REUSED pid
# cannot forge: the OS never hands out a pid to a new process without giving that process a
# later start time than whatever held the pid before. cwd alone is not enough to prove
# identity across a wait — a reused pid could, in principle, land in a matching cwd by
# coincidence; cwd + start time together is what "still the same process" actually means.
# No pidfd here: this box is macOS, and pidfd is Linux-only.
process_identity() {
  local pid="$1" cwd_raw cwd start
  cwd_raw=$(lsof -a -p "$pid" -d cwd 2>/dev/null | awk 'NR==2 {print $NF}') || true
  cwd="$(resolve_path "$cwd_raw" 2>/dev/null)" || cwd=""   # empty raw cwd -> resolve_path fails -> no identity, not a guess
  start=$(ps -o lstart= -p "$pid" 2>/dev/null | sed -e 's/^ *//' -e 's/ *$//') || true
  [ -n "$cwd" ] && [ -n "$start" ] || return 1
  printf '%s\t%s\n' "$cwd" "$start"
}

# identity_still_matches PID EXPECTED_CWD EXPECTED_START — true iff PID is still alive, its cwd
# STILL passes cwd_matches, AND its start time is UNCHANGED from EXPECTED_START. Folded from the
# arm's pass-1 review (HIGH): cwd alone, checked once before SIGTERM, does not survive a wait —
# the target can exit and the OS can hand its pid to an unrelated process during the SIGTERM
# grace period, and a cwd-only recheck could theoretically pass by coincidence. Re-validate BOTH
# immediately before EVERY signal that follows the first read, SIGKILL included, since SIGKILL
# is unconditional and unblockable and is exactly the wrong place to trust a stale identity.
identity_still_matches() {
  local pid="$1" expected_cwd="$2" expected_start="$3" now
  now=$(process_identity "$pid") || return 1
  local now_cwd="${now%%$'\t'*}" now_start="${now#*$'\t'}"
  [ "$now_cwd" = "$expected_cwd" ] && [ "$now_start" = "$expected_start" ] && cwd_matches "$now_cwd"
}

# System-wide cwd table, once. `-a` ANDs `-d cwd` with nothing else here (no name filter, on
# purpose — see header) so this returns cwd for every process lsof can see; filtering happens
# in bash against the resolved WORKTREE, not inside lsof.
#
# Captured OUTSIDE a `< <(...)` process substitution and on its own line, specifically so its
# exit status is checkable. Piped straight into the while-loop the way an earlier version of
# this script did, lsof failing entirely (missing binary, broken PATH, no permission at all —
# folded from the arm's pass-1 review, reproduced by running with a PATH lacking lsof) makes
# the loop read zero lines and this script report "no processes rooted in $WORKTREE — nothing
# to reap" with exit 0: a clean-looking reap that never actually looked. A real box always has
# many processes holding a cwd fd (this shell among them), so empty output here is enumeration
# failure, not "found nothing" — fail loud instead of reporting a false clean.
#
# DOES require lsof's own exit status 0 — reversed from an earlier draft of this comment, which
# declined that on the theory that lsof commonly exits non-zero on a GOOD listing when it can't
# read every process due to permissions. That theory was untested on this box; measured instead
# (a second, independent gate run pushed back on it, and the measurement settled it, not the
# argument): `lsof -a -d cwd` — the exact invocation used here — returns exit 0 on this machine
# right now, unfiltered. So there is no real tradeoff to avoid here, and the exit code is exactly
# the signal the recommendation said it was. If a future box's lsof genuinely needs a permission
# exception, that is the moment to reintroduce a documented, MEASURED carve-out — not to guess
# one back in speculatively.
#
# `set +e` around this ONE call rather than `|| true`, because `|| true` on the assignment
# would swallow $? before this line can read it — the exit code is the thing being checked here,
# so it has to survive past the assignment.
LSOF_ERR_FILE="$(mktemp)"
set +e
LSOF_RAW="$(lsof -a -d cwd 2>"$LSOF_ERR_FILE")"
LSOF_RC=$?
set -e
LSOF_ERR="$(cat "$LSOF_ERR_FILE" 2>/dev/null)"
rm -f "$LSOF_ERR_FILE"

LSOF_LINES="$(printf '%s\n' "$LSOF_RAW" | grep -c '.' || true)"
# Bash string expansion, not `| head -1`: piping a large `$LSOF_RAW` (thousands of lines on a
# busy box) into a command that only reads the first line and closes can SIGPIPE the writer —
# reproduced: `head -1` here made the whole script exit 141 (128+SIGPIPE) under `set -e
# -o pipefail` the moment LSOF_RAW was big enough to fill a pipe buffer.
LSOF_HEADER="${LSOF_RAW%%$'\n'*}"
case "$LSOF_HEADER" in
  *COMMAND*PID*USER*) LSOF_HEADER_OK=1 ;;
  *) LSOF_HEADER_OK=0 ;;
esac
# Belt AND suspenders, on purpose: exit code catches a clean failure (missing binary, denied
# entirely); the line-count/header floor catches a WEIRD partial success that still exits 0.
if [ "$LSOF_RC" -ne 0 ] || [ "$LSOF_HEADER_OK" -ne 1 ] || [ "$LSOF_LINES" -lt 10 ]; then
  echo "reap-worktree-processes: STOP — lsof produced no usable process listing (enumeration" >&2
  echo "  failure, not \"nothing found\" — this box always has dozens of processes holding a" >&2
  echo "  cwd fd, and a real listing's first line is a COMMAND/PID/USER header)." >&2
  echo "  lsof exit=$LSOF_RC  stderr: $LSOF_ERR" >&2
  echo "  lsof stdout: $LSOF_RAW" >&2
  exit 3
fi

# `mapfile` is bash 4+; this box's default `/bin/bash` is 3.2 (macOS), so results are collected
# through a plain read loop instead — portable back to bash 3.
CANDIDATES=""
while IFS=$'\t' read -r pid cwd; do
  [ -n "$pid" ] || continue
  case " $CANDIDATES " in *" $pid "*) continue ;; esac   # a pid can hold cwd more than once
  cwd="$(resolve_path "$cwd" 2>/dev/null)" || cwd=""
  cwd_matches "$cwd" && CANDIDATES="$CANDIDATES $pid"
done < <(printf '%s\n' "$LSOF_RAW" | awk 'NR>1 {print $2"\t"$NF}')

if [ -z "${CANDIDATES// /}" ]; then
  echo "reap-worktree-processes: no processes rooted in $WORKTREE — nothing to reap"
  exit 0
fi

killed=0
for pid in $CANDIDATES; do
  # Defense in depth: re-resolve this PID's cwd directly and require it to still pass the
  # SAME prefix+boundary check before touching it. The system-wide scan above already applies
  # this check once; this is a second, independent read immediately before the kill, so a cwd
  # that changed between the scan and now (or a stale/aliased first read) can't slip through —
  # cheap here since the candidate set is tiny.
  # Baseline identity read via process_identity() — the SAME function the pre-SIGKILL re-check
  # uses, so establishing identity and re-verifying it go through one code path instead of two.
  # `|| true`: under `set -eo pipefail`, this failing because the pid has already died between
  # the scan and here would otherwise abort THIS WHOLE SCRIPT mid-loop — silently leaving every
  # remaining candidate unprocessed and unreported, the exact "silent reap" this script exists
  # to prevent. Reproduced: `x=$(false | true)` under `set -e` exits the shell even though the
  # assignment "succeeds" by content.
  identity_raw=$(process_identity "$pid") || true
  if [ -z "$identity_raw" ]; then
    echo "reap-worktree-processes: pid=$pid already gone (or unreadable) before reap could act"
    continue
  fi
  actual_cwd="${identity_raw%%$'\t'*}"
  start_time="${identity_raw#*$'\t'}"
  if ! cwd_matches "$actual_cwd"; then
    echo "reap-worktree-processes: SKIP pid=$pid — cwd resolved to '$actual_cwd', not under '$WORKTREE'"
    continue
  fi

  cmd=$(ps -o command= -p "$pid" 2>/dev/null || true)
  if [ -z "$cmd" ]; then
    echo "reap-worktree-processes: pid=$pid already gone before reap could act"
    continue
  fi

  # Revalidate immediately before SIGTERM too, folded from a fresh gate the arm's pass-2 fold
  # earned (needs-attention, not a third pass against the cap — see the commit message): the
  # baseline read above and the `cmd` read just before this are two SEPARATE lsof/ps calls, and
  # the pid could theoretically be reused in the gap between them and the kill(2) call that
  # follows. Uses the exact same identity_still_matches the SIGKILL path uses, so both signals
  # go through one re-verification shape rather than SIGTERM getting a weaker one.
  if ! identity_still_matches "$pid" "$actual_cwd" "$start_time"; then
    echo "reap-worktree-processes: ABORT pid=$pid — identity changed before SIGTERM could be" \
      "sent; the pid was likely REUSED. NOT sending SIGTERM."
    continue
  fi

  echo "reap-worktree-processes: KILLING pid=$pid cwd=$actual_cwd cmd=${cmd:0:200}"
  kill -TERM "$pid" 2>/dev/null || true

  # Give it a real chance to exit clean before escalating — the orphan that motivated this
  # ticket ignored SIGTERM outright, so the escalation path is the one that actually mattered.
  alive=1
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if ! kill -0 "$pid" 2>/dev/null; then
      alive=0
      break
    fi
    sleep 0.5
  done

  if [ "$alive" -eq 1 ]; then
    # PID-reuse guard, folded from the arm's pass-1 review (HIGH): the identity check above ran
    # BEFORE SIGTERM. In the 5s poll loop since then, the target could have exited and the OS
    # handed its pid to an unrelated new process — `kill -0` above only proves SOMETHING is
    # alive at this pid, not that it is still OUR target, and cwd alone is not enough to prove
    # otherwise (a reused pid could, in principle, land in a matching cwd by coincidence).
    # SIGKILL is unconditional and unblockable, so this is the one signal that must never fire
    # on a re-verified-wrong identity. Re-check BOTH cwd and start time immediately before the
    # kill, via the same identity_still_matches used to establish the baseline.
    if [ -z "$start_time" ] || ! identity_still_matches "$pid" "$actual_cwd" "$start_time"; then
      recheck_cwd_raw=$(lsof -a -p "$pid" -d cwd 2>/dev/null | awk 'NR==2 {print $NF}') || true
      recheck_cwd="$(resolve_path "$recheck_cwd_raw" 2>/dev/null)" || recheck_cwd="(gone)"
      echo "reap-worktree-processes: ABORT escalation for pid=$pid — identity no longer" \
        "matches (cwd was '$actual_cwd', now '$recheck_cwd'; start time was '$start_time')." \
        "The pid was likely REUSED by an unrelated process during the SIGTERM grace period." \
        "NOT sending SIGKILL."
    else
      echo "reap-worktree-processes: pid=$pid survived SIGTERM after 5s — sending SIGKILL"
      kill -KILL "$pid" 2>/dev/null || true
      sleep 0.2
      if kill -0 "$pid" 2>/dev/null; then
        echo "reap-worktree-processes: WARNING pid=$pid still alive after SIGKILL (zombie or reparented mid-kill?)"
      else
        echo "reap-worktree-processes: pid=$pid killed (SIGKILL)"
      fi
    fi
  else
    echo "reap-worktree-processes: pid=$pid exited cleanly (SIGTERM)"
  fi
  killed=$((killed + 1))
done

echo "reap-worktree-processes: reaped $killed process(es) rooted in $WORKTREE"
