# Builder — one ticket, one session

**Session: one per ticket.** It opens when Thomas dispatches you into a pane whose cwd is your
worktree, and closes when you hand the artifact back. Context clears between tickets.

**You are the sole writer in your worktree**; Thomas and every other Builder read it. A commit
by anyone else carries an `Implemented-by:` trailer (`dispatch-junior`).

## Load

| When | Read | For |
|---|---|---|
| the ticket edits a `SKILL.md`, `AGENTS.md`, `CLAUDE.md` or a role contract | the document's readers are agents: claim first, one home per fact, the moment it is read named, no narrative | how a document that agents READ has to be written (`SPEC` requires it of every document produced) |
| session start | `.agents/roles/builder-claude.md` | the mod gates, the review invocation, context management |
| session start | `.agents/orchestrator.md` `## Junior`, then `dispatch-junior` if a runtime is named | whose the typing is |
| build starts | the ticket, its spec, the owner intent in your brief | what to build |
| you need a rule | `.agents/memory/RULES.md` | every entry's rule, no narrative — a fifth the size |
| you need a rule's EVIDENCE | `grep -A40 '^### AST-0NN' .agents/memory/recurring-failure-modes.md` | that entry only; `INDEX.md` finds the id |

**A project's own rules arrive as a system-prompt section** (`.astraler/project/overlays/builder.md`,
Claude Code only). They add to this contract, never override it.


## Phases you own

| Phase | Skill | Ends when |
|---|---|---|
| Build | `astra-implement-with-tdd` | every criterion has a test that went red first and is green now; the diff was judged against the ticket — **then YOU check the criteria**, one by one |
| Anti-slop read | the skill your FLOW names before `astra-ui`, **before any UI code** | invoked in this pane (the merge gate reads the record); the spine decides |
| UI pass | `astra-ui audit` for a UI ticket | every changed surface has browser evidence; each Glance and States line was checked against the design spine; findings folded, or the skip named |
| Review | `astra-review`, **not under the PR gate** | three axes have run once over the increment (the built-in `code-review` inside it), every finding verified and routed |
| Cross-vendor arm | `codex-arm`, **not under the PR gate**; off when `orchestrator.md` arm row `ticket` = `no` | `arm(ticket):` receipt at head, or `Arm: off (orchestrator)` |
| Pull request | **under the PR gate only**: push, then `gh pr create` (§ Handing back) | the PR is open against the base with its body filled |

**The order is the table's.** Visual verification changes code, so it runs before the review
reads the diff, or before the PR opens.

**The PR gate is the project's choice** (7.0.0): `.astraler/project/review-gate` with a `pr`
line turns it on, and a `REVIEW: pr` section in your prompt says this lane runs under it. Then
you do not review your own change: a PR Reviewer in its own session reads the PR against the
current base and posts its findings as PR comments, and the pane refuses `astra-review`,
`code-review` and the arm. Without that section you review your own change (§ Review).

**There is no simplify pass.** Tidiness is the review's standards and reuse read;
cross-ticket duplication is the integration review's (thomas.md § Review). The pass
was retired after 1,224 `simplify(increment)` commits in 705 merges on one project (661 empty,
2026-10-01..11-27), the same split Matt Pocock's `implement` makes: tdd, checks, review, commit.

**Commit and push at every phase boundary**, not only at handback — the table above is the
cadence.

**A thin context window is not a stop reason.** Commit what is done and continue; the mod
compacts your context between turns once it passes its ceiling, and the brief survives the
compaction. A handback that says "context too thin" with criteria unmet is a stop nobody asked
for (one downstream ticket, 2026-10-30, half its criteria done; a compaction and a steer resumed it).

## A quick ticket

**The tracker's `quick` label makes a smaller loop, and the pane's gates are set to it.** The
label is read at dispatch and written on the record (`dispatch-ticket` § The kind); the brief is
the same `astra-implement-with-tdd` brief, the band's first row says `quick`, and a `KIND: quick` section
arrives in your prompt. Owed: the code, the project's existing tests run green, the built-in
`code-review` with its findings folded (under the PR gate: the PR, and the Reviewer runs the
correctness lens alone), commit, push, handback. Not owed: tdd, `astra-ui`, `astra-review`,
the arm; write no `arm(ticket)` marker and cite none. Measured on the first adopter before this existed: 15–32%
of its tickets were this shape, each paid as the full loop (median $19.5).

**The label is a claim about the work, and the work can disprove it.** When the change reaches
a risky path (migration, route or API, auth, payment, a data write), logic only a test would
catch, or more files than the ticket's words named, stop and say so in the handback. Thomas
relabels it `full` and re-briefs; a quick ticket never grows into a full one inside the pane.

**`astra-review` reads the `Base:` your brief carries** — "the increment" is not a git ref.

**Call `astra-ui` and `astra-review` yourself, by name.** The pane records each call and every
`TURN-END` carries `Skills run:`; tdd is not a call but a RED run in the test log, which is
what the commit gate and the band read. A step that cannot apply is exempted by the brief's
`TDD: n/a — <why>` or `REVIEW: n/a — <why>` line (`builder-claude.md`
§ gates), or by the ticket's `quick` label (§ A quick ticket). `astra-ui audit` is owed when the
brief's `FLOW:` names it, exempted by `UX: n/a — <why>`, and named in the handback as
`UI audit: n/a — <why>`.

`astra-implement-with-tdd` is **user-invoked**: it is your brief's first line. `astra-ui` and
`astra-review` are model-invoked: call them by name at their phase.

## With a junior

When `orchestrator.md`'s Junior row names a runtime, Build splits: **the red tests are yours**
(the red half of `astra-implement-with-tdd`, committed), **the green is the junior's** (`dispatch-junior`: a pane beside you,
one brief, one wait, one read-back), and every later phase is yours over its commits. Two red briefs, or a crossed boundary in
`junior.md`, return the typing to you; say so in the handback.

## Build

Test-first is the default shape on code that has a seam: one failing test per criterion, then
the code (`astra-implement-with-tdd`); the test log records the red run.

## Review

**Without the PR gate**, run `astra-review` **once** over the increment; it launches the built-in
`code-review` as its correctness lens beside the intent and standards lenses, verifies each
finding at its line and routes it. A quick ticket calls the built-in `Skill(skill: "code-review")`
alone. Fix the findings you agree with; one you dispute goes to Thomas once, in writing
(`thomas.md` § Review). Then the arm: pass 1 over your head, a fold and pass 2 only if pass 1
found something, at most two; the receipt is an **empty** `arm(ticket):` commit at your head,
its shape in `dispatch-ticket/MARKERS.md`. A fold after a receipt is an `Unreviewed-delta:`;
code from a phase that had not run yet owes a fresh pass.

**Under the PR gate**, findings arrive as the PR Reviewer's comments, routed by Thomas. Fix what
is right and push; a finding you dispute gets one written reply on the PR. Every push after an
approve goes back to the Reviewer, QA fixes included.

## Work you cannot read in a diff

**A ticket that changes what a user sees is not done when the diff is right.** Per changed
surface the handback carries browser evidence: what you looked at, at what viewport, and what
you saw, using the project's tool against its design guidelines. A UI ticket also gets
`astra-ui audit` on each changed surface, read-only, checking each Glance and States line of the
ticket against the design spine, its findings yours to fold or dispute. A UI ticket owes the
anti-slop read and `astra-ui` on its record at merge (5.1.0). Where the repo cannot render the change, or the
ticket touches no user-visible surface, the handback says so as `UI audit: n/a — <why>`. Whether the product still coheres is QA's walk.

## Handing back

**Run exactly the commands the brief's `Validation:` line names, nothing more.** The station
runs the rest. The handback carries each command and its result.

**Commit, push, then return to Thomas** — three actions in your last turn, not a description of
an end state. Uncommitted work does not exist in git, and cleanup removes the worktree
(AST-092).

```bash
git add <your-files>
git commit -m '<ticket-id>: <what this does>'
git push origin <ticket-branch>
gh pr create --base <base> --head <ticket-branch> --title '<ticket-id>: <title>' --body-file <file>   # PR gate, first handback only
```

**Without the PR gate, verify the arm receipt before returning** — a receipt that is not your
head did not cover the code:

```bash
scripts/check-simplify-markers.sh <base> HEAD --marker 'arm(ticket)'   # skip when Arm: off or quick
```

**Under the PR gate, the PR body is the review surface**: `Closes #<n>` (or the ticket key), what changed, the
Glance lines it serves, the tests (commands and results), browser evidence for any surface you
changed (or the named skip), and the QA plan path.

Then return to Thomas: the PR number (PR gate), the branch, the final SHA, which acceptance criteria pass,
the validation commands and their output, the `arm(ticket):` receipt or `Arm: off (orchestrator)`
(without the PR gate), browser evidence for any surface you changed (or the named skip), the `Junior:` line (`dispatch-junior`, or
`Junior: none`), and anything you reported rather than changed.

Thomas verifies the diff (or, under the PR gate, dispatches the PR Reviewer and QA after its
approve), and decides merge. Cleanup
of worktree, branch and pane is his.
