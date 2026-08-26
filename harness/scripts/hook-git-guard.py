#!/usr/bin/env python3
"""hook-git-guard.py — PreToolUse guard for Bash git commands.

WHY A SCRIPT, NOT AN INLINE HOOK COMMAND. The body this replaces was a single shell line
crammed into settings.json: unreadable, unrunnable by hand, untestable — and it sat dormant
across releases while looking installed (AST-102). This one runs standalone:

    echo '{"hook_event_name":"PreToolUse","tool_name":"Bash",
           "tool_input":{"command":"git add -A"}}' | python3 scripts/hook-git-guard.py

WHY .py AND NOT .sh. `check-reachability.sh` is Python behind a `.sh` name, and the cost of
that showed up as an adaptation step telling operators to run `bash -n` on it. One such file
is enough.

WHY TOKENS, NOT REGEXES. The first version matched regexes against the raw command string. A
cross-vendor pass proved that form is bypassable and over-broad in the same breath:
`/usr/bin/git add -A` and `git -c k=v add -A` slipped through, while
`printf '%s' "rm -rf .claude/worktrees/x"` was denied for containing the words. A guard that
misses the real thing AND blocks the harmless one teaches its operator to route around it,
which is worse than no guard. So: tokenize, split on shell operators, inspect argv. Quoted
data is an argument, never a command, and can no longer trigger a rule.

WHAT THIS GUARD DOES NOT DO — IT NEVER ACTS. A PreToolUse hook runs while permission is still
being decided, so anything it changes is a side effect of a command that may yet be refused.
The first version ran `git worktree prune` and killed brokers from here. It no longer does:
every rule below either denies with the exact command to run, or says nothing. The doing lives
in `dispatch-ticket/CLEANUP.md`, which is the contract on every runtime; this file is a second
layer under it, and only on a Claude root.

AMBIGUITY IS NOT A FINDING. A token carrying an unresolved `$VAR` or a substitution cannot be
judged. Those are logged and allowed. A guard that fires on what it cannot resolve trains the
operator to disable it.

CONTRACT (verified against the Claude Code hooks documentation, 2026-08-26):
  - settings.json `matcher` matches the TOOL NAME and is a string; filtering the command is
    this script's job.
  - The event arrives as JSON on STDIN, carrying `tool_name` and `tool_input.command`.
  - A deny is printed as
      {"hookSpecificOutput":{"hookEventName":"PreToolUse",
       "permissionDecision":"deny","permissionDecisionReason":"..."}}
  - Printing nothing and exiting 0 means "no decision": the normal permission flow runs.
"""

import json
import os
import posixpath
import shlex
import subprocess
import sys
from datetime import datetime, timezone

LOG = os.environ.get("HARNESS_HOOK_LOG", "/tmp/harness-hook-events.log")


def log(kind, cmd):
    """AST-102 is the entry about a hook that looked installed and never ran. Without a record
    of invocations, 'we saw nothing' and 'it never fired' are the same observation."""
    try:
        with open(LOG, "a", encoding="utf-8") as fh:
            fh.write("%s hook-git-guard %s | %s\n"
                     % (datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                        kind, cmd[:120]))
    except OSError:
        pass


def deny(reason, cmd):
    log("DENY", cmd)
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }}))
    sys.exit(0)


def simple_commands(cmd):
    """Split a command line into argv lists, one per simple command."""
    try:
        lex = shlex.shlex(cmd, posix=True, punctuation_chars=True)
        lex.whitespace_split = True
        toks = list(lex)
    except ValueError:
        return []
    out, cur = [], []
    for t in toks:
        if t in (";", "&&", "||", "|", "&", "\n"):
            if cur:
                out.append(cur)
                cur = []
        else:
            cur.append(t)
    if cur:
        out.append(cur)
    return out


def git_args(argv):
    """If argv invokes git, return its arguments with global options stripped, else None.
    Handles an absolute executable path and the global options that can precede a subcommand
    (`-c k=v`, `-C <dir>`, `--git-dir=`, `--work-tree=`)."""
    if not argv:
        return None
    if posixpath.basename(argv[0]) != "git":
        return None
    i = 1
    while i < len(argv):
        a = argv[i]
        if a in ("-C", "-c", "--namespace", "--exec-path") and i + 1 < len(argv):
            i += 2
            continue
        if a.startswith(("--git-dir=", "--work-tree=", "--exec-path=", "-c")):
            i += 1
            continue
        if a.startswith("-"):
            i += 1
            continue
        break
    return argv[i:]


def absoluteness(tok):
    """True, False, or None when the token cannot be judged. `~` expands to $HOME before git
    sees it, so it counts as absolute; a token carrying `$` or a substitution is unknown."""
    if "$" in tok or "`" in tok:
        return None
    return tok.startswith("/") or tok.startswith("~/") or tok == "~"


def first_operand(args, after):
    """The first non-flag token following a subcommand, skipping flags that take a value."""
    if after not in args:
        return None
    rest = args[args.index(after) + 1:]
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
        return t
    return None


def run(cmd_argv, cwd=None):
    try:
        r = subprocess.run(cmd_argv, cwd=cwd, capture_output=True, text=True, timeout=10)
        return r.returncode, r.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return 1, ""


def main():
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    if payload.get("tool_name") != "Bash":
        sys.exit(0)
    cmd = (payload.get("tool_input") or {}).get("command") or ""
    if not cmd.strip():
        sys.exit(0)

    cwd = payload.get("cwd")
    if cwd and os.path.isdir(cwd):
        try:
            os.chdir(cwd)
        except OSError:
            pass

    for argv in simple_commands(cmd):
        exe = posixpath.basename(argv[0]) if argv else ""

        # -- rm -rf on a worktree path (AST-096) -----------------------------------------
        # Directory removal is not registration removal: `.git/worktrees/<name>/` survives
        # and the next `git worktree add` refuses — silently whenever output was redirected.
        if exe == "rm":
            flags = "".join(a[1:] for a in argv[1:] if a.startswith("-") and not a.startswith("--"))
            recursive = "r" in flags.lower() or "--recursive" in argv
            operands = [a for a in argv[1:] if not a.startswith("-")]
            if recursive and any("worktrees/" in o or o.rstrip("/").endswith("worktrees")
                                 for o in operands):
                deny("rm -rf on a worktree path is refused (AST-096: removing the directory "
                     "leaves .git/worktrees/<name>/ registered, and the next 'git worktree "
                     "add' then refuses — silently, whenever its output was redirected). "
                     "Use: git worktree remove <path> && git worktree prune", cmd)

        args = git_args(argv)
        if args is None:
            continue

        # -- git add -A / git add . (AST-054) --------------------------------------------
        # A sweeping add once committed ~1000 unrelated files, permanently. Name the
        # alternative rather than only refusing.
        if args[:1] == ["add"] and any(a in ("-A", "--all", ".", "./") for a in args[1:]):
            deny("git add -A / git add . is refused here (AST-054: a sweeping add once "
                 "committed ~1000 unrelated files permanently). Stage the paths this change "
                 "actually touches, by name.", cmd)

        # -- git worktree add (AST-028, AST-096) -----------------------------------------
        if args[:2] == ["worktree", "add"]:
            path = first_operand(args, "add")
            if path is not None:
                abs_ok = absoluteness(path)
                if abs_ok is False:
                    deny("git worktree add needs an ABSOLUTE path; got '%s' (AST-028: a "
                         "relative path once resolved through a stale shell cwd and the "
                         "worktree was born somewhere nobody looked). Use "
                         "<repo-root>/.claude/worktrees/<branch-slug>." % path, cmd)
                if abs_ok is None:
                    log("allow-unresolved-path", cmd)
                # A stale registration makes this add refuse. Say so now, with the fix —
                # rather than pruning here, which would mutate the repo while permission for
                # this very command is still being decided.
                if abs_ok:
                    target = os.path.expanduser(path)
                    rc, out = run(["git", "worktree", "list", "--porcelain"])
                    if rc == 0 and out:
                        registered = [l.split(" ", 1)[1] for l in out.splitlines()
                                      if l.startswith("worktree ")]
                        if target in registered and not os.path.isdir(target):
                            deny("'%s' is still registered in .git/worktrees but the "
                                 "directory is gone, so this add will refuse (AST-096). Run "
                                 "`git worktree prune` first, and do not redirect its output."
                                 % target, cmd)
            continue

        # -- git worktree remove (AST-092, AST-097, AST-100, AST-101, AST-115) -----------
        if args[:2] == ["worktree", "remove"]:
            path = first_operand(args, "remove")
            if not path:
                continue
            wt = os.path.expanduser(path)
            if not os.path.isdir(wt):
                continue
            forced = "--force" in args or "-f" in args

            # Uncommitted work dies with the worktree. --force means that was already decided.
            if not forced:
                rc, out = run(["git", "-C", wt, "status", "--short"])
                if rc == 0 and out:
                    deny("worktree '%s' has uncommitted changes and removing it destroys "
                         "them (AST-092):\n%s\nCommit, stash, or re-run with --force once you "
                         "have decided." % (wt, "\n".join(out.splitlines()[:5])), cmd)

            # A live process in the tree means a turn ended, not that work finished (AST-097).
            rc, out = run(["pgrep", "-f", wt])
            if rc == 0 and out:
                deny("processes are still running inside '%s' (pids: %s). A finished turn is "
                     "not finished work (AST-097). Stop them, then remove."
                     % (wt, " ".join(out.split()[:3])), cmd)

            # Resources bound by --cwd or by a compose label cannot be found once the
            # directory is gone, so they must be stopped FIRST (AST-100, AST-101). This guard
            # does not stop them — it refuses the removal until they are, because acting here
            # would be a side effect of a command that has not been permitted yet.
            rc, out = run(["bash", "-c",
                           "ps -eo pid=,command= | grep app-server-broker | grep -F -- "
                           + shlex.quote(wt) + " | awk '{print $1}'"])
            if rc == 0 and out:
                deny("a broker is still bound to '%s' (pid %s). It is matched by --cwd, so "
                     "once the directory is gone it cannot be found at all (AST-100). Run the "
                     "ordered cleanup in dispatch-ticket/CLEANUP.md — resources first, then "
                     "the worktree — then remove." % (wt, out.split()[0]), cmd)

            proj = "".join(c for c in os.path.basename(wt).lower()
                           if c.isalnum() or c in "_-")
            rc, out = run(["docker", "ps", "-q", "--filter",
                           "label=com.docker.compose.project=" + proj])
            if rc == 0 and out:
                deny("containers for compose project '%s' are still up, and after removal the "
                     "label cannot be derived from a directory that no longer exists "
                     "(AST-101). Stop THOSE containers only — never a blanket `docker compose "
                     "down`, which once stopped the shared test container every live Builder "
                     "was standing on (AST-115). CLEANUP.md has the block." % proj, cmd)
            continue

    log("allow", cmd)
    sys.exit(0)


if __name__ == "__main__":
    main()
