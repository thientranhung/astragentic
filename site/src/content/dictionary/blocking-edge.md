---
term: Blocking-edge
oneLiner: "A dependency link between two tickets that says one has to finish before the other can be picked up."
order: 6
related: [tracker, frontier, claim]
updated: 2026-09-04
---

**A blocking edge is a dependency link recorded on the tracker between two tickets, saying one can't be claimed until the other is done.**

`batch-triage/SKILL.md` sets these edges when it turns an inherited backlog into live tickets: "set blocking edges where one item plainly depends on another — those edges are what Thomas's [frontier](/dictionary/frontier) query reads, so an edge left out is a ticket that becomes ready too early." That's the edge's whole job — it's the input the frontier query filters on, not a status field or a priority marker. Thomas's contract is careful about what a blocking edge does and doesn't mean: "a blocking edge expresses ORDER, not EXCLUSION — two unordered tickets can still be unsafe together." Ordering and mutual exclusion are different problems, and the [claim](/dictionary/claim)'s write-set, not the edge graph, is what handles the second one.

The edge graph is also known to be an incomplete signal on its own. `reconcile-tracker/SKILL.md` documents a live project where computing frontier readiness purely from blocking edges returned epics and a ticket explicitly marked deferred as "ready," because parent/child sequencing carries information a flat blocking-edge rule can't see — so Thomas applies judgement on top of the raw query rather than trusting it mechanically. Per-tracker mechanics for the edge differ too: `jira-issue-tracker/SKILL.md` notes Jira's `Blocks` relationship is expressible in one JQL query, which is the actual reason to pick Jira's native link type over its noisier `Relates`.

## Why it matters here

Recording explicit blocking edges instead of letting the tracker's flat backlog imply order costs upkeep at triage time — someone (or `batch-triage`) has to notice and encode every real dependency, and a missed one silently produces a ticket that looks ready before it actually is. The payoff is that the frontier query can stay mechanical for the ordering half of readiness, leaving Thomas's judgement to cover only what edges structurally can't express, like parent/child sequencing.

## Seen in:

- `harness/.agents/skills/batch-triage/SKILL.md` — edges set at inherited-backlog triage
- `harness/.agents/roles/thomas.md` — "A blocking edge expresses ORDER, not EXCLUSION"
- `harness/.agents/skills/reconcile-tracker/SKILL.md` — over-inclusive-promotion finding
- `harness/.agents/skills/jira-issue-tracker/SKILL.md` — `Blocks` vs `Relates`

## Usage:

"The frontier says 214 is ready but it clearly needs 209 first." — "Then the blocking edge is missing, not the query — go add it before anyone claims 214."
