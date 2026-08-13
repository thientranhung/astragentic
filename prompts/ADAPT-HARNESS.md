# Adapt the Astraler harness into this project

You are the semantic installer for the release staged inside this repository. `install.sh`
changed nothing outside `.astraler/`. Your job: understand this project, integrate the
candidate, verify the result **by artifact**, and leave an auditable receipt.

Work autonomously where the evidence is sufficient. Take a genuine ownership conflict to the
owner rather than resolving it with an overwrite.

## 1. Resolve the installation state

1. Read `.astraler/CANDIDATE` — call its value `<candidate>`.
2. Read `.astraler/releases/<candidate>/RELEASE-NOTES.md` **first**: it owns this release's
   semantic intent, breaking changes and migration guidance. Then its `VERSION`, `README.md`,
   the role contracts under `harness/.agents/roles/`, and the skills the contracts name.
   Load a skill's body when you need its contract, rather than preloading all of them.
3. Read `.astraler/state/applied-version` when present. A named `<previous>` makes this an
   upgrade: read that release's notes and use `.astraler/releases/<previous>/` as the
   baseline for a three-way comparison. No applied version means a fresh install.
4. **Read the live project before planning**: root instructions, existing agent
   configuration, dependency manifests, build and test commands, docs, git status, and any
   existing harness-derived files. Live project truth is evidence, not disposable output.

## 2. The plugin and its setup step — mandatory, and verified

**This package is an operating framework around
[`mattpocock-skills`](https://github.com/mattpocock/skills), not a replacement for it.**
Every spine phase the role contracts name — `triage`, `wayfinder`, `to-questionnaire`,
`ask-matt`, `grill-with-docs`, `to-spec`, `to-tickets`, `implement`, `code-review` — lives in
that plugin. Without it the contracts point at nothing, so this step comes before any
integration work.

1. **Confirm the plugin is installed**, version ≥ 1.2.3. Where it is absent, stop and ask the
   owner to install it (`/plugin` → `mattpocock-skills`, marketplace `claude-plugins-official`).
   This is a genuine blocker: record `PENDING` and return rather than adapting around it.

2. **Ask the OWNER to run `/mattpocock-skills:setup-matt-pocock-skills` in this repo, and wait.** You cannot
   run it yourself: it is `disable-model-invocation: true`, like every flow skill in the
   plugin, so no model reaches it — only a person typing the command, or that text arriving
   as a user turn in a pane. Stop here and say so plainly rather than working around it.

   It is mandatory because the whole chain's indirection depends on it: Thomas's frontier
   query reads the tracker named in `docs/agents/issue-tracker.md`, his triage reads the
   vocabulary in `triage-labels.md`, and the Shaper's domain work reads `domain.md`.

3. **Verify the three files exist, by reading them.** A skill that reported success and a
   skill that produced files are different claims, and only the second one is checkable:

   ```bash
   ./check-requirements.sh .        # MACHINE + TARGET axes, exit 0 = both clean
   ```

   Or directly: `docs/agents/issue-tracker.md`, `docs/agents/triage-labels.md`,
   `docs/agents/domain.md`. **A missing file after a step that reported success is the
   finding**, not a detail to fill in yourself — writing one by hand produces a tracker
   pointer nothing actually configured. Report it and ask the owner.

4. **Confirm the tracker is reachable** using whatever `issue-tracker.md` names, and that a
   ticket can carry an **assignee** and **blocking edges**. Those two fields are the
   coordination substrate: assignee is the claim that keeps concurrent Builders apart, and
   blocking edges are what the frontier query reads. A tracker missing either one is a
   finding for the owner, because the concurrency model rests on them.

## 3. Build an integration map

Classify candidate material before editing anything:

- **Reusable harness runtime** — role contracts, skills, scripts, Codex config. Add or
  upgrade these.
- **Project-owned truth** — `AGENTS.md`, `CLAUDE.md`, `docs/` content, domain docs, ops
  skills, environment and deployment instructions. These stay the project's; wire them to
  harness context with a small marked reference where one is needed.
- **Runtime-specific** — Claude Markdown/YAML agents and skills stay Claude-native; Codex
  TOML profiles and skills stay Codex-native; opencode adapters (`.opencode/agents/*.md`)
  stay opencode-native. Translate mechanics by reading each runtime's contract, rather than
  by analogy from another.
- **Scaffold — written once, never overwritten.** `.agents/orchestrator.md` and
  `.codex/profiles/*.config.toml` carry the owner's runtime and model choices. Write them on
  a FRESH install only. On an upgrade, leave the values alone and report any change in the
  table's shape for the owner to merge. A release that overwrites them silently reverts
  tuning the owner made deliberately, and the first sign is a dispatch failing on a model id
  they never chose (AST-041).
- **Role contracts and their adapters** — `harness/.agents/roles/{thomas,shaper,builder,rin}.md`
  are runtime-neutral and are the single home for each role's phases. Role →
  runtime/model/effort lives in the owner-editable `.agents/orchestrator.md`; contracts carry
  no model IDs. On upgrade, preserve the owner's tuned row values and merge new rows or
  columns.

For an upgrade, compare previous upstream → live project → candidate:

- live matches previous upstream → safe to replace with the candidate;
- live diverged for project reasons → preserve the intent and merge the candidate's new
  behaviour semantically;
- the candidate supersedes a harness-owned file → remove it once you have confirmed the live
  file holds no unique project value and no references remain;
- ownership genuinely ambiguous → record the conflict and ask.

**Retiring an always-on rule is a POLICY change, not housekeeping.** Where an upgrade removes
a file the project loads every session — `.claude/rules/*.md` and anything equivalent — the
receipt gets an explicit line per rule: **re-homed to X**, or **dropped because Y**. Removing a
persona or a skill is housekeeping; removing an invariant is a decision, and one that reads as
a tidy-up in a diff. When 1.x dropped 0.14.0's rule tier, two invariants went
unnoticed until a project measured it — and a third survived only because that project had
already adopted it as its own (AST-048).

**Check for an ID-namespace collision.** This package's failure-mode ledger uses `FW-0xx`,
and that prefix is not reserved — a mature repo often keeps its own ledger using the same
shape. Grep the project's docs for `FW-0` and compare the IDs against
`.agents/memory/recurring-failure-modes.md`. Where any ID appears in both with
different meanings (one measured install collided on ten, including the payload's
most-cited `AST-032`), the numbers alone are ambiguous and the project's entry doc probably
routes all of them to one place.

Resolve it **by location, not by renumbering** — the ledger is append-only: record in the
project's entry doc that a citation resolves in the ledger belonging to the material that
carries it, harness citations in the harness ledger and project citations in the project's.
Report the collision and the rule in the receipt (AST-039).

**The project keeps its own ledger, and this is where it gets established.** Two ledgers is
the design, not drift: `.agents/memory/recurring-failure-modes.md` is PAYLOAD and a release
overwrites it whole, so a project entry written there is deleted by the next upgrade, in
silence. Confirm the project has a ledger of its own outside the payload — a mature repo
usually does — and if it does not, create one and name its path in the project's entry doc
beside the tracker and standards pointers.

**Then say which one is written to, in a file the agent loads at session start**, not in a
document it opens on demand. Read resolves in either; **writing is always the project's.** An
instruction that lives only in a load-on-demand doc is skipped, and only the owner notices
(AST-069) — a measured project ran a whole harness generation with the rule in place, in the
wrong file, and added zero entries.

Produce a concise map — add, update, merge, preserve, remove, and the questions that truly
block safe integration — before you edit.

## 4. Apply

Integrate the smallest coherent result.

1. Keep project instructions and system truth intact. Mature project docs stay; harness
   content is referenced from them rather than replacing them.
2. Adapt generic placeholders to this project's real commands and boundaries **in
   project-owned files only**. The reusable payload stays generic.
3. Preserve runtime separation and the project's existing custom agents and skills. Merge
   upstream changes rather than multiplying near-duplicate files.
4. This run installs the operating harness. Product behaviour stays as it is, and pushing,
   merging or changing external services waits for the owner to ask.

**The installation has to be COMMITTED before any Builder can be dispatched**, and this is
the one commit to raise with the owner rather than leave for later. A git worktree contains
only tracked content, so an uncommitted payload is invisible inside every Builder worktree —
including the role contract its adapter tells it to read first (AST-036). Check the repo's
ignore rules for `.agents/` or `.claude/` patterns that would exclude the payload, propose
allow-list entries where needed, and prove the result:

```bash
git worktree add --detach /tmp/harness-check HEAD
test -f /tmp/harness-check/.agents/roles/builder.md && echo OK || echo "PAYLOAD NOT VISIBLE"
git worktree remove --force /tmp/harness-check
```

Report the outcome in the receipt. `PAYLOAD NOT VISIBLE` after the commit is a blocker, not a
detail: it means dispatch will silently produce contract-less Builders.

**Commit the applied release and the payload — not every release sitting under
`.astraler/releases/`.** Staging is cheap and abandoning a candidate is normal: a release can
be staged, superseded before anyone runs it, and never applied. `git add -A` sweeps those in,
and a project that upgrades often accrues megabytes of releases nobody ever ran, permanently,
in a history that cannot be trimmed without a rewrite. Measured once: two superseded
candidates, ~1000 files, entered history in a single upgrade commit.

So add paths, and know which release you are keeping:

```bash
CAND="$(cat .astraler/CANDIDATE)"
git add .agents .claude .codex scripts .astraler/state .astraler/CANDIDATE
git add ".astraler/releases/$CAND" || true          # may be refused; the next line decides
git diff --cached --name-only -- ".astraler/releases/$CAND" | wc -l
```

**That count is the check, and it must be non-zero.** The obvious version of this step —
`git status --short ".astraler/releases/"`, reading "anything still listed was never
applied" — cannot fail: where a project's `.gitignore` excludes `.astraler/`, `git add`
refuses the path and `git status` then prints **nothing**, which reads as *everything
applied and committed* while not one file was staged. Measured on a real upgrade. A check
whose output is identical when the step worked and when it was impossible is AST-032, and
this file has now carried two of them.

**A zero is a finding, not a failure to route around.** Do not reach for `git add -f`: the
ignore rule is the project's, and forcing past it overrides a decision this package did not
make and does not ship. Record the outcome in the receipt instead — *applied release is on
disk only, excluded by the project's ignore rules* — so the owner can decide whether to
carve an exception. What must not happen is the receipt implying it was committed.

An unapplied release left untracked is the correct resting state — it costs disk, not
history, and the next run either applies it or the owner deletes the directory. **An
applied one left untracked is a different thing**: the notes and the prompt describing what
this upgrade meant to do exist on one disk and nowhere else.

**Codex role profiles** (`thomas`, `shaper`, `builder`, `rin`) are machine-local at
`${CODEX_HOME:-$HOME/.codex}/<role>.config.toml`. Compare each tracked template with its
destination and report missing or drifted state. Provision only after explicit owner
confirmation in this session; a declined or absent confirmation is recorded `PENDING` for
that runtime and leaves a Claude-only installation valid.

**Rin has no fallback row, and its absence is the correct state — preserve it.** The gate is
a Herdr pane on the root provider's runtime, so a fallback would name a runtime that cannot
host it. A project that has re-added the row has regressed; report it.

## 5. Brownfield entry

On a repo with existing code, three bootstrap skills run once and each produces an artifact
the **owner reviews before it counts**. Thomas owns all three as phases; run them in this
order, because each feeds the next:

1. **`extract-standards`** → `docs/agents/standards.md`. **Report its coverage verdict to the
   owner in words, in this run's summary.** A `THIN` verdict means `code-review`'s Standards
   axis will keep falling back to twelve generic smells — the generic review its own design
   exists to avoid. Silent degradation is the failure class this harness exists to catch, so
   a THIN verdict filed quietly in a header is that failure happening inside the tool built
   to prevent it.
2. **`bootstrap-glossary`** → `CONTEXT.md`, seeded from the terms the code already uses, every
   term citing the file it was read from and marked `UNREVIEWED` until the owner confirms it.
3. **`batch-triage`** — only where the repo arrives with an existing backlog. Its closures
   wait for the owner; its live tickets carry labels and blocking edges, which is what makes
   Thomas's frontier query meaningful on day one.

Three further skills are **model-invoked** and need no wiring: `legacy-testing` when code has
no seam for `tdd` to attach to, `untangle` when a refactor is too tangled for
`improve-codebase-architecture`, and `module-boundaries` when an import crosses a boundary.
Confirm they are staged; reaching them is the agents' business, not this run's.

**Name the repo's rendering path, or record that it has none.** The Builder's contract
requires browser evidence for work that changes a user-visible surface, and Rin's gate checks
for it, but the *tool* is the project's — a browser skill, a preview or dev command, a
storybook. Find what this repo already uses and record it in the receipt so a Builder does
not have to rediscover it per ticket. A repo with a UI and no way to render it is a finding
worth stating plainly: every visual defect there will reach the owner's screen first.

Record the coverage verdict, the glossary counts, the triage counts and the rendering path
under a **`## Brownfield bootstrap`** heading in the receipt.

## 6. Validate by artifact

Run checks proportional to what changed:

- `git diff` — confirm unrelated project work is untouched;
- `bash -n` on shell scripts, and parse any Codex TOML;
- `./check-requirements.sh .` passes both axes;
- **`scripts/check-reachability.sh` exits 0.** It enforces that every phase the method names
  is owned by exactly one contract, that every shipped skill is reached by something, and
  that every path, agent and profile a contract or skill names actually exists. A contract
  naming a file that does not exist is how the prior package failed, so this is a hard
  failure rather than a warning;
- Codex profile templates compared with their machine-local destinations, each recorded
  provisioned, drifted, missing or declined, and agreeing with their `orchestrator.md` rows;
- referenced files exist, and project-owned entry docs carry no leftover placeholders;
- `AGENTS.md`, `CLAUDE.md` and the project's docs still express this project's truth rather
  than package defaults.

**Verify by reading the artifact, not by reading a summary of it.** A report saying a file
was updated is not evidence the file changed.

## 7. Record the receipt

Only after validation succeeds:

1. Create `.astraler/state/` when needed.
2. Write `<candidate>` to `.astraler/state/applied-version`.
3. Write `.astraler/state/ADAPTATION-REPORT.md` containing: fresh install or upgrade with
   previous → candidate versions; release-note requirements applied, superseded or judged not
   applicable; files added, replaced, merged, preserved and removed; project-specific
   decisions and why; the plugin version and the step-2 verification results; a
   **`## Brownfield gaps`** section from step 5; validation commands and their outcomes; and
   unresolved conflicts or follow-up work.

Where validation fails or a real ownership conflict is unresolved, leave `applied-version`
where it is, record the blocker, and return `PENDING`.

Finish with `APPLIED` or `PENDING`, the candidate version, the most important integration
decisions, and exact artifact paths.
