# Matt Pocock skills — distilled

> Distilled from **mattpocock-skills** 1.3.1 (marketplace commit b0618bc, 2026-10-08), Copyright (c)
> 2026 Matt Pocock, MIT. Upstream: <https://github.com/mattpocock/skills> · <https://www.aihero.dev>.
> Same treatment as `docs/bmad-distilled/`: install machinery stripped (`setup-matt-pocock-skills`,
> tracker vocabulary, triage labels, `agents/openai.yaml`), method preserved word for word where the
> wording is the method.

## Why this folder exists

Astragentic ran six of these skills as its Shaper and Builder operating layer from 2.x to 4.6.x
(owner decision 2026-10-29: replace them with harness-owned `astra-*` skills that keep Matt's
brevity and take BMAD's production philosophy; see `docs/audit/2026-10-29-ui-ux-flow-proposal.md`
§10.4). This folder is the **source text** for that rewrite, so the rewrite can cite what it kept,
what it dropped and why, and so the plugin can be uninstalled without losing the method.

Measured on the two downstream projects before the decision (Skill tool calls, all time):

| Skill | nizzy | inception | Bytes (SKILL.md + refs) |
|---|---|---|---|
| code-review | 272 | 130 | 6.7k |
| tdd | 224 | 111 | 3.6k + tests.md 2.2k + mocking.md 1.5k |
| grilling | 9 | 6 | 1.9k |
| domain-modeling | 9 | 6 | 3.1k (+ GLOSSARY-FORMAT.md, ADR-FORMAT.md not copied) |
| to-spec | 6 | 5 | 3.0k |
| to-tickets | 3 | 4 | 5.8k |
| implement | 0 (prompt prefix, not a Skill call) | 0 | 0.6k |
| grill-with-docs | 0 | 0 | 0.2k (= grilling + domain-modeling) |

## Capabilities

| File | What it is | Where Astragentic used it |
|---|---|---|
| [grilling](capabilities/grilling.md) | Design-tree interview in rounds, frontier questions, recommended answers | Shaper phase Align (via grill-with-docs) |
| [domain-modeling](capabilities/domain-modeling.md) | GLOSSARY.md + ADR discipline, challenge terms, sparing ADRs | Shaper phase Align |
| [to-spec](capabilities/to-spec.md) | Conversation → spec, seams first, numbered user stories | Shaper phase Spec |
| [to-tickets](capabilities/to-tickets.md) | Spec → tracer-bullet tickets with blocking edges; expand–contract for wide refactors | Shaper phase Tickets |
| [implement](capabilities/implement.md) | Six lines: fetch ticket, tdd at seams, tests, code-review, commit | Builder brief prefix |
| [tdd](capabilities/tdd.md) | Seams, good/bad tests, mocking at boundaries, red before green | Builder phase Build |
| [code-review](capabilities/code-review.md) | Two axes (Standards with Fowler smells, Spec), parallel sub-agents, never rerank across axes | Builder review:matt |

## What each one lacks for Astragentic (the reason for `astra-*`)

Stated once here so the capability files stay faithful to the source:

- **to-tickets** has no actor, screen or state field; nizzy: 65 of 209 UI merges in 45 days were
  corrections. BMAD's story form (`As a {user_type}` + Given/When/Then) and the harness's three UI
  sections (Glance / States / Criteria) fill that.
- **to-spec** regenerates actors per spec; no persistent cast. BMAD's PRD journeys (UJ-N, named
  protagonist, persona inline) fill that.
- **code-review**'s Spec axis is the only spec check at build time (35 handbacks with a Spec finding
  in 272 nizzy calls); the built-in `/code-review` has no such axis. BMAD's Acceptance Auditor is the
  same idea with triage (patch / defer / dismiss) added.
- **implement** is a prompt prefix the mod keys on (`^/mattpocock-skills:implement`, 4 regex sites);
  **tdd** is a literal the tdd-order gate keys on (`tddCalledAfter`). Both move with the rewrite.
- **grilling** asks the user for decisions only and looks facts up itself: keep that rule verbatim.
