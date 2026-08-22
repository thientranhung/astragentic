#!/usr/bin/env bash
# check-payload-drift.sh — did a release overwrite something this PROJECT wrote?
#
# A project can author a file at a path a harness release also ships — a skill under
# `.agents/skills/`, a script under `scripts/`, a runtime adapter. Neither side can see the
# collision: upstream sees its own payload, not that a project authored a file there first.
# Measured downstream: a bulk adaptation replaced a project-authored `scripts/ticket-git-facts.sh`
# with the payload's version at the same path, mentioned it nowhere, and a doc that was accurate
# went false with nobody editing it (AST-132).
#
# `install.sh --apply` guards the same boundary at UPGRADE time, three-way against the previous
# staged release. This guards it at COMMIT time, against a hash the project recorded. They catch
# different halves: --apply catches the release overwriting the project, this catches the project
# and the payload diverging in between, including by a hand edit nobody reviewed.
#
# STATE lives in `.agents/payload-drift-manifest.json`, which the PAYLOAD DOES NOT SHIP — it is
# the project's, like `.agents/orchestrator.md`, so an upgrade cannot reset the hashes that make
# this check mean anything. Track it in git: the recorded hash should travel with the branch, so
# a finding reproduces on another clone.
#
# Usage:
#   scripts/check-payload-drift.sh                          # verify — exit 0 clean, 1 on drift
#   scripts/check-payload-drift.sh --update PATH [PATH...]  # after a REVIEWED edit, re-hash
#
# Never run --update to silence a finding you have not read. The whole mechanism is the pause.
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

MANIFEST=".agents/payload-drift-manifest.json"

sha() { shasum -a 256 "$1" | awk '{print $1}'; }

# Minimal manifest reader — no jq assumed. One process, one parse: prints a COUNT header, then
# "ENTRY<TAB>path<TAB>sha256" per hashed file and "SYMLINK<TAB>link<TAB>target" per dual-homed
# skill, so verifying N files costs one python launch rather than 1 + N.
#
# The COUNT header exists so that "the manifest is readable and watches nothing" and "the
# manifest could not be read" are DIFFERENT observations. Without it both look like empty
# output, and a fresh project with an empty manifest is indistinguishable from a machine with
# no python3 — one of those should pass and the other must not.
dump_manifest() {
  python3 - "$MANIFEST" <<'PY'
import json, sys
with open(sys.argv[1]) as fh:
    m = json.load(fh)
entries = m.get("entries", [])
links = m.get("symlinks", [])
print(f'COUNT\t{len(entries) + len(links)}')
for e in entries:
    print(f'ENTRY\t{e["path"]}\t{e.get("sha256", "")}')
for s in links:
    print(f'SYMLINK\t{s["link"]}\t{s["target"]}')
PY
}

if [ "${1:-}" = "--update" ]; then
  shift
  [ "$#" -ge 1 ] || { echo "usage: $0 --update PATH [PATH...]" >&2; exit 2; }
  if [ ! -f "$MANIFEST" ]; then
    mkdir -p "$(dirname "$MANIFEST")"
    cat > "$MANIFEST" <<'JSON'
{
  "_comment": "Project-authored files at payload-owned paths. scripts/check-payload-drift.sh fails pre-commit when one changes without --update. This file is the PROJECT's; no release ships it.",
  "entries": [],
  "symlinks": []
}
JSON
    echo "created $MANIFEST"
  fi
  for p in "$@"; do
    [ -f "$p" ] || { echo "FAIL: $p does not exist, cannot record a hash for it" >&2; exit 1; }
    h=$(sha "$p")
    python3 - "$MANIFEST" "$p" "$h" <<'PY'
import json, sys
manifest_path, path, h = sys.argv[1], sys.argv[2], sys.argv[3]
with open(manifest_path) as fh:
    m = json.load(fh)
m.setdefault("entries", [])
for e in m["entries"]:
    if e["path"] == path:
        e["sha256"] = h
        break
else:
    m["entries"].append({"path": path, "sha256": h})
with open(manifest_path, "w") as fh:
    json.dump(m, fh, indent=2)
    fh.write("\n")
PY
    echo "recorded $p -> $h"
  done
  exit 0
fi

# --- verify -------------------------------------------------------------------------
# A project may dual-home a skill: real content under `.agents/skills/<name>/`, with
# `.claude/skills/<name>/` a symlink to it, so both loaders see one file. A payload shipping a
# REAL directory at the .claude/ path breaks that silently — the symlink disappears and Claude
# Code starts reading a harness skill of the same name. SYMLINK rows watch the link itself.
# (This package's own payload keeps byte-identical copies instead; install.sh enforces that.
# Both arrangements are legal in a project, and this watches whichever one it is told about.)
findings=0

if [ ! -f "$MANIFEST" ]; then
  echo "No $MANIFEST — nothing is being watched yet."
  echo "Register the project-authored files that sit at payload-owned paths:"
  echo "  $0 --update <path> [<path>...]"
  exit 0
fi

# Fail CLOSED on a reader failure, not clean. `< <(dump_manifest)` does not propagate the
# reader's exit status, so a missing python3 or a corrupt manifest would iterate zero times and
# print "OK: 0 watched paths" with exit 0 — a reader failure reported as a passing check, which
# is worse than no check because it looks like one (AST-122's macOS `markers=0` shape exactly).
# `if var=$(cmd)` rather than a bare assignment, so `set -e` does not exit before status is set.
if manifest_output=$(dump_manifest 2>/dev/null); then
  dump_status=0
else
  dump_status=$?
fi
count=""
case "$manifest_output" in
  COUNT*) count=$(printf '%s\n' "$manifest_output" | head -1 | cut -f2) ;;
esac
if [ "$dump_status" -ne 0 ] || [ -z "$count" ]; then
  echo "FAIL: could not read $MANIFEST (reader exited $dump_status, no COUNT header)" >&2
  echo "Refusing to report OK on a manifest this run could not read — that is the exact" >&2
  echo "fail-open this mechanism exists to prevent." >&2
  exit 1
fi
if [ "$count" -eq 0 ]; then
  echo "OK: $MANIFEST is readable and watches 0 paths — this check is inert until you"
  echo "    register something with: $0 --update <path>"
  exit 0
fi

while IFS=$'\t' read -r kind a b; do
  case "$kind" in
  ENTRY)
    path="$a"; expected="$b"
    if [ ! -f "$path" ]; then
      echo "MISSING: $path is in the manifest but no longer exists on disk"
      findings=$((findings + 1)); continue
    fi
    if [ -z "$expected" ]; then
      echo "UNRECORDED: $path has no hash yet — run: $0 --update $path"
      findings=$((findings + 1)); continue
    fi
    actual=$(sha "$path")
    if [ "$actual" != "$expected" ]; then
      echo "DRIFT: $path content changed — recorded $expected, now $actual"
      echo "       If this is YOUR reviewed edit:  $0 --update $path"
      echo "       If you did not make this change: a release adaptation likely overwrote a"
      echo "       project-authored file at a payload-owned path (AST-132). Diff against git"
      echo "       history before accepting it."
      findings=$((findings + 1))
    fi
    ;;
  SYMLINK)
    link="$a"; want="$b"
    if [ ! -L "$link" ]; then
      echo "DRIFT: $link is no longer a symlink (expected -> $want) — a payload may have"
      echo "       shipped a real directory here, shadowing the project skill it points at"
      findings=$((findings + 1)); continue
    fi
    got=$(readlink "$link")
    if [ "$got" != "$want" ]; then
      echo "DRIFT: $link points at $got, expected $want"
      findings=$((findings + 1))
    fi
    ;;
  esac
done <<< "$manifest_output"

if [ "$findings" -gt 0 ]; then
  echo
  echo "$findings finding(s). AST-132 in .agents/memory/recurring-failure-modes.md is what"
  echo "this protects and why."
  exit 1
fi

echo "OK: $count watched path(s) match $MANIFEST"
