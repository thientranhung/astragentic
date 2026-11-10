# Kiểm kê nguồn Astragentic cho Codex

Baseline Git: `f484b22a4a37157ca8fc9a0e723299ccb61e0442`. Ngày: 2026-11-05.

Đây là chỉ mục nguồn và các dấu phụ thuộc runtime, không phải kết quả chạy thử. Scan tự động không chứng minh file không có phụ thuộc khi không khớp pattern.

| Nhóm | Số lượng |
|---|---:|
| File role và runtime supplement | 10 |
| Skill chính | 17 |
| Agent phụ plugin Claude | 3 |
| Skill adoption | 2 |

## `harness/.agents/roles/ba.md`

70 dòng. [Mở nguồn](../../harness/.agents/roles/ba.md).

- `harness/.agents/roles/ba.md:3` — **Session: owner-opened, read-only.** The owner starts it (`claude --agent ba`, tab `ba`)
- `harness/.agents/roles/ba.md:15` — / session start / `docs/agents/issue-tracker.md`, then the adapter it names (`Skill(skill: "github-issue-tracker")`, `jira-issue-tracker` or `linear-issue-tracker`) / how this project's tickets are written and labelled /
- `harness/.agents/roles/ba.md:19` — / an answer needs research / WebSearch, the code, or a read-only sub-agent briefed "read and report only" / a source for the recommendation /

## `harness/.agents/roles/builder-claude.md`

126 dòng. [Mở nguồn](../../harness/.agents/roles/builder-claude.md).

- `harness/.agents/roles/builder-claude.md:6` — ## Three gates the mod holds
- `harness/.agents/roles/builder-claude.md:23` — background launch is logged `background`, which is no code at all. The mod refuses a content `git commit` (empty marker commits pass) unless a test file is
- `harness/.agents/roles/builder-claude.md:40` — **Invoke `Skill(skill: "astra-review")`** after the UI pass and before simplify. It launches
- `harness/.agents/roles/builder-claude.md:41` — `Skill(skill: "code-review")`, Claude Code's built-in bug review, as its correctness lens — not
- `harness/.agents/roles/builder-claude.md:47` — **Invoke `Skill(skill: "simplify")`** — model-invocable, no plugin prefix.
- `harness/.agents/roles/builder-claude.md:52` — substitute leaves the same marker, and `Skills run:` on `TURN-END` is what shows it was never invoked.
- `harness/.agents/roles/builder-claude.md:64` — Agent(subagent_type: "...", isolation: "worktree", prompt: "...")   # report-only fan-out
- `harness/.agents/roles/builder-claude.md:75` — context including Thomas's address, and its `SendMessage` arrives under your name where you
- `harness/.agents/roles/builder-claude.md:85` — Pass: Skill(skill: "simplify")'
- `harness/.agents/roles/builder-claude.md:90` — Pass: Skill(skill: "simplify") — fork unavailable, ran four corners directly'
- `harness/.agents/roles/builder-claude.md:94` — Pass: Skill(skill: "simplify") — forks returned narration (AST-098), ran four corners directly'
- `harness/.agents/roles/builder-claude.md:99` — Pass: Skill(skill: "simplify")'
- `harness/.agents/roles/builder-claude.md:104` — When your `orchestrator.md` row sets an advisor, your session carries a stronger model you can
- `harness/.agents/roles/builder-claude.md:116` — agent, an `Agent(...)` call) keeps your TURN-END held: the mod sends it only when no agent of
- `harness/.agents/roles/builder-claude.md:118` — agent — the hold does not see it, so a turn that ends on one reports TURN-END with the work
- `harness/.agents/roles/builder-claude.md:124` — keeps waking an idle pane after your handback. The mod refuses it in a dispatched pane

## `harness/.agents/roles/builder.md`

167 dòng. [Mở nguồn](../../harness/.agents/roles/builder.md).

- `harness/.agents/roles/builder.md:14` — / session start / `.agents/roles/builder-claude.md` / the two mod gates, simplify invocation, context management /
- `harness/.agents/roles/builder.md:15` — / session start / `.agents/orchestrator.md` `## Junior`, then `dispatch-junior` if a runtime is named / whose the typing is /
- `harness/.agents/roles/builder.md:33` — / Cross-vendor arm / `codex-arm`; off when `orchestrator.md` arm row `ticket` = `no` / `arm(ticket):` receipt at head, or `Arm: off (orchestrator)` /
- `harness/.agents/roles/builder.md:45` — **A thin context window is not a stop reason.** Commit what is done and continue; the mod
- `harness/.agents/roles/builder.md:69` — `TURN-END` carries `Skills run:`; tdd is not a call but a RED run in the test log, which is
- `harness/.agents/roles/builder.md:81` — When `orchestrator.md`'s Junior row names a runtime, Build splits: **the red tests are yours**
- `harness/.agents/roles/builder.md:95` — routes it. A quick ticket calls the built-in `Skill(skill: "code-review")` alone.

## `harness/.agents/roles/junior-grok.md`

28 dòng. [Mở nguồn](../../harness/.agents/roles/junior-grok.md).

- `harness/.agents/roles/junior-grok.md:8` — Grok Build loads this project's `CLAUDE.md`/`AGENTS.md` chain, `.claude/rules/`, the skills under
- `harness/.agents/roles/junior-grok.md:9` — `.agents/skills/` and `~/.claude/skills/`, and, once the folder is trusted, the project's
- `harness/.agents/roles/junior-grok.md:10` — `.claude/settings.json` hooks (Grok Build 1.0.60 docs, 2026-10-16; the lab did not exercise the hooks). There is no `Skill` tool: a skill is read by
- `harness/.agents/roles/junior-grok.md:25` — The dispatch mod and its gates do not run on this runtime, and the project's git guard reads a

## `harness/.agents/roles/junior.md`

59 dòng. [Mở nguồn](../../harness/.agents/roles/junior.md).

Không khớp pattern phụ thuộc runtime; vẫn cần semantic review trước khi tái sử dụng.

## `harness/.agents/roles/qa.md`

198 dòng. [Mở nguồn](../../harness/.agents/roles/qa.md).

- `harness/.agents/roles/qa.md:11` — probed, a job verified. The dispatch's `Mode:` line names it and the mod records it.
- `harness/.agents/roles/qa.md:125` — yes does not carry to the next run. The mod refuses only the commands the project lists in

## `harness/.agents/roles/quick-builder.md`

63 dòng. [Mở nguồn](../../harness/.agents/roles/quick-builder.md).

- `harness/.agents/roles/quick-builder.md:3` — **Session: owner-opened, one task, no ticket.** The owner starts it (`claude --agent quick-builder`,
- `harness/.agents/roles/quick-builder.md:37` — 1. `git worktree add -b ops/<slug> .claude/worktrees/quick-<slug> main`, and work there.
- `harness/.agents/roles/quick-builder.md:46` — 6. Tell Thomas in one line (SendMessage to the resident pane): what landed, the commit.

## `harness/.agents/roles/shaper.md`

105 dòng. [Mở nguồn](../../harness/.agents/roles/shaper.md).

- `harness/.agents/roles/shaper.md:27` — / Arm / `codex-arm` (`arm: spec`); skipped when `orchestrator.md` arm row `spec` is `no` / you fired the arm over the finalized spec, its findings are folded and the spec is committed /

## `harness/.agents/roles/thomas-claude.md`

43 dòng. [Mở nguồn](../../harness/.agents/roles/thomas-claude.md).

- `harness/.agents/roles/thomas-claude.md:11` — Skill(skill: "dispatch-ticket")
- `harness/.agents/roles/thomas-claude.md:12` — Skill(skill: "dispatch-ticket-claude")
- `harness/.agents/roles/thomas-claude.md:17` — **One SendMessage per brief, and no watcher to arm.** The `astragentic-dispatch` mod, which
- `harness/.agents/roles/thomas-claude.md:26` — The mod does the arming, typing and id-recording from inside the pane
- `harness/.agents/roles/thomas-claude.md:31` — One marker per increment. A `Pass:` line that starts with `Skill(skill: "simplify")` is the
- `harness/.agents/roles/thomas-claude.md:35` — Pass: Skill(skill: "simplify")
- `harness/.agents/roles/thomas-claude.md:36` — Pass: Skill(skill: "simplify") — fork unavailable, ran four corners directly
- `harness/.agents/roles/thomas-claude.md:41` — `Pass:` line that does not start with `Skill(skill: "simplify")` is a substitute, and an

## `harness/.agents/roles/thomas.md`

196 dòng. [Mở nguồn](../../harness/.agents/roles/thomas.md).

- `harness/.agents/roles/thomas.md:11` — / session start / `.agents/orchestrator.md` / workspace-label; runtime, model and effort per role /
- `harness/.agents/roles/thomas.md:13` — / session start / the adapter that file names — `Skill(skill: "github-issue-tracker")`, `Skill(skill: "jira-issue-tracker")` or `Skill(skill: "linear-issue-tracker")` / how to drive that tracker /
- `harness/.agents/roles/thomas.md:23` — **The BA is not yours to dispatch.** The owner opens it (`claude --agent ba`, tab `ba`); it
- `harness/.agents/roles/thomas.md:27` — **Nor is the Quick Builder** (`claude --agent quick-builder`, tab `quick-builder`): the owner's pane for small
- `harness/.agents/roles/thomas.md:37` — / Slice gate / `codex-arm` + `Agent(astragentic-dispatch:astra-slice-reviewer)` / slice-close findings, folded, on an `arm(slice):` marker /
- `harness/.agents/roles/thomas.md:60` — frontier.** The default is **4**; `.agents/orchestrator.md` carries the override where the
- `harness/.agents/roles/thomas.md:104` — UJ-n, …` or `UX: n/a — <why>`; the mod refuses a Shaper brief without it (5.0.9).
- `harness/.agents/roles/thomas.md:112` — do.** The mod reads the label at your brief and sets the Builder's gates (`dispatch-ticket` §
- `harness/.agents/roles/thomas.md:117` — **Steer** the Builder directly via SendMessage. A pane's status is a bell; the verdict is the diff and the tests. A TURN-END that says it waits on agents while its `Agents:` line reads 0 running is parked: send it on. A junior pane (`dispatch-junior`) is the Builder's; its commits arrive in the handback, trailered `Implemented-by:`.
- `harness/.agents/roles/thomas.md:139` — `Agent(subagent_type: "astragentic-dispatch:astra-slice-reviewer", isolation: "worktree", prompt: "… read and report only …")`
- `harness/.agents/roles/thomas.md:145` — Invocation is `codex-arm`; the firer records the vendor. An `orchestrator.md` arm row at `no` skips that

## `harness/.agents/skills/astra-grill-with-docs/SKILL.md`

62 dòng. [Mở nguồn](../../harness/.agents/skills/astra-grill-with-docs/SKILL.md).

- `harness/.agents/skills/astra-grill-with-docs/SKILL.md:4` — disable-model-invocation: true

## `harness/.agents/skills/astra-implement-with-tdd/SKILL.md`

72 dòng. [Mở nguồn](../../harness/.agents/skills/astra-implement-with-tdd/SKILL.md).

- `harness/.agents/skills/astra-implement-with-tdd/SKILL.md:4` — disable-model-invocation: true

## `harness/.agents/skills/astra-review/SKILL.md`

68 dòng. [Mở nguồn](../../harness/.agents/skills/astra-review/SKILL.md).

- `harness/.agents/skills/astra-review/SKILL.md:20` — - **Correctness**: `Skill(skill: "code-review")`, the built-in, on the staged diff. It hunts

## `harness/.agents/skills/astra-to-spec/SKILL.md`

83 dòng. [Mở nguồn](../../harness/.agents/skills/astra-to-spec/SKILL.md).

- `harness/.agents/skills/astra-to-spec/SKILL.md:4` — disable-model-invocation: true

## `harness/.agents/skills/astra-to-tickets/SKILL.md`

122 dòng. [Mở nguồn](../../harness/.agents/skills/astra-to-tickets/SKILL.md).

- `harness/.agents/skills/astra-to-tickets/SKILL.md:4` — disable-model-invocation: true
- `harness/.agents/skills/astra-to-tickets/SKILL.md:95` — - **A UI ticket without `## Glance` and `## States` is not cut.** Thomas's mod refuses to

## `harness/.agents/skills/astra-ui/SKILL.md`

65 dòng. [Mở nguồn](../../harness/.agents/skills/astra-ui/SKILL.md).

- `harness/.agents/skills/astra-ui/SKILL.md:13` — Skill(skill: "astra-ui", args: "audit <surface>")      # a route, a component, a flow, or "the dashboard"
- `harness/.agents/skills/astra-ui/SKILL.md:14` — Skill(skill: "astra-ui", args: "polish <surface>")
- `harness/.agents/skills/astra-ui/SKILL.md:15` — Skill(skill: "astra-ui", args: "upgrade <surface>")
- `harness/.agents/skills/astra-ui/SKILL.md:48` — context calls `Skill(astra-ui)` first, then spawns the lens read-only from within it:
- `harness/.agents/skills/astra-ui/SKILL.md:51` — Agent(subagent_type: "astragentic-dispatch:astra-ui-lens", isolation: "worktree",
- `harness/.agents/skills/astra-ui/SKILL.md:55` — The report returns to the caller, who decides. Only the `Skill(astra-ui)` call is recorded in

## `harness/.agents/skills/astra-ux/SKILL.md`

62 dòng. [Mở nguồn](../../harness/.agents/skills/astra-ux/SKILL.md).

Không khớp pattern phụ thuộc runtime; vẫn cần semantic review trước khi tái sử dụng.

## `harness/.agents/skills/codex-arm/SKILL.md`

251 dòng. [Mở nguồn](../../harness/.agents/skills/codex-arm/SKILL.md).

- `harness/.agents/skills/codex-arm/SKILL.md:64` — Plugin root: `~/.claude/plugins/cache/openai-codex/codex/<version>`. Plain `review --background
- `harness/.agents/skills/codex-arm/SKILL.md:131` — git worktree add --detach <repo-root>/.claude/worktrees/gate-arm-<key> <head-sha>
- `harness/.agents/skills/codex-arm/SKILL.md:160` — **The `WorktreeRemove` hook in `.claude/settings.json` calls `scripts/release-worktree-resources.sh`

## `harness/.agents/skills/dispatch-junior/SKILL.md`

142 dòng. [Mở nguồn](../../harness/.agents/skills/dispatch-junior/SKILL.md).

- `harness/.agents/skills/dispatch-junior/SKILL.md:3` — description: "Builder-only recipe to hand a ticket's implementation to a junior pane on another runtime (Grok first) and take the tree back for review, simplify and the arm. Fires only when the Builder's Junior row in .agents/orchestrator.md names a runtime. Covers the pane, the launcher, the brief, the wait, the read-back and the close."
- `harness/.agents/skills/dispatch-junior/SKILL.md:11` — **When:** `.agents/orchestrator.md` → `## Junior` → the `builder` row names a runtime. `none`
- `harness/.agents/skills/dispatch-junior/SKILL.md:18` — over the junior's commits exactly as over your own. The mod's gates read your pane, not the

## `harness/.agents/skills/dispatch-qa-walk/SKILL.md`

172 dòng. [Mở nguồn](../../harness/.agents/skills/dispatch-qa-walk/SKILL.md).

Không khớp pattern phụ thuộc runtime; vẫn cần semantic review trước khi tái sử dụng.

## `harness/.agents/skills/dispatch-ticket/CLEANUP.md`

93 dòng. [Mở nguồn](../../harness/.agents/skills/dispatch-ticket/CLEANUP.md).

- `harness/.agents/skills/dispatch-ticket/CLEANUP.md:30` — in `.astraler/state/dispatch-record.json`. On a Claude root the mod refuses the close while
- `harness/.agents/skills/dispatch-ticket/CLEANUP.md:83` — On a Claude root the mod runs the release itself at `git worktree remove`

## `harness/.agents/skills/dispatch-ticket/GATE.md`

114 dòng. [Mở nguồn](../../harness/.agents/skills/dispatch-ticket/GATE.md).

- `harness/.agents/skills/dispatch-ticket/GATE.md:42` — <repo-root>/.claude/worktrees/gate-<artifact-key> <reviewed-sha>
- `harness/.agents/skills/dispatch-ticket/GATE.md:53` — **The argv comes from `dispatch-ticket-claude` (§ Launcher matrix), and it omits the executable.** `--kind claude` makes herdr run `claude` itself; an argv that begins with `claude` launches `claude claude …` and the pane's first turn runs on the prompt "claude" with no brief (measured once, 2026-11-01). The `qa` row's Runtime column in `orchestrator.md` must read `claude`; anything else means STOP.
- `harness/.agents/skills/dispatch-ticket/GATE.md:64` — **Deliver the brief through the mod on a Claude root** — one `SendMessage` whose first line is
- `harness/.agents/skills/dispatch-ticket/GATE.md:66` — brief's `Mode:` line. `herdr agent prompt` is the form for a pane without the mod (a gate pane), and the
- `harness/.agents/skills/dispatch-ticket/GATE.md:104` — prompt` and runs under permissions, so its mod has no dispatcher address and a direct message
- `harness/.agents/skills/dispatch-ticket/GATE.md:106` — `qa:<artifact-key>` entry and your mod rings it within the 30-second poll, worded as a gate

## `harness/.agents/skills/dispatch-ticket/MARKERS.md`

111 dòng. [Mở nguồn](../../harness/.agents/skills/dispatch-ticket/MARKERS.md).

- `harness/.agents/skills/dispatch-ticket/MARKERS.md:9` — scripts/check-simplify-markers.sh <base> <head> --marker 'arm(ticket)'   # omit when orchestrator.md arm row ticket = no

## `harness/.agents/skills/dispatch-ticket/SKILL.md`

309 dòng. [Mở nguồn](../../harness/.agents/skills/dispatch-ticket/SKILL.md).

- `harness/.agents/skills/dispatch-ticket/SKILL.md:9` — `.agents/orchestrator.md`, read at session start; an edit takes effect at the next dispatch.
- `harness/.agents/skills/dispatch-ticket/SKILL.md:10` — Every role runs on Claude Code. **The launcher, the mod and pre-dispatch verification live in
- `harness/.agents/skills/dispatch-ticket/SKILL.md:17` — 2. **Resolve the row** — runtime, model, effort from `orchestrator.md`; collect the write-set.
- `harness/.agents/skills/dispatch-ticket/SKILL.md:22` — 7. **Branch on the pane's turn end** — `TURN-END` for a mod pane, the watcher's exit for a gate or junior pane.
- `harness/.agents/skills/dispatch-ticket/SKILL.md:37` — - model, effort, advisor: `.agents/orchestrator.md`
- `harness/.agents/skills/dispatch-ticket/SKILL.md:44` — A row reading `<set-me>`, a missing row, or an ambiguous `orchestrator.md` is a STOP: name
- `harness/.agents/skills/dispatch-ticket/SKILL.md:67` — `PAYLOAD NOT VISIBLE` is a STOP. The mod also refuses the brief while a payload file is
- `harness/.agents/skills/dispatch-ticket/SKILL.md:72` — `<worktree-path>` is ABSOLUTE: `<repo-root>/.claude/worktrees/<branch-slug>` (branch `/`
- `harness/.agents/skills/dispatch-ticket/SKILL.md:87` — **Workspace.** Match `workspace-label` from `orchestrator.md` against `herdr workspace list`.
- `harness/.agents/skills/dispatch-ticket/SKILL.md:107` — silently. The mod reads the tab label at session start, so label before launch.
- `harness/.agents/skills/dispatch-ticket/SKILL.md:119` — else the `builder` row. The mod reads the same label again at the send and sets the gates.
- `harness/.agents/skills/dispatch-ticket/SKILL.md:136` — skills are `disable-model-invocation: true`, so only text arriving as a user turn reaches
- `harness/.agents/skills/dispatch-ticket/SKILL.md:139` — (`simplify`) is written `Skill(skill: "simplify")` in a brief, never `/simplify`. <!-- addr-ok: wrong form, cited -->
- `harness/.agents/skills/dispatch-ticket/SKILL.md:143` — looks at a surface. The mod refuses the brief without it, when the PRD is not committed on the
- `harness/.agents/skills/dispatch-ticket/SKILL.md:150` — a `TDD: n/a — <why>`, `REVIEW: n/a — <why>` or `SIMPLIFY: n/a — <why>` brief line, read by the mod
- `harness/.agents/skills/dispatch-ticket/SKILL.md:153` — **The kind — `quick` or `full` — is the ticket's label, never a brief line** (4.6.0). The mod
- `harness/.agents/skills/dispatch-ticket/SKILL.md:160` — FLOW: 1 Skill(skill: "code-review")   [quick: the project's existing tests, the BUILT-IN review by its bare name, handback]
- `harness/.agents/skills/dispatch-ticket/SKILL.md:164` — (`Skill(skill: "code-review")`), and the merge gate reads that key off the record.** A full
- `harness/.agents/skills/dispatch-ticket/SKILL.md:172` — verbatim** (5.0.0). The mod sees the brief and not the tracker: a brief whose `FLOW:` names
- `harness/.agents/skills/dispatch-ticket/SKILL.md:180` — project's `.claude/skills`, `.agents/skills` or `~/.claude/skills`). The mod refuses a brief whose
- `harness/.agents/skills/dispatch-ticket/SKILL.md:194` — FLOW: 1 Skill(astraler-ui-anti-slop) [before UI code; .astraler/project/anti-slop-skills] → 2 Skill(astra-ui) [UI ticket]
- `harness/.agents/skills/dispatch-ticket/SKILL.md:195` — → 3 Skill(astra-review) [the built-in code-review runs inside it] → 4 Skill(simplify) [once, last content commit] → 5 arm(ticket)
- `harness/.agents/skills/dispatch-ticket/SKILL.md:224` — - **`QA:` and `QA plan:`** are required by the mod (`dispatch-ticket-claude` § QA).
- `harness/.agents/skills/dispatch-ticket/SKILL.md:228` — A Builder, Shaper or QA pane carries the brief over `SendMessage` (`dispatch-ticket-claude`).
- `harness/.agents/skills/dispatch-ticket/SKILL.md:229` — A pane without the mod, a QA gate pane (`GATE.md` explains why) or a junior pane
- `harness/.agents/skills/dispatch-ticket/SKILL.md:242` — A mod pane reports its own turn end as `TURN-END` (`dispatch-ticket-claude`); there is nothing
- `harness/.agents/skills/dispatch-ticket/SKILL.md:264` — "worktree": "/abs/path/.claude/worktrees/builder-ABC-129",
- `harness/.agents/skills/dispatch-ticket/SKILL.md:289` — - **`kind` is written by the dispatcher's mod at the send**, from the tracker's label
- `harness/.agents/skills/dispatch-ticket/SKILL.md:291` — `review_na`, `simplify_na`, `ux_owed`) by the pane's mod from the delivered brief. The
- `harness/.agents/skills/dispatch-ticket/SKILL.md:296` — For a pane without the mod, Thomas writes `tab_id` and `pane_id` from the create output.

## `harness/.agents/skills/dispatch-ticket/WATCHING.md`

118 dòng. [Mở nguồn](../../harness/.agents/skills/dispatch-ticket/WATCHING.md).

- `harness/.agents/skills/dispatch-ticket/WATCHING.md:4` — The per-turn watcher is for a pane without the mod: a QA gate pane or a junior pane
- `harness/.agents/skills/dispatch-ticket/WATCHING.md:5` — (`dispatch-junior`). A mod pane reports its own turn end (`dispatch-ticket-claude`) and draws
- `harness/.agents/skills/dispatch-ticket/WATCHING.md:87` — It reads `workspace-label` from `orchestrator.md`; `stop` verifies the PID at the lock.
- `harness/.agents/skills/dispatch-ticket/WATCHING.md:91` — `orchestrator.md`, sweep, and read each cwd before killing:
- `harness/.agents/skills/dispatch-ticket/WATCHING.md:102` — Every alert fires once per episode, for panes without the mod only. `STUCK` and

## `harness/.agents/skills/dispatch-ticket-claude/SKILL.md`

315 dòng. [Mở nguồn](../../harness/.agents/skills/dispatch-ticket-claude/SKILL.md).

- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:3` — description: "Claude Code-specific dispatch protocol. Covers the astragentic-dispatch mod (the pane records itself, runs its brief, reports its turn end), the launcher matrix, pre-dispatch verification, and Claude runtime facts. Read dispatch-ticket for the shared protocol."
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:9` — format, cleanup). This skill adds the Claude Code launcher and the mod that does the steps a
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:10` — dispatcher kept skipping. The mod `.claude/skills/astragentic-dispatch/` ships in the payload,
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:13` — / Step / What the mod does /
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:16` — / Deliver the slash command / **one SendMessage**; the pane runs the first line as a real command /
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:18` — / Watch the turn / the pane reports `TURN-END` when a turn ends with none of its agents still running, and wakes you with a prompt /
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:19` — / Route a pane's sends to you / the pane's overlay names your session; a SendMessage from it to any name no agent of its own carries (a peer Builder, a session in another project) goes to you instead, and the pane's status line says so /
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:20` — / Announce a newer release / at your session start the mod asks the package remote for its newest tag once and shows a chip on your band; `.astraler/astragentic.sh update` prints the gap and the one-liner. Applying stays the owner's call /
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:27` — / Record which flow steps ran / every Skill call the Builder makes, as the engine expands it; `TURN-END` carries the list and a merge names the steps with no record /
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:32` — floor the mod does not load and nothing else watches the pane.
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:33` — - **The tab label is set before launch.** The mod reads `ticket:` / `spec:` / `qa:` from its tab
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:35` — - **The mod is committed on the branch the worktree checks out.** The pane loads the copy in its
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:40` — STOP, because a pane the mod does not know about is unwatched.
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:42` — ## Submitting: one SendMessage
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:45` — SendMessage({
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:53` — `disable-model-invocation` skill. The pane's mod runs the first line through `$.command.run`.
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:54` — Steering is a plain SendMessage too: to an idle pane it becomes a user turn, to a mid-turn
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:58` — second copy of something the mod does. The shared protocol's `herdr agent prompt` is for a pane
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:59` — without the mod (a QA gate pane, a junior pane).
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:64` — - **`TURN-END`** arrives as a prompt: *"builder ABC-123 ended its turn (answer). Its last
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:69` — *N agent(s) still running, turn end held*, and the one TURN-END comes when nothing is live.
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:70` — The hold has a ceiling of 20 minutes: past it your mod rings once with
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:80` — - **A TURN-END the pane could not send still arrives from the record within 30 s**, marked
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:92` — - **`AskUserQuestion` is refused in a dispatched pane.** The model decides from its evidence or
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:103` — / `overlays/dispatch-brief.md` / appended to every brief the mod sends /
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:123` — and the ui pass, by the record's `kind` the mod wrote at the send (`dispatch-ticket` § The kind); the
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:124` — built-in review stays owed at the arm and at merge. The mod reads it from the brief it delivers, never from the Builder's
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:125` — handback. A brief delivered outside the mod carries no exemption the mod can see, so on a
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:126` — pane prompted by hand the gate holds until the brief is re-sent through SendMessage.
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:130` — the owner and the journeys the spec realizes, and the mod reads the file from `HEAD` of the base
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:140` — the mod refuses a brief whose `QA:` mode is not `none` without one, or whose path does not
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:150` — the Builder's entry. Its brief carries `Mode: walk/probe/verify`, which the mod records and
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:155` — In any dispatched pane the mod refuses a Bash command whose wait is keyed on a process name
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:173` — - **`TURN-END` carries `Skills run: …`.**
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:176` — and the mod cannot read reasons. Any other gap is a step that did not run.
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:177` — - **Only a pane the mod registered is judged.** A junior pane has no `session_id` in its entry;
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:221` — ## What the mod cannot see
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:223` — - **A pane whose process died.** The mod dies with it; the workspace watchdog is what sees it
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:229` — - **A QA gate pane or a junior pane.** They run no Claude mod, so they keep the watcher script
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:233` — dispatcher side the mod consumes only its own marked messages whose key and pane match the
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:241` — launches `claude claude --agent …`, and the pane's first turn runs on the prompt "claude" with no
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:243` — dispatch", both as real bells). The dispatcher's mod refuses that launch.
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:251` — Model and effort come from the role's `orchestrator.md` row, never from memory. **A ticket
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:267` — flag makes the engine compact at 300k; the mod compacts a pane that ends a turn over the same
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:275` — only when the row's Advisor cell is set (pairing rules: `orchestrator.md`); a session that
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:281` — not committed or was gitignored; without the mod the pane runs but nothing records it,
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:285` — test -f <worktree-path>/.claude/agents/<role>.md // echo "STOP: adapter missing"
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:286` — test -f <worktree-path>/.claude/skills/astragentic-dispatch/hooks/register.tsx // echo "STOP: dispatch mod missing"
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:294` — herdr agent start "<role>-<ticket-id-lowercased>" --kind claude --pane <pane-id> --timeout 60000 \
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:301` — herdr agent start "<role>-<artifact-key-lowercased>" --kind claude --pane <pane-id> --timeout 60000 \
- `harness/.agents/skills/dispatch-ticket-claude/SKILL.md:311` — These describe how herdr reads a Claude pane. The mod does not depend on them; the watchdog

## `harness/.agents/skills/github-issue-tracker/SKILL.md`

187 dòng. [Mở nguồn](../../harness/.agents/skills/github-issue-tracker/SKILL.md).

Không khớp pattern phụ thuộc runtime; vẫn cần semantic review trước khi tái sử dụng.

## `harness/.agents/skills/github-issue-tracker/project-status-sync.sh`

99 dòng. [Mở nguồn](../../harness/.agents/skills/github-issue-tracker/project-status-sync.sh).

Không khớp pattern phụ thuộc runtime; vẫn cần semantic review trước khi tái sử dụng.

## `harness/.agents/skills/jira-issue-tracker/SKILL.md`

168 dòng. [Mở nguồn](../../harness/.agents/skills/jira-issue-tracker/SKILL.md).

- `harness/.agents/skills/jira-issue-tracker/SKILL.md:22` — the session-start counts and the dispatch mod; delete the old `unreachable` plugs, because a
- `harness/.agents/skills/jira-issue-tracker/SKILL.md:36` — **Never on a clock.** A 5.4 s count is longer than the band's 5 s plug budget; the mod reads it

## `harness/.agents/skills/linear-issue-tracker/SKILL.md`

120 dòng. [Mở nguồn](../../harness/.agents/skills/linear-issue-tracker/SKILL.md).

Không khớp pattern phụ thuộc runtime; vẫn cần semantic review trước khi tái sử dụng.

## `harness/.agents/skills/reconcile-tracker/SKILL.md`

175 dòng. [Mở nguồn](../../harness/.agents/skills/reconcile-tracker/SKILL.md).

Không khớp pattern phụ thuộc runtime; vẫn cần semantic review trước khi tái sử dụng.

## `harness/.agents/skills/test-design/SKILL.md`

85 dòng. [Mở nguồn](../../harness/.agents/skills/test-design/SKILL.md).

Không khớp pattern phụ thuộc runtime; vẫn cần semantic review trước khi tái sử dụng.

## `harness/.claude/skills/astragentic-dispatch/agents/astra-slice-reviewer.md`

39 dòng. [Mở nguồn](../../harness/.claude/skills/astragentic-dispatch/agents/astra-slice-reviewer.md).

Không khớp pattern phụ thuộc runtime; vẫn cần semantic review trước khi tái sử dụng.

## `harness/.claude/skills/astragentic-dispatch/agents/astra-test-architect.md`

39 dòng. [Mở nguồn](../../harness/.claude/skills/astragentic-dispatch/agents/astra-test-architect.md).

Không khớp pattern phụ thuộc runtime; vẫn cần semantic review trước khi tái sử dụng.

## `harness/.claude/skills/astragentic-dispatch/agents/astra-ui-lens.md`

49 dòng. [Mở nguồn](../../harness/.claude/skills/astragentic-dispatch/agents/astra-ui-lens.md).

Không khớp pattern phụ thuộc runtime; vẫn cần semantic review trước khi tái sử dụng.

## `prompts/adoption-skills/batch-triage/SKILL.md`

76 dòng. [Mở nguồn](../../prompts/adoption-skills/batch-triage/SKILL.md).

Không khớp pattern phụ thuộc runtime; vẫn cần semantic review trước khi tái sử dụng.

## `prompts/adoption-skills/bootstrap-glossary/SKILL.md`

125 dòng. [Mở nguồn](../../prompts/adoption-skills/bootstrap-glossary/SKILL.md).

Không khớp pattern phụ thuộc runtime; vẫn cần semantic review trước khi tái sử dụng.

