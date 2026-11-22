---
title: "Tech stack"
description: "Eight components in the stack: Claude Code, the Claude Code techniques in use, Codex, Herdr, Orca, git worktree, tracker adapters and diagram-design. Each states what it is, why I chose it, the mechanism and the cost."
harness: v6.1.19
source: README.md, harness/.claude/settings.json, harness/.claude/agents/, harness/.claude/skills/astragentic-dispatch/hooks/register.tsx, harness/.claude/skills/dispatch-ticket-claude/SKILL.md, harness/.claude/skills/codex-arm/SKILL.md, harness/.claude/skills/astra-review/SKILL.md, harness/.agents/orchestrator.md, harness/scripts/herdr-watch-terminal.sh, runtimes/codex/README.md
---

Each component here has to answer "what breaks if I remove it". A component whose removal causes only a small inconvenience I left out. The first two are the main runtime, the next two are the second runtime and the terminal hosts, and the rest are shared mechanisms.

## claude-code

Claude Code is the runtime for all six roles. Each role is a custom agent in `harness/.claude/agents/`, and the router starts with `claude --dangerously-skip-permissions --agent thomas --model claude-opus-5 --effort medium --advisor fable`.

I chose it because three mechanisms need runtime support:

- **Custom agent.** `.claude/agents/<role>.md` is the role's system prompt and survives compaction. The full contract in `.agents/roles/<role>.md` enters the session as a tool result.
- **Hook.** 6 event types, 7 commands in `settings.json`: git guard, test-run record, contract reload after compaction, tracker status, subagent log, worktree release. Details are on the hooks page.
- **Mod.** The `astragentic-dispatch` plugin (v1.0.3) does the dispatch steps a dispatcher kept forgetting: it writes the record, turns a brief into a user turn, sends `TURN-END`, and checks the tracker before a brief.

**Cost.** Hooks and the mod only work on Claude Code. Another runtime receives the contract through its own overlay, as Codex does in the section below, and does not receive this lane's hook mechanism.

## claude-techniques

The Claude Code features below are used in the harness, and each has a place in the payload.

- **Subagent review.** The plugin has 4 subagents: the adversarial lens, the slice reviewer, the test architect and the UI lens. `astra-review` runs three lenses at once, each in its own context: correctness through the built-in `code-review`, intent through a subagent that reads the ticket and criteria, standards through a subagent that reads the repository's coding standards.
- **Built-in `code-review` and `simplify`.** The harness does not rewrite these two steps. Simplify runs once, after the last content commit.
- **Advisor.** The Advisor column in `.agents/orchestrator.md` sets the `--advisor` flag: an Opus row takes `fable`, a Sonnet row takes `opus`, blank means none. The advisor must rank at or above the main model.
- **`--effort`.** Added only when the orchestrator row sets a `low|medium|high|xhigh|max` value.
- **Auto-compact window.** `CLAUDE_CODE_AUTO_COMPACT_WINDOW` sets the context ceiling for a dispatched pane, and `dispatch-ticket-claude` passes the same value through `--autocompact 300000`.
- **SendMessage and ListAgents.** Sessions talk to each other across sessions, and the mod turns a dispatcher's message into a real user turn.
- **Monitor.** The Herdr lane's watcher wraps `herdr agent wait` in a Monitor. The Claude lane drops that step because the mod sends `TURN-END`.

**Measurement.** Simplify ran 2 to 5 times in 57 of 244 Builder sessions, about $335 over 14 days, so it now runs once at the end. One downstream project's Builders held a median 400–550k tokens of context per call, and the 300k ceiling makes a pane compact after about 170 calls instead of letting context grow.

**Cost.** I only use features that exist in the payload. A new Claude Code feature that has not entered the harness does not count. Code Mode is off and is not part of the stack.

## codex

Codex CLI is the second runtime in two different ways. The first is the cross-vendor arm: one direct, read-only `codex exec` with no Codex plugin, on model `gpt-6.2-astra` at medium effort. The second is the Codex v6 overlay, where the whole set of roles runs on Codex.

The arm uses a second vendor because a model re-reading its own diff re-reads its own assumptions. Ticket and slice read with `edge-lens.md`, and spec reads with the adversarial lens. The Codex plugin is no longer used as of 6.1.19 because it allowed no effort setting or lens of ours, leaked a broker per pass and exited 0 on a configuration failure.

The Codex overlay lives in `runtimes/codex/` and does not replace the Claude payload. It has its own roles in `.codex/roles/`, 20 `codex-*` entrypoints, a host guard, a coordinator Stop hook and a TURN-END bell. The Claude lane is the reference: a Codex rule is diffed against Claude before it changes.

**Measurement.** A blind measurement over 7 replayed tickets and 336 findings: Codex with the edge lens found 21 real defects per run at 0.77 precision and about 79k tokens. Codex found 29 of 34 real defects and Claude 17. The arm shrank from 2,893 to 1,553 words in 6.1.19.

**Cost.** When the quota runs out or the output fails the schema, the arm reports `NOT RUN` with the reason, never counts as a pass, and the ticket falls back to the Opus adversarial lens. The spec and slice lenses are not measured (chưa đo), because the Codex quota is out until 2026-11-28.

## herdr

Herdr is the default terminal host, minimum version 0.8.0. Each agent gets a visible pane, and Thomas nudges, waits on and reads each pane. Work in flight becomes something you count instead of guess.

The `herdr-watch-terminal.sh` watcher waits in slices and takes the verdict from a fresh `herdr agent get` on each slice. A long `herdr agent wait` was once alive and deaf (AST-107), so the wait is reduced to an interruptible sleep. `herdr-watchdog.sh` runs in the background and polls every 300 seconds by default, and the preflight of `dispatch-ticket` at the session's first dispatch requires the watchdog to be running.

**Measurement.** Polling pane state left a 67-second gap between a pane going idle and the dispatcher knowing. The mod's bell cuts it to under 1 second.

**Cost.** Status is a bell, not proof, so Thomas still verifies by artifact. One host per session: an `orca` command in a Herdr session is refused.

## orca

Orca is the second terminal host, from 6.1.0. A session opened in Orca dispatches only through Orca, and an `herdr` command in that session is refused. A pane writes its record from the `ORCA_*` environment and `ASTRA_DISPATCH` in the launch command.

The mod recognises the host from the pane's environment: `ORCA_PANE_KEY` present means Orca. The record, the brief and the `TURN-END` bell work the same way as on Herdr. `orca terminal close` on a pane that is mid-turn is refused.

**Cost.** The mod refuses cross-host commands. An Orca terminal that shows `connected: false` is treated as gone, while `orphaned: true` alone is a live PTY with no UI pane.

## git-worktree

A worktree is the real isolation boundary, and it is git rather than a house rule. Each ticket gets its own checkout, created with `git worktree add -b <ticket-branch> <worktree-path> <base>` and an absolute path. The Builder is the only writer in it.

A worktree holds the tracked git content and nothing else:

- **Database containers.** Not isolated.
- **Background processes.** Not isolated.
- **Fixed paths outside the checkout.** Not isolated.

What is not isolated is the job of the `WorktreeRemove` hook and the project's `cleanup-worktree.sh` plug. Remove with `git worktree remove`, never `rm -rf`, and the git guard refuses `rm -rf` on a worktree path.

**Measurement.** One night without a release step left 43 orphaned processes, 3,405 databases (25 GB) and a load average of 123.

**Cost.** Each worktree is a full checkout, so disk and runtime have to be handled separately. The tips page describes how.

## trackers

Astragentic does not ship a tracker. It ships three adapters, `github-issue-tracker`, `jira-issue-tracker` and `linear-issue-tracker`, and each describes how to operate exactly one backend: how status is represented, where the claim is written, how a blocking edge is expressed.

What stays fixed is not an adapter but `.agents/tracker-contract.md`: what the pipeline needs from any tracker. Thomas reads `docs/agents/issue-tracker.md`, learns which adapter the project uses, and then acts the same way regardless of backend. The tracker is the shared memory: what is ready to do is a query.

**Cost.** Each backend carries its own trap. GitHub Issues has no real status field, so status lives in a label.

## diagram-design

The site's own figures are drawn with the `diagram-design` plugin. The Vietnamese serif font is Newsreader, because the plugin's default Instrument Serif has no Vietnamese diacritics. Each figure is one HTML file with embedded SVG, with a `vi` version and an `en` version.

The site is bilingual, so only labels are translated. Role names, skill names, commands and file names stay as they are.

**Cost.** The figure pipeline is still moving to this plugin. The number of figures already redrawn is not measured (chưa đo).
