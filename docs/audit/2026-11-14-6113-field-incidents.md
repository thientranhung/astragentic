# Field incidents after 6.1.13 (batch for 6.1.14)

## L-4 (carried) — held-stale bells: the built-in review was wrapped in a background sub-agent

| số đo | nguồn |
|---|---|
| held-stale bells of 20 min in one day: 4 (TRA-1423 01:41Z, TRA-1440 12:05Z and 12:36Z, TRA-1453 21:21Z) | nizzy root transcript `99caf986` |
| on all 3 tickets the Builder ran the built-in review inside a `general-purpose` background sub-agent (description `/code-review medium …`); that wrapper ended before the angle agents it started (TRA-1440: wrapper 11:41:17Z, angles 11:42:02 to 11:46:14Z; TRA-1453: 21:00:35Z, angles to 21:02:18Z; TRA-1423: 01:21:41Z, angles to 01:22:28Z) | `*builder-TRA-{1423,1440,1453}*/**/agent-*.meta.json` (`agentType`, `parentAgentId`, `requestShape`) and the last record of each `.jsonl` |
| the agents each bell lists as `[running]` are those angle agents, ended `end_turn` 19 to 20 min before the bell | bell text against the same files |
| lines in `astra-review` that say who calls the built-in review, or that a sub-agent runs in the foreground: 0 | `astra-review/SKILL.md` at v6.1.13 |
| Matt Pocock 1.3.2 `code-review`: "runs both sub-agents in the foreground and uses their returned reports" (#1073) | upstream `CHANGELOG.md` |
| the 12:36Z bell on TRA-1440 (simplify angles, `spawnDepth: 0`, no wrapper) | not explained by this; open |
| a Builder on 6.1.14 finishing a review with no hold | chưa đo |

Layer: upstream skill text for the wrapper; Claude Code's agent list for the stale `running` (not filed).

Fix (`astra-review`, both skill mirrors, text only): the Builder calls the built-in review itself, never
inside a sub-agent; the Intent and Standards sub-agents run in the foreground and what each returns is its
report. Static checks only: mirrors byte-identical, staleness and reachability exit 0.

## Receipts from nizzy on 6.1.12 and 6.1.13 (live, its Thomas restarted 2026-11-14 12:08 local)

| số đo | nguồn |
|---|---|
| a create naming a ticket checkout is refused in a live Orca session, the refusal carries the session's own root, no pane created: 1 of 1 | nizzy Thomas, cross-session message, refusal quoted verbatim |
| L-1, base-form creates since the restart: 2 of 2 `orphaned: false, connected: true`, 3 reads each | same; 8 more owed; the Orca window state at those moments not recorded |
| the ticket-done note on a local merge waiting on its gate (6.1.13) | chưa đo; owed by nizzy |
