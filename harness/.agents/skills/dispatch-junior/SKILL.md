---
name: dispatch-junior
description: "Builder-only recipe to hand a ticket's implementation to a junior pane on another runtime (Grok first) and take the tree back for review, simplify and the arm. Fires only when the Builder's Junior row in .agents/orchestrator.md names a runtime. Covers the pane, the launcher, the brief, the wait, the read-back and the close."
---

# Dispatch to a junior

**Who:** the Builder, inside its own ticket, after the red tests are committed. Thomas never
dispatches a junior; a junior never reports to Thomas.

**When:** `.agents/orchestrator.md` → `## Junior` → the `builder` row names a runtime. `none`
or no row means you implement alone and this skill does not fire. The runtime names the
supplement the junior reads: `.agents/roles/junior-<runtime>.md`. A runtime with no supplement
file in the worktree is a misconfigured row: STOP and tell Thomas.

**What stays yours:** every phase in `builder.md` except the typing. the red tests of `astra-implement-with-tdd`,
both reviews, simplify, the arm, the markers, the handback and the push are the Builder's, run
over the junior's commits exactly as over your own. The mod's gates read your pane, not the
junior's, so nothing about them changes.

## 1. The pane — in your tab, beside you

```bash
herdr pane split --current --direction right --no-focus      # read result.pane.pane_id
herdr pane rename <pane-id> "junior:<ticket-id>"
```

The pane's cwd is your worktree, because yours is. Never a new tab, never a new worktree: one
worktree, two writers in sequence, never at once (below).

## 2. Launch — the row decides the flags

```text
grok → herdr agent start "junior-<id>" --kind grok --pane <pane-id> --timeout 60000 \
         -- --model <row: Model> --reasoning-effort <row: Effort> \
            --always-approve --deny "Bash(git push *)"
```

`<id>` is the ticket id **lowercased**: herdr refuses an agent name with a capital letter
(`invalid_agent_name`; lowercase letters, digits, `-`, `_`, 1–32 chars), so `ABC-129` launches
as `junior-<abc-129>` with the brackets dropped. Model and effort come from the Junior row, never from memory.
`--always-approve` because nobody sits at that pane to answer a prompt; `--deny` is enforced by
the runtime itself and is the one hard stop the pane carries. Measured 2026-10-17 on Grok
Build 1.0.60: driven straight at the runtime, `git push origin main` returned *Denied by
permission policy: deny rule on bash matching "git push \*"* and the remote stayed empty.

Then wait for the prompt: `herdr agent wait junior-<id> --until idle --timeout 60000`.

## 3. The brief — one `agent prompt`, by name

```bash
herdr agent prompt junior-<id> "<brief>"
```

The brief's first line is `Read .agents/roles/junior.md, then .agents/roles/junior-<runtime>.md, before anything else.`
Then, each on its own line:

```
ticket: <id> — <title>
criteria: <the acceptance criteria this brief covers, numbered>
red tests: <paths> — run: <exact command>
write-set: <files you may change>
read-only: <files you may not change — the tests above are always here>
head before: <short sha>
```

A brief without the test command or the write-set is not sent: the junior stops on it, and
rightly. **A brief never contains the literal `JUNIOR-DONE` or `JUNIOR-BLOCKED`**: the pane
echoes the brief, and the read-back takes the last match, which would then be your own words
(measured: a follow-up that quoted the marker matched before the junior's reply did). The
rendered line is indented, so the match is unanchored. `agent prompt` appends to an unsent composer and submits the fusion (AST-154), so a
re-delivery reads the composer first (`dispatch-ticket`, *Submitting*).

## 4. The wait — the watcher, in the background

**You do not edit the worktree while the junior holds it.** Two writers in one checkout is
AST-016 with a shorter fuse.

```bash
scripts/herdr-watch-terminal.sh <pane-id> 3 3600 120 20   # Bash run_in_background; exit 0 = TERMINAL:<state>
```

The watcher observes `working` for this turn before trusting any settled state, debounces the
idle flicker a Grok pane shows mid-turn (measured 2026-10-16: three consecutive reads needed),
and heartbeats. The workspace watchdog does not treat a `junior:` pane as dispatched (its
prefix lists are `ticket:`/`spec:`/`qa:`), so this watcher run is the only watch on it and
Thomas gets no alert for it. Status is a bell, not a verdict: on exit, read.

Measured 2026-10-17 (Grok Build 1.0.60, grok-4.7 high): three committed red tests, one brief,
`TERMINAL:done` after 1m1s, one commit `LAB-1: implement slugify` trailered
`Implemented-by: grok/grok-4.7`, `JUNIOR-DONE LAB-1 head=80fa15b tests=pass changed=1 files`
as the last line, tests green on re-run. A follow-up brief planting `git push` came back
`JUNIOR-BLOCKED … push is outside the junior boundary` with nothing run.

```bash
herdr pane read <pane-id> --source recent-unwrapped --lines 200 | grep -E 'JUNIOR-(DONE|BLOCKED) ' | tail -1
```

| Line | You do |
|---|---|
| `JUNIOR-DONE <id> head=<sha> tests=pass changed=<n>` | step 5 |
| `JUNIOR-DONE … tests=fail` | read the transcript; a follow-up brief (step 6) or take the ticket back |
| `JUNIOR-BLOCKED <id> <why>` | answer it in a follow-up brief, or take the ticket back |
| no line, pane idle | the turn ended without a handback: read the transcript, then one follow-up asking for the line — never assume done |
| `NO_START` / `TIMEOUT` from the watcher | `dispatch-ticket`, *Submitting*: unsent composer first |

## 5. Take the tree back — read the log before you trust it

```bash
git log --format='%h %s%n%(trailers:key=Implemented-by)' <head before>..HEAD
git diff --stat <head before>..HEAD
<the test command from the brief>
```

`git status --short` too: a junior leaves build residue (`__pycache__/`, measured) that is
yours to ignore or clean before the next commit. Every commit carries `Implemented-by:`; a commit without it, a change outside the write-set, an
edited red test, or a touched base branch (`git reflog` shows a checkout) is a boundary break:
take the ticket back, note it in the handback, close the pane. Otherwise continue
`builder.md` from *Increment review* over `<Base>..HEAD` as usual — the junior's commits are
part of the increment.

## 6. Follow-ups — same session, same rules

A review finding to fold, a criterion missed: one more `agent prompt` to the same name with
the same shape (the `head before` line updated), the same wait, the same read-back. Fold by
class; a third round is a signal the brief, not the junior, is the problem.

## 7. Close — yours, at handback

```bash
herdr pane close <pane-id>
```

The pane is yours because you created it; close it before you hand back, so Thomas's cleanup
finds one pane per ticket. A junior pane left open holds no lock, but it is a writer with
access to a worktree about to be removed.

## Handback line

Add to your return to Thomas: `Junior: <runtime>/<model> — <n> commits <first>..<last>` or
`Junior: none`. The log carries the same fact in trailers; the line is so Thomas does not have
to look for it.
