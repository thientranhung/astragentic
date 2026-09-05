---
title: bootstrap-glossary
oneLiner: "Seed CONTEXT.md from the terms the code already uses, marked unreviewed until confirmed."
group: entry
order: 1
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/bootstrap-glossary/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

`bootstrap-glossary` reads the vocabulary a codebase has already committed to: type, class,
and table names first, then module and directory names, then function names on public
surfaces, then enum values, then recurring words in comments and commit messages. It turns
the highest-frequency terms into glossary entries. Each entry gets a definition derived from
how the code actually uses the term, an `_Avoid_` line naming the synonyms it's replacing, and
a citation to the exact file it was read from. The definitions go into `CONTEXT.md` in the
format `domain-modeling` and its sibling skills already expect; the citations, ambiguities, and
per-term review state go into a separate file, `docs/agents/CONTEXT-review.md`, so the
evidence trail never gets mistaken for the vocabulary itself.
<!-- source: harness/.agents/skills/bootstrap-glossary/SKILL.md -->

The friction this replaces is a fifty-question domain interview at the start of a brownfield
project, the kind where nobody has an hour free and the answers drift from what the code
actually does anyway. But the harder problem it's built against is subtler: an
agent-authored glossary that looks confirmed is worse than no glossary at all, because later
sessions treat confident-sounding prose as settled fact. So this skill extracts rather than
invents, and it marks every term `UNREVIEWED` until the owner has looked at it, visibly, in a
header any reader sees, because the review-state field itself doesn't exist anywhere else in
the plugin this feeds into, and nine downstream skills load `CONTEXT.md` with no way to know
the field is missing unless the header says so in prose.
<!-- source: harness/.agents/skills/bootstrap-glossary/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A brownfield repo with no `CONTEXT.md` yet | Run it at bootstrap, once, instead of an interview |
| A repo that already has a `CONTEXT.md` a human wrote | Run it to add to it: leave existing entries alone, and record any contradiction as an observation under the existing entry |
| A term the code uses two incompatible ways | Let it land as `AMBIGUOUS` rather than guessing which reading is right |
| A domain term whose meaning can't be read from usage | Let it land as `definition: UNKNOWN` with its citations rather than invent one |
<!-- source: harness/.agents/skills/bootstrap-glossary/SKILL.md -->

## Prerequisites

Check the repo's shape before writing anything: one bounded context gets one root
`CONTEXT.md`; several contexts get a `CONTEXT-MAP.md` at the root plus one `CONTEXT.md` inside
each. Seeding a single root file across a multi-context repo merges unrelated vocabularies
into a document every downstream reader treats as authoritative, and brownfield repos are the
ones most likely to actually be multi-context. Read `CONTEXT-FORMAT.md` first, since
`domain-modeling` and eight other plugin skills consume `CONTEXT.md` in a fixed shape and a
code-seeded pass gets the details wrong without it.
<!-- source: harness/.agents/skills/bootstrap-glossary/SKILL.md -->

## What it leaves behind

| What happened | Where it lands |
|---|---|
| A term extracted from code, with a draft definition | `CONTEXT.md`, under `## Language`, marked by the file's own header count |
| The citation, synonyms, and review state for that term | `docs/agents/CONTEXT-review.md`, one file regardless of how many contexts the repo has |
| A term the owner has since checked | `CONFIRMED <date>` in `docs/agents/CONTEXT-review.md`, with the header counts in `CONTEXT.md` updated to match |
| A term the code uses two incompatible ways | `AMBIGUOUS` in `docs/agents/CONTEXT-review.md`, kept visible rather than resolved by guessing |
<!-- source: harness/.agents/skills/bootstrap-glossary/SKILL.md -->

## It's working if

- Every entry in `CONTEXT.md` traces back to a real citation in `docs/agents/CONTEXT-review.md`.
  A definition the citations don't support is the failure mode this skill is built to avoid.
- The header on `CONTEXT.md` states the review ratio in prose a reader sees without knowing
  the field exists, e.g. "23 terms · 0 CONFIRMED · 21 UNREVIEWED · 2 AMBIGUOUS."
- Existing human-written entries are left untouched; anything the code contradicts is recorded
  as an observation, not an overwrite.
- Implementation detail and general programming concepts never make it into `CONTEXT.md`,
  however often the code uses them.
- The owner's review pass covers the `AMBIGUOUS` terms, the `UNKNOWN` definitions, and the ten
  highest-frequency terms first: the short list this skill exists to hand them, instead of a
  full read-through.
<!-- source: harness/.agents/skills/bootstrap-glossary/SKILL.md -->

## Where it fits

`bootstrap-glossary` runs once, by name, early in a brownfield project's life, alongside the
other invoked-once, owner-reviewed bootstrap passes: `extract-standards` for coding
conventions and `batch-triage` for an inherited backlog. Thomas owns all three as phases so
none of them becomes work everyone assumes someone else ran. Once terms are `CONFIRMED`,
`domain-modeling` is where they get sharpened further; this skill's own job ends at handing it
a vocabulary drawn from the code that's actually there, not a vocabulary somebody guessed at
in an interview.
