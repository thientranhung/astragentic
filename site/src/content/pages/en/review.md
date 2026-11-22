---
title: "Review"
description: "Every change is read from four sides before merge: three Claude lenses on the ticket, a model from another vendor, QA on the running product, and a slice gate once many tickets have merged."
harness: v6.1.19
source: "harness/.claude/skills/astra-review/SKILL.md, harness/.claude/skills/codex-arm/, harness/.claude/skills/astragentic-dispatch/agents/, harness/.agents/roles/builder.md, harness/.agents/roles/thomas.md, harness/scripts/check-simplify-markers.sh"
---

Review in Astragentic runs once per tier, in a fixed order, and leaves receipts the merge script can
check. No tier counts as run just because a handback says so.

## The order of Builder's phases is a rule, not a suggestion

The visual check changes code, so it runs before review. Review finds and reports, so it runs
before simplify. Simplify cleans up finished code, so it runs once, last.

| phase | skill | ends when |
|---|---|---|
| Build | `astra-implement-with-tdd` | each criterion has a test that was red and is now green |
| UI pass | `astra-ui audit` (UI tickets) | every changed surface has browser evidence |
| Review | `astra-review` | all three lenses ran, every finding verified and routed |
| Simplify | `simplify` | a `simplify(increment):` commit exists |
| Cross-vendor arm | `codex-arm` | an `arm(ticket):` receipt exists at head |

**Measurement.** Before the "simplify once, last" rule, 57 of 244 Builder sessions ran simplify two
to five times, for one rebase, one regenerated file or one folded line: about $335 in 14 days.

## `astra-review` runs three lenses at once, each in its own context

- **Correctness.** Claude Code's built-in `code-review`, run on the staged diff. It does not
  receive the ticket, and that is deliberate: it finds what is missing, not only what is wrong.
- **Intent.** A read-only subagent that receives exactly the ticket and the diff. For each
  criterion: which test proves it, whether that test runs, and whether the criterion is met on the
  right surface.
- **Standards.** A read-only subagent that receives the repo's coding standard and the diff. A
  violation cites the file and the rule; hard violations are separated from judgment calls.

The three lenses are launched in one message, before any result is read. A lens that fails is
reported as failed, never as clean.

### A fourth lens when no other vendor is available

When the ticket's arm is off or cannot run, `astra-review` adds an adversarial lens: the
`astra-adversarial-lens` subagent runs on Opus and reads the change to break confidence in it
rather than confirm it. This lens is not the arm and writes no arm receipt.

**Measurement.** Measured blind on seven replayed tickets: Opus found 13 real high or medium
defects at precision 0.71; Sonnet found 7 at precision 0.46. About 109k tokens per ticket.

## Every finding is checked at the code line before it gets a verdict

Findings are numbered `R1, R2…` per lens, not yet merged. For each finding, Builder reads the cited
line, including callers and guards: can that state occur, and is it unintended.

- **Verdict.** `high`, `medium`, `low`, `false` or `maybe false`, with exactly one sentence of
  evidence. Severity is the harm of one occurrence, not how rare it is or how costly the fix is.
- **Merge by root cause.** Remaining findings are grouped as `F1, F2…`. Intent and standards
  findings are never ranked against each other.
- **Route.** `patch` when the fix is unambiguous; `decision_needed` when the fix depends on the
  owner's intent; `defer` when the defect predates the change. A finding caused by the change itself
  and verified is never deferred.

## A model from another vendor re-reads the simplified tree

After simplify, Builder runs `codex-arm`: one read-only `codex exec` command, no Codex plugin
needed, model gpt-6.2-astra at medium effort. Tickets and slices are read with the edge lens; specs
with the adversarial lens. Findings are folded in, a second pass runs if the first one fixed
anything, then the `arm(ticket):` receipt is written at head.

The reason for another vendor: a model re-reading its own diff also re-reads its own assumptions.

**Measurement.** Measured blind on 7 replayed tickets, 72 runs, 336 findings:

| reader | real defects / run | precision | tokens |
|---|---|---|---|
| Codex, edge lens, gpt-6.2-astra | 21 | 0.77 | ~79k |
| Claude, adversarial lens, Opus | 13 | 0.71 | ~109k |
| Claude, adversarial lens, Sonnet | 7 | 0.46 | |

Of 34 real defects, the Codex cells together found 29 and the Claude cells found 17.

### Out of quota is NOT RUN, never a pass

When quota is exhausted, or there is no output matching the schema, the arm writes `NOT RUN` with
the reason. The ticket then falls back to the Opus adversarial lens above, recorded as same-vendor
and advisory only.

**Measurement.** Trial run with quota exhausted: exit 1, `NOT RUN — usage limit`, nothing counted
as a pass. A hostile `AGENTS.md` demanding "fix and commit" did not make the arm write into the
tree.

## Thomas merges on artifacts, not on handback wording

`check-simplify-markers.sh` runs on the SHA about to merge and refuses the merge when a full ticket
still owes a `simplify(increment)` or `arm(ticket)` receipt. A change that touches a user-visible surface or a public
endpoint gets a QA walk on the running product before merge, with a `qa(walk)` marker.

### A quick ticket runs only the built-in review

A ticket labelled `quick` runs no three lenses, no simplify and no arm, and owes no marker. The
label belongs to whoever cuts the ticket, not to Thomas.

## When a slice closes, Thomas reads the whole slice once more

Two reads on the base branch: the slice arm, and the `astra-slice-reviewer` subagent running in its
own worktree, read-only, hunting hidden assumptions, unguarded edge cases and removed behavior. This
pass sees contradictions between tickets that no per-ticket review can see. The result is folded in
and written on the `arm(slice):` marker.

**Cost.** More than 10 merges since the last `arm(slice)` is a STOP point.

## What is not yet measured

- **The lens at spec and slice scope.** Not yet measured; Codex quota is out from 2026-11-21 to
  2026-11-28.
- **6.1.18 and 6.1.19 on real projects.** Not yet measured. After about 10 tickets per project,
  any arm or lens that has found no real defect will be proposed for removal.
