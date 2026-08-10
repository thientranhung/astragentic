---
name: codex-arm
description: Invocation mechanics for the cross-vendor arm on a Claude root — the Codex pass Thomas fires at phase end, after the milestone gate. Covers the runtime invocation, argv and quoting gotchas, intent-loaded focus text, failover, and where the outcome is recorded. Thomas fires it, never Rin. Use at phase end, once the milestone gate has closed.
---

# The cross-vendor arm on a Claude root

**When it fires belongs to the method document, not here** — one arm per phase, at phase
end, after the milestone gate has closed, at most two passes. This skill owns the HOW.
`codex-claude-arm` is the mirror for a Codex root.

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

Gotchas, each of which has cost us a run:

- Flags and focus are **separate argv tokens** — one quoted blob fails.
- Focus text takes **no apostrophes and no semicolons** (zsh reads them as `unmatched '` or
  as a command split), and no literal `--flag` (the parser consumes it).
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
OWNER may accept closing the phase without it. Single-provider mode is legal. A same-vendor
lens silently counted as the arm is the thing this rule exists to prevent, so the recorded
vendor is always the one that actually ran.

Record the outcome once, in the phase's decision trail: the date, the verdict, the
per-finding resolution, and the vendor that ran. **You classify which findings are real** —
the arm advises. A second pass is legal only where the first produced blocking findings, and
it re-reviews the FULL artifact rather than only those findings, since a fix can introduce
defects of its own. Escalate to the owner on a genuine fork.
