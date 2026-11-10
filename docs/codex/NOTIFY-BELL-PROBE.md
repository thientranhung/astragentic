# Notify bell probe — Codex TURN-END to an idle coordinator (2026-11-08)

Question: can a worker's Codex `notify` hook wake an idle coordinator session through
`codex queue`, and how long does it take? Measured by Thomas (Claude) on CLI 0.167.0.

## Fixture
- Coordinator: interactive `codex` TUI in a hidden Herdr tab, cwd /tmp/astra-notify-fx/proj,
  gpt-6-astra low, instructed to answer every TURN-END message with one ACK line and no tools.
  Thread 01a1bb4e-972f-7f10-baf8-be8979a45637.
- Worker: `codex exec … -c notify=["turn-end.sh","D1-n","<coordinator uuid>"]` × 10, 20 s apart.
- `turn-end.sh` (evidence/notify-turn-end.sh) parses the notify JSON (turn-id, thread-id,
  last-assistant-message) and runs `codex queue --thread <uuid> --message "TURN-END dispatch=…"`.
- Clocks: bell script writes t1 (fired) and t2 (queue returned); coordinator rollout jsonl gives
  the ACK timestamp. The owner's global `notify` (Computer Use client) is replaced only for the
  worker session, by the per-invocation `-c`.

## Result (evidence/notify-turn-end.log, notify-rounds.log, coordinator rollout)
| round | bell→queue ok | queue→ACK | total |
|---|---|---|---|
| 1 | 0.2 s | 10.5 s | 10.7 s |
| 2 | 0.2 | 14.1 | 14.4 |
| 3 | 0.2 | 12.5 | 12.8 |
| 4 | 0.2 | 14.3 | 14.5 |
| 5 | 0.2 | 6.3 | 6.5 |
| 6 | 0.2 | 7.4 | 7.7 |
| 7 | 0.2 | 6.1 | 6.3 |
| 8 | 0.2 | 8.3 | 8.5 |
| 9 | 0.3 | 13.3 | 13.5 |
| 10 | 0.2 | 7.8 | 8.0 |

10/10 bells fired, 10/10 queued (rc 0), 10/10 ACKed by the idle coordinator, 0 tool calls,
0 duplicates, median total 9.6 s (min 6.3, max 14.5; the 10.7 s first reported was the 6th value, corrected by the Codex builder). The queue→ACK span includes the
model's own reply time, so the wake itself is under that bound.

## Not measured
Busy coordinator (bell arriving mid-turn), coordinator after Esc interrupt (earlier probe: queue
does not wake), compaction, daemon `--remote` endpoint, real Builder turns, n>10.
