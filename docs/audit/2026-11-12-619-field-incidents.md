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

## I-2 — the BA role forbids looking at the customer's production site

Reported 2026-11-12 by nizzy BA (cross-session message from `etsy-fulfillment-thanh-71`; note
`~/.astraler/handoff/etsy-fulfillment-thanh/2026-11-12-ba-may-view-customer-prod.md`).

| số đo | nguồn |
|---|---|
| owner messages in the BA session asking for production to be opened, then ruling the role wrong: 2 (13:59:08Z, 13:59:47Z: "BA thì phải được coi site prod khách hàng, đứng về phía khách hàng") | nizzy transcript `6928dd24…`, `type: user`, `agentSetting: ba` |
| lines in the payload that forbid it: 1 (`ba.md:57` "Browse production"); other carriers (Claude agent file, Codex payload, guard): 0 | `grep -rn -i "browse production" harness runtimes docs` |
| how many BA sessions on nizzy and inception were refused production before this one | chưa đo |

Layer: upstream harness (payload text; a project edit is overwritten on upgrade). Fix: `ba.md` § What
you do gains "look at the product where the customer uses it" (view only, press nothing that writes,
close the tabs); § What you do not do keeps "act on production". Text only: no hook separates a
read from a write in the browser, so the no-write half is unenforced.

By hand downstream: none after the upgrade; until then the ruling lives in the project's BA memory.

## I-3 — the BA role is a decision clerk: nothing in it puts the BA in the user's seat

Owner order 2026-11-12 in nizzy's BA session ("role BA markdown như vậy là chưa chuẩn. Cần thiết kế lại
đi em. Hỏi bmad distilled xem"), repeated in the upstream pane ("tham khảo bmad distilled … để thiết kế
role ba"). Proposal from the BA session: `~/.astraler/handoff/etsy-fulfillment-thanh/2026-11-12-ba-role-redesign.md`.

| số đo | nguồn |
|---|---|
| asked about a screen users get lost on, the BA's calls before the owner's "tại sao không mở prod được": 3 code reads (13:58:42–48Z), 0 browser calls; n=1 session | nizzy transcript `6928dd24…` |
| lines in `ba.md` about looking at the product, discovery or the user's problem before this batch: 0 of 70 | `ba.md` at 9dfbf78 |
| `ba.md` words: 953 → 1334; not among the 4 roles the staleness audit budgets (default ceiling 1200 would not pass it) | `wc -w`; `docs-staleness-audit.sh` output |
| field use of the research row, the re-walk after a fix and the "still stuck: why?" question | chưa đo (owner-directed design) |
| a live BA session on the new role | chưa đo; static checks only: staleness exit 0, reachability exit 0, tests/codex 72 OK |

Sources read for the method (docs only, no name ships in the payload, ruling 2026-10-29): `docs/bmad-distilled/roster.md`
(the analyst), `capabilities/product-brief.md`, `prfaq.md`, `forge-idea.md`, `market-research.md`,
`domain-research.md`; `docs/bmad-distilled-latest/capabilities/advanced-elicitation.md`, `ux.md`.

Taken: whole problem first then "anything else?", stakes read early, drill after the broad shape; the
user's problem before a solution, how they cope today, terms kept apart; coach not quiz, a hypothesis
when stuck, no agreement to smooth; assumptions marked, unknowns said; answer first; one pre-mortem
question per actor; three ends (hardened, killed, clearer). Added from the field: the walk (three
questions per screen, stuck point with screenshot beside the handoff file, read-only, map to code after).
Not taken: brainstorming to 100 ideas, the PRFAQ document, full market reports, the 71-method menu,
personas (astra-ux already caps actors). Kept: every discussion is the BA's (ruling 2026-10-23), ticket
only on the owner's yes, handoff file, blast radius, sizing, memory.

Differences from the proposal: no project names or competitor examples; journeys stay with `astra-ux`
(captured, never authored), which now lets the BA take a screenshot of the product as it runs; the
re-walk is not a gate. Lands in `harness/.agents/roles/ba.md`, `harness/.claude/agents/ba.md`
(description, compaction list), `runtimes/codex/.codex/roles/ba.md`, both `astra-ux` mirrors.

By hand downstream: restart the BA session after the upgrade.

## I-4 — two agent files name skills the payload no longer ships

Found 2026-11-12 while answering the owner ("Thomas được gọi là gì").

| số đo | nguồn |
|---|---|
| skills named in `harness/.claude/agents/thomas.md` description that have no directory under `harness/.claude/skills/`: 4 of 4 (triage, wayfinder, to-questionnaire, ask-matt); mentions of the last three in `roles/thomas.md`: 0 | `ls harness/.claude/skills`; grep |
| `harness/.claude/agents/shaper.md` hands a compacted effort back "for `wayfinder`": 1 line | grep |
| sessions that tried to call one of them because of these lines | chưa đo |

Fix: the description names what Thomas drives today (reconcile-tracker, astra-ux, dispatch, the QA walk);
the Shaper hands back to Thomas. Text only.

## Measured, not changed — quick-builder against its use

| số đo | nguồn |
|---|---|
| quick-builder sessions in 30 days: nizzy 9, inception 0 | transcripts, `agentSetting` |
| sessions that ran the role's one git shape (a commit): 3 of 9 | `git commit` Bash calls |
| sessions that were server or deploy work over ssh: 3 (40 ssh calls); GitHub-side or cluster ops with no commit: 3; questions only: 2 (classified from the opening messages, one label per session beside the commit count) | same transcripts |
| guard refusals seen in those sessions: 1 | tool results |
| the role's line "The owner asks for a deploy: that is Thomas's … not yours" against that use: quick did the deploy steps on the owner's word in 2 sessions, refused 0 | first replies of `cc97d3b2`, `63c15686` |

Not changed: widening the role to ops is the Devop question the owner parked 2026-10-27.

## I-5 — quick-builder takes whatever the owner asks; Thomas is titled "router"

Owner 2026-11-12, upstream pane, on the quick-builder numbers above: "lỗi anh sai, với nó cũng thảo mai cái
gì cũng nhận làm là không đúng"; on Thomas: "Thomas mà router cũng không đúng, nó giúp anh trả lời mọi
thứ mà, nó có kiến thức và góc nhìn của anh".

| số đo | nguồn |
|---|---|
| quick-builder sessions on nizzy that opened with server/deploy work or a question: 5 of 9 in 30 days; declined: 0 | the table above |
| lines in `quick-builder.md` telling it to decline and name the owner of the work: 1, for deploy only, with no "stop" | `quick-builder.md` § When you stop at 33a6d13 |
| places the payload titles Thomas a router: 2 (`roles/thomas.md` line 1, the agent description); the role file already said "you answer for the owner" once, for Shaper questions only | grep |
| a live quick-builder session declining; a live Thomas session on the new opening | chưa đo; static: staleness exit 0, reachability exit 0, tests/codex 72 OK |

Fix: quick-builder declines a deploy, server work or a discussion in one sentence, names whose it is
(Thomas or the owner; the BA; a ticket) and stops; both runtimes. Thomas is "the owner's deputy": stands in
for the owner, carries his knowledge and view, answers him and the team from it, his decisions stay his;
`thomas.md` 2050 words, margin unchanged at 100; Codex contract carries the same sentence. The word
"router" stays where it describes the routing rules, not the role.
