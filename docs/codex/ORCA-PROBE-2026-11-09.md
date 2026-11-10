# Orca 1.4.254 + Codex 0.167 probe (2026-11-09, UTC)

Thomas (Claude, inside Orca). Two disposable repos under /private/tmp/orca-probe, gpt-6-astra, launched with
`orca agent launch --surface terminal --model gpt-6-astra --effort low`. n=1 per measurement.

| Measure | Result | Source |
|---|---|---|
| Hook cost outside Orca, median of 20 | Codex 5.4 ms, Claude 9.3 ms | timed the installed hook command with ORCA_* unset |
| Agent-to-agent via `orca terminal send` | PONG in about 18 s including one model turn | ping 10:21:03, reply 10:21:21 |
| Codex coordinator ended its turn, later woken by Orca | ended 10:21:28, worker file 10:23:31, woken 10:23:50 | files in the fixture; wake text "You have 1 orchestration message. Run `orca orchestration check`" |
| Coordinator poll calls during the wait | 0 | its pane |
| Builder spawns three `astragentic_reviewer` from its own session, native wait | 3/3 ran, `agent_role=astragentic_reviewer`, depth 1, correctness and intent named the planted bug at calc.py:2, took about 1 min 50 s | REVIEW.md, rollouts 01a1bfd3-759b (parent), -c47c, -ddcf, -fb27 |
| Helper effort | TOML and orchestrator say `high`; all 3 helper turn contexts say `low`, the parent's launch value | helper turn_context vs .codex/agents/astragentic-reviewer.toml |
| Permissions actually used | approval `never`, sandbox `danger-full-access` (Orca's Yolo) | turn_context of all 6 sessions |

Not measured: wake or spawn under Manual or Auto permissions, wake after a long idle or across Orca hibernation, wake
during a provider error, the helper spawn in a Herdr-launched TUI, why helper effort follows the parent (upstream #52887
is the nearest report, unread), a real ticket.
Cleanup: `orca project setup-delete --setup <repoId> --force` removes a project added with `repo add`; Orca also added a trust entry per fixture to ~/.codex/config.toml, removed by hand after the probe.
