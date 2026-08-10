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

2. **Run `setup-matt-pocock-skills` in this repo.** It configures the issue tracker and
   writes the files the whole chain reads. It is mandatory because the indirection depends on
   it: Thomas's frontier query reads the tracker named in `docs/agents/issue-tracker.md`, his
   triage reads the vocabulary in `triage-labels.md`, and the Shaper's domain work reads
   `domain.md`.

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
4. This run installs the operating harness. Product behaviour stays as it is, and committing,
   pushing, merging or changing external services waits for the owner to ask.

**Codex role profiles** (`thomas`, `shaper`, `builder`, `rin`) are machine-local at
`${CODEX_HOME:-$HOME/.codex}/<role>.config.toml`. Compare each tracked template with its
destination and report missing or drifted state. Provision only after explicit owner
confirmation in this session; a declined or absent confirmation is recorded `PENDING` for
that runtime and leaves a Claude-only installation valid.

**Rin has no fallback row, and its absence is the correct state — preserve it.** The gate is
a Herdr pane on the root provider's runtime, so a fallback would name a runtime that cannot
host it. A project that has re-added the row has regressed; report it.

## 5. Brownfield entry — not in this release

This package's brownfield half is **specified and not yet built**: standards extraction,
glossary bootstrap, the legacy-testing doctrine, a refactor path for repos too tangled for
`improve-codebase-architecture`, batch triage of an inherited backlog, and boundary
enforcement. See `docs/adr/0001-*.md` for what each one is for.

**Until that release lands, this is the hand-off point, and it is named rather than silent.**
On a repo with existing code, tell the owner plainly in the receipt:

- **`code-review`'s Standards axis reads whatever the repo documents**, and otherwise falls
  back to twelve generic Fowler smells — becoming the generic review its own design exists to
  avoid. Report what this repo documents today, and say which of the two the axis will do.
  Silent degradation is the failure class this harness exists to catch, so make it audible.
- **`tdd` requires a confirmed seam.** On code that has none, the Builder is instructed to
  report that to Thomas rather than force it, and the doctrine that resolves it is not in
  this release.
- **`CONTEXT.md` is not bootstrapped here.** `domain.md` from step 2 is what exists.

Record these under a `## Brownfield gaps` heading in the receipt. `code-scout` and the
staleness audit ship in this release and are the reading layer these will build on.

## 6. Validate by artifact

Run checks proportional to what changed:

- `git diff` — confirm unrelated project work is untouched;
- `bash -n` on shell scripts, and parse any Codex TOML;
- `./check-requirements.sh .` passes both axes;
- every role contract named in `.agents/orchestrator.md` resolves to a file that exists, and
  every phase in the method appears in exactly one contract;
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
