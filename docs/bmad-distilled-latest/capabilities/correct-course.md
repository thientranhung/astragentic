# 🧭 Correct Course → Sofia replans (upstream main 61e01f8, 2026-10-18)

> `bmad-correct-course` is **retired** (`skills/bmod-method/retired.toml:53`; "Sofia the Product Owner replaces bmad-spec, bmad-ticket and bmad-correct-course", `CHANGELOG.md:15`). Distilled from `skills/bmad-agent-po/references/replan.md`, with the Re-slicing and Close/drop/move rules it calls in `slice.md` and `board.md`, and `help/implementation-skills.md:17`. **The Sprint Change Proposal document, the interactive impact checklist, the Incremental/Batch modes, and the Minor/Moderate/Major routing are gone**: "No proposal file." Machinery (`tickets.py`, tracker, memlog) stripped. Baseline: `docs/bmad-distilled/capabilities/correct-course.md`.

## When
A significant midstream change — a technical limit, a new or misread requirement, a pivot, a failed approach — means talking to Sofia: **"this changed, what now."** A change **after an entry has started** is a replan; before that it is an ordinary requirements update.

## Rule
**Leave the remaining tickets true and nothing already built rewritten.** No proposal file. The user decides the path.

## Steps
1. **Name the change** briefly: what changed, its source and evidence. Read the ticket, its decision log, its breakdown, finished children, and any architecture or design it touches; **ask only what the tree cannot tell you.** Say whether **what is required** changed or only **how it is delivered**, and propose a way forward — **adjust remaining entries, roll back built work, or cut scope** — with the reason; the user decides. An in-progress ticket: ask whether its build stops; **never edit its plan.**
2. **What is required.** If the change alters what the ticket requires, re-derive its Requirements with the change as input: lines re-render **with ids kept**, naming the entries whose `covers` cite a changed id. Otherwise say so and skip.
3. **Re-slice** each affected epic: revise unstarted entries and tickets in place with the user, keeping each `id`; run the Set check before approval; record the reason in the epic's Notes. An obsolete or new epic changes the initiative's breakdown the same way.
4. **Drop** what no longer belongs — only after a `Dropped:` line in its Notes says why; **never delete an entry from an approved breakdown**; remove or repoint the dropped ticket in each dependent's `after`; cancelling a container cancels its descendants once the user confirms. Clear what waited on it.
5. **Record the reason** as a dated `Decision:` line in the Notes of each container touched, in step 1's words. If the architecture spine or design is invalidated, note it in the container's Notes and offer `bmad-architecture` or `bmad-ux`; **never edit the companion.**

Then report what changed, what was dropped, and what is ready.

## Related board moves
- A blocked ticket waiting on a person or an answer carries the reason; an `Unknown:` is settled, removed, and recorded as a dated `Decision:`.
- Moving an entry between epics renumbers it, moves its file and plan, rewrites every `after` naming it; put it in build order by hand and move its `covers` ids with the user if the requirement moves.
- A done standalone ticket stays where it is beside its plan. Historical plans are evidence, never rewritten.
