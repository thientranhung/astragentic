# Harness usage measured from nizzy-ecom transcripts

Generated from `~/.claude/projects/*etsy-fulfillment-thanh*` (read-only), extracted into sqlite `/tmp/nizzy-audit/t.db` by `/tmp/nizzy-audit/extract.py`; analysis `/tmp/nizzy-audit/analyze.py`. Windows: 30d = events with timestamp >= 2026-09-18T00:00:00Z, 7d = >= 2026-10-11T00:00:00Z (today 2026-10-18). Transcripts span 2026-07-15 to 2026-10-18.

## 0. Coverage and how sessions were told apart

- **Top-level vs subagent**: by file path. A transcript at `<project-dir>/<session>.jsonl` is a top-level session. A transcript at `<project-dir>/<session>/subagents/agent-<id>.jsonl` is a subagent run, with `agent-<id>.meta.json` beside it giving `agentType`, `description`, `toolUseId`. No line in any file carried `isSidechain: true` that was needed; path is the discriminator. Fork subagents begin with a `fork-context-ref` line pointing at the parent session instead of copying its history.
- **Role**: the `agent-setting` line of a top-level file (`thomas`, `builder`, `shaper`, `qa`, and the older name `rin`, merged into `qa` here). Files without that line are mapped by project directory name: `...thanh` (main checkout) = `thomas(untagged)`; `deploy-agent`, `harness-partner`, `design-partner`, `observer-*` = `other`. A subagent inherits the role of its parent session.
- **Dedupe**: assistant messages by `message.id` (a streamed message appears on several lines; the line with the largest `output_tokens` is kept), tool_use by block `id`, tool_result by `tool_use_id`. Duplicates dropped across all files: {'msgs': 89, 'tus': 89} (resumed sessions re-copy few messages).
| role | top-level sessions (all) | active 30d | active 7d | subagent runs (all) | active 30d | active 7d |
|---|---|---|---|---|---|---|
| thomas | 24 | 23 | 9 | 31 | 30 | 10 |
| thomas(untagged) | 8 | 5 | 1 | 64 | 0 | 0 |
| builder | 307 | 304 | 72 | 1556 | 1548 | 716 |
| shaper | 13 | 13 | 4 | 49 | 49 | 8 |
| qa | 46 | 46 | 14 | 29 | 29 | 0 |
| other | 10 | 10 | 0 | 0 | 0 | 0 |

Source: `files` table; "active" = last timestamp in the file inside the window. Counts of events below are by event timestamp, not file activity.

## 1. Skill invocations

| skill | 30d Skill-tool calls | 30d slash-command | 30d distinct sessions | 30d distinct tickets | 7d tool calls | 7d slash | 7d sessions | 7d tickets |
|---|---|---|---|---|---|---|---|---|
| simplify | 327 | 0 | 277 | 274 | 85 | 0 | 72 | 72 |
| codex-arm | 288 | 0 | 283 | 275 | 64 | 0 | 61 | 57 |
| mattpocock-skills:implement | 2 | 276 | 278 | 275 | 0 | 72 | 72 | 72 |
| mattpocock-skills:code-review | 175 | 0 | 172 | 172 | 74 | 0 | 72 | 72 |
| omnilogin-agent-browser | 116 | 0 | 116 | 103 | 0 | 0 | 0 | 0 |
| code-review | 97 | 0 | 90 | 90 | 79 | 0 | 72 | 72 |
| mattpocock-skills:tdd | 82 | 0 | 82 | 82 | 69 | 0 | 69 | 69 |
| astraler-omnilogin-agent-browser | 47 | 0 | 47 | 41 | 47 | 0 | 47 | 41 |
| bmad-ux | 32 | 0 | 32 | 32 | 32 | 0 | 32 | 32 |
| frontend-implement | 17 | 12 | 27 | 27 | 10 | 0 | 9 | 9 |
| mattpocock-skills:to-spec | 8 | 10 | 9 | 9 | 4 | 3 | 3 | 3 |
| golang-implement | 17 | 0 | 17 | 17 | 5 | 0 | 5 | 5 |
| dispatch-ticket | 15 | 1 | 16 | 2 | 6 | 0 | 6 | 0 |
| dispatch-ticket-claude | 15 | 0 | 15 | 0 | 6 | 0 | 6 | 0 |
| mattpocock-skills:grill-with-docs | 0 | 11 | 11 | 10 | 0 | 3 | 3 | 3 |
| mattpocock-skills:to-tickets | 0 | 9 | 9 | 8 | 0 | 3 | 3 | 3 |
| test-design | 7 | 1 | 8 | 7 | 6 | 0 | 6 | 6 |
| mattpocock-skills:domain-modeling | 6 | 0 | 6 | 6 | 3 | 0 | 3 | 3 |
| mattpocock-skills:grilling | 6 | 0 | 6 | 6 | 3 | 0 | 3 | 3 |
| review-with-rin | 6 | 0 | 6 | 1 | 0 | 0 | 0 | 0 |
| dispatch-qa-walk | 5 | 0 | 5 | 0 | 3 | 0 | 3 | 0 |
| agent-browser | 4 | 0 | 4 | 4 | 0 | 0 | 0 | 0 |
| deploy-stage | 3 | 1 | 4 | 0 | 0 | 0 | 0 | 0 |
| herdr | 4 | 0 | 4 | 0 | 1 | 0 | 1 | 0 |
| defuddle | 2 | 0 | 2 | 1 | 1 | 0 | 1 | 1 |
| astraler-jev-design | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| claude-api | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 |
| mattpocock-skills:wizard | 1 | 0 | 1 | 1 | 1 | 0 | 1 | 1 |
| reconcile-tracker | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |

Sources: Skill tool_use `input.skill` (tool); user turn containing `<command-name>/skill</command-name>` (slash, includes the brief `/mattpocock-skills:implement TRA-N` that the mod/Thomas sends a Builder); sessions = distinct top-level session ids (subagent counted under its parent); tickets = ticket in the worktree directory name (Builder) or first `TRA-n` in the args/command-args (other roles). Skill-tool calls made inside subagent runs are included.

### 1b. Skill x role (30d, tool + slash counts, with 7d in brackets)

| skill | thomas | thomas(untagged) | builder | shaper | qa | other |
|---|---|---|---|---|---|---|
| agent-browser | . | . | 4 [0] | . | . | . |
| anthropic-skills:herdr | . | . | . | . | . | . |
| astraler-jev-design | 1 [0] | . | . | . | . | . |
| astraler-omnilogin-agent-browser | . | . | 41 [41] | . | 6 [6] | . |
| bmad-ux | . | . | 32 [32] | . | . | . |
| browser-test | . | . | . | . | . | . |
| claude-api | 1 [1] | . | . | . | . | . |
| code-review | . | . | 97 [79] | . | . | . |
| codex-arm | 11 [4] | . | 275 [58] | 2 [2] | . | . |
| codex-gate | . | . | . | . | . | . |
| defuddle | 1 [0] | . | 1 [1] | . | . | . |
| deploy-prod | . | . | . | . | . | . |
| deploy-stage | 1 [0] | . | . | . | . | 3 [0] |
| dispatch-dan | . | . | . | . | . | . |
| dispatch-qa-walk | 5 [3] | . | . | . | . | . |
| dispatch-ticket | 15 [6] | . | . | . | . | 1 [0] |
| dispatch-ticket-claude | 15 [6] | . | . | . | . | . |
| frontend-implement | . | . | 29 [10] | . | . | . |
| golang-implement | . | . | 17 [5] | . | . | . |
| herdr | 2 [1] | 2 [0] | . | . | . | . |
| mattpocock-skills:code-review | . | . | 175 [74] | . | . | . |
| mattpocock-skills:domain-modeling | . | . | . | 6 [3] | . | . |
| mattpocock-skills:grill-with-docs | . | . | . | 11 [3] | . | . |
| mattpocock-skills:grilling | . | . | . | 6 [3] | . | . |
| mattpocock-skills:implement | . | . | 278 [72] | . | . | . |
| mattpocock-skills:tdd | . | . | 82 [69] | . | . | . |
| mattpocock-skills:to-spec | . | . | . | 18 [7] | . | . |
| mattpocock-skills:to-tickets | . | . | . | 9 [3] | . | . |
| mattpocock-skills:wizard | . | . | . | 1 [1] | . | . |
| omnilogin-agent-browser | 3 [0] | . | 101 [0] | 1 [0] | 11 [0] | . |
| reconcile-tracker | 1 [0] | . | . | . | . | . |
| review-with-rin | 6 [0] | . | . | . | . | . |
| run-local-dev | . | . | . | . | . | . |
| simplify | . | . | 326 [85] | . | . | 1 [0] |
| test-design | 4 [3] | . | . | 4 [3] | . | . |

### 1c. Builtin slash commands seen (30d) with role

| command | role | 30d count |
|---|---|---|
| /advisor | thomas | 1 |
| /clear | other | 2 |
| /clear | thomas(untagged) | 1 |
| /compact | builder | 1 |
| /compact | thomas | 3 |
| /compact | thomas(untagged) | 1 |
| /feedback | thomas | 1 |
| /login | thomas | 3 |
| /loop | thomas | 3 |
| /model | thomas | 2 |
| /reload-skills | other | 1 |
| /reload-skills | thomas | 1 |

### 1d. Skill bodies injected into context (user turn `Base directory for this skill: <dir>/<name>`), 30d

| skill dir name | role | injections 30d | distinct sessions |
|---|---|---|---|
| implement | builder | 278 | 278 |
| codex-arm | builder | 272 | 270 |
| code-review | builder | 175 | 172 |
| omnilogin-agent-browser | builder | 101 | 101 |
| tdd | builder | 82 | 82 |
| astraler-omnilogin-agent-browser | builder | 41 | 41 |
| bmad-ux | builder | 32 | 32 |
| frontend-implement | builder | 29 | 27 |
| golang-implement | builder | 17 | 17 |
| dispatch-ticket | thomas | 15 | 15 |
| dispatch-ticket-claude | thomas | 15 | 15 |
| codex-arm | thomas | 11 | 11 |
| grill-with-docs | shaper | 11 | 11 |
| omnilogin-agent-browser | qa | 11 | 11 |
| to-spec | shaper | 10 | 9 |
| to-tickets | shaper | 9 | 9 |
| review-with-rin | thomas | 6 | 6 |
| grilling | shaper | 6 | 6 |
| domain-modeling | shaper | 6 | 6 |
| astraler-omnilogin-agent-browser | qa | 6 | 6 |
| dispatch-qa-walk | thomas | 5 | 5 |
| agent-browser | builder | 4 | 4 |
| test-design | shaper | 4 | 4 |
| test-design | thomas | 4 | 4 |
| omnilogin-agent-browser | thomas | 3 | 3 |
| deploy-stage | other | 3 | 3 |
| herdr | thomas(untagged) | 2 | 2 |
| herdr | thomas | 2 | 2 |
| codex-arm | shaper | 2 | 2 |
| omnilogin-agent-browser | shaper | 1 | 1 |
| dispatch-ticket | other | 1 | 1 |
| defuddle | thomas | 1 | 1 |
| deploy-stage | thomas | 1 | 1 |
| astraler-jev-design | thomas | 1 | 1 |
| reconcile-tracker | thomas | 1 | 1 |
| wizard | shaper | 1 | 1 |
| defuddle | builder | 1 | 1 |
| claude-api | thomas | 1 | 1 |

Source: first line of the expanded skill text. This also catches skills loaded through a slash command or the brief, not just the Skill tool. The directory name is the last path segment, so `implement` is `mattpocock-skills:implement`.

### 1e. Share of Builder tickets that used each phase skill (30d)

| skill | 30d Builder tickets using it (of 299) | share | calls per using ticket | 7d tickets (of 72) | 7d share |
|---|---|---|---|---|---|
| mattpocock-skills:implement | 275 | 91% | 1.0 | 72 | 100% |
| mattpocock-skills:tdd | 82 | 27% | 1.0 | 69 | 95% |
| code-review | 90 | 30% | 1.1 | 72 | 100% |
| mattpocock-skills:code-review | 172 | 57% | 1.0 | 72 | 100% |
| simplify | 273 | 91% | 1.2 | 72 | 100% |
| codex-arm | 269 | 89% | 1.0 | 55 | 76% |
| bmad-ux | 32 | 10% | 1.0 | 32 | 44% |
| frontend-implement | 27 | 9% | 1.1 | 9 | 12% |
| golang-implement | 17 | 5% | 1.0 | 5 | 6% |
| omnilogin-agent-browser | 101 | 33% | 1.0 | 0 | 0% |
| astraler-omnilogin-agent-browser | 41 | 13% | 1.0 | 41 | 56% |
| atdd | 0 | 0% | 0.0 | 0 | 0% |

Source: Builder top-level sessions started in the window (one worktree dir = one ticket id); skill events attributed to the ticket in the worktree directory name. A ticket can have several Builder sessions (restarts); each counts once.

## 2. Harness scripts run through Bash

### 2a. Harness payload scripts (`scripts/<name>` or `harness/scripts/<name>`)

| script | 30d Bash calls naming it | 30d run (first token) | 30d non-zero exit / is_error | 30d output has STOP/MISS/FAIL | 30d runs by role | 7d naming | 7d run | 7d non-zero | 7d STOP/MISS/FAIL |
|---|---|---|---|---|---|---|---|---|---|
| check-payload-drift.sh | 2 | 1 | 0 | 0 | thomas(untagged):1 | 0 | 0 | 0 | 0 |
| check-reachability.py | 83 | 66 | 5 | 16 | thomas:22, thomas(untagged):6, builder:35, shaper:3 | 70 | 54 | 3 | 13 |
| check-simplify-markers.sh | 2302 | 1911 | 116 | 304 | thomas:507, thomas(untagged):19, builder:1356, shaper:2, qa:19, other:8 | 574 | 469 | 29 | 38 |
| docs-staleness-audit.sh | 64 | 47 | 0 | 10 | thomas:9, thomas(untagged):38 | 0 | 0 | 0 | 0 |
| herdr-watch-terminal.sh | 22 | 9 | 0 | 1 | thomas:4, thomas(untagged):2, builder:3 | 4 | 3 | 0 | 0 |
| herdr-watchdog.sh | 96 | 26 | 1 | 1 | thomas:19, thomas(untagged):6, other:1 | 10 | 2 | 0 | 0 |
| hook-contract-reload.py | 1 | 0 | 0 | 0 | . | 1 | 0 | 0 | 0 |
| hook-git-guard.py | 69 | 10 | 0 | 1 | thomas:3, thomas(untagged):1, other:6 | 8 | 0 | 0 | 0 |
| hook-tracker-status.py | 3 | 0 | 0 | 0 | . | 1 | 0 | 0 | 0 |
| ledger-index.sh | 24 | 19 | 1 | 8 | thomas:13, thomas(untagged):4, other:2 | 4 | 3 | 0 | 0 |
| ledger-rules.py | 3 | 2 | 0 | 1 | thomas:2 | 0 | 0 | 0 | 0 |
| pre-push-ticket-done.sh | 8 | 2 | 0 | 0 | other:2 | 2 | 0 | 0 | 0 |
| reap-worktree-processes.sh | 6 | 2 | 0 | 0 | thomas:2 | 0 | 0 | 0 | 0 |
| release-worktree-resources.sh | 410 | 384 | 25 | 3 | thomas:362, thomas(untagged):3, builder:5, shaper:10, qa:1, other:3 | 50 | 44 | 11 | 1 |
| selftest.sh | 33 | 19 | 0 | 8 | thomas:9, thomas(untagged):2, other:8 | 12 | 4 | 0 | 0 |
| ticket-done.sh | 365 | 351 | 20 | 12 | thomas:348, thomas(untagged):1, other:2 | 90 | 88 | 13 | 1 |
| ticket-git-facts.sh | 6 | 5 | 0 | 0 | thomas:3, builder:2 | 1 | 1 | 0 | 0 |
| lib/marker_field_parser.py | 2 | 0 | 0 | 0 | . | 0 | 0 | 0 | 0 |
| check-requirements.sh | 166 | 129 | 4 | 65 | thomas:75, thomas(untagged):45, other:9 | 17 | 16 | 1 | 7 |

### 2b. Scripts in nizzy `scripts/` that are NOT in the harness payload (context only)

| script | 30d Bash calls naming it | 30d run (first token) | 30d non-zero exit / is_error | 30d output has STOP/MISS/FAIL | 30d runs by role | 7d naming | 7d run | 7d non-zero | 7d STOP/MISS/FAIL |
|---|---|---|---|---|---|---|---|---|---|
| gate-token.sh | 844 | 651 | 95 | 23 | thomas:263, thomas(untagged):7, builder:373, qa:4, other:4 | 205 | 178 | 22 | 4 |
| herdr-prompt.sh | 16 | 9 | 0 | 1 | thomas:2, thomas(untagged):7 | 0 | 0 | 0 | 0 |
| check-server-bans.sh | 63 | 8 | 0 | 1 | thomas:3, builder:2, shaper:2, qa:1 | 52 | 5 | 0 | 0 |
| check-no-hardcoded-pg-port.sh | 23 | 5 | 0 | 1 | thomas:3, builder:2 | 18 | 3 | 0 | 0 |

### 2c. Project plugs (`.astraler/project/<name>`)

| script | 30d Bash calls naming it | 30d run (first token) | 30d non-zero exit / is_error | 30d output has STOP/MISS/FAIL | 30d runs by role | 7d naming | 7d run | 7d non-zero | 7d STOP/MISS/FAIL |
|---|---|---|---|---|---|---|---|---|---|
| cleanup-worktree.sh | 35 | 4 | 0 | 0 | thomas:1, thomas(untagged):3 | 4 | 0 | 0 | 0 |
| marker-output-check.sh | 21 | 4 | 0 | 0 | builder:4 | 16 | 3 | 0 | 0 |
| setup-worktree.sh | 41 | 21 | 1 | 0 | thomas:9, builder:7, shaper:5 | 0 | 0 | 0 | 0 |
| status-line.sh | 1 | 1 | 0 | 0 | thomas:1 | 0 | 0 | 0 | 0 |
| ticket-done.sh | 31 | 1 | 0 | 0 | thomas:1 | 1 | 1 | 0 | 0 |
| tracker-state.sh | 161 | 152 | 11 | 3 | thomas:150, other:2 | 79 | 76 | 6 | 1 |
| tracker-status.sh | 15 | 9 | 0 | 0 | thomas(untagged):9 | 0 | 0 | 0 | 0 |
| watchdog-probe.sh | 0 | 0 | 0 | 0 | . | 0 | 0 | 0 | 0 |
| work-in-flight.sh | 3 | 1 | 0 | 0 | other:1 | 0 | 0 | 0 | 0 |
| refused-in-dispatched-panes | 0 | 0 | 0 | 0 | . | 0 | 0 | 0 | 0 |
| qa-report-path.sh | 1 | 0 | 0 | 0 | . | 1 | 0 | 0 | 0 |

### 2d. `.astraler/astragentic.sh`

| script | 30d Bash calls naming it | 30d run (first token) | 30d non-zero exit / is_error | 30d output has STOP/MISS/FAIL | 30d runs by role | 7d naming | 7d run | 7d non-zero | 7d STOP/MISS/FAIL |
|---|---|---|---|---|---|---|---|---|---|
| astragentic.sh | 16 | 10 | 0 | 3 | thomas:6, thomas(untagged):4 | 16 | 10 | 0 | 3 |

Definitions: "naming it" = the Bash `input.command` contains the path (includes `cat`, `grep`, `git diff` of the file, heredocs that quote it). "run" = a command segment (split on `&&`, `||`, `;`, `|`, newline, `$(`) whose first token, after env assignments and an interpreter, ends with the path. "non-zero" = tool_result text starts with `Exit code N` (N != 0) or `is_error` true. "STOP/MISS/FAIL" = regex `\b(STOP|MISS|FAIL|FAILED|FAILURE)\b` anywhere in that tool_result text (a loose signal: selftest output prints the words in test names). Commands are truncated to 8000 chars in the extract, so a script named only past that point in a long heredoc is not seen.

### 2e. Script hooks seen as attachments (hooks that produced output or a recorded success)

| hook script | 30d attachments | 30d exit!=0 | 30d sessions | 7d attachments | 7d exit!=0 | 7d sessions |
|---|---|---|---|---|---|---|
| hook-git-guard.py | 1 | 0 | 1 | 0 | 0 | 0 |
| hook-contract-reload.py | 27 | 0 | 22 | 13 | 0 | 11 |
| hook-tracker-status.py | 407 | 0 | 401 | 99 | 0 | 99 |
| release-worktree-resources.sh | 0 | 0 | 0 | 0 | 0 | 0 |

Source: `attachment` lines of type `hook_*` whose `command` contains the script name. Claude Code records an attachment only when a hook produced output or was blocking; a silent allow from hook-git-guard.py leaves no line, so this undercounts guard invocations. Denials are counted in section 3.

## 3. Mod and hook outputs (gates, refusals)

| gate / refusal (by message text) | 30d total | 30d by role | 7d total | 7d by role |
|---|---|---|---|---|
| downstream hook-agent-isolation-guard (nizzy tools/, not payload) | 475 | thomas:21, builder:429, shaper:5, qa:20 | 258 | builder:255, shaper:1, qa:2 |
| guard: git add -A / . refused | 167 | thomas:2, thomas(untagged):1, builder:161, shaper:2, qa:1 | 44 | builder:43, shaper:1 |
| mod: tdd-gate | 39 | builder:39 | 37 | builder:37 |
| guard: push main without ticket-done stamp | 27 | thomas:27 | 17 | thomas:17 |
| guard: worktree remove without release stamp | 22 | thomas:18, builder:4 | 10 | thomas:7, builder:3 |
| mod: worktree-remove refusal | 16 | thomas:16 | 7 | thomas:7 |
| guard: worktree remove with live processes | 7 | thomas:7 | 0 | . |
| mod: no-human-picker | 7 | builder:6, shaper:1 | 4 | builder:3, shaper:1 |
| guard: hook-git-guard (hook script failed or not found) | 6 | thomas:4, builder:2 | 0 | . |
| mod: wait-gate | 5 | builder:5 | 5 | builder:5 |
| guard: push main with merge lacking Ledger: line | 4 | thomas:3, thomas(untagged):1 | 2 | thomas:2 |
| guard: rm -rf worktree | 4 | builder:4 | 1 | builder:1 |
| guard: git worktree add relative path | 3 | thomas:2, thomas(untagged):1 | 0 | . |
| guard: worktree remove with uncommitted changes | 3 | thomas:3 | 0 | . |
| mod: arm-gate | 3 | builder:3 | 3 | builder:3 |
| mod: brief refused (payload edited/untracked) | 2 | thomas:2 | 0 | . |
| mod: brief refused (base ticket with no ticket-done) | 1 | thomas:1 | 1 | thomas:1 |
| mod: brief refused (ticket not claimed) | 1 | thomas:1 | 0 | . |

Source: tool_result text anchored at the start of the result: `<tool_use_error>astragentic-dispatch: ...` (mod deny on Bash/Skill/etc.), `PreToolUse:<Tool> hook error: ...` (a settings.json PreToolUse hook; hook-git-guard.py reason text), and SendMessage results `Not sent: a plugin hook refused it ([astragentic-dispatch] not sent. ...)` (brief refusals). Results that merely quote these strings (cat/grep of register.tsx, pane screen captures, `box-pressure-check: REFUSING`) are excluded by the anchoring. The `permissionDecision` string appears in tool_results only inside file contents or docs (10 results, all quoted source), never as a live deny, because Claude Code turns a hook deny into the `hook error:` text above.

### 3b. What the agent did after a refusal (next 3 tool calls in the same transcript, 30d refusals)

| refusal | 30d count | changed course | retried identical command as the very next call | did something else, then repeated it within 3 calls | no further call | did it do the prescribed fix |
|---|---|---|---|---|---|---|
| downstream hook-agent-isolation-guard (nizzy tools/, not payload) | 475 | 443 | 25 | 7 | 0 | . |
| guard: git add -A / . refused | 167 | 93 | 71 | 3 | 0 | . |
| mod: tdd-gate | 39 | 12 | 0 | 27 | 0 | called Skill mattpocock-skills:tdd within next 3: 39 |
| guard: push main without ticket-done stamp | 27 | 15 | 11 | 1 | 0 | . |
| guard: worktree remove without release stamp | 22 | 11 | 8 | 3 | 0 | . |
| mod: worktree-remove refusal | 16 | 12 | 3 | 1 | 0 | . |
| guard: worktree remove with live processes | 7 | 4 | 0 | 3 | 0 | . |
| mod: no-human-picker | 7 | 7 | 0 | 0 | 0 | . |
| guard: hook-git-guard (hook script failed or not found) | 6 | 6 | 0 | 0 | 0 | . |
| mod: wait-gate | 5 | 5 | 0 | 0 | 0 | . |
| guard: push main with merge lacking Ledger: line | 4 | 4 | 0 | 0 | 0 | . |
| guard: rm -rf worktree | 4 | 4 | 0 | 0 | 0 | . |
| guard: git worktree add relative path | 3 | 3 | 0 | 0 | 0 | . |
| guard: worktree remove with uncommitted changes | 3 | 2 | 1 | 0 | 0 | . |
| mod: arm-gate | 3 | 3 | 0 | 0 | 0 | called Skill code-review within next 3: 3 |
| mod: brief refused (payload edited/untracked) | 2 | 0 | 2 | 0 | 0 | . |
| mod: brief refused (base ticket with no ticket-done) | 1 | 0 | 0 | 1 | 0 | . |
| mod: brief refused (ticket not claimed) | 1 | 0 | 1 | 0 | 0 | . |

Source: tool_use calls with a higher line index in the same file than the refused call. "Changed course" means none of the next three calls repeats the refused call; it does not prove the new call obeyed the refusal. Window: refusals in 30d.

### 3c. First next call after each mod refusal class (most common, 30d)

| refusal | top first next calls |
|---|---|
| mod: tdd-gate | Skill:mattpocock-skills:tdd x39 |
| mod: arm-gate | Skill:code-review x3 |
| mod: wait-gate | Bash:bash tools/gate-plan-selftest.sh > x2; Bash:wc -l /tmp/gp_selftest_out.txt; x1; Bash:pid=79030; while kill x1; ScheduleWakeup x1 |
| mod: no-human-picker | ScheduleWakeup x2; Write x1; Read x1; Bash:sleep 60; echo x1 |
| mod: refused-command | . |
| mod: worktree-remove refusal | Bash:scripts/release-worktree-resources.sh /U x4; Write x1; Bash:git -C /Users/tranthien/Documents/2.DEV/ x1; Bash:cat /private/tmp/claude-501/-Users-trant x1 |
| mod: close-refusal | . |
| mod: merge-gate | . |
| guard: git add -A / . refused | Bash:cd /Users/tranthien/Documents/2.DEV/2.PR x72; Bash:git add \ x41; Bash:git status --short x20; Bash:git branch --show-current x4 |
| guard: push main without ticket-done stamp | Bash:gh issue close x8; Bash:git reset -q x3; Bash:git worktree remove x3; Bash:gh issue edit x2 |
| guard: worktree remove without release stamp | Bash:cd /Users/tranthien/Documents/2.DEV/2.PR x5; Bash:scripts/release-worktree-resources.sh /U x5; Bash:scripts/release-worktree-resources.sh /t x4; Bash:./scripts/release-worktree-resources.sh  x2 |

### 3d. Mod bells and notices that reach the model as user turns

| bell | 30d total | 30d received by role (the session that read it) | 7d total | 7d by role |
|---|---|---|---|---|
| TURN-END bell (aborted) | 2 | thomas:2 | 0 | . |
| TURN-END bell (answer) | 792 | thomas:792 | 436 | thomas:436 |
| TURN-END bell (error) | 17 | thomas:17 | 12 | thomas:12 |
| held bell (turn end held, builder still had agents) | 7 | thomas:7 | 7 | thomas:7 |

Source: `user` lines with `origin.kind == "plugin"` and text `The astragentic-dispatch plugin sent a message: [astragentic-dispatch] <role> <key> ended its turn (answer|error|aborted)`. These are the TURN-END bells; they land in the dispatcher (Thomas) transcript. RECEIVED acks, the status-line toasts (`recorded tab..`, `confirmed receipt`, `TURN-END held`, `readdressed`, `compaction skipped`, `context compacted at the Nk ceiling`) go to `$.ui.status`/`toast` and the mod `consumed` path; they are not written to the transcript, so their count here is 0 by construction (see limits). A `No RECEIVED came back for:` note was seen 1 times as a live note.

## 4. SendMessage / cross-session traffic per day (last 30 days)

| day (UTC) | SendMessage calls | briefs (first line starts with /) | prose briefs from Thomas (first line has the word brief, heuristic) | TURN-END bells | held bells | batched bells | peer messages received | readdressed notices | agent-written TURN-END/RECEIVED text |
|---|---|---|---|---|---|---|---|---|---|
| 2026-09-18 | . | . | . | . | . | . | . | . | . |
| 2026-09-19 | . | . | . | . | . | . | . | . | . |
| 2026-09-20 | 111 | . | 13 | . | . | . | 59 | . | . |
| 2026-09-21 | 57 | . | 5 | . | . | . | 39 | . | . |
| 2026-09-22 | 168 | . | 18 | . | . | . | 75 | . | . |
| 2026-09-23 | 80 | . | 14 | . | . | . | 33 | . | . |
| 2026-09-24 | 33 | . | 7 | . | . | . | 18 | . | . |
| 2026-09-25 | 44 | . | 12 | . | . | . | 25 | . | . |
| 2026-09-26 | 47 | . | 8 | . | . | . | 27 | . | . |
| 2026-09-27 | 64 | . | 13 | . | . | . | 31 | . | . |
| 2026-09-28 | 154 | . | 32 | . | . | . | 100 | . | . |
| 2026-09-29 | 141 | . | 17 | . | . | . | 72 | . | . |
| 2026-09-30 | 85 | . | 9 | . | . | . | 33 | . | . |
| 2026-10-01 | 88 | . | 12 | . | . | . | 47 | . | . |
| 2026-10-02 | 24 | . | 4 | . | . | . | 17 | . | . |
| 2026-10-03 | 24 | . | . | . | . | . | 20 | . | . |
| 2026-10-04 | 10 | . | . | . | . | . | 7 | . | . |
| 2026-10-05 | 82 | 10 | . | 46 | . | . | 52 | . | . |
| 2026-10-06 | 72 | 12 | 1 | 81 | . | . | 16 | . | . |
| 2026-10-07 | 50 | 16 | . | 58 | . | . | 4 | . | . |
| 2026-10-08 | 50 | 10 | 1 | 38 | . | . | 15 | . | . |
| 2026-10-09 | 39 | 9 | . | 62 | . | . | 24 | . | . |
| 2026-10-10 | 26 | 8 | . | 78 | . | . | 8 | . | . |
| 2026-10-11 | 48 | 18 | . | 139 | . | . | 3 | . | . |
| 2026-10-12 | 54 | 15 | . | 91 | . | . | 7 | . | . |
| 2026-10-13 | 32 | 8 | . | 82 | . | . | 2 | . | . |
| 2026-10-14 | 53 | 10 | 1 | 26 | 5 | . | 9 | . | . |
| 2026-10-15 | 25 | 7 | 2 | 34 | 1 | . | 4 | . | 1 |
| 2026-10-16 | 34 | 10 | . | 24 | . | . | 4 | . | . |
| 2026-10-17 | 155 | 12 | 2 | 41 | 1 | . | 35 | . | . |
| 2026-10-18 | 14 | 3 | . | 11 | . | . | 1 | . | . |
| **total** | 1864 | 148 | 171 | 811 | 7 | 0 | 787 | 0 | 1 |

Sources: SendMessage tool_use `input.message` (briefs = first non-blank character is `/`); user turns with `origin.kind == "plugin"` (mod bells), `origin.kind == "peer"` (cross-session message from another Claude session). "readdressed notices" is the mod string `a reply to "<x>" readdressed to the dispatcher`; it is a UI status, so a non-zero here would only be a quoted mention.

Briefs by role of sender, 30d / 7d: thomas: 148 / 83, thomas(untagged): 0 / 0, builder: 0 / 0, shaper: 0 / 0, qa: 0 / 0, other: 0 / 0

## 5. Subagent spawns (Agent tool)

| spawning role | subagent_type (Agent input) | 30d spawns | 30d median chars returned | 7d spawns | 7d median chars |
|---|---|---|---|---|---|
| builder | general-purpose | 768 | 1133 | 309 | 609 |
| builder | Explore | 742 | 1133 | 398 | 1133 |
| builder | fork | 268 | 598 | 64 | 598 |
| builder | (default general-purpose) | 101 | 594 | 72 | 594 |
| shaper | Explore | 37 | 1129 | 7 | 1132 |
| builder | astragentic-dispatch:bmad-sally | 35 | 6040 | 35 | 6040 |
| builder | Plan | 20 | 1341 | 20 | 1341 |
| qa | general-purpose | 18 | 609 | 0 | . |
| qa | Plan | 17 | 275 | 0 | . |
| shaper | general-purpose | 15 | 1129 | 0 | . |
| thomas | general-purpose | 14 | 619 | 2 | 7199 |
| qa | Explore | 12 | 278 | 0 | . |
| thomas | Explore | 10 | 7523 | 2 | 6269 |
| builder | feature-dev:code-reviewer | 9 | 2134 | 6 | 2471 |
| thomas | astragentic-dispatch:bmad-reviewer | 9 | 8280 | 7 | 8280 |
| thomas | Plan | 4 | 1098 | 0 | . |
| qa | fork | 3 | 598 | 1 | 598 |
| builder | builder | 2 | 873 | 0 | . |
| builder | claude | 2 | 600 | 0 | . |
| builder | code-reviewer | 2 | 522 | 0 | . |
| shaper | astragentic-dispatch:bmad-murat | 2 | 8985 | 2 | 8985 |
| builder | SendMessage | 1 | 605 | 0 | . |
| builder | select:SendMessage | 1 | 257 | 0 | . |
| qa | qa | 1 | 596 | 1 | 596 |

Source: Agent tool_use `input.subagent_type` (empty means the default general-purpose type); role = role of the spawning session; chars returned = length of the `<result>` body in the later `task-notification` user turn for background spawns (joined by `tool-use-id`), else the length of the Agent tool_result. A subagent that is spawned from inside a subagent is attributed to the top-level role.

### 5b. Skill phase active at spawn (last Skill call before the Agent call in the same transcript), 30d

| role | last Skill called before spawn | 30d spawns |
|---|---|---|
| builder | simplify | 970 |
| builder | mattpocock-skills:code-review | 438 |
| builder | None | 436 |
| builder | codex-arm | 58 |
| qa | None | 51 |
| shaper | None | 34 |
| builder | bmad-ux | 27 |
| thomas | codex-arm | 23 |
| shaper | mattpocock-skills:grilling | 9 |
| builder | code-review | 8 |
| shaper | mattpocock-skills:domain-modeling | 6 |
| builder | frontend-implement | 5 |
| thomas | omnilogin-agent-browser | 5 |
| shaper | mattpocock-skills:to-spec | 3 |
| builder | golang-implement | 3 |
| thomas | dispatch-qa-walk | 3 |
| builder | astraler-omnilogin-agent-browser | 3 |
| thomas | None | 2 |
| builder | omnilogin-agent-browser | 2 |
| shaper | test-design | 2 |
| thomas | test-design | 2 |
| thomas | herdr | 1 |
| thomas | dispatch-ticket-claude | 1 |
| builder | mattpocock-skills:tdd | 1 |

"None" = no Skill call earlier in that transcript (spawn from the Builder transcript after its brief loaded the skill by slash command counts as None, because the slash command is a user turn, not a Skill call).

### 5c. Subagent runs on disk by `agentType` from meta.json (all files, 30d by first timestamp)

| parent role | agentType | runs started 30d |
|---|---|---|
| builder | general-purpose | 655 |
| builder | Explore | 470 |
| builder | named/ad-hoc | 165 |
| builder | fork | 89 |
| builder | astragentic-dispatch:bmad-sally | 33 |
| builder | simplify-reuse | 27 |
| builder | simplify-simplification | 27 |
| builder | simplify-efficiency | 27 |
| builder | simplify-altitude | 27 |
| shaper | Explore | 24 |
| qa | named/ad-hoc | 24 |
| builder | Plan | 20 |
| shaper | named/ad-hoc | 13 |
| shaper | general-purpose | 11 |
| thomas | Explore | 9 |
| builder | feature-dev:code-reviewer | 8 |
| thomas | astragentic-dispatch:bmad-reviewer | 7 |
| thomas | general-purpose | 6 |
| thomas | named/ad-hoc | 4 |
| thomas | Plan | 4 |
| qa | Plan | 3 |
| qa | Explore | 2 |
| shaper | astragentic-dispatch:bmad-murat | 1 |

## 6. Cost per role

### 6.a 30d

| role | own vs subagent | assistant calls (deduped by message.id) | input_tokens | cache_read | cache_creation | sum input+cache | output_tokens | est. @Sonnet 5 ($2/$10, read $0.20, write $4) | est. @Opus 5.5 ($4/$20, read $0.20, write $8*) | est. as-run (model per call) |
|---|---|---|---|---|---|---|---|---|---|---|
| thomas | own | 14921 | 41,504 | 6,462,735,603 | 54,162,564 | 6,516,939,671 | 7,997,790 | $1,589 | $1,886 | $1,886 |
| thomas | subagent | 1158 | 2,336 | 133,700,169 | 4,563,726 | 138,266,231 | 565,279 | $51 | $75 | $70 |
| thomas(untagged) | own | 1076 | 2,194 | 420,667,744 | 5,592,390 | 426,262,328 | 811,819 | $115 | $145 | $145 |
| builder | own | 93483 | 187,704 | 33,031,285,564 | 187,483,995 | 33,218,957,263 | 43,619,498 | $7,793 | $8,979 | $7,793 |
| builder | subagent | 17974 | 36,949 | 1,758,141,948 | 125,156,446 | 1,883,335,343 | 8,366,442 | $936 | $1,520 | $939 |
| shaper | own | 1556 | 3,186 | 363,769,624 | 6,605,053 | 370,377,863 | 1,867,289 | $118 | $163 | $163 |
| shaper | subagent | 1835 | 3,686 | 210,763,991 | 7,460,516 | 218,228,193 | 1,396,835 | $86 | $130 | $125 |
| qa | own | 3883 | 7,788 | 590,794,221 | 10,204,774 | 601,006,783 | 1,723,326 | $176 | $234 | $196 |
| qa | subagent | 1235 | 2,470 | 167,740,428 | 6,396,968 | 174,139,866 | 300,964 | $62 | $91 | $91 |
| other | own | 1479 | 3,000 | 495,941,908 | 23,023,465 | 518,968,373 | 1,232,564 | $204 | $308 | $304 |
| **total** |  | 138600 | 290,817 | 43,635,541,200 | 430,649,897 | 44,066,481,914 | 67,881,806 | $11,129 | $13,531 | $11,711 |

### 6.b 7d

| role | own vs subagent | assistant calls (deduped by message.id) | input_tokens | cache_read | cache_creation | sum input+cache | output_tokens | est. @Sonnet 5 ($2/$10, read $0.20, write $4) | est. @Opus 5.5 ($4/$20, read $0.20, write $8*) | est. as-run (model per call) |
|---|---|---|---|---|---|---|---|---|---|---|
| thomas | own | 3177 | 7,316 | 893,108,170 | 12,358,345 | 905,473,831 | 1,458,829 | $243 | $307 | $307 |
| thomas | subagent | 484 | 984 | 64,860,696 | 1,891,654 | 66,753,334 | 237,822 | $23 | $33 | $33 |
| thomas(untagged) | own | 64 | 134 | 8,050,668 | 329,622 | 8,380,424 | 35,612 | $3 | $5 | $5 |
| builder | own | 27174 | 54,526 | 10,248,537,188 | 56,773,561 | 10,305,365,275 | 12,704,582 | $2,404 | $2,758 | $2,404 |
| builder | subagent | 9847 | 20,538 | 908,659,247 | 63,964,949 | 972,644,734 | 4,624,289 | $484 | $786 | $487 |
| shaper | own | 501 | 1,034 | 126,918,526 | 1,731,016 | 128,650,576 | 625,397 | $39 | $52 | $52 |
| shaper | subagent | 257 | 530 | 22,859,633 | 994,752 | 23,854,915 | 187,728 | $10 | $16 | $16 |
| qa | own | 1350 | 2,706 | 200,634,824 | 3,439,102 | 204,076,632 | 441,790 | $58 | $76 | $58 |
| **total** |  | 42854 | 87,768 | 12,473,628,952 | 141,483,001 | 12,615,199,721 | 20,316,049 | $3,264 | $4,033 | $3,362 |

Source: `message.usage` of each deduped assistant message. *Opus cache-write price was not given; assumed 2x input ($8/M) to match the Sonnet 2x ratio. "As-run" prices each call by `message.model` family: opus-* and fable-* at the Opus rates, sonnet-* and haiku-* at the Sonnet rates (the haiku and fable rates were not supplied, so those ~700 calls are approximate). Thinking tokens are inside `output_tokens`. 1h-cache write premiums are not modelled.

### 6c. Model used (assistant calls by `message.model`, 30d) per role

| role | calls by model |
|---|---|
| thomas | claude-opus-5-5: 11412; claude-opus-5: 4180; claude-fable-5-1: 305; claude-haiku-5-5: 67; claude-sonnet-5-5: 61; claude-sonnet-5: 54 |
| thomas(untagged) | claude-opus-5: 972; claude-opus-5-5: 104 |
| builder | claude-sonnet-5: 111404; claude-opus-5-5: 53 |
| shaper | claude-opus-5: 3200; claude-sonnet-5: 191 |
| qa | claude-sonnet-5: 2985; claude-opus-5: 2125; claude-sonnet-4-6: 8 |
| other | claude-opus-5: 1394; claude-sonnet-5: 82; claude-haiku-4-5-20251001: 3 |

### 6d. Model per session (top-level sessions with a call in 30d; dominant model by call count)

| role | dominant model | single/mixed within the session | sessions |
|---|---|---|---|
| builder | claude-sonnet-5 | single | 304 |
| other | claude-haiku-4-5-20251001 | single | 1 |
| other | claude-opus-5 | single | 6 |
| other | claude-sonnet-5 | single | 3 |
| qa | claude-opus-5 | single | 11 |
| qa | claude-sonnet-4-6 | single | 3 |
| qa | claude-sonnet-5 | single | 32 |
| shaper | claude-opus-5 | single | 13 |
| thomas | claude-fable-5-1 | single | 1 |
| thomas | claude-opus-5 | single | 5 |
| thomas | claude-opus-5-5 | mixed | 1 |
| thomas | claude-opus-5-5 | single | 16 |
| thomas(untagged) | claude-opus-5 | single | 3 |
| thomas(untagged) | claude-opus-5-5 | single | 2 |

Subagent runs: a subagent line carries its own `message.model`; fork subagents showed `model: inherit` in meta.json. Section 6c includes subagent calls under their parent role.

## 7. Compactions

| role | trigger (compactMetadata.trigger) | 30d `compact_boundary` events | 7d |
|---|---|---|---|
| thomas | manual | 3 | 0 |
| thomas | auto | 13 | 7 |
| thomas(untagged) | manual | 1 | 0 |
| builder | manual | 1 | 0 |
| builder | auto | 8 | 5 |
| shaper | auto | 1 | 1 |

Heuristic count: consecutive assistant messages in one transcript where total prompt tokens (input+cache read+cache write) fall by more than 50% and the earlier one was at least 50,000 tokens (30d):

| role | own/subagent | drops >50% |
|---|---|---|
| builder | own | 32 |
| builder | sub | 4 |
| other | own | 1 |
| shaper | own | 1 |
| thomas | own | 34 |
| thomas(untagged) | own | 2 |

### 7b. Per-session compaction count (30d, top-level sessions with at least one compact_boundary or drop)

| session | role | dir | first day | compact_boundary events | >50% drops |
|---|---|---|---|---|---|
| 73cb18a2 | thomas | main | 2026-09-27 | 3 | 10 |
| 1907f191 | thomas | main | 2026-09-23 | 2 | 5 |
| bc9baaa0 | thomas | main | 2026-10-17 | 3 | 3 |
| 8cf631d5 | thomas | main | 2026-09-21 | 1 | 4 |
| ae4498c5 | thomas(untagged) | main | 2026-09-20 | 1 | 2 |
| 76221af0 | thomas | main | 2026-09-20 | 1 | 2 |
| d6be0294 | thomas | main | 2026-10-05 | 1 | 2 |
| e0730974 | builder | ude-worktrees-builder-TRA-1100 | 2026-10-13 | 1 | 2 |
| eb89a41a | thomas | main | 2026-10-15 | 1 | 2 |
| 3f27be19 | builder | ude-worktrees-builder-TRA-1132 | 2026-10-17 | 1 | 2 |
| 063c8856 | builder | cket-tra-830-testdb-second-run | 2026-09-21 | 1 | 1 |
| 5bc9eb7f | builder | ket-tra-841-manual-link-switch | 2026-09-22 | 1 | 1 |
| 358d529a | builder | aude-worktrees-builder-TRA-895 | 2026-09-27 | 1 | 1 |
| d1a8c54b | builder | aude-worktrees-builder-TRA-958 | 2026-09-30 | 1 | 1 |
| b851cba9 | thomas | main | 2026-10-03 | 1 | 1 |
| c355a763 | thomas | main | 2026-10-10 | 1 | 1 |
| 8ebfef2b | shaper | aude-worktrees-shaper-TRA-1078 | 2026-10-11 | 1 | 1 |
| 5f276c5d | thomas | main | 2026-10-12 | 1 | 1 |
| 66827de8 | builder | ude-worktrees-builder-TRA-1094 | 2026-10-12 | 1 | 1 |
| 7a4520e5 | thomas | main | 2026-10-13 | 1 | 1 |
| 7737646d | builder | ude-worktrees-builder-TRA-1108 | 2026-10-14 | 1 | 1 |
| b7106abc | builder | ude-worktrees-builder-TRA-1136 | 2026-10-17 | 1 | 1 |
| afc8e75d | builder | ude-worktrees-builder-TRA-1042 | 2026-10-08 | 0 | 2 |
| 52f956a1 | thomas | main | 2026-10-14 | 0 | 2 |
| 5ae3c3bf | builder | ude-worktrees-builder-TRA-1011 | 2026-10-06 | 0 | 1 |
| c01322f6 | builder | ude-worktrees-builder-TRA-1028 | 2026-10-07 | 0 | 1 |
| 47eff6a8 | builder | ude-worktrees-builder-TRA-1035 | 2026-10-07 | 0 | 1 |
| fcc7671f | builder | ude-worktrees-builder-TRA-1079 | 2026-10-11 | 0 | 1 |
| 1b100434 | builder | ude-worktrees-builder-TRA-1086 | 2026-10-12 | 0 | 1 |
| 524a0040 | builder | ude-worktrees-builder-TRA-1096 | 2026-10-13 | 0 | 1 |
| 9ab02103 | builder | ude-worktrees-builder-TRA-1106 | 2026-10-14 | 0 | 1 |
| fbf292f8 | builder | ude-worktrees-builder-TRA-1110 | 2026-10-14 | 0 | 1 |
| 7adbe891 | builder | ude-worktrees-builder-TRA-1116 | 2026-10-15 | 0 | 1 |
| 46b01261 | builder | ude-worktrees-builder-TRA-1143 | 2026-10-17 | 0 | 1 |
| b4eb620f | builder | aude-worktrees-builder-TRA-862 | 2026-09-24 | 0 | 1 |
| d5f34bf7 | builder | aude-worktrees-builder-TRA-945 | 2026-09-29 | 0 | 1 |
| b734d4e6 | builder | aude-worktrees-builder-TRA-947 | 2026-09-29 | 0 | 1 |
| eb0aab28 | builder | aude-worktrees-builder-TRA-956 | 2026-09-29 | 0 | 1 |
| 6c221935 | builder | aude-worktrees-builder-TRA-962 | 2026-09-30 | 0 | 1 |
| 6d0734b2 | builder | aude-worktrees-builder-TRA-963 | 2026-09-30 | 0 | 1 |

(+4 more sessions)

Sources: `system` lines with `subtype == compact_boundary` and `compactMetadata.trigger`; `user` lines with `isCompactSummary` (same count as boundaries: 38 all-time); the drop heuristic above. The mod auto-compaction at a context ceiling reports via `$.ui.status` and would appear as `trigger: manual`/`auto` boundary; the drop heuristic counts `/clear` resets and subagent restarts too. User `/compact` commands seen are in 1c.

## 8. Role contract sections vs what was measured

| contract section | measured role | what the section points at | 30d count per pointer, that role only | 7d counts in same order |
|---|---|---|---|---|
| builder.md § Phases you own | builder | Skill mattpocock-skills:implement (slash), mattpocock-skills:tdd, code-review, simplify, codex-arm, bmad-ux, atdd | mattpocock-skills:implement=278; mattpocock-skills:tdd=82; code-review=97; mattpocock-skills:code-review=175; simplify=326; codex-arm=275; bmad-ux=32; atdd=0 | 72/69/79/74/85/58/32/0 |
| builder.md § Load | builder | legacy-testing, untangle, dispatch-junior | legacy-testing=0; untangle=0; dispatch-junior=0 | 0/0/0 |
| builder.md § With a junior | builder | dispatch-junior, atdd | dispatch-junior=0; atdd=0 | 0/0 |
| builder.md § Handing back | builder | scripts/check-simplify-markers.sh | check-simplify-markers.sh=1356 | 365 |
| builder-claude.md § Two gates the mod holds | builder | tdd-gate, arm-gate | mod: tdd-gate=39; mod: arm-gate=3 | 37/3 |
| builder-claude.md § Long tickets | builder | /compact, /clear | /compact=1; /clear=0 | 0/0 |
| thomas.md § Load | thomas | github-issue-tracker, reconcile-tracker, dispatch-ticket, dispatch-ticket-claude | github-issue-tracker=0; jira-issue-tracker=0; linear-issue-tracker=0; reconcile-tracker=1; dispatch-ticket=15; dispatch-ticket-claude=15 | 0/0/0/0/6/6 |
| thomas.md § Phases you own | thomas | batch-triage, bootstrap-glossary, codex-arm, bmad-reviewer, mattpocock-skills:{triage,wayfinder,ask-matt,to-questionnaire} | batch-triage=0; bootstrap-glossary=0; codex-arm=11; mattpocock-skills:triage=0; mattpocock-skills:wayfinder=0; mattpocock-skills:ask-matt=0; mattpocock-skills:to-questionnaire=0; agent bmad-reviewer=9 | 0/0/4/0/0/0/0/7 |
| thomas.md § Dispatch | thomas | /mattpocock-skills:grill-with-docs, dispatch-junior, dispatch-ticket* | mattpocock-skills:grill-with-docs=0; dispatch-junior=0; dispatch-ticket=15; dispatch-ticket-claude=15 | 0/0/6/6 |
| thomas.md § Review | thomas | dispatch-qa-walk, simplify | dispatch-qa-walk=5; simplify=0 | 3/0 |
| thomas.md § Slice gate | thomas | bmad-reviewer fan-out | agent bmad-reviewer=9 | 7 |
| thomas.md § Merge | thomas | scripts/ticket-done.sh, merge-gate | ticket-done.sh=348; mod: merge-gate=0 | 88/0 |
| thomas.md § Watchdog | thomas | scripts/release-worktree-resources.sh, herdr-watchdog.sh, herdr-watch-terminal.sh | release-worktree-resources.sh=362; herdr-watchdog.sh=19; herdr-watch-terminal.sh=4 | 31/2/0 |
| thomas-claude.md § Dispatch routing / simplify verification | thomas | dispatch-ticket-claude, scripts/ticket-done.sh, simplify | dispatch-ticket-claude=15; simplify=0 | 6/0 |
| shaper.md § Phases you own | shaper | mattpocock-skills:{grill-with-docs,to-spec,to-tickets}, test-design, codex-arm | mattpocock-skills:grill-with-docs=11; mattpocock-skills:to-spec=18; mattpocock-skills:to-tickets=9; test-design=4; codex-arm=2 | 3/7/3/3/2 |
| shaper.md § Load | shaper | legacy-testing, untangle | legacy-testing=0; untangle=0 | 0/0 |
| shaper.md § Align | shaper | bmad-party | bmad-party=0 | 0 |
| shaper.md § STOP after Spec | shaper | /compact, /clear | /compact=0; /clear=0 | 0/0 |
| qa.md § Load | qa | bmad-ux, dispatch-qa-walk | bmad-ux=0; dispatch-qa-walk=0 | 0/0 |
| qa.md § Where the report lives | qa | .astraler/project/qa-report-path.sh | qa-report-path.sh=0 | 0 |

Source: pointers extracted by regex from each `## ` section of `harness/.agents/roles/*.md`; counts are Skill-tool + slash-command invocations (skills), first-token Bash runs (scripts), refusals (gates) or Agent spawns (agents) by sessions of that role.

## 9. Components with ZERO occurrences

| skill | kind | Skill-tool+slash 30d | all-time (since Jul 15) | body injected 30d | SKILL.md/doc read via Read/Bash/Grep 30d | doc reads all-time |
|---|---|---|---|---|---|---|
| atdd | harness skill | 0 | 0 | 0 | 1 | 1 |
| batch-triage | harness skill | 0 | 0 | 0 | 1 | 1 |
| bmad-party | harness skill | 0 | 0 | 0 | 0 | 0 |
| bmad-ux | harness skill | 32 | 32 | 32 | 3 | 3 |
| bootstrap-glossary | harness skill | 0 | 0 | 0 | 4 | 4 |
| codex-arm | harness skill | 288 | 291 | 285 | 95 | 96 |
| dispatch-junior | harness skill | 0 | 0 | 0 | 10 | 10 |
| dispatch-qa-walk | harness skill | 5 | 5 | 5 | 5 | 7 |
| dispatch-ticket | harness skill | 16 | 16 | 16 | 703 | 711 |
| dispatch-ticket-claude | harness skill | 15 | 15 | 15 | 69 | 74 |
| github-issue-tracker | harness skill | 0 | 0 | 0 | 35 | 35 |
| jira-issue-tracker | harness skill | 0 | 0 | 0 | 1 | 1 |
| legacy-testing | harness skill | 0 | 0 | 0 | 1 | 1 |
| linear-issue-tracker | harness skill | 0 | 0 | 0 | 1 | 1 |
| reconcile-tracker | harness skill | 1 | 1 | 1 | 1 | 1 |
| test-design | harness skill | 8 | 8 | 8 | 6 | 6 |
| untangle | harness skill | 0 | 0 | 0 | 1 | 1 |
| mattpocock-skills:tdd | plugin/builtin skill | 82 | 82 | 82 | 0 | 0 |
| mattpocock-skills:code-review | plugin/builtin skill | 175 | 175 | 175 | 0 | 0 |
| mattpocock-skills:implement | plugin/builtin skill | 278 | 281 | 278 | 0 | 0 |
| mattpocock-skills:to-spec | plugin/builtin skill | 18 | 18 | 10 | 0 | 0 |
| mattpocock-skills:to-tickets | plugin/builtin skill | 9 | 9 | 9 | 0 | 0 |
| mattpocock-skills:grill-with-docs | plugin/builtin skill | 11 | 11 | 11 | 0 | 0 |
| mattpocock-skills:triage | plugin/builtin skill | 0 | 0 | 0 | 0 | 0 |
| mattpocock-skills:wayfinder | plugin/builtin skill | 0 | 0 | 0 | 0 | 0 |
| mattpocock-skills:ask-matt | plugin/builtin skill | 0 | 0 | 0 | 0 | 0 |
| mattpocock-skills:to-questionnaire | plugin/builtin skill | 0 | 0 | 0 | 0 | 0 |
| mattpocock-skills:grilling | plugin/builtin skill | 6 | 6 | 6 | 0 | 0 |
| mattpocock-skills:domain-modeling | plugin/builtin skill | 6 | 6 | 6 | 5 | 5 |
| mattpocock-skills:diagnosing-bugs | plugin/builtin skill | 0 | 0 | 0 | 0 | 0 |
| mattpocock-skills:simplify | plugin/builtin skill | 0 | 0 | 0 | 0 | 0 |
| simplify | plugin/builtin skill | 327 | 331 | 0 | 0 | 0 |
| code-review | plugin/builtin skill | 97 | 98 | 175 | 0 | 0 |

| plugin agent | Agent spawns 30d | all-time | subagent transcripts started 30d |
|---|---|---|---|
| astragentic-dispatch:bmad-john | 0 | 0 | 0 |
| astragentic-dispatch:bmad-mary | 0 | 0 | 0 |
| astragentic-dispatch:bmad-murat | 2 | 2 | 1 |
| astragentic-dispatch:bmad-paige | 0 | 0 | 0 |
| astragentic-dispatch:bmad-reviewer | 9 | 9 | 7 |
| astragentic-dispatch:bmad-sally | 35 | 35 | 33 |
| astragentic-dispatch:bmad-winston | 0 | 0 | 0 |

Scripts and hooks, 30d run count (zero rows are the candidates):

| script | Bash runs 30d | Bash mentions 30d | hook attachments 30d |
|---|---|---|---|
| check-payload-drift.sh | 1 | 2 |  |
| check-reachability.py | 66 | 83 |  |
| check-simplify-markers.sh | 1911 | 2302 |  |
| docs-staleness-audit.sh | 47 | 64 |  |
| herdr-watch-terminal.sh | 9 | 22 |  |
| herdr-watchdog.sh | 26 | 96 |  |
| hook-contract-reload.py | 0 | 1 | 27 |
| hook-git-guard.py | 10 | 69 | 1 |
| hook-tracker-status.py | 0 | 3 | 407 |
| ledger-index.sh | 19 | 24 |  |
| ledger-rules.py | 2 | 3 |  |
| pre-push-ticket-done.sh | 2 | 8 |  |
| reap-worktree-processes.sh | 2 | 6 |  |
| release-worktree-resources.sh | 384 | 410 | 0 |
| selftest.sh | 19 | 33 |  |
| ticket-done.sh | 351 | 365 |  |
| ticket-git-facts.sh | 5 | 6 |  |
| lib/marker_field_parser.py | 0 | 2 |  |
| check-requirements.sh | 129 | 166 |  |

Gates, observed refusals:

| gate | 30d fires | all-time fires (since Jul 15) |
|---|---|---|
| mod: tdd-gate | 39 | 39 |
| mod: arm-gate | 3 | 3 |
| mod: wait-gate | 5 | 5 |
| mod: merge-gate | 0 | 0 |
| mod: refused-command | 0 | 0 |
| mod: close-refusal | 0 | 0 |
| mod: worktree-remove refusal | 16 | 16 |
| mod: no-human-picker | 7 | 7 |
| mod: brief refused (payload edited/untracked) | 2 | 2 |
| mod: brief refused (ticket not claimed) | 1 | 1 |
| mod: brief refused (QA line/plan) | 0 | 0 |
| mod: brief refused (base ticket with no ticket-done) | 1 | 1 |
| mod: brief refused (upgrade incomplete) | 0 | 0 |
| guard: git add -A / . refused | 167 | 167 |
| guard: push main without ticket-done stamp | 27 | 27 |
| guard: worktree remove without release stamp | 22 | 22 |
| guard: rm -rf worktree | 4 | 4 |
| guard: worktree remove with uncommitted changes | 3 | 3 |
| guard: worktree remove with live processes | 7 | 7 |

### 9b. Explicit zero list (30 days)

| kind | component | evidence |
|---|---|---|
| skill | atdd | 0 Skill/slash 30d; body injected 0; doc read 1 |
| skill | batch-triage | 0 Skill/slash 30d; body injected 0; doc read 1 |
| skill | bmad-party | 0 Skill/slash 30d; body injected 0; doc read 0 |
| skill | bootstrap-glossary | 0 Skill/slash 30d; body injected 0; doc read 4 |
| skill | dispatch-junior | 0 Skill/slash 30d; body injected 0; doc read 10 |
| skill | github-issue-tracker | 0 Skill/slash 30d; body injected 0; doc read 35 |
| skill | jira-issue-tracker | 0 Skill/slash 30d; body injected 0; doc read 1 |
| skill | legacy-testing | 0 Skill/slash 30d; body injected 0; doc read 1 |
| skill | linear-issue-tracker | 0 Skill/slash 30d; body injected 0; doc read 1 |
| skill | untangle | 0 Skill/slash 30d; body injected 0; doc read 1 |
| skill | mattpocock-skills:triage | 0 Skill/slash 30d; body injected 0; doc read 0 |
| skill | mattpocock-skills:wayfinder | 0 Skill/slash 30d; body injected 0; doc read 0 |
| skill | mattpocock-skills:ask-matt | 0 Skill/slash 30d; body injected 0; doc read 0 |
| skill | mattpocock-skills:to-questionnaire | 0 Skill/slash 30d; body injected 0; doc read 0 |
| skill | mattpocock-skills:diagnosing-bugs | 0 Skill/slash 30d; body injected 0; doc read 0 |
| skill | mattpocock-skills:simplify | 0 Skill/slash 30d; body injected 0; doc read 0 |
| plugin agent | astragentic-dispatch:bmad-john | 0 spawns 30d |
| plugin agent | astragentic-dispatch:bmad-mary | 0 spawns 30d |
| plugin agent | astragentic-dispatch:bmad-paige | 0 spawns 30d |
| plugin agent | astragentic-dispatch:bmad-winston | 0 spawns 30d |
| library | lib/marker_field_parser.py | not run directly (0 Bash runs); it is imported by check-simplify-markers.sh, so this is expected, not a finding |
| plug | watchdog-probe.sh | 0 runs 30d (0 mentions); may be called by another script, invisible to Bash logging |
| plug data file | refused-in-dispatched-panes | 0 runs 30d (0 mentions); a regex list read by the mod, never run; its only observable effect is the refused-command gate, 0 fires |
| plug | qa-report-path.sh | 0 runs 30d (1 mentions); may be called by another script, invisible to Bash logging |
| gate | mod: merge-gate | 0 fires 30d, 0 all-time |
| gate | mod: refused-command | 0 fires 30d, 0 all-time |
| gate | mod: close-refusal | 0 fires 30d, 0 all-time |
| gate | mod: brief refused (QA line/plan) | 0 fires 30d, 0 all-time |
| gate | mod: brief refused (upgrade incomplete) | 0 fires 30d, 0 all-time |


## 10. Limits of the method (what transcripts cannot show)

- **Silent successes are invisible.** A PreToolUse hook that allows a call leaves no line in the transcript, so hook-git-guard.py invocation counts are unknowable; only its denials are visible (section 3). The same holds for the mod gates: a passing tdd/arm/wait/merge gate leaves nothing. The refusal counts are numerator only, with no denominator of "times the gate evaluated and passed".
- **Mod UI output is not recorded.** `$.ui.status`, toasts, the status-line chips, the `RECEIVED` ack, `confirmed receipt`, `TURN-END held`, `readdressed`, `compaction skipped`, `context compacted at the Nk ceiling` and `recorded tab...` are rendered in the terminal or consumed by the mod. None of them is a transcript line. The only mod outputs that reach the model are bells (user turn, origin plugin), deny texts (tool_result), brief refusals (SendMessage result) and prompt-submit notes. Pane-screen captures that Thomas pasted back via herdr do contain the status text, but those are quotations and are excluded from every count.
- **The dispatch record is the better source for gates.** `.astraler/state/dispatch-record.json[key].refusals` and `skills_run` (written by `logRefusal`) hold refusal events and the Skill calls the merge gate checks. That file is outside the transcripts and was not read (read-only brief, no access requested).
- **Script "run" is a parse, not an exit.** Bash commands are matched textually. A script invoked inside another script (watchdog-probe.sh from herdr-watchdog.sh, lib/marker_field_parser.py from check-simplify-markers.sh, hooks from settings.json) is not seen as a Bash call. Commands over 8000 characters were truncated before matching. STOP/MISS/FAIL is a keyword hit in output, not a verdict.
- **Non-zero exit coverage.** Claude Code writes `Exit code N` into the tool_result text only when it is non-zero; a result without it is treated as exit 0. Background Bash calls (run_in_background) return only a launch acknowledgement, so their real exit is not in the call's own result.
- **Role is inferred.** Sessions without an `agent-setting` line (8 main-checkout sessions) are labelled `thomas(untagged)`; `rin` is merged into `qa`. Subagents take their parent's role. Spawns from a resumed or forked session may be attributed to the file where the line was first written.
- **Cost is an estimate from usage fields.** Only the supplied Sonnet 5 and Opus 5.5 rates were used; fable and haiku calls are priced at Opus and Sonnet rates. Opus cache-write was assumed at 2x input. Subscription billing, 1-hour cache premiums, batch discounts, and the advisor tool's separate model calls are not modelled; an advisor call appears in neither the parent usage nor as a subagent. `<synthetic>` messages (156) were excluded.
- **A skill counted once is not a skill that mattered.** Invocation shows a skill was loaded, not that it changed the output. Skills read by `Read` of a SKILL.md (column in section 9) were loaded without being invoked and can explain a zero.
- **Skill-by-ticket for Thomas and Shaper** uses the first `TRA-n` in the call arguments, so skills called without a ticket in the args (dispatch-ticket, dispatch-ticket-claude, dispatch-qa-walk, reconcile-tracker) show 0 tickets. They are session-scoped, not ticket-scoped.
- **Windows.** 30d starts 2026-09-18 and 7d starts 2026-10-11 at 00:00 UTC. The 7d window follows the 4.0.x releases; 30d spans earlier harness versions (the tdd/arm/wait gates, the brief `/` convention and the TURN-END bells only exist from about 2026-10-05, so their 30d totals are a fortnight of data, not a month). Transcripts before 2026-09-18 exist back to 2026-07-15 and were only used for the all-time columns of section 9.
- **Ticket attribution** for older Builder directories (`ticket-tra-NNN-slug`) and QA gate directories (`gate-*`) uses the number in the directory name; batch gates covering several tickets are attributed to the first.
- **Transcripts show what happened, not what a component prevented.** A refusal that stops a mistake is counted; a rule that is obeyed without ever firing (the agent never attempts the forbidden command) looks identical to a rule that is dead. Zero fires means either, and needs a planted-defect test to tell apart.
