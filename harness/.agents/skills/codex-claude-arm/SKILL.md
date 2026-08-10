---
name: codex-claude-arm
description: ARM ONLY — the Claude pass a Codex root fires at phase end, after the milestone gate has closed elsewhere. Covers the isolated worktree, the read-only allowlist, cleanup order, and recording. This skill never dispatches a reviewer and never hosts a gate; a Codex root cannot host the gate (see review-with-rin). Use at phase end on a Codex root.
---

# The cross-vendor arm on a Codex root

**Scope: one thing — the `claude -p` pass a Codex root fires at phase end.** When it fires,
and the two-pass cap, belong to the method document. The gate itself, its form and its
report mechanics belong to `review-with-rin`, and none of it is restated here.

**A Codex root cannot host the gate at all**: the gate is a Herdr pane on the root
provider's runtime, and no Codex adapter can host it, so a `rin` row naming Codex is a
misconfigured row to raise with the owner. The gate runs on a Claude root; this pass is what
a Codex root contributes. The arm always calls the OTHER vendor.

**The root leader fires this pass, never the reviewer.**

## Isolation is unconditional

`claude -p` is a FULL agent with Edit and Bash, so it runs in its own detached worktree
rather than the shared checkout — the rule explicitly binds read-only reviewers that have
shell access (FW-016). Name it `gate-arm-<artifact-key>`, distinct from the reviewer's own
`gate-<artifact-key>`, so the two can never collide. Commit first.

```bash
git worktree add --detach <repo-parent>/<repo-dir-name>.worktrees/gate-arm-<artifact-key> <head-sha>
cd <that worktree>
git diff <base>...<head> > <gate-worktree>/GATE-DIFF.patch
git log --oneline <base>..<head> > <gate-worktree>/GATE-LOG.txt
claude -p "<intent-loaded focus; review GATE-DIFF.patch, the net <base>...<head> diff>" \
  --model claude-sonnet-4-6 --allowedTools "Read,Grep,Glob"
```

Two flags carry the whole boundary. Gates run without `--dangerously-skip-permissions`, and
the allowlist stays free of a raw `Bash(...)` prefix: **a prefix is not a read boundary**,
since `git diff --output=<path>` writes, to any absolute path. The DISPATCHER materializes
the diff and log as files and grants only Read, Grep and Glob, so the arm can read
everything it needs and write nowhere. Pin the model ID explicitly — the bare `sonnet` alias
resolves to a different model.

Cleanup is the dispatcher's, and it **deletes the two evidence files first**: `git worktree
remove` refuses a worktree holding untracked files, so keep any transcript you need outside
the gate checkout.

```bash
rm -f <gate-worktree>/GATE-DIFF.patch <gate-worktree>/GATE-LOG.txt
git worktree remove <gate-worktree>      # never --force; a refusal means real state to read
```

The arm never removes its own worktree.

## Sequence

1. **Precondition — the milestone gate has already closed** on the Claude root that hosts
   it. Firing early spends one of the two permitted passes on an artifact still in motion.
2. Confirm the artifact is COMMITTED, resolve the exact base ref and the FINAL head SHA,
   then run the pass above. A verdict for an older SHA cannot authorize a merge.
3. **You classify which findings are real**; the arm advises. Findings route through you to
   the Builder. A second pass is legal only where the first produced blocking findings, and
   it re-reviews the FULL artifact. Any fix means a new SHA.
4. **Record the arm once** in the merge decision trail — the vendor that ran, or
   `cross-vendor arm: NOT RUN — <reason>`, which only the OWNER may accept. Claude
   unavailable or out of quota means the arm did not run; the native lens is advisory.
5. Verify the final artifact, run the repository's required tests, and merge on a clean
   final SHA with the evidence present.
