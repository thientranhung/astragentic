# To tickets — distilled

> From `skills/engineering/to-tickets/SKILL.md` (user-invoked). Break a plan, spec or conversation
> into **tracer-bullet** tickets, each declaring the tickets that **block** it.

## Process
1. **Gather context** from the conversation; fetch any spec path or issue passed as argument, body
   and comments.
2. **Explore the codebase** if not done; use glossary vocabulary; respect ADRs. Look for
   **prefactoring** that makes the change easy: "make the change easy, then make the easy change."
3. **Draft vertical slices.**
   - Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests).
   - A completed slice is demoable or verifiable on its own.
   - Each slice fits one fresh context window.
   - Prefactoring goes first.
   - Give each ticket its **blocking edges**; a ticket with none can start immediately.
4. **Quiz the user**: numbered list, per ticket Title / Blocked by / What it delivers. Ask: granularity
   right? edges correct (each ticket depends only on what genuinely gates it)? merge or split?
   Iterate to approval.
5. **Publish** in dependency order, blockers first, native blocking links where the tracker has
   them; sub-issues of the source issue if there was one. Never close or modify the parent. Work the
   **frontier**: any ticket whose blockers are all done.

## Wide refactors: expand–contract, not tracer bullets
A **wide refactor** is one mechanical change (rename a column, retype a shared symbol) whose blast
radius fans across the codebase so no vertical slice lands green. Sequence it:
1. **Expand**: add the new form beside the old; nothing breaks.
2. **Migrate** call sites in batches sized by blast radius (per package, per directory), each batch a
   ticket blocked by the expand; CI stays green because the old form still exists.
3. **Contract**: delete the old form once no caller remains, blocked by every migrate batch.
If even the batches cannot stay green alone, keep the sequence on a shared integration branch that
all block one final integrate-and-verify ticket; green is promised only there.

## Ticket template (tracker form)
- **Parent** (if any).
- **What to build**: the end-to-end behaviour this ticket makes work, from the user's perspective,
  not a layer-by-layer list.
- **Acceptance criteria**: checkboxes.
- **Blocked by**: references, or "None (can start immediately)"; omit when edges are native.
No file paths or code snippets, same prototype exception as to-spec.
