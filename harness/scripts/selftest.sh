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

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

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
  python3 "$S/check-reachability.sh" "$ROOT" >/dev/null 2>&1 \
    && ok "check-reachability runs under python3 (never bash -n)" \
    || bad "check-reachability" "python3 invocation failed"
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
rm -rf /tmp/harness-ticket-done
TD="$TMP/td"; mkdir -p "$TD"; ( cd "$TD" && git init -q -b main . && git config user.email t@t && git config user.name t \
  && git commit -q --allow-empty -m init \
  && git remote add origin "$TD" && git update-ref refs/remotes/origin/main HEAD \
  && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main \
  && git checkout -qb builder/ABC-7 && git commit -q --allow-empty -m "feat: x" \
  && git checkout -q main && git merge -q --no-ff builder/ABC-7 -m "Merge ABC-7: x (AST-069)" \
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
rm -rf /tmp/harness-ticket-done

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
