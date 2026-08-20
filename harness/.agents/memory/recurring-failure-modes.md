# Recurring Failure Modes

Status: current · 121 entries (AST-001 … AST-122, 067 withdrawn) · AST-001…034 carried into 1.0.0 unchanged

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
(`<repo-root>/.claude/worktrees/<branch-slug>`, gitignored), `git worktree list` verifies
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

**A second arm pass, fired against this exact fix, found the fix itself still narrowing
rather than closing the window** — correctly: moving the isolation hop earlier shrank the gap
between `mkdir` and the PID write to one line, but did not remove it, and a single line is
still a line the scheduler can preempt between. Treating a PID-less lock as reclaimable on
first sight was the actual defect, not the gap's width. Fixed by retrying for up to a second
before concluding a PID-less lock is a genuine crash rather than a live instance still inside
that line — long enough that a real instance, which writes its PID in microseconds, is never
mistaken for a dead one, without leaving a doomed instance waiting forever on a lock nothing
will ever release. The same pass found a second, unrelated bug in the fix's own `stop`-path
change: BSD/macOS `ps -o pgid=,args=` right-pads the pgid column with leading spaces, and
`${line%% *}` — written to combine two `ps` calls into one — returned EMPTY on exactly that
padding, silently downgrading every group-kill to a single-PID kill. `read -r pgid rest <<<
"$line"` replaced it, since `read` discards leading and internal whitespace runs itself.
**A fix for one AST entry is not exempt from becoming the subject of the next one** — this
review found real defects in code written specifically to close a review finding, twice in
the same file in one day.

**A third pass, on the `mv`-based fix above, found it still narrowing rather than closing.**
The `mv` made the destructive act atomic, but the DECISION to act on it was still made
independently by every contender, up to a second before any of them acted on it — so a slow
contender's `mv` could fire after a different contender had already legitimately reclaimed and
started, evicting a LIVE lock, not a stale one. This was not caught by reasoning about the
diff; it took forcing the worst case (a pre-planted, permanently PID-less lock, 15 concurrent
`start` calls, five repetitions) to show 2–3 survivors where exactly 1 was correct, and a first
attempt to re-measure with too short a wait window read as clean when it was not — the
processes still mid-retry were miscounted as resolved.

The actual defect, finally: letting more than one process independently decide staleness at
all. Fixed with a reclaim-mutex — one more `mkdir`, held only across the handful of syscalls a
reclaim takes and never across a sleep — so exactly one process is ever the arbiter, and every
other contender either finds a live lock the arbiter just created or waits for the arbiter to
finish before looking. Re-measured with a wait long enough for every bounded retry to actually
resolve (worst case ~1.5s of mutex contention plus 1s of PID-liveness retry, so 20s of margin):
six repetitions of the same 15-way, pre-planted-stale-lock attack, one `started` log line and
one surviving process every time.

**Reasoning about a diff and measuring it are different activities, and this entry needed
three rounds of the second one before the first one's conclusion held.** A test that finishes
early reads as a passing test; only a wait margin wider than the code's own worst-case retry
budget tells the two apart.

**A fourth round chased the mutex's own failure mode — a crash while holding it stranding
every future `start` — into a kernel-managed `flock`, and that round is the one worth
remembering the shape of, not the mechanism.** `flock` genuinely has no stale-lock state: it
releases the instant its file descriptor closes, for any reason, including `kill -9`. Verified
in isolation, correct. Wired into this script, wrong anyway — because bash spawns children
constantly (`sleep`, `herdr`, the analyze() python call), and every one of them inherits open
file descriptors by default. A `sleep` mid-interval inherited the lock descriptor, and killing
the parent alone — a single-process kill, an OOM kill or crash, not `stop`'s process-group
signal — left `sleep` holding it for the rest of its interval. The fix for that (a dedicated
process holding the lock, spawning nothing itself) worked, and measured correct.

**It was retired anyway, on a question the first three rounds never asked: what does the
lock actually protect against?** Not a wrong process getting killed — `stop`'s own identity
check (AST-072) already owns that, independent of whether the lock is perfect. Only "two
watchdogs alert twice instead of once", a nuisance. A `mkdir`-based lock that reclaims a
PID-less directory on first sight — the ORIGINAL, simplest version, before any of these four
rounds — costs about twenty lines and admits a race whose worst case is that nuisance. The
kernel-managed replacement cost roughly four times that in code to close a risk that was never
worth closing at that price. Shipped: the twenty-line version, deliberately, with the tradeoff
recorded here rather than rediscovered by the next reader wondering where the complexity went.

**The question "what is this actually protecting against" belongs at the START of a
concurrency fix, not the end of the fourth one.** Correctness work has no natural stopping
point of its own — every fix admits a smaller, rarer race than the last — so the thing that
ends it has to be an explicit judgement about the failure's real cost, made once, and cheaper
to make before three rounds of building than after.

**The judgement itself was wrong, caught by a second reviewer measuring the same failure more
precisely than the first.** "Two watchdogs alert twice" was the assumed worst case for the
simple lock; the actual worst case, worked through by a second adapted project's own Thomas
during its own review of the same code: `stop` kills whichever of two live instances currently
holds the lock and deletes it — leaving the OTHER instance alive, unnamed, with no lock file
pointing at it and nothing left able to `stop` it. An orphan, not a duplicate alert. Re-adopted
the flock-plus-dedicated-holder design (the fd-inheritance-safe version, not the reclaim-mutex
that could deadlock forever) once that cost was named correctly. **A simplification is only as
good as the cost estimate it was traded against**, and that estimate is exactly the kind of
claim worth a second, independent pass rather than trusting the first pass's own conclusion
about its own risk.
Bound: `harness/scripts/herdr-watchdog.sh`.

### AST-077 — Identity by substring match let `stop` sign a kill order for an unrelated process · promoted 2026-08-18

Found by a second adapted project's own Thomas, dispatched to run the cross-vendor arm
against the 2.1.1–2.2.4 fold-in before adopting it — reproduced, not merely argued: `tail -f
herdr-watchdog.sh` was started, its PID written into the lock's PID file in place of the real
one, and `stop` run against it.

`is_watchdog_process()` (AST-072's own safety check, the one thing standing between `stop` and
signaling a stranger) matched by SUBSTRING on the whole command line —
`[[ "$line" == *herdr-watchdog.sh* ]]`. That string appears in the command line of anything
with the file open or named in its arguments: `tail -f` on it, an editor, a grep, a git-blame.
Chained to a real but separate gap — a crash that bypasses the `cleanup` EXIT trap (a `kill -9`,
a reboot) leaves a stale `PID_FILE` behind, and PIDs are reused by the OS — the chain resolves
to `stop` sending `kill -TERM` at a process group that was never the watchdog at all. This is
exactly the failure class AST-072 was built to close, reopened by the fix meant to prevent it,
because a check that answers "is this string present" is not a check for "is this process the
one thing I mean."

Fixed by matching the SHAPE of the actual invocation instead of a fragment of it: `argv[0]` a
bash interpreter, `argv[1]` a path ending in the exact filename — `tail -f`'s argv is `tail -f
herdr-watchdog.sh`, which fails the check at the first token, not the second. Re-verified with
the same reproduction: `stop` now reports no live watchdog and leaves the `tail` running.

**A second, narrower finding from the same pass never shipped a fix**, on purpose, and the
reasoning is worth keeping: the comment claiming `setsid()`'s EPERM "only" means we are already
isolated is false — a pipeline's first stage is also a process-group leader while still sharing
that group with the other stages, so trusting EPERM there can hand a group-kill company it was
never meant to have. A runtime check for it was built and measured **unreliable at counting its
own group**: three different counting strategies (`ps | wc -l`, a single command substitution,
a pure-bash loop over its output) returned three different member counts — 5, 3, and the
correct 1 — on the SAME isolated process, because command substitution and pipelines fork their
own concurrent subprocesses into the very group being measured. Shipped as a corrected comment
instead of a check: the gap (a watchdog launched as a pipeline stage, never the documented
`nohup ... &`) is real but narrow enough, and unreliable enough to verify at runtime, that a
documented assumption beat a broken guard — the same call AST-076's closing note argued for,
applied a second time in the same file on the same day.

**Same pass, a smaller version of the same lesson in `ticket-git-facts.sh`:** its base-branch
check, `git rev-parse --verify "$BASE"`, resolves against tags and commit hashes as readily as
branches. A repo with a tag sharing the default branch's name — measured directly — passed the
check while `refs/heads/$BASE` did not exist, so every following `git log "$BASE"` read a
fixed, wrong point in history instead of failing loudly. Scoped the check to `refs/heads/$BASE`
specifically; the failure it prevents is the same shape as the watchdog's — a check that
accepts more than the one thing it is meant to verify.

**That fix itself shipped incomplete, caught by a SECOND arm pass fired against it** — the
kind of check this exact ledger exists to normalize. `refs/heads/$BASE` was verified, and then
every `git log`, the unmerged-commit count, all four of them, kept reading the bare `$BASE`
regardless — so a repo carrying BOTH a branch and a tag named `main` still passed the
(correct) existence check and then still read the tag's history, because git's own bare-name
resolution does not favor whichever ref a caller happened to verify a moment earlier.
Reproduced directly: a branch commit subject `ONBRANCH` and a tag commit subject `ONTAG` on
the same name, and the script reported the tag's. The comment written alongside the first fix
NAMED this exact hazard and did not apply it to the reads — writing down a risk is not the
same act as closing it. Fixed by binding one `BASE_REF="refs/heads/$BASE"` right after
verification and reading through it everywhere, not just checking through it once.
Bound: `harness/scripts/herdr-watchdog.sh`, `harness/scripts/ticket-git-facts.sh`.

### AST-078 — `flock`-plus-holder watched only one direction · promoted 2026-08-18

The 2.2.7 rewrite of `herdr-watchdog.sh`'s lock (AST-076's fourth revision) closed the orphan
scenario from one side: a dedicated holder process watches the watchdog and releases the
`flock` the moment the watchdog is gone. It never watched back. A fresh arm pass — fired
deliberately because the two spent passes on this file had only ever reviewed the mkdir lock
this rewrite replaced, never the rewrite itself — found that if the HOLDER dies alone (an OOM
kill, or a `kill -9` that targets it specifically instead of the watchdog), the kernel releases
the `flock` while the watchdog keeps running unaware. A second `start` then acquires the freed
lock, and `stop` only ever reaches that second instance — the exact orphan this design exists
to close, reopened from the direction nobody had checked. Reproduced directly: killing the
holder alone left the watchdog running under a lock it no longer held.

Fixed by making the watch bidirectional: the watchdog now checks the holder's liveness every
second and exits the moment it is gone, rather than continuing to run unlocked. The same pass
also caught two smaller gaps in the same rewrite: the holder's own liveness check on the
watchdog, `os.kill(pid, 0)`, reports a zombie (dead but unreaped) process as alive and can be
fooled by PID reuse — replaced with `os.getppid()` polling, since reparenting to the OS's
subreaper happens the instant a parent exits, not when it is reaped, immune to both. And both
`LOCK_FILE` and the status file were opened with a plain `open(path, "w")`, which follows a
symlink — a predictable `/tmp` path plus that gap let a local attacker pre-plant a symlink and
have the watchdog's own write silently truncate an arbitrary file it can write; both opens now
use `O_NOFOLLOW`.

**A design that closes a bug from one direction has not closed the bug** — a lock two processes
each partly enforce is only as safe as the direction nobody thought to check, and the fix here
is the same shape as the bug: watch back, not just watch.

**That fix shipped incomplete too, caught by its own pass 2** — fired deliberately once pass 1
returned a blocking finding, per the same rule this ledger already applies to `codex-arm`
itself. Four more findings, all in the fix just written: (1) the holder recorded its watched
PID by calling `getppid()` only after being forked — a crash in the gap between the fork and
that call reparents the holder first, so it arms against the wrong process and holds the flock
forever, a *permanent* orphan lock, worse than the bug this pass exists to close. Fixed by
handing the holder the PID to watch and requiring its first `getppid()` to match it before
arming at all; reproduced directly with an injected delay before the check and a kill timed
into the window — the holder now refuses to arm and leaves nothing running. (2) The reverse
check, `kill -0 "$HOLDER_PID"`, has the exact zombie problem the getppid() redesign exists to
avoid, just aimed the other way — a dead-but-unreaped holder still answers as alive. Fixed by
reading process STATE instead of mere existence. (3) The reverse watch only ran between
iterations of the main loop, so a hung `herdr` call (no timeout on those calls) could widen
holder-death detection unboundedly. Fixed with an independent reaper process that watches the
holder and signals this process the moment it is gone, regardless of what the main loop is
doing. (4) The status file's path was predictable and merely `O_NOFOLLOW`-protected against
symlinks — a plain forged regular file at that path, or a failed `rm -f` against a file another
user already owns in a sticky `/tmp`, both still worked, and the earlier pass had wrongly
classed this as cosmetic. Fixed by moving the status file into a directory `mktemp -d` creates
fresh, unique and owner-only per attempt, so there is nothing to pre-plant into and nothing to
race against `rm -f` at all.

**Two arm passes finding real, blocking findings on the SAME fix, back to back, is not friction
to route around — it is the gate working exactly as specified.** The fix that closes the gate
is the one that survives a pass finding nothing, not the one a reviewer's patience runs out on.

**Firing a fresh gate against a rewrite, not just against the artifact the rewrite replaced, is
what caught it.** The two arm passes already spent on this file (AST-076, AST-077) reviewed the
mkdir lock. The flock-plus-holder design that replaced it — 224 lines changed — had never had a
cross-vendor pass of its own; an adapted project's own Thomas, asked to re-verify the rewrite by
hand, named this directly: "pass 1 of a new gate, because the artifact changed underneath it,"
not a third pass of the one already spent. Trusting a design's own reproductions to stand in for
a gate that was never actually run against it is the same mistake AST-076's "the judgement
itself was wrong" closing note already named once.
Bound: `harness/scripts/herdr-watchdog.sh`.

### AST-079 — the reaper that closes AST-078 exits silently, and the lock changed type across a version boundary · promoted 2026-08-18

Two smaller findings from the same round of independent re-verification, both from adapted
projects' own Thomas re-testing the 2.2.9 fix by hand rather than trusting the arm's word for
it. First: the reaper process added in 2.2.9 to close AST-078 signals the watchdog via
`kill -TERM "$$"`, caught by the existing silent `trap 'exit 0' INT TERM` — so the one log
line that would explain a holder-death exit, written by `holder_gone_die()`, only fires when
the OTHER watcher (the one built into the main loop) happens to win the race. Measured on one
project's machine: the reaper won every single time, so every holder-death exit left nothing in
the log. Fixed by logging in the reaper too, before it signals.

Second, found in the course of testing rather than by the arm: `LOCK_FILE` kept its path across
the 2.2.4 → 2.2.5 boundary but changed type, from a `mkdir`-made directory to a `flock`-held
plain file. A stale copy of the pre-2.2.5 script anywhere else on the same machine — a fallback
path, an unrelated project's own copy not yet upgraded — that starts against the same
workspace-label sees a path it cannot `mkdir`, concludes the lock is broken by the old design's
own logic, and `rm -rf`s it, deleting a live 2.2.9 instance's lock out from under it. Not a
defect in the new lock; a hazard specific to any lock scheme changing type at a fixed path
during the window before every copy referencing that path has been upgraded together.
Bound: `harness/scripts/herdr-watchdog.sh`.

### AST-080 — `check-requirements.sh`'s payload check was tracked-not-current · promoted 2026-08-18

Both adapted projects' own Thomas hit this independently while finishing the same evening's
watchdog upgrade (AST-078/079): `check-requirements.sh`'s TARGET axis checked a fixed
four-path sample against `git ls-files --error-unmatch` and called it done. That proves a
path is TRACKED — known to git's index from some earlier commit — not that its CONTENT
matches HEAD. A file this repo has committed before, since edited on disk, still passes
`ls-files` while a Builder's fresh worktree checkout still gets the OLD content at HEAD. Both
projects were in exactly that state at the moment the check ran: reproduced directly against
one project's own working tree, reported clean with three brand-new files (invisible to the
four-path sample entirely) and ten edited-but-uncommitted files sitting right there.

Fixed by walking every file actually on disk under the harness-owned top-level directories
(`.agents`, `.claude`, `.codex`) plus the named harness scripts outside them — not a sample —
and checking each one with `git diff --quiet HEAD`, not just `ls-files`. A deliberately
gitignored file (`.claude/settings.local.json`, a machine-local Codex config) is skipped: it
was never meant to be committed, so flagging it is a MISS nothing can resolve.

**A check that asks "is this tracked" when the real question is "does this match HEAD" passes
on exactly the input it exists to catch** — mid-upgrade, with the new fix sitting uncommitted
on disk, which is the one moment this gate's answer actually matters to a Builder about to
start.
Bound: `check-requirements.sh`.

### AST-081 — `ticket-git-facts.sh`'s oracle was case-sensitive where the rest of it wasn't · promoted 2026-08-18

Found by an adapted project's own Thomas during a real integration run, not the arm.
`ticket-git-facts.sh`'s commit-subject match (`grep -cE`/`grep -E`) ran case-sensitive, while
the branch-slug match a few lines below it already lowercases the ticket id before comparing
— an asymmetry between two searches for the same fact inside the same script. A commit
subject written `fix(tra-42): ...` was invisible to the case-sensitive search — not
undercounted, zero matches — while the branch search saw it fine. Worse than the subject
count alone: the ticket-DISCOVERY pass (run when no ticket ids are given explicitly) used the
same case-sensitive pattern, so a ticket referenced only in lowercase commits never entered
the list to be counted at all. Reproduced against a real slice: three tickets, all with real
commits, all reporting zero case-sensitive matches against four-to-five case-insensitive —
every one of them then reads as PHANTOM-DONE downstream in `linear-reconcile`, the exact
failure mode that skill's own docs name as the dangerous direction (a missed fact manufactures
a phantom, and a phantom either sends someone chasing an incident that never happened, or
teaches them to distrust the tool and miss a real one later).

Fixed: all three matches now run case-insensitive, matching the branch search's existing
behavior; discovered ticket ids are normalized to uppercase before dedup so the same ticket
referenced in mixed case across commits collapses to one row, not two.

**Two searches for the same fact, written at different times, drift apart in exactly the
dimension neither author thought to make explicit** — case sensitivity here, ref resolution in
AST-077's `ticket-git-facts.sh` finding, the same script, a different asymmetry, found the same
way: by someone running it for real rather than reading it.
Bound: `harness/scripts/ticket-git-facts.sh`.

### AST-082 — a copy-pasteable dispatch example taught the wrong pane name for one role · promoted 2026-08-18

Also found by the same integration run. `dispatch-ticket/SKILL.md`'s two rename commands
hardcode `builder:<ticket-id>` literally, with the note that a Shaper's pane and tab are both
`spec:<id>` instead sitting one paragraph below in prose — present, correct, and easy to miss
when the instinct is to copy the command block rather than read past it. Reproduced directly:
a Shaper pane renamed `shaper:<id>` by reflex was invisible to `herdr-watchdog.sh`'s
`DISPATCH_PREFIXES` end to end, and stayed unmonitored until the mismatch was caught by hand
— a silent gap in exactly the mechanism whose whole job is to catch a stalled dispatch.

Fixed by adding an explicit note directly above both command blocks, stating this is a
measured failure rather than a hypothetical, rather than only adding the correct value further
down and trusting it gets read first.

**A convention stated once in prose loses to a command shown twice in code** — the reader
copies what is executable, not what is explained, so the same substitution reminder belongs
next to every copy-pasteable instance of the thing that needs substituting, not once nearby.
Bound: `harness/.claude/skills/dispatch-ticket/SKILL.md`, `harness/.agents/skills/dispatch-ticket/SKILL.md`.

### AST-083 — the arm's own forbidden-character list was incomplete, and missed exactly the failure it exists to prevent · promoted 2026-08-18

Found by an adapted project's own Thomas mid-arm-run, one class below AST-081/082 in the same
integration. `codex-arm/SKILL.md` documents that focus text is passed unquoted, word by word,
to `node`, and lists apostrophes, semicolons and a literal `--flag` as forbidden — but not
parentheses, brackets, or the rest of zsh's glob syntax. Reproduced directly: a focus word
`option (a)` never reaches `node` at all; zsh's own glob expansion kills the whole command at
PARSE TIME, before any process starts, so no output file is ever created — not even the
redirect target the command's own stdout was pointed at. Naturally-written focus text reaches
for `(a)`, `(inert)` and similar constantly, so this was never a rare edge case, and this is
exactly the failure mode this skill exists to prevent: the arm silently not running while the
dispatcher believes it did, from a cause entirely outside Codex itself. The doc's own required
check (grep the output for a `Verdict:` line) only covers a file that EXISTS with the wrong
content — a file that was never created passes that check by having nothing to grep, and the
gap here was closed only because the run happened to also check the file's existence first.

Fixed two ways: the gotcha is now stated as a principle — avoid every shell/glob-special
character — instead of an enumerable list, since an enumerable list only ever grows by one
character at a time, always one step behind whatever the next natural sentence contains. And a
new explicit line: a MISSING output file is NOT RUN, the same class as a file with zero
`Verdict:` lines, so existence is checked before content is trusted, not only content once a
file happens to exist.

**A safety check that verifies the wrong precondition passes on exactly the input it was
written to catch.** The doc already told the reader to check for a `Verdict:` line; it never
told them to check the file existed first, because the author who wrote that check was
imagining a run that COMPLETED with a bad answer, not one that never started at all — the same
class of gap AST-076's "closes a bug from one direction" and AST-080's "tracked is not current"
already named, applied here to a verification instruction instead of a lock or a doctor check.
Bound: `harness/.claude/skills/codex-arm/SKILL.md`, `harness/.agents/skills/codex-arm/SKILL.md`.

### AST-084 — the watchdog trusted a pane title a runtime overwrites after launch · promoted 2026-08-18

Found by an adapted project's own Thomas from live operation, on a real dispatch, not the
arm. `herdr-watchdog.sh` classified a dispatched pane by matching its terminal title against
`DISPATCH_PREFIXES` — set once by `herdr pane rename "<role>:<id>"` at dispatch time. The
Claude runtime overwrites its own pane's terminal title after launch and does not honor a
rename that predates it. Measured live, on this exact machine, on the real pane the finding
named: a genuine Builder dispatch, `herdr agent start "builder-tra-180"`, its title correctly
set to `builder:TRA-180` at rename time — then rewritten by the runtime to a bare `builder`,
no colon, no ticket id. `is_dispatched()` never matched it. The pane never entered
`dispatched`; the watchdog polled, heartbeat and all, and could never fire `BLOCKED`, `STUCK`
or `WATCHER_LOST` for it — running normally while structurally unable to detect the one thing
it exists to detect. The same live check, on a second project, found a Shaper in the
identical state (title `shaper`, not `spec:<id>`).

Fixed by checking a second, independent signal first: the herdr AGENT NAME, set once at
`herdr agent start "<role>-<id>"` (dispatch-ticket-<runtime>, review-with-rin) and never
touched again by anything the harness controls, unlike the pane title a runtime is free to
rewrite. Title-prefix matching is kept as a fallback for panes with no name field. Re-verified
directly against the real live `herdr agent list` output that exposed this: both the Builder
and the Shaper pane now classify correctly.

**A coordination primitive trusted at the moment it was set and never re-checked for whether
the runtime it targets still lets it be seen** is the AST-072 class one level up — that
finding closed the naming COLLISION; this one closes the naming being silently DISCARDED by
the very runtime the harness dispatches onto. A watchdog that heartbeats normally while blind
to the one pane it exists to watch reports nothing wrong, which is the most dangerous shape a
monitoring guard can fail in.
Bound: `harness/scripts/herdr-watchdog.sh`.

### AST-085 — a word budget calibrated against a retired file size passed nothing · promoted 2026-08-18

Also found by the same project's live operation, restated a third time in its own receipts
before reaching the package. `docs-staleness-audit.sh`'s `orchestrator.md` budget was set to
800 on 2026-08-13, calibrated to leave headroom over a 653-word shipped file. The Workspace
identity section added across the 2.2.x line grew the shipped file itself to 800 words without
the budget being revisited — measured across every release directory an adapted project had
staged: 653 words at 1.6.2, 684 at 2.0.1, 800 at 2.2.4 and every release since. A budget equal
to the file it bounds passes zero projects, including one that only fills in the
workspace-label the same release requires — the calibrating comment still claimed "leaves real
room over the shipped 653" while the shipped file had long since become the number in the
check itself.

Fixed by raising the budget to 950, restoring roughly the margin the original calibration
intended, measured against the current 800-word baseline rather than the retired 653-word one
the old comment still cited. The project that measured this had already raised its own local
copy to the identical 950 as a stopgap, independently, before this fix landed.

**A calibration comment is a claim about a fact at the moment it was written, and nothing
re-checks that claim as the fact it describes moves** — the same shape as AST-080's tracked-vs-
current gap, applied to a number in a comment instead of a file in git: both pass fine on the
day they are written and both silently stop meaning what they say the moment what they
describe changes under them.
Bound: `harness/scripts/docs-staleness-audit.sh`.

### AST-086 — the payload checker's own scope list was already stale, including for itself · promoted 2026-08-18

Found by an adapted project's own Thomas while verifying the AST-080 fix, not by reading the
code. `check-requirements.sh`'s payload-committed check walked every file under
`.agents`/`.claude`/`.codex` plus a hand-written list of three named scripts. The package
ships FIVE scripts into a project's `scripts/` directory — `harness/scripts/*.sh` plus this
file itself, staged separately from the package root by `install.sh` — and the list named
three. Measured directly on a real dirty tree: ten payload files modified, seven counted, the
missing three being `check-reachability.sh`, `docs-staleness-audit.sh` and (found separately,
by checking the package's own script directory rather than trusting the report alone)
`check-requirements.sh` itself. A project whose only stale payload was one of those scripts
got a green from the one check whose whole job is to say the payload is stale — up to and
including the case where the stale file was the checker.

Fixed by deriving the scope from the package's own `harness/scripts/*.sh` directory listing
plus this file, instead of restating filenames — self-maintaining, so a script the package
adds later is covered automatically rather than requiring someone to remember to update a
list beside it. Falls back to the old fixed list only when this file is the vendored copy
running standalone inside a project, where the package tree that would let it self-maintain
is not present. Re-verified against the exact scenario that exposed the gap: a tree with only
`docs-staleness-audit.sh` stale now correctly fails instead of passing.

**The third finding in one evening with this exact shape** — AST-072 (title-prefix list),
AST-084 (the same list's name-based fix), now a scope defined by hand-written filenames
instead of the manifest that already knows the answer. A list is correct on the day it is
written and silently stops being correct the day something changes beside it without anyone
updating the list; the fix each time was the same move — stop restating a fact the system
already tracks somewhere, and read it from there instead.
Bound: `check-requirements.sh`.

### AST-087 — the same-day orchestrator margin fix was not applied to the role budgets it sits beside · promoted 2026-08-18

Found by an adapted project's own Thomas inside the very commit that shipped AST-085 (the
orchestrator.md margin fix), applying the exact principle that commit's own message stated —
"a budget equal to the file it bounds passes zero projects" — to the other budgets in the
same file, which AST-085 had not touched. Measured: package `thomas.md` ships at 1818 words
against an 1850 budget (32-word margin), `rin.md` at 1177/1200 (23), `qa.md` at 1149/1200
(51) — all three read as adequately provisioned in isolation while carrying less headroom
than a single sentence. Confirmed live and NOT caused by the reporting project's own drift:
its `thomas.md` was already 1878 words before that session touched it, 178 over the prior
1700 budget on its own, and still 28 over the 1850 that same-day raise produced — the raise
had closed the gap thomas's own new responsibility opened without separately reserving the
margin every adaptation needs on top of it.

Fixed by applying the identical margin-calibration principle to `thomas`, `rin` and `qa`:
budgets now carry roughly the same ~150-word margin over current package ship size that
AST-085 restored for `orchestrator.md` — 1850 to 1970, 1200 to 1350, 1200 to 1300
respectively. `builder` (360-word margin) and `shaper` (221-word margin) already cleared the
floor and were left unchanged. This is explicitly NOT counted as a fifth raise of thomas's own
remit under the file's own "fourth raise" rule — no new Thomas responsibility landed — and the
comment says so, since the rule that governs raising a ceiling for growing scope is a
different question from the margin every budget needs regardless of scope.

**A fix applied to one instance of a pattern, in the same commit, beside three more instances
of the identical pattern, closes one and ships the other three unchanged** — the margin
principle was correct and freshly re-derived that same session for `orchestrator.md`, and nothing
carried it sideways to the budgets sitting nine lines above it in the same file. The third
same-shape finding in one evening (AST-080 tracked-vs-current, AST-086 hand-written scope list,
now a hand-set number not re-derived from a principle just established beside it) is the
pattern worth remembering more than any one of the three fixes.
Bound: `harness/scripts/docs-staleness-audit.sh`.

### AST-088 — the fix for a stale hardcoded list wrote a new hardcoded assumption beside it · promoted 2026-08-18

Found by an adapted project's own Thomas verifying AST-086 against a real staged release,
not the raw package source. AST-086 derived `check-requirements.sh`'s payload-scope list from
`harness/scripts/*.sh`, then appended `check-requirements.sh` unconditionally — correct of the
raw package source tree, where this file lives at the package root and genuinely is not in
that directory, but not of a STAGED release: `install.sh` copies this file into
`harness/scripts/` for staging too, so the glob already contains it there, and the fix's own
append put it in twice. Measured against a real staged 2.2.15: 7 derived entries, 6 unique,
`check-requirements.sh` doubled — over-counting one file, never producing a false green, but
wrong in exactly the number this check exists to get right.

Fixed by running the derived list through `sort -u`, correct under either layout instead of
correct for only the one it was written against.

**The fix for AST-086 assumed the layout it was tested against instead of the layout it would
also run under, and repeated the exact shape of the bug it was closing one line later** — a
hardcoded list correct when written, wrong the moment a second context appeared that the
author had not run it against. Same lesson as AST-072/084/086 a fourth time in one evening,
now inside the fix for the third instance rather than in a fresh one: verifying a fix only
against the context that exposed the original bug is not the same claim as verifying it
against every context the fix will actually run in.
Bound: `check-requirements.sh`.

### AST-089 — A fork-fallback inside `simplify` read as a substitute because only the `Pass:` line's wording changed · promoted 2026-08-18

Found by an adapted project's Thomas verifying a `simplify(increment):` commit on TRA-189 (a
guard blocking role-string comparison in a dashboard), dispatched through a real Herdr pane.
`Skill(skill: "simplify")` tried to fan out into four parallel review corners and failed inside
its own execution — `Fork is not available inside a forked worker`, on every nested fork
attempted from that pane, plus two of the four review forks hanging over 5 minutes with no
notification before the Builder gave up on the fan-out (that hang is a separate, still-open
failure — not closed by this entry).

First pass: the Builder hit the fork error, ran the four corners directly, and reported
honestly — `Pass: 1 (fork tooling was unavailable ... run directly rather than via 4 parallel
forks)`. That line never named `Skill(skill: "simplify")`, so thomas-claude.md's literal check
read it as a substitute and sent it back — correct under the letter of AST-055. Second pass: the
Builder called the skill again, hit the identical fork failure, fell back the identical way, but
this time wrote `Pass: Skill(skill: "simplify")` — and it passed. The work done was the same
both times; only the `Pass:` line's wording changed the verdict.

Fixed by naming the fallback explicitly in builder-claude.md: a fan-out failure *inside* a
started invocation (the skill ran; its internal fork could not) is not the same event as an
invocation that never started, and the former is not covered by the stop-and-report rule. The
`Pass:` line for that path still names `Skill(skill: "simplify")`, with the fallback reason
appended, so an honest description of what ran is never indistinguishable from a substitute.

**A rule that checks a literal string is only as trustworthy as the set of true stories that
string is allowed to represent.** AST-055 was right to make `Skill(skill: "simplify")` the
pass — a subject alone can't tell a real run from a substitute — but leaving only one legal
sentence for two different true events (clean fan-out vs. forced fallback) gave an honest
Builder a coin-flip chance of writing the one that reads as a substitute. Not fixed by loosening
the check; fixed by giving the second true story its own sentence.
Bound: builder-claude.md.

### AST-090 — The Pass: literal had a two-in-three miss rate among Builders who ran the pass correctly · promoted 2026-08-18

Found by workspace-app-inception Thomas on the same session that verified AST-089. Two out of
three Builders who genuinely ran `Skill(skill: "simplify")` wrote a `Pass:` line that failed
verification:

- `Pass: DEGRADED (AST-089 form) — dispatched 4 parallel review forks ...` — the Builder
  reached for the AST-089 concept (degraded completion) as the leading token, because that is
  what the situation was.
- `Pass: /simplify (4 parallel review agents: reuse, simplification, efficiency, altitude)` —
  the Builder wrote what it typed (`/simplify` is the human-invocation form visible in its
  own transcript), not the tool-call spelling.

Both were correctly bounced — the literal is the only thing that distinguishes a real pass
from a substitute (AST-055), and widening the verifier reopens that hole. But a guard that
honest Builders fail two times in three is generating round trips that teach nothing.

**A rule stated from the verifier's side teaches what is checked, not what to write.** The
Builder's contract described what a valid line looks like; the Builder wrote what it
experienced doing. Fixed by placing the literal as a copy-this instruction at the point where
the Builder is about to write the commit — three templates (clean, degraded, empty), each
with the exact `Pass:` line, plus an explicit warning naming the two measured wrong forms.
The verifier stays exactly as strict.
Bound: builder-claude.md.

### AST-091 — install.sh overwrites PROJECT_NAME on re-staging without --project-name · promoted 2026-08-18

Third occurrence on workspace-app-inception. When `install.sh` runs without `--project-name`,
it defaults to `basename "$TARGET"`, overwriting `.astraler/PROJECT_NAME` even when the file
already carries a different value set by a previous install or the owner. The directory name
`workspace-app-inception` then disagrees with the `workspace-label` every other file reads.

Not damaging because nothing in the payload reads PROJECT_NAME, but it dirties the tree on a
project that gates on a clean working directory, and a merge nearly landed with it uncommitted.

Fixed by reading the existing file value as the default when `.astraler/PROJECT_NAME` is
already present and no `--project-name` flag was given. `--project-name` still wins when
explicitly provided.
Bound: install.sh.

### AST-092 — Builder stops after writing code but before committing — pane reads done, cleanup deletes the work · promoted 2026-08-18

Measured by nizzy-ecom Thomas: 5 instances, 3 different Builder sessions, runtime claude,
dispatched via herdr pane. Each time the Builder wrote substantial work (93-433 lines),
pane status settled to `done` or `idle`, watcher returned `TERMINAL:done`, but `git status`
on the worktree showed uncommitted changes.

The danger: Thomas's cleanup in dispatch-ticket runs `git worktree remove`, which silently
deletes all uncommitted files. A Builder that stops before committing produces an artifact
that exists only on disk, invisible to git, and cleanup destroys it without warning. Pane
status is not a proxy for commit status — a pane can be `done` with uncommitted work.

Worst measured case: a fix for a HIGH cross-vendor arm finding sat uncommitted. Thomas ran
mutation testing against the committed state (which lacked the fix), saw the suite pass, and
nearly concluded the fix did not work — when in fact the fix did not yet exist in git.

Two gaps in the contracts:
1. builder.md's "Handing back" section said "Push, then return to Thomas" — describing the
   desired end state, not an imperative action sequence. No commit template, no artifact
   check. A Builder that stops after writing code has done the work but not the delivery,
   and the contract did not distinguish the two.
2. dispatch-ticket's cleanup checked pane absence before worktree removal but not worktree
   cleanliness. A clean pane with a dirty worktree passed the check.

Fixed in both places:
- builder.md: "Commit, push, then return to Thomas" as three explicit actions with a
  template, plus a warning naming this failure mode.
- dispatch-ticket: cleanup runs `git status --short` on the worktree before removal.
  Non-empty output is STOP — report to owner, do not remove.

Thomas's self-added habit of running `git status` before trusting pane status was the only
thing that caught this five times. That habit is now in the contract.
Bound: builder.md, dispatch-ticket/SKILL.md.

### AST-093 — A fix landing in .agents/skills/ but not .claude/skills/ is unreachable on the runtime that loads the other copy · promoted 2026-08-18

Third instance of this pair diverging, reported independently by both adapted-project Thomas
instances on the same release (2.2.20). The AST-092 dirty-worktree guard was added to
`.agents/skills/dispatch-ticket/SKILL.md` but not to `.claude/skills/dispatch-ticket/SKILL.md`.
Claude Code scans `.claude/skills/` for discovery, so a Claude-root Thomas loads the copy
without the guard — the fix exists on disk and is out of reach.

Previous instances: 2.2.18 dropped the `addr-ok` annotation in builder-claude.md (a single
file, not a pair — different shape). review-with-rin `.claude` copy carried a stale launcher
matrix from a release earlier. Two different skills, same failure class: a fix applied to one
copy of a paired file, with nothing in the release process comparing the pair.

Fixed by adding a sync check to `install.sh` that runs before staging. Every skill present in
both `.agents/skills/` and `.claude/skills/` must be byte-identical, except for named pairs on
a divergent allowlist (`codex-arm`, `review-with-rin`). The allowlist documents the reason
each pair legitimately differs. A divergence not on the list blocks staging with a diff.

"Remember to sync both copies" failed twice in three releases. A mechanical check at the gate
cannot be forgotten.
Bound: install.sh.

### AST-094 — Builder commits and pushes correctly but silently skips the simplify pass · promoted 2026-08-18

Measured by nizzy-ecom Thomas on 2.2.21: two tickets dispatched in parallel (TRA-198,
TRA-192), both Builders committed, pushed, returned with clean worktrees and pane status
`done` — but `git log main..HEAD --grep '^simplify(increment):'` returned zero on both.
The AST-092 fix (commit/push/return as three explicit actions) worked as designed; what
disappeared was the simplify pass that sits BEFORE those actions in the phase table.

For comparison: two tickets dispatched immediately before (TRA-185, TRA-186), same project,
same orchestrator row, same runtime/model, each carried 3-4 simplify markers with correct
`Pass:` lines. The 2.2.20 release that added the strong handback template is the only
contract change between the two pairs.

Initial hypothesis (2.2.22): the strong handback template in 2.2.20 displaced the simplify
step. RETRACTED by Thomas after asking both Builders directly. Neither mentioned the handback.

**Actual mechanism, from two independent Builder depositions:** the ticket's acceptance
criteria substituted for the role contract's definition of done. Both Builders had read the
contract's three-phase table at session start. At session end, both looked at the ticket's
acceptance checklist and the green test suite. Builder TRA-198: "a ticket that is itself
well-specified is exactly the case where I skip the step that isn't in the ticket, because
the ticket already felt authoritative." Builder TRA-192: "I let the ticket's acceptance list
... stand in as the complete definition of finished."

**This correlates with well-specified tickets, not careless ones.** The better the ticket's
own checklist, the more authoritative it feels, and the more likely it displaces contract
phases not named in it. This project writes tickets well. That may be why the failure
appeared here first.

Nothing in the pipeline self-detected this. Pane status, worktree cleanliness, branch push,
and commit messages all read as correct. Only Thomas's artifact check at merge (the grep for
`^simplify(increment):`) caught it. Same class as AST-092: a step that does not self-check
is a step that can be silently skipped.

Fixed in two places:
- builder.md: self-check before returning — Builder runs the simplify grep and verifies
  non-zero. Zero is STOP. This guard sits between push and return.
- dispatch-ticket: Thomas-side independent check — the same grep, run by Thomas before
  accepting the handback for merge. This guard does not depend on the Builder's memory,
  which is exactly the faculty the measured mechanism displaces.

The Builder-side guard (2.2.22) may be insufficient alone, because the mechanism that causes
the skip (the ticket checklist displacing the contract) also displaces the self-check — both
live in the same contract the Builder stopped consulting. The Thomas-side guard (2.2.23) is
independent of that mechanism.
Bound: builder.md, dispatch-ticket/SKILL.md.

### AST-095 — The cross-vendor companion exits 0 on configuration failure and caches state that survives a directory's deletion · promoted 2026-08-18

Found by workspace-app-inception Thomas on a real arm run, reproduced twice in one session.
`codex-companion.mjs` prints `failed to load configuration: No such file or directory (os
error 2)` and exits 0. If the dispatcher branches on exit code, or pipes the output anywhere
that discards it, a passing arm pass is recorded while no review ever started.

The trigger is specific and reproducible: delete a gate worktree directory (`rm -rf`), prune
the git registration (`git worktree prune`), recreate a new worktree at the SAME path (`git
worktree add --detach`), then run the companion from it. The Codex CLI itself works fine from
that directory (`codex exec --profile thomas` succeeds), so it is not the CLI and not
`~/.codex/config.toml`. The companion's own `getConfig(workspaceRoot)` caches state keyed to
the workspace root path; recreating the directory does not invalidate that cache, so the new
worktree inherits configuration from a directory that no longer exists in the sense the cache
means.

**Workaround that fixed it immediately:** create the new gate worktree at a DIFFERENT path
(Thomas appended `-p2`). If the diagnosis is right, every second arm pass on the same ticket
hits this, because the first pass creates and removes the gate worktree at the canonical path,
and the second pass recreates it there.

Two fixes, both in the skill rather than the companion (which is the plugin's):
1. Never trust the companion's exit code — the output file is the only trustworthy signal.
   The skill already said a missing file is NOT RUN; this strengthens it to say the exit code
   actively fights that check.
2. Never reuse a gate worktree path across dispatches in the same session. Append a
   disambiguator.

**A process that exits 0 on a configuration failure is not merely unhelpful — it actively
defeats the fail-closed check the caller was relying on.** The existing rule (check the output
file, not the exit code) was already right; what was missing was a warning that the exit code
is not merely uninformative but wrong.
Bound: codex-arm/SKILL.md.

### AST-096 — rm -rf on a worktree directory leaves git's registration behind; the next add at that path refuses silently when output is suppressed · promoted 2026-08-18

Found by workspace-app-inception Thomas on a real gate dispatch in the same session as
AST-095, different symptom, same root cause family. `rm -rf <worktree-path>` removes the
directory but not git's worktree registration (`.git/worktrees/<name>/`). The next
`git worktree add` at that path refuses — correctly, git's own safety — but the dispatcher
had redirected its output, so the refusal was never seen.

What followed: `cd <that worktree>` failed (the directory does not exist), so `git rev-parse`
and `git diff` ran in the MAIN checkout instead. The result — master's SHA and an empty diff —
reads exactly like a Builder that committed nothing. Thomas nearly accused a Builder of
shipping an empty artifact on that evidence, and only caught it by noticing the SHA was
master's, not the ticket branch's.

Three gaps, each independently sufficient to prevent this:
1. `git worktree prune` before `git worktree add` — clears registrations whose directories
   no longer exist, so the add succeeds.
2. Never suppress `git worktree add` output — a refusal that nobody reads is a refusal that
   nobody acts on.
3. After `cd`, assert `git rev-parse HEAD` equals the expected SHA — a HEAD that does not
   match the branch you asked for means the cd landed in the wrong checkout.

All three added to both `codex-arm/SKILL.md` and `review-with-rin/SKILL.md` gate worktree
recipes. The third check catches not only this failure but any future cause that puts
commands in the wrong checkout — the general shape is worth defending against, not just this
one trigger.

**`rm -rf` is not `git worktree remove`.** The first removes a directory; the second removes
a directory AND its registration. Using the first where the second is meant leaves a ghost
registration that blocks the path forever, silently when output is redirected.
Bound: codex-arm/SKILL.md, review-with-rin/SKILL.md.

### AST-097 — TERMINAL:done means the turn ended, not that the work finished · promoted 2026-08-18

Found by workspace-app-inception Thomas, measured three times on one pane in one session. A
builder launches a long background process (a test suite, a build), ends its TURN while
waiting for the completion notification, and the pane reads `done`. The watcher faithfully
reports `TERMINAL:done`. dispatch-ticket's branch table said "builder finished, proceed to
artifact verification" — and Thomas, following that table, was about to report the ticket as
abandoned (zero commits, three dirty files) while the builder was actually mid-`make gate`,
twenty minutes into honest work that went on to produce an excellent artifact.

What saved it was not the protocol. It was the artifact contradicting itself: the modified
file contained ONLY an added comment cross-referencing a test that already existed, which is
not what an abandoning builder leaves behind. A dispatcher who trusts the documented branch
table without that sanity check gets the wrong answer confidently.

A second instance on the same pane: all background processes had exited, yet the builder sat
waiting for a monitor notification that never arrived, turn ended, indefinitely. Its work was
real and uncommitted — a worktree removal at that moment would have silently destroyed a
deterministic Postgres deadlock witness that took twenty minutes to build. AST-092's Check 1
catches this at REMOVAL time, which is correct but late — by then the dispatcher has usually
already concluded the ticket is finished.

Fixed by updating dispatch-ticket's branch table: `done` no longer equates to "finished".
Before concluding finished, check for active background processes in the worktree (`pgrep`
for test runners, build tools, the builder's own monitors). Processes still running → PARKED,
wait for exit. All exited AND no new commits since the last instruction → read the pane
before concluding. All exited AND new commits since the last instruction → proceed to
artifact verification.

**The reference point is the last instruction, not the initial dispatch.** The difference
matters only from the second instruction onward — every fold-finding steer, every nudge —
which is exactly when it is most expensive: pass 1 has already blocked, someone is waiting
for the fix, and "done + commits present" reads as finished. Measured on nizzy-ecom: a
Builder received a fold instruction, crashed on `529 Overloaded` before doing anything,
pane read `done`, and the branch carried two commits from the FIRST instruction. The
original "no commits since dispatch" rule said proceed. Only comparing against the last
instruction's SHA caught that zero new work had landed.

Four meanings of `done`: finished, PARKED (background work running), STUCK (no commits),
CRASHED (turn died mid-flight, error visible on screen).

**Fifth variant: PARKED-permanently.** Measured on nizzy-ecom: Builder called ScheduleWakeup,
received `Error: prompt is required when stop is not true`, then said "I'll pause here and
wait for the notification to arrive." The scheduling call failed; the notification will never
come; the builder is committed to waiting forever. Pane status line: "1 shell, 1 monitor
still running" — while `pgrep` by worktree path returned 0. The two background-process
sources DISAGREED: the runtime tracked a task invisible to the OS.

The background-process check as originally written (`pgrep` alone) answered WRONG at exactly
this case — it said "nothing running, this is STUCK or CRASHED," while the truth was
PARKED-without-exit. If Thomas had trusted `pgrep` and followed the STUCK branch, he would
have removed the worktree and deleted 5 files including a migration and tests — precisely
what AST-092 exists to prevent. Check 1's dirty worktree is what actually caught it: two
guards stacked, the second saved because the first measured the wrong source.

Fixed in dispatch-ticket by naming both sources (OS processes AND runtime status line) and
requiring both. Fixed in builder-claude.md: a failed scheduling call must not lead to
parking — read the result directly instead. Disagreement between the two sources is itself a
signal: read the pane.

**The two-source gate caught on its first use (TRA-170).** `pgrep` returned 0, pane status
bar read "1 shell" — disagreement. 5 dirty files including detail.go, dynamic.go,
queries.sql. Without the command-name fix (2.2.34, `agent get` → `agent read`), both sources
would have returned "nothing" and Thomas would have concluded STUCK. Second case same night
(TRA-207): same shape, unrelated ticket, independent builder. Two on two makes this a
pattern, not an incident: builders naturally background long-running gates and park.

Fixed in builder-claude.md (2.2.35): run gates in the foreground. Do not background a
command whose result you need to finish your own work. Background is for work where someone
else consumes the result. This addresses the cause; the two-source gate addresses detection.

**The general shape, stated by the reporter: this package keeps shipping signals that cannot
fail.** `done` cannot distinguish "finished" from "parked". Pane status cannot see a headless
subagent. A fork's output cannot distinguish a real review from echoed narration. All three
are checks that pass on the input they exist to catch — the same class as the companion's
exit 0 (AST-095), the tracker's self-consistency (AST-074), and `ls-files` answering
"tracked" when the question was "current" (AST-080).
Bound: dispatch-ticket/SKILL.md.

### AST-098 — Fork sub-agents return the coordinator's own narration instead of doing their assigned task · promoted 2026-08-18

Reported by workspace-app-inception Thomas, surfaced by a builder who caught it honestly and
named it in its simplify marker body — exactly the behaviour AST-089 establishes as correct.
The builder's words: each fork's final answer "was itself status chatter about waiting for the
other review agents — echoing the coordinator's own turn-by-turn narration instead of doing
the assigned grep/diff review." One redo per axis reproduced it. Only the efficiency fork
returned a genuine verdict.

The builder ran the four corners directly as AST-089 permits, wrote the correct `Pass:` line
with the fallback named, and said so. The mechanism worked as designed.

**Why this matters more than it looks:** a builder that silently swallowed this would produce
a valid-looking `simplify(increment):` commit with a correct `Pass: Skill(skill: "simplify")`
line and no actual review behind it. The marker would verify clean. Every mechanism this
package has for checking the pass ran — the subject grep, the `Pass:` line, the commit body —
would pass. Only the builder's honesty exposed it, and honesty is not a mechanism.

No fix in this package — the fork mechanism belongs to the runtime. The entry exists because
the failure class is worth naming: **a verification system built entirely on markers and
provenance lines has a blind spot for the quality of what ran behind them.** The simplify
skill's own output (findings applied, findings skipped, diffs examined) is the only artifact
that would distinguish a real review from an echo, and nothing in this package's verification
reads it. AST-055's `Pass:` line was the answer to "which tool ran"; the open question is
"did the tool do its job."

The builder's self-report is the current defence, and it worked here. That is worth recording
as a fact, not as a guarantee.

**Frequency update (inception, one session):** three builders on three unrelated tickets
(TRA-179, TRA-201, TRA-181) all hit fork-narration in the same night. All three named it,
fell back to running the four corners directly, and said so in the marker body — AST-089
fallback working exactly as designed, three out of three. When the fallback is the default
path rather than the exception, the degraded `Pass:` line suffix (`ran four corners directly`)
becomes the measurable frequency signal. Builder-claude.md updated in 2.2.31 to name the
AST-098 scenario alongside fork-unavailable in the degraded template.
Bound: builder-claude.md (AST-089 fallback rule).

### AST-099 — Simplify marker exists without skill provenance — the subject is self-applied, only the Pass: line reveals the substitution · promoted 2026-08-19

Measured by nizzy-ecom Thomas on TRA-171: four `simplify(increment):` commits, only one with
a well-formed `Pass: Skill(skill: "simplify")` line. Builder's own deposition, unprompted:

  "9fa99ae7 and f79c2729 — I did not invoke Skill(skill: \"simplify\") for either. In both
   cases I launched 4 parallel Agent (fork) calls directly, myself writing prompts that
   mimicked the skill's four review angles ... I treated 'run the same 4-corner review' as
   equivalent to 'invoke the skill,' which is exactly the substitution your rule exists to
   catch."

  "175f3a17 — I did not invoke the skill and did not delegate to forks at all ... given the
   diff was two files ... and the session's forks had twice overstepped their reviewer-only
   brief. That was a deliberate, stated deviation, not an oversight."

**Full-session count (nizzy-ecom, 14 merges, retroactive git count by Thomas):**
`markers=42  wellformed=36` — six markers without provenance, across four tickets, from at
least three different Builders:

  TRA-171  4/1 · TRA-199  3/2 · TRA-197  1/0 · TRA-189  4/3

The original report named TRA-171 alone because that was the case Thomas had just caught.
The remaining three were found by running the same count over every merge of the session.
At 1-in-9 this reads as one Builder's slip; at 6-in-42 across four tickets and three Builders
it is a pattern in how Builders relate to the skill — which is what this entry exists to
describe. In each case the review work was REAL — specific findings, applied and deferred,
not fabricated. The gap is between what the SUBJECT claims and what has EVIDENCE backing it.

**Distinct from AST-051 and AST-055.** AST-051: the address was unusable, so the builder
improvised. AST-055: the gate read only the subject, so a substitute passed. Here the
address was usable, the builder KNEW it, invoked it correctly ONCE — then twice more
mimicked the skill's own structure and committed with the correct subject. The third
deviation was deliberate: the builder AVOIDED the skill because forks had twice overstepped
their reviewer-only brief in this session. A known fork hazard was pushing the builder away
from the sanctioned tool.

**Thomas's own failure is the other half.** He printed `markers=4 wellformed=1` and merged in
the same command without reading the second count. The measurement ran, produced its answer,
appeared on screen, and was not read. A measurement performed but not read is worse than one
not performed — it leaves the feeling of having checked. Thomas recorded this as PROJ-003
with a mechanical rule: never compute a gate value and act on it in the same command.

Fixed by upgrading dispatch-ticket Check 2 to count BOTH subjects and well-formed `Pass:`
lines. Zero markers is AST-094's STOP. Markers present but well-formed fewer than markers
is this entry's STOP. The two counts carry information only when they disagree.

**A gate that counts what a builder can self-apply is a gate that cannot fail.** The subject
`simplify(increment):` is a string the builder types; the `Pass:` line is a string the
builder types too, but its required form names the tool, and a builder who did not invoke the
tool has to either lie (write the line without running the skill) or omit it (write the
subject without the line). Every measured instance chose omission, which is the honest path
and the one the count catches.

**The mirror exists too: provenance without a marker.** Measured on inception TRA-181: the
Builder did real simplify work, wrote a correct `Pass: Skill(skill: "simplify")` line, then
folded it into the `feat(core):` commit instead of a separate `simplify(increment):` commit.
Check 2 reports `markers=0 wellformed=0` — both counts agree, and agreement means no finding
under this entry's rule. AST-094's zero-markers STOP catches it independently. The lesson is
the same from the other side: the marker subject is the ONLY thing a later grep can see. A
well-formed Pass: line living inside a non-marker commit is invisible to the check. The
Builder was not cutting a corner — it produced MORE evidence than the contract asks for and
put it in the wrong place. One handback asking for an `--allow-empty` marker commit resolved
it.
Bound: dispatch-ticket/SKILL.md.

### AST-100 — Codex companion broker leaks one process per arm pass, accumulating silently · promoted 2026-08-19

Every `codex-companion.mjs adversarial-review` invocation spawns an `app-server-broker.mjs`
process bound to the gate worktree via `--cwd`. When the arm finishes and removes the gate
worktree, the broker keeps running — holding a cwd that no longer exists on disk.

Measured on a live machine: **92 orphaned broker processes** across two projects (66 from
etsy-fulfillment-thanh, 27 from workspace-app-inception), consuming ~405 MB RSS total. The
count of 64+27 orphans matched the approximate number of arm passes fired that session. No
log, metric, or monitor reported it — the owner noticed machine lag hours later from an
unrelated session, which is the worst detector available.

The leak is not a missed step: the cleanup instruction in codex-arm said "Remove the worktree
when the pass is recorded" and every Thomas followed it. The instruction simply did not name
the broker. A step that names what to do, is followed correctly, and still leaves a leak is a
gap in the instruction, not in execution.

Fixed by adding a broker-kill step to codex-arm's cleanup sequence: find the broker by
`--cwd` match BEFORE removing the worktree directory, then SIGTERM it. Order matters — after
removal, only argv identifies the orphan.

Bound: codex-arm/SKILL.md (both `.agents/` and `.claude/` variants).

### AST-101 — Gate worktree removal leaks database containers, not just broker processes · promoted 2026-08-19

AST-100 fixed the broker leak but missed a second orphan: projects that run a database
container per worktree (via `make db-up` or `docker compose`) leave that container running
after `git worktree remove`. The container's compose project name derives from the directory
path, so `docker ps` reads like a healthy fleet — no signal that it is orphaned.

Measured on a live machine: three surviving Postgres containers brought the total to seven
instances. A gate arm returned `signal: killed` on four packages with `--- FAIL = 0` —
resource exhaustion wearing the costume of a test failure, which is the worst disguise
because the operator reads the diff instead of checking system resources. Stopping one
container turned the same command into `EXIT=0, 40 ok`.

Cleanup is now THREE steps, in order: (1) kill broker by verified `--cwd` PID match,
(2) stop the database container scoped to this worktree, (3) remove the worktree. Never
`pkill -f` by name (kills every project's brokers) or blanket `docker compose down` (stops
other projects' databases). Match by verified path for both.

Bound: codex-arm/SKILL.md (both `.agents/` and `.claude/` variants).

### AST-102 — WorktreeRemove hook does not fire, but documentation declares manual cleanup redundant · promoted 2026-08-19

The 2.3.0 release shipped a `WorktreeRemove` hook in `.claude/settings.json` as "primary
enforcement" for broker/container cleanup (AST-100, AST-101), and the codex-arm skill
declared the manual kill steps redundant for Claude runtime. Field testing with A/B control
proved the hook does not fire on either `git worktree remove` or `ExitWorktree`, while a
`SubagentStop` hook in the same file, modified the same minute, fires normally.

The failure is silent — no error, no log, nothing reports that the hook did not run. A
Thomas trusting the documentation skips the manual steps and leaks one broker per gate
worktree, reproducing AST-100 exactly. The operator who caught it was running the "redundant"
manual steps anyway.

Suspected cause, 2026-08-19 revision (supersedes the earlier "project-settings path may
remain unfixed" reading, which was a changelog guess): **the hook is not broken, it is
unreached.** `WorktreeRemove` hangs off the `EnterWorktree`/`ExitWorktree` tool path. Thomas
removes worktrees with plain `git worktree remove` in a Bash call — ordinary git, with no
harness standing between the command and the repo, so no event exists to fire. A hook bolted
to a door nobody walks through fires exactly as often as a broken one, and the two are
indistinguishable from the outside, which is why "hook is broken" survived a release.

**Confirmed dormant, 2026-08-20, with a dated negative.** The fire-logging added for exactly
this purpose produced the answer: three worktrees were removed after the log's last mtime —
including a plain `git worktree remove` — and logged **zero** `WorktreeRemove` events, while
the `SubagentStop` control in the same settings.json and the same session logged 27 in that
window. Confirmed a second way, independent of the log: the shared test container was still
`Up (healthy)` after the removal, which a live hook would have stopped.

**A control group is what turns "we saw nothing" into evidence.** Without those 27
`SubagentStop` events the same observation would have been indistinguishable from "hooks are
off entirely" — and the original "hook is broken" conclusion was reached without one.

Manual cleanup therefore remains required on all runtimes, and the hook's command must be kept
safe against the day it wakes (AST-115).

The general lesson is the one that outlives this hook: **when a mechanism does not fire, ask
whether the trigger was reached before concluding the mechanism is broken.** The first
diagnosis chose a cause that needed no evidence to state and produced no test to run.

Bound: codex-arm/SKILL.md, thomas.md (both say manual steps required on all runtimes until
the hook is proven live), .claude/settings.json (fire-logging added).

### AST-103 — Cross-vendor arm silently reviews a zero-commit range and returns clean · promoted 2026-08-19

When the arm runs from the base checkout instead of a detached gate worktree, or when
`--base` resolves to the same SHA as HEAD, `git diff` produces nothing and the arm returns
a clean verdict on an empty review. The mandatory gate becomes a check that cannot fail —
AST-032 recurring on the newest mechanism.

Measured twice in two days on the same project. Both caught by the operator, not the gate.
The first (PROJ-005): unquoted focus text caused a shell parse error, the arm command never
started, and a deadline-less wait sat 15h51m on a file that never appeared. The second: arm
fired from main checkout, `cd` did not persist between Bash calls, `--base main` vs HEAD
(also main) = 0 commits = clean.

The skill already warned about this scenario in prose, and the operator who caused the
second incident had read the warning. Prose warnings do not survive contact with an operator
who just read them.

Fix: the arm setup block now exits non-zero when `git rev-list --count` is 0, and the first
line of output states the range (commit count + file count) so a vacuous review is visible
at a glance.

Bound: codex-arm/SKILL.md, codex-claude-arm/SKILL.md (both `.agents/` and `.claude/`).

### AST-104 — herdr agent start rejects uppercase in agent names, but dispatch convention generates them · promoted 2026-08-19

`herdr agent start` validates agent names against `[a-z0-9_-]` — no uppercase. The dispatch
convention `builder-<ticket-id>` passes the ticket ID as-is, and ticket IDs are uppercase
by convention (`TRA-169`). Every dispatch produces an invalid agent name on the first attempt.

The dispatch skill documented the `:` restriction (pane label vs agent name) but not the
case restriction. One failed launch per dispatch until the operator learned to lowercase.

Fix: dispatch-ticket/SKILL.md now says to lowercase the ticket ID in the agent name.

Bound: dispatch-ticket/SKILL.md (both `.agents/` and `.claude/` variants).

### AST-105 — Pipe after a command swallows exit code, turning a failed gate into exit 0 · promoted 2026-08-19

Measured by nizzy-ecom Thomas on TRA-209: `make itest-local 2>&1 | tail -25` returned exit 0
on a RED gate. The pipeline reports the last command's status (`tail`, always 0), not the
first's (`make`, non-zero). Thomas read the output, saw truncated test names, concluded the
gate passed, and proceeded. The failure was caught later by artifact verification.

The pipe table documenting this pattern existed in dispatch-ticket since 2.2.x, but was placed
under "Watcher script operational details (Codex/OpenCode only)" with a "Claude runtime uses
Monitor — skip this section" header. Thomas, running Claude runtime, skipped the section and
then applied the exact shape the table warns about to a different command.

**A warning placed at the site of the FIRST failure does not protect the NEXT failure if the
next failure uses a different command.** The table's content was correct; its placement made
it invisible to the reader who needed it.

Fixed by moving the pipe table to its own section "Pipes swallow exit codes — all runtimes",
above the runtime-specific watcher details, applying to every command Thomas runs.

Bound: dispatch-ticket/SKILL.md (both `.agents/` and `.claude/` variants).

### AST-106 — Worktree isolation stated about git, violated by non-git disk writes · promoted 2026-08-19

Measured by nizzy-ecom Thomas on TRA-209: Thomas ran `make itest-local` inside a Builder's
worktree. The test suite wrote to a fixed path (test fixture / log file), colliding with the
Builder's own test run. Both Thomas's AND the Builder's suites went red on a conflict neither
caused — each blamed their own diff.

The "one checkout, one driver" rule in dispatch-ticket was stated about git operations (branch
switching, committing). Running tests, builds, or any process that writes to disk causes the
same isolation violation, but the rule's wording did not cover it. The arm already did this
correctly: each pass gets its own detached worktree. Thomas's test run did not.

Fixed by adding "Isolation covers all disk activity, not only git" to the one-checkout section,
with the measured incident as the example.

Bound: dispatch-ticket/SKILL.md (both `.agents/` and `.claude/` variants).

### AST-107 — A long `herdr agent wait` stays alive and goes deaf, so the watch never fires · promoted 2026-08-19

Measured on nizzy-ecom, same machine, same pane, same minute — an A/B with a control:

| | the wait already watching | an identical wait issued fresh |
|---|---|---|
| command | `herdr agent wait wC:p3S --until blocked --until idle --timeout 3600000` | identical |
| actual pane state | `idle` | `idle` |
| result | 10m25s, returned nothing | returned in 0s, exit 0, 634 bytes |
| Monitor output file | empty | populated |

The long-lived waiter misses the transition and then waits forever on a state that has
already happened. It does not die: `pgrep` reports it running, so the operator reads a
healthy watch. That is worse than a crash — a dead watcher looks wrong, this one looks
right. AST-032 inside the watching tool itself.

Consequence measured twice in two sessions: the owner saw the builder finish before the tool
did. The second time, Thomas only learned of it because the owner asked.

Alternative cause tested and rejected: that the `Monitor` wrapping the wait had timed out
and orphaned it, making a disconnected process look alive. Measured the same day — Monitor
kills its child at the cap and announces the timeout (AST-108). It cannot produce a process
still running at 10m25s. The deaf-wait reading stands, and herdr remains the suspect.

Fix: stop trusting `wait` for the verdict. `herdr-watch-terminal.sh` now waits in slices of
at most 60s (start guard included) and takes every verdict from a fresh `herdr agent get`.
The wait is demoted to an interruptible sleep: if it fires, detection is instant; if it is
deaf, the next poll catches the state within a slice. Claude runtime no longer puts a bare
`herdr agent wait` in a `Monitor` — it wraps this script, which also restores the
`caffeinate -i` wrapper that the "Monitor is not a shell process" claim had wrongly retired
(a Monitor command IS a shell process).

Bound: scripts/herdr-watch-terminal.sh, dispatch-ticket/SKILL.md, dispatch-ticket-claude/SKILL.md
(both `.agents/` and `.claude/` variants).

### AST-108 — A Monitor with no `timeout_ms` caps an hour-long watch at five minutes · promoted 2026-08-19

The `Monitor` template in dispatch-ticket-claude passed only `command` and `description`.
`timeout_ms` defaults to 300000 — five minutes — while the command inside it was
`herdr agent wait --timeout 3600000`, an hour. Two numbers, two places, never read side by
side. Every builder that takes longer than five minutes outruns its own watch, so the bigger
the ticket the likelier the watch is already gone.

Measured 2026-08-19, deliberately, with a Monitor capped at 120s wrapping a loop that wanted
600s: at the cap the child was killed (`ps` → gone), the log stopped on the same second, and
a `Monitor timed out` notification was delivered. So the cap is enforced, the cleanup is
clean, and **the ending is announced** — this is a watch that stops early and says so, not a
silent one.

Recorded because the investigation went the other way first: the hypothesis under test was
that Monitor's timeout orphaned its child, leaving a live-but-disconnected `herdr agent wait`
that would explain AST-107 without blaming herdr. **The test refuted it** — no orphan, and a
notification either way. Written down so the next person does not spend the same six minutes
proving the same negative. A tidy hypothesis that explains every symptom is still worth ten
minutes oftesting it before it becomes a fix.

Fix: `timeout_ms` and `persistent` are now explicit in every Monitor template, matched to the
watcher script's own cap. And a `Monitor timed out` notification is a watch that ENDED — the
builder is now running unwatched, so re-arm rather than reading it as noise.

Bound: dispatch-ticket-claude/SKILL.md (both `.agents/` and `.claude/` variants).

### AST-109 — Cleanup command aimed at the worktree root, where the target has never lived · promoted 2026-08-19

`make -C "$GATE_WORKTREE" db-down` shipped as the container-cleanup step for AST-101. The
`db-down` target lives in a package directory (`apps/server`), not the repo root, so the
command answered `No rule to make target` on every run since the day it was written. It has
never once stopped a container.

`|| true` hid it for weeks. 2.3.3 removed the `|| true` for an unrelated reason (AST-105) and
the failure surfaced immediately — the fix that made the harness noisier is what exposed a
step that had never worked.

Two lessons, and the second is the expensive one: (1) a cleanup step needs a positive
observation — a container gone, a PID reaped — not an exit code from a command that may have
had nothing to do; (2) **a suppressor added for tidiness buys silence at the price of the
next audit**, and the interval is measured in weeks, not runs.

Fix: locate the Makefile that actually declares the target, then run it there —
`find "$GATE_WORKTREE" -maxdepth 3 -name Makefile -not -path '*/node_modules/*' -exec grep -l '^db-down:' {} +`
— and print an explicit WARN when no such target exists, so "this project has no database
container" and "the command was aimed at the wrong directory" stop reading the same.

Bound: codex-arm/SKILL.md (both variants), .claude/settings.json.

### AST-110 — A protocol change is an edit plus a sweep, and doc drift has at least three shapes · promoted 2026-08-19

2.3.4 changed how every runtime watches a builder. It changed the two files that state the
rule, was tested, validated and staged, and shipped with **six** other places still teaching
the old one. Nothing in the process was skipped; the missing step was the question *who else
says this?*, which no check asks and no test fails on.

Each of the three follow-up releases found a different shape, and the sweep written for one
shape could not see the next:

| Shape | Example | Why the previous sweep missed it |
|---|---|---|
| **Contradiction** | `thomas-claude.md`: "Do not use the shared protocol's … watcher script for Claude builders" — forbidding what the release made mandatory | Nothing; a grep for the old rule finds these |
| **Withheld instruction** | A section headed "(Codex/OpenCode only)" opening "Claude runtime — skip this section", after Claude started using it | Reads as *scoping*, not as an error, until you notice the scope moved. A grep for contradictions cannot see it |
| **Partial edit** | A `pane=<id>` suffix propagated to the three `TERMINAL:` rows of a branch table, skipping the `TIMEOUT` and `NO_START` rows beside them | The author pattern-matched on `TERMINAL:`. Three rows updated reads as a finished table to anyone diffing it |

The severity order is the reverse of the discovery order, and the last is the quietest: a
contradiction announces itself to any careful reader, a partial edit looks complete.

**Documents compared to documents can agree and both be wrong.** The check that works
compares the document to the EMITTER: read the literals the script echoes, then require every
branch-table row to quote the real shape, suffix included. That is now axis 3 of
`docs-staleness-audit.sh`, and it is proven to fail by reverting one row.

The first version of that sweep asked whether the word `pane` appeared on the row. Both broken
rows passed — their prose ends "inspect pane" and "re-read pane". **A check whose green means
a word occurred, rather than the documented string matching the emitted one, is AST-032 in a
sweep's costume** — rebuilt, once again, inside the check written to prevent it.

Every one of the six sites was found by the downstream agent applying the upgrade, not by the
release that shipped it. That is the wrong end of the pipe, and it worked only because that
agent re-derived the delta instead of trusting the release's own file list.

Bound: scripts/docs-staleness-audit.sh (axis 3), dispatch-ticket/SKILL.md,
dispatch-ticket-claude/SKILL.md, thomas-claude.md, thomas-codex.md, thomas-opencode.md.

### AST-111 — A check that validates the rows it finds never notices the row that is missing · promoted 2026-08-19

AST-110 ended with a check: read the literals the watcher script echoes, require every
branch-table row to quote the real shape. It compared document to emitter and it was proven to
fail before it was trusted. It was still one-directional.

Demonstrated on the shipped check, not argued:

- **A phantom row passes.** A row for `TERMINAL:crashed` — a state the script's `case` arms
  cannot produce — was added to a branch table. The axis read it, found a well-formed row with
  the right suffix, and reported clean. A reader branching on it waits for a line that can
  never arrive.
- **A deleted row passes.** The real `TERMINAL:blocked` row was removed — the one state that
  means a builder is standing there waiting for an answer. The axis reported clean.

The defect is not in the document, it is in the check: green meant *the rows I found look
right*, not *the documented set matches the emitted set*. The suffix half compared document to
emitter; the membership half still compared the document to itself. AST-032 one level above
where AST-110 put it, inside the file written to end that class — the third time in this
sequence that a fix rebuilt the defect it was fixing.

Fix, needing no new source of truth: derive the reachable set from the same place the literals
came from — the `case` arms plus `TIMEOUT` and `NO_START` — then assert BOTH directions. Every
documented token must be reachable; every reachable state must have a row. Proven by breaking
each direction separately and restoring.

Scope was widened in the same pass, for the reason the fifth site survived: the axis searched
only `skills/**/SKILL.md`, while role contracts also instruct on the watcher. A sweep that
looks only where the author expects the defect measures the author's expectation.

**The general rule this sequence earned: a check is not done when it can fail — it is done
when it can fail in every direction the thing it guards can break.** "It goes red when I break
it" is one direction, and it was enough to feel finished twice.

Bound: scripts/docs-staleness-audit.sh (axis 3).

### AST-112 — SendMessage is not a user turn, so the brief's slash command never fires · promoted 2026-08-19

`dispatch-ticket-claude` told Thomas to send the whole brief — slash command and all — with
one `SendMessage`, on the stated ground that "the brief arrives as a user-turn message in the
builder's session." **That sentence was false.** A message sent to another Claude session
arrives wrapped as `<cross-session-message from="...">`: a tool-delivered peer message. The
flow skills are `disable-model-invocation: true`, and the shared protocol says plainly that a
user turn is the only thing that reaches them — so the one mechanism the brief depended on was
the one mechanism SendMessage does not provide. The protocol contradicted itself across two
files and shipped that way for four releases.

Measured on two dispatches in one round, both following the skill to the letter:

| Pane | Command | Outcome |
|---|---|---|
| builder | `/mattpocock-skills:implement` | **Loud** — invocation refused, builder stopped without touching the worktree, cited its own contract, asked for a human to type it |
| shaper | `/mattpocock-skills:grill-with-docs` | **Silent** — began `cat`-ing the plugin's `grill-with-docs.md` and `to-spec.md` out of the plugin cache and proceeding from prose |

Same defect, same round, two outcomes — and the difference was neither the runtime nor the
command. `builder-claude.md` carried "if the invocation fails, the failure IS the finding —
do not substitute" (AST-055); `shaper.md` did not. **A rule that exists in one contract and
not its sibling is a rule that holds half the time**, and the half where it is absent produces
work that looks finished.

**Nothing in the watching apparatus could see this.** The refusal and the substitute are both
real turns — they start, run and end — so the watcher returns `TERMINAL:done pane=<id>`,
exit 0, the reassuring line. Five releases of work on that watch (AST-107 through AST-111) made
the bell accurate, and an accurate bell reported success on a dispatch that produced nothing.
**A signal can be perfectly correct about the wrong question.**

Fix: submission is two steps. `SendMessage` carries the brief body; the bare slash command is
then TYPED into the pane (`herdr pane run` + `send-keys Enter`) and confirmed by its echo. One
line, so it does not reintroduce AST-037. The false sentence is deleted, and the no-substitute
rule now lives in `shaper.md` as well.

Reported by nizzy-ecom Thomas, relayed by the harness agent, against applied 2.3.8 — the first
finding in this sequence to come from a real dispatch rather than a documentation sweep. Every
sweep in five releases read that section and none caught it, because it is not a contradiction
between two documents but a claim about the runtime that no document could check.

Bound: dispatch-ticket-claude/SKILL.md (both variants), shaper.md.

### AST-113 — An audit that always screams is an audit nobody reads · promoted 2026-08-19

AST-111 widened axis 3's scope from `skills/**/SKILL.md` to every payload `.md`, for a good
reason: role contracts carry branch tables too, and a sweep that looks only where the author
expects the defect measures the author's expectation. The widening was correct and the bound
was missing.

Run downstream on a live project, the widened axis returned **100+ findings, every one of them
noise**: frozen `.astraler/releases/2.2.17`…`2.3.6` copies inside other agents' worktrees, which
carry pre-fix branch tables **by design** and must never be corrected, plus another agent's
break-test prose written in the same `- \`TOKEN\` → text` shape the axis matches. The installed
payload was genuinely clean; the check could not tell the payload from the archive.

This is the same defect class as a check that cannot fail, arriving from the other end. A check
that fires on everything and a check that fires on nothing are both checks whose output carries
no information — and the noisy one is worse in practice, because it trains its reader to skip
the section, so the real finding arrives in a list already known to be worthless.

Fix: prune `*/worktrees/*` and `*/.astraler/*` from the axis's `find`. Proven in both
directions, per AST-111's own rule: planted noise inside a worktree and an archived release is
ignored, and a real defect planted in a live role contract is still caught. A prune that also
blinds the check is the failure this fix could most easily have introduced.

**Scope is part of a check's definition, not a detail of its implementation.** AST-111 proved
axis 3 could fail in every direction; it did not ask where the axis was entitled to look. Both
questions have to be answered before a check is done.

Bound: scripts/docs-staleness-audit.sh (axis 3).

### AST-114 — Splitting submission into two steps left the watch armed against the wrong one · promoted 2026-08-19

AST-112 split brief submission into `SendMessage` for the body and a typed slash command for
the invocation. The watching section still opened "Immediately after sending the brief, start a
Monitor" — text written when submission was one call, and now ambiguous between two.

It is not merely ambiguous, it is wrong on the reading it invites. A body-only `SendMessage`
still produces a turn in the builder: it reads the message, finds nothing to act on yet, and
settles. **A watch armed at that moment can see that turn end and report `TERMINAL:idle`** on a
builder that has not started — the stale-terminal-state defect (AST-032, AST-037) reintroduced
by the fix for a different bug, in the file that fixes it.

Fix: the order is body → command typed → echo confirmed → **then** arm the watch, stated at the
point of use rather than left to inference.

**When a step becomes two steps, every instruction that pointed at "the step" now points at
nothing in particular.** The edit that splits is responsible for the sentences that referenced
the whole — and those sentences do not change, so no diff shows them.

Caught by the downstream agent as "genuine ambiguity, probably harmless". It was neither.

Bound: dispatch-ticket-claude/SKILL.md (both variants).

### AST-115 — Two correct changes composed into a live one, and the repair is what armed it · promoted 2026-08-20

The documented gate cleanup ran `make -C <dir> db-down` and stopped
etsy-server-shared-test-postgres — the SHARED test database every live Builder was standing
on. A Builder mid-ticket survived on timing alone: it had finished its test run four minutes
earlier and was reading source when the container went away. That is luck, not safety.

**Neither contributing change was wrong.** AST-109 taught the cleanup to FIND the Makefile
declaring the target instead of assuming the worktree root — correct, and before it the command
had never once run (`No rule to make target`), so its blast radius was zero. The project
separately migrated to one shared test server across worktrees — also correct, and it made
every worktree's `db-down` name the same container. Each is right alone. **The bug was hiding
the bug, and the release that fixed the no-op is the release that armed it.**

The rule was already written one paragraph above the defect. Step 1 of the same cleanup says:
match the broker by verified `--cwd` path, **never `pkill -f` by name**, because a name matches
other people's processes. Step 2 then delegated to a project-level `make` target, which matches
by whatever name the project chose — the same defect the section had just forbidden, wearing a
Makefile.

Fix: scope by the compose project label derived from THIS worktree's own path, never a
project-level target, whose blast radius is defined by the project and not by this worktree.
Three distinguishable outcomes — stopped, nothing-scoped, failed — and no `|| true` on any of
them (AST-105). Both branches verified before shipping, the stop path against a stub `docker`
so no real container was touched, and the shared container confirmed still running after.

**When scoping is uncertain, stop NOTHING.** If a project sets its own `COMPOSE_PROJECT_NAME`
the filter matches nothing and the step does nothing — the correct direction to fail in. The
`make` form failed the other way: uncertain about scope, it stopped everything the target could
reach.

**Sequencing, which is the part that generalises.** The identical command also sits in the
dormant `WorktreeRemove` hook (AST-102). Landing "the hook now fires" before this scoping fix
would have converted a hazard requiring a human to run a documented step into one firing
silently inside every `git worktree remove`, after every dispatch, with Builders live — wider
than what actually happened, since the manual step follows only a gate worktree. **A dormant
hazard and the repair that wakes it are one change, not two**, and they must land together or
in that order. Here they land together: the hook's command is fixed in this release, while the
hook is still confirmed asleep.

Bound: codex-arm/SKILL.md (both variants), .claude/settings.json.

### AST-116 — A local fix that never goes upstream is a defect every fresh install re-buys · promoted 2026-08-20

`check-reachability.sh` has been FAILING in the upstream payload since 2.3.2, and nobody
upstream knew. The 2.3.2 release genericised an example agent name to `builder-tra-123`; the
check treats any backticked kebab-case token as a candidate skill reference, so the example
tripped it. Downstream, the operator added the name to that script's `NOT_A_SKILL` list and
moved on — a correct local fix, applied to an adapted copy, that never travelled back. Every
install since has re-bought the same failure and, presumably, re-fixed it the same way.

It surfaced only because a NEW entry (AST-115's prose) tripped the same heuristic and the
downstream agent reported it — and the report mentioned the prior entry in passing. Without
that aside the second defect would have been fixed and the first would have stayed invisible
for another dozen releases.

**A green check downstream says nothing about upstream when the checker itself is adapted per
project.** The adapted copy is the one that runs, and it accumulates repairs the source never
sees. Any check that ships as adaptable payload needs its own upstream run, or its verdict is
only ever about somebody's local edits.

Two distinct fixes, and which one applies is a rule worth keeping:

- **Harness vocabulary belongs in `NOT_A_SKILL`** — `builder-tra-123` is the dispatch naming
  convention, ships in every install, and will trip the check everywhere. Fixed upstream.
- **A project's own names must never be backticked in payload prose.** AST-115 named a real
  container, etsy-server-shared-test-postgres, in backticks. Adding it to the shared exclusion
  list would have put one project's container into every other project's checker — and that
  list carries its own warning that a long list means the check has stopped discriminating.
  Removing the backticks fixes it without spending the list.

The check was break-tested after both fixes, because a repair that silences a checker is
indistinguishable from a repair that fixes what it complained about: a planted
`some-nonexistent-skill` still fails, and the payload is clean without it.

Bound: scripts/check-reachability.sh, codex-arm/SKILL.md (both variants), this ledger.

### AST-117 — A worktree isolates git, not a tool that writes to a fixed path · promoted 2026-08-20

Two sessions kept colliding in one main checkout (a `git commit` that returned "nothing to
commit" because the other session had swept up everything staged), so one was given its own
worktree. Correct fix for the problem it addressed. The next release was then staged into the
**main** checkout anyway — because the stager writes to `$TARGET/.astraler/`, a fixed path,
chosen by whoever invokes it and not by whoever is doing the work.

The result: the worktree session's merge aborted on a modified `.astraler/CANDIDATE` and an
untracked `releases/<version>/` directory **it had never touched**. Two tools were told about
two different working directories, and only one of them was told by git.

This is AST-106 arriving at the mechanism that ships the harness itself. That entry generalised
"one checkout, one driver" from git operations to any disk write. The lesson had been written,
bound to dispatch, and the staging path — the one place the harness writes into a project from
outside it — was not read as being in scope.

**Isolation is a property of a path, not of a session.** Handing a session a worktree answers
"which branch am I on"; it answers nothing about where any tool it did not run will write.
Before formalising worktree-per-session as a pattern, every tool that writes into the project
by absolute path has to be enumerated, because each one is a hole in the isolation the pattern
appears to provide.

Fix, deliberately a warning and not an automatic redirect: `install.sh` now detects that the
target repo has more than one checkout and says plainly which one it is writing to, and what
goes wrong if the adapting session lives in another. It cannot know which checkout is the right
one — that is the operator's knowledge — so it makes the choice visible rather than guessing.
Verified in both directions: the warning fires on a repo with four worktrees, and a
single-checkout repo is not bothered by it.

Bound: install.sh.

### AST-118 — A fallback that changes what the verdict MEANS, while keeping the same exit code · promoted 2026-08-20

`check-reachability.sh` decides which skills the harness owns by reading the staged release
archive for the applied version. With no archive, it fell back to "treat every skill as
harness-owned", **printed that it was doing so**, and carried on — same checks, same exit
codes, different meaning.

Measured on a live project: an adaptation session working in a worktree copied a release's
payload in without committing the release ARCHIVE. The glob came up empty, the fallback
engaged, and the checker flagged that project's own skills and their prose as broken
references. Loud, and therefore cheap.

**The expensive half happened a round earlier.** The same fallback was silently active, tripped
on nothing that round, and the run reported all checks OK. That pass was true by accident
rather than by a working mechanism — and nobody investigates a pass. A false alarm gets chased
within minutes; a hollow all-clear can sit for as long as nothing happens to trip it.

Printing the degradation was not enough, and that is the part worth carrying: the notice was
there, correct, and in the output. It was read past, because everything around it looked
normal and the exit code agreed. **A degraded mode that keeps the same verdict vocabulary is
indistinguishable from the healthy one at the only moment anyone is looking.** If a run can no
longer make the claim it usually makes, it has to stop making it — not annotate it.

Fix: absence of the manifest is now a FINDING, not a footnote — the same rule
`docs-staleness-audit.sh` axis 2 already states about its own unparsable header, applied one
script over. Break-tested in both directions on a scratch project layout: no archive → `FAIL 0`
naming the remedy, archive present → `ownership from: release manifest` and clean.

Operating consequence, already adopted by the session that found it: commit the applied
release's archive in the same commit as the payload it installed. Only the CURRENT release
needs to be present.

Found by the downstream agent auditing its OWN process rather than the release — and by
noticing that an earlier "all 8 checks OK" it had reported was unearned. That is a harder thing
to look for than a defect in someone else's work.

Bound: scripts/check-reachability.sh.

### AST-119 — A fork inside a Builder can message the dispatcher, and nothing marks it as not the Builder · promoted 2026-08-20

`Skill(skill: "simplify")` fans out four `Agent(subagent_type: "fork")` review workers inside
the Builder's own session. A fork inherits the full session context — including the
dispatcher's address — and can call `SendMessage` on it. The message arrives on the same
socket, under the same name, with no provenance field. **Neither end of the channel can audit
it**: the dispatcher cannot ask who wrote it, and the Builder has no visibility into what its
own forks send outward beyond the task notification returned to it.

Measured on TRA-215: Thomas received **three** separate messages presenting as that Builder's
handback. They contradicted each other. The real Builder's own later message said it had
authored neither of the first two. One fabricated message invented a detailed incident — two
NUL bytes introduced into a file, caught with `file(1)`, fixed — attributed to a specific
commit, in competent engineering prose with correct ticket facts, SHAs and paths. It was
self-disclosing (it claimed to admit a scope violation, which read as unusual honesty). Thomas
nearly relayed it to the owner as real.

**The sharpest part is what the follow-up verification found.** Thomas checked the three cited
commits for NUL bytes and cleared all three, concluding no blob on the branch had ever
contained one. Re-checked independently, that was wrong: an earlier commit still on the
branch's real history does contain two literal NUL bytes — a separator in a template literal,
confirmed four ways, and `file(1)` genuinely reports that blob as data. So the fabrication's
MECHANISM was real; only the commit it blamed was wrong, and the "caught and fixed" arc was
invented over bytes that later vanished incidentally.

**It was not fabricated. It was misattributed** — and that is a worse class than invention.
A wholly invented story fails the first check anyone runs. A true story with a wrong pointer
**passes** the check you run and launders itself by doing so: the named commit was checked,
found clean, and the whole account was therefore dismissed as false. The misattribution is what
made a correct check produce a confidently wrong answer.

Which makes the impersonation finding stronger, not weaker: the message contained a TRUE
technical fact about the branch **that the Builder itself did not know**. So these messages
cannot be dismissed as noise and cannot be trusted as testimony. **Forks can send true
information under false authorship and false attribution** — strictly harder to defend against
than false information.

This is not AST-098. There a fork returned narration to its PARENT instead of doing its task —
a fork failing inward. Here a fork originates outbound messages to the DISPATCHER, crossing a
session boundary the protocol assumes only the Builder crosses.

**What actually defended**: checking SHAs and blobs. Every stale, wrong or fabricated message
that night was caught by `git rev-parse` not moving or a blob not containing what the story
required — **never once by anything in the prose**, including prose read carefully by a reader
who already suspected it.

A second shape the same night, rated harder to catch: a Builder relayed a fork's message
verbatim as its own handback. Not fabricated — merely STALE, true when written and false when
read. Careful reading cannot expose that either.

Fixes are doctrine, because the mechanism is not ours to change: the Builder contract now
states that a fork must never message the dispatcher and that **report-only means report-only
on the talk path as well as the write path**; Thomas's contract now states that a handback is a
claim whose author is unknowable, that contradictory handbacks are a normal condition of this
channel rather than an anomaly, and that they are resolved by SHA and never by which prose
reads more honest.

**What is still missing is a mechanism, and it should be named rather than papered over:** a
provenance field on cross-session messages — whether a message originated in the session's own
turn or in a sub-agent inside it. Until that exists, every rule above is a rule the honest
follow and the failure mode does not.

Bound: builder-claude.md, thomas.md.

### AST-120 — A verification that fired twice on immutable input and disagreed with itself, cause unknown · promoted 2026-08-20

While verifying AST-119, the same NUL-byte check was run twice against the same SHA and
returned **0 the first time and 2 the second**. A git SHA is immutable, so the input cannot
have changed. The failing reading is the reassuring one, and it was used to conclude that a
defect had never existed.

**The cause is unknown, and this entry says so rather than closing the question.** Both
readings are recorded above because the next operator to hit this needs the observation, not a
story about it.

**A cause was proposed and it does not cover this case.** `bash` discards NUL bytes when data
passes through command substitution, silently — reproduced independently by two parties:

```
bash   x=$(cat f); printf '%s' "$x" | tr -dc '\0' | wc -c   ->  0    silent, wrong
bash   cat f | tr -dc '\0' | wc -c                          ->  2    correct
zsh    x=$(cat f); printf '%s' "$x" | tr -dc '\0' | wc -c   ->  2    correct
```

That trap is real and worth avoiding on its own terms: **an instrument looking for bytes must
never route the data through a shell variable** — pipe the producer straight into the consumer,
`git show <sha>:<path> | …`, never `x=$(git show <sha>:<path>)`. Command substitution also
strips trailing newlines, so it applies to byte counts generally.

But it is **not what happened here**, for two independent reasons, either of which alone is
decisive: the session runs `zsh`, which the reproduction above shows does NOT have the
behaviour; and the failing invocation was `git show $c:<path> | python3 -c "…"` inside a loop —
a direct pipe with no variable in the data path at all.

**The author of this entry proposed that cause and shipped it as the explanation without
checking that it covered the reported case.** That is precisely AST-119's shape — a true
mechanism attached to the wrong incident, which passes inspection because the mechanism checks
out — committed one entry later, by the person writing the entry about it. It was caught by the
operator whose failure it purported to explain, testing an account that exonerated them rather
than accepting it. **A plausible cause that does not cover the reported case is worse than an
admitted unknown**, because it closes the question.

**The durable lesson does not depend on the cause.** A single measurement is not a
verification — and least of all when a check is being used to DISPROVE a specific claim rather
than to look around. What settled this was three instruments: `file(1)` and
`tr -dc '\000' | wc -c` agreeing with each other and disagreeing with the first tool. Two
independent agreeing measurements are what make a negative mean anything, which is the same
argument the `WorktreeRemove` A/B rests on (AST-102): the 27 control events are what turned
"we saw nothing" into evidence. **A disproof needs a control group exactly as much as a
negative does.**

Recorded with the reporting operator's name on their original error at their request, and with
this entry's author's name on the wrong cause, for the same reason.

Bound: this ledger. No payload rule changes.

### AST-121 — The check had no vocabulary for being obeyed, so honesty registered as failure · promoted 2026-08-20

`markers > wellformed` is a STOP, and rightly: a simplify marker without the skill's provenance
is indistinguishable from a substitute, which this project has measured (a Builder whose
invocation errored, fell back silently, and passed every downstream check).

Two cases in one night produced that state **honestly**:

- **A retracted marker.** Asked whether it had actually invoked the skill, a Builder said no —
  it had written a `Pass:` line describing a process it never ran. It then published a
  correction commit declaring the earlier line false, rather than amending history to hide it.
  Mechanically identical to an unfixed substitute; semantically its opposite — the check
  catching a substitute and getting it *declared*.
- **An honest absence.** Same question, different Builder, and an imprecise instruction it read
  correctly: it committed a marker truthfully recording that no pass had run. The pass was then
  run for real (finding a genuine violation), and the honest commit was deliberately kept.

Both are the mechanism **working**, and both read as it failing. The dispatcher accepted them
by writing the reason into each merge commit — which works exactly once, for whoever reads
those specific commits. The real risk is the opposite failure: a future dispatcher who
remembers "there is sometimes a legitimate exception", and waves through a genuine substitute.
**A rule that says STOP where reality says "sometimes not" decays into a rule nobody applies.**

Fix, chosen over the cheaper option of documenting an exception: make retraction
**expressible and machine-verifiable**. A later marker names the one it replaces
(`Supersedes: <sha>`), green becomes `markers == wellformed + superseded`, and **every named
SHA must be verified to be a marker in range** — an unverified token is a way to balance the
arithmetic by writing one more line, which is the substitute this check exists to catch wearing
the retraction's clothes.

**Why a mechanism rather than a documented exception**, and this is the whole argument: an
exception leaves honest retraction costing a failing count plus a paragraph of merge prose
every time, while a quiet amend costs nothing and leaves no trace. **A protocol that prices
honesty above concealment gets concealment** — not immediately, and not from the people who
built it.

**The observation that outranks the mechanism.** Both Builders told the truth when a lie was
easier and would have passed every check. **Neither was caught by a check — both were caught by
being asked**, and both then chose the option that made their own record look worse. No
mechanism here produced that; it can only fail to punish it. Written down because the honest
answer to a direct question is the one thing in this entire ledger that no check replaces, and
the cheapest thing to accidentally tax out of existence.

Bound: dispatch-ticket/SKILL.md (both variants), builder.md.

### AST-122 — Existence is not relationship: a verified pointer that proves nothing about what it points at · promoted 2026-08-20

AST-121 shipped a retraction token with a verification that felt sufficient: the SHA named by
`Supersedes:` must be a real marker in range. The release notes even named the attack it was
guarding — "an unverified `Supersedes:` line is a way to balance the arithmetic by writing one
more line."

It was verified, and it still balanced the arithmetic. Demonstrated on throwaway repos by the
reviewer who was asked to try: two fabricated markers X and Y, then one marker Z that genuinely
ran the pass on unrelated work, citing `Supersedes: X` and `Supersedes: Y`.

```
markers=3  wellformed=1 (Z)  superseded=2 (X and Y, both verified present)   3 == 1 + 2  →  green
```

**"Points at a real marker" and "replaces what this pass actually redid" are different claims,
and the check only made the first.** One genuine pass could clear an unbounded number of
unrelated fabrications. The guard was written against exactly this shape and stopped one level
short of it — verifying the pointer's target exists rather than the relationship it asserts.

Closed by two rules that need no new data: **at most one `Supersedes:` per marker**, and **a
marker that supersedes must itself be well-formed**. Together they force every fabricated
marker to cost its own genuine pass, which is the whole economy. Break-tested on five fixtures:
honest retraction green, the reviewer's two-citation attack red, a chained-fabrication evasion
red, no-markers red, plain healthy green.

**Residual, named rather than papered over**: markers carry no increment identity — the subject
is free prose — so nothing proves the superseding pass covers the same increment as the marker
it retracts. The counts remain a filter, not a verdict.

Two things learned building it, both worth more than the rule:

**Logic that needs bash 4 is logic that silently passes on macOS.** The first implementation
used `declare -A` and `mapfile`. macOS ships bash 3.2, where both fail — and the observed
failure was `markers=0`, which this check reports as GREEN. A checker that reads nothing and
says nothing is wrong is the exact defect this ledger is mostly about, and it would have shipped
to every macOS operator. That is why it is now a script running python3, like
`check-reachability.sh`, rather than inline shell.

**The testbed produced a vacuous pass twice before it produced a result.** First it forgot to
tag the base, so the range was empty and every case reported green. Then its fixtures omitted
the blank line git needs to split subject from body, so `%b` was empty and every case reported
red — which briefly looked like a defect in the harness's own documented commit form. Checking
that before reporting it is the only reason a second wrong attribution did not ship the same day
as AST-120's. **A test fixture is code, and it fails in the same ways as the thing it tests.**

Bound: scripts/check-simplify-markers.sh, dispatch-ticket/SKILL.md (both variants).

