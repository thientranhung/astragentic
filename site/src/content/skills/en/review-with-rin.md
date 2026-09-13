---
title: review-with-rin
oneLiner: "Run Rin's milestone gate as an observable pane, then classify what she finds."
group: gate
order: 1
runtimes: [claude]
source: harness/.agents/skills/review-with-rin/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

This is the recipe Thomas runs to get a second opinion at a milestone: a finalized spec, a
ticket or PR closing, an epic wrapping up. It resolves an artifact key, opens a Herdr pane with
its own detached worktree at the exact reviewed SHA, then packs a brief for Rin.

The brief carries the mode, the spec or ticket path, the acceptance criteria, one paragraph of
owner intent, and, for UI work, the design-guidelines pointer plus the Builder's browser
evidence. It then dispatches her and collects whatever she writes to a gate-file before touching
anything else.

What makes this different from a normal PR review is that it deliberately runs only **once per
milestone**. The problem it answers is a loop: an earlier version of this method let review
rounds repeat.

Without a stopping point the rounds multiply, and most of the later ones re-review the earlier
rounds' own fixes.

So this skill treats Rin's findings as advice Thomas classifies once. Design-level blockers go to
the owner as a decision, never as a second round, and everything else becomes one work order to
whoever owns the artifact.

The gate-file mechanics exist for a related reason: a pane read in Herdr silently truncates to
the visible row count while reporting success, and gate reports routinely run 300+ lines. So the
full report has to land in a file Thomas names and verifies before any cleanup.
<!-- source: harness/.agents/skills/review-with-rin/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A spec just got committed, finalized | `review-with-rin`, `mode=adversarial` |
| A ticket or PR is ready to close | `review-with-rin`, `mode=code-review` |
| An epic just closed | `review-with-rin`, `mode=code-review` (reports to the owner, nothing to merge) |
| You are reviewing one increment inside an open ticket | Not this one, but `mattpocock-skills:code-review` plus the simplify pass, which is complete on its own |
<!-- source: harness/.agents/skills/review-with-rin/SKILL.md -->

## Prerequisites

- You are Thomas, because this is a Thomas-only recipe.
- Herdr is reachable and the workspace is nameable. A live daemon is not enough proof, and if you
  cannot name the workspace, that is a STOP rather than a fallback to a subagent.
- A launcher exists for the `rin` row's runtime in `orchestrator.md`. No adapter for the needed
  runtime is also a STOP to the owner.
- `check-requirements.sh` already treats Herdr as hard-required, so this adds no new dependency on
  top of it.
<!-- source: harness/.agents/skills/review-with-rin/SKILL.md -->

## What it leaves behind

| What happened | Where it lands |
|---|---|
| Rin's full report | `$GATE_FILE`, then copied to `.astraler/state/gate-history/<artifact-key>-<short-sha>.md` before cleanup |
| Rin's verdict trace at the reviewed head | an empty `rin(gate):` commit carrying `Scope:`, `Verdict:`, `Report:` |
| A design-level blocking finding | `to-questionnaire`, routed to the owner |
| A non-blocking or non-design finding | a work order to the paused Shaper (spec gate) or the ticket's Builder (ticket/PR gate) |
| A merge decision | only after the cross-vendor arm has run on the final SHA, reviewed in `codex-arm` |
<!-- source: harness/.agents/skills/review-with-rin/SKILL.md -->

## Known failures

- **A runtime was named that had no dispatch path.** The orchestrator named a runtime for the `rin` row with no dispatch path, so Rin
  went undispatchable. Promoted: the launcher matrix is now the single home for every role.
- **A bad lookup made a gate invisible.** The old "is there a live ticket tab?" lookup answered "no" every time at a spec
  gate, quietly turning every spec gate into an invisible subagent. Promoted, superseded by
  "can I name the workspace?"
- **The gate demanded evidence no one had promised to produce.** The gate asked the brief to carry "the Builder's browser-verify evidence," but
  `builder.md` never mentioned producing one. Promoted: the contract that owes it now says so.
- **A pipeline could fail mid-pipe yet exit 0.** A token-generation pipeline could fail mid-pipe and exit 0 under bare `set -e`,
  silently emptying the freshness token. Promoted, fixed by `set -euo pipefail` plus a length
  check.
<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- The gate ran in its own Herdr pane, in a detached worktree at the exact reviewed SHA, never
  inside the Builder's checkout.
- `$GATE_FILE` exists, is non-empty, and got copied into `.astraler/state/gate-history/`
  before the gate worktree was removed.
- A `rin(gate):` marker sits at the reviewed head with `Scope:`, `Verdict:` and `Report:`
  filled in.
- Thomas has actually overruled or deferred at least one finding across recent gates. A run of
  zero overrules is a sign he is relaying Rin's labels rather than classifying them.
- Nothing merged before the cross-vendor arm ran on the final SHA.
<!-- source: harness/.agents/skills/review-with-rin/SKILL.md -->

## Where it fits

A ticket moves through `/skills/dispatch-ticket`'s worktree, and once it is ready to close,
`review-with-rin` gates it: reading the diff, checking that the simplify marker and the
`Ledger:` line actually exist, and that browser evidence backs any UI change. What Rin cannot
judge, meaning whether the running product still coheres, is `dispatch-qa-walk`'s job. Once
findings are folded and verified, `/skills/codex-arm` takes the final SHA for the cross-vendor
pass before anything merges. `rin` itself is a [role](/dictionary/role/), and the
whole thing happens inside a [gate](/dictionary/gate/), on a [worktree](/dictionary/worktree/) nobody but Rin
writes to.
<!-- source: harness/.agents/skills/review-with-rin/SKILL.md -->
