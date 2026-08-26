#!/usr/bin/env bash
# hook-git-guard.sh — PreToolUse guard for Bash git commands.
#
# WHY THIS IS A SCRIPT AND NOT AN INLINE HOOK COMMAND. The prior hook was a single
# shell line crammed into settings.json. It could not be read, could not be run by hand,
# and could not be tested — and it sat dormant across releases while looking installed
# (AST-102). A hook whose body cannot be executed outside the harness is a signal that
# cannot fail. This one runs standalone:
#
#   echo '{"hook_event_name":"PreToolUse","tool_name":"Bash",
#          "tool_input":{"command":"git add -A"}}' | scripts/hook-git-guard.sh
#
# CONTRACT (verified against the Claude Code hooks documentation, 2026-08-26):
#   - `matcher` in settings.json matches the TOOL NAME, not the command. It is a string.
#     Filtering the command is this script's job, from the stdin payload.
#   - The event payload arrives as JSON on STDIN, with `tool_name` and `tool_input.command`.
#   - PreToolUse CAN block, by printing
#       {"hookSpecificOutput":{"hookEventName":"PreToolUse",
#        "permissionDecision":"deny","permissionDecisionReason":"..."}}
#   - Printing nothing and exiting 0 means "no decision" — the normal permission flow runs.
#
# WHAT IT DOES NOT DO. It never blocks on a rule the agent could not have satisfied, and
# it never guesses a path. Where a rule needs a repo fact it cannot resolve, it allows and
# says nothing: a guard that fires on ambiguity trains the operator to route around it.

set -uo pipefail

PAYLOAD="$(cat)"

# Parse with python3 rather than jq: python3 is already a hard requirement of this package
# (check-reachability.sh is python), jq is not.
read_field() {  # $1 = dotted path, e.g. tool_input.command
    printf '%s' "$PAYLOAD" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for k in sys.argv[1].split("."):
    if not isinstance(d, dict):
        sys.exit(0)
    d = d.get(k)
    if d is None:
        sys.exit(0)
print(d if isinstance(d, str) else json.dumps(d))
' "$1" 2>/dev/null
}

CMD="$(read_field tool_input.command)"
TOOL="$(read_field tool_name)"
CWD="$(read_field cwd)"
[ -n "${CWD:-}" ] && [ -d "$CWD" ] && cd "$CWD" 2>/dev/null

# Not a Bash call, or an empty command: no opinion.
[ "$TOOL" = "Bash" ] || exit 0
[ -n "${CMD:-}" ] || exit 0

# Fire log. AST-102 is the entry about a hook that looked installed and never ran: without a
# record of invocations, "we saw nothing" and "it never fired" are the same observation. Every
# call lands here, allow or deny, so the question is answerable with a dated negative.
LOG="${HARNESS_HOOK_LOG:-/tmp/harness-hook-events.log}"
log() { printf '%s hook-git-guard %s | %s\n' "$(date -u +%FT%TZ)" "$1" "${CMD:0:120}" >> "$LOG" 2>/dev/null || true; }

deny() {  # $1 = reason
    log "DENY"
    python3 -c '
import sys, json
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": sys.argv[1],
}}))
' "$1"
    exit 0
}

note() { printf 'hook-git-guard: %s\n' "$1" >&2; }

# ---------------------------------------------------------------------------------------
# RULE 1 — `git add -A` / `git add .` (AST-054)
# A sweeping add once committed ~1000 unrelated files, permanently. "Commit it" without
# naming what is read as `-A`, so the guard names the alternative rather than only refusing.
# ---------------------------------------------------------------------------------------
if printf '%s' "$CMD" | grep -qE '(^|[;&|]|\s)git\s+add\s+(-A\b|--all\b|\.(\s|$))'; then
    deny "git add -A / git add . is refused here (AST-054: a sweeping add once committed ~1000 unrelated files permanently). Stage the paths this change actually touches, by name."
fi

# ---------------------------------------------------------------------------------------
# RULE 2 — `rm -rf` on a worktree path (AST-096)
# Removing the DIRECTORY leaves `.git/worktrees/<name>/` behind, and the next `git worktree
# add` then refuses — silently, whenever output was redirected. Directory removal is not
# registration removal.
# ---------------------------------------------------------------------------------------
if printf '%s' "$CMD" | grep -qE 'rm\s+(-[a-zA-Z]*\s+)*-?[a-zA-Z]*[rR][a-zA-Z]*f|rm\s+-rf' \
   && printf '%s' "$CMD" | grep -qE '(worktrees?/|\.claude/worktrees)'; then
    deny "rm -rf on a worktree path is refused (AST-096: removing the directory leaves .git/worktrees/<name>/ registered, and the next 'git worktree add' refuses silently). Use: git worktree remove <path> && git worktree prune"
fi

# ---------------------------------------------------------------------------------------
# RULE 3 — `git worktree add` (AST-028, AST-096)
# Two failures, one command. A relative path resolved through a stale shell cwd and put the
# worktree somewhere nobody looked (an hour-long misdiagnosis). And a stale registration makes
# `add` refuse — which goes unnoticed when the command's output is redirected away.
# The prune that prevents the second is run HERE, so it stops being a step to remember.
# ---------------------------------------------------------------------------------------
if printf '%s' "$CMD" | grep -qE '(^|[;&|]|\s)git\s+(-C\s+\S+\s+)?worktree\s+add\b'; then
    if printf '%s' "$CMD" | grep -qE '>\s*/dev/null|2>\s*/dev/null|&>\s*/dev/null'; then
        deny "git worktree add with its output redirected is refused (AST-096: 'add' refuses on a stale registration, and the refusal is exactly what the redirect throws away). Run it so the result is visible."
    fi
    # The path argument is the first non-flag token after `add` that is not a branch flag value.
    WT_PATH="$(printf '%s' "$CMD" | python3 -c '
import sys, re, shlex
try:
    toks = shlex.split(sys.stdin.read())
except Exception:
    sys.exit(0)
if "add" not in toks:
    sys.exit(0)
rest = toks[toks.index("add") + 1:]
skip = False
for t in rest:
    if skip:
        skip = False
        continue
    if t in ("-b", "-B", "--reason"):
        skip = True
        continue
    if t.startswith("-"):
        continue
    print(t)
    break
' 2>/dev/null)"
    if [ -n "${WT_PATH:-}" ] && [ "${WT_PATH#/}" = "$WT_PATH" ] && [ "${WT_PATH#\$}" = "$WT_PATH" ]; then
        deny "git worktree add needs an ABSOLUTE path; got '$WT_PATH' (AST-028: a relative path once resolved through a stale shell cwd and the worktree was born somewhere nobody looked). Use <repo-root>/.claude/worktrees/<branch-slug>."
    fi
    # Prune before add, rather than asking anyone to remember it.
    if git rev-parse --git-dir >/dev/null 2>&1; then
        git worktree prune 2>/dev/null && note "ran 'git worktree prune' before add (AST-096)"
    fi
    exit 0
fi

# ---------------------------------------------------------------------------------------
# RULE 4 — `git worktree remove` (AST-092, AST-097, AST-100, AST-101, AST-115)
# The ordering is the whole rule: resources bound to the worktree by --cwd or by a compose
# label cannot be found once the directory is gone, so the kill must PRECEDE the removal.
# The dormant WorktreeRemove hook carried this body and never ran, because that event fires
# only for worktrees Claude Code itself manages — not for `git worktree remove` in Bash.
# ---------------------------------------------------------------------------------------
if printf '%s' "$CMD" | grep -qE '(^|[;&|]|\s)git\s+(-C\s+\S+\s+)?worktree\s+remove\b'; then
    WT="$(printf '%s' "$CMD" | python3 -c '
import sys, shlex
try:
    toks = shlex.split(sys.stdin.read())
except Exception:
    sys.exit(0)
if "remove" not in toks:
    sys.exit(0)
for t in toks[toks.index("remove") + 1:]:
    if t.startswith("-"):
        continue
    print(t)
    break
' 2>/dev/null)"

    # No resolvable path: say nothing rather than block on ambiguity.
    [ -n "${WT:-}" ] || exit 0
    [ -d "$WT" ] || exit 0

    # 4a. Uncommitted work dies with the worktree (AST-092). --force means the operator
    #     already answered this, so only the plain form is checked.
    if ! printf '%s' "$CMD" | grep -qE '\-\-force|\-f\b'; then
        DIRTY="$(git -C "$WT" status --short 2>/dev/null | head -5)"
        if [ -n "$DIRTY" ]; then
            deny "worktree '$WT' has uncommitted changes and removing it destroys them (AST-092):
$DIRTY
Commit, stash, or re-run with --force once you have decided."
        fi
    fi

    # 4b. A live process in the tree means the work is not finished (AST-097): a turn that
    #     ended is not a task that completed.
    if command -v pgrep >/dev/null 2>&1; then
        LIVE="$(pgrep -f -- "$WT" 2>/dev/null | head -3)"
        if [ -n "$LIVE" ]; then
            deny "processes are still running inside '$WT' (pids: $(printf '%s' "$LIVE" | tr '\n' ' ')). A finished turn is not finished work (AST-097). Stop them, then remove."
        fi
    fi

    # 4c. Resource cleanup, BEFORE removal — this is the ordering AST-100 and AST-101 cost.
    BROKER_PIDS="$(ps -eo pid=,command= 2>/dev/null | grep 'app-server-broker' | grep -F -- "$WT" | awk '{print $1}')"
    if [ -n "${BROKER_PIDS:-}" ]; then
        # Matched by --cwd, never by process name: `pkill -f` by name kills other worktrees'.
        printf '%s' "$BROKER_PIDS" | xargs -r kill 2>/dev/null \
            && note "killed broker pid(s) $(printf '%s' "$BROKER_PIDS" | tr '\n' ' ') bound to $WT (AST-100)"
    fi
    if command -v docker >/dev/null 2>&1; then
        PROJ="$(basename "$WT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g')"
        # Scoped to THIS worktree's compose project only. A blanket `docker compose down`
        # once stopped the shared test container every live Builder was standing on (AST-115).
        IDS="$(docker ps -q --filter "label=com.docker.compose.project=$PROJ" 2>/dev/null)"
        if [ -n "${IDS:-}" ]; then
            docker stop $IDS >/dev/null 2>&1 \
                && note "stopped container(s) for compose project '$PROJ' (AST-101, scoped — AST-115)"
        fi
    fi
    exit 0
fi

log "allow"
exit 0
