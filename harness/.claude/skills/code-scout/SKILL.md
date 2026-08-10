---
name: code-scout
description: Map the CURRENT state of the exact area a spec or ticket will touch — files, seams, flow — cross-checking codemap claims in passing, so work is shaped from what is there rather than from memory. Use at the START of shaping anything that touches existing code, when the owner asks for a survey of an area, or when the staleness audit flags an old doc whose area the work enters.
---

# Code-scout — eyes on the ground before the work is shaped

This is the reading layer's dispatch recipe. The sequence is always **codemap load (no
subagent) → THIS dispatch → shape the work**. It exists because the rule for everything this
package adds on top of upstream is *extract, never invent*, and a scout is how extraction
happens before a decision rather than after it.

## When it fires

1. **Anything that touches existing code**, after you load the owning module docs via the
   docs index and before you write the spec or the ticket. Doc-only work skips it.
2. The owner asks for a survey of an area before shaping.
3. The staleness audit flagged an old doc covering the area the work enters — widen the
   scope for that area, since an old map is a weak map.

## The brief — the scout knows ONLY what you pack

Dispatch through the Agent tool with `subagent_type: "code-scout"`
(`.claude/agents/code-scout.md` — read-only, model pinned, report shape baked into the
agent). The two-sided pattern: this skill owns YOUR side, the agent file owns ITS side. The
brief carries:

- (a) **Scope** — the exact files and directories the work will touch. Narrow; a request to
  map the whole application returns a summary of nothing. The scout loads the repo's code
  map itself, so paste only the claims you need cross-checked.
- (b) **What the change is**, one paragraph, so the scout knows which seams matter.
- (c) **Codemap claims to cross-check, QUOTED** (optional) — the lines whose truth the work
  depends on.
- (d) **The questions** the work needs answered where the docs are silent.

## After the report

- **The area map and the answers feed the spec directly.** The spec cites which docs were
  read and what the scout mapped; a spec with no citations was written from memory.
- **Blast-radius hits are scope corrections.** Every out-of-scope consumer the scout named
  either enters the work — impact section, test target — or gets an explicit "unaffected
  because …" line. One ignored consumer is how a narrow scope becomes a P1 finding at the
  end of review, which is where this was measured.
- **Negative claims are hypotheses.** Before anything depends on an absence the scout
  reported, re-run and EXTEND the searches it listed: a scout's "missing" proves only that
  its patterns missed. Treat them as UNPROVEN until a wider search agrees.
- **Drifted cross-checks are docs-sync debt.** Fold the doc correction into the work, or
  file it. This applies to module docs and code-map lines alike, and it is the loop that
  keeps both layers trustworthy enough to shape work from.
