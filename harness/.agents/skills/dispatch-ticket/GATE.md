# Gate mechanics — a QA gate in an observable pane

Thomas-only. A gate is a reviewer that reads or walks an artifact it did not write, in a pane the owner can watch. These are the mechanics every gate pane shares. `dispatch-qa-walk` adds what a walk needs on top. The method document (`.agents/roles/qa.md`) owns the report schema.

## 1. The brief — QA knows only what you send

A context-starved reviewer judges "clean", never "right". The prompt carries:

- **Artifact** — the base ref and branch, or the reviewed SHA. A verdict is valid only for its SHA.
- **Ticket or spec path** and its acceptance criteria.
- **Owner intent, one paragraph** — what the milestone is for, plus the must-not-break floors. Intent left out of the brief is invisible to the reviewer.
- **UI work** — the design-guidelines pointer and the Builder's browser-verify evidence.
- **`$GATE_FILE`** as an absolute path, and an explicit "stay inside this worktree" line.

## 2. Dispatch

**Resolve `<artifact-key>` first.** It names the tab, the worktree directory, the pane, the agent and the report filename. It is the ticket ID, or the spec or slice slug when no ticket is the subject.

**A gate always runs as a Herdr pane.** If you cannot create one (herdr unreachable, the workspace not nameable, no launcher for the `qa` row's runtime), STOP and tell the owner. A subagent shares your session, so it is not an independent review. A gate nobody can observe is trusted on your word, which is the thing the gate exists to remove.

**The only question is whether you can name the workspace this gate belongs to.** An ambiguous workspace is a STOP. `herdr tab list` answers a different question: a daemon answering proves the daemon is up, not that a workspace is nameable.

**Pane mechanics.** QA gets its own tab `qa:<artifact-key>` and its own **detached** worktree at the reviewed SHA, in the same workspace. Sharing the Builder's worktree destroys independence.

```bash
# --- gate-file setup: FAIL-CLOSED, and the path is unique to THIS dispatch ---
set -euo pipefail            # pipefail is REQUIRED: without it a failed od leaves the token empty
GATE_ROOT="${TMPDIR:-/tmp}/astraler-gates"
case "$GATE_ROOT" in /*) ;; *) echo "STOP: TMPDIR is not absolute"; exit 1 ;; esac
REPO_ROOT="$(git rev-parse --show-toplevel)"
case "$GATE_ROOT/" in "$REPO_ROOT"/*)
  echo "STOP: TMPDIR lies under the repo, cleanup would delete the report"; exit 1 ;;
esac
mkdir -p "$GATE_ROOT"
chmod 700 "$GATE_ROOT"                             # explicit, not inherited
GATE_TOKEN="$(od -An -tx1 -N8 /dev/urandom | tr -d ' \n')"   # unique per dispatch
[ ${#GATE_TOKEN} -eq 16 ] || { echo "STOP: bad gate token"; exit 1; }
GATE_FILE="$GATE_ROOT/<artifact-key>-<short-sha>-$GATE_TOKEN.md"

git worktree prune                         # clear stale registrations
git worktree add --detach \
  <repo-root>/.claude/worktrees/gate-<artifact-key> <reviewed-sha>
git worktree list          # verify the exact path before anything uses it
git -C <gate-worktree> rev-parse HEAD      # must equal <reviewed-sha>, a mismatch is STOP
herdr tab create --workspace <workspace-id> --label "qa:<artifact-key>" \
  --cwd <gate-worktree> --no-focus
herdr pane rename <returned-root-pane-id> "qa:<artifact-key>"
herdr pane get <returned-root-pane-id>    # foreground_cwd gate, a mismatch is STOP
herdr agent start "qa-<artifact-key, lowercased>" --pane <returned-root-pane-id> --timeout 60000 \   # agent names take no uppercase and no ":" (dispatch-ticket § Agent names)
  --kind <qa row: Runtime> -- <argv from the runtime-specific dispatch-ticket skill>
```

**The argv comes from the runtime-specific dispatch skill** (`dispatch-ticket-claude`, `dispatch-ticket-codex` or `dispatch-ticket-opencode`), resolved from the `qa` row's Runtime column in `orchestrator.md`. No adapter for that runtime means STOP.

Every check in that block is fail-closed:

- **Absolute, and not under the repo.** A repo-internal `TMPDIR` puts the report inside a checkout that cleanup deletes, and the report dies with it silently.
- **`mkdir`, `chmod` and the token are STOPs**, not best-effort. A tolerated failure is setup that "ran" without landing.
- **`pipefail` and the length check keep the token from becoming empty.** An empty token collapses the path back to the deterministic form the token exists to prevent.
- **The token is the whole freshness mechanism.** The path cannot pre-exist, so a file at it proves this dispatch wrote it. No mtime comparison, no BSD versus GNU `stat`. Two dispatchers gating the same SHA get different paths.

The pane form needs QA to write exactly one file outside every checkout, so a runtime that denies all writes cannot serve a gate pane. That is a misconfigured row to raise with the owner. A gate runs without `--dangerously-skip-permissions`.

**Deliver the brief through the mod on a Claude root** — one `SendMessage` whose first line is
the slash command, as `dispatch-ticket-claude` says; the pane answers `RECEIVED` and records the
brief's `Mode:` line. `herdr agent prompt` is the form for a Codex or OpenCode pane, and the
fallback when the mode class holds the message; a brief delivered that way records no mode and the
pane's band shows none:

```bash
herdr agent prompt qa-<artifact-key> "<brief>"
```

A peer message to a session that runs under permissions is held for approval on its side, and the sender gets `success: true`. The pane sits idle, which reads exactly like a gate that started and found nothing. `agent prompt` is typed input and crosses no permission boundary. It addresses the pane by agent name, so the launch must register one.

## 3. Collect the report

**The pane cannot carry the report.** A pane read returns only the visible row count and still reports success. Gate reports routinely run past 300 lines.

- **QA writes the full report to `$GATE_FILE`**, the absolute path you created and named.
- **QA prints to the pane only** the verdict line, the blocking and non-blocking counts, and one line per blocking finding. That keeps the gate observable.
- **You copy `$GATE_FILE` into the gate history and verify it before cleanup.**

The report lives outside every checkout because you delete the gate worktree at cleanup. It lives under `${TMPDIR:-/tmp}` rather than bare `/tmp` because `$TMPDIR` is per-user `0700` on macOS and `/tmp` is world-readable. Reports quote code and production measurements, so `no-secrets-in-exports` binds them.

```bash
# after the pane reports, BEFORE any cleanup, all fail-closed
set -euo pipefail
test -s "$GATE_FILE"                                          # exists and non-empty
GATE_HISTORY="$(git rev-parse --show-toplevel)/.astraler/state/gate-history"
mkdir -p "$GATE_HISTORY"
DEST="$GATE_HISTORY/<artifact-key>-<mode>-<short-sha>.md"   # mode: walk | probe | verify | arm — two QA modes on one SHA are two runs
[ -e "$DEST" ] && { echo "STOP: $DEST exists, a concurrent gate on the same artifact, mode AND SHA; take it to the owner"; exit 1; }
cp "$GATE_FILE" "$DEST"
test -s "$DEST"                                               # MUST pass before cleanup
rm -f "$GATE_FILE"                                            # only what THIS dispatch made
```

**The destination is deliberately not tokenized, so it refuses to overwrite.** The gate history answers "why did we merge this SHA" months later, and a hex blob per filename would damage that. An existing destination means two gates converged on one artifact and SHA, which is the owner's call.

**A missing or empty file is a failed gate: re-dispatch.** A fresh dispatch takes a fresh token. A verdict you cannot read in full is not a verdict, and there is no subagent to fall back to. On opencode `idle` is fabricated, so collecting the file is what ends the gate.

**Evidence goes to files. Panes and replies carry pointers and headlines.** A verdict held only in your context dies at the next compaction.

**Read the artifact rather than the author's account of it.** A summary saying a finding was folded is not evidence the body changed: grep the body.

## 4. Cleanup

Thomas's, after the report. Collect and verify `$GATE_FILE` first, then `herdr tab close <gate-tab-id>`, confirm the pane is gone, then `git worktree remove <gate-worktree>`, plain and never `--force`. A read-only reviewer writes nothing inside the tree, so the remove succeeds. A refusal is a signal: git refuses only on modified or untracked files, so inspect what was written before anything else. A gate that starts an app (`dispatch-qa-walk`) is the exception and has its own ordered cleanup.
