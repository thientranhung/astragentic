---
name: codex-astra-to-tickets
description: "Cut a released Astragentic specification and QA plan into owner-approved vertical tickets with dependency edges and quick/full evidence."
---

# Released spec to buildable tickets

Require the exact released spec revision, findings and disposition, owner intent,
PRD actor/FR IDs and QA plan. Missing release or plan blocks publication. Read current
code for seams and conflicts, but keep tickets focused on observable behavior rather
than brittle implementation paths.

Cut narrow vertical tracer bullets across the needed layers, each independently
verifiable. Retire uncertainty early; put shared interfaces before dependent lanes.
Tickets editing shared code form an ordered lane. Edges represent prerequisites,
not decorative sequence. For broad migrations use expand, green migration batches,
then contract; if only integration can be green, say so and name that checkpoint.
Do not shrink requirements into placeholders. Tests travel with behavior tickets.

Each ticket carries: What to build; behavioral Given/When/Then Criteria citing FRs;
Must not change; QA cases; prerequisite IDs; quick/full classification with evidence
for risky paths, test-only detectable logic and relevant file reach. Full if any
risk/logic answer is yes or reach exceeds three files (unless a measured project
threshold replaces it). UI tickets also need Glance (one must-see per surface) and
States including empty/loading/error/partial/permission, or justified inapplicability.

Show the owner the cut, edge reasons, assumptions and unknowns before publishing.
Existing approval of that exact breakdown is sufficient; do not ask again. Create
through the selected tracker in dependency order, using real IDs and native edges.
Keep readiness needs-triage for Thomas to promote. Never close/edit the parent as a
side effect. After an uncertain create, reconcile by dispatch/spec identity before
retrying. Preserve IDs for revisions; mark dropped work, do not delete it.

Hand back IDs/edges/plan, every FR and QA case mapped or explicitly deferred, cycle
check, unresolved prerequisites and disposition of every spec-stage finding.
