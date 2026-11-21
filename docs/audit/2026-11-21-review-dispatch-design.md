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
