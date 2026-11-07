---
name: codex-dispatch-ticket
description: "Prepare an Astragentic Codex ticket dispatch with verified claim, base, write ownership and artifact requirements."
---

# Prepare a ticket dispatch

Read the project's tracker configuration and `.agents/orchestrator-for-codex.md`
(or the owner's explicit launch-selected Codex override). Use its role assignments
and operating policies; never fall back to `.agents/orchestrator.md`. Full Builder
uses `builder`, quick tickets use `builder-quick`, not owner `quick-builder`. Resolve ticket, spec,
criteria, full/quick evidence, dependencies and parent readiness. Reconcile tracker
and Git before claiming. A same-account assignee is not a unique worker identity.
Use a deterministic ticket branch and Git's exclusive branch creation to catch
duplicate dispatch; do not rely on same-account label readback as a unique claim.
Keep one Thomas per frontier and separate records for concurrent tickets.

The brief must name dispatch/attempt, role, ticket/kind, owner intent, base SHA,
write-set, forbidden paths, criteria, validation commands, QA plan/cases, UI Glance/
States or exemption, Junior policy, arm policy and durable output directory. No QA
plan means no Builder dispatch. For explicitly justified QA-none, record the reason
and criterion validation instead of inventing product surfaces. Missing quick/full
evidence returns to shaping. For Shaper,
name effort and Spec checkpoint; for QA use codex-dispatch-qa-walk.

Before launch record every owed cross-vendor policy and its gate boundary through
`codex-cross-vendor-review`. Policy resolution and adapter availability are distinct.
With owner-authorized bounded pre-arm work, dispatch may proceed for the named code,
tests and same-vendor review even if policy is unconfigured or an enabled adapter is
unavailable. Record authorization, allowed phases, pending policy/availability,
NOT RUN and the exact stop point in the brief/checkpoint. A stricter project or owner
policy takes precedence. Without bounded authorization, resolve the dependency before
launch. At the first owed gate, stop dependent work and request the missing decision
or adapter; never disable the arm, infer a waiver, or accept/integrate an artifact
without required evidence. A quick ticket owes only its explicit brief requirements.
Before launch verify authorization, capacity, worktree/branch/base and claim. Use
`codex-dispatch-ticket-codex` for launch and coordination. Follow the native command procedure in that skill; the owner launcher is not a
worker dispatcher. Do not introduce another runtime service for this workflow.
Keep an uncertain launch recorded for reconciliation rather than blindly repeating.

A handback is a candidate artifact. Verify exact head/tree, write-set, criteria,
checks and required review/QA/arm before integration. Dirty or changed artifacts need
new evidence. Release claims and clean only owned resources after preserving artifacts
and confirming no live worker writes there. Never force-remove uncommitted work.

After integration, follow DISPATCH.md's coordinator close-out section before reporting
full done or refilling capacity. Record each owned resource as released with evidence,
retained with reason/owner/next checkpoint and capacity impact, or justified not
applicable. Include QA/station resources. Preserve shared/active resources; a retention
is not permission to force cleanup or claim freed capacity.
