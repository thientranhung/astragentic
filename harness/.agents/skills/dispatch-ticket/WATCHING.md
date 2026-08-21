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

**Safe alternatives when you need both status and trimmed output:**

```bash
cmd … > /tmp/out.log 2>&1; status=$?; tail -25 /tmp/out.log; exit $status
```

## Watcher script operational details (all runtimes)

**Claude runtime does NOT skip this section.** Every runtime runs this same script; Claude
differs only in launch and stop — `Monitor` instead of a direct call, `TaskStop` instead of
the process-group kill. `NO_START` semantics, the exit contract and status-is-a-bell apply to
Claude unchanged. Only "Stopping a watch" is Codex/OpenCode-specific.

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

