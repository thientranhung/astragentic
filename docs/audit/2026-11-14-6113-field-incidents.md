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

## Receipt from nizzy on 6.1.13 (live)

| số đo | nguồn |
|---|---|
| TRA-1457 (quick) merged locally and gated for about 10 min: 0 ticket-done notes on the prompt, the merge result named the ticket, no note after ticket-done and push | nizzy Thomas, cross-session message 2026-11-14 |
| a brief going out while a merge waits on its gate | chưa đo; no brief was attempted in that window |

## Leads from Matt Pocock's tracker (read 2026-11-14: 218 open issues, 25 open PRs)

Not incidents of ours. Each is another project's report; the right column is what the payload has today.
Nothing here is planned until it has a number from nizzy or inception.

| upstream item | what it says | in the payload today | our number |
|---|---|---|---|
| #1424 (open, 2026-11-12) | "word each question so yes accepts" makes grilling rounds drift to yes-only questions; the options disappear | `astra-grill-with-docs` carries the same line, beside "open questions beat trees of multiple choice" and "do not pick the owner's wedge" | chưa đo: share of yes-only questions in Shaper and BA rounds |
| PR #1221 (open) | a bug fix's red must fail on the wrong behaviour, not on a missing symbol; the reported red was a compile error | the red-run gate reads a non-zero exit; 0 lines ask what the red failed on | chưa đo: first reds that were compile or import errors |
| #1385, PR #1428 | agents commit screenshots to the branch to get them into a PR; the fix records how to attach a file to a comment | 0 lines govern evidence images (L-6: 13 image blobs in nizzy since 11-01) | L-6, returned to nizzy |
| #1384 | 29 skills measured fact by fact: Haiku 5.5 and Sonnet 5.5 already answer 45% and 53% of a skill's facts without it; 44% are new to both | overbuild audit 2026-10-17: prose restated 10 to 35 times | chưa đo per skill |
| #479, #1408, #511 | `implement` skips its tdd and review steps; review sees only committed changes | tdd order and markers are mod gates; `astra-review` stages the diff, untracked files included | covered |
| #1377 | the orchestrator implemented tickets itself and compacted 3 times | 6.1.11 § Not a ticket | 1 ticket in 30 days (TRA-1428) |
| #1412, #1399 | research and implement runs leave servers, branches, labels behind | tab lifecycle (6.1.10), `release-worktree-resources.sh`, `ticket-done.sh` | covered for lanes; research runs chưa đo |
| PR #807, PR #1368 | flatten `skills/` to meet Agent Plugins 1.0 by layout; publish to npm so a factory can pin a version | get.sh pins by tag | no action |
