# Recurring Failure Modes

Status: current · carried into 1.0.0 unchanged · 34 entries (FW-001 … FW-034)

Practical AI-agent failure modes measured while operating this harness. They are the
evidence base: a rule kept in this package can point at an entry here, and a rule that
cannot is a rule to re-examine. Advisory memory — code, docs and ADRs are stronger truth,
and where an entry conflicts with current code the source of truth wins.

**This file is append-only.** Existing entries keep their text and their numbers, IDs are
never reused, and a lesson that later proved wrong is marked `superseded` or `reverted` in
place rather than edited away. That is what lets an entry be cited as evidence years later.

**Format:** each entry is the lesson plus its binding surface, a few lines. Fuller incident
narratives live in git history (`git log -p` this file). `FW-*` = framework class,
`FM-*` = product class. Status: `open → proposed → promoted → closed`, or `superseded` /
`reverted`.

**The `Bound:` pointers are historical.** They name the surface an entry was promoted into
at the time, and many of those files were retired when 1.0.0 rebuilt the method around the
`mattpocock-skills` plugin. Read them as provenance rather than as live links — which is
also why the staleness audit excludes this file from its fossil scan.

---

## Product failure modes (FM-*)

> None recorded yet. First one: class `product`, promote the guardrail into `docs/SYSTEM.md`.

---

## Framework failure modes (FW-*)

### FW-001 — Gate wired to a fix tool, not a review tool · promoted 2026-06-28
Review ≠ rescue: the gate runs a real diff **review**, never `/codex:rescue`.
Bound: working-method §4, rules §3.

### FW-002 — A prose link does not guarantee load · promoted 2026-06-28
Always-required context must be a bare `@`-import in `CLAUDE.md` (loads by construction);
task docs stay router-loaded (`docs/INDEX.md`). Bound: CLAUDE.md structure.

### FW-003 — No lessons ledger existed · promoted 2026-06-28
This file + the framework-change loop (now rules §7). Bound: rules §7.

### FW-004 — Process decisions routed to ADRs · promoted 2026-06-29
Durable process/framework decisions live in the owning governance doc; ADRs stay
product/architecture. Bound: rules §2.

### FW-005 — Entry-doc rewrite silently dropped unique content · promoted 2026-06-29
When rewriting an always-loaded entry-doc shorter, diff old vs new for unique lines and
re-home anything not covered by the imported targets, BEFORE the gate. Bound:
working-method §2 (navigation freshness).

### FW-006 — `fork` delegation inherited Opus, ignored the model ladder · promoted 2026-06-29
Implementation delegation = fresh subagent + explicit `model: sonnet` + self-contained
brief; `fork` (parent model) only when context inheritance is the bottleneck. Bound:
working-method §5.

### FW-007 — Long-lived branch + oversized PR outran the gate · promoted 2026-07-01
9 non-converging review passes over a 255-file diff. One slice → one short-lived branch →
one PR sized to converge in one/few passes; a non-converging gate = too-big diff, split —
not a backlog to grind. Bound: working-method §2, rules §3.

### FW-008 — Docs cited a retired skill collection · promoted 2026-07-02
Cite only routes that actually run; verify a path exists before citing. Bound: rules §2.

### FW-009 — No UI-prototype phase before Build · promoted 2026-07-02
Customer-facing surfaces get a cheap mockup + stakeholder review before build spend.
Bound: working-method §3 (Prototype row).

### FW-010 — Worktree delegation hygiene undocumented · promoted 2026-07-02
Superseded in scope by FW-016 (isolation became unconditional). Committed base, one agent
per worktree. Bound: `.claude/rules/agent-worktree-isolation.md`.

### FW-011 — Gate was per-PR only, not per-step · promoted 2026-07-02 · **superseded 2026-07-16**
Its fix ("gate every step") over-corrected into continuous Codex loops that stalled
delivery. Superseded by the **Codex end-of-phase rule** (rules §3, owner 2026-07-16): ONE
adversarial pass at plan END + ONE review at review END; Claude carries the in-loop review.
The surviving core: no plan goes to build ungated.

### FW-012 — Two review rounds not stated as both-mandatory · promoted 2026-07-02 · **superseded 2026-07-16**
Its "re-gate both lenses to clean" loop is superseded by the Codex end-of-phase rule
(rules §3). The surviving core: cross-vendor and same-vendor lenses catch DIFFERENT defect
classes (proven by FW-015) — both still exist, once each, at the right points: Claude
in-loop (Dan self-gate + Rin independent) + ONE Codex at review END.

### FW-013 — Ad-hoc build delegation; false tooling-gap assumed · superseded by FW-019/FW-026
Surviving lesson: **verify tooling by inspecting the filesystem before claiming a
capability gap** — never scope down a port on an assumption.

### FW-014 — Multi-slice rebuild needs a gated integration branch · promoted 2026-07-11 · epic-specific
Pre-launch rebuild whose slices individually break `main`: gated integration branch,
per-slice gates + one holistic train gate (hub-v2 pattern). Historical; propose CLOSE.

### FW-015 — Export step committed live secrets + buyer PII · promoted 2026-07-11
Same-vendor correctness review PASSED it; cross-vendor caught it (P1) — the two lenses
catch different classes. A value that touched a tracked file is burned — rotate it.
Bound: `.claude/rules/no-secrets-in-exports.md` (always-on). CI secret-scan still TODO.

### FW-016 — Agents sharing one checkout moved HEAD under each other · promoted 2026-07-11
Includes a READ-ONLY reviewer that `git switch`ed the PM's HEAD. Worktree isolation is
UNCONDITIONAL for every spawned agent that can run state-changing git; PM re-asserts its
branch each turn + verifies reflog after each agent. Bound:
`.claude/rules/agent-worktree-isolation.md` (always-on).

### FW-017 — Per-package typecheck missed a cross-package break · promoted 2026-07-11
Gate evidence = repo-root `pnpm -r typecheck` + `pnpm -r test`; per-package green is not
whole-repo green. Bound (machine): `.github/workflows/ci.yml`.

### FW-018 — Dispatch emitted as text, never executed; no liveness signal · promoted 2026-07-11
Dispatch-is-not-done-until-observed: verify every delegation by its observable effect
(agent appears in `herdr agent list` / branch moves) in the same turn; narrating a tool
call is not calling it. Bound: `.claude/agents/thomas-leader.md` (orchestration §) +
`scripts/herdr-watch-terminal.sh` (FW-022 watcher).

### FW-019 — Implementer subagent retired; independence moved to the PR · promoted 2026-07-12 · dispatch superseded by FW-026
The in-session build subagent cost more than it returned. Surviving core: branch → PR →
review always; plan gate before build; `/simplify` before PR. Bound:
`.claude/rules/build-loop-gates.md`.

### FW-020 — Plugin review commands invisible → rescue used as review; raw exec hung · promoted 2026-07-12
`disable-model-invocation` commands don't appear in the skill list — absence there is NOT
evidence of absence; inspect the plugin cache. Gates run the plugin runtime
(`codex-companion.mjs`); raw `codex exec` fallback-only; review ≠ rescue. Bound:
working-method §4, build-loop-gates.

### FW-021 — Gate workflows blocked on owner presence · promoted 2026-07-13
grilling/to-spec/to-tickets/wayfinder are agent-operated (owner-proxy), escalate only
genuine owner-scale decisions; a skill's own "this decision is mine" marker = escalate
signal; decisions recorded in the issue/ADR for after-the-fact veto. Bound:
working-method §3a.

### FW-022 — A filesystem-only tool was invisible to agents · promoted 2026-07-13
A shared operational tool needs a pointer in a doc an agent is GUARANTEED to load
(`AGENTS.md` @-import or `.claude/rules/`), with full path/args/exit codes; tool + every
doc pointer change in the same commit. Bound: `AGENTS.md` (watcher bullet) +
`.claude/agents/thomas-leader.md` (full herdr-watch doctrine; ex-`THOMAS.md`, folded
2026-07-16). Watcher semantics: bell not verdict — verify by artifact; `done` mis-fires
when the worker spawns sub-agents; real end-signal = artifact progress.

### FW-023 — "Main session builds directly" conflated two mechanisms · promoted 2026-07-15 · dispatch superseded by FW-026
The orchestrator does NOT hand-write product slices; the build runs in an isolated
dev-role session. Gate-independence guarantee UNCHANGED across supersessions. The
"Worker" name survives only in this ledger — the dev role is `dan-implementor.md`.

### FW-024 — Role rule auto-loads into every session → role-bleed (Worker acted as Thomas) · promoted 2026-07-16
"Auto-loaded" ≠ "I am Thomas". Role adoption is gated by an explicit, exhaustive,
ordered self-check keyed on **spawn designation** (system prompt / subagent_type), never
prompt content, never `HERDR_ENV` (diagnostic only); fail-closed STOP on mislaunch.
Bound: `.claude/rules/role-thomas.md`.

### FW-025 — Gate-able conventions parked in the always-on rule tier tax every loop · proposed 2026-07-16 (PARKED debt)
The always-on `.claude/rules/` tier is for un-gate-able safety invariants; a convention a
PR gate can catch lives in its SoT doc + the gate rubric. Retirement precondition: every
invariant the rule carried must be live in the wired gate FIRST, same commit
(`dashboard-tables.md` → rubric §A.6/§B.5/§B.6 with L1/L2 wiring; `seller-visual-first.md`
additionally waits for Phase-2 Extension coverage — it spans both surfaces). Owner PARKED
the gate-wiring work — do not retire either rule until it lands. Target binding when
promoted: rules §7 (promote ladder note).
Counter-measurement added 2026-08-07 (FW-034, no text above changed): this entry's premise is
that a PR gate catches the convention, so the rule tier need not carry it. Measured otherwise
— the simplify pass was gate-able, was in its SoT doc, and was still skipped through five
consecutive gate rounds. FW-034 therefore places it in the always-on tier, knowingly taking
on the loop tax parked here. Re-derive that placement when this entry's gate-wiring lands.

### FW-026 — Named-persona harness: Thomas / Dan / Rin · promoted 2026-07-17 (merged to main)
Owner brief: way-of-working as named employees; a name routes work + loads the right
contract without role-bleed. **Verified facts (do NOT re-verify):** `claude --agent <name>`
= that agent file as system prompt, but CLAUDE.md/rules STILL load additively (NOT
isolated) → Dan needs the self-check; an Agent-tool subagent IS isolated → Rin needs none;
no built-in env var exposes the agent name; Agent Teams = experimental, parked.
Identity = observable spawn designation (fail-closed STOP); dispatch-mechanism changes
re-bind EVERY governance surface in the same slice (see
`.scratch/harness/personas/BINDING-INVENTORY.md`). ACCEPTED RESIDUAL RISK (owner, option
B): forgot-`--agent` mislaunch is soft-guarded only (fixed launch script + self-check
STOP). Bound: `.claude/agents/thomas-leader.md` / `dan-implementor.md` /
`rin-pr-reviewer.md`, `.claude/rules/role-thomas.md` / `build-loop-gates.md` /
`agent-worktree-isolation.md`, working-method §3–§5, rules §3, `AGENTS.md`, truth-model §2.
actual-outcome: _pending — at next self-audit confirm: a Dan pane resolves to Dan (no
re-dispatch), Rin resolves to Rin, Thomas verifies by artifact, no doc still mandates the
old worker dispatch._

### FW-027 — TWO ROOT sessions shared the main checkout; one switched branches under the other · promoted 2026-07-17
Live incident: the product-Thomas session (epic 55) ran `git switch plan/…` in the shared
main checkout while the harness-builder session was committing — three harness commits
landed on the OTHER session's plan branch, then vanished from `main` when it switched back
and pulled (also polluting that plan branch's gate diff). FW-016 only bound SPAWNED agents;
two ROOT sessions in one checkout were unregulated. Lesson: **one checkout, one driver —
at any moment at most ONE root session treats the main checkout as its working copy; any
concurrent second root session (e.g. harness maintenance beside a product Thomas) works in
its OWN worktree/branch and merges via the normal flow.** Also: EVERY session re-verifies
`git branch --show-current` before each commit (a switch can happen between turns).
Recovery pattern proven: lost commits stay in the object store — `git reflog` +
`git branch --contains <sha>` find them; re-apply on current main. Second live incident
same day: a detached-SHA checkout by the other session made `.claude/agents/*` files
vanish mid-turn. Bound: `.claude/rules/agent-worktree-isolation.md` (owner delegated the
promote decision to Thomas 2026-07-17).

### FW-028 — Relative worktree path + unverified pane cwd → worktree born in the wrong place, hour-long misdiagnosis · promoted 2026-07-30
Live incident (in a deployed project, 2026-07-30): the dispatching session's shell was
still standing in an app subdirectory (left over from an earlier export step), so a
RELATIVE `git worktree add ../<name>-worktrees/…` resolved against that stale cwd and
created the worktree INSIDE the repo — while the path handed to the Herdr pane did not
exist. Domino: `cd` in the pane failed → `claude` started from `$HOME` → agent definition
not found → the session concluded "input isn't reaching the pane / Herdr is hung" and
misdiagnosed for an hour. Two aggravators: briefs were pushed via split
`send-text`+`send-keys` (drops input; `pane run`/`agent prompt` are the standard), and an
outdated local herdr CLI lacked a documented subcommand, reinforcing the false "app is
broken" theory. Root cause was ONE error: no path/cwd verification floor. Lesson:
**worktree paths are absolute and convention-bound
(`<repo-parent>/<repo-dir-name>.worktrees/<branch-slug>`), `git worktree list` verifies
every add, and no agent is launched or briefed in a pane whose `foreground_cwd` was not
verified against the worktree — a mismatch is STOP, and a "missing" herdr subcommand
means check `herdr --version` first.** Bound:
`.claude/rules/agent-worktree-isolation.md` (Location & naming + verification floor),
`.agents/skills/dispatch-dan/SKILL.md`.

### FW-029 — Slice finished but Dan tabs survived; `/clear` blurred context and checkout lifecycle · promoted 2026-08-02
Observed harness friction: dispatch created a new workspace and then another tab even
though the workspace already owned an initial tab/pane; after work completed, cleanup
removed only the Git worktree/branch and never named Herdr tab/pane retirement. Repeated
dispatches therefore accumulated indistinguishable `dan-implementor` terminals. The
Thomas contract also said “new slice to the same pane → `/clear`” without rebinding or
verifying cwd/worktree; `/clear` starts a fresh chat but does not change the process cwd,
branch, worktree, or lifecycle ownership. This made it impossible to tell from topology
alone whether multiple Dan windows represented independent active tasks or orphaned
sessions. Lesson: **one active slice owns one fresh `dan:<slice-key>` session/tab,
worktree/branch, and PR; parallel slices share none; sequential slices may share only the
project/epic workspace. `/compact` stays within a slice after a durable checkpoint;
`/clear` is never cross-slice reuse. Thomas captures the final artifact, verifies
merge/approved abandonment, then closes the exact Dan tab when another tab remains or the
root-managed workspace when Dan is last (Herdr 0.7.5 cannot close a last tab); workspace
ownership persists across parallel slices and never depends on which slice finishes last.
Only then does Git cleanup run. Any survivor records owner, reason, and next action.** Bound:
`.agents/skills/dispatch-dan/SKILL.md`, `.agents/roles/dan-implementor.md`,
`.astraler/AGENTS.harness.md`, `.claude/rules/agent-worktree-isolation.md`,
`.claude/agents/thomas-leader.md`, working-method §3/§5/§7, rules §3.

### FW-030 — Orchestrator row named a runtime with no dispatch path for the role; Rin went undispatchable · promoted 2026-08-02
(incident from the origin project) Rin's Active row was tuned from `claude/opus` to a
codex model. On a Claude root Rin's ONLY dispatch path is the Agent tool
(`subagent_type: "rin-reviewer"` + `isolation: "worktree"`), whose `model` parameter
accepts Claude models only — and no `.codex/profiles/rin-reviewer.config.toml` exists.
The row was syntactically valid and semantically dead: the sole independent gate could
not be dispatched at all. The project's end-of-phase Codex gate caught it (its fourth
catch) and the row was reverted. Lesson: **(a) a role's row is executable only through
that role's real dispatch path on the current root — Rin's Runtime must match the root
runtime (Claude root → claude row via the Agent tool; Codex root →
`.codex/agents/rin-reviewer.toml`; opencode root → `.opencode/agents/rin-reviewer.md`);
Rin's cross-VENDOR coverage comes from its gate arm, never from the Runtime cell; moving
a role to another runtime is a role-contract change (new dispatch path +
adapter/profile), not a row tune. (b) Resolution is by TABLE, not improvisation:
dispatch always uses the Active row; the Fallback row is consulted only on degradation
or an explicit `runtime=` override; a fallback naming a runtime with no dispatch path
(or duplicating the active runtime) means that role has NO fallback — STOP and ask the
owner, never invent a model ID.** Bound: `.agents/orchestrator.md` (header),
`.agents/skills/dispatch-slice/SKILL.md`, `.claude/skills/review-with-rin/SKILL.md`.

### FW-031 — A prose instruction telling an agent to suppress its tool's own default is not a boundary · promoted 2026-08-03
Release 0.11.4 authorized Dan — the READ-ONLY slice lead — to invoke Claude Code's
built-in `/simplify`, whose own contract is "review the changed code THEN APPLY THE
FIXES", under the guard "invoke it WITH the instruction 'findings only, edit no files'".
Three things defeat that guard: the tool's instructions enter the agent's context and
compete with the role, the agent launches with permission prompts disabled so nothing
can refuse the write, and the release text itself conceded the skill "will push against
your role once loaded". The one-writer invariant (FW-026) was left resting on a model
choosing to honour a sentence, and the formative reviewer would have become an author. A
consuming project's cross-vendor adaptation gate caught it before any slice ran on the
release. Lesson: **a natural-language instruction to suppress a tool's default behaviour
is NOT a boundary — the tool's contract and the agent's permissions win. A role
forbidden from an action must never be handed a tool CAPABLE of that action; give the
action to the role that is allowed to perform it and let the forbidden role review the
result.** Scope honestly: where the forbidden role legitimately needs broad capability
(Dan MUST run typecheck/tests/build, all of which write), the enforceable line is the
tool's PURPOSE, not raw capability — do not sell a purpose boundary as a sandbox. Bound:
`.agents/roles/dan-senior.md` (step 4), `.claude/agents/dan-senior.md`.

### FW-032 — A signal that cannot fail is not evidence · promoted 2026-08-05
A consuming project ran two real product slices through the framework and hit the same
shape seven times in one session, each time in a different costume. The watcher script
was invoked as `watch.sh <pane> | tail -3`, and a pipeline returns the LAST command's
status, so it reported success whether the watcher reached a terminal state or never
started. A DEAD opencode process still answered `interactive_ready: true` for at least
one poll interval. `go test -run <pattern>` with a pattern that matched NOTHING printed
"no tests to run" and exited 0 — a green that meant nothing, which nearly got a working
test reported as broken. Subagents reported `idle`/`available` three separate times
WITHOUT having sent their result (each had written its report and simply not handed it
back), so reacting to idle either re-tasks a finished agent or banks work that was never
delivered. A background task reported `killed` was read as `completed`. `caffeinate` was
killed while the child process it wrapped survived orphaned — a cleanup command that RAN
is not a cleanup that WORKED. And three times a fix was recorded as "folded" in a summary
table while the body text was untouched; the reviewer caught all three only by grepping
the body and refusing to read the summary table as evidence. Lesson: **a signal is
evidence only if it was CAPABLE of saying no. Before trusting one, ask what it would have
looked like had the thing failed — if the answer is "the same", it is decoration, not
proof. Never place a command whose exit status IS the signal anywhere that status gets
replaced — a pipe always replaces it, `|| rhs` replaces it EXACTLY WHEN THE COMMAND FAILS
(so `cmd || true` erases the only failure you needed to hear about), and `$(…)` replaces it
outside a bare assignment, while `&& rhs` is safe on failure and only overwrites a success;
never accept a status field over
the artifact it claims to describe; and verify against the artifact itself, never against
an author's account of the artifact.** Corollary for reviewers: a filtered or scoped
check must report WHAT IT ACTUALLY EXAMINED, not merely that it passed. The harness's own
watcher is an instance: it re-execs under `caffeinate`, so `caffeinate` becomes the visible
PID and `kill <that pid>` leaves the wrapped shell orphaned and still polling (verified
locally 2026-08-05 — the child survived the parent's death). The whole watch shares one
process group, so `kill -TERM -<pgid>` and then re-check for survivors: a cleanup command
that RAN is not a cleanup that WORKED. Another instance, and the reason this repo keeps a
hand-rolled start guard: herdr's `events.wait` is LEVEL-triggered, and was measured
matching a STALE `idle` in 0 ms on a pane untouched for hours — there is no edge-triggered
wait in the API (`state_change_seq` exists on `AgentInfo`, but no method accepts it), so a
wait that returns instantly proves nothing about the turn you just submitted. The purest
instance yet, measured on herdr 0.8.0: **opencode's `idle` is FABRICATED.** `agent explain`
on an opencode pane reports `state: idle · rule: none · fallback_reason:
default_known_agent_idle_fallback`, and `agent wait --until idle` returned rc=0 in 8 ms on
a pane nobody had touched. Its manifest carries 3 rules (claude 12, codex 7) covering only
`blocked` and `working`; NOTHING establishes idle, so idle is merely what is left when no
rule matches — a state that cannot say no, and the mechanism behind the earlier
observation that a dead opencode process still reported `interactive_ready: true`. Claude
is better but not clean: `prompt_box_body` (priority 950) matches on the evidence `"❯\n"`,
so an EMPTY COMPOSER reads as idle. Consequence: **detection quality is a per-runtime
property that must be checked, not assumed, and where a state has no rule behind it,
verify-by-artifact is the only instrument that works.** The law has a
MIRROR, and this release shipped an instance of it inside its own remedy: the survivor check
`ps -eo pid,pgid,command | grep herdr-watch-terminal` matches its own command line, so it
can never return empty — a VERIFICATION step incapable of passing is as worthless as a
signal incapable of failing. Ask of any check what a pass and a fail each look like; if
either is impossible, it is decoration (`pgrep -f` / `grep '[h]erdr-…'` fix this one). A
corollary runs the other way: when a signal misbehaves, prefer the mundane cause already
known over a new theory — an invented mechanism is itself an unfalsifiable claim. Bound:
`scripts/herdr-watch-terminal.sh`, `.claude/agents/thomas-leader.md` (herdr judgment
items 1 and 4), `.claude/agents/dan-senior.md`, `.agents/roles/dan-senior.md` (duty 3),
`.claude/agents/rin-reviewer.md` (Tests checklist + report contract),
`.agents/skills/dispatch-slice/SKILL.md` (brief/watch/steer), `docs/governance/rules.md`
§2, `templates/AGENTS.md.template`.

### FW-033 — A lookup whose question has no referent at one of its call sites · promoted 2026-08-06
Release 0.12.0 replaced a discretionary choice of Rin's dispatch form with a LOOKUP, on the
correct instinct that a rule two dispatchers can evaluate identically beats a judgement
call. The question it asked was *"is there a live `slice:<slice-key>` tab in this herdr
session?"* — written for the CODE-REVIEW gate, where a slice tab exists by definition. At
the PLAN gate there is no such tab, because a plan is gated BEFORE its slice is dispatched
(the harness's own rule is that no plan builds ungated). The question therefore had no
referent there and resolved to "no" every single time, silently making every plan gate the
unobservable form — at the one milestone where design decisions are actually made. A
consuming project ran three consecutive plan gates invisibly, with owner-scale calls made
inside them, before anyone found the cause; the same file said "never invent a slice key
for a plan gate" three lines above the question keyed to that very key. Lesson: **a lookup
is only better than a judgement if its question has a referent at EVERY call site. Enumerate
the call sites and evaluate the question at each one before shipping it — a rule that is
mechanically evaluable but wrong is worse than a judgement call, because it is confidently
wrong every time and nobody re-examines it.** Corollary for reviewers: when a rule is
tightened from discretion to a test, the review question is not "is this test objective"
but "what does this test RETURN in each situation it governs". Bound:
`.claude/skills/review-with-rin/SKILL.md` §2, `.agents/skills/dispatch-slice/SKILL.md`
(rin-reviewer row), `.claude/agents/rin-reviewer.md`, `.claude/rules/build-loop-gates.md`.

### FW-034 — A mandatory rule that lives only in load-on-demand docs is skipped, and only the owner notices · promoted 2026-08-07
The simplify pass had been mandatory since the harness began — written into
`working-method.md` and into both role contracts. In a consuming project it was **skipped
through five consecutive gate rounds**, and the **OWNER** caught it: not the orchestrator,
not the lead, and not eight independent same-vendor review rounds. Nobody ignored it. It was
invisible, because it appeared in neither of the two surfaces an orchestrator actually reads
while running a slice — the always-on rule tier and the dispatch checklist. Lesson: **a rule
that is not present where it must be remembered does not exist.** Presence in the SoT doc
establishes what is true; it does not establish that anyone will see it at the moment of
action. For any rule whose skip is silent, place it on the surface read at the moment it
must fire, AND give a downstream reader a question that makes the skip audible — the PR
checklist now asks whether the pass RAN, **checking the ARTIFACT, not the record**, and an
unrun pass is a FINDING.
Second lesson, found by the cross-vendor pass on the follow-up release and worth more than the
first: **"check the ARTIFACT, not the record" is itself unenforceable until the artifact is
NAMED.** As first written, 0.13.0 told the gate not to trust self-report and then gave it
nothing else to look at — and because an empty clean pass is legitimate, a pass that ran and
found nothing left a tree IDENTICAL to a pass that was skipped. The requirement was
un-evaluable at exactly the moment it mattered. Fixed by making every run land a marker commit,
`--allow-empty` when it finds nothing, so `git log --grep` separates "ran, clean" from "never
ran". Generalize: **an anti-self-report rule must name a mechanically checkable artifact, and
that artifact must be produced by the NEGATIVE outcome too — otherwise it only detects the
loud failures and stays blind to the silent one it was written for.**
Third lesson, from the CONFIRMATION round of that same cross-vendor pass — the fix's own
first draft was defective: it gave the per-increment pass and the whole-slice pass ONE shared
`simplify:` prefix, so the first increment's marker satisfied the gate's check for a
whole-slice pass that never ran. A false green, built into the very mechanism written to stop
false greens. Hence the split prefixes `simplify(increment):` and `simplify(slice):`.
Generalize: **when one marker is made to stand for two different obligations, satisfying the
cheap one discharges the expensive one.** Distinguish the marker per obligation, and check
the counts, not merely presence.
Accepted limitation, recorded rather than papered over: a marker proves the pass was
CLAIMED at a point where claiming costs a deliberate act — it cannot prove the lens was
genuinely applied, and `--allow-empty` can be typed by anyone. That is the same standard the
rest of this harness runs on (a gate report can be written without reading, too). Its job is
to make a SKIP visible, not to prove diligence; the honest ceiling for a judgement pass is a
second reader, which is why `dan-senior.md` §4a reviews the pass as its own diff.
Second, independent measurement from the same incident: when the pass finally ran, on a
**68-file** slice diff, it edited **ONE file** and missed a helper declared **three times
inside a single package**, two files from the one it opened; the reviewer found that, not the
pass. **The lens does not scale to a diff that large** — hence the per-increment cadence in
`james-dev.md` §4b, where the diff is small enough for the lens to see all of it.
Corollary, from this package's own 0.13.0 release: the release that fixed this shipped
straight to `main` from a consuming-project session with no branch, no PR, and no
cross-vendor pass — skipping the very review it was written to protect. Three defects
survived that a second pair of eyes catches cheaply (a README stating the pre-0.13.0 form of
the same law, this missing entry, and the FW-025 tension below). **The author of a rule is
the worst-placed person to notice they are exempting themselves from it.**
Tension to hold, not resolve: this promotion puts a gate-able convention INTO the always-on
rule tier, which is exactly the cost **FW-025** parks. Accepted deliberately — FW-025's
premise is that a PR gate WILL catch the convention, and the five skipped rounds are the
measurement that it did not. When FW-025's gate-wiring work lands, re-derive this placement
rather than inheriting it.
Bound: `.claude/rules/build-loop-gates.md`, `.agents/roles/james-dev.md` §4b,
`.agents/roles/dan-senior.md` §4a, `docs/governance/working-method.md` (PR checklist
"Reuse/simplify"), `.agents/skills/dispatch-slice/SKILL.md`.
