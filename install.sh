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
#                agent reads that directory as the manifest of what the package contained,
#                and --apply's three-way arbitration compares against it.
set -euo pipefail

HARNESS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="$HARNESS_ROOT/harness"
ADAPT_PROMPT="$HARNESS_ROOT/prompts/ADAPT-HARNESS.md"
UNINSTALL_PROMPT="$HARNESS_ROOT/prompts/UNINSTALL-HARNESS.md"
RELEASE_NOTES="$HARNESS_ROOT/RELEASE-NOTES.md"
VERSION="$(cat "$HARNESS_ROOT/VERSION")"

for REQUIRED in "$PAYLOAD" "$ADAPT_PROMPT" "$UNINSTALL_PROMPT" "$RELEASE_NOTES" \
                "$HARNESS_ROOT/README.md" "$HARNESS_ROOT/check-requirements.sh"; do
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

APPLY=0
PLAN=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --apply) APPLY=1 ;;
    --plan)  APPLY=1; PLAN=1 ;;
    *) ARGS+=("$a") ;;
  esac
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

TARGET="${1:-}"
[ -n "$TARGET" ] || {
  echo "Usage: $0 <target-repo-path> [--project-name NAME] [--plan|--apply]" >&2
  echo "  (default)  stage only — edits no project file" >&2
  echo "  --plan     show what --apply would write; writes nothing" >&2
  echo "  --apply    write the payload in; owner files kept, diverged paths reported" >&2
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

# WHICH CHECKOUT — this stages to a FIXED path under $TARGET, and nothing about git stops it
# from landing in a checkout that some other session is holding. Measured 2026-08-20: an
# adaptation agent was given its own worktree so the two sessions would stop colliding, the
# release was staged into the MAIN checkout anyway, and the agent's merge aborted on a
# CANDIDATE it had never touched and an untracked releases/ directory it had never written.
# A worktree stops git operations from colliding; it does nothing about a tool writing to a
# fixed disk path (AST-106, now landing on the stager itself — AST-117).
#
# So: stage into the checkout that will RUN the adaptation, and if a session is resident in
# the target, tell it before staging. The warning below exists because that is knowable here
# and the operator usually is not thinking about it.
if command -v git >/dev/null 2>&1 && git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  WT_COUNT="$( { git -C "$TARGET" worktree list 2>/dev/null || true; } | wc -l | tr -d ' ')"
  if [ "${WT_COUNT:-1}" -gt 1 ]; then
    echo "NOTE: $TARGET has $WT_COUNT checkouts (worktrees). Staging writes to THIS one:"
    echo "        $TARGET/.astraler/"
    echo "      If the session doing the adaptation works in a different worktree, the"
    echo "      candidate will not be in its tree, and its merge will meet files it never"
    echo "      wrote. Stage into that checkout instead, or tell the resident session first."
    echo
  fi
fi

STATE_ROOT="$TARGET/.astraler"
RELEASES_DIR="$STATE_ROOT/releases"
RELEASE_DIR="$RELEASES_DIR/$VERSION"
CANDIDATE_FILE="$STATE_ROOT/CANDIDATE"
# The applied version has ONE home, and it is ADAPT-HARNESS section 7's:
# .astraler/state/applied-version. 2.3.30 invented .astraler/APPLIED beside it, and on a
# project carrying both they disagreed immediately - state/ said 2.3.3 while APPLIED said
# 2.3.32. Two homes for one fact, in the package that keeps saying so.
APPLIED_FILE="$STATE_ROOT/state/applied-version"
PROJECT_NAME_FILE="$STATE_ROOT/PROJECT_NAME"

mkdir -p "$RELEASES_DIR"
STAGING_DIR="$(mktemp -d "$STATE_ROOT/staging.XXXXXX")"
cleanup() { [ ! -d "$STAGING_DIR" ] || rm -rf "$STAGING_DIR"; }
trap cleanup EXIT

cp -R "$PAYLOAD" "$STAGING_DIR/harness"
# Ship only what the package considers itself. `.opencode/.gitignore` names node_modules,
# package.json, package-lock.json and bun.lock as local residue — this package does not track
# them, and `cp -R` shipped them anyway: 3,645 of 3,712 payload files and 61 MB PER RELEASE.
# Measured on one adapted project: 2.3 GB under `.astraler/`. It stayed out of that project's
# git only because its .gitignore happened to carry `node_modules/`; a project without that
# line commits 61 MB per upgrade into a history ADAPT-HARNESS itself warns cannot be trimmed
# without a rewrite. A packager shipping what its own ignore rules exclude is the defect.
while IFS= read -r RESIDUE; do
  [ -n "$RESIDUE" ] && rm -rf "$STAGING_DIR/harness/.opencode/$RESIDUE"
done < "$PAYLOAD/.opencode/.gitignore"
cp "$ADAPT_PROMPT"                    "$STAGING_DIR/ADAPT-HARNESS.md"
# Staged beside its mirror, and for the same reason the release directory is immutable: removal
# is classified against THIS release's bytes, so the prompt that does the classifying has to be
# the one that shipped with them.
cp "$UNINSTALL_PROMPT"                "$STAGING_DIR/UNINSTALL-HARNESS.md"
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
    echo "Releases are immutable: the adaptation agent reads that directory as the record" >&2
    echo "of what $VERSION shipped, and --apply arbitrates against it. Bump VERSION and add a" >&2
    echo "matching RELEASE-NOTES.md heading before staging changed content." >&2
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


# ---------------------------------------------------------------------------
# --apply: write the PAYLOAD straight into the project.
#
# The default run still edits no project file. --apply is the opt-in that skips semantic
# adaptation for files a release overwrites wholesale anyway — role contracts, adapters,
# skills, scripts, the ledger. Making an agent read a 20k-word prompt to "integrate" a file
# that gets replaced whole is latency, not safety.
#
# What it will NOT do, and why:
#   - OWNER FILES are never overwritten. `.agents/orchestrator.md` carries the owner's runtime
#     and model rows (AST-041); `.claude/settings.json` carries project hooks. Written only
#     when absent.
#   - A payload path the PROJECT has diverged on is reported, never overwritten. A project can
#     author a file at a path the payload only starts shipping later, and overwriting it is
#     silent data loss (ADAPT-HARNESS §4).
# ---------------------------------------------------------------------------
if [ "$APPLY" -eq 1 ]; then
  echo
  if [ "$PLAN" -eq 1 ]; then
    echo "--plan: what an --apply would do to $TARGET (nothing is written)"
  else
    echo "--apply: writing payload into $TARGET"
  fi
  echo

  OWNER_PATHS=".agents/orchestrator.md .claude/settings.json"
  # The arbiter for "did the project change this, or did the package?" is the release the
  # project last received. `state/applied-version` records it — but a project may predate
  # project adapted before that has a full harness and no marker. Fall back to the newest
  # staged release below this one: it is what the project was last given, whatever integrated it.
  PREV_VERSION="$(cat "$APPLIED_FILE" 2>/dev/null || true)"
  if [ -z "$PREV_VERSION" ] || [ ! -d "$RELEASES_DIR/$PREV_VERSION/harness" ]; then
    PREV_VERSION="$(ls "$RELEASES_DIR" 2>/dev/null | grep -v "^$VERSION\$" \
      | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)"
    [ -n "$PREV_VERSION" ] && echo "  (no applied-version marker — comparing against staged $PREV_VERSION)" && echo
  fi
  PREV_DIR="$RELEASES_DIR/$PREV_VERSION/harness"
  [ -n "$PREV_VERSION" ] && [ -d "$PREV_DIR" ] || PREV_DIR=""

  N_NEW=0; N_UPD=0; N_SAME=0; N_OWNER=0; N_CONFLICT=0; N_KEPT=0
  CONFLICTS=""

  while IFS= read -r SRC; do
    REL="${SRC#$RELEASE_DIR/harness/}"
    DST="$TARGET/$REL"

    # owner files: only when absent
    OWNED=0
    for o in $OWNER_PATHS; do [ "$REL" = "$o" ] && OWNED=1; done
    if [ "$OWNED" -eq 1 ]; then
      if [ -e "$DST" ]; then
        echo "  owner   $REL (kept — yours)"; N_OWNER=$((N_OWNER+1))
      else
        [ "$PLAN" -eq 1 ] || { mkdir -p "$(dirname "$DST")"; cp "$SRC" "$DST"; }
        echo "  NEW     $REL (owner file, scaffolded — fill its <set-me> rows)"; N_NEW=$((N_NEW+1))
      fi
      continue
    fi

    if [ ! -e "$DST" ]; then
      [ "$PLAN" -eq 1 ] || { mkdir -p "$(dirname "$DST")"; cp "$SRC" "$DST"; }
      echo "  NEW     $REL"; N_NEW=$((N_NEW+1)); continue
    fi

    if cmp -s "$SRC" "$DST"; then N_SAME=$((N_SAME+1)); continue; fi

    # Differs. Did the PROJECT diverge, or is this just a newer payload?
    # The previous applied release is the arbiter: if the project's copy still matches what
    # the last release shipped, the project never touched it and this is a clean upgrade.
    # Three-way, and the first branch is the one a two-way check gets wrong: when the package
    # has shipped no change since the prior release, a project's edit is not a conflict — there
    # is nothing to reconcile it against. Measured on a real upgrade: five .codex profiles the
    # owner had filled in reported CONFLICT while the release carried no change to any of them.
    if [ -n "$PREV_DIR" ] && [ -f "$PREV_DIR/$REL" ] && cmp -s "$PREV_DIR/$REL" "$SRC"; then
      echo "  kept    $REL (yours; release ships no change here)"; N_KEPT=$((N_KEPT+1))
    elif [ -n "$PREV_DIR" ] && [ -f "$PREV_DIR/$REL" ] && cmp -s "$PREV_DIR/$REL" "$DST"; then
      [ "$PLAN" -eq 1 ] || cp "$SRC" "$DST"; echo "  UPDATED $REL"; N_UPD=$((N_UPD+1))
    elif [ -z "$PREV_DIR" ]; then
      # No arbiter at all, and the file already exists and differs. Whether the project wrote
      # it or an older payload did is unknowable here, so this fails CLOSED. Overwriting on a
      # guess is the silent-data-loss case ADAPT-HARNESS §4 measured.
      echo "  CONFLICT $REL — exists and differs, no prior release to compare; NOT overwritten"
      CONFLICTS="$CONFLICTS$REL"$'\n'; N_CONFLICT=$((N_CONFLICT+1))
    else
      echo "  CONFLICT $REL — project diverged from $PREV_VERSION; NOT overwritten"
      CONFLICTS="$CONFLICTS$REL"$'\n'; N_CONFLICT=$((N_CONFLICT+1))
    fi
  done < <(find "$RELEASE_DIR/harness" -type f ! -name '.DS_Store' | sort)

  echo
  echo "  new $N_NEW · updated $N_UPD · unchanged $N_SAME · kept $N_KEPT · owner-kept $N_OWNER · conflicts $N_CONFLICT"
  # --apply lands the payload; ADAPT-HARNESS section 7 still owns the semantic half.
  [ "$PLAN" -eq 1 ] || { mkdir -p "$(dirname "$APPLIED_FILE")"; printf '%s\n' "$VERSION" > "$APPLIED_FILE"; }

  if [ "$N_CONFLICT" -gt 0 ]; then
    echo
    echo "CONFLICTS — the project changed these and so did the package. Decide each:"
    printf '%s' "$CONFLICTS" | sed 's|^|  |'
    echo
    if [ -n "$PREV_DIR" ]; then
      echo "  diff .astraler/releases/$PREV_VERSION/harness/<path> <path>   # what YOU changed"
    fi
    echo "  diff .astraler/releases/$VERSION/harness/<path> <path>   # what the release brings"
  fi

  echo
  if [ "$PLAN" -eq 1 ]; then
    echo "Nothing written. Rerun with --apply to write it."
    exit 0
  fi
  echo "Payload applied. ADAPT-HARNESS.md still owns the semantic half — the project entry doc,"
  echo "the ledger namespace, and anything above listed as CONFLICT."
  exit 0
fi

cat <<EOF

No project files were changed. The agent-driven install/upgrade is ready.

Give your root Claude Code or Codex agent this instruction:

  Read .astraler/releases/$VERSION/ADAPT-HARNESS.md completely and execute it.

It will inspect this project, compare any previously applied release, integrate the
candidate, verify the result by artifact, and record the applied version.

To remove the harness later, the mirror of that instruction is:

  Read .astraler/releases/<applied>/UNINSTALL-HARNESS.md completely and execute it.
EOF
