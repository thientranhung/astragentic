---
title: legacy-testing
oneLiner: "Pin what untested code does today, cut a seam into it, and only then let TDD start."
group: brownfield
order: 1
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/legacy-testing/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

`legacy-testing` is the doctrine for the case `tdd` does not cover. `tdd` writes a failing test
first, and that assumes a **seam**, a place where you can substitute what the code depends on.
Existing code often has none: the function reaches straight for the clock, the network, the
database, or a module-level singleton. This skill fixes the order for that case, and it is the
opposite of greenfield: characterise what the code does now, create a seam, then run `tdd`
normally with the characterisation tests as the net underneath.
<!-- source: harness/.agents/skills/legacy-testing/SKILL.md -->

The problem it removes is a Builder stalling on a ticket with nothing to write a test against,
along with the two wrong exits from that stall. The first is a characterisation test that asserts
what the code *should* do: it fails on day one and tells you nothing about what is safe to change.
The second is worse and quieter, because a test that silently blesses a bug as intended is how a
bug becomes a requirement. The discipline is a comment: assert the surprising value anyway, then
mark it pinned-but-unjudged with a ticket reference, which keeps both readings alive. This skill
is also why I treat brownfield as the default rather than the special case. Upstream agent skills
assume a seam exists, and most repos that arrive do not have one.
<!-- source: harness/.agents/skills/legacy-testing/SKILL.md, README.md -->

## When Thomas reaches for it

Thomas rarely reaches for this one directly. It is **model-invoked craft**, reached when the
situation arises, and it needs no wiring at adoption beyond confirming it is staged.

| What is in front of you | Reach for |
|---|---|
| The code under a ticket has no seam to test through | `legacy-testing`, from the Builder's own contract |
| A test would require the whole system to boot | `legacy-testing`: characterise the paths the change touches, seam the rest |
| A seam is too large to create inside one ticket | Hand back to Thomas, who routes it to a Shaper; `codebase-design` is the vocabulary for that conversation |
| The blast radius keeps growing as you read | Not this one. `untangle` is the path when the tangle itself is the problem |
| A refactor where module boundaries already exist | `mattpocock-skills:improve-codebase-architecture`, which already has something to work with |

<!-- source: harness/.agents/roles/builder.md, harness/.agents/roles/shaper.md, harness/.agents/skills/legacy-testing/SKILL.md -->

## Prerequisites

- Coverage data, before you pick inputs. Characterisation inputs are chosen **by coverage, not by
  intuition**: aim them at the branches the change will touch. Characterising a whole file is
  rarely worth it, and characterising the paths your change can break always is.
- A ticket id to reference from the pinned comments, since a pinned bug is a ticket later rather
  than a deletion.
- The knowledge that a large seam is not the Builder's decision. A parameter added to one function
  is the Builder's. A new interface several modules will depend on shapes the module boundaries,
  and that belongs where the whole picture is in context.

<!-- source: harness/.agents/skills/legacy-testing/SKILL.md -->

## What it leaves behind

| What happened | Where it lands |
|---|---|
| Current behaviour, pinned | Characterisation tests, passing on day one by construction, in the project's own test tree |
| A surprising value you asserted anyway | A `// CHARACTERISATION:` comment naming what was pinned, that it is not yet judged correct, and the ticket |
| The seam itself | A **behaviour-preserving** commit, separate from any behaviour change |
| Behaviour changed under the net | The commits `tdd` produces after the seam exists |
| A seam too large for one ticket | A handback to Thomas naming the paths, the blocker, and the smallest seam you can see |
| A characterisation test whose path is now covered behaviourally | Retired, and if it was pinning a bug, converted to a ticket |

<!-- source: harness/.agents/skills/legacy-testing/SKILL.md -->

## It's working if

- Every characterisation test asserts what the code returns today, not what it ought to return,
  and every surprising assertion carries the pinned-but-unjudged comment with a ticket.
- Seam creation and behaviour change never share a commit. If the tests break, you want to know it
  was the seam.
- The seam chosen is the smallest one that unblocks the ticket: parameterise before extracting an
  interface, sprout or wrap before breaking a static dependency.
- A seam the Builder could not justify inside one ticket was reported to Thomas as a result, not
  forced through under ticket pressure.
- Characterisation tests get retired as behavioural tests take over their paths, rather than
  accumulating as a second permanent suite.

<!-- source: harness/.agents/skills/legacy-testing/SKILL.md -->

## Where it fits

The chain inside one ticket is `characterise` → `seam` → `mattpocock-skills:tdd`, and this skill
owns the first two. It is reached from `builder.md`'s Load table on the row "no seam to test
through", and its escalation lands in `shaper.md`'s Load table on the row for a seam too large to
create inside one ticket. That landing row exists because an audit found the escalation pointing
at a contract that had no row for it. Beside it sit the other brownfield answers: `untangle` when
the code is too tangled to scope a refactor at all, and `/skills/bootstrap-glossary` and
`/skills/batch-triage` for the vocabulary and the backlog an adopted repo brings with it. Whatever
this skill produces still goes through the normal close: `/skills/review-with-rin` reads the diff,
`/skills/codex-arm` takes the final SHA.

<!-- source: harness/.agents/roles/builder.md, harness/.agents/roles/shaper.md, docs/audit/2026-08-26-dissection.md -->
