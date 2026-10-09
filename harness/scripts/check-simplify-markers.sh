#!/bin/bash
# check-simplify-markers.sh <base> [head] [--marker <prefix>]...
#
# Verifies the verification-marker record on a range. Exit 0 = green, 1 = STOP.
#
# Why this is a script and not the inline shell it replaced: the rules below need per-commit
# state, and the portable-shell version of that reaches for bash-4 associative arrays. macOS
# ships bash 3.2, where `declare -A` and `mapfile` fail — and the failure mode measured while
# writing this was `markers=0`, i.e. GREEN on every macOS operator's machine (AST-122). So the
# bash part stays thin and the logic is Python, which does not vary by shell.
#
# MARKER KINDS. The harness has more than one marker whose rules are identical, so the kind is
# data rather than a second script. `--marker` is repeatable; the default is the simplify pass.
# A kind is a list of the body lines a well-formed marker must carry plus a policy (the KINDS
# table below). Four ship: `simplify(increment)`, `arm(ticket)`, and the advisory milestone
# markers `rin(gate)` and `qa(walk)`.
#
# PROJECT PLUG POINTS. Everything a project would otherwise edit this file for lives in
# `<repo-root>/.astraler/project/`, which a release never overwrites. The repo root is
# `git rev-parse --show-toplevel`, the same lookup ticket-done.sh uses for its plugs.
#
#   marker-kinds.json         Merged over KINDS, PER KIND, PER FIELD, BY UNION. An entry adds
#                             required body fields (`required`), accepted leading tokens
#                             (`tokens`) and flags (`economy`, `reviewed`, `output_resolvable`)
#                             to the payload kind of the same name, and may add whole new kinds.
#                             It cannot remove a payload requirement: a flag can be turned on
#                             and never off, a list can grow and never shrink, and `scope` can
#                             only widen (advisory < head < live). A key it does not know, or a
#                             wrong type, is a STOP — a typo that silently did nothing would be a
#                             requirement the project believes it has. Absent file: KINDS as is.
#   marker-output-check.sh    `<sha> <subject> <path>`, run once per path on an `Output:` line of
#                             every marker of a kind that sets `output_resolvable`, from the repo
#                             root. Exit 0 = ok; non-zero with a ONE-LINE reason on stdout = STOP
#                             quoting it. This script already checks the path is relative,
#                             resolves to a non-empty regular file at the marker's own commit; the
#                             plug owns what only the project knows: the directory the evidence
#                             must live in, whether its name binds to the marker's ticket. Absent
#                             (or not executable) while a kind requires it: STOP saying so. A
#                             required check that cannot run must not pass.
#   marker-evidence-paths.txt One glob per line (`#` comments, blanks ignored; fnmatch, so `*`
#                             crosses `/`). Rule 5 below: a head whose only changes since the
#                             newest live marker match these still counts as covered. For a log
#                             that is evidence a review happened, not code the marker had to
#                             re-cover. Absent: no exemptions.
#
# The rules, and the attack each one closes. Rules 1-3 are the Supersedes LAUNDERING economy and
# STOP only on kinds with `economy: True`; 4-9 run on every kind. Resolving the Supersedes CHAIN —
# which marker retracts which, i.e. the `superseded=`/`live=` counts — is NOT gated on `economy`:
# a kind that opts out of the laundering rules still retracts markers with a well-formed,
# in-range, same-kind `Supersedes:`, and skipping the resolution made every retraction on such
# a kind read as live (measured on `arm(ticket)`: three markers, a two-link chain, `live=3`).
#   1. A marker may carry AT MOST ONE `Supersedes:`. Without this, one genuine pass launders an
#      unbounded number of fabricated markers by listing their SHAs.
#   2. A marker that supersedes MUST itself be well-formed. Without this, rule 1 is evaded by
#      chaining fabricated markers, each superseding the last.
#   3. The named SHA must be a marker IN RANGE, and may be named by only one marker.
#   4. Every marker in the kind's SCOPE is well-formed — every live one, or the head one. Fields
#      are read from per-paragraph FIELD RUNS (lib/marker_field_parser.py), never from the raw
#      body, so prose that wraps with `Output:` at a line start is not a second declaration. A
#      field that is in the body but excluded by a wrap is reported as that, not as absent: three
#      merges were refused with one identical message and three different causes, and each
#      commit body had to be opened by hand to tell them apart. The discriminator is a
#      declaration (line start, or 2+ spaces after a packed field), not the word, so "No
#      Output: field was recorded" is still reported as absent.
#   5. The newest live marker of each kind COVERS <head>. EXISTENCE IS NOT RELATIONSHIP: a marker
#      whose every field is true, with a later commit sitting on top of it, is a pass that did
#      not cover the code being merged — and rules 1-4 all pass on it (AST-122). This compares
#      TREES, not commit count: an empty commit on top (the arm fires last and commits empty)
#      changes neither tree and must not trip it, while a commit with a real diff must, whatever
#      its count. Changes that match marker-evidence-paths.txt are the only exemption. Paths are
#      listed with `--no-renames`: rename detection reports only the destination, so a tracked
#      code file renamed INTO an exempt path showed as one exempt addition and its removal went
#      unlisted. The fix is cheap and is already the protocol: commit a fresh marker; markers
#      may be empty. The STOP names the fold re-run, because four refusals across three
#      Builders in one shift were each a Builder who ran the documented loop and was never told
#      this step: re-run the simplify pass over `<marker>..<head>` and commit a fresh marker.
#   6. Where a kind sets `reviewed`, the marker's `Reviewed:` SHA is its own parent — the marker
#      commits empty, so the parent IS the tree the gate read — OR it declares the gap with
#      `Unreviewed-delta:`. Never neither. A fold moves the tree past what any pass read, which
#      makes the first half legitimately false; the failure is declaring nothing (AST-134).
#   7. `Reviewed:` must be REACHABLE from the marker even under `Unreviewed-delta:`. The delta
#      says the tree moved past what the pass read; it does not turn a SHA nobody can reach into
#      a receipt. Measured over 400 commits: 59 markers named a reachable commit, 20 did not
#      (a rebase strands the SHA and a restatement carries it forward), 1 did not exist.
#   8. `Range:` endpoints, where the field carries a hex..hex pair, are reachable too. Same
#      disease, same corpus: 55 reachable, 22 not, 87 carry no extractable pair at all. The pair
#      is READ, not asserted: `15 commits, 7 files (a..b)` and `main..f88d2c27 (3 commits)` are
#      both real, so no pair means silence, never a STOP on a shape the check guessed.
#   9. `Supersedes:` is validated on EVERY kind, because a line of record is a claim the moment
#      it is written, whether or not the kind's economy consumes it. Measured: three fabricated
#      values on an economy-off kind, one of them twelve real characters padded with zeros, and
#      the gate passed GREEN. Each value must be SHA-shaped, resolve to a commit, and be a marker
#      IN RANGE of the SAME kind — except a value that is the marker's own `Reviewed:` commit,
#      or that names a commit of the same ticket (a rebase orphans the retracted commit from the
#      new range by construction), or the literal `(none ...)`. A comma-separated list is
#      validated value by value, and a `Supersedes:` line stranded outside the field run is
#      validated too: it is the same bypass moved one line down. The exceptions were fixed by
#      sweeping every merge in a 560-merge history: the strict rule found five real
#      fabrications and ten legitimate markers it would have condemned.
#
# RESIDUAL, stated because it is not closed: markers carry no increment identity — the subject
# is free prose. So nothing here proves the superseding pass covers the SAME increment as the
# marker it retracts. A Builder with two increments can still retract increment-1's marker
# using increment-2's real pass, leaving increment-1 uncovered. The counts are a filter, not a
# verdict: read the bodies. A same-ticket `Supersedes:` is also accepted across kinds.
#
# RESIDUAL, second and larger: every marker is a commit written by the agent being verified.
# A fork inside a Builder's session forged one carrying a sanctioned degraded `Pass:` line that
# quoted a real runtime error string — well-formed by every rule here (AST-130). This script
# checks the record's shape. It cannot check that the work happened.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"; ROOT="${ROOT:-${CLAUDE_PROJECT_DIR:-$PWD}}"
# The parser is found from THIS file, never from the working directory.
LIB_DIR="$(cd "$(dirname "$0")" && pwd)/lib"
export ROOT LIB_DIR
exec python3 -B - "$@" <<'PY'
import fnmatch, json, os, re, subprocess, sys

sys.path.insert(0, os.environ["LIB_DIR"])
import marker_field_parser as _mfp

ROOT = os.environ["ROOT"]
PROJECT_DIR = os.path.join(ROOT, ".astraler", "project")


def advisory_on_base(kind, base):
    """Distance on the BASE branch since the last marker of this kind.

    THE SPAN, NOT THE MESSAGE, WAS WRONG. `rin(gate)` is a MILESTONE marker and a merge range
    is a TICKET branch, so its absence in-range is true BY CONSTRUCTION at every merge — a
    downstream project measured sixteen NONE lines across eight merges, every one structurally
    guaranteed. A line that is always right is wallpaper inside a week, and then it teaches the
    reader that NONE is normal, which makes the one meaningful NONE invisible.

    What the Thomas role asks for is distance ON THE BASE since the last round. That number is
    computable only because the marker exists, it CHANGES OVER TIME so it can cross a threshold,
    and it is silent where absence is definitional.

    EVERY NUMBER ON THE LINE NAMES ITSELF. The earlier wording was `last on <base>: <sha> — N
    merge(s) since`, and a base label is routinely a ref carrying its own integer:
    `origin/main~60`. Two numbers sat side by side with one labelled, and the router reported
    the ref's 60 as the backlog to the owner. It was 9. Nothing in the line was false and it
    still misinformed. `scanned over` marks the base as the range the CALLER chose.
    """
    # `-E`, because `--grep` is BASIC regex where `\(` is a GROUP and every kind here is named
    # `something(scope)` (AST-136).
    #
    # Shorten the ref the caller gave, not only the SHA found: Thomas passes a RESOLVED
    # merge-base at merge time, and the line went to 114 characters on the real path while the
    # tested path passed `main`.
    base_label = base if len(base) < 12 or not re.fullmatch(r"[0-9a-f]{7,40}", base) else base[:9]
    last = git("log", base, "-E", "--format=%H",
               "--grep=^" + re.escape(kind) + ":", "-n", "1").strip()
    if not last:
        total = git("rev-list", "--count", "--merges", base).strip() or "?"
        print("[%s] no marker found — scanned over %s, which holds %s merge(s) of history. "
              "No round recorded. This gate leaves no other machine-readable trace."
              % (kind, base_label, total))
        return
    last = last.splitlines()[0]
    since = git("rev-list", "--count", "--merges", last + ".." + base).strip() or "?"
    when = git("log", "-1", "--format=%ad", "--date=short", last).strip()
    print("[%s] last %s (%s) — %s merge(s) since it; scanned over %s (advisory)"
          % (kind, last[:9], when, since, base_label))


# A KIND is a policy, not just a field list, because the markers are verified for different
# reasons and measurement said so.
#
#   required          body substrings a well-formed marker must ALL carry. SUBSTRING, not
#                     line-anchored: `Vendor:`, `Tests:` and `Pass:` are commonly packed onto ONE
#                     line separated by runs of spaces, and a `^Pass:` matcher fails on every one.
#   tokens            field -> the leading tokens its value may start with. Prefix, not equality:
#                     `NOT RUN by the arm (...)` is a real and correct value.
#   scope             "live" validates every live marker; "head" validates only the marker that IS
#                     the head; "advisory" reports distance on the base and never blocks.
#   economy           the Supersedes arithmetic (rules 1-3).
#   reviewed          enforce `Reviewed:` == the marker's own parent, OR `Unreviewed-delta:`.
#   output_resolvable every path on an `Output:` line must pass the project's
#                     marker-output-check.sh plug and resolve at the marker's own commit.
#
# WHY THE SCOPES DIFFER. `simplify(increment)` validates every live marker because the economy
# depends on it: the rule that every fabricated marker costs its own genuine pass only holds if a
# junk live marker is a finding. Narrowing it to the head hands back the laundering attack.
#
# `arm(ticket)` validates the head marker only and runs no laundering economy. Measured over 32
# real arm markers: two are `Supersedes:` repairs (one a Builder catching the covers-head failure
# in the field and re-firing — the best outcome available) and one is a correction with no fields,
# correcting a prior marker's CLAIM. A field-list validator rejects all three. They dissolve
# once the question is asked of the receipt instead of the history: the router merges one tree on
# one receipt, and whatever ends up at the head IS that receipt. There is nothing to launder when
# exactly one commit is asserted against.
KINDS = {
    "simplify(increment)": {
        "required": ['Pass: Skill(skill: "simplify")'],
        "scope": "live",
        "economy": True,
    },
    "arm(ticket)": {
        # `Output:` is not required here, deliberately: it was absent in 4 of 32, prose in 3, and
        # where it was a path it was a session-scoped scratch path belonging to a Builder that
        # has since ended — a pointer already dead when the router reads it. Requiring it buys
        # presence, not evidence. A project whose arm output is COMMITTED (so the path is a
        # tracked blob) reverses that premise in marker-kinds.json: `required: ["Output:"]`
        # with `output_resolvable: true`, and the two go together or not at all.
        # `Unreviewed-delta:` is optional by design (9 of 32).
        "required": ["Range:", "Reviewed:", "Vendor:", "Pass:"],
        "tokens": {"Tests:": ("RAN", "NOT RUN")},
        "scope": "head",
        "economy": False,
        "reviewed": True,
    },
    # rin(gate) and qa(walk). The sharpest thing a downstream project has told this package:
    # over 200 commits it counted 35 `arm(ticket):`, 22 `simplify(increment):` and ZERO Rin
    # rounds across 107 merges. The gates that fire are the ones with a PHYSICAL ARTIFACT that a
    # script the router already runs REFUSES TO PROCEED WITHOUT. Nobody remembers the arm; they
    # cannot merge without it. Rin's gate had a report outside every checkout, no marker, and no
    # reader — so ">10 merges since the last round is a STOP" was a quantity NOTHING COMPUTED.
    # The counter was answering "the router did not know the number"; the measured problem was
    # "nothing was ever going to tell it". `qa(walk)` is here for the same shape, before the same
    # evidence arrives. Both are ADVISORY: milestone gates do not fire per ticket.
    "rin(gate)": {
        "required": ["Scope:", "Verdict:", "Report:"],
        "tokens": {"Verdict:": ("PASS", "BLOCKING", "NON-BLOCKING")},
        "scope": "advisory",
        "economy": False,
    },
    "qa(walk)": {
        "required": ["Scope:", "Verdict:", "Report:"],
        "tokens": {"Verdict:": ("PASS", "BLOCKING", "NON-BLOCKING")},
        "scope": "advisory",
        "economy": False,
    },
}

# Do not parse a field's interior. `Range:` occurs as both `15 commits, 7 files (a..b)` and
# `main..f88d2c27 (3 commits, 6 files)`; `Pass:` carries an integer and an optional parenthetical,
# and `Pass: 8` is LEGAL against a two-pass cap when the gate re-fired per fold and no single
# invocation exceeded two. A validator asserting `Pass: <= 2` rejects a correct marker.

# ── project plug points ─────────────────────────────────────────────────────────────────────
SCOPE_RANK = {"advisory": 0, "head": 1, "live": 2}
KIND_KEYS = {"required", "tokens", "scope", "economy", "reviewed", "output_resolvable"}
KIND_FLAGS = ("economy", "reviewed", "output_resolvable")
notes = []


def kinds_error(msg):
    sys.exit(f"marker-kinds.json: {msg}")


def merge_project_kinds(path):
    """Union the project's entries into KINDS. See the header: it can add, never remove."""
    try:
        with open(path, encoding="utf-8") as fh:
            project = json.load(fh)
    except (OSError, ValueError) as e:
        kinds_error(f"cannot read {path}: {e}")
    if not isinstance(project, dict):
        kinds_error("top level must be an object mapping kind name -> entry")
    for name, entry in project.items():
        if not isinstance(entry, dict):
            kinds_error(f"{name!r}: entry must be an object")
        unknown = sorted(set(entry) - KIND_KEYS)
        if unknown:
            kinds_error(f"{name!r}: unknown key(s) {', '.join(unknown)} — known: "
                        f"{', '.join(sorted(KIND_KEYS))}")
        spec = KINDS.get(name)
        if spec is None:
            spec = KINDS[name] = {"required": [], "tokens": {}, "scope": "head", "economy": False}
        required = entry.get("required", [])
        if not isinstance(required, list) or not all(isinstance(r, str) for r in required):
            kinds_error(f"{name!r}: required must be a list of strings")
        spec["required"] = list(spec.get("required", [])) + [
            r for r in required if r not in spec.get("required", [])]
        tokens = entry.get("tokens", {})
        if not isinstance(tokens, dict) or not all(
                isinstance(v, list) and all(isinstance(t, str) and t.strip() for t in v) for v in tokens.values()):
            kinds_error(f"{name!r}: tokens must map a field to a list of non-empty strings "
                        f"(an empty token would accept every value, which loosens the kind)")
        merged = {k: tuple(v) for k, v in spec.get("tokens", {}).items()}
        for field, allowed in tokens.items():
            merged[field] = merged.get(field, ()) + tuple(
                t for t in allowed if t not in merged.get(field, ()))
        spec["tokens"] = merged
        for flag in KIND_FLAGS:
            if flag in entry:
                if not isinstance(entry[flag], bool):
                    kinds_error(f"{name!r}: {flag} must be true or false")
                if entry[flag]:
                    spec[flag] = True
                elif spec.get(flag):
                    notes.append(f"NOTE: marker-kinds.json cannot turn {flag} off for {name!r}; "
                                 f"a project adds requirements, it does not remove them")
        if "scope" in entry:
            if entry["scope"] not in SCOPE_RANK:
                kinds_error(f"{name!r}: scope must be one of {', '.join(SCOPE_RANK)}")
            if SCOPE_RANK[entry["scope"]] >= SCOPE_RANK[spec["scope"]]:
                spec["scope"] = entry["scope"]
            else:
                notes.append(f"NOTE: marker-kinds.json cannot narrow the scope of {name!r} "
                             f"({spec['scope']} -> {entry['scope']})")


_kinds_path = os.path.join(PROJECT_DIR, "marker-kinds.json")
if os.path.isfile(_kinds_path):
    merge_project_kinds(_kinds_path)

EVIDENCE_GLOBS = []
_evidence_path = os.path.join(PROJECT_DIR, "marker-evidence-paths.txt")
if os.path.isfile(_evidence_path):
    with open(_evidence_path, encoding="utf-8") as fh:
        EVIDENCE_GLOBS = [l.strip() for l in fh if l.strip() and not l.lstrip().startswith("#")]

OUTPUT_PLUG = os.path.join(PROJECT_DIR, "marker-output-check.sh")

# ── arguments ───────────────────────────────────────────────────────────────────────────────
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


def git_ok(*a):
    return subprocess.run(["git", *a], capture_output=True, text=True).returncode == 0


# `git rev-parse --verify <ref>^{commit}` is a subprocess launch, and one `Supersedes:` value is
# resolved up to three times over a marker (reference validity, the orphan filter, the chain).
# Memoised on the raw ref string, the 2nd and 3rd lookups are a dict read.
_RESOLVE_CACHE = {}


def resolve_commit(ref):
    """`git rev-parse --verify <ref>^{commit}`, memoised; '' when it is not a commit."""
    if ref not in _RESOLVE_CACHE:
        _RESOLVE_CACHE[ref] = git("rev-parse", "--verify", f"{ref}^{{commit}}").strip()
    return _RESOLVE_CACHE[ref]


# FIELD LOOKUPS READ A REGION, NEVER THE BODY. Every lookup below (`required`, `tokens`,
# `Reviewed:`, `Supersedes:`, `Output:`) once searched the whole commit body, which reads any line
# that merely STARTS with a field name as a declaration — including a line inside prose that
# wrapped that way by accident. Measured hitting three Builders on `Output:`: a paragraph wrapped
# so "Output:" landed at a line start, the checker read it as a second path, rejected it, and
# refused a marker whose real field was fine. The region rule is in lib/marker_field_parser.py.
FIELD_TOKENS = {"Supersedes:", "Unreviewed-delta:"}
for _spec in KINDS.values():
    for _f in list(_spec.get("required", [])) + list(_spec.get("tokens", {})):
        _m = re.match(r"^([A-Za-z][A-Za-z-]*):", _f)
        if _m:
            FIELD_TOKENS.add(_m.group(1) + ":")
FIELD_LINE_RE = _mfp.build_field_line_re(FIELD_TOKENS)


def field_region(body):
    return _mfp.field_region(body, FIELD_LINE_RE)


def _orphan_lines(body):
    """Lines of `body` NOT in the field region, by POSITION, not by text: two lines with the
    same text at different positions are different declarations."""
    lines, flags = _mfp.field_line_flags(body, FIELD_LINE_RE)
    return [l for l, f in zip(lines, flags) if not f]


# ── Output: ─────────────────────────────────────────────────────────────────────────────────
# Every path on a live marker's Output: line(s) must resolve to a non-empty regular file AT THE
# MARKER'S OWN COMMIT — not merely exist on disk, where a relative path could exist in the working
# tree without ever having been committed. Reading the tree object is what proves it was
# committed before the marker. Practice uses two forms for multi-pass tickets — repeated
# `Output:` lines and one line with a comma-separated list — so both are parsed. What the path
# must LOOK like (directory, name bound to a ticket) is the project's: marker-output-check.sh.
#
# [ \t]*, NEVER \s*: \s matches newline, so an `Output:` line with only trailing whitespace would
# capture the NEXT line (measured: "Output: \nVendor: claude" returned ['Vendor: claude']).
OUTPUT_RE = re.compile(r"^Output:[ \t]*(\S.*)$", re.M)


def _output_plug_problem():
    """Why the project plug cannot run, or '' when it can."""
    if not os.path.exists(OUTPUT_PLUG):
        return "the plug .astraler/project/marker-output-check.sh is missing"
    if not os.access(OUTPUT_PLUG, os.X_OK):
        return "the plug .astraler/project/marker-output-check.sh is not executable (chmod +x it)"
    return ""


def _validate_output_path(sha, subject, path):
    """The reason ONE candidate Output: path is rejected, or None. The same rules apply whether
    the path came from the field region or from an orphan-shaped line (see
    `orphan_output_values`)."""
    if path.startswith("/"):
        return f"Output: path {path!r} is absolute — it must be repo-relative so it resolves inside the tree being merged"
    if ".." in path.split("/") or "\\" in path or path.startswith("~"):
        return f"Output: path {path!r} leaves the tree (a `..` segment) — refused before any plug sees it"
    r = subprocess.run([OUTPUT_PLUG, sha, subject, path], cwd=ROOT,
                       capture_output=True, text=True)
    if r.returncode != 0:
        why = (r.stdout.strip().splitlines() or ["(the plug printed no reason)"])[0]
        return f"Output: path {path!r} refused by marker-output-check.sh — {why}"
    if not git_ok("cat-file", "-e", f"{sha}:{path}"):
        return f"Output: path {path!r} does not resolve at {sha[:9]} (git cat-file -e failed) — the log is not in this commit"
    # Regular file only: a symlink is stored as a blob too, so cat-file alone cannot tell a real
    # log from a symlink pointing anywhere. `git ls-tree` gives the entry's own mode.
    ls_tree_line = git("ls-tree", sha, "--", path).strip()
    mode = ls_tree_line.split()[0] if ls_tree_line else ""
    if mode not in ("100644", "100755"):
        return f"Output: path {path!r} is not a regular file at {sha[:9]} (mode {mode!r} — symlinks and other tree-entry types are not evidence)"
    if git("cat-file", "-s", f"{sha}:{path}").strip() == "0":
        return f"Output: path {path!r} resolves at {sha[:9]} but is EMPTY (0 bytes)"
    return None


# An `Output:` line OUTSIDE the field region cannot be ignored wholesale: once a paragraph's run
# breaks, every later line in it is excluded, which also hid a deliberate `Output: <real path>`,
# prose, `Output: /etc/hosts` in one paragraph that a whole-body scan would have caught. Nor can
# the whole value be validated: wrapped prose ("Output: improved") would then be read as a path
# and refuse a good marker. A "no internal whitespace" test fails both ways (`/etc/hosts extra`).
# What a malformed value cannot avoid is containing a PATH-SHAPED WORD, so the line is split on
# whitespace and only those words are validated. Prose words never look like paths.
#
# Wrappers are stripped first, because quoting a value defeated the shape test: `"/etc/hosts"`
# no longer starts with `/`. The set covers ASCII and Unicode quotes, guillemets and dashes, and
# zero-width characters (U+200B-D, U+FEFF) are REMOVED outright — a zero-width space spliced
# before a path also produced no candidate. `/`, `.`, `-` and `_` are never wrappers: they are
# what a path is made of.
_ZERO_WIDTH_RE = re.compile("[​‌‍‎‏﻿]")
_WORD_WRAPPERS = (
    ".,;:()'\"`[]{}<>!?*_"
    "‘’‚‛“”„‟"
    "‹›«»"
    "‐‑‒–—―"
)
_PATH_EXT_RE = re.compile(r"\.[A-Za-z0-9]{1,6}$")


def _path_shaped(word):
    """Absolute, a relative path with an extension, or a markdown file. 'and/or' is not."""
    return word.startswith("/") or word.endswith(".md") or ("/" in word and bool(_PATH_EXT_RE.search(word)))


def _path_shaped_words(value):
    value = _ZERO_WIDTH_RE.sub("", value)
    words = [w.strip(_WORD_WRAPPERS) for w in re.split(r"\s+", value.strip())]
    return [w for w in words if w and _path_shaped(w)]


def orphan_output_values(body):
    orphans = []
    for line in _orphan_lines(body):
        m = OUTPUT_RE.match(line)
        if m:
            orphans.extend(_path_shaped_words(m.group(1)))
    return orphans


def check_output_resolves(sha, subject, body, region):
    # Called only when the REGION contains "Output:". If OUTPUT_RE still finds no value, the field
    # is present but EMPTY, which the substring test passes vacuously — this is the only catch.
    lines = OUTPUT_RE.findall(region)
    if not lines:
        return "the `Output:` field is present but carries no path (a whitespace-only value passes the substring check but names nothing to resolve)"
    # "Output: ," matches OUTPUT_RE but splits to nothing, and the loop below would then run zero
    # times and return success on a marker naming nothing.
    paths = [p.strip() for line in lines for p in line.split(",") if p.strip()]
    if not paths:
        return f"the `Output:` field's value ({lines[0]!r}) is delimiter-only — no actual path survives the comma split"
    for path in paths:
        why = _validate_output_path(sha, subject, path)
        if why:
            return why
    for path in orphan_output_values(body):
        why = _validate_output_path(sha, subject, path)
        if why:
            return f"an Output:-shaped line outside the recognized field block also failed validation — {why}"
    return None


# ── Supersedes: ─────────────────────────────────────────────────────────────────────────────
head_sha = git("rev-parse", "--verify", f"{head}^{{commit}}").strip()
if not head_sha:
    sys.exit(f"cannot resolve head '{head}'")

SUP = re.compile(r"^Supersedes: ([0-9a-f]{7,40})\b", re.M)

# RECOGNITION IS SPLIT FROM VALIDITY. `SUP` only matches a value that already looks like a SHA, so
# a malformed one (41 hex characters, uppercase, any single-token garbage) read as "no
# declaration" and was never validated — the field read as absent because its value did not parse.
# The two raw patterns below capture the value whatever its shape; validity is judged in
# `check_supersedes_references`, which STOPs with its own message.
#
# They are DELIBERATELY DIFFERENT. A PRIMARY (region) line is trusted as a declaration, so only its
# START is anchored: end-anchoring it would have stopped recognising 52 already-merged markers
# that carry `Supersedes: <sha> (explanatory prose)` on one line. An ORPHAN line has no such
# trust, so it must be one token, whole line.
# `[^\s,]+`, not `\S+`: one real marker has "Supersedes: <sha1>, <sha2>" and `\S+` glues the comma
# onto the first token, which then fails the shape check on a good marker.
SUP_LINE_RAW_RE = re.compile(r"^Supersedes:[ \t]*([^\s,]+)", re.M)
ORPHAN_SUP_LINE_RE = re.compile(r"^Supersedes:[ \t]*(\S+)[ \t]*$")
SUP_SHAPE_RE = re.compile(r"^[0-9a-f]{7,40}$")
# `Supersedes: (none -- <reason>)` is an established idiom for "nothing superseded", not a SHA.
SUP_NONE_RE = re.compile(r"^\(none\b", re.I)

# An orphan line with TRAILING content (`Supersedes: <40 zeros> <!-- note -->`, or a Builder
# appending `(corrected)`) never matched the whole-line pattern and stayed invisible. A length
# threshold only moved the gap (a 7-19 character value still evaded), and `\S+` glued a SHA to
# whatever followed it. The rule that holds is shape-rooted: take the LONGEST run of [0-9a-f]
# right after "Supersedes: " — a charclass match, so it stops at the first non-hex character
# (`<sha><!--` yields `<sha>`) — and promote it as a candidate when it is at least a FULL SHA
# length. No English word reaches 40 hex-only characters (the real collision, `defaced`, is 7),
# and `backward-compatibility` stops at `k`. A short value with trailing content stays
# unpromoted: the accepted residual of the field-run rule, extended a few characters, not
# closed at an arbitrary line. `>=`, not `==`: with `==` a 41-character value was silently not
# promoted at all; `>=` promotes it and SUP_SHAPE_RE then rejects it with the accurate reason.
SHA_FULL_LEN = 40
ORPHAN_SUP_HEXRUN_RE = re.compile(r"^Supersedes:[ \t]*([0-9a-f]+)")


def orphan_supersedes_exact_lines(body):
    """Orphan candidate values for `check_supersedes_references`: a line that is exactly
    `Supersedes: <single token>`, or whose leading hex run is at least a full SHA. Deliberately
    NOT gated on resolving to an in-range marker: a fabricated value is fabricated precisely
    because it does not resolve, so gating detection on resolution hides the thing hunted."""
    out = []
    for line in _orphan_lines(body):
        stripped = line.strip()
        m = ORPHAN_SUP_LINE_RE.match(stripped)
        if m:
            out.append(m.group(1))
            continue
        m2 = ORPHAN_SUP_HEXRUN_RE.match(stripped)
        if m2 and len(m2.group(1)) >= SHA_FULL_LEN:
            out.append(m2.group(1))
    return out


def orphan_supersedes_values(body, in_range_shas):
    """`Supersedes:` lines outside the field region whose value resolves to one of
    `in_range_shas` — the economy arithmetic's own filter. The gate is "one of THIS range's
    markers", not "any commit": a stray hex-shaped word in prose ("Supersedes: decfabe behavior")
    resolved to a real commit in the measured repo, and the odds of colliding with a handful of
    SHAs in a range are smaller than with the whole history, by the same ratio."""
    orphans = []
    for line in _orphan_lines(body):
        m = SUP.match(line)
        if not m:
            continue
        candidate = m.group(1)
        full = resolve_commit(candidate)
        if full and full in in_range_shas:
            orphans.append(candidate)
    return orphans


exit_code = 0

# ONE git call for the whole range, and NO `--grep`. The kinds carry parentheses, and `--grep`
# takes a POSIX BASIC regex where `\(` is a group — escaping with `re.escape` produced
# `markers=0` on a range that had one, reported as a STOP naming the wrong cause. Matching
# subjects in Python removes the regex-dialect question (AST-122: a fixture fails the same ways
# as the thing it tests). Unit/record separators, not NUL: NUL cannot travel in argv.
REC, FLD = "\x1e", "\x1f"
commits = []
for rec in git("log", f"{base}..{head}", f"--format=%H{FLD}%s{FLD}%b{REC}").split(REC):
    rec = rec.strip("\n")
    if not rec:
        continue
    sha, subject, body = rec.split(FLD, 2)
    commits.append((sha, subject, body))

# Every commit in the range, markers or not: what the reference check needs to answer "in range?"
# and "same kind?" independent of the per-kind marker list.
RANGE_SHAS = {sha for sha, _, _ in commits}
RANGE_SUBJECTS = {sha: subject for sha, subject, _ in commits}

REVIEWED_RE = re.compile(r"\bReviewed:\s*([0-9a-f]{7,40})\b")
RANGE_PAIR_RE = re.compile(r"\bRange:[^\n]*?\b([0-9a-f]{7,40})\.\.([0-9a-f]{7,40})\b")


def check_range_reachable(sha, region):
    """`Range:` names what the pass actually read. A range whose endpoints a rebase stranded
    describes a diff nobody can reconstruct, so the count in front of it ("3 commits, 4 files")
    is a number about nothing. Extracts a hex..hex pair and stays silent when there is none."""
    m = RANGE_PAIR_RE.search(region)
    if not m:
        return ""
    for end in m.groups():
        if not git_ok("cat-file", "-e", end + "^{commit}"):
            return (f"Range: endpoint {end[:9]} does not resolve to a commit in this "
                    f"repository — the range the pass claims to have read cannot be replayed")
        if not git_ok("merge-base", "--is-ancestor", end, sha):
            return (f"Range: endpoint {end[:9]} is not reachable from this marker "
                    f"({sha[:9]}) — a rebase stranded it, so the diff this receipt reports on "
                    f"cannot be reconstructed. Re-run the pass and restate the marker")
    return ""


def check_reviewed_reachable(sha, claimed):
    """`Reviewed:` under an `Unreviewed-delta:` must still name a commit you can GET BACK TO.
    Two different accidents: the SHA never existed here (a typo, a value copied from another
    checkout), or it existed and a rebase orphaned it. A fold ADDS commits, so the legitimate
    case stays an ancestor and passes untouched."""
    if not git_ok("cat-file", "-e", claimed + "^{commit}"):
        return (f"Reviewed: {claimed[:9]} does not resolve to a commit in this repository — "
                f"an Unreviewed-delta: declares a gap, it does not excuse an unresolvable SHA")
    if not git_ok("merge-base", "--is-ancestor", claimed, sha):
        return (f"Reviewed: {claimed[:9]} is not reachable from this marker ({sha[:9]}) — "
                f"a rebase stranded it, so nothing can re-derive what the pass actually read. "
                f"Re-run the pass at the current head and restate the marker with THIS SHA")
    return ""


# SAME-TICKET AND == Reviewed: ARE EXCEPTIONS TO IN-RANGE/SAME-KIND, and the history said so.
# The strict rule was swept against every merge in a 560-merge history before it was trusted: it
# found 15 STOPs. Five were real fabrications (a correct short prefix, wrong trailing digits —
# the shape of the original incident), caught by "resolves at all" with zero false positives. Ten
# were the range and kind rules firing on legitimate, already-merged markers:
#   - three were a Builder re-firing after a REBASE and superseding its own prior same-ticket
#     marker; the rebase orphans the retracted commit from the new range by construction.
#   - seven were `Supersedes: == Reviewed:` on the marker's own parent, an established convention
#     for restating "this is the tree I reviewed" with nothing to retract (seven tickets).
# Every one named a commit whose subject carries the SAME ticket id. "Resolves at all" still runs
# unconditionally and is what a fabricated value cannot survive.
#
# RESIDUAL: a real cross-kind retraction WITHIN one ticket is now accepted. Zero instances in the
# 560 merges; the trade is accepting that over condemning good history.
TICKET_ID_RE = re.compile(r"\b([A-Za-z]{2,}-\d+)\b")


def _same_ticket_reference(my_subject, target_subject):
    """True when both subjects carry the SAME `PREFIX-<n>` token. Empty on either side never
    matches, so subjects with no ticket token take the strict path."""
    m1 = TICKET_ID_RE.search(my_subject or "")
    m2 = TICKET_ID_RE.search(target_subject or "")
    return bool(m1 and m2 and m1.group(1) == m2.group(1))


# `SUP_LINE_RAW_RE` takes only the FIRST token, so `Supersedes: <valid>, <fabricated>` left every
# later value unvalidated: a bypass on an economy-off kind. Capture the whole rest of the line.
SUP_LINE_FULL_RE = re.compile(r"^Supersedes:[ \t]*(.+)$", re.M)


def _supersedes_candidates(region, body):
    """Every raw value to validate: the primary line's leading token, any FURTHER comma segment
    that is a bare single token, and every orphan candidate. The first segment keeps the
    leading-token rule because a real value may be followed by prose before the first comma; a
    later segment counts only when the WHOLE segment is one token, because a naive split on every
    comma read the sentence punctuation in "Supersedes: 6d65b058 (prior marker read a stale base;
    rebase onto main, which merged X, moved the tree)" as SHAs "which" and "moved" and condemned a
    good merged marker."""
    out = []
    for line_value in SUP_LINE_FULL_RE.findall(region):
        segments = line_value.split(",")
        first_token = segments[0].strip().split()[:1]
        if first_token:
            out.append(first_token[0])
        for segment in segments[1:]:
            # The segment's FIRST token counts when it is SHA-shaped, whatever follows it: a
            # fabricated value hidden behind a comment ("0000…, (prior pass)") used to drop out of
            # validation because the segment held two tokens (found by the 2.20.0 gate). Prose
            # segments ("which merged X") still fall out, because "which" is not hex.
            first = segment.strip().split()[:1]
            if first and SUP_SHAPE_RE.match(first[0]):
                out.append(first[0])
    out.extend(orphan_supersedes_exact_lines(body))
    return out


def _reviewed_sha(region):
    m = REVIEWED_RE.search(region)
    return resolve_commit(m.group(1)) if m else None


def check_supersedes_references(kind, region, body, subject):
    """Reference-validity issues for every `Supersedes:` value, for every kind. Failure shapes,
    each its own message so a STOP names the defect rather than "not well-formed":
      - not SHA-shaped (wrong length, uppercase, non-hex);
      - does not resolve to a commit (fabricated but well-shaped) — unconditional;
      - unless it is this marker's own `Reviewed:` commit or names the same ticket: resolves but
        is OUTSIDE base..head, or is in range but not a marker of the SAME kind."""
    prefix = kind + ":"
    reviewed_full = _reviewed_sha(region)
    out = []
    for n in _supersedes_candidates(region, body):
        if SUP_NONE_RE.match(n):
            continue
        if not SUP_SHAPE_RE.match(n):
            out.append(
                f"Supersedes: {n!r} is not shaped like a commit SHA (7-40 lowercase hex "
                f"characters)")
            continue
        full = resolve_commit(n)
        if not full:
            out.append(f"Supersedes: {n!r} does not resolve to a commit in this repository")
            continue
        if reviewed_full and full == reviewed_full:
            continue
        target_subject = RANGE_SUBJECTS.get(full)
        if target_subject is None:
            target_subject = git("log", "-1", "--format=%s", full).strip()
        if _same_ticket_reference(subject, target_subject):
            continue
        if full not in RANGE_SHAS:
            out.append(
                f"Supersedes: {n[:9]} resolves to {full[:9]}, which is not in the range "
                f"being verified ({base}..{head})")
            continue
        if not RANGE_SUBJECTS.get(full, "").startswith(prefix):
            out.append(
                f"Supersedes: {n[:9]} names {full[:9]}, which is not a {kind!r} marker — "
                f"a marker can only supersede its own kind (category error)")
    return out


def field_value(region, field):
    """Text following `field` up to the end of the line. Substring, not line-anchored — but the
    caller passes the field region, never the raw body."""
    i = region.find(field)
    if i < 0:
        return None
    tail = region[i + len(field):]
    return tail.split("\n", 1)[0].strip()


def shortfalls(kind, sha, body, subject="", output_plug_ok=True):
    """(shortfall reasons, field region) for this marker. The region is returned so the callers
    that also need it do not recompute a full per-line paragraph scan on the same body."""
    spec = KINDS[kind]
    region = field_region(body)
    out = []

    def add(msg):
        if msg not in out:
            out.append(msg)

    def absent(f):
        # A FIELD IN THE COMMIT BUT OUTSIDE THE REGION IS A DIFFERENT DEFECT FROM AN ABSENT ONE.
        # Packing `Vendor:`/`Tests:`/`Pass:` onto one line is legitimate, and a real Tests: value
        # is a sentence. When it wraps, the continuation carries no field token, so the region
        # drops it AND EVERYTHING AFTER IT in that paragraph — taking Pass: and Output: with it
        # while they sit in the commit. Telling an author a field is missing when it is written
        # ten characters away is the most misleading thing this validator can say.
        # THE DISCRIMINATOR IS A DECLARATION, NOT THE WORD: at line start, or after the 2+ spaces
        # that separate packed fields. Prose reaches the word with one space, and "No Output:
        # field was recorded" has no field at all.
        if re.search(r"(?m)(^|\s{2,})" + re.escape(f), body):
            add(f"{f!r} is IN the commit body but OUTSIDE the recognised field region "
                f"(AST-099) -- a preceding line in its paragraph carries no field token, so "
                f"everything after it is dropped. Usual cause: a long value wrapped. "
                f"Put {f!r} on its own line, or unwrap the value above it")
        else:
            add(f"missing {f!r} (AST-099)")

    for f in spec["required"]:
        if f not in region:
            absent(f)
    for msg in check_supersedes_references(kind, region, body, subject):
        add(msg)
    for field, allowed in spec.get("tokens", {}).items():
        val = field_value(region, field)
        if val is None:
            absent(field)
        elif not val.startswith(allowed):
            add(f"{field} does not start with one of {', '.join(allowed)}: {val[:40]!r}")
    if spec.get("reviewed"):
        # The marker commits EMPTY, so its parent is the tree the gate read. Where a fold has
        # moved the tree past what any pass read, `Reviewed: == parent` is impossible — exactly
        # when the delta must be declared rather than omitted (AST-134).
        m = REVIEWED_RE.search(region)
        parent = git("rev-parse", "--verify", f"{sha}^").strip()
        claimed = m.group(1) if m else ""
        has_reviewed_line = re.search(r"^Reviewed:", region, re.M) is not None
        # A `Reviewed:` that is not a commit, or a delta declared with no `Reviewed:` at all,
        # used to pass through the delta escape with an empty claim (found by the 2.20.0 gate).
        if has_reviewed_line and not claimed:
            add("Reviewed: names no commit (not a 7-40 hex sha); the delta escape needs a real base to measure from")
        elif not claimed and "Unreviewed-delta:" in region:
            add("Unreviewed-delta: is declared but no Reviewed: names the commit the gate read")
        elif not (claimed and parent.startswith(claimed)) and "Unreviewed-delta:" not in region:
            add(f"Reviewed: {claimed[:9] or '(none)'} is not this marker's parent "
                f"({parent[:9]}) and no Unreviewed-delta: declares the gap (AST-134)")
        elif claimed and not parent.startswith(claimed):
            why = check_reviewed_reachable(sha, claimed)
            if why:
                add(why)
    # `Range:` is the other half of the same receipt. Checked for every kind that requires it,
    # not only under the delta escape: a stranded range is unreplayable whatever moved the tree.
    if "Range:" in spec.get("required", ()):
        why = check_range_reachable(sha, region)
        if why:
            add(why)
    if spec.get("output_resolvable") and output_plug_ok and "Output:" in region:
        why = check_output_resolves(sha, subject, body, region)
        if why:
            add(why)
    return out, region


for kind in kinds:
    spec = KINDS[kind]
    # A milestone marker cannot appear in a ticket range, so measure it where it means
    # something and say nothing here.
    if spec["scope"] == "advisory":
        advisory_on_base(kind, base)
        continue

    prefix = kind + ":"
    marks = [(sha, body) for sha, subject, body in commits if subject.startswith(prefix)]
    shas = [sha for sha, _ in marks]
    bodies = dict(marks)
    subjects = {sha: subject for sha, subject, _ in commits if subject.startswith(prefix)}

    # ABSENCE IS A FINDING. A range with no markers is AST-094, not a quiet pass.
    if not shas:
        print(f"[{kind}] markers=0 — STOP: no marker on {base}..{head} (AST-094)")
        exit_code = 1
        continue

    stop = []
    plug_problem = _output_plug_problem() if spec.get("output_resolvable") else ""
    if plug_problem:
        stop.append(f"{kind} sets output_resolvable but {plug_problem}; a required check that "
                    f"cannot run does not pass")
    well, missing, superseded_by = {}, {}, {}
    for sha in shas:
        body = bodies[sha]
        missing[sha], region = shortfalls(kind, sha, body, subjects.get(sha, ""),
                                          output_plug_ok=not plug_problem)
        well[sha] = not missing[sha]
        # Resolving the CHAIN runs for every kind; only the laundering rules are `economy`-gated.
        # Primary declaration from the region, plus an orphan scan for a second line hiding past a
        # field-run break, gated on resolving to a marker of THIS range.
        names = SUP.findall(region) + orphan_supersedes_values(body, shas)
        short = sha[:9]
        if spec["economy"]:
            if len(names) > 1:
                stop.append(f"{short} carries {len(names)} Supersedes lines; at most one is allowed")
            if names and not well[sha]:
                stop.append(f"{short} supersedes a marker but is not itself well-formed")
            # Rule 1 caps this kind at one line, so exactly one target is ever legitimate.
            targets = names[:1]
        else:
            # An economy-off kind may legitimately name SEVERAL targets (several lines, or one
            # comma-separated line): two real markers had three on one line, all in range, and
            # `names[:1]` counted one and reported the other two live. Reuse the parser that
            # already validates every value.
            targets = _supersedes_candidates(region, body)
        for n in targets:
            full = resolve_commit(n)
            if not full or full not in shas:
                if spec["economy"]:
                    stop.append(f"{short} supersedes {n}, which is not a marker in this range")
                continue
            if full in superseded_by:
                if spec["economy"]:
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

    # Rule 5 — covers-head, by TREE. Do not loosen this to "no STOP if only one commit sits on
    # top": that reopens the gap AST-122 was written to close with a different-sized excuse.
    if live and live[0] != head_sha:
        live_tree = git("rev-parse", f"{live[0]}^{{tree}}").strip()
        head_tree = git("rev-parse", f"{head_sha}^{{tree}}").strip()
        if live_tree != head_tree:
            changed = [p for p in git("diff", "--no-renames", "--name-only", live[0], head_sha).split("\n")
                       if p.strip()]
            content_changed = [p for p in changed
                               if not any(fnmatch.fnmatchcase(p, g) for g in EVIDENCE_GLOBS)]
            if content_changed:
                ahead = git("rev-list", "--count", f"{live[0]}..{head_sha}").strip() or "?"
                stop.append(
                    f"newest live marker {live[0][:9]} is not the head being merged "
                    f"({head_sha[:9]}); {ahead} commit(s) sit on top of it, so the pass did not "
                    f"cover them (AST-122). Re-run the pass over the current head and commit a "
                    f"fresh marker — an empty one is valid. If those commit(s) are an arm "
                    f"FOLD, this is the fold re-run: run the simplify pass over "
                    f"{live[0][:9]}..{head_sha[:9]} and commit a fresh marker.")

    for msg in stop:
        print(f"  STOP: {msg}")
    if stop:
        exit_code = 1

for n in notes:
    print(f"  {n}")
print("GREEN" if exit_code == 0 else "NOT GREEN")
sys.exit(exit_code)
PY
