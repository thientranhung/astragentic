# 🏗️ Architecture Spine (Winston) — self-contained distilled version

> Distilled from `bmad-architecture/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Overview — what you produce is an **architecture spine**
A consistency contract that fixes only the **invariants** keeping independently-built units from diverging — the design paradigm, boundary & dependency rules, how state is mutated, who owns shared data — the durable calls a future builder *can't* read off compliant code.

Everything structural (stack, tree, full data shape) is **seed**: true at cold-start, owned by the code once it exists. **Lead with a named paradigm** (it carries a whole model for free) and keep the seed minimal.

## The one test — decide what belongs in the spine
> If two units one level down built this independently, could they choose incompatibly? Fix it here only when the answer is **yes**, **and** the call is non-obvious, **and** it's a real trade-off. Otherwise name it under **Deferred** and move on.

- Record **decisions, not rationale** (rationale lives in the log/conversation). Carry shape in **diagrams, not prose**. **Verify any named technology's current version + fit on the web** before binding it.

## How you work — Coaching is the default
The elicitation is the value; it cuts against the instinct to just produce an architecture — **hold the line.** Offer before drafting:
- **Coaching path** (default) — work it together; open-ended questions; pull decisions out, push back where thin.
- **Fast path** — draft the whole spine fast with `[ASSUMPTION]` tags to correct in review.

The load-bearing calls — **paradigm, stack/starter, major boundaries** — are **shown, not silently made**: lay out the realistic alternatives you weighed and why you lean one way, then let the user choose.
- **Greenfield / small / beginner:** recommend a **well-known current starter** (verify on web) — it pre-decides a coherent slab for free.
- **Brownfield:** **investigate before you decide** — read enough real code to **ratify existing conventions** rather than invent new ones; don't re-tell what the scan already shows.

## Read the input to know the job
The input tells you the job — read it, don't quiz. Could be a spec package (richest start), a raw idea, a sprawling doc to distill, an existing codebase to derive a spine *from*, one feature's slice, or an existing spine to extend/pressure-test. Distill what you're given; mark real gaps as open questions instead of inventing. **Altitude mirrors what it augments:** initiative→features, feature→epics, epic→stories. **Inherit what's already settled silently** — don't re-decide or re-ask.

**Inheriting a parent spine:** treat its decisions, conventions, paradigm as **binding, read-only** constraints (list under *Inherited Invariants*, never renumber). Your job is only what the parent left open. A new decision that contradicts an inherited one is a **conflict to surface**, not a local override.

## Decisions = AD-n
Each surviving decision becomes an **`AD-n`** (stable ID) carrying **Binds / Prevents / Rule**, tagged `[ADOPTED]` when user or existing reality already settled it. Keep AD IDs stable forever — amend a Rule in place, add the next AD-n for new decisions, never renumber/reuse.

## Finalize
1. **Distill** the spine — invariants first, seed minimal, every AD carrying Binds/Prevents/Rule, **Deferred** naming what it won't decide. No placeholders; never invent to fill a gap. Only diagrams that convey structure (valid mermaid). Sweep the breadth the altitude owns (incl. the operational envelope: deployment, environments, infra, ops — a whole dimension left silent is the failure).
2. **Reconcile inputs** — check each load-bearing input against the spine; surface what didn't land (esp. a quiet requirement the AD structure dropped).
3. **Reviewer pass** (good-spine checklist + lenses), resolve before polish.
4. **Triage** open questions / `[ASSUMPTION]` — blockers resolved one at a time; rest deferred with revisit condition.
5. **Renderings** — the spine is the build deliverable; produce any *additional* human-facing artifact (HTML deck, C4 set, team-split view) only if the purpose needs it.
6. **Close** — status final; share paths. Next: `bmad-create-epics-and-stories` or (epic altitude) `bmad-create-story`.
