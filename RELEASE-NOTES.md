# Astraler Harness 2.2.2

Fix: 2.2.1's own race fix still narrowed the window rather than closing it, plus a PGID
parsing bug in the same diff — both found by a second arm pass fired against 2.2.1 itself.

- The single-instance lock still had a one-line gap between `mkdir` succeeding and the PID
  being written, and a PID-less lock was still reclaimed on first sight. Now retried for up
  to a second before a PID-less lock is treated as a genuine crash — long enough that a real
  instance (which writes its PID in microseconds) is never mistaken for a dead one.
  Re-measured: 20 concurrent `start` calls, exactly one survivor.
- `stop`'s combined `ps -o pgid=,args=` parsing used `${line%% *}`, which returns empty when
  BSD/macOS right-pads the pgid column with leading spaces — silently downgrading a group
  kill to a single-PID kill. Replaced with `read -r`, which discards leading and internal
  whitespace itself.

## Upgrade from 2.2.1

Copy `herdr-watchdog.sh`.

# Astraler Harness 2.2.1

Fix: a real double-watchdog race, plus five documentation/UX defects, found by an adapted
project's own Thomas dispatched to run the cross-vendor arm against 2.2.0 before adopting it.

- **A real race, not a review nitpick (AST-076).** AST-072's single-instance lock (`mkdir`
  as the atomic primitive) had a window between the lock existing and the owning PID being
  recorded — two re-exec hops wide, since `caffeinate` forked a new, different-PID child to
  run the script. A `start` landing in that window read the lock as stale and reclaimed it,
  running a second watchdog alongside the first. Measured before the fix: ten concurrent
  `start` calls could leave more than one alive. Fixed by moving the isolation hop before the
  lock is acquired and launching `caffeinate` as a background helper (`-w $$`) instead of
  exec'ing into it — no hop left where the final PID is still unknown. Re-measured: ten
  concurrent `start` calls, exactly one survivor, nine correctly refused.
- `thomas.md`'s Watchdog section named the wrong PID path (missed the `.lock/` AST-072
  introduced) and never mentioned the heartbeat file at all — the one role that owns this
  script had no documented way to check it.
- `ticket-git-facts.sh` defaulted `BASE_BRANCH` to `main` unconditionally; a repo on `master`
  would fail its first real run. Now auto-detects `origin/HEAD`, falling back to `main` only
  when that is unset. Ticket-id validation also now runs before the base-branch check, so a
  caller with both wrong sees the more specific error first.
- `.claude/skills/review-with-rin/SKILL.md` had drifted from its `.agents/` twin: it still
  described argv as coming from a "launcher matrix in `dispatch-ticket`" — the matrix moved
  to the runtime-specific companion skills a release ago. Pre-existing, unrelated to this
  cycle's changes, caught in the same pass. Also fixed: the tab-create line labeled Rin's tab
  `rin:<ticket-id>`, inconsistent with the pane rename two lines below and wrong for a spec
  gate, which has no ticket id — both now read `rin:<artifact-key>`, the identifier the skill
  already resolves first and uses everywhere else.
- `herdr-watchdog.sh`'s `stop` path made two separate `ps` calls where the second existed
  only to read a field the first call could have returned too — combined into one.

## Upgrade from 2.2.0

Copy `herdr-watchdog.sh`, `ticket-git-facts.sh`, `thomas.md`'s Watchdog section, and both
`review-with-rin/SKILL.md` copies.

# Astraler Harness 2.2.0

Feature: reconcile the tracker against git, and a watchdog you can check.

Folded in from a handoff written by an adapted project's own Thomas session, which built,
committed and **exercised** both changes in live use before reporting them upstream —
generalized here for a tracker-agnostic package, on this package's own evidence where the
handoff's numbers were project-specific.

## Tracker ↔ git reconciliation

**A wrong ticket state is perfectly consistent with itself.** In-progress with an assignee is
exactly what a real in-flight ticket looks like, so a check that reads only the tracker can
detect nothing — the same law that already requires an independent key set for a parity or
coverage denominator. Git is that independent oracle for ticket state.

- **`reconcile-tracker`** (new skill, both `.agents/skills/` and `.claude/skills/` copies) —
  owns the join between git facts and tracker state, the three drift classes (lagging,
  phantom-done, stale claim), and why the check stays read-only.
- **`scripts/ticket-git-facts.sh`** (new) — git's half. No network, no tracker call, decides
  nothing. Matches a ticket id in the commit SUBJECT only, never the body; `TICKET_PREFIX` has
  no default and is a required STOP, since a bare id pattern also matches ADR ids and other
  kebab-tagged history.
- **`thomas.md`** — wired at merge and at session start, alongside the frontier write-back it
  verifies. Also gains a direct caution that frontier promotion computed from blocking edges
  alone is over-inclusive (epics, an unstarted phase's children, deferred tickets all pass it);
  promotion stays a judgement, not a mechanical pass.

**Read-only is a ruling, not timidity.** The join key — a ticket id in a commit subject — is
not exact: a partial fix, a revert, or a forward-citation all produce a hit. Auto-closing on
that signal would eventually mark unfinished work done, and a tracker that is wrong and *tidy*
is worse than one that is wrong and messy — it is believed by the one reader who cannot re-run
the query. `reconcile-tracker` reports; Thomas applies each fix by hand. Recorded as
**AST-074**, alongside the frontier-promotion finding.

## Watchdog heartbeat

**AST-072's watchdog was itself the thing that failed silently on a live project's machine:**
an instance survived with its `caffeinate` wrapper gone and its own PID file deleted, alerted
nothing across a real STUCK window for two hours, and every liveness signal tried against it —
the process table, the PID file, CPU time — read healthy the whole time, because each one can
be true of a process that is running but not doing its job.

- `herdr-watchdog.sh` now writes a timestamp to its own `.alive` file every few polls, in
  place rather than appended, so it never buries the alert log beside it — a timestamp that
  only advances when the loop *completes* is the one signal the other three cannot fake.
  Removed on a clean stop, so its absence and its staleness stay distinguishable.
- Same handoff, independent confirmation of AST-072's core finding: `pkill -f` left a wedged
  watchdog alive, because macOS re-execs the script under `caffeinate` and the visible PID is
  not the one that needs signaling — exactly the class AST-072 already fixed by isolating into
  a dedicated process group before any PID is written down.

Recorded as **AST-075**.

## Upgrade from 2.1.1

Copy `scripts/ticket-git-facts.sh`, both `reconcile-tracker/SKILL.md` copies, and
`harness/scripts/herdr-watchdog.sh`. Merge the two new paragraphs into your project's
`thomas.md` (the frontier caution and the merge/session-start wiring) — this is scaffold-
adjacent content inside a payload file, so diff rather than overwrite if you have local
changes there. `docs-staleness-audit.sh`'s Thomas budget moved 1700 → 1850 to carry this; the
reasoning is recorded in the script itself.

# Astraler Harness 2.1.1

Fix: the watcher is called by project-local path again, reversing 2.0.1.

2.0.1 moved the mandatory watcher call to `~/.claude/scripts/herdr-watch-terminal.sh`,
reasoned as one shared copy instead of one per project. In practice every release still
stages `scripts/herdr-watch-terminal.sh` into each project regardless, so the global copy —
the one actually invoked — was the one no release ever touched. On this machine it had
already drifted from the shipped script, and an unrelated file at the same path prefix
(`~/.claude/scripts/herdr-watchdog.sh`) turned out to be a three-drafts-old prototype nothing
referenced, stale for over a week without anyone noticing (**AST-073**).

- `dispatch-ticket` and the `thomas-claude` / `thomas-codex` / `thomas-opencode`
  supplements now call `<repo-root>/scripts/herdr-watch-terminal.sh` — absolute, not
  relative, per the cwd lesson in AST-028.
- `check-requirements.sh` check 9 now verifies the project-local (or package-local) path
  instead of the home-directory one.

## Upgrade from 2.1.0

Copy the three `thomas-*.md` supplements and `dispatch-ticket/SKILL.md` (both `.agents/` and
`.claude/` copies). If a global `~/.claude/scripts/herdr-watch-terminal.sh` or
`~/.claude/scripts/herdr-watchdog.sh` exists on your machine from an earlier draft, it is no
longer referenced by anything shipped — safe to leave in place or delete.

# Astraler Harness 2.1.0

Feature: one herdr workspace per project, and a self-monitoring watchdog for Thomas.

`orchestrator.md` gains a `workspace-label` field and a fixed tab/pane-rename convention
(`ticket:`, `spec:`, `qa:`, `rin:`), so Thomas resolves the same herdr workspace every session
instead of matching loosely on project/epic. `dispatch-ticket` now STOPs on a placeholder or
duplicate label instead of guessing, re-verifies uniqueness after create, and records
`workspace_managed_by_root` explicitly rather than assuming cleanup can infer it.

A new `harness/scripts/herdr-watchdog.sh` polls `herdr agent list` for the project's
workspace and wakes Thomas — via the pane or, failing that, a desktop notification — on a
blocked, stuck, watcher-lost or crashed dispatch during autonomous work.

A cross-vendor arm pass fired against the first cut of this feature returned
`needs-attention` before it shipped, with three HIGH findings — all of the same shape,
captured as **AST-072**: a coordination primitive was trusted the moment it started, and
never checked for what it could do to the session running it, only whether it worked.
Fixed before release:

- **Watchdog shutdown could kill an unrelated process group.** `stop` now verifies the
  recorded PID's command line still names the watchdog before signaling it, and `start`
  isolates into its own session (via `os.setsid()`, no `setsid` binary required) so its
  process group is never shared with the shell that launched it. A live test confirmed the
  before-state: an unisolated background watchdog, killed by group, took the launching shell
  down with it.
- **Workspace resolution had no lock and no duplicate check.** Two concurrent Thomas sessions
  could each create a workspace for the same label. Creation now re-lists and confirms
  exactly one match; two or more matches is a STOP, not a silent pick of the first.
- **`workspace_managed_by_root` was read by cleanup but never written by resolution.** The
  create path now records it immediately; the reuse path reads the existing record rather
  than assuming a value.
- The watchdog also gained a single-instance lock per workspace-label (a second `start`
  refuses rather than racing the first), and stopped hard-coding Thomas's crash-detection to
  the `claude` process name — it now reads the active runtime from `orchestrator.md`, so a
  Codex- or opencode-dispatched Thomas is not falsely reported crashed.

## Upgrade from 2.0.2

Copy `orchestrator.md`'s new `## Workspace identity` section into your project's copy (it is
scaffold — an install never overwrites your row values, but a new section needs a manual
merge), fill in `workspace-label`, and copy `dispatch-ticket/SKILL.md` (both `.agents/` and
`.claude/` copies) and the new `harness/scripts/herdr-watchdog.sh`.

# Astraler Harness 2.0.2

Patch: 5 skills missing from `.claude/skills/`.

Claude Code only scans `.claude/skills/` for skill discovery. Five skills existed in
`.agents/skills/` (for Codex/OpenCode) but had no copy in `.claude/skills/`, making them
invisible to Claude Code agents — including Thomas, who needs `dispatch-ticket` and its
runtime companions to dispatch correctly.

Added to `.claude/skills/`:
- `codex-claude-arm`
- `dispatch-ticket`
- `dispatch-ticket-claude`
- `dispatch-ticket-codex`
- `dispatch-ticket-opencode`

## Upgrade from 2.0.1

Copy the five new `.claude/skills/` directories from the release. No other changes.

# Astraler Harness 2.0.1

Patch: dispatch reliability and watcher path.

- **Thomas dispatch routing requires `Skill()` invocation.** All three thomas supplements
  (`thomas-claude.md`, `thomas-codex.md`, `thomas-opencode.md`) now instruct Thomas to
  invoke `Skill(skill: "dispatch-ticket")` + `Skill(skill: "dispatch-ticket-<runtime>")`
  before every dispatch. Previously the contract named the skills in prose, which let Thomas
  skip loading them and dispatch from reasoning alone — producing incorrect mechanisms.
- **Watcher path changed to global.** `dispatch-ticket` now references
  `~/.claude/scripts/herdr-watch-terminal.sh` instead of repo-local
  `scripts/herdr-watch-terminal.sh`. The script is shared across projects.
- **orchestrator.md documents opencode provider/model format.** The Model column explanation
  now notes that opencode requires `provider/model` format and that a bare model name
  produces `ProviderModelNotFoundError`.

## Upgrade from 2.0.0

Copy the three thomas supplements and `dispatch-ticket/SKILL.md` from the release. No
structural changes — the adaptation agent can diff and apply.

# Astraler Harness 2.0.0

Cross-runtime compatibility. The harness now dispatches builders on Claude Code, Codex and
OpenCode, where previously only Claude Code was wired end to end. Three structural changes
make that work, and all three are breaking for projects that adapted 1.6.x contracts.

## Breaking — role contracts split per runtime

Each role contract that carried runtime-specific logic (builder, thomas, rin) is now a base
file plus per-runtime supplements:

```
builder.md              shared phases, build, increment review, handing back
builder-claude.md       simplify via Skill(skill: "simplify"), /compact, /clear
builder-codex.md        simplify SKIPPED protocol
builder-opencode.md     simplify SKIPPED protocol
```

Same pattern for `thomas-{claude,codex,opencode}.md` and `rin-{claude,codex,opencode}.md`.
`shaper.md` and `qa.md` are runtime-neutral and have no supplements.

**Adapters load base + supplement.** A Claude builder reads `builder.md` then
`builder-claude.md`. A Codex builder reads `builder.md` then `builder-codex.md`.

**Thomas and Rin read ALL supplements**, because they dispatch and verify builders on every
runtime. When verifying a simplify artifact, they apply the rules matching the **builder's**
runtime from `orchestrator.md`, not their own.

## Breaking — dispatch-ticket split per runtime

`dispatch-ticket` is now a shared protocol (binding, worktree, brief format, review). Three
companion skills carry the launcher mechanics:

| Skill | Launches |
|---|---|
| `dispatch-ticket-claude` | `claude --dangerously-skip-permissions --agent builder` |
| `dispatch-ticket-codex` | `codex --profile builder --dangerously-bypass-approvals-and-sandbox` |
| `dispatch-ticket-opencode` | `opencode --agent builder --auto` |

Each carries its runtime's measured facts (idle detection, transcript access, effort
parameter location) and its launcher template. `dispatch-ticket-claude` separates write
roles (`--dangerously-skip-permissions`) from review roles (without it).

## Added — skills for Codex/OpenCode discovery

Seven skills that lived only in `.claude/skills/` — invisible to Codex and OpenCode — now
have adapted copies in `.agents/skills/`:

`batch-triage` · `bootstrap-glossary` · `codex-arm` · `dispatch-qa-walk` ·
`legacy-testing` · `review-with-rin` · `untangle`

Claude originals are untouched. Claude Code scans `.claude/skills/` only; Codex and OpenCode
scan `.agents/skills/` only. The copies are adapted where needed (e.g., `review-with-rin`
references `.agents/roles/rin.md` instead of `.claude/agents/rin.md`).

## Added — OpenCode adapters

`.opencode/agents/` now ships adapters for builder, thomas, rin, shaper and qa, so
`opencode --agent <role>` resolves.

## Added — simplify skip protocol

When a builder runs on a runtime that has no `simplify` built-in (Codex, OpenCode), it
commits an empty marker:

```
simplify(increment): SKIPPED — runtime <runtime> has no simplify built-in

Pass: SKIPPED (runtime does not provide Skill(skill: "simplify"))
```

Thomas and Rin accept this marker when the builder's runtime in `orchestrator.md` is not
Claude. A Claude builder must still produce `Pass: Skill(skill: "simplify")`.

## Changed — check-reachability.sh

Added `.opencode/agents/` to check 4 scan paths. Runtime supplement files are now included
in reachability validation.

## Upgrading from 1.6.x

**This is a breaking upgrade.** Projects that adapted role contracts must re-adapt: the base
contracts have changed shape (runtime-specific sections moved to supplements), and adapters
now reference supplement files. Re-stage and re-run adaptation.

Projects using `dispatch-ticket` directly must update references to include the
runtime-specific companion skill for their runtime.

Scaffold files (`.agents/orchestrator.md`, `.codex/profiles/*`) are untouched as always.

# Astraler Harness 1.6.3

Three of the staleness audit's five axes removed, on the same test that removed five skills
in 1.6.1: what has it caught, measured rather than imagined.

## Removed

**AGE** — flagged any tracked doc not committed in 21 days. It has caught nothing here, and
"old" is a candidate rather than a defect. Its own header said so: *"an old file is a
candidate, not a verdict."* A check whose output always needs a human to re-judge it is a
prompt, not a gate.

**FOSSILS** — grep for retired names in live docs. The cost is a hand-maintained marker list
that must be appended on every rename, plus an exemption per false positive, and an exemption
outlives the reason for it: one project de-scoped a marker because a doc of that name was
live, deleted that doc a day later, and the exemption survived. In three weeks its one real
catch was a marker of its own that had never matched anything in either repo's history.

**DEAD LINKS** — scanned `docs/INDEX.md`, `docs/SYSTEM.md`, `AGENTS.md`. This package has
**zero** of the three and one measured project has one. It printed `(skip)` three times and
then `(clean)`, and the RESULT line rolled that up to `all clean`. **A green line over
nothing it looked at** — the class this file exists to catch (AST-051), sitting inside the
file, through four repairs on the same day.

## Kept, because both fire

**Word budgets.** The one axis that fired constantly: it caught `orchestrator.md` at 1,477
words against 800 in a project, forced three deliberate budget decisions in a day rather than
silent growth, and stopped `thomas.md` four times. The prior package reached 100k words by
accretion nobody measured; this is what stops that returning.

**Self-reported counts.** Caught the ledger's own header claiming 50 entries over a file
holding 66, and before that a README claiming 35 failure modes over a ledger of 51.

## The trade, stated

`mattpocock-skills` has no equivalent. Its 34 skills measure the METHOD — triage, spec,
tickets, implement, review — not document drift. Nothing replaces the three axes; they were
carrying less than they cost. Said here rather than discovered in six months.

Script: 266 lines to 196.

## Upgrading

Payload only. A project that relied on the fossil list keeps its own copy until it takes this
release; a project that wants that check back has it in git history.

# Astraler Harness 1.6.2

One check, for the question none of the other seven asked.

## Added — check 8: WRITES → REGISTERED

Seven reachability checks and a five-axis staleness audit were all green while three skills
shipped for weeks writing documents nobody was told to read. The blind spot was structural:
**check 3 asks whether a skill is named, check 4 whether a path exists, check 6 whether an
address is callable, check 7 producer-and-verifier for the gate artifacts a human listed.**
A file with a writer and no reader satisfies every one of them.

Check 8 asks the missing one. A skill declaring `## N. Write <path>` must have a row in the
artifact registry, where a human states who reads it. Adding a writing skill without
registering a reader now fails.

**It deliberately does not infer readers.** `batch-triage` asked for *"the code map"* in prose
for weeks, and a filename grep called that artifact an orphan while a shipped skill wanted it
every run — a grep for a name is not a search for a consumer (AST-071). So the registry stays
hand-written and check 8 only enforces that nothing escapes it. The scope line says so.

The registry also learned to hold verifiers **outside this payload**: `CONTEXT.md` is read by
the plugin rather than by us, so its row names `plugin:domain-modeling` and is checked against
the installed copy. Where the plugin is absent the verdict **names what it could not read**
instead of passing quietly.

## Upgrading

Payload only. Projects on 1.6.1 take this to receive the check; nothing else changes.

# Astraler Harness 1.6.1

Five skills removed. Every one of them wrote a document, and nothing in this package or in the
plugin was ever told to read what they wrote.

## Removed

`extract-standards` · `module-boundaries` · `code-scout` (with `scripts/gen-code-map.sh` and
its agent adapter) · `tracker-frontier-audit` · `codex-dispatch-headless`.

Measured per artifact, on both sides — this package's five contracts and the plugin's 34
skills:

| skill | writes | contract reads | plugin reads |
|---|---|---|---|
| `extract-standards` | `docs/agents/standards.md` | 0 | 0 |
| `module-boundaries` | `docs/agents/module-boundaries.md` | 0 | 0 |
| `code-scout` | `CODE-MAP.md` — never named by filename anywhere | 0 | 0 |
| `bootstrap-glossary` | `CONTEXT.md` | 0 | **13** — kept |

`extract-standards` took reading rather than grepping. Its consumer was meant to be the
plugin's Standards axis, and that step is one sentence: *"anything in the repo that documents
how code should be written, such as CODING_STANDARDS.md or CONTRIBUTING.md."* No path, no
directory — against the neighbouring step for spec sources, which is a numbered four-way
lookup naming `docs/agents/issue-tracker.md` outright. **This package wrote a file to an
address its reader has no instruction to visit, under a name that reader never mentions.**

`tracker-frontier-audit` went six merges without one call, its trigger being *"when the board
looks wrong to the owner"* — a feeling, not a step. `codex-dispatch-headless` offered a Builder
with no observable pane and went three weeks across two active projects without a single
request; headless is now unsupported outright, because a topology the owner cannot watch
contradicts what every gate here argues (AST-070).

One correction the arm forced, and it is the same mistake in miniature: the filename
`CODE-MAP.md` appeared nowhere, but `batch-triage` asked for *"the code map"* in words. A grep
for the literal name said orphan; the artifact had a consumer that named it semantically.
`batch-triage` now reads the current tree with `rg` and `git log` instead — which is what it
should have said, since a map is stale exactly where triage needs it, on code that moved.

**Every orphan was ours.** Nothing the plugin ships was orphaned, because its skills read the
files its skills write. We diagnosed a real gap and answered it by writing documents beside
its own, in our convention, without reading where the consumer was told to look.

## Changed

**The plugin's `code-review` is named in full.** Three things answered to the bare name: the
plugin skill, a Claude Code built-in, and `mode=code-review`, a dispatch argument. `builder.md`
already stated the rule and two references out of nineteen followed it. Fourteen now carry
`mattpocock-skills:`; the three that stay bare are the sentence naming the ambiguity and the
two literal mode values.

**The ledger is anchored to merge.** A merge carries a `Ledger:` line naming what went in, with
`none` valid and silence not. Before this the package had no rule anywhere telling anyone to
write to a ledger, and never established that a project keeps its own — which `ADAPT-HARNESS`
now does, including that the harness ledger is payload and a project entry written there is
deleted by the next upgrade in silence (AST-069).

**Brownfield entry is two bootstrap skills, not three**, and coding standards are stated to
belong in a skill the project invokes rather than in a document. The pointer is the mechanism,
not the filename.

## Fixed

**AXIS 5 read every count except the ledger's own.** The header said "50 entries (AST-001 …
AST-050)" while the file held 66 — sixteen entries adrift in the one file every rule cites as
evidence. It now checks the count and the range, **and fails when the header cannot be parsed
at all**: the first version guarded both comparisons on non-empty values, so deleting the
Status line made the axis print clean having read nothing. That is the vacuous pass this axis
exists to catch, rebuilt inside the check written to catch it, and caught by the arm within
the hour.

## Upgrading

Payload only; scaffold is untouched as always. Projects on 1.6.0 must take 1.6.1 to receive
this batch — `install.sh` refuses changed content at an unchanged VERSION, by design, because
a staged release directory is the manifest of what shipped.

Five skills and their artifacts disappear from your tree. **If your project wrote real
standards into `docs/agents/standards.md`, that content is worth keeping** — move it into the
implement skill your project actually invokes, keep its evidence counts, and point at it from
a surface loaded at session start. One measured project had 25 verified rules there; the
document was good and only its address was wrong.

# Astraler Harness 1.6.0

A ruling made in a project on 2026-08-12, marked twice in its own commits as *"this must flow
upstream to harness-matt-pocock rather than living only here"*, and which had not. This release
carries it up, and the arm it describes then found six defects in the carrying.

## Changed — the cross-vendor arm fires per ticket, not once at a phase end

**Three scopes, named by the artifact each one reads**: `arm: spec` before tickets are cut,
`arm: ticket` at every handback before that merge, `arm: slice` once when the slice closes. **No
ticket merges without one.**

The measurement that forced it: batched to slice scope, one review ran to **6,904 added lines
across 31 files** against **1,238 for a single ticket**. Nobody skips a review that size — they
skim it, and skimming is how a hollow test survives. Three survived a single day on that
project, every one of them plainly visible at ticket scope, all three caught by hand at the
merge rather than by any gate (AST-061).

**The second pass is now MANDATORY after a blocking first**, a step rather than a judgement
call. On one ticket the dispatcher talked himself out of it in a paragraph where every reason
was true, and was still wrong: what pass 2 catches is the defect the FIX introduced, which by
definition nobody has looked at. The neighbouring ticket proves the cost — pass 1 found
authorization outside a write transaction, and pass 2 found a real 40P01 deadlock cycle living
inside the code written to repair it (AST-062).

**The Shaper now STOPS at Spec and hands back twice.** Its session used to close *"when
`to-tickets` has produced the tickets"*, everything running unbroken, which left no moment where
the spec existed and the tickets did not — so the plan gate had nowhere to fire and silently did
not, for two consecutive slices, the second a 44k spec with ten tickets. Nobody forgot it. The
sequence gave it no window (AST-063).

**"Milestone gate" and "spec gate" are the reviewer's names and are reserved.** A cross-vendor
pass wearing either one tells a reader of that reviewer's contract that the reviewer fires
Codex, and lets a dispatcher who ran only one of the two report that the spec was gated
(AST-065).

`thomas.md`'s budget rises 1400 → 1600 for the cadence. Only the rule landed in the contract;
the measurements went to `codex-arm`, which loads when the arm runs rather than every session.

## Added — a budget on the one always-on file no release can repair

`orchestrator.md` is read at every session start, and nothing measured it. It is also scaffold:
written once, never overwritten, so a release cannot take back what collects there. Measured
across three trees in one day — **package 653 words, one project 941, another 1,477** — the last
carrying 505 words of argument about which model a row should hold, including a decision, its
reversal the same day, and an instruction not to undo the reversal.

The guard went into `docs-staleness-audit.sh`, which is payload. **A check for scaffold drift has
to live in payload, because payload is the only thing an upgrade can carry into a project that
already has the drift.** Budget 800. Verified in both layouts before shipping (AST-064).

## Fixed — the staleness audit was reading one file

`scoped_md()` globbed from the repo root while the payload sits under `harness/`, so in package
layout AXES 1 through 3 matched **one** tracked file and reported clean over everything they
never opened. This is the defect 1.5.0 fixed for AXIS 4 and left in its siblings. Scope is now
27 files. Run widened, it found four hits immediately.

Three of those four were in `SPEC-1.0.0.md` and were not defects: a shipped version's build spec
names files in the repo it copied FROM, so its retired names are accurate history. `SPEC-*.md`
stays out of scope, recorded as a decision rather than an oversight.

The fourth was the marker `agents/rin\.md`, whose only match in either repo's entire history is
the live `.claude/agents/rin.md` adapter — and `agents/dan\.md`, which has never matched
anything, anywhere. Both are removed rather than narrowed: narrowing keeps a rule that still
cannot point at anything. Verified by planting a real fossil and watching the axis report it.

## What the arm found in this release

Two passes over the diff, and **six findings, every one of them introduced by this release**.

Pass 1: the Claude-root skill still called pass 2 *legal* while its Codex-root mirror called it
mandatory, so the rule depended on which vendor was root. The Shaper's new section called the
spec arm "the plan gate", a name the reviewer already owned. And `review-with-rin` told its
executor to verify the fold *"and merge"*, then said the arm precedes that merge — the exact
ordering defect this release had repaired in `thomas.md` hours earlier, reintroduced in the file
Thomas actually executes.

Pass 2, over the full artifact: **two of the three pass-1 repairs had broken something.** The
merge-after-arm repair gave a gate that handles three different artifacts one ending — but a
spec gate has nothing to merge, and its real exit is releasing the Shaper sitting paused waiting
for it. And the spec-stop repair had left a blocking spec finding with no repair window, so
tickets could still be cut from a spec that never took its mandatory second pass.

That is the whole argument for AST-062 arriving as evidence in the same release that wrote it.

Then `arm: slice` ran for the first time, over the release as one artifact, and found four more
that both ticket-scope passes had missed — because they read the diff as a ticket, and these
were defects in how the scopes fit together. The release **declared** three scopes and had
written every execution path for a ticket: findings routed to "the Builder" where at spec scope
no Builder exists yet, an ending that merged where at slice scope the commits are already
merged, and an unavailable-vendor exception that authorized "merging" in one file and "closing
the phase" in another.

Its pass 2 found the one that matters most. **The Claude-root invocation was never bound to the
reviewed head** — `--base <ref>` names one end of the range and the current directory silently
names the other. That was harmless at phase end, when the commits were already on the base
branch. Moved to per-ticket, run from Thomas's resident checkout while the ticket head sits
unmerged in the Builder's worktree, it compares the base branch to itself and returns clean
having read nothing — at the exact moment a ticket merges on that verdict. The Codex-root
mirror had carried the answer all along. **A cadence change can invalidate an assumption the
mechanics never wrote down** (AST-066).

## Upgrading

Payload only. Your `.agents/orchestrator.md` and `.codex/profiles/*` are untouched, as always —
and the new budget will now tell you if the first of those has been collecting prose. A report
over 800 words is a finding for the owner, not for a release to repair.

# Astraler Harness 1.5.4

Three checks that could not fail, found in one pass by a project's Thomas asking one question
of the 1.5.3 upgrade it had just received: does the instruction match the tree?

## Fixed

**The verification after the release commit reported clean when the commit was impossible.**
`ADAPT-HARNESS.md` §4 said to `git add` the applied release, then read
`git status --short ".astraler/releases/"` as *anything still listed was never applied*. In a
project whose `.gitignore` excludes `.astraler/`, the add is refused and that status prints
**nothing** — which the prompt's own reading turns into *everything applied and committed*,
with not one file staged.

The `git add` was never the defect: it errors and returns 1, loudly. The line after it is what
converted a loud failure into a clean report, because its output is identical when the step
worked and when it could not run. The check is now a count of what is actually staged, which
absence cannot satisfy (AST-058).

`git add -f` was considered and rejected. The ignore rule is the project's — this package ships
no `.astraler` stanza — so forcing past it would override a decision made elsewhere and never
surfaced. A zero is a finding for the receipt: *applied release is on disk only*.

**The repo kept one self-check and lost the other.** `install.sh` staged
`check-requirements.sh` into `.astraler/releases/<version>/` only, while `check-reachability.sh`
travelled inside the payload and landed tracked in the project's `scripts/`. A project that
deletes or ignores its releases directory — a legitimate resting state under AST-054 — silently
lost its own doctor and kept the other one. The installer now copies the one source file to both
destinations, and the vendored copy resolves its version from `.astraler/state/applied-version`
instead of printing `?` in every project (AST-059).

**Check 3 printed green about the skills it had not opened.** In project layout, reachability
examines harness-owned skills only — correctly, since checking the project's produced a wave of
false findings in AST-038 — and then said `every shipped skill is reached`, with the skipped
count on a line above the verdict where the pass buries it. The timing is what makes it bite: a
project skill is skipped on the run right after it is written, which is when its author is
looking for reassurance. Check 3 now names its scope inline, and the skipped set moved into the
verdict beside check 4's exclusion (AST-060).

## The shape, since this is the third release running

All three are one thing: **a green line that speaks for more than the check looked at.** 1.5.2
fixed check 4's referenced-path claim, 1.5.0 fixed a staleness audit reporting `all clean` over a
loop that ran zero times, and these are the next three. Worth stating because the cure is always
the same and always cheap — make the claim name its own scope — while the disease is only ever
found by running the thing somewhere its preconditions are messy.

None of these came from reading this package. All three came from one project agent comparing an
instruction against the tree it had produced.

# Astraler Harness 1.5.3

One finding from a live project, and it is about the one participant the harness had never
modelled: the owner, who cannot re-run a query.

## Fixed

**A frontier that is only computed is invisible to the person who cannot compute it.**
`thomas.md` defined the frontier as a query and never said to write the answer back. An agent
re-runs that query on demand, so it is never wrong for long and never notices anything missing.
The owner opens the board and looks. Measured on a live project: zero issues had ever entered
the unstarted state across the project's whole life, and one ticket sat looking blocked for
hours after both its blockers merged. The owner found it by comparing two boards by eye — no
check this harness runs had ever looked.

The contract now carries it as a **merge step that must be reported**: merge is not complete
until Thomas re-runs the query, moves every ticket that merge unblocked, and names which ones
moved — `none` is a valid report, silence is not. Plus one clause that costs nothing: never read
a readiness label as a blocker (AST-057).

The first draft of this release was weaker, and the owner caught it. It said "move it in the same
breath as closing the ticket" and stopped — a rule with nothing to fail when a busy dispatcher
skips it. Reporting is what makes a skipped step visible, which is the same reasoning that made
the write-set a required field in 1.5.2 rather than advice.

**Naming the upstream cause correctly is what decided where the fix went.**
`mattpocock-skills:to-tickets` draws the blocking edges and writes `Status: ready-for-agent` in
the same breath — a label, applied once at creation, never revisited when a blocker is later
added or cleared. It sets no workflow state at all, so two representations of readiness sit side
by side and neither answers what a dispatcher asks. Verified in the installed plugin, not only
in an old vendored copy: the line is live in 1.2.3.

**That skill is the plugin's, so this package does not patch it.** 1.0.0 exists to stop
vendoring Matt's skills, and a patched copy here would be the second-home failure ADR 0001 was
written about. The contract compensates instead.

## Added

**`tracker-frontier-audit`** — reports the three ways a tracker answers READY with confidence
about things it cannot represent: a frontier computed but never materialised, preconditions
that are no issue at all, and parent blocking a tracker does not inherit. One law, three
instances; each fails because no entity contradicts it, so an absent edge beats a wrong edge.
It reports and proposes exact writes, and never mass-edits — a bulk state change on someone's
board is hard to walk back.

Ported from the project that found it, keeping its name: `frontier` is already this package's
word, and one thing deserves one name across both repos.

**Bound to a moment rather than to someone noticing.** It runs at phase end beside the
cross-vendor arm, because the trigger it shipped with — "when a board looks wrong" — depends on
the very noticing that took a whole project lifetime here. And check 7 now registers
`frontier write-back` as an artifact whose producer is Thomas's contract and whose verifier is
this skill, so neither half can go quiet without a red check.

Worth stating plainly, because it is a fact about this package and not about trackers: **naming a
skill in a contract clears reachability check 3 and makes nothing run.** Check 3 asks whether a
skill can be reached, never whether anything reaches it. The checker's own docstring records the
proof — *a browser walker shipped across releases that never ran once.*

## Scope note

The contract names no workflow state. `to-tickets` targets GitHub as well as Linear, and GitHub
Issues has no such state — naming one would hardcode a tracker into the single file written not
to know which tracker it is on. The mapping belongs in each project's
`docs/agents/issue-tracker.md`.

One choice was never available: reachability check 3 requires every shipped skill to be named by
a contract, so shipping the audit forced the contract edit. The package settled the
skill-versus-contract question before anyone could argue it.

# Astraler Harness 1.5.2

Two defects a live project measured while running 1.5.1, and one honesty fix on a check that
was overclaiming its own scope. Same pattern as the last three releases: found by use, not by
review.

## Fixed

**A marker any tool can write is a check that cannot fail.** 1.5.0 fixed the simplify pass's
address and the fix held — a Builder invoked `Skill(skill: "simplify")` and said so. The next
one called `Skill(mattpocock-skills:simplify)`, which does not exist, because it had just
invoked `mattpocock-skills:implement` from the row above and generalised the namespace one row
down. It then fell back to the `code-simplifier` agent and committed
`simplify(increment):` anyway. Thomas's merge grep, Rin's gate and reachability check 7 all
read as satisfied. The substitution was visible only because a human was watching the pane.

The commit body now carries a `Pass:` line naming what actually ran, registered in check 7 as
its own artifact with its own producer and verifiers — the marker and its provenance are two
things, not one thing with a detail. The Builder contract states the negative in the table cell
(**not** `mattpocock-skills:`) and says plainly that a failed invocation is a finding to report,
not a step to route around (AST-055).

Worth recording what did NOT work: 1.5.1's table already annotated that row `(built-in, via the
Skill tool)`. The signal was there and was read past. More qualifying prose in the place that
was skimmed is not a fix, which is why this release changes what the gate READS rather than
what the contract says.

**The frontier could hand two Builders the same file.** The query asks which tickets have no
open blocker and no assignee; it never asked what each ticket will write. Two correctly
dispatched tickets edited the same three rows of one document — the second because the repo's
docs-sync rule required it, so it was obeying a correct rule. Two conflict blocks, and a naive
merge in the wrong direction would have reverted reviewed work with no signal.

Measured twice in one day, the second time by the operator who had just diagnosed the first. So
the write-set is now a **required field** of a concurrent dispatch rather than a rule in prose,
the way browser consent is required of a QA dispatch, and the dispatch record grew the column it
was missing: what this ticket writes. The brief carries an `Owned elsewhere:` line, which
converts a merge conflict into a handback note for one sentence (AST-056).

**Reachability check 4 spoke for more than it scanned.** It printed *"every referenced path and
skill exists"* and then, three lines later, a separate note that the failure-mode ledger's
`Bound:` provenance is not scanned. A live project measured five citations there to a deleted
file while check 4 reported clean. The claim now names its own scope, and the exclusion reads as
part of the verdict rather than a footnote to it.

## Not taken

**A per-dispatch `model=` override**, to A/B two models on one ticket. The same project that
asked for it measured 40-50% of Builder wall-clock going to rework rounds — a rebase from a
write-set collision, a re-run aimed at the wrong binary, two marker fixes — which dwarfs any
plausible model delta and is fixed by orchestration rather than procurement. AST-041 keeps
`orchestrator.md` the owner's; nothing here needs to change that.

# Astraler Harness 1.5.1

Two defects 1.5.0 introduced, both found by running it against a real project rather than
against this package.

## Fixed

**Staleness AXIS 5 was mute on every run it would ever do.** It closed with
`[[ $FOUND -eq 1 ]] || echo "(clean)"`, reading the whole run's flag rather than its own. Any
earlier axis that fired left it set, so AXIS 5 printed its header and nothing — clean and
found being indistinguishable.

It passed here because AXIS 1–3 happen to be clean in this package. In a real project AXIS 1
lists every doc older than three weeks and is never clean. The only environment it was tested
in was the one where the bug could not appear.

This is AST-052's shape — a check whose own result cannot be read — shipped in the release
that fixed AST-052, in adjacent lines of the same file. Each axis now reports from its own
flag; the shared one is for the exit code. AXIS 1 had the same silence and was fixed with it
(AST-053).

**`ADAPT-HARNESS.md` said to commit the installation and never said what.** The upgrading
agent reached for `git add -A` and swept in two staged releases that had been superseded
before anyone ran them — roughly 1000 files, permanently, in a history that cannot be trimmed
without a rewrite.

Staging is deliberately cheap, so an abandoned candidate is ordinary rather than exceptional.
The prompt now names paths, derives the release to keep from `.astraler/CANDIDATE`, and
prints what is still untracked so an abandoned candidate is visible rather than assumed.
Untracked is its correct resting state: disk, not history (AST-054).

## Scope note

Both were found by running the shipped scripts against a project whose preconditions are
messy, not by re-reading them here. That is now three releases running where the defects came
from use rather than from review. The package-side checks are still worth having — they
caught the 1.5.0 payload defects on the project in one pass — but a check verified only where
its preconditions are tidy has not been verified.

# Astraler Harness 1.5.0

An address is only correct relative to whoever has to use it. This release fixes one that
was not, and adds the check that would have caught it.

## Fixed

**The simplify pass was addressed as `/simplify` — a form no agent can type.** `builder.md`
named Claude Code's built-in correctly and then handed the Builder a slash command. Measured
in a live project: two Builders, two tickets, one day, both hand-rolled a cleanup and neither
left the `simplify(increment):` marker. Nothing errored; both handbacks honestly described a
pass that had happened. The rows in the same table naming `mattpocock-skills:implement` and
`mattpocock-skills:code-review` were invoked correctly in those same sessions — a usable
address gets used.

Measured, not assumed: an agent invoked `Skill(skill: "simplify")` with no human typing
anything, the tool accepted it, and the real instruction body loaded. The alternative fix
under consideration — firing `/simplify` into the pane as a second user turn, costing a
round-trip per increment — was ruled out by that measurement rather than by argument.

**`dispatch-ticket` taught the rule that caused it.** AST-050 grouped `/compact`, `/clear`
and `/simplify` as built-ins whose bare names are their addresses. True for the first two:
they are CLI commands with no Skill-tool path. False for `simplify`, which is a bundled skill
carrying no `disable-model-invocation`. The two kinds are now separate, with the general rule
stated once: slash form for what only a human can type, Skill form for what the model can.

**Thomas's contract never carried the marker check.** The rule lived only in
`dispatch-ticket`, a skill read at dispatch; the check has to happen at handback. Thomas is
resident, so his contract is loaded every session and a skill he invoked fifty turns ago is
not. His merge step now verifies by artifact, with the command, and says plainly that a
handback describing a pass that left no marker is describing a substitute — and will read as
honest, because it is.

**The word-budget audit was measuring nothing.** `docs-staleness-audit.sh` looked for role
contracts at the repo root while this package keeps them under `harness/`. Five failed path
tests, a loop that ran zero times, no output, and `RESULT: all clean` — since 1.0.0, quoted
as evidence more than once in the session that found it. It now detects the payload, reports
how many contracts it measured, and fails when that number is zero (AST-052).

## Added

**Reachability check 6 — ADDRESS -> CALLABLE.** Checks 1–5 ask whether a thing exists and is
reached. None asked whether the address given for it works. Check 6 reads every skill named
in a contract, resolves how it can actually be invoked, and fails both directions: a
model-invocable skill written as `/name`, and a user-invoked-only skill called through the
Skill tool.

Invocability comes from the plugin's own frontmatter — 35 skills read at runtime, not a list
copied into this repo to drift. Built-ins are carried as two explicit sets, because the first
version of this audit tabulated plugin skills only and therefore could not have found
`simplify` at all. A line that names a skill without invoking it clears the check with
`<!-- addr-ok: <reason> -->`, so every exception is one visible decision rather than a
pattern quietly widened.

It also keeps 1.4.1's prefix work honest mechanically: a plugin command written bare, like
`/implement`, fails until it carries `/mattpocock-skills:`.

Mutation-tested in three directions: a model-invocable skill in slash form FAILS, a
user-only skill in Skill form FAILS, and `/compact` stays silent.

**Reachability check 7 — ARTIFACT -> BOTH ENDS.** The gap AST-043 recorded as unfixed. Every
artifact a gate reads must be named by the contract that produces it AND by the one that
checks it, with the registry recording whether each half belongs in an always-on contract or
in a skill read on invocation — a judgement, so it is written down rather than guessed. Its
honest limit: it catches a half going missing, not an artifact nobody registered. Mutation
tests include deleting the marker check from `thomas.md`, which is the real defect this
release fixes; check 7 catches it.

**The doctor now checks that bundled skills are reachable.** The Builder invokes `simplify`
itself, and three switches take that away — the `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS`
environment variable, `disableBundledSkills`, and a `skillOverrides` entry. All three fail
the same silent way. A harness installed across many machines cannot rely on the one it was
written on.

**Staleness axis 5 — self-reported counts vs the thing counted.** README claimed 35 failure
modes while the ledger held 51, said 1.0.0 at 1.4.4, and filed the ledger under a directory
it left in 1.1.0. Three statements of fact, none re-derived by anything. Now the version and
the count are checked against `VERSION` and the ledger itself.

## Scope note

The defect was found by the project running the harness, not by the harness. Check 6 closes
that specific blindness; it does not close the general one. Check 6 closes that specific
blindness; check 7 closes the class the marker fell through.

Two of this release's four defects were found in the tooling written to catch defects: an
audit axis that ran zero iterations and passed, and an audit regex that could not see
built-ins. Both are the shape the ledger already held three times.

Still not verified end to end: a ticket from spec to merge, concurrent Builders racing for a
claim, a QA walk, and a real Codex invocation.

# Astraler Harness 1.4.4

Corrects 1.4.3, which fixed the right symptom from the wrong assumption.

## Fixed

- **`<set-me>` means UNDECIDED, and undecided is a resting state.** 1.4.3 assumed a
  `<set-me>` row meant the owner did not want that runtime, and offered deleting the row as
  the way to say so. The owner's actual position is different and more common: *I use Claude
  or Codex depending on the project and the situation, and I have not decided for this role
  yet.* A table with a runtime left open is normal, not a defect, so the doctor now records
  it and moves on.

  The check that is actually worth having moved to **dispatch**: resolving a role onto a
  runtime whose row still reads `<set-me>` means using a model id nobody chose, so that
  STOPs and asks. Substituting another role's model to keep the dispatch moving is exactly
  the failure this prevents.

  Three states, each meaning one thing: a real model id is usable, `<set-me>` is undecided
  and blocks only at use, an absent row is a deliberate no.

  1.4.3's reasoning still holds — a warning the owner cannot act on is one they learn to
  skip. It was aimed at the wrong state.

# Astraler Harness 1.4.3

## Fixed

- **A role can decline a runtime, and the doctor stops asking.** `qa` shipped with a
  `<set-me>` codex row, so every doctor run warned about it and every upgrade asked the owner
  the same question again — with no way to answer "we are not using Codex for this role".
  Deleting the row now means exactly that: no fallback, no machine profile, and the doctor
  reports it as a decision rather than a gap.

  This is the convention `rin` has carried since 1.0.0 — an absent row is the correct state,
  read deliberately — applied to every role instead of just that one. A warning the owner
  cannot act on is a warning they learn to skip, which costs the ones that matter.

# Astraler Harness 1.4.2

## Fixed

- **Plugin skills are qualified at every point a command is CALLED**, which 1.4.1 covered
  only for the three literal slash commands. The phase tables in the role contracts are the
  other call site: they are where a role reads which command it must drive, so
  `mattpocock-skills:implement` there is what stops a bare `/implement` being constructed
  from a bare table cell.

  Scope is deliberately call sites only. A craft-layer list — "`tdd`, `research`,
  `codebase-design` are available to you" — names skills the model reaches by registration
  and nobody types, so a prefix there buys nothing and costs readability. This package's own
  skills stay bare; they are not plugin skills.

  `check-reachability.sh` now reads either form and compares on the bare name, so a
  qualified table cell does not break phase parsing.

# Astraler Harness 1.4.1

## Fixed

- **Plugin commands are written in their qualified form everywhere (AST-050).** 1.3.0 fixed
  the one name already known to collide and left the rest bare — including the **first line
  of every dispatch brief**: `/implement` for a Builder, `/grill-with-docs` for a Shaper.
  Those resolve today only because nothing else claims those words yet, and a collision is
  invisible until it exists: a later built-in or a second plugin changes what they resolve to
  with no diff here and no error at dispatch. The brief just gets prose instead of a phase.

  Bare forms now appear only for Claude Code's own built-ins — `/compact`, `/clear`,
  `/simplify` — where the bare name is the correct address.

  Owner's suggestion, and it was right: write commands the way Claude Code addresses them.

# Astraler Harness 1.4.0

Findings from the live project, and from the agent that built the package this replaces.
The theme is one sentence, taken from a file 1.x deleted: **a rule that is not present where
it must be remembered does not exist.**

## Fixed

- **Three of four dispatchable roles had no launcher written anywhere (AST-049).** Only the
  builder did. `review-with-rin` said "argv from the dispatch-ticket launcher matrix" and that
  matrix listed the builder alone, so dispatching Rin by the documentation was impossible. The
  matrix is now the single home for all four, and **check 5** requires every role to have both
  a launcher and a dispatcher that names it.

  Checks 1–4 only asked whether things agreed with each other — a question a completely inert
  system also passes. The shaper gap survived two rewrites because nothing tested for it: it
  is the same align-phase hole ADR 0001 was written about.

- **Thomas can dispatch the Shaper.** Previously his contract did not contain the word, so the
  role that runs align → spec → tickets had no way to be started.

- **Two always-on invariants came back (AST-048).** 1.x kept the ledger and dropped every
  `.claude/rules/` file — measured on 1.3.1, that count was zero. *One checkout, one driver*
  and *a role is decided by how it was spawned* survived only in advisory memory. They now sit
  in `dispatch-ticket` and in every Claude adapter. The ledger records evidence; a rule binds
  only from a contract.

- **Four prevention lessons entered role contracts**: test from the other side of a contract,
  fix the class not the instance, folding a finding is propagation, run every machine before
  the reviewer. A one-round gate has no second round in which to catch what these prevent.

- **The checker stops overclaiming.** It now prints its scope and states that the ledger's
  historical `Bound:` provenance is deliberately not scanned.

- **Adaptation treats removing an always-on rule as a policy change**, with a per-rule
  "re-homed to X / dropped because Y" line in the receipt.

  *Correction to an earlier draft of this note:* the package carries none of 0.14.0's four
  rule files, but the first repo to migrate lost **three**, not four —
  `no-secrets-in-exports.md` survived there because it had already become project-owned,
  citing an incident in that repo. Package scope and installed-project scope are different
  measurements and this note previously ran them together.

- **A web-shape assumption came out of the QA role.** It called an unrunnable product a
  finding; for a library, a CLI or a pipeline that is a fact about the product, not a defect.

## Declined

- **Putting the prevention lessons in the ledger**, as recommended. The ledger is advisory
  memory nothing is told to read — that placement is the very failure being reported.
- **Failing check 4 on the ledger's stale `Bound:` pointers.** They are documented provenance
  in append-only entries; enforcing it would keep the checker permanently red or force
  rewriting history.

# Astraler Harness 1.3.1

Two defects, both found by the repo running this, and both invisible to every check here.

## Fixed

- **1.2.0's language survived the release that reversed it (AST-046).** Splitting the walk
  out of the reviewer moved the dispatch mechanics into a new skill *verbatim*: three lines
  went on naming the walker "Rin" and calling the walk "a mode". The dispatcher reads that
  skill to pack the brief, so one line would have set the persona for the wrong agent.
  `check-reachability.sh` cannot see it — every path resolves; the error is semantic.
  **Re-read a moved block in its new context before the move counts as done.**

- **"Local" is a deployment fact, not a data fact (AST-047).** The QA role said "prefer a
  local or seeded environment for anything carrying customer data", assuming local means
  synthetic. The first repo to read it has a local database that is a **production snapshot
  with real buyer PII** — a screenshot of an order list there captures exactly what a
  production one would. The rule now keys on the data's provenance, treats prod-derived data
  as production data wherever it runs, and requires the agent to establish what the data *is*
  rather than infer it from where it runs.

  The general shape: a safety rule keyed to a proxy for the risk will be satisfied by the
  proxy.

# Astraler Harness 1.3.0

A fifth role. 1.2.0 put the product walk inside Rin as a mode; that was wrong by this
package's own rule.

## Added — the QA role

**Roles follow session boundaries.** A walk is a different session: its own worktree with the
product *running*, a different instrument, a different lifecycle. By ADR 0001's own criterion
that is a role, not a mode — and `rin.md` hitting its word budget was the measurement saying
so. Rin reads the diff; QA uses the running system.

Scope is wider than UI: interface, journeys, **API and contract behaviour including error
paths**, and data as experienced across the screens that show it.

**Why it earns a role (AST-045).** A test asserts what somebody thought to assert, which on a
web product is mostly backend logic. What is missing, misordered, unreadable or unreachable
on screen is where a user lives, and is exactly what no assertion covers. A green suite and a
coherent product are different claims.

**Carried from the prior package's retired walker**, whose three right decisions are kept:
scope and browser permission are **dispatch parameters**, so one role covers every screen
present and future; the judging **persona is fixed**, so a caller can narrow scope but not
lower the bar; and the default is **strictly non-mutating**, because a walk drives a real
logged-in session and the click that deletes has no undo. Unauthorized mutations and
unreadable data become **COVERAGE GAPS**, a first-class report section.

**Its safety rules are the load-bearing part.** Browser consent is a required dispatch field
and does not carry between runs. Prefer a local or seeded environment for anything carrying
customer data. Redact before the bytes are written, not after — gitignore prevents a commit,
not a leak. On a data-bearing screen ask a structural question rather than dumping the DOM.

**What was NOT carried:** the walk *method*. The original marked it fixed while containing one
project's browser tooling — a project shape smuggled into a generic payload. The method is the
project's, and adaptation records it.

**What actually killed the original: nothing referenced it.** It shipped across releases and
never ran, because no contract owned it and no dispatcher named it. Thomas's contract now
dispatches it before a PR, a merge or a release, and the reachability check covers it.

# Astraler Harness 1.2.0

Rin gains a third mode. 1.1.1 fixed the smaller half of this and said so; this is the rest.

## Added — `mode=walk`

**Reading a diff cannot find a disagreement between two screens (AST-044).** 1.1.1 gave the
Builder visual verification of its own change, which confirms a ticket renders. It does not
confirm the product still coheres, and the author is the worst-placed party to judge that —
the same reason a reviewer exists for code.

One walk of the prior package's retired walker role found: a 500 from a stale seed *plus the
production implication behind it*, a raw timestamp disagreeing with every other page, two
screens printing 85 and 44 for one concept, tabs summing to 183 against a total of 190. None
is in the diff that introduced it, because none is *in* a diff — each is a disagreement
between the change and somewhere else.

It is a **mode of the existing reviewer, not a fifth role**: same milestone, read-only, one
report, same triage. It fires **before a PR, a merge or a release**. What it needs that the
other modes do not is a running app at the reviewed SHA — never the Builder's checkout — and
a **written plan**: persona and data state, surfaces in scope *including the unchanged ones
showing the same concept*, what correct means, and the journeys.

Two outputs make it compound: a **verified-clean list**, so coverage accumulates rather than
resetting, and an honest statement of what could not be reached — a surface you could not
open is not a clean surface.

The plugin ships nothing for this: no QA, browser or e2e skill exists upstream.

# Astraler Harness 1.1.1

One defect, and it is the one this package was written to prevent — reproduced inside the
package itself.

## Fixed

- **A gate required an artifact no contract produced (AST-043).** `review-with-rin` asked the
  brief to carry "the Builder's browser-verify evidence". `builder.md` did not contain the
  word *browser* once. The gate named an artifact, named the role that owed it, and that
  role's contract never mentioned producing it — exactly the failure ADR 0001 was written
  about. A consuming repo shipped a visually-wrong control to `main` through this gap, caught
  by a person noticing rather than by any gate.

  The Builder's contract now owns visual verification for work that changes a user-visible
  surface, Rin treats unexplained absence as a finding, and adaptation records the repo's
  rendering path so a Builder does not rediscover it per ticket. The *tool* stays the
  project's; the harness requires the evidence, not a way of getting it.

## Known gap, stated rather than fixed

`check-reachability.sh` does not catch this class. It verifies every phase has an owner and
every reference resolves — **not that every artifact a gate demands has a producer.** That
check is harder and is not written. Until it is, read a gate's input list against the
contracts by hand whenever either changes.

# Astraler Harness 1.1.0

Five findings raised by the first repo to run this harness, written up as a report against
the package rather than patched locally. Four are structural, which is why this is a minor
bump: an ID namespace changes, a payload file moves, and two files stop being payload.

## Fixed

- **The ledger's IDs are now `AST-0xx`, not `FW-0xx` (AST-039).** `FW-` was already in use by
  the projects this installs into — one repo carried six IDs meaning different things across
  two ledgers and 235 citations, separated only by a prose routing rule a reader had to know
  existed. Numbers are unchanged, so `AST-032` is the entry that was `FW-032`. Projects keep
  `FW-`; the harness owns `AST-`.
- **The ledger moves to `.agents/memory/recurring-failure-modes.md` (AST-039).** It was the
  only payload file under `docs/`, which made it read as project material. Ownership is now
  learnable: `.agents/`, `.claude/agents/`, `.codex/` are the harness; `docs/` is yours.
- **Codex profiles ship no model id (AST-040).** The old placeholder resolved on no account
  and failed at the first cross-vendor call — end of phase, looking like the provider being
  down. The field is empty with a comment, and the doctor now MISSes on empty. A default that
  cannot be right should not look right.
- **`.agents/orchestrator.md` and the Codex profiles are SCAFFOLD, not payload (AST-041).**
  The file said "This file is the owner's" while every release overwrote it; the only thing
  preventing loss was an instruction to an agent. Written when absent, never overwritten;
  shape changes get reported for the owner to merge.
- **`code-review` and `simplify` are named unambiguously (AST-042).** Two skills answer to
  `code-review`, and the mandated `simplify` pass is the built-in — the plugin ships no such
  skill, so an agent looking for one skipped the pass silently.

## Upgrading from 1.0.x

Re-stage and re-apply. Your `.agents/orchestrator.md` and `.codex/profiles/*` are now
protected. Citations of `FW-0xx` in **harness-owned** files become `AST-0xx`; citations in
your own files are untouched and keep meaning what they meant.

# Astraler Harness 1.0.3

One defect, and it is the kind this package exists to catch: a check that could not fail.

## Fixed

- **The doctor compared Codex profiles against its own template, never against the table
  that owns the answer.** `.agents/orchestrator.md` is the single owner of role →
  runtime/model/effort, but a template shipped with placeholder model IDs agrees perfectly
  with a profile copied from it while BOTH disagree with the owner's table. The doctor
  reported green, and the first cross-vendor call would have failed looking like the
  provider being down rather than a config error. It now reads the role's codex row and
  fails when the profile disagrees. A named target's table wins over the package's copy.

## Still not verified

Three things, unchanged plus one: no ticket has gone spec → dispatch → gate → merge,
concurrent Builders have never raced for a claim, and **no Codex model ID has ever been
confirmed by an actual invoke** — the fallback rows are declared, not measured. The first
cross-vendor arm is that test.

# Astraler Harness 1.0.2

One defect, found by reading a diff rather than by any check.

## Fixed

- **`FW-*` is not a reserved namespace (FW-039).** The first upgrade into a mature repo
  landed beside a project ledger already owning ten of the same IDs — including `FW-032`,
  which this payload cites eleven times with an entirely different meaning. Every check
  passed: the reference existed, the file existed, the number was well-formed. A checker
  verifies that a reference RESOLVES, not that it resolves to what the author meant.
  Citations now resolve by the location of the citing file, the ledger says so, and
  adaptation detects the collision and records the rule in the project's entry doc.
- **`check-reachability.sh` no longer degrades silently.** Its ownership answer comes from
  the staged release; with no release to read it now says so instead of quietly treating
  every project skill as harness-owned, which is the FW-038 defect returning.

# Astraler Harness 1.0.1

The first real installation, into an existing 1,991-commit repo. Eight defects surfaced that
no amount of re-reading had found — five of them in the dispatch path the whole package
exists to provide. Nothing here is a new feature.

## Fixed

- **The payload has to be COMMITTED, not merely present (FW-036).** A git worktree carries
  tracked content only, so an untracked or gitignored payload leaves every Builder with no
  contract — and no signal that one is missing. The target repo's `.gitignore` had `.agents/*`,
  which would have produced contract-less Builders silently. `dispatch-ticket` now states the
  rule with a worktree proof, `check-requirements.sh` fails when the payload is untracked, and
  the adaptation prompt raises the commit with the owner instead of leaving it for later.
- **A multi-line brief pastes without submitting, and the pane calls it `idle` (FW-037).**
  Both submission commands work on one line and silently fail on a block — and every real
  brief is multi-line. `dispatch-ticket` now sends an explicit Enter and requires observing
  `working` before believing a turn began.
- **The flow skills are `disable-model-invocation`, so no agent can invoke them.** The brief's
  first line is now the slash command itself, which is what "an agent playing the human at
  that step" means mechanically. The adaptation prompt no longer orders an agent to run
  `setup-matt-pocock-skills`; it asks the owner and then verifies the artifacts.
- **`check-reachability.sh` fired on every adopted repo (FW-038).** It treated everything in
  `.claude/skills/` as harness-owned, so a project's own skills read as unreachable defects —
  six findings, none real, on a correct install. Ownership now comes from the staged release
  manifest, and skipped project skills are reported by name.
- **The doctor's TARGET axis** described a post-adaptation state while telling the owner to
  fix it before installing; those files are produced *during* adaptation. It also could not
  find Codex templates from inside a staged target.

## Upgrading from 1.0.0

Re-stage and re-run the adaptation; it is a normal upgrade with no migration. After it lands,
confirm the payload is visible where it has to be:

```bash
git worktree add --detach /tmp/harness-check HEAD
test -f /tmp/harness-check/.agents/roles/builder.md && echo OK
git worktree remove --force /tmp/harness-check
```

## Still not verified

No ticket has gone spec → dispatch → gate → merge end to end. Concurrent Builders have never
raced for a claim. Both remain the first things to test.

# Astraler Harness 1.0.0

A rebuild, not an upgrade. The method moves to Matt Pocock's `mattpocock-skills` plugin, the
review loop is removed, and this package keeps only its own half: brownfield work, and many
agents on one codebase at once. See `docs/adr/0001-rebuild-the-method-around-matt-pocock-skills.md`
for the reasoning and the rejected alternatives.

## Breaking

- **The vendored skills are gone.** Install the `mattpocock-skills` plugin (≥ 1.2.3); it
  supplies `wayfinder`, `grill-with-docs`, `to-spec`, `to-tickets`, `implement`,
  `code-review`, `triage`, `to-questionnaire`, the craft layer, and
  `setup-matt-pocock-skills`. Nothing in this package works without it: the whole chain's
  indirection depends on that setup step.
- **The review loop is removed.** Two weeks of field use produced 5 to 14 gate rounds per
  artifact, a large share of them the loop repairing its own earlier rounds. Review is now
  one bounded pass per ticket, one Rin round per milestone, one cross-vendor arm per phase.
  A design-level blocking finding escalates to the owner through `to-questionnaire`.
- **Roles are Thomas, Shaper, Builder and Rin**, and they follow session boundaries rather
  than seniority. The prior lead/executor build pair is retired: seam decisions move up to
  the Shaper, where the whole picture is still in context, and increment review moves to
  `code-review`, which is spec-aware and bounded.
- **`dispatch-slice` is now `dispatch-ticket`**, rebuilt around one Builder per ticket in one
  pane over one worktree. The two-pane tab is gone.
- **The two Codex-root arm skills are now one.** With a single arm point at phase end,
  `codex-plan-gate` and `codex-review-with-rin` collapse into `codex-claude-arm`;
  `codex-gate` becomes `codex-arm`.
- **The tracker is the coordination substrate.** Work state lives on the tracker configured
  behind `docs/agents/issue-tracker.md`, and assigning a ticket is the claim that keeps
  concurrent sessions apart.

## Carried over

`recurring-failure-modes.md` (34 entries, append-only, unchanged), Rin's gate mechanics, the
cross-vendor arm, `code-scout`, the herdr watcher and the staleness audit. Each survived on
the same test: it points at a measured failure mode, and it serves either brownfield work or
concurrency.

## The brownfield half

The six gaps upstream leaves on an existing codebase, split by how they are reached.
`extract-standards`, `bootstrap-glossary` and `batch-triage` are **invoked by name**, run once
per repo, and each produces an artifact the owner reviews before it counts — Thomas owns all
three as phases, so none can become work everyone assumes someone else ran.
`legacy-testing`, `untangle` and `module-boundaries` are **model-invoked craft**, reached when
the situation arises, needing no wiring.

`extract-standards` carries the loudest requirement in this release: a `THIN` coverage verdict
is reported to the owner in words, because it means `code-review`'s Standards axis will keep
doing the generic review its own design exists to avoid.

`.agents/orchestrator.md` ships as the owner's role → runtime/model/effort table. Row values
survive upgrades; the structure follows the package.

## The reachability check

`scripts/check-reachability.sh` enforces, in both directions, that the method the docs
describe is the method that exists: every phase the README's role table names is owned by
exactly one contract and by the role named; every shipped skill is reached by a contract,
another skill or the adaptation prompt; and every path, `--agent` and `--profile` a contract
or skill names resolves in the payload.

It found five real defects on its first run, including two skills naming `.claude/agents/*.md`
files the payload never shipped — meaning `claude --agent builder` would have failed at
dispatch with "agent not found". The adapters and the Codex profile templates now ship.

## Held out of 1.0.0 deliberately

- `docs/governance/distilled/` — 26,150 words of distilled BMAD, the approach upstream names
  as the one it rejects. Holding both is a separate decision.
- `docs/agents/` content beyond what `setup-matt-pocock-skills` writes.

## Upgrading from 0.14.0

There is no in-place upgrade path. Run the prior package's `uninstall.sh` against the target
repo first: it removes what the old installer staged and reports the project-owned files the
old adaptation agent edited, which stay yours to review by hand.
