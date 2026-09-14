---
title: "Tech stack"
description: "Nine components in the stack, and why each one rather than something else. Each with the place it has already caused a failure."
---

This list is deliberately short. Every component on it has to answer "what breaks if you take it
out," and any component that only causes minor inconvenience when removed is already gone. The
first three are runtimes, the middle three are mechanisms, and the last three are what I wrote
myself or picked to build this site.

## claude-code

The root runtime. Agents in all five roles run here, and `claude --dangerously-skip-permissions --agent thomas --model claude-opus-5 --effort medium` is the line that opens a
session. If you install exactly one runtime, make it this one.

It is required because two mechanisms only exist here:

- **System prompt split from contract.** `.claude/agents/<role>.md` is the system prompt and
  survives compaction, while `.agents/roles/<role>.md` enters the session as a tool result and is
  the first thing compaction summarises away.
- **Compaction itself.** Codex and OpenCode have no such mechanism, so `hook-contract-reload.py`
  is registered on Claude Code only, and that is a deliberate decision rather than an oversight.

## codex

An optional runtime, here for the cross-vendor arm. Without a second vendor that arm does not
exist, and the arm has the highest measured defect yield in this system.

Three directories carry the Codex half:

- **`.codex/profiles/`.** The pane-launch templates per role.
- **`.codex/agents/`.** Two read-only helper agents.
- **`.codex/hooks.json`.** Registers the git guard.

The limit is in the last one: Codex reviews project-local hook definitions by hash, so without a
trust decision the guard sits there looking installed and gets skipped. The doctor checks
registration; confirming trust means typing `/hooks` in the Codex CLI.

## opencode

The third runtime option for role dispatch, with adapters in `.opencode/agents/`. It exists so
`.agents/orchestrator.md` is not pinned to a single vendor.

The limit: an OpenCode Builder has no equivalent of `hook-git-guard.py`. That is one of the two
reasons the cleanup-ordering rule has to live in `dispatch-ticket/CLEANUP.md` first and in a hook
second. The other reason is that Claude and Codex can both run with hooks disabled.

## git-worktree

This is the real isolation boundary, and it is git rather than a house rule. One checkout per
ticket at `.claude/worktrees/<branch-slug>`, an absolute path inside the repo, created with `git
worktree add -b <ticket-branch> <worktree-path> <base>`. The Builder is the sole writer in
there. Thomas, Rin and another Builder all read, and none of them write.

The part that is easy to get wrong is what a worktree actually holds. It holds tracked git
content and nothing else:

- **A database container.** Not isolated.
- **A background process.** Not isolated.
- **A fixed path outside the checkout.** Anything a tool writes there is not isolated either.

Removal is `git worktree remove`, never `rm -rf`. A raw delete leaves the registration behind in
`.git/worktrees/`, and the next `add` at that path refuses.

## herdr

The terminal workspace manager, floor `>= 0.8.0`. It gives every agent a pane you can open and
look at, and it lets you prompt, wait on and read each one. This is what turns dispatch from
something narrated into something countable.

**And it is the one channel that does not care which vendor you are on.** Two Claude Code
sessions already have cross-session messaging, but that channel exists only inside one vendor.
When Thomas runs on Claude, a Builder on Codex and a QA on OpenCode, three processes from three
vendors share no protocol at all. herdr does: the pane is the address, `herdr pane run` is send,
`herdr pane read` is receive. Thomas drives a Builder on Codex with the same commands it uses for
a Builder on Claude — which is what keeps "one process, several runtimes" from being a slogan.

**One measured trap when reading a pane:** the read is truncated and says nothing about it. When
you need a long output verbatim, do not trust the pane read — have the agent write a file and
read the file. A short read looks exactly like a complete one.

`dispatch-ticket` refuses to dispatch unless `herdr-watchdog.sh` is running, and it checks at the
first dispatch. The limit I had to learn twice: `herdr agent wait` cannot be
trusted for the verdict. Now `herdr-watch-terminal.sh` waits in 60-second slices and takes the
verdict from a fresh `herdr agent get` on every slice, with the wait demoted to an interruptible
sleep. Worst-case detection lag is 60 seconds rather than the whole session.

**The watchdog, and the question that is harder than it looks: is it alive.** Measured on a live
project, one instance did all three at once: it was in `ps`, its own pid file had been deleted
while it kept running, and a permanent child process made "has a child" true whether the loop was
working or wedged. **None of those three can go false when the loop hangs.** What can is a
timestamp that only advances when the loop **completes a pass** — that is the heartbeat file.
Check its `mtime`, not its presence.

**And do not wrap it in anything.** Launch it as `nohup … &` with nothing else in the pipeline.
Isolating it into its own process group protects it from a signal sent to the caller's group; it
does nothing against a signal sent straight to its PID, which is exactly what a wrapper with a
timeout does when that timeout fires. Measured: a watchdog launched from inside a tool call that
later timed out exited within the same second — **cleanly, and with nothing in the log to say
why**, because from the log alone a clean exit and a kill look identical. After launching,
confirm with `ps -o ppid= -p <pid>` reading `1`; a live PID with no error printed is **not** the
same claim as "detached and still running".

**`/loop` — the cadence that means nobody has to sit and watch.** The watchdog catches a dead
pane. There is one state it cannot catch, because from outside it looks perfectly healthy:
**nothing is happening at all** — the last ticket merged, no pane failed, and nobody picked up
anything new. Claude Code's `/loop` puts a fixed cadence on Thomas's own session, and each tick
is a real model pass rather than a shell cron:

```
/loop 12m Thomas: are the agents still active? Make sure monitoring and watching remain
healthy. When the tickets run out, proactively pick a new ticket and continue. Only stop
when there are no tickets left to pick up AND no pane is running AND nothing is waiting
to be merged. If Thomas's context is above 80%, proactively compact it.
```

Three things worth knowing before setting a cadence. **The floor is 60 seconds** — `15s` is
rounded up to `1m`. Below `5m` most ticks produce no meaningful change while still spending a
full model pass, and dead panes are already caught by `herdr-watchdog.sh` on its own 300-second
interval — the two watch different failures, so do not make one carry the other's job. And **in
cron mode Thomas cannot stop by itself**: if you want it to stop for real, the stop condition has
to come with an instruction to remove the cron job.

## mattpocock-skills

The entire craft part comes from here, minimum version `>= 1.2.3`, installed as a plugin.

- **User-invoked steps.** `wayfinder`, `grill-with-docs`, `to-spec`, `to-tickets`, `implement`,
  `code-review`.
- **Craft the model reaches for on its own.** `grilling`, `tdd`, `codebase-design`,
  `domain-modeling`, `research`, `prototype`, `diagnosing-bugs`, `wizard`,
  `resolving-merge-conflicts`.

The benefit of installing it once is that the whole team gets the craft, because model-invoked
skills need no wiring.

**Trade-off.** `check-requirements.sh` fails hard without it, and the address
`/mattpocock-skills:<name>` is spread across every contract. Changing method means rewriting
contracts, not editing one config line.

## trackers

Astragentic ships no tracker. It ships three adapters, `github-issue-tracker`,
`jira-issue-tracker` and `linear-issue-tracker`, each describing how to drive exactly one
backend: how status is represented, where the claim is written, how a blocking edge is
expressed.

What is fixed is not the adapter but `.agents/tracker-contract.md`: the five things the pipeline
needs of any tracker. So Thomas reads `docs/agents/issue-tracker.md`, learns which adapter this
project uses, and drives it identically regardless of backend.

**Trade-off.** Stated on the why page: every backend brings its own traps, and GitHub Issues has no
real status field, so status has to live in a label.

## scripts

The Python and Bash I wrote myself. Three scripts stand for three kinds:

- **`hook-git-guard.py`.** Blocks while permission is still being decided.
- **`herdr-watchdog.sh`.** Runs in the background all session and has to be alive before any
  dispatch.
- **`ledger-index.sh`.** Runs after the payload changes, not after work happens.

The rule I took from it: every script needs a calling moment and an owner. A script missing
either one is a script nobody runs until something has already gone wrong.

**Trade-off.** Release 2.5.0 is the evidence against: it shipped adapters naming another project's
real ticket ids, a stale index, and two contracts over their word budget. Three classes of
defect, none of them visible by reading, all introduced by careful work an hour earlier. Release
2.5.1 is exactly those three fixes and nothing else.

## archify

Every diagram on this site is built with `archify`. The source is JSON at
`content/site/diagrams/<slug>.<type>.json`, and the output is standalone HTML with inline SVG,
so one diagram is both clickable in the page and readable outside it.

Diagrams are described as data rather than drawn by hand, because this site is bilingual. Each
diagram has a translation at `content/site/diagrams/vi/` covering the title, labels, edge
labels, lane names and notes, while role names, skill names, commands, AST ids and filenames
stay as they are. Drawn by hand twice, the two copies diverge on the third edit.
