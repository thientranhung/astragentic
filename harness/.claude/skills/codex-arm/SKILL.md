---
name: codex-arm
description: Invocation mechanics for the cross-vendor arm on a Claude root — the Codex pass Thomas fires over a completed artifact. Covers the runtime invocation, argv and quoting gotchas, intent-loaded focus text, failover, and where the outcome is recorded. Thomas fires it, never Rin. Cadence lives in thomas.md; it is per ticket, at handback, before the merge, plus one at spec and one at slice close.
---

# The cross-vendor arm on a Claude root

**When it fires belongs to `thomas.md`, not here** — three scopes, at most two passes each.
Do not restate the cadence in this file; this skill owns the HOW. `codex-claude-arm` is the
mirror for a Codex root.

## Why per ticket, so nobody reverts it as a mistake

The arm ran at phase end until a project measured the payload it builds. At slice scope one
measured slice reached **6,904 added lines across 31 files**, against **1,238 for a single
ticket** — about six times. A payload that size forces the reviewer to skim, and skimming is
how a hollow test survives: three survived in one day on that project, each of them plainly
visible at single-ticket scope, all three caught by hand at the merge rather than by any
gate. The first per-ticket arm returned a HIGH the author's own mutation pass had missed — a
destructive reset authorizing outside its write transaction, while an established fence in
the same codebase rechecks inside. **That is the class the arm wins at: internal
inconsistency against the project's own standard**, because the author reads the ticket and
the arm reads the repository.

The second pass earns its cost the same way, and it is why `rin.md` makes it mandatory rather
than advisory: on one ticket pass 1 found authorization outside the write transaction, the
fix added transaction and locking code, and **pass 2 found a real 40P01 deadlock cycle inside
that new code**. Nobody had looked at it, because it did not exist when pass 1 ran.

**Thomas fires it, never Rin.** Rin is dispatched per gate and would fire the arm from
inside its own review. Thomas also records which vendor ran.

## Invocation

Use the plugin runtime; raw `codex exec` is fallback-only, and it has hung.

```bash
node "$CLAUDE_PLUGIN_ROOT/scripts/codex-companion.mjs" adversarial-review --wait --base <ref> <focus words>
node "$CLAUDE_PLUGIN_ROOT/scripts/codex-companion.mjs" review --wait --base <ref>
```

Plugin root: `~/.claude/plugins/cache/openai-codex/codex/<version>`. Run it in the
background; the completion notification is your bell.

### Bind it to the reviewed head, and fail closed

**The companion resolves `HEAD` from the checkout it runs in, and `--base` alone does not
say which head.** At the ticket fire point you are resident in the base checkout while the
reviewed commits are still in the Builder's worktree, unmerged — so the run compares the base
branch to itself, reads nothing, and returns **clean**. The mandatory arm becomes a check that
cannot fail, at the one moment the ticket is about to merge on its verdict.

It is only the ticket scope that exposes this. At slice scope the commits are already on the
base branch, which is why the old phase-end invocation never met it.

So resolve the head yourself, review from a detached checkout at that SHA, and **verify the
range before you trust the verdict**:

```bash
git worktree add --detach <repo-parent>/<repo-dir-name>.worktrees/gate-arm-<key> <head-sha>
cd <that worktree>
git rev-list --count <base>..<head-sha>   # zero commits means you are reviewing nothing
```

A count of zero, or a changed-file set that is not the artifact you meant to review, is a
STOP — not a pass. Remove the worktree when the pass is recorded; the arm never removes the
Builder's.

Gotchas, each of which has cost us a run:

- Flags and focus are **separate argv tokens** — one quoted blob fails.
- Focus text is unquoted, word by word, so **avoid every shell/glob-special character**, not
  a specific list of them — apostrophes and semicolons split or unterminate the command;
  parentheses, brackets, `*` and `?` are zsh glob syntax and fail with `no matches found`
  before the command even runs (measured: a focus word `option (a)` never reached node —
  no process started, no output file created, nothing to read). Naturally-written focus text
  reaches for `(a)`, `(inert)` and similar constantly, so this is not a rare edge case. No
  literal `--flag` either (the parser consumes it).
- **A missing output file is NOT RUN, the same as an output file with zero `Verdict:`
  lines** — check for the file's existence before trusting its content, not only the content
  once it exists. A shell parse error from the gotcha above kills the whole command before
  node starts: no crash surfaces where you are watching, no file is written, and the ONLY way
  to catch it is to have checked that a file exists at all. This is the exact silent-non-run
  failure mode the rest of this section exists to prevent, from a cause outside Codex itself.
- **Focus goes to `adversarial-review` only.** Plain `review` takes no focus, so pack the
  intent into the adversarial pass.
- Commit first and scope with `--base <ref>`. Focus text steers the prompt; it is advisory,
  and it filters nothing.

## Focus text carries the OWNER INTENT

The pass is only as good as this. An intent-blind pass finds internal inconsistencies; an
intent-loaded pass finds betrayals of what the owner actually wants — a
production-database-wipe critical surfaced only once intent was packed in. Structure it as:
(1) the owner's goals in plain words, (2) the safety floors and must-not-break list, (3) the
instruction to attack the diff AGAINST THAT INTENT.

## Failover and recording

Codex unavailable or out of quota → **the arm DID NOT RUN.** Rin's own fresh-context lens is
advisory and never completes it: record `cross-vendor arm: NOT RUN — <reason>`, and only the
OWNER may accept proceeding without it, on the terms `rin.md` sets for the artifact under
review — they are not the same at spec, ticket and slice. Single-provider mode is legal. A
same-vendor
lens silently counted as the arm is the thing this rule exists to prevent, so the recorded
vendor is always the one that actually ran.

Record the outcome once, in the merge decision trail: the date, the verdict, the per-finding
resolution, and the vendor that ran. **You classify which findings are real** — the arm
advises. Where pass 1 returned a blocking finding, **run pass 2 under the rule in `rin.md`** —
that contract owns when it is required and what it must cover, and this file does not restate
it in weaker words. Escalate to the owner on a genuine fork.
