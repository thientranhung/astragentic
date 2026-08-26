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

WHAT THIS GUARD CANNOT DO, STATED RATHER THAN DISCOVERED. It matches commands; it is not a
shell. Two adversarial passes each found a way through and each was closed — regex spellings
first, then newlines, subshells, substitutions, assignment prefixes and `env`/`xargs`/`find
-exec` wrappers. A third form will exist: a script that writes and runs another script, an
alias, an interpreter invoked with `-c`. Treat every rule here as a floor that catches the
ACCIDENTAL case, never a boundary that survives someone routing around it deliberately.

That is why the contract is `dispatch-ticket/CLEANUP.md` and this file is a second layer under
it. A Builder on Codex or opencode has no hook at all and must still get the ordering right,
so a rule that lives only here is a rule that does not exist on two of three runtimes. If a
rule matters, it belongs in the contract first and here second.

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


# Operators that end a simple command. Split happens on the RAW string, at positions outside
# any quoting — shlex discards quote context, and a pass proved that letting it classify
# punctuation denies `printf '%s' ';' git add -A` for containing a quoted semicolon.
_OPS = ("|&", "&&", "||", ";;", ";", "|", "&", "\n")
# Wrappers that run another command. `xargs git add -A` and `find . -exec git add -A {} ;`
# were both allowed until these were unwrapped.
_WRAPPERS = {"env", "command", "nohup", "time", "sudo", "nice", "ionice", "stdbuf", "setsid",
             "xargs", "timeout", "doas"}


def _split_unquoted(cmd):
    """Split on shell operators that are NOT inside quotes. Returns raw segments."""
    segs, buf, i, quote = [], [], 0, None
    while i < len(cmd):
        c = cmd[i]
        if quote:
            buf.append(c)
            if c == "\\" and quote == '"' and i + 1 < len(cmd):
                buf.append(cmd[i + 1]); i += 2; continue
            if c == quote:
                quote = None
            i += 1
            continue
        if c in ("'", '"'):
            quote = c; buf.append(c); i += 1; continue
        if c == "\\" and i + 1 < len(cmd):
            buf.append(c); buf.append(cmd[i + 1]); i += 2; continue
        # Grouping constructs and substitutions: treat their contents as commands too, so
        # `(git add -A)` and `$(git add -A)` are not a way through.
        if c in "(){}":
            segs.append("".join(buf)); buf = []; i += 1; continue
        if c == "$" and i + 1 < len(cmd) and cmd[i + 1] == "(":
            segs.append("".join(buf)); buf = []; i += 2; continue
        if c == "`":
            segs.append("".join(buf)); buf = []; i += 1; continue
        matched = None
        for op in _OPS:
            if cmd.startswith(op, i):
                matched = op; break
        if matched:
            segs.append("".join(buf)); buf = []; i += len(matched); continue
        buf.append(c); i += 1
    segs.append("".join(buf))
    return [x for x in (seg.strip() for seg in segs) if x]


def _unwrap(argv):
    """Strip env-assignment prefixes and command wrappers, returning the inner argv.

    `FOO=bar git add -A`, `env git add -A`, `xargs git add -A` and
    `find . -exec git add -A {} ;` all reached the repository unchallenged before this."""
    out = list(argv)
    guard = 0
    while out and guard < 8:
        guard += 1
        head = posixpath.basename(out[0])
        # VAR=value prefixes
        if "=" in out[0] and not out[0].startswith("=") and "/" not in out[0].split("=", 1)[0]:
            out = out[1:]; continue
        if head == "find":
            if "-exec" in out:
                out = out[out.index("-exec") + 1:]
                out = [t for t in out if t not in ("{}", ";", "\\;", "+")]
                continue
            break
        if head in _WRAPPERS:
            rest = out[1:]
            # skip the wrapper's own flags and, for xargs/timeout, their operands
            while rest and rest[0].startswith("-"):
                rest = rest[1:]
            if head == "timeout" and rest:
                rest = rest[1:]
            out = rest
            continue
        break
    return out


def simple_commands(cmd):
    """Every simple command in the line, argv-split, wrappers unwrapped."""
    out = []
    for seg in _split_unquoted(cmd):
        try:
            lex = shlex.shlex(seg, posix=True)
            lex.whitespace_split = True
            argv = list(lex)
        except ValueError:
            continue
        argv = _unwrap(argv)
        if argv:
            out.append(argv)
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
