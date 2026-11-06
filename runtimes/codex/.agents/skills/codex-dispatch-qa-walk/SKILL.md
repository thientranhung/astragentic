---
name: codex-dispatch-qa-walk
description: "Prepare and dispatch Astragentic product QA in walk, probe or verify mode at an exact artifact revision."
---

# QA dispatch

Require target identity (committed SHA, or base/HEAD plus dirty-artifact manifest hash),
plan path, mode, depth, scope, persona, environment/data provenance,
consent for the specified session, authorized mutations and durable report/clean-list
paths. Walk covers screens, probe endpoints, verify jobs/data. Dispatch one run per
applicable mode. Missing plan or consent blocks the corresponding operation.

For committed artifacts, create an isolated checkout at the exact target and verify
HEAD before launch. For a dirty no-commit artifact, Thomas may instead dispatch QA
read-only against the existing worker worktree after Builder/Junior acknowledge that
all source/build-input writes are paused through QA handback. Pin base/HEAD, dirty
status and a content manifest/hash covering the material tracked and untracked files,
required ignored build inputs, deleted paths and symlink targets. Identify included
runtime/build artifacts and exclusions; a HEAD alone cannot identify dirty contents.
Keep reports outside the inspected tree. No temporary commit is required or authorized.

A separate snapshot is an alternative only if its contents and material metadata are
verified against that same manifest, including deletions/untracked inputs; a fresh
checkout of HEAD or a tracked-only patch is insufficient. Record source and snapshot
paths and verified hash. In either route, establish that the exercised process/build
uses the pinned artifact, then recheck manifest/status at handback. Drift invalidates
coverage of affected content; stop and reconcile rather than reporting a clean run.
These are checks with project/Git tools, not a new artifact service or enforced lock.

Pass previous verified-clean items only with their verified artifact identity and
scope. Without a previous list use full depth. Use the Codex worker adapter with the
qa model row and separate dispatch identity; the dirty-worktree route is an explicit
exception to fresh-checkout creation, with no QA source-write ownership.

Read the returned matrix, not only the verdict. Verify target identity, P0/P1 coverage,
mandatory mode checks, evidence and declared gaps. Save reports outside disposable
checkouts and preserve them in the project under authorization. A different target
requires new coverage. QA output never authorizes production mutations or integration.
