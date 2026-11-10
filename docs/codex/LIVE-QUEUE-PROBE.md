# Live Codex queue probe

Status: first implementation checkpoint; not production acceptance. CLI 0.166.0 / Herdr 0.9.5.
Owner authorized implementation. Dedicated tabs codex-queue-probe / codex-queue-peer
were created in the verified astragentic workspace. Existing panes were not steered.
Both probe processes use read-only sandbox and model/effort inherited from owner config.

## Observed

- Fixture TUI stopped at trust. An invocation-level project trust setting did not
  bypass this prompt. No persistent trust was saved; the startup was exited.
- Probe then launched at the existing project with explicit no-edit instructions.
- Herdr detected idle → working → done for the test recipient.
- Session UUID was obtained by reading only CODEX_THREAD_ID inside that recipient.
- Idle queue PING ASTRA-IDLE-001 produced ACK ASTRA-IDLE-001.
- During a working turn (sleep 12), queue PING ASTRA-BUSY-002 was accepted;
  after BUSY-END-001, the recipient produced ACK ASTRA-BUSY-002.
- Herdr read of long history while working returned agent_not_idle. Read visible
  while active, and read full recent history after settled state.
- Herdr foreground_cwd remained the launcher shell directory when Codex used --cd,
  while the model's actual cwd was the project. Launch future workers with the pane
  cwd already set correctly; do not use --cd to mask a mismatched pane identity.

## Limits

Idle and busy tests prove processing of these exact messages, not exactly-once
semantics generally. Duplicate processing and unloaded-session resume remain unmeasured. No tracker, merge, file editing or real task dispatch occurred.

## Peer send and recovery results

| Case | Observed result | Verdict |
|---|---|---|
| Idle recipient, external CLI sender | ACK ASTRA-IDLE-001 | PASS for this case |
| Busy recipient, external CLI sender | BUSY-END-001 then ACK ASTRA-BUSY-002 | PASS for this case |
| Peer agent in read-only sandbox invokes queue | exit 1: failed to start embedded app server, Operation not permitted | BLOCKED by sandbox; no delivery |
| Queue after Esc interrupt | enqueue exit 0, no working transition within 15 s | NOT auto-woken in observation window |
| Queue --resume against that loaded interrupted thread | warning: already has an active writer; no working transition within 15 s | NOT recovered |
| Explicit recovery through Herdr prompt | RECOVERED-006, then ACK for both pending messages | PASS recovery in this fixture |

Recipient transcript: [queue-recipient.txt](evidence/queue-recipient.txt).
Recipient UUID: 01a1ab8a-821d-7db2-ae1d-4583563a1ea2.
Sender UUID: 01a1ab8b-cc20-7e33-b2ef-a3ba12ed6d47.
These are disposable probes, not role instances. Both test tabs were closed after
completion; existing owner tabs were untouched. No trust or permission config was saved.

## Implementation decision

Keep queue first, but call from an authorized process outside a restricted agent
sandbox when needed; do not broaden role permissions just to make queue succeed.
The read-only failure is not evidence that workspace-write or every Codex environment
fails too. Measure the eventual launch permission mode separately.

Do not automatically recover a human-interrupted worker. Report pending/unconfirmed;
only resume on an explicit continuation decision. The Herdr recovery test was an
explicitly authorized test input, not an automatic duplicate of the queued message.

Implemented `runtimes/codex/transport.py`: single-send UUID-targeted envelopes,
no shell interpolation, no auto-resume/retry/fallback. Four boundary tests passed.
This module is not yet wired to role launchers or a running dispatch supervisor.
