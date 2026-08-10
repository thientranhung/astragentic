# Astraler Harness 1.0.0 — build spec

You are building a fresh package from an empty repo. Everything you need is in this file plus
the two sources it names. Read this file completely before starting.

## Sources

- **Prior package** — `/Users/tranthien/Documents/2.DEV/2.PRIVATE/astraler-harness-vibe-coding`
  at branch `v1`. Read `docs/adr/0001-rebuild-the-method-around-matt-pocock-skills.md` first;
  it carries the reasoning and the rejected alternatives. Tag `v0.14.0` holds the old method.
- **Matt Pocock's skills** — installed as the `mattpocock-skills` plugin (v1.2.3, 25 skills,
  ~1,620 always-on tokens). Read a skill's source when you need its exact contract.

## What this package is

It ships an operating framework that lets **several agents build software together on an
existing codebase**. Matt Pocock's plugin supplies the method one engineer follows. This
package supplies the two things that method leaves open: **working on code that already
exists**, and **many agents working at once without colliding**.

Everything here earns its place against that sentence. A rule that serves one engineer on a
clean repo belongs upstream, and stays there.

## Carry over from the prior package

Copy these, then prune under the writing rules below.

| From `v1` branch | Why |
|---|---|
| `harness/docs/governance/memory/recurring-failure-modes.md` | 36 FW entries, the evidence base for every rule kept. Append-only: existing entries keep their text and numbers |
| `harness/.claude/skills/review-with-rin/` · `codex-gate/` · `code-scout/` | the gate, the cross-vendor arm, current-state reading |
| `harness/.agents/skills/codex-plan-gate/` · `codex-review-with-rin/` · `codex-dispatch-headless/` | cross-vendor invocation mechanics |
| `harness/.agents/skills/dispatch-slice/` | slice dispatch; rewrite against the new roles |
| `harness/scripts/` | herdr watcher, staleness audit |
| `install.sh` · `check-requirements.sh` · `VERSION` · `RELEASE-NOTES.md` | staging and doctor; adapt |
| `docs/adr/0001-*.md` | this decision, as ADR 0001 here too |

Leave behind: every vendored Matt Pocock skill (the plugin supplies them), and
`docs/governance/distilled/` (26,150 words of distilled BMAD — an open decision, held out of
1.0.0 deliberately).

## The method

**Spine, from the plugin.** A foggy effort larger than one session enters at `wayfinder`;
anything that fits one session enters at `grill-with-docs`. Both hand off to `to-spec` →
`to-tickets` → one `implement` per ticket → `code-review`.

**Roles follow session boundaries**, because the plugin fixes those boundaries: align + spec
+ tickets run in one unbroken context, and each `implement` runs in a fresh one.

| Role | Session | Drives |
|---|---|---|
| Thomas — router | resident | `triage`, `wayfinder`, `to-questionnaire`, `ask-matt`; owns the tracker and the frontier |
| Shaper | one unbroken session | `grill-with-docs` → `to-spec` → `to-tickets`; decides seams while the whole picture is in context |
| Builder | one per ticket | `implement`, in its own worktree, sole writer there |
| Rin — reviewer | per milestone | second opinion, artifact verification, cross-vendor arm |

Every agent reaches the craft layer directly, since those skills are model-invoked: `grilling`,
`tdd`, `code-review`, `codebase-design`, `domain-modeling`, `research`, `prototype`,
`diagnosing-bugs`, `wizard`, `resolving-merge-conflicts`. Installing the plugin once equips
the whole team.

**The tracker is the coordination substrate.** Work state lives on the tracker configured by
`setup-matt-pocock-skills` behind `docs/agents/issue-tracker.md`. Blocking edges give the
dependency graph; the frontier query — every ticket whose blockers are done — answers what is
ready; assigning a ticket before starting it is the claim that keeps concurrent sessions apart.

**This package extends the claim to build tickets.** Upstream applies assignee-as-lock to
decision tickets and builds one ticket per session. Here a claimed build ticket gets its own
worktree and pane, so several Builders work the frontier at once under the isolation rules
carried over from the prior package.

**Review keeps its weight and drops the loop.** Per ticket: `code-review`'s two axes in one
pass, plus a per-increment simplify pass leaving a `simplify(increment):` marker commit. At a
milestone: one Rin round, verifying the artifact and that the process left its traces. At
phase end: the cross-vendor arm. A design-level blocking finding escalates to the owner
through `to-questionnaire` rather than to another round.

**Answers carry a source.** Agents resolve the Align frontier themselves, answering from the
codebase, a prior ADR, `research`, `prototype`, or a second opinion — and recording which.
An answer with no source leaves the question open.

## Brownfield is this package's half

Upstream's skills contain no occurrence of legacy, brownfield, characterisation, or
untestable; its brownfield notes live on its docs site for human readers. Build these six.

1. **Standards extraction.** `code-review`'s Standards axis reads whatever the repo documents
   and otherwise falls back to twelve generic Fowler smells — becoming the generic review its
   own design says it exists to avoid. Produce a real standards document by reading existing
   code. Report loudly when it is thin, so the degradation is audible.
2. **Glossary bootstrap.** Seed `CONTEXT.md` from terms the code already uses. Upstream warns
   that an unreviewed agent-authored glossary becomes confident-sounding lore, so every seeded
   term carries the file it was read from, and the owner reviews before it counts.
3. **Legacy testing doctrine.** `tdd` requires a confirmed seam and says nothing about code
   that has none. Cover characterisation tests and creating a seam before TDD attaches.
4. **A refactor path** for repos too tangled for `improve-codebase-architecture`, which
   upstream names as missing.
5. **Batch triage** of an inherited backlog.
6. **Boundary enforcement** for the module design `codebase-design` describes.

The rule for all six: **extract, never invent.** `code-scout`, the codemaps and the staleness
audit are the reading layer.

## Writing rules

Apply `writing-for-agents` from the plugin to every document produced.

- **Prohibition density is a measured target.** The prior package ran one prohibition every
  24 words in its reviewer contract, against upstream's one per 155. Prohibition makes the
  forbidden behaviour more available. Phrase the positive target; keep a prohibition only as a
  guardrail that resists positive phrasing, and pair it with the positive.
- **Hunt no-ops.** An instruction the model already follows by default costs load and buys
  nothing. Settle it by running the document. When a sentence fails, remove the sentence.
- **Branching is the disclosure test.** Inline what every branch needs; put behind a pointer
  what only some branches reach.
- **One home per rule.** Everywhere else links. The prior package restated its gate law in five
  places and they drifted apart.
- **Sharpen completion criteria.** A vague bound invites stopping early; make each step end on
  something checkable.

## Deliverables, in order

1. `uninstall.sh` in the **prior** repo on branch `v1` — see the separate note below.
2. Repo skeleton, `README.md`, `VERSION` at `1.0.0`, carried-over assets pruned.
3. `check-requirements.sh` — extend the prior doctor with: the plugin present and its version;
   and `docs/agents/issue-tracker.md`, `triage-labels.md`, `domain.md` present in the target.
4. Role contracts for Thomas, Shaper, Builder, Rin.
5. `install.sh` and the adaptation prompt, including a mandatory `setup-matt-pocock-skills`
   step, since the whole chain's indirection depends on it.
6. Brownfield bootstrap — the six items above.
7. A reachability check in `scripts/`: every phase named in the method appears in the contract
   of the role that owns it, and every model-invocable skill shipped here is referenced by the
   method. The prior package lost two weeks to a phase that existed only in a method document.

Stop after 3 and report. Then continue on approval.

## Acceptance

Each deliverable is judged by artifact, not by report:

- `VERSION` reads `1.0.0`; `bash -n` passes on every script.
- No project or product noun appears anywhere in the payload.
- No vendored copy of a plugin skill exists.
- Prohibition density in every role contract is one per 60 words or better; state the measured
  figure per file.
- The reachability check runs and passes on this package's own contents.
