---
name: codex-batch-triage
description: "Classify an inherited Astragentic backlog against current code and propose evidence-backed dispositions and dependency edges."
---

# Triage an inherited backlog

Read project triage labels and the current code tree. For each issue determine whether
its subject still exists, whether its request is already implemented, whether another
issue covers the same code/symptom, or whether it remains live. Cite searches, code or
commits. Ambiguous evidence is NEEDS-OWNER, not a confident classification.

Report counts, stale/done evidence, duplicate groups, live labels and ticket-versus-effort
size, proposed prerequisite edges and owner decisions. Batch by complete area when the
backlog is large, preserving an explicit remaining set.

Closures require the owner's disposition. Creating/editing live tickets must fit the
active authorization; approval to classify alone does not authorize tracker mutation.
When publication is authorized use the selected tracker adapter, preserve existing IDs,
read back edges and leave new work unassigned. Do not invent a second label vocabulary.
