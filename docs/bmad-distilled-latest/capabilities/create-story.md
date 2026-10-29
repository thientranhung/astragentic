# 📝 Create Story → Write a ticket (upstream main 61e01f8, 2026-10-18)

> `bmad-bmm-create-story` is **retired** (`skills/bmod-method/retired.toml:32`); the story-file-per-story model is gone ("Build an entry directly without making a story file", `help/ticketing-and-epics.md:3`). What remains of the method splits in two: the **ticket** (Sofia, `skills/bmad-agent-po/references/ticket.md`, `assets/ticket-template.md`, `bug-template.md`, `spike-template.md`) and the **context engine**, which moved into the build's plan (`skills/bmad-build/step-02-plan.md` Code Map — see `dev-story.md`). Machinery (`tickets.py pull/find`, tracker publish, memlog) stripped. Baseline: `docs/bmad-distilled/capabilities/create-story.md`.

## Posture
Ask only what is unsettled, with a default for each. Open only the template for the ticket's type; match its example's detail, not its content. **Each fact lives in one place**: reference the Requirements of the ticket above, never copy them. The ticket distills its sources; the builder reads the ticket, not the PRD.

## Ticket shape (initiative · epic · story share one template)
Frontmatter: `id`, `type`, `title` (container: its outcome; story: what works when done), `parent`, `covers` (epic: parent ids it owns; story: epic ids it serves), `sources`, `companions`, `after` (prerequisites only), `refined`, `hitl`, `risk`.
Body sections:
- **Description** — container: a paragraph, what is true when done and why. Story: one sentence; with numbered criteria, 2–4 sentences on how it advances the epic, not restating them.
- **Outcome** — container only: for whom, what changes, the source's success signal named.
- **Requirements** — container: `R<n> (<source ids>): <checkable result>`. Story: by default only `Verify: how it will be checked`. **Full criteria** (bugs, `refine = true` entries, leaves with no entry, or on request) are numbered, each naming the epic ids it proves, **a rule not an instance, with its failure path**:
  ```
  1. **[Behavior name]** (R<m>)
     **Given** [state before] · **When** [the one action] · **Then** [what is observable] · **And** [another observation, if any]
  ```
- **Constraints** — container: design-bending non-negotiables with source. Story: only beyond its epic's.
- **Done when** — container only: three to six end checks, production delivery among them.
- **Boundaries** — container: what it is not; touch points (`Touch point: [unit] — [use]; owner: epic-[slug]`). Story with criteria: adjacent behavior an implementation could break (`Must not change: [behavior]`), not files.
- **References** — `type — location, section`; location a repo path or url, **opened before citing**; cite the nearest document. One line per companion (glossary, design, architecture, prd).
- **Notes** — only what is unsettled and not in repo or source, one marked line each: `Assumption:` · `Open question:` · `Unknown:` (gates the start) · `Parked:` · `Decision:` (dated; declined suggestions too) · `Source conflict:` · `Waits on [epic] because:` · `Dropped:`.

## Rules the template cannot carry
- Criteria are **provable without pointing at code**, together failing any wrong build. Behavior that must not change goes under Boundaries.
- Short plain sentences in the project's vocabulary, no invented terms; offer the user a rewrite where their text breaks this.
- **No source-code paths or snippets unless the snippet is the decision**; a path the user wants kept goes in Notes.
- **A UI ticket links its design in References; criteria stay functional.** User-facing without a design: offer `bmad-ux`; if declined, warn that the builder will guess the layout unless Notes gives details.
- `hitl: true` only when a person does part of the work; name that step.
- **Risk on every ticket**: low / medium / high business impact if wrong, proposed with a one-line reason; the user decides. A high-risk ticket names in Notes one check beyond its criteria.
- Record an `estimate` only when the user gives one; never propose one.
- **Bug**: reproduction steps + cause hypothesis, **never a fix**; run the steps when cheap — if the behavior already holds, show the evidence and create nothing. Criteria name the other valid outcome: proof no change is needed. Severity P0 outage/data loss/security · P1 core broken, no workaround · P2 impaired, workaround · P3 cosmetic. Criterion 2 is always "a test that fails on the defect and passes on the fix covers the reproduction".
- **Spike**: names the question, who waits on it, where the answer goes; `Verify:` lines instead of Given/When/Then; a time box; criteria: candidates compared, prototype shows the answer works, answer recorded where waiting tickets find it, the people who must accept it have.
- Confirm each `Assumption:` with the user; the answer is a dated decision. An `Open question:` is answered during the work. An `Unknown:` gates the start: settle it, or spike it. **Never guess.**

## Review vs Refine
- **Review** (the next story, or more on request): read the file, its epic, finished siblings and their plans; improve ticket, order, prerequisites with the user. Set neither `status` nor `refined`.
- **Refine** (before the ticket starts): read what a review reads **plus the code it touches**. Code contradicting a Requirements line → `Source conflict:` in the owner's Notes; tickets covering that id stay `refined: false` until a `Decision:` settles it. Confirm prerequisites are done or in review; expand to full criteria.
- A ticket that already has full criteria, or a container: confirm the user still agrees, check it against references and the ticket above, settle questions blocking implementation.

## Self-review before the user sees it
Level (an entry: description + verification approach; refined: runnable criteria, settled prerequisites) · size (one agent session) · references open · consistency with the ticket above. Fix, then mention fixes that change intent. On approval a ticket with full criteria gets `refined: true`; then the Ticket check (references open, no placeholders, assumptions marked, nothing contradicts epic/companions/architecture/decisions, each entry has a `verify` a non-builder can run) before a build starts it.
