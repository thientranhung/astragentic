---
title: codex-claude-arm
oneLiner: "Run a Claude pass over a finished artifact when the root session runs on Codex."
group: gate
order: 3
runtimes: [codex]
source: harness/.agents/skills/codex-claude-arm/SKILL.md
rented: false
diagram: cross-vendor-arm
lang: en
updated: 2026-09-04
---

## What it does

`codex-claude-arm` does one thing: the `claude -p` pass a Codex root runs over an artifact that is
already finished and committed. It covers the isolated worktree, the read-only allowlist, the
cleanup order and the recording, and nothing else. When the arm runs, and the two-pass rule that
bounds it, belong to `thomas.md` and `rin.md`. The gate itself belongs to `review-with-rin`. The
arm always calls the *other* vendor, so on a Codex root it calls Claude.
<!-- source: harness/.agents/skills/codex-claude-arm/SKILL.md -->

The thing worth knowing before anything else is a boundary, not a step: **a Codex root cannot host
the gate at all.** The gate is a Herdr pane on the root provider's runtime, and no Codex adapter
can host one, so a `rin` row in `orchestrator.md` naming Codex is a misconfigured row. Raise it
with the owner rather than working around it. What a Codex root contributes is this pass. The
second difference is quieter and cost more: **the ticket scope is deliberately not symmetric with
`codex-arm`.** A Builder running the Codex arm does it inside its own worktree, because
`codex exec review` only reads. A Builder running this arm may not, because `claude -p` is a full
agent with Edit and Bash. Copying the Codex path here would hand a writing reviewer the Builder's
live checkout, which is AST-016 rebuilt on the newest mechanism.
<!-- source: harness/.agents/skills/codex-claude-arm/SKILL.md -->

## When Thomas reaches for it

| What is in front of you | Reach for |
|---|---|
| The root session is Codex and an artifact is committed and handed back | `codex-claude-arm` |
| The root session is Claude and the arm should call Codex | `codex-arm` |
| A Builder on a Codex root has finished a ticket | The Builder runs `arm: ticket` itself |
| A spec is paused, or a slice has closed, on a Codex root | Thomas runs `arm: spec` / `arm: slice` |
| The milestone gate, the reviewer, the report | `review-with-rin`, never this skill |

<!-- source: harness/.agents/skills/codex-claude-arm/SKILL.md -->

## Prerequisites

- **The artifact is finished and handed back.** Running early spends one of the two permitted
  passes on something still changing.
- **The artifact is committed**, with the exact base ref and the final head SHA resolved. A
  verdict for an older SHA cannot authorize a merge.
- **A Claude model id pinned explicitly.** The bare `sonnet` alias resolves to a different
  model than the one the skill names.
- **The gate is not on this runtime.** Confirm the `rin` row does not name Codex before
  treating anything here as the gate.

## What it leaves behind

| What happened | Where it lands |
|---|---|
| The isolated review checkout | `<repo-root>/.claude/worktrees/gate-arm-<artifact-key>`, distinct from the reviewer's own `gate-<artifact-key>` |
| The material under review | `GATE-DIFF.patch` and `GATE-LOG.txt`, written by the dispatcher inside the gate worktree |
| The range, stated up front | One line naming the commit count and file count for `<base>..<head-sha>` |
| The verdict | Recorded once in the decision trail: the vendor that ran, or `cross-vendor arm: NOT RUN — <reason>` |
| Findings you classified as real | Routed to whoever owns the artifact: a spec to the paused Shaper, a ticket to its Builder |

<!-- source: harness/.agents/skills/codex-claude-arm/SKILL.md -->

## Known failures

Pulled from `harness/.agents/memory/recurring-failure-modes.md`. All three are marked
`promoted`.

- **AST-016**: agents sharing one checkout moved HEAD under each other, including a read-only
  reviewer that `git switch`ed someone else's HEAD. Fixed: isolation is unconditional for any
  spawned agent that can run state-changing git. That is why `claude -p` gets its own detached
  worktree even when the Builder is already standing in the reviewed tree.
- **AST-103**: the arm silently reviewed a zero-commit range and returned clean, measured twice
  in two days on one project, both times caught by the operator rather than by the gate.
  Fixed: the setup block exits non-zero when `git rev-list --count` is 0, and the first line of
  output states the range so a vacuous review is visible at a glance.
- **AST-135**: the run point had to follow the artifact. The Builder now runs `arm: ticket`
  from its own worktree, while Thomas keeps `arm: spec` and `arm: slice`. This skill does not
  copy that move at ticket scope, and the entry says why.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## It's working if

- The first line of the arm's output names a commit count and a file count, and the count is
  not zero.
- The gate worktree is `gate-arm-<artifact-key>`, never the reviewer's `gate-<artifact-key>`
  and never a path that has been used before.
- The allowlist is exactly `Read,Grep,Glob` with no `Bash(...)` prefix, and the command carries
  no `--dangerously-skip-permissions`.
- The two evidence files are deleted before `git worktree remove`, and the remove runs without
  `--force`.
- The decision trail carries exactly one arm record for this artifact, naming the vendor that
  ran or the reason it did not.

<!-- source: harness/.agents/skills/codex-claude-arm/SKILL.md -->

## Where it fits

The artifact is committed and handed back → `codex-claude-arm` runs one Claude pass over the
resolved range → you classify which findings are real and route them to the artifact's owner →
a blocking finding means a fix, a new SHA and pass 2 under the same contract → the exit differs
by artifact, and only the ticket exit is a merge. `codex-arm` is the mirror of this skill on a
Claude root; `review-with-rin` owns the gate this skill is explicitly not.
