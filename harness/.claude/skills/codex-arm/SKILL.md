---
name: codex-arm
description: Invocation mechanics for the cross-vendor arm on a Claude root — the Codex pass Thomas fires over a completed artifact. Covers the runtime invocation, argv and quoting gotchas, intent-loaded focus text, failover, and where the outcome is recorded. The BUILDER fires the ticket arm from its own worktree; Thomas fires spec and slice from the base checkout. Never Rin. Cadence lives in thomas.md and builder.md.
---

# The cross-vendor arm on a Claude root

**When it fires belongs to `thomas.md` and `builder.md`, not here** — three scopes, at most two
passes **per gate invocation**. Do not restate the cadence in this file; this skill owns the HOW.
`codex-claude-arm` is the mirror for a Codex root.

**Who fires it depends on the scope**, and it is never Rin — Rin is dispatched per gate and would
otherwise fire the arm from inside its own review.

| Scope | Fired by | Standing in |
|---|---|---|
| `arm: spec` | Thomas | the base checkout |
| `arm: ticket` | **the Builder**, inside its own closed loop | its own worktree, which holds the reviewed commits |
| `arm: slice` | Thomas | the base checkout |

Whoever fires it records which vendor actually ran.

**What the arm wins at: internal inconsistency against the project's own standard**, because
the author reads the ticket and the arm reads the repository. Measured, for why the cadence in
`thomas.md` is per ticket rather than per phase: a slice-scope payload reached 6,904 added
lines across 31 files against 1,238 for one ticket, and three hollow tests survived that skim
in a single day. Pass 2 earns its cost the same way — on one ticket it found a real 40P01
deadlock inside the code pass 1's fix had just added.

## Invocation

Use the plugin runtime; raw `codex exec` is fallback-only, and it has hung.

```bash
node "$CLAUDE_PLUGIN_ROOT/scripts/codex-companion.mjs" adversarial-review --wait --base <ref> <focus words>
node "$CLAUDE_PLUGIN_ROOT/scripts/codex-companion.mjs" review --wait --base <ref>
```

Plugin root: `~/.claude/plugins/cache/openai-codex/codex/<version>`. Run it in the
background; the completion notification is your bell.

### Bind it to the reviewed head, and fail closed

**The companion resolves `HEAD` from the checkout it runs in, and `--base` alone does not say
which head.** Where the two disagree, the run compares the base branch to itself, reads nothing,
and returns **clean** — a mandatory gate that cannot fail. Measured twice in two days, both
caught by the operator rather than the gate (AST-103).

Which apparatus you need depends on **where you are standing**, and the two cases are not
symmetric.

#### At TICKET scope — you are already standing in the reviewed tree

The Builder fires this one, in its own pane, whose cwd **is** the worktree holding the reviewed
commits. `HEAD` resolves to the head under review because there is nowhere else it could
resolve to. **No gate worktree, no broker to kill, no container to stop, no path disambiguator**
— none of the apparatus below applies, because none of it is needed to make the range correct.

Keep the range header, which costs one command and is the thing a reader glances at:

```bash
COMMIT_COUNT=$(git rev-list --count <base>..HEAD)
FILE_COUNT=$(git diff --name-only <base>...HEAD | wc -l | tr -d ' ')
[ "$COMMIT_COUNT" -gt 0 ] || { echo "STOP: range <base>..HEAD has 0 commits — reviewing nothing"; exit 1; }
echo "arm range: $COMMIT_COUNT commits, $FILE_COUNT files changed (<base>..HEAD)"
```

#### At SPEC and SLICE scope — Thomas fires from the base checkout

Here the two can disagree, so resolve the head yourself and review from a detached checkout at
that SHA:

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

**Everything from here to the end of the cleanup rules is SPEC/SLICE apparatus.** A Builder
running the ticket arm has no gate worktree and skips all of it.

**Never reuse a gate worktree path across dispatches.** The companion caches state keyed to
the workspace root; deleting and recreating the directory at the same path inherits stale
configuration that causes a silent failure — exit 0, no review started (AST-095). Append a
disambiguator (`-p2`, a counter, a short token) when a previous gate used that path in this
session.

**Every gate worktree removal must kill its broker first** — not only the final
cleanup, but also the mid-ticket removal between pass 1 and pass 2. Removing
the pass-1 worktree to create the `-p2` worktree orphans the pass-1 broker
(AST-100, measured: every two-pass ticket leaked one process this way).

**The `WorktreeRemove` hook in `.claude/settings.json` calls `scripts/release-worktree-resources.sh`
for you, but field testing (2.3.0) showed the event does not fire on `git worktree remove` or
`ExitWorktree` — confirmed by A/B test with control (SubagentStop fires from the same file, same
minute). Until a probe proves it live, make the call yourself, on ALL runtimes, before every gate
worktree removal — including the mid-ticket removal between pass 1 and pass 2, which orphaned one
broker per two-pass ticket when it was skipped (AST-100).**

In this order, every time you remove a gate worktree:

1. Release what the worktree holds — one call, before the directory is gone:
   ```bash
   scripts/release-worktree-resources.sh "$GATE_WORKTREE"
   ```
   A clean run stamps the path; `hook-git-guard.py` refuses step 2 for an unstamped path, so
   this is enforced, not remembered.
   It reaps every process rooted in the worktree by REAL cwd — the companion's broker
   included, which is why a hand-typed `ps | grep -- '--cwd …'` is not a substitute: that grep
   reported nothing while a live broker had run three hours — and then runs the project's own
   plug, `.astraler/project/cleanup-worktree.sh`, for whatever this project's worktrees
   allocate beyond git. **Never `pkill -f` by name** — it kills every project's brokers on the
   machine (34 were live the night this was measured, including other projects').

   **The plug must scope to THIS worktree and never delegate to a project-level target.**
   Measured 2026-08-19: a documented project teardown target resolved correctly, ran
   correctly, and stopped the project's SHARED test-database container — the one every live
   Builder was standing on, because the project had that day moved to one shared server
   across worktrees. A Builder mid-ticket survived on timing alone (AST-115). When scoping is
   uncertain, release NOTHING — that is the correct direction to fail in; the project-level
   form failed the other way, uncertain about scope and stopping everything it could name.

   **Three outcomes, all spoken, none silent**: released (named by the plug), nothing
   declared (the script's `NOTE:` line — an empty socket, which is not a clean one), or a
   failure (`WARN:`). Do not `|| true` any of them.

   Measured earlier: three surviving database containers took a machine to seven instances;
   a gate returned `signal: killed` on four packages with `FAIL = 0` — resource exhaustion
   wearing the costume of a test failure. Releasing one turned the same command into
   `EXIT=0, 40 ok`.
2. Remove the worktree: `git worktree remove --force <path>`.

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
