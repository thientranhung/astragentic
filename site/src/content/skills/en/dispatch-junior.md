---
title: dispatch-junior
oneLiner: "Hand a ticket's typing to a junior pane on another runtime, then take the tree back for review, simplify and the arm."
group: main-flow
order: 4
runtimes: [claude]
source: harness/.agents/skills/dispatch-junior/SKILL.md
rented: false
lang: en
updated: 2026-10-17
---

## What it does

`dispatch-junior` is the Builder's recipe for handing the implementation of one ticket to a junior pane. The Builder commits the red tests, opens a pane beside itself in the same tab, launches the junior on the runtime its row names (Grok first), sends one brief, waits, and reads the tree back.

Only the typing moves. `atdd` and `tdd`, both reviews, simplify, the arm, the markers, the handback and the push stay the Builder's, run over the junior's commits exactly as over its own.

<!-- source: harness/.agents/skills/dispatch-junior/SKILL.md -->

## When the Builder reaches for it

| What is in front of you | Reach for |
|---|---|
| The `builder` row of `## Junior` in `orchestrator.md` names a runtime, and the red tests are committed | `dispatch-junior` |
| The row says `none`, or there is no row | Nothing: the Builder implements alone |
| The row names a runtime with no `junior-<runtime>.md` supplement in the worktree | Stop and tell Thomas |
| Thomas wants a junior | Not possible: Thomas never dispatches one, and a junior never reports to Thomas |

<!-- source: harness/.agents/skills/dispatch-junior/SKILL.md -->

## The shape of one handoff

1. **A pane in the Builder's tab**, split to the right, named `junior:<ticket-id>`. Its cwd is the Builder's worktree: one worktree, two writers in sequence, never at once.
2. **A launch whose flags come from the row.** Model and effort are read from the Junior row. The pane runs with `--always-approve` because nobody sits there to answer a prompt, and with a deny rule on `git push` that the runtime enforces itself.
3. **One brief, sent by name.** Ticket, criteria, the red tests and the exact command that runs them, the write-set, the read-only files, and the head before. A brief without the test command or the write-set is not sent.
4. **A wait on the watcher script.** The Builder does not edit the worktree while the junior holds it. The junior ends its turn with `JUNIOR-DONE` or `JUNIOR-BLOCKED`, and the Builder reads the pane for that line.
5. **A read-back before trust.** Every commit must carry an `Implemented-by:` trailer. A change outside the write-set, an edited red test or a touched base branch is a boundary break: the Builder takes the ticket back and notes it.
6. **A close at handback.** The Builder closes the pane it opened, and its return to Thomas carries one `Junior:` line.

<!-- source: harness/.agents/skills/dispatch-junior/SKILL.md -->

## What it leaves behind

| What happened | Where it lands |
|---|---|
| Who wrote the code | An `Implemented-by: <runtime>/<model>` trailer on each commit |
| That the junior finished | A last line `JUNIOR-DONE <ticket> head=<sha> tests=<pass or fail> changed=<n>` in the pane |
| A question the junior could not settle | `JUNIOR-BLOCKED <ticket> <why>`, answered in a follow-up brief |
| That a junior was used | `Junior: <runtime>/<model> — <n> commits <first>..<last>` in the handback, or `Junior: none` |

<!-- source: harness/.agents/skills/dispatch-junior/SKILL.md -->

## What is not enforced

The dispatch mod and its gates read the Builder's pane, not the junior's, and the project's git guard reads a Claude tool name. The junior's boundaries are therefore its own to keep, and the Builder's check is the log: a push, a base-branch checkout or a commit outside the write-set is visible there and ends the session.

<!-- source: harness/.agents/roles/junior-grok.md -->
