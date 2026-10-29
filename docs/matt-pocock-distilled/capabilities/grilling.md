# Grilling — distilled

> From `skills/productivity/grilling/SKILL.md` (model-invocable). Trigger: the user wants a plan,
> decision or idea stress-tested.

## Posture
Interview the user relentlessly until you reach a shared understanding. Map it as a **design tree**:
every decision branches into the decisions that hang off it.

## Rounds and the frontier
- The **frontier** is every decision whose prerequisites are already settled: the questions you can
  ask *now* without guessing at answers you have not heard yet.
- Ask the **whole frontier in one round**: number each question, give your recommended answer, then
  wait. A question whose answer depends on another question still open this round belongs to a
  *later* round.
- Each round of answers reshapes the tree: settled decisions push the frontier outward. Recompute,
  ask the next round.

## Format of a round
```
❓ **Q1** - **<title>**: <body, may be several paragraphs, may list choices>
➡️ <your recommended answer>
---
❓ **Q2** - ...
```
Word each question so that "yes" accepts your recommendation.

## Facts are yours, decisions are the user's
Finding *facts* is your job, never the user's. When a frontier question needs a fact from the
environment (filesystem, tools), dispatch a sub-agent; do not ask the user anything you could look
up. Do not block on it: only the questions downstream of that exploration wait; ask the rest now.
The *decisions* are the user's: put each to them and wait.

## Done
The frontier is empty: every branch visited, nothing silently assumed. Do not act until the user
confirms the shared understanding.
