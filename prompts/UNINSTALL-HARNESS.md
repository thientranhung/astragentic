# Remove the Astraler harness from this project

You are the semantic uninstaller, and you are the mirror of `ADAPT-HARNESS.md`. That prompt
integrated a release using project context; this one takes it back out using the same context.

**Nothing here is `rm -rf`.** The mechanical half of removal is trivial and is not why this file
exists. The hard half is deciding, for every file at a path the payload also ships, whether the
PROJECT wrote it — and getting that wrong deletes work nobody can recover from a release
directory. Work autonomously where the evidence decides it. Take anything the evidence does not
decide to the owner.

**Fail closed. A file you cannot classify is a file you keep** and report. An over-cautious
uninstall leaves a directory the owner deletes in one command; an over-confident one loses
authored work silently, and silence is the part that makes it unrecoverable.

## 1. Resolve what is actually installed

1. Read `.astraler/state/applied-version` — call it `<applied>`. **No marker means STOP**: you
   cannot classify anything without the release the project actually received. Report that, and
   ask the owner whether a staged release under `.astraler/releases/` is the right baseline. A
   guess here is the silent-loss case.
2. Confirm `.astraler/releases/<applied>/harness/` exists and is readable. That directory is the
   byte-exact record of what shipped; it is the oracle for every decision below, and this whole
   procedure is one more use of the immutability `install.sh` protects.
3. Read the project's entry docs (`AGENTS.md`, `CLAUDE.md`) and `.agents/orchestrator.md` before
   deleting anything. You are about to remove things they reference.

## 2. Stop what is running, BEFORE you touch files

A watchdog outlives the files it watches, and a broker outlives its worktree. Do this first or
you will leave processes holding paths that no longer exist.

```bash
scripts/herdr-watchdog.sh stop        # clears /tmp/herdr-watchdog-<workspace-label>.lock
git worktree list                     # every gate-arm-* and ticket worktree still registered
```

Remove those worktrees, and for each one kill the `app-server-broker.mjs` whose `--cwd` matches
it and stop only the containers labelled with that worktree's compose project. `codex-arm`
documents the sequence and the reasons; follow it rather than a blanket kill. **Never `pkill -f`
by name** — it reaches every project on the machine.

Report any Builder pane still working. **A live Builder is a stop, not a cleanup step.**

## 3. Classify every payload path by evidence, not by memory

```bash
diff -rq .astraler/releases/<applied>/harness .
```

| `diff` says | Means | Do |
|---|---|---|
| identical | the package's, untouched | remove |
| differs | the project edited a payload file, or a later release did | **keep, report, ask** |
| only in the project | the project authored it at a payload path | **keep** |
| only in the release | already gone | nothing |

Where the project runs `scripts/check-payload-drift.sh`, its manifest is a second, independent
statement of the same thing — the files the project authored at payload paths. **Read both.
Where they disagree, the disagreement is the finding**, and it goes to the owner rather than
being resolved by picking the more convenient one.

**Never owned by the package, regardless of what `diff` says:**

- `.agents/orchestrator.md` — the owner's runtime and model rows; the installer only ever wrote
  it when absent (AST-041)
- `.claude/settings.json` — the project's hooks

## 4. Remove, in this order

1. The payload files step 3 marked **identical**, under `.agents/`, `.claude/`, `.codex/`,
   `.opencode/` and `scripts/`. Directories that end up empty go too; directories still holding
   project files stay.
2. `.astraler/` **last** — step 3 reads it, so removing it earlier destroys your own oracle.

Outside the repo, and nothing in the repo will remind anyone:

- `${CODEX_HOME:-$HOME/.codex}/<role>.config.toml`, one per role the project provisioned. Read
  `.agents/orchestrator.md` for which roles those were **before** you delete it.
- the herdr workspace, if it exists only for this project. Ask — a workspace can outlive one
  project's use of it.

## 5. Unwire the semantic half

The adaptation did not only copy files; it edited the project's own documents. Removing the
files leaves those edits pointing at nothing.

- `AGENTS.md` / `CLAUDE.md` — remove the harness-derived rows and pointers (the ticket prefix
  declaration, role and dispatch pointers, ledger path). **Leave everything the project wrote.**
  Read each line and decide; do not pattern-delete.
- Anything else referencing `.agents/`, `scripts/` or `.astraler/`. `grep` for them and fix each
  hit rather than trusting a list — a stale pointer to a deleted file is the exact defect this
  package spends most of its ledger on.

## 6. KEEP these, and say so in the receipt

They arrive with the harness and are not the harness:

- **`docs/agents/issue-tracker.md`, `triage-labels.md`, `domain.md`** — written by
  `setup-matt-pocock-skills`, describing the project's tracker and domain. They outlive this
  package and a project still uses them without it.
- **The project's ledger** — its own measured history. Removing the tool that suggested the
  format is not a reason to lose the measurements.
- **Every ticket, branch, worktree and commit** the harness helped produce. Obviously, and it is
  written down because "clean removal" has been read as "revert" before.

## 7. Verify by artifact, then leave a receipt

Verification is a command, not a belief:

```bash
git status                                  # exactly the deletions you intended, nothing else
grep -rn '\.astraler\|\.agents/roles' --exclude-dir=.git .   # no live pointer to what is gone
ls ~/.codex/*.config.toml 2>/dev/null       # profiles gone, or named as deliberately kept
```

Write `UNINSTALL-RECEIPT.md` at the repo root, and keep it short — it exists so a later session
can tell a deliberate removal from an accident:

- the `<applied>` version removed, and when
- what was KEPT and why, one line each: project-authored files at payload paths, the three
  `docs/agents/` files, the ledger
- what was NOT decidable and is waiting on the owner
- anything left running that you could not stop

**Then commit, in one commit, with the receipt in it.** A removal spread over several commits is
one a bisect cannot step over.
