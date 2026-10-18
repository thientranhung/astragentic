# Harness inventory at HEAD 4.0.4 (7d07125)

Read-only. R = /Users/tranthien/Documents/2.DEV/2.PRIVATE/astragentic. Assembled from section files; section order in this file: 1, 2, then 3+5+6 (one block), then 4, then 7, 8, 9, 10, 11. Rows were built from the files and from grep; scripts' internals were read from headers and grep hits, not line by line, except register.tsx (read whole).

Row counts per section:
| section | content | rows |
|---|---|---|
| 1 | role contracts | 1.1=8, 1.2=9, 1.3=13, 1.4=7, 1.5=10 |
| 2 | skills | 2.1=22 files, 2.2=29 plugin/built-in/subagent names |
| 3 | scripts | 18 |
| 4 | mod | 4.1=17, 4.2=21, 4.3=27, 4.4=26, 4.5=17, 4.6=10, 4.7=5, 4.8=14 |
| 5 | settings.json hooks | 5 |
| 6 | installer/doctor | 6a=10, 6b=18, 6c=10, 6d=5, 6e=22, 6f=5 |
| 7 | prompts | 7.1=17, 7.2=7 |
| 8 | orchestrator rows | 8 |
| 9 | ledger | 9.1=5, 9.2=31 |
| 10 | plugs and state | 10.1=19, 10.2=9 |
| 11 | pure-prose rules | P=57, H=31 across 8 contracts |

Facts that change how measurements join:
- Thomas is resident: mod M05 does not record his Skill calls. Only the transcript shows them.
- Only G02, G03, G04, G05, G12 write `astragentic-dispatch REFUSED <gate>` to /tmp/harness-hook-events.log and `refusals[]`; all other denials and S01-S08 leave only the tool result text.
- `FLOW:` brief line (dispatch-ticket/SKILL.md:323) is not parsed by any code found.
- Scripts with only prose callers: herdr-watchdog.sh, herdr-watch-terminal.sh, ticket-git-facts.sh, check-payload-drift.sh (no install/settings wiring). ledger-index.sh and ledger-rules.py are run only by install.sh and selftest.
- builder-target, Junior row and the model/effort cells of Active assignments have no code reader beyond the Advisor header check.

# Section 1 — Role contracts

R = /Users/tranthien/Documents/2.DEV/2.PRIVATE/astragentic. All line numbers refer to the file named in the row. Skill names without prefix are harness skills; `mattpocock-skills:*` and built-ins are plugin or engine skills.

Trace vocabulary used in all sections:
- **skills_run** = record field `.astraler/state/dispatch-record.json[<key>].skills_run.<skill>` written by mod M05 for every Skill expansion in a dispatched non-resident pane (builder, shaper, qa). A resident (Thomas) Skill call leaves NO record; only the transcript shows it.
- **chip** = AbovePrompt chip from FLOW_BY_ROLE (register.tsx:195-214).
- **transcript** = Skill/Bash/Agent/SendMessage tool call in the session JSONL.

## 1.1 Contract files (8)
| id | path | lines | type | intended caller | trigger | trace |
|---|---|---|---|---|---|---|
| RC1 | harness/.agents/roles/builder.md | 178 | role contract | `harness/.claude/agents/builder.md` (role system prompt, "Read `.agents/roles/builder.md` now"); `--agent builder` launcher in dispatch-ticket-claude | per dispatch (Builder session start) | Read tool call of the path in the pane transcript |
| RC2 | harness/.agents/roles/builder-claude.md | 117 | runtime supplement | builder.md:15 (Load row "session start"); harness/.claude/agents/builder.md | per dispatch | Read of the path; gates it describes fire as G03/G05 (register.tsx:1272, 1306) |
| RC3 | harness/.agents/roles/thomas.md | 200 | role contract | harness/.claude/agents/thomas.md; resident session start | session start (resident) | Read of the path; also re-injected after compaction by hook-contract-reload.py (settings.json SessionStart compact) |
| RC4 | harness/.agents/roles/thomas-claude.md | 51 | runtime supplement | thomas.md:18 (Load row "before each merge") | per merge | Read of the path |
| RC5 | harness/.agents/roles/shaper.md | 111 | role contract | harness/.claude/agents/shaper.md | per dispatch (Shaper session start) | Read of the path |
| RC6 | harness/.agents/roles/qa.md | 208 | role contract | harness/.claude/agents/qa.md ("read Safety first") | per dispatch (QA session start) | Read of the path |
| RC7 | harness/.agents/roles/junior.md | 60 | role contract | junior-grok.md:3; dispatch-junior/SKILL.md (brief names it); only when orchestrator.md Junior row names a runtime | per junior dispatch | Read of the path in the junior pane; handback line `JUNIOR-DONE` / `JUNIOR-BLOCKED` |
| RC8 | harness/.agents/roles/junior-grok.md | 28 | runtime supplement | junior.md:16 (`.agents/roles/junior-<runtime>.md`) | per junior dispatch | Read of the path |

Also in this layer: harness/.claude/agents/{builder,thomas,shaper,qa}.md (4 role system prompts) are listed in section 4.8 rows A11-A14.

## 1.2 builder.md — section headings and what each points at (9)
| id | heading (line) | points at | trace |
|---|---|---|---|
| B-H1 | Load (10) | `writing-for-agents` (plugin skill, when ticket edits SKILL/AGENTS/CLAUDE/role contract); builder-claude.md; orchestrator.md `## Junior`; `dispatch-junior`; ticket+spec+brief; `legacy-testing`; `untangle`; `.agents/memory/RULES.md`; `grep -A40 '^### AST-0NN' recurring-failure-modes.md`; overlay `.astraler/project/overlays/builder.md` | skills_run `mattpocock-skills:writing-for-agents`, `legacy-testing`, `untangle`; Bash command text `grep -A40 '^### AST-`; Read of RULES.md; overlay delivered as system section `astragentic-dispatch:overlay` (M03) |
| B-H2 | Phases you own (27) | `mattpocock-skills:implement`; `atdd`; `mattpocock-skills:tdd`; `mattpocock-skills:code-review <Base>`; built-in `code-review`; `simplify`; `codex-arm`; `bmad-ux audit` | skills_run keys `mattpocock-skills:implement`, `mattpocock-skills:tdd`, `atdd`, `mattpocock-skills:code-review`, `code-review`, `bmad-ux`, `simplify`, `codex-arm`; chips implement/tdd/atdd/review:matt/review:built-in/ux/simplify/arm; commit subjects `simplify(increment):`, `arm(ticket):`; handback lines `TDD: n/a — <why>`, `ATDD: n/a — <why>`, `UX audit: n/a — <why>`, `Arm: off (orchestrator)` |
| B-H3 | With a junior (52) | orchestrator.md Junior row; `atdd`, `tdd`; `dispatch-junior`; junior.md | commit trailer `Implemented-by: <runtime>/<model>`; pane line `JUNIOR-DONE <id> head=… tests=… changed=…`; handback `Junior: none` or `Junior:` line; `herdr` pane beside Builder tab |
| B-H4 | Build (59) | `atdd`, `tdd`; ask Thomas | skills_run atdd/tdd; SendMessage to dispatcher |
| B-H5 | Two rules about being wrong (71) | none (no skill, script or marker) | none |
| B-H6 | Increment review (84) | `mattpocock-skills:code-review`; reply to Thomas | skills_run `mattpocock-skills:code-review`; SendMessage to Thomas |
| B-H7 | Work you cannot read in a diff (94) | `bmad-ux audit`; project render tool; design guidelines | skills_run `bmad-ux`; handback text (viewport, what seen); `UX audit: n/a — <why>` |
| B-H8 | The cross-vendor arm — yours to fire (109) | `codex-arm`; `dispatch-ticket/MARKERS.md`; simplify re-run over `<marker>..HEAD`; `Agent(... isolation)` | skills_run `codex-arm`; empty commit `arm(ticket): <id> — <verdict>, <n> passes` with `Reviewed:`, `Vendor:`, `Tests:`, `Pass:`, `Unreviewed-delta:`; `.scratch/gates/arm-<key>-<scope>-pass<n>` (codex-arm) |
| B-H9 | Handing back (140) | `git add/commit/push origin <branch>`; `scripts/check-simplify-markers.sh <base> HEAD --marker 'simplify(increment)'` and `--marker 'arm(ticket)'` | Bash command text of both script calls; remote branch exists; handback fields: branch, final SHA, criteria, validation output, marker, browser evidence, `Junior:` line |

## 1.3 thomas.md — section headings (13)
| id | heading (line) | points at | trace |
|---|---|---|---|
| T-H1 | Load (7) | orchestrator.md; `docs/agents/issue-tracker.md`; `Skill(skill: "github-issue-tracker"|"jira-issue-tracker"|"linear-issue-tracker")`; tracker-contract.md; `docs/agents/triage-labels.md`; `reconcile-tracker`; `dispatch-ticket`+`dispatch-ticket-claude`; thomas-claude.md; RULES.md; `.claude/agents/thomas.md` | Thomas Skill calls (NOT in dispatch record: resident excluded from M05); transcript Skill calls; hook-tracker-status.py injects tracker counts at SessionStart (log `hook-tracker-status`) |
| T-H2 | Phases you own (24) | `mattpocock-skills:triage`, `:wayfinder`, `:to-questionnaire`, `:ask-matt`; `bootstrap-glossary`; `batch-triage`; `codex-arm` + `Agent(astragentic-dispatch:bmad-reviewer)` | transcript Skill calls; outputs `GLOSSARY.md`, `GLOSSARY-review.md`; slice marker `arm(slice):` |
| T-H3 | The frontier (40) | tracker query (adapter); board write | tracker label/state writes; ticket labels in tracker |
| T-H4 | Dispatch to CAPACITY (54) | orchestrator.md `builder-target` (default 4); pane count | `herdr` tabs `ticket:<id>` count in workspace; record entries with role builder and live pane_id; chips/board rows |
| T-H5 | The claim protocol (63) | tracker assignee write `builder/<ticket-id>`; readback; `git worktree add -b <ticket-branch> <worktree-path> <base>`; `git worktree remove`; dispatch record | tracker assignee value; Bash `git worktree add -b`; record entry (role, tab_id, pane_id, session_id, worktree, branch, start_sha); mod setup-worktree plug note N05 |
| T-H6 | Releasing a claim (86) | tracker clear assignee; worktree check | tracker assignee empty after cleanup; `git worktree list` |
| T-H7 | Dispatch (94) | Shaper brief opening `/mattpocock-skills:grill-with-docs`; `dispatch-ticket`, `dispatch-ticket-claude`; SendMessage; `dispatch-junior` (Builder's) | brief first line begins `/mattpocock-skills:implement <ID>` (P08) or `/mattpocock-skills:grill-with-docs`; mod refusals S01-S08; `RECEIVED key=… pane=…` mark; record `acked_at` |
| T-H8 | Review (106) | `to-questionnaire`; `dispatch-qa-walk`; COVERAGE GAPS; Builder reply | QA marker `qa(walk):`; QA report `.scratch/qa/<key>-<sha>.md`; Skill `dispatch-qa-walk`; brief lines `QA: walk|probe|verify|none — <why>`, `QA plan: docs/qa/plan-<slug>.md` (P04, P05) |
| T-H9 | Slice gate (130) | `Agent(subagent_type: "astragentic-dispatch:bmad-reviewer", isolation: "worktree")`; `arm(slice):` marker | transcript Agent call with that subagent_type; commit `arm(slice): <slice-key> — <verdict>` with `Scope:`, `Vendor:`, `Verdict:`, `Report:` |
| T-H10 | The cross-vendor arm (138) | `codex-arm`; orchestrator arm rows ticket/spec/slice; `cross-vendor arm: NOT RUN — <reason>` | `arm(spec|ticket|slice):` commits; handback `Arm: off (orchestrator)`; text `cross-vendor arm: NOT RUN — `; mod system section `ARM: off …` (register.tsx:855/860) |
| T-H11 | Merge (156) | `check-simplify-markers.sh` for every receipt plus `--marker 'arm(slice)'`, `--marker 'qa(walk)'`; `dispatch-ticket/MARKERS.md`; `dispatch-ticket` §Merge mechanics; `check-payload-drift.sh`; `scripts/ticket-done.sh <id> --moved "<ids or none>"`; merge commit `Ledger:` line | Bash command text; merge gate G12 (register.tsx:1500) and notes N03/N04; stamp at `<git common dir>/astraler-stamps/harness-ticket-done/<ID>`; push refusal `pre-push: REFUSED — this push lands merge(s) for <ids>` and hook-git-guard DENY (`this push lands merge(s) with no \`Ledger:\` line`); record `merged_at` |
| T-H12 | Watchdog (185) | `dispatch-ticket/WATCHING.md` (`nohup scripts/herdr-watchdog.sh 300 900 6 &`); `dispatch-ticket/CLEANUP.md`; `scripts/release-worktree-resources.sh` | lock `/tmp/herdr-watchdog-<workspace-label>.lock`; watchdog alert lines; WorktreeRemove hook log `HOOK: WorktreeRemove — path=…`; release-worktree-resources stdout |
| T-H13 | Answers carry a source (196) | `research`, `prototype`, `to-questionnaire`, ADR | none fixed (source named in prose) |

## 1.4 shaper.md — section headings (7)
| id | heading (line) | points at | trace |
|---|---|---|---|
| S-H1 | Load (9) | code itself; `codebase-design`; `domain-modeling`; `research`, `prototype`; `improve-codebase-architecture`; `untangle`; `docs/agents/boundaries.md`; `legacy-testing`; RULES.md | skills_run for each skill name; Read of files |
| S-H2 | Phases you own (24) | `mattpocock-skills:grill-with-docs`; `mattpocock-skills:to-spec`; `codex-arm` (arm: spec); `test-design`; `mattpocock-skills:to-tickets` | skills_run keys; chips align/spec/arm:spec/test-design/tickets (FLOW_BY_ROLE shaper); `docs/qa/plan-<slug>.md` |
| S-H3 | STOP after Spec (43) | `arm: spec`; label `needs-triage` vs `ready-for-agent` | `arm(spec):` receipt; tracker label on spec at publish; handback with spec path and findings |
| S-H4 | Test design (68) | `test-design`; `docs/qa/plan-<slug>.md` | file exists; skills_run `test-design` |
| S-H5 | Align: the frontier and its sources (75) | `grill-with-docs`; `research`, `prototype`, `bmad-party` transcript | skills_run; source named per answer in handback (no fixed pattern) |
| S-H6 | Spec and tickets (87) | `to-spec`, `to-tickets`; blocking edges | tracker tickets with edges; skills_run `mattpocock-skills:to-tickets` |
| S-H7 | Handing off (99) | spec path, arm findings, open questions; ticket IDs, graph, plan path | two handbacks (turn ends) in the Shaper pane; TURN-END marks |

## 1.5 qa.md — section headings (10)
| id | heading (line) | points at | trace |
|---|---|---|---|
| Q-H1 | Load (16) | dispatch brief (mode, depth, scope, persona, consent, mutations, report path); `docs/qa/plan-<slug>.md`; project entry doc; design guidelines; `bmad-ux`; API contract; job def; previous verified-clean list; `dispatch-qa-walk` | brief line `Mode: walk|probe|verify` (P06, record `qa_mode`); mod S08 refuses brief when plan missing; skills_run `bmad-ux` |
| Q-H2 | Phases you own (33) | modes walk/probe/verify | `Mode:` line; marker `qa(walk):` with `Mode:` field |
| Q-H3 | Your persona, the judging lens, fixed (43) | none | none |
| Q-H4 | Two depths (52) | incremental / full; skip list | brief names depth; report lists skips (text) |
| Q-H5 | The mandatory checklists (67) | walk items 1-3; probe items 1-4; verify items 1-4 | report body text; `COVERAGE GAPS` section; matrix |
| Q-H6 | Not every product has a surface (112) | one-line report | one-line report text |
| Q-H7 | Safety, hard rules a-f (118) | consent field; authorized mutations; data provenance; redact; no customer values | brief text; `.astraler/project/refused-in-dispatched-panes` regexes (mod G02) if project lists them; report text |
| Q-H8 | Your report is a trace matrix (149) | matrix columns `Plan item|Priority|Coverage|Result|Evidence`; verdict FAIL/CONCERNS/PASS | report file text |
| Q-H9 | Where the report lives (179) | `.scratch/qa/<key>-<sha>.md`; plug `.astraler/project/qa-report-path.sh <key> <sha>`; `$GATE_FILE`; `$VERIFIED_CLEAN_FILE` (`.astraler/state/qa-verified-clean.md`) | committed file at path; GATE_FILE and VERIFIED_CLEAN_FILE written outside checkouts |
| Q-H10 | Where findings go (196) | `to-questionnaire`; marker `qa(walk): <artifact-key> — <verdict>` with `Mode:`, `Scope:`, `Verdict:`, `Report:` | empty commit with that subject; record `qa_last_turn_end_at`, `qa_last_mode` (R21); merge note N04 `owing a QA <mode>` |

Section 1 rows: 1.1=8, 1.2=9, 1.3=13, 1.4=7, 1.5=10.

# Section 2 — Skills

Layout: harness/.agents/skills/<name>/ is the source. harness/.claude/skills/<name>/ holds a byte-identical twin of every file (install.sh phase I3 enforces; `diff -rq` shows only `astragentic-dispatch/` extra under .claude/skills). Row counts below count the .agents files once.
"Caller" = who names it, cited file:line. "Invocation" = user-invoked (needs a human/brief slash form), model-invoked (Skill tool), or recipe (read by SKILL.md).

## 2.1 Harness skills, every file (22)
| id | path | lines | invocation | intended caller (cite) | trigger | observable trace |
|---|---|---|---|---|---|---|
| K01 | skills/atdd/SKILL.md | 68 | model, by name | builder.md:31,46,55,64; register.tsx:199 (optional chip); dispatch-junior, test-design name it | per dispatch, ticket with clear criteria | skills_run `atdd`; chip `atdd`; handback `ATDD: n/a — <why>`; red tests recorded and committed with tdd's first commit (atdd:50) |
| K02 | skills/batch-triage/SKILL.md | 76 | user-invoked by name | thomas.md:33; ADAPT-HARNESS.md:405 | brownfield install only | Thomas transcript Skill call (resident: no record); tracker tickets with labels and edges; closures citing commit or file (`DONE`) |
| K03 | skills/bmad-party/SKILL.md | 73 | `disable-model-invocation: true`, owner-only | shaper.md:82 (transcript as a source); ADAPT-HARNESS.md:187 | owner ad hoc | team of subagents `astragentic-dispatch:bmad-*`; writes no artifact (bmad-party:65) |
| K04 | skills/bmad-ux/SKILL.md | 62 | model, by name | builder.md:36,46,104; qa.md:24; register.tsx:202 (optional chip `ux`) | Builder UI ticket before handback; QA walk when a surface reads wrong | skills_run `bmad-ux`; Agent call to `astragentic-dispatch:bmad-sally` with prompt `audit <surface>. Read and report only` (bmad-ux:48); handback `UX audit: n/a — <why>` |
| K05 | skills/bootstrap-glossary/SKILL.md | 125 | user-invoked by name | thomas.md:32; ADAPT-HARNESS.md:400; check-reachability.py:643,649 | brownfield install only | files `GLOSSARY.md`, `docs/agents/GLOSSARY-review.md` with `UNREVIEWED` entries (bootstrap-glossary:68,101) |
| K06 | skills/codex-arm/SKILL.md | 251 | model, by name | builder.md:35; thomas.md:34,140; shaper.md:30,35; builder-claude.md:10 (gate) | Builder per ticket; Shaper per spec; Thomas per slice | skills_run `codex-arm` (Builder/Shaper); G05 refuses the call without built-in code-review; empty commits `arm(ticket|spec|slice):` with `Reviewed:`/`Vendor:`/`Tests:`/`Pass:`; temp files `.scratch/gates/arm-<key>-<scope>-pass<n>`; release-worktree-resources call (codex-arm:160,171) |
| K07 | skills/dispatch-junior/SKILL.md | 142 | model, Builder-only | builder.md:16,55,174; orchestrator.md:59; dispatch-ticket/SKILL.md, WATCHING.md | per ticket when orchestrator.md Junior row names a runtime | junior pane `junior-<abc-129>`; commits trailered `Implemented-by:`; pane last line `JUNIOR-DONE <id> head=<sha> tests=<pass|fail> changed=<n>` or `JUNIOR-BLOCKED`; `herdr-watch-terminal.sh` output `TERMINAL:done|blocked|idle`; handback `Junior:` line |
| K08 | skills/dispatch-qa-walk/SKILL.md | 172 | model, Thomas-only | qa.md:28; thomas.md:120; check-reachability.py:619,633,635 | Thomas before a PR, merge or release on a user-visible surface or public endpoint | tab `qa:<id>`; brief `Mode:` line; GATE_FILE; `.scratch/qa/<key>-<sha>.md`; `.astraler/state/gate-history/walk-<artifact-key>-<short-sha>`; `.astraler/state/qa-verified-clean.md`; commit `qa(walk): <key> — <verdict>`; record `qa_mode`, `qa_last_*` |
| K09 | skills/dispatch-ticket/SKILL.md | 682 | model, Thomas | thomas.md:17,75,84,101,173; thomas-claude.md:11; builder.md:133 | before each dispatch and merge | transcript `Skill(skill: "dispatch-ticket")`; watchdog lock `/tmp/herdr-watchdog-<workspace-label>.lock`; tab `ticket:<id>`/`spec:<id>`/`qa:<id>`; `git worktree add -b`; dispatch-record entry (section "10. Write `.astraler/state/dispatch-record.json`", line 594); brief first line slash command; a `FLOW:` line in the brief (line 323; no mod code parses `FLOW:`) |
| K10 | skills/dispatch-ticket/CLEANUP.md | 177 | recipe | thomas.md:194 (via Watchdog section); check-simplify-markers cites; SKILL.md Cleanup | per merge/abandon | `git worktree remove`; `scripts/release-worktree-resources.sh`; plug `.astraler/project/cleanup-worktree.sh`; tab/pane close; claim release in tracker |
| K11 | skills/dispatch-ticket/GATE.md | 109 | recipe | dispatch-qa-walk, codex-arm (gate worktrees) | per gate (arm spec/slice, QA) | `gate-arm-*` worktrees; `$GATE_FILE`; `.astraler/state/gate-history/` |
| K12 | skills/dispatch-ticket/MARKERS.md | 121 | recipe | builder.md:133; thomas.md:168,170 | per merge and per Builder handback | marker shapes `arm(ticket):`, `arm(slice):`, `qa(walk):`, `simplify(increment):` and fields `Reviewed:`, `Vendor:`, `Tests:`, `Pass:`, `Unreviewed-delta:`, `Scope:`, `Verdict:`, `Report:`, `Mode:`; counts printed by check-simplify-markers.sh |
| K13 | skills/dispatch-ticket/WATCHING.md | 181 | recipe | thomas.md:188,191; builder-claude.md:109 | once before dispatch; per alert | `nohup scripts/herdr-watchdog.sh 300 900 6 &`; `herdr-watch-terminal.sh`; alert lines; `.astraler/project/work-in-flight.sh`, `watchdog-probe.sh` |
| K14 | skills/dispatch-ticket-claude/SKILL.md | 353 | model, Thomas | thomas.md:17,101; thomas-claude.md:12; register.tsx:1174 (message text) | before each dispatch | transcript Skill call; launcher command `--agent <role> --model … --effort … [--advisor …]`; mod gate messages S01-S08, G03-G05, G12; `.astraler/project/{status-line.sh,setup-worktree.sh,overlays/*}` |
| K15 | skills/github-issue-tracker/SKILL.md | 187 | model, Thomas | thomas.md:13; tracker-contract.md:19,136; ADAPT-HARNESS.md:89 | session start when docs/agents/issue-tracker.md names GitHub | transcript Skill call; `gh issue` / `gh api` commands; labels; assignee `builder/<id>` |
| K16 | skills/github-issue-tracker/project-status-sync.sh | 99 | script shipped inside skill | github-issue-tracker/SKILL.md (Projects board mirror); not listed in install/settings | when the Projects board mirror is used | `gh project` calls (see script header) |
| K17 | skills/jira-issue-tracker/SKILL.md | 146 | model, Thomas | thomas.md:13; tracker-contract.md:20,137 | session start when tracker is Jira | transcript Skill call; Jira transitions by number; JQL |
| K18 | skills/linear-issue-tracker/SKILL.md | 120 | model, Thomas | thomas.md:13; tracker-contract.md:21,138 | session start when tracker is Linear | transcript Skill call; Linear MCP calls |
| K19 | skills/legacy-testing/SKILL.md | 85 | model | builder.md:18; shaper.md:20; junior.md:18; untangle names it; ADAPT-HARNESS.md:418 | when code has no seam | skills_run `legacy-testing`; characterisation-test commits; seam-creation commit separate from behaviour change (legacy-testing:59) |
| K20 | skills/reconcile-tracker/SKILL.md | 175 | model, Thomas | thomas.md:16; github-issue-tracker names it; docs-staleness-audit.sh:151 (anchored duty) | session start; after every merge | transcript Skill call; runs `scripts/ticket-git-facts.sh` (reconcile-tracker:39,58); report of four drift classes in Thomas's text |
| K21 | skills/test-design/SKILL.md | 87 | model, Shaper | shaper.md:31,35,54,70; register.tsx:210 (chip `test-design`); dispatch-ticket-claude names it | per spec between Spec and Tickets | skills_run `test-design`; file `docs/qa/plan-<slug>.md`; later brief lines `QA plan: docs/qa/plan-<slug>.md` |
| K22 | skills/untangle/SKILL.md | 89 | model | builder.md:19; shaper.md:18; legacy-testing names it; check-reachability.py:343,636,638 | tangled refactor | skills_run `untangle`; file `docs/agents/boundaries.md` ("Write `docs/agents/boundaries.md`", untangle:81) |

## 2.2 Plugin and built-in skills and subagents the contracts name (30)
Trace for any row when run in a Builder/Shaper/QA pane: skills_run key = the exact name. When run by Thomas (resident): transcript only.
| id | skill / agent | named at | caller role | trigger | trace |
|---|---|---|---|---|---|
| P01 | `mattpocock-skills:implement` | builder.md:31,49 | Builder (user-invoked: brief first line `/mattpocock-skills:implement <ID>`) | per dispatch | skills_run; chip `implement`; mod P08 parses ID; S05/S06/S07/S08 gates on this brief |
| P02 | `mattpocock-skills:tdd` | builder.md:31,44; builder-claude.md:8 | Builder | per ticket | skills_run; chip `tdd`; G03 refuses content commit without it; handback `TDD: n/a — <why>` |
| P03 | `mattpocock-skills:code-review <Base>` | builder.md:32,41,86 | Builder | once per increment | skills_run `mattpocock-skills:code-review`; chip `review:matt` |
| P04 | built-in `code-review` (`Skill(skill: "code-review")`) | builder.md:33; builder-claude.md:16 | Builder | after P03, before simplify | skills_run `code-review`; chip `review:built-in`; G05 gates `codex-arm` on it |
| P05 | built-in `simplify` (`Skill(skill: "simplify")`) | builder.md:34; builder-claude.md:22 | Builder | after reviews | skills_run `simplify`; commit `simplify(increment): …` with `Pass: Skill(skill: "simplify")` (+ ` — <reason>`) |
| P06 | `mattpocock-skills:writing-for-agents` | builder.md:14 | Builder, edits to SKILL/AGENTS/CLAUDE/role contracts | conditional | skills_run |
| P07 | `mattpocock-skills:triage` | thomas.md:28 | Thomas | inbox item | transcript only; labelled tickets |
| P08 | `mattpocock-skills:wayfinder` | thomas.md:29; shaper.md:109 | Thomas | foggy multi-session effort | transcript only |
| P09 | `mattpocock-skills:to-questionnaire` | thomas.md:30,108,200; qa.md:199 | Thomas | owner decision | transcript only |
| P10 | `mattpocock-skills:ask-matt` | thomas.md:31 | Thomas | method question | transcript only |
| P11 | `mattpocock-skills:grill-with-docs` | shaper.md:28; thomas.md:97 | Shaper (brief first line `/mattpocock-skills:grill-with-docs`) | per shaping dispatch | skills_run; chip `align` |
| P12 | `mattpocock-skills:to-spec` | shaper.md:29 | Shaper | after Align | skills_run; chip `spec`; spec published with label `ready-for-agent` then downgraded to `needs-triage` |
| P13 | `mattpocock-skills:to-tickets` | shaper.md:32 | Shaper | after Test design | skills_run; chip `tickets`; tracker tickets with edges |
| P14 | `codebase-design` | shaper.md:14 | Shaper | seam placement | skills_run |
| P15 | `domain-modeling` | shaper.md:15 | Shaper | new domain terms | skills_run |
| P16 | `research` | shaper.md:16,81; thomas.md:198 | Shaper, Thomas | answer needs a source | skills_run (Shaper) / transcript |
| P17 | `prototype` | shaper.md:16,81; thomas.md:198 | Shaper, Thomas | answer needs a source | same |
| P18 | `improve-codebase-architecture` | shaper.md:17 | Shaper | refactor with boundaries | skills_run |
| P19 | `diagnosing-bugs`, `grilling`, `wizard` and the rest of the "craft layer" | builder.md:50 | Builder, model-invoked | no trigger specified | skills_run if invoked |
| P21 | `/compact`, `/clear` (CLI commands) | builder-claude.md:116; shaper.md:6 | Builder, Shaper | long tickets | transcript; mod compaction status ST04 |
| P22 | `Agent(subagent_type: "astragentic-dispatch:bmad-reviewer", isolation: "worktree")` | thomas.md:134 | Thomas | slice close | Agent call in transcript |
| P23 | `astragentic-dispatch:bmad-sally` | bmad-ux:48 | Builder/QA via bmad-ux | UX pass | Agent call |
| P24 | `astragentic-dispatch:bmad-john/mary/murat/paige/winston` | bmad-party | owner | round table | Agent calls (team) |
| P25 | `Agent(... isolation: "worktree")` report-only fan-out | builder-claude.md:35-40 | Builder | simplify/review fan-out | Agent call args `isolation: "worktree"` |
| P26 | `/mattpocock-skills:setup-matt-pocock-skills` | ADAPT-HARNESS.md:48 | owner | install | files docs/agents/{issue-tracker,triage-labels,domain}.md |
| P27 | herdr skill | check-requirements.sh C5 | Thomas, panes | dispatch | `herdr` CLI calls |
| P28 | codex plugin (`codex-companion`) | codex-arm | Builder/Shaper/Thomas | arm | `.scratch/gates/…` |
| P29 | advisor tool (`--advisor <value>`) | orchestrator.md:92; builder-claude.md:94 | Thomas, Shaper (rows set); Builder/QA unset by default | engine-decided | transcript `advisor` tool call |
| P30 | `ScheduleWakeup` | builder-claude.md:111 | Builder | background waits | transcript |


Section 2 rows: 2.1=22, 2.2=29 (P20 excluded).

# Parts 3, 5, 6 — scripts, settings hooks, installer/doctor

Repo root R = /Users/tranthien/Documents/2.DEV/2.PRIVATE/astragentic. Paths relative to R. Caller cites come from grep over roles, skills, install.sh, check-requirements.sh, settings.json, register.tsx, selftest.sh, README tables, other scripts. "log" = /tmp/harness-hook-events.log (hook-git-guard honours HARNESS_HOOK_LOG).

## 3. Scripts (harness/scripts)

| id | path | type | intended caller (cite) | trigger | observable trace |
|---|---|---|---|---|---|
| S01 | harness/scripts/check-payload-drift.sh | bash, VCS hook | thomas.md:175 (names the failure); README.md:477 "pre-commit … where a project has installed one"; check-requirements.sh:631-635 NAMED_SCRIPTS list; no install.sh/settings.json wiring found | per commit (project pre-commit) | stdout `OK: N watched path(s) match`, `DRIFT: <path> content changed`, `MISSING:`, `UNRECORDED:`, `FAIL:`; exit 0/1; reads .agents/payload-drift-manifest.json; `--update PATH` writes hash |
| S02 | harness/scripts/check-reachability.py | python, doctor | install.sh:311 run_selfcheck at staging; README.md:486 "after editing any contract, skill or role table"; README.md:496 | staging / manual | stdout `[OK] 1..10`, `[FAIL n]`, `All reachability checks passed`; exit 0/1 |
| S03 | harness/scripts/check-simplify-markers.sh | bash+python | builder.md:166-167; thomas.md:162; dispatch-ticket/MARKERS.md:11-12; CLEANUP.md:23,76; WATCHING.md:180; .claude/agents/thomas.md:25; register.tsx:855 (ARM: off text) | Builder before handback; Thomas per merge | stdout `[<kind>] markers=N`, `STOP: <msg>`, `markers=0 — STOP: no marker on base..head (AST-094)`; exit 0 green /1 STOP; kinds simplify(increment), arm(ticket), arm(slice), qa(walk); `marker-kinds.json`, `marker-evidence-paths.txt` plugs |
| S04 | harness/scripts/docs-staleness-audit.sh | bash, doctor | install.sh:312 run_selfcheck; README.md:487,498; check-requirements.sh:487; selftest.sh:224-226,376 | staging / manual | stdout `=== n. … ===`, `ok:`, `OVER:`, `TIGHT:`, `STALE`; exit 1 on any finding |
| S05 | harness/scripts/herdr-watch-terminal.sh | bash | dispatch-ticket/SKILL.md:477,484,536; WATCHING.md:55,74; dispatch-junior/SKILL.md:80; check-requirements.sh:266-274 (WARN if missing) | per turn on junior/QA-gate pane | stdout `TERMINAL:<done\|blocked\|idle> pane=<id>`, `TIMEOUT … pane=`, `NO_START pane=`; exit 0/1/2 |
| S06 | harness/scripts/herdr-watchdog.sh | bash daemon | dispatch-ticket/SKILL.md:114-116; WATCHING.md:112-117 (`nohup scripts/herdr-watchdog.sh 300 900 6 &`, `stop`); README.md:473 | once before any dispatch, stays running | lock /tmp/herdr-watchdog-<workspace-label>.lock; stdout `STOP: watchdog already running…`, `STOP: no workspace-label set in .agents/orchestrator.md`, `STOP: not in a git repo`, `STOP: could not create a private status directory`; alerts to Thomas pane (see WATCHING.md table) |
| S07 | harness/scripts/hook-contract-reload.py | python, runtime hook | harness/.claude/settings.json:31 (SessionStart compact) | SessionStart source=compact | stdout JSON `hookSpecificOutput.additionalContext`; log line `<ts> hook-contract-reload …` (EVENTS_LOG line 54) |
| S08 | harness/scripts/hook-git-guard.py | python, runtime hook | harness/.claude/settings.json:9 (PreToolUse Bash); check-requirements.sh:362-406 (presence, registration, smoke `git add -A` must deny) | per Bash tool call | log `<ts> hook-git-guard DENY \| <cmd[:120]>`; stdout JSON `permissionDecision":"deny"` + reason; deny sites hook-git-guard.py:536 (git add -A, AST-054), 561 (rm -rf worktree, AST-096), 574 (sweeping add), 584 (worktree add absolute path, AST-028), 600 (registered but missing), 620 (uncommitted worktree), 633 (resources not released), 644 (lsof unverifiable), 657 (broker bound), 665 (processes inside), 720 (push without ticket-done stamp), 753 (push without `Ledger:` line) |
| S09 | harness/scripts/hook-tracker-status.py | python, runtime hook | harness/.claude/settings.json:40 (SessionStart ""); tracker-contract.md:80; install.sh:451 | SessionStart (all sources) | stdout JSON additionalContext; log `<ts> hook-tracker-status <line>` (hook-tracker-status.py:86); reads .astraler/project tracker plug |
| S10 | harness/scripts/ledger-index.sh | bash, generator | install.sh:276 (regenerate in staging), :315 (`--check`); README.md:488,497; register.tsx:1132 (message text only); selftest.sh:192-210 | after ledger edit; staging | stdout `ok: INDEX.md current`, `STOP: INDEX.md is stale — run scripts/ledger-index.sh`, `STOP: ledger not found`; writes harness/.agents/memory/INDEX.md |
| S11 | harness/scripts/ledger-rules.py | python, generator | install.sh:277,316; register.tsx:1132 (text); RULES.md:3 header; selftest.sh:235-240 | after ledger edit; staging | stdout `ok: RULES.md current (N entries)`, `STOP: RULES.md is stale/missing`, `STOP: ledger not found`; writes RULES.md |
| S12 | harness/scripts/pre-push-ticket-done.sh | bash, VCS hook | check-requirements.sh:317,348-357 (must be called from pre-push); ADAPT-HARNESS.md:489-494; selftest.sh:586-592 | per `git push` | stderr `pre-push: REFUSED — this push lands merge(s) for <ids> on …`; exit 1; reads stamp dir |
| S13 | harness/scripts/reap-worktree-processes.sh | bash | release-worktree-resources.sh:48-53 (calls it); check-reachability.py:730 notes it | at worktree removal (via S14) | stdout prefix `reap-worktree-processes:` + `KILLING pid=`, `SKIP pid=`, `ABORT`, `STOP — lsof produced no usable process listing`, `no processes rooted in`, `reaped N process(es)`, `WARNING pid=… still alive after SIGKILL` |
| S14 | harness/scripts/release-worktree-resources.sh | bash | settings.json:20 (WorktreeRemove hook); register.tsx:1387-1389; thomas.md:194; CLEANUP.md:144; dispatch-qa-walk/SKILL.md:161; codex-arm/SKILL.md:160,171; dispatch-ticket-claude/SKILL.md:33,252 | per worktree removal | stdout prefix `release-worktree-resources:` + `worktree=`, `running project plug`, `NOTE — no project cleanup declared at .astraler/project/cleanup…`, `STOP — … not executable`, `WARN reap exited`, `WARN project plug exited`, `compose project`, `stamped $STAMP_DIR/<key>` / `NOT stamped (exit rc)`; stamp file under $HARNESS_STAMP_ROOT or /tmp; plug .astraler/project/cleanup* |
| S15 | harness/scripts/selftest.sh | bash, test | install.sh:322 (ASTRALER_IN_SELFTEST=1 run_selfcheck selftest); check-reachability.py:803 PACKAGE_ONLY | staging | stdout `selftest: N passed, M FAILED (<layout> layout, K package-only section(s) skipped)`; exit nonzero on FAIL |
| S16 | harness/scripts/ticket-done.sh | bash | thomas.md:177 (`scripts/ticket-done.sh <id> --moved "…"`); thomas-claude.md:23; reconcile-tracker/SKILL.md:44; dispatch-ticket-claude/SKILL.md:32,139; consumed by S08 (hook-git-guard.py:720) and S12 | per merge (after frontier write-back) | stdout `ticket-done: <id> on base <b>`, `STOP — nothing on <base> carries <id>`, `STOP — tracker says <id> is <state>…`, `NOTE — tracker half unverified`, `NOTE — --moved not given`, `NOT stamped (exit rc)`; stamp file; plugs .astraler/project/tracker-state.sh and ticket-done plug |
| S17 | harness/scripts/ticket-git-facts.sh | bash | reconcile-tracker/SKILL.md:39,58-59; README.md:476 | session start and after every merge | stdout per-ticket facts lines prefix `ticket-git-facts:` for errors (`TICKET_PREFIX must…`, `base branch…`, `no ticket ids found on…`); needs env TICKET_PREFIX |
| S18 | harness/scripts/lib/marker_field_parser.py | python module | imported by check-simplify-markers.sh:119 (`import marker_field_parser`) | with S03 | none of its own (field-region parse) |

Section 3 rows: 18 (17 scripts + 1 lib).

## 5. Hooks in harness/.claude/settings.json

| id | event | matcher | script | log line written | cite |
|---|---|---|---|---|---|
| H1 | PreToolUse | Bash | scripts/hook-git-guard.py (fallback harness/scripts/…; python3 -c cat fallback on EPERM) | `<ts> hook-git-guard DENY \| <cmd>`; if script missing: `<ts> hook-git-guard MISSING under <dir>` + stderr `hook-git-guard: NOT FOUND` | settings.json:5-12 |
| H2 | WorktreeRemove | "" | scripts/release-worktree-resources.sh "$WORKTREE_PATH" | `HOOK: WorktreeRemove — path=<p> at <ts>`; missing: `<ts> release-worktree-resources MISSING under <dir>` | settings.json:15-22 |
| H3 | SessionStart | compact | scripts/hook-contract-reload.py | `<ts> hook-contract-reload …`; missing: `<ts> hook-contract-reload MISSING under <dir>` | settings.json:27-33 |
| H4 | SessionStart | "" | scripts/hook-tracker-status.py | `<ts> hook-tracker-status <line>`; missing: `<ts> hook-tracker-status MISSING under <dir>` | settings.json:35-41 |
| H5 | SubagentStop | "" | inline shell (no script) | `HOOK: SubagentStop — type=<t> id=<id> session=<sid> payload_size=<n> exited` | settings.json:46-52 |

Also: harness/.claude/skills/astragentic-dispatch/hooks/hooks.json (34 bytes) registers the mod; mod events are in the mod section (part 4).

Section 5 rows: 5.

## 6. Installer / doctor

### 6a. install.sh phases (R/install.sh)

| id | phase | lines | what it asserts / does | trace |
|---|---|---|---|---|
| I1 | package completeness | 36-38 | PAYLOAD, ADAPT/UNINSTALL prompts, RELEASE-NOTES, README, check-requirements exist | `ERROR: package is incomplete, missing …` |
| I2 | version heading | 41-46 | RELEASE-NOTES heading `# Astragentic $VERSION` matches VERSION | `ERROR: RELEASE-NOTES.md needs a heading…` |
| I3 | skill twin sync | 48-120 | .agents/skills vs .claude/skills byte-identical per file; DIVERGENT_ALLOWLIST validated | `ERROR: .agents/skills/<s>/<f> has no .claude/ twin` / `differs from its .claude/ twin` / `allowlisted pair … missing` / `… identical` |
| I4 | ledger header + README badges | 122-160 | auto-updates entry count header; README badge numbers | `Ledger header auto-updated: N entries (AST-001 … AST-nnn)` |
| I5 | arg parse | 162-200 | `<target> [--project-name NAME] [--plan\|--apply]`; project name default | `Usage: …` |
| I6 | worktree warning | 204-222 | warns when target has >1 checkout | `NOTE: <target> has N checkouts (worktrees)` |
| I7 | staging build | 224-292 | copies payload into STAGING_DIR, regenerates INDEX/RULES against staged tree (276-277), stages VERSION, install.sh, astragentic.sh (290) | none (silent) |
| I8 | self-checks | 293-330 | run_selfcheck: check-reachability, docs-staleness, ledger-index --check, ledger-rules --check, selftest (not when ASTRALER_IN_SELFTEST) | `ERROR: <label> failed — the release does not ship until it passes` |
| I9 | immutability | 331-349 | existing release dir must equal staged copy | `Astraler release V is already staged and unchanged.` / `ERROR: staged release V differs from this package source.` / `Staged Astraler release V at <dir>` |
| I10 | --apply/--plan | 372-735 | per-file classes: NEW, owner (kept), kept, updated, CONFLICT (three-way vs applied-version release), settings.json hook merge (520-534), deleted-upstream (638), IGNORED by .gitignore (659), stamps .astraler/state/applied-version (673), writes .astraler/state/apply-incomplete on conflict, copies astragentic.sh to .astraler/ (682) | summary line `new N · updated N · unchanged N · kept N · owner-kept N · conflicts N · deleted-upstream N`; `--plan: what an --apply would do…`; `--apply: writing payload into`; `CONFLICT <rel> — …`; `Payload PARTIALLY applied`; `Payload applied. ADAPT-HARNESS.md still owns the semantic half` |

### 6b. check-requirements.sh groups (R/check-requirements.sh; usage `[target] [--optional-too] [--adapted]`; exit 0/1/2; messages `[OK]`/`[MISS]`/`[WARN]` + `→ fix`)

| id | group | lines | check | ok / warn / miss message prefix |
|---|---|---|---|---|
| C1 | MACHINE (required) | 61-83 | claude CLI on PATH; Claude Code version vs CLAUDE_FLOOR (mod loads) | ok `claude CLI`, `Claude Code X loads the dispatch mod`; miss `Claude Code … is below`, `claude CLI not on PATH` |
| C2 | MACHINE | 85-123 | mattpocock-skills plugin present and >= PLUGIN_FLOOR | miss `mattpocock-skills plugin not installed` / `… is below the floor`; warn `version unreadable`; ok `mattpocock-skills plugin X (>= floor)` |
| C3 | MACHINE | 125-150 | bundled skills / skillOverrides must not restrict `simplify` | warn `bundled skills are disabled`, `skillOverrides restricts 'simplify'`; ok `bundled skills reachable by the model` |
| C4 | MACHINE | 152-157 | git with worktree support | ok/miss `git with worktree support` |
| C5 | MACHINE | 160-196 | herdr version >= HERDR_FLOOR, agent API (prompt/wait/read/start), herdr skill | ok `herdr X >= floor`, `herdr skill`; miss `herdr … below the required floor`, `herdr lacks the required agent API`, `herdr not on PATH`, `herdr skill missing` |
| C6 | MACHINE | 198-233 | codex CLI and Codex plugin, waived when all arm scopes are `no` in orchestrator | ok `codex CLI and plugin: not required`, `codex CLI`, `Codex plugin in Claude Code`; warn `codex CLI not on PATH`, `Codex plugin not installed` |
| C7 | MACHINE | 235-262 | orchestrator Active assignments table + Advisor column | miss `orchestrator: no Active assignments table found`, `… has no Advisor column`; ok `… carries the Advisor column` |
| C8 | MACHINE | 264-275 | watcher script herdr-watch-terminal.sh present | ok `<WATCHER> present`; warn `scripts/herdr-watch-terminal.sh missing` |
| C9 | TARGET | 277-306 | docs/agents/*.md present (miss when --adapted) | ok `docs/agents/<doc>.md`; miss `… is missing after adaptation`; warn `… not present yet`; or `TARGET: not checked (no target path given)` |
| C10 | TARGET | 308-345 | git core.hooksPath directory and hook executability | miss `git core.hooksPath is … but … is not a directory`, `holds hooks that are not executable`; ok `git core.hooksPath -> …` |
| C11 | TARGET | 346-358 | pre-push gate wired to pre-push-ticket-done.sh | miss `scripts/pre-push-ticket-done.sh is missing`, `no executable pre-push hook`, `does not call scripts/pre-push-ticket-done.sh`; ok `pre-push gate wired` |
| C12 | TARGET | 360-410 | hook-git-guard.py present, registered PreToolUse/Bash in .claude/settings.json, smoke test denies `git add -A` | ok `scripts/hook-git-guard.py present`, `… has a PreToolUse/Bash command hook naming hook-git-guard.py`, `the guard denies a command it must deny`; miss `… is missing`, `registered guard did not deny`, `has no PreToolUse/Bash hook`, `could not be parsed` |
| C13 | TARGET | 412-416 | target is git work tree | ok `target is a git work tree` |
| C14 | INTEGRATION | 441-480 | applied-version marker vs candidate; apply-incomplete | miss `an apply stopped part-way`, `no applied-version marker`; ok `applied-version (X) matches CANDIDATE`, `… is landed and clean` |
| C15 | INTEGRATION | 482-560 | payload files match release, owner-owned, or named in ADAPTATION record; NAMED_SCRIPTS list 631-635 | ok `every payload file matches the release, is owner-owned, or is named in ADAPTATION…`; miss `payload files differ from the release and no record says why` |
| C16 | INTEGRATION | 562-690 | commits exist; payload committed and visible in worktrees | miss `target repo has no commits yet`, `harness payload has N untracked and M uncommitted…`, `target is not a git work tree`; ok `harness payload is committed and matches HEAD` |
| C17 | OPTIONAL (project-dependent) | 695-712 | agent-browser CLI and skill | ok `agent-browser CLI`, `agent-browser skill`; warn `… not on PATH`, `… missing` |
| C18 | verdict | 713 | summary | `REQUIRED checks failed — fix the [MISS] items above before installing the harness.` |

### 6c. check-reachability.py checks (docstring says "Eleven checks" but lists and prints 10)

| id | check | line | asserts | trace |
|---|---|---|---|---|
| R1 | METHOD -> CONTRACT | 315 | every phase in README role table owned by exactly one contract, the named role | `[OK] 1` / `[FAIL 1]` |
| R2 | CONTRACT -> UNIQUE | 372 | each declared phase declared once | `[OK] 2` / `[FAIL 2]` |
| R3 | SKILL -> NAMED | 378 | every harness skill string-named by a contract, skill or ADAPT prompt (a string find, not proof of invocation) | `[OK] 3` / `[FAIL 3]` |
| R4 | REFERENCE -> EXISTS | 398 | payload paths and skill names referenced by contracts/skills resolve (hard fail) | `[OK] 4` / `[FAIL 4]` |
| R5 | ROLE -> STARTABLE | 468 | each role has a launcher and a dispatcher that names it | `[OK] 5` / `[FAIL 5]` |
| R6 | ADDRESS -> CALLABLE | 504 | skills invoked in the form the caller can use (user-only vs model-invocable; AST-051) | `[OK] 6` / `[FAIL 6]` |
| R7 | ARTIFACT -> PRODUCED AND VERIFIED | 592 | each gate artifact named by producer and verifier contract | `[OK] 7` / `[FAIL 7]` |
| R8 | WRITES -> REGISTERED | 698 | each document a skill declares it writes has a registry row naming its reader | `[OK] 8 … (N write heading(s) read)` / `[FAIL 8]` |
| R9 | SHIPPED -> CALLED | 724 | every shipped script called from session context, skill, runtime hook, project plug, VCS hook, installer or wired script (needs a staged release or scores nothing: `[--] 9`) | `[OK] 9 … (N scripts, 0 orphans)` / `[FAIL 9]` |
| R10 | ASSERTION -> TRUE | 885 | every live `Bound:`/`Wired`/`Enforced by` in the ledger resolves; `(gone)` retires | `[OK] 10 … (N assertion citation(s) read)` / `[FAIL 10]` |

Final lines: `All reachability checks passed.` or `N finding(s). A phase or skill nothing reaches will not run.`; 24 fail() sites total.

### 6d. docs-staleness-audit.sh axes (usage `docs-staleness-audit.sh [root]`; exit 1 on finding)

| id | axis | line | measures | trace |
|---|---|---|---|---|
| D1 | always-on word budgets | 48 | `.claude/rules/` total 1100 words (91); per-role roles/<role>.md budget with MIN_MARGIN=100 (207); orchestrator.md 950 (237) | `ok: <label> = n/limit words (m margin)`, `OVER:`, `TIGHT:` |
| D2 | self-reported counts vs the thing counted | 249 | numbers stated in docs vs counted | `ok:` / stale-count line |
| D3 | documented signal strings vs emitter output | 334 | strings docs quote exist in the emitting script | `ok:` / missing-string line |
| D4 | payload names no real project, ticket or host | 428 | project-noun guard over payload (incl. prompts/) | finding lines naming the token |
| D5 | ledger index vs the ledger | 520 | INDEX.md consistent with ledger | `ok:` / stale line |

### 6e. selftest.sh sections (echo headers, harness/scripts/selftest.sh)

| id | line | section header |
|---|---|---|
| T01 | 89 | hook-git-guard — accidental misuse it must catch |
| T02 | 98 | hook-git-guard — correct work it must NOT block |
| T03 | 108 | hook-git-guard — a sweeping add is judged even on an unreadable line (4.0.2) |
| T04 | 142 | hook-git-guard — the registered wrapper's unreadable-file fallback runs the same guard (4.0.2) |
| T05 | 178 | argument conventions — a check must not depend on flag position (2.7.2) |
| T06 | 221 | root resolution — bare, with an explicit root, and from an unrelated cwd |
| T07 | 270 | marker gate — advisory span and regex dialect (2.7.3, AST-136) |
| T08 | 305 | install.sh — layouts and paths it is actually invoked from |
| T09 | 373 | docs-staleness axis 4 — the project-noun guard runs in package layout |
| T10 | 405 | release-worktree-resources — empty socket speaks, plug runs, plug failure propagates (2.7.15) |
| T11 | 500 | ticket-done — base push refused without the stamp, admitted with it, tracker plug decides (2.8) |
| T12 | 643 | ledger line — declared, not mentioned (2.9.0) |
| T13 | 697 | worktree residency — by real cwd, fails closed without lsof (2.8) |
| T14 | 739 | one rule, registered where it is loaded |
| T15 | 794 | hook-tracker-status — the moment, and every way the plug can let it down |
| T16 | 841 | reachability — mention is not invocation, an assertion is about now |
| T17 | 876 | I am shipped and nobody runs me |
| T18 | 1002 | watchdog — a stall beside a busy sibling, a pane that never started, a run in the background |
| T19 | 1070 | watchdog — one alert per episode, not one per poll |
| T20 | 1108 | astragentic.sh update — installed vs latest, the gap's notes, the one-liner (3.3.0) |
| T21 | 1160 | dispatch mod — the engine's reader loads it, and refuses a broken copy |
| T22 | 1193 | dispatch mod — a brief sent to "name [ref]" is cleared by the ack from "name" |

Case count: 44 `ok`/`bad` call lines by grep (helpers invoked in loops, so executed cases are more). Final line `selftest: N passed, M FAILED …`.

### 6f. get.sh, astragentic.sh, .githooks

| id | file | interface | cite | trace |
|---|---|---|---|---|
| G1 | get.sh | `curl … get.sh \| bash -s -- [version\|latest] [--apply\|--plan]`; env ASTRAGENTIC_REPO, ASTRAGENTIC_CACHE; fetches tag into ~/.cache/astragentic/<v>/, runs that release's install.sh against cwd | header lines 3-20; called by astragentic.sh update --apply (117) | `get.sh: fetching astragentic vV into <dest>`, `get.sh: running vV install.sh against <target>`, errors `get.sh: not a git repository`, `no release tag vV`, `says VERSION=… expected … refusing to run a mismatched installer` |
| G2 | astragentic.sh `version` | prints installed version from .astraler/state/applied-version | lines 42-43 | stdout version or `none` |
| G3 | astragentic.sh `update` | read-only: installed vs latest tag, release notes between, one-liner | lines 44-108 | `astragentic: installed X · latest Y (N release(s) behind: …)`, `installed X — this is the latest release.`, `not applied in <root> (no .astraler/state/applied-version)`, `To upgrade, in the project root:` |
| G4 | astragentic.sh `update --apply` | runs get.sh latest --apply | lines 112-117 | `astragentic: applying <latest>`; errors `unknown command`, `could not list release tags` |
| G5 | .githooks/pre-commit | package repo's own pre-commit (sh): refuses staged blob > 50 MB | R/.githooks/pre-commit | stderr `pre-commit: STOP — <file> is N MB, over the 50 MB line`; exit 1; override `--no-verify`; not in harness payload |

Section 6 rows: 6a 10, 6b 18, 6c 10, 6d 5, 6e 22, 6f 5 = 70.

# Section 4 — Mod: harness/.claude/skills/astragentic-dispatch/hooks/register.tsx (1628 lines)

Path prefix for lines: register.tsx. Record = `.astraler/state/dispatch-record.json` (RECORD, line 91). MARK = `[astragentic-dispatch]` (line 50). Log = `/tmp/harness-hook-events.log`.
Side = D (dispatcher: `me` null) / P (dispatched pane: `me` set) / both.

## 4.1 on(...) registrations (17)
| id | line | event / filter | side | trigger | observable trace |
|---|---|---|---|---|---|
| M01 | 771 | session.start | both | pane/session start, reload, resume | record entry created (role, tab_id, pane_id, session_id, worktree, branch, start_sha, registered_at); toast `astragentic-dispatch: <role> <key> recorded (tab …, pane …)`; D: command `dispatch-board` registered, 30s clock poll, release-check status |
| M02 | 825 | turn.start (main loop only, agentId undefined) | both | each main-loop turn | P: record `waiting_on: null` if own pane held; D: isBusy=true (bells held) |
| M03 | 848 | prompt.compose | both | each prompt build | system-prompt section id `astragentic-dispatch:overlay` (scope session) = overlays/<role>.md + ARM text + dispatcher-address text |
| M04 | 874 | session.receive | both | every cross-session message | D: consumes RECEIVED / TURN-END marks (`consumed: astragentic-dispatch: …`); P: runs dispatcher message as user turn (`consumed: astragentic-dispatch: dispatcher message run as a user turn`) and sends RECEIVED |
| M05 | 966 | skill.prompt | P (non-resident) | every Skill expansion in a pane | record `skills_run.<skill> = ts` |
| M06 | 980 | turn.complete | both | each main-loop turn end | P: sends `[astragentic-dispatch] TURN-END key=… pane=… reason=…`; record last_turn_end_at etc.; D: refreshBoard + flushBells |
| M07 | 1064 | session.send | both | every SendMessage | P: readdress to dispatcher; D: brief gates (see 4.2), appends overlays/dispatch-brief.md to briefs, notes send in `sends` map |
| M08 | 1200 | prompt.submit | both | every prompt | P: isNoticeTurn flag; D: adds context notes (No RECEIVED / owed ticket-done) |
| M09 | 1221 | tool.call {tool: AskUserQuestion} | P non-resident | picker call | deny G01 |
| M10 | 1241 | tool.call {tool: Bash} | P non-resident | each Bash | deny G02 (refused-in-dispatched-panes) |
| M11 | 1256 | tool.call {tool: Bash} | P builder | each Bash with git commit | deny G03 (tdd-gate) |
| M12 | 1290 | tool.call {tool: Bash} | P non-resident | each Bash | deny G04 (wait-gate) |
| M13 | 1298 | tool.call {tool: Skill} | P builder | Skill codex-arm / codex-claude-arm | deny G05 (arm-gate) |
| M14 | 1310 | tool.call {tool: Bash} | D | each Bash | herdr close guard G06/G07, worktree-remove G08-G11, worktree-add setup plug, merge gate G12 + notes |
| M15 | 1529 | command.run {command: dispatch-board} | D | `/dispatch-board` | opens pane `dispatch-board`; text `Dispatch board opened.` |
| M16 | 1535 | ui.render {component: Pane, requestId: dispatch-board} | D | board pane render | rows `key role state age note` |
| M17 | 1557 | ui.render {component: AbovePrompt} | both | every render | P: chips (role key, per-step chips, refusal chip, mode chip, version); D: branch/version/latest/board chips/status-line extra |

Other registrations inside session.start: `$.command.register dispatch-board` (814, D only); `$.clock.every(15_000)` compaction poll (805, P); `$.clock.every(30_000)` refreshBoard + wakeFromRecord (817, D).

## 4.2 Deny / refusal sites (all prefixed; 21)
Gate = value passed to logRefusal (logs `<iso> astragentic-dispatch REFUSED <gate> key=<key> <detail>` to Log and appends `{at,gate,detail}` to record `refusals[]`). "none" = deny without logRefusal.

| id | line | kind | exact message prefix / start | trigger | gate logged | observable trace |
|---|---|---|---|---|---|---|
| G01 | 1225 | deny (tool.call) | `astragentic-dispatch: no human is at this pane (<role> <key>).` | AskUserQuestion in dispatched pane | none | tool result deny text only |
| G02 | 1250 | deny (tool.call) | `astragentic-dispatch: this command matches "<pat>" in .astraler/project/refused-in-dispatched-panes` | Bash matching a regex in plug | refused-command | Log line REFUSED refused-command; record refusals[] |
| G03 | 1272 | deny (tool.call) | `astragentic-dispatch: no record of mattpocock-skills:tdd in this pane, and the brief declares no "TDD: n/a — <why>".` | content git commit (no --allow-empty) in builder worktree with no tdd in skills_run and no tdd_na | tdd-gate | Log REFUSED tdd-gate |
| G04 | 1295 | deny (tool.call) | `astragentic-dispatch: refused — <why>.` + WAIT_FIX (`Key the wait on the pid you launched: …`) | Bash with until/while loop keyed on pgrep/ps, or no-sleep loop | wait-gate | Log REFUSED wait-gate |
| G05 | 1306 | deny (tool.call) | `astragentic-dispatch: no record of the built-in code-review (Skill(skill: "code-review"), bare name) in this pane, and the brief declares no "REVIEW: n/a — <why>".` | builder calls Skill codex-arm / codex-claude-arm with no `code-review` in skills_run and no review_na | arm-gate | Log REFUSED arm-gate |
| G06 | 1329 | deny (tool.call, D) | `astragentic-dispatch: resident pane <key> lives in <kind> <id>. Closing it is the owner's call, not yours.` | `herdr tab\|pane\|workspace close <id>` of a recorded resident | none | deny text |
| G07 | 1330 | deny (tool.call, D) | `astragentic-dispatch: <role> <key> is mid-turn in <kind> <id> (brief received, no TURN-END since). Closing it kills a working agent.` | herdr close of a mid-turn pane/tab | none | deny text |
| G08 | 1371 | deny (tool.call, D) | `astragentic-dispatch: cannot tell which worktree "<raw>" is — it is expanded by the shell after this check runs.` | `git worktree remove` with `$`, backtick or `~` in path | none | deny text |
| G09 | 1377 | deny (tool.call, D) | `astragentic-dispatch: "<raw>" resolves to <target>, which is not a worktree of this repository (git worktree list).` | worktree remove of path not in `git worktree list` | none | deny text |
| G10 | 1383 | deny (tool.call, D) | `astragentic-dispatch: <role> <key> is mid-turn in <target>. Removing its worktree destroys work in progress.` | worktree remove of recorded mid-turn worktree | none | deny text |
| G11 | 1393 | deny (tool.call, D) | `astragentic-dispatch: releasing <target> failed, so it was not removed:` | release-worktree-resources.sh exit != 0 | none | deny text with last 15 lines |
| G12 | 1500 | deny (tool.call, D) | `astragentic-dispatch: <key> has no record of: <gaps>. The Builder's pane records every Skill call…` | `git merge` / `gh pr merge` naming a builder key/branch whose entry has session_id, ≥1 skills_run, and a FLOW gap (tdd, Matt's code-review, built-in code-review, simplify) not covered by tdd_na/review_na | merge-gate | Log REFUSED merge-gate `no record of: …` |
| S01 | 1097 | send refusal (isDelivered false, reason) | `[astragentic-dispatch] not sent. A harness upgrade stopped part-way (<.astraler/state/apply-incomplete>)` | slash-command brief while `.astraler/state/apply-incomplete` exists | none | send result reason |
| S02 | 1112 | send refusal | `[astragentic-dispatch] not sent. 2.18.0 added an Advisor column to the Active assignments table in .agents/orchestrator.md` | brief while orchestrator.md Active assignments header lacks `Advisor` | none | send result reason |
| S03 | 1136 | send refusal | `[astragentic-dispatch] not sent. Payload files are edited or untracked in this checkout, and a worktree sees only HEAD` | brief while dirtyPayload() non-empty and no `Uncommitted-payload: <why>` line | none | send result reason; ack line `^Uncommitted-payload:[ \t]*(\S.*)$` |
| S04 | 1144 | send refusal | `[astragentic-dispatch] not sent. <owedText>` = `<ids> reached the base but has/have no ticket-done evidence. Owed now: …` | brief while owedTickets() non-empty | none | send result reason |
| S05 | 1156 | send refusal | `[astragentic-dispatch] not sent. The tracker says <id> is "<line>", so it is not claimed.` | `/mattpocock-skills:implement <ID>` brief where tracker-state.sh says assignee `-`/empty or state closed/unclaimed | none | send result reason |
| S06 | 1174 | send refusal | `[astragentic-dispatch] not sent. The brief carries no "QA: walk\|probe\|verify\|none — <why>" line.` | implement brief with no QA line | none | send result reason |
| S07 | 1178 | send refusal | `[astragentic-dispatch] not sent. QA: <mode> is declared but no "QA plan: docs/qa/plan-<slug>.md" line names the plan.` | QA mode != none with no `QA plan:` line | none | send result reason |
| S08 | 1182 | send refusal | `[astragentic-dispatch] not sent. QA plan: <plan> does not exist in this checkout.` | QA plan path not on disk | none | send result reason |
| X01 | 890 | consume (session.receive, D) | `astragentic-dispatch: <key> turn end from a retired lane` (+ status `a turn end from <key> (pane …) arrived after its lane was retired — dropped`) | TURN-END whose pane != record pane_id | none | status text |

## 4.3 Bell / prompt / status / toast text
| id | line | kind | text (exact start) | trigger | observable trace |
|---|---|---|---|---|---|
| B01 | 903 | bell (D prompt) | `[astragentic-dispatch] <role> <key> ended its turn (<reason>). A bell, not proof: verify by artifact before acting.\n\nIts last words:` | TURN-END message matching record | prompt text in dispatcher transcript |
| B02 | 702 | bell (D, from record) | `[astragentic-dispatch] <role> <key> ended its turn (<reason>) — read from the record: its TURN-END message was not delivered (<reason>).` | turn_end_pending in record, poll 30s | same |
| B03 | 691 | bell (D) | `[astragentic-dispatch] <role> <key> has held its turn end for <ago> (reason=held-stale): <n> agent(s) still running` | waiting_on older than HOLD_STALE_MS (20 min), once (stale_rung_at) | same; record waiting_on.stale_rung_at |
| B04 | 734 | bell (D, batched) | `[astragentic-dispatch] <n> turn ends arrived while you were busy; read them together.` | bells held while isBusy, flushed at turn.complete | same |
| B05 | 937 | pane→D message | `[astragentic-dispatch] RECEIVED key=<key> pane=<pane>` | every message to a pane | record `acked_at`, `session_name` |
| B06 | 1047 | pane→D message | `[astragentic-dispatch] TURN-END key=<key> pane=<pane> reason=<reason>\nSkills run: <list\|none>\n<answer last 1500>` | pane turn end (reason answer, aborted, error) | D bell B01; record last_turn_end_at |
| B07 | 950 | pane→D message | `[astragentic-dispatch] TURN-END key=… pane=… reason=command-failed\n/<command>: <err>` | `$.command.run` rejects | same |
| N01 | 1210 | prompt note (D, context) | `[astragentic-dispatch] No RECEIVED came back for: <keys>. The message may be held or lost; read that pane before assuming it is working.` | board row note `not confirmed received` (send >90s unacked) | prompt context |
| N02 | 1213 / 1524 | prompt/merge note | `[astragentic-dispatch] <owedText>` (+ ` The next brief will not be sent until this is done.` at merge) | owedTickets non-empty | tool result context |
| N03 | 1514 | merge note | `[astragentic-dispatch] <key> merged with no record of: <gaps>. A step the handback names n/a with its reason is fine; any other is a step that did not run.` | merge ran, builder entry has flow gaps | tool result context |
| N04 | 1518 | merge note | `[astragentic-dispatch] <key> merged owing a QA <mode> (declared on its brief) with no QA turn after the Builder's last.` | qaOwed() non-null at merge | tool result context |
| N05 | 1459/1460/1463 | setup-plug note | `[astragentic-dispatch] setup-worktree.sh ran for <wt>.` / `… FAILED (exit N) for <wt>: …` / `… could not run for <wt>: …` | `git worktree add` followed by existing worktree and plug present | tool result context |
| O01 | 869 | system section | id `astragentic-dispatch:overlay`; texts: `ARM: off — .agents/orchestrator.md § Cross-vendor arm has \`<scope>: no\`…` (860/855), `ARM: off at <scopes> …`, `Your dispatcher is the session <who>. A written reply goes there and nowhere else…` | prompt.compose | system prompt |
| T01 | 801 | toast | `astragentic-dispatch: <role> <key> recorded (tab <t>, pane <p>)` | session.start of dispatched pane | UI only |
| ST01 | 435 | status | `astragentic-dispatch: .astraler/state/dispatch-record.json is not valid JSON; not written` | patchRecord on unreadable record | UI only |
| ST02 | 726 | status | `astragentic-dispatch: <n> bell(s) held until this turn ends` | bell during busy turn | UI only |
| ST03 | 779 | status | `astragentic-dispatch: release <latest> exists (this project applied <applied>) — .astraler/astragentic.sh update says what changed` | D session.start, git ls-remote tag newer than applied-version | UI only; banner.latest |
| ST04 | 810 | status | `astragentic-dispatch: context compacted at the <N>k ceiling` / `compaction skipped (<reason>)` | compactDue and not busy (15s poll) | UI only; compaction in transcript |
| ST05 | 1007 | status | `astragentic-dispatch: <n> agent(s) still running — TURN-END held until they finish` | turn end reason=answer with live agents | UI only; record waiting_on |
| ST06 | 1017 | status | `astragentic-dispatch: <key> is no longer in the record (lane retired) — turn end not reported` | own pane_id != record | UI only |
| ST07 | 1056 | status | `astragentic-dispatch: TURN-END not delivered — <reason>; recorded for the dispatcher to pick up` | session.send isDelivered false | UI only; record turn_end_pending |
| ST08 | 1077 | status | `astragentic-dispatch: a reply to "<to>" readdressed to the dispatcher (<name>)` | pane's model-origin send to a non-dispatcher non-agent name | UI only; send `to` rewritten |
| ST09 | 889 | status | (see X01) | | |
| BD01 | 625-652 | board row notes | `resident`; `turn end read from record: its message was blocked, check that pane mode`; `tracker not closed` (state merged); `not confirmed received` (state sent, >90s); `<n> agent(s) still running, turn end held[ <ago> — stale, read that pane]`; `no brief yet`; `<last_turn_reason> · qa ○ <mode>` / `qa ✓ <mode>`; states registered/sent/working/ended/merged | refreshBoard | /dispatch-board pane and AbovePrompt chips |
| BD02 | 1579 | pane red line | `TURN-END not delivered to the dispatcher (<reason>). … This pane is not in bypass-permissions mode: press shift+tab until it is.` | `undelivered` non-empty | UI only |
| BD03 | 1584-1604 | chips | `<role> <key>`; `⛔ <gate> refused` (120 s); `✓ <label>`, `n/a <label>`, `· <label>`, `▶ <label>`, `○ <label>`; `mode <qaMode>`; `astragentic <version>` | Builder FLOW_BY_ROLE (195-214): implement, tdd, atdd(opt), review:matt, review:built-in, ux(opt), simplify, arm; Shaper: align, spec, arm:spec, test-design, tickets; QA: none | UI only |
| BD04 | 1617-1624 | D chips | `⎇ <branch>`, `astragentic <ver>`, `<latest> available · .astraler/astragentic.sh update`, `no dispatches`, `<key> <state> <ago> · <note>`, status-line.sh extra | D AbovePrompt | UI only |

## 4.4 Record keys written (patchRecord / deleteRecordKey) — `.astraler/state/dispatch-record.json[<key>]`
Key = ticket id (`ABC-12`) for builder/shaper/resident (`spec:<id>` etc. keyed by tab label suffix), `qa:<id>` for QA.
| id | field | written at line | by | trigger | consumer |
|---|---|---|---|---|---|
| R01 | role | 790 | P session.start | pane start | owedTickets, board, gates |
| R02 | tab_id | 791 | P session.start | | herdr close guard, tab cleanup |
| R03 | pane_id | 792 | P session.start | | isLive, session.receive match, retired-lane checks |
| R04 | session_id | 793 | P session.start | | merge gate (only judges entries with session_id) |
| R05 | worktree | 794 | P session.start | | commitsInWorktree, worktree remove guard |
| R06 | branch | 795 | P session.start | | owedTickets ancestry, merge name match |
| R07 | start_sha | 796 | P session.start (kept across reloads) | | owedTickets (tip != start_sha) |
| R08 | registered_at | 797 | P session.start | | board |
| R09 | dispatcher / dispatcher_name | 928 | P session.receive | each non-mark message | |
| R10 | last_brief_received_at | 928 | P session.receive | each non-mark message | isMidTurn |
| R11 | tdd_na | 930 | P session.receive (brief only) | brief line `TDD: n/a …` | G03, G12, chip |
| R12 | review_na | 930 | P session.receive (brief only) | brief line `REVIEW: n/a …` | G05, G12, chip |
| R13 | qa_required | 931 | P builder session.receive (brief) | brief line `QA: walk\|probe\|verify\|none` | qaOwed, board note |
| R14 | qa_plan | 931 | P builder session.receive (brief) | brief line `QA plan: <path>` | none read in file |
| R15 | qa_mode | 932 | P qa session.receive (brief) | brief line `Mode: walk\|probe\|verify` | QA band chip, R22 |
| R16 | session_name / acked_at | 896 | D session.receive | RECEIVED mark | board, sends map |
| R17 | turn_end_pending (set / null / woken_at) | 1028, 1057, 901, 700 | P turn.complete; D consume/wake | undeliverable TURN-END | wakeFromRecord bell B02 |
| R18 | skills_run.<skill> = ts | 972 | P skill.prompt | any Skill expansion | G03, G05, G12, N03, chips, TURN-END `Skills run:` |
| R19 | waiting_on {n, at, what[], stale_rung_at} / null | 1006, 1032, 839, 689 | P turn.complete / turn.start; D wakeFromRecord | live agents at turn end | board, B03 |
| R20 | last_turn_end_at / last_turn_reason | 1027, 1032 | P turn.complete | turn end | isMidTurn, qaOwed, owedTickets |
| R21 | qa_last_turn_end_at / qa_last_mode (on ticket key `<key>`) | 1038 | P qa turn.complete | QA turn end | qaOwed |
| R22 | refusals[] {at, gate, detail≤200} | 238 | logRefusal (any gate) | G02,G03,G04,G05,G12 | flow chip, record |
| R23 | merged_at | 1508 | D tool.call after `gh pr merge` | merge | owedTickets |
| R24 | tab_closed_at | 1337 | D after `herdr tab close` | worktree still exists | worktree-remove cleanup |
| R25 | worktree_removed_at | 1405 | D after worktree remove | tab still alive | |
| R26 | (entry deleted) | 1338, 1404, 698 | deleteRecordKey | tab close with worktree gone; worktree removed with tab gone; stub with pending turn end and no pane | |

## 4.5 Files read / written by the mod
| id | path | line | direction | when | purpose |
|---|---|---|---|---|---|
| F01 | .astraler/state/dispatch-record.json | 91, 420, 439 | R/W | everywhere | the record |
| F02 | .astraler/state/applied-version | 537, 673, 774 | R | session.start, dirtyPayload, refreshBoard | version chip, release compare |
| F03 | .astraler/state/apply-incomplete | 1089 | R (exists + first 12 lines) | each slash-command brief | S01 |
| F04 | .astraler/releases/<applied>/harness/** | 541 | R (find) | each slash-command brief | payload file list for S03 |
| F05 | .astraler/project/overlays/<role>.md (builder, shaper, qa, resident, thomas) | 98, 138, 851 | R | prompt.compose | system-prompt section O01 |
| F06 | .astraler/project/overlays/dispatch-brief.md | 1187 | R | each slash-command brief from D | appended to the brief |
| F07 | .astraler/project/tracker-state.sh | 471 | R/exec `<plug> <id>` (30s) | implement brief (S05) | `<state> <assignee-or-dash>` first line; `unreachable`/empty/nonzero = empty socket |
| F08 | .astraler/project/status-line.sh | 658 | exec `bash` (5s) | each refreshBoard | first line, 160 chars → banner extra |
| F09 | .astraler/project/refused-in-dispatched-panes | 1243 | R | each Bash in dispatched pane | regex per line, `#` comments (G02) |
| F10 | .astraler/project/setup-worktree.sh | 1452 | exec `bash <plug> <wt>` (120s) | after `git worktree add` | N05 |
| F11 | .agents/orchestrator.md | 127, 1106 | R | `## Cross-vendor arm` rows (ticket\|spec\|slice → `no`), Active assignments header needs `Advisor` | O01 ARM text, chips, S02 |
| F12 | <git common dir>/astraler-stamps/harness-ticket-done/<ID> (or $HARNESS_STAMP_ROOT) | 504 | exists | owedTickets | written by scripts/ticket-done.sh |
| F13 | scripts/release-worktree-resources.sh (or harness/scripts/…) | 1387 | exec `bash <script> <target>` (600s) | worktree remove of recorded clean/forced worktree | G11 |
| F14 | docs/qa/plan-*.md (path in brief `QA plan:`) | 1180 | exists | implement brief with QA != none | S08 |
| F15 | /tmp/harness-hook-events.log | 245 | append `<iso> astragentic-dispatch REFUSED <gate> key=<key> <detail>` | logRefusal | grep `astragentic-dispatch REFUSED` |
| F16 | git ls-remote --tags --refs $ASTRAGENTIC_REPO (default https://github.com/thientranhung/astragentic.git) | 157 | exec (15s) | D session.start | ST03 |
| F17 | env: HERDR_TAB_ID, HERDR_PANE_ID, HERDR_BIN_PATH, HARNESS_STAMP_ROOT, BASE_BRANCH, ASTRAGENTIC_CONTEXT_CEILING (≥50000, default 200000), ASTRAGENTIC_REPO | 395, 485, 493, 803, 157 | R | | |

## 4.6 Brief / message line patterns the mod parses (grep targets in transcripts)
| id | line | pattern | in |
|---|---|---|---|
| P01 | 916 | first line starts with `/` = brief | any dispatcher message |
| P02 | 918 | `^TDD: n/a …` | brief (fenced blocks ignored) |
| P03 | 919 | `^REVIEW: n/a …` | brief |
| P04 | 923 | `^QA: (walk\|probe\|verify\|none)` | builder brief |
| P05 | 924 | `^QA plan: <path>` | builder brief |
| P06 | 926 | `^Mode: (walk\|probe\|verify)` | qa brief |
| P07 | 1128 | `^Uncommitted-payload: <why>` | any brief |
| P08 | 1150 | first line `/mattpocock-skills:implement <TICKET-ID>`; TICKET regex `^[A-Z][A-Z0-9]*-[0-9]+$` (170) | builder brief |
| P09 | 399 | tab label `^(ticket\|spec\|qa\|resident):(.+)$` → role builder/shaper/qa/resident | herdr tab label |
| P10 | 374 | `[astragentic-dispatch] (RECEIVED\|TURN-END) key=… pane=…( reason=…)?` | cross-session envelope |

## 4.7 Constants
| id | line | name | value |
|---|---|---|---|
| K01 | 140 | ACK_GRACE_MS | 90_000 |
| K02 | 144 | HOLD_STALE_MS | 20 min |
| K03 | 715 | contextCeiling | 200_000 tokens (env ASTRAGENTIC_CONTEXT_CEILING ≥ 50_000) |
| K04 | 716 | COMPACT_INSTRUCTIONS | keep ticket id/brief, phase, flow steps run, branch/HEAD, unfolded findings, handback owed |
| K05 | 57-62 | FLOW (merge-gate steps) | mattpocock-skills:tdd, mattpocock-skills:code-review, code-review, simplify |

## 4.8 Other files in the mod package and role system prompts
| id | path | type | content / trigger |
|---|---|---|---|
| A01 | harness/.claude/skills/astragentic-dispatch/hooks/hooks.json | manifest | `{"modules":["./register.tsx"]}` |
| A02 | harness/.claude/skills/astragentic-dispatch/.claude-plugin/plugin.json | manifest | name astragentic-dispatch, version 1.0.3, types ./types/index.d.ts |
| A03 | harness/.claude/skills/astragentic-dispatch/types/index.d.ts | types | BoardRow, Banner, Flow, PluginState |
| A04 | agents/bmad-john.md | subagent (tools Read,Grep,Glob,Bash) | PRD facilitation; called by skill bmad-party |
| A05 | agents/bmad-mary.md | subagent (Read,Grep,Glob,Bash) | research/brief/brainstorm |
| A06 | agents/bmad-murat.md | subagent (Read,Grep,Glob,Bash) | test plan/NFR/coverage trace |
| A07 | agents/bmad-paige.md | subagent (Read,Grep,Glob) | doc edit/index |
| A08 | agents/bmad-reviewer.md | subagent (Read,Grep,Glob,Bash) | slice-close adversarial read; named in thomas.md Slice gate as `Agent(subagent_type: "astragentic-dispatch:bmad-reviewer", isolation: "worktree")` |
| A09 | agents/bmad-sally.md | subagent (Read,Grep,Glob) | UX; called by bmad-ux skill |
| A10 | agents/bmad-winston.md | subagent (Read,Grep,Glob,Bash) | architecture/seam |
| A11 | harness/.claude/agents/builder.md | role system prompt (launched `--agent builder`) | tells role to read .agents/roles/builder.md, builder-claude.md; 4 compaction-surviving rules (sole writer; commit+push every phase; newest marker must be head; declare context exhaustion at 60%) |
| A12 | harness/.claude/agents/qa.md | role system prompt | read .agents/roles/qa.md Safety first; 4 rules (consent per dispatch; non-mutating default; data not environment; verdict valid for SHA walked) |
| A13 | harness/.claude/agents/shaper.md | role system prompt | read .agents/roles/shaper.md; 3 rules (no /compact /clear; every answer carries a source; stop after Spec, arm: spec fires) |
| A14 | harness/.claude/agents/thomas.md | role system prompt | read .agents/roles/thomas.md; supplement per builder runtime; 4 rules (claim precedes worktree; merge verified by artifact via check-simplify-markers.sh; count panes, top up to builder-target; merge not complete until frontier write-back reported) |

Row counts: 4.1=17, 4.2=21 (G01-G12 tool.call/deny, S01-S08 send refusals, X01 consume), 4.3=27 (ST09 duplicates X01), 4.4=26, 4.5=17, 4.6=10, 4.7=5, 4.8=14.

# Section 7 — Prompts

Both prompts are read by an agent launched by the owner in the target repo. Observable traces are artifacts in the adopter repo.

## 7.1 prompts/ADAPT-HARNESS.md (556 lines) — steps asked of the adopter
| id | section (line) | step asked | trace |
|---|---|---|---|
| AD1 | 1 Resolve the installation state (10) | read `.astraler/CANDIDATE`; read `.astraler/releases/<candidate>/RELEASE-NOTES.md` section (awk recipe) and every section back to previous applied version; read `.astraler/state/applied-version`; read live project (entry docs, manifests, git status) | Read calls; Bash `awk '/^# Astragentic <candidate>$/…'` |
| AD2 | 2.1 (42) | confirm mattpocock-skills plugin >= 1.3.1; stop and ask owner if absent | transcript; check-requirements C2 |
| AD3 | 2.2 (48) | ask OWNER to run `/mattpocock-skills:setup-matt-pocock-skills`; wait | owner message; files below |
| AD4 | 2.3 (57) | verify docs/agents/{issue-tracker,triage-labels,domain}.md exist by reading | Read of the 3 files; check-requirements C9 |
| AD5 | 2.4 (69) | record tracker ticket prefix in entry doc loaded at session start | line in AGENTS.md/CLAUDE.md; `TICKET_PREFIX` read by ticket-git-facts.sh |
| AD6 | 2.5 (74) | confirm tracker reachable | adapter command output |
| AD7 | 2.6 (83) | split issue-tracker.md into pointer half and adapter half (mechanics move to the adapter skill) | edited docs/agents/issue-tracker.md |
| AD8 | 3 Build an integration map (107) | classify reusable runtime vs project-owned vs plugs vs runtime-specific vs scaffold vs settings.json hook set vs role contracts | integration map in transcript |
| AD9 | 3 plugs (116-176) | write six plugs: cleanup-worktree.sh, tracker-state.sh, ticket-done.sh, tracker-status.sh, not-a-skill.txt, work-in-flight.sh (or decline) | files under `.astraler/project/`; ADAPTATION-REPORT.md one line per plug |
| AD10 | 3 (186-190) | BMAD personas and two skills are payload; `.astraler/project/` never written by a release | none |
| AD11 | 3 (202) | orchestrator.md is scaffold, written once, never overwritten; fill `<set-me>` | `.agents/orchestrator.md` values |
| AD12 | 3 (208) | settings.json hook set merge (install.sh merges) | `.claude/settings.json` hooks entries |
| AD13 | 3 (222-273) | role contracts and adapters wiring; entry-doc pointers | AGENTS.md/CLAUDE.md pointers |
| AD14 | 4 Apply (274) | list payload paths the project already wrote (DIFFERS loop over `.astraler/releases/$CAND/harness`), decide taken/merged/preserved; copy payload; gitignore check per payload file (323-330) | Bash loop output `DIFFERS: <path>`; `git check-ignore` calls; receipt lines |
| AD15 | 5 Brownfield entry (394) | `bootstrap-glossary` -> GLOSSARY.md; `batch-triage` only with existing backlog; two further model-invoked skills need no wiring (418) | GLOSSARY.md, docs/agents/GLOSSARY-review.md |
| AD16 | 6 Validate by artifact (445) | `git diff`; `bash -n` shell scripts; `./check-requirements.sh . --adapted`; `python3 scripts/check-reachability.py .`; populate `.agents/payload-drift-manifest.json` then install pre-commit hook for `check-payload-drift.sh` (chain, not overwrite); wire pre-push to `scripts/pre-push-ticket-done.sh` (489); state gitignore of `.astraler/` (505); CANDIDATE and applied-version agree (511); run docs-staleness-audit.sh and ledger-index.sh (516) | exit codes of those commands; `.git/hooks/pre-commit`, `.git/hooks/pre-push` or hook-manager entries |
| AD17 | 7 Record the receipt (528) | write `<candidate>` to `.astraler/state/applied-version`; OVERWRITE `.astraler/state/ADAPTATION-REPORT.md` (exceptions only, one line per plug); finish with `APPLIED` or `PENDING` | files; final word `APPLIED`/`PENDING` |

## 7.2 prompts/UNINSTALL-HARNESS.md (133 lines)
| id | section (line) | step asked | trace |
|---|---|---|---|
| UN1 | 1 Resolve what is installed (16) | read `.astraler/state/applied-version` (no marker = STOP); confirm `.astraler/releases/<applied>/harness/`; read entry docs and orchestrator.md | Read calls |
| UN2 | 2 Stop what is running (28) | `scripts/herdr-watchdog.sh stop`; `git worktree list`; `scripts/release-worktree-resources.sh <path>` per worktree before removal; never `pkill -f`; leave `.astraler/project/`; report live Builders | Bash commands; lock file removed |
| UN3 | 3 Classify every payload path by evidence (50) | identical / project-authored / modified vs release | classification list |
| UN4 | 4 Remove, in this order (74) | delete identical payload files; `.astraler/` last | `git status` deletions |
| UN5 | 5 Unwire the semantic half (90) | remove harness rows/pointers from AGENTS.md/CLAUDE.md; grep and fix stale pointers | edited entry docs |
| UN6 | 6 KEEP (102) | keep docs/agents/{issue-tracker,triage-labels,domain}.md, ledger, tickets/branches/commits; say so in receipt | receipt lines |
| UN7 | 7 Verify and receipt (114) | `git status`; `grep -rn '\.astraler\|\.agents/roles' --exclude-dir=.git .`; write `UNINSTALL-RECEIPT.md` at repo root; single commit | file `UNINSTALL-RECEIPT.md`; one commit |

Section 7 rows: 7.1=17, 7.2=7.
# Section 8 — Orchestrator rows (harness/.agents/orchestrator.md, 100 lines)

Scaffold: install.sh writes it only when absent (orchestrator.md:7). Readers split into mechanical (code parses the row) and prose (an agent is told to read it).

| id | row / table (line) | shipped value | mechanical reader (cite) | prose reader (cite) | trace |
|---|---|---|---|---|---|
| O1 | Workspace identity: workspace-label (21) | `<set-me>` | none in code. check-reachability.py:302,441 only checks the token exists in docs. docs-staleness-audit.sh:229 mentions blank value | thomas.md:11; dispatch-ticket/SKILL.md:116,201,212; WATCHING.md:116-117 | `herdr workspace list/create --label`; watchdog lock `/tmp/herdr-watchdog-<workspace-label>.lock` |
| O2 | Workspace identity: builder-target (22) | `4` | none (check-reachability.py:275 token check only) | thomas.md:58 (default 4); harness/.claude/agents/thomas.md:28 | count of live `ticket:<id>` tabs; no log line. Absent row defaults to 4 |
| O3 | Tab creator patterns (32-38) | thomas, `ticket:<id>`, `spec:<id>`, `qa:<id>` | register.tsx:399 (P09) regex `^(ticket|spec|qa|resident):(.+)$` assigns role from tab label | dispatch-ticket/SKILL.md | herdr tab labels; record role |
| O4 | Active assignments table (45-50): Role, Runtime, Model, Effort, Advisor | thomas claude opus-5 medium fable; shaper claude opus-5 high fable; builder claude sonnet-5 medium (no advisor); qa claude sonnet-5 low (no advisor) | register.tsx:1107-1113 refuses a brief when header lacks `Advisor` (S02); check-requirements.sh:249-259 (C7) | dispatch-ticket-claude/SKILL.md:280-300 launcher matrix (Thomas types `--model/--effort/--advisor`); orchestrator.md:79-100 | launcher command line in transcript; no code verifies the launched model equals the row |
| O5 | Junior table (54-56) | builder: `none` | none | builder.md:16,54; dispatch-junior/SKILL.md:11,41 | junior pane existence; `Junior:` handback line; `Implemented-by:` trailer |
| O6 | Cross-vendor arm table (67-71): ticket, spec, slice | yes/yes/yes | register.tsx:108-135 parses rows (`no` -> system section `ARM: off …` at 855/860 and chip); check-requirements.sh:212-223 (C6 waives Codex checks when all `no`) | builder.md:35; shaper.md:30; thomas.md:140 | `Arm: off (orchestrator)` handback line; absence of `arm(<scope>):` receipt |
| O7 | Model, Effort, Runtime column semantics (81-97) | prose | none | dispatch-ticket SKILL launcher | n/a |
| O8 | "Every Role runs on Claude Code" (99) | prose | none (junior runtime enters only via O5) | — | none |

Section 8 rows: 8.
# Section 9 — Ledger (harness/.agents/memory)

## 9.1 Files and generators (5)
| id | file | size | generated by | caller of generator (cite) | trigger | trace |
|---|---|---|---|---|---|---|
| L1 | recurring-failure-modes.md | 290k bytes, 157 entries (`^### AST-` count 157) | hand-written, append-only | Thomas at merge ("Decide the lesson", thomas.md:181) | per merge | entry `### AST-nnn`; merge commit line `Ledger: AST-nnn` or `Ledger: none` (hook-git-guard.py:750 denies a push whose merge lacks a `Ledger:` line) |
| L2 | INDEX.md | 21k | scripts/ledger-index.sh | install.sh:276 (regenerate in staging), :315 (`--check`); README.md:488,497; register.tsx:1132 names it in a message string only; selftest.sh:192-210 | staging; manual after ledger edit | stdout `ok: INDEX.md current`; `Cited by` column (80 of 157 entries empty); docs-staleness axis 5 (D5) |
| L3 | RULES.md | 53k | scripts/ledger-rules.py | install.sh:277,316; selftest.sh:235-240 | staging; manual | stdout `ok: RULES.md current (N entries)`, `STOP: RULES.md is stale/missing`; read via "you need a rule" Load row in builder.md:20, thomas.md:19, shaper.md:21, junior.md:19 |
| L4 | `grep -A40 '^### AST-0NN' recurring-failure-modes.md` | — | — | Load row "you need a rule's EVIDENCE": builder.md:21, thomas.md:20, shaper.md:22 | on demand | Bash command text |
| L5 | `Bound:` / `Wired` / `Enforced by` assertions in the ledger (161 lines match `Bound:|Wired|Enforced by`; 158 contain `Bound:`) | — | check-reachability.py check 10 (R10, :885) | install.sh:311 staging; manual | staging | `[OK] 10 … (N assertion citation(s) read)`; `(gone)` retires |

Entry statuses in INDEX.md: promoted 155, superseded 1, proposed 1. Header count of entries is auto-updated by install.sh phase I4.

## 9.2 Lines mentioning an AST id, per file (`grep -c 'AST-[0-9][0-9][0-9]'`, line count not occurrence count)
| file | lines |
|---|---|
| harness/.agents/memory/recurring-failure-modes.md | 339 |
| harness/.agents/memory/RULES.md | 158 |
| harness/.agents/memory/INDEX.md | 157 |
| harness/.agents/skills/dispatch-ticket/SKILL.md (+ identical twin under .claude/skills) | 22 |
| harness/scripts/hook-git-guard.py | 22 |
| harness/scripts/check-reachability.py | 20 |
| harness/scripts/docs-staleness-audit.sh | 16 |
| harness/scripts/selftest.sh | 15 |
| prompts/ADAPT-HARNESS.md | 15 |
| harness/scripts/check-simplify-markers.sh | 14 |
| harness/.agents/roles/thomas.md | 12 |
| harness/.agents/roles/builder-claude.md | 12 |
| harness/.agents/skills/dispatch-ticket/CLEANUP.md (+twin) | 11 |
| harness/.agents/skills/dispatch-ticket-claude/SKILL.md (+twin) | 11 |
| harness/.claude/skills/astragentic-dispatch/hooks/register.tsx | 11 |
| harness/scripts/herdr-watchdog.sh | 8 |
| harness/.agents/skills/codex-arm/SKILL.md (+twin) | 7 |
| install.sh | 7 |
| check-requirements.sh | 7 |
| harness/.agents/skills/dispatch-ticket/WATCHING.md (+twin) | 5 |
| harness/.agents/skills/dispatch-ticket/MARKERS.md (+twin) | 5 |
| harness/scripts/release-worktree-resources.sh | 5 |
| harness/scripts/herdr-watch-terminal.sh | 5 |
| harness/scripts/check-payload-drift.sh | 4 |
| harness/.agents/roles/thomas-claude.md | 3 |
| harness/.agents/roles/builder.md | 3 |
| harness/scripts/ticket-done.sh | 3 |
| harness/scripts/ledger-rules.py | 3 |
| harness/.agents/skills/dispatch-junior/SKILL.md (+twin) | 2 |
| harness/scripts/pre-push-ticket-done.sh | 2 |
| 1 line each: tracker-contract.md; skills/untangle/SKILL.md (+twin); skills/reconcile-tracker/SKILL.md (+twin); roles/shaper.md; orchestrator.md; scripts/reap-worktree-processes.sh; scripts/hook-tracker-status.py; scripts/hook-contract-reload.py; .claude/agents/{thomas,shaper,qa,builder}.md; prompts/UNINSTALL-HARNESS.md | 1 each |
| roles/qa.md, roles/junior.md, roles/junior-grok.md, all other skills, astragentic.sh, get.sh | 0 |

AST ids named in role contracts (line numbers): thomas.md 24@22, 74@52, 131@61, 96@79, 56@84, 119@128, 135@151, 133@163, 132@175, 57@179, 69@182, 124@188; builder.md 92@153, 94@162, 122@163; thomas-claude.md 89@45, 55@49, 51@51; shaper.md 55 and 112@41; builder-claude.md 12 lines (see table); qa.md none.

Section 9 rows: 9.1=5 rows, 9.2=31 rows.
# Section 10 — Project plugs and state files the harness expects

"Plugs" = `.astraler/project/` (project-owned, never written by a release). "State" = `.astraler/state/`. Counts are references found by grep over harness/, install.sh, check-requirements.sh, astragentic.sh, get.sh, prompts/ (selftest excluded).

## 10.1 .astraler/project/ (19)
| id | path | kind | reader / caller (cite) | trigger | observable trace |
|---|---|---|---|---|---|
| J01 | cleanup-worktree.sh `<worktree-path>` | exec plug | scripts/release-worktree-resources.sh:42 (called at worktree remove by settings.json H2 and register.tsx:1387) | per worktree removal | stdout of release script; absent plug prints `release-worktree-resources: NOTE — no project cleanup declared` (:106); ADAPTATION-REPORT line |
| J02 | tracker-state.sh `<ticket-id>` | exec plug | scripts/ticket-done.sh:81; register.tsx:471 (S05, 30s cache) | per ticket-done; per implement brief | prints `<state> <assignee-or-dash>` (`closed -`); `ticket-done: STOP — tracker-state.sh printed nothing for <id>` |
| J03 | ticket-done.sh `<ticket-id>` | exec plug | scripts/ticket-done.sh (project half) | per merge write-back | stamp `<git common dir>/astraler-stamps/harness-ticket-done/<ID>` |
| J04 | tracker-status.sh | exec plug | scripts/hook-tracker-status.py:63 | SessionStart | additionalContext line; log `hook-tracker-status` |
| J05 | not-a-skill.txt | list | scripts/check-reachability.py:262 | staging / manual doctor | tokens excluded from the skill-name reachability scan (empty socket if absent) |
| J06 | work-in-flight.sh | exec plug (exit 0 = busy) | scripts/herdr-watchdog.sh:548 | each watchdog poll | suppresses stall alert |
| J07 | watchdog-probe.sh | exec plug | scripts/herdr-watchdog.sh:569 | each watchdog poll | project alert lines |
| J08 | status-line.sh | exec plug | register.tsx:658 (5s timeout); dispatch-ticket-claude/SKILL.md:119 | each refreshBoard (30s) | banner extra; `status-line.sh failed` |
| J09 | setup-worktree.sh `<wt>` | exec plug | register.tsx:1452; dispatch-ticket-claude/SKILL.md:35 | after `git worktree add` | note N05 `setup-worktree.sh ran for <wt>.` |
| J10 | refused-in-dispatched-panes | regex list | register.tsx:1243 (G02) | each Bash in a dispatched pane | deny `astragentic-dispatch: this command matches "<pat>"`; log `REFUSED refused-command` |
| J11 | shared-compose-projects | list | scripts/release-worktree-resources.sh:81 | worktree removal | declared stack reported and never taken down |
| J12 | qa-report-path.sh `<key> <sha> [<mode>]` | exec plug | qa.md:184; dispatch-qa-walk/SKILL.md:94,101 | QA dispatch | one printed path |
| J13 | role-budgets.txt | list `role words reason` | scripts/docs-staleness-audit.sh:105 | doctor (axis 1) | `ok:`/`OVER:` lines |
| J14 | marker-output-check.sh `<sha> <subject> <path>` | exec plug | scripts/check-simplify-markers.sh:316,410 | Builder handback and Thomas merge | refusal `the plug .astraler/project/marker-output-check.sh is missing` |
| J15 | marker-evidence-paths.txt | glob list | scripts/check-simplify-markers.sh:311; builder.md:170; MARKERS.md:26 | marker verification | exempts matching paths from STOP |
| J16 | overlays/<role>.md (builder, shaper, qa, resident, thomas) | markdown | register.tsx:98,138,851 (system section `astragentic-dispatch:overlay`); builder.md:23 | prompt.compose | overlay text in system prompt |
| J17 | overlays/dispatch-brief.md | markdown | register.tsx:1187 | each slash-command brief from the dispatcher | text appended to the brief |
| J18 | (`.astraler/project/*` gitignore statement) | note | ADAPT-HARNESS.md:505; check-reachability.py reads it | install | receipt line |
| J19 | docs/agents/{issue-tracker,triage-labels,domain}.md (not under .astraler) | docs | check-requirements.sh C9; thomas.md:12,15 | session start | files exist |

## 10.2 .astraler/state/ and other install artifacts (9)
| id | path | writer | reader (cite) | trace |
|---|---|---|---|---|
| X1 | applied-version | ADAPT step 7 / install.sh --apply | register.tsx:537,673,774; astragentic.sh:42; check-requirements.sh C14; UNINSTALL step 1 | file contents; chip `astragentic <version>` |
| X2 | apply-incomplete | install.sh (stops part-way) | register.tsx:1089 (S01); check-requirements.sh C14 | brief refused `A harness upgrade stopped part-way` |
| X3 | dispatch-record.json | register.tsx patchRecord (keys in 4.4); dispatch-ticket/SKILL.md "10. Write" | register.tsx; hook-git-guard.py (see 3.S08) | JSON keyed by ticket id |
| X4 | ADAPTATION-REPORT.md | ADAPT step 7 | check-requirements.sh:519 (C15) | file; exceptions only |
| X5 | qa-verified-clean.md | dispatch-qa-walk/SKILL.md:139 | dispatch-qa-walk/SKILL.md:72; qa.md:191 | file headed by SHA |
| X6 | gate-history/walk-<artifact-key>-<short-sha> | dispatch-ticket/GATE.md:90 | check-reachability.py:632 (names the artifact) | files |
| X7 | .astraler/CANDIDATE | install.sh | ADAPT step 1, step 6 | file |
| X8 | .astraler/releases/<version>/ | install.sh staging | register.tsx:541; check-requirements.sh C15; UNINSTALL step 1 | directory immutable (I9) |
| X9 | .agents/payload-drift-manifest.json | ADAPT step 6 | scripts/check-payload-drift.sh | exits 0 when absent |

Section 10 rows: 10.1=19, 10.2=9.
# Section 11 — Rules in role contracts that point at nothing observable

Classification used (mine, mechanical): for each bold-led rule in the contract text, look at the rule's own words plus the mod, scripts and skills for any of: a Skill name that lands in skills_run, a script or command that appears in a Bash call, a commit subject or trailer, a brief or handback line with a fixed literal, a record field, a file path, a log or refusal string, a tracker write.
- **P** = pure prose: none of the above exists for this rule. No measurement over transcripts, git or logs can score it.
- **H** = handback or report text only: a human-readable field is demanded but with no fixed literal pattern, so scoring needs reading, not grep.
Rules counted at the grain of one bold-led sentence or one numbered item. Counts are mine; line numbers let a second reader recount.

## 11.1 Counts per contract (counts are of the rows listed in 11.2 and 11.3; "rules examined" was not tallied)
| contract | P (pure prose) | H (handback/report text only) |
|---|---|---|
| builder.md | 12 | 4 |
| builder-claude.md | 7 | 2 |
| thomas.md | 12 | 3 |
| thomas-claude.md | 2 | 1 |
| shaper.md | 8 | 3 |
| qa.md | 10 | 18 (11 checklist items + 7 other) |
| junior.md | 5 | 0 |
| junior-grok.md | 1 | 0 |
| **total** | **57** | **31** |

## 11.2 P rules by contract (quoted opening, line)
| contract | line | rule opening |
|---|---|---|
| builder.md | 6 | "You are the sole writer in your worktree" |
| builder.md | 56 | "Never edit the worktree while the junior holds it" |
| builder.md | 61 | "Stay inside your worktree" |
| builder.md | 61 | "Where the brief is ambiguous, ask Thomas" |
| builder.md | 67-70 | "A small seam is yours to make; one several modules will depend on ... report that to Thomas" |
| builder.md | 73 | "A test written from the same side as the code is green by construction" |
| builder.md | 79 | "Fix the class, not the instance" (report how many found: no fixed literal) |
| builder.md | 90 | "A finding you dispute gets one reply, in writing, to Thomas" |
| builder.md | 128 | "A fork may be a SOURCE, never a GATE" |
| builder.md | 142 | "Run every machine that can answer before you hand back" (output cited in handback, no literal) |
| builder.md | 145 | "Never infer blast radius from a diff's paths or extensions" |
| builder.md | 148 | "Declare context exhaustion at 60%, not 95%" (mod compacts at a 200k ceiling, ST04; no 60% check) |
| builder-claude.md | 55 | "Your forks must never message anyone" |
| builder-claude.md | 62 | "A marker whose parent carries implementation you did not narrate is the signal" |
| builder-claude.md | 66 | "Judge a fork by its artifact, not its activity" |
| builder-claude.md | 103 | "Run gates in the foreground" |
| builder-claude.md | 106 | "A backgrounded block's completion notice reports its LAST command" |
| builder-claude.md | 111 | "If ScheduleWakeup errors, do not park" |
| builder-claude.md | 116 | "Write a durable checkpoint before /compact; /clear belongs between tickets" |
| thomas.md | 22 | "Compaction summarises tool results away first" (rule text lives in .claude/agents/thomas.md) |
| thomas.md | 52 | "promotion is your judgement" |
| thomas.md | 104 | "A junior pane is the Builder's: never brief it" |
| thomas.md | 108 | "Reviewers advise and you classify" |
| thomas.md | 110 | "The author gets ONE written reply before you classify" |
| thomas.md | 113 | "One reply, not a round" |
| thomas.md | 125 | "Folding a finding is propagation: grep for the claim" |
| thomas.md | 127 | "A handback is a claim ... Resolve contradictions by SHA" |
| thomas.md | 158 | "Commit the merge, then gate on the committed SHA" |
| thomas.md | 173 | "Merge in the foreground, never gate through a pipe" |
| thomas.md | 191 | "Silence is not health ... count panes yourself" |
| thomas.md | 196 | "Answers carry a source ... record which" |
| thomas-claude.md | 26 | "Do not arm a Monitor, type into a Builder's pane, or write its tab and pane ids by hand" |
| thomas-claude.md | 28 | "Do not use the shared protocol's Herdr paste for Claude builders" |
| shaper.md | 6 | "without /compact and without /clear" |
| shaper.md | 38 | "If a skill invocation fails, the failure IS the finding" |
| shaper.md | 56 | "A blocking finding is repaired in the SPEC, here, before any ticket is cut" |
| shaper.md | 66 | "No /compact, no /clear while you wait" |
| shaper.md | 81 | "Every answer carries a source" (record which: no literal) |
| shaper.md | 94 | "Size each ticket to one session" |
| shaper.md | 96 | expand-contract path for wide refactors |
| shaper.md | 109 | "hand it back for wayfinder rather than compacting" |
| qa.md | 6 | "You exercise the running system; you do not read the diff" |
| qa.md | 9 | "An automated suite is not this role either" |
| qa.md | 13 | "QA is not UI-only" |
| qa.md | 43 | "You are the product's user, not its author" |
| qa.md | 49 | "This lens is fixed and is not a dispatch parameter" |
| qa.md | 63 | "Text first, pixels second" |
| qa.md | 126 | "Default flows are strictly non-mutating" (mod G02 enforces only regexes the project lists in refused-in-dispatched-panes) |
| qa.md | 133 | "The rule is about the DATA, not the environment" |
| qa.md | 138 | "Redact before the bytes are written, not after" |
| qa.md | 142 | "Ask a structural question rather than dumping the page or payload" |
| junior.md | 4 | "You never review, never simplify, never merge, never push" (git log shows pushes; no guard on Grok, see junior-grok.md:25) |
| junior.md | 32 | "Make them green with the smallest change that is not a stub" |
| junior.md | 33 | "Tests named in the brief are read-only to you" |
| junior.md | 49 | "Only the worktree you were launched in" |
| junior.md | 56 | "No new dependencies unless the brief names them" |
| junior-grok.md | 20 | "After a compaction re-read the brief and the failing tests" |

## 11.3 H rules (handback or report text only), by contract
| contract | lines |
|---|---|
| builder.md | 94-107 browser evidence (what looked at, viewport, what seen); 172-175 handback field list; 100-102 "say so" when repo cannot render; 36 skip "is named" for UX |
| builder-claude.md | 26 failed invocation reported to Thomas; 29-33 degraded reason named after ` — ` (suffix is greppable, the reason is prose) |
| thomas.md | 123 read COVERAGE GAPS; 154 NOT RUN recorded (literal exists; owner acceptance is prose); 50 write answer to board (tracker state is the trace but wording varies) |
| thomas-claude.md | 48-51 handback describing a pass that left no marker is a substitute |
| shaper.md | 103-108 two handbacks; 100 how each spec finding resolved in tickets; 84 open questions with reason |
| qa.md | 69-110 eleven checklist items (walk 3, probe 4, verify 4) live only in report body; 123 consent field (brief text; mod parses no consent literal); 146 no real customer value in report; 58 skips listed; 112-116 one-line "QA does not apply" report; 172 defect vs environment artifact; 175 COVERAGE GAPS section (heading is greppable, contents are prose); 156-168 matrix and verdict thresholds (table header greppable, thresholds are prose) |

Section 11 rows: 11.1=8 contracts, 11.2=57 P rows, 11.3=8 contract rows covering 31 H rules.
