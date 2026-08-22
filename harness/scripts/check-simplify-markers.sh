#!/bin/bash
# check-simplify-markers.sh <base> [head] [--marker <prefix>]...
#
# Verifies the verification-marker record on a range. Exit 0 = green, 1 = STOP.
#
# Why this is a script and not the inline shell it replaced: the rules below need per-commit
# state, and the portable-shell version of that reaches for bash-4 associative arrays. macOS
# ships bash 3.2, where `declare -A` and `mapfile` fail — and the failure mode measured while
# writing this was `markers=0`, i.e. GREEN on every macOS operator's machine (AST-122).
#
# MARKER KINDS. The harness has more than one marker whose rules are identical, so the kind is
# data rather than a second script. `--marker` is repeatable; the default is the simplify pass.
# A kind is a list of the body lines a well-formed marker must carry — one entry per kind:
#
#   simplify(increment)   Pass: Skill(skill: "simplify")
#
# One kind ships today. `arm(ticket)` gets its row when its body format is fixed; a rule
# guessed ahead of the marker it validates is a rule the next release has to change.
#
# The rules, and the attack each one closes. 1-4 are the Supersedes economy and run on kinds
# with `economy: True`; 5 and 6 run on every kind:
#   1. A marker may carry AT MOST ONE `Supersedes:`. Without this, one genuine pass launders an
#      unbounded number of fabricated markers by listing their SHAs.
#   2. A marker that supersedes MUST itself be well-formed. Without this, rule 1 is evaded by
#      chaining fabricated markers, each superseding the last.
#   3. The named SHA must be a marker IN RANGE, and may be named by only one marker.
#   4. Every marker in the kind's SCOPE is well-formed — every live one, or the head one.
#   5. The newest live marker of each kind IS <head>. EXISTENCE IS NOT RELATIONSHIP: a marker
#      whose every field is true, with a later commit sitting on top of it, is a pass that did
#      not cover the code being merged — and rules 1-4 all pass on it (AST-122). The fix is
#      cheap and is already the protocol: commit a fresh marker. Markers are allowed to be
#      empty, so re-marking after a fold costs one commit.
#   6. Where a kind sets `reviewed`, the marker's `Reviewed:` SHA is its own parent — the marker
#      commits empty, so the parent IS the tree the gate read — OR it declares the gap with
#      `Unreviewed-delta:`. Never neither. A fold moves the tree past what any pass read, which
#      makes the first half legitimately false; the failure is declaring nothing (AST-134).
#
# RESIDUAL, stated because it is not closed: markers carry no increment identity — the subject
# is free prose. So nothing here proves the superseding pass covers the SAME increment as the
# marker it retracts. A Builder with two increments can still retract increment-1's marker
# using increment-2's real pass, leaving increment-1 uncovered. The counts are a filter, not a
# verdict: read the bodies.
#
# RESIDUAL, second and larger: every marker is a commit written by the agent being verified.
# A fork inside a Builder's session forged one carrying a sanctioned degraded `Pass:` line that
# quoted a real runtime error string — well-formed by every rule here (AST-130). This script
# checks the record's shape. It cannot check that the work happened.
exec python3 - "$@" <<'PY'
import re, subprocess, sys

# A KIND is a policy, not just a field list, because the two markers are verified for
# different reasons and measurement said so.
#
#   required   body substrings a well-formed marker must ALL carry. SUBSTRING, not line-anchored:
#              measured on a real corpus, `Vendor:`, `Tests:` and `Pass:` are commonly packed onto
#              ONE line separated by runs of spaces, and a `^Pass:` matcher fails on every one.
#   tokens     field -> the leading tokens its value may start with. Prefix, not equality:
#              `NOT RUN by the arm (...)` is a real and correct value.
#   scope      "live" validates every live marker; "head" validates only the marker that IS the
#              head. See below — this is the load-bearing difference between the two kinds.
#   economy    the Supersedes arithmetic from AST-121/AST-122.
#   reviewed   enforce `Reviewed:` == the marker's own parent, OR `Unreviewed-delta:` present.
#
# WHY THE SCOPES DIFFER, since a reviewer will ask. `simplify(increment)` validates every live
# marker because AST-122's economy depends on it: the rule that every fabricated marker costs its
# own genuine pass only holds if a junk live marker is a finding. Narrowing that kind to the head
# would hand back the laundering attack that entry was written to close.
#
# `arm(ticket)` validates the head marker only, and does not run the economy at all. Measured over
# 32 real arm markers: two are `Supersedes:` repairs (one of them a Builder catching the covers-head
# failure in the field and re-firing — the best outcome available) and one is a correction with no
# fields at all, correcting a prior marker's CLAIM rather than re-running the gate. All three are
# correct and a field-list validator rejects all three. They dissolve without a special case once
# the question is asked of the receipt instead of the history: the router merges one tree on one
# receipt, and whatever ends up at the head IS that receipt. Everything below it is narration.
# There is nothing to launder when exactly one commit is asserted against.
KINDS = {
    "simplify(increment)": {
        "required": ['Pass: Skill(skill: "simplify")'],
        "scope": "live",
        "economy": True,
    },
    "arm(ticket)": {
        # Not required, deliberately: `Output:` is absent in 4 of 32, prose in 3, and where it is
        # a path it is a session-scoped scratch path belonging to a Builder session that has since
        # ended — a pointer already dead when the router reads it. Requiring it buys presence, not
        # evidence. `Unreviewed-delta:` is optional by design (9 of 32).
        "required": ["Range:", "Reviewed:", "Vendor:", "Pass:"],
        "tokens": {"Tests:": ("RAN", "NOT RUN")},
        "scope": "head",
        "economy": False,
        "reviewed": True,
    },
}

# Do not parse a field's interior. `Range:` occurs as both `15 commits, 7 files (a..b)` and
# `main..f88d2c27 (3 commits, 6 files)`; `Pass:` carries an integer and an optional parenthetical,
# and `Pass: 8` is LEGAL against a two-pass cap when the gate re-fired per fold and no single
# invocation exceeded two. A validator asserting `Pass: <= 2` rejects a correct marker.

args = sys.argv[1:]
base = head = None
kinds = []
i = 0
while i < len(args):
    a = args[i]
    if a == "--marker":
        i += 1
        if i >= len(args):
            sys.exit("--marker needs a prefix")
        kinds.append(args[i])
    elif base is None:
        base = a
    elif head is None:
        head = a
    else:
        sys.exit(f"unexpected argument: {a}")
    i += 1

if not base:
    sys.exit("usage: check-simplify-markers.sh <base> [head] [--marker <prefix>]...")
head = head or "HEAD"
kinds = kinds or ["simplify(increment)"]
for k in kinds:
    if k not in KINDS:
        sys.exit(f"unknown marker kind '{k}' — known: {', '.join(KINDS)}")


def git(*a):
    return subprocess.run(["git", *a], capture_output=True, text=True).stdout


head_sha = git("rev-parse", "--verify", f"{head}^{{commit}}").strip()
if not head_sha:
    sys.exit(f"cannot resolve head '{head}'")

SUP = re.compile(r"^Supersedes: ([0-9a-f]{7,40})\b", re.M)
exit_code = 0

# ONE git call for the whole range, and NO `--grep`. The kinds carry parentheses, and
# `--grep` takes a POSIX BASIC regex where `\(` is a group rather than a literal — escaping
# the kind with Python's `re.escape` produced `markers=0` on a range that had one, which this
# script reports as a STOP that names the wrong cause. Matching subjects in Python removes the
# regex-dialect question entirely (AST-122: a fixture fails the same ways as the thing it
# tests; this was caught by a fixture that looked like it was working).
# Unit/record separators, not NUL: NUL cannot travel in argv (`ValueError: embedded null
# byte`), and these two do not occur in commit text.
REC, FLD = "\x1e", "\x1f"
commits = []
for rec in git("log", f"{base}..{head}", f"--format=%H{FLD}%s{FLD}%b{REC}").split(REC):
    rec = rec.strip("\n")
    if not rec:
        continue
    sha, subject, body = rec.split(FLD, 2)
    commits.append((sha, subject, body))

REVIEWED_RE = re.compile(r"\bReviewed:\s*([0-9a-f]{7,40})\b")


def field_value(body, field):
    """Text following `field` up to the end of the line. Substring, not line-anchored."""
    i = body.find(field)
    if i < 0:
        return None
    tail = body[i + len(field):]
    return tail.split("\n", 1)[0].strip()


def shortfalls(kind, sha, body):
    """Every reason this marker is not a well-formed receipt of its kind."""
    spec = KINDS[kind]
    out = [f"missing {f!r} (AST-099)" for f in spec["required"] if f not in body]
    for field, allowed in spec.get("tokens", {}).items():
        val = field_value(body, field)
        if val is None:
            out.append(f"missing {field!r} (AST-099)")
        elif not val.startswith(allowed):
            out.append(f"{field} does not start with one of {', '.join(allowed)}: {val[:40]!r}")
    if spec.get("reviewed"):
        # The marker commits EMPTY, so its parent is the tree the gate actually read. Where a fold
        # has moved the tree past what any pass read, `Reviewed: == parent` is structurally
        # impossible — and that is exactly when the delta must be declared rather than omitted.
        # Its ABSENCE where `Reviewed:` is not the parent is the failure (AST-134).
        m = REVIEWED_RE.search(body)
        parent = git("rev-parse", "--verify", f"{sha}^").strip()
        claimed = m.group(1) if m else ""
        if not (claimed and parent.startswith(claimed)) and "Unreviewed-delta:" not in body:
            out.append(
                f"Reviewed: {claimed[:9] or '(none)'} is not this marker's parent "
                f"({parent[:9]}) and no Unreviewed-delta: declares the gap (AST-134)")
    return out


for kind in kinds:
    spec = KINDS[kind]
    prefix = kind + ":"
    marks = [(sha, body) for sha, subject, body in commits if subject.startswith(prefix)]
    shas = [sha for sha, _ in marks]
    bodies = dict(marks)

    # ABSENCE IS A FINDING. A range with no markers is AST-094, not a quiet pass.
    if not shas:
        print(f"[{kind}] markers=0 — STOP: no marker on {base}..{head} (AST-094)")
        exit_code = 1
        continue

    stop = []
    well, missing, superseded_by = {}, {}, {}
    for sha in shas:
        body = bodies[sha]
        missing[sha] = shortfalls(kind, sha, body)
        well[sha] = not missing[sha]
        if not spec["economy"]:
            continue
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

    # `git log` lists newest first, so the first live marker is the newest one.
    live = [s for s in shas if s not in superseded_by]
    checked = live if spec["scope"] == "live" else live[:1]
    bad = [s for s in checked if not well[s]]
    print(f"[{kind}] markers={len(shas)} superseded={len(superseded_by)} live={len(live)} "
          f"validated={len(checked)} ({spec['scope']}) not-well-formed={len(bad)}")
    for s in bad:
        for m in missing[s]:
            stop.append(f"{s[:9]}: {m}")

    # Rule 5 — covers-head.
    if live and live[0] != head_sha:
        ahead = git("rev-list", "--count", f"{live[0]}..{head_sha}").strip() or "?"
        stop.append(
            f"newest live marker {live[0][:9]} is not the head being merged "
            f"({head_sha[:9]}); {ahead} commit(s) sit on top of it, so the pass did not "
            f"cover them (AST-122). Re-run the pass over the current head and commit a "
            f"fresh marker — an empty one is valid.")

    for msg in stop:
        print(f"  STOP: {msg}")
    if stop:
        exit_code = 1

print("GREEN" if exit_code == 0 else "NOT GREEN")
sys.exit(exit_code)
PY
