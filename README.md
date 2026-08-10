# Astraler Harness 1.0.0

An operating framework that lets **several agents build software together on an existing
codebase**.

[Matt Pocock's `mattpocock-skills` plugin](https://github.com/mattpocock/skills) supplies the
method one engineer follows. This package supplies the two things that method leaves open:
**working on code that already exists**, and **many agents working at once without
colliding**.

Everything here earns its place against that sentence. A rule that serves one engineer on a
clean repo belongs upstream, and stays there.

## Requirements

```bash
./check-requirements.sh                 # machine readiness
./check-requirements.sh <target-repo>   # machine + that repo's readiness
```

The machine needs the Claude Code CLI, git with worktree support, herdr ≥ 0.8.0, and the
`mattpocock-skills` plugin. Codex is the cross-vendor arm and degrades to a warning when
absent. The target repo needs its tracker and triage labels configured — the doctor names
what is missing and how to produce it.

## The method

**The spine comes from the plugin.** A foggy effort larger than one session enters at
`wayfinder`; anything that fits one session enters at `grill-with-docs`. Both hand off to
`to-spec` → `to-tickets` → one `implement` per ticket → `code-review`.

**Roles follow session boundaries**, because the plugin fixes those boundaries: align, spec
and tickets run in one unbroken context, and each `implement` runs in a fresh one.

| Role | Session | Drives |
|---|---|---|
| **Thomas** — router | resident | `triage`, `wayfinder`, `to-questionnaire`, `ask-matt`; owns the tracker and the frontier |
| **Shaper** | one unbroken session | `grill-with-docs` → `to-spec` → `to-tickets`; decides seams while the whole picture is in context |
| **Builder** | one per ticket | `implement`, in its own worktree, sole writer there |
| **Rin** — reviewer | per milestone | second opinion, artifact verification, cross-vendor arm |

Every agent reaches the craft layer directly, since those skills are model-invoked:
`grilling`, `tdd`, `code-review`, `codebase-design`, `domain-modeling`, `research`,
`prototype`, `diagnosing-bugs`, `wizard`, `resolving-merge-conflicts`. Installing the plugin
once equips the whole team.

**The tracker is the coordination substrate.** Work state lives on the tracker configured by
`setup-matt-pocock-skills` behind `docs/agents/issue-tracker.md`. Blocking edges give the
dependency graph; the frontier query — every ticket whose blockers are done — answers what
is ready; and assigning a ticket before starting it is the claim that keeps concurrent
sessions apart.

**This package extends the claim to build tickets.** Upstream applies assignee-as-lock to
decision tickets and builds one ticket per session. Here a claimed build ticket gets its own
worktree and pane, so several Builders work the frontier at once under the isolation rules
carried over from the prior package. That is the throughput mechanism, and
`dispatch-ticket` is where it lives.

**Review keeps its weight and drops the loop.** Per ticket: `code-review`'s two axes in one
pass, plus a per-increment simplify pass leaving a `simplify(increment):` marker commit. At a
milestone: one Rin round, verifying the artifact and that the process left its traces. At
phase end: the cross-vendor arm. A design-level blocking finding escalates to the owner
through `to-questionnaire` rather than to another round.

**Answers carry a source.** Agents resolve the Align frontier themselves, answering from the
codebase, a prior ADR, `research`, `prototype`, or a second opinion — and recording which. An
answer with no source leaves the question open.

## Brownfield is this package's half

Upstream's skills contain no occurrence of *legacy*, *brownfield*, *characterisation* or
*untestable*; its brownfield notes live on its docs site for human readers. The projects this
package installs into are not greenfield, so six gaps are ours: standards extraction,
glossary bootstrap, a legacy-testing doctrine, a refactor path for repos too tangled for
`improve-codebase-architecture`, batch triage of an inherited backlog, and boundary
enforcement for the module design `codebase-design` describes.

The rule for all six is **extract, never invent**. `code-scout`, the codemaps and the
staleness audit are the reading layer. *(Shipping in a later increment — see
RELEASE-NOTES.md.)*

## Layout

```text
harness/                          the payload staged into a target repo
  .claude/skills/
    review-with-rin/              Rin's milestone gate — dispatch, gate file, collection
    code-scout/                   read the current state before work is shaped
    codex-arm/                    cross-vendor arm, Claude root → Codex
  .agents/skills/
    dispatch-ticket/              one ticket → one Builder → one worktree → one pane
    codex-claude-arm/             cross-vendor arm, Codex root → Claude
    codex-dispatch-headless/      explicit headless exception
  docs/governance/memory/
    recurring-failure-modes.md    34 measured failure modes; append-only, the evidence base
  scripts/
    herdr-watch-terminal.sh       turn watcher with a real start guard
    docs-staleness-audit.sh       age, fossils, dead links, always-on word budgets
docs/adr/0001-…                   why the method was rebuilt around the plugin
check-requirements.sh             the doctor
```

## Why the failure-mode ledger is here

It is the evidence base. A rule kept in this package can point at an entry in
`recurring-failure-modes.md`; a rule that cannot point at one is a rule to re-examine. That
is the test 1.0.0 applied to everything it carried over, and it is why this package is
smaller than the one it replaces.

## Writing rules

Every document here is written under `writing-for-agents` from the plugin, with four
measured targets:

- **Prohibition density.** The prior package ran one prohibition every 24 words in its
  reviewer contract, against upstream's one per 155. Prohibition makes the forbidden
  behaviour more available, so the positive target gets phrased and a prohibition survives
  only as a guardrail that resists positive phrasing — paired with the positive.
- **No-ops get hunted.** An instruction the model already follows by default costs load and
  buys nothing. Settle it by running the document; when a sentence fails, remove it.
- **Branching is the disclosure test.** Inline what every branch needs; put behind a pointer
  what only some branches reach.
- **One home per rule.** Everywhere else links. The prior package restated its gate law in
  five places and they drifted apart.
