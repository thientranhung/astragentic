---
name: astra-grill-with-docs
description: "Stress-test a plan, direction or effort with the owner until the design tree has no unvisited branch: rounds of numbered questions, each with a recommended answer, facts found by the agent, decisions made by the owner, every answer carrying its source, and the project's glossary and ADRs kept honest along the way. Shaper's Align phase."
disable-model-invocation: true
---

# Grill, with the docs open

The effort is a **design tree**: every decision branches into the decisions that hang off it.
The job is to visit every branch with the owner, not to fill it from your own judgement.

## Rounds and the frontier

The **frontier** is every decision whose prerequisites are settled: the questions you can ask
now without guessing at answers you have not heard. Ask the **whole frontier in one round**,
then wait. A question whose answer depends on another question still open this round belongs
to a later round. Each round of answers reshapes the tree; recompute, ask the next round.

```
❓ Q1 · <title>: <body; may list choices>
➡️ <your recommended answer, and the source it rests on>
---
❓ Q2 · …
```

Word each question so that **"yes" accepts the recommendation**. Open questions beat trees of
multiple choice: "tell me how X works today" before "A, B or C?". Infer-and-confirm ("I take it
X works like Y, right?") is fine; do not pick the owner's wedge, MVP cut or phasing for them.

**Brain dump first.** Before the first round, ask for everything the owner already has in mind
and every input they want read (brief, prior spec, research, transcript). One "anything else?".
Paragraphs the owner opened with are intake, not the dump.

## Facts are yours, decisions are the owner's

A question that needs a **fact** from the environment (the code, a config, a log, a doc, the
web) is never put to the owner: look it up, or send a sub-agent, and ask only the questions
downstream of that fact once it is in. A **decision** is the owner's: put it to them and wait.

**Every answer carries a source**: the codebase (file and line), an ADR, a research note, a
prototype run, a second opinion, or the owner's own words this round. An answer with no source
leaves the question **open**, and leaving it open is the correct outcome. The answer comes back
through the pane that dispatched you; whose voice it is is not your concern.

## The docs stay honest while you grill

- **Challenge against the glossary.** A term used against `GLOSSARY.md`'s definition is called
  out at once: "the glossary defines *cancellation* as X; you seem to mean Y. Which?"
- **Sharpen fuzzy words.** An overloaded term ("account": Customer or User?) gets a canonical
  one; a concrete edge scenario forces precision at the boundary between two concepts.
- **Cross-reference with code.** When the owner states how something works, check; surface the
  contradiction as a question with the file that shows it.
- **Update `GLOSSARY.md` inline**, the moment a term resolves; never batch. The glossary holds
  no implementation detail and is not a scratch pad. Create it on the first resolved term.
- **ADR only when all three hold**: hard to reverse, surprising without context, the result of a
  real trade-off. Any one missing: no ADR. `docs/adr/NNNN-<slug>.md`, created on the first one.

## Done

The frontier is empty: every branch visited, nothing silently assumed. Hand the answered tree
to the Spec phase with two lists: decisions with their sources, and questions still open with
why. Do not write the spec until the owner confirms the shared understanding.
