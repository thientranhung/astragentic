---
name: codex-claude-arm
description: ARM ONLY — the Claude pass a Codex root fires over a completed artifact: the Builder fires it per ticket from its own worktree, Thomas fires it at spec and at slice close. Covers the isolated worktree, the read-only allowlist, cleanup order, and recording. This skill never dispatches a reviewer and never hosts a gate; a Codex root cannot host the gate (see review-with-rin). Use on a Codex root when an artifact is committed and ready for its arm.
---

# The cross-vendor arm on a Codex root

**Scope: one thing — the `claude -p` pass a Codex root fires over a finished artifact.** When
it fires, and the two-pass rule, belong to `thomas.md` and `rin.md`. The gate itself, its
form and its report mechanics belong to `review-with-rin`, and none of it is restated here.

**A Codex root cannot host the gate at all**: the gate is a Herdr pane on the root
provider's runtime, and no Codex adapter can host it, so a `rin` row naming Codex is a
misconfigured row to raise with the owner. The gate runs on a Claude root; this pass is what
a Codex root contributes. The arm always calls the OTHER vendor.

**Never the reviewer.** Who fires it follows the artifact: the **Builder** fires `arm: ticket`,
**Thomas** fires `arm: spec` and `arm: slice`.

**The ticket scope is NOT symmetric with `codex-arm`, and the difference is load-bearing.** A
Builder firing the Codex arm runs it in its own worktree, because `codex exec review` reads. A
Builder firing THIS arm may not: `claude -p` is a full agent with Edit and Bash, so it gets its
own detached worktree even though the Builder is already standing in the reviewed tree. The
range is still correct by construction — the head is the Builder's own `HEAD` — but the
isolation below is not optional and is not something the move removed. Mirroring `codex-arm`'s
ticket path here would hand a writing reviewer the Builder's live checkout (AST-016).

## Isolation is unconditional

`claude -p` is a FULL agent with Edit and Bash, so it runs in its own detached worktree
rather than the shared checkout — the rule explicitly binds read-only reviewers that have
shell access (AST-016). Name it `gate-arm-<artifact-key>`, distinct from the reviewer's own
`gate-<artifact-key>`, so the two can never collide. Commit first.

```bash
set -euo pipefail
git worktree add --detach <repo-root>/.claude/worktrees/gate-arm-<artifact-key> <head-sha>
cd <that worktree>
[ "$(git rev-parse HEAD)" = "<head-sha>" ] || { echo "STOP: HEAD mismatch"; exit 1; }
COMMIT_COUNT=$(git rev-list --count <base>..<head-sha>)
FILE_COUNT=$(git diff --name-only <base>...<head-sha> | wc -l | tr -d ' ')
[ "$COMMIT_COUNT" -gt 0 ] || { echo "STOP: range <base>..<head-sha> has 0 commits — reviewing nothing"; exit 1; }
echo "arm range: $COMMIT_COUNT commits, $FILE_COUNT files changed (<base>..<head-sha>)"
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

1. **Precondition — the artifact is finished and handed back.** Firing early spends one of
   the two permitted passes on something still in motion.
2. Confirm the artifact is COMMITTED, resolve the exact base ref and the FINAL head SHA,
   then run the pass above. A verdict for an older SHA cannot authorize a merge.
3. **You classify which findings are real**; the arm advises. Route them to whoever owns the
   artifact you just reviewed — **a spec goes back to the paused Shaper**, a ticket to its
   Builder — and `rin.md` owns that rule. Where pass 1 returned a blocking finding, run pass 2
   under the same contract. Any fix means a new SHA.
4. **Record the arm once** in the decision trail — the vendor that ran, or
   `cross-vendor arm: NOT RUN — <reason>`, which only the OWNER may accept, on the terms
   `rin.md` sets per artifact. Claude unavailable or out of quota means the arm did not run;
   the native lens is advisory.
5. **Exit by artifact, and only one of the three is a merge**: at spec, release the paused
   Shaper to cut tickets; at ticket, verify the artifact, run the required tests and merge on
   a clean final SHA; at slice, the reviewed commits are already on the base branch, so what
   remains is recording the verdict and raising a follow-up ticket for anything unresolved.
