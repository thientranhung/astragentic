---
name: untangle
description: A refactor path for code too tangled for improve-codebase-architecture — where there are no module boundaries to improve, everything imports everything, and a clean restructure would be one enormous unreviewable change. Use when a refactor cannot be scoped, when improve-codebase-architecture has nothing to work with, or when a change's blast radius keeps growing the more you read.
---

# Untangling code with no boundaries to improve

`improve-codebase-architecture` improves boundaries that exist. Some repos have none: one
module imports thirty others, cycles are normal, and any honest restructure is a change no
one can review. Upstream names this gap and does not fill it. This is the path for it.

**The failure it prevents is the big-bang refactor** — a branch that grows for weeks,
conflicts with everything, and gets abandoned or merged unreviewed. Every step below exists
to keep the work in reviewable pieces that ship.

## 1. Read the actual dependency graph

Guessing here is expensive, so measure. Extract the real import graph, then find:

- **the cycles** — which modules import each other, directly or transitively;
- **the hubs** — modules imported by many (changing them touches everything);
- **the leaves** — modules imported by few (these are where you can move safely);
- **the crossings** — where a call reaches deep inside another area rather than through its
  front door.

Extract the graph rather than recall it — a graph you extracted beats a graph you remember,
and the surprise is usually which module is the real hub.

## 2. Cut where the graph is thinnest, not where the mess is worst

The instinct is to attack the biggest tangle. **Start at a leaf instead.** A leaf can be given
a boundary without moving anything else, it lands in one reviewable change, and it proves the
approach on something cheap.

Then work inward. Each step: pick the next module whose dependencies are already resolved,
give it a front door, and route its callers through it. The order comes out of the graph
rather than out of judgement, which is what makes it arguable in a review.

## 3. One boundary per ticket, expand–contract

Each ticket does exactly this, and each ships on its own:

1. **Characterise** the behaviour crossing the boundary you are about to draw
   (`legacy-testing`), so the refactor has a net.
2. **Expand** — add the new front door beside the old paths. Nothing breaks; both work.
3. **Migrate** callers to it, in batches sized by blast radius. the expand–contract path belongs to `to-tickets`, which is **user-invoked**: you
   cannot reach it. Hand the shape back and name it — the Shaper drives it (AST-051).
4. **Contract** — remove the old paths once nothing calls them, verified by search rather
   than by belief.

**Expand and contract belong in different tickets** when the caller migration is large. A
ticket that both adds and removes is a ticket that cannot be merged until every caller moves,
which is the big-bang shape reappearing one level down.

## 4. Cycles

A cycle takes one of three cuts, in order of preference:

- **The dependency is one-way in truth** — one module uses a small part of the other. Extract
  that part to a third module both depend on. This is usually the right answer.
- **The cycle is an event** — one side does not need the other's result, only to announce
  something happened. Invert it: publish, and let the other side subscribe.
- **The two are genuinely one module** wearing two names. Merge them, then split along the
  real seam. Say so plainly; a merge that looks like a step backwards needs its reasoning
  visible in the ticket.

## 5. Stopping conditions

**Untangling is not the goal; shipping is.** Stop when the boundaries the current work needs
exist, rather than when the graph is beautiful. A repo with three clean boundaries and a messy
middle is a repo that ships, and the middle can wait for a ticket that actually needs it.

Stop and take it to the owner when: the next cut would touch a floor item's construction
path, the graph shows the intended architecture and the code disagrees with it (that is a
decision, not a refactor), or two cuts in a row grew rather than shrank the blast radius.
The last one means the graph you extracted is stale — re-read before continuing.

Record the boundaries as they land, where this project keeps its architecture notes, so the
next session does not re-derive them from scratch.

## 4. Write `docs/agents/boundaries.md`

The boundaries this pass established, and the seams it deliberately left. Previously this said
"where this project keeps its architecture notes" — no path, no filename, no named reader, and
therefore invisible to the check written for exactly that defect.

**The Shaper reads it** when scoping the next refactor on the same code: a boundary already
drawn is a boundary not to re-derive, and a seam deliberately left is the one place a later
pass will otherwise waste itself.
