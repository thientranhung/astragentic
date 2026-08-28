# 🔍 Advanced Elicitation — self-contained distilled version

> Distilled from `bmad-advanced-elicitation/SKILL.md`. Install machinery (python/config/memlog/headless) stripped; method preserved.

## Goal
Push the LLM to reconsider, refine, and improve its **most recent output**. Use it to critique a just-created section more deeply, or when the user names a method (socratic, first principles, pre-mortem, red team…). Elicitation applies to specific content — no rambling.

## When invoked indirectly (from another skill)
1. Receive the section content that was just created.
2. Apply the method iteratively to upgrade that very content.
3. When the user chooses `x`, return the upgraded version to the calling skill — it replaces the original section.

## Flow
### Step 1 — Choose methods by context
Analyze the conversation: content type, complexity, stakeholder needs, risk level, creative potential. From that, **choose the 5 best-fitting methods** — balancing foundational + specialized. (If party-mode is on, personas may join a method.)

### Step 2 — Present options & handle responses
Show the menu:
```
**Advanced Elicitation Options**
Choose 1-5, [r] Reshuffle, [a] List All, or [x] Proceed:
1..5. [Method Name]
```
- **1–5:** Execute the chosen method, adapt complexity + format to context, apply the creativity to the current section, show the upgraded version. Then **ask whether to apply it to the doc (y/n/other) and HALT for the reply.** Only apply on Yes; on No drop the proposal; on any other reply follow it. Then **re-present the 1-5,r,x menu** for the next elicitation round.
- **r (Reshuffle):** choose 5 new, diverse methods by category; 1 and 2 should be the most useful for the section.
- **a (List All):** list all methods + descriptions as a compact table; let the user choose by name/number then execute as with 1–5.
- **x (Proceed):** finish, return the finalized content to the calling skill.
- **Direct feedback:** apply it straight to the content then re-present.
- **Multiple numbers:** execute in sequence then re-offer.

### Step 3 — Execution principles
- Apply the method to the **latest version** of the content, each pass building on the previous; track every enhancement.
- The output pattern (e.g. `paths → evaluation → selection`) is a flexible guide, not rigid.
- Focus on **actionable insights**, staying tight to the section being analyzed.
- Multi-persona methods: state each viewpoint clearly (use party members if available).
- **Always re-offer 1-5,r,a,x after each execution**, until the user chooses `x`.

## Method registry (condensed — choose 5 by context)
Apply the description to understand & wield each method:
- **core:** First Principles · 5 Whys · Socratic Questioning · Critique and Refine · Second-Order Thinking · Inversion Analysis · Problem Decomposition · Analogy Mapping · Steelmanning · Occam's Razor.
- **advanced:** Tree/Graph/Thread of Thoughts · Self-Consistency Validation · Meta-Prompting · Chain-of-Thought Scaffolding · Few-Shot Priming.
- **risk / competitive:** Pre-mortem Analysis · Red Team vs Blue Team · Shark Tank Pitch · Code Review Gauntlet.
- **framing:** Abstraction Laddering · Reframe the Question · Stakeholder Lens Rotation · Map Is Not the Territory.
- **collaboration (multi-persona):** Stakeholder Round Table · Expert Panel · Debate Club · Six Thinking Hats · Delphi Method · Cross-Functional War Room.
- **creative:** SCAMPER · What If · Constraint Injection · Morphological Analysis · Subtraction · Reverse Engineering.
- **learning / research / retrospective:** Feynman · Active Recall · Source Triangulation · Comparative Analysis Matrix · Hindsight Reflection · Lessons Learned.

## HALT
- Content empty/unreadable → ask for clarification, abort.

*"Session memory": keep a simple append-only markdown log if you need to resume.*
