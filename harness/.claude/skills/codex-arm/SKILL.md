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
set -euo pipefail
git worktree prune                         # clear stale registrations BEFORE add (AST-096)
git worktree add --detach <repo-root>/.claude/worktrees/gate-arm-<key> <head-sha>
cd <that worktree>
[ "$(git rev-parse HEAD)" = "<head-sha>" ] || { echo "STOP: HEAD mismatch"; exit 1; }
COMMIT_COUNT=$(git rev-list --count <base>..<head-sha>)
FILE_COUNT=$(git diff --name-only <base>...<head-sha> | wc -l | tr -d ' ')
[ "$COMMIT_COUNT" -gt 0 ] || { echo "STOP: range <base>..<head-sha> has 0 commits — reviewing nothing"; exit 1; }
echo "arm range: $COMMIT_COUNT commits, $FILE_COUNT files changed (<base>..<head-sha>)"
```

**The first line of arm output must state the range.** A review of 0 commits and a review
of 40 commits look identical once the verdict line prints — the header is what makes the
silent-empty-range failure visible to a reader who glances at the top. Two incidents in two
days were caught by the operator, not the gate, because nothing in the output distinguished
a real review from a vacuous one.

**Never reuse a gate worktree path across dispatches.** The companion caches state keyed to
the workspace root; deleting and recreating the directory at the same path inherits stale
configuration that causes a silent failure — exit 0, no review started (AST-095). Append a
disambiguator (`-p2`, a counter, a short token) when a previous gate used that path in this
session.

**Every gate worktree removal must kill its broker first** — not only the final
cleanup, but also the mid-ticket removal between pass 1 and pass 2. Removing
the pass-1 worktree to create the `-p2` worktree orphans the pass-1 broker
(AST-100, measured: every two-pass ticket leaked one process this way).

**The `WorktreeRemove` hook in `.claude/settings.json` is intended to automate steps 1-2,
but field testing (2.3.0) showed it does not fire on `git worktree remove` or
`ExitWorktree` — confirmed by A/B test with control (SubagentStop fires from the same
file, same minute). Until the hook is proven live by probe, treat steps 1-3 below as
required on ALL runtimes.**

In this order, every time you remove a gate worktree:

1. Kill the companion's broker process. Find it by verifying each PID's `--cwd`
   matches the gate worktree path — **never `pkill -f` by name**, which kills
   every project's brokers on the machine (34 were live the night this was
   measured, including other projects'):
   ```bash
   broker_pid=$(ps -eo pid=,command= | grep "app-server-broker.mjs" \
     | grep -- "--cwd $GATE_WORKTREE" | awk '{print $1}')
   [ -n "$broker_pid" ] && kill "$broker_pid" 2>/dev/null
   ```
2. Stop the gate worktree's database container, if the project uses one.
   Same rule: stop only the container whose compose project matches this
   worktree, not a blanket `docker compose down`:
   ```bash
   db_mk=$(find "$GATE_WORKTREE" -maxdepth 3 -name Makefile -not -path '*/node_modules/*' \
     -exec grep -l '^db-down:' {} + 2>/dev/null | head -1)
   if [ -n "$db_mk" ]; then
     make -C "$(dirname "$db_mk")" db-down 2>&1 || echo "WARN: db-down failed for $db_mk"
   else
     echo "WARN: no db-down target found under $GATE_WORKTREE"
   fi
   ```
   **Find the Makefile, do not assume the worktree root.** `make -C "$GATE_WORKTREE" db-down`
   was shipped for weeks and never once ran: the target lives in a package directory
   (`apps/server`), so make answered `No rule to make target` every time. `|| true` hid it
   until 2.3.3 removed it (AST-109).

   **Do not `|| true` or `2>/dev/null` this command** — both swallow the failure and its
   reason, leaving containers running while the operator believes cleanup succeeded.
   Measured: an operator ran the `|| true` form after every gate for a full day and
   ended with 3 orphaned containers (AST-105).

   Measured earlier: three surviving Postgres containers took a machine to seven
   instances; a gate returned `signal: killed` on four packages with
   `FAIL = 0` — resource exhaustion wearing the costume of a test failure.
   Stopping one container turned the same command into `EXIT=0, 40 ok`.
3. Remove the worktree: `git worktree remove --force <path>`.

The arm never removes the Builder's worktree.

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
- **The companion exits 0 on configuration failure** (AST-095). `failed to load
  configuration` prints and the process ends clean. Never branch on the companion's exit
  code; the output file is the ONLY trustworthy signal.
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
resolution, the vendor that ran, and a **`Tests:` line** — `RAN` when the arm executed the
project's test suite, `NOT RUN — <reason>` when it could not (read-only sandbox, missing
dependencies, test runner failure). A code-reading-only verdict is still valuable — measured
arm passes have found real defects by reading alone — but a Thomas who does not check this
line will merge believing tests ran on the other vendor's side. **You classify which findings
are real** — the arm advises. Where pass 1 returned a blocking finding, **run pass 2 under the rule in `rin.md`** —
that contract owns when it is required and what it must cover, and this file does not restate
it in weaker words. Escalate to the owner on a genuine fork.
