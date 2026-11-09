---
name: codex-cross-vendor-review
description: "Apply Astragentic cross-vendor review policy from a Codex session and fire the configured other-provider reviewer (Claude Code CLI) over a pinned artifact without misrepresenting another OpenAI model as another provider."
---

# Cross-vendor arm from Codex

Read the `## Cross-vendor arm` table in `orchestrator-for-codex.md`; a project's
`.astraler/project/codex.md` may tighten it. `no` is a recorded exemption: no receipt owed,
handback says `Arm: off (orchestrator)`. `unconfigured` is a decision still missing, not off:
stop at that gate, record NOT RUN, ask for the decision. `claude-code` means fire the pass
below. Owner-authorized bounded pre-arm phases may proceed under `codex-dispatch-ticket`
with pending policy/availability and NOT RUN recorded; stricter project policy wins.
Never use Codex review or another OpenAI model as evidence that cross-vendor ran.

Who fires it owns the artifact at that scope: the Builder at `ticket` from its own worktree,
the Shaper at `spec` from a detached checkout at the spec revision, Thomas at `slice` from a
detached checkout at the slice head. At most two passes per gate; the second is mandatory
after a blocking finding, over the whole revised artifact. Remaining blockers go to the
owner; never waive them because two passes were consumed.

## The pass (reviewer `claude-code`)

Define the log first, in the worktree that carries the artifact, never a disposable one:

```bash
SCOPE=ticket          # spec | ticket | slice
KEY=<ticket-or-spec-id>
N=1                   # pass number
BASE=<base sha or branch>
MODEL=<Model cell of the arm table>
OUT=".scratch/gates/arm-$KEY-$SCOPE-pass$N.md"; mkdir -p "$(dirname "$OUT")"
git check-ignore -q "$OUT" && echo "WARN: $OUT is ignored; commit it with git add -f (the log dies with a removed worktree)"
SCHEMA=.codex/astragentic/arm-schema.json
COMMITS=$(git rev-list --count "$BASE"..HEAD); FILES=$(git diff --name-only "$BASE"...HEAD | wc -l | tr -d ' ')
[ "$COMMITS" -gt 0 ] || { echo "STOP: $BASE..HEAD has 0 commits"; exit 1; }
```

Run the reviewer and tee header + result into the one file. `perl alarm` is the timeout
(macOS has no `timeout`); `< /dev/null` stops the CLI waiting on stdin:

```bash
{ echo "arm range: $COMMITS commits, $FILES files changed ($BASE..HEAD) head=$(git rev-parse HEAD) model=$MODEL"
  perl -e 'alarm 900; exec @ARGV' -- claude -p "Adversarial review of the range $BASE..HEAD in this repository against the project's own standard. Owner intent: <one sentence>. Must not break: <list>. Read the diff with 'git diff $BASE...HEAD' and the files it touches. Report defects only; do not modify anything. verdict=block if any blocking finding, else pass. coverage = exactly what you read and did not read." \
    --model "$MODEL" --output-format json --json-schema "$(cat "$SCHEMA")" \
    --tools Read,Grep,Glob,Bash --allowedTools "Bash(git diff *)" "Bash(git log *)" "Bash(git show *)" \
    --permission-mode manual --no-session-persistence --max-budget-usd 1 < /dev/null
  echo "exit=$?"
} 2>&1 | tee "$OUT"
```

Why these flags, measured 2026-11-09 on a planted-defect fixture (`docs/codex/CLAUDE-ARM-PROBE-2026-11-09.md`):
`--restricted` removes Bash despite `--allowedTools`, so the reviewer never saw the diff;
`--permission-mode manual` with no TTY denies Edit and lists it under `permission_denials`
(the tree stayed clean when the prompt ordered an edit); a CLAUDE.md that says "you are the
Builder, fix and commit" was read and refused in 4/4 runs; `--json-schema` returned all three
keys in 4/4 runs; Sonnet 5.5 cost 0.13 to 0.18 USD and 15 to 20 s per pass on a 4-line diff.

## Reading the result

The verdict is `structured_output.verdict` in the JSON the CLI printed, nothing else.
`stop_reason` reads `tool_use` on a complete result; do not read it. Any of these is
`cross-vendor arm: NOT RUN — <reason>` even when the shell exit is 0: no `structured_output`,
`is_error` true, the alarm killed it, a login/quota error on stderr, a budget stop. A
non-empty `permission_denials` goes into the log verbatim and into the handback. Verify the
`head=` in the header is the SHA you hand back; a later commit invalidates the receipt.

Classify each finding with evidence. Fold supported fixes, bump `N`, re-run over the whole
artifact. Record provider `claude-code`, model, range, exit, cost (`total_cost_usd`),
duration and `$OUT` in the handback; commit `$OUT` (with `-f` when ignored) before the handback names it. Clean only resources this invocation created. Do not
emit legacy marker commits or pretend the old runtime's receipt machinery ran.
