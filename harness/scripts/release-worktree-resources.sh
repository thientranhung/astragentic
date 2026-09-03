#!/usr/bin/env bash
# release-worktree-resources.sh — the ONE call that releases what a worktree allocated, in order.
#
#   scripts/release-worktree-resources.sh <worktree-path>
#
# THIS IS A SOCKET, NOT AN ANSWER. The harness knows exactly one thing every worktree can
# allocate — processes rooted in it — and reaps those itself. Everything else a worktree may
# hold is the PROJECT's to know: a database, a port registration, a container, a broker, a
# shared cluster lease. The harness cannot name those without naming one project's stack, and
# for four releases it did: a compose label and a broker process were hardwired at five
# separate call sites, so a project on a different stack read "cleanup exists" and released
# nothing. Measured downstream in one night: 43 orphaned processes, 3,405 leftover databases
# (25 GB), load average 123, one Builder killed by the OS.
#
# So the project declares its own release step as an executable plug:
#
#   .astraler/project/cleanup-worktree.sh <worktree-path>
#
# and this script calls it after the reap. `.astraler/project/` is project-owned — no release
# ever writes there, so an upgrade cannot overwrite the answer. ADAPT-HARNESS.md §3 asks the
# project to write it. A project that allocates nothing beyond git still writes one that says so.
#
# ORDER IS LOAD-BEARING. Resources bound to a directory — by cwd, by a label derived from the
# path, by a name the project computed from it — cannot be matched once the directory is gone,
# so this runs BEFORE `git worktree remove`, never after (AST-100, AST-101). And the plug must
# scope to THIS worktree only: a project-level teardown target once stopped the shared test
# container every live Builder was standing on (AST-115).
#
# EVERY OUTCOME IS SPOKEN. An empty socket is reported as empty — "no project cleanup declared"
# — because a silent no-op is indistinguishable from a successful release, and that
# indistinguishability is exactly how the orphans above accumulated (AST-057). Nothing here is
# `|| true`d: a plug that fails fails this script.
set -uo pipefail

WT="${1:?usage: release-worktree-resources.sh <worktree-path>}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The project root is where the plug lives. Resolve it from the caller's checkout — hooks run
# with the project as cwd — and fall back to CLAUDE_PROJECT_DIR for a hook fired elsewhere.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
ROOT="${ROOT:-${CLAUDE_PROJECT_DIR:-$PWD}}"
PLUG="$ROOT/.astraler/project/cleanup-worktree.sh"

echo "release-worktree-resources: worktree=$WT"
rc=0

# 1. The harness's own part: processes rooted in the worktree, matched by real cwd.
REAP="$HERE/reap-worktree-processes.sh"
[ -x "$REAP" ] || REAP="$ROOT/scripts/reap-worktree-processes.sh"
if [ -x "$REAP" ]; then
  "$REAP" "$WT" || { echo "release-worktree-resources: WARN reap exited $? for $WT" >&2; rc=1; }
else
  echo "release-worktree-resources: STOP — reap-worktree-processes.sh not found beside this script or under $ROOT/scripts" >&2
  rc=1
fi

# 2. The project's part: whatever this project's worktrees allocate beyond git.
if [ -x "$PLUG" ]; then
  echo "release-worktree-resources: running project plug $PLUG"
  "$PLUG" "$WT" || { echo "release-worktree-resources: WARN project plug exited $? for $WT" >&2; rc=1; }
elif [ -e "$PLUG" ]; then
  echo "release-worktree-resources: STOP — $PLUG exists but is not executable (chmod +x it)" >&2
  rc=1
else
  echo "release-worktree-resources: NOTE — no project cleanup declared at .astraler/project/cleanup-worktree.sh; nothing project-specific was released. If this project's worktrees allocate anything beyond git (a database, a port, a container, a lease), that is a gap — see ADAPT-HARNESS.md §3."
fi

# 3. Leave evidence. `hook-git-guard.py` refuses `git worktree remove <path>` unless this stamp
#    exists for the path, so the call above is a MECHANISM, not a remembered step: skipping it
#    blocks the removal instead of leaking silently. The key is the resolved path, hashed, so
#    macOS's /tmp → /private/tmp alias cannot split the pair. /tmp, not the repo: this is
#    machine-local evidence, and the hook-events log already lives there.
if [ "$rc" -eq 0 ]; then
  STAMP_DIR=/tmp/harness-released; mkdir -p "$STAMP_DIR"
  real="$(cd "$WT" 2>/dev/null && pwd -P || printf '%s' "$WT")"
  key="$(printf '%s' "$real" | shasum -a 256 | cut -c1-16)"
  printf '%s %s\n' "$(date -u +%FT%TZ)" "$real" > "$STAMP_DIR/$key"
  echo "release-worktree-resources: stamped $STAMP_DIR/$key — the git guard now admits \`git worktree remove\` for this path"
else
  echo "release-worktree-resources: NOT stamped (exit $rc) — the git guard will keep refusing removal until a clean run" >&2
fi
exit $rc
