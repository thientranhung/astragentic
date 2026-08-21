---
name: batch-triage
description: Triage an inherited backlog in one pass — many existing issues at once, rather than one new item at a time. Classifies each by reading its own content and the code it names, dedupes, marks the stale, and produces tracker tickets with labels and blocking edges. Invoke by name when adopting a repo that arrives with a backlog.
---

# Batch-triage an inherited backlog

The plugin's `triage` handles one item arriving now. An inherited backlog is a different
shape: a hundred items of unknown age, written by people who are not here, about code that
has moved since. This skill is the one-pass version, and its output feeds Thomas's frontier.

**Extract, never invent.** Every classification cites the item's own text or the code it
names. An item you cannot classify from evidence is classified `NEEDS-OWNER`, which is a real
outcome and takes one line.

## 1. Read the vocabulary first

Load `docs/agents/triage-labels.md` — the label set is the project's, produced by
`setup-matt-pocock-skills`, and inventing a parallel vocabulary here would fork it.

**Then read the tree, not a map of it.** Most triage decisions turn on whether the code an
item names still exists, so resolve each item against the CURRENT tree with `rg` and `git
log`. A map would be faster and would also be the thing most likely to be stale exactly
where triage needs it: on code that moved
or died.

## 2. Classify each item against the code

For each item, answer three questions in order. The first that resolves it wins, so most
items cost very little.

1. **Does the thing it describes still exist?** Grep for the files, symbols and routes it
   names. Nothing left → `STALE`, citing what you searched for and did not find. This is the
   largest category in most inherited backlogs and the cheapest to establish.
2. **Has it already been done?** Check the code and `git log` for the change it asks for.
   Already there → `DONE`, citing the commit or the file.
3. **Is it a duplicate?** Group by the code path and the symptom rather than by title —
   inherited backlogs duplicate heavily under different wording. Keep the item with the most
   evidence, and record the others as duplicates pointing at it.

What survives is live. Label it from the project's vocabulary, and size it: does it fit one
ticket, or is it an effort needing `wayfinder` and a Shaper session? Record which.

**Where the evidence is genuinely ambiguous, `NEEDS-OWNER` is the answer.** A confident guess
on a hundred items produces a confidently wrong backlog, and the owner cannot see which
decisions were guesses.

## 3. Write the results

Produce, in one report before touching the tracker:

- counts per class, so the owner sees the shape of what they inherited;
- the `STALE` and `DONE` lists with their evidence, since these are closures and closing
  something that was real is the expensive mistake here;
- the duplicate groups;
- the live items with proposed labels and sizes;
- the `NEEDS-OWNER` list.

**Closures wait for the owner.** Everything else you can act on: create the live tickets with
their labels, and set blocking edges where one item plainly depends on another — those edges
are what Thomas's frontier query reads, so an edge left out is a ticket that becomes ready
too early.

Leave every created ticket **unassigned**. Assignment is the claim, it belongs to Thomas at
dispatch time, and pre-assigning here would hand out claims nothing is ready to act on.

## 4. What this produces for the rest of the method

A backlog that has been read against the code, with its dead weight identified and its
dependency edges set. Thomas can run a frontier query against it immediately, which is the
point: an inherited backlog with no edges has no frontier, so every ticket looks ready and
the ordering falls back to guesswork.

Where the backlog is large enough that one pass cannot finish it, batch by area rather than
by age, and report where you stopped. An area triaged completely is usable; a backlog triaged
10% evenly is not.
