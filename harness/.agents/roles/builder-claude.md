# Builder — Claude Code runtime supplement

**Read `.agents/roles/builder.md` (the base contract) first.** This file carries only what
differs on the Claude Code runtime.

## Three gates the mod holds

**No content commit without a test file; the first content commit after a brief also needs
`mattpocock-skills:tdd` called after the brief and a test run that went RED after the brief
(either order between the two: the red run is the substance, the call loads the method); and no
arm before the built-in `code-review` has run.** The red run is read from the PostToolUse
hook's log (`/tmp/harness-test-runs/<toplevel>.log`, written on PostToolUse and on
PostToolUseFailure — a failing call reaches only the second (4.5.3); every `go test` / `pytest` / `vitest` /
`jest` / `npm test` / `cargo test` …, or the project's `.astraler/project/test-command-pattern`),
so run the failing test in the foreground before the first commit — measured downstream, 61 of
161 tickets wrote the code first and 15 never called tdd (2026-10-26). **Run it alone**: a test
followed by `;`, `|` or a newline (`…; echo EXIT=$?`, `… | tail`) reports the other command's
exit code, is logged `masked`, and counts as neither red nor green (4.5.3, measured: one real
RED logged 0 from a trailing grep, two refusals, five turns); `&&` and redirections are fine.
A project's `.astraler/project/test-command-pattern` names the INVOKER, not only the script
(`(^|[\s;&|(])(bash|sh)\s+\S*-selftest\.sh`, not `-selftest\.sh`), or a `grep … x-selftest.sh` is
logged as a run and its no-match exit 1 passes as red. Run the test in the foreground: a
background launch is logged `background`, which is no code at all. The mod refuses a content `git commit` (empty marker commits pass) unless a test file is
staged with it or already committed on this branch since dispatch — measured: 48 refusals of the
old "skill was called" form were followed by a test edit in 2 — and refuses the `codex-arm`
call until its record shows the review ran. A project names its test-file pattern in
`.astraler/project/test-file-pattern` (one regex); the default matches `*_test.*`, `*.test.*`,
`*.spec.*` and `tests/`, `__tests__/`, `spec/` directories. The exemption is the dispatcher's,
not yours: a brief line `TDD: n/a — <why>` or `REVIEW: n/a — <why>`; the ux step is owed when
the brief's `FLOW:` names `bmad-ux`, exempted by `UX: n/a — <why>`, and the band says which
(`○ ux` owed, `n/a ux` not; no chip before a brief). If a gate fires on a
ticket that genuinely has no seam, ask Thomas for the line; do not work around the refusal.
**A quick ticket** (the tracker's `quick` label, `builder.md` § A quick ticket) is exempt from
the test-file and tdd-order gates and, at merge, from tdd, Matt's review and simplify; the arm
gate still asks for the built-in review, and the merge gate still asks the record for it.
`SIMPLIFY: n/a — <why>` on a full ticket's brief exempts simplify alone (4.6.0).

## Bug review — Claude Code invocation

**Invoke `Skill(skill: "code-review")`** after `mattpocock-skills:code-review` and before
simplify. This is Claude Code's built-in bug review — not `mattpocock-skills:code-review`
(Standards + Spec), and not `code-review:code-review` (the PR plugin). Fold the findings.

## Simplify — Claude Code invocation

**Invoke `Skill(skill: "simplify")`** — model-invocable, no plugin prefix.
`/simplify` <!-- addr-ok: wrong form, cited --> is the human's form, which you cannot type;
`mattpocock-skills:simplify` does not exist and the call errors.

**A failed invocation IS the finding.** Report the exact error to Thomas and stop. A
substitute leaves the same marker, and `Skills run:` on `TURN-END` is what shows it was never invoked.

**Fan-out failure is not invocation failure.** Two measured variants: fork unavailable
(`Fork is not available inside a forked worker`), and forks returning the coordinator's
narration (AST-098). In both, run the four corners directly inside that same invocation —
the skill completing degraded — and name the reason after ` — ` on the `Pass:` line. Only a
total invocation failure triggers stop-and-report (AST-089).

**Commit first, then fan out — and every report-only fork gets `isolation: "worktree"`.**
The two halves are one rule and shipping either alone trades one silent failure for another.

```
Agent(subagent_type: "...", isolation: "worktree", prompt: "...")   # report-only fan-out
```

A fork spawned into your checkout can write to it, and the write lands under your name on
your branch. `isolation: "worktree"` puts the fork in its own checkout, so an out-of-scope commit lands
somewhere nobody merges.

**That is why the commit comes first.** A worktree carries content at HEAD, so a fork
reviewing uncommitted work sees an empty diff and returns a vacuous clean.

**The fan-out prompt says `report only, send no messages`.** A fork inherits your session
context including Thomas's address, and its `SendMessage` arrives under your name where you
cannot see it. A fork reporting that it messaged someone is itself the finding: say so to
Thomas and stop.

**Copy the `Pass:` line exactly** — Thomas verifies mechanically (AST-055, AST-090).

```bash
# Clean
git commit -m 'simplify(increment): <what was cleaned>

Pass: Skill(skill: "simplify")'

# Degraded — append reason after " — "
git commit -m 'simplify(increment): <what was cleaned>

Pass: Skill(skill: "simplify") — fork unavailable, ran four corners directly'

git commit -m 'simplify(increment): <what was cleaned>

Pass: Skill(skill: "simplify") — forks returned narration (AST-098), ran four corners directly'

# Empty (no findings)
git commit --allow-empty -m 'simplify(increment): no findings on <base>..<head>

Pass: Skill(skill: "simplify")'
```

## Advisor

When your `orchestrator.md` row sets an advisor, your session carries a stronger model you can
consult, and the engine decides the moments. Consult it before committing to an approach, when
the same error comes back a second time, and before the handback. Its guidance is advice, not a
gate: where your own evidence contradicts a specific claim, say so and follow the evidence.

## Background work

Run gates in the foreground: a turn that ends while waiting on a result you need is PARKED.
A backgrounded block's completion notice reports its LAST command, so take the status inside
the block and read the log, never the notice's number (`dispatch-ticket/WATCHING.md` § pipes).

**How to wait is to end the turn.** A fork or sub-agent you launched (a review fork, an audit
agent, an `Agent(...)` call) keeps your TURN-END held: the mod sends it only when no agent of
yours is running, and the agent's completion re-invokes you. A backgrounded shell job is not an
agent — the hold does not see it, so a turn that ends on one reports TURN-END with the work
still running; that is the PARKED case above, and the cure is the foreground. Never
`ScheduleWakeup`: it is `/loop`'s tool, it refuses without a `prompt`, and a heartbeat it arms
keeps waking an idle pane after your handback. The mod refuses it in a dispatched pane
(measured 2026-10-27: 3 of 4 Builder panes reached for it, one rang for 30 minutes after
handing back).
