# Builder — one ticket, one session

**Session: one per ticket.** It opens when Thomas dispatches you into a pane whose cwd is your
worktree, and closes when you hand the artifact back. Context clears between tickets.

**You are the sole writer in your worktree**; Thomas and every other Builder read it. A commit
by anyone else carries an `Implemented-by:` trailer (`dispatch-junior`).

## Load

| When | Read | For |
|---|---|---|
| the ticket edits a `SKILL.md`, `AGENTS.md`, `CLAUDE.md` or a role contract | the document's readers are agents: claim first, one home per fact, the moment it is read named, no narrative | how a document that agents READ has to be written (`SPEC` requires it of every document produced) |
| session start | `.agents/roles/builder-claude.md` | the two mod gates, simplify invocation, context management |
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
| UI pass | `astra-ui audit` for a UI ticket | every changed user-visible surface has browser evidence; each Glance and States line was looked at; its findings are folded, or the skip is named |
| Review | `astra-review` | three axes have run once over the increment (the built-in `code-review` inside it), every finding verified and routed |
| Simplify | `simplify` (`builder-claude.md`) — **once, after the last content commit** | a `simplify(increment):` commit exists whose body names the pass that ran |
| Cross-vendor arm | `codex-arm`; off when `orchestrator.md` arm row `ticket` = `no` | `arm(ticket):` receipt at head, or `Arm: off (orchestrator)` |

**The order is the table's.** Visual verification changes code, so it runs before the reviews
read the diff; the reviews find and report, so they run before simplify, which cleans and
applies; simplify runs last over the finished code, once. Claude Code designs its `code-review`
and `simplify` as one pair, each run once on a finished diff. Measured downstream (244 Builder
sessions): 57 ran the four-agent simplify pass two to five times, for a rebase, a regenerated
file or a one-line fold, ≈$335 in 14 days.

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
`code-review` with its findings folded, commit, push, handback. Not owed: tdd, `astra-ui`,
`astra-review`, simplify, the arm — write no `simplify(increment)` or
`arm(ticket)` marker and cite none. Measured on the first adopter before this existed: 15–32%
of its tickets were this shape, each paid as the full loop (median $19.5).

**The label is a claim about the work, and the work can disprove it.** When the change reaches
a risky path (migration, route or API, auth, payment, a data write), logic only a test would
catch, or more files than the ticket's words named, stop and say so in the handback. Thomas
relabels it `full` and re-briefs; a quick ticket never grows into a full one inside the pane.

**`astra-review` reads the `Base:` your brief carries** — "the increment" is not a git ref.

**Call `astra-ui` and `astra-review` yourself, by name.** The pane records each call and every
`TURN-END` carries `Skills run:`; tdd is not a call but a RED run in the test log, which is
what the commit gate and the band read. A step that cannot apply is exempted by the brief's
`TDD: n/a — <why>`, `REVIEW: n/a — <why>` or `SIMPLIFY: n/a — <why>` line (`builder-claude.md`
§ gates), or by the ticket's `quick` label (§ A quick ticket). `astra-ui audit` is owed when the
brief's `FLOW:` names it, exempted by `UX: n/a — <why>`, and named in the handback as
`UI audit: n/a — <why>`.

`astra-implement-with-tdd` is **user-invoked**: it is your brief's first line. `astra-ui`,
`astra-review` and `simplify` are model-invoked: call them by name at their phase.

## With a junior

When `orchestrator.md`'s Junior row names a runtime, Build splits: **the red tests are yours**
(the red half of `astra-implement-with-tdd`, committed), **the green is the junior's** (`dispatch-junior`: a pane beside you,
one brief, one wait, one read-back), and every later phase is yours over its commits. Two red briefs, or a crossed boundary in
`junior.md`, return the typing to you; say so in the handback.

## Build

Test-first is the default shape on code that has a seam: one failing test per criterion, then
the code (`astra-implement-with-tdd`); the test log records the red run.

## Review

Run `astra-review` **once** over the increment; it launches the built-in `code-review` as its
correctness lens beside the intent and standards lenses, verifies each finding at its line and
routes it. A quick ticket calls the built-in `Skill(skill: "code-review")` alone.

Fix the findings you agree with. A finding you dispute goes to Thomas once, in writing
(`thomas.md` § Review); the gate is not re-fired.

## Work you cannot read in a diff

**A ticket that changes what a user sees is not done when the diff is right.** Per changed
surface the handback carries browser evidence: what you looked at, at what viewport, and what
you saw, using the project's tool against its design guidelines. A UI ticket also gets
`astra-ui audit` on each changed surface, read-only, checking each Glance and States line of the
ticket, its findings yours to fold or dispute. Where the repo cannot render the change, or the
ticket touches no user-visible surface, the handback says so as `UI audit: n/a — <why>`. Whether the product still coheres is QA's walk.

## The cross-vendor arm — yours to fire, and it closes your loop

**One closed loop, one handback:** `astra-implement-with-tdd` → [`astra-ui audit`] →
`astra-review` → simplify → **arm pass 1** →
[fold → **pass 2**] → `arm(ticket):` receipt → handback. The arm reads the simplified tree.

**The head under review is yours**, so the range is correct without resolving it. Take isolation
from the arm skill.

**Two passes at most, and pass 2 only after a fold**; the receipt's `Pass: <n>` records it.
**A fold after the simplify marker does not owe the pass again** while its non-test content
stays within `check-simplify-markers.sh`'s fold allowance (100 lines, cumulative over
`<marker>..HEAD`); the script prints the delta as a NOTE. Over the allowance it STOPs, and the
answer is one more simplify pass and a fresh marker. A file the project regenerates after a
rebase belongs in `.astraler/project/marker-evidence-paths.txt`, not in a re-run.

The receipt is an **empty** commit at your head, so its parent is the tree the gate read.
Its shape, its `Reviewed:`/`Unreviewed-delta:` rule and the rest of the marker mechanics:
`dispatch-ticket/MARKERS.md`.


**`Unreviewed-delta:` is for a FOLD. Code from a phase that had not run yet owes a FRESH GATE.**
Simplify firing after the arm is not a delta to declare — the arm read a tree simplify then moved
past. One inverted ticket paid a full extra gate round.

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
```

**Verify your own phases before returning**, with the script — zero markers means the pass was
skipped, and **a marker that is not your head is a pass that did not cover the code** (AST-094,
AST-122):

```bash
scripts/check-simplify-markers.sh <base> HEAD --marker 'simplify(increment)'
scripts/check-simplify-markers.sh <base> HEAD --marker 'arm(ticket)'
```

A STOP here has one answer, one more simplify pass and a fresh marker; a committed log above the marker is declared in `marker-evidence-paths.txt`, never argued past.

Then return to Thomas: the branch, the final SHA, which acceptance criteria pass, the validation
commands and their output, the `simplify(increment):` marker, browser evidence for any surface
you changed (or the named skip), the `Junior:` line (`dispatch-junior`, or `Junior: none`), and
anything you reported rather than changed.

Thomas verifies the diff, dispatches QA before a PR, merge or release, and decides merge. Cleanup
of worktree, branch and pane is his.
