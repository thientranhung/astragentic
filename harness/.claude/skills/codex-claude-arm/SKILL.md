---
name: codex-claude-arm
description: ARM ONLY — the Claude pass a Codex root fires over a completed artifact: the Builder fires it per ticket from its own worktree, the Shaper fires it at spec, Thomas at slice close. Covers the isolated worktree, the read-only allowlist, cleanup order, and recording. This skill never dispatches a reviewer and never hosts a gate. Use on a Codex root when an artifact is committed and ready for its arm.
---

# The cross-vendor arm on a Codex root

**Scope: one thing — the `claude -p` pass a Codex root fires over a finished artifact.** When
it fires, and the two-pass rule, belong to `thomas.md`, and none of it is restated here. A QA gate's form and report
mechanics belong to `dispatch-ticket/GATE.md`.

The arm always calls the OTHER vendor, so on a Codex root it is a Claude pass.

**Never the reviewer.** Who fires it follows the artifact: the **Builder** fires `arm: ticket`,
the **Shaper** fires `arm: spec`, **Thomas** fires `arm: slice`.

**The ticket scope is NOT symmetric with `codex-arm`, and the difference is load-bearing.** A
Builder firing the Codex arm runs it in its own worktree, because the Codex arm reads — both
its forms report `sandbox: read-only` in their own run header. A
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
OUT="<ticket-worktree>/.scratch/gates/arm-<artifact-key>-<scope>-pass<N>.md"   # tracked .md, never the gate worktree
mkdir -p "$(dirname "$OUT")"
claude -p "<intent-loaded focus; review GATE-DIFF.patch, the net <base>...<head> diff>" \
  --model claude-sonnet-4-6 --allowedTools "Read,Grep,Glob" | tee "$OUT"
```

**The report is captured by `tee` into a tracked file and committed.** Without a redirect the
report exists only on a pane's screen, with no file to lose and none to cite on `Output:`.
`<ticket-worktree>` is the worktree whose branch carries the artifact, never the gate worktree,
which is removed. Commit `$OUT` before the `arm(ticket):` receipt (shape and `Tests:`:
`dispatch-ticket/MARKERS.md`). `GATE-DIFF.patch` and `GATE-LOG.txt` are input evidence, not
the report, and keep the delete-before-remove treatment below.

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
3. **Thomas classifies which findings are real**; the arm advises. When Thomas fired it, he
   routes them to whoever owns the artifact — a ticket to its Builder. When the Shaper fired it
   at spec, the Shaper hands the findings to Thomas with the spec, waits for his classification,
   and folds in its own session (`shaper.md` § Arm); `thomas.md` owns the classification rule. Where pass 1 returned a blocking finding, run pass 2
   under the same contract. Any fix means a new SHA.
4. **Record the arm once** in the decision trail — the vendor that ran, or
   `cross-vendor arm: NOT RUN — <reason>`, which only the OWNER may accept, on the terms
   `thomas.md` sets. Claude unavailable or out of quota means the arm did not run;
   the native lens is advisory.
5. **Exit by artifact, and only one of the three is a merge**: at spec, release the paused
   Shaper to cut tickets; at ticket, verify the artifact, run the required tests and merge on
   a clean final SHA; at slice, the reviewed commits are already on the base branch, so what
   remains is recording the verdict and raising a follow-up ticket for anything unresolved.
