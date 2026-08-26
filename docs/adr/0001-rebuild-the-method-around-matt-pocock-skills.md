# 0001 — Rebuild the method around Matt Pocock's skills, and move the loop to the front

Status: accepted · 2026-08-10 · supersedes the gate-loop design of 0.9.0–0.14.0

## Context

Two weeks of field use produced plans and slices that took **5 to 14 review-gate rounds**.
The rounds were thorough and the results were good; the throughput was not. The gate record
of one 10-round plan shows where the rounds went: round 2 added a lock, round 3 cut it as
false comfort, and round 8 was still repairing a sentence round 2 had left behind. A large
share of the later rounds were the loop cleaning up after itself.

Three measurements explain it.

**The exit condition was held by the party that can always avoid triggering it.** The method
said a reviewer "can always produce one more finding", and then ended the loop on the
reviewer producing none.

**The phase that resolves decisions never ran.** The method document described an Align phase
— `grilling` — from 2026-07-19 onward. The contract of the role that owned
`align → plan → plan gate` never contained the word. The gate was built two weeks later and
calibrated against plans whose decisions were still open, so it absorbed that work at the
most expensive point in the process.

**The upstream system this method borrowed from resolves it differently.** 19 of Matt
Pocock's skills were vendored here in 0.2.0. His back half (`code-review`) was wired; his
front half (`grill-with-docs → to-spec → to-tickets`) was not. In his system every review is
a single bounded pass — no re-review, no convergence condition, no severity tier that blocks
a merge — while `grilling` loops "until the frontier is empty" and `to-tickets` iterates
"until the user approves".

**He loops at the front. We looped at the back.**

## Decision

Adopt his spine, and keep the four things this harness contributes that his system lacks.

**The spine.** Foggy effort larger than one session enters at `wayfinder`; anything that fits
one session enters at `grill-with-docs`. Both hand off to `to-spec → to-tickets`, then one
`implement` per ticket, closing with `code-review`. Matt's skills are installed as the
`mattpocock-skills` plugin; the vendored copies are removed.

**The tracker is the coordination substrate.** Work state lives on the configured issue
tracker behind `docs/agents/issue-tracker.md`. Blocking edges give a dependency graph; the
frontier query answers what is ready; and assigning a ticket before starting it is the claim
that keeps concurrent sessions off each other.

**This harness extends the claim to build tickets.** Upstream applies assignee-as-lock to
decision tickets and builds strictly one ticket per session. Here a claimed build ticket gets
its own worktree and pane, so several agents work the frontier at once under the isolation
rules this harness already enforces. This is the throughput mechanism.

**Review keeps its weight and loses its loop.** Per ticket: `code-review`'s two axes in one
pass, plus the per-increment simplify pass. At a milestone: one Rin round, whose job becomes
a second opinion plus verification that the process left its artifacts. At phase end: the
cross-vendor arm, which has the highest measured yield of anything here and is unchanged.
Blocking stays available for work touching money or state; it escalates to the owner rather
than to another round.

**Answers at the Align frontier carry a source.** The agents answer — that is the point of
the harness — from the codebase, a prior ADR, `research`, `prototype`, or a second opinion.
An answer with no recorded source leaves the question open.

## Roles follow session boundaries

Three upstream rules fix the shape. Steps 1–3 run in "one unbroken context window — don't
compact or clear until after `/to-tickets`". `implement` is "one ticket per session, clearing
context between tickets". A user-invoked skill may never reach another, so every spine step
needs an agent playing the human at that step. Roles therefore follow session boundaries
rather than seniority.

| Role | Session | Drives (user-invoked) |
|---|---|---|
| Thomas — router | resident | `triage`, `wayfinder`, `to-questionnaire`, `ask-matt` |
| Shaper | one unbroken session | `grill-with-docs` → `to-spec` → `to-tickets` |
| Builder | one per ticket | `implement` |
| Rin — reviewer | per milestone | — |

Every agent carries the whole craft layer, because model-invoked skills need no wiring:
`grilling`, `tdd`, `code-review`, `codebase-design`, `domain-modeling`, `research`,
`prototype`, `diagnosing-bugs`, `wizard`, `resolving-merge-conflicts`. Installing the plugin
once gives the entire team the craft.

**Superseded roles (tombstone).** The prior lead/executor build pair is retired, and its two
halves move to where they can be answered: seam decisions to the Shaper, where the whole
picture is still in context and where upstream's own gap sits — "nothing inside `implement`
agrees the seams" — and increment review to `code-review`, which is spec-aware and bounded.
The cost is real: the per-increment simplify commit is now seen at the milestone rather than
immediately. A high-risk tier restores a second agent beside the Builder.

## Brownfield is this harness's half of the work

Upstream's skills contain no occurrence of *legacy*, *brownfield*, *characterisation* or
*untestable*. Every brownfield acknowledgement lives on its docs site as a caveat for a human
reader, not as an agent instruction. The method is greenfield-shaped, and the projects this
harness installs into are not.

The sharpest instance: `code-review`'s Standards axis reads whatever the repo documents and
otherwise falls back to twelve generic Fowler smells. Upstream's own design note says "a
generic review skill that does not know your standards is the thing this design is trying to
avoid" — so on a repo with no written standards it silently becomes the thing it was built to
prevent. Silent degradation is the failure class this harness exists to catch.

Six gaps are ours to fill: extracting real coding standards from existing code so the
Standards axis has something to review against; bootstrapping `CONTEXT.md` from the terms the
code already uses rather than a fifty-question interview; a legacy-testing doctrine covering
characterisation tests and creating a seam before TDD can attach; a refactor path for repos
too tangled for `improve-codebase-architecture`, which upstream names as missing; batch
triage of an inherited backlog; and enforcement of the module boundaries `codebase-design`
only describes.

The bootstrap principle is **extract, never invent** — upstream warns that "an unreviewed,
agent-authored glossary is worse than none: it becomes confident-sounding lore that later
sessions treat as truth." the staleness audit already does this
reading; they become the brownfield entry rather than incidental tooling.

Two upstream mechanics carry into legacy work unchanged: `to-tickets`' expand–contract path
for wide refactors, batched by blast radius; and `wayfinder`, which upstream reports is
"arguably sharper" on legacy "because a lot of the fog is 'what is already true here'".

## Rejected alternatives

**Put the owner back on the spine, as upstream does.** His flow skills are user-invoked by
design, and a user-invoked skill may never reach another. Rejected: the owner is building a
coordinated agent team, and routing every spine step through a human defeats that. The cost
is real — `grilling`'s frontier empties instantly when a proxy may answer from its own
judgement — and the source rule above is what buys the value back.

**Keep the loop and cap the rounds.** Rejected: a cap on a mechanism whose exit the reviewer
controls gets argued around. Removing the loop's reason to exist is the smaller change.

**Adopt upstream wholesale and drop the gate.** Rejected: his review is advisory and blocks
nothing, and his system has an open fan-out defect where sub-agents rediscover `/code-review`
and spawn more, one report reaching 50-plus agents. Worktree isolation, the one-writer rule,
the evidence artifact and the cross-vendor arm are this harness's reason to exist.

## Consequences

Contracts get rewritten against `writing-for-agents`. Prohibition density is the first
target: the prior reviewer contract carried one prohibition every 24 words against
`code-review`'s one every 155, and prohibition makes the forbidden behaviour more available,
not less.

`to-questionnaire` is the intended channel for owner decisions, and upstream defines no way
for a completed questionnaire to re-enter the flow. That return path is ours to build.

`docs/governance/distilled/` is 26,150 words of distilled BMAD — the approach upstream names
as the one it rejects. Holding both is a separate decision, deliberately not folded into this
one.
