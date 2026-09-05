---
title: untangle
oneLiner: "Cut boundaries into code that has none, one reviewable ticket at a time."
group: brownfield
order: 2
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/untangle/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

`untangle` is the refactor path for code with no boundaries to improve. The upstream skill
`improve-codebase-architecture` improves boundaries that exist; some repos have none — one module
imports thirty others, cycles are normal, and any honest restructure is a change nobody can
review. Upstream names that gap and does not fill it, so this is the path for it. Five moves:
read the real dependency graph, cut where the graph is thinnest, one boundary per ticket on an
expand–contract shape, handle cycles by one of three cuts, and stop deliberately.
<!-- source: harness/.agents/skills/untangle/SKILL.md -->

**The failure it prevents is the big-bang refactor** — a branch that grows for weeks, conflicts
with everything, and gets abandoned or merged unreviewed. Every step exists to keep the work in
pieces that ship. Two of them push against instinct. The instinct is to attack the biggest
tangle; the skill says start at a leaf, because a leaf can be given a boundary without moving
anything else and it proves the approach on something cheap. And the instinct is to add the new
front door and delete the old paths in one ticket; the skill splits them, because a ticket that
cannot merge until every caller moves is the big-bang shape reappearing one level down.
<!-- source: harness/.agents/skills/untangle/SKILL.md -->

## When Thomas reaches for it

Nobody dispatches this one. It is model-invoked craft, offered to two roles and owned by neither,
so it is reached when the situation arises rather than wired into a phase.

| What is in front of you | Reach for |
|---|---|
| A change whose blast radius keeps growing the more you read | `untangle` — a Builder scoping a refactor that will not scope |
| An effort that is a refactor too tangled to scope | `untangle` — a Shaper, before cutting tickets |
| Boundaries that exist and merely need improving | `improve-codebase-architecture`, upstream |
| A boundary about to be drawn with no test net under it | `legacy-testing`, first |
| The expand–contract ticket split itself | Hand the shape back; `to-tickets` is user-invoked and the Shaper drives it |

<!-- source: harness/.agents/skills/untangle/SKILL.md, harness/.agents/roles/builder.md, harness/.agents/roles/shaper.md -->

## Prerequisites

- **The import graph is extracted, not recalled.** A graph you extracted beats a graph you
  remember, and the surprise is usually which module is the real hub.
- **The behaviour crossing the boundary is characterised first**, via `legacy-testing`, so the
  refactor has a net.
- **A ticket surface that can hold one boundary each**, because the whole method is one boundary
  per ticket.
- **Somewhere to record architecture notes** — this skill names `docs/agents/boundaries.md`
  explicitly, and the reason it names a path is below.

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The measured graph | Cycles, hubs, leaves and crossings, named rather than guessed at |
| Each boundary | One ticket that ships on its own: characterise, expand, migrate callers, contract |
| The old paths | Removed in a later ticket, verified gone by search rather than by belief |
| The order of the work | Derived from the graph, which is what makes it arguable in a review |
| The boundaries drawn and the seams left | `docs/agents/boundaries.md`, read by the Shaper scoping the next refactor on the same code |

<!-- source: harness/.agents/skills/untangle/SKILL.md -->

## Known failures

One entry in `harness/.agents/memory/recurring-failure-modes.md` names this skill. It is marked
`promoted`.

- **AST-051**: an address the caller cannot use produces a substitute, not an error. A contract
  named a pass by a slash command, which is the form a *human* types, and an agent with no
  keyboard could not invoke it — so two Builders each performed a hand-rolled cleanup, both
  handbacks honestly described a pass that did happen, and the real skill fired later over the
  same diff found an extraction both had missed. The general rule: an address is correct relative
  to who must use it. This skill carries it at the expand–contract step, which points at
  `to-tickets` — user-invoked, and therefore not something the model can reach for itself.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- The first cut landed at a leaf, in one reviewable change, before anything harder was attempted.
- Each ticket drew exactly one boundary, and expand and contract sit in different tickets wherever
  the caller migration is large.
- Every cycle was cut by one of the three named moves, and a merge that looks like a step
  backwards carries its reasoning in the ticket.
- Work stopped when the boundaries the current work needs exist, not when the graph is beautiful.
- `docs/agents/boundaries.md` exists and names both what was drawn and what was deliberately left.

<!-- source: harness/.agents/skills/untangle/SKILL.md -->

## Where it fits

A Builder or Shaper hits a refactor that will not scope → `untangle` extracts the graph and picks
the thinnest cut → `legacy-testing` puts a net under the boundary about to be drawn → the shape
goes back to the Shaper, who drives `to-tickets` → each ticket runs the ordinary loop through
`dispatch-ticket` → the boundaries land in `docs/agents/boundaries.md` for the next pass. It
stops and goes to the owner when the graph shows the intended architecture and the code disagrees
with it, which is a decision rather than a refactor.
