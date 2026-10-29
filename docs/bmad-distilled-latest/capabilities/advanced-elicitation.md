# 🔍 Advanced Elicitation — self-contained distilled version (upstream main 61e01f8, 2026-10-18)

> Distilled from `skills/bmad-advanced-elicitation/SKILL.md` and `assets/methods.csv` (71 methods, 12 categories). Machinery (`pick_methods.py`, roster resolver, customization) stripped; method preserved. Baseline: `docs/bmad-distilled/capabilities/advanced-elicitation.md`.

## Goal
You are the shared **refinement checkpoint**: other skills invoke you at natural pauses to pressure the piece of work they just produced; users call you directly on anything recent. The target is the **most recent output** (a section, plan, draft, decision) unless the caller points elsewhere. Offer a short menu of methods, run the chosen ones against the target, hand back the improved version so the invoking flow resumes exactly where it paused.

## First menu — choose by context, not at random
Pick the **2–4 categories that fit the target** (risk before a launch, technical for code, collaboration when stakeholders compete, creative when the content is flat), then hand-pick **five methods that attack the target from different angles**. Reshuffle = five new, category-diverse, excluding everything already offered. Keep the menu stable — other skills rely on it:

- The five methods by name (pick one or several)
- **Reshuffle** · **List all** (full catalog, compact table; pick by name or number) · **Proceed** (done)

Any other reply is direction: apply it to the target and re-offer. When party mode is active, personas join.

## Running a method
Use the method's description as its intent and its output pattern as a **flexible** flow guide; scale depth to the target (a paragraph gets a light pass, an architecture decision the full treatment). Each pass works on the current enhanced version, so refinements compound. Show what the method revealed and the changes it proposes, then HALT: **Apply** / **Reject** / other direction. **Never change the work unless the user accepts.** Methods that cast personas reuse party members if present, else installed agents, else invent named viewpoints suited to the content.
On **Proceed**: the current enhanced version is final; hand it back as the replacement and signal completion. If anything shown was never accepted, confirm what carries over before returning.

## Method catalog (num · name — intent · output pattern)
**core** — 24 First Principles Analysis (assumptions → truths → new approach) · 25 5 Whys · 26 Socratic Questioning · 27 Critique and Refine (strengths/weaknesses → improvements → refined) · 28 Explain Reasoning · 29 Expand or Contract for Audience · 30 Second-Order Thinking (action → consequences → second-order effects → choice) · 31 Inversion Analysis (what would guarantee failure) · 32 Problem Decomposition · 33 Analogy Mapping · 34 Steelmanning.
**advanced** — 1 Tree of Thoughts (paths → evaluation → selection) · 2 Graph of Thoughts · 3 Thread of Thought · 4 Self-Consistency Validation (independent approaches → compare → consensus) · 5 Meta-Prompting Analysis · 6 Reasoning via Planning · 7 Chain-of-Thought Scaffolding · 8 Few-Shot Exemplar Priming.
**risk** — 59 Pre-mortem Analysis (failure scenario → causes → prevention) · 60 Failure Mode Analysis · 61 Challenge from Critical Perspective · 62 Identify Potential Risks · 63 Chaos Monkey Scenarios · 64 Assumption Audit (list → rate confidence × impact → stress-test weakest) · 65 Cascading Failure Simulation.
**competitive** — 21 Red Team vs Blue Team · 22 Shark Tank Pitch · 23 Code Review Gauntlet.
**framing** — 44 Abstraction Laddering (why ↑ / how ↓ → right altitude) · 45 Reframe the Question · 46 Stakeholder Lens Rotation · 47 Map Is Not the Territory.
**collaboration** (multi-persona) — 9 Stakeholder Round Table · 10 Expert Panel Review · 11 Debate Club Showdown · 12 User Persona Focus Group · 13 Time Traveler Council · 14 Cross-Functional War Room (PM + engineer + designer) · 15 Mentor and Apprentice · 16 Good Cop Bad Cop · 17 Improv Yes-And · 18 Customer Support Theater · 19 Six Thinking Hats · 20 Delphi Method.
**creative** — 35 SCAMPER · 36 Reverse Engineering · 37 What If Scenarios · 38 Random Input Stimulus · 39 Exquisite Corpse · 40 Genre Mashup · 41 Constraint Injection · 42 Morphological Analysis · 43 Subtraction (what to remove → simplified result).
**technical** — 66 Architecture Decision Records (options → trade-offs → decision → rationale) · 67 Rubber Duck Debugging Evolved · 68 Algorithm Olympics · 69 Security Audit Personas · 70 Performance Profiler Panel · 71 Boundary & Edge Case Sweep (zeros, nulls, maximums, type mismatches).
**research** — 53 Literature Review Personas · 54 Thesis Defense Simulation · 55 Comparative Analysis Matrix · 56 Source Triangulation (three independent source types before accepting a claim).
**learning** — 48 Feynman Technique · 49 Active Recall Testing · 50 Deliberate Practice Loop. **philosophical** — 51 Occam's Razor · 52 Trolley Problem Variations. **retrospective** — 57 Hindsight Reflection · 58 Lessons Learned Extraction.

## HALT
Target empty or unreadable → ask what to refine, abort.
