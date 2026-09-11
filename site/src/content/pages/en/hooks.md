---
title: "Hooks"
description: "Four hooks, three scripts. One blocks dangerous git, one re-arms the contract after compaction, one writes a log, and one I measured as dormant."
---

Four hooks are registered in `harness/.claude/settings.json`, and the git guard is registered
again in `harness/.codex/hooks.json`. The principle behind all four is that the hook always
comes after and the contract always comes first. A rule that matters has to live in the contract,
because the contract is read on every runtime, while a hook can be disabled, can be untrusted,
and can be bolted to an execution path nobody walks through.

That last case is not hypothetical. One of the four below is dormant, I measured it, and I am
leaving it here rather than quietly removing it.

## pre-tool-use

It fires before an agent runs the `Bash` tool, on both Claude Code and Codex, and it runs
`scripts/hook-git-guard.py`.

The script reads the command about to run and does exactly one of two things: deny, naming the
exact command to run instead, or say nothing. It never acts itself. The first version ran `git
worktree prune` and killed brokers from inside the hook, and that was wrong in principle. A
`PreToolUse` hook runs while permission is still being decided, so anything it changes is a side
effect of a command that may yet be refused.

The script tokenises and inspects argv rather than matching regexes against the raw command
string. A cross-vendor pass proved the regex version was bypassable and over-broad in the same
breath: `/usr/bin/git add -A` and `git -c k=v add -A` slipped through, while `printf '%s' "rm
-rf .claude/worktrees/x"` was denied for containing the words. A guard that misses the real case
and blocks the harmless one teaches its own operator to route around it, which is worse than no
guard.

Limit: this is an accidental-misuse lint, not a boundary. Three
adversarial gates each found a fresh way through, and the third concluded the matcher was not
converging. The answer was to shrink its claim rather than grow its rules. It now recognises one
shape, simple commands separated by unquoted operators, and stays silent on anything containing
a substitution, heredoc, comment, reserved word, wrapper or interpreter. Silence there is the
design, not a gap: a coverage claim that is not true is worse than no claim.

There is also a reason it is a `.py` file rather than a shell line crammed into `settings.json`.
The old version was exactly that line: unreadable, unrunnable by hand, untestable, and it sat
dormant across releases while looking installed (AST-102). This one runs standalone, which means
it can be tested.

## worktree-remove

It fires when a worktree is removed through the `EnterWorktree` / `ExitWorktree` tool path, and
it runs `scripts/release-worktree-resources.sh` with `$WORKTREE_PATH`.

The script releases what a worktree allocated, in order. First the harness's own part: processes
whose real cwd is inside the worktree, reaped by `reap-worktree-processes.sh`. Then the part the
project declares, through the plug at `.astraler/project/cleanup-worktree.sh`. That order is
load-bearing. Resources bound to a directory, by cwd or by a label derived from the path or by a
name the project computed from it, cannot be matched once the directory is gone, so this has to
run before `git worktree remove` and never after (AST-100, AST-101).

This hook is dormant. Measured 2026-08-20 with the very
logging I added to answer the question. Three worktrees were removed after the log's last write,
one of them by a plain `git worktree remove`, and the number of `WorktreeRemove` events recorded
was zero. Meanwhile the `SubagentStop` hook in the same file and the same session logged 27
events in that same window. I confirmed it a second, independent way: the shared test container
was still `Up (healthy)` after the removal, which a live hook would have stopped.

The cause is not that the hook is broken, it is that the hook is never reached. `WorktreeRemove`
hangs off the `EnterWorktree` / `ExitWorktree` tool path, and Thomas removes worktrees with `git
worktree remove` in a Bash call. That is ordinary git, with nothing standing between the command
and the repo, so no event exists to fire. A hook bolted to an execution path nobody walks
through fires exactly as often as a broken one, and from the outside the two are
indistinguishable.

So manual cleanup remains required on every runtime, and the hook's command has to be kept safe
against the day it wakes (AST-115). The lesson outlives this particular hook: when a mechanism
does not fire, ask whether the trigger was reached before concluding the mechanism is broken.

## session-start

It fires immediately after a Claude Code session compacts, with `source: compact`, and it runs
`scripts/hook-contract-reload.py`.

The script re-arms exactly one thing: the path to the running role's contract, delivered through
`hookSpecificOutput.additionalContext`, reaching the agent before it acts.

The failure behind it is AST-069, and the one-line form is that an instruction with no moment
attached measures zero. The system prompt already says "Read `.agents/roles/<role>.md` now", and
that line comes through compaction untouched because it is the system prompt. What does not come
through is the word "now". A compacted agent reads its own summary, sees work underway,
concludes it is mid-session, and never re-reads. The instruction is present and inert.

Two details are deliberate. It fires on `compact` and not on `clear`, because after `/clear` an
agent faces an empty context and reads its contract unprompted, while after compaction it faces
a summary insisting work is underway and does not. That asymmetry is the entire defect. And it
is Claude Code only, because Codex and OpenCode have no compaction, so there is no moment to
attach to.

Every exit path in the script is either valid JSON on stdout or nothing at all, and none of them
raise. A traceback on stderr would be read by the runtime as a broken hook and disabled, and the
operator would carry on shipping a harness that looks armed.

## subagent-stop

It fires every time a subagent ends. There is no script of its own: the hook reads JSON from
stdin and appends a line to `/tmp/harness-hook-events.log`.

It records `agent_type`, `agent_id`, `session_id` and the payload size. That is all, and it
blocks nothing. The first version read the environment variables `$AGENT_NAME` and `$SESSION_ID`
and got empty strings back. The current one reads stdin and takes the right fields.

It is the cheapest of the four, and it returned the most value in a place nobody designed for.
It was the control group. The 27 events it logged in that window are what turned "nothing was
observed" into evidence that `WorktreeRemove` was dormant. Without them the same observation
would have been indistinguishable from "hooks are off entirely", and the first conclusion, that
the hook was broken, was reached without any control group at all.

Beyond that, it records the moment a Builder dies, which without a log shows up only as a silent
pane.
