#!/usr/bin/env bash
# astragentic.sh — the project's own view of its harness release. `install.sh --apply` puts a
# copy at `<project>/.astraler/astragentic.sh`, so from inside the project:
#
#   .astraler/astragentic.sh update           installed vs latest, what changed between, the one-liner
#   .astraler/astragentic.sh update --apply   pull the latest release and apply it (get.sh latest --apply)
#   .astraler/astragentic.sh version          the installed version only
#   .astraler/astragentic.sh doctor           5.0.0: is the installed scaffold whole — exit 0 clean, 1 findings (5.0.1: settings*.json exempt)
#
# `update` changes nothing: it reads `.astraler/state/applied-version`, asks the package remote
# for its newest v-tag, prints the release notes of every release in between, and prints the
# command that upgrades. Applying stays the owner's decision (the one-liner, or `--apply` here).
#
# Why this exists: get.sh (2.22.0) let a project pull its own release, but nothing in the
# project could say which release it had, which was newest, or what the gap held — a question
# the owner asked on 2026-10-14 and answered by hand each time.
#
# Environment (shared with get.sh):
#   ASTRAGENTIC_REPO    git URL or local path of the package (default: the GitHub repo)
#   ASTRAGENTIC_RAW     base URL for raw files of a tag (default: raw.githubusercontent.com/<repo>)
#   ASTRAGENTIC_CACHE   where get.sh keeps releases (default: ~/.cache/astragentic)
set -euo pipefail

REPO="${ASTRAGENTIC_REPO:-https://github.com/thientranhung/astragentic.git}"
RAW="${ASTRAGENTIC_RAW:-https://raw.githubusercontent.com/thientranhung/astragentic}"
CACHE="${ASTRAGENTIC_CACHE:-$HOME/.cache/astragentic}"
GET_URL="https://raw.githubusercontent.com/thientranhung/astragentic/main/get.sh"

CMD="${1:-update}"
APPLY=0
for arg in "${@:2}"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    *) echo "astragentic.sh: unknown argument $arg" >&2; exit 2 ;;
  esac
done

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
APPLIED_FILE="$ROOT/.astraler/state/applied-version"
installed="$(cat "$APPLIED_FILE" 2>/dev/null | tr -d '[:space:]' || true)"

case "$CMD" in
  version)
    echo "${installed:-none}"; exit 0 ;;
  doctor)
    # DOCTOR (5.0.0, minimal; the eight-group doctor is 5.1). Three questions a release
    # cannot answer for the project after it lands, each with the number it counted:
    #   1. no retired name (the Matt Pocock plugin, the BMAD personas) in payload, plugs or overlays
    #   2. every astra-* skill present in both trees and identical (install.sh:67-104 asks the same
    #      of the package; this asks it of the project after a partial apply or a hand edit)
    #   3. the dispatch mod's brief regex and flow table name skills that exist
    # Exit 1 on any finding, so a gate can read it (CLAUDE.md: verify exit codes, not strings).
    findings=0
    say() { printf '  %s\n' "$1"; }
    bad_() { findings=$((findings+1)); printf '  FAIL %s\n' "$1"; }
    echo "astragentic doctor · $ROOT · installed ${installed:-none}"
    # 1. retired names
    scope=""
    for d in .agents .claude .astraler/project; do [ -d "$ROOT/$d" ] && scope="$scope $ROOT/$d"; done
    # shellcheck disable=SC2086
    # `.claude/settings*.json` is configuration, not a reference: the per-project way to turn the
    # old plugin OFF is the key `"mattpocock-skills@mattpocock": false` in it (nizzy, 2026-10-29,
    # the day 5.0.0 landed), and a scan that flags the off switch asks for a machine-wide uninstall.
    # `.claude/worktrees/` holds whole checkouts of live Builder panes (5.0.5: nizzy, 5 930 hits
    # from two worktrees, 0 in the checkout itself); node_modules is never ours.
    hits="$(grep -rIl --exclude-dir=memory --exclude-dir=worktrees --exclude-dir=node_modules --exclude=recurring-failure-modes.md --exclude='settings*.json' -e 'mattpocock-skills' -e 'bmad-' $scope 2>/dev/null | sed "s#^$ROOT/##" || true)"
    n="$(printf '%s' "$hits" | grep -c . || true)"
    if [ "$n" -eq 0 ]; then say "ok   0 files name a retired skill or persona in .agents, .claude, .astraler/project"
    else bad_ "$n file(s) still name mattpocock-skills or bmad-* (5.0.0 ships astra-* only):"; printf '%s\n' "$hits" | sed 's/^/         /'; fi
    # 2. astra-* skills, paired and identical
    want="astra-grill-with-docs astra-ux astra-to-spec astra-to-tickets astra-implement-with-tdd astra-ui astra-review"
    okn=0
    for sk in $want; do
      a="$ROOT/.agents/skills/$sk/SKILL.md"; c="$ROOT/.claude/skills/$sk/SKILL.md"
      if [ ! -f "$a" ] || [ ! -f "$c" ]; then bad_ "$sk: SKILL.md missing in $([ -f "$a" ] || printf '.agents ')$([ -f "$c" ] || printf '.claude')"
      elif ! cmp -s "$a" "$c"; then bad_ "$sk: .agents and .claude copies differ"
      elif ! head -1 "$a" | grep -q '^---$' || ! grep -q "^name: $sk\$" "$a"; then bad_ "$sk: SKILL.md has no frontmatter naming it"
      else okn=$((okn+1)); fi
    done
    say "ok   $okn/7 astra-* skills present in both trees, identical, with frontmatter"
    # 3. the mod points at skills that exist
    mod="$ROOT/.claude/skills/astragentic-dispatch/hooks/register.tsx"
    if [ ! -f "$mod" ]; then bad_ "dispatch mod not found at .claude/skills/astragentic-dispatch/hooks/register.tsx"
    else
      if grep -qF '/^\/astra-implement-with-tdd\b/' "$mod" && [ -f "$ROOT/.agents/skills/astra-implement-with-tdd/SKILL.md" ]; then
        say "ok   the mod recognises a Builder brief by /astra-implement-with-tdd, and that skill exists"
      else bad_ "the mod's Builder-brief regex does not name /astra-implement-with-tdd, or that skill is missing"; fi
      missing=""
      for sk in $(grep -o "\['astra-[a-z-]*'" "$mod" | tr -d "['" | sort -u); do
        [ -f "$ROOT/.agents/skills/$sk/SKILL.md" ] || missing="$missing $sk"
      done
      if [ -z "$missing" ]; then say "ok   every astra-* name in the mod's flow table has a SKILL.md"
      else bad_ "the mod's flow table names skills with no SKILL.md:$missing"; fi
    fi
    if [ "$findings" -eq 0 ]; then echo "doctor: clean"; exit 0; fi
    echo "doctor: $findings finding(s)"; exit 1 ;;
  update) ;;
  --help|-h|help)
    sed -n '2,21p' "$0"; exit 0 ;;
  *)
    echo "astragentic.sh: unknown command $CMD (update | update --apply | version | doctor)" >&2; exit 2 ;;
esac

# Numeric sort of dotted versions: `sort` alone reads 0.0.10 below 0.0.9.
vsort() { sort -t. -k1,1n -k2,2n -k3,3n; }
# vgt a b → a is newer than b
vgt() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | vsort | tail -1)" = "$1" ]; }

tags="$(git ls-remote --tags --refs "$REPO" 2>/dev/null \
  | awk -F'refs/tags/v' '/refs\/tags\/v[0-9]/{print $2}' | vsort)" || true
[ -n "$tags" ] || { echo "astragentic.sh: could not list release tags at $REPO (offline, or the remote refused)" >&2; exit 1; }
latest="$(printf '%s\n' "$tags" | tail -1)"

if [ -z "$installed" ]; then
  echo "astragentic: not applied in $ROOT (no .astraler/state/applied-version) · latest release $latest"
  echo
  echo "To stage it, in the project root:"
  echo "  curl -fsSL $GET_URL | bash -s -- $latest"
  exit 0
fi

if ! vgt "$latest" "$installed"; then
  echo "astragentic: installed $installed — this is the latest release."
  exit 0
fi

between="$(printf '%s\n' "$tags" | while IFS= read -r t; do vgt "$t" "$installed" && echo "$t"; done)"
n="$(printf '%s\n' "$between" | grep -c .)"
echo "astragentic: installed $installed · latest $latest ($n release(s) behind: $(printf '%s\n' "$between" | paste -sd, - | sed 's/,/, /g'))"
echo

# The notes of the releases in between, from the latest tag's RELEASE-NOTES.md: a local
# package path is read with git, a fetched release from get.sh's cache, anything else over HTTPS.
notes=""
if [ -d "$REPO" ]; then
  notes="$(git -C "$REPO" show "v$latest:RELEASE-NOTES.md" 2>/dev/null || true)"
elif [ -f "$CACHE/$latest/RELEASE-NOTES.md" ]; then
  notes="$(cat "$CACHE/$latest/RELEASE-NOTES.md")"
elif command -v curl >/dev/null 2>&1; then
  notes="$(curl -fsSL "$RAW/v$latest/RELEASE-NOTES.md" 2>/dev/null || true)"
fi
if [ -n "$notes" ]; then
  printf '%s\n' "$notes" | awk -v inst="$installed" '
    /^# Astragentic [0-9]/ {
      v = $3; keep = 0
      n = split(v, a, "."); m = split(inst, b, ".")
      for (i = 1; i <= 3; i++) { x = (i <= n) ? a[i] + 0 : 0; y = (i <= m) ? b[i] + 0 : 0
        if (x > y) { keep = 1; break } if (x < y) { break } }
    }
    keep { print }'
else
  echo "(release notes not readable from here — read RELEASE-NOTES.md in the release once staged)"
  echo
fi

echo "To upgrade, in the project root:"
echo "  curl -fsSL $GET_URL | bash -s -- $latest --apply"
echo "or:"
echo "  .astraler/astragentic.sh update --apply"
echo "Then read .astraler/releases/$latest/ADAPT-HARNESS.md for what the release asks of this"
echo "project, and restart the dispatcher pane: the dispatch mod loads at a session's start."

if [ "$APPLY" -eq 1 ]; then
  echo
  echo "astragentic: applying $latest"
  cd "$ROOT"
  # The receipt is written by this script, not by an agent reading the ADAPT prompt: a field
  # audit (2026-10-18) found a project with no receipt for three releases applied this way
  # (4.1.0). ONE home, `.astraler/state/ADAPTATION-REPORT.md`, OVERWRITTEN per apply — the
  # previous receipt is in git history, and an appended one accreted to 3,000 unread lines
  # (AST-129); ADAPT §7 has the agent add its exceptions under this header (4.1.1). Run the
  # installer (not exec), keep its output, and write the summary and the deleted-upstream block.
  out="$(mktemp)"
  if [ -d "$REPO" ] && [ -f "$REPO/get.sh" ]; then
    ASTRAGENTIC_REPO="$REPO" bash "$REPO/get.sh" "$latest" --apply 2>&1 | tee "$out"; rc=${PIPESTATUS[0]}
  else
    command -v curl >/dev/null 2>&1 || { echo "astragentic.sh: curl is required to fetch get.sh" >&2; exit 2; }
    curl -fsSL "$GET_URL" | ASTRAGENTIC_REPO="$REPO" bash -s -- "$latest" --apply 2>&1 | tee "$out"; rc=${PIPESTATUS[1]}
  fi
  if [ "$rc" -eq 0 ]; then
    mkdir -p "$ROOT/.astraler/state"
    {
      echo "## $latest applied $(date '+%F %T') via astragentic.sh update --apply (from $installed)"
      echo
      grep -E '^[[:space:]]*new [0-9]+ · updated' "$out" | head -1 | sed 's/^[[:space:]]*/- /'
      if grep -q 'DELETED upstream' "$out"; then
        echo "- DELETED upstream (still in the project; remove by hand):"
        awk '/DELETED upstream/{f=1; next} f && /^[[:space:]]*\(not removed/{exit} f && /^[[:space:]]+[^[:space:]]/{print "  - " $1}' "$out"
      fi
    } > "$ROOT/.astraler/state/ADAPTATION-REPORT.md"
    echo "astragentic: receipt written to .astraler/state/ADAPTATION-REPORT.md (add exceptions under it: ADAPT §7)"
  fi
  rm -f "$out"
  exit "$rc"
fi
