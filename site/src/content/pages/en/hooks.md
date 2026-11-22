---
title: "Hooks"
description: "Six Claude Code hook event types, seven commands, plus one mod. The hooks block wrong git commands, record test runs, reload the contract after compaction, inject tracker status at session start, log subagents and release worktree resources."
harness: v6.1.19
source: harness/.claude/settings.json, harness/scripts/hook-git-guard.py, harness/scripts/hook-test-run.py, harness/scripts/hook-contract-reload.py, harness/scripts/hook-tracker-status.py, harness/scripts/release-worktree-resources.sh, harness/.claude/skills/astragentic-dispatch/hooks/register.tsx
---

`harness/.claude/settings.json` registers 6 Claude Code hook event types, 7 commands in total. The `astragentic-dispatch` mod registers its own events on top.

A hook always comes after the contract. A rule that matters has to live in the contract, because a hook can be disabled or untrusted. Each command below is a file you can run by hand, and the command in `settings.json` only calls that file.

## pre-tool-use

One command runs `scripts/hook-git-guard.py` before every `Bash` tool call. The script denies a git command that could destroy someone else's work, or says nothing.

It denies with the exact command to run instead, and it never acts. `PreToolUse` runs while permission is still being decided, so anything it changed would be a side effect of a command that may yet be refused.

- **Staging.** `git add -A` and `git add .` without a pathspec are denied, with the list of changed files so the next attempt stages by path.
- **Worktree.** `git worktree add` needs an absolute path. `git worktree remove` is denied while the worktree has uncommitted changes, while its resources are not released, or while a process still has its real cwd inside it.
- **Read-only role.** A BA pane runs no command that writes to the repository. A Quick Builder pane is limited to an `ops/<slug>` branch, a `--ff-only` merge and the push of that branch.
- **Push.** A push that lands merges with no `ticket-done` evidence or no `Ledger:` line is denied. The same rule also lives in `scripts/pre-push-ticket-done.sh`, which runs as git's `pre-push` hook.

The script tokenises and inspects argv instead of matching a regex on the raw command string. The first regex version let `/usr/bin/git add -A` through and blocked a `printf` that merely contained those words.

**Measurement.** On one day's log, 84 of 319 commands (26%) held a heredoc, a `$(...)` or a `( ... )` and were not read. After ignoring a `(` inside a quoted string, 13 of the 20 base pushes that had gone unjudged carried only that character in an `echo`. For staging, 71 of 167 refusals were followed by the identical command retyped, so since 4.1.0 a refusal lists the paths.

**Cost.** This is a lint against accidents, not a boundary. Three adversarial gates each found a way through. The script accepts one shape, simple commands separated by unquoted operators, and stays silent on a heredoc, substitution, comment, wrapper or interpreter. A junior pane on another runtime sends a different tool name, so the hook never sees its commands.

## post-tool-use

Two commands run `scripts/hook-test-run.py`: one on `PostToolUse` and one on `PostToolUseFailure`, both with matcher `Bash`. The script appends every test run to `/tmp/harness-test-runs/<git toplevel>.log`, one line each with the time, the exit status and the first 200 characters of the command.

It exists because the commit gate needs to know whether a test went red before the first content commit. A skill call is only a line in a record, while a red run is what TDD demands. The mod cannot see a tool's result because its events fire before the call, so the hook writes the status and the mod reads the file.

Two statuses are never counted as 0:

- **`background`.** A command launched in the background has no exit code yet. The hook tells the pane to run the test in the foreground before the first commit.
- **`masked`.** The test is followed by `;`, `|`, `||` or a newline, so the exit code the tool reports belongs to the next command. The hook tells the pane to run the test alone.

What counts as a test is set by `.astraler/project/test-command-pattern`, or by a default list covering `go test`, `pytest`, `vitest`, `jest`, `cargo test`, `npm test` and other common runners.

**Measurement.** In 14 days to 2026-10-26, 61 of 161 downstream tickets wrote code first and called the tdd skill afterwards, and 15 never called it. Release 4.5.2 registered only `PostToolUse`, but a command that exits non-zero goes to `PostToolUseFailure`, so no red run was ever logged and every honest Builder was refused at its first commit. 4.5.3 registers both events.

**Cost.** The hook recognises only runners that match the pattern. A project with another runner adds one line to the plug.

## session-start

Two commands fire on `SessionStart`, one with matcher `compact` and one with no matcher.

`scripts/hook-contract-reload.py` fires after a session compacts, with `source: compact`. It re-arms the path of the role's contract through `hookSpecificOutput.additionalContext`, before the agent acts.

The contract lives in `.agents/roles/<role>.md` and enters the conversation as a Read tool result, which compaction summarises first. What survives is the system prompt, with its four rules. The line "read the contract now" in the system prompt survives, but the word "now" does not: the agent reads a summary that reports work in progress and concludes it is mid-session.

The hook fires on `compact` and not on `clear`. After `/clear` the agent faces an empty context and reads the contract itself. Every exit path of the script prints valid JSON or nothing, because a traceback on stderr makes the runtime treat the hook as broken.

`scripts/hook-tracker-status.py` fires at the start of every session. It runs the project's `.astraler/project/tracker-status.sh` plug, or `scripts/tracker.sh counts` for a project that declares a `jira <KEY>` tracker, and puts the counts in context. With the counts already in context, reporting status costs nothing and leaving it out is visible. A missing plug produces one note, and output is cut at 4,000 characters with a statement that it was cut.

**Measurement.** In one long session that compacted once, the four rules in the system prompt were obeyed all session and every rule outside it was violated.

**Cost.** The hook only works on Claude Code. The tracker hook only reads; if a mirror needs a push, the role's contract says so.

## subagent-stop

The hook fires every time a subagent finishes. The command is inline in `settings.json`: it reads JSON from stdin and appends one line to `~/.local/state/astragentic/harness-hook-events.log` with `agent_type`, `agent_id`, `session_id` and the payload size. `HARNESS_HOOK_LOG` changes the path.

It blocks nothing. The log is shared by the whole machine: the git guard, both `SessionStart` hooks, `tracker.sh` and the mod all write to it. Since 6.1.8 it lives outside `/tmp`, because `/tmp` is emptied at boot and the log's counts began at the last restart.

**Measurement.** The number of `SubagentStop` events per day is not measured (chưa đo).

**Cost.** It is the cheapest of the seven commands, and it only records. It says a subagent stopped, not whether the work was right.

## worktree-remove

The hook runs `scripts/release-worktree-resources.sh` with `$WORKTREE_PATH` when Claude Code removes a worktree, and writes a line to the hook log.

The script releases what a worktree allocated, in order. First comes what the harness knows: processes whose real cwd is inside the worktree, reaped by `reap-worktree-processes.sh`. Then comes what the project declares, through the `.astraler/project/cleanup-worktree.sh` plug.

The order is load-bearing. A resource bound to a directory by cwd or by a name derived from its path cannot be matched once the directory is gone, so this runs before `git worktree remove`. The plug must scope to that worktree only. A missing plug is reported as empty, because a silent no-op is indistinguishable from a successful release.

Thomas removes worktrees with `git worktree remove` in a Bash command. That path has two backstops: the git guard refuses while resources are unreleased, and the mod runs this script first on a recorded, clean worktree whose agent is not mid-turn.

**Measurement.** Before the harness had a plug, one downstream night left 43 orphaned processes, 3,405 databases (25 GB), a load average of 123, and the OS killed one Builder.

**Cost.** Whether the `WorktreeRemove` event fires when a worktree is removed with a bare `git worktree remove` is not measured (chưa đo). The two backstops above stay for that reason.

## mod

The `astragentic-dispatch` mod (v1.0.3) is a Claude Code plugin at `harness/.claude/skills/astragentic-dispatch/hooks/register.tsx`. It replaces three dispatch steps that a dispatcher kept forgetting with something the panes do themselves.

- **Record.** A pane whose tab label is `ticket:`, `spec:`, `qa:` or `resident:` writes its own tab and pane ids into `.astraler/state/dispatch-record.json` at session start.
- **Brief.** A message from the dispatcher becomes a real user turn: a first line starting with `/` runs through `$.command.run`, anything else through `$.prompt.submit`. The pane answers `RECEIVED` at once.
- **TURN-END.** When the turn the dispatcher started ends, the pane sends `TURN-END` with its last words, and the dispatcher's copy of the mod wakes the dispatcher.

The mod registers the events `session.start`, `turn.start`, `turn.complete`, `prompt.compose`, `prompt.submit`, `session.send`, `session.receive`, `skill.prompt`, `tool.call` and `ui.render`, and two commands, `dispatch-board` and `tracker-refresh`. Since 4.6.1 it refuses `ScheduleWakeup` in a dispatched pane, and it refuses an `herdr` command in an Orca session and an `orca` command in a Herdr session.

**Measurement.** From turn end to dispatcher wake is under 1 second, against the 67-second gap of polling pane state.

**Cost.** TURN-END is a bell, not proof. It says a turn ended, not that the work is right, so Thomas still verifies by artifact. The mod dies with its pane, so it cannot report a pane that died.
