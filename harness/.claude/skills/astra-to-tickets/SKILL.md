---
name: astra-to-tickets
description: "Cut a committed spec into tracer-bullet tickets a Builder can take one per session: vertical slices with prerequisite edges, published to the project's tracker in build order. A ticket that changes a surface carries Glance, States and Criteria; every ticket carries its quick/full label. Shaper's Tickets phase; opens on Thomas's release line."
disable-model-invocation: true
---

# To tickets

Thomas's release line is `/astra-to-tickets <spec-id>`. Cut from the spec as committed after
the arm.

## 1. Gather

- The spec: full body and comments, and the spec-stage findings; a ticket that ignores a
  finding is how a finding gets waved through.
- The PRD (`docs/prd.md` or the project's own) for **actor names and FR ids**. Actors live
  there, once; a ticket uses the PRD's name verbatim, never a synonym.
- `docs/qa/plan-<slug>.md` from `test-design`: cut along the slices the plan drew.
- The code the spec touches: where deployment splits, which slices share files. Code that
  contradicts a spec line is a `Source conflict:` note, never silently resolved. Glossary
  vocabulary; respect ADRs.

## 2. Slice

Each ticket is a **tracer bullet**: a narrow but complete path through every layer the work
touches (schema, API, UI, tests), verifiable on its own, sized for **one Builder session in
one fresh context window**. A horizontal slice (one layer, no behaviour) is not a ticket.

- **Prefactoring first**: make the change easy, then make the easy change. An opening
  refactor is its own ticket when code quality calls for one.
- **Tracer bullet first, then the slice the spec is least sure of.** Risk is retired early.
- **Tickets touching the same code form one ordered lane**; an interface two lanes share gets
  a stub as its own early ticket so neither lane waits on the other.
- **Split, never shrink**: "for now", "placeholder", "simplified", "wired later" is a second
  ticket, not a smaller first one.
- **Tests go in every ticket.** The only test-only ticket is a closing end-to-end suite when
  the plan has one. Past three tickets, close with a refactor sweep scoped from deferred findings.

**Edges are prerequisites only**: what must be done for this ticket to start or run its check,
never a restated sequence. Thomas's frontier query reads them; a wrong edge builds too early or
idles a Builder.

**Wide refactors are the exception.** One mechanical change whose blast radius fans across
the codebase (rename a column, retype a shared symbol) cannot land as a slice. Sequence it
**expand** (new form beside the old) → **migrate** in batches sized by blast radius, each a
ticket after the expand, green because the old form still exists → **contract** (delete the
old form, after every batch). When batches cannot stay green alone, they share an integration
branch and precede one integrate-and-verify ticket; green is promised only there.

## 3. Write each ticket

Short plain sentences in the project's vocabulary. **No file paths or code snippets**: they
go stale. Exception: a prototype snippet that IS the decision (state machine, schema, type
shape), trimmed to the decision-rich part.

```markdown
## What to build
One sentence from the actor's seat: what works when this is done. Then 2–4 sentences on how it
advances the spec, not restating it.

## Glance                    ← only when a surface someone looks at changes
- **<Screen or state>:** <actor> must see <X> first; <Y> recedes.

## States                    ← only when a surface changes
- empty: … · loading: … · error: … · partial: … · permission-denied: …
  (one line each; "n/a — <why>" where a state cannot occur)

## Criteria
1. **<Behaviour name>** (FR-n)
   **Given** <actor> <state before> · **When** <the one action> · **Then** <what is observable>
   · **And** <another observation, if any>

## Must not change
- <adjacent behaviour an implementation could break>

## Evidence
1. risky path: yes/no — <which>   2. defect needs a test: yes/no   3. git grep reach: <n> files
Label: quick | full

## Blocked by                ← omit when edges are native on the tracker
- <ids>, or "None (can start immediately)"
```

Rules the template cannot carry:

- **Glance**: one line per screen or state, **exactly one must-see**; two must-sees mean two
  screens, or a priority nobody decided. **States**: the five are the floor; a missing line is
  a state the Builder will guess.
- **Criteria** are rules with their failure path, not instances, and are **provable without
  pointing at code**; together they fail any wrong build. `Given` opens with the PRD's actor
  name. Each names the FR it proves. Criteria stay functional; the look lives in Glance and
  `DESIGN.md`.
- **Evidence and label**: the three questions are `shaper.md` § Spec and tickets; the first
  "yes" is `full`. Thomas never reclassifies; an unlabelled ticket comes back.
- **A UI ticket without `## Glance` and `## States` is not cut.** Thomas's mod refuses to
  brief one (`dispatch-ticket` § The brief), so the ticket would only bounce.
- Notes, one marked line each, only for what is unsettled: `Assumption:` · `Open question:` ·
  `Unknown:` (gates the start; settle or spike it, never guess) · `Source conflict:` · `Decision:` (dated).

## 4. Quiz the owner before anything is published

One message, build order, one line per ticket: title · `after` · what it delivers · **your
reason for the cut** (the rule above that drew it). Then three questions: is the granularity
right (too coarse, too fine)? does each edge gate what it names and nothing else? merge or
split any? Add every `Unknown:` and `Assumption:` you could not settle from the spec, the PRD
or the code. The answer comes back through the pane that dispatched you; whose voice it is
is not your concern. Iterate until the owner says cut. Nothing reaches the tracker before that.

## 5. Publish

Through the project's `*-issue-tracker` skill, **in build order so blockers have real ids
first**, native blocking relation (each tracker skill names its own edge pitfalls), sub-issues
of the spec where the tracker has them. `quick`/`full` as a tracker label; readiness
`needs-triage`, Thomas promotes after he classifies the arm. **Never close or edit the spec or
any parent.**

## 6. Hand back

Ticket ids in build order with their edges, the plan path, the **Set check** (every spec
requirement and plan case lands in a ticket or a named deferral; each FR cited exists; no
cycle, no undeclared prerequisite), and how each spec-stage finding was resolved. Later changes
are made **in place, ids kept**; a dropped ticket gets a `Dropped:` note, never a deletion.
