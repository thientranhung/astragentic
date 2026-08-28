# 🎯 SPEC Kernel (shared) — self-contained distilled version

> Distilled from `bmad-spec/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Overview / posture
Canonical transformer for the spec-kernel ecosystem. Takes **any intent input** — vague idea, brain dump, PRD, GDD, RFC, brief, Slack thread, customer email, meeting transcript, mockups, mixed multi-source — and produces **SPEC.md**: the five-field kernel plus companion files for load-bearing content that doesn't fit the kernel. Together they are the **machine contract** every downstream skill consumes. This skill **distills; it does not coach.** Multiple skills may update the same spec over time.

## The five-field kernel
**Why · Capabilities · Constraints · Non-goals · Success signal.** Use the template as the skeleton. Write **lean from the first pass** — every sentence must earn its place; decoration costs tokens and dilutes downstream readers.

## The workspace
A spec is **always a folder**, named for a `{slug}` that describes *the thing being specced*, not the input shape. Same slug = same folder → a second invocation lands in place and **updates**, preserving capability IDs. Inside:
```
<spec-folder>/
  SPEC.md          ← the kernel — DERIVED, never hand-edited
  <companion>.md   ← optional, content-typed (glossary.md, ...)
```
**No input** → interactive: ask for a file path / pasted content / a detailed explanation / a source. If genuinely too thin to distill (e.g. "an app for hikers" with no context), stop and suggest `bmad-prd`.

## Memory & derivation (the core mechanic)
Keep an **append-only, chronological log** of every decision, constraint, capability (with its stable `CAP-N`), assumption, open question, and bit of user direction — one line each, in the order it happened, never edited or reordered. `SPEC.md` and every spec-authored companion are **derived on each run** from that log plus the sources it cites — never hand-patched. Deriving the contract from a living log (instead of editing the contract in place) is what lets the surrounding steps (PRD, UX, architecture, epics) run **in any order** and feed the same spec without merge drift: the log only accumulates, the artifact is re-rendered. A later log entry supersedes an earlier one on the same point while history stays intact. A hand-edit to SPEC.md from outside is unsupported and overwritten on the next derive.

## The operation
Read the input and its linked materials. If a prior log exists at the target folder, it's an **update** — the log (not the rendered SPEC.md) is the authority on what was decided and on capability IDs. Preserve IDs; new capabilities get the next unused `CAP-N`; never reuse retired IDs. Otherwise it's a **create**.
- **Structured, pre-sorted input** (PRD+addendum, GDD, upstream brief) → trust the authored separation: lift kernel-fitting content into SPEC.md, overflow into named companions.
- **Mixed input** (brain dump, transcript, RFC, email) → do the sorting yourself: walk each claim, apply the load-bearing test, route to a kernel field or a companion.
- **Rich input** → extract directly, no elicitation. **Sparse input** → choose **express** (best-effort distill; every gap becomes an `open_questions[]` entry) or **guided** (walk the five fields with the user one at a time).
- A recognized **domain implication the input leaves unaddressed is itself a gap** — name it as an open question (healthcare silent on PHI/HIPAA, payments silent on PCI, control systems silent on fail-safe). **Flag it; never invent the answer or coach toward it.** If these dominate, the input is too thin → suggest `bmad-prd`.
- When two live sources/companions disagree, or an either/or never resolved, **surface it to the user** rather than silently choosing.

## Load-bearing & companions
A claim is **load-bearing** if any consumer (downstream skill, implementing agent, verification pass) would change a decision without it. When load-bearing content doesn't fit a kernel line, it lives in a **companion**; the kernel cites it. Spawn a companion when content needs more than one kernel-shape line: multi-item catalogs/matrices, tables, **diagrams (always)**, editorial voice rules, long-form reference (glossary, brownfield notes, conventions). Single-line decision-benders stay in Constraints; intent+success pairs stay in Capabilities.
- **Spec-authored** companions are written and owned here (siblings of SPEC.md), named for the **content type they hold** (`glossary.md`, `patron-archetypes.md`, `stack.md`, `conventions.md`, `architecture-diagrams.md`) — a reader should know what's inside before opening it.
- **Adopted** companions are load-bearing artifacts written by an upstream skill (a UX `DESIGN.md`, a partner API spec, a project-wide `project-context.md`); referenced by relative path but **not edited** here. Never duplicate them into the kernel.

## Spec Law (eight rules; the self-validate sweep enforces them)
1. Each capability has **both `intent` and `success`** — missing either = not a capability.
2. Intents describe **WHAT, not HOW** — implementation prescription belongs in a companion.
3. Constraints **actually bend design decisions** — one that rules nothing out is decoration.
4. **Non-goals are explicit** — at least one; absence lets downstream fill the vacuum.
5. **Success signal is concrete enough to test/demonstrate against** — "users love it" doesn't qualify.
6. **Capability IDs are stable and unique** — never reused, never renumbered.
7. **Preservation** — every load-bearing source claim lands in SPEC.md or a companion; wrapper ceremony does not.
8. **Lean prose** — every sentence carries load-bearing content; cut decoration, hedges, backstory, throat-clearing.

## Self-validate (two passes after every create/update, before presenting)
- **Pass 1 — Coherence.** Judge against Spec Law 1–6 and 8. Fix weaknesses without inventing content the input didn't support; calls made without confirmation become `assumptions[]`, unfilled gaps become `open_questions[]`.
- **Pass 2 — Preservation.** Walk the source claim by claim; confirm each load-bearing claim landed in SPEC.md or a companion. Wrapper-ceremony drops are logged, not silent.

## Output & after
Share the spec folder path conversationally: capability count, companions produced, the verdict in a sentence or two. If `assumptions[]` / `open_questions[]` are non-empty, list them (one line each) and invite a walkthrough — resolving them can update the source input, the spec, or both. Any later change is appended to the log as it happens; when a change overrides something from a source input, offer to update that source too so upstream and the spec don't silently diverge.

## Frontmatter
- `companions:` — `.md` files downstream MUST read alongside SPEC.md (paths inside or outside the folder; spec-authored vs adopted is implicit by path — downstream treats both the same).
- `sources:` — files **fully absorbed** into the spec with no remaining downstream value (for audit + re-read on update; downstream does NOT read these). Do not list the process log, READMEs, or organizational/process metadata.

> Persistence: keep a simple append-only markdown log (append-only decision-of-record) if you need to resume — SPEC.md is always re-derived from it.
