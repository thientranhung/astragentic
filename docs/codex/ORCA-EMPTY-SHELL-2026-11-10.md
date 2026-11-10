# Orca empty child shell — fixture receipt (6.1.5, 2026-11-10)

Report: nizzy Thomas, `etsy-fulfillment-thanh/.scratch/codex/final-1353-1355/UPSTREAM-EMPTY-TERMINAL-REPORT.md`
(run `run_362765c066b0`). Fixtures ran in this repo from an Orca pane (orca CLI 1.4.255, app 1.4.254, codex-cli 0.167.0).
Count = connected rows of `orca terminal list --json` whose `worktreePath` lies inside the child checkout.
Raw JSON: `/tmp/probe-empty-shell/` on the box (not tracked).

## A — `git worktree add` + worker pane in the base workspace (the 6.1.5 recipe)

| step | count / reading |
|---|---|
| `git worktree add -b probe/empty-shell-a .claude/worktrees/probe-empty-shell-a HEAD` | t=0: 0, t=15 s: 0 |
| `orca terminal create --worktree path:<base> --command "codex --cd <child> --model gpt-6-astra -c model_reasoning_effort=\"high\" -c notify=[] --dangerously-bypass-approvals-and-sandbox"` | handle `term_c9460530…`, `tui-idle` satisfied |
| `terminal read` header | cwd `<child>`, `permissions: YOLO mode`, `GPT-6-Astra high` |
| `terminal show` | `orphaned: false`, `connected: true`, `paneRuntimeId: 1`, `worktreePath` = base |
| child count with the worker running | 0 |
| `orca worktree activate --worktree path:<child>` (`activated: true`) | t=0: 0, t=15 s: 0 |

## B — `orca worktree create --setup skip` (the reported path)

| step | count / reading |
|---|---|
| `orca worktree create --name probe-empty-shell-b --setup skip` | create JSON has no terminal handle; ~5 s and ~17 s: 1 (`term_f84b755e…`, `orphaned: false`, preview = prompt only) |
| reuse: `terminal send --text <same argv>` then `--enter` | ps argv carries `--model gpt-6-astra -c model_reasoning_effort="high" -c notify=[] --dangerously-bypass-approvals-and-sandbox` (Orca prefixes `--no-daemon` and `shell_environment_policy.set.ORCA_*`); header YOLO, `GPT-6-Astra high` after first frame read "default" |
| `worktree activate` while the worker runs | t=0: 1, t=15 s: 1 (same handle) |
| `terminal close --tab` on the worker | immediate `show`: `connected: true`; later `false` |
| `worktree activate` on the empty checkout | t=0: 1 (closing handle), t=15 s: 1 new handle `term_985c95f7…`, prompt only |

Reuse works but needs a handle the create does not return (inventory after it settles), and a re-activated empty
checkout grows a shell again. A has neither. `orca worktree create --agent` and `orca agent launch` take
`--model/--effort` only: no `-c notify=[]`, no yolo flag (help text), so neither carries the selected policy.

## Cleanup

`terminal close` on `term_985c95f7…`, `term_c9460530…`; `orca worktree rm --force --delete-branch` on B;
`git worktree remove --force` + `git branch -D` on A. After 5 s: all three handles `connected: false`, 0 `probe`
rows in `terminal list`, `worktree list`, `git worktree list`, `git branch`.

## Not run

A full ticket (task, `worker-start`, retry/reconnect, `worker_done`, release, remove) on 6.1.5 on a Codex project.
