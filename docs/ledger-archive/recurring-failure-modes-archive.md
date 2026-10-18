# Recurring Failure Modes — archive

Status: archived · 89 entries · moved out of the shipped ledger on 2026-10-18 (4.1.0)

These entries were cut from `harness/.agents/memory/recurring-failure-modes.md` because no live
contract, skill or script cited them (empty "Cited by" in INDEX.md at the time). The text is
unchanged and the format is the ledger's own. This directory is not part of the harness payload
and no role loads it.

A `Bound:` line or a comment in code that cites one of these ids as `AST-nnn (gone)` still
applies: the rule was kept, only the narrative left the payload. Read the entry here when you
need the incident behind it.

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
per worktree. Bound: `.claude/rules/agent-worktree-isolation.md` (gone).

### AST-013 — Ad-hoc build delegation; false tooling-gap assumed · superseded by AST-019/AST-026
Surviving lesson: **verify tooling by inspecting the filesystem before claiming a
capability gap** — never scope down a port on an assumption.

### AST-014 — Multi-slice rebuild needs a gated integration branch · promoted 2026-07-11 · epic-specific
Pre-launch rebuild whose slices individually break `main`: gated integration branch,
per-slice gates + one holistic train gate (hub-v2 pattern). Historical; propose CLOSE.

### AST-015 — Export step committed live secrets + buyer PII · promoted 2026-07-11
Same-vendor correctness review PASSED it; cross-vendor caught it (P1) — the two lenses
catch different classes. A value that touched a tracked file is burned — rotate it.
Bound: `.claude/rules/no-secrets-in-exports.md` (gone) (always-on). CI secret-scan still TODO.

### AST-017 — Per-package typecheck missed a cross-package break · promoted 2026-07-11
Gate evidence = repo-root `pnpm -r typecheck` + `pnpm -r test`; per-package green is not
whole-repo green. Bound (machine): `.github/workflows/ci.yml`.

### AST-018 — Dispatch emitted as text, never executed; no liveness signal · promoted 2026-07-11
Dispatch-is-not-done-until-observed: verify every delegation by its observable effect
(agent appears in `herdr agent list` / branch moves) in the same turn; narrating a tool
call is not calling it. Bound: `.claude/agents/thomas-leader.md` (gone) (orchestration §) +
`scripts/herdr-watch-terminal.sh` (AST-022 watcher).

### AST-019 — Implementer subagent retired; independence moved to the PR · promoted 2026-07-12 · dispatch superseded by AST-026
The in-session build subagent cost more than it returned. Surviving core: branch → PR →
review always; plan gate before build; `/simplify` before PR. Bound:
`.claude/rules/build-loop-gates.md` (gone).

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
doc pointer change in the same commit. Bound: `AGENTS.md` (gone) +
`.claude/agents/thomas-leader.md` (gone) (full herdr-watch doctrine; ex-`THOMAS.md` (gone), folded
2026-07-16). Watcher semantics: bell not verdict — verify by artifact; `done` mis-fires
when the worker spawns sub-agents; real end-signal = artifact progress.

### AST-023 — "Main session builds directly" conflated two mechanisms · promoted 2026-07-15 · dispatch superseded by AST-026
The orchestrator does NOT hand-write product slices; the build runs in an isolated
dev-role session. Gate-independence guarantee UNCHANGED across supersessions. The
"Worker" name survives only in this ledger — the dev role is `dan-implementor.md`.

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
STOP). Bound: `.claude/agents/thomas-leader.md` (gone) / `dan-implementor.md` (gone) /
`rin-pr-reviewer.md` (gone), `.claude/rules/role-thomas.md` (gone) / `build-loop-gates.md` (gone) /
`agent-worktree-isolation.md` (gone), working-method §3–§5, rules §3, `AGENTS.md` (gone), truth-model §2.
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
vanish mid-turn. Bound: `.claude/rules/agent-worktree-isolation.md` (gone) (owner delegated the
promote decision to Thomas 2026-07-17).

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
`.agents/skills/dispatch-dan/SKILL.md` (gone), `.agents/roles/dan-implementor.md` (gone),
`.astraler/AGENTS.harness.md` (gone), `.claude/rules/agent-worktree-isolation.md` (gone),
`.claude/agents/thomas-leader.md` (gone), working-method §3/§5/§7, rules §3.

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
`.agents/skills/dispatch-slice/SKILL.md` (gone), `.claude/skills/review-with-rin/SKILL.md` (gone).

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
`.agents/roles/dan-senior.md` (gone) (step 4), `.claude/agents/dan-senior.md` (gone).

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
`.claude/skills/review-with-rin/SKILL.md` (gone) §2, `.agents/skills/dispatch-slice/SKILL.md` (gone)
(rin-reviewer row), `.claude/agents/rin-reviewer.md` (gone), `.claude/rules/build-loop-gates.md` (gone).

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
Bound: `.claude/rules/build-loop-gates.md` (gone), `.agents/roles/james-dev.md` (gone) §4b,
`.agents/roles/dan-senior.md` (gone) §4a, `docs/governance/working-method.md` (gone) (PR checklist
"Reuse/simplify"), `.agents/skills/dispatch-slice/SKILL.md` (gone).

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
Bound: `harness/scripts/gen-code-map.sh` (gone), `check-requirements.sh`,
`harness/scripts/docs-staleness-audit.sh`.

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
Bound: `harness/.codex/profiles/*.config.toml` (gone), `harness/.agents/orchestrator.md`, `check-requirements.sh`. 2.12.0 moved the model out of the profile entirely: the
orchestrator row is its only home, and the doctor MISSes on a codex row that names none.

### AST-043 — A gate that requires an artifact no contract produces · promoted 2026-08-11
`review-with-rin` §1(d) required the brief to carry "the Builder's browser-verify evidence".
`builder.md` did not contain the words browser, visual or screenshot — not once. The gate
asked for an artifact, named the role that owed it, and that role's contract never mentioned
producing it.

This is the failure ADR 0001 was written about, reproduced inside the package that exists to
prevent it: a step described in one document, owned by nobody in the contract that would run
it. A consuming repo shipped a visually-wrong control to main this way, and it was caught by
a human noticing, not by any gate.

`check-reachability.py` does not catch this class. It verifies that every phase has an owner
and every reference resolves — not that **every artifact a gate demands has a producer**.
That is the harder check and it is not written. Until it is, a gate's input list is worth
reading against the contracts by hand whenever either changes.

The fix is the boring one: the contract that owes the artifact says so, and the gate treats
an unexplained absence as a finding rather than as nothing.
Bound: `harness/.agents/roles/builder.md`, `harness/.agents/roles/rin.md` (gone),
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
Bound: `harness/.agents/roles/rin.md` (gone), `harness/.claude/skills/review-with-rin/SKILL.md` (gone) §2b.

### AST-046 — A block moved between documents keeps the old document's referents · promoted 2026-08-11
1.3.0 split the product walk out of the reviewer into its own role. The dispatch mechanics
were **moved** from `review-with-rin` into a new skill — and moved verbatim. Three lines went
on naming the walker "Rin" and calling the walk "a mode", which is 1.2.0's design surviving
inside the release that reversed it. The dispatcher reads that skill to pack the brief, so
one of those lines would have set the persona for the wrong agent.

`check-reachability.py` cannot see this: every path resolves, every name exists, nothing
dangles. It is a **semantic** error, and the checker verifies references, not meaning.

Moving text is not the same as re-homing it. **Re-read a moved block in its new context
before the move counts as done** — the sentences that were correct in the old document are
exactly the ones nobody looks at again.
Bound: `harness/.claude/skills/dispatch-qa-walk/SKILL.md`.

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
`check-reachability.py` verified that every phase had an owner and every reference resolved,
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
Bound: `harness/scripts/check-reachability.py` (check 5).

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
`check-reachability.py` travelled inside the payload and therefore landed in the project's
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
Bound: `harness/scripts/check-reachability.py`.

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
Bound: `harness/.agents/roles/rin.md` (gone).

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

### AST-086 — the payload checker's own scope list was already stale, including for itself · promoted 2026-08-18

Found by an adapted project's own Thomas while verifying the AST-080 fix, not by reading the
code. `check-requirements.sh`'s payload-committed check walked every file under
`.agents`/`.claude`/`.codex` plus a hand-written list of three named scripts. The package
ships FIVE scripts into a project's `scripts/` directory — `harness/scripts/*.sh` plus this
file itself, staged separately from the package root by `install.sh` — and the list named
three. Measured directly on a real dirty tree: ten payload files modified, seven counted, the
missing three being `check-reachability.py`, `docs-staleness-audit.sh` and (found separately,
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

### AST-104 — herdr agent start rejects uppercase in agent names, but dispatch convention generates them · promoted 2026-08-19

`herdr agent start` validates agent names against `[a-z0-9_-]` — no uppercase. The dispatch
convention `builder-<ticket-id>` passes the ticket ID as-is, and ticket IDs are uppercase
by convention (`TRA-123`). Every dispatch produces an invalid agent name on the first attempt.

The dispatch skill documented the `:` restriction (pane label vs agent name) but not the
case restriction. One failed launch per dispatch until the operator learned to lowercase.

Fix: dispatch-ticket/SKILL.md now says to lowercase the ticket ID in the agent name.

Bound: dispatch-ticket/SKILL.md (both `.agents/` and `.claude/` variants).

### AST-105 — Pipe after a command swallows exit code, turning a failed gate into exit 0 · promoted 2026-08-19

Measured in the field: `make itest-local 2>&1 | tail -25` returned exit 0
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

Measured in the field: Thomas ran `make itest-local` inside a Builder's
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
`db-down` target lives in a package directory, not the repo root, so the
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

### AST-124 — The watcher covers one turn; the protocol never said who covers the next one · promoted 2026-08-20

Two dispatched Builders ran unwatched for an extended stretch, one advancing four commits.
**The project owner noticed before the dispatcher did**, from the absence of notifications on
his own screen.

Nothing malfunctioned. `herdr-watch-terminal.sh` watches ONE newly-submitted turn and exits
correctly when that turn reaches terminal. The gap is between the parts:

```
send brief → arm watcher → work → handback → watcher exits (all correct)
  → long absorbing task the contract itself mandates (gate worktree, arm pass 5-15 min,
    read report, write fold)
  → send the fold as a NEW turn → no watcher, because the old one ended correctly
    and nothing re-arms it
```

Six trips through the identical gap in one session. **It generalises to every dispatched role**
— a Shaper's spec gates, a Builder's ticket gates, a reviewer classifying findings, a QA
deciding what its walk found. The contract prescribes the gates and prescribes the watch, and
never connects them. More gates means more of this gap.

**An unwatched pane and a quiet healthy pane produce identical evidence: nothing.** This
ledger's most-repeated shape, landing on the dispatcher instead of on a check. A Builder that
parks on `blocked` mid-gap parks indefinitely.

**The first proposed fix was rejected by the owner, and that rejection is the finding.** The
proposal was "arm the watcher in the same action as sending the message" — still a rule that
depends on remembering it, which is exactly what had just failed. **A firmer promise is not a
repair for a discipline failure.**

The structural answer already existed and was opt-in: `herdr-watchdog.sh` alerts on `BLOCKED`
independently of any per-turn watcher. Nine hours of dispatch, six gate passes and three
concurrent Builders ran with it off, and **nothing anywhere reported its absence** — because a
watchdog that was never started manifests as no alerts, which is what a healthy session looks
like too. It sat as a `nohup` line under a heading reading "safety net", with no step that
starts it and no check that notices it missing. **A safety net nobody is required to hang is
one that is usually not hanging.**

Fix, in two places because one would not have held: `dispatch-ticket` now **gates** on the
watchdog before the first dispatch — the one moment the question can be asked, since its
absence is invisible everywhere else — and states that every NEW turn needs a NEW watcher, at
the point where the fold is sent rather than only where the first brief is.

**Coverage, stated rather than assumed**: the watchdog's `STUCK` rule requires that no pane is
working, so an active dispatcher suppresses it — a Builder finishing while the dispatcher is
busy still pings nothing. The per-turn watcher and the watchdog cover different halves. With
the watchdog up, a missed re-arm costs latency; without it, silence. Anyone who starts it and
assumes full coverage has traded one invisible gap for another.

Raised by a human owner, not by a check — and the sharpest correction in it was the owner
rejecting the dispatcher's own first fix.

Bound: dispatch-ticket/SKILL.md (both variants), thomas.md.

### AST-127 — The runnable example contradicted the prose eight lines below it · promoted 2026-08-20

`reconcile-tracker`'s copy-paste block called `scripts/ticket-git-facts.sh` with no
`TICKET_PREFIX`, labelled **"ALWAYS this form"** — a command the script refuses. Eight lines
down, same file: *"`TICKET_PREFIX` has no default and is required."*

An adapted project reported it as ITS drift, and this entry first recorded the opposite — that
the bare call sites were ours and it had copied them. **Corrected 2026-08-20: that was wrong.**
That project had authored its own script at the same path, with its own `TRA` default; its doc
quoted its own code and was exact. The variable has been required since 2.2.0 *in this payload*,
which is true of the payload and says nothing about a file a project wrote itself (AST-128).
The self-contradiction below is real and was fixed; it did not cause that incident.

**Fix the EXAMPLE first — the prose is the half that does not run.** Prose is read; a fenced
block is copied. The project's own first remediation corrected the sentence and left the bare
block six lines above it, reproducing the defect inside its own fix, because every description
of it led with "the prose disagrees". State the finding as the example or the fix arrives half.

**A required value also needs a home the agent already has open**: the project's session-start
instructions, not a load-on-demand doc (AST-069). Declared once — a second home, whether a
sibling doc or an `.envrc`, is this entry's own defect returning.

Bound: `harness/.agents/skills/reconcile-tracker/SKILL.md` (and its `.claude/` twin).

### AST-128 — Only the adapter is ever standing where both files exist · promoted 2026-08-20

A project authored `scripts/ticket-git-facts.sh` itself, with its own `TICKET_PREFIX:-TRA`
default. The first payload shipping that path arrived **nine hours later**. A bulk adaptation
the next day replaced the file with the payload's mandatory-prefix version; the commit message
named the script **zero times**; a second adaptation passed over it undetected; the failure
surfaced **twenty-two hours** after the replacement as a refused command.

Both sides then reasoned correctly from what they could see and reached opposite conclusions.
Upstream measured its own releases — "mandatory since 2.2.0, so the divergence existed only in
prose" — true of the payload, false of that repo. The project measured its releases directory
and confirmed it. **Neither party's evidence contained the fact that the project had authored
the file first**, so an accurate report and an accurate investigation produced a wrong shared
answer, twice, and the first fix was aimed at the wrong defect.

**Nor could a rule have prevented it from either end.** "Check whether a payload already ships
this path before authoring here" returns clean at the moment it matters: payload path ownership
is not a published stable set, it grows per release, and a project cannot check itself against a
set that does not exist yet. **The adapter is the only place both files exist at once.** Step 4
now lists every payload path whose live copy differs, with its commits, before overwriting
anything — eight paths on the project measured, all owner-tuned.

Bound: `prompts/ADAPT-HARNESS.md` (step 4).

### AST-129 — The receipt was a producer with no reader, and it hid the one fact that had readers · promoted 2026-08-20

The adaptation receipt was mandated in full — every file added, replaced, merged, preserved;
every requirement judged; validation transcripts — and appended per upgrade. One measured
project accreted **3,093 lines across 39 receipts**, and nothing read them: no contract, no
skill, no later install. The single fact in there with recurring readers — the rendering path,
which the Builder needs per ticket and `dispatch-qa-walk` reads per walk — was buried in a
state file those readers never load, while the entry doc they do load carried nothing.

Same class as AST-069 from the producing side: a required artifact whose write moment has no
read moment attached measures as pure cost. The same window measured release bookkeeping at
**~3 lines written per line of behaviour change** — one lesson written three times, as a
commit message, a release-note narrative and a ledger entry.

**A fact goes where its reader already is; a record with no reader is written as exceptions
or not at all.** The receipt now overwrites (history is git's) and records only decisions —
DIFFERS, PENDING, conflicts, candidate defects. The rendering path, standards pointer and
ledger path live in the project's entry doc. The ledger entry is the one canonical home for
a lesson; the release note states the change and points here.

Bound: `prompts/ADAPT-HARNESS.md` (steps 5 and 7), `dispatch-qa-walk/SKILL.md`, `qa.md`.

### AST-139 — The fork guard AST-119 asked for cannot be built today, measured three ways · promoted 2026-09-14

AST-119 closes by naming what is missing: *a provenance field on cross-session messages — whether
a message originated in the session's own turn or in a sub-agent inside it. Until that exists,
every rule above is a rule the honest follow and the failure mode does not.* A downstream project
shipped a `PreToolUse`/`Agent` guard for the same class, so this package went to build one. **It
does not exist, and the reason is measured rather than argued.**

Three candidate signals, all negative:

| signal | result |
|---|---|
| process ancestry | **negative.** A fork is not a separate OS process. Measured inside one: its shell's `PPID` equals `CLAUDE_PID` equals the single `claude` process in `ps`. A script inspecting its own tree sees an identical picture in a fork and in the parent. |
| `CLAUDE_CODE_CHILD_SESSION` | **negative.** Present as `1` inside a fork — and present as `1` in the parent session, measured in the same minute. It marks a Claude Code session, not a child of one. |
| the `PreToolUse` payload | **negative.** No provenance field is observable, and nothing routes the payload to a fork so it could be read from there. |

**The near-miss is worth more than the result.** The first two readings looked positive.
`CLAUDE_CODE_CHILD_SESSION=1` inside a fork is exactly what a guard would key on, and the probe
that found it said so — while flagging that it had observed PRESENCE in the fork and ASSUMED
absence in the parent, because `ps eww` on macOS prints no environment for another process. One
command in the parent session closed it and inverted the answer. A guard built on the unverified
half would have been registered, logged, reviewed, and incapable of ever firing — the exact shape
of a check that always takes the reassuring branch (AST-051), arriving by a route nobody would
have called careless.

**So the mechanism stays doctrine, and this entry exists to stop the next attempt from starting
over.** The defences AST-119 already names are the ones that worked that night: a handback is a
claim whose author is unknowable, contradictory handbacks are a normal condition of this channel,
and they are resolved by SHA and never by which prose reads more honest. Every stale, wrong or
fabricated message was caught by `git rev-parse` not moving or a blob not containing what the
story required — **never once by anything in the prose.**

Revisit when the runtime exposes provenance on a message or on a tool call. Until then, a guard
here is not a missing feature, it is an unbuildable one, and shipping something shaped like it
would cost more than the gap.

Bound: `.agents/memory/recurring-failure-modes.md` (AST-119), `.agents/roles/thomas.md`,
`.agents/roles/builder-claude.md`.

### AST-141 — The ledger's `Bound:` line claims the present, and nothing had ever checked it · promoted 2026-09-16

A ledger entry narrates the past, and that is correct: an entry naming a role file from a
generation since renamed is history told accurately, and "fixing" it would falsify the record.
But three labels inside those entries are not narrative. `Bound:` names where a rule is enforced
**right now**; `Wired` and `Enforced by` make the same claim about a tool. Those are assertions
about the present, and a false one is worse than silence, because it **closes the question** — a
reader who sees `Bound:` stops looking for the enforcement.

Measured on 2026-09-16, both halves on live repositories. In this package: `Bound:` pointing at
`.claude/rules/agent-worktree-isolation.md` five times, `build-loop-gates.md` three, and
`role-thomas.md` twice — files this package does not ship, does not require in
`check-requirements.sh`, and names in no contract or adaptation step. Downstream: a ledger line
reading `"Wired 2026-08-29 (report-only; --kill opt-in)"` about a tool with no call site
anywhere in the tree.

**The part worth keeping is what the package had already done about it.** `check-reachability.py`
knew. Its closing scope line said so in plain words — *"Not scanned, and check 4 does not speak
for it: the failure-mode ledger's historical `Bound:` provenance. A live project measured five
citations there to a file that had been deleted, while check 4 reported clean."* The finding had
been converted into a footnote and shipped for four releases. **A rot entry written up honestly
is still a rot entry**, and an accurate scope line is not a substitute for the check it is
describing the absence of.

**The rule.** An assertion label in the ledger is checkable and is checked. Retiring one is
explicit and local: `` `path` (gone) `` at the citation, never at the entry, so a line binding one
live file and one dead one keeps its live half under the check instead of being excused
wholesale. And when a check's scope line names a defect the check does not cover, that sentence
is a ticket, not documentation.

Bound: `scripts/check-reachability.py` (check 10), `.agents/memory/recurring-failure-modes.md`.

### AST-143 — A scaffold path swallowed this package's own headline fix, silently, and the receipt said clean · promoted 2026-09-16

2.9.0 is titled *"a rule reaches every runtime, or it reaches one"* and its central change was
the compaction rules landing in all five `.codex/profiles/*.config.toml`. Those profiles are in
`OWNER_PATHS`, so on every already-adapted project `install.sh` printed `owner … (kept — yours)`
and wrote none of it. **The release's own headline fix could not reach a single project that had
ever run it before**, and the receipt reported a clean upgrade.

The scaffold rule is right and is not what failed: `.codex/profiles/` carries the owner's model
and effort choices, and a release that overwrote them would silently revert deliberate tuning
(AST-041). What was missing is that an owner file protects the owner's **tuning** — it was never
meant to protect a **stale copy** from a safety fix the owner cannot see. `.claude/settings.json`
already had the answer one branch above: keep the file, and REPORT what the release ships that
the copy lacks.

**And the check that should have caught it was disabled exactly where it would have fired.** The
suite's runtime-parity case was `pkg_only` and resolved its paths through `$ROOT/harness/`, so it
ran only in package layout — where the files are AUTHORED. The adapted project is where they are
LOADED and the only place they can drift. A parity check that runs only where drift is impossible
is a green light pointed at the wrong room.

**The rule.** A scaffold path is reported on every upgrade that changes it — kept, never merged,
always named. And a check that compares surfaces runs where the surfaces are loaded, not where
they are written.

Bound: `install.sh` (owner-file branch), `scripts/selftest.sh` (runtime parity),
`.agents/memory/recurring-failure-modes.md` (AST-138).

### AST-144 — Three gates met their first real project on the same day and all three answered about the wrong thing · promoted 2026-09-16

2.10.0 shipped three checks whose fixtures all passed at package root, then went down into the
first adapted project that had ever run them. Each failed in a different way, and none of the
three was a bug in what it measured — each was **pointed at the wrong tree, or asked the wrong
question, or left the project nowhere to answer.**

**One: the gate measured the caller's cwd instead of the tree it was given.**
`docs-staleness-audit.sh` resolves every axis through `$PAYLOAD` — and its `.claude/rules/`
word-budget block used a bare relative path. A project ran `bash <package>/install.sh .` from
its own repo; the installer asked the audit to check the PACKAGE; the audit read the PROJECT's
rules, went over budget on them, and **the package refused to stage**. The comment forty lines
above that block says, in plain words, that a bare relative path here *was* the real cwd
dependency and was fixed. It was fixed for every axis except the one added later.

Compounding it: the package ships no `.claude/rules/` at all, so that budget had run against an
empty set since the day it was written. It reported clean on a denominator of zero for four
releases, met one real rules tier, and shut the door.

**Two: the case asserted cleanliness while claiming to test invocation.** `selftest.sh` carries
a case titled *"check-reachability runs under python3 (never bash -n)"* — the file is Python
with a `.sh` name and that is the defect it guards. It asserted **exit 0**. The tool exits 1 on
any finding. So any healthy adapted project with one legitimate finding read as a failed
invocation, and the suite that is supposed to prove a shape was silently proving a verdict.

**Three: the error text told the project to edit the payload.** Check 4 flagged a Docker
container name written in backticks in a project's own contract — character-for-character the
shape of a skill reference. Its hint said to add the word to `NOT_A_SKILL` *in this script*,
and that script is payload: doing what the hint says makes two owners for one path (`AST-132`),
and the next upgrade undoes it.
2.7.15 had correctly removed two downstream project names from that set — *the payload names no
project* — and left projects with nowhere to put their own. **A gate that cannot go green is a
gate people stop reading**, so this one benign token would have retired the whole check.

**The rule, and it is one rule.** A check belongs to the package; the vocabulary, the budget and
the tree it judges belong to whoever is being judged. So: resolve every path through the tree
under test, never the caller's cwd; assert the thing the case is named for and nothing wider;
and wherever a check needs a project-specific answer, give the project a socket at a path no
release writes — `.astraler/project/not-a-skill.txt` joins the plug set for exactly this, union
with the payload's vocabulary and never replacing it.

**And a fourth finding, from the same apply, about advisory WORDING rather than mechanism.** The
installer's new hook-script advisory fired correctly and its instruction was still wrong. It
says *"merge everything that is not your own tuning"*, which assumes the release's version is
the newer, better thing to fold in. In this case the project already had its own
`SessionStart` hook answering the same question, and merging would have injected the same table
twice per session (`AST-041`). The correct resolution was to **delete something of the
project's** — repoint the existing registration at the payload script, verify the new path
renders end-to-end, and only then retire the old file. An advisory that can only say "add mine"
cannot describe "yours and mine are duplicates and one has to die."

Bound: `scripts/docs-staleness-audit.sh`, `scripts/check-reachability.py` (check 4),
`scripts/selftest.sh`, `install.sh`, `prompts/ADAPT-HARNESS.md` (§3 plugs).

### AST-145 — A role identity routed through a namespace the project does not own · promoted 2026-09-20

A downstream project asked a narrow question — does `codex --profile <role>` read the repo's
`.codex/profiles/`? — and the answer was already in the CLI's own help: `--profile` layers
`$CODEX_HOME/<name>.config.toml`, and nothing else. The package had never claimed otherwise. It
shipped in-repo TEMPLATES and told the owner to copy each one into `$CODEX_HOME` by hand.

The narrow answer was the smaller half. **`$CODEX_HOME` is one namespace for every project on
the machine, and the key is a generic role name.** Two repositories adapting this harness both
want `builder`; the second one to be provisioned wins, silently, and no check on either side can
see it — each compares its own template against a destination that belongs to neither. That the
file had to be copied by hand was the second cost: `install.sh` cannot write outside the repo,
so the doctor reported an unprovisioned profile on every run until a human acted, which is how a
project ends up sitting on four `[MISS]` lines that mean nothing is wrong yet.

The third cost was ordinary duplication. `model` and `model_reasoning_effort` lived in the
profile AND in the orchestrator row, and a third of the doctor's Codex block existed only to
police the disagreement. **A value with two homes needs a referee; a value with one does not.**

The fix removes the namespace rather than guarding it. Everything travels on the launch line:

```
codex -m <model> -c model_reasoning_effort="<effort>" \
  -c developer_instructions="$(cat .codex/profiles/<role>.md)" \
  --dangerously-bypass-approvals-and-sandbox
```

`.codex/profiles/<role>.md` is plain text, in the repository, tracked, per-project. The row is
the only home for model and effort. Nothing is provisioned and nothing can drift.

**One consequence worth stating, because it changes how the file is written: it IS the system
prompt.** A line explaining the file to a reader is said to the agent. So the explanation moved
into the skill, and the file carries instructions only — which is also why the sentence *"it
exists so `codex --profile <role>` resolves"* had to be removed from all five rather than left
as a stale comment: a pane launched with it reads it as current instruction (AST-146).

Bound: `.agents/skills/dispatch-ticket-codex/SKILL.md` (gone), `.codex/profiles/*.md` (gone),
`.agents/orchestrator.md`, `check-requirements.sh`, `scripts/check-reachability.py` (check 4).

### AST-146 — An unrecognised configuration key is accepted in silence, so "it launched" is not evidence · promoted 2026-09-20

Measured on codex-cli 0.155.1 while replacing the launcher above. Three probes, run as a set
because the first one alone would have made the other two look unnecessary:

| probe | result |
|---|---|
| `-c totally_bogus_key_xyz="whatever"` | accepted, no warning, exit 0 |
| `-c developer_instructions="<text>"` | the agent obeyed the text; a control run without it did not |
| `-c model_reasoning_effort="definitely_not_a_level"` | HTTP 400 — at the first API call, not at launch |

**A typo in a config key costs a Builder with no contract and produces no error anywhere.** The
pane starts, looks healthy, reports for work, and is running on the base user config. This is
AST-032's shape (a signal that cannot fail is not evidence) one layer below where that entry
found it: not a check that always passes, but an INPUT that is always accepted.

So the pre-dispatch step stopped comparing two files and started asking the parser.
`codex debug prompt-input` renders the model-visible prompt as JSON without a model call, and
the role file must come back byte for byte. Two traps it caught that reading would not:

- `-c` parses its value as TOML FIRST and falls back to a literal string. Prose survives
  verbatim — headings, `$`, backticks, quotes, markdown links — but a file that is one quoted
  line comes back with its quotes stripped, and a file containing only `true` is refused with
  *invalid type: boolean, expected a string*.
- The first version of the verification snippet compared with `diff` against output written
  without a trailing newline, so it failed on a CORRECT file. It would have shipped as a step
  that is red for everyone, which is a step people learn to skip.

**What the check proves is delivery, and only delivery.** The bytes reach the pane; it cannot
say the bytes are right. A file still describing a retired mechanism passes it — so
`check-requirements.sh` WARNs on `--profile`, `CODEX_HOME` and `.config.toml` appearing inside a
role's instruction file, which is the half a parser can never answer.

Bound: `.agents/skills/dispatch-ticket-codex/SKILL.md` (gone), `check-requirements.sh`,
`scripts/selftest.sh`.

### AST-148 — One condition answering two questions delivered the second answer as the first · promoted 2026-09-20

`check-requirements.sh` read a role's codex row with `if ($2 == role && $3 == "codex" && $4 != "")`.
That last clause is a judgement about the MODEL cell smuggled into a test for whether the ROW
EXISTS. A row reading `| builder | codex |  | medium |` produced no output, and the loop below
reported `ok: no codex row — this role does not run on Codex` — which is what a DELIBERATE
decline looks like. The role was assigned to Codex and could not launch, and the doctor said
green in the sentence reserved for a correct configuration.

It survived because a second home covered it: the profile TOML shipped `model = ""` and a
different branch MISSed on that. 2.12.0 made the row the only home (AST-145), and the moment it
did, this blank cell became unreportable. **Removing a duplicate removes the redundancy that was
quietly answering for a defect elsewhere** — the deduplication is still right, and the check that
was leaning on the duplicate has to be found before it falls over.

Three distinct states, three distinct answers, and the fix is to ask three questions instead of
one: no row is a decline and reports `ok`; a row with `<set-me>` is the scaffold's resting state
and reports `ok` on a target; a row naming the runtime and no model is a `MISS`. It is AST-040
wearing a blank instead of a plausible id — *a default that cannot be right should not look
right*, and `ok: this role does not run on Codex` is the most reassuring-looking wrong answer
the block had available.

Bound: `check-requirements.sh`, `scripts/selftest.sh`,
`.agents/memory/recurring-failure-modes.md` (AST-040).

### AST-149 — No form of the command carried both the range and the intent, and the repair that suggested itself failed silently · promoted 2026-09-20

`codex-arm` documented the cross-vendor gate's raw invocation as

```
codex exec review --base "$BASE" -m <model> "<focus text>"
```

which on codex-cli 0.155.1 cannot run at all: *the argument `--base <BRANCH>` cannot be used with
`[PROMPT]`*, exit 2. `--commit <SHA>` refuses a prompt the same way, and `-` — the documented
way to read the prompt from stdin — IS that positional, so it is refused too. **Because argument
parsing fails before any review starts, the command produces no output file, which is
indistinguishable from an arm that was never fired.**

The first fix reached for the obvious alternative: pipe the focus without `-`. That is accepted,
and the focus is **discarded**. The run reviews the range under a generic `changes against
'<base>'` prompt and exits 0 with a complete, plausible review. Proven by piping *"Respond with
exactly PIPEWORKS"* and getting an ordinary review back with zero occurrences of the token.

**A loud failure was replaced by a silent one, and the silent one is worse.** Exit 2 with no
artifact is a gate that obviously did not run. Exit 0 with a full review, from a mandatory
intent-loaded gate that never saw the intent, is AST-032 exactly: a signal that cannot fail. The
downstream project that found the conflict shipped the piped form and recorded the correct
measurement in its own commit message one pass later, without the skill text catching up —
which is how a measurement and the instruction it should have corrected end up in the same
repository disagreeing.

**The general shape: when a documented invocation turns out to be impossible, the replacement
has to be measured for what it DELIVERS, not for what it exits.** Every arm form is now proven
with a token the prompt asks for and the reader greps: plain `codex exec` with the range named
in the prompt text carries both, and it was accepted only after the token came back.

Bound: `.agents/skills/codex-arm/SKILL.md`, `.claude/skills/codex-arm/SKILL.md`,
`.agents/memory/recurring-failure-modes.md` (AST-032).

### AST-150 — The launcher the shared protocol asks for cannot encode the identity the runtime needs · promoted 2026-09-20

2.12.0 moved the Codex role identity onto the launch command line as multi-line
`developer_instructions`. `herdr agent start … -- <args>`, which every other runtime's dispatch
uses and which registers the agent name in the same call, refuses it:

```
invalid_agent_argument — agent arguments cannot be encoded safely for the target shell
```

Measured with a control on herdr 0.9.1: the identical call with a **single-line** identity gets
past encoding and fails only on the pane id. **The cause is the newline, not the length** — and
every role file is multi-line, so `agent start` refuses every real Codex dispatch.

So the launch is two steps: `herdr pane run`, which takes the whole command as one shell string,
then `herdr agent rename` to restore the registered name. **`pane run` alone is half a
dispatch**: the pane has no agent name, so it is invisible to the watchdog that counts
dispatched agents, and it cannot be prompted by name at all — which the one-call
`herdr agent prompt` form depends on.

**And the step added to prevent an unregistered pane can itself produce one.** `rename` enforces
the same name rule as `start`: lowercase first character, lowercase letters, digits, `-` or `_`.
A project with uppercase ticket ids (`ABC-123`) fails at the rename — the END of dispatch, with
the agent already up and unregistered, which is the exact state the step exists to prevent. The
lowercasing rule was already written for `agent start` in the shared protocol and had never been
stated where `rename` is used.

Bound: `.agents/skills/dispatch-ticket-codex/SKILL.md` (gone),
`.agents/skills/dispatch-ticket/SKILL.md`, `.claude/skills/dispatch-ticket-codex/SKILL.md` (gone).

### AST-151 — An empty cell read as "the default" was refused at bootstrap · promoted 2026-09-20

With model and effort moved onto the launch line (AST-145), `check-requirements.sh` WARNed on a
codex row that named a model and left Effort blank, on the reading that an absent value falls
back to the account default. Measured: it does not. The launcher passes
`-c model_reasoning_effort=""` and Codex refuses it while loading configuration —
*reasoning_effort must not be empty* — so the pane never starts, and it fails AFTER dispatch has
reported a launch.

This is AST-040 one column over. That entry is about a placeholder that LOOKS like a real id; an
empty cell that looks like an intentional default is the same failure with the plausibility
supplied by the reader instead of by the value. Refused now where the empty model is refused.

**What made it findable is that the duplicate was gone.** While effort lived in both the row and
a profile TOML, the profile carried a real value and the blank row cell never reached a launch.
Deduplication does not create these; it exposes the ones a second copy was answering for
(AST-148).

Bound: `check-requirements.sh`, `scripts/selftest.sh`,
`.agents/memory/recurring-failure-modes.md` (AST-040).

### AST-153 — A transport that can hold a message returned success, and the sender had no other evidence · promoted 2026-09-25

`SendMessage` to another Claude session returns `{"success": true}` when the message is
transported. The receiving session can then hold it for its user's approval
(`crossSessionInbound`), and nothing tells the sender. Measured downstream: a gate brief to a
Rin launched without bypass sat held while the pane read `idle` — exactly what a gate that
started and found nothing looks like — and the verdict in the other direction was held too,
with the release prompt defaulting to Deny. The first diagnosis blamed the permission-mode
mismatch the pane printed; then a brief to a Builder launched WITH bypass was held as well, so
the mismatch is one trigger, not the cause. **A cause read off the error text was narrower than
the behaviour.**

The two roles fail differently. Rin with no brief asks, and goes `blocked`. A Builder whose
slash command already ran improvises from it and reads `working`. Delivery evidence therefore
belongs at the receiver — a phrase only the brief could have supplied, read from the pane — and
a gate brief goes by `herdr agent prompt`, typed input that crosses no permission boundary.

Bound: `.agents/skills/review-with-rin/SKILL.md` (gone), `.agents/skills/dispatch-ticket-claude/SKILL.md`.

### AST-156 — Three dispatch steps had no lock, and the same agent skipped two of them on the same day · promoted 2026-10-05

A downstream Thomas reported its own day. It violated none of the roughly thirty steps a script
refuses, and was stopped by one of them minutes before writing the report. It broke two that
nothing refused: it never wrote the dispatch record, then guessed a tab id at cleanup and
closed a working Builder; and it armed no watcher, writing a `while true; sleep 30` loop
instead. The second has a plain cause. The rule to wrap the watcher script was read at hour
zero, and the Monitor tool's description, which carries exactly that loop as its example, was
in the prompt at every hour after (AST-041, AST-069). The record step had a cause in this
package: the dispatch sequence listed nine steps and the record was not one of them. It sat in
a section after cleanup, so it was skippable by construction.

Same agent, same session, same day: the variable was never discipline, only whether
something refused. The obvious fix is another refusal. It was not taken, because two of the
three steps can be made to stop existing. The `astragentic-dispatch` mod runs inside every
Claude pane. The pane writes its own tab and pane ids from herdr's environment at session
start, runs its brief's first line as a real command, and reports each turn end to the
dispatcher, which is woken by a prompt. The dispatcher side refuses to close a mid-turn pane.
Measured 2026-10-05 on Claude Code 2.1.289 with a Builder in its own worktree: the record ids
were correct, a phrase present only in the brief body came back, the wake arrived under one
second after the turn ended (pane polling was 67 s late, AST-097), and the close was refused.
Two of the lab's own first drafts failed. Reporting every turn woke the dispatcher three times
for one task, on turns that only read delivery notices. Reporting only the brief's turn missed
the result of a Builder that backgrounded its work and finished a turn later.

**A step that can be removed beats a step that can be enforced. Enforce only what cannot be
removed.** The watchdog stays, because a pane whose process died takes its mod with it.

Bound: `.claude/skills/astragentic-dispatch/hooks/register.tsx`,
`.agents/skills/dispatch-ticket-claude/SKILL.md`, `scripts/selftest.sh`.

### AST-158 — "Its commits reached the base" passed for a branch that had no commits · promoted 2026-10-05

`git merge-base --is-ancestor <branch> <base>` is how both `ticket-done.sh` and the dispatch mod
asked whether a ticket's work had landed. A branch created at the base and never committed to
is an ancestor too, because its tip is a base commit. Measured twice in one lab run. The mod's
board read "merged" for a Builder that had committed nothing. `ticket-done.sh` stamped that
ticket done: git half "an ancestor of main", tracker half "closed". Only the plug stood between
an empty ticket and a closed one.

The same check was written twice, months apart, by two authors, and both trusted the question
over what it measured. Ancestry answers "is nothing on this branch missing from the base", and
an empty set is never missing. The work must exist before its arrival is checked. The mod
records the start commit at first registration, and keeps it there, because a reload re-fires
session start and rewrote it once in the lab. `ticket-done.sh` reads that start commit when it
exists, and otherwise requires the tip off the base's first-parent line. A fast-forward lands
on that line as well, and falls through to the existing subject test.

Bound: `scripts/ticket-done.sh`, `scripts/selftest.sh`.

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
Bound: `harness/scripts/check-reachability.py`.
