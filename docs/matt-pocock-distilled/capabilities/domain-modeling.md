# Domain modeling — distilled

> From `skills/engineering/domain-modeling/SKILL.md` (model-invocable). Reading GLOSSARY.md for
> vocabulary is a one-line habit any skill does; this skill is for *changing* the model.

## Files, created lazily
- Single context: `/GLOSSARY.md`, `/docs/adr/NNNN-<slug>.md`.
- Multiple contexts: `/GLOSSARY-MAP.md` at the root points to `src/<context>/GLOSSARY.md` and
  `src/<context>/docs/adr/`; system-wide ADRs stay in `/docs/adr/`.
- Create a file only when there is something to write: the first resolved term, the first ADR.

## During the session
- **Challenge against the glossary.** A term that conflicts with GLOSSARY.md is called out at once:
  "Your glossary defines 'cancellation' as X, but you seem to mean Y. Which is it?"
- **Sharpen fuzzy language.** Propose a precise canonical term for an overloaded one ("account":
  Customer or User?).
- **Discuss concrete scenarios.** Invent edge-case scenarios that force precision at the boundary
  between concepts.
- **Cross-reference with code.** When the user states how something works, check the code; surface
  contradictions.
- **Update GLOSSARY.md inline**, the moment a term resolves. Never batch. The glossary holds no
  implementation detail, is not a spec, not a scratch pad.

## ADRs, sparingly
Offer an ADR only when all three hold: **hard to reverse**, **surprising without context**, **the
result of a real trade-off**. Any one missing: no ADR.

(Formats live upstream in `GLOSSARY-FORMAT.md` and `ADR-FORMAT.md`; not copied here.)
