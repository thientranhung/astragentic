---
title: dispatch-qa-walk
oneLiner: "Start the app in its own worktree and let QA use it as a user, before a PR, a merge or a release."
group: gate
order: 2
runtimes: [claude]
source: harness/.agents/skills/dispatch-qa-walk/SKILL.md
rented: false
lang: en
updated: 2026-09-04
---

## What it does

This skill dispatches QA's product walk: the gate that judges the running system instead of the
diff. It builds on `review-with-rin`'s gate-file setup and pane form rather than restating them,
and adds the one thing a walk needs that no other gate does: an environment.

Thomas creates a gate worktree at the reviewed SHA, starts the app there with the project's own
command, then packs a brief with:

- **Persona and data state.**
- **Every surface showing the same concept**, not only the changed ones.
- **Design guidelines.**
- **Browser consent and any authorized mutation.**
- **The previous verified-clean list.**

From there it dispatches QA as a gate pane, collects the report, then stops the app and confirms
the port is free before removing the worktree.

The problem it handles is that reading a diff and using a product are different acts, and a green
test suite proves neither. A test asserts what somebody thought to assert; what is missing,
misordered, unreadable or unreachable on the actual screen is exactly what nobody wrote an
assertion for.

This gap is not hypothetical. An earlier harness version shipped a browser-walking agent across
several releases that never ran once; a separate project logged nine fold rounds and a merge in
half a day with QA never dispatched at all. So this skill carries its own counter: more than ten
merges touching a user-visible surface since the last walk is a STOP, and "none touched a surface"
is a valid answer while "not counted" is not.
<!-- source: harness/.agents/skills/dispatch-qa-walk/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| A PR or merge touches a user-visible surface or a public endpoint | `dispatch-qa-walk`, incremental depth |
| A release or a slice is closing | `dispatch-qa-walk`, full depth |
| More than 10 merges touched a surface since the last walk | `dispatch-qa-walk`, the STOP, not a judgement call |
| Several tickets land together toward one PR or release | One walk at the batch head SHA, scoped to their union |
| The change is backend-only, no surface a user meets | Not this skill. Record that the walk does not apply, then stop |
<!-- source: harness/.agents/skills/dispatch-qa-walk/SKILL.md -->

## Prerequisites

- You are Thomas: this recipe is Thomas-only, the same precondition as `review-with-rin`.
- The project has a rendering path documented in its entry doc. Where there is none, a walk
  cannot run, and that itself is a finding for the owner.
- Browser consent and any authorized mutation are named exactly in the dispatch. Without them
  QA declines and records a COVERAGE GAP.
- The previous verified-clean list, if one exists, comes from
  `.astraler/state/qa-verified-clean.md`. Where there is none, QA runs full instead of
  guessing what was covered.
<!-- source: harness/.agents/skills/dispatch-qa-walk/SKILL.md -->

## What it leaves behind

| What happened | Where it lands |
|---|---|
| QA's full walk report | `$GATE_FILE` → `.astraler/state/gate-history/walk-<artifact-key>-<short-sha>.md` |
| The verified-clean list | `$VERIFIED_CLEAN_FILE` → `.astraler/state/qa-verified-clean.md` |
| A record that the walk happened | An empty `qa(walk): <artifact-key> — <verdict>` commit at the walked head |
| COVERAGE GAPS QA declined to close | The report body; Thomas classifies these like any finding |
| A design-level product disagreement | `to-questionnaire`, routed to the owner |
<!-- source: harness/.agents/skills/dispatch-qa-walk/SKILL.md -->

## Known failures

- **Shipped but wired to nothing.** A browser-walking agent shipped for several releases and never ran once; no
  contract owned it, no dispatcher named it. Promoted, fixed by wiring (contract, dispatcher,
  reachability check), not by the missing file itself.
- **Its own queue was invisible to itself.** The verifier's own dispatch queue was invisible to itself, so the run point had to
  follow the artifact instead of a schedule. Promoted, cited by this skill and `thomas.md`.
- **Moved text kept stale names.** Moving the walk's mechanics out of `review-with-rin` carried three stale lines
  still naming the walker "Rin" and calling the walk "a mode." Promoted, moved text is not
  re-homed until it is re-read in context.
- **Teardown once stopped a shared container.** A running app leaks broker processes and database
  containers per walk; one badly scoped teardown once stopped a shared test container every
  live Builder stood on. Promoted, cleanup runs in order: kill the app, confirm the port,
  scoped teardown, then `--force` the worktree.
<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- The app ran in its own worktree at the reviewed SHA, never in the Builder's checkout.
- Both `$GATE_FILE` and `$VERIFIED_CLEAN_FILE` exist, are non-empty, and were copied into
  `.astraler/state/` before the gate worktree was removed.
- The brief named every surface showing the changed concept, not only those in the diff.
- The app was killed and the port confirmed free before `git worktree remove --force` ran.
- A `qa(walk):` marker sits at the walked head, so the walk left a trace the merge gate counts.
<!-- source: harness/.agents/skills/dispatch-qa-walk/SKILL.md -->

## Where it fits

A ticket closes through `/skills/dispatch-ticket`, `/skills/review-with-rin` reads the diff and
checks that the process left its traces, and `dispatch-qa-walk` is the gate beside it that reads
nothing. It drives the running product instead, because a coherent diff and a coherent product
are different claims. Findings from both gates route the same way: `qa` advises, Thomas
classifies, the Builder fixes, and a genuine product decision goes to the owner. The walk runs
inside a `/dictionary/gate` and a `/dictionary/worktree` it force-removes at cleanup, which is
why the verified-clean list has to be written outside that worktree first.
<!-- source: harness/.agents/skills/dispatch-qa-walk/SKILL.md -->
