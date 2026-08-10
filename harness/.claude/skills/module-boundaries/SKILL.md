---
name: module-boundaries
description: Declare and enforce module boundaries — which modules exist, what each one's public surface is, and which imports violate it. codebase-design describes deep modules; this is what holds the boundary once it is drawn. Use when reviewing whether a change respects module structure, when adding an import that reaches into another module, or when recording a boundary a refactor has just created.
---

# Module boundaries — declared, then held

`codebase-design` gives the vocabulary for deep modules: a narrow interface over substantial
implementation. It describes what a good boundary looks like. **A boundary nobody records
erodes** — one reach-inside import at a time, each individually reasonable, until the module
is deep in name only. This skill records boundaries and checks changes against them.

**Extract, never invent.** A boundary is declared from what the code does, or from a refactor
that just created it. A boundary declared aspirationally, against code that violates it
everywhere, produces a review that fails constantly and gets switched off.

## The declaration

`docs/agents/module-boundaries.md`, one entry per module:

```markdown
### ledger
- root: `src/ledger/`
- public: `src/ledger/index.ts`
- may depend on: `shared`, `db`
- status: HELD           # HELD = code obeys it · DRIFTING = known violations, counted
- violations: 0
```

Three fields carry the weight. **`public`** is the front door — the only path other modules
may import. **`may depend on`** is the outward edge, and it is what keeps cycles from
reappearing. **`status`** is the honest part: a boundary the code violates is `DRIFTING` with
a count, never `HELD` with an asterisk.

Start from the real import graph rather than from intent. Where a module has no single front
door yet, record `public: NONE` and `status: DRIFTING` — a named absence is a boundary
somebody can decide to draw, while silence is not.

## Checking a change

Two questions, both answerable from the diff:

1. **Does any new import cross into a module below its `public` path?** That is a
   reach-inside, and it is the erosion this skill exists to catch. The fix is usually to
   widen the front door deliberately — adding an export is a decision with a name — rather
   than to reach past it.
2. **Does any new import add an edge absent from `may depend on`?** A new outward edge is a
   change to the module's shape. Where it introduces a cycle, `untangle` has the three cuts.

A violation is a **finding, not a veto**. Report it with the import, the boundary it crosses,
and the two options: route through the front door, or change the declaration because the
boundary was wrong. Both are legitimate — boundaries drawn early are often drawn wrong, and a
declaration that can never change is one the team will route around instead.

**What is not declared is not checked.** A module with no entry is out of scope rather than
implicitly forbidden, which keeps a partial declaration useful. Most brownfield repos start
with two or three modules declared and the rest unlisted; that is the working state, not a
failure of the file.

## Keeping it true

Update the declaration in the same change that moves a boundary — a refactor that creates a
front door and leaves this file describing the old shape has produced two truths, and later
sessions will find the wrong one first.

When `untangle` lands a boundary, record it here as `HELD` with its violation count at zero.
When a review finds violations against a `HELD` module, either the change routes through the
front door or the status becomes `DRIFTING` with the real count. A count that only ever goes
up is the signal that the boundary was drawn in the wrong place, and it is worth saying so to
the owner rather than continuing to file findings against it.
