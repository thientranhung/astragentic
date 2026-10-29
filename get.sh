#!/usr/bin/env bash
# get.sh — install or upgrade the Astragentic harness from inside the project that takes it.
#
#   curl -fsSL https://raw.githubusercontent.com/thientranhung/astragentic/main/get.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/thientranhung/astragentic/main/get.sh | bash -s -- 2.21.6
#   curl -fsSL https://raw.githubusercontent.com/thientranhung/astragentic/main/get.sh | bash -s -- latest --apply
#
# Run it in the project's root. It fetches ONE tagged release of the package into
# ~/.cache/astragentic/<version>/ and runs THAT release's own install.sh against the current
# directory — so staging, the three-way arbitration and the hook merge are exactly the ones the
# release shipped with, never a newer installer reading an older payload. By default it stages
# only (writes .astraler/releases/<version>/, edits no project file) and prints the ADAPT
# instruction; `--apply` is passed through to install.sh.
#
# Why this exists: until 2.22.0 every upgrade was run from the package's own checkout, pointed
# at the project — a second repo on the machine and a person standing between them. A project
# should pull its own upgrade the way it pulls any dependency.
#
# Environment:
#   ASTRAGENTIC_REPO    git URL or local path of the package (default: the GitHub repo)
#   ASTRAGENTIC_CACHE   where releases are kept (default: ~/.cache/astragentic)
set -euo pipefail

REPO="${ASTRAGENTIC_REPO:-https://github.com/thientranhung/astragentic.git}"
CACHE="${ASTRAGENTIC_CACHE:-$HOME/.cache/astragentic}"
VERSION="latest"
PASS=()
for arg in "$@"; do
  case "$arg" in
    --apply|--plan) PASS+=("$arg") ;;
    --help|-h)
      sed -n '2,20p' "$0" 2>/dev/null || true
      exit 0 ;;
    -*) echo "get.sh: unknown option $arg" >&2; exit 2 ;;
    *) VERSION="$arg" ;;
  esac
done

TARGET="$(pwd)"
if ! git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  echo "get.sh: $TARGET is not a git repository. Run this inside the project that takes the harness." >&2
  exit 2
fi
command -v git >/dev/null 2>&1 || { echo "get.sh: git is required" >&2; exit 2; }

# Resolve "latest" to the newest v-tag on the remote, so what lands is a tagged release and the
# version it reports is the one the project's receipt will name.
if [ "$VERSION" = "latest" ]; then
  VERSION="$(git ls-remote --tags --refs "$REPO" 2>/dev/null \
    | awk -F'refs/tags/v' '/refs\/tags\/v[0-9]/{print $2}' \
    | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)"
  [ -n "$VERSION" ] || { echo "get.sh: could not list release tags at $REPO" >&2; exit 1; }
fi
VERSION="${VERSION#v}"

DEST="$CACHE/$VERSION"
if [ ! -f "$DEST/install.sh" ]; then
  # THE CACHE IS SHARED AND TWO PROJECTS UPGRADE AT ONCE (5.0.2). nizzy and inception applied
  # 5.0.1 in the same minute: each saw no install.sh, each `rm -rf`-ed the other's half-cloned
  # tree, one printed "no release tag" for a clone it had itself broken, the other lost ~30 files
  # mid-staging (nizzy report 2026-10-29). So: clone into a private temp dir beside the cache,
  # then ONE rename into place — a rename is atomic, so DEST is either whole or absent, and a
  # loser whose rename finds DEST already there discards its own copy and uses the winner's.
  mkdir -p "$CACHE"
  if [ -d "$DEST" ]; then mv "$DEST" "$DEST.stale.$$" 2>/dev/null && rm -rf "$DEST.stale.$$"; fi
  if ! git ls-remote --tags --refs "$REPO" "refs/tags/v$VERSION" 2>/dev/null | grep -q .; then
    echo "get.sh: no release tag v$VERSION at $REPO (or the remote could not be listed)" >&2; exit 1
  fi
  TMPD="$CACHE/.fetch-$VERSION-$$"
  rm -rf "$TMPD"
  echo "get.sh: fetching astragentic v$VERSION into $DEST"
  git clone --quiet --depth 1 --branch "v$VERSION" "$REPO" "$TMPD" \
    || { echo "get.sh: clone of v$VERSION from $REPO failed (the tag exists; network, lock or disk)" >&2; rm -rf "$TMPD"; exit 1; }
  if [ -f "$DEST/install.sh" ]; then
    rm -rf "$TMPD"                      # another run won the race; its tree is whole
  elif ! mv "$TMPD" "$DEST" 2>/dev/null; then
    rm -rf "$TMPD"
    [ -f "$DEST/install.sh" ] || { echo "get.sh: could not place v$VERSION at $DEST" >&2; exit 1; }
  fi
fi
GOT="$(cat "$DEST/VERSION" 2>/dev/null || true)"
if [ "$GOT" != "$VERSION" ]; then
  echo "get.sh: $DEST says VERSION=$GOT, expected $VERSION — refusing to run a mismatched installer" >&2
  exit 1
fi

echo "get.sh: running v$VERSION install.sh against $TARGET ${PASS[*]:-}"
exec bash "$DEST/install.sh" "$TARGET" ${PASS[@]+"${PASS[@]}"}
