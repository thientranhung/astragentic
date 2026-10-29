---
name: astra-review
description: "Review a Builder's change against three axes, each in its own context: correctness (the built-in code-review), the ticket's intent and criteria, and the repo's coding standards; then verify every finding at its line, give it one verdict with evidence, and route it. Use after the tests and the UI pass, before simplify, on a full ticket. A quick ticket runs the built-in review alone."
---

# Review, three axes, one triage

## 1. Pin the change

The fixed point is the ticket's base (`Base:` in the brief); the diff is `git diff
<base>...HEAD`, untracked files included, staged to a temp file outside the repo. Empty diff:
stop. The **intent** is the ticket verbatim: What to build, Criteria, Must not change, and for
UI Glance and States; plus the spec FRs the criteria cite. The **standards** are every file
that documents how code is written here (`CODING_STANDARDS.md`, `CONTRIBUTING.md`,
`AGENTS.md`/`CLAUDE.md` at root and in touched directories) plus the smell baseline below.
Skip anything a linter already enforces.

## 2. Three lenses, launched together before any result is read

- **Correctness**: `Skill(skill: "code-review")`, the built-in, on the staged diff. It hunts
  bugs without the intent, which is the point: what is missing, not only what is wrong.
- **Intent** (sub-agent, read-only, given the intent and the diff, nothing else): per
  criterion, the test that proves it and whether it ran; criteria missing or partial;
  behaviour nobody asked for; criteria that look met but are met at the wrong surface (the
  intent's expectation lives at surface A, the diff and its tests exercise surface B); each
  Must-not-change line, still true or not. **Verification gap**: for each changed consumer,
  would any test fail if this broke? Read the test before saying what it covers; search for the
  symbol before saying no test exists; a source-text, no-throw, snapshot-only or mock-call
  check does not count.
- **Standards** (sub-agent, read-only, given the standards and the diff): documented-standard
  violations citing file and rule; baseline smells, named, hunk quoted; hard violations
  separated from judgement calls. A documented standard that endorses a smell silences it.

Each sub-agent prompt ends: inspect only, no edits, no test runs, no skills, no sub-agents,
findings as text under 400 words. A lens that fails is reported as failed, never as clean.

Smell baseline (each "what → fix"): Mysterious Name → rename · Duplicated Code → extract the
shape · Feature Envy → move the method to the data · Data Clumps → one type · Primitive
Obsession → a small type · Repeated Switches → one map or polymorphism · Shotgun Surgery →
gather what changes together · Divergent Change → split by reason to change · Speculative
Generality → delete · Message Chains → one method · Middle Man → cut · Refused Bequest →
composition.

## 3. Triage, after all three report

Number every finding `R1, R2…` with its lens; do not deduplicate yet. For each: **verify the
claim at the cited line**, callers and guards included. Can that state be reached? Is it
unwanted? "Throws when X" is real only when you show X happens. **Never judge B by its
similarity to A.** Then one verdict with **one sentence of evidence**: `high` (data loss,
security, silently wrong result, path broken with no workaround) · `medium` (broken but
noticed, or limited reach; verification gaps are medium by rule) · `low` (cosmetic) · `false`
· maybe false (undecidable from the diff; say what would settle it). Severity is the harm
of one occurrence, never rarity or fix cost. Group survivors by **shared root cause** into
`F1, F2…`, highest verdict first. Standards and intent findings are **never reranked against
each other**: report each axis under its own heading.

## 4. Route, then act

- **patch**: the fix is unambiguous, adds no public surface, guards no undemonstrated state →
  fix it now, re-run the covering tests, re-stage the diff.
- **decision_needed**: the right fix depends on what the owner meant → options one line each,
  your recommendation, into the handback. Never guess and patch.
- **defer**: pre-existing and not caused by this change, or all members maybe false → one
  line in the handback with what would settle it. **A finding this change caused, with a
  verified verdict, is never deferred.** Nothing is dismissed without a reason on record.

Close with one line per axis: findings, worst verdict within that axis. Zero findings plus a
failed lens is "may be incomplete", not clean. Then `simplify`, once.
