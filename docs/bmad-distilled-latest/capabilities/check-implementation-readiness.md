# ✅ Implementation Readiness → Sofia validates the tree (upstream main 61e01f8, 2026-10-18)

> `bmad-check-implementation-readiness` is **retired** (`skills/bmod-method/retired.toml:50`; folded into sprint-planning in v6.11.0 `CHANGELOG.md:74`, and sprint-planning is itself gone). The method survives as Sofia's **VALIDATE**: `skills/bmad-agent-po/references/validate.md` and `validate-checks.md` (sections Ticket, Set, Tree, Dependencies, Closure). The old READY / NEEDS WORK / NOT READY report and the coverage-matrix document no longer exist; findings are sorted into fix / suggest / ask. Machinery (`tickets.py status`, tracker state) stripped. Baseline: `docs/bmad-distilled/capabilities/check-implementation-readiness.md`.

## Posture
Fresh-context subagents run the checks, each given the file's path and its section names; **they find missing prerequisites the tooling cannot see.** Sort findings into **fix** (mechanical), **suggest** (with reason), or **ask the user**. Resolve gaps, missing prerequisites, and contradictions before proceeding; the user decides suggestions and scope changes. **Do not re-raise a suggestion declined in a `Decision:` line unless new evidence changes its basis.**

## When
- A proposed set of child initiatives or epics, an epic breakdown, or a re-slice: **always, on the draft before approval**. Run Dependencies yourself first and fix the draft. Rerun when the user adds, removes, merges, or reorders. At initiative slicing, check scope ownership; future epics need no stories or full detail yet.
- A refined ticket: **before execution**.
- A container: **before closure** — its implemented coverage and Done when.

## What each scope reads
- **Per epic**: its file, its breakdown, every child ticket (done ones too), its Requirements, its sources, companions → sections **Ticket, Set, Dependencies**.
- **The tree**: the initiative, its breakdown, the epic files once written (on a parent, each child initiative's file), its sources → **Tree, Dependencies**.
- **A single ticket**: its epic file → **Ticket**. **Closure** → Closure.

## Ticket
- References open; no unfilled placeholders; assumptions marked.
- Nothing contradicts its epic file, its companions, the architecture, or a recorded decision.
- Each entry has a description, an `unknown` when one is known, and **a `verify` a non-builder can run**; only bugs, `refine = true` entries, and leaves with no entry need full criteria before execution.
- A ticket needing full criteria that covers an id under an unresolved `Source conflict:` stays `refined: false`.

## Set (every entry in the epic's breakdown)
- Tickets cover every Requirements line not deferred with the user; each `covers` id exists; tickets sharing an id say which part each delivers.
- **UX, architecture, constraint and integration work is covered without ids; results satisfy Done when; citing an id alone is not coverage.**
- Every `after`, cross-epic too, is a real prerequisite, not restated order; no cycle, drift, unpinned or undeclared prerequisite, order conflict; the epic's Notes hold a dated `Decision:` naming the tracer bullet and the sequencing decisions.
- **A builder could write each story's acceptance criteria from the epic, entry, and references; if not, fix the epic, not the one-sentence description.**
- Tracer bullet first (thinnest path through every layer; setup is hitl; demoable entries say what someone sees running); **Refactor sweep** closes an epic of more than three entries, or a `Decision:` says why not.

## Tree (the initiative and its epic envelopes)
- Every initiative requirement has an accountable epic or agreed deferral; shared ones say which part each epic delivers; no unexplained overlap.
- Each epic's `covers` cites parent ids; each Requirements line names its parent id (or source section); a child's `covers` resolves through the Requirements line to a parent id.
- Every source id on a line exists in a source file; every adopted design or architecture document is in `companions:`.
- **Every unit the source touches is an epic, out of scope, or a touch point** (consumed or configured only; named in the initiative's Boundaries with its owner).
- Each decision several epics adopt has **one home**: an architecture spine section, or an opening-epic entry the others wait on.
- Every written epic has Outcome, **Done when including production delivery**, Boundaries, `covers`, references; `refined: false` epics need no Requirements yet; the breakdown lists every epic in build order with its `after`; **it opens with a platform-baseline epic, or its first epic's first stories, or a `Decision:` saying why not**.
- A parent initiative lists every child in build order; each child's sources name the parent. One kind of child per breakdown.

## Dependencies (set entries, tree epics, or child initiatives)
- **Needs**: what each item needs to start and to run its check is built by it or by its `after`.
- **Collisions**: items with no dependency path share no code, config, schema, or setup; else add an `after` or merge them.
- **Shared setup**: the earliest item needing it owns it; others list it in `after`.
- **Handoffs**: when one item relies on another's output, both descriptions say so.

## Closure
Verify the container's Done when, requirements, constraints and companions **against implementation evidence, not child status** ("Done is a check the owner runs, not a count of closed children"); explain dropped work; confirm remaining scope with the user. Closing every child does not close the parent.

## Still worth keeping from the old check (not in upstream any more)
The epic-quality red flags — technical-layer epics ("Setup Database", "API Development"), forward references Epic N → N+1, Story N.k using outputs of a later story, entities created before a story needs them, vague ACs ("user can login") — remain good tests; upstream now enforces them through Spec Law, the tracer bullet, and `after` = prerequisites only rather than a separate report.
