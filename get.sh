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
  mkdir -p "$CACHE"
  rm -rf "$DEST"
  echo "get.sh: fetching astragentic v$VERSION into $DEST"
  git clone --quiet --depth 1 --branch "v$VERSION" "$REPO" "$DEST" \
    || { echo "get.sh: no release tag v$VERSION at $REPO" >&2; rm -rf "$DEST"; exit 1; }
fi
GOT="$(cat "$DEST/VERSION" 2>/dev/null || true)"
if [ "$GOT" != "$VERSION" ]; then
  echo "get.sh: $DEST says VERSION=$GOT, expected $VERSION — refusing to run a mismatched installer" >&2
  exit 1
fi

echo "get.sh: running v$VERSION install.sh against $TARGET ${PASS[*]:-}"
exec bash "$DEST/install.sh" "$TARGET" ${PASS[@]+"${PASS[@]}"}
