#!/usr/bin/env bash
# selftest.sh — exercise this package's scripts the way they are actually invoked.
#
# WHY THIS EXISTS, and it is one sentence from a downstream project: **every defect a live
# upgrade found lived in the gap between a tested invocation and a real one** (AST-137). Not one
# of them needed a repository with history. They needed a caller that invokes differently than
# the author does — a different cwd, layout, argument position, ref form, or shell.
#
# So this file is not a unit test suite. It is a list of INVOCATION SHAPES, one per defect this
# package has actually shipped, and it fails on the shape rather than on the logic. Every case
# below was a real regression, in the release named beside it.
#
#   selftest.sh            run everything, print a summary, exit 1 on any failure
#   selftest.sh -v         also print each case as it runs
#
# ADDING A CASE: when a defect turns out to be an invocation-shape defect — and they nearly all
# are — add the shape here in the same commit as the fix. A case that reproduces the bug before
# the fix and passes after is worth more than the fix's own comment.
#
# AND THE OPERATIONAL RULE `AST-137` DOES NOT STATE, which the project that found the entry
# supplied afterwards: **every instance of it was caught by making the thing fail on purpose,
# and none by reading.** Restoring a real fossil into a tree and re-running. Passing a
# 40-character SHA instead of a branch name. Editing a payload file and watching the check stay
# green. Building an actual dual-homed symlink. In every case the code had already been read,
# by both of us, and read as correct.
#
# So a case here does not earn its place by asserting the right answer. It earns it by having
# been watched to FAIL first. If you add one that passed on the first run, you have written a
# test for the invocation you already believed in — which is the defect, not the check for it.

set -uo pipefail
VERBOSE=0; [ "${1:-}" = "-v" ] && VERBOSE=1

# LAYOUT-AWARE ROOT (2.7.16). A fixed `../..` is right under harness/scripts/ and lands on the
# repo's PARENT in every adapted project, where scripts/ sits at the root — two upgrade receipts
# in a row reported "46 cases cannot be run downstream". Resolve from where this file IS: the
# package is the tree whose scripts dir is `harness/scripts` with `install.sh` two levels up;
# anything else is an adapted project, where the package-only cases (installer, payload
# fixtures) are SKIPPED BY NAME rather than failing on a path that does not exist.
S="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ "$(basename "$(dirname "$S")")" = harness ] && [ -f "$S/../../install.sh" ]; then
  LAYOUT=package; ROOT="$(cd "$S/../.." && pwd)"
else
  LAYOUT=project; ROOT="$(cd "$S/.." && pwd)"
fi
SKIPPED=0
pkg_only() { # <section name> — true in package layout; otherwise say so and skip
  [ "$LAYOUT" = package ] && return 0
  SKIPPED=$((SKIPPED+1)); echo "  skip $1 — package layout only, not applicable in an adapted project"; return 1
}
PASS=0; FAIL=0; FAILED=""

ok()   { PASS=$((PASS+1)); [ "$VERBOSE" = 1 ] && printf '  ok   %s\n' "$1"; return 0; }
bad()  { FAIL=$((FAIL+1)); FAILED="$FAILED  $1\n"; printf '  FAIL %s\n     %s\n' "$1" "${2:-}"; }
have() { command -v "$1" >/dev/null 2>&1; }
# DEFINED WITH THE OTHER HELPERS, not beside its first caller. It lived inside the reachability
# section for two releases, four hundred lines below the top of the file, so a case added ABOVE
# that point called an undefined function — which in a shell is not an error a reader sees: the
# call returns non-zero and the case reports the FAILURE IT WAS WRITTEN TO CATCH. Measured
# 2026-09-20 on the install.sh fossil case, which passed by hand and failed here for a reason
# that had nothing to do with install.sh.
says() { # <haystack> <needle> — substring, with no pipeline and no exit status in the way
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# Evidence stamps go under this run's own TMP: install.sh runs this suite INSIDE this suite, and
# two runs sharing /tmp deleted each other's stamps mid-run (measured as a flaky "spaced path").
export HARNESS_STAMP_ROOT="$TMP/stamps"

# ---------------------------------------------------------------------------------------------
# hook-git-guard — 2.7.0 through 2.7.2 shipped three matchers, each bypassable and over-broad in
# a different way. The guard is an accidental-misuse lint by design; these are the cases that
# define that boundary, and half of them are commands it must NOT touch.
# ---------------------------------------------------------------------------------------------
guard() { # <expected deny|allow|no-opinion> <command>
  local want="$1"; shift
  local out got
  out="$(printf '%s' "$1" | python3 -c '
import sys, json
print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Bash",
                  "tool_input":{"command":sys.stdin.read()}}))' \
    | HARNESS_HOOK_LOG="$TMP/hook.log" python3 "$S/hook-git-guard.py" 2>/dev/null)"
  if [ -n "$out" ]; then got=deny; else got=allow; fi
  [ "$want" = "$got" ] && ok "guard $want: $1" || bad "guard $1" "expected $want, got $got"
}

echo "hook-git-guard — accidental misuse it must catch"
guard deny  'git add -A'
guard deny  'git add .'
guard deny  '/usr/bin/git add -A'                 # absolute exe (2.7.1)
guard deny  'git -c core.quotePath=false add -A'  # global option before subcommand (2.7.1)
guard deny  'cd /x && git add -A'
guard deny  'rm -rf .claude/worktrees/t1'
guard deny  'git worktree add -b b ./rel main'    # relative path (AST-028)

echo "hook-git-guard — correct work it must NOT block"
guard allow 'git add src/a.ts'
guard allow 'git worktree add -b b /tmp/abs main'
guard allow 'git worktree add ~/wt br'                     # ~ expands to absolute (2.7.1)
guard allow 'printf "%s" "rm -rf .claude/worktrees/x"'     # quoted DATA, not a command (2.7.1)
guard allow "printf '%s' ';' echo hi"                      # quoted operator (2.7.2)
guard allow 'grep -rn "git add -A" docs/'
guard allow 'git status --short'

echo "hook-git-guard — out of scope: silent by design, never denied (2.7.3)"
guard allow 'echo "$(git add -A)"'          # substitution inside quotes
guard allow 'if git add -A; then :; fi'     # reserved word
guard allow 'FOO=bar git add -A'            # assignment prefix
guard allow 'xargs git add -A'              # wrapper
guard allow 'cat <<EOF
git add -A
EOF'                                        # heredoc body

# The distinction the shrink was FOR: unsupported structure must record no-opinion, not allow.
if grep -q 'no-opinion' "$TMP/hook.log" 2>/dev/null; then
  ok "guard logs no-opinion distinctly from allow (2.7.4)"
else
  bad "guard no-opinion logging" "expected a no-opinion entry in the fire log"
fi

# Codex registration is a separate runtime surface. Exercise the command AS REGISTERED from
# an adapted-project layout; parsing hooks.json or running the script directly proves neither
# that the registration resolves the installed path nor that stdin reaches the guard.
if pkg_only "codex hooks, codex agents, argument conventions"; then
echo "codex hooks — registered command reaches the shared guard"
CT="$TMP/codex-hook-target"; mkdir -p "$CT/.codex" "$CT/scripts"
cp "$ROOT/harness/.codex/hooks.json" "$CT/.codex/hooks.json"
cp "$S/hook-git-guard.py" "$CT/scripts/hook-git-guard.py"
HOOK_CMD="$(python3 - "$CT/.codex/hooks.json" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1], encoding="utf-8"))
print(cfg["hooks"]["PreToolUse"][0]["hooks"][0]["command"])
PY
)"
SMOKE='{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git add -A"}}'
out="$(cd "$CT" && printf '%s' "$SMOKE" | HARNESS_HOOK_LOG="$TMP/codex-hook.log" bash -c "$HOOK_CMD" 2>/dev/null)"
case "$out" in
  *'"permissionDecision": "deny"'*) ok "Codex hooks.json invokes the guard from adapted layout" ;;
  *) bad "Codex hook registration" "registered command did not deny git add -A: $out" ;;
esac

echo "codex custom agents — project TOML requests read-only mode and is parseable"
if python3 - "$ROOT/harness/.codex/agents" <<'PY'
import os, sys, tomllib
expected = {
    "astragentic-explorer.toml": "astragentic_explorer",
    "astragentic-reviewer.toml": "astragentic_reviewer",
}
for filename, name in expected.items():
    with open(os.path.join(sys.argv[1], filename), "rb") as fh:
        cfg = tomllib.load(fh)
    assert cfg["name"] == name
    assert cfg["sandbox_mode"] == "read-only"
    assert cfg["description"] and cfg["developer_instructions"]
PY
then
  ok "project custom-agent TOML parses and requests read-only mode"
else
  bad "Codex custom-agent TOML" "missing, invalid, or not read-only"
fi

# ---------------------------------------------------------------------------------------------
# Argument conventions — 2.7.2's `--check` was positional, and the wrong position exited 0 AND
# REWROTE the file it was asked about. Three scripts, one convention.
# ---------------------------------------------------------------------------------------------
echo "argument conventions — a check must not depend on flag position (2.7.2)"
# NEVER MUTATE THE TREE UNDER TEST. The first version of this case edited the repository's own
# INDEX.md and restored it afterwards, which is fine until a case fails, the script exits early,
# and the restore never runs — leaving the repo dirty and the next staging gate red for a reason
# that has nothing to do with the payload. A selftest that can damage what it inspects is worse
# than no selftest. Work on a throwaway copy of the payload instead.
COPY="$TMP/payload"; mkdir -p "$COPY"
cp -R "$ROOT/harness/.agents" "$ROOT/harness/scripts" "$COPY/" 2>/dev/null
IDX="$COPY/.agents/memory/INDEX.md"
if [ -f "$IDX" ]; then
  cp "$IDX" "$TMP/idx.clean"
  for form in "--check" ". --check" "--check ."; do
    cp "$TMP/idx.clean" "$IDX"; echo '<!-- selftest stale -->' >> "$IDX"
    before="$(shasum "$IDX" | cut -d' ' -f1)"
    (cd "$COPY" && bash "$COPY/scripts/ledger-index.sh" $form >/dev/null 2>&1); rc=$?
    after="$(shasum "$IDX" | cut -d' ' -f1)"
    if [ "$rc" -ne 0 ] && [ "$before" = "$after" ]; then
      ok "ledger-index '$form' fails on stale and writes nothing"
    else
      bad "ledger-index '$form'" "exit=$rc, file $([ "$before" = "$after" ] && echo unchanged || echo REWRITTEN)"
    fi
  done
fi

fi

# ---------------------------------------------------------------------------------------------
# Root resolution — 2.7.0 assumed a fixed depth, which is right under harness/scripts/ and one
# level too high in an adapted project; 2.7.4 then depended on the caller's cwd.
# ---------------------------------------------------------------------------------------------
echo "root resolution — bare, with an explicit root, and from an unrelated cwd (2.7.1, 2.7.2)"
for inv in "bare" "explicit" "elsewhere"; do
  case "$inv" in
    bare)      out="$( (cd "$ROOT" && bash "$S/docs-staleness-audit.sh" 2>&1) )" ;;
    explicit)  out="$( bash "$S/docs-staleness-audit.sh" "$ROOT" 2>&1 )" ;;
    elsewhere) out="$( (cd "$TMP" && bash "$S/docs-staleness-audit.sh" 2>&1) )" ;;
  esac
  case "$out" in
    *"NO ROLE CONTRACTS"*|*"measured nothing"*) bad "docs-staleness $inv" "found no contracts" ;;
    *) ok "docs-staleness $inv" ;;
  esac
done
for inv in "bare" "explicit"; do
  case "$inv" in
    bare)     out="$( (cd "$ROOT" && python3 "$S/ledger-rules.py" --check 2>&1) )" ;;
    explicit) out="$( python3 "$S/ledger-rules.py" "$ROOT" --check 2>&1 )" ;;
  esac
  case "$out" in
    *"not found"*) bad "ledger-rules $inv" "$out" ;;
    *) ok "ledger-rules $inv" ;;
  esac
done

# The one that cost an adaptation step: this file is Python behind a `.sh` name.
# In an adapted project this check needs the staged release manifest; without one it hard-
# fails at check 0 by design, which is not the invocation shape this case is about.
if head -1 "$S/check-reachability.sh" | grep -q python && { [ "$LAYOUT" = package ] || [ -d "$ROOT/.astraler/releases" ]; }; then
  # ASSERT THE INTERPRETER RAN, NOT THAT THE TREE IS CLEAN. This case is about invocation
  # shape — the file is python with a `.sh` name, and `bash -n` on it is the defect. It used
  # to assert exit 0, but check-reachability exits 1 on ANY finding, so an adapted project
  # with one legitimate finding read this as a broken invocation. Measured 2026-09-16 on the
  # first real project to run it: a benign Docker container name in a contract produced one
  # check-4 finding, and the suite reported the invocation as failed. A gate that cannot go
  # green on a healthy project is a gate people stop reading.
  _cr="$(python3 "$S/check-reachability.sh" "$ROOT" 2>&1)"; _crx=$?
  case "$_cr" in
    *"Reachability check"*)
      [ "$_crx" -le 1 ] \
        && ok "check-reachability runs under python3 (never bash -n)" \
        || bad "check-reachability" "ran but exited $_crx — neither clean (0) nor findings (1)" ;;
    *) bad "check-reachability" "python3 invocation produced no header: ${_cr:-no output}" ;;
  esac
fi

# ---------------------------------------------------------------------------------------------
# check-simplify-markers — advisory kinds report on the BASE and stay silent about a ticket
# range, because a milestone marker cannot appear in one (2.7.3). And `--grep` is BASIC regex,
# where every kind name's parenthesis is a group (AST-136).
# ---------------------------------------------------------------------------------------------
echo "marker gate — advisory span and regex dialect (2.7.3, AST-136)"
R="$TMP/markers"; mkdir -p "$R"
( cd "$R" && git init -q . && git config user.email t@t && git config user.name t \
  && git commit -q --allow-empty -m init \
  && git commit -q --allow-empty -m 'rin(gate): s1 — PASS

Scope: s1
Verdict: PASS (0 blocking, 0 non-blocking)
Report: /tmp/g.md' ) >/dev/null 2>&1
B="$( cd "$R" && git rev-parse HEAD )"
( cd "$R" && for i in 1 2 3; do
    git checkout -q -b "t$i" && git commit -q --allow-empty -m "t$i" \
      && git checkout -q - && git merge -q --no-ff "t$i" -m "merge t$i"
  done ) >/dev/null 2>&1
# A 40-character SHA is what the router passes at merge; a branch name is what gets tested.
out="$( cd "$R" && bash "$S/check-simplify-markers.sh" "$B" HEAD --marker 'rin(gate)' 2>&1 | head -1 )"
case "$out" in
  *"never recorded"*) bad "advisory finds a marker on the base" "grep dialect: $out" ;;
  *"merge(s) since"*) ok  "advisory reports distance on the base, not absence in range" ;;
  *)                  bad "advisory line" "$out" ;;
esac
[ "${#out}" -le 100 ] && ok "advisory line fits one terminal width (${#out} chars)" \
                      || bad "advisory line width" "${#out} chars with a resolved SHA"

# ---------------------------------------------------------------------------------------------
# install.sh — the release must stage from a package root AND from inside a staged release
# (2.7.2), and from a path containing a space (2.7.1).
# ---------------------------------------------------------------------------------------------
# When install.sh is running THIS suite as a staging gate, these cases would stage again from
# inside a stage. Skipped there and exercised on a direct run, which is where they matter.
if pkg_only "install.sh layouts"; then
if [ -n "${ASTRALER_IN_SELFTEST:-}" ]; then
  echo "install.sh — layout cases skipped (running as install.sh's own staging gate)"
else
echo "install.sh — layouts and paths it is actually invoked from (2.7.1, 2.7.2)"
V="$(cat "$ROOT/VERSION" 2>/dev/null)"
T1="$TMP/plain"; mkdir -p "$T1"; ( cd "$T1" && git init -q . ) >/dev/null 2>&1
if bash "$ROOT/install.sh" "$T1" >/dev/null 2>&1 && [ -d "$T1/.astraler/releases/$V" ]; then
  ok "stages from the package root"
  # The installer ships INSIDE the release; staging flattens prompts/ to the release root.
  T2="$TMP/from-release"; mkdir -p "$T2"; ( cd "$T2" && git init -q . ) >/dev/null 2>&1
  if [ -f "$T1/.astraler/releases/$V/install.sh" ]; then
    ( cd "$T1/.astraler/releases/$V" && bash install.sh "$T2" ) >/dev/null 2>&1 \
      && [ -d "$T2/.astraler/releases/$V" ] \
      && ok "the staged installer runs from its own release directory" \
      || bad "staged installer" "cannot stage from inside .astraler/releases/$V"
  else
    bad "staged installer" "install.sh is not in the release — every upgrade note names it"
  fi
  # Field splitting broke all four staging checks on a valid checkout.
  SP="$TMP/Astraler Repo"; mkdir -p "$SP"
  cp -R "$ROOT/harness" "$ROOT/install.sh" "$ROOT/VERSION" "$ROOT/README.md" \
        "$ROOT/RELEASE-NOTES.md" "$ROOT/check-requirements.sh" "$ROOT/prompts" "$SP/" 2>/dev/null
  T3="$TMP/spaced-target"; mkdir -p "$T3"; ( cd "$T3" && git init -q . ) >/dev/null 2>&1
  ( cd "$SP" && bash install.sh "$T3" ) >/dev/null 2>&1 && [ -d "$T3/.astraler/releases/$V" ] \
    && ok "stages from a path containing a space" \
    || bad "spaced path" "a repository path with a space refused a valid install"

  # A RENAMED SCAFFOLD PATH. The fossil report has existed since 2.7.6 and excluded
  # `.codex/profiles/*` by name, because a project keeps its own scaffold — right reasoning,
  # and it stops holding the moment the path is RETIRED rather than tuned. 2.12.0 renamed all
  # five profiles, and this exclusion is what would have carried the dead name into every
  # adapted repo without a word (AST-143's shape, one directory over).
  T4="$TMP/pre212"; rm -rf "$T4"
  mkdir -p "$T4/.codex/profiles" "$T4/.astraler/releases/0.0.1/harness/.codex/profiles" "$T4/.astraler/state"
  ( cd "$T4" && git init -q . ) >/dev/null 2>&1
  FOSSIL="builder.config"".toml"
  printf 'model = "x"\n' > "$T4/.codex/profiles/$FOSSIL"
  cp "$T4/.codex/profiles/$FOSSIL" "$T4/.astraler/releases/0.0.1/harness/.codex/profiles/"
  printf '0.0.1\n' > "$T4/.astraler/state/applied-version"
  # The guard install.sh reads, set deliberately: these two runs are about the fossil REPORT,
  # and without it each one spawns a nested copy of this whole suite as its staging gate —
  # minutes, for coverage the three cases above already provide.
  ASTRALER_IN_SELFTEST=1 bash "$ROOT/install.sh" "$T4" >/dev/null 2>&1
  out="$(ASTRALER_IN_SELFTEST=1 bash "$ROOT/install.sh" "$T4" --apply 2>&1)"
  says "$out" ".codex/profiles/$FOSSIL" \
    && ok "a renamed profile is reported as a fossil rather than skipped as scaffold" \
    || bad "profile rename fossil" "the dead name stays in the project and the receipt says clean"
  says "$out" "READ THIS ONE BEFORE DELETING" \
    && ok "the fossil report says where the owner's model and effort have to go first" \
    || bad "profile rename advisory" "the owner is told to delete a file holding values nothing else has"
else
  bad "install.sh staging" "did not stage $V into a fresh target"
fi
fi

fi

# ---------------------------------------------------------------------------------------------
# docs-staleness axis 4 — the only guard on "the payload names no project" compared an absolute
# path to the bare word "harness" and printed "(skipped)" on every run for four releases
# (2.7.15). Both cases here were watched to FAIL against the shipped condition before the fix.
# ---------------------------------------------------------------------------------------------
if pkg_only "docs-staleness axis 4"; then
echo "docs-staleness axis 4 — the project-noun guard runs in package layout, and catches (2.7.15)"
for inv in "bare" "explicit"; do
  case "$inv" in
    bare)     out="$( (cd "$ROOT" && bash "$S/docs-staleness-audit.sh" 2>&1) )" ;;
    explicit) out="$( bash "$S/docs-staleness-audit.sh" "$ROOT" 2>&1 )" ;;
  esac
  case "$out" in
    *"this axis is about the scaffold"*) bad "axis-4 runs ($inv)" "printed (skipped) in package layout" ;;
    *) ok "axis-4 runs ($inv)" ;;
  esac
done
PKG="$TMP/pkg"; mkdir -p "$PKG/harness/.agents/roles" "$PKG/harness/scripts"
cp "$ROOT/harness/.agents/roles/"*.md "$PKG/harness/.agents/roles/"
cp "$S/"*.sh "$PKG/harness/scripts/"; touch "$PKG/install.sh"
# The planted id is ASSEMBLED, not written literally — this file is inside axis 4's scan scope,
# and a literal here would be reported as the leak it exists to detect.
LEAK="QQQ-$((120+3))"
echo "leak $LEAK" > "$PKG/harness/.agents/roles/leak.md"
out="$( bash "$S/docs-staleness-audit.sh" "$PKG" 2>&1 )"
case "$out" in
  *"$LEAK"*) ok "axis-4 flags a planted id" ;;
  *) bad "axis-4 flags a planted id" "$LEAK not reported" ;;
esac

fi

# ---------------------------------------------------------------------------------------------
# release-worktree-resources — the cleanup SOCKET (2.7.15). An empty socket must say so and
# succeed; a present plug must run and its failure must propagate; a plug that exists but
# cannot run is a STOP, not a silent skip. The silent version of each is how 43 orphaned
# processes and 3,405 leftover databases accumulated downstream in one night.
# ---------------------------------------------------------------------------------------------
echo "release-worktree-resources — empty socket speaks, plug runs, plug failure propagates (2.7.15)"
R="$TMP/rwr"; mkdir -p "$R/wt"; (cd "$R" && git init -q . 2>/dev/null)
out="$( (cd "$R" && bash "$S/release-worktree-resources.sh" "$R/wt" 2>&1); echo "rc=$?" )"
case "$out" in
  *"no project cleanup declared"*"rc=0"*) ok "rwr empty socket: NOTE + exit 0" ;;
  *) bad "rwr empty socket" "$out" ;;
esac
mkdir -p "$R/.astraler/project"
printf '#!/bin/sh\necho "plug released: $1"\n' > "$R/.astraler/project/cleanup-worktree.sh"
out="$( (cd "$R" && bash "$S/release-worktree-resources.sh" "$R/wt" 2>&1); echo "rc=$?" )"
case "$out" in
  *"not executable"*"rc=1"*) ok "rwr non-executable plug: STOP + exit 1" ;;
  *) bad "rwr non-executable plug" "$out" ;;
esac
chmod +x "$R/.astraler/project/cleanup-worktree.sh"
out="$( (cd "$R" && bash "$S/release-worktree-resources.sh" "$R/wt" 2>&1); echo "rc=$?" )"
case "$out" in
  *"plug released: $R/wt"*"rc=0"*) ok "rwr plug runs with the worktree path" ;;
  *) bad "rwr plug runs" "$out" ;;
esac
printf '#!/bin/sh\nexit 3\n' > "$R/.astraler/project/cleanup-worktree.sh"
out="$( (cd "$R" && bash "$S/release-worktree-resources.sh" "$R/wt" 2>&1); echo "rc=$?" )"
case "$out" in
  *"WARN project plug exited 3"*"rc=1"*) ok "rwr plug failure propagates" ;;
  *) bad "rwr plug failure propagates" "$out" ;;
esac

# A compose stack rooted in the worktree is checked AFTER the plug, by Docker's own labels
# (2.13.0, AST-155). Downstream the plug ran `down -v` and every built image survived it — 99
# of them. `docker` is stubbed here so the case runs on a machine without Docker; the real
# shape (compose up, `down -v` leaves the image, `--rmi local` clears it) was run against
# Docker Desktop before this stub was written, and the stub prints what that run printed.
DK="$TMP/rwr-docker"; mkdir -p "$DK"
cat > "$DK/docker" <<EOF
#!/bin/sh
case "\$*" in
  version*) exit 0 ;;
  "ps -a --format"*) echo "stubproj|$R/wt/deploy"; echo "otherproj|$TMP/elsewhere" ;;
  images*stubproj*) cat "$DK/images" 2>/dev/null ;;
esac
exit 0
EOF
chmod +x "$DK/docker"
printf '#!/bin/sh\nexit 0\n' > "$R/.astraler/project/cleanup-worktree.sh"
printf 'stubproj-app\nshared-server\n' > "$DK/images"
out="$( (cd "$R" && PATH="$DK:$PATH" bash "$S/release-worktree-resources.sh" "$R/wt" 2>&1); echo "rc=$?" )"
case "$out" in
  *"otherproj"*|*"shared-server"*) bad "rwr compose scope" "checked a stack outside this worktree, or an image the project tags itself: $out" ;;
  *"'stubproj'"*"image stubproj-app"*"rc=1"*) ok "rwr names the image a plug's down -v left behind, and refuses the stamp" ;;
  *) bad "rwr compose leftover" "a built image survived the plug and nothing said so: $out" ;;
esac
: > "$DK/images"
out="$( (cd "$R" && PATH="$DK:$PATH" bash "$S/release-worktree-resources.sh" "$R/wt" 2>&1); echo "rc=$?" )"
case "$out" in
  *"no container, volume or built image left"*"rc=0"*) ok "rwr passes a stack the plug fully released" ;;
  *) bad "rwr compose clean" "$out" ;;
esac


# The release is ENFORCED by the git guard (2.7.15): an unstamped path is refused, a stamped
# one admitted. Watched to fail before the stamp existed — the guard allowed the removal.
# The stamped case then failed a SECOND way, and that one was real: the broker check's
# `bash -c "ps | grep …"` matched its own shell and refused every removal of an existing
# directory. Nothing had ever run this guard against a real directory before this case.
W="$TMP/wt-stamp"; mkdir -p "$W"
guard deny  "git worktree remove $W"
rm -f "$R/.astraler/project/cleanup-worktree.sh"   # the failing plug above must not stamp; an empty socket does
( cd "$R" && bash "$S/release-worktree-resources.sh" "$W" ) >/dev/null 2>&1
guard allow "git worktree remove $W"
mkdir -p "$TMP/wt-never-released"
guard deny  "git worktree remove --force $TMP/wt-never-released"   # --force is not a bypass
# ---------------------------------------------------------------------------------------------
# ticket-done — the SECOND enforced pin (2.8). A push of the base branch carrying a merge that
# names a ticket is refused until `ticket-done.sh <id>` has verified and stamped it; a push of
# any other branch is untouched; a tracker plug saying "open" blocks the stamp. Every case was
# watched to fail before the push block existed — the guard allowed all of them.
# ---------------------------------------------------------------------------------------------
echo "ticket-done — base push refused without the stamp, admitted with it, tracker plug decides (2.8)"
guard_in() { # <cwd> <expected deny|allow> <command>
  local cwd="$1" want="$2"; shift 2
  local out got
  out="$(printf '%s' "$1" | python3 -c '
import sys, json
print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Bash","cwd":sys.argv[1],
                  "tool_input":{"command":sys.stdin.read()}}))' "$cwd" \
    | HARNESS_HOOK_LOG="$TMP/hook.log" python3 "$S/hook-git-guard.py" 2>/dev/null)"
  if [ -n "$out" ]; then got=deny; else got=allow; fi
  [ "$want" = "$got" ] && ok "guard $want: $1" || bad "guard $1" "expected $want, got $got"
}
TD="$TMP/td"; mkdir -p "$TD"; ( cd "$TD" && git init -q -b main . && git config user.email t@t && git config user.name t \
  && git commit -q --allow-empty -m init \
  && git remote add origin "$TD" && git update-ref refs/remotes/origin/main HEAD \
  && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main \
  && git checkout -qb builder/ABC-7 && git commit -q --allow-empty -m "feat: x" \
  && git checkout -q main && git merge -q --no-ff builder/ABC-7 -m "Merge ABC-7: x (AST-069)
Ledger: none" \
  && git checkout -qb feature/other && git commit -q --allow-empty -m "wip" && git checkout -q main ) >/dev/null 2>&1
guard_in "$TD" deny  "git push origin main"                       # merge for ABC-7, no stamp
guard_in "$TD" deny  "git push"                                   # bare push of the base
guard_in "$TD" allow "git push origin feature/other"              # not the base branch
mkdir -p "$TD/.astraler/project"
printf '#!/bin/sh\necho "open alice"\n' > "$TD/.astraler/project/tracker-state.sh"; chmod +x "$TD/.astraler/project/tracker-state.sh"
( cd "$TD" && bash "$S/ticket-done.sh" ABC-7 --moved none ) >/dev/null 2>&1 \
  && bad "ticket-done open ticket" "stamped a ticket the tracker says is open" \
  || ok "ticket-done refuses while the tracker says open"
guard_in "$TD" deny  "git push origin main"                       # still no stamp
printf '#!/bin/sh\necho "closed -"\n' > "$TD/.astraler/project/tracker-state.sh"
( cd "$TD" && bash "$S/ticket-done.sh" ABC-7 --moved none ) >/dev/null 2>&1 \
  && ok "ticket-done stamps a merged, closed, released ticket" \
  || bad "ticket-done closed ticket" "did not stamp"
guard_in "$TD" allow "git push origin main"
( cd "$TD" && bash "$S/ticket-done.sh" ABC-9 ) >/dev/null 2>&1 \
  && bad "ticket-done unmerged" "stamped a ticket with nothing on the base" \
  || ok "ticket-done refuses a ticket with nothing on the base"
# A branch with no commit of its own is an ancestor of the base too. Measured 2026-10-05: a
# ticket whose Builder had committed nothing was stamped done, the tracker plug saying closed.
( cd "$TD" && git branch builder/ABC-11 main ) >/dev/null 2>&1
( cd "$TD" && bash "$S/ticket-done.sh" ABC-11 --moved none ) >/dev/null 2>&1 \
  && bad "ticket-done empty branch" "stamped a ticket whose branch never had a commit of its own" \
  || ok "ticket-done refuses a branch with no commit of its own"
# ...while a fast-forwarded branch, whose commits sit on the base's first-parent line exactly
# like the empty one's tip, still passes on its subject naming the ticket.
( cd "$TD" && git checkout -qb builder/ABC-12 && git commit -q --allow-empty -m "ABC-12: y" \
  && git checkout -q main && git merge -q --ff-only builder/ABC-12 ) >/dev/null 2>&1
( cd "$TD" && bash "$S/ticket-done.sh" ABC-12 --moved none ) >/dev/null 2>&1 \
  && ok "ticket-done stamps a fast-forwarded ticket by its subject" \
  || bad "ticket-done fast-forward" "refused a fast-forwarded ticket whose commit names it"

# ---------------------------------------------------------------------------------------------
# The `Ledger:` line — a rule nothing could refuse until 2.9.0. Measured in this package on
# 2026-09-14: 1 of the last 60 commits carried it, while the contract had required it since 2.0
# and the project's own site advertised it. These were watched to fail against the guard as it
# stood. The last case is the point of the whole check: a merge whose PROSE mentions the ledger
# is the shape a careful author produces when they mean to comply, and accepting it would pass
# on exactly the merges that skipped the step.
# ---------------------------------------------------------------------------------------------
echo "ledger line — declared, not mentioned (2.9.0)"
LD="$TMP/ld"; mkdir -p "$LD"; ( cd "$LD" && git init -q -b main . && git config user.email t@t && git config user.name t \
  && git commit -q --allow-empty -m init \
  && git remote add origin "$LD" && git update-ref refs/remotes/origin/main HEAD \
  && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main ) >/dev/null 2>&1
LDN=0
ld_merge() { # <subject-and-body> — a fresh branch each call; reusing one silently fails the
             # checkout, leaves the range empty, and turns a deny case green for the wrong reason
  LDN=$((LDN+1))
  ( cd "$LD" && git checkout -qb "builder/ABC-1-$LDN" && git commit -q --allow-empty -m "w" \
    && git checkout -q main && git merge -q --no-ff "builder/ABC-1-$LDN" -m "$1" ) >/dev/null 2>&1
}
mkdir -p "$HARNESS_STAMP_ROOT/harness-ticket-done" && : > "$HARNESS_STAMP_ROOT/harness-ticket-done/ABC-1"
ld_merge "Merge ABC-1: no declaration at all"
guard_in "$LD" deny  "git push origin main"            # no Ledger: line anywhere
( cd "$LD" && git reset -q --hard HEAD~1 ) >/dev/null 2>&1
ld_merge "Merge ABC-1: declared nothing

Ledger: none"
guard_in "$LD" allow "git push origin main"            # `Ledger: none` IS a declaration
( cd "$LD" && git reset -q --hard HEAD~1 ) >/dev/null 2>&1
ld_merge "Merge ABC-1: declared an entry

Ledger: AST-042"
guard_in "$LD" allow "git push origin main"
( cd "$LD" && git reset -q --hard HEAD~1 ) >/dev/null 2>&1
ld_merge "Merge ABC-1: wrote the ledger and moved on

This one updated the Ledger: carefully, see the entry."
guard_in "$LD" deny  "git push origin main"            # a MENTION is not a declaration
( cd "$LD" && git reset -q --hard HEAD~1 ) >/dev/null 2>&1
ld_merge "Merge ABC-1: empty value

Ledger:"
guard_in "$LD" deny  "git push origin main"            # a bare key declares nothing

# ---------------------------------------------------------------------------------------------
# Residency by REAL cwd (2.8, adopted from a downstream project's ten-case proof). Real
# fabricated processes with real cwds, never a mock of lsof. Cases 1 and 2 are the two the
# argv form got WRONG in opposite directions: a resident whose argv never names the path, and
# a non-resident whose argv does. Watched to fail against the `pgrep -f <path>` guard.
# ---------------------------------------------------------------------------------------------
echo "worktree residency — by real cwd, fails closed without lsof (2.8)"
if have lsof; then
  RW="$TMP/resident-wt"; mkdir -p "$RW"; R2="$TMP/rwr"
  ( cd "$R2" && bash "$S/release-worktree-resources.sh" "$RW" ) >/dev/null 2>&1   # stamp it, so residency is the only question
  ( cd "$RW" && exec -a app-server-broker sleep 60 ) & BK=$!                          # cwd inside, argv silent about the path
  sleep 0.3
  guard deny  "git worktree remove $RW"
  kill "$BK" >/dev/null 2>&1; wait "$BK" 2>/dev/null; sleep 0.3
  ( cd "$TMP" && exec sh -c "sleep 60 # $RW" ) & NB=$!                               # cwd elsewhere, argv names the path
  sleep 0.3
  guard allow "git worktree remove $RW"
  kill "$NB" >/dev/null 2>&1; wait "$NB" 2>/dev/null
  # lsof unreachable → fail closed
  PY3="$(command -v python3)"; NOPATH="$TMP/nopath"; mkdir -p "$NOPATH"; ln -sf "$PY3" "$NOPATH/python3"
  out="$(printf '%s' "git worktree remove $RW" | python3 -c '
import sys, json
print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":sys.stdin.read()}}))' \
    | PATH="$NOPATH" HARNESS_HOOK_LOG="$TMP/hook.log" "$PY3" "$S/hook-git-guard.py" 2>/dev/null)"
  case "$out" in *"cannot verify"*) ok "guard fails closed when lsof is unreachable" ;; *) bad "guard without lsof" "did not fail closed: ${out:-allowed}" ;; esac
  # the pure parser rejects a malformed listing outright
  # importlib would write scripts/__pycache__/*.pyc into the tree under test, and the ledger
  # index scans that directory for citations — a stale INDEX verdict from a test artefact.
  PYTHONDONTWRITEBYTECODE=1 "$PY3" - "$S/hook-git-guard.py" <<'PYT' && ok "malformed lsof listing rejects the whole table" || bad "lsof parser" "accepted a malformed listing"
import importlib.util, sys
spec = importlib.util.spec_from_file_location("g", sys.argv[1]); g = importlib.util.module_from_spec(spec); spec.loader.exec_module(g)
assert g._parse_lsof_pcn(["p1","cx","n/a","p2","cy"], "0") is None          # trailing record missing n
assert g._parse_lsof_pcn(["p1","cx","n/a","zz"], "0") is None               # unknown tag
assert g._parse_lsof_pcn(["p1","cx","n/a","p2","cy","n/b"], "2") == {"1": g.resolve_path("/a")}
PYT
else
  echo "  skip worktree residency — lsof not installed on this machine"
fi

# ---------------------------------------------------------------------------------------------
# A RULE REACHES EVERY RUNTIME, OR IT REACHES ONE (2.9.0).
#
# 2.7.13 is titled "the guard shipped for three runtimes and was registered on one":
# hook-git-guard.py lived in .claude/settings.json, which Codex does not read, so a Builder on
# a Codex pane ran with the contract above it and nothing underneath. That release fixed the
# registration for that one script. Nobody asked the next question, so in 2.9.0 the same shape
# was found twice more: hook-contract-reload.py registered only for Claude, and the four rules
# that outlive compaction present in the Claude and OpenCode adapters and in NONE of the five
# Codex profiles. Both were watched to fail here before they were fixed.
# ---------------------------------------------------------------------------------------------
echo "one rule, every runtime"

# WHY THIS SECTION IS NO LONGER `pkg_only` (2.10.0). It was, and that was the same defect it
# exists to catch, one floor down. The payload is where these five files are AUTHORED; the
# adapted project is where they are actually LOADED, and it is the only place they can drift —
# `.codex/profiles/` is a scaffold path `install.sh` keeps for the owner, so a project that
# already had one received none of 2.9.0's headline fix and its suite stayed green about it.
# The check that proves a rule reached every runtime must run where the runtimes are.
PAY="$ROOT/harness"; [ "$LAYOUT" = project ] && PAY="$ROOT"
for role in thomas shaper builder rin qa; do
  cla="$PAY/.claude/agents/$role.md"
  opc="$PAY/.opencode/agents/$role.md"
  cdx="$PAY/.codex/profiles/$role.md"
  # A project may not run all five roles, and a surface that does not exist there is not a
  # drifted surface. Absent files are reported as scope, never as a failure.
  present=0; miss=""
  for f in "$cla" "$opc" "$cdx"; do [ -f "$f" ] && present=$((present+1)); done
  if [ "$present" -eq 0 ]; then
    SKIPPED=$((SKIPPED+1)); echo "  skip compaction rules: $role — no adapter on any runtime here"
    continue
  fi
  [ ! -f "$cla" ] || grep -qi 'survives compaction' "$cla" || miss="$miss claude"
  [ ! -f "$opc" ] || grep -qi 'survives compaction' "$opc" || miss="$miss opencode"
  [ ! -f "$cdx" ] || grep -qi 'survives compaction' "$cdx" || miss="$miss codex"
  [ -z "$miss" ] && ok "compaction rules reach every runtime present: $role" \
                 || bad "compaction rules missing for $role" "absent on:$miss"
done

# Every hook script the payload ships must be named by every runtime that HAS a hook surface.
# OpenCode has none of the declarative kind, so it is out of scope here by measurement rather
# than by assumption — its adapters are markdown and carry the rules instead.
for hk in hook-git-guard.py hook-contract-reload.py hook-tracker-status.py; do
  inc=$(grep -c "$hk" "$PAY/.claude/settings.json" 2>/dev/null || echo 0)
  inx=$(grep -c "$hk" "$PAY/.codex/hooks.json" 2>/dev/null || echo 0)
  if [ "$inc" -gt 0 ] && [ "$inx" -gt 0 ]; then ok "registered for claude and codex: $hk"
  else bad "$hk registered on one runtime" "claude=$inc codex=$inx — this is the 2.7.13 shape"; fi
done

# hook-contract-reload had no case at all until 2.9.0, which is its own finding: the hook that
# defends the one failure whose correlation was measured as total had never been watched to
# fire, or to stay quiet.
reload() { # <expect fire|silent> <json>
  local want="$1" out got
  out="$(printf '%s' "$2" | python3 "$S/hook-contract-reload.py" 2>/dev/null)"
  if [ -n "$out" ]; then got=fire; else got=silent; fi
  [ "$want" = "$got" ] && ok "contract-reload $want: $3" || bad "contract-reload $3" "expected $want, got $got"
}
reload fire   '{"hook_event_name":"SessionStart","source":"compact","agent_type":"builder"}' "compact re-arms"
reload silent '{"hook_event_name":"SessionStart","source":"startup"}'                        "startup does not"
reload silent '{"hook_event_name":"SessionStart","source":"clear"}'                          "clear does not"
reload silent 'not json at all'                                                              "malformed stdin is silent"
reload fire   '{"hook_event_name":"SessionStart","source":"compact"}'                        "no role named still re-arms"

# ---------------------------------------------------------------------------------------------
# hook-tracker-status.py (2.10.0) — the hook that deletes an obligation instead of raising its
# tier (AST-142). Every case below was watched to FAIL against an empty scripts/ before the
# script existed, which is the only thing that earns a case a place here (AST-137).
#
# What is actually under test is the FAILURE discipline, not the happy path: this fires at the
# top of every session on every runtime, so a plug that is missing, dead, slow or silent must
# cost one line on stderr and nothing else. A session-start hook that can abort a session is a
# worse defect than the one it fixes.
# ---------------------------------------------------------------------------------------------
echo "hook-tracker-status — the moment, and every way the plug can let it down"

TS="$TMP/tracker"; mkdir -p "$TS/.astraler/project"; ( cd "$TS" && git init -q . ) >/dev/null 2>&1
tstat() { # <expect inject|silent> <json> <label>
  local want="$1" out got
  out="$( cd "$TS" && printf '%s' "$2" | CLAUDE_PROJECT_DIR="$TS" python3 "$S/hook-tracker-status.py" 2>/dev/null )"
  case "$out" in *additionalContext*) got=inject ;; *) got=silent ;; esac
  [ "$want" = "$got" ] && ok "tracker-status $want: $3" \
                       || bad "tracker-status $3" "expected $want, got $got"
}

# An absent plug is an empty socket: a note, never a failure, and never a broken session.
tstat silent '{"hook_event_name":"SessionStart","source":"startup"}' "no plug is an empty socket"
( cd "$TS" && printf '%s' '{"source":"startup"}' | python3 "$S/hook-tracker-status.py" >/dev/null 2>&1 ) \
  && ok "exits 0 with no plug" || bad "exit status with no plug" "a session-start hook must never fail closed"

printf '#!/bin/sh\necho "| open | wip |"\necho "| 12 | 3 |"\n' > "$TS/.astraler/project/tracker-status.sh"
chmod +x "$TS/.astraler/project/tracker-status.sh"
tstat inject '{"hook_event_name":"SessionStart","source":"startup"}' "a working plug is injected"
tstat inject '{"hook_event_name":"SessionStart","source":"resume"}'  "resume injects"
tstat inject '{"source":"startup"}'                                  "a payload with no event name still injects"
# compact belongs to hook-contract-reload: re-fetching there hands the agent two snapshots of
# the same board taken seconds apart and no way to tell which one its summary was reasoning on.
tstat silent '{"hook_event_name":"SessionStart","source":"compact"}' "compact is not this hook's moment"
tstat silent 'not json at all'                                       "malformed stdin is silent"
out="$( cd "$TS" && printf '%s' '{"source":"startup"}' | CLAUDE_PROJECT_DIR="$TS" python3 "$S/hook-tracker-status.py" 2>/dev/null )"
case "$out" in *"12"*) ok "the plug's own output reaches the context" ;;
               *)      bad "plug output" "the injected block did not carry what the plug printed" ;; esac

printf '#!/bin/sh\nexit 4\n' > "$TS/.astraler/project/tracker-status.sh"
tstat silent '{"source":"startup"}' "a plug that exits non-zero fails open"
printf '#!/bin/sh\nexit 0\n' > "$TS/.astraler/project/tracker-status.sh"
tstat silent '{"source":"startup"}' "a plug that prints nothing fails open"
printf '#!/bin/sh\nyes ABCDEFGHIJ | head -2000\n' > "$TS/.astraler/project/tracker-status.sh"
out="$( cd "$TS" && printf '%s' '{"source":"startup"}' | CLAUDE_PROJECT_DIR="$TS" python3 "$S/hook-tracker-status.py" 2>/dev/null )"
case "$out" in *"Cut off at"*) ok "an oversized plug is truncated AND says so" ;;
               *)              bad "truncation" "a cut-off count that does not admit it is worse than none" ;; esac
chmod -x "$TS/.astraler/project/tracker-status.sh"
tstat silent '{"source":"startup"}' "a non-executable plug fails open"

# ---------------------------------------------------------------------------------------------
# check-reachability checks 9, 10 and 11 (2.10.0) — the three the audit in AST-140/141 produced.
# Each is driven through a FIXTURE built to trip it, because a check that has only ever been run
# against a clean tree has been watched to stay quiet and never watched to fire.
# ---------------------------------------------------------------------------------------------
if pkg_only "reachability 9/10/11 fixtures"; then
echo "reachability — mention is not invocation, an assertion is about now, a rule follows its runtime"

RX="$TMP/rx"; rm -rf "$RX"; mkdir -p "$RX"
cp -R "$ROOT/harness" "$RX/harness"; mkdir -p "$RX/prompts"
# A staged release FLATTENS prompts/ to its root, and this suite runs there too (install.sh
# stages, then runs the staged copy of itself). Take the file from whichever layout we are in,
# or the fixture is missing a surface every check below scans and the baseline case fails for
# a reason that has nothing to do with what is being tested.
cp "$ROOT/prompts/ADAPT-HARNESS.md" "$RX/prompts/" 2>/dev/null \
  || cp "$ROOT/ADAPT-HARNESS.md" "$RX/prompts/" 2>/dev/null
cp "$ROOT/README.md" "$ROOT/install.sh" "$ROOT/check-requirements.sh" "$RX/" 2>/dev/null

# CAPTURE, NEVER PIPE. This file runs under `set -o pipefail` and check-reachability.sh exits 1
# when it has findings, so `rx | grep -q "the finding"` returns 1 — the pipeline inherits the
# tool's failure — and the case reads a CORRECT detection as a miss. The mirror is worse: the
# `goes quiet` cases were passing because grep found nothing on a clean tree, which is also what
# they would do if the tool were broken and printed nothing at all. Both halves were measured
# here on 2026-09-16 before this comment existed.
rx()  { python3 "$S/check-reachability.sh" "$RX" 2>&1; }
rxp() { python3 "$S/check-reachability.sh" "$RP" 2>&1; }

out="$(rx)"
says "$out" "All reachability checks passed" \
  && ok "the fixture copy is clean before anything is broken" \
  || bad "fixture baseline" "the copy already fails; every case below would be meaningless"

# 9 — a script named ONLY in a comment and in a printed string. This is the exact shape that
# scored an orphan as wired downstream: two comments and one `note "... (reap with tools/X)"`.
#
# The fixture's filename is COMPOSED and never written out whole, because this file is itself a
# payload script: a literal name here is a real script-to-script edge, check 9 reads it as a
# call site, and the fixture reports itself wired. Measured — that is how the first version of
# this case failed.
MO="orph""an-fixture.sh"
cat > "$RX/harness/scripts/$MO" <<'EOS'
#!/bin/sh
echo "I am shipped and nobody runs me"
EOS
printf '\n# see scripts/%s for the same logic\n' "$MO" >> "$RX/harness/scripts/ledger-index.sh"
printf 'echo "run scripts/%s by hand if this is ever non-zero"\n' "$MO" >> "$RX/harness/scripts/ledger-index.sh"
out="$(rx)"
says "$out" "$MO is shipped and nothing calls it" \
  && ok "check 9 refuses a comment and a printed string as call sites" \
  || bad "check 9 mention-vs-invocation" "a mention was accepted as a call — the 2.10.0 defect is back"
# ...and the same script, genuinely invoked, must go quiet — verified against a PASSING verdict,
# not against the absence of a string, so a tool that printed nothing could not pass this.
printf 'sh "$(dirname "$0")/%s" >/dev/null 2>&1 || true\n' "$MO" >> "$RX/harness/scripts/ledger-index.sh"
out="$(rx)"
says "$out" "All reachability checks passed" \
  && ok "check 9 goes quiet once the script is really invoked" \
  || bad "check 9 accepts a real call" "a genuinely invoked script is still reported as an orphan"
rm -f "$RX/harness/scripts/$MO"
cp "$ROOT/harness/scripts/ledger-index.sh" "$RX/harness/scripts/ledger-index.sh"

# 10 — a present-tense binding to a file that does not exist, and the `(gone)` retirement.
printf '\n### AST-999 — fixture\n\nBound: `.agents/roles/no-such-role.md`.\n' \
  >> "$RX/harness/.agents/memory/recurring-failure-modes.md"
out="$(rx)"
says "$out" "asserts a live binding to .agents/roles/no-such-role.md" \
  && ok "check 10 catches a Bound: line whose target is gone" \
  || bad "check 10" "a dead present-tense binding passed — this is the four-release footnote again"
python3 - "$RX" <<'EOS'
import sys, os
p = os.path.join(sys.argv[1], "harness", ".agents", "memory", "recurring-failure-modes.md")
t = open(p).read().replace("`.agents/roles/no-such-role.md`.", "`.agents/roles/no-such-role.md` (gone).")
open(p, "w").write(t)
EOS
out="$(rx)"
says "$out" "All reachability checks passed" \
  && ok 'check 10 accepts (gone) as an explicit retirement' \
  || bad "check 10 (gone)" "an explicitly retired citation is still reported"
cp "$ROOT/harness/.agents/memory/recurring-failure-modes.md" \
   "$RX/harness/.agents/memory/recurring-failure-modes.md"

# 10 — THE SAME CLAIM WITH A STAR IN IT. `Bound: `x/*.toml`` was not a resolved binding, not a
# finding and not even a counted assertion: the pattern demanded both backticks and `*` was
# outside its character class, so the citation matched nothing at all. Two entries carried that
# shape while the files behind it were renamed away (2.12.0), and check 10 stayed green over
# both. Watched to fail here first: with the star, invisible; without it, caught (AST-147).
printf '\n### AST-998 — fixture\n\nBound: `.agents/roles/*.no-such-suffix.md`.\n' \
  >> "$RX/harness/.agents/memory/recurring-failure-modes.md"
out="$(rx)"
says "$out" "asserts a live binding to .agents/roles/*.no-such-suffix.md" \
  && ok "check 10 reads a globbed binding that matches no file" \
  || bad "check 10 glob" "a starred Bound: line was excused by the pattern that was meant to read it"
cp "$ROOT/harness/.agents/memory/recurring-failure-modes.md" \
   "$RX/harness/.agents/memory/recurring-failure-modes.md"
out="$(rx)"
says "$out" "All reachability checks passed" \
  && ok "check 10 stays quiet on the payload's own globbed bindings" \
  || bad "check 10 glob" "a live glob binding in the shipped ledger reads as rot"

# 4 — `--profile <role>` is an address outside the repository. codex --help: it layers
# $CODEX_HOME/<name>.config.toml, which no payload ships and no adaptation writes since 2.12.0.
# A launcher written that way starts a pane with no role contract and Codex says nothing.
python3 - "$RX" <<'EOS'
import sys, os
p = os.path.join(sys.argv[1], "harness", ".agents", "skills", "dispatch-ticket-codex", "SKILL.md")
open(p, "a").write("\n```text\nbuilder → codex --profile builder\n```\n")
EOS
out="$(rx)"
says "$out" "launches \`--profile builder\`, an address outside the repository" \
  && ok "check 4 refuses the retired --profile launcher" \
  || bad "check 4 --profile" "a launcher pointing outside the repo passed as a resolved address"
cp "$ROOT/harness/.agents/skills/dispatch-ticket-codex/SKILL.md" \
   "$RX/harness/.agents/skills/dispatch-ticket-codex/SKILL.md"

# 4 — and the address that replaced it must resolve like any other payload path.
mv "$RX/harness/.codex/profiles/builder.md" "$RX/harness/.codex/profiles/builder.md.away"
out="$(rx)"
says "$out" "orchestrator.md puts builder on codex, but .codex/profiles/builder.md is absent" \
  && ok "check 4 catches a role the table puts on codex with no instruction file" \
  || bad "check 4 role file" "a launcher would have passed an empty developer_instructions and nothing went red"
mv "$RX/harness/.codex/profiles/builder.md.away" "$RX/harness/.codex/profiles/builder.md"

# docs-staleness axis 4 must actually READ the shipped prompts. Three attempts at that scope
# fix each passed `bash -n`, printed `(clean)`, and scanned zero files — an array that read as
# unbound inside the process substitution, a guard that two byte-identical copies disagreed
# about, and finally the real cause: `$ROOT` here is the PAYLOAD dir, so `$ROOT/prompts` does
# not exist. A check whose verdict is indistinguishable between "nothing wrong" and "nothing
# read" is the failure this whole release is named for, so it is pinned by planting a token.
#
# The token is COMPOSED, never written whole: this file lives in scripts/, which axis 4 scans,
# so a literal project-shaped id here makes that axis report on the suite itself, forever. The
# same trap as the orphan fixture above — met twice in one afternoon, which is why both now
# build their fixture names at run time.
TOK="XY""Z-991"
PF="$RX/prompts/ADAPT-HARNESS.md"
if [ -f "$PF" ]; then
  cp "$PF" "$PF.orig"
  printf '\nFixture token: %s.\n' "$TOK" >> "$PF"
  out="$(bash "$S/docs-staleness-audit.sh" "$RX/harness" 2>&1)"
  says "$out" "$TOK" \
    && ok "docs-staleness axis 4 reads the shipped prompts" \
    || bad "axis 4 prompts scope" "a project-shaped id in ADAPT-HARNESS.md went unreported"
  mv "$PF.orig" "$PF"
  out="$(bash "$S/docs-staleness-audit.sh" "$RX/harness" 2>&1)"
  says "$out" "$TOK" \
    && bad "axis 4 prompts scope" "still reporting a token that was removed" \
    || ok "axis 4 goes quiet once the token is gone"
else
  SKIPPED=$((SKIPPED+1)); echo "  skip axis 4 prompts scope — no prompts/ in this layout"
fi

# 4 — a project's own vocabulary. Before 2.10.0 the only place to silence a skill-shaped token
# was the payload set inside check-reachability.sh, so the project redid that edit on every
# upgrade and the error text told it to. Watched here both ways: red without the plug, green
# with it — the second half matters more, because an allowance that does not actually allow is
# how a gate stays permanently red and stops being read.
VOC="$TMP/rxvoc"; rm -rf "$VOC"; cp -R "$RX" "$VOC"
python3 - "$VOC" <<'EOS'
import sys, os
p = os.path.join(sys.argv[1], "harness", ".agents", "roles", "thomas.md")
open(p, "a").write("\n\nA container this project runs: `some-project-stage-server`.\n")
EOS
out="$(python3 "$S/check-reachability.sh" "$VOC" 2>&1)"
says "$out" "names 'some-project-stage-server'" \
  && ok "check 4 flags a skill-shaped token it does not know" \
  || bad "check 4 vocabulary" "an unknown skill-shaped token passed unreported"
mkdir -p "$VOC/.astraler/project"
printf '# this project'"'"'s own words\nsome-project-stage-server\n' > "$VOC/.astraler/project/not-a-skill.txt"
out="$(python3 "$S/check-reachability.sh" "$VOC" 2>&1)"
says "$out" "names 'some-project-stage-server'" \
  && bad "check 4 project vocabulary" "the plug was declared and the token is still reported" \
  || ok "check 4 accepts .astraler/project/not-a-skill.txt"

# 11 — the loaded trap: a rule in the Claude-only tier while a role is assigned to another
# runtime. Needs project layout, because no package ships that tier.
RP="$TMP/rxproj"; rm -rf "$RP"; mkdir -p "$RP/.claude/rules"
cp -R "$ROOT/harness/." "$RP/"
printf '# fixture rule\n' > "$RP/.claude/rules/fixture-invariant.md"
python3 - "$RP" <<'EOS'
import sys, os, re
p = os.path.join(sys.argv[1], ".agents", "orchestrator.md")
t = open(p).read()
t = re.sub(r"^\|\s*builder\s*\|\s*claude\s*\|", "| builder | codex |", t, count=1, flags=re.M)
open(p, "w").write(t)
EOS
out="$(rxp)"
says "$out" "role 'builder' runs on codex, which never sees .claude/rules/fixture-invariant.md" \
  && ok "check 11 fires when a role is moved off the runtime its rules live on" \
  || bad "check 11" "reassigning a runtime silenced an always-on rule and nothing went red"
printf 'fixture-invariant\n' >> "$RP/.codex/profiles/builder.md"
out="$(rxp)"
says "$out" "never sees .claude/rules/fixture-invariant.md" \
  && bad "check 11 after carrying the rule" "the rule was carried into the profile and it still fires" \
  || ok "check 11 goes quiet once the rule is carried into that runtime's adapter"
fi
# ---------------------------------------------------------------------------------------------
# THE CODEX LAUNCHER: THE ROW, THE FILE, AND A MECHANISM THAT RETIRED UNDER IT (2.12.0).
#
# `codex --profile <role>` layers `$CODEX_HOME/<role>.config.toml` and nothing else — the CLI's
# own help says so. Until 2.12.0 this package shipped in-repo templates for a machine-local file
# the owner had to copy by hand into a namespace every project on the machine shares. The
# replacement passes the role file on the command line, which makes the orchestrator row the
# only home for model and effort and leaves three ways to be wrong, each fired here first.
# ---------------------------------------------------------------------------------------------
echo "codex launcher — a row that names no model, a file that is not there, a mechanism that retired"

CR="$ROOT/check-requirements.sh"; [ -f "$CR" ] || CR="$S/check-requirements.sh"
if [ -f "$CR" ]; then
  CFIX="$TMP/cqfix"
  cfresh() {
    rm -rf "$CFIX"; mkdir -p "$CFIX"
    cp -R "$ROOT/harness/.agents" "$CFIX/.agents"
    cp -R "$ROOT/harness/.codex"  "$CFIX/.codex"
  }
  crow() { python3 - "$CFIX" "$1" <<'EOS'
import sys, os, re
p = os.path.join(sys.argv[1], ".agents", "orchestrator.md")
t = open(p).read()
t = re.sub(r"^\|\s*builder\s*\|\s*codex\s*\|.*\n", sys.argv[2], t, count=1, flags=re.M)
open(p, "w").write(t)
EOS
  }
  cq() { bash "$CR" "$CFIX" 2>&1; }

  # A row that claims the runtime and names nothing to launch. Until 2.12.0 one awk condition
  # answered two questions — is there a row, and does it name a model — and delivered the
  # second answer as the first: a blank Model cell printed `no codex row … does not run on
  # Codex`, which is what a DELIBERATE decline looks like. AST-040 wearing a blank.
  cfresh; crow '| builder | codex |  | medium |
'
  out="$(cq)"
  says "$out" "Codex builder has a codex row with no model" \
    && ok "a codex row with a blank model is a finding, not a decline" \
    || bad "codex row/model" "a role that cannot launch was reported as declining the runtime"

  # And the decline itself must still read as one, or the fix above turns into noise on every
  # project that deliberately runs a role on one runtime.
  cfresh; crow ''
  out="$(cq)"
  says "$out" "Codex builder: no codex row — this role does not run on Codex" \
    && ok "no codex row still reads as a deliberate decline" \
    || bad "codex row absent" "declining a runtime now produces a finding"

  # A TARGET missing its own file must not be answered by the package's copy. Same class as
  # 2.11.0's staleness gate measuring the caller's cwd: the checker was handed a tree and
  # reported on a different one.
  cfresh; rm -f "$CFIX/.codex/profiles/builder.md"
  out="$(cq)"
  says "$out" "Codex builder instruction file not found" \
    && ok "a target with no instruction file is not answered by the package's copy" \
    || bad "codex file scope" "the checker fell back across the target boundary and reported OK"

  # The file IS the pane's system prompt, so a sentence describing the retired mechanism is
  # read as instruction. Measured downstream: five role files kept "it exists so codex
  # --profile <role> resolves" through the change that retired it, and the pane quoted it back.
  cfresh; printf 'it exists so codex --profile builder resolves\n' >> "$CFIX/.codex/profiles/builder.md"
  out="$(cq)"
  says "$out" "still describe the retired --profile mechanism" \
    && ok "role instructions teaching a dead mechanism are reported" \
    || bad "codex stale mechanism" "a pane would be told to use a flag that resolves nowhere"

  # An upgrade adds `<role>.md` and cannot delete the `<role>.config.toml` it no longer ships.
  # Both then sit in the same directory and the stale one still reads as current.
  cfresh; printf 'model = ""\n' > "$CFIX/.codex/profiles/builder.config.toml"
  out="$(cq)"
  says "$out" "pre-2.12 profile TOML still present" \
    && ok "a leftover profile TOML is named rather than left beside the live file" \
    || bad "codex legacy leftover" "two files, one dead, and the upgrade said nothing"

  # An empty Effort cell is refused where an empty model is. Measured: the launcher passes
  # `-c model_reasoning_effort=""` and Codex refuses it while loading config —
  # `reasoning_effort must not be empty` — so the pane never starts, after dispatch has already
  # reported a launch. It was a WARN until 2026-09-20, on the wrong reading that an empty cell
  # falls back to an account default (AST-151).
  cfresh; crow '| builder | codex | gpt-5.6-luna |  |
'
  out="$(cq)"
  says "$out" "[MISS] Codex builder row names a model and no effort" \
    && ok "an empty effort cell is refused, not warned about" \
    || bad "codex empty effort" "a row that cannot boot a pane passed as an advisory"

  # The green case, because a gate only read when it is red teaches nothing about when it is right.
  cfresh; crow '| builder | codex | gpt-5.6-luna | medium |
'
  out="$(cq)"
  says "$out" "Codex builder row: gpt-5.6-luna / medium" \
    && ok "a fully configured codex row reports the pair it will launch with" \
    || bad "codex row green" "a correct row produced no confirmation"
else
  SKIPPED=$((SKIPPED+1)); echo "  skip codex launcher — check-requirements.sh not in this layout"
fi

# A path is never built from unvetted input: a role name with a separator must not escape.
out="$(printf '%s' '{"hook_event_name":"SessionStart","source":"compact","agent_type":"../../etc/passwd"}' \
       | python3 "$S/hook-contract-reload.py" 2>/dev/null)"
case "$out" in
  *"/etc/passwd"*) bad "contract-reload path traversal" "a role name reached the emitted path" ;;
  *)               ok  "contract-reload refuses a role name that is not a bare identifier" ;;
esac

# ---------------------------------------------------------------------------------------------
# THE WATCHDOG ASKS ABOUT ONE PANE (2.13.0).
#
# Two downstream measurements: a Builder that worked and then stopped beside a busy sibling
# fired nothing, because STUCK needed NO pane working anywhere; and a pane that never started
# was invisible to all three alerts. Both were watched to be silent on the 2.12.0 analyzer
# before this section was written. The analyzer is the python inside `analyze()`, run here on a
# stubbed `herdr` and `pgrep`, poll after poll against one state dir, because the alerts it
# gained are about what happens ACROSS polls — a single call cannot fail them.
# ---------------------------------------------------------------------------------------------
echo "watchdog — a stall beside a busy sibling, a pane that never started, a run in the background"

WD="$S/herdr-watchdog.sh"
W="$TMP/wd"; mkdir -p "$W/bin" "$W/proj/.astraler/project" "$W/state"
awk '/^analyze\(\) \{/{f=1;next} f&&/^  python3 -c '"'"'$/{g=1;next} g&&/^'"'"' 2>\/dev\/null$/{exit} g{print}' "$WD" \
  | sed -e "s#\"'\"\$WORKSPACE_LABEL\"'\"#\"ws\"#" -e "s#\"'\"\$PROJECT_ROOT\"'\"#\"$W/proj\"#" \
        -e "s#\"'\"\$STATE_DIR\"'\"#\"$W/state\"#" > "$W/analyze.py"
printf '#!/bin/sh\necho %s\n' "'{\"result\":{\"workspaces\":[{\"label\":\"ws\",\"workspace_id\":\"w1\"}]}}'" > "$W/bin/herdr"
printf '#!/bin/sh\nexit 1\n' > "$W/bin/pgrep"
chmod +x "$W/bin/herdr" "$W/bin/pgrep"
# wd_polls <builder status>... : one poll per status, sibling always working, prints alerts per poll
wd_polls() {
  rm -rf "$W/state"; mkdir -p "$W/state"; local st
  for st in "$@"; do
    printf '{"result":{"agents":[{"pane_id":"w1:t","name":"thomas","agent_status":"done"},{"pane_id":"w1:b","name":"builder-x","agent_status":"%s"},{"pane_id":"w1:s","name":"builder-y","agent_status":"working"}]}}' "$st" \
      | PATH="$W/bin:$PATH" python3 "$W/analyze.py" 2>&1 | grep -v '^__' | grep '|w1:b' | cut -d'|' -f1 | tr '\n' ' '
    printf ';'
  done
}
if [ ! -s "$W/analyze.py" ]; then
  bad "watchdog analyzer extraction" "could not lift analyze() out of $WD — the fixture no longer matches the script"
else
  out="$(wd_polls working idle idle)"
  case "$out" in *";;STUCK ;"|*";; STUCK ;") ok "STUCK fires for a pane that worked and stopped, beside a busy sibling" ;;
                 *) bad "STUCK beside a busy sibling" "got '$out' — one working sibling is silencing every other pane again" ;; esac
  out="$(wd_polls idle idle)"
  case "$out" in ";NEVER_STARTED ;") ok "NEVER_STARTED fires on the second poll of a pane that never worked, and not the first" ;;
                 *) bad "NEVER_STARTED" "got '$out' — a pane that never started is invisible again, or fires on first sighting" ;; esac
  printf '#!/bin/sh\nexit 0\n' > "$W/proj/.astraler/project/work-in-flight.sh"; chmod +x "$W/proj/.astraler/project/work-in-flight.sh"
  out="$(wd_polls working idle idle)"
  case "$out" in *STUCK*) bad "work-in-flight plug" "STUCK fired while the project said a run is in flight: '$out'" ;;
                 *) ok "STUCK stays quiet while .astraler/project/work-in-flight.sh says a run is in flight" ;; esac
  printf '#!/bin/sh\nexit 7\n' > "$W/proj/.astraler/project/work-in-flight.sh"
  out="$(wd_polls working idle idle)"
  case "$out" in *STUCK*) bad "work-in-flight plug, broken" "a plug that errored read as nothing-in-flight: '$out'" ;;
                 *) ok "a work-in-flight plug that errors reads as in flight" ;; esac
  rm -f "$W/proj/.astraler/project/work-in-flight.sh"
fi

# ---------------------------------------------------------------------------------------------
# The dispatch mod. On a Claude root it is the only thing that records a pane, delivers its
# brief and reports its turn end, so a mod that does not load leaves every Claude pane
# unwatched. Claude Code's own reader validates it the way the engine loads it, and a planted
# defect proves the reader names one: a check only ever seen passing has not been tested.
# ---------------------------------------------------------------------------------------------
echo "dispatch mod — the engine's reader loads it, and refuses a broken copy"
MOD="$(dirname "$S")/.claude/skills/astragentic-dispatch"
if [ ! -d "$MOD" ]; then
  bad "dispatch mod" "missing at $MOD — Claude panes would run unrecorded and unwatched"
elif ! have claude; then
  SKIPPED=$((SKIPPED+1)); echo "  skip dispatch mod — no claude CLI to validate it with"
else
  out="$(claude plugin validate "$MOD" 2>&1)"; rc=$?
  missing=""
  for h in session.start session.receive turn.complete "tool.call{tool=Bash}"; do
    says "$out" "$h" || missing="$missing $h"
  done
  if [ "$rc" -eq 0 ] && [ -z "$missing" ]; then
    ok "dispatch mod validates and hooks session.start, session.receive, turn.complete, tool.call"
  else
    bad "dispatch mod validation" "exit=$rc, hooks missing:${missing:- none}"
  fi
  rm -rf "$TMP/mod-broken"; cp -R "$MOD" "$TMP/mod-broken"
  python3 - "$TMP/mod-broken/hooks/register.tsx" <<'EOS'
import sys
p = sys.argv[1]; s = open(p).read()
anchor = "export const register: Register = on => {\n"
s = s.replace(anchor, anchor + "  on('session.end', ($, e, next) => { const leak = (x: any) => x; leak($); return next(e) })\n", 1)
open(p, 'w').write(s)
EOS
  if claude plugin validate "$TMP/mod-broken" >/dev/null 2>&1; then
    bad "dispatch mod planted defect" "the reader passed a module that leaks \$ — this check cannot fail"
  else
    ok "the reader refuses a planted defect in the dispatch mod"
  fi
fi

# ---------------------------------------------------------------------------------------------
echo
if [ "$FAIL" -eq 0 ]; then
  echo "selftest: $PASS passed, 0 failed ($LAYOUT layout, $SKIPPED package-only section(s) skipped)."
  exit 0
fi
echo "selftest: $PASS passed, $FAIL FAILED ($LAYOUT layout, $SKIPPED package-only section(s) skipped)"
printf '%b' "$FAILED"
echo
echo "Each case above is an invocation shape this package has shipped a defect in. A failure"
echo "here is a regression of a real one, not a hypothetical."
exit 1
