---
name: review-with-rin
description: Thomas-only recipe to run Rin's milestone gate as an observable Herdr gate pane — brief, dispatch, collect the report, classify. Use when a spec is finalized, a ticket/PR or epic closes, or the owner asks for a Rin review.
---

# Review with Rin — one round per milestone, in an observable pane

Preconditions: you are **Thomas**. Rin's contract: `.agents/roles/rin.md`.

Rin is the second opinion at a milestone, and fires there only: a finalized spec
(`mode=adversarial`), a ticket/PR or epic close (`mode=code-review`). Per-ticket review is
`mattpocock-skills:code-review`'s two axes plus the increment simplify pass, and it is complete on its own.

**One round per milestone.** Rin verifies the artifact and that the process left its traces.
A design-level blocking finding goes to the OWNER through `to-questionnaire` — the question
it raises is a decision, and another review round is the wrong instrument for a decision.
Everything else Thomas classifies and the Builder folds. The prior package looped here and
measured 5 to 14 rounds, a large share of them the loop repairing its own earlier rounds.

## 1. Pack the brief — Rin knows ONLY what you send

A context-starved reviewer judges "clean", never "right". The prompt carries:

- (a) **Mode** — `adversarial` (a finalized, COMMITTED spec; pass the path plus base ref) or
  `code-review` (pass explicit base and branch; Rin reviews `git diff <base>...<branch>`,
  three-dot, so it works from a detached worktree whatever its HEAD).
- (b) **Spec/ticket path** and acceptance criteria.
- (c) **Owner intent, one paragraph** — what the milestone is FOR, plus the must-not-break
  floors. Intent left out of the brief is invisible to the reviewer.
- (d) UI work: the design-guidelines pointer plus the Builder's browser-verify evidence.

## 2. Dispatch

**Resolve `<artifact-key>` first — it names everything this gate creates**: the tab, the
worktree directory, the pane, the agent and the report filename. For `adversarial` it is the
spec's slug; for `code-review` it is the ticket ID. A gate is not always about a ticket, so
a plan gate that borrowed a ticket key would file its report where nobody looks.

**Rin always runs as a Herdr GATE PANE.** Cannot create a pane — herdr unreachable, the
workspace not nameable, no launcher for the `rin` row's runtime → **STOP and tell the
owner.** Two reasons, the second stronger: a subagent shares your session, so it is not
structurally an independent review; and a gate nobody can observe is trusted on your word,
which is the thing the gate exists to remove. The pane is also the only form the tracked
watcher can watch. This adds no dependency — `check-requirements.sh` already treats herdr as
hard-required.

The earlier lookup ("is there a live ticket tab?") is superseded: a spec is gated BEFORE its
tickets exist, so it answered "no" every time and made every spec gate a subagent — invisible,
at exactly the milestone where design decisions get made (AST-033).

**The only question is: can I name the workspace this gate belongs to?** An ambiguous
workspace is a STOP. `herdr tab list` answers a different question — a daemon answering proves
the daemon is up, not that a workspace is nameable — and `HERDR_ENV` is absent for Thomas by
design.

**Consequence for the `rin` row.** The pane form requires Rin to write exactly one file
outside every checkout (§3), so a runtime whose permissions deny all writes cannot serve a
pane gate, and such a row is a misconfigured row to raise with the owner (AST-030). Rin's
runtime matches the ROOT runtime, and the cross-vendor coverage is the arm, never this cell.
Rin has **no fallback row** — an absent row is the correct state and adaptation preserves
it: no root runtime that can host the gate means STOP, not a degraded gate. Sandboxes stay
as they are; an enforced read-only posture is what makes such a reviewer worth having.

**Pane mechanics.** Rin gets its OWN tab `rin:<artifact-key>` and its OWN **detached**
worktree at the reviewed SHA, in the same workspace. Sharing the Builder's worktree destroys
independence and puts a shell-capable reviewer inside the author's checkout.

```bash
# --- gate-file setup: FAIL-CLOSED, and the path is unique to THIS dispatch ---
set -euo pipefail            # pipefail is REQUIRED — see the token note below
GATE_ROOT="${TMPDIR:-/tmp}/astraler-gates"
case "$GATE_ROOT" in /*) ;; *) echo "STOP: TMPDIR is not absolute"; exit 1 ;; esac
REPO_ROOT="$(git rev-parse --show-toplevel)"
case "$GATE_ROOT/" in "$REPO_ROOT"/*)
  echo "STOP: TMPDIR lies under the repo — cleanup would delete the report"; exit 1 ;;
esac
mkdir -p "$GATE_ROOT"
chmod 700 "$GATE_ROOT"                             # explicit, not inherited — see §3
GATE_TOKEN="$(od -An -tx1 -N8 /dev/urandom | tr -d ' \n')"   # unique per dispatch
[ ${#GATE_TOKEN} -eq 16 ] || { echo "STOP: bad gate token"; exit 1; }
GATE_FILE="$GATE_ROOT/<artifact-key>-<short-sha>-$GATE_TOKEN.md"

git worktree prune                         # clear stale registrations (AST-096)
git worktree add --detach \
  <repo-root>/.claude/worktrees/gate-<artifact-key> <reviewed-sha>
git worktree list          # verify the exact path before anything uses it (AST-028)
git -C <gate-worktree> rev-parse HEAD      # must equal <reviewed-sha> — mismatch is STOP
herdr tab create --workspace <workspace-id> --label "rin:<artifact-key>" \
  --cwd <gate-worktree> --no-focus
herdr pane rename <returned-root-pane-id> "rin:<artifact-key>"
herdr pane get <returned-root-pane-id>    # foreground_cwd gate — mismatch is STOP (AST-028)
herdr agent start "rin-<artifact-key>" --pane <returned-root-pane-id> --timeout 60000 \
  --kind <rin row: Runtime> -- <argv from the runtime-specific dispatch-ticket skill>
```

**The argv comes from the runtime-specific dispatch skill** (`dispatch-ticket-claude`,
`dispatch-ticket-codex` or `dispatch-ticket-opencode`), resolved from the `rin` row's Runtime
column in `orchestrator.md`. No adapter for the needed runtime → STOP and tell the owner.

**The brief names `$GATE_FILE` as an absolute path.** You create the directory and you name
the file; Rin writes to what you named.

Every check in that block is fail-closed, and each earns its place:

- **Absolute, and not under the repo.** A relative or repo-internal `TMPDIR` puts the report
  inside a checkout that cleanup deletes, so the report dies with it, silently. *Known
  unhandled, deliberately:* a `TMPDIR` symlinked into the repo, and repo roots other than
  this one. Resolving symlinks and enumerating every worktree root is a heavier mechanism
  than the risk earns.
- **`mkdir`, `chmod` and the token are STOPs, not best-effort** — a tolerated failure here
  is setup that "ran" without landing, exactly what the collection check exists to catch.
- **`pipefail` and the length check keep the token from silently becoming EMPTY.** `set -e`
  alone misses a mid-pipeline failure: `od` fails, `tr` still exits 0, and `$GATE_TOKEN` is
  empty — collapsing the path back to the deterministic form the token exists to prevent.
  Verified: `set -e` yields `len=0` and survives; `set -euo pipefail` aborts (AST-032).
- **The token is the whole freshness mechanism.** The path cannot pre-exist, so existence at
  it IS proof this dispatch produced it — no mtime comparison, and so no dependency on
  `stat -f` (BSD) versus `stat -c` (GNU). It also makes concurrent dispatchers safe: two
  roots gating the same SHA get different paths and cannot read or delete each other's.

Gates run without `--dangerously-skip-permissions`. The brief carries everything §1 lists,
plus `$GATE_FILE`, plus an explicit "stay inside this worktree" line.

Cleanup is Thomas's, after the report: **collect and verify `$GATE_FILE` FIRST** (§3) →
`herdr tab close <gate-tab-id>` → confirm the pane is gone → `git worktree remove
<gate-worktree>` (plain, never `--force`). Rin writes nothing inside the gate worktree and
removes nothing, so the tree stays clean and the remove succeeds. **A refusal is a signal** —
git refuses only on modified or untracked files, so inspect what was written before doing
anything else.

## 3. Collect the report

**The pane cannot carry the report, so it does not have to.** A pane read returns only the
visible ROW COUNT — no `--lines` value or `--source` gets past it — and it reports SUCCESS
while doing so. A gate pane at `viewport_rows: 60` was measured against gate reports
routinely running 300+ lines. Re-dispatching is no remedy: the second report is just as
unreadable.

- **Rin writes the FULL report to `$GATE_FILE`** — the absolute path you created and named.
- **Rin prints to the pane only** the verdict line, the blocking/non-blocking counts, and
  one line per blocking finding. That is what keeps the gate observable to the owner.
- **You copy `$GATE_FILE` into the gate history and verify it BEFORE cleanup.**

**Outside every checkout, and `${TMPDIR:-/tmp}` rather than bare `/tmp`.** You delete the
gate worktree at cleanup, so the report lives outside it. On macOS `/tmp` is `1777` and
anything under it is world-readable, while `$TMPDIR` is per-user `0700`. Gate reports quote
production measurements and code, so `no-secrets-in-exports` binds them — hence the explicit
`chmod 700` (AST-015).

```bash
# after the pane reports, BEFORE any cleanup — all fail-closed
set -euo pipefail
test -s "$GATE_FILE"                                          # exists and non-empty
GATE_HISTORY="$(git rev-parse --show-toplevel)/.astraler/state/gate-history"
mkdir -p "$GATE_HISTORY"
DEST="$GATE_HISTORY/<artifact-key>-<short-sha>.md"
[ -e "$DEST" ] && { echo "STOP: $DEST exists — concurrent gate on the same artifact AND
  SHA; take it to the owner"; exit 1; }
cp "$GATE_FILE" "$DEST"
test -s "$DEST"                                               # MUST pass before cleanup
rm -f "$GATE_FILE"                                            # only what THIS dispatch made
```

**The token IS the freshness check.** With a deterministic filename a re-dispatch reuses the
same key and SHA, so a Rin that never wrote would leave the previous file in place and
`test -s` would pass on it — a check that cannot fail, blessing a stale verdict as this
round's (AST-032).

**The destination is deliberately NOT tokenized, so it refuses to overwrite.** The gate
history is durable and human-readable — it answers "why did we merge this SHA" months later —
and a hex blob per filename would damage that. An existing destination means two gates
converged on the same artifact AND SHA: pathological, and the owner's call.

**A missing or empty file is a FAILED gate: re-dispatch** (a fresh dispatch takes a fresh
token). A verdict you cannot read in full is not a verdict, so a report reconstructed from the
pane is not one either, and there is no subagent to fall back to. On opencode `idle` is
fabricated — collecting the file is what ends the gate.

The rule generalizes: **evidence goes to files; panes and replies carry pointers and
headlines.** A verdict held only in your context dies at the next compaction, which is the
second reason the file exists.

**The report schema has one owner: the method document.** Check the returned report against
it there rather than against a copy here — a restatement drifts, and the prior package's
already had. A verdict is valid only for its SHA.

**Read the artifact rather than the author's account of it.** A summary table saying a
finding was folded is not evidence the body changed: grep the body. Three times in one session
findings were recorded as folded while the text was untouched, all three caught only by
refusing the summary as proof.

## 4. Act on the findings

**Rin advises, YOU classify, the artifact's owner fixes.** Rin labels each finding blocking or
non-blocking; that label is advice, and treating one as real is your decision.

- **Design-level blockers → the owner, via `to-questionnaire`.** These are decisions, and a
  second review round cannot make a decision. Record the question and the artifact it blocks.
- **Everything else → your work order to whoever owns what was gated.** At a spec gate that is
  the **paused Shaper**, which repairs and re-commits the spec — no Builder exists yet, and
  naming one here is how a spec finding dead-ends. At a ticket or PR gate it is that ticket's
  **Builder**, in its own pane. Either way the middle link is a JUDGEMENT, not a relay: a raw
  findings list is not a work order.
- **wontfix-with-a-recorded-reason is a legitimate outcome**, and the check that keeps it
  honest is that the reason survives being written down. Write it in the gate record.

**You are relaying, not classifying, if you have overruled nothing.** The symptom is
countable: a dispatcher who has rejected or deferred no finding at all is relaying, wearing
diligence. One measured run reached 35 findings accepted and 0 overruled before anyone
noticed. Count your own overrules; a run of zero is a prompt to re-read the findings as a
judge.

Fixes produce a new SHA. Verify the fold by artifact — the diff, not the summary. **Then the
cross-vendor arm, which is yours to fire**: run it over that final SHA and resolve what it
returns, pass 2 included under `rin.md`'s rule. Cadence lives in `thomas.md`, mechanics in
`codex-arm`.

**How the gate exits depends on which artifact it gated**, and only one of the three ends in
a merge:

| Gated | Exit |
|---|---|
| a spec (`mode=adversarial`) | release the **paused Shaper** to cut tickets — there is nothing to merge |
| a ticket or PR | **merge**, and only on a SHA the arm has actually seen |
| an epic close | report to the owner; the merges it covers already happened |

Merging straight out of this gate is how a ticket reaches the base branch with no arm on it,
and closing a spec gate without releasing the Shaper leaves a live session waiting forever.
