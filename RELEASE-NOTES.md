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
