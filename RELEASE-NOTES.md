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
