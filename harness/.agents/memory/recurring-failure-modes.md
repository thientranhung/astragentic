# Recurring Failure Modes

Status: current · 75 entries (AST-001 … AST-076, 067 withdrawn) · AST-001…034 carried into 1.0.0 unchanged

Both numbers above are checked by `docs-staleness-audit.sh` AXIS 5 against `^### AST-` in this
file. It sat at "50 entries (AST-001 … AST-050)" while the file held 66, for sixteen entries,
because the axis compared README's count to the ledger and never read the ledger's claim about
itself. A file that is the evidence base for every rule here is the last place a self-reported
number should go unchecked.

Practical AI-agent failure modes measured while operating this harness. They are the
evidence base: a rule kept in this package can point at an entry here, and a rule that
cannot is a rule to re-examine. Advisory memory — code, docs and ADRs are stronger truth,
and where an entry conflicts with current code the source of truth wins.

**This file is append-only.** Existing entries keep their text and their numbers, IDs are
never reused, and a lesson that later proved wrong is marked `superseded` or `reverted` in
place rather than edited away. That is what lets an entry be cited as evidence years later.

**Format:** each entry is the lesson plus its binding surface, a few lines. Fuller incident
narratives live in git history (`git log -p` this file). `AST-*` = a harness lesson; a project's
own ledger keeps its own prefix. Status: `open → proposed → promoted → closed`, or `superseded` /
`reverted`.

**These IDs were `FW-0xx` until 1.1.0 and are now `AST-0xx`.** The number is unchanged —
`AST-032` is the entry that was `FW-032` — so every citation still names the same lesson.
The prefix moved because `FW-` was already in use by the projects this harness installs
into: one measured repo carried six IDs meaning different things in the two ledgers across
235 citations, and the only thing separating them was a paragraph a reader had to know
existed. **A namespace has to be unambiguous where it is minted, not routed by prose at
every read site.** Projects keep `FW-`; the harness owns `AST-`.

**The `Bound:` pointers are historical.** They name the surface an entry was promoted into
at the time, and many of those files were retired when 1.0.0 rebuilt the method around the
`mattpocock-skills` plugin. Read them as provenance rather than as live links — which is
also why the staleness audit excludes this file from its fossil scan.

---

## Product failure modes (FM-*)

> None recorded yet. First one: class `product`, promote the guardrail into `docs/SYSTEM.md`.

---

## Framework failure modes (AST-*)

### AST-001 — Gate wired to a fix tool, not a review tool · promoted 2026-06-28
Review ≠ rescue: the gate runs a real diff **review**, never `/codex:rescue`.
Bound: working-method §4, rules §3.

### AST-002 — A prose link does not guarantee load · promoted 2026-06-28
Always-required context must be a bare `@`-import in `CLAUDE.md` (loads by construction);
task docs stay router-loaded (`docs/INDEX.md`). Bound: CLAUDE.md structure.

### AST-003 — No lessons ledger existed · promoted 2026-06-28
This file + the framework-change loop (now rules §7). Bound: rules §7.

### AST-004 — Process decisions routed to ADRs · promoted 2026-06-29
Durable process/framework decisions live in the owning governance doc; ADRs stay
product/architecture. Bound: rules §2.

### AST-005 — Entry-doc rewrite silently dropped unique content · promoted 2026-06-29
When rewriting an always-loaded entry-doc shorter, diff old vs new for unique lines and
re-home anything not covered by the imported targets, BEFORE the gate. Bound:
working-method §2 (navigation freshness).

### AST-006 — `fork` delegation inherited Opus, ignored the model ladder · promoted 2026-06-29
Implementation delegation = fresh subagent + explicit `model: sonnet` + self-contained
brief; `fork` (parent model) only when context inheritance is the bottleneck. Bound:
working-method §5.

### AST-007 — Long-lived branch + oversized PR outran the gate · promoted 2026-07-01
9 non-converging review passes over a 255-file diff. One slice → one short-lived branch →
one PR sized to converge in one/few passes; a non-converging gate = too-big diff, split —
not a backlog to grind. Bound: working-method §2, rules §3.

### AST-008 — Docs cited a retired skill collection · promoted 2026-07-02
Cite only routes that actually run; verify a path exists before citing. Bound: rules §2.

### AST-009 — No UI-prototype phase before Build · promoted 2026-07-02
Customer-facing surfaces get a cheap mockup + stakeholder review before build spend.
Bound: working-method §3 (Prototype row).

### AST-010 — Worktree delegation hygiene undocumented · promoted 2026-07-02
Superseded in scope by AST-016 (isolation became unconditional). Committed base, one agent
per worktree. Bound: `.claude/rules/agent-worktree-isolation.md`.

### AST-011 — Gate was per-PR only, not per-step · promoted 2026-07-02 · **superseded 2026-07-16**
Its fix ("gate every step") over-corrected into continuous Codex loops that stalled
delivery. Superseded by the **Codex end-of-phase rule** (rules §3, owner 2026-07-16): ONE
adversarial pass at plan END + ONE review at review END; Claude carries the in-loop review.
The surviving core: no plan goes to build ungated.

### AST-012 — Two review rounds not stated as both-mandatory · promoted 2026-07-02 · **superseded 2026-07-16**
Its "re-gate both lenses to clean" loop is superseded by the Codex end-of-phase rule
(rules §3). The surviving core: cross-vendor and same-vendor lenses catch DIFFERENT defect
classes (proven by AST-015) — both still exist, once each, at the right points: Claude
in-loop (Dan self-gate + Rin independent) + ONE Codex at review END.

### AST-013 — Ad-hoc build delegation; false tooling-gap assumed · superseded by AST-019/AST-026
Surviving lesson: **verify tooling by inspecting the filesystem before claiming a
capability gap** — never scope down a port on an assumption.

### AST-014 — Multi-slice rebuild needs a gated integration branch · promoted 2026-07-11 · epic-specific
Pre-launch rebuild whose slices individually break `main`: gated integration branch,
per-slice gates + one holistic train gate (hub-v2 pattern). Historical; propose CLOSE.

### AST-015 — Export step committed live secrets + buyer PII · promoted 2026-07-11
Same-vendor correctness review PASSED it; cross-vendor caught it (P1) — the two lenses
catch different classes. A value that touched a tracked file is burned — rotate it.
Bound: `.claude/rules/no-secrets-in-exports.md` (always-on). CI secret-scan still TODO.

### AST-016 — Agents sharing one checkout moved HEAD under each other · promoted 2026-07-11
Includes a READ-ONLY reviewer that `git switch`ed the PM's HEAD. Worktree isolation is
UNCONDITIONAL for every spawned agent that can run state-changing git; PM re-asserts its
branch each turn + verifies reflog after each agent. Bound:
`.claude/rules/agent-worktree-isolation.md` (always-on).

### AST-017 — Per-package typecheck missed a cross-package break · promoted 2026-07-11
Gate evidence = repo-root `pnpm -r typecheck` + `pnpm -r test`; per-package green is not
whole-repo green. Bound (machine): `.github/workflows/ci.yml`.

### AST-018 — Dispatch emitted as text, never executed; no liveness signal · promoted 2026-07-11
Dispatch-is-not-done-until-observed: verify every delegation by its observable effect
(agent appears in `herdr agent list` / branch moves) in the same turn; narrating a tool
call is not calling it. Bound: `.claude/agents/thomas-leader.md` (orchestration §) +
`scripts/herdr-watch-terminal.sh` (AST-022 watcher).

### AST-019 — Implementer subagent retired; independence moved to the PR · promoted 2026-07-12 · dispatch superseded by AST-026
The in-session build subagent cost more than it returned. Surviving core: branch → PR →
review always; plan gate before build; `/simplify` before PR. Bound:
`.claude/rules/build-loop-gates.md`.

### AST-020 — Plugin review commands invisible → rescue used as review; raw exec hung · promoted 2026-07-12
`disable-model-invocation` commands don't appear in the skill list — absence there is NOT
evidence of absence; inspect the plugin cache. Gates run the plugin runtime
(`codex-companion.mjs`); raw `codex exec` fallback-only; review ≠ rescue. Bound:
working-method §4, build-loop-gates.

### AST-021 — Gate workflows blocked on owner presence · promoted 2026-07-13
grilling/to-spec/to-tickets/wayfinder are agent-operated (owner-proxy), escalate only
genuine owner-scale decisions; a skill's own "this decision is mine" marker = escalate
signal; decisions recorded in the issue/ADR for after-the-fact veto. Bound:
working-method §3a.

### AST-022 — A filesystem-only tool was invisible to agents · promoted 2026-07-13
A shared operational tool needs a pointer in a doc an agent is GUARANTEED to load
(`AGENTS.md` @-import or `.claude/rules/`), with full path/args/exit codes; tool + every
doc pointer change in the same commit. Bound: `AGENTS.md` (watcher bullet) +
`.claude/agents/thomas-leader.md` (full herdr-watch doctrine; ex-`THOMAS.md`, folded
2026-07-16). Watcher semantics: bell not verdict — verify by artifact; `done` mis-fires
when the worker spawns sub-agents; real end-signal = artifact progress.

### AST-023 — "Main session builds directly" conflated two mechanisms · promoted 2026-07-15 · dispatch superseded by AST-026
The orchestrator does NOT hand-write product slices; the build runs in an isolated
dev-role session. Gate-independence guarantee UNCHANGED across supersessions. The
"Worker" name survives only in this ledger — the dev role is `dan-implementor.md`.

### AST-024 — Role rule auto-loads into every session → role-bleed (Worker acted as Thomas) · promoted 2026-07-16
"Auto-loaded" ≠ "I am Thomas". Role adoption is gated by an explicit, exhaustive,
ordered self-check keyed on **spawn designation** (system prompt / subagent_type), never
prompt content, never `HERDR_ENV` (diagnostic only); fail-closed STOP on mislaunch.
Bound: `.claude/rules/role-thomas.md`.

### AST-025 — Gate-able conventions parked in the always-on rule tier tax every loop · proposed 2026-07-16 (PARKED debt)
The always-on `.claude/rules/` tier is for un-gate-able safety invariants; a convention a
PR gate can catch lives in its SoT doc + the gate rubric. Retirement precondition: every
invariant the rule carried must be live in the wired gate FIRST, same commit
(`dashboard-tables.md` → rubric §A.6/§B.5/§B.6 with L1/L2 wiring; `seller-visual-first.md`
additionally waits for Phase-2 Extension coverage — it spans both surfaces). Owner PARKED
the gate-wiring work — do not retire either rule until it lands. Target binding when
promoted: rules §7 (promote ladder note).
Counter-measurement added 2026-08-07 (AST-034, no text above changed): this entry's premise is
that a PR gate catches the convention, so the rule tier need not carry it. Measured otherwise
— the simplify pass was gate-able, was in its SoT doc, and was still skipped through five
consecutive gate rounds. AST-034 therefore places it in the always-on tier, knowingly taking
on the loop tax parked here. Re-derive that placement when this entry's gate-wiring lands.

### AST-026 — Named-persona harness: Thomas / Dan / Rin · promoted 2026-07-17 (merged to main)
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

### AST-027 — TWO ROOT sessions shared the main checkout; one switched branches under the other · promoted 2026-07-17
Live incident: the product-Thomas session (epic 55) ran `git switch plan/…` in the shared
main checkout while the harness-builder session was committing — three harness commits
landed on the OTHER session's plan branch, then vanished from `main` when it switched back
and pulled (also polluting that plan branch's gate diff). AST-016 only bound SPAWNED agents;
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

### AST-028 — Relative worktree path + unverified pane cwd → worktree born in the wrong place, hour-long misdiagnosis · promoted 2026-07-30
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

### AST-029 — Slice finished but Dan tabs survived; `/clear` blurred context and checkout lifecycle · promoted 2026-08-02
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

### AST-030 — Orchestrator row named a runtime with no dispatch path for the role; Rin went undispatchable · promoted 2026-08-02
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

### AST-031 — A prose instruction telling an agent to suppress its tool's own default is not a boundary · promoted 2026-08-03
Release 0.11.4 authorized Dan — the READ-ONLY slice lead — to invoke Claude Code's
built-in `/simplify`, whose own contract is "review the changed code THEN APPLY THE
FIXES", under the guard "invoke it WITH the instruction 'findings only, edit no files'".
Three things defeat that guard: the tool's instructions enter the agent's context and
compete with the role, the agent launches with permission prompts disabled so nothing
can refuse the write, and the release text itself conceded the skill "will push against
your role once loaded". The one-writer invariant (AST-026) was left resting on a model
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

### AST-032 — A signal that cannot fail is not evidence · promoted 2026-08-05
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

### AST-033 — A lookup whose question has no referent at one of its call sites · promoted 2026-08-06
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

### AST-034 — A mandatory rule that lives only in load-on-demand docs is skipped, and only the owner notices · promoted 2026-08-07
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
the same law, this missing entry, and the AST-025 tension below). **The author of a rule is
the worst-placed person to notice they are exempting themselves from it.**
Tension to hold, not resolve: this promotion puts a gate-able convention INTO the always-on
rule tier, which is exactly the cost **AST-025** parks. Accepted deliberately — AST-025's
premise is that a PR gate WILL catch the convention, and the five skipped rounds are the
measurement that it did not. When AST-025's gate-wiring work lands, re-derive this placement
rather than inheriting it.
Bound: `.claude/rules/build-loop-gates.md`, `.agents/roles/james-dev.md` §4b,
`.agents/roles/dan-senior.md` §4a, `docs/governance/working-method.md` (PR checklist
"Reuse/simplify"), `.agents/skills/dispatch-slice/SKILL.md`.

### AST-035 — `set -euo pipefail` plus a no-match `grep` aborts before its own guard · promoted 2026-08-10
Hit three times while building 1.0.0, in three separate scripts, each time wearing a
different costume. `uninstall.sh` printed half a manifest and exited 1 before reaching the
machine-local section, because `grep -rl … | wc -l` found no match: `grep` exits 1, and
under `pipefail` that status is the pipeline's, so `set -e` killed the script mid-report.
`check-requirements.sh` had the same shape. `gen-code-map.sh` exited 1 on a directory with
no source files and printed NOTHING — the `|| { echo "error: …"; exit 1; }` guard written to
explain exactly that case was three lines below the pipeline that aborted first.

The costume is what makes it recur: `grep` returning 1 is not an error, it is an ANSWER —
"none" — and it is the answer these pipelines are usually asking for. `wc -l` is downstream
and exits 0, so without `pipefail` the bug is invisible and with `pipefail` the script dies
somewhere the author never looks. **A guard placed after the pipeline it protects cannot
run.**

The fix is one shape, applied at the point of counting rather than to the whole script:
wrap the fallible producer, never relax the shell options —
`X=$( { grep … || true; } | wc -l )`. Relaxing `set -e` or dropping `pipefail` to make the
symptom go away re-opens AST-032, since `pipefail` is what makes a mid-pipeline failure
observable at all; these two entries pull in opposite directions and the wrap is what
satisfies both.

Cheapest detection: run every script's empty/zero-result path, not only its happy path. All
three defects were found that way and none by reading.
Bound: `harness/scripts/gen-code-map.sh`, `check-requirements.sh`,
`harness/scripts/docs-staleness-audit.sh`.

### AST-036 — A git worktree carries TRACKED content only · promoted 2026-08-10
First real installation of 1.0.0 into an existing repo. The project's `.gitignore` carried
`.agents/*`, so a Builder dispatched into its worktree would have found no
`.agents/roles/builder.md` — the exact file its adapter tells it to read first. It would have
started with no contract and no signal that anything was missing, which is worse than a
Builder that fails: it improvises, plausibly.

Allow-listing the paths was not enough. **Files must be COMMITTED**, because a worktree is
built from the index, so allow-listed-but-untracked is still invisible. That second half is
the part everyone believes is already done.

The general shape: **any mechanism that materializes a fresh checkout sees only what git
tracks.** Payload placed on disk by an installer is not payload the method can use.
Cheapest proof, and the only one that answers the question:
`git worktree add --detach /tmp/x HEAD && test -f /tmp/x/.agents/roles/builder.md`.
Bound: `dispatch-ticket` (payload-must-be-committed section), `check-requirements.sh`
(tracked-payload check), `prompts/ADAPT-HARNESS.md` §4.

### AST-037 — A multi-line prompt pastes without submitting, and the pane calls it idle · promoted 2026-08-10
`herdr pane run` and `agent prompt` both send text plus Enter, and both work on one line. A
MULTI-LINE block is pasted as a unit and the Enter is consumed by the paste: the transcript
shows `[Pasted text #1 +N lines]` sitting in an unsent composer. Every real dispatch brief is
multi-line, so this is the default case rather than an edge case.

It compounds with AST-032: the pane then reports **`idle`**, because an empty-looking composer
matches Claude's `prompt_box_body` rule. A dispatcher that trusts that status concludes the
agent finished instantly, and waits forever on work that never started.

Two-part fix, and the second part is what makes it detectable: send Enter explicitly after a
multi-line brief, then **require observing `working`** before believing the turn began.
Reaching `idle`/`done` without ever seeing `working` means it never ran.
Bound: `dispatch-ticket` (Submitting it).

### AST-038 — A checker that cannot tell project content from package content fires on every adopted repo · promoted 2026-08-10
`check-reachability.sh` globbed `.claude/skills/*/SKILL.md` and treated everything it found
as harness-owned. In the package that is true. In an adopted repo the project's own skills
sit in the same directory, so the checker reported four of them as unreachable defects and
one as naming unknown skills — six findings, none real, on a correct installation.

A gate that cries wolf on a correct install gets switched off, which costs more than the
gate was worth. The fix is to establish ownership from evidence rather than from location:
the staged release under `.astraler/releases/<applied>/harness/` is the authoritative
manifest of what the package shipped, and anything outside it belongs to the project and is
skipped — reported by name, so the skip is visible rather than silent.

The general shape: **tooling that ships INTO other repos must be able to name its own
files.** Location is not ownership.
Bound: `harness/scripts/check-reachability.sh`.

### AST-039 — An ID namespace shared with the host project resolves confidently to the wrong lesson · promoted 2026-08-10
The first upgrade into a mature repo landed a payload citing `AST-036` and `AST-037` beside a
project ledger that already owned `AST-034` and `AST-035` with unrelated meanings — ten IDs
collided in total, and the payload's most-cited lesson, `AST-032`, was one of them. The
project's entry doc routed every `FW-0xx` to its own ledger, so every citation this package
ships would have resolved there.

Nothing detected it. Every check passed: the reference existed, the file existed, the number
was well-formed. It was found by a human-style reading of the diff, which is the honest
lesson — **a checker verifies that a reference RESOLVES, not that it resolves to the thing
the author meant.**

Fix by location rather than by renumbering, which append-only forbids anyway: a citation
resolves in the ledger belonging to the material that carries it. Adaptation now detects a
colliding project ledger and records the rule in the project's own entry doc.
Bound: this file's preamble, `prompts/ADAPT-HARNESS.md` §3.

### AST-040 — A placeholder that looks like a real id fails later than a missing one · promoted 2026-08-11
The package shipped `model = "gpt-5.1-codex"` in all four Codex profiles. It resolves on no
account. It does not fail at install, at adaptation, or at any doctor run — the template and
the profile copied from it agreed perfectly. It fails at the first cross-vendor call, which
is **end of phase, when the work looks finished**, and it fails looking like the provider
being down rather than like a config error.

An empty field a doctor refuses is louder than a plausible wrong value nothing questions. So
ship no id: `model = ""` plus a comment naming where the real one comes from, and a doctor
that MISSes on empty. The general shape: **a default that cannot be right should not look
right.** Placeholders that pass validation are how a config error becomes an outage report.
Bound: `harness/.codex/profiles/*.config.toml`, `check-requirements.sh`.

### AST-041 — A file called "the owner's" that ships in the payload has two homes and the shipped one wins · promoted 2026-08-11
`.agents/orchestrator.md` opens with "This file is the owner's" and was nevertheless part of
the payload every release overwrites. A consuming repo had tuned it — three rows plus a
documented `## Owner decisions` section — and the only thing preventing loss was the
adaptation prompt telling an agent to preserve it, which is a habit rather than a mechanism.

Declaring ownership in prose while shipping a competing copy is not ownership. Scaffold and
payload are different categories: **a scaffold is written when absent and never overwritten**,
and where its shape must change the release reports the difference for the owner to merge.
The same applies to the Codex profiles, which carry the same owner-chosen values.
Bound: `harness/.agents/orchestrator.md`, `prompts/ADAPT-HARNESS.md` §3.

### AST-042 — Two skills answering to one name means the model-invoked path picks the wrong one · promoted 2026-08-11
`builder.md` told the Builder to run `code-review` and listed it as model-invoked craft. Two
skills answer to that name: the plugin's `mattpocock-skills:code-review`, which has the two
axes the contract describes, and the built-in `/code-review`, which takes different flags and
does something else. Slash invocation is unambiguous because the plugin namespaces its
commands; the model-invoked path is not.

The mirror case is worse: the contract mandated a `simplify` pass, the plugin ships no skill
by that name, and the built-in `/simplify` is what actually runs — stated nowhere. An agent
looking for a plugin skill that does not exist finds nothing and skips the pass silently.

**Name the qualified skill wherever a bare name is ambiguous**, and say which tool a mandated
pass actually is. Bound: `harness/.agents/roles/builder.md`.

### AST-043 — A gate that requires an artifact no contract produces · promoted 2026-08-11
`review-with-rin` §1(d) required the brief to carry "the Builder's browser-verify evidence".
`builder.md` did not contain the words browser, visual or screenshot — not once. The gate
asked for an artifact, named the role that owed it, and that role's contract never mentioned
producing it.

This is the failure ADR 0001 was written about, reproduced inside the package that exists to
prevent it: a step described in one document, owned by nobody in the contract that would run
it. A consuming repo shipped a visually-wrong control to main this way, and it was caught by
a human noticing, not by any gate.

`check-reachability.sh` does not catch this class. It verifies that every phase has an owner
and every reference resolves — not that **every artifact a gate demands has a producer**.
That is the harder check and it is not written. Until it is, a gate's input list is worth
reading against the contracts by hand whenever either changes.

The fix is the boring one: the contract that owes the artifact says so, and the gate treats
an unexplained absence as a finding rather than as nothing.
Bound: `harness/.agents/roles/builder.md`, `harness/.agents/roles/rin.md`,
`prompts/ADAPT-HARNESS.md` §5.

### AST-044 — Reading a diff cannot find a disagreement between two screens · promoted 2026-08-11
1.1.1 closed a gate that demanded browser evidence no contract produced, by giving the
Builder visual verification of its own change. That was the smaller half. A Builder confirms
its ticket renders; it cannot confirm the product still coheres, and it is the worst-placed
party to try — the same reason a reviewer exists for code.

The retired walker role in the prior package is the evidence. One read-only walk as a user
found: a 500 caused by a stale local seed **plus the production implication hiding behind
it**; a raw ISO timestamp on one page against humanised ones everywhere else; two screens
counting one concept and printing 85 versus 44; quick-tabs summing to 183 against a total of
190. Not one is visible in the diff that introduced it, because not one is *in* that diff —
each is a disagreement between the change and somewhere else.

A repo running without this shipped a visually-subordinate control to `main`; a linter caught
neither, because a linter finds a hard-coded colour and not a button nobody will press.

Kept as a MODE of the existing reviewer rather than a fifth role: it fires at the same
milestone, is read-only, writes one report, and its findings route through the same triage.
What it needs that the other modes do not is a **running app** and a **written plan** —
persona, data state, surfaces including the unchanged ones showing the same concept, and the
journeys. Two outputs make it compound: a verified-clean list, and an honest statement of
what could not be reached. Upstream ships nothing for this; the plugin has no QA, browser or
e2e skill at all.
Bound: `harness/.agents/roles/rin.md`, `harness/.claude/skills/review-with-rin/SKILL.md` §2b.

### AST-045 — A green test suite and a coherent product are different claims · promoted 2026-08-11
The prior package shipped a browser-walking agent for several releases and it **never ran
once**. A grep of the whole payload found no file naming it outside its own two definition
files: no role contract, no dispatch path. It was correct, it was valuable, and it was
unreachable — the exact class `check-reachability.sh` exists to catch, sitting in the package
that later wrote that checker.

So the work of adopting it was never the file. It was the wiring: a contract that owns it, a
dispatcher that names it, and a check that fails when either goes missing.

What it earns its place with, on a web product: **a test asserts what somebody thought to
assert**, and that is mostly backend logic. Missing, misordered, unreadable or unreachable on
the screen is where a user lives and is precisely what no one wrote an assertion for. One
walk found a stale-seed 500 carrying a production implication, a timestamp format disagreeing
with every other page, two screens printing 85 and 44 for one concept, and tabs summing to
183 against a total of 190.

Three of its design decisions were right and are kept. **Scope and browser permission are
dispatch parameters**, so one role covers every screen present and future instead of spawning
one agent per surface. **The judging persona is fixed, not a parameter** — a caller cannot
lower the bar by rewording the dispatch, only narrow the scope. And **the default is strictly
non-mutating**, because it drives a real logged-in session: the click that deletes has no
undo, so an unauthorized one is declined and recorded as a coverage gap.

One was wrong and is not kept: the walk METHOD was marked fixed while containing one
project's browser tooling. In a package that installs anywhere, "fixed" there is a project
shape smuggled into a generic payload — the same defect as a code-map generator assuming
`package.json` and `src/`. The method is the project's; adaptation records it.
Bound: `harness/.agents/roles/qa.md`, `harness/.claude/skills/dispatch-qa-walk/SKILL.md`,
`harness/.agents/roles/thomas.md` (dispatch).

### AST-046 — A block moved between documents keeps the old document's referents · promoted 2026-08-11
1.3.0 split the product walk out of the reviewer into its own role. The dispatch mechanics
were **moved** from `review-with-rin` into a new skill — and moved verbatim. Three lines went
on naming the walker "Rin" and calling the walk "a mode", which is 1.2.0's design surviving
inside the release that reversed it. The dispatcher reads that skill to pack the brief, so
one of those lines would have set the persona for the wrong agent.

`check-reachability.sh` cannot see this: every path resolves, every name exists, nothing
dangles. It is a **semantic** error, and the checker verifies references, not meaning.

Moving text is not the same as re-homing it. **Re-read a moved block in its new context
before the move counts as done** — the sentences that were correct in the old document are
exactly the ones nobody looks at again.
Bound: `harness/.claude/skills/dispatch-qa-walk/SKILL.md`.

### AST-047 — "Local" is a deployment fact, not a data fact · promoted 2026-08-11
The QA role shipped with "prefer a local or seeded environment for anything carrying customer
data", which quietly assumes local means synthetic. The first repo to read it said otherwise:
its local database is a **production snapshot with real buyer PII**, so a screenshot of an
order list there captures the same names and addresses a production one would.

The safety rule was written about the wrong noun. Where the data came from decides what may
be captured, and prod-derived data is production data wherever it happens to be running. A
rule phrased around environment lets a team satisfy it exactly and still write customer
records to disk.

Generalises past this case: **a safety rule keyed to a proxy for the risk will be satisfied
by the proxy.** Key it to the thing itself, and require the agent to establish it rather than
infer it — here, what the data *is*, asked before a screen is judged safe to capture.
Bound: `harness/.agents/roles/qa.md` §Safety(c).

### AST-048 — A rule not present where it must be remembered does not exist · promoted 2026-08-11
1.x carried this ledger forward and dropped every always-on rule file. Measured on 1.3.1:
`git ls-files | grep -c 'claude/rules'` returns **0**. Two rules survived only here, in a file
whose own header calls it advisory memory that nothing is told to read:

- **One checkout, one driver** (AST-016, AST-027). A live incident: two root sessions shared a
  main checkout, one ran `git switch` while the other was committing, three commits landed on
  the wrong branch and vanished when it switched back. Nothing errored; both sessions were
  correct in isolation. The owner hit this class again while 1.3.1 was installed.
- **Role is decided by how a session was spawned**, never by prompt content (AST-024). The
  risk grew rather than shrank: five roles now, against four.

The line the deleted file ended on is the one worth keeping: **a rule that is not present
where it must be remembered does not exist.** This package had already demonstrated it three
times — a walker shipped across releases that nothing dispatched, a gate demanding evidence no
contract produced, and now two invariants living only in memory.

The corollary for this file: **the ledger is evidence, not law.** An entry here records what
was measured; a rule only binds when it sits in the contract of the role that must obey it, or
in the skill that role reaches for. Promoting a lesson means moving it to that surface, not
appending here and considering it done.

Retiring an always-on rule is therefore a **policy change**, not housekeeping, and belongs in
an upgrade receipt as "re-homed to X" or "dropped because Y".
Bound: `harness/.agents/skills/dispatch-ticket/SKILL.md` (one checkout),
`harness/.claude/agents/*.md` (spawn-decides-role), `prompts/ADAPT-HARNESS.md` §3.

### AST-049 — Checks 1–4 asked whether things were consistent, never whether a role could START · promoted 2026-08-11
`check-reachability.sh` verified that every phase had an owner and every reference resolved,
and passed on a package where **three of four dispatchable roles had no launcher written
anywhere** and the shaper was never named by the dispatcher's contract. Dispatching Rin by the
documentation was impossible: `review-with-rin` said "argv from the dispatch-ticket launcher
matrix", and that matrix listed only the builder.

The gap outlived two rewrites. The prior package's dispatch skill mentioned james 51 times,
dan 52, rin 10, shaper 0 — and the align phase never had a dispatch path in any version, which
is the finding ADR 0001 was written about. It survived the rewrite intact because nothing
tested for it.

A role needs **two** things to be startable: a written launcher, and a dispatcher whose
contract names it. Check 5 requires both. The general shape: **a consistency check answers
"does this agree with itself", which a completely inert system also passes.** At least one
check has to ask whether the thing can run.
Bound: `harness/scripts/check-reachability.sh` (check 5).

### AST-050 — Qualify a plugin command always, not once it is known to collide · promoted 2026-08-11
AST-042 fixed one name — `code-review`, where a plugin skill and a built-in already answered
to the same word — and left every other flow command written bare. Two of those bare forms
were the **first line of a dispatch brief**: `/implement` for a Builder, `/grill-with-docs`
for a Shaper. They resolve today because nothing else claims those words yet.

That is the whole problem: a name collision is **invisible until it exists**. A built-in
added later, or a second plugin installed by the owner, changes what a bare command resolves
to with no diff anywhere in this package and no error at dispatch — the brief simply gets
prose instead of a phase, which reads as a weak agent rather than a broken command.

So the rule is unconditional: **write `/mattpocock-skills:<name>` every time**, and reserve
the bare form for Claude Code's own built-ins (`/compact`, `/clear`, `/simplify`), where the
bare name IS the correct address. AST-042's "wherever ambiguous" was too weak — the author of
a document cannot see the ambiguity that arrives next month.

Written while making this change: a blanket regex for `/triage` also rewrote three
`docs/agents/triage-labels.md` paths into nonsense, because `\b` matched mid-path. Caught by
reading the diff rather than by any check. AST-046 reappearing in the act of applying it.
Bound: `harness/.agents/roles/thomas.md`, `harness/.agents/skills/dispatch-ticket/SKILL.md`,
`prompts/ADAPT-HARNESS.md`.

### AST-051 — An address the caller cannot use produces a substitute, not an error · promoted 2026-08-11

`builder.md` named the simplify pass as Claude Code's built-in `/simplify`. The name was
right and the address was wrong: a slash command is the form a **human** types, and a Builder
is an agent with no keyboard. It could not invoke what it was told to invoke.

Nothing failed. Two Builders on two tickets in one day each performed a hand-rolled cleanup
and neither produced the `simplify(increment):` marker. Both handbacks honestly described a
pass that did happen. Measured afterwards, the real skill fired over the same diff found an
extraction both had missed — so the substitute was not merely unmarked, it was **weaker**.

The control experiment is in the same table: the rows naming `mattpocock-skills:implement`
and `mattpocock-skills:code-review` were both invoked correctly in those same sessions. A
usable address gets used.

**This entry corrects AST-050.** That rule said built-ins "keep their bare names, which are
the correct address", listing `/compact`, `/clear`, `/simplify` together. Two of those three
are CLI commands with no Skill-tool path, so bare IS their address. `simplify` is a bundled
**skill** carrying no `disable-model-invocation`, so the model can invoke it and its address
for an agent is `Skill(skill: "simplify")`. One sentence, correct for two of three cases.

The general rule: **an address is correct relative to who must use it.** User-invoked only
(`disable-model-invocation: true`) → `/name`, and something must deliver it as a user turn.
Everything else → the Skill form. Getting this backwards fails silently in both directions,
because an agent handed an unusable address improvises rather than reporting.

Also measured while fixing it: the first audit regex could not have found this. It tabulated
plugin skills only, and `simplify` is a built-in — a check blind to a whole class of the
thing it checks. Reachability check 6 reads both, and rejects an unknown name rather than
passing it. Found by the project running the harness, not by the harness.
Bound: `harness/.agents/roles/builder.md`, `harness/.agents/skills/dispatch-ticket/SKILL.md`,
`harness/scripts/check-reachability.sh`.

### AST-052 — The word-budget audit ran its loop zero times and reported all clean · promoted 2026-08-11

`docs-staleness-audit.sh` measured `.agents/roles/<role>.md`. In this package the payload
sits under `harness/`, so all five paths failed their `-f` test, the loop body never ran, the
axis printed nothing, and the script closed with `RESULT: all clean`.

It shipped that way from 1.0.0 and was quoted as evidence in this session more than once.
The word counts reported alongside it were right — they were taken by hand with `wc -w` —
which is exactly why nobody noticed: two sources agreed, and only one of them was working.

**A loop over zero items is a pass.** That is the whole failure. Nothing errored, no path
was reported missing, and the axis header still printed, so the run looked identical to a
run that had measured five contracts and found them all within budget.

The fix is two lines and neither is the path: detect the payload, and **count what was
measured**, then fail when the count is zero. A check that cannot say how much it checked
cannot be believed when it says everything passed — AST-039 and AST-049 are the same shape,
and this is the third time it has appeared inside tooling written to catch it.

Found while adding an unrelated axis, not by any check. The reachability script has known
its own layout since 1.0.0; this one did not, and nothing compared them.
Bound: `harness/scripts/docs-staleness-audit.sh`.

### AST-053 — An axis read the run's verdict instead of its own, and went mute · promoted 2026-08-11

The staleness audit's new AXIS 5 closed with `[[ $FOUND -eq 1 ]] || echo "(clean)"`. `FOUND`
is the whole run's flag. Any earlier axis that fired left it set, so AXIS 5 printed its
header and nothing else — indistinguishable from clean, and from a finding.

It passed in the package because AXIS 1-3 happened to be clean there. In a real project
AXIS 1 lists every doc older than three weeks, so it is **never** clean, so AXIS 5 was mute
on every run it would ever actually do. The one environment it was tested in was the one
environment where the bug could not appear.

**Shipped in the same release that fixed AST-052**, which is the same failure: a check whose
own result cannot be read. Writing the ledger entry did not prevent reproducing it forty
minutes later, in adjacent lines of the same file.

The rule is small and mechanical: **an axis reports its own verdict from its own flag.** The
shared flag is for the exit code and nothing else. Two axes here already did it correctly
(2 and 3); AXIS 1 had the same silence and was fixed alongside.

Found by running the shipped script against a real project rather than against this package.
Every check in this package should be run once somewhere its preconditions are messy.
Bound: `harness/scripts/docs-staleness-audit.sh`.

### AST-054 — `git add -A` committed two releases nobody ever applied · promoted 2026-08-11

`ADAPT-HARNESS.md` said the installation has to be committed and did not say **what**. The
upgrading agent used `git add -A`, which swept in `.astraler/releases/1.4.3/` and `1.4.4/` —
both staged, both superseded before anyone ran them, both untracked until that moment. About
1000 files, permanently in a history that cannot be trimmed without a rewrite.

Staging is deliberately cheap, so abandoned candidates are normal rather than exceptional,
and a project that upgrades often accrues them. Untracked is their correct resting state:
disk, not history.

The instruction now names paths and derives the release to keep from `.astraler/CANDIDATE`,
then prints what is still untracked so an abandoned candidate is visible rather than assumed.
**An instruction that says "commit" without saying what to commit will be read as `-A`** —
this is the second time a gap in this prompt was filled by an agent's reasonable default.
Bound: `prompts/ADAPT-HARNESS.md`.

### AST-055 — A gate that reads the subject cannot see which pass wrote it · promoted 2026-08-12

AST-051 fixed the address, and the fix worked: a Builder under the corrected contract invoked
`Skill(skill: "simplify")` and said so unprompted. The next Builder called
`Skill(mattpocock-skills:simplify)` — a skill that does not exist — because it had just
invoked `mattpocock-skills:implement` from the row above and generalised the namespace one row
down. Two adjacent rows, two different systems: the plugin, and Claude Code itself.

The error is not the interesting half. **It fell back to the `code-simplifier` agent, and the
`simplify(increment):` commit appeared anyway.** Thomas's merge grep, Rin's gate and
reachability check 7 all read as satisfied, because every one of them asked whether the marker
exists. None could ask which pass produced it. The substitution was visible only because a
human happened to be watching the pane.

**A marker that any tool can write is a check that cannot fail.** The subject proves a commit
happened; the body is where a substitute can disagree with the sanctioned pass. The commit now
carries a `Pass:` line naming what actually ran, and the two halves are registered separately
in check 7 — the marker and its provenance are different artifacts, not one artifact with a
detail.

The exploitable fact is that agents here were **honest and imprecise, never dishonest**. Every
measured failure of this step ended with a handback that accurately described a pass and an
artifact that recorded nothing. So the fix is to put the honesty where the gate reads, rather
than to ask for more of it.

Note what did NOT work: 1.5.1's table already annotated the row `(built-in, via the Skill
tool)`. The signal was present and was read past, so the repair is a stated negative in the
cell — **not** `mattpocock-skills:` — plus a rule that a failed invocation is a finding to
report rather than a step to route around. More qualifying prose in the same place that was
skimmed is not a fix.

Bound: `harness/.agents/roles/builder.md`, `harness/.agents/roles/thomas.md`,
`harness/.agents/roles/rin.md`, `harness/.agents/skills/dispatch-ticket/SKILL.md`,
`harness/scripts/check-reachability.sh`.

### AST-056 — A blocking edge expresses order, not exclusion · promoted 2026-08-12

The frontier asks which tickets have no open blocker and no assignee. It never asks what each
ticket will WRITE, and nothing else did either. Two tickets went out together, correct by every
rule the package stated. One existed to correct `WIRE-CONTRACT.md`; the other was a Go ticket
whose brief never mentioned that document — and whose Builder edited the same three rows of
it, because the repo's docs-sync rule requires the touched document to move in the same slice.
It was obeying a correct rule. The first merged, the second was based on the commit before that
merge, and the same three corrections were re-derived blind: two conflict blocks, and a naive
merge in the wrong direction would have reverted reviewed work with no signal.

One worktree per Builder solves the checkout collision and nothing else. It relocates the
collision to the merge, where it is found late and by hand. **Two tickets can be genuinely
unordered and still unsafe to run at once, and a tracker with only blocking edges has no way
to say so.** Any repo with a docs-sync rule guarantees this class exists, because shared
documents are exactly what several tickets in one slice touch.

Measured twice in one day. The second time — on `routes.go` and its test, an hour later — was
dispatched by the operator who had just diagnosed the first occurrence and written it up. With
the diagnosis in front of them they did not generalise it: the harness's own *fix the class,
not the instance* failing in the hands of the role that owns it.

That is why the write-set is a required FIELD of a concurrent dispatch rather than a rule in
prose, the way browser consent is required of a QA dispatch. A rule a careful operator forgets
within the hour needs a slot that blocks the launch, not a reminder. The dispatch record grew
the column it was missing: what this ticket writes.
Bound: `harness/.agents/roles/thomas.md`, `harness/.agents/skills/dispatch-ticket/SKILL.md`.

### AST-057 — A frontier that is only computed is invisible to the one person who cannot compute · promoted 2026-08-12

Thomas's contract defined the frontier as a QUERY — open, no unfinished blockers, no assignee —
and nothing said to write the answer back. An agent re-runs the query on demand, so it is never
wrong for long and never notices anything missing. **The owner cannot re-run anything: he opens
the board and looks.** So the board can be useless to the human while serving every agent
perfectly, and no role is positioned to notice.

Measured on a live project, 2026-08-12: **zero issues had ever entered the unstarted state**
across the project's whole life, and one ticket sat looking blocked for hours after both its
blockers merged. Found by the owner comparing two boards by eye. No check the harness runs had
ever looked.

**The upstream cause is in the plugin, and naming it correctly is what decides the fix.**
`mattpocock-skills:to-tickets` draws the blocking edges and writes `Status: ready-for-agent` at
the same moment — a **label**, applied once at creation, never revisited when a blocker is
later added or cleared. It sets no workflow state at all. Two representations of readiness end
up side by side and neither answers the dispatcher's question: the label means *shaped well
enough to hand over*, and the state that would mean *unblocked and unclaimed* is never written.
On the measured board, four tickets wore the label while blocked.

**That skill is the plugin's, so this package cannot fix it.** 1.0.0 exists to stop vendoring
Matt's skills, and a patched copy here would be a second home for one fact — the failure ADR
0001 was written about. What the package owns is the contract, so the contract carries both
halves: write the computed answer back as state, and never read a readiness label as a blocker.
`tracker-frontier-audit` was the compensating control; the OWNER REMOVED that skill on
2026-08-13, so the contract's two halves are now the whole of it.

**The tracker vocabulary stayed out of the contract deliberately.** `thomas.md` names no state,
because `to-tickets` targets GitHub as well as Linear and GitHub Issues has no such state.
Naming one would hardcode a tracker into the one file written not to know which tracker it is
on; the mapping belongs in each project's `docs/agents/issue-tracker.md`.

Note the choice that was never available: check 3 requires every shipped skill to be named by a
contract, so shipping the audit *forced* the contract edit. The package decided where this went
before anyone argued about it.

**A rule with nothing to fail is not yet a fix, and the first draft of this entry was one.** It
said "move it in the same breath as closing the ticket" and stopped there — a line in a contract,
with nothing that goes red when a busy dispatcher skips it. The owner asked what it actually
solved, which was the right question. Two changes followed:

- **The write-back is a merge step that must be REPORTED.** Merge is not complete until Thomas
  names which tickets moved, and `none` is a valid report while silence is not. A step nothing
  reports is a step nobody can tell was skipped — the same reasoning that made the write-set a
  required field in AST-056 rather than advice.
- **The audit is bound to a moment that arrives on its own**, at phase end beside the
  cross-vendor arm, instead of to the owner noticing a board looks wrong. Noticing is exactly
  what took a whole project lifetime here. And check 7 now registers `frontier write-back` as an
  artifact whose producer is this contract and whose verifier is the audit skill, so neither half
  can go quiet without a red check.

That second point is worth keeping separate from this failure, because it is a fact about the
package rather than about trackers: **naming a skill in a contract clears check 3 and makes
nothing run.** Check 3 asks whether a skill is reachable, never whether anything reaches it. The
package's own history has the proof, recorded in the checker's docstring — *a browser walker
shipped across releases that never ran once.* A new skill needs a moment, not only a mention.
Bound: `harness/.agents/roles/thomas.md`, `harness/scripts/check-reachability.sh`.

### AST-058 — The check after the step reported clean when the step was impossible · promoted 2026-08-12

`ADAPT-HARNESS.md` §4 told the installer to commit the applied release and then verify:

```bash
git add ".astraler/releases/$(cat .astraler/CANDIDATE)"
git status --short ".astraler/releases/"   # anything still listed was never applied
```

In a project whose `.gitignore` excludes `.astraler/`, `git add` refuses the path — and
`git status` on an ignored directory then prints **nothing**, which the prompt's own reading
turns into *everything applied and committed*. Not one file was staged. Measured on a real
upgrade, and found by the project's Thomas comparing the instruction against the tree rather
than against the receipt.

**The verification was the defect, not the `git add`.** The add is loud: it errors and returns
1. The line after it is what converted a loud failure into a clean report, because its output
is identical when the step worked and when it could not run. That is AST-032, in the file that
already carries AST-054 for a different failure of the same step.

The check is now a count of what is actually staged, which cannot be satisfied by absence.

**`git add -f` was considered and rejected.** The ignore rule belongs to the project — this
package ships no `.astraler` stanza, verified by grep — so forcing past it would override a
decision made elsewhere and never surfaced. A zero is recorded in the receipt as *applied
release is on disk only*, and the owner decides whether to carve an exception. The distinction
worth keeping: an UNAPPLIED release left untracked is correct and cheap (AST-054), while an
APPLIED one left untracked means the notes describing what this upgrade intended exist on one
disk and nowhere else.
Bound: `prompts/ADAPT-HARNESS.md`.

### AST-059 — The repo kept one self-check and lost the other to a directory it may ignore · promoted 2026-08-12

`install.sh` staged `check-requirements.sh` into `.astraler/releases/<version>/` only, while
`check-reachability.sh` travelled inside the payload and therefore landed in the project's
`scripts/` and was tracked. Same class of tool, two fates. A project that deletes or ignores
its releases directory — which AST-054 says is a legitimate resting state — silently loses its
own doctor while keeping the other one, and nothing reports the asymmetry.

Found in the same pass as AST-058, by the same question: does the instruction match the tree?

The installer now copies the one source file to both destinations — the release directory, for
the adaptation agent to read, and the payload's `scripts/`, so the project keeps it. The
package still has a single home for it; only the copy count changed.

The vendored copy also needed to survive being moved: it read its version from a sibling
`VERSION` file that exists only at the package root, and would have printed `?` in every
project. It now falls back to `.astraler/state/applied-version`. **A tool that cannot name the
version it is checking invites the wrong answer** — the same reason `docs-staleness-audit.sh`
had to learn it was measuring nothing in AST-052.
Bound: `install.sh`, `check-requirements.sh`.

### AST-060 — Check 3 printed green about the skills it had not opened · promoted 2026-08-12

In project layout, reachability splits skills into harness-owned and project-owned and examines
only the first set — correctly, since checking the second produced a wave of false findings
(AST-038). But it then printed `[OK] 3 every shipped skill is reached`, with the count of
skipped skills on a line ABOVE the verdict, where the pass line buries it.

The failure is timed to hurt: a project skill is skipped on the very run after it is written,
which is exactly when its author runs the checker looking for reassurance. Reported by the
project that had just written one — the checker went green and said nothing about it.

Check 3 now names its own scope in its own line, and the skipped set moved into the verdict
beside check 4's exclusion. Third instance of one shape: **a green line that speaks for more
than the check looked at** — after check 4's referenced-path claim, and the staleness audit's
`RESULT: all clean` over a loop that ran zero times.
Bound: `harness/scripts/check-reachability.sh`.

### AST-061 — The arm batched to phase end built a payload only skimming could finish · promoted 2026-08-13

One arm per phase looks cheaper than one per ticket and is the same total work spread over a
worse shape. A project measured both: at slice scope one review ran to **6,904 added lines
across 31 files**, against **1,238 for a single ticket** — about six times. Nobody skips a
review that size. They skim it, which is not the same instrument.

What skimming misses is specific rather than random: **the hollow test**. Three survived a
single day on that project — a test comparing a constant to itself, a fixture of two isolated
tenants that could not deadlock whatever the lock order, and a fixture where row-level security
refused the row before the fence under test was ever reached. All three were plainly visible at
single-ticket scope. All three were caught by hand at the merge rather than by any gate.

The first per-ticket arm returned a HIGH the author's own mutation pass had missed: a
destructive reset authorizing outside its write transaction, while an established fence in the
same codebase rechecks inside. **That is the class a cross-vendor pass wins at — internal
inconsistency against the project's own standard** — because the author reads the ticket and
the arm reads the repository. It only wins it at a scope where reading is possible.
Bound: `harness/.agents/roles/thomas.md`, `harness/.claude/skills/codex-arm/SKILL.md`.

### AST-062 — A second pass left to judgement is a second pass that does not run · promoted 2026-08-13

The rule was "a second pass where the first produced blocking findings", and the word *where*
left the decision open. Measured on one ticket: the dispatcher talked himself out of it in a
single paragraph, and **every reason he gave was true** — the finding was already
mutation-proven, the fixes looked mechanical, quota was tight. The call was still wrong.

The mechanism is that the discretion is exercised at the exact moment it is least reliable:
after the fix, when the work reads as finished. And what pass 2 catches is **the defect the FIX
introduced**, which by definition nobody has looked at, so no amount of confidence about pass 1
speaks to it. Proof from the neighbouring ticket: pass 1 found authorization outside a write
transaction, the repair added transaction and locking code, and **pass 2 found a real 40P01
deadlock cycle inside that new code**. Skipping there would have shipped a seller-facing 500 on
the only unstick path the product had.

The rule is now a step rather than a judgement, and it lives in exactly one contract — the
first repair of this made four files normative about it at once, which is the drift the
one-home rule exists to stop.
Bound: `harness/.agents/roles/rin.md`.

### AST-063 — A gate with no window in the sequence never fires, and nobody forgets it · promoted 2026-08-13

The plan gate did not run for two consecutive slices, the second a 44k spec with 44 acceptance
criteria and ten tickets. No one skipped it. The Shaper contract closed its session *"when
`to-tickets` has produced the tickets"*, with align, spec and tickets running unbroken — so
there was **never a moment where the spec existed and the tickets did not**. The gate had
nowhere to fire.

Adding a reminder would have been the third attempt at the same thing. The repair is
structural: the contract that runs the sequence now STOPS at Spec and hands back, and hands
back twice, the second time reporting how each finding was resolved in the tickets. A finding
cannot be waved through by cutting tickets that ignore it.

**Test a rule by asking where in the sequence it could execute**, not by whether the document
says it. A rule with no window reads as followed forever, because nothing it governs ever
reaches it. The first repair of this one reintroduced the shape one layer down: it left a
blocking spec finding with no repair window before the mandatory second pass, so tickets could
still be cut from a spec that never took it.
Bound: `harness/.agents/roles/shaper.md`, `harness/.agents/roles/thomas.md`.

### AST-064 — The one always-on file no release can repair had no budget · promoted 2026-08-13

`orchestrator.md` is read at every session start and nothing measured it. It is also SCAFFOLD —
written once on a fresh install, never overwritten, so a release cannot take back what
accumulates there. Those two properties together make it the worst place in the harness for
prose to collect, and it was the only always-on surface with no ceiling.

Measured across three trees on one day: **package 653 words, one project 941, another 1,477**.
The 1,477 carried 505 words arguing which model a row should hold — including a decision, its
reversal the same day, and an instruction to future agents not to undo the reversal. All of it
billed on every session, to answer a question almost no session asks. The table is the file's
job; the argument for a row belongs in the project's decision record.

The guard went into `docs-staleness-audit.sh`, which is PAYLOAD. **A check for scaffold drift
has to live in payload, because payload is the only thing an upgrade can carry into a project
that already has the drift.** Verified in both layouts before shipping: the package reports
653/800 ok, the project reports 1,477 OVER.
Bound: `harness/scripts/docs-staleness-audit.sh`.

### AST-065 — Two reviewers sharing one name, each in the other's contract · promoted 2026-08-13

A cross-vendor pass was documented as "the milestone gate", and later as "the plan gate". Both
names already belonged to the same-vendor reviewer, in that reviewer's own contract. The
collision is not cosmetic: a reader of the reviewer's contract who meets its name on a Codex
pass concludes **that reviewer fires Codex**, and a dispatcher who has run either one can report
"the spec was gated" and be believed. Two independent checks collapse into one, and the report
reads as compliant.

It happened twice, the second time in this package, by porting a project's wording without
checking whether the name already had an owner here — the project's own reviewer contract had
not been updated, so nothing collided there.

Names are now assigned on one axis, **the artifact each pass reads**: `arm: spec`,
`arm: ticket`, `arm: slice`. The reviewer's names are reserved, and both contracts state that
neither review stands in for the other. The first version of that repair was itself an instance
of agreeing rather than thinking: an agent renamed a gate purely because the owner had used a
different word in a question.
Bound: `harness/.agents/roles/thomas.md`, `harness/.agents/roles/shaper.md`.

### AST-066 — A review bound to the wrong checkout returns clean without reading anything · promoted 2026-08-13

The Claude-root arm invoked the companion with `--base <ref>` and nothing else. The companion
resolves `HEAD` from the checkout it runs in, so the flag names one end of the range and the
cwd silently names the other. That was harmless while the arm fired at phase end, because by
then the commits were already on the base branch and Thomas's own checkout was the right place
to stand.

Moving the arm to per-ticket, before the merge, changed the ground under it: the reviewed
commits now live in the **Builder's** worktree, unmerged, while Thomas is resident in base.
Run from there, the pass compares the base branch to itself, reads nothing, and returns
**clean** — at the exact moment a ticket is about to merge on that verdict. A mandatory gate
had become a check that could not fail, and its output was indistinguishable from a real pass.

Two things are worth separating. The invocation did not change; the **cadence** did, and it
invalidated an assumption the invocation had never written down. And the Codex-root mirror had
carried the answer the whole time — an explicit detached worktree at the head SHA — so the
package already knew, in one file, what the other file omitted.

The recipe now resolves the head, reviews from a detached checkout at that SHA, and verifies
`git rev-list --count <base>..<head>` before trusting a verdict. **Zero commits is a STOP, not
a pass.** Found by `arm: slice` on its first run, in the release that introduced the cadence.
Bound: `harness/.claude/skills/codex-arm/SKILL.md`.

### AST-068 — A lesson closed at instance level reopens at class level · promoted 2026-08-13

A project recorded that **a git worktree carries only TRACKED files**, so an agent dispatched
into a fresh one arrives without anything untracked that it must load. The entry named the
mechanism correctly and in the general form: *"anything an agent must LOAD at dispatch."* The
repair tracked `.claude/` and `.agents/`, the two directories the symptom had named. It carried
a prediction — *"a fresh worktree will now resolve every skill"* — and that prediction came
true, verified at exit 0.

Nine days later the same mechanism returned wearing different clothes: `node_modules` is not
tracked either, so a review gate ran **with no test runner present and returned a green
verdict**. The agent wrote it up as a new discovery. It was not new. It was the same entry,
one instance over.

The failure is in how the repair was scoped, not in the finding or in the fix. **Nobody asked
the class question** — *what else must an agent load at dispatch that git does not carry?* — so
the entry closed on the two directories that had hurt, and everything else in that class stayed
open while reading as solved. A prediction that comes true is the most convincing way to close
a wound too narrowly: the fix worked, the check passed, and the class was never swept.

The cheap discipline: when a repair lands, re-read the entry's own words for the widest noun it
used, and ask what else that noun covers. Here the word was *anything*, and the repair covered
two directories.
Bound: `harness/.agents/roles/thomas.md`, `harness/.agents/skills/dispatch-ticket/SKILL.md`.

### AST-069 — An instruction with no moment attached measures zero · promoted 2026-08-13

A project kept a ledger and a written rule to *"capture every real friction"*. Across a whole
harness generation it added **zero entries** — while its own ledger, in the same window,
contained the entries that described the bugs it was hitting. Reading ran: 74 citations across
30 live docs. Only writing stopped.

Nobody forgot. The rule had no MOMENT. It sat in §7 of a load-on-demand document, so it was
read when someone opened that document, which is never the instant a friction happens. And the
project's own ledger already held the diagnosis: *"a mandatory rule that lives only in
load-on-demand docs is skipped, and only the owner notices."* The ledger contained the reason
it was not being written to.

Two properties make an instruction actually run, and both are needed:

- **A moment** — an event that already happens and already must report. Merge is the natural
  one here: it is mandatory, it is frequent, and the friction is still warm.
- **A trace** — something grep-able whose absence is visible. A `Ledger:` line in the merge
  commit, where `none` is a valid answer and silence is not (AST-057's shape).

The same shape had already been measured on a skill whose trigger was *"when the board looks
wrong to the owner"* — a feeling, not a step; it ran zero times across six merges while every
reachability check certified it. **Naming a thing in a document makes nothing run.** That
entry was withdrawn with the skill it described, which is why AST-067 is a gap; the mechanism
outlived it and is recorded here on its own evidence.
Bound: `harness/.agents/roles/thomas.md`, `prompts/ADAPT-HARNESS.md`.

### AST-070 — A bounded exception nobody asked for is a contradiction carried on speculation · promoted 2026-08-13

`codex-dispatch-headless` was the written, narrowed form of one exception: run a Builder on
Codex with no Herdr pane. It was built well — three preconditions, any one absent routing back
to the visible default, and the invariant kept explicit that a headless author cannot approve
its own work. It made headless HARDER to reach, not easier.

It ran zero times. Two active projects carried it for three weeks and one for ten days, and
`visibility=headless` never appears outside the two files that define it. The four commits
that mention "headless" are about browser automation, and one of them bans it.

Two arguments for keeping it fell to measurement rather than to opinion. **It is not too young
to judge** — three weeks with two projects dispatching daily is opportunity. And **it is not
where the dangerous flag lives**: `--yolo` is already on the mainline codex path in
`dispatch-ticket` for builder, shaper and qa, so removing this changed no permission posture.
What remained was only the topology.

The decision turned on what the package sells. Every gate and every dispatch here argues the
same thing — **work the owner cannot observe is trusted on the dispatcher's word**, and the
pane is the answer to that. Shipping an invisible topology *in case* someone wants it means
carrying the contradiction permanently to serve a request that has never arrived. Headless is
now unsupported outright, and the routing line says so instead of pointing at a skill.

**Adding it back is cheap; guessing its shape in advance was not.** A real request would have
shaped it against a real constraint. This one was shaped against a hypothesis.
Bound: `harness/.agents/skills/dispatch-ticket/SKILL.md`.

### AST-071 — Every check asked whether a thing was NAMED, none asked whether anything READ it · promoted 2026-08-13

Seven reachability checks, five contracts, a staleness audit on five axes, and three skills
shipped for weeks writing documents that no contract and no plugin skill was ever told to
open. Every check was green the whole time. The owner found all three by hand, on the third
occasion of noticing the same shape in one day.

The blind spot was structural rather than careless. Check 3 asks whether a skill is NAMED.
Check 4 asks whether a referenced path EXISTS. Check 6 asks whether an address is CALLABLE.
Check 7 asks producer-and-verifier, but only for the gate artifacts a human had listed. Not
one asked the question that mattered: **does anything read what we produce?** A file with a
writer and no reader satisfies every one of them.

`extract-standards` is the sharpest instance because it was well built. Its consumer was
supposed to be the plugin's Standards axis, whose instruction is one sentence — *"anything in
the repo that documents how code should be written"* — with no path and no directory, against
a neighbouring step that names `docs/agents/issue-tracker.md` outright. So the package wrote a
file to an address its reader has no instruction to visit, under a name that reader never
mentions. **Diagnosis right, address wrong, and nothing could see the difference.**

Check 8 closes it at the only point that is mechanical: a skill declaring `## N. Write <path>`
must have a row in the artifact registry, where a human names the reader. It deliberately does
not try to infer readers — `batch-triage` asked for "the code map" in prose for weeks, and a
filename grep called that artifact an orphan while a shipped skill wanted it every run. **A
grep for a name is not a search for a consumer**, so the registry is written by hand and the
check only enforces that nothing escapes it.
Bound: `harness/scripts/check-reachability.sh`.

### AST-072 — Self-monitoring shipped without proof it cannot harm what it monitors · promoted 2026-08-18

Two new mechanisms — a workspace-identity convention and a background watchdog — landed with
their own reachability and word-budget checks green, and their own author read the shutdown
logic as safe. A Codex adversarial-review pass, fired against the same commit before it was
called done, returned `needs-attention` with three HIGH findings, none of them about whether
the feature worked: whether it could hurt something it was never meant to touch.

The sharpest one: the documented shutdown sent `kill -TERM` to a process group resolved from a
bare PID, with no check that the PID still belonged to the watchdog and no guarantee the
watchdog ever ran in its own process group to begin with. Launched as a plain background job
from a non-interactive shell — exactly how a dispatched agent starts one — the watchdog shares
its process group with the shell that launched it. Stop that watchdog and the signal lands on
every process in that group, including the caller. A live test confirmed the mechanism: an
unisolated background process, killed by group, took the launching shell down with it. The
second and third findings were the same class from two other angles — a workspace resolved by
list-then-create with no lock could be duplicated by two concurrent sessions, and an ownership
field the cleanup path reads had no step left that ever wrote it.

**The common shape: a coordination primitive is trusted the moment it starts, and audited only
for whether it does its job — never for what it can do to the session running it.** Nothing in
the existing reachability or staleness checks asks that question; they check that a thing is
named, reachable and within budget, not that its failure mode is bounded. The fix in each case
was the same move — verify identity before acting (process args before signaling, workspace
list before *and after* create, an explicit ownership record instead of an inherited one) —
and none of the three fixes changed what the feature does, only what it is allowed to do by
accident.
Bound: `harness/scripts/herdr-watchdog.sh`, `harness/.agents/skills/dispatch-ticket/SKILL.md`.

### AST-073 — A global script is only shared if something keeps it updated · promoted 2026-08-18

2.0.1 moved the mandatory watcher off a repo-local path onto `~/.claude/scripts/herdr-watch-
terminal.sh`, reasoned as "shared across projects" — one file instead of a copy per repo. In
practice nothing ships to that path after the first install: every later release still stages
`scripts/herdr-watch-terminal.sh` into each project (nothing removed that step), so the copy
actually invoked is the one no release touches, while the copy every release updates sits
unused. On this machine the two had already drifted — a stale citation label in the global
copy — and a second, unrelated global file at the same path prefix
(`~/.claude/scripts/herdr-watchdog.sh`) turned out to be an early prototype three drafts
behind the shipped script, invoked by nothing, silently stale for over a week.

**"Shared" is not the same property as "kept in sync."** A path a release writes to is kept in
sync by construction; a path nothing writes to just has one fewer reason to notice it fell
behind. The fix reverses the 2.0.1 call: `dispatch-ticket` and the `thomas-*` supplements now
call `<repo-root>/scripts/herdr-watch-terminal.sh` — absolute, not relative, per the cwd
lesson in AST-028 — and the doctor's check 9 verifies that path instead of the home directory
one.
Bound: `harness/.agents/skills/dispatch-ticket/SKILL.md`, `check-requirements.sh`.

### AST-074 — A tracker measured only against itself cannot detect its own drift · promoted 2026-08-18

Reported upstream from an adapted project's own Thomas, via a handoff, rather than found in
this package directly — the first entry with that provenance, recorded because the class it
names is general and the reachability checks have no way to see a tracker's *content* going
stale, only a document's.

Four tickets in that project sat claimed and in-progress with a live assignee **after their
code had merged to the base branch**, the oldest by a full day. Nothing errored: the merge ran,
the frontier write-back after it did not, and no artifact recorded the omission — the exact
shape of AST-057, arriving in a place check-reachability cannot reach, because the drift is in
the tracker's *content*, not in whether a phase is named or wired.

**The reason no tracker-only check catches this: a wrong state is perfectly consistent with
itself.** In-progress with an assignee is exactly what a real in-flight ticket looks like from
inside the tracker; the two are indistinguishable without a second, independent source. Git is
that source for a ticket the same way an independently-enumerated key set is that source for a
coverage or parity check — the general law is **an oracle must be independent of what it
measures**, and a check that reads only the thing it is verifying has already failed before it
runs.

The fix that shipped, `reconcile-tracker` plus `scripts/ticket-git-facts.sh`, is **read-only by
a recorded ruling, not by omission.** The join key — a ticket id in a commit subject — is not
exact: a partial fix, a revert, or a forward-citation all produce a hit, and the reporting
project's own first real run flagged a phase as "merged" on commits that only named it. Auto-
closing on that signal would have marked unfinished work done, and a tracker that is wrong and
*tidy* is worse than one that is wrong and messy — it is believed by the one reader who cannot
re-run the query.

The same handoff carried a second, related finding: **frontier promotion computed from
blocking edges alone is over-inclusive.** The raw rule returned claimable tickets that included
epics, a phase whose parent had not started, and a ticket marked deferred — parent/child
sequencing carries sequencing information a blocking-edge query cannot see. `thomas.md`'s
frontier section now says so directly; promotion stays a judgement.

**And the tool that carried both lessons was not trusted until it was run.** Built, committed,
then exercised against real data, it failed three separate ways on the first real run — a
shell builtin the design assumed portable was not, on the platform actually in use; an
unscoped id pattern swept up unrelated ids; and deriving the ticket list from the wrong side
of history made every unmerged ticket invisible, silently. None of the three was visible from
reading the script. That rule is now written into the skill itself, not just this entry.
Bound: `harness/.claude/skills/reconcile-tracker/SKILL.md`,
`harness/.agents/skills/reconcile-tracker/SKILL.md`, `harness/scripts/ticket-git-facts.sh`,
`harness/.agents/roles/thomas.md`.

### AST-075 — Neither the process table nor the PID file nor CPU time proves a loop is alive · promoted 2026-08-18

Also reported via the same handoff. The watchdog built for AST-072 monitors dispatched panes
so the owner does not have to — and on the reporting project's own machine, it was itself the
thing silently broken: an instance survived with its `caffeinate` wrapper gone and its own PID
file deleted, alerted nothing across a real STUCK window for two hours, and every liveness
check tried against it said healthy the whole time.

**Three signals were tried, in order, and each failed the same way — each one can be true of a
process that is running but not doing its job.** The process table listed the wedged instance
normally. The PID file question was moot: that instance's had already been deleted while it
kept running. CPU time and "has a child process" both read true permanently, because the
`caffeinate` child is a fixture of the design (AST-072), not a signal — it samples the same
whether the poll loop is turning or hung.

**A timestamp that only advances when the loop *completes* is the one signal the other three
cannot fake**, so `herdr-watchdog.sh` now writes one to its own file every few polls, in place
rather than appended, so the heartbeat never buries the alert log it sits beside. Checking it
means reading its mtime, not its existence — a stale heartbeat and a missing one mean different
things, and only the file's own age tells them apart. Two more measured facts folded in with
it: `grep -c` prints its count and still exits 1 on zero, so a naive `|| echo` fallback fires
alongside it and corrupts a one-line file into two; and killing a watchdog needs the process
GROUP, because on macOS the script re-execs under `caffeinate`, so signalling only the PID a
process listing shows leaves the working half alive — independent confirmation, from a second
project, of the exact class AST-072 already fixed by isolating into a dedicated group before
that PID is ever written down.
Bound: `harness/scripts/herdr-watchdog.sh`.

### AST-076 — AST-072's own fix left a window between acquiring the lock and recording who holds it · promoted 2026-08-18

Found by an adapted project's own Thomas, dispatched to run the cross-vendor arm against the
2.2.0 fold-in before it was adopted there — the review-before-adopt discipline catching a
defect in the very payload it was reviewing, one commit downstream of where AST-072 first
shipped it.

AST-072 fixed the single-instance lock by having `mkdir "$LOCK_DIR"` double as the lock
primitive, atomic and portable. What it missed: the PID written into that lock as proof of
ownership was not available until two re-exec hops later — first into a `setsid` wrapper for
process-group isolation, then into `caffeinate`, which itself forked a new child to run the
script, so the PID that finally reached `echo $$ > "$PID_FILE"` was neither the PID that ran
`mkdir` nor any PID visible before that second hop completed. Between `mkdir` succeeding and
that write landing, `LOCK_DIR` existed with no matching `PID_FILE` — and the script's own
stale-lock recovery path reads exactly that state as "a crashed instance, safe to reclaim."

A second `start` landing in that window doesn't just fail to be blocked — it **evicts the
first instance's lock**, `rm -rf`s the directory the first instance is still mid-setup inside,
and re-creates it as its own. Whichever of the two writes `PID_FILE` last wins the record;
both keep running. Measured: ten `start` invocations fired at once with the original ordering
would, on an unlucky interleaving, have left more than one watchdog alive — each one polling,
alerting, and racing the other's cooldown state. Restructured to fire the isolation hop
BEFORE the lock is acquired, so `$$` is already final and stable when `mkdir` succeeds, and
`caffeinate` is launched as a background helper (`caffeinate -i -w $$ &`) rather than exec'd
into — a helper we start, never a wrapper that forks a second, different-PID copy of us out
of our own control. Re-measured the same way after the fix: ten concurrent `start`
invocations, exactly one survivor, nine correctly refused.

**A lock is only as good as the record it produces.** `mkdir` being atomic proved only that
one process won the directory; it said nothing about how long that process took to prove it
was the one that won, and every instruction between the two was a window nobody had measured.
Bound: `harness/scripts/herdr-watchdog.sh`.
