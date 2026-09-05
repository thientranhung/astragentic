---
title: codex-arm
oneLiner: "Run a Codex pass over a finished artifact so a different vendor reads the diff before it merges."
group: gate
order: 1
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/codex-arm/SKILL.md
rented: false
diagram: cross-vendor-arm
lang: en
updated: 2026-09-04
---

## What it does

`codex-arm` is the invocation mechanics for the cross-vendor arm: the Codex review that Thomas,
or at ticket scope the Builder itself, runs over a completed artifact before it can merge. It
covers the runtime-specific command (`codex-companion.mjs` on a Claude root, `codex exec review`
directly on Codex or opencode), the argv and quoting traps, and where the verdict gets recorded.
It does not decide *when* to run. That cadence, and the two-pass cap, belong to `thomas.md` and
`builder.md`. This skill owns the how, not the when.
<!-- source: harness/.agents/skills/codex-arm/SKILL.md -->

The reason it exists: a same-vendor reviewer and a cross-vendor one catch different defect
classes, because the author reads the ticket and the arm reads the repository. This has been
measured directly. The first per-ticket arm run caught a destructive reset authorizing outside its
write transaction, something the author's own mutation-testing pass had missed. The very next
pass, over the fix for that finding, caught a real deadlock cycle the fix itself had introduced.
Skipping it would have shipped a production 500 on the only unstick path the product had.
<!-- source: harness/.agents/skills/codex-arm/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A ticket's diff is committed, root is Claude or the Builder is running its own ticket arm | `codex-arm` |
| Root runtime is Codex, a Claude pass is needed instead | `codex-claude-arm` (mirror skill; the arm always calls the *other* vendor) |
| A spec is finished, about to be cut into tickets | `codex-arm` at `arm: spec`, run by Thomas from the base checkout |
| A slice is closing | `codex-arm` at `arm: slice`, same as above |
| Rin's own gate needs to run | Not this skill. Rin never runs the arm from inside its own review |

<!-- source: harness/.agents/skills/codex-arm/SKILL.md -->

## Prerequisites

- The artifact under review is already committed. The arm reads a tree, not a working
  directory. <!-- source: harness/.agents/skills/codex-arm/SKILL.md -->
- At ticket scope, the Builder runs it from its own worktree, where `HEAD` already resolves to
  the reviewed commits. At spec or slice scope, Thomas resolves the head from a detached checkout
  at that SHA, because `--base` alone does not say which head the companion compares against.
  <!-- source: harness/.agents/skills/codex-arm/SKILL.md -->
- Focus text avoids every shell-special and glob-special character, not a fixed list. It is passed
  unquoted, word by word, so a naturally written phrase like `option (a)` never reaches the
  process; zsh's glob expansion kills the command at parse time.
  <!-- source: harness/.agents/skills/codex-arm/SKILL.md -->
- `codex exec review` accepts `-m <model>`; the bare `codex review` does not.
  <!-- source: harness/.agents/skills/codex-arm/SKILL.md -->

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The verdict | The merge decision trail: date, verdict, per-finding resolution, the vendor that ran |
| Whether tests ran | A `Tests:` line: `RAN` or `NOT RUN — <reason>` |
| The arm range | First line of output: commit and file count, so a 0-commit range cannot pass as clean |
| Codex unavailable | `cross-vendor arm: NOT RUN — <reason>`, which only the owner may accept |
| A gate worktree's resources | Released via `release-worktree-resources.sh` before removal, never after |

<!-- source: harness/.agents/skills/codex-arm/SKILL.md -->

## Known failures

Pulled from `harness/.agents/memory/recurring-failure-modes.md`. All entries below are marked
`promoted`: fixed and already in the contract this page describes.

- **AST-103**: the companion resolves `HEAD` from the checkout it runs in. Where that disagrees
  with `--base`, the run compares the base branch to itself and returns clean. Caught twice by
  the operator, not by the gate. Fixed: print the commit and file range as the first output line,
  stop on 0 commits.
- **AST-095**: the companion exits 0 on configuration failure and caches state keyed to the
  workspace root. Fixed: never branch on exit code, only on the output file's content; never
  reuse a gate worktree path.
- **AST-100**: every `codex-companion.mjs` call spawned a broker process that outlived the
  review, 92 orphans (~405 MB) measured across two projects. Fixed: kill the broker by real cwd
  before removing the gate worktree.
- **AST-115**: a project-level teardown target used as the release step stopped the shared
  test-database container every live Builder was standing on. Fixed: scope release to this
  worktree alone, or release nothing.
- **AST-016**: a read-only reviewer with shell access still moved another agent's `HEAD` via
  `git switch`. Fixed, and load-bearing for `codex-claude-arm`: `claude -p` is a full agent, so
  even the ticket-scope arm gets its own detached worktree.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- The first line of every arm run states the commit and file count of the range under review.
- A `Tests:` line is present and reads `RAN` or names why not.
- The recorded vendor in the merge trail matches the vendor that actually executed, and a
  same-vendor lens is never counted as the cross-vendor pass.
- No gate worktree survives past its review. Resources are released before removal, on every path.
- A blocking finding from pass 1 gets a pass 2 over the fix, not a judgement call that it can be
  skipped.

<!-- source: harness/.agents/skills/codex-arm/SKILL.md -->

## Where it fits

A Builder's closed loop runs `implement` → review → simplify → `codex-arm` (ticket scope) →
`arm(ticket):` receipt → handback, and `/skills/dispatch-ticket`'s cleanup checks that receipt
before removing the worktree. At spec and slice scope, Thomas runs it from the base checkout
before releasing a paused `shaper` or closing a slice. `codex-claude-arm` mirrors it for a Codex
root: same cadence, opposite vendor. Neither substitutes for `/skills/review-with-rin`, which is
the gate itself rather than the pass feeding it.
