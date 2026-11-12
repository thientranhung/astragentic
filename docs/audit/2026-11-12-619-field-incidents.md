# 6.1.9 field incidents (batched, one release on the owner's go)

Each row carries `số đo | nguồn`. Rows without a number go to a count first, not into a plan.

## I-1 — agents leave browser tabs open in the shared OmniLogin browser after a UI pass or a walk

Reported 2026-11-12 by the owner, in his words: agent-browser on OmniLogin does not close its tab after
testing and keeps a pile of them.

| số đo | nguồn |
|---|---|
| `agent-browser … tab new` against `tab close` in 10 days of transcripts, nizzy + inception: 172 opened, 148 closed, 24 net left | `~/.claude/projects/*etsy-fulfillment-thanh*`, `*workspace-app-inception*`, Bash tool calls |
| lanes with more opened than closed: 23 of 82 (Builder 16 of 44, QA 5 of 36, root sessions 2 of 2) | same count, per transcript directory |
| lines in the shipped harness that name agent-browser, OmniLogin, or closing a browser tab: 0 | `grep -rnIi 'agent-browser\|omnilogin' harness runtimes` |
| the owner's OmniLogin skill on closing the tab an agent opened: 0 lines (it says to take a new tab, and to stop a profile only on request) | `~/.claude/skills/astraler-omnilogin-agent-browser/SKILL.md` lines 36–38, 199–203 |
| page tabs open at the count (2026-11-12 ~15:00 +07): 2 on CDP 12463 (both of live lanes TRA-1410, TRA-1411), 3 blank on 15886 | `curl 127.0.0.1:<port>/json/list` |
| Codex rollouts: chưa đo | — |

Layer: upstream harness (no rule), beside the owner's own skill file (his to change).

Fix (next release): one sentence in the `astra-ui` skill (§ The surface, rendered; both mirrors), which a
Builder runs on a UI ticket, and one in `harness/.agents/roles/qa.md` (text first, pixels second): close every
browser tab you opened before the report. `builder.md` is left alone: the sentence put it at 1673 of 1760
words, under the 100-word margin, and the staleness audit exited 1. qa.md 1837 → 1850 of 2000. A Builder that
opens a browser on a ticket with no `astra-ui` step is not covered. Text only: whether panes follow it is chưa đo; the same count after the
upgrade is the measurement. No checker added.

Owner ruling 2026-11-12: the tab's life belongs to the workflow that opens it (the harness), not to the
OmniLogin skill, which is operating mechanics. So the harness also checks it: the dispatch mod counts a
dispatched pane's own `agent-browser … tab new` and `tab close` commands that ran, and a TURN-END with tabs
left carries `Browser tabs open: n`, so the dispatcher's steer is one line.

| số đo | nguồn |
|---|---|
| released mod in the driver: 2 `tab new` (one command), 1 failed `tab new`, 1 `tab close`, turn end: no line | `mod-drive.cjs pane` against `HEAD:register.tsx`, `tabsNamed none:gone` |
| patched mod: the same turn end says `Browser tabs open: 1`; after the second `tab close` the line is gone | selftest pane side, `tabsNamed 1:gone` |

Limits: the count is in the pane's memory, so a resumed pane starts at 0; a tab opened by `open` with no
`tab new`, or by another tool, is not seen; root sessions (2 of 2 leaked) have no TURN-END and are not
covered; the mod names `agent-browser`, the one tool both projects use. Claude lane only: a Codex pane has
no mod. Live: chưa đo.
