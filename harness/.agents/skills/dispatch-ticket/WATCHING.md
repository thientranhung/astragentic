# Watcher operational reference

Companion to `dispatch-ticket`. Read when a watch returns something unexpected.

## Pipes swallow exit codes — all runtimes

Any command piped through `tail`, `grep`, `head` or similar **loses the original exit code**
and reports the last command's status instead — for ANY command Thomas runs, not only the
watcher (AST-105).

| shape | status |
| :--- | :--- |
| `cmd … \| tail -3` | **always lost** — the pipeline reports the last command |
| `cmd … \|\| true` / `\|\| echo "failed"` | **lost exactly when the command FAILS**, since that is when the right side runs; both failure codes are non-zero, so a real failure becomes 0 |
| `echo "$(cmd …)"`, `export v=$(…)`, `local v=$(…)` | lost |
| `v=$(cmd …)` (bare assignment) | preserved |
| `cmd … && rhs` | preserved on FAILURE; a success is overwritten by `rhs` |

`||` is the one to watch for: it is the shape people reach for when they are being careful,
and it converts precisely the failures you needed to hear about into silence (AST-032).

**The rule reaches past pipes: any status you did not take from the command you care about is
some other command's status, and the substitute defaults to success.** A backgrounded Bash
block reports its LAST command, so `make itest-local …; grep …` arrives as a completion notice
reading *"exit code 0"* while the suite was red. A flag the command does not have fails before
your logic runs, so `git cherry-pick <sha> -q 2>&1 | tail -2; echo "RC=$?"` prints `tail`'s `0`
for a cherry-pick that never happened — and the commit that followed carried a `Ledger:` line
pointing at an entry the tree did not contain. Measured three times in one day on one project,
twice at a merge gate, which is the one place a false green merges bad code. A rule illustrated
on one command gets applied to one command: this one is about the channel, not the pipe.

**Safe alternatives when you need both status and trimmed output:**

```bash
cmd … > /tmp/out.log 2>&1; status=$?; tail -25 /tmp/out.log; exit $status
```

## Watcher script operational details (all runtimes)

**Claude runtime does NOT skip this section.** Every runtime runs this same script; Claude
differs only in launch and stop — `Monitor` **launches** it and `TaskStop` cancels it, in place
of a direct call and the process-group kill. **`Monitor` is the launcher, not a substitute for
the script:**

```
Monitor({command: "<repo-root>/scripts/herdr-watch-terminal.sh <pane-id>", timeout_ms: <ms>})
```

**Never hand-roll a status-poll loop** (`while true; do herdr pane get …; sleep …; done`) in its
place. The loop drops `TIMEOUT` and drops `NO_START` — and `NO_START` is the only thing that
separates *this pane never started* from *it ran and finished*, because a status poll reads
`idle` for both. Never-started is the slash command that queued instead of firing and the
Builder that worked half an hour without its skill, so hand-rolling removes the sensor for that
exact failure and reports healthy while it is happening. Measured on three consecutive
dispatches by one router reading "`Monitor` instead of a direct call" as *Monitor replaces the
script*.

**Poll fast, emit rarely.** Noise comes from what a watcher emits, not from how often it asks.
The script blocks on an event wait, re-polls in short slices, and speaks only once, on the
transition; stretching an interval to stay quiet only makes the answer late.

`NO_START` semantics, the exit contract and status-is-a-bell apply to Claude unchanged. Only
"Stopping a watch" is Codex/OpenCode-specific.

`<repo-root>/scripts/herdr-watch-terminal.sh` watches a NEWLY SUBMITTED turn: it waits to
observe `working` first, so pointing it at an already-idle pane returns `NO_START` —
truthful output rather than a fault. Point it at the pane whose turn you just opened. Any
role may read or watch any pane, and concurrent watchers are fine. Its exit status IS the
signal (`0`+`TERMINAL:<state> pane=<id>` / `1`+`TIMEOUT ... pane=<id>` / `2`+`NO_START
pane=<id>` — every line names its pane so concurrent watches stay distinguishable), so call
it by absolute path, alone on its own line, and branch on `$?`. The pipe table above applies
here too.

**Stopping a watch takes the process GROUP — Codex/OpenCode only.** On Claude runtime the
watch is a `Monitor`, and `TaskStop` cancels it; none of the PID work below applies. On macOS the watcher re-execs under
`caffeinate`, so `caffeinate` is the visible PID and killing it orphans the wrapped shell,
still polling. Signal the group, then confirm:

```bash
pgid=$(ps -o pgid= -p <watch-pid> | tr -d ' ')   # read it first — see below
kill -TERM -"$pgid"                              # leading '-' targets the GROUP
pgrep -g "$pgid" >/dev/null && echo SURVIVORS || echo clean
```

Verify with `pgrep` rather than `ps | grep herdr-watch-terminal`: that grep matches its own
command line, so it can never return empty — a check incapable of passing, the mirror of a
signal incapable of failing (AST-032). (`grep '[h]erdr-watch-terminal'` works too; the
brackets are what stop the pattern matching itself.) Read the PGID before signalling: a
watch launched inline from your own shell may share that shell's group, so a watch you
intend to group-kill belongs in its own.

Status is a bell. The verdict comes from branch movement, the diff, the tests, the final SHA
and the reported artifact. **Observation is unrestricted — reading or watching any pane is
always legal, and verify-by-artifact requires it. Only TASKING is restricted**, and Thomas
tasks the Builder directly, since there is no intermediate role.

## The workspace watchdog — invocation and alerts

Moved here from `thomas.md`: the contract carries the policy (it is required), this file carries
the mechanics, because this is the one home for watching.

```bash
nohup scripts/herdr-watchdog.sh 300 900 6 &   # interval, cooldown, max-alerts/hr
scripts/herdr-watchdog.sh stop
```

Reads `workspace-label` from `orchestrator.md`; `stop` verifies the PID at
`/tmp/herdr-watchdog-<workspace-label>.lock`.

| Alert | What it means | Action |
|---|---|---|
| `BLOCKED` | Pane asking a question | Read, answer, **restart the watch** — Monitor on Claude, watcher script on Codex/OpenCode |
| `WATCHER_LOST` | Pane working, nobody watching | Re-arm the watch now |
| `STUCK` | **No** pane working anywhere | Inspect, handback or re-dispatch |
| `THOMAS_CRASHED` | The router's process is gone | Desktop notification substitutes |

**What falls between them, stated because silence here reads as health.** `STUCK` requires that
NO pane is working, so a Builder that finishes while a sibling still works produces nothing —
with several Builders in flight, the ordinary case. A pane launched through the `herdr pane run`
fallback carries no agent name and is never counted as dispatched, so it emits nothing at all
(AST-084). Neither is a bug in the watchdog; both are why the router counts panes itself.
