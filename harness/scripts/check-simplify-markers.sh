#!/bin/bash
# check-simplify-markers.sh <base> [head]
#
# Verifies the simplify-marker record on a range. Exit 0 = green, 1 = STOP.
#
# Why this is a script and not the inline shell it replaced: the rules below need per-commit
# state, and the portable-shell version of that reaches for bash-4 associative arrays. macOS
# ships bash 3.2, where `declare -A` and `mapfile` fail — and the failure mode measured while
# writing this was `markers=0`, i.e. GREEN on every macOS operator's machine (AST-122).
#
# The rules, and the attack each one closes:
#   1. A marker may carry AT MOST ONE `Supersedes:`. Without this, one genuine pass launders an
#      unbounded number of fabricated markers by listing their SHAs.
#   2. A marker that supersedes MUST itself be well-formed. Without this, rule 1 is evaded by
#      chaining fabricated markers, each superseding the last.
#   3. The named SHA must be a marker IN RANGE, and may be named by only one marker.
#   4. Green: every LIVE marker (not superseded by anything) is well-formed.
#
# RESIDUAL, stated because it is not closed: markers carry no increment identity — the subject
# is free prose. So nothing here proves the superseding pass covers the SAME increment as the
# marker it retracts. A Builder with two increments can still retract increment-1's marker
# using increment-2's real pass, leaving increment-1 uncovered. The counts are a filter, not a
# verdict: read the bodies.
exec python3 - "$@" <<'PY'
import re, subprocess, sys

base = sys.argv[1] if len(sys.argv) > 1 else None
head = sys.argv[2] if len(sys.argv) > 2 else "HEAD"
if not base:
    sys.exit("usage: check-simplify-markers.sh <base> [head]")

def git(*a):
    return subprocess.run(["git", *a], capture_output=True, text=True).stdout

MARK = "^simplify(increment):"
shas = git("log", f"{base}..{head}", "--grep", MARK, "--format=%H").split()

# ABSENCE IS A FINDING. A range with no markers is AST-094, not a quiet pass.
if not shas:
    print(f"markers=0 — STOP: no simplify marker on {base}..{head} (AST-094)")
    sys.exit(1)

WELL = 'Pass: Skill(skill: "simplify")'
SUP = re.compile(r"^Supersedes: ([0-9a-f]{7,40})\b", re.M)

stop = []
well, sup_of, superseded_by = {}, {}, {}
for sha in shas:
    body = git("log", "-1", sha, "--format=%b")
    well[sha] = WELL in body
    names = SUP.findall(body)
    short = sha[:9]
    if len(names) > 1:
        stop.append(f"{short} carries {len(names)} Supersedes lines; at most one is allowed")
    if names and not well[sha]:
        stop.append(f"{short} supersedes a marker but is not itself well-formed")
    for n in names[:1]:
        full = git("rev-parse", "--verify", f"{n}^{{commit}}").strip()
        if not full or full not in shas:
            stop.append(f"{short} supersedes {n}, which is not a marker in this range")
            continue
        if full in superseded_by:
            stop.append(f"{n[:9]} is superseded by more than one marker")
            continue
        superseded_by[full] = sha
        sup_of[sha] = full

live = [s for s in shas if s not in superseded_by]
livebad = [s for s in live if not well[s]]
print(f"markers={len(shas)} superseded={len(superseded_by)} live={len(live)} "
      f"live-without-provenance={len(livebad)}")
for s in livebad:
    stop.append(f"{s[:9]} is a live marker without the skill's provenance (AST-099)")

for msg in stop:
    print(f"  STOP: {msg}")
print("GREEN" if not stop else "NOT GREEN")
sys.exit(1 if stop else 0)
PY
