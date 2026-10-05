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
#
#    WHAT THE HARNESS CAN SEE WITHOUT KNOWING THE STACK, and checks after the plug. Tearing a
#    Compose stack down needs the project's compose file, env and project name — hardwiring
#    that is the defect 2.7.15 retired — but IDENTIFYING what a worktree's stack left behind
#    needs only Docker's own labels. Compose stamps every container with the directory it ran
#    from (`com.docker.compose.project.working_dir`), so the stacks rooted in this worktree are
#    named before the plug runs, and whatever still carries their project label afterwards is a
#    leak by construction. Measured downstream: a plug running `down -v` left the image its
#    stack built, 99 of them at ~485 MB, because `down -v` removes containers and volumes and
#    no image (AST-155). Images are checked only under Compose's default `<project>-<service>`
#    name — exactly what `--rmi local` removes — so an image the project tags on purpose is
#    never flagged. Resolved before the plug on purpose: after `down`, no container is left to
#    say which project was this worktree's. A stack whose containers were already gone before
#    this ran is not seen, and nothing here deletes anything.
compose_projects=""
if command -v docker >/dev/null 2>&1 && docker version >/dev/null 2>&1; then
  real_wt="$(cd "$WT" 2>/dev/null && pwd -P || printf '%s' "$WT")"
  compose_projects="$(docker ps -a --format '{{.Label "com.docker.compose.project"}}|{{.Label "com.docker.compose.project.working_dir"}}' 2>/dev/null \
    | awk -F'|' -v a="$WT" -v b="$real_wt" '$1 != "" && ($2 == a || $2 == b || index($2, a "/") == 1 || index($2, b "/") == 1) { print $1 }' \
    | sort -u)"
fi

if [ -x "$PLUG" ]; then
  echo "release-worktree-resources: running project plug $PLUG"
  "$PLUG" "$WT" || { echo "release-worktree-resources: WARN project plug exited $? for $WT" >&2; rc=1; }
elif [ -e "$PLUG" ]; then
  echo "release-worktree-resources: STOP — $PLUG exists but is not executable (chmod +x it)" >&2
  rc=1
else
  echo "release-worktree-resources: NOTE — no project cleanup declared at .astraler/project/cleanup-worktree.sh; nothing project-specific was released. If this project's worktrees allocate anything beyond git (a database, a port, a container, a lease), that is a gap — see ADAPT-HARNESS.md §3."
fi

for p in $compose_projects; do
  left="$(docker ps -a --filter "label=com.docker.compose.project=$p" --format 'container {{.Names}}' 2>/dev/null
          docker volume ls -q --filter "label=com.docker.compose.project=$p" 2>/dev/null | sed 's/^/volume /'
          docker images --filter "label=com.docker.compose.project=$p" --format '{{.Repository}}' 2>/dev/null \
            | grep "^$p-" | sort -u | sed 's/^/image /')"
  if [ -n "$left" ]; then
    echo "release-worktree-resources: WARN compose project '$p' was rooted in this worktree and still holds:" >&2
    printf '%s\n' "$left" | sed 's/^/  /' >&2
    echo "release-worktree-resources:      the plug should release it: docker compose -p $p ... down -v --rmi local" >&2
    rc=1
  else
    echo "release-worktree-resources: compose project '$p' — no container, volume or built image left"
  fi
done

# 3. Leave evidence. `hook-git-guard.py` refuses `git worktree remove <path>` unless this stamp
#    exists for the path, so the call above is a MECHANISM, not a remembered step: skipping it
#    blocks the removal instead of leaking silently. The key is the resolved path, hashed, so
#    macOS's /tmp → /private/tmp alias cannot split the pair. /tmp, not the repo: this is
#    machine-local evidence, and the hook-events log already lives there.
if [ "$rc" -eq 0 ]; then
  # HARNESS_STAMP_ROOT overrides /tmp so nested or parallel selftests never share (or delete)
  # each other's evidence; production leaves it unset.
  # In the repository's git common dir, beside ticket-done's, for the same reason: /tmp does not
  # survive a reboot. Resolved from the worktree, whose common dir is the main repository's.
  CD="$(git -C "$WT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
  SR="${HARNESS_STAMP_ROOT:-${CD:+$CD/astraler-stamps}}"; SR="${SR:-/tmp}"
  STAMP_DIR="$SR/harness-released"; mkdir -p "$STAMP_DIR"
  real="$(cd "$WT" 2>/dev/null && pwd -P || printf '%s' "$WT")"
  key="$(printf '%s' "$real" | shasum -a 256 | cut -c1-16)"
  printf '%s %s\n' "$(date -u +%FT%TZ)" "$real" > "$STAMP_DIR/$key"
  echo "release-worktree-resources: stamped $STAMP_DIR/$key — the git guard now admits \`git worktree remove\` for this path"
else
  echo "release-worktree-resources: NOT stamped (exit $rc) — the git guard will keep refusing removal until a clean run" >&2
fi
exit $rc
