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
guard deny  'echo "retire the pane (already closed)" && git add -A'  # quoted ( is data: judged

echo "hook-git-guard — a sweeping add is judged even on an unreadable line (4.0.2)"
# Measured downstream: six `git add -A && git commit -m "$(cat <<EOF` lines passed as
# no-opinion in two days while the bare form was refused seven times. The sweep is two words
# at the head of the line; the heredoc that made the line unreadable is the commit message.
guard deny  'git add -A && git commit -m "$(cat <<EOF
feat: thing

body
EOF
)"'
guard deny  'echo "done (ok) $(true)" && git add -A'   # was allow before 4.0.2: unreadable tail, readable sweep
guard deny  'if git add -A; then :; fi'
guard deny  'FOO=bar git add -A'
guard deny  'git add -A -- .'
guard deny  'git add -A .'
guard allow 'git add -A -- apps/server apps/dashboard'   # path-limited: ~100 of 163 downstream refusals were this shape
guard allow 'git add --all src/'
guard allow 'git add -A -- "apps/server"'            # a quoted pathspec is a path
guard deny  'git add -A
git commit -m "$(cat <<EOF
msg
EOF
)"'                                        # two lines: the sweep on line 1, the heredoc on line 2
guard allow 'git commit -m "$(cat <<EOF
docs: say never run git add -A in this repo
EOF
)"'                                         # the words inside the heredoc body are data
guard allow 'echo "$(git add -A)"'          # substitution inside quotes: data to this scan
guard allow 'cat <<EOF
git add -A
EOF'                                        # heredoc body
guard allow 'git add -A.txt'                # a file named -A.txt is a path, not the flag
guard deny  'xargs git add -A'              # a wrapper still runs the sweep (was out of scope before 4.0.2)

echo "hook-git-guard — the paths a refusal suggests are shell-quoted, and a hostile name is a name (4.1.0)"
# The 4.1.0 arm planted `$(printf INJECTED)` as a filename and the suggested command ran it.
HG="$TMP/hostile"; rm -rf "$HG"; mkdir -p "$HG"
( cd "$HG" && git init -q && git config user.email t@t && git config user.name t && echo a > a.txt && git add a.txt && git commit -qm init \
  && echo b >> a.txt && touch '$(printf INJECTED)' && touch -- '-A' && mkdir -p 'd i r' && touch 'd i r/x y.txt' && touch ':(glob)*' ) >/dev/null 2>&1
sugg="$(cd "$HG" && printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Bash","cwd":"'"$HG"'","tool_input":{"command":"git add -A"}}' \
  | HARNESS_HOOK_LOG="$TMP/hook.log" python3 "$S/hook-git-guard.py" 2>/dev/null \
  | python3 -c 'import sys,json;r=json.load(sys.stdin)["hookSpecificOutput"]["permissionDecisionReason"];i=r.find("git --literal-pathspecs add -- ");print(r[i:] if i>=0 else "")')"
if [ -n "$sugg" ] && ( cd "$HG" && eval "$sugg" >/dev/null 2>&1 && [ "$(git diff --cached --name-only | wc -l | tr -d ' ')" = "5" ] && ! ls INJECTED >/dev/null 2>&1 ); then
  ok "a refusal's suggested command stages the five changed files by name, including \$(…), -A, a space and :(glob)*"
else
  bad "guard suggested paths" "suggestion: '$sugg' — staged $(cd "$HG" && git diff --cached --name-only | wc -l | tr -d ' ') files"
fi

echo "hook-git-guard — a read-only role is refused the repository's write commands (4.2.0)"
# The BA talks and cuts tickets; its contract says never commit/push/merge/dispatch. One
# downstream project shipped that rule as prose on 2026-10-21 with nothing under it. The
# guard reads the role from `agent_type` when the payload carries it, else from the marker
# hook-tracker-status.py writes at SessionStart (SessionStart carries agent_type; measured).
guard_role() { # <expected deny|allow> <extra payload json fields> <command> [guard script]
  local want="$1" extra="$2" cmd="$3" script="${4:-$S/hook-git-guard.py}"; local out got
  out="$(printf '%s' "$cmd" | python3 -c '
import sys, json
extra = json.loads(sys.argv[1])
p = {"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":sys.stdin.read()}}
p.update(extra); print(json.dumps(p))' "$extra" \
    | ASTRAGENTIC_ROLE_MARKER_DIR="$TMP" HARNESS_HOOK_LOG="$TMP/hook.log" python3 "$script" 2>/dev/null)"
  if says "$out" '"permissionDecision": "deny"'; then got=deny; else got=allow; fi
  [ "$want" = "$got" ] && ok "guard($extra) $want: $cmd" || bad "guard role $cmd" "expected $want, got $got: $out"
}
guard_role deny  '{"agent_type":"ba"}' 'git commit -m "tidy"'
guard_role deny  '{"agent_type":"ba"}' 'cd /x && git push origin main'
guard_role deny  '{"agent_type":"ba"}' 'git commit -m "$(cat <<EOF
msg
EOF
)"'                                                    # whole text, heredoc included
guard_role deny  '{"agent_type":"ba"}' 'gh pr merge 12 --squash'
guard_role deny  '{"agent_type":"ba"}' 'bash scripts/ticket-done.sh AB-1'
guard_role deny  '{"agent_type":"ba"}' 'herdr agent start --cwd /x claude'
guard_role allow '{"agent_type":"ba"}' 'git log --oneline -5'
guard_role allow '{"agent_type":"ba"}' 'gh issue create --title "AB-9: x" --body-file /tmp/b.md'
guard_role allow '{"agent_type":"builder"}' 'git commit -m "tidy"'    # the gate is the role's, not everyone's
# the marker path: no agent_type on the call, the SessionStart hook wrote the role for this session
printf '%s' '{"source":"startup","session_id":"sess-ba-1","agent_type":"ba"}' \
  | ASTRAGENTIC_ROLE_MARKER_DIR="$TMP" CLAUDE_PROJECT_DIR="$TMP/stamps" python3 "$S/hook-tracker-status.py" >/dev/null 2>&1
[ "$(cat "$TMP/astragentic-role-sess-ba-1" 2>/dev/null)" = "ba" ] && ok "hook-tracker-status writes the role marker from SessionStart's agent_type" \
  || bad "role marker" "hook-tracker-status did not write $TMP/astragentic-role-sess-ba-1"
guard_role deny  '{"session_id":"sess-ba-1"}' 'git merge builder/AB-1'
guard_role allow '{"session_id":"sess-none"}' 'git merge builder/AB-1'   # no marker, no agent_type: not a BA pane
# planted: a guard with the role gate removed lets the BA commit
sed 's/if role in READ_ONLY_ROLES:/if False:/' "$S/hook-git-guard.py" > "$TMP/guard-no-role.py"
guard_role allow '{"agent_type":"ba"}' 'git commit -m "tidy"' "$TMP/guard-no-role.py"

echo "hook-git-guard — the quick pane commits data inside quick-paths and nothing else (4.3.0)"
# Six catalog-data commits in 30 days downstream, each paid for as a full Builder ticket to run
# a tool that existed. The quick pane may commit only the paths the project declares, in one
# git shape the guard can read: index commit, ff-only merge of its own ops/* branch, push of it.
QR="$TMP/quick-repo"; rm -rf "$QR"; mkdir -p "$QR/.astraler/project" "$QR/apps/server/catalog-data" "$QR/apps/server/internal"
( cd "$QR" && git init -q && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init )
printf '# data the owner curates\napps/server/catalog-data/**\n' > "$QR/.astraler/project/quick-paths"
quick() { # <expected deny|allow> <command> [guard script]
  local want="$1" cmd="$2" script="${3:-$S/hook-git-guard.py}"; local out got
  out="$(printf '%s' "$cmd" | python3 -c '
import sys, json
print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":sys.stdin.read()},"agent_type":"quick","cwd":sys.argv[1]}))' "$QR" \
    | ASTRAGENTIC_ROLE_MARKER_DIR="$TMP" HARNESS_HOOK_LOG="$TMP/hook.log" python3 "$script" 2>/dev/null)"
  if says "$out" '"permissionDecision": "deny"'; then got=deny; else got=allow; fi
  [ "$want" = "$got" ] && ok "quick $want: ${cmd:0:70}" || bad "quick $cmd" "expected $want, got $got: $out"
}
echo x > "$QR/apps/server/catalog-data/images.json"; ( cd "$QR" && git add apps/server/catalog-data/images.json )
quick allow 'git commit -m "catalog: 12 new images"'
echo y > "$QR/apps/server/internal/a.go"; ( cd "$QR" && git add apps/server/internal/a.go )
quick deny  'git commit -m "catalog: and a little code"'             # one file outside: refused, named
( cd "$QR" && git reset -q -- apps/server/internal/a.go )
quick deny  'git commit -am "everything"'
quick deny  'git commit -m x -- apps/server/catalog-data/images.json'  # a pathspec commit is not the index
quick deny  'git commit -m "$(cat <<EOF
x
EOF
)"'                                                                   # unreadable around git: refused, not skipped
quick allow 'git merge --ff-only ops/images-1022'
quick deny  'git merge ops/images-1022'
quick deny  'git merge --ff-only builder/AB-1'
quick allow 'git push origin main'
quick allow 'git push -u origin ops/images-1022'
quick deny  'git push origin feature/x'
quick deny  'git push --force origin main'
quick allow 'git worktree add -b ops/images-1022 /tmp/wt main'
quick deny  'git worktree add -b feat/x /tmp/wt main'
quick deny  'git rebase main'
quick deny  'bash scripts/ticket-done.sh AB-1'
quick allow 'go run ./cmd/curated-images-upload --dir /tmp/imgs && git status --short'
rm "$QR/.astraler/project/quick-paths"
quick deny  'git commit -m "no quick-paths declared"'
# planted: a guard whose quick gate never runs lets the code file through
sed 's/if role == QUICK_ROLE:/if False:/' "$S/hook-git-guard.py" > "$TMP/guard-no-quick.py"
printf 'apps/server/catalog-data/**\n' > "$QR/.astraler/project/quick-paths"
( cd "$QR" && git add apps/server/internal/a.go )
quick allow 'git commit -m "catalog: and a little code"' "$TMP/guard-no-quick.py"

echo "hook-git-guard — the registered wrapper's unreadable-file fallback runs the same guard (4.0.2)"
# Measured downstream: 27 whole-session blocks where python3 could not open the hook file
# ([Errno 1] under ~/Documents: macOS TCC on Python.app, or a sandbox) while the shell could
# stat it, and `onFailure: block` then refused every Bash call. The wrapper now runs the file
# from a shell read; this proves that form reaches the same verdict.
out="$(printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git add -A"}}' \
  | HARNESS_HOOK_LOG="$TMP/hook.log" python3 -c "$(cat "$S/hook-git-guard.py")" 2>/dev/null)"
says "$out" '"permissionDecision": "deny"' \
  && ok "python3 -c \"\$(cat guard)\" denies git add -A like python3 guard does" \
  || bad "wrapper fallback" "the shell-read form did not deny: $out"
# the settings file of the layout this runs in: a project has no harness/ (nizzy, 4.1.0 receipt)
SJ="$ROOT/harness/.claude/settings.json"; [ "$LAYOUT" = project ] && SJ="$ROOT/.claude/settings.json"
if python3 - "$SJ" <<'PY' 2>/dev/null
import json, sys
d = json.load(open(sys.argv[1]))
cmds = [h.get("command", "") for arr in d.get("hooks", {}).values() for m in arr for h in m.get("hooks", [])]
py = [c for c in cmds if "python3" in c]
sys.exit(0 if py and all('exec python3 -c "$(cat "$s")"' in c for c in py) else 1)
PY
then
  ok "settings.json wrappers carry the found-but-unreadable fallback"
else
  bad "wrapper fallback registration" "settings.json has no shell-read fallback for the python hooks"
fi

# The distinction the shrink was FOR: unsupported structure must record no-opinion, not allow.
if grep -q 'no-opinion' "$TMP/hook.log" 2>/dev/null; then
  ok "guard logs no-opinion distinctly from allow (2.7.4)"
else
  bad "guard no-opinion logging" "expected a no-opinion entry in the fire log"
fi

if pkg_only "argument conventions"; then

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
  # 4.0.1 — bytecode is not a citation. 4.0.0's INDEX.md was generated beside a `__pycache__/`
  # and named `.pyc` files as citing files; the clean clone a project fetches regenerates without
  # them, and the release's own check 5 refused it on every fetch (found by nizzy-ecom, 2026-10-17).
  cp "$TMP/idx.clean" "$IDX"
  mkdir -p "$COPY/scripts/__pycache__"
  printf 'AST-001 AST-028 AST-050\n' > "$COPY/scripts/__pycache__/planted.cpython-314.pyc"
  (cd "$COPY" && bash "$COPY/scripts/ledger-index.sh" >/dev/null 2>&1)
  if grep -q 'cpython' "$IDX"; then
    bad "ledger-index bytecode" "INDEX.md names a .pyc under __pycache__ as a citing file"
  else
    ok "ledger-index ignores __pycache__ bytecode when counting citations"
  fi
  rm -rf "$COPY/scripts/__pycache__"
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
if head -1 "$S/check-reachability.py" | grep -q python && { [ "$LAYOUT" = package ] || [ -d "$ROOT/.astraler/releases" ]; }; then
  # ASSERT THE INTERPRETER RAN, NOT THAT THE TREE IS CLEAN. This case is about invocation
  # shape — the file is python with a `.sh` name, and `bash -n` on it is the defect. It used
  # to assert exit 0, but check-reachability exits 1 on ANY finding, so an adapted project
  # with one legitimate finding read this as a broken invocation. Measured 2026-09-16 on the
  # first real project to run it: a benign Docker container name in a contract produced one
  # check-4 finding, and the suite reported the invocation as failed. A gate that cannot go
  # green on a healthy project is a gate people stop reading.
  _cr="$(python3 "$S/check-reachability.py" "$ROOT" 2>&1)"; _crx=$?
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
  && git commit -q --allow-empty -m 'qa(walk): s1 — PASS

Scope: s1
Mode: walk
Verdict: PASS (0 fail, 0 concerns)
Report: /tmp/g.md' ) >/dev/null 2>&1
B="$( cd "$R" && git rev-parse HEAD )"
( cd "$R" && for i in 1 2 3; do
    git checkout -q -b "t$i" && git commit -q --allow-empty -m "t$i" \
      && git checkout -q - && git merge -q --no-ff "t$i" -m "merge t$i"
  done ) >/dev/null 2>&1
# A 40-character SHA is what the router passes at merge; a branch name is what gets tested.
out="$( cd "$R" && bash "$S/check-simplify-markers.sh" "$B" HEAD --marker 'qa(walk)' 2>&1 | head -1 )"
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
        "$ROOT/RELEASE-NOTES.md" "$ROOT/check-requirements.sh" "$ROOT/prompts" "$ROOT/astragentic.sh" "$SP/" 2>/dev/null
  T3="$TMP/spaced-target"; mkdir -p "$T3"; ( cd "$T3" && git init -q . ) >/dev/null 2>&1
  ( cd "$SP" && bash install.sh "$T3" ) >/dev/null 2>&1 && [ -d "$T3/.astraler/releases/$V" ] \
    && ok "stages from a path containing a space" \
    || bad "spaced path" "a repository path with a space refused a valid install"

  # A RETIRED PATH IS REPORTED, NOT SKIPPED. The runtime-profile directories were removed from
  # the payload; a project that still carries one must be told by the "DELETED upstream"
  # report, because nothing else sees a file the release no longer ships. The fixture is an
  # earlier staged release that shipped the file, and a project that still has it.
  T4="$TMP/retired"; rm -rf "$T4"
  mkdir -p "$T4/.codex/profiles" "$T4/.astraler/releases/0.0.1/harness/.codex/profiles" "$T4/.astraler/state"
  ( cd "$T4" && git init -q . ) >/dev/null 2>&1
  printf 'x\n' > "$T4/.codex/profiles/builder.md"
  cp "$T4/.codex/profiles/builder.md" "$T4/.astraler/releases/0.0.1/harness/.codex/profiles/"
  printf '0.0.1\n' > "$T4/.astraler/state/applied-version"
  # The guard install.sh reads, set deliberately: this run is about the REPORT, and without it
  # it spawns a nested copy of this whole suite as its staging gate.
  ASTRALER_IN_SELFTEST=1 bash "$ROOT/install.sh" "$T4" >/dev/null 2>&1
  out="$(ASTRALER_IN_SELFTEST=1 bash "$ROOT/install.sh" "$T4" --apply 2>&1)"
  says "$out" "DELETED upstream" && says "$out" ".codex/profiles/builder.md" \
    && ok "a path an earlier release shipped and this one does not is reported as deleted upstream" \
    || bad "deleted-upstream report" "the retired file stays in the project and the receipt says clean"
  # --apply must EXIT 0 and stamp, not just print. 2.20.1 printed its whole summary and died
  # on the next line, before the stamp, and this suite passed it on the strings alone.
  if ASTRALER_IN_SELFTEST=1 bash "$ROOT/install.sh" "$T1" --apply >/dev/null 2>&1 \
      && grep -qx "$V" "$T1/.astraler/state/applied-version" 2>/dev/null; then
    ok "--apply exits 0 and stamps applied-version on a fresh target"
  else
    bad "apply exit" "--apply failed or did not stamp $V on a fresh target"
  fi
  # 4.1.0 — a project that names its tracker gets that tracker skill only; one that names none
  # gets all three. The RELEASE keeps all three (it is immutable and restaged byte-for-byte; the
  # 4.1.0 arm showed a selection made at staging breaking the restage once the project wrote its
  # tracker doc); the selection is made on the project's copy at --apply.
  T6="$TMP/t6"; rm -rf "$T6"; mkdir -p "$T6/docs/agents"
  ( cd "$T6" && git init -q && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init ) >/dev/null 2>&1
  printf '# Issue tracker: GitHub Issues\n' > "$T6/docs/agents/issue-tracker.md"
  ASTRALER_IN_SELFTEST=1 bash "$ROOT/install.sh" "$T6" --apply >/dev/null 2>&1
  proj6="$(ls -d "$T6"/.agents/skills/*-issue-tracker 2>/dev/null | wc -l | tr -d ' ')"
  rel6="$(ls -d "$T6"/.astraler/releases/*/harness/.agents/skills/*-issue-tracker 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$proj6" = "1" ] && [ -d "$T6/.agents/skills/github-issue-tracker" ] && [ -d "$T6/.claude/skills/github-issue-tracker" ] && [ "$rel6" = "3" ]; then
    ok "a target naming GitHub gets github-issue-tracker only in both trees, while the staged release keeps all three"
  else
    bad "tracker selection" "project tracker skills=$proj6 (want 1, github), release tracker skills=$rel6 (want 3)"
  fi
  proj1="$(ls -d "$T1"/.agents/skills/*-issue-tracker 2>/dev/null | wc -l | tr -d ' ')"
  [ "$proj1" = "3" ] && ok "a target with no issue-tracker.md gets all three tracker skills" \
    || bad "tracker selection default" "expected 3 tracker skills on a fresh target, found $proj1"
  # stage first, write the tracker doc, then --apply the SAME version: the restage must not refuse
  T7="$TMP/t7"; rm -rf "$T7"; mkdir -p "$T7"
  ( cd "$T7" && git init -q && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init ) >/dev/null 2>&1
  ASTRALER_IN_SELFTEST=1 bash "$ROOT/install.sh" "$T7" >/dev/null 2>&1
  mkdir -p "$T7/docs/agents"; printf '# Issue tracker: Linear\n' > "$T7/docs/agents/issue-tracker.md"
  if ASTRALER_IN_SELFTEST=1 bash "$ROOT/install.sh" "$T7" --apply >/dev/null 2>&1 && [ -d "$T7/.agents/skills/linear-issue-tracker" ] && [ ! -d "$T7/.agents/skills/github-issue-tracker" ]; then
    ok "staging before the tracker doc, then --apply after it, applies the same version with the named tracker only"
  else
    bad "tracker restage" "a tracker doc written between staging and --apply refused the apply or copied the wrong skills"
  fi
  # 3.3.0: the project's release view lands beside the stamp it reads, executable.
  if [ -x "$T1/.astraler/astragentic.sh" ] && [ "$(cd "$T1" && bash .astraler/astragentic.sh version)" = "$V" ]; then
    ok "--apply writes .astraler/astragentic.sh, and \`version\` reads the stamp"
  else
    bad "astragentic.sh on apply" "not written, not executable, or version != $V"
  fi
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
# A stack every worktree shares carries the working_dir of whichever Builder last started it
# (measured downstream 2026-10-13: the one test Postgres, read as this worktree's, drew the
# `down -v` advice that would have dropped every live Builder's database). Declared in
# `.astraler/project/shared-compose-projects`, it is left alone; undeclared, it still refuses.
printf 'stubproj-app\n' > "$DK/images"
printf '# shared stacks\nstub*\n' > "$R/.astraler/project/shared-compose-projects"
out="$( (cd "$R" && PATH="$DK:$PATH" bash "$S/release-worktree-resources.sh" "$R/wt" 2>&1); echo "rc=$?" )"
case "$out" in
  *"'stubproj'"*"declared shared"*"rc=0"*) ok "rwr leaves a declared shared stack alone and stamps" ;;
  *) bad "rwr shared stack" "$out" ;;
esac
printf 'otherstack\n' > "$R/.astraler/project/shared-compose-projects"
out="$( (cd "$R" && PATH="$DK:$PATH" bash "$S/release-worktree-resources.sh" "$R/wt" 2>&1); echo "rc=$?" )"
case "$out" in
  *"WARN compose project 'stubproj'"*"shared-compose-projects"*"rc=1"*) ok "planted: a stack the declaration does not name is still refused, and the refusal names the declaration" ;;
  *) bad "rwr shared stack planted" "$out" ;;
esac
rm -f "$R/.astraler/project/shared-compose-projects"


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
# ADAPT tells an MCP-only tracker project to print `unreachable -`; until 3.2.1 ticket-done read
# that as "not closed" and refused every ticket, so every base push on that project was blocked
# (measured on an adopting project, 2026-10-12). Unreachable stamps as UNVERIFIED, like no plug.
( cd "$TD" && git checkout -qb builder/ABC-15 && git commit -q --allow-empty -m "ABC-15 y" && git checkout -q main \
  && git merge -q --no-ff builder/ABC-15 -m "Merge ABC-15: y
Ledger: none" ) >/dev/null 2>&1
printf '#!/bin/sh\necho "unreachable -"\n' > "$TD/.astraler/project/tracker-state.sh"
if ( cd "$TD" && bash "$S/ticket-done.sh" ABC-15 --moved none ) >/dev/null 2>&1 \
   && grep -q "UNVERIFIED" "$HARNESS_STAMP_ROOT/harness-ticket-done/ABC-15" 2>/dev/null; then
  ok "ticket-done stamps an unreachable tracker as UNVERIFIED, as ADAPT promised"
else
  bad "ticket-done unreachable" "a plug printing 'unreachable -' (what ADAPT asks for) refused the ticket or left no UNVERIFIED stamp"
fi
printf '#!/bin/sh\necho "closed -"\n' > "$TD/.astraler/project/tracker-state.sh"
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
# WHERE THE STAMP LIVES, with no override, as in real use. It was /tmp, and a reboot emptied
# it: every finished ticket then read as unfinished to the push guard (measured downstream, 0
# stamps after a restart). The default is now the repository's git common dir. Both writer and
# reader must agree on it, or the guard refuses a push the stamp was written to allow.
( cd "$TD" && git checkout -q -b builder/ABC-14 main && git commit -q --allow-empty -m "ABC-14: z" \
  && git checkout -q main && git merge -q --no-ff builder/ABC-14 -m "Merge ABC-14: z
Ledger: none" ) >/dev/null 2>&1
( cd "$TD" && env -u HARNESS_STAMP_ROOT bash "$S/ticket-done.sh" ABC-14 --moved none ) >/dev/null 2>&1
if [ -f "$TD/.git/astraler-stamps/harness-ticket-done/ABC-14" ]; then
  ok "ticket-done stamps inside the git common dir by default"
else
  bad "ticket-done stamp home" "no stamp under .git/astraler-stamps — it would not survive a reboot"
fi
out="$(cd "$TD" && printf 'git push origin main' | python3 -c '
import sys, json
print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Bash","cwd":sys.argv[1],"tool_input":{"command":sys.stdin.read()}}))' "$TD" \
  | env -u HARNESS_STAMP_ROOT HARNESS_HOOK_LOG="$TMP/hook.log" python3 "$S/hook-git-guard.py" 2>/dev/null)"
case "$out" in *ABC-14*) bad "guard reads the default stamp home" "refused a push for ABC-14 whose stamp is in .git/astraler-stamps" ;;
               *) ok "the push guard reads stamps from the same default home" ;; esac

# THE PUSH GATE AS A GIT HOOK. hook-git-guard.py is silent on a heredoc, a $(...) or a ( ... )
# (26% of one day's commands downstream), and a ticket's merge reached origin/main unstamped
# inside a heredoc. pre-push-ticket-done.sh sees git's own refs. Refused unstamped, refused when
# the push sits in exactly the line shape the guard skips, allowed once stamped.
PR="$TMP/pp"; rm -rf "$PR"; mkdir -p "$PR"; git init -q --bare "$PR/remote.git"
( cd "$PR" && git init -q -b main work && cd work && git config user.email t@t && git config user.name t \
  && git commit -q --allow-empty -m init && git remote add origin "$PR/remote.git" && git push -q origin main \
  && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main \
  && mkdir -p hooks && printf '#!/bin/sh\nexec "%s" "$@"\n' "$S/pre-push-ticket-done.sh" > hooks/pre-push \
  && chmod +x hooks/pre-push && git config core.hooksPath hooks \
  && git checkout -qb builder/ABC-21 && git commit -q --allow-empty -m "ABC-21: x" \
  && git checkout -q main && git merge -q --no-ff builder/ABC-21 -m "Merge ABC-21: x" ) >/dev/null 2>&1
if ( cd "$PR/work" && HARNESS_STAMP_ROOT="$PR/stamps" git push -q origin main ) >/dev/null 2>&1; then
  bad "pre-push gate" "an unstamped ticket merge was pushed to the base branch"
else
  ok "pre-push refuses an unstamped ticket merge on the base branch"
fi
if ( cd "$PR/work" && X="$(git rev-parse HEAD)" && HARNESS_STAMP_ROOT="$PR/stamps" git push -q origin main ) >/dev/null 2>&1; then
  bad "pre-push gate, guard-blind shape" "a push behind a \$(...) went through, as it did past the guard"
else
  ok "pre-push refuses it in the line shape the guard cannot read"
fi
mkdir -p "$PR/stamps/harness-ticket-done"; : > "$PR/stamps/harness-ticket-done/ABC-21"
( cd "$PR/work" && HARNESS_STAMP_ROOT="$PR/stamps" git push -q origin main ) >/dev/null 2>&1 \
  && ok "pre-push admits the same push once the ticket is stamped" \
  || bad "pre-push stamped" "refused a push whose ticket carries its stamp"

# THE SAME EMPTY BRANCH, ON A HISTORY LONGER THAN A PIPE BUFFER. The check above lived as
# `git rev-list --first-parent | grep -qx` under pipefail: grep -q exits at the first line, and
# once rev-list has more than 64 KB to write it takes SIGPIPE, failing the pipeline and stamping
# the empty branch. Deterministic past ~1600 commits (the reviewer measured 10/10 on a 2392-
# commit project, 98 KB), invisible on the short fixture above — which is why it shipped.
TB="$TMP/td-big"; mkdir -p "$TB"
( cd "$TB" && git init -q -b main . && git config user.email t@t && git config user.name t \
  && { for i in $(seq 1 1800); do
         printf 'commit refs/heads/main\ncommitter t <t@t> %s +0000\ndata 3\nc%s\n' "$((1700000000+i))" "$((i % 10))"
         [ "$i" -gt 1 ] || true
       done; } | git fast-import --quiet \
  && git remote add origin "$TB" && git update-ref refs/remotes/origin/main main \
  && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main \
  && git checkout -q main && git branch builder/ABC-13 main ) >/dev/null 2>&1
mkdir -p "$TB/.astraler/project"
printf '#!/bin/sh\necho "closed -"\n' > "$TB/.astraler/project/tracker-state.sh"; chmod +x "$TB/.astraler/project/tracker-state.sh"
if [ "$(git -C "$TB" rev-list --count main 2>/dev/null)" -ge 1700 ]; then
  ( cd "$TB" && bash "$S/ticket-done.sh" ABC-13 --moved none ) >/dev/null 2>&1 \
    && bad "ticket-done empty branch, long history" "stamped an empty branch once rev-list outran the pipe buffer" \
    || ok "ticket-done refuses an empty branch on a history longer than a pipe buffer"
else
  bad "ticket-done long-history fixture" "fast-import did not build 1700+ commits"
fi

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
( cd "$LD" && git reset -q --hard HEAD~1 ) >/dev/null 2>&1
# 4.0.3 — a Builder's sync merge of the base into its branch is in the pushed range and owes no
# Ledger line; only first-parent merges onto the base are judged. Measured downstream: two
# pushes refused on such merges, ten minutes of history rewriting each.
LDN=$((LDN+1))
( cd "$LD" && git checkout -qb "builder/ABC-1-$LDN" && git commit -q --allow-empty -m "w1" \
  && git checkout -q main && git commit -q --allow-empty -m "base moved" \
  && git checkout -q "builder/ABC-1-$LDN" && git merge -q --no-ff main -m "sync main into ticket (no ledger line)" \
  && git checkout -q main && git merge -q --no-ff "builder/ABC-1-$LDN" -m "Merge ABC-1: with sync below

Ledger: none" ) >/dev/null 2>&1
guard_in "$LD" allow "git push origin main"            # the sync merge is second-parent history

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
# A RULE IS REGISTERED, OR IT IS INERT (2.7.13, 2.9.0).
#
# 2.7.13 is titled "the guard shipped for three runtimes and was registered on one". Claude is
# now the only role runtime, so what is left to pin is the half that still applies: every hook
# script the payload ships is named by .claude/settings.json, and the rules that outlive
# compaction are present in the Claude adapters. Both were watched to fail here before they
# were fixed.
# ---------------------------------------------------------------------------------------------
echo "one rule, registered where it is loaded"

# WHY THIS SECTION IS NO LONGER `pkg_only` (2.10.0). It was, and that was the same defect it
# exists to catch, one floor down. The payload is where these four files are AUTHORED; the
# adapted project is where they are actually LOADED, and it is the only place they can drift.
# The check that proves a rule reached the runtime must run where the runtime is.
PAY="$ROOT/harness"; [ "$LAYOUT" = project ] && PAY="$ROOT"
for role in thomas shaper builder qa ba quick; do
  cla="$PAY/.claude/agents/$role.md"
  # A project may not run all four roles, and a surface that does not exist there is not a
  # drifted surface. Absent files are reported as scope, never as a failure.
  present=0; miss=""
  [ -f "$cla" ] && present=1
  if [ "$present" -eq 0 ]; then
    SKIPPED=$((SKIPPED+1)); echo "  skip compaction rules: $role — no Claude adapter here"
    continue
  fi
  [ ! -f "$cla" ] || grep -qi 'survives compaction' "$cla" || miss="$miss claude"
  [ -z "$miss" ] && ok "compaction rules present in the Claude adapter: $role" \
                 || bad "compaction rules missing for $role" "absent on:$miss"
done

# Every hook script the payload ships must be named by the runtime's hook registration
# (.claude/settings.json). A script that ships and is registered nowhere is inert.
for hk in hook-git-guard.py hook-contract-reload.py hook-tracker-status.py; do
  inc=$(grep -c "$hk" "$PAY/.claude/settings.json" 2>/dev/null || echo 0)
  if [ "$inc" -gt 0 ]; then ok "registered in .claude/settings.json: $hk"
  else bad "$hk not registered" "shipped but named nowhere in .claude/settings.json — the hook is inert"; fi
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
# check-reachability checks 9 and 10 (2.10.0) — from the audit in AST-140/141. Check 11 (a rule
# follows its role's runtime) retired in 4.0.0 with the second runtime it watched for.
# Each is driven through a FIXTURE built to trip it, because a check that has only ever been run
# against a clean tree has been watched to stay quiet and never watched to fire.
# ---------------------------------------------------------------------------------------------
if pkg_only "reachability 9/10 fixtures"; then
echo "reachability — mention is not invocation, an assertion is about now"

RX="$TMP/rx"; rm -rf "$RX"; mkdir -p "$RX"
cp -R "$ROOT/harness" "$RX/harness"; mkdir -p "$RX/prompts"
# A staged release FLATTENS prompts/ to its root, and this suite runs there too (install.sh
# stages, then runs the staged copy of itself). Take the file from whichever layout we are in,
# or the fixture is missing a surface every check below scans and the baseline case fails for
# a reason that has nothing to do with what is being tested.
cp "$ROOT/prompts/ADAPT-HARNESS.md" "$RX/prompts/" 2>/dev/null \
  || cp "$ROOT/ADAPT-HARNESS.md" "$RX/prompts/" 2>/dev/null
cp "$ROOT/README.md" "$ROOT/install.sh" "$ROOT/check-requirements.sh" "$RX/" 2>/dev/null

# CAPTURE, NEVER PIPE. This file runs under `set -o pipefail` and check-reachability.py exits 1
# when it has findings, so `rx | grep -q "the finding"` returns 1 — the pipeline inherits the
# tool's failure — and the case reads a CORRECT detection as a miss. The mirror is worse: the
# `goes quiet` cases were passing because grep found nothing on a clean tree, which is also what
# they would do if the tool were broken and printed nothing at all. Both halves were measured
# here on 2026-09-16 before this comment existed.
rx()  { python3 "$S/check-reachability.py" "$RX" 2>&1; }

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
# was the payload set inside check-reachability.py, so the project redid that edit on every
# upgrade and the error text told it to. Watched here both ways: red without the plug, green
# with it — the second half matters more, because an allowance that does not actually allow is
# how a gate stays permanently red and stops being read.
VOC="$TMP/rxvoc"; rm -rf "$VOC"; cp -R "$RX" "$VOC"
python3 - "$VOC" <<'EOS'
import sys, os
p = os.path.join(sys.argv[1], "harness", ".agents", "roles", "thomas.md")
open(p, "a").write("\n\nA container this project runs: `some-project-stage-server`.\n")
EOS
out="$(python3 "$S/check-reachability.py" "$VOC" 2>&1)"
says "$out" "names 'some-project-stage-server'" \
  && ok "check 4 flags a skill-shaped token it does not know" \
  || bad "check 4 vocabulary" "an unknown skill-shaped token passed unreported"
mkdir -p "$VOC/.astraler/project"
printf '# this project'"'"'s own words\nsome-project-stage-server\n' > "$VOC/.astraler/project/not-a-skill.txt"
out="$(python3 "$S/check-reachability.py" "$VOC" 2>&1)"
says "$out" "names 'some-project-stage-server'" \
  && bad "check 4 project vocabulary" "the plug was declared and the token is still reported" \
  || ok "check 4 accepts .astraler/project/not-a-skill.txt"

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
  # A plug present without its exec bit raised inside the watchdog and read as IN FLIGHT on
  # every poll: STUCK muted for good, by a forgotten chmod (found supervising an adoption).
  printf '#!/bin/sh\nexit 0\n' > "$W/proj/.astraler/project/work-in-flight.sh"; chmod -x "$W/proj/.astraler/project/work-in-flight.sh"
  out="$(wd_polls working idle idle)"
  case "$out" in *STUCK*) ok "a non-executable work-in-flight plug does not mute STUCK" ;;
                 *) bad "work-in-flight plug, not executable" "STUCK went quiet behind a plug that cannot run: '$out'" ;; esac
  rm -f "$W/proj/.astraler/project/work-in-flight.sh"
  # A working pane with no watcher is WATCHER_LOST, unless the dispatch mod recorded it: since
  # 2.14 a Claude pane reports itself and runs no watcher, and the first live dispatch drew a
  # false WATCHER_LOST every time (fixed in 2.15.9). Both directions, or the case cannot fail.
  out="$(wd_polls working)"
  case "$out" in *WATCHER_LOST*) ok "a working pane with no watcher and no record is WATCHER_LOST" ;;
                 *) bad "WATCHER_LOST baseline" "a watcherless working pane went unreported: '$out'" ;; esac
  mkdir -p "$W/proj/.astraler/state"
  printf '{"ABC-9":{"role":"builder","pane_id":"w1:b","tab_id":"w1:tb","session_id":"s-1"}}' > "$W/proj/.astraler/state/dispatch-record.json"
  out="$(wd_polls working)"
  case "$out" in *WATCHER_LOST*) bad "self-reporting pane" "a pane the mod recorded drew WATCHER_LOST: '$out'" ;;
                 *) ok "a pane the dispatch mod recorded is not WATCHER_LOST" ;; esac
  # A recorded pane that worked and stopped is one that reported its turn end through the mod;
  # 26 STUCK alerts through one night said otherwise (nizzy-ecom, 2026-10-12). Nothing fires on
  # a self-reporting pane. The baseline above (no record → STUCK) keeps this case honest.
  out="$(wd_polls working idle idle)"
  case "$out" in *STUCK*|*NEVER_STARTED*|*BLOCKED*) bad "self-reporting pane, stopped" "a pane the mod recorded drew an alert after it reported: '$out'" ;;
                 *) ok "a pane the dispatch mod recorded draws no STUCK, NEVER_STARTED or BLOCKED" ;; esac
  rm -f "$W/proj/.astraler/state/dispatch-record.json"
fi

# ---------------------------------------------------------------------------------------------
# AN ALERT FIRES ON THE EDGE (3.2.0). The whole script runs here against a stubbed `herdr` that
# always answers the same stalled Builder, with no cooldown, for a few polls: once fires once.
# The 3.1.1 loop fires on every poll a condition holds (the overnight 26), so the case fails on it.
# ---------------------------------------------------------------------------------------------
echo "watchdog — one alert per episode, not one per poll"
E="$TMP/wd-edge"; mkdir -p "$E/bin" "$E/repo/.agents"
( cd "$E/repo" && git init -q . && printf '| workspace-label | `wdedge` |\n' > .agents/orchestrator.md )
cat > "$E/bin/herdr" <<'EOS'
#!/bin/sh
case "$1 $2" in
  "agent list") echo '{"result":{"agents":[{"pane_id":"w9:t","name":"thomas","agent_status":"done","workspace_id":"w9"},{"pane_id":"w9:b","name":"builder-e","agent_status":"idle","workspace_id":"w9"}]}}' ;;
  "workspace list") echo '{"result":{"workspaces":[{"label":"wdedge","workspace_id":"w9"}]}}' ;;
  "agent prompt") echo "PROMPTED $3" >> "$E_LOG"; exit 0 ;;
  *) echo '{"result":{}}' ;;
esac
EOS
printf '#!/bin/sh\nexit 1\n' > "$E/bin/pgrep"; printf '#!/bin/sh\nexit 0\n' > "$E/bin/caffeinate"
chmod +x "$E/bin/"*
rm -f /tmp/herdr-watchdog-wdedge.lock; rm -rf /tmp/herdr-watchdog-wdedge.state /tmp/herdr-watchdog-wdedge.log
export E_LOG="$E/prompts.log"; : > "$E_LOG"
# Started as a plain child and ended by its own PID: the script's `stop` signals a process
# group, and under a test runner that group can be the runner's (measured: the first draft of
# this case stopped the selftest). TERM lands on its `trap 'exit 0'`.
( cd "$E/repo" && PATH="$E/bin:$PATH" exec bash "$WD" 1 0 50 ) >/dev/null 2>&1 &
wdpid=$!
sleep 9
kill -TERM "$wdpid" 2>/dev/null; sleep 1; kill -KILL "$wdpid" 2>/dev/null; wait "$wdpid" 2>/dev/null || true
pkill -f "herdr-watchdog.sh 1 0 50" 2>/dev/null || true
rm -f /tmp/herdr-watchdog-wdedge.lock
n="$(grep -c '^PROMPTED' "$E_LOG" 2>/dev/null || true)"
# seen on first poll, idle on the second → STUCK or NEVER_STARTED fires on poll 2; polls 3..8 must not repeat it
if [ "${n:-0}" -eq 1 ]; then ok "a condition that holds across eight polls alerts once"
elif [ "${n:-0}" -eq 0 ]; then bad "edge alert baseline" "no alert fired at all in nine seconds (log: $(cat /tmp/herdr-watchdog-wdedge.log 2>/dev/null | tail -3))"
else bad "alert per poll" "the same condition alerted $n times in nine seconds — level-triggered again"; fi
unset E_LOG

# ---------------------------------------------------------------------------------------------
# The dispatch mod. On a Claude root it is the only thing that records a pane, delivers its
# brief and reports its turn end, so a mod that does not load leaves every Claude pane
# unwatched. Claude Code's own reader validates it the way the engine loads it, and a planted
# defect proves the reader names one: a check only ever seen passing has not been tested.
# ---------------------------------------------------------------------------------------------
echo "astragentic.sh update — installed vs latest, the gap's notes, the one-liner (3.3.0)"
# A local package with tags v0.0.9 and v0.0.10: the pair `sort` alone orders wrong, which is
# the planted shape below. The target has applied 0.0.9.
AX="$TMP/astra-update"; rm -rf "$AX"; mkdir -p "$AX/pkg" "$AX/proj/.astraler/state"
( cd "$AX/pkg" && git init -q && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m i
  for v in 0.0.9 0.0.10; do
    { printf '# Astragentic %s\n\n**Note for %s.**\n\n' "$v" "$v"; cat RELEASE-NOTES.md 2>/dev/null; } > RN.tmp; mv RN.tmp RELEASE-NOTES.md
    echo "$v" > VERSION; printf '#!/bin/sh\necho "get.sh stub: $*" > "%s/get-args"\necho "  new 2 · updated 1 · unchanged 0 · kept 0 · owner-kept 1 · conflicts 0 · deleted-upstream 1"\necho "DELETED upstream — an earlier release shipped these, $v does not, and they are"\necho "  .agents/roles/old-role.md"\necho "  (not removed automatically: a project may have adopted one of these on purpose)"\n' "$AX" > get.sh
    git add -A; git -c user.name=t -c user.email=t@t commit -q -m "$v"; git tag "v$v"
  done ) >/dev/null 2>&1
( cd "$AX/proj" && git init -q ) >/dev/null 2>&1
echo 0.0.9 > "$AX/proj/.astraler/state/applied-version"
# The script lives at the package root, or at `.astraler/astragentic.sh` once applied.
AU=""
for cand in "$(dirname "$S")/../astragentic.sh" "$ROOT/astragentic.sh" "$ROOT/.astraler/astragentic.sh"; do
  [ -f "$cand" ] && { AU="$cand"; break; }
done
if [ -z "$AU" ]; then
  SKIPPED=$((SKIPPED+1)); echo "  skip astragentic.sh — not at the package root nor at .astraler/ in this layout"
else
out="$( (cd "$AX/proj" && ASTRAGENTIC_REPO="$AX/pkg" bash "$AU" update 2>&1); echo "rc=$?" )"
if says "$out" "installed 0.0.9 · latest 0.0.10" && says "$out" "Note for 0.0.10." && ! says "$out" "Note for 0.0.9." \
   && says "$out" "bash -s -- 0.0.10 --apply" && says "$out" "rc=0"; then
  ok "update names installed and latest, prints only the gap's notes, and the one-liner pins latest"
else
  bad "astragentic.sh update" "$out"
fi
echo 0.0.10 > "$AX/proj/.astraler/state/applied-version"
out="$( (cd "$AX/proj" && ASTRAGENTIC_REPO="$AX/pkg" bash "$AU" update 2>&1); echo "rc=$?" )"
says "$out" "installed 0.0.10 — this is the latest release" && says "$out" "rc=0" \
  && ok "update on the latest release says so and prints no one-liner" \
  || bad "astragentic.sh current" "$out"
echo 0.0.9 > "$AX/proj/.astraler/state/applied-version"; rm -f "$AX/get-args"
echo "stale receipt" > "$AX/proj/.astraler/state/ADAPTATION-REPORT.md"
out="$( (cd "$AX/proj" && ASTRAGENTIC_REPO="$AX/pkg" bash "$AU" update --apply 2>&1); echo "rc=$?" )"
if [ -f "$AX/get-args" ] && says "$(cat "$AX/get-args")" "0.0.10 --apply"; then
  ok "update --apply hands latest and --apply to the package's own get.sh"
else
  bad "astragentic.sh --apply" "$out / $(cat "$AX/get-args" 2>/dev/null)"
fi
# 4.1.0 — the receipt lands by the script's hand, not an agent's: a project had none for three
# releases applied this way (field audit 2026-10-18). 4.1.1 — one home, .astraler/state/, and
# overwritten: 4.1.0 appended to a second file at the root while ADAPT §7 overwrote this one.
rpt="$(cat "$AX/proj/.astraler/state/ADAPTATION-REPORT.md" 2>/dev/null)"
if says "$rpt" "## 0.0.10 applied" && says "$rpt" "(from 0.0.9)" && says "$rpt" "- new 2 · updated 1" && says "$rpt" "  - .agents/roles/old-role.md" && ! says "$rpt" "stale receipt" && [ ! -f "$AX/proj/ADAPTATION-REPORT.md" ]; then
  ok "update --apply overwrites .astraler/state/ADAPTATION-REPORT.md with the receipt (version, from, counts, deleted-upstream), no root copy"
else
  bad "astragentic.sh receipt" "ADAPTATION-REPORT.md after --apply: ${rpt:-<absent>}"
fi
out="$( (cd "$AX/proj" && ASTRAGENTIC_REPO="$AX/nowhere" bash "$AU" update 2>&1); echo "rc=$?" )"
says "$out" "could not list release tags" && says "$out" "rc=1" \
  && ok "an unreachable package remote is said, exit 1" \
  || bad "astragentic.sh offline" "$out"
# planted: plain `sort` reads 0.0.9 as newest and reports the target up to date
sed 's/sort -t\. -k1,1n -k2,2n -k3,3n/sort/' "$AU" > "$AX/lexical.sh"
out="$( (cd "$AX/proj" && ASTRAGENTIC_REPO="$AX/pkg" bash "$AX/lexical.sh" update 2>&1); echo "rc=$?" )"
says "$out" "latest 0.0.10" \
  && bad "astragentic.sh planted sort" "a lexical sort still found 0.0.10 — this case cannot fail" \
  || ok "planted: a lexical version sort misses 0.0.10, and the case says so"
fi

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
echo "dispatch mod — a brief sent to \"name [ref]\" is cleared by the ack from \"name\""
# The driver transpiles register.tsx with the engine's own TypeScript and replays the hooks with
# a stub engine: a brief to the address SendMessage demands when names share a prefix, then the
# RECEIVED ack, whose envelope carries the bare name. Measured downstream (2026-10-13): the chip
# "not confirmed received" never cleared on 6 of 6 lanes, and outlived three retired lanes.
TSC_PKG=""
for cand in "$(npm root -g 2>/dev/null)/skillkit/node_modules/typescript" "$(npm root -g 2>/dev/null)/typescript"; do
  [ -f "$cand/package.json" ] && { TSC_PKG="$cand"; break; }
done
if ! have node || [ -z "$TSC_PKG" ] || [ ! -d "$MOD" ]; then
  SKIPPED=$((SKIPPED+1)); echo "  skip mod driver — needs node and a typescript package under npm root -g"
else
  cat > "$TMP/mod-drive.cjs" <<'DRVEOS'
// Drives the dispatch mod under node: transpiles register.tsx, stubs the engine, and replays
// a brief sent to a "name [ref]" address followed by its RECEIVED ack from the bare name.
const fs = require('fs'), path = require('path'), Module = require('module')
const [,, modDir, root, tsPath, mode] = process.argv
const isPane = mode === 'pane'
const ts = require(tsPath)
const src = fs.readFileSync(path.join(modDir, 'hooks/register.tsx'), 'utf8')
const js = ts.transpileModule(src, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022, jsx: ts.JsxEmit.React, jsxFactory: 'h', jsxFragmentFactory: 'Fragment' } }).outputText
const state = new Map()
const engine = {
  atom: (id, init) => ({ id: `${id.plugin}.${id.key}`, init }),
  read: async (_$, a) => state.has(a.id) ? state.get(a.id) : a.init,
  update: async (_$, a, f) => { state.set(a.id, f(state.has(a.id) ? state.get(a.id) : a.init)) },
}
const origLoad = Module._load
Module._load = function (req, ...rest) { return req === 'claude-code' ? engine : origLoad.call(this, req, ...rest) }
globalThis.h = (type, props, ...children) => typeof type === 'function' ? type({ ...(props ?? {}), children }) : ({ type, props: props ?? {}, children })
globalThis.Fragment = 'Fragment'
const m = new Module(path.join(modDir, 'hooks/register.cjs')); m.filename = m.id; m.paths = []
m._compile(js, m.filename)
const hooks = {}
m.exports.register((name, a, b) => { const fn = typeof a === 'function' ? a : b; const sel = typeof a === 'function' ? null : a; (hooks[name] ??= []).push({ fn, sel }) })
const log = []
let liveAgents = []
let tick = 0
let everyFn = async () => {}
const every = () => everyFn()
const $ = {
  env: { get: async k => k === 'ASTRAGENTIC_REPO' ? root : (isPane && k === 'HERDR_TAB_ID') ? 't5' : (isPane && k === 'HERDR_PANE_ID') ? 'p5' : undefined },
  clock: { now: async () => { tick = Math.max(tick + 1, Date.now()); return tick }, every: (_ms, fn) => { everyFn = fn } },
  command: { register: () => {}, run: async () => ({}) },
  session: { id: async () => 'disp', send: async () => ({ isDelivered: true }), usage: async () => ({ startedAt: 0, context: { tokens: 1000, window: 1_000_000, percent: 0 } }), compact: async () => ({}) },
  fs: { read: async p => fs.readFileSync(p, 'utf8'), write: async (p, t) => fs.writeFileSync(p, t), exists: async p => fs.existsSync(p) },
  process: { run: async (argv, o = {}) => { if (argv[0] === 'herdr') return { exitCode: 0, stdout: argv[1] === 'tab' ? '{"result":{"tab":{"label":"ticket:AB-5"}}}' : '{}', stderr: '' }; const r = require('child_process').spawnSync(argv[0], argv.slice(1), { cwd: o.cwd ?? root, encoding: 'utf8', env: { ...process.env, ...(o.env ?? {}) } }); return { exitCode: r.status ?? 1, stdout: r.stdout ?? '', stderr: r.stderr ?? '' } } },
  ui: { status: t => log.push(t), toast: () => {}, open: () => {}, resolve: () => ({ Box: 'Box', Text: 'Text' }) },
  prompt: { submit: async () => {} },
  agent: { list: async () => liveAgents },
}
const fire = async (name, e, next) => {
  const list = (hooks[name] ?? []).filter(({ sel }) => !(sel && Object.entries(sel).some(([k, v]) => e?.[k] !== v)))
  if (name === 'tool.call') {  // the engine chains tool.call hooks: each one's `next` is the one after it
    let i = -1
    const call = async ev => { i++; if (i >= list.length) return (next ?? (x => x))(ev); return list[i].fn($, ev, call) }
    return call(e)
  }
  for (const { fn } of list) { const r = await fn($, e, next ?? (x => x)); if (r !== undefined && name !== 'session.start') return r }
}
const rows = async () => (await engine.read($, { id: 'astragentic-dispatch.board', init: [] })).map(r => `${r.key}:${r.state}:${r.note ?? ''}`).join(' ')
// the band above the prompt, as the text of its chips in order
const leaves = n => n == null || n === false ? [] : Array.isArray(n) ? n.flatMap(leaves) : typeof n === 'object' ? leaves(n.children) : [String(n)]
const band = async () => leaves(await fire('ui.render', { component: 'AbovePrompt', props: {} }, async () => null)).join('').replace(/\s+/g, ' ').trim()
;(async () => {
  if (isPane) {
    // the dispatched side: a turn end with a live agent is held; the next turn start ends the hold
    await fire('session.start', { cwd: root }, async () => ({}))
    const rec = () => JSON.parse(fs.readFileSync(path.join(root, '.astraler/state/dispatch-record.json'), 'utf8'))
    const registered = rec()['AB-5']?.pane_id === 'p5'
    liveAgents = [{ id: 'a1', status: 'running', description: 'Standards axis code review' }]
    await fire('turn.complete', { reason: 'answer', answer: 'working', turnId: 't1' }, async () => ({}))
    const paneHeld = rec()['AB-5']?.waiting_on?.n === 1
    liveAgents = []
    await fire('turn.start', { text: '', turnId: 't2' }, async () => ({}))
    await new Promise(r => setTimeout(r, 300))
    const paneCleared = rec()['AB-5']?.waiting_on === null && log[log.length - 1] === undefined
    // the arm row: `ticket: no` in orchestrator.md reaches the Builder as a system-prompt section
    const composed = await fire('prompt.compose', {}, async () => ({ sections: [] }))
    const armOffSection = (composed?.sections ?? []).some(s => String(s.text).includes('ARM: off'))
    // 4.1.0 — the tdd gate asks git for a test file, not the record for a skill call
    const cmdOf = async (command) => { let ran = false; const r = await fire('tool.call', { tool: 'Bash', command }, async () => { ran = true; return {} }); return `${r?.deny ? 'deny' : 'pass'}:${ran ? 'ran' : 'held'}` }
    const git = (...a) => require('child_process').spawnSync('git', a, { cwd: root, encoding: 'utf8' })
    fs.writeFileSync(path.join(root, 'app.js'), 'x'); git('add', 'app.js')
    const commitNoTest = await cmdOf('git commit -m "feat: thing"')
    fs.writeFileSync(path.join(root, 'app.test.js'), 'x'); git('add', 'app.test.js')
    const commitWithTest = await cmdOf('git commit -m "feat: thing with its test"')
    git('reset', '-q'); fs.unlinkSync(path.join(root, 'app.js')); fs.unlinkSync(path.join(root, 'app.test.js'))
    // a DELETED test beside a production change is not a test (arm pass 2)
    fs.writeFileSync(path.join(root, 'old.test.js'), 'x'); git('add', 'old.test.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'old test')
    // the test predates the dispatch: move the record's start_sha to this head
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'app.js'), 'y'); git('add', 'app.js'); git('rm', '-q', 'old.test.js')
    const commitDeletedTest = await cmdOf('git commit -m "feat: thing, test deleted"')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js', 'old.test.js')
    // a test committed AFTER dispatch, then staged for deletion beside the production change (arm pass 3)
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'new.test.js'), 'x'); git('add', 'new.test.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'new test after dispatch')
    fs.writeFileSync(path.join(root, 'app.js'), 'z'); git('add', 'app.js'); git('rm', '-q', 'new.test.js')
    const commitLaterDeletedTest = await cmdOf('git commit -m "feat: thing, later test deleted"')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js')
    // arm pass 4: the tree the call commits, not the index at the check
    // (a) path-limited commit: the staged test is left out of the commit (the branch carries no
    // test since this base — the previous case's new.test.js is before it)
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'app.js'), 'p'); fs.writeFileSync(path.join(root, 'p.test.js'), 'x'); git('add', 'app.js', 'p.test.js')
    const commitPathLimited = await cmdOf('git commit -m "feat" -- app.js')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js', 'p.test.js')
    // (b) -a with a test committed after dispatch and deleted in the working tree, unstaged
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'q.test.js'), 'x'); git('add', 'q.test.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'q test')
    fs.writeFileSync(path.join(root, 'app.js'), 'q'); git('add', 'app.js'); fs.unlinkSync(path.join(root, 'q.test.js'))
    const commitAllDeleted = await cmdOf('git commit -am "feat"')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js')
    // (c) add + commit in one call, the test only in the working tree: the add stages it, so it passes
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'app.js'), 'r'); fs.writeFileSync(path.join(root, 'r.test.js'), 'x')
    const commitAddThenCommit = await cmdOf('git add app.js r.test.js && git commit -m "feat"')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js', 'r.test.js')
    // (d) rm of the only test + commit in one call: refused
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 's.test.js'), 'x'); git('add', 's.test.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 's test')
    fs.writeFileSync(path.join(root, 'app.js'), 's'); git('add', 'app.js')
    const commitRmThenCommit = await cmdOf('git rm -q s.test.js && git commit -m "feat"')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js')
    // arm pass 5: (e) a changed test in the index whose working copy is deleted, re-added in the call
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'e.test.js'), 'x'); git('add', 'e.test.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'e test')
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'e.test.js'), 'changed'); git('add', 'e.test.js'); fs.unlinkSync(path.join(root, 'e.test.js'))
    fs.writeFileSync(path.join(root, 'app.js'), 'e')
    const commitRestageDeleted = await cmdOf('git add e.test.js app.js && git commit -m fix')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js')
    // (f) -mchange is a message, not -a: an unstaged tracked test change is not committed
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'e.test.js'), 'unstaged change'); fs.writeFileSync(path.join(root, 'app.js'), 'f'); git('add', 'app.js')
    const commitDashMAttached = await cmdOf('git commit -mchange')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js')
    // (g) add -A scoped to a directory: an untracked test elsewhere does not count
    fs.mkdirSync(path.join(root, 'src'), { recursive: true }); fs.mkdirSync(path.join(root, 'tests'), { recursive: true })
    fs.writeFileSync(path.join(root, 'src/app.js'), 'g'); fs.writeFileSync(path.join(root, 'tests/unrelated.test.js'), 'x')
    const commitScopedAddAll = await cmdOf('git add -A src && git commit -m fix')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'src', 'tests')
    // (h) a path-limited commit whose ./-prefixed path is a test restored to the base
    fs.writeFileSync(path.join(root, 'h.test.js'), 'base'); git('add', 'h.test.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'h base')
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'h.test.js'), 'changed'); git('add', 'h.test.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'h changed')
    fs.writeFileSync(path.join(root, 'h.test.js'), 'base'); fs.writeFileSync(path.join(root, 'app.js'), 'h')
    const commitPathRestored = await cmdOf('git commit -m fix -- ./h.test.js app.js')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js')
    // arm pass 6: (i) a `git mv` before the commit is refused and NOT replayed: the file stays put
    fs.writeFileSync(path.join(root, 'i.test.js'), 'x'); fs.writeFileSync(path.join(root, 'app.js'), 'i'); git('add', 'i.test.js', 'app.js')
    const commitAfterMv = await cmdOf('git mv app.js app2.js && git commit -m fix')
    const mvNotReplayed = fs.existsSync(path.join(root, 'app.js')) && !fs.existsSync(path.join(root, 'app2.js'))
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js', 'app2.js', 'i.test.js')
    // (j) two content commits in one call are refused
    fs.writeFileSync(path.join(root, 'j.test.js'), 'x'); fs.writeFileSync(path.join(root, 'app.js'), 'j'); git('add', 'j.test.js', 'app.js')
    const commitTwice = await cmdOf('git commit -m first && git rm -q j.test.js && git commit -m second')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js', 'j.test.js')
    // (k) -C src with a path-limited commit: the src test is unchanged from base, the root test is not committed
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.mkdirSync(path.join(root, 'src'), { recursive: true })
    fs.writeFileSync(path.join(root, 'src/app.test.js'), 'base'); git('add', 'src/app.test.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'src test base')
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'app.test.js'), 'root changed'); fs.writeFileSync(path.join(root, 'src/app.js'), 'k'); git('add', 'app.test.js', 'src/app.js')
    const commitDashCSrc = await cmdOf('git -C src commit -m fix -- app.js app.test.js')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.test.js', 'src')
    // (l) --amend --only with no paths: HEAD's tree, the staged test ignored
    fs.writeFileSync(path.join(root, 'app.js'), 'l0'); git('add', 'app.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'l base')
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'app.js'), 'l1'); git('add', 'app.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'l prod')
    fs.writeFileSync(path.join(root, 'l.test.js'), 'x'); git('add', 'l.test.js')
    const commitAmendOnly = await cmdOf('git commit --amend --only -m fix')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js', 'l.test.js')
    // arm pass 7: (m) a working-tree `git rm` then `add -A` cannot be replayed: refused, file untouched
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'm.test.js'), 'x'); git('add', 'm.test.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'm test')
    fs.writeFileSync(path.join(root, 'app.js'), 'm')
    const commitRmAddAll = await cmdOf('git rm m.test.js && git add -A && git commit -m fix')
    const rmNotReplayed = fs.existsSync(path.join(root, 'm.test.js'))
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js')
    // (n) --pathspec-from-file names paths the gate cannot read: refused
    fs.writeFileSync(path.join(root, 'app.js'), 'n'); fs.writeFileSync(path.join(root, 'n.test.js'), 'x'); git('add', 'app.js', 'n.test.js'); fs.writeFileSync(path.join(root, 'paths.txt'), 'app.js\n')
    const commitPathspecFile = await cmdOf('git commit --pathspec-from-file=paths.txt -m fix')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.js', 'n.test.js', 'paths.txt')
    // (o) cd elsewhere, then repeated -C back into the worktree: judged, not bypassed
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.mkdirSync(path.join(root, 'src'), { recursive: true }); fs.writeFileSync(path.join(root, 'src/app.js'), 'o'); git('add', 'src/app.js')
    const commitRepeatedC = await cmdOf(`cd /tmp && git -C ${root} -C src commit -m fix -- app.js`)
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'src')
    // arm pass 8: (q) a path-limited commit does not commit an untracked test under the path
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'app.js'), 'q0'); git('add', 'app.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'q base')
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'app.js'), 'q1'); fs.writeFileSync(path.join(root, 'pending.test.js'), 'x')
    const commitDotUntracked = await cmdOf('git commit -m fix -- .')
    // (s) …but a STAGED-new test under the path is committed, so it counts
    git('add', 'pending.test.js')
    const commitDotStaged = await cmdOf('git commit -m fix -- .')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'pending.test.js')
    // (r) a staging step behind shell control flow is refused, not replayed
    fs.writeFileSync(path.join(root, 'app.js'), 'r1'); git('add', 'app.js'); fs.writeFileSync(path.join(root, 'pending.test.js'), 'x')
    const commitSkippedAdd = await cmdOf('false && git add pending.test.js; git commit -m fix')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'pending.test.js')
    // arm pass 9: (t) a negated --cached is refused and the working file survives
    fs.writeFileSync(path.join(root, 'app.js'), 't1'); git('add', 'app.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 't base')
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'app.js'), 't2 uncommitted')
    const commitRmNoCached = await cmdOf('git rm --cached --no-cached -f app.js; git commit -m fix')
    const fileSurvived = fs.existsSync(path.join(root, 'app.js')) && fs.readFileSync(path.join(root, 'app.js'), 'utf8') === 't2 uncommitted'
    git('reset', '-q', '--hard')
    // (u) a staging step behind || or inside another command's arguments is not a staging step
    fs.writeFileSync(path.join(root, 'app.js'), 'u'); git('add', 'app.js'); fs.writeFileSync(path.join(root, 'pending.test.js'), 'x')
    const commitOrAdd = await cmdOf('git status || git add pending.test.js; git commit -m fix')
    const commitEchoAdd = await cmdOf('echo git add pending.test.js; git commit -m fix')
    // (v) a removal of a path git does not know fails, so the add after && never runs
    const commitRmAbsent = await cmdOf('git rm --cached absent.js && git add pending.test.js; git commit -m fix')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'pending.test.js')
    // arm pass 10: (w) a substitution inside the message runs before the commit: refused, test stays staged
    fs.writeFileSync(path.join(root, 'app.js'), 'w'); fs.writeFileSync(path.join(root, 'pending.test.js'), 'x'); git('add', 'app.js', 'pending.test.js')
    const commitSubstQuoted = await cmdOf('git commit -m "fix $(git reset -q HEAD -- pending.test.js)"')
    const testStillStaged = git('diff', '--cached', '--name-only').stdout.includes('pending.test.js')
    // (x) a global git option other than -C points at a tree the replay does not model: refused
    const commitWorkTree = await cmdOf(`git --work-tree=${root}/src add -A && git commit -m fix`)
    const commitConfigOpt = await cmdOf('git -c core.quotepath=off commit -a -m fix')
    // arm pass 11: (y) apostrophes inside double quotes do not hide a substitution; a backtick
    // in double quotes runs too; a single-quoted one is text and is NOT refused
    const commitSubstApos = await cmdOf(`git commit -m "'$(git reset -q HEAD -- pending.test.js)'"`)
    const commitBacktickDouble = await cmdOf('git commit -m "fix `git reset -q HEAD -- pending.test.js`"')
    const commitSubstLiteral = await cmdOf("git commit -m 'see $(ref) and `x`'")
    // (z) a separate-valued global option must not hide the commit from the reader
    const commitConfigEnv = await cmdOf('git --config-env core.foo=PATH commit -a -m fix')
    // arm pass 12: (aa) a staging step behind `#` never runs, so it is not a step; (ab) an
    // abbreviated long option (`--pathspec-from`) is refused, a full one in a value form passes
    git('reset', '-q', 'HEAD', '--', 'pending.test.js')
    const commitCommentedAdd = await cmdOf('git status # ignored; git add pending.test.js\ngit commit -m fix')
    git('add', 'pending.test.js'); fs.writeFileSync(path.join(root, 'paths.txt'), 'app.js\n')
    const commitAbbrevOpt = await cmdOf('git commit --pathspec-from=paths.txt -m fix')
    const commitMessageEq = await cmdOf('git commit --message=fix --no-verify')
    // arm pass 13: (ac) a redirection before the commit restores the test on disk after the
    // judgment reads it: refused
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'pending.test.js', 'paths.txt')
    fs.writeFileSync(path.join(root, 'app.js'), 'ac0'); fs.writeFileSync(path.join(root, 'app.test.js'), 'ac0'); git('add', 'app.js', 'app.test.js'); git('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'ac base')
    { const r = rec(); r['AB-5'].start_sha = git('rev-parse', 'HEAD').stdout.trim(); fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    fs.writeFileSync(path.join(root, 'app.js'), 'ac1'); fs.writeFileSync(path.join(root, 'app.test.js'), 'ac1')
    const commitRedirect = await cmdOf('git show HEAD:app.test.js > app.test.js; git commit -am fix')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'app.test.js')
    // a descriptor duplication (`2>&1`) is not a step: the commit is judged and passes; `&>` to a
    // file is one redirection, named as such (nizzy, 2026-10-20: "git a step behind `&`")
    fs.writeFileSync(path.join(root, 'app.js'), 'fd'); fs.writeFileSync(path.join(root, 'app.test.js'), 'fd'); git('add', 'app.js', 'app.test.js')
    const commitFdDup = await cmdOf('git commit -m fix 2>&1')
    const ampRefusal = String((await fire('tool.call', { tool: 'Bash', command: 'git commit -m fix &> log.txt' }, async () => ({})))?.deny ?? '')
    const ampNamed = ampRefusal.includes('a redirection to or from a file') && !ampRefusal.includes('git a ')
    // Claude Code's own commit recipe, `-m "$(cat <<'EOF' … EOF)"`, is a literal message and is
    // judged (nizzy, 2026-10-21: refused on both fresh Builders' first commit); an unquoted
    // delimiter, a second command inside, or an unquoted substitution is still refused, and the
    // refusal names `-F <file>`
    const commitHeredocMsg = await cmdOf(`git commit -m "$(cat <<'EOF'\nfix: don't "break" (x)\n\nCo-Authored-By: t <t@t>\nEOF\n)"`)
    const commitHeredocOpen = await cmdOf('git commit -m "$(cat <<EOF\n$(git reset -q HEAD -- app.test.js)\nEOF\n)"')
    const commitHeredocExtra = await cmdOf(`git commit -m "$(cat <<'EOF'\nfix\nEOF\ngit reset -q HEAD -- app.test.js\n)"`)
    const commitHeredocBare = await cmdOf(`git commit -m $(cat <<'EOF'\n-a\nEOF\n)`)
    const substRefusal = String((await fire('tool.call', { tool: 'Bash', command: 'git commit -m "$(git log -1 --format=%s)"' }, async () => ({})))?.deny ?? '')
    const substFixNamed = substRefusal.includes('git commit -F <file>')
    git('reset', '-q', '--hard')
    git('reset', '-q', '--hard'); git('clean', '-fdq', '--', 'pending.test.js', 'paths.txt')
    const noScratchLeft = !fs.readdirSync(root).some(n => n.startsWith('.git-tdd-gate'))
    // the project's refused-in-dispatched-panes list: a listed command is refused in this pane
    fs.mkdirSync(path.join(root, '.astraler/project'), { recursive: true })
    fs.writeFileSync(path.join(root, '.astraler/project/refused-in-dispatched-panes'), '# shared test database\n\\bmake\\s+db-down\n\n# a plain comment is not a reason\n# reason: the station runs the whole suite; run only your touched packages\n\\bmake\\s+itest-local\\b\n\\bgo\\s+test\\s+\\./\\.\\.\\.\n')
    const refusedListed = await cmdOf('cd apps/server && make db-down')
    const refusedOther = await cmdOf('cd apps/server && make db-up')
    // a `# reason:` line directly above a pattern is the refusal's text; db-down's plain comment is
    // not, and a pattern with none keeps the default (one downstream ask, 2026-10-22: a listed whole-suite run was told "the owner runs it")
    const denyOf = async (command) => String((await fire('tool.call', { tool: 'Bash', command }, async () => ({})))?.deny ?? '')
    const whyItest = await denyOf('make itest-local')
    const whyGo = await denyOf('go test ./...')
    const whyDb = await denyOf('make db-down')
    const refusedWhy = !whyDb.includes('shared test database') && whyItest.includes('the station runs the whole suite') && !whyItest.includes('the owner runs it')
      && whyGo.includes('the owner runs it') && !whyGo.includes('the station runs')
    // the context ceiling: a turn that ends over it is compacted at the next tick, between turns
    let compacted = 0
    $.session.usage = async () => ({ startedAt: 0, context: { tokens: 350_000, window: 1_000_000, percent: 35 } })
    $.session.compact = async () => { compacted++; return {} }
    await fire('turn.complete', { reason: 'answer', answer: 'done', turnId: 't3' }, async () => ({}))
    await every()
    // 4.3.1 — a send to the pane's OWN fork ("code-review [ce2df1]") is not readdressed to the
    // dispatcher; a send to a role name still is (one downstream ticket, 2026-10-22)
    await fire('session.receive', { text: '<cross-session-message from="uds:/tmp/d.sock" from-name="disp-07">\n/mattpocock-skills:implement AB-5\nQA: none — no surface\n</cross-session-message>', origin: { kind: 'plugin' } }, async () => ({}))
    liveAgents = [{ id: 'a-7f3-ce2df1', name: 'code-review', status: 'running', description: 'Review the changes' }]
    const sendTo = async (to) => { let seen = null; await fire('session.send', { to, text: 'Report your final findings summary now.', origin: { kind: 'model' } }, async ev => { seen = ev.to; return { isDelivered: true } }); return seen }
    const sendToFork = await sendTo('code-review [ce2df1]')
    const sendToForkById = await sendTo('a-7f3-ce2df1')
    const sendToRole = await sendTo('thomas')
    liveAgents = []
    // 4.3.2 — the band: the step invoked most recently is "…" (running, with the pane's live agent
    // count) until a later step is invoked or a turn ends with nothing live; the step after it
    // is "○", not a yellow "next"; before any step the first is "→" (one downstream ticket,
    // 2026-10-22: a built-in code-review read ✓ while its four agents still ran, and the owner read
    // the yellow step after it as the pane hanging there)
    const bandNext = await band()
    await fire('skill.prompt', { skill: 'code-review' }, async () => ({}))
    liveAgents = [{ id: 'r1', status: 'running', description: 'review' }, { id: 'r2', status: 'running', description: 'review' }, { id: 'r3', status: 'pending', description: 'review' }, { id: 'r4', status: 'running', description: 'review' }]
    await fire('turn.complete', { reason: 'answer', answer: 'reviewing', turnId: 't4' }, async () => ({}))
    const bandHeld = await band()
    liveAgents = []
    await fire('turn.start', { text: '', turnId: 't5' }, async () => ({}))
    await fire('skill.prompt', { skill: 'simplify' }, async () => ({}))
    const bandSimplify = await band()
    await fire('turn.complete', { reason: 'answer', answer: 'done', turnId: 't5' }, async () => ({}))
    const bandDone = await band()
    // an agent spawned after that clean turn end (a follow-up brief, no new step) re-lights nothing
    liveAgents = [{ id: 'x1', status: 'running', description: 'explore' }]
    const bandAfterAgent = await band()
    liveAgents = []
    // two steps stamped in the same millisecond (4.3.2 downstream, 2026-10-22): the later step in
    // flow order is the one running
    { const r = rec(); const t = Date.now() + 10; r['AB-5'].skills_last = { ...(r['AB-5'].skills_last ?? {}), 'code-review': t, simplify: t }; fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify(r)) }
    liveAgents = [{ id: 'x2', status: 'running', description: 'simplify angle' }]
    await fire('turn.complete', { reason: 'answer', answer: 'simplifying', turnId: 't6' }, async () => ({}))
    const bandTie = await band()
    liveAgents = []
    const bandText = { bandNext, bandHeld, bandSimplify, bandDone, bandAfterAgent, bandTie }
    const bandRead = {
      next: /→ implement ○ tdd/.test(bandNext) && !/…/.test(bandNext),
      held: /… review:built-in \(4 agents\)/.test(bandHeld) && !/✓ review:built-in/.test(bandHeld) && !/→/.test(bandHeld),
      simplify: /✓ review:built-in/.test(bandSimplify) && /… simplify/.test(bandSimplify) && !/→/.test(bandSimplify),
      done: /✓ simplify/.test(bandDone) && !/…/.test(bandDone) && /→ implement/.test(bandDone),
      afterAgent: /✓ simplify/.test(bandAfterAgent) && !/…/.test(bandAfterAgent),
      tie: /… simplify \(1 agent\)/.test(bandTie) && /✓ review:built-in/.test(bandTie),
    }
    console.log(JSON.stringify({ registered, paneHeld, paneCleared, sendToFork, sendToForkById, sendToRole, bandRead, armOffSection, refusedListed, refusedOther, refusedWhy, compacted, commitNoTest, commitWithTest, commitDeletedTest, commitLaterDeletedTest, commitPathLimited, commitAllDeleted, commitAddThenCommit, commitRmThenCommit, commitRestageDeleted, commitDashMAttached, commitScopedAddAll, commitPathRestored, commitAfterMv, mvNotReplayed, commitTwice, commitDashCSrc, commitAmendOnly, commitRmAddAll, rmNotReplayed, commitPathspecFile, commitRepeatedC, commitDotUntracked, commitDotStaged, commitSkippedAdd, commitRmNoCached, fileSurvived, commitOrAdd, commitEchoAdd, commitRmAbsent, commitSubstQuoted, testStillStaged, commitWorkTree, commitConfigOpt, commitSubstApos, commitBacktickDouble, commitSubstLiteral, commitConfigEnv, commitCommentedAdd, commitAbbrevOpt, commitMessageEq, commitRedirect, commitFdDup, ampNamed, commitHeredocMsg, commitHeredocOpen, commitHeredocExtra, commitHeredocBare, substFixNamed, noScratchLeft, bandText, log }))
    return
  }
  await fire('session.start', {}, async () => ({}))
  await new Promise(r => setTimeout(r, 800))  // the newer-release lookup runs beside the start
  const latestChip = (await engine.read($, { id: 'astragentic-dispatch.banner', init: {} })).latest
  await fire('session.send', { to: 'builder-ab-1-32 [1c2d95]', text: '/mattpocock-skills:verify AB-1', origin: { kind: 'model' } }, async () => ({ isDelivered: true }))
  const afterSend = await rows()
  const ack = `<cross-session-message from="uds:/tmp/x.sock" from-name="builder-ab-1-32">\n[astragentic-dispatch] RECEIVED key=AB-1 pane=p1\n</cross-session-message>`
  await fire('session.receive', { text: ack, origin: { kind: 'plugin' } }, async () => ({}))
  const afterAck = await rows()
  // retire the lane: the entry leaves the record, the next board refresh must forget the send
  await fire('session.send', { to: 'builder-ab-1-32', text: 'one more', origin: { kind: 'model' } }, async () => ({ isDelivered: true }))
  fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), '{}')
  await fire('prompt.submit', { text: 'hello', origin: { kind: 'composer' } }, async () => ({}))
  const afterRetire = await rows()
  // a retired pane wrote a stub entry (no pane_id) with a pending turn end: no bell, entry removed
  const bells = []; $.prompt.submit = async p => { bells.push(p.text.split('\n')[0]) }
  fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify({ 'AB-2': { role: 'builder', turn_end_pending: { at: 1, reason: 'dead address', text: '[astragentic-dispatch] TURN-END key=AB-2 pane=p2 reason=answer\nWork is complete' } } }))
  await every()
  const stubBells = bells.length, stubLeft = Object.keys(JSON.parse(fs.readFileSync(path.join(root, '.astraler/state/dispatch-record.json'), 'utf8'))).length
  // a held turn end older than the ceiling rings once as held-stale, and the row reads stale
  bells.length = 0
  fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify({ 'AB-3': { role: 'builder', pane_id: 'p3', tab_id: 't3', last_brief_received_at: Date.now() - 5 * 3600_000, waiting_on: { n: 8, at: Date.now() - 4 * 3600_000, what: ['code-review finder'] } } }))
  await every(); await every()
  const staleBells = bells.filter(b => b.includes('reason=held-stale')).length
  const staleRow = (await rows()).includes('— stale')
  // a subagent's turn.start (Claude Code 2.1.299 fires it with agentId) must not hold bells
  bells.length = 0
  fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify({ 'AB-4': { role: 'builder', pane_id: 'p4', tab_id: 't4', session_name: 'builder-ab-4', last_brief_received_at: Date.now() - 60_000 } }))
  await fire('turn.start', { text: '', turnId: 'sub-1', agentId: 'a-sub-1' }, async () => ({}))
  const end = `<cross-session-message from="uds:/tmp/y.sock" from-name="builder-ab-4">\n[astragentic-dispatch] TURN-END key=AB-4 pane=p4 reason=answer\nDone</cross-session-message>`
  await fire('session.receive', { text: end, origin: { kind: 'plugin' } }, async () => ({}))
  const subagentHeld = bells.length === 0
  // a bell held during the dispatcher's own turn is flushed at turn.complete, and the "held"
  // status line goes with it (measured on nizzy 2026-10-20: it outlived its flush by hours)
  bells.length = 0
  await fire('turn.start', { text: '', turnId: 'main-1' }, async () => ({}))
  await fire('session.receive', { text: end, origin: { kind: 'plugin' } }, async () => ({}))
  const heldShown = log.some(t => typeof t === 'string' && t.includes('held until this turn ends'))
  await fire('turn.complete', { reason: 'answer', answer: 'ok', turnId: 'main-1' }, async () => ({}))
  const heldCleared = heldShown && bells.length === 1 && log[log.length - 1] === undefined
  // a merge of a Builder whose pane recorded skills but not simplify is refused before it runs;
  // the same merge with the full record goes through; an entry with an empty record is not judged
  const mergeOf = async (skills, extra = {}) => {
    fs.writeFileSync(path.join(root, '.astraler/state/dispatch-record.json'), JSON.stringify({ 'AB-6': { role: 'builder', pane_id: 'p6', tab_id: 't6', session_id: 's6', branch: 'builder/AB-6', skills_run: skills, ...extra } }))
    let nextRan = false
    const r = await fire('tool.call', { tool: 'Bash', command: 'git merge --no-ff builder/AB-6' }, async () => { nextRan = true; return {} })
    return `${r?.deny ? 'deny' : 'pass'}:${nextRan ? 'ran' : 'held'}${r?.deny && /has no record of: [^.]*\btdd\b/.test(String(r.deny)) ? ':tdd' : ''}`
  }
  const full = { 'mattpocock-skills:implement': 1, 'mattpocock-skills:tdd': 1, 'mattpocock-skills:code-review': 1, 'code-review': 1, 'simplify': 1, 'codex-arm': 1 }
  const mergeGap = await mergeOf({ ...full, simplify: undefined })
  const mergeFull = await mergeOf(full)
  const mergeEmpty = await mergeOf({})
  // 4.1.3 — tdd at merge is the commit gate's question (one downstream ticket, 2026-10-22: five commits
  // with test files passed the pane, the merge was refused "no record of: tdd"): a record with
  // no tdd call and a branch carrying a test file since the dispatch base merges; the same
  // record with no test file on the branch is refused and the refusal names tdd
  const gitq = (...a) => require('child_process').spawnSync('git', a, { cwd: root, encoding: 'utf8' })
  const baseSha = gitq('rev-parse', 'HEAD').stdout.trim()
  gitq('checkout', '-q', '-b', 'builder/AB-6')
  fs.writeFileSync(path.join(root, 'feat.js'), 'f'); fs.writeFileSync(path.join(root, 'feat.test.js'), 't')
  gitq('add', 'feat.js', 'feat.test.js'); gitq('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'feat with test')
  gitq('checkout', '-q', '-')
  const mergeTddByBranch = await mergeOf({ ...full, 'mattpocock-skills:tdd': undefined }, { start_sha: baseSha })
  gitq('branch', '-q', '-D', 'builder/AB-6'); gitq('checkout', '-q', '-b', 'builder/AB-6')
  fs.writeFileSync(path.join(root, 'feat.js'), 'f2'); gitq('add', 'feat.js'); gitq('-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '-m', 'feat alone')
  gitq('checkout', '-q', '-')
  const mergeTddNoTest = await mergeOf({ ...full, 'mattpocock-skills:tdd': undefined }, { start_sha: baseSha })
  gitq('branch', '-q', '-D', 'builder/AB-6'); gitq('clean', '-fdq', '--', 'feat.js', 'feat.test.js')
  // the dispatcher learns every off scope: it runs the marker check at merge
  const composed = await fire('prompt.compose', {}, async () => ({ sections: [] }))
  const armOffDispatcher = (composed?.sections ?? []).some(s => /ARM: off at ticket[\s\S]*arm\(ticket\)/.test(String(s.text)))
  // 4.1.0 — four gates a 30-day field audit saw fire 0 times, each driven here with its defect planted
  const sendBrief = async text => { const r = await fire('session.send', { to: 'builder-ab-9', text, origin: { kind: 'model' } }, async () => ({ isDelivered: true })); return r?.isDelivered === false ? `refused:${String(r.reason ?? '').slice(0, 60)}` : 'sent' }
  const recPath = path.join(root, '.astraler/state/dispatch-record.json')
  const orchPath = path.join(root, '.agents/orchestrator.md')
  const orchText = fs.readFileSync(orchPath, 'utf8')
  // (1) a brief with no QA line
  const briefNoQa = await sendBrief('/mattpocock-skills:implement AB-9\nWorktree: x · Branch: y · Base: main')
  // (2) an upgrade that stopped part-way
  fs.writeFileSync(path.join(root, '.astraler/state/apply-incomplete'), '0.0.2')
  const briefUpgrade = await sendBrief('/mattpocock-skills:implement AB-9\nQA: none — no surface')
  fs.unlinkSync(path.join(root, '.astraler/state/apply-incomplete'))
  // (3) an orchestrator whose Active assignments table has no Advisor column
  fs.writeFileSync(orchPath, orchText.replace('| Role | Runtime | Model | Effort | Advisor |', '| Role | Runtime | Model | Effort |').replace('|---|---|---|---|---|', '|---|---|---|---|').replace('| builder | claude | m | medium | opus |', '| builder | claude | m | medium |'))
  const briefAdvisor = await sendBrief('/mattpocock-skills:implement AB-9\nQA: none — no surface')
  fs.writeFileSync(orchPath, orchText)
  // (4) closing the pane of a Builder that is mid-turn
  fs.writeFileSync(recPath, JSON.stringify({ 'AB-9': { role: 'builder', pane_id: 'p9', tab_id: 't9', session_id: 's9', last_brief_received_at: Date.now() } }))
  let closeRan = false
  const closeR = await fire('tool.call', { tool: 'Bash', command: 'herdr pane close p9' }, async () => { closeRan = true; return {} })
  const closeRefusal = `${closeR?.deny ? 'deny' : 'pass'}:${closeRan ? 'ran' : 'held'}`
  const roleAtDispatch = (() => { fs.writeFileSync(recPath, '{}'); return null })()
  // a delivered Builder brief writes the role on the record at dispatch
  await sendBrief('/mattpocock-skills:implement AB-9\nQA: none — no surface')
  const roleWritten = JSON.parse(fs.readFileSync(recPath, 'utf8'))['AB-9']?.role === 'builder'
  // 4.1.0 — builder-target is read by the mod: two live Builders against a row of 2 refuse a third brief
  fs.writeFileSync(orchPath, orchText.replace(/\| builder-target \| `\d+` \|/, '| builder-target | `2` |'))
  fs.writeFileSync(recPath, JSON.stringify({ 'AB-10': { role: 'builder', pane_id: 'p10' }, 'AB-11': { role: 'builder', pane_id: 'p11' } }))
  const briefOverTarget = await sendBrief('/mattpocock-skills:implement AB-12\nQA: none — no surface')
  fs.writeFileSync(recPath, JSON.stringify({ 'AB-10': { role: 'builder', pane_id: 'p10', worktree_removed_at: 1 }, 'AB-11': { role: 'builder', pane_id: 'p11' } }))
  const briefUnderTarget = await sendBrief('/mattpocock-skills:implement AB-12\nQA: none — no surface')
  // the destination registered itself first (the protocol): its own entry is not a competing lane
  fs.writeFileSync(orchPath, orchText.replace(/\| builder-target \| `\d+` \|/, '| builder-target | `1` |'))
  fs.writeFileSync(recPath, JSON.stringify({ 'AB-13': { role: 'builder', pane_id: 'p13' } }))
  const briefToRegistered = await sendBrief('/mattpocock-skills:implement AB-13\nQA: none — no surface')
  fs.writeFileSync(orchPath, orchText); fs.writeFileSync(recPath, '{}')
  console.log(JSON.stringify({ afterSend, afterAck, afterRetire, stubBells, stubLeft, staleBells, staleRow, subagentHeld, heldCleared, latestChip, mergeGap, mergeFull, mergeEmpty, mergeTddByBranch, mergeTddNoTest, armOffDispatcher, briefNoQa, briefUpgrade, briefAdvisor, closeRefusal, roleWritten, briefOverTarget, briefUnderTarget, briefToRegistered, log }))
})().catch(e => { console.error(e); process.exit(2) })
DRVEOS
  mod_drive() {  # $1 mod dir → prints {afterSend, afterAck, afterRetire}
    rm -rf "$TMP/mod-drive-repo"; mkdir -p "$TMP/mod-drive-repo/.astraler/state"
    ( cd "$TMP/mod-drive-repo" && git init -q && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init && git tag v0.0.2 )
    echo 0.0.1 > "$TMP/mod-drive-repo/.astraler/state/applied-version"
    mkdir -p "$TMP/mod-drive-repo/.agents"
    printf '| workspace-label | `x` |\n| builder-target | `4` |\n\n## Active assignments\n\n| Role | Runtime | Model | Effort | Advisor |\n|---|---|---|---|---|\n| builder | claude | m | medium | opus |\n\n## Cross-vendor arm\n\n| Scope | Enabled |\n|---|---|\n| ticket | no |\n| spec | yes |\n| slice | yes |\n' > "$TMP/mod-drive-repo/.agents/orchestrator.md"
    echo '{"AB-1":{"role":"builder","pane_id":"p1","tab_id":"t1","session_name":"builder-ab-1-32","registered_at":1,"branch":"feat/ab-1","start_sha":"abc"}}' > "$TMP/mod-drive-repo/.astraler/state/dispatch-record.json"
    node "$TMP/mod-drive.cjs" "$1" "$TMP/mod-drive-repo" "$TSC_PKG" "${2:-}" 2>&1
  }
  out="$(mod_drive "$MOD")"
  if says "$out" '"afterSend":"AB-1:sent:"' && says "$out" '"afterAck":"AB-1:registered:no brief yet"' && says "$out" '"afterRetire":""' && says "$out" '"stubBells":0,"stubLeft":0,"staleBells":1,"staleRow":true,"subagentHeld":false,"heldCleared":true,"latestChip":"0.0.2"'; then
    ok "the ack from the bare name clears the send keyed by \"name [ref]\"; a retired lane's send goes with its entry; a stub entry rings no bell; a hold past the ceiling rings once as held-stale; a subagent's turn.start holds nothing; a bell held in the dispatcher's turn clears its status line when flushed; a newer tag at the remote reaches the band"
  else
    bad "mod send/ack keys" "$out"
  fi
  # 4.0.2 — the record refuses the merge. one downstream ticket (2026-10-16) shipped forged Pass: lines past the marker gate.
  if says "$out" '"mergeGap":"deny:held","mergeFull":"pass:ran","mergeEmpty":"pass:ran","mergeTddByBranch":"pass:ran","mergeTddNoTest":"deny:held:tdd","armOffDispatcher":true'; then
    ok "merge gate: a recorded pane missing simplify is refused before the merge runs; a full record passes; an empty record is not judged; tdd is judged by a test file on the branch since dispatch, not by the skill call (one downstream ticket, 2026-10-22); the dispatcher's prompt names the off arm scope and its marker"
  else
    bad "mod merge gate" "$out"
  fi
  # 4.1.0 — the four gates no field data had seen fire, each shown firing on its planted defect
  if says "$out" '"briefNoQa":"refused:' && says "$out" 'no \"QA:' && says "$out" '"briefUpgrade":"refused:' && says "$out" '"briefAdvisor":"refused:' && says "$out" '"closeRefusal":"deny:held"' && says "$out" '"roleWritten":true' && says "$out" '"briefOverTarget":"refused:' && says "$out" '"briefUnderTarget":"sent"' && says "$out" '"briefToRegistered":"sent"'; then
    ok "brief refused without a QA line, during a half-applied upgrade, without an Advisor column, and at builder-target; a mid-turn pane's close is refused; a delivered brief writes the role on the record"
  else
    bad "mod merge gate" "$out"
  fi
  out="$(mod_drive "$MOD" pane)"
  if says "$out" '"registered":true,"paneHeld":true,"paneCleared":true,"sendToFork":"code-review [ce2df1]","sendToForkById":"a-7f3-ce2df1","sendToRole":"uds:/tmp/d.sock","bandRead":{"next":true,"held":true,"simplify":true,"done":true,"afterAgent":true,"tie":true},"armOffSection":true,"refusedListed":"deny:held","refusedOther":"pass:ran","refusedWhy":true,"compacted":1,"commitNoTest":"deny:held","commitWithTest":"pass:ran","commitDeletedTest":"deny:held","commitLaterDeletedTest":"deny:held","commitPathLimited":"deny:held","commitAllDeleted":"deny:held","commitAddThenCommit":"pass:ran","commitRmThenCommit":"deny:held","commitRestageDeleted":"deny:held","commitDashMAttached":"deny:held","commitScopedAddAll":"deny:held","commitPathRestored":"deny:held","commitAfterMv":"deny:held","mvNotReplayed":true,"commitTwice":"deny:held","commitDashCSrc":"deny:held","commitAmendOnly":"deny:held","commitRmAddAll":"deny:held","rmNotReplayed":true,"commitPathspecFile":"deny:held","commitRepeatedC":"deny:held","commitDotUntracked":"deny:held","commitDotStaged":"pass:ran","commitSkippedAdd":"deny:held","commitRmNoCached":"deny:held","fileSurvived":true,"commitOrAdd":"deny:held","commitEchoAdd":"deny:held","commitRmAbsent":"deny:held","commitSubstQuoted":"deny:held","testStillStaged":true,"commitWorkTree":"deny:held","commitConfigOpt":"deny:held","commitSubstApos":"deny:held","commitBacktickDouble":"deny:held","commitSubstLiteral":"pass:ran","commitConfigEnv":"deny:held","commitCommentedAdd":"deny:held","commitAbbrevOpt":"deny:held","commitMessageEq":"pass:ran","commitRedirect":"deny:held","commitFdDup":"pass:ran","ampNamed":true,"commitHeredocMsg":"pass:ran","commitHeredocOpen":"deny:held","commitHeredocExtra":"deny:held","commitHeredocBare":"deny:held","substFixNamed":true,"noScratchLeft":true'; then
    ok "pane side: a turn end with a live agent is held, the next turn start ends the hold, the band reads the latest step as … with the pane's agent count until a later step or a clean turn end and the step after it as ○, an arm row at no reaches the Builder's prompt, a command on the project's refused list is refused, and a turn over the context ceiling is compacted"
  else
    bad "mod pane hold" "$out"
  fi
  rm -rf "$TMP/mod-stuck"; cp -R "$MOD" "$TMP/mod-stuck"
  python3 - "$TMP/mod-stuck/hooks/register.tsx" <<'EOS'
import sys
p = sys.argv[1]; s = open(p).read()
old = "return to.replace(/\\s*\\[[0-9a-f]{4,}\\]\\s*$/i, '').trim()"
assert old in s, "addressName body not found"
s = s.replace(old, "return to", 1)
old2 = "if (!isLive(entry)) { await deleteRecordKey($, root, key); continue }"
assert old2 in s, "wakeFromRecord stub guard not found"
s = s.replace(old2, "", 1)
old3 = "if (w && isLive(entry) && !w.stale_rung_at && now - (w.at ?? now) > HOLD_STALE_MS) {"
assert old3 in s, "hold ceiling not found"
s = s.replace(old3, "if (false) {", 1)
old4 = "if ((e as any).agentId !== undefined) return next(e)\n    isBusy = true"
assert old4 in s, "turn.start agentId guard not found"
s = s.replace(old4, "isBusy = true", 1)
old5 = "if (own?.pane_id === me!.pane && own.waiting_on) {\n          await patchRecord($, root!, me!.key, { waiting_on: null })\n          $.ui.status(undefined)\n          await refreshFlow($, root!, me!.key)\n        }"
assert old5 in s, "turn.start hold clear not found"
s = s.replace(old5, "", 1)
old6 = "if (entry?.role !== 'builder' || !entry.session_id || Object.keys(skillsRun(entry)).length === 0) continue"
assert old6 in s, "merge gate guard not found"
s = s.replace(old6, "continue", 1)
old6c = "return id === to || a.name === to || a.teammateId === to"
assert old6c in s, "fork name match not found"
s = s.replace(old6c, "return id === to || a.teammateId === to", 1)
old6d = "|| (ref !== '' && id.toLowerCase().includes(ref))"
assert old6d in s, "fork ref match not found"
s = s.replace(old6d, "", 1)
old6f = "if (at > 0 && (!best || at >= best.at)) best = { name, at }"
assert old6f in s, "tie-break not found"
s = s.replace(old6f, "if (at > 0 && (!best || at > best.at)) best = { name, at }", 1)
old6e = "if (name === running) return <Chip"
assert old6e in s, "running chip not found"
s = s.replace(old6e, "if (false) return <Chip", 1)
old7 = "if (m[2].toLowerCase() === 'no') off.add(m[1])"
assert old7 in s, "arm row parser not found"
s = s.replace(old7, "", 1)
old8 = "      if (re.test(e.command)) {"
assert old8 in s, "refused-list test not found"
s = s.replace(old8, "      if (false) {", 1)
old9 = "if ((usage?.context?.tokens ?? 0) >= contextCeiling) compactDue = true"
assert old9 in s, "context ceiling check not found"
s = s.replace(old9, "", 1)
old10 = "  $.ui.status(undefined)\n  const text"
assert old10 in s, "held-bell status clear not found"
open(p, 'w').write(s.replace(old10, "  const text", 1))
EOS
  out="$(mod_drive "$TMP/mod-stuck")"
  if says "$out" 'builder-ab-1-32 [1c2d95]:sent:' && says "$out" '"afterRetire":"builder-ab-1-32' && says "$out" '"stubBells":1' && says "$out" '"staleBells":0' && says "$out" '"subagentHeld":true,"heldCleared":false' && says "$out" '"mergeGap":"pass:ran"' && says "$out" '"armOffDispatcher":false'; then
    ok "planted: a send keyed by the typed string stays \"sent\" through the ack and past the lane's retirement; a stub entry rings; a hold never times out; a subagent's turn.start holds the bell; a flushed bell leaves its held status standing; a merge with a gapped record goes through"
  else
    bad "mod send/ack planted defect" "the driver did not show the stuck chip: $out"
  fi
  # 4.1.3 — the merge gate's tdd question reverts to the record alone (the 4.1.2 shape): the branch
  # that carries its test since dispatch, with no tdd call recorded, is refused at merge
  rm -rf "$TMP/mod-stuck-tdd"; cp -R "$MOD" "$TMP/mod-stuck-tdd"
  python3 - "$TMP/mod-stuck-tdd/hooks/register.tsx" <<'EOS'
import sys
p = sys.argv[1]; s = open(p).read()
old = "const carries = await branchCarriesTest($, root, entry, ref)"
assert old in s, "merge gate tdd-by-branch not found"
open(p, 'w').write(s.replace(old, "const carries = false", 1))
EOS
  out="$(mod_drive "$TMP/mod-stuck-tdd")"
  if says "$out" '"mergeTddByBranch":"deny:held:tdd"' && says "$out" '"mergeTddNoTest":"deny:held:tdd"'; then
    ok "planted: a merge gate that asks the record for tdd refuses the branch that carries its test (one downstream ticket, 2026-10-22)"
  else
    bad "mod merge gate planted tdd" "the record-only gate did not refuse the tested branch: $out"
  fi
  # 4.3.4 — a refusal that ignores the pattern's own `# reason:` line says "the owner runs it" to a
  # Builder whose whole-suite run the station owns
  rm -rf "$TMP/mod-stuck-why"; cp -R "$MOD" "$TMP/mod-stuck-why"
  python3 - "$TMP/mod-stuck-why/hooks/register.tsx" <<'EOS'
import sys
p = sys.argv[1]; s = open(p).read()
old = "reason = line.match(/^#+\\s*reason:\\s*(.+)$/i)?.[1] ?? ''"
assert old in s, "refusal reason read not found"
open(p, 'w').write(s.replace(old, "reason = ''", 1))
EOS
  out="$(mod_drive "$TMP/mod-stuck-why" pane)"
  if says "$out" '"refusedListed":"deny:held","refusedOther":"pass:ran","refusedWhy":false'; then
    ok "planted: a refusal that drops the pattern's reason tells a Builder the owner runs the station's suite (one downstream ask, 2026-10-22)"
  else
    bad "mod refusal planted reason" "the reasonless refusal was not caught: $out"
  fi
  out="$(mod_drive "$TMP/mod-stuck" pane)"
  if says "$out" '"paneHeld":true,"paneCleared":false,"sendToFork":"uds:/tmp/d.sock","sendToForkById":"a-7f3-ce2df1","sendToRole":"uds:/tmp/d.sock","bandRead":{"next":true,"held":false,"simplify":false,"done":true,"afterAgent":true,"tie":false},"armOffSection":false,"refusedListed":"pass:ran","refusedOther":"pass:ran","refusedWhy":false,"compacted":0'; then
    ok "planted: a step invoked reads ✓ while the pane's four agents still run; a same-millisecond tie lights the earlier step; a pane that starts a turn leaves its hold standing; an arm row nobody parses reaches no prompt; a refused list nobody tests refuses nothing; a ceiling nobody reads compacts nothing"
  else
    bad "mod send/ack planted defect" "the driver did not show the stuck chip: $out"
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
