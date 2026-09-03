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
layer under it on Claude and Codex roots.

AMBIGUITY IS NOT A FINDING. A token carrying an unresolved `$VAR` or a substitution cannot be
judged. Those are logged and allowed. A guard that fires on what it cannot resolve trains the
operator to disable it.

WHAT THIS GUARD CANNOT DO, STATED RATHER THAN DISCOVERED. It is an accidental-misuse lint, not
a boundary. Three adversarial gates each found a fresh way through, and the third concluded the
matcher was not converging; the answer was to shrink its claim rather than grow its rules. It
now recognises ONE shape — simple commands separated by unquoted operators — and stays silent
on anything containing a substitution, heredoc, comment, reserved word, wrapper or interpreter.
Silence there is the design, not a gap: a coverage claim that is not true is worse than none.

That is why the contract is `dispatch-ticket/CLEANUP.md` and this file is a second layer under
it. An OpenCode Builder has no equivalent hook, and either Claude or Codex may run with hooks
disabled or untrusted, so every Builder must still get the ordering right. If a rule matters,
it belongs in the contract first and here second.

CONTRACT (verified against Claude Code and Codex hooks documentation, 2026-08-28):
  - settings.json `matcher` matches the TOOL NAME and is a string; filtering the command is
    this script's job.
  - The event arrives as JSON on STDIN, carrying `tool_name` and `tool_input.command`.
  - A deny is printed as
      {"hookSpecificOutput":{"hookEventName":"PreToolUse",
       "permissionDecision":"deny","permissionDecisionReason":"..."}}
  - Printing nothing and exiting 0 means "no decision": the normal permission flow runs.

Codex registration lives at `.codex/hooks.json`. Codex reviews project-local hook definitions
by hash; an absent trust decision means this guard is installed but skipped, so the doctor
checks registration and the operator confirms trust with `/hooks` in the Codex CLI.
"""

import hashlib
import json
import os
import posixpath
import re
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


# ---------------------------------------------------------------------------------------
# SCOPE, AND WHY IT IS THIS SMALL.
#
# Three adversarial gates were run over this file. Each one found a fresh way through, and
# each fix bought one round: regex spellings, then newlines and subshells and wrappers, then
# quoted substitutions, reserved words, `env -u FOO`, and heredocs read as commands. Gate 3's
# verdict was that the matcher was not converging and should stop approximating shell grammar.
#
# It has stopped. This guard now recognises exactly ONE shape: a line made of simple commands
# separated by unquoted operators, containing no construct it cannot read with certainty. Meet
# anything else — a substitution, a heredoc, a comment, a reserved word, a wrapper, an `eval` —
# and it says NOTHING and records why.
#
# That is a deliberate downgrade from "boundary" to **accidental-misuse lint**. It catches the
# `git add -A` an agent reaches for by habit. It does not stop anyone who is routing around it,
# and it no longer pretends to. The previous version's wrapper handling was itself wrong
# (`env -u FOO git add -A` unwrapped to a command that was then allowed), which is the argument
# against the whole approach: coverage claims that are not true are worse than absent ones.
#
# The contract is `dispatch-ticket/CLEANUP.md`, on every runtime. This is a floor under it.
# ---------------------------------------------------------------------------------------

_OPS = ("|&", "&&", "||", ";;", ";", "|", "&", "\n")

# Any of these means the line has structure this guard cannot read. Presence is not suspicion —
# it is the guard declining to guess, which is the only honest response to a construct whose
# execution semantics it does not model.
_UNREADABLE = ("$(", "`", "<<", "#", "(", ")", "{", "}", "&>", ">(", "<(")
_RESERVED = {"if", "then", "elif", "else", "fi", "while", "until", "for", "do", "done",
             "case", "esac", "function", "select", "!", "time", "coproc",
             "eval", "exec", "source", ".", "bash", "sh", "zsh", "env", "xargs", "find",
             "command", "sudo", "doas", "nohup", "setsid", "timeout", "nice", "ionice",
             "stdbuf", "watch", "parallel"}


def _split_unquoted(cmd):
    """Split on operators outside quoting, or return None when the line is unreadable.

    Quote tracking exists so quoted data is never mistaken for syntax; the unreadable check
    exists because quote tracking alone is not enough — a shell runs `$(...)` inside double
    quotes, which this scanner would otherwise treat as inert text."""
    segs, buf, i, quote = [], [], 0, None
    while i < len(cmd):
        c = cmd[i]
        if quote:
            if c == "\\" and quote == '"' and i + 1 < len(cmd):
                buf.append(c); buf.append(cmd[i + 1]); i += 2; continue
            if c == quote:
                quote = None
            buf.append(c); i += 1; continue
        if c in ("'", '"'):
            quote = c; buf.append(c); i += 1; continue
        if c == "\\" and i + 1 < len(cmd):
            buf.append(c); buf.append(cmd[i + 1]); i += 2; continue
        matched = next((op for op in _OPS if cmd.startswith(op, i)), None)
        if matched:
            segs.append("".join(buf)); buf = []; i += len(matched); continue
        buf.append(c); i += 1
    if quote:
        return None                      # unterminated quote: unreadable
    segs.append("".join(buf))
    return [x for x in (seg.strip() for seg in segs) if x]


def readable(cmd):
    """True only when every construct in the line is one this guard models."""
    depth_free = cmd
    for tok in _UNREADABLE:
        if tok in depth_free:
            return False
    return True


OUT_OF_SCOPE = []          # set by simple_commands, read by main for the log line


def simple_commands(cmd):
    """Top-level simple commands, or [] when the line is outside this guard's scope."""
    OUT_OF_SCOPE.clear()
    if not readable(cmd):
        OUT_OF_SCOPE.append("unreadable-construct")
        return []
    segs = _split_unquoted(cmd)
    if segs is None:
        OUT_OF_SCOPE.append("unterminated-quote")
        return []
    out = []
    for seg in segs:
        try:
            lex = shlex.shlex(seg, posix=True)
            lex.whitespace_split = True
            argv = list(lex)
        except ValueError:
            OUT_OF_SCOPE.append("untokenizable")
            return []                    # no opinion about the whole line
        if not argv:
            continue
        head = posixpath.basename(argv[0])
        # A reserved word, an interpreter or a wrapper means the real command is nested
        # somewhere this guard does not follow. Modelling that was tried and was wrong.
        # An assignment prefix (`FOO=bar git add -A`) hides the real command one token along.
        # The first version tested only argv[0][:1], which never matched, so these reached the
        # final `allow` log — recorded as examined-and-approved when nothing had been examined.
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", argv[0]):
            OUT_OF_SCOPE.append("assignment-prefix")
            return []
        if head in _RESERVED or argv[0] in _RESERVED:
            OUT_OF_SCOPE.append("reserved-or-wrapper:" + head)
            return []
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

    cmds = simple_commands(cmd)
    if OUT_OF_SCOPE:
        # NOT the same as approving it. A reader of this log must be able to tell a line this
        # guard examined from one it declined to have an opinion about.
        log("no-opinion(%s)" % OUT_OF_SCOPE[0], cmd)
        sys.exit(0)

    for argv in cmds:
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

            # Were the worktree's resources released? `scripts/release-worktree-resources.sh`
            # stamps the resolved path after a clean run; no stamp means the reap and the
            # project's plug never ran for it. Until 2.7.15 the only call site for that release
            # was prose at the end of CLEANUP.md — and prose at the end of a ticket is what gets
            # skipped (AST-057). This turns it into a refusal. `--force` does not bypass it:
            # force is about uncommitted files, not about a database left running.
            key = hashlib.sha256(os.path.realpath(wt).encode()).hexdigest()[:16]
            if not os.path.exists(os.path.join("/tmp/harness-released", key)):
                deny("nothing has released this worktree's resources. Run "
                     "`scripts/release-worktree-resources.sh %s` first — it reaps processes "
                     "rooted there, runs the project's plug (.astraler/project/"
                     "cleanup-worktree.sh) and stamps the path so this guard admits the "
                     "removal (AST-100, AST-101)." % wt, cmd)

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

            # A resource bound to the directory cannot be found once the directory is gone, so
            # it must be released FIRST (AST-100, AST-101). This guard does not release anything
            # — it refuses the removal until that is done, because acting here would be a side
            # effect of a command that has not been permitted yet. It checks the one resource
            # the HARNESS owns (the cross-vendor companion broker). What the PROJECT's worktrees
            # allocate is the project's to declare and release — `.astraler/project/
            # cleanup-worktree.sh`, run by `scripts/release-worktree-resources.sh` — and a guard
            # that hardwired one project's stack (a compose label, until 2.7.15) read as
            # coverage to every project on a different one.
            # Filter in Python, not in a `bash -c "ps | grep …"` pipeline: that pipeline's own
            # shell carried both the process name and the path in ITS argv, so the grep matched
            # itself and every removal of an existing directory was refused as "a broker is
            # still bound". Found by the 2.7.15 selftest case for a stamped removal — the check
            # had never been exercised against a real directory before (AST-133's shape: a
            # textual match reading its own pattern).
            rc, out = run(["ps", "-eo", "pid=,command="])
            bound = [l.split(None, 1)[0] for l in (out.splitlines() if rc == 0 else [])
                     if "app-server-broker" in l and wt in l
                     and "hook-git-guard" not in l and "grep" not in l]
            if bound:
                deny("a broker is still bound to '%s' (pid %s). It is matched by --cwd, so "
                     "once the directory is gone it cannot be found at all (AST-100). Run "
                     "`scripts/release-worktree-resources.sh <worktree>` — resources first, "
                     "then the worktree — then remove." % (wt, bound[0]), cmd)
            continue

    log("allow", cmd)
    sys.exit(0)


if __name__ == "__main__":
    main()
