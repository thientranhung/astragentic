#!/usr/bin/env bash
# Stage an immutable Astraler harness release inside a target repository.
#
# This is deliberately NOT the semantic installer. Its entire job is to copy this package
# into `<target>/.astraler/releases/<version>/` and stop. It edits no project file, so a
# staging run is always safe to repeat and always safe to abandon.
#
# The semantic half runs afterwards: an agent reads ADAPT-HARNESS.md and integrates the
# release using project context, the previously applied release, and this candidate.
#
# Two properties this script is responsible for:
#   IDEMPOTENT   an identical rerun re-stages nothing and says so.
#   IMMUTABLE    a release directory, once written, is a fixed record of what was shipped.
#                Changed content at an unchanged VERSION is refused, because the adaptation
#                agent and uninstall.sh both read that directory as the manifest of what
#                the package contained.
set -euo pipefail

HARNESS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="$HARNESS_ROOT/harness"
ADAPT_PROMPT="$HARNESS_ROOT/prompts/ADAPT-HARNESS.md"
RELEASE_NOTES="$HARNESS_ROOT/RELEASE-NOTES.md"
VERSION="$(cat "$HARNESS_ROOT/VERSION")"

for REQUIRED in "$PAYLOAD" "$ADAPT_PROMPT" "$RELEASE_NOTES" "$HARNESS_ROOT/README.md" \
                "$HARNESS_ROOT/check-requirements.sh"; do
  [ -e "$REQUIRED" ] || { echo "ERROR: package is incomplete, missing $REQUIRED" >&2; exit 1; }
done

# The release notes own this version's semantic intent, and the adaptation agent is told to
# read them first. A heading that does not match VERSION means one of the two was bumped
# without the other, and the agent would read the wrong release's intent.
if ! grep -qx "# \(Astragentic\|Astraler Harness\) $VERSION" "$RELEASE_NOTES"; then
  echo "ERROR: RELEASE-NOTES.md needs a heading '# Astragentic $VERSION' (or '# Astraler Harness $VERSION')." >&2
  exit 1
fi

# Skills that exist in both .agents/skills/ and .claude/skills/ must be byte-identical,
# except for known-divergent pairs that carry legitimate adapter differences. A fix landing
# in one copy but not the other is invisible to the runtime that loads the other — measured
# three times across two skills, each found in the field rather than at staging (AST-093).
SKILL_SYNC_FAIL=0
DIVERGENT_ALLOWLIST="codex-arm review-with-rin"
for agents_skill in "$PAYLOAD/.agents/skills"/*/SKILL.md; do
  [ -f "$agents_skill" ] || continue
  skill_name="$(basename "$(dirname "$agents_skill")")"
  claude_skill="$PAYLOAD/.claude/skills/$skill_name/SKILL.md"
  [ -f "$claude_skill" ] || continue
  # Skip known-divergent pairs
  case " $DIVERGENT_ALLOWLIST " in *" $skill_name "*) continue ;; esac
  if ! diff -q "$agents_skill" "$claude_skill" >/dev/null 2>&1; then
    echo "ERROR: .agents/skills/$skill_name/SKILL.md differs from .claude/skills/$skill_name/SKILL.md" >&2
    echo "  These copies must be identical (not in the divergent allowlist)." >&2
    echo "  Diff:" >&2
    diff "$agents_skill" "$claude_skill" | sed 's/^/    /' >&2
    SKILL_SYNC_FAIL=1
  fi
done
[ "$SKILL_SYNC_FAIL" -eq 0 ] || {
  echo >&2
  echo "Sync the copies before staging. A fix in one but not the other is unreachable" >&2
  echo "on the runtime that loads the other copy." >&2
  exit 1
}

# Auto-update the ledger header count from actual content before staging.
# A hand-maintained count in a file copied wholesale on every release is a tax every
# downstream project pays when it drifts — measured: two consecutive releases shipped with
# a stale header, and the adapted project had to fix it twice.
LEDGER="$PAYLOAD/.agents/memory/recurring-failure-modes.md"
if [ -f "$LEDGER" ]; then
  ACTUAL_COUNT=$(grep -c '^### AST-' "$LEDGER")
  FIRST_AST=$(grep -m1 -oE 'AST-[0-9]+' "$LEDGER" | head -1)
  LAST_AST=$(grep -oE '^### AST-[0-9]+' "$LEDGER" | tail -1 | grep -oE 'AST-[0-9]+')
  WITHDRAWN=$(grep -c 'withdrawn' "$LEDGER" | head -1)
  if [ "$WITHDRAWN" -gt 0 ]; then
    HEADER_NEW="Status: current · $ACTUAL_COUNT entries ($FIRST_AST … $LAST_AST, 067 withdrawn) · AST-001…034 carried into 1.0.0 unchanged"
  else
    HEADER_NEW="Status: current · $ACTUAL_COUNT entries ($FIRST_AST … $LAST_AST) · AST-001…034 carried into 1.0.0 unchanged"
  fi
  HEADER_OLD=$(sed -n '3p' "$LEDGER")
  if [ "$HEADER_OLD" != "$HEADER_NEW" ]; then
    sed -i '' "3s|.*|$HEADER_NEW|" "$LEDGER"
    echo "Ledger header auto-updated: $ACTUAL_COUNT entries ($FIRST_AST … $LAST_AST)"
  fi
fi

TARGET="${1:-}"
[ -n "$TARGET" ] || {
  echo "Usage: $0 <target-repo-path> [--project-name NAME]" >&2
  exit 2
}
shift

PROJECT_NAME=""
while [ $# -gt 0 ]; do
  case "$1" in
    --project-name) PROJECT_NAME="${2:?--project-name needs a value}"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

[ -d "$TARGET" ] || { echo "Target does not exist: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"
if [ -z "$PROJECT_NAME" ]; then
  EXISTING="$TARGET/.astraler/PROJECT_NAME"
  if [ -f "$EXISTING" ]; then
    PROJECT_NAME="$(cat "$EXISTING")"
  else
    PROJECT_NAME="$(basename "$TARGET")"
  fi
fi

STATE_ROOT="$TARGET/.astraler"
RELEASES_DIR="$STATE_ROOT/releases"
RELEASE_DIR="$RELEASES_DIR/$VERSION"
CANDIDATE_FILE="$STATE_ROOT/CANDIDATE"
PROJECT_NAME_FILE="$STATE_ROOT/PROJECT_NAME"

mkdir -p "$RELEASES_DIR"
STAGING_DIR="$(mktemp -d "$STATE_ROOT/staging.XXXXXX")"
cleanup() { [ ! -d "$STAGING_DIR" ] || rm -rf "$STAGING_DIR"; }
trap cleanup EXIT

cp -R "$PAYLOAD" "$STAGING_DIR/harness"
cp "$ADAPT_PROMPT"                    "$STAGING_DIR/ADAPT-HARNESS.md"
cp "$HARNESS_ROOT/README.md"          "$STAGING_DIR/README.md"
cp "$RELEASE_NOTES"                   "$STAGING_DIR/RELEASE-NOTES.md"
cp "$HARNESS_ROOT/check-requirements.sh" "$STAGING_DIR/check-requirements.sh"
# ...and into the PAYLOAD, so adaptation lands it in the project's scripts/ beside
# check-reachability.sh. Staged-only was asymmetric: one self-check survived in the repo and
# the other lived solely inside .astraler/releases/, which a project may legitimately ignore —
# so deleting that directory took the repo's own doctor with it (AST-059). One source file
# here, copied to two destinations; the package keeps a single home for it.
cp "$HARNESS_ROOT/check-requirements.sh" "$STAGING_DIR/harness/scripts/check-requirements.sh"
cp "$HARNESS_ROOT/VERSION"            "$STAGING_DIR/VERSION"
# Templates are optional: 1.0.0 ships none, because the adaptation agent derives project
# docs from the repo itself rather than scaffolding them. Staged when a later version adds
# them, so this line needs no revisit then.
[ -d "$HARNESS_ROOT/templates" ] && cp -R "$HARNESS_ROOT/templates" "$STAGING_DIR/templates"
find "$STAGING_DIR" -name '.DS_Store' -delete

if [ -d "$RELEASE_DIR" ]; then
  if diff -qr "$STAGING_DIR" "$RELEASE_DIR" >/dev/null 2>&1; then
    echo "Astraler release $VERSION is already staged and unchanged."
  else
    echo "ERROR: staged release $VERSION differs from this package source." >&2
    echo >&2
    echo "  staged at: $RELEASE_DIR" >&2
    echo >&2
    echo "Releases are immutable: the adaptation agent and uninstall.sh both read that" >&2
    echo "directory as the record of what $VERSION shipped. Bump VERSION and add a matching" >&2
    echo "RELEASE-NOTES.md heading before staging changed content." >&2
    echo >&2
    echo "Differences:" >&2
    diff -qr "$STAGING_DIR" "$RELEASE_DIR" 2>&1 | sed "s|$STAGING_DIR|<package>|g; s|$RELEASE_DIR|<staged>|g; s|^|  |" >&2
    exit 1
  fi
else
  mv "$STAGING_DIR" "$RELEASE_DIR"
  echo "Staged Astraler release $VERSION at $RELEASE_DIR"
fi

printf '%s\n' "$VERSION"      > "$CANDIDATE_FILE"
printf '%s\n' "$PROJECT_NAME" > "$PROJECT_NAME_FILE"

cat <<EOF

No project files were changed. The agent-driven install/upgrade is ready.

Give your root Claude Code or Codex agent this instruction:

  Read .astraler/releases/$VERSION/ADAPT-HARNESS.md completely and execute it.

It will inspect this project, compare any previously applied release, integrate the
candidate, verify the result by artifact, and record the applied version.
EOF
