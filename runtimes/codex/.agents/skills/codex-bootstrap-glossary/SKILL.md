---
name: codex-bootstrap-glossary
description: "Seed domain vocabulary from an existing codebase with citations and explicit unreviewed status for owner confirmation."
---

# Extract domain language

Inspect existing glossary/context layout first. Preserve owner-written terms. Harvest
domain nouns from types/tables/modules, public verbs, states and repeated explanations.
Do not include generic programming vocabulary or invent a meaning from a name alone.
For multiple bounded contexts keep separate glossaries and a root map, not merged meanings.

Use the project's established glossary format. If none exists, use a Language section
with **Term** entries defining what it is and _Avoid_ synonyms. Keep implementation
details/citations in docs/agents/GLOSSARY-review.md. Mark each extraction UNREVIEWED,
conflicting meanings AMBIGUOUS and unsupported definitions UNKNOWN with evidence.

The glossary header must visibly say it is code-derived, not owner-confirmed, with
counts and date. Keep per-term sources/review state in the review file and update counts
from it. Do not overwrite an existing human definition when code disagrees; record the
conflict for review. Write only authorized documents and hand the owner the review path.
No term becomes CONFIRMED without an actual owner decision.
