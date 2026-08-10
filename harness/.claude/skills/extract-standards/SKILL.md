---
name: extract-standards
description: Read an existing codebase and write docs/agents/standards.md — the coding standards the code ALREADY follows, each rule citing the files it was read from and carrying an evidence count. Invoke by name at bootstrap, and again when the repo has changed enough that the standards are stale. Produces a coverage verdict (SOLID/PARTIAL/THIN) that code-review's Standards axis reads.
---

# Extract standards from the code that exists

`code-review` has two axes, and the Standards axis reads whatever the repo documents. Where a
repo documents nothing, it falls back to twelve generic smells and **becomes the generic
review its own design exists to avoid** — quietly, with no signal that it happened. This
skill gives that axis something real to read, and makes the degradation audible when it
cannot.

**Extract, never invent.** A standard this repo does not actually follow is worse than no
standard: it becomes confident-sounding lore, and the first review that cites it produces a
finding the codebase will not accept.

## 1. Read before writing

Load the code map if one exists, then read broadly rather than deeply — you are looking for
what repeats. Cover: the build and lint configuration, the test layout, the most-changed
files (`git log --format= --name-only | sort | uniq -c | sort -rn | head -40`), and one
representative module per top-level area.

Existing config is the strongest evidence available. A lint rule that is **enabled and
passing** is a standard the repo enforces mechanically, and it belongs in the document with
that provenance.

## 2. Derive rules with their evidence

A candidate rule needs three things before it is written down:

- **What the rule is**, in one sentence, phrased as what the code does.
- **The files it was read from** — at least three, by path.
- **A count**: how many files follow it, and how many contradict it.

Search for contradictions deliberately rather than waiting to meet one. A rule holding in 18
files and broken in 11 is not a standard; it is an unresolved disagreement, and recording it
as a standard would make `code-review` produce findings against half the repo.

Classify each candidate:

| Class | Test |
|---|---|
| `ENFORCED` | a linter or the compiler rejects violations |
| `STRONG` | ≥ 8 supporting files, 0–1 contradicting |
| `WEAK` | ≥ 3 supporting, and contradictions under a quarter of the sample |
| *dropped* | fewer than 3 supporting, or contradictions above a quarter |

A dropped candidate is worth one line under `## Unresolved`, because the disagreement itself
is real information for the owner.

## 3. Write `docs/agents/standards.md`

Open the file with a header the Standards axis can read without parsing the body:

```markdown
# Coding standards — extracted 2026-08-10
Coverage: PARTIAL (14 rules: 5 ENFORCED, 6 STRONG, 3 WEAK)
Areas covered: api/, web/, shared/
Areas with no extractable standard: jobs/, legacy-import/
Status: UNREVIEWED — awaiting owner review
```

Then the rules, grouped by area, each with its class, its evidence count and its file
citations. A rule with no citation is not a rule.

**The coverage verdict is the loud part**, and the thresholds are fixed so it cannot be
talked up:

- **SOLID** — every top-level area has ≥ 3 rules, and most are ENFORCED or STRONG.
- **PARTIAL** — some areas covered, others with nothing extractable. Name them.
- **THIN** — fewer than 5 rules total, or no area reaching 3.

**Report THIN loudly to the owner, in the run's summary and not only in the file.** THIN
means the Standards axis will keep doing a generic review, and the owner needs that in words:
*"this repo has no extractable standards, so `code-review`'s Standards axis will fall back to
generic smells until standards are written by hand."* Silent degradation is the failure class
this package exists to catch, and a THIN verdict quietly filed is that failure happening
inside the tool built to prevent it.

## 4. The owner review gate

The file ships `Status: UNREVIEWED`. It is usable in that state — a cited, evidence-counted
rule is better than a generic smell — and the status tells every later session how much
weight it carries.

Take the WEAK rules and the `## Unresolved` list to the owner. Their answers turn rules into
`CONFIRMED`, drop them, or add a rule the code does not yet follow — which is a **goal**
rather than an extracted standard, and is recorded as `ASPIRATIONAL` so no review treats
current code as violating it.

Flip the header to `Status: REVIEWED <date>` only after the owner has actually answered.
