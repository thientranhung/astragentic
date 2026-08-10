#!/usr/bin/env bash
# gen-code-map.sh — emit a CODE-MAP.md SKELETON for one area of a repo.
#
#   scripts/gen-code-map.sh <dir> > /tmp/<area>-skeleton.md
#
# STDOUT ONLY, by design. It never writes a file and never touches curated prose: you copy
# the entry lines you want into the real CODE-MAP.md and replace each "TODO" with a
# description you sourced from the code. That split is the point — the script supplies the
# structure it can prove (what directories and files exist), and a human or an agent that
# has READ the code supplies the meaning. A generator that wrote descriptions would be
# inventing exactly what this package says to extract.
#
# Language-agnostic: the source root and file extensions are detected, then overridable.
#   SRC_DIRS="lib app"        source roots to try, in order
#   EXTS="go rs"              file extensions to list
set -euo pipefail

usage() { echo "Usage: $0 <dir>   (e.g. $0 packages/api)" >&2; exit 1; }

[ $# -eq 1 ] || usage
dir="${1%/}"
[ -d "$dir" ] || { echo "error: not a directory: $dir" >&2; exit 1; }

# Find the source root: an explicit override, else the first conventional directory that
# exists, else the directory itself for repos that keep sources at the top.
src=""
for candidate in ${SRC_DIRS:-src lib app pkg internal cmd source}; do
  [ -d "$dir/$candidate" ] && { src="$dir/$candidate"; break; }
done
[ -n "$src" ] || src="$dir"

# Detect extensions from what is actually present, unless told otherwise. Counting real
# files avoids emitting an empty map for a language nobody thought to hardcode.
if [ -n "${EXTS:-}" ]; then
  exts="$EXTS"
else
  # `|| true` on the grep: pipefail is on, and a directory with no matching file makes
  # grep exit 1, which would abort here with no message instead of reaching the guard below.
  exts="$( { find "$src" -type f -name '*.*' 2>/dev/null \
    | sed 's|.*/||; s|^.*\.||' \
    | grep -Ex '[A-Za-z0-9]+' || true; } \
    | sort | uniq -c | sort -rn | head -4 | awk '{print $2}' | tr '\n' ' ')"
fi
[ -n "${exts// /}" ] || { echo "error: no source files found under $src" >&2; exit 1; }

find_expr=()
for e in $exts; do find_expr+=(-o -name "*.$e"); done
find_expr=("${find_expr[@]:1}")   # drop the leading -o

area="$(basename "$dir")"

echo "# CODE-MAP — $area"
echo "<!-- Skeleton: scripts/gen-code-map.sh · Semantics: curated by a reader"
echo "     RULES: the code outranks the map · the map points, grep confirms · keep it short"
echo "     Source root: ${src#"$dir"/} · Extensions: $exts -->"
echo
echo "## What it is (3 lines)"
echo "TODO"
echo
echo "## Package map (path · 1-line responsibility · mark hot files)"
echo
echo "### directories"
find "$src" -mindepth 1 -maxdepth 2 -type d \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  | LC_ALL=C sort | while IFS= read -r d; do
  echo "- ${d#"$dir"/}/ — TODO: responsibility"
done
echo
echo "### top-level files"
find "$src" -mindepth 1 -maxdepth 1 -type f \( "${find_expr[@]}" \) \
  | LC_ALL=C sort | while IFS= read -r f; do
  echo "- ${f#"$dir"/} — TODO: responsibility"
done
echo
echo "## Key seams (where a change plugs in)"
echo "TODO — name the places a change substitutes behaviour; see the legacy-testing skill"
echo
echo "## Data flow (1 line)"
echo "TODO"
echo
echo "## Gotchas (fix-blocking only, each citing an incident, ADR or file)"
echo "TODO"
