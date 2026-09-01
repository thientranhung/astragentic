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
# TWO LAYOUTS, because this script now ships INSIDE a release. The package keeps its prompts
# under `prompts/`; staging flattens them to the release root, so the copy that lands in
# `.astraler/releases/<v>/` finds `ADAPT-HARNESS.md` beside itself and no `prompts/` at all.
# Shipping the installer without teaching it that made the fix inert exactly where it was sent.
if [ -f "$HARNESS_ROOT/prompts/ADAPT-HARNESS.md" ]; then
  ADAPT_PROMPT="$HARNESS_ROOT/prompts/ADAPT-HARNESS.md"
  UNINSTALL_PROMPT="$HARNESS_ROOT/prompts/UNINSTALL-HARNESS.md"
else
  ADAPT_PROMPT="$HARNESS_ROOT/ADAPT-HARNESS.md"
  UNINSTALL_PROMPT="$HARNESS_ROOT/UNINSTALL-HARNESS.md"
fi
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
# ALLOWLIST ONE PAIR, AND ONLY WHILE IT ACTUALLY DIVERGES. `codex-arm` diverges on purpose:
# the .claude copy drops the `codex exec review` fallback, which exists only for a non-Claude
# root. `review-with-rin` was allowlisted too and diffs zero lines — a dead exemption that
# masks any future drift in exactly the pair it names. An allowlist entry that no longer
# describes a real difference is worse than no allowlist, so an unused one now fails here.
# EXACT FILE PAIRS, not skill directories. Exempting a directory skipped every file under
# it, so an auxiliary runtime file could sit missing or drifted in one tree indefinitely while
# the two SKILL.md files stayed legitimately different — the exemption covering more than the
# difference it was granted for.
DIVERGENT_ALLOWLIST="codex-arm/SKILL.md"
# EVERY FILE, not just SKILL.md. WATCHING.md, CLEANUP.md and project-status-sync.sh are all
# loaded at runtime and none of them was compared.
for agents_file in "$PAYLOAD/.agents/skills"/*/*; do
  [ -f "$agents_file" ] || continue
  skill_name="$(basename "$(dirname "$agents_file")")"
  base_name="$(basename "$agents_file")"
  claude_file="$PAYLOAD/.claude/skills/$skill_name/$base_name"
  case " $DIVERGENT_ALLOWLIST " in *" $skill_name/$base_name "*) continue ;; esac
  if [ ! -f "$claude_file" ]; then
    echo "ERROR: .agents/skills/$skill_name/$base_name has no .claude/ twin" >&2
    echo "  A file present in one tree and absent from the other is unreachable on the" >&2
    echo "  runtime that loads the other tree, and the old check skipped it silently." >&2
    SKILL_SYNC_FAIL=1
    continue
  fi
  if ! diff -q "$agents_file" "$claude_file" >/dev/null 2>&1; then
    echo "ERROR: .agents/skills/$skill_name/$base_name differs from its .claude/ twin" >&2
    diff "$agents_file" "$claude_file" | sed 's/^/    /' >&2
    SKILL_SYNC_FAIL=1
  fi
done
# The reverse direction: a skill or file that exists only under .claude/ was invisible,
# because the loop above never iterated that tree.
for claude_file in "$PAYLOAD/.claude/skills"/*/*; do
  [ -f "$claude_file" ] || continue
  skill_name="$(basename "$(dirname "$claude_file")")"
  base_name="$(basename "$claude_file")"
  case " $DIVERGENT_ALLOWLIST " in *" $skill_name/$base_name "*) continue ;; esac
  if [ ! -f "$PAYLOAD/.agents/skills/$skill_name/$base_name" ]; then
    echo "ERROR: .claude/skills/$skill_name/$base_name has no .agents/ twin" >&2
    SKILL_SYNC_FAIL=1
  fi
done
# VALIDATE EVERY ALLOWLISTED PAIR BEFORE EXEMPTING IT. Both sync loops skip an allowlisted
# pair before asking whether its twin exists, so deleting either copy left the check green —
# the exemption hiding exactly the missing-twin case the reverse loop was added to catch.
# A pair must EXIST on both sides and must ACTUALLY differ, or the exemption is a defect.
for pair in $DIVERGENT_ALLOWLIST; do
  a="$PAYLOAD/.agents/skills/$pair"
  c="$PAYLOAD/.claude/skills/$pair"
  skill_name="$pair"
  if [ ! -f "$a" ] || [ ! -f "$c" ]; then
    echo "ERROR: allowlisted pair '$pair' is missing on one side" >&2
    echo "  An exemption may not stand in for a file that is not there." >&2
    SKILL_SYNC_FAIL=1
    continue
  fi
  if diff -q "$a" "$c" >/dev/null 2>&1; then
    echo "ERROR: '$skill_name' is in DIVERGENT_ALLOWLIST but the copies are identical" >&2
    echo "  Remove it from the allowlist — it is masking future drift in this pair." >&2
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

# README badges are hand-maintained numbers in a file every release copies wholesale — the same
# class as the ledger header above, and it recurred exactly as that comment predicted: a project
# taking 2.6.0 read a version badge saying 2.3.23 and a failure-mode count 9 entries stale. A
# number a document states about itself is derived here or it drifts.
README="$HARNESS_ROOT/README.md"
if [ -f "$README" ] && [ -f "$LEDGER" ]; then
  LEDGER_COUNT=$(grep -c '^### AST-' "$LEDGER")
  BEFORE=$(cat "$README")
  sed -i '' -E "s|badge/version-[0-9]+\.[0-9]+\.[0-9]+-blue|badge/version-$VERSION-blue|g; \
                s|badge/failure_modes-[0-9]+_measured-red|badge/failure_modes-${LEDGER_COUNT}_measured-red|g; \
                s|releases/[0-9]+\.[0-9]+\.[0-9]+/ADAPT-HARNESS\.md|releases/$VERSION/ADAPT-HARNESS.md|g" "$README"
  [ "$BEFORE" = "$(cat "$README")" ] || echo "README badges auto-updated: version $VERSION, $LEDGER_COUNT failure modes"
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
# REGENERATE THE DERIVED FILES AGAINST THE STAGED TREE, not the source tree. The line above
# INJECTS a file the source does not have at that path, and it cites ledger entries — so an
# index generated from the source is stale for the payload by exactly those citations, and the
# staging gate below then refuses the release. Measured downstream: five rows short, and the
# immutability rule correctly refused an in-place repair, leaving `--plan` and `--apply` both
# unreachable for the release that shipped it. Derived files are derived from what SHIPS.
bash "$STAGING_DIR/harness/scripts/ledger-index.sh" >/dev/null 2>&1 || true
python3 "$STAGING_DIR/harness/scripts/ledger-rules.py" "$STAGING_DIR" >/dev/null 2>&1 || true
cp "$HARNESS_ROOT/VERSION"            "$STAGING_DIR/VERSION"
# STAGE THE INSTALLER ITSELF. Every "Upgrade from" note and ADAPT-HARNESS tell an operator to
# run `./install.sh <target> --apply`, and the staged release did not contain one — so the
# arbitration logic, the owner-path rules and any fix to them were unreachable from the only
# place the instructions point at. A downstream project reported it after computing arbitration
# BY HAND because there was nothing to run. An instruction that names a file the release does
# not ship is the class commit 037c847 was written to close, arriving one directory over.
cp "$HARNESS_ROOT/install.sh"         "$STAGING_DIR/install.sh"
# Templates are optional: 1.0.0 ships none, because the adaptation agent derives project
# docs from the repo itself rather than scaffolding them. Staged when a later version adds
# them, so this line needs no revisit then.
[ -d "$HARNESS_ROOT/templates" ] && cp -R "$HARNESS_ROOT/templates" "$STAGING_DIR/templates"
find "$STAGING_DIR" -name '.DS_Store' -delete

# THE SELF-CHECKS RUN HERE, at staging. Commit 54c85c2 kept them out of role contracts on
# purpose — a rule in a contract is read every time a role starts, and most projects never
# edit the harness. That argument holds, and it leaves exactly one moment where the cadence
# belongs: the release. This script already refuses to stage on a bad RELEASE-NOTES heading
# and on skill-sync drift; it ran none of the three checks written to catch the rest.
SELFCHECK_FAIL=0
# Invoke each check DIRECTLY with quoted arguments. Storing them as strings and running an
# unquoted "$cmd" field-splits a root like `/tmp/Astraler Repo` into two arguments, and all
# four checks then fail on a perfectly valid checkout — a gate that refuses correct installs
# teaches its operator to bypass it.
run_selfcheck() {  # $1 = label, rest = argv
  _label="$1"; shift
  if ! _out="$("$@" 2>&1)"; then
    echo "ERROR: $_label failed — the release does not ship until it passes" >&2
    printf '%s\n' "$_out" | sed 's/^/    /' >&2
    SELFCHECK_FAIL=1
  fi
}
run_selfcheck check-reachability python3 "$HARNESS_ROOT/harness/scripts/check-reachability.sh" "$HARNESS_ROOT"
run_selfcheck docs-staleness     bash    "$HARNESS_ROOT/harness/scripts/docs-staleness-audit.sh" "$HARNESS_ROOT"
# These two run against the STAGED tree: it is what a project receives, and it differs from the
# source by the injected check-requirements.sh above.
run_selfcheck ledger-index       bash    "$STAGING_DIR/harness/scripts/ledger-index.sh" --check
run_selfcheck ledger-rules       python3 "$STAGING_DIR/harness/scripts/ledger-rules.py" "$STAGING_DIR" --check
# The suite reproduces every invocation-shape defect this package has shipped — INCLUDING three
# that stage releases, so it invokes this script. Without the guard below that is unbounded
# recursion, which is what the first attempt did: install.sh -> selftest -> install.sh, until a
# timeout. The comment warning about nesting was already written when I wrote the bug.
if [ -z "${ASTRALER_IN_SELFTEST:-}" ]; then
  ASTRALER_IN_SELFTEST=1 run_selfcheck selftest bash "$HARNESS_ROOT/harness/scripts/selftest.sh"
fi
[ "$SELFCHECK_FAIL" -eq 0 ] || {
  echo >&2
  echo "Three checks, run together on purpose: they catch different classes, and a release" >&2
  echo "that ran only one shipped defects of the other two." >&2
  exit 1
}

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
#     and model rows (AST-041); `.claude/settings.json` carries owner-tuned Claude hooks; and
#     `.codex/profiles/` carries machine-profile templates. Written only when absent.
#     `.codex/hooks.json` and `.codex/agents/` are payload: they contain no model choice and
#     must receive safety fixes on upgrade.
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

  # Scaffold: written once, never overwritten. `.codex/profiles/` is named as scaffold by
  # ADAPT-HARNESS alongside orchestrator.md and was surviving only because arbitration
  # happened to land on kept/CONFLICT — incidental, not declared.
  OWNER_PATHS=".agents/orchestrator.md .claude/settings.json .codex/profiles"
  # The arbiter for "did the project change this, or did the package?" is the release the
  # project last received. `state/applied-version` records it — but a project may predate
  # project adapted before that has a full harness and no marker. Fall back to the newest
  # staged release below this one: it is what the project was last given, whatever integrated it.
  PREV_VERSION="$(cat "$APPLIED_FILE" 2>/dev/null || true)"
  if [ -z "$PREV_VERSION" ] || [ ! -d "$RELEASES_DIR/$PREV_VERSION/harness" ]; then
    # `|| true` because grep exits 1 when nothing survives the filter, and under
    # `set -euo pipefail` that status reaches the assignment and kills the script — silently,
    # mid-run, with no diagnostic. The state that triggers it is ordinary: a project whose
    # applied-version names a release it no longer has staged, and no older one staged either,
    # which is every project that prunes or gitignores `.astraler/releases/`. Measured on a
    # 2.6.1 project taking 2.7.0: `--apply` printed its header, wrote nothing, and exited 1
    # without a word. An operator reads that as done.
    PREV_VERSION="$(ls "$RELEASES_DIR" 2>/dev/null | grep -v "^$VERSION\$" \
      | sort -t. -k1,1n -k2,2n -k3,3n | tail -1 || true)"
    if [ -n "$PREV_VERSION" ]; then
      echo "  (applied-version names a release that is not staged — comparing against $PREV_VERSION)"
      echo
    else
      echo "  NO BASELINE: no staged release to compare against, so every project file that"
      echo "  differs from this one is a CONFLICT rather than an update. That is the safe"
      echo "  reading and it is noisy on purpose — nothing is overwritten without you saying so."
      echo
    fi
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
    # Exact match OR directory prefix: an entry naming a directory (.codex/profiles) has to
    # own every file under it, or the scaffold rule protects the name and not the contents.
    for o in $OWNER_PATHS; do
      case "$REL" in "$o"|"$o"/*) OWNED=1 ;; esac
    done
    if [ "$OWNED" -eq 1 ]; then
      if [ -e "$DST" ]; then
        echo "  owner   $REL (kept — yours)"; N_OWNER=$((N_OWNER+1))
        # Keeping the owner's file is right for their TUNING and wrong for the HOOK SET: hooks
        # are safety machinery the release ships, so a project that keeps its copy keeps the
        # hooks it had on install day and is told nothing. Measured on a 2.7.10 project: the
        # release carried a hook event the project lacked, this branch printed "kept — yours",
        # and the missing hook was invisible. Report the gap; merging is ADAPT-HARNESS §4's job,
        # because only a reader can tell an owner's deliberate removal from a stale copy.
        if [ "$REL" = ".claude/settings.json" ]; then
          MISSING_HOOKS="$(python3 - "$SRC" "$DST" <<'PY' 2>/dev/null || true
import json, sys
def events(p):
    try:
        with open(p) as f: return set(json.load(f).get("hooks", {}))
    except Exception: return None
ship, proj = events(sys.argv[1]), events(sys.argv[2])
# None means unreadable/unparseable — say nothing rather than claim every hook is missing.
if ship is not None and proj is not None:
    print(" ".join(sorted(ship - proj)))
PY
)"
          if [ -n "$MISSING_HOOKS" ]; then
            echo "          ACTION: this release ships hook event(s) your copy has no entry for:"
            echo "          $MISSING_HOOKS"
            echo "          Merge them in, keeping your own keys and hooks (ADAPT-HARNESS §4)."
          fi
        fi
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

  # DELETIONS. The loop above iterates the CANDIDATE's files and therefore has no concept of a
  # path the PREVIOUS release carried and this one does not. A RENAME is invisible to it as a
  # deletion: 2.7.6 renamed `ledger-rules.sh` to `.py`, an apply wrote the new name and left
  # the old, and the adapted project carried two byte-identical copies of one script under two
  # names. Nothing downstream catches it either — `check-payload-drift` does not watch it, and
  # the integration check cannot, because a file the release does not ship is not a file that
  # DIFFERS from the release. Left alone, every rename this package ever makes leaves a fossil
  # in every adapted repo, forever.
  #
  # Reported, not removed: a project may have adopted the old path on purpose, and deleting
  # files during an upgrade is how an upgrade destroys work. The operator decides.
  # BASELINE IS EVERY OLDER RELEASE ON DISK, not just the applied one. A rename is only visible
  # on the single upgrade step that performs it, so comparing `applied - candidate` misses it
  # for ANY project that skips a release — which is the case this package exists to serve, and
  # was the situation of the project that found this. Verified downstream by restoring the real
  # fossil and re-running: the applied-only baseline still answered 0.
  #
  # The union of every staged release older than the candidate is what a project may actually
  # be carrying, and it costs one extra walk of directories already on disk.
  N_GONE=0; GONE=""
  BASELINE_DIRS=""
  for _d in "$RELEASES_DIR"/*/harness; do
    [ -d "$_d" ] || continue
    _v="$(basename "$(dirname "$_d")")"
    [ "$_v" = "$VERSION" ] && continue
    BASELINE_DIRS="$BASELINE_DIRS $_d"
  done
  [ -n "$BASELINE_DIRS" ] || BASELINE_DIRS="$PREV_DIR"
  if [ -n "$BASELINE_DIRS" ]; then
    while IFS= read -r OLDREL; do
      [ -n "$OLDREL" ] || continue
      [ -e "$RELEASE_DIR/harness/$OLDREL" ] && continue      # still shipped
      [ -e "$TARGET/$OLDREL" ] || continue                    # already gone from the project
      case "$OLDREL" in .agents/orchestrator.md|.claude/settings.json|.codex/profiles/*) continue ;; esac
      GONE="$GONE  $OLDREL"$'\n'; N_GONE=$((N_GONE+1))
    done < <(for _d in $BASELINE_DIRS; do (cd "$_d" && find . -type f ! -name '.DS_Store' | sed 's|^\./||'); done | sort -u)
  fi
  if [ "$N_GONE" -gt 0 ]; then
    echo
    echo "DELETED upstream — an earlier release shipped these, $VERSION does not, and they are"
    echo "still in the project. Usually a rename; check for the new name before removing."
    printf '%s' "$GONE"
    echo "  (not removed automatically: a project may have adopted one of these on purpose)"
  fi

  echo
  echo "  new $N_NEW · updated $N_UPD · unchanged $N_SAME · kept $N_KEPT · owner-kept $N_OWNER · conflicts $N_CONFLICT · deleted-upstream $N_GONE"
  # --apply lands the payload; ADAPT-HARNESS section 7 still owns the semantic half.
  #
  # DO NOT STAMP OVER OUTSTANDING CONFLICTS. `applied-version` is the arbiter for the NEXT
  # upgrade and the ownership manifest `check-reachability.sh` reads. Stamping it while files
  # are unreconciled tells both consumers a release landed cleanly when it did not, and the
  # lie is silent. A run with conflicts leaves the previous marker in place; re-run once the
  # conflicts are resolved, or stamp by hand having decided.
  if [ "$PLAN" -eq 0 ]; then
    if [ "$N_CONFLICT" -gt 0 ]; then
      echo "  NOTE: applied-version NOT stamped — $N_CONFLICT conflict(s) outstanding."
      echo "        Resolve them, then re-run, or write $VERSION into $APPLIED_FILE by hand."
    else
      mkdir -p "$(dirname "$APPLIED_FILE")"; printf '%s\n' "$VERSION" > "$APPLIED_FILE"
    fi
  fi

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
  PENDING_FILE="$TARGET/.astraler/state/apply-incomplete"
  if [ "$N_CONFLICT" -gt 0 ]; then
    # LEAVE A DURABLE TRACE, because exit 3 does not survive the moment. A later check has to
    # tell "an apply stopped here" from "a newer release is staged and nobody has started it" —
    # two states that look identical when all you compare is applied-version against CANDIDATE.
    # Collapsing them turned a healthy project's own acceptance gate red the instant someone
    # upstream ran `install.sh`, with no action by that project and nothing wrong with it.
    mkdir -p "$(dirname "$PENDING_FILE")"
    { echo "version: $VERSION"; echo "at: $(date -u +%FT%TZ)"; echo "conflicts:";
      printf '%s' "$CONFLICTS" | sed 's|^|  |'; } > "$PENDING_FILE"
    # PARTIALLY applied, and it must not read as success. The non-conflicting files are
    # already on disk while `applied-version` still names the previous release, so ownership
    # checks run against the old manifest over a hybrid payload. Exit 3 — distinct from 1 so
    # automation can tell "pending arbitration" from "this run failed".
    echo "Payload PARTIALLY applied — $N_CONFLICT conflict(s) outstanding."
    echo "The non-conflicting files are written; applied-version still names the previous"
    echo "release, so this checkout is a hybrid until each conflict above is decided."
    echo "Resolve them, then re-run --apply. Where you deliberately keep the project's"
    echo "version, stamp $VERSION into .astraler/state/applied-version by hand, say why, AND"
    echo "delete .astraler/state/apply-incomplete — that file is what says the work is not"
    echo "finished, and a stamp alone leaves it behind asserting the opposite."
    exit 3
  fi
  rm -f "$PENDING_FILE"
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
