---
name: bootstrap-glossary
description: Seed CONTEXT.md with the domain terms the code already uses, each term carrying the file it was read from and marked unreviewed until the owner confirms it. Invoke by name at bootstrap on an existing codebase, instead of a fifty-question domain interview. Extracts vocabulary from code; it does not invent definitions.
---

# Bootstrap the glossary from the terms the code uses

Upstream's warning is the whole design constraint here: *an unreviewed, agent-authored
glossary is worse than none — it becomes confident-sounding lore that later sessions treat as
truth.* So this skill seeds a glossary it explicitly marks as unconfirmed, with the evidence
attached to every entry, and hands the owner a short review rather than a long interview.

**Extract, never invent.** Every term comes from the code. Every definition is derived from
how the code uses the term, and says so.

## 1. Harvest the vocabulary

Read the names the codebase has already committed to, in roughly this order of authority:

1. **Type, class, and table names** — the nouns the system is built out of.
2. **Module and directory names** — the areas the domain is divided into.
3. **Function names on public surfaces** — the verbs the domain performs.
4. **Enum and constant values** — the states and categories the domain distinguishes.
5. **Recurring words in comments and commit messages** — where a term is explained in prose.

Rank by frequency and by position: a term appearing in a type name, a table name and a module
name is core vocabulary. A term appearing once in a private helper is not.

## 2. Derive each definition from usage

For each term, write what the code shows it to be — its shape, what it relates to, what
changes it. Then attach the evidence:

**Write the entry in the reader's format, not a format of our own.** `CONTEXT.md` is consumed by
`domain-modeling` and eight other plugin skills, and its shape is fixed by that skill's
`CONTEXT-FORMAT.md`. Read that file and follow it whole — the parts below are the ones a
code-seeded pass gets wrong, not a replacement for it.

- Terms live under `## Language` as `**Term**:`, one or two sentences, defining what it **is**
  rather than what it does.
- **Every term carries `_Avoid_`.** Where the code uses several words for one concept, pick the
  best and list the rest — that choice is most of this file's value, and a pass reading code
  sees the synonyms more clearly than anyone.
- **Implementation detail does not belong.** `domain-modeling` wants `CONTEXT.md` "totally
  devoid" of it, which is exactly what a code-seeded pass will otherwise fill it with.
- **General programming concepts do not belong**, however often the code uses them.
- **Check the layout before writing.** One context → one `CONTEXT.md` at the repo root. Several
  → one `CONTEXT-MAP.md` at the root listing them, and a `CONTEXT.md` inside each. Seeding one
  root file across a multi-context repo merges unrelated vocabularies into a document every
  reader treats as authoritative, and it is the brownfield repos most likely to be multi-context.

So the definition goes in `CONTEXT.md`:

```markdown
## Language

**Ledger entry**:
An immutable record of one balance change, belonging to exactly one Account and carrying the
Transaction that caused it.
_Avoid_: Posting, journal line
```

...and the evidence, the citations and the review state go in **one** file,
`docs/agents/CONTEXT-review.md` — this pass's audit trail, not vocabulary, and one path
regardless of how many contexts the repo has:

```markdown
### Ledger entry — UNREVIEWED
- read from: `src/ledger/entry.ts:12` (type), `db/schema/ledger_entries.sql` (table)
- also used in: `src/posting/post.ts`, `src/reports/balance.ts`
- note: created only by the posting path
```

**A definition that the citations do not support is the failure mode.** Where the code uses a
term two incompatible ways, record both readings and mark the term `AMBIGUOUS` — that
ambiguity is the single most useful thing this pass can hand the owner, because it is usually
a real domain confusion sitting in the code.

Where a term is clearly domain language but its meaning cannot be read from usage, record the
term with `definition: UNKNOWN` and its citations. A named gap is worth more than a confident
guess, and it costs the owner one sentence to close.

## 3. Write `CONTEXT.md`

Open with a header that says exactly how much weight the file carries:

```markdown
# CONTEXT — domain vocabulary
Seeded from code 2026-08-10 · 23 terms · 0 CONFIRMED · 21 UNREVIEWED · 2 AMBIGUOUS
Status: UNREVIEWED — extracted from usage, not yet confirmed by the owner.
Terms below describe what the code does today, which may differ from what it should do.
```

**`UNREVIEWED` must be visible to a reader that has never heard of it.** The status field lived
only in this skill's own vocabulary: it appears nowhere in the plugin, and nine plugin skills
load `CONTEXT.md` without knowing the field exists — so every one of them read unconfirmed
extractions as confirmed domain language, which is the "confident-sounding lore" this pass
exists to prevent. Keeping the review state OUT of `CONTEXT.md` is half the fix; the other half
is the header below, which is prose any reader sees.

## 4. Write `docs/agents/CONTEXT-review.md`

The citations, the ambiguities, the `UNKNOWN` definitions and the per-term review state.
**The owner reads it** — that is what "ends on owner review, not on the artifact" means, and
until now the review had no address to be pointed at. A term moves out of this file by being
confirmed, and the header count in `CONTEXT.md` is derived from it.

Where `CONTEXT.md` already exists, **add to it and leave existing entries alone.** An entry a
human wrote outranks an entry read from code; where the code contradicts one, record that
under the existing entry as an observation for the owner.

## 4. The owner review gate

**A term counts only once the owner has confirmed it**, and the status field is what later
sessions read to know the difference. Take the owner the short list first: the `AMBIGUOUS`
terms, the `UNKNOWN` definitions, and the ten highest-frequency terms. That is a few minutes
of their attention against a fifty-question interview, which is the trade this skill exists
to make.

Mark each confirmed term `CONFIRMED <date>`. Leave the rest as they are — a glossary that is
half confirmed and honest about which half is a working glossary. Update the header counts so
the ratio stays visible at a glance.

`domain-modeling` from the plugin is where terms get sharpened once they are confirmed. This
skill's job ends at handing it a vocabulary drawn from the real code.
