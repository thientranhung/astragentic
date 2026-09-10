---
title: "Tech stack"
description: "Nine components in the stack, and why each one rather than something else. Each with the place it has already caused a failure."
---

This list is deliberately short. Every component on it has to answer "what breaks if you take it
out," and any component that only causes minor inconvenience when removed is already gone. The
first three are runtimes, the middle three are mechanisms, and the last three are what I wrote
myself or picked to build this site.

## claude-code

The root runtime. All five roles run here, and `claude --dangerously-skip-permissions --agent thomas --model claude-opus-5 --effort medium` is the line that opens a
session. If you install exactly one runtime, make it this one.

It is also where I put the two most important hooks, because the two mechanisms I need only
exist here. The first is the split between system prompt and contract:
`.claude/agents/<role>.md` is the system prompt and survives compaction, while
`.agents/roles/<role>.md` enters the session as a tool result and is the first thing compaction
summarises away. The second is compaction itself: Codex and OpenCode have no such mechanism, so
`hook-contract-reload.py` is registered on Claude Code only, and that is a deliberate decision
rather than an oversight.

## codex

An optional runtime, and the reason it is here is the cross-vendor arm. Without a second vendor
that arm does not exist, and the arm has the highest measured defect yield in this system.

Three directories carry the Codex half: `.codex/profiles/` holds the pane-launch templates per
role, `.codex/agents/` holds two read-only helper agents, and `.codex/hooks.json` registers the
git guard. Watch the last one: Codex reviews project-local hook definitions by hash, so without
a trust decision the guard sits there looking installed and gets skipped. The doctor checks
registration; confirming trust means typing `/hooks` in the Codex CLI.

## opencode

The third runtime option for role dispatch, with adapters in `.opencode/agents/`. It exists so
`.agents/orchestrator.md` is not pinned to a single vendor.

I will state plainly where it is weaker than the other two: an OpenCode Builder has no
equivalent of `hook-git-guard.py`. That is one of the two reasons the cleanup-ordering rule has
to live in `dispatch-ticket/CLEANUP.md` first and in a hook second. The other reason is that
Claude and Codex can both run with hooks disabled.

## git-worktree

This is the real isolation boundary, and it is git rather than a house rule. One checkout per
ticket at `.claude/worktrees/<branch-slug>`, an absolute path inside the repo, created with `git
worktree add -b <ticket-branch> <worktree-path> <base>`. The Builder is the sole writer in
there. Thomas, Rin and another Builder all read, and none of them write.

The part that is easy to get wrong is what a worktree actually holds. It holds tracked git
content and nothing else: it does not isolate a database container, a background process, or
anything a tool writes to a fixed path outside the checkout. Removal is `git worktree remove`,
never `rm -rf`. A raw delete leaves the registration behind in `.git/worktrees/`, and the next
`add` at that path refuses.

## herdr

The terminal workspace manager, floor `>= 0.8.0`. It gives every agent a pane you can open and
look at, and it lets you prompt, wait on and read each one. This is what turns dispatch from
something narrated into something countable.

`dispatch-ticket` refuses to dispatch unless `herdr-watchdog.sh` is running, and it checks at
the first dispatch. Here is what I had to learn twice: AST-107 showed that `herdr agent wait`
cannot be trusted for the verdict. Now `herdr-watch-terminal.sh` waits in 60-second slices and
takes the verdict from a fresh `herdr agent get` on every slice, with the wait demoted to an
interruptible sleep. Worst-case detection lag is 60 seconds rather than the whole session.

## mattpocock-skills

The entire craft layer is rented from here, floor `>= 1.2.3`, installed as a plugin.
`wayfinder`, `grill-with-docs`, `to-spec`, `to-tickets`, `implement` and `code-review` are the
user-invoked steps; `grilling`, `tdd`, `codebase-design`, `domain-modeling`, `research`,
`prototype`, `diagnosing-bugs`, `wizard` and `resolving-merge-conflicts` are the craft layer the
model reaches for on its own.

The benefit of installing it once is that the whole team gets the craft, because model-invoked
skills need no wiring. The cost is that `check-requirements.sh` fails hard without it, and the
address `/mattpocock-skills:<name>` is spread across every contract. Changing method means
rewriting contracts, not editing one config line.

## trackers

Astragentic ships no tracker. It ships three adapters, `github-issue-tracker`,
`jira-issue-tracker` and `linear-issue-tracker`, each describing how to drive exactly one
backend: how status is represented, where the claim is written, how a blocking edge is
expressed.

What is fixed is not the adapter but `.agents/tracker-contract.md`: the five things the pipeline
needs of any tracker. So Thomas reads `docs/agents/issue-tracker.md`, learns which adapter this
project uses, and drives it identically regardless of backend. The cost is stated on the why
page: every backend brings its own traps, and GitHub Issues has no real status field, so status
has to live in a label.

## scripts

The Python and Bash I wrote myself. Three scripts stand for three kinds: `hook-git-guard.py` is
a blocking layer running while permission is still being decided; `herdr-watchdog.sh` runs in
the background all session and has to be alive before any dispatch; `ledger-index.sh` runs after
the payload changes, not after work happens.

The rule I took from it: every script needs a calling moment and an owner. A script missing
either one is a script nobody runs until something has already gone wrong. Release 2.5.0 is the
evidence against: it shipped adapters naming another project's real ticket ids, a stale index,
and two contracts over their word budget. Three classes of defect, none of them visible by
reading, all introduced by careful work an hour earlier. Release 2.5.1 is exactly those three
fixes and nothing else.

## archify

Every diagram on this site is built with `archify`. The source is JSON at
`content/site/diagrams/<slug>.<type>.json`, and the output is standalone HTML with inline SVG,
so one diagram is both clickable in the page and readable outside it.

I chose to describe diagrams as data rather than draw them because this site is bilingual. Each
diagram has a translation at `content/site/diagrams/vi/` covering the title, labels, edge
labels, lane names and notes, while role names, skill names, commands, AST ids and filenames
stay as they are. Drawn by hand twice, the two copies diverge on the third edit.
