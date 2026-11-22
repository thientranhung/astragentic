---
title: codex-arm
oneLiner: "One direct, read-only Codex call that reads a finished artifact with an Astragentic lens before it merges."
group: gate
order: 2
runtimes: [claude]
source: harness/.claude/skills/codex-arm/SKILL.md
rented: false
diagram: cross-vendor-arm
lang: en
updated: 2026-11-22
harness: v6.1.19
---

## What the arm is

The cross-vendor arm is one `codex exec` call, read-only, run over a completed artifact by the author's other vendor. It needs no Codex plugin. `codex-arm` owns the call; `thomas.md` and `builder.md` own when it fires.

I replaced the plugin with a direct call in 6.1.18 and 6.1.19. The plugin allowed no effort setting and no lens of ours, leaked a broker per pass (AST-100) and exited 0 on a configuration failure (AST-095). The skill shrank from 2,893 to 1,553 words.

**Measurement.** Seven merged tickets were replayed at their merge trees and 72 runs produced 336 findings, verified blind. Codex with the edge lens found 21 real defects per run at precision 0.77 and about 79k tokens. Across the 34 real defects, Codex found 29 and Claude 17.

**Cost.** Pass 2 is owed whenever pass 1 left a fixed finding, so most tickets run two passes: about 160k Codex tokens per ticket.

## Who fires it, with which lens

| Scope | Fired by | Stands in | Lens |
|---|---|---|---|
| `arm: ticket` | Builder | its own worktree | edge lens (`edge-lens.md`) |
| `arm: spec` | Shaper | a detached checkout at the spec commit | adversarial lens |
| `arm: slice` | Thomas | a detached checkout at the slice head | edge lens |

**Measurement.** The ticket lens is measured. The spec and slice lenses are `chưa đo`: the Codex quota ran out before they could be.

## One call, one model

Every pass runs `gpt-6.2-astra` at medium effort, set explicitly and never inherited. Changing the model is the owner's decision.

**Measurement.** Astra found 18 to 21 real defects per run against 16 to 20 for Sol, at 70 to 79k tokens against 102 to 124k.

The call passes the diff, the commit messages as claims and the owner's intent in plain words. The intent matters: an intent-blind pass finds internal inconsistencies, and an intent-loaded pass finds betrayals of what the owner wants.

## The verdict is yours and fails closed

- **No output is not a pass.** A run with no schema-valid JSON is `cross-vendor arm: NOT RUN` with the reason, never a clean arm.
- **Every finding gets a disposition.** Verify it at its line, then record fixed, low, by design, false or deferred.
- **A bad model name is NOT RUN.** An empty range stops before launch.

**Measurement.** Live proof on 2026-11-21: a planted defect was named in 39 s, a hostile `AGENTS.md` saying "fix and commit" left the tree untouched, and an unknown model exited 1 with NOT RUN. Direct runs: 32 of 32 exited 0 with valid JSON.

## When Codex is out of quota

A usage limit means the arm did not run. The one who fired the arm records `NOT RUN — usage limit`, and only the owner may accept proceeding without it. At ticket scope the ticket still gets an adversarial read: `astra-review` runs its Opus adversarial lens, recorded as same-vendor and advisory. A same-vendor lens never completes the arm.

**Measurement.** With the quota exhausted, the call exited 1 with `NOT RUN — usage limit`. On that lens, Opus found 13 real defects at precision 0.71, Sonnet 7 at 0.46.

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The arm's log and dispositions | `.scratch/gates/arm-<key>-<scope>-pass<N>.md` on the artifact's branch |
| Ticket scope outcome | the `arm(ticket):` receipt, an empty commit naming `Vendor: codex gpt-6.2-astra (direct, <lens>)` |
| Spec and slice outcome | the merge decision trail; the slice gate also writes `arm(slice):` |

## Where it fits

`astra-review` → `simplify` → `codex-arm` pass 1 → fold → pass 2 → `arm(ticket):` receipt → handback. A ticket built by Codex and merged at a Claude station is armed by Claude, not by this file.
