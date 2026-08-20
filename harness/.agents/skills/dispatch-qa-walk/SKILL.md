---
name: dispatch-qa-walk
description: Thomas-only recipe to dispatch QA's product walk — the gate that uses the running system instead of reading the diff. Arrange an app at the reviewed SHA in its own worktree, pack the plan inputs (persona, data state, surfaces including unchanged ones, contracts, journeys, the previous verified-clean list), collect the report, then stop the app. Use before a PR, a merge or a release.
---

# Dispatch a QA product walk

Role contract: `.agents/roles/qa.md`. The gate-file setup, the pane form and the collection
checks are identical to `review-with-rin` §2–3 and are **not restated here** — that skill is
their one home. This skill owns only what a walk needs and the other gates do not.

## The running app

The other two modes read a detached worktree. A walk needs the product **running** at the
reviewed SHA, which makes it the only gate with an environment to arrange.

**Not the Builder's checkout.** Independence is the same rule as always, and a running app
writes caches, logs and local state — sharing the author's tree would corrupt what is being
judged. Create `gate-walk-<artifact-key>` at the reviewed SHA and start the app there with
the project's own command. The project's entry doc records that command as the rendering
path; where a repo has none, a walk cannot run and that is a finding for the owner, not a
reason to approximate one.

**One walk covers a batch.** When several tickets land together toward one PR or one
release, dispatch one walk at the batch head SHA rather than one per merge — the verdict is
valid for the SHA it walked, and that SHA carries every ticket in the batch. Scope the brief
to the union of their surfaces.

The brief carries §1's contents plus five more:

- **The walk depth** — incremental (the default, before a PR or a merge) or full (at a
  release or a slice close). `qa.md` § Two walk depths owns what each covers.

- **Persona and data state.** Who QA acts as, and what the data looks like. A walk on empty
  data and a walk on realistic volume find different defects, so the verdict is only
  interpretable against the state that produced it. Where the repo has a seed command, name
  it — a stale seed once produced a 500 that read as a code bug and was an environment
  artifact, with a real production implication hiding behind it.
- **Surfaces in scope.** What this work changed, **plus every surface showing the same
  concept.** Naming only the changed ones guarantees the walk cannot find the class of defect
  it exists to find.
- **The design guidelines**, by path. Without them a finding is an observation rather than a
  violation, and QA will say so.
- **The previous walk's verified-clean list**, so coverage accumulates instead of resetting.

Findings route as every gate's do: QA advises, **you classify**, the Builder fixes,
and a design-level blocker goes to the owner through `to-questionnaire`. A walk finding that
is a *product* decision — two labels that disagree because the concepts genuinely differ — is
the owner's, not a bug to assign.

Cleanup adds one step before the worktree removal: stop the app you started, and confirm the
port is free. A surviving dev server binds a port the next walk needs.

