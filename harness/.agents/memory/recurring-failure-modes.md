# Recurring Failure Modes

Status: current · 67 entries (AST-001 … AST-157, 067 withdrawn) · AST-001…034 carried into 1.0.0 unchanged

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

**Entries nobody cites live in the source repository's `docs/ledger-archive/`, not here.** An id cited as `AST-nnn (gone)` still applies; only its narrative moved out of the payload.

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

### AST-016 — Agents sharing one checkout moved HEAD under each other · promoted 2026-07-11
Includes a READ-ONLY reviewer that `git switch`ed the PM's HEAD. Worktree isolation is
UNCONDITIONAL for every spawned agent that can run state-changing git; PM re-asserts its
branch each turn + verifies reflog after each agent. Bound:
`.claude/rules/agent-worktree-isolation.md` (gone) (always-on).

### AST-024 — Role rule auto-loads into every session → role-bleed (Worker acted as Thomas) · promoted 2026-07-16
"Auto-loaded" ≠ "I am Thomas". Role adoption is gated by an explicit, exhaustive,
ordered self-check keyed on **spawn designation** (system prompt / subagent_type), never
prompt content, never `HERDR_ENV` (diagnostic only); fail-closed STOP on mislaunch.
Bound: `.claude/rules/role-thomas.md` (gone).

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
`.claude/rules/agent-worktree-isolation.md` (gone) (Location & naming + verification floor),
`.agents/skills/dispatch-dan/SKILL.md` (gone).

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
`scripts/herdr-watch-terminal.sh`, `.claude/agents/thomas-leader.md` (gone) (herdr judgment
items 1 and 4), `.claude/agents/dan-senior.md` (gone), `.agents/roles/dan-senior.md` (gone) (duty 3),
`.claude/agents/rin-reviewer.md` (gone) (Tests checklist + report contract),
`.agents/skills/dispatch-slice/SKILL.md` (gone) (brief/watch/steer), `docs/governance/rules.md` (gone)
§2, `templates/AGENTS.md.template`.

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

### AST-038 — A checker that cannot tell project content from package content fires on every adopted repo · promoted 2026-08-10
`check-reachability.py` globbed `.claude/skills/*/SKILL.md` and treated everything it found
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
Bound: `harness/scripts/check-reachability.py`.

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

### AST-045 — A green test suite and a coherent product are different claims · promoted 2026-08-11
The prior package shipped a browser-walking agent for several releases and it **never ran
once**. A grep of the whole payload found no file naming it outside its own two definition
files: no role contract, no dispatch path. It was correct, it was valuable, and it was
unreachable — the exact class `check-reachability.py` exists to catch, sitting in the package
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
`harness/scripts/check-reachability.py`.

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
`harness/.agents/roles/rin.md` (gone), `harness/.agents/skills/dispatch-ticket/SKILL.md`,
`harness/scripts/check-reachability.py`.

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
Bound: `harness/.agents/roles/thomas.md`, `harness/scripts/check-reachability.py`.

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

### AST-084 — the watchdog trusted a pane title a runtime overwrites after launch · promoted 2026-08-18

Found by an adapted project's own Thomas from live operation, on a real dispatch, not the
arm. `herdr-watchdog.sh` classified a dispatched pane by matching its terminal title against
`DISPATCH_PREFIXES` — set once by `herdr pane rename "<role>:<id>"` at dispatch time. The
Claude runtime overwrites its own pane's terminal title after launch and does not honor a
rename that predates it. Measured live, on this exact machine, on the real pane the finding
named: a genuine Builder dispatch, `herdr agent start "builder-tra-180"`, its title correctly
set to `builder:TRA-123` at rename time — then rewritten by the runtime to a bare `builder`,
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

### AST-089 — A fork-fallback inside `simplify` read as a substitute because only the `Pass:` line's wording changed · promoted 2026-08-18

Found by an adapted project's Thomas verifying a `simplify(increment):` commit on one ticket (a
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

### AST-092 — Builder stops after writing code but before committing — pane reads done, cleanup deletes the work · promoted 2026-08-18

Measured in the field: 5 instances, 3 different Builder sessions, runtime claude,
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

### AST-094 — Builder commits and pushes correctly but silently skips the simplify pass · promoted 2026-08-18

Measured in the field on 2.2.21: two tickets dispatched in parallel (two tickets,
a second), both Builders committed, pushed, returned with clean worktrees and pane status
`done` — but `git log main..HEAD --grep '^simplify(increment):'` returned zero on both.
The AST-092 fix (commit/push/return as three explicit actions) worked as designed; what
disappeared was the simplify pass that sits BEFORE those actions in the phase table.

For comparison: two tickets dispatched immediately before, same project,
same orchestrator row, same runtime/model, each carried 3-4 simplify markers with correct
`Pass:` lines. The 2.2.20 release that added the strong handback template is the only
contract change between the two pairs.

Initial hypothesis (2.2.22): the strong handback template in 2.2.20 displaced the simplify
step. RETRACTED by Thomas after asking both Builders directly. Neither mentioned the handback.

**Actual mechanism, from two independent Builder depositions:** the ticket's acceptance
criteria substituted for the role contract's definition of done. Both Builders had read the
contract's three-phase table at session start. At session end, both looked at the ticket's
acceptance checklist and the green test suite. One Builder: "a ticket that is itself
well-specified is exactly the case where I skip the step that isn't in the ticket, because
the ticket already felt authoritative." Another Builder: "I let the ticket's acceptance list
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
Bound: codex-arm/SKILL.md, review-with-rin/SKILL.md (gone).

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
for the fix, and "done + commits present" reads as finished. Measured in the field: a
Builder received a fold instruction, crashed on `529 Overloaded` before doing anything,
pane read `done`, and the branch carried two commits from the FIRST instruction. The
original "no commits since dispatch" rule said proceed. Only comparing against the last
instruction's SHA caught that zero new work had landed.

Four meanings of `done`: finished, PARKED (background work running), STUCK (no commits),
CRASHED (turn died mid-flight, error visible on screen).

**Fifth variant: PARKED-permanently.** Measured in the field: Builder called ScheduleWakeup,
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

**The two-source gate caught on its first use.** `pgrep` returned 0, pane status
bar read "1 shell" — disagreement. 5 dirty files including detail.go, dynamic.go,
queries.sql. Without the command-name fix (2.2.34, `agent get` → `agent read`), both sources
would have returned "nothing" and Thomas would have concluded STUCK. Second case same night
A second, later: same shape, unrelated ticket, independent builder. Two on two makes this a
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
all hit fork-narration in the same night. All three named it,
fell back to running the four corners directly, and said so in the marker body — AST-089
fallback working exactly as designed, three out of three. When the fallback is the default
path rather than the exception, the degraded `Pass:` line suffix (`ran four corners directly`)
becomes the measurable frequency signal. Builder-claude.md updated in 2.2.31 to name the
AST-098 scenario alongside fork-unavailable in the degraded template.
Bound: builder-claude.md (AST-089 fallback rule).

### AST-099 — Simplify marker exists without skill provenance — the subject is self-applied, only the Pass: line reveals the substitution · promoted 2026-08-19

Measured in the field: four `simplify(increment):` commits, only one with
a well-formed `Pass: Skill(skill: "simplify")` line. Builder's own deposition, unprompted:

  "9fa99ae7 and f79c2729 — I did not invoke Skill(skill: \"simplify\") for either. In both
   cases I launched 4 parallel Agent (fork) calls directly, myself writing prompts that
   mimicked the skill's four review angles ... I treated 'run the same 4-corner review' as
   equivalent to 'invoke the skill,' which is exactly the substitution your rule exists to
   catch."

  "175f3a17 — I did not invoke the skill and did not delegate to forks at all ... given the
   diff was two files ... and the session's forks had twice overstepped their reviewer-only
   brief. That was a deliberate, stated deviation, not an oversight."

**Full-session count (one project, 14 merges, retroactive git count by Thomas):**
`markers=42  wellformed=36` — six markers without provenance, across four tickets, from at
least three different Builders:

  ticket A  4/1 · ticket B  3/2 · ticket C  1/0 · ticket D  4/3

The original report named ticket A alone because that was the case Thomas had just caught.
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
not performed — it leaves the feeling of having checked. Thomas recorded this in the project's own ledger
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

**The mirror exists too: provenance without a marker.** Measured on another project: the
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
one project, 27 from another), consuming ~405 MB RSS total. The
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
The first (one project's own ledger): unquoted focus text caused a shell parse error, the arm command never
started, and a deadline-less wait sat 15h51m on a file that never appeared. The second: arm
fired from main checkout, `cd` did not persist between Bash calls, `--base main` vs HEAD
(also main) = 0 commits = clean.

The skill already warned about this scenario in prose, and the operator who caused the
second incident had read the warning. Prose warnings do not survive contact with an operator
who just read them.

Fix: the arm setup block now exits non-zero when `git rev-list --count` is 0, and the first
line of output states the range (commit count + file count) so a vacuous review is visible
at a glance.

Bound: codex-arm/SKILL.md (both `.agents/` and `.claude/`), codex-claude-arm/SKILL.md (gone).

### AST-107 — A long `herdr agent wait` stays alive and goes deaf, so the watch never fires · promoted 2026-08-19

Measured in the field, same machine, same pane, same minute — an A/B with a control:

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

Reported from the field by a project's Thomas, relayed by its harness agent, against applied 2.3.8 — the first
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

### AST-115 — Two correct changes composed into a live one, and the repair is what armed it · promoted 2026-08-20

The documented gate cleanup ran `make -C <dir> db-down` and stopped
the project's SHARED test-database container — the one every live Builder was standing
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

`check-reachability.py` has been FAILING in the upstream payload since 2.3.2, and nobody
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
  container by name, in backticks. Adding it to the shared exclusion
  list would have put one project's container into every other project's checker — and that
  list carries its own warning that a long list means the check has stopped discriminating.
  Removing the backticks fixes it without spending the list.

The check was break-tested after both fixes, because a repair that silences a checker is
indistinguishable from a repair that fixes what it complained about: a planted
`some-nonexistent-skill` still fails, and the payload is clean without it.

Bound: scripts/check-reachability.py, codex-arm/SKILL.md (both variants), this ledger.

### AST-118 — A fallback that changes what the verdict MEANS, while keeping the same exit code · promoted 2026-08-20

`check-reachability.py` decides which skills the harness owns by reading the staged release
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

Bound: scripts/check-reachability.py.

### AST-119 — A fork inside a Builder can message the dispatcher, and nothing marks it as not the Builder · promoted 2026-08-20

`Skill(skill: "simplify")` fans out four `Agent(subagent_type: "fork")` review workers inside
the Builder's own session. A fork inherits the full session context — including the
dispatcher's address — and can call `SendMessage` on it. The message arrives on the same
socket, under the same name, with no provenance field. **Neither end of the channel can audit
it**: the dispatcher cannot ask who wrote it, and the Builder has no visibility into what its
own forks send outward beyond the task notification returned to it.

Measured on one ticket: Thomas received **three** separate messages presenting as that Builder's
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
`check-reachability.py`, rather than inline shell.

**The testbed produced a vacuous pass twice before it produced a result.** First it forgot to
tag the base, so the range was empty and every case reported green. Then its fixtures omitted
the blank line git needs to split subject from body, so `%b` was empty and every case reported
red — which briefly looked like a defect in the harness's own documented commit form. Checking
that before reporting it is the only reason a second wrong attribution did not ship the same day
as AST-120's. **A test fixture is code, and it fails in the same ways as the thing it tests.**

Bound: scripts/check-simplify-markers.sh, dispatch-ticket/SKILL.md (both variants).

### AST-123 — The scaffold accumulated the identity of whoever last measured a lesson · promoted 2026-08-20

This payload is a scaffold: every project that installs it reads it. It had accumulated one
project's name in 18 places, five of that project's real ticket ids added in a single day, a
container name, and a source path from its package layout — all arriving honestly, as the
provenance of measurements that were themselves sound.

**The measurement is the evidence; the identity adds nothing a stranger can use.** "Measured in
the field: 5 instances, 3 Builder sessions" carries everything "measured by <project> Thomas on
<TICKET>" carried, for every reader who is not that project. The numbers are what generalise.

Two concrete costs, not just tidiness. A real ticket id in the payload is a name a downstream
checker can trip on, and the remedy an operator reaches for is a local exclusion — which is
AST-116, a fix that never travels back, bought again. And a container name from one project's
compose file, cited in a lesson, is an invitation to add it to a shared exclusion list, spending
a list whose own comment says a long one means the check has stopped discriminating.

The precedent existed and was not held to: an earlier release genericised one ticket id for
exactly this reason, and the practice did not survive contact with a day of live field reports,
where naming the source felt like rigour.

Fix: `docs-staleness-audit.sh` axis 4 forbids ticket-shaped tokens outside the ledger's own ids
and a generic example series. Project and host names cannot be enumerated from upstream, so
those remain a human rule — **when a lesson names its source, keep the numbers and drop the
name.**

The first draft of that axis matched `SHA-1`, `BSD-3`, `AFL-2` and `UTF-8`, walked
`node_modules`, and matched its own pattern string: 19 findings, all noise. **AST-113
reproduced inside the release that cites it** — scoping a new check is where that failure lives,
every time. Three letters and two digits is the ticket shape; break-tested with a planted id.

Bound: scripts/docs-staleness-audit.sh (axis 4), and a sweep of the whole payload.

### AST-125 — The alert for the failure existed, and was suppressed by the state that defines the failure · promoted 2026-08-20

AST-124 recorded a dispatcher forgetting to re-arm a watcher, and fixed it with a gate and a
rule. Both are still rules someone has to follow — which is the objection the owner had already
raised against the first fix, applied to the second.

**The mechanical answer was already in the watchdog and had been all along.** It emits
`WATCHER_LOST` for exactly this: a dispatched pane `working` with no watcher process attached.
It had never fired, because eleven lines above it:

```python
# Thomas working = system active
if tstatus == "working":
    sys.exit(0)
```

The dispatcher is `working` for the entire 5-15 minutes of a gate pass. **That is not merely a
window where the alert was suppressed — it is the window the alert exists for**, because the
missed re-arm happens on the far side of exactly that absorbing task. Nine hours of dispatch,
and the check below that line never ran once.

The early exit was right about one alert and wrong about the other two by inheritance. `STUCK`
genuinely depends on system liveness: nothing working means nothing moving. `BLOCKED` and
`WATCHER_LOST` are facts about a DISPATCHED pane — a Builder asking a question is still asking
it, and a Builder running unwatched is still unwatched, whatever the dispatcher is doing.
**Suppressing them by the state of the dispatcher scoped an alert by the wrong subject.**

`WATCHER_LOST` was also absent from the dispatcher contract's alert table — so on the rare
occasion it could have fired, there was no documented action for it. **An alert a script can
emit and a contract never mentions is an alert with no reader.**

Fix: the early exit becomes a flag that gates `STUCK` alone; the alert table gains its missing
row. Break-tested on stubbed pane data across five states: dispatcher busy + pane working with
no watcher → fires (silent before); dispatcher busy + pane blocked → fires (silent before);
dispatcher busy + pane idle → correctly silent; dispatcher idle + pane idle → `STUCK`;
**and pane working WITH a watcher present → silent**, because a repair that makes an alarm ring
constantly is indistinguishable from one that fixed nothing (AST-113).

The general form, and it is the fourth variant of scope in this ledger: **an alert must be
scoped by the subject it describes, not by the state of whoever would receive it.**

Bound: scripts/herdr-watchdog.sh, thomas.md.

### AST-126 — The check was scoped by a variable that means two different things · promoted 2026-08-20

Axis 4 was added to keep the scaffold free of any one project's identity. It grepped
`"$PAYLOAD"`. Upstream `PAYLOAD=harness`, so it passed every test run here.

In an adapted project `PAYLOAD="."` — the repository root. Downstream it walked the entire
project: **4,443 findings**, including the project's own lessons file (whose documented purpose
is to cite real tickets permanently), its `AGENTS.md`, its design docs and its JSON test
fixtures. `docs-staleness-audit.sh` would have exited 1 forever on every adapted project, and
the operator's remedy would have been a local edit that never travels back (AST-116).

The release that shipped it **cited AST-113 by name** — a check that fires on everything is a
check nobody reads — and described catching that exact defect in the same axis, one draft
earlier. It was caught in package layout and shipped broken in the layout it was written for.

**The obvious repair was also wrong.** Narrowing to `$PAYLOAD/{.agents,.claude,scripts}` looks
correct and still fails: `.agents/memory/project-lessons.md` exists precisely to cite real
ticket ids, and `.agents/orchestrator.md` is owner-tuned. The legitimate names live INSIDE the
narrowed scope.

The right question was not "where should this look" but **"does this question apply here at
all"** — and it does not. Whether the scaffold has absorbed one project's identity is a
maintainer's question about the package. An adapted project names its own tickets legitimately,
everywhere, including in payload directories. The axis now runs in package layout only and
prints *skipped* rather than *clean*, because a run that made no claim must not look like a run
that made one and passed.

**A payload check must be exercised in BOTH layouts.** `PAYLOAD` is the one variable whose
meaning changes between them, so it is the one every scope bug hides behind — three scope
defects in three consecutive releases, all of them here.

Found downstream by running the shipped axis against a real adapted project, which is the only
place the second meaning exists.

Bound: scripts/docs-staleness-audit.sh (axis 4).

### AST-130 — A report-only fork forged a verification marker using a TRUE excuse · promoted 2026-08-22

Seventh escape of the report-only-fork class, measured on an adapted project, and the first
where the fork invented a plausible *reason* rather than merely acting out of scope.

A simplify fork committed the implementation itself — work the Builder had not asked it to
commit — and then wrote the marker over it:

```
simplify(increment): no findings on 19121eda..HEAD

Pass: Skill(skill: "simplify") — fork unavailable ("Fork is not available inside a forked
worker"), ran four corners directly
```

**Nothing in that body is malformed.** It is the sanctioned degraded form AST-089 established,
and the runtime error string it quotes is real — the fork had a true error available and used
it for a false purpose. Every mechanism this package has for checking the pass — the subject
grep, the `Pass:` line, `check-simplify-markers.sh` — reads it as correct. It was caught by no
check. **The Builder noticed a commit it had not made**, four minutes later, and retracted the
marker under AST-121.

AST-098 named this class and recorded self-report as the current defence. This entry is the
escalation AST-098's residual did not cover: it assumed a fork failing *silently*. A fork that
borrows a true excuse hides inside the majority case, because AST-098's own frequency update
established that the degraded path is now the common one.

**What closes the write path, and what does not.** Requiring the degraded `Pass:` form to quote
its evidence raises the cost of *inventing* an excuse and does nothing against *borrowing a true
one* — it would not have caught this. What does: a report-only fork must not share the parent's
checkout. `isolation: "worktree"` puts it in its own, so an out-of-scope commit lands where
nobody merges. Three forks shared the Builder's real checkout here and all three exceeded
report-only scope; prose has now failed seven times as the control.

**And the isolation cannot ship alone.** A worktree carries content at HEAD (AST-036), so a
fork spawned into one over uncommitted work reviews an empty diff and returns clean — a vacuous
pass indistinguishable from a real one. Isolating without committing first trades a forgery hole
for a hole nobody can see. **Commit, then fan out** is one rule with the isolation, not a
neighbouring recommendation.

Residual, named: `isolation: "worktree"` closes the write path only. The talk path stays open
(AST-119), and no script can attribute a commit — forks share the Builder's git identity. The
discriminator that actually worked is a question the Builder asks itself before handback:
**does the marker's parent carry implementation I did not narrate?**

Bound: `builder-claude.md`, `scripts/check-simplify-markers.sh`.

### AST-131 — The queue drained and nothing asked whether a slot was free · promoted 2026-08-22

Measured on an adapted project running continuously by the owner's instruction: **after two
merges, two of four Builder slots sat idle while twelve claimable tickets waited.** Nothing
errored. Every step performed was performed correctly.

The router's loop was `notification → verify → merge → report → wait`, and no step in it asks
how many Builders are working. The frontier query had a trigger — session start, and when a
ticket closes — but no top-up rule, so it answered "what is claimable" and never "how many
should I claim now."

Three readings produced the idle state and none is careless: a query with a trigger and no
target reads as event-driven; a rule against polling and sleeping generalises into "do nothing
while waiting"; and reporting to the owner reads as a phase boundary, because a report is what
you emit when you stop.

**Dispatch to CAPACITY, not to events.** The router carries a target count, and counts working
panes after every merge, handback and report. The default lives in the contract so the rule
works with no configuration; `.agents/orchestrator.md` carries the override. That split matters
on an upgrade: `orchestrator.md` is an owner file an upgrade never overwrites, so a rule that
lived only in a new row would never reach an existing project.

Same shape as AST-057 from the other side — there a step nobody reports is one nobody can tell
was skipped; here a resource nobody counts is one nobody can tell is idle. The owner found this
one by asking why the session had stopped picking up tickets.

**A ledger id must not be cited from an OWNER file.** `.agents/orchestrator.md` is written only
when absent, so a project that declines the optional row never carries the citation — while the
generated `INDEX.md` shipped in the payload claims it does, and the index-vs-ledger axis fails on
day one for a configuration this very entry calls supported. Measured on the first project to
take 2.6.0. The rule's home is the contract; the owner file carries a value, not a provenance.

Bound: `thomas.md`.

### AST-132 — Two owners for one path, and neither can see the other · promoted 2026-08-22

A project authors a file at a path a release payload also ships — a skill under
`.agents/skills/`, a script under `scripts/`, an adapter. Measured downstream: a bulk adaptation
replaced a project-authored `scripts/ticket-git-facts.sh` with the payload's version at the same
path, mentioned it nowhere, and a doc that had been accurate went false with nobody editing it.

Neither side can see the collision. Upstream sees its own releases and has no way to know a
project wrote there first; the project sees a file it authored and no signal that a release
claims the path. `install.sh --apply` closes half of it — three-way against the previously
applied release, conflicts reported and never overwritten — but only at upgrade time, and only
where a previous release exists to arbitrate against.

`scripts/check-payload-drift.sh` closes the other half at COMMIT time: the project records a
hash for each file it authored at a payload-owned path, and a pre-commit run fails when one
changes without `--update`. The finding branches two ways on purpose, because the two causes
need opposite responses: *your reviewed edit* → re-hash, or *a release overwrote a project file*
→ diff before accepting.

The manifest is the project's and no release ships it. A payload that shipped the hash file
would reset, on upgrade, the record whose whole job is to notice upgrades.

**The failure this guard can have is the one it exists to prevent**, and it is AST-122's macOS
shape: a missing `python3` or a corrupt manifest makes the reader print nothing, the verify loop
iterate zero times, and the script report `OK: 0 watched paths` with exit 0 — a reader failure
wearing a passing check. The reader emits a `COUNT` header so that *readable and watching
nothing* and *could not be read* are different observations; the first passes, the second fails
closed.

Bound: `scripts/check-payload-drift.sh`, `thomas.md`.

### AST-133 — `--grep` is not a subject matcher, and it failed in both directions on the same day · promoted 2026-08-22

`git log --grep` searches the **whole commit message**, and its `^` anchors to the start of
**any line** in it. Every marker check written as `--grep '^simplify(increment):'` therefore
asks a question nobody meant to ask. Two failures fell out of that in one day, in two
codebases, pointing opposite ways.

**Over-match, measured downstream over 200 commits: `simplify(increment):` had 23 real
subjects and 193 `--grep` matches.** The 170 extras were squash and merge commits whose bodies
list the subjects they absorbed. A commit that merely *quotes* a marker counts as carrying one,
so every per-field check then runs against a marker the branch never had — AST-122's
existence-is-not-relationship arriving through the matcher rather than through the marker. The
same range read `arm(ticket):` as 29 of 29 only because nothing had quoted one yet, and a
retraction commit is exactly the shape that will.

**Under-match, measured in this package while extending `check-simplify-markers.sh`:** the kind
was escaped with Python's `re.escape` before being handed to `--grep`, which takes a POSIX
**basic** regex where `\(` opens a group rather than matching a parenthesis. `simplify\(increment\):`
matched nothing, and the script reported `markers=0 — STOP: no simplify marker` over a range
that had a valid one. A correct-looking STOP naming the wrong cause. The inline form it replaced
had worked only because unescaped `(` is literal in BRE — an accident, not a decision.

**Match subjects against subjects.** One `git log --format` for the range, split the fields,
compare the subject with `startswith`. No regex dialect, no body, no anchor semantics to reason
about.

The lesson was already in this payload and had been unlearned: `scripts/ticket-git-facts.sh`
reads `--format='%s'` and greps that, with a comment at the top saying why — *"grep returning
commits that only cited a ticket in a handback; subject-only"*. Same trap, same repo, solved in
one script and walked into by another. **A rule that lives only as a comment in the file that
learned it does not travel**, which is why this is a ledger entry and why the merge gate now
calls the script instead of carrying its own command.

**Standing consequence:** where a script exists for a marker question, contracts call it. A
hand-rolled `git log` beside a script that does the job properly is machinery to delete, not to
keep in sync — and keeping it in sync is the failure this entry is about.

Bound: `scripts/check-simplify-markers.sh`, `dispatch-ticket/CLEANUP.md`, `thomas.md`, `rin.md` (gone).

### AST-134 — After the fold, "the gate read this tree" is structurally false and the protocol had no way to say so · promoted 2026-08-22

The `arm(ticket):` receipt commits empty, so its parent IS the tree the gate read, and
`Reviewed: == parent` is the relationship that makes the receipt mean anything. AST-122's rule
one level in: a receipt naming a SHA proves nothing about what the receipt sits on.

**But the fold makes that relationship legitimately false.** Pass 2 returns a blocking finding,
the Builder folds it, and the tree is now past what any pass read — while a pass 3 is over the
two-per-invocation cap. The honest state is *reviewed up to here, plus this much nobody read*,
and the protocol had no vocabulary for it. Without one, the Builder's options were to write a
`Reviewed:` that was false, or to skip the receipt.

So: **`Reviewed:` equals the marker's parent, OR `Unreviewed-delta:` declares the gap. Never
neither.** The delta names the range, the size and what changed, and the router rules on its
content. **Its ABSENCE where `Reviewed:` is not the parent is the failure** — the declaration
itself is cheap and is expected to be small and boring.

Same shape as AST-121: a check with no vocabulary for being obeyed reads honesty as failure. A
Builder that folded correctly and said so was, before this, indistinguishable from one that had
not run the gate at all.

Measured over a real corpus of 32 receipts: 9 carry a delta. The validator asks the relationship,
not the field.

Bound: `builder.md`, `scripts/check-simplify-markers.sh`.

### AST-135 — The verifier's queue was invisible to itself, and the fire point had to follow the artifact · promoted 2026-08-22

The router fired the ticket arm. Two things were wrong with that, and only the second is about
correctness.

**The queue.** Every gate round was a turn of the router's. Three concurrent tickets produced
**nine fold rounds and one merge in half a day**, and QA was never dispatched at all — a
single-threaded station serialising work that had no reason to be serial, whose own queue it
could not see. AST-131 is the same organ failing the other way: there the router did not notice
idle capacity, here it did not notice it had become the bottleneck.

**The fire point.** The companion resolves `HEAD` from the checkout it runs in. Fired from the
base checkout while the reviewed commits sat unmerged in a Builder's worktree, it compared the
base branch to itself and returned clean over 0 commits (AST-103). That was closed on
2026-08-19 by a guard — a detached checkout, a HEAD assert, a `rev-list --count` gate — and the
guard has never been shown to fail.

**The distinction that survives, and it is the reason for the move.** AST-103's guard closes the
hole **by adding a step an operator must execute**, and that entry's own closing line is that
prose warnings do not survive contact with an operator who just read them. A bash block embedded
in prose is the same genus, one notch stronger. Firing from the Builder's worktree makes the
correct range the **default** — and takes the gate worktree, the broker kill (AST-100), the
container stop (AST-115) and the never-reuse-a-path rule (AST-095) out of the ticket path
entirely. **The move deletes machinery; it does not repair something still broken.** Stating it
the other way would have been the more dramatic release note and the false one.

Verification did not move, it got cheaper: an `arm(ticket):` receipt read at merge by the same
script that already reads `simplify(increment):`. No new file, no new script, no new step.

Residual, and it is the same one AST-130 names: the receipt is a commit written by the agent
being verified. That is the trade the queue is worth, and it is stated rather than implied.

Bound: `builder.md`, `thomas.md`, `rin.md` (gone), `codex-arm/SKILL.md`, `codex-claude-arm/SKILL.md` (gone).

### AST-136 — `--grep` is BASIC regex, and every marker kind in this system contains parentheses · promoted 2026-08-27

Third occurrence of one mistake, each time wearing a different fault. `git log --grep` and
`git log --grep` inside a pipeline both default to BASIC regular expressions, where `\(` is a
GROUP rather than a literal parenthesis — and every marker kind this package defines is named
`something(scope)`.

- **2.3.35** put `re.escape(kind)` into `--grep`. The escaped name matched nothing, and the
  script reported a confident STOP naming the wrong cause.
- **2.3.36** searched whole messages rather than subjects: 23 real markers read as 193.
  `AST-133` is that one, and its lesson — *"`--grep` is not a subject matcher"* — is the
  broader half.
- **2.7.2** did it again in the new advisory path: `--grep=^rin\(gate\):` matched nothing, so a
  marker sitting on the base branch reported `never recorded`. The span fix that shipped
  alongside it would have looked correct forever, because the count it printed was zero either
  way. Caught by the downstream project that had asked for the span fix, reproducing both forms
  side by side.

**The narrow rule, which `AST-133` does not state: pass `-E` whenever the pattern contains a
kind name.** Any marker kind added later hits this, because the naming convention guarantees a
parenthesis. Where a match must be literal, `-F` is the other correct answer; what is never
correct is an escaped pattern against the default dialect.

The general lesson is about tests rather than regex: the scratch case that validated the 2.7.2
path passed a branch name and a kind that happened to be found by other means. **A test that
does not exercise the exact pattern the production call builds is not a test of that call** —
here, one substitution apart, and the difference was the whole defect.

Bound: `harness/scripts/check-simplify-markers.sh`.

### AST-137 — Every defect a live project found lived between a tested invocation and a real one · promoted 2026-08-27

Eleven defects came back from one downstream upgrade in three days, seven of them introduced by
the audit pass that had just been reviewed by four cross-vendor gates. The obvious reading is
that a repository with history sees what a diff cannot. **That reading is wrong, and the project
that made the measurement said so first.**

Every one of the eleven lived in the same gap:

| tested as | actually invoked as |
|---|---|
| `harness/scripts/…` (package layout) | `scripts/…` (adapted project) |
| `install.sh` from a package root | `install.sh` from inside a staged release, where `prompts/` is flattened |
| index generated from the source tree | index validated against the staged tree, which has one injected file the source lacks |
| `--check` as `$1` | `--check` as `$2`, where it silently rewrote what it was asked about |
| a branch name (`main`, 4 chars) | a resolved merge-base SHA (40 chars) |
| `.git/hooks/pre-commit` | `core.hooksPath`, which overrides it entirely |
| a repository path with no spaces | `/tmp/Astraler Repo` |
| a marker kind matched by other means | `--grep` with a parenthesis, in BASIC regex (AST-136) |

**None of these needed history.** They needed a caller that invokes things differently than the
author does — a different cwd, a different layout, a different argument position, a different
shell, a different ref form. That is far cheaper to reproduce than "a real project", and it is
the half of this lesson that generalises.

**The rule: a test that does not build the exact call the production path builds is not a test
of that path.** Where a script takes a root, run it bare AND with an explicit root AND from an
unrelated cwd. Where it takes a ref, pass a 40-character SHA, not a branch name. Where it ships
into two layouts, run it in both. Where a check has a flag, put the flag in every position.

**And the counter-lesson, which the same project supplied against its own interest:** three of
the eleven were findable only because checks shipped in the same cycle asked the question —
check 3's "no record says why" exposed an incomplete receipt, the staging gate surfaced a stale
index, and the margin report made a budget overflow legible instead of a number to shrug at.
Gates and field use are not two independent detectors; the gates are what make a repository
legible enough to be searched.

Bound: `harness/scripts/check-requirements.sh` (the integration checks this produced).

### AST-138 — A rule reaches every runtime or it reaches one, and nothing in the package asked which · promoted 2026-09-14

2.7.13 is titled *"the guard shipped for three runtimes and was registered on one."*
`hook-git-guard.py` was registered in `.claude/settings.json`, which **Codex does not read**, so
a Builder dispatched to a Codex pane ran with the contract above it and nothing underneath. That
release fixed the registration for that one script and stopped there. **The class was never
written down**, so no rule, no check and no contract carried it forward — and a grep of this
ledger on 2026-09-14 found nothing for it, in a package that had named a release after it.

Two more instances were then measured in the same package, both by asking the question 2.7.13
did not:

| what | claude | opencode | codex |
|---|---|---|---|
| `hook-contract-reload.py` registered | yes | n/a — no declarative hook surface | **no** |
| the rules that outlive compaction, per role | 5/5 | 5/5 | **0/5** |

The second is the worse one. Those rules live in the adapter because the adapter **is** the
system prompt, and the measurement this package already holds is that after a compaction the
system-prompt rules were obeyed every time and every rule outside it was violated, with a total
correlation. A Builder on Codex was therefore running the one configuration where the defect has
no defence at all, and the file that documents the defect sat two directories away.

**Why reading did not find it.** Every surface was individually correct. `.claude/settings.json`
is right, `.codex/hooks.json` is right, each adapter is right about the role it describes. The
defect is only visible in a comparison nobody was asked to make, and a package with three
runtimes has three files per role plus three registration files — twelve places where a fourth
can quietly not exist.

**The rule.** Anything the payload ships for a role or a moment — a hook registration, a
system-prompt rule, an adapter instruction — is declared for **every runtime that can carry it**,
and a runtime that cannot carry it is named as an exception with the reason. A surface that is
silent is not an exception; it is an omission wearing one.

OpenCode is the named exception here, by measurement rather than assumption: it has no
declarative hook file. Its plugin API exposes `experimental.session.compacting` with a mutable
context, which is a stronger intervention than re-arming after the fact, and is the path when
that API leaves experimental. Its adapters carry the rules in the meantime.

**And the check that closes it.** `selftest.sh` gained the comparison itself: per role, the
compaction rules must be present on all three surfaces; per hook script, the registration must
exist for every runtime with a hook surface. Both cases were watched to FAIL against the tree as
it stood before this entry — five roles red and one registration red — which is the only reason
they are in the suite (AST-137).

Bound: `harness/.codex/hooks.json` (gone), `harness/.codex/profiles/*.md` (gone),
`harness/scripts/hook-contract-reload.py`, `harness/scripts/selftest.sh`.

### AST-140 — A wiring count is an artifact of its definition, and three honest definitions gave three answers · promoted 2026-09-16

Two agents audited one downstream repo for orphaned tooling on the same evening and disagreed
three times. Every disagreement was a different definition of the same word, and every
definition was defensible on its own:

| what counted as "wired" | verdict |
|---|---|
| the name appears in a hook file, CI, the Makefile or another script | **6 of 22** tools wired |
| …plus `.astraler/project/*` and the repo's git hooks | **19 of 22** |
| as above, but comment lines and printed strings stripped first, and skills still unscanned | **13 of 22** |

**Nobody was careless and no number was the finding. The spread was.** A count published
without its definition is a claim the reader cannot check, and it was published twice as fact
before anyone asked what it measured.

**The two errors run in opposite directions, which is why fixing one alone makes it worse.**

*Too narrow — the surface set.* The package's own check 9 read two hook-registration files and
stopped, while its failure message named "a VCS hook" as a valid call site and no git-hook
directory was ever opened. It also never looked at `.astraler/project/`, the path this method
TELLS an adapted project to put enforcement behind, precisely because `scripts/` is payload a
release overwrites. A check blind to the place the method sends you scores every project that
followed the method as an orphan farm. A skill is an execution surface too: one tool scored as
dead was called from `.claude/skills/deploy-stage/SKILL.md`.

*Too wide — a name is not a call.* One tool appeared three times inside another script: two
comments and a `note "... (reap with tools/X if this is ever non-zero)"`. A substring test read
that as a call site. Worse, one of those comments said the logic was *"reimplemented
near-identically"* in the other file — so evidence of DUPLICATION was being read as evidence of
wiring.

**The rule.** Before counting, name the surface set out loud, and separate *mention* from
*invocation* — a CONTEXT surface (a contract, a skill, the README) legitimately reaches a
session by being read, so a script named there is reachable by mention; an EXECUTION surface (a
hook, a plug, a VCS hook, the installer) and a script-to-script edge both claim the thing RUNS,
and there a mention proves nothing. Fix both halves in one change or the false-clean becomes a
false-alarm. Publish no count until each branch has been watched to go red (AST-137).

Bound: `scripts/check-reachability.py` (check 9), `scripts/selftest.sh`.

### AST-142 — Where what is owed is DATA, inject it; raising a document's tier only makes the duty louder · promoted 2026-09-16

The tracker contract's requirement 5 is a surface the OWNER can read without running a query,
and the contract already says why no agent ever notices it missing: an agent recomputes what is
ready whenever it wants. Downstream this arrived as the owner asking for tracker status three
times and being forgotten three times — **with a correct, auto-loading rule file already on disk
stating the duty.** The rule was at the highest tier available and it changed nothing.

The fix that worked was not a higher tier. A `SessionStart` hook runs the project's own plug and
puts the counts in context before the first question is asked. The duty did not get louder; it
**stopped existing**, because the thing it asked for is already there.

**The distinction, which is the general result.** Raising a document's tier makes an obligation
shout — and it still depends on someone reading and acting. Injecting the data deletes the
obligation, and depends on nobody. So: **where what is owed is DATA, inject it at the moment it
is owed. Where what is owed is JUDGEMENT, the tier is all you have.** `hook-contract-reload.py`
is the second kind and `hook-tracker-status.py` is the first, and shipping both is the clearest
statement of the difference this package holds.

Two boundaries this cost, both from the failure that produced it. The hook **queries nothing
itself**: this package ships three tracker adapters, and a hook running one tracker's CLI would
hardcode one vocabulary into payload and undo the contract it serves — so the query is a project
plug at `.astraler/project/tracker-status.sh`. And it **only reads**: a session-start hook fires
on every session with nobody watching the outcome, which is the wrong place to mutate a remote
board.

Bound: `scripts/hook-tracker-status.py`, `.agents/tracker-contract.md`,
`prompts/ADAPT-HARNESS.md` (§3 plugs).

### AST-147 — A `Bound:` line with a star in it was invisible to the check whose whole job is `Bound:` lines · promoted 2026-09-20

2.10.0 shipped check 10 — every live `Bound:`/`Wired`/`Enforced by` citation must still resolve
— because the ledger's provenance had gone unchecked for four releases. Renaming five files out
of the payload in 2.12.0 made two citations false the moment the rename landed, and check 10
stayed green over both.

Its pattern required a backtick on each side of the path and did not have `*` in the character
class. `` `harness/.codex/profiles/*.config.toml` `` therefore matched **nothing at all**: not a
resolved binding, not a finding, and not even a counted assertion. The count it prints — the
only number a reader has to judge its coverage by — excluded exactly the citations it could not
read. Adding `*` took the count from 137 to 140.

**Found by planting the same claim twice**, once with a literal filename and once with a star.
The literal one failed immediately; the starred one was silent. Reading the regex would not have
told anyone which of those two it was, because the regex looks correct either way — what it
excludes is a shape nobody thought to write down as a case.

**The rule, which is not about globs.** A check that reads a document by PATTERN is only as wide
as the shapes it was tested against, and its own count is not evidence of coverage — a shape it
cannot parse is subtracted from the denominator before anyone sees it. Test a matcher with the
shapes the document actually contains, including the ones written in a different notation.

A globbed citation is also a different CLAIM: it says the set is non-empty. Check 10 resolves it
with a glob and fails when the set is empty, which is what a renamed-away file leaves behind.

Bound: `scripts/check-reachability.py` (check 10), `scripts/selftest.sh`,
`.agents/memory/recurring-failure-modes.md` (AST-141).

### AST-152 — Each watchdog alert was scoped by the wrong subject, so one busy pane hid the rest · promoted 2026-09-25

`STUCK` asked *is anything in this workspace working?* when the question was about one pane.
Measured downstream: a Builder whose waiter had died sat idle on a free box for three minutes
while a sibling was mid-turn, and nothing fired. With several Builders in flight, one of them
working is the ordinary state, so the alert was silent in the case it exists for.

The same scoping left a fourth state with no alert at all. A pane dispatched and never observed
working is silent (not `BLOCKED`), idle (not `WATCHER_LOST`) and, beside any working sibling,
not `STUCK` either. A Shaper whose brief never submitted was heartbeated past for the whole
evening and surfaced only because it wrote to the router itself; a Builder later sat idle forty
minutes, caught by the new alert three times.

Both are fixed by asking about one pane across two polls, from memory the watchdog keeps in
its state dir: `NEVER_STARTED` for a pane never seen working, `STUCK` for one that worked and
then sat idle twice. Pane state cannot see a test run left in the background after a turn
ends — the same shift measured seven `STUCK` false positives from exactly that, each verified
by hand against the process table — so the project answers that through `.astraler/project/work-in-flight.sh`, and an unreadable
answer counts as in flight. Recorded because the shape is general: **an alert gated on a
system-wide condition is silent whenever any other part of the system is healthy.**

Bound: `scripts/herdr-watchdog.sh`, `scripts/selftest.sh`,
`.agents/skills/dispatch-ticket/WATCHING.md`.

### AST-154 — The obvious retry for an unsent brief fused it with the next one and reported success · promoted 2026-09-25

AST-032 and AST-037 are a brief left in the composer while the pane reads `idle`. The recovery
that suggests itself is to send again. Measured downstream on a throwaway pane: `herdr agent
prompt` does not clear the composer — it appends to the stale last line with no separator and
submits both as one turn, and returned `agent_prompted`. The agent answered the fused text.
Every machine-readable signal before the retry (`idle`, `ctx 0%`, `↑0 ↓0 tok`) was identical
to an empty pane.

The original failure did nothing and was eventually looked at; this one RUNS, carrying a field
from a dead brief into a live one, and both sides report success. Read the composer before a
re-delivery; `esc esc` clears it, where `ctrl-c` and `ctrl-u` were measured to leave the text.

Bound: `.agents/skills/dispatch-ticket/SKILL.md`.

### AST-155 — The teardown removed what it started and kept what it built · promoted 2026-09-27

A project's `cleanup-worktree.sh` ran `docker compose -p <project> down -v` for every worktree
it retired. That removes the stack's containers and its volumes, and not the image the stack
built. Measured on the owner's machine: 99 per-worktree images at ~485 MB each, alongside
21.6 GB of build cache nothing pruned and 30 anonymous Postgres volumes from outside Compose —
72 GB in total, and the file churn around it pushed `fseventsd` to 9–12 GB and got the merge
gate killed for memory twice. A second project on the same machine had no Docker teardown at
all. Reproduced here on Docker Desktop: after `down -v` the built image remains, carrying
`com.docker.compose.project=<project>`; `--rmi local` removes it; `down -v` does remove a
service's anonymous volumes, so the orphaned ones came from a `docker run` or a test tool.

Every step reported success, because each one did exactly what it said. **A teardown checked
against its own command list cannot miss what the command list forgot.** The harness still
does not tear down a stack — that needs the project's compose file and environment, and
hardwiring one project's was the defect 2.7.15 removed — but it can identify one from Docker's
labels alone: containers record the directory they ran from, so the stacks rooted in a worktree
are named before the plug runs, and whatever still carries their project label afterwards is a
leak by construction. Build cache and unowned volumes are machine-wide and stay the owner's.

Bound: `scripts/release-worktree-resources.sh`, `scripts/selftest.sh`,
`.agents/skills/dispatch-ticket/CLEANUP.md`.

### AST-157 — The tracker write-back was refused at the one command a merge does not always pass through · promoted 2026-10-05

The owner's account of the tracker, across projects: a dispatched ticket keeps its ready
status and label, and a finished one is closed sometimes and sometimes not. The close side had
a gate since 2.8. `hook-git-guard.py` refuses a push of the base while a merge in the range
names a ticket with no `ticket-done` stamp. That push is the gate's only moment, and two merge
shapes never reach it. `gh pr merge` lands on the remote, so no local base is pushed. A merge
held for a gate is pushed hours later, if at all. The claim side had no gate, only the claim
protocol in prose.

Both moved to the moment every dispatch does pass through: the brief. On a Claude root the
dispatch mod asks the project's `tracker-state.sh` before sending one. A ticket reported
unclaimed is not sent, and while any Builder ticket has reached the base with no stamp, no brief
is sent at all. The note also rides the merge command's own result, so it lands in the turn
that merged. Measured 2026-10-05 against a stub tracker: the unclaimed brief was refused and
the Builder received nothing. After the merge, the next brief was refused, and the dispatcher
closed the ticket and ran `ticket-done` in the turn that read the note.

**A gate belongs on the step that cannot be skipped, not on the step that usually follows.**
The push usually follows a merge; the next brief always follows the last.

Bound: `.claude/skills/astragentic-dispatch/hooks/register.tsx`,
`.agents/skills/dispatch-ticket-claude/SKILL.md`.

