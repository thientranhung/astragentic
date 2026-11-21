# Review dispatch: one method, lenses by scope, vendor and model as parameters

Owner's brief, 2026-11-21: the adversarial review is hard-wired to Codex; build a standard review that
dispatches lenses, learns from Codex's two review prompts and BMAD's review lenses, picks the model per
job by evidence, and runs on Claude as agents.

## What exists today

| layer | who runs it | vendor | when Codex is off | số đo | nguồn |
|---|---|---|---|---|---|
| correctness (built-in `code-review`) + Intent + Standards lenses | Builder, `astra-review` | Claude, the Builder's model (Sonnet on inception) | unchanged | 8 of 8 slice-1121 tickets ran all three | inception Builder transcripts |
| adversarial (the arm) | Builder / Shaper / Thomas, `codex-arm` | Codex only (`adversarial-review`) | gone: `Arm: off`, no substitute (6.1.7 ruling) | inception arm `no` since 11-11, 140 merges | inception `orchestrator.md`, git log |
| slice adversarial fan-out | Thomas, `astra-slice-reviewer` | Claude, parent's model | unchanged | 21 runs since 11-11, 15 Opus inherited | inception transcripts |

What the off arm costs, measured on one ticket (IN-474, replayed alone at its merge with the slice
reviewer's method): 3 defects verified real by inception that the three Builder lenses and the slice
fan-out both missed. Sonnet 90k tokens / 1.7 min, Opus 109k / 2.5 min. n=1.

## What the sources teach

**Codex `review`** (`codex-rs/prompts/templates/review/rubric.md`, read 2026-11-21): a bug is flagged
only if the author would fix it: introduced by this change, discrete, provable without unstated
assumptions ("one must identify the other parts of the code that are provably affected"), not an
intentional change. List every qualifying finding; none rather than a weak one. P0–P3 per finding with
a confidence, one paragraph each, shortest line range; an overall "patch is correct / incorrect".
Repository rules (AGENTS.md and scoped files) are cited when they support a finding.

**Codex `adversarial-review`** (plugin 1.0.6 `prompts/adversarial-review.md`): break confidence, not
validate. A fixed attack surface: trust boundaries; data loss, duplication, irreversible state;
retries, partial failure, idempotency; races, ordering, stale state; empty, null, timeout, degraded
dependency; version skew and migrations; observability gaps. Material findings only, each answering
what goes wrong, why this path, impact, concrete fix; "prefer one strong finding over several weak
ones"; verdict `approve | needs-attention`; JSON schema with file, lines, confidence.

**BMAD `code-review`** (`docs/bmad-distilled-latest/capabilities/code-review.md`, upstream 61e01f8):
lenses run context-free, in parallel, **same model tier**, each reading a staged diff file:
- Blind Hunter: no intent; "look for what's missing"; a finding floor `N = min(floor(sqrt(kB)+1), 10)`.
  BMAD's A/B on Claude and Codex: the persona made no difference to residual-bug hit rate; the floor
  and "what is missing" did.
- Edge Case Hunter: a path tracer over the hunks (implicit branches of a value set, handle lifetime,
  call-site contracts, deletion check); reads the author's claims only after tracing, to falsify them.
- Verification Gap: would a test fail if this broke; skipped / not-run tests count as gaps.
- Intent Alignment: readings of the intent vs the surface the diff exercises.
Then the orchestrator verifies every finding at its line, grades by single-occurrence harm, groups by
root cause, routes patch / decision / defer.

Mapped onto IN-474's verified defects: (a) mid-group session error discards fetched days, (c) the skip
misses the job's own retry, (e) empty scope reads collected: all three sit on Codex's adversarial
attack surface (partial failure, retries, empty state) and BMAD's edge-case classes; none is a
rubric-style "line X is wrong" bug. Our `astra-review` has the rubric (built-in `code-review`), Intent
and Verification Gap; it has **no adversarial and no edge-case lens**. That is the gap, not the vendor.

## Proposal

1. **Two lenses become agents in the plugin**, beside `astra-slice-reviewer`:
   `astra-adversarial-lens` (Codex adversarial stance + attack surface + BMAD finding floor) and
   `astra-edge-lens` (BMAD path tracer, claims last). Read-only tools, `model:` and `effort:` in their
   frontmatter so they never inherit the caller's model. They are sub-agent definitions: Claude Code
   reads the same file shape from `.claude/agents/` or a plugin's `agents/`; a pane role
   (`.agents/roles/`) is only for work that needs its own environment or runs for minutes (QA).
2. **`astra-review` launches them** with the three lenses it has, in one message, foreground, no
   `isolation: "worktree"` (6 of 282 inception `simplify` markers record a fork reading a stale or
   empty diff). Full ticket only; a quick ticket keeps the built-in review alone.
3. **The arm stays the cross-vendor pass.** Codex on, the arm runs as today. Codex off: the receipt
   says `cross-vendor arm: NOT RUN — off (orchestrator)`, and the two Claude lenses above are what read
   adversarially. No Claude pass is written as an arm receipt (6.1.7 stays).
4. **Slice**: `astra-slice-reviewer` gets the same frontmatter treatment (model pinned).

## Model per job: what is measured, what is not

| job | candidates | số đo | status |
|---|---|---|---|
| rubric / correctness | Sonnet (today) | 8 of 8 tickets ran; missed 3 real defects on IN-474 | measured as a miss, not as a model fault |
| adversarial / edge, ticket scope | Sonnet 5 vs Opus 5.5 | IN-474: Sonnet 2 real (c, e), Opus 2 real (a, c) + 1 gate gap; tokens 90k vs 109k | n=1, chưa đủ |
| cross-vendor arm | gpt-6.2-sol (owner 2026-11-21) vs gpt-6.2-astra | none since the switch | chưa đo |
| slice | Opus 5.5 (inherited) | 6 findings on slice-1121, 9 on 11-20 | measured, model not varied |

Measurement before any default is written (owner's yes 2026-11-21, Codex Sol and Astra included):
- **Sample.** Not blind: these tickets were chosen because a slice review recorded a finding whose
  origin is that ticket, so recall can be scored with no judge. IN-474 (pilot; slice-1121 #4, #5),
  IN-447 (11-20 F2, F3), IN-453 (F5), IN-462 (F1, F7), IN-476 (slice-1121 #1, #3), IN-479 (#2),
  IN-487 (#6). Each replayed from `git archive` at its merge, `.scratch` excluded, no later history.
- **Cells.** Lens file frozen in this commit, same text for both vendors. Claude {adversarial, edge} x
  {Sonnet 5, Opus 5.5}; control: `astra-slice-reviewer` at ticket scope on Sonnet; Codex {adversarial,
  edge} x {gpt-6.2-sol, gpt-6.2-astra}, effort medium, `codex exec` read-only with the output schema.
- **Noise.** The pilot runs each cell twice; a gap inside that spread is a tie, and a tie goes to the
  cheaper model.
- **Scores.** Recall against the recorded slice findings; precision = real over reported, on a
  per-ticket list merged, deduped, shuffled and stripped of its source, verified at the line by the
  `astra-review` §3 rule, inception spot-checking a sample; cost in tokens and minutes; overlap between
  the two lenses (heavy overlap means ship one).
- **Spend.** Projected from the pilot before the batch; any rate-limit error stops the Codex cells.

## Results, 2026-11-21 (recall and cost; precision not yet verified)

72 runs: pilot IN-474 x 9 cells x 2, then 6 tickets x 9 cells x 1. 40 Claude runs, 32 Codex runs
(`codex exec`, read-only, output schema): 72 of 72 exit 0 with schema-valid JSON, 0 rate-limit errors.
Raw outputs `/tmp/upstream-check/rmeas/out/`, tally `recall.txt`.

Recall against the 11 recorded slice findings on these tickets (IN-474 #4 #5, IN-447 F2 F3, IN-453 F5,
IN-462 F1 F7, IN-476 #1 #3, IN-479 #2, IN-487 #6); one run per cell per ticket (pilot run 1); a finding
naming the same defect by another route counts 0.5.

| cell | recall /11 | tokens per run (avg) | seconds (avg) |
|---|---|---|---|
| Claude adversarial, Sonnet 5.5 | 5.0 | 90k | ~55 |
| Claude adversarial, Opus 5.5 | 4.5 | 109k | ~120 |
| control: slice-reviewer method, Sonnet | 4.5 | 96k | ~70 |
| Claude edge, Sonnet | 3.0 | 89k | ~55 |
| Claude edge, Opus | 3.0 | 114k | ~110 |
| Codex adversarial, gpt-6.2-sol | 4.5 | 102k | 95 |
| Codex adversarial, gpt-6.2-astra | 2.5 | 70k | 80 |
| Codex edge, gpt-6.2-sol | 2.5 | 124k | 132 |
| Codex edge, gpt-6.2-astra | 2.0 | 79k | 100 |

Noise: on the pilot the same cell changed between its two runs (Claude adversarial Sonnet named #4 in
run 1, not in run 2), so a gap of 1 or less is a tie.

What the numbers say:
- **Vendors are complementary, not interchangeable.** IN-474's verified defect (a), a mid-group session
  error discarding fetched days, was named by Codex in 8 of 8 pilot runs and by Claude in 1 of 10. The
  slice findings #4, #2 and #6 were named only by Claude. Union of all Claude cells: 8 of 11; union of all
  Codex cells: 5 of 11, all inside the Claude union, plus (a).
- **Adversarial beats edge on both vendors** (Claude 5.0 / 4.5 vs 3.0 / 3.0; Codex 4.5 / 2.5 vs 2.5 / 2.0).
  The edge lens added no recorded finding the adversarial cells missed. Its distinct output was test-
  harness and docs drift, precision unverified.
- **Opus does not beat Sonnet on this lens** (4.5 vs 5.0, inside the noise) at about 1.2x the tokens and
  about 2x the time.
- **Sol beats Astra on Codex adversarial** (4.5 vs 2.5, outside the noise) at about 1.45x the tokens.
- **The new adversarial lens ties the existing slice-reviewer method** at ticket scope (5.0 vs 4.5).
- Missed by every cell: IN-474 #5 (queued jobs keep 25 attempts), IN-447 F3 (no MaxAttempts), IN-462 F7
  (ceiling-skipped chunk writes no rows). Each needs a fact outside the diff (queued state, a default in a
  library, a later ticket's behaviour).

Owed before any default is written: precision (real over reported) on a deduped, source-stripped list
per ticket, verified at the line, inception spot-checking a sample.

## Precision, 2026-11-21 (blind verification)

The 336 findings of the 63 run-1 outputs, shuffled per ticket with their source removed, were grouped
and judged at the line by one Opus verifier per ticket (`astra-review` §3 verdicts plus `by-design`).
Result: 135 groups — high 1, medium 33, low 45, by-design 31, maybe-false 10, false 15; 0 ids
unassigned. Files: `/tmp/upstream-check/rmeas/prec/`. The verifier is a Claude model; a 12-item spot-check
went to inception (8 medium, 1 false, 3 by-design, including IN-479 #2, which the blind verifier called
by-design and inception's slice gate filed as a fix).

| cell | findings | real high/medium | real incl. low | false | precision (h/m/l) | distinct high/medium defects |
|---|---|---|---|---|---|---|
| Codex edge, gpt-6.2-astra | 61 | 22 | 47 | 3 | 0.77 | 21 |
| Codex edge, gpt-6.2-sol | 53 | 20 | 38 | 2 | 0.72 | 20 |
| Codex adversarial, gpt-6.2-astra | 35 | 18 | 24 | 1 | 0.69 | 18 |
| Codex adversarial, gpt-6.2-sol | 32 | 16 | 21 | 1 | 0.66 | 16 |
| Claude adversarial, Opus | 21 | 13 | 15 | 0 | 0.71 | 13 |
| Claude edge, Opus | 33 | 10 | 22 | 2 | 0.67 | 10 |
| control, Sonnet | 40 | 9 | 24 | 6 | 0.60 | 9 |
| Claude edge, Sonnet | 35 | 8 | 15 | 7 | 0.43 | 8 |
| Claude adversarial, Sonnet | 26 | 7 | 12 | 2 | 0.46 | 7 |

34 distinct high/medium defects in all: Codex cells together 29, Claude cells together 17; Codex-only 16
(9 of them tests that cannot fail when the behaviour breaks), Claude-only 5, both 13. Best pair: Claude
adversarial Opus + Codex edge Astra, 26 of 34. Lens overlap: Claude adversarial and edge 11 shared of 17;
Codex 17 shared of 29, edge-only 9.

This overturns three readings of the recall table above, which rested on 11 targets:
- **Codex is the stronger reader**, not a complement: 29 of 34 against 17 of 34.
- **Sonnet is not enough on the Claude side**: precision 0.43 to 0.46 and 7 to 8 defects, against Opus
  0.67 to 0.71 and 10 to 13.
- **Astra is not worse than Sol**: 18 vs 16 (adversarial), 21 vs 20 (edge), at 70k vs 102k and 79k vs
  124k tokens. Whether a token costs the same quota on both is chưa đo.
- **The edge lens earns its place on Codex** (9 defects no Codex adversarial run found), less on Claude (3).
