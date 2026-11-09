---
name: codex-dispatch-qa-walk
description: "Prepare and dispatch Astragentic product QA in walk, probe or verify mode at an exact artifact revision."
---

# QA dispatch

Require a pushed target SHA,
plan path, mode, depth, scope, persona, environment/data provenance,
consent for the specified session, authorized mutations and durable report/clean-list
paths. Walk covers screens, probe endpoints, verify jobs/data. Dispatch one run per
applicable mode. Missing plan or consent blocks the corresponding operation.

Create an isolated checkout at the exact SHA and verify HEAD before launch. An uncommitted
target goes back to the Builder to commit; never run QA on one. Keep reports outside the
checkout. One run covers a batch: dispatch at the batch head SHA, scoped to the union of the
tickets' surfaces. Findings: QA advises, you classify, the Builder fixes; a fix owes no second
run, and a design-level blocker goes to the owner.

Pass previous verified-clean items only with their verified artifact identity and
scope. Without a previous list use full depth. Use the Codex worker adapter with the
qa model row and separate dispatch identity.

Read the returned matrix, not only the verdict. Verify target identity, P0/P1 coverage,
mandatory mode checks, evidence and declared gaps. For filtered/status surfaces,
require the requirement-derived positive AND negative membership oracle and actual
record identities; matching badge/list totals alone cannot establish acceptance. Save reports outside disposable
checkouts and preserve them in the project under authorization. A different target
requires new coverage. QA output never authorizes production mutations or integration.
