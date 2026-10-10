# Astragentic 3.0.3

**The version chip is on every pane, not only the dispatcher's.** 3.0.2 put `astragentic
<version>` on the dispatcher's band and the board; the owner's ask was every agent. A Builder,
Shaper or QA pane now ends its band with the same dim chip, and a resident pane shows its role
chip and the version. Read once at session start from `.astraler/state/applied-version`.

## Upgrade from 3.0.2

`curl -fsSL https://raw.githubusercontent.com/thientranhung/astragentic/main/get.sh | bash -s -- 3.0.3 --apply`;
panes pick it up at their next start.

# Astragentic 3.0.2

**The applied version is on the band and the board.** An owner running several projects asked
to see at a glance which one is behind. The dispatcher's band carries a dim `astragentic
<version>` chip beside the branch, read from `.astraler/state/applied-version`, and
`/dispatch-board` opens with the same line. Mod only.

## Upgrade from 3.0.1

`curl -fsSL https://raw.githubusercontent.com/thientranhung/astragentic/main/get.sh | bash -s -- 3.0.2 --apply`,
then restart the dispatcher's session.

# Astragentic 3.0.1

**No QA plan, no dispatch.** The owner's rule, stated on 3.0.0's first day and replacing the
payload's default where QA inferred a plan and capped its verdict at CONCERNS: a Builder brief is
not sent until a committed `docs/qa/plan-<slug>.md` covers the ticket. The brief names it on a
`QA plan: <path>` line; the mod refuses a brief whose `QA:` mode is not `none` without one, or
whose path does not exist in the checkout, and a brief with no `QA:` line at all. `test-design`
takes a second input for this: loose tickets with no spec — a gate's follow-ups, small fixes —
planned from each ticket's acceptance criteria and the source it cites, one section per ticket,
`QA: none — <why>` for a ticket with no surface. `qa.md` no longer describes an inferred oracle.

**The claim check reads the Builder's ticket, not any id on the line.** A Shaper brief for
`test-design` whose first line named the tickets it was planning for was refused as "not
claimed" on one of them. The check now applies to `implement` briefs only, on the ticket that
is `implement`'s argument.

Two notes from the first adoption, for projects like it: a `.gitignore` written as an allowlist
swallows a new payload skill directory, and `install.sh --apply` names it under `IGNORED` —
add the allow rule before committing; a project that wired its own marker tooling to the
`rin(gate)` kind re-homes it to `arm(slice)` / `qa(walk)`.

## Upgrade from 3.0.0

`curl -fsSL https://raw.githubusercontent.com/thientranhung/astragentic/main/get.sh | bash -s -- 3.0.1 --apply`
between tickets, then ADAPT. From the next brief on, add `QA plan: docs/qa/plan-<slug>.md`
under the `QA:` line; a brief without it is refused.

# Astragentic 3.0.0

**QA and testing enter the chain of every role, and Rin leaves it.** Four roles — Thomas,
Shaper, Builder, QA — and more measured steps than five had.

## Why the major

Measured on the first adopter over a month: QA's product walk produced 75 findings in 27 walks,
five of them on surfaces the ticket had not touched — the catch no author's check can make — yet
only 4 walks left a mark at merge, the verified-clean list was three weeks stale, and the
reports lived in a temp directory that a reboot empties. Rin's milestone gate, over 20 merged
tickets, produced 15 findings the Builder's three reviews had not, of which 3 changed an outcome;
Rin's spec gate ran 0 times on the last 3 specs while the codex arm at spec scope ran on all 3
and its findings were folded. Test was the most valuable step and the least held; Rin's two jobs
were already being done elsewhere.

## The chain

```
Shaper   align → spec → arm:spec → test-design → tickets
Builder  implement → tdd (+ atdd) → review:matt → review:built-in (+ ux) → simplify → arm
Thomas   handback → QA (walk | probe | verify, by the ticket's surface) → merge → ticket-done
         slice close → arm:slice + adversarial fan-out → release
```

**`test-design` (Shaper, before tickets).** From the finalized spec, Murat's method produces
`docs/qa/plan-<slug>.md`: journeys, endpoints and jobs with risk P0–P3, the mandatory checks per
mode, and each ticket's cases. The cases ride into the ticket's brief. The plan is written
before a line of code, so a later change is walked against what the product was meant to do.

**QA is one plan with three ways to run it**, chosen by the ticket's surface: `walk` for UI
(journeys; numbers agreeing on every screen that shows a concept; deeplinks opening the exact
record; end-of-journey links reaching their target — the owner's three measured production
defect classes, as mandatory checklist items), `probe` for an API or service (contract, status
codes, error paths, permission-denied paths, data after the call), `verify` for a job or
pipeline (it ran, data landed, logs clean, numbers agree with the source). A ticket with no
user-visible surface and no endpoint is not skipped; it gets the mode its surface has. The
report is a trace matrix — plan item → coverage → result — with a verdict PASS / CONCERNS /
FAIL and COVERAGE GAPS, committed under `.scratch/qa/` (a plug may redirect it), never left in
a temp directory. The verified-clean list is rebuilt at every full walk with its SHA.

**Builder gains two optional steps**: `atdd`, red acceptance tests from the ticket's criteria
before implementation (level chosen per stack, never duplicating `tdd`), and for a UI ticket a
read-only `bmad-ux audit` before handback. Both are named with a reason when skipped.

**The station owes QA and says so.** A Builder's brief carries `QA: walk|probe|verify|none —
<why>`; the mod records it, the dispatcher's board shows `qa ○ walk` until a QA pane keyed
`qa:<key>` ends a turn after the Builder's last, and a merge without it carries a red note.
QA panes are recorded under `qa:<key>` so they never overwrite the Builder's entry. The band
on a Shaper pane shows `test-design` and `arm:spec`; on a Builder pane `atdd` and `ux` as
dim optional chips; on a QA pane its mode.

**A wait that cannot end is refused.** Four Builders in a row, two with the brief saying the
rule in so many words, waited on backgrounded work with a loop that never exits: a name-keyed
wait (`until ! pgrep -f <name>` matches its own shell's argv; `until ! ps | grep <name>` matches
a sibling) or a body with no sleep (`do :; done` at full CPU). Each parked the pane for ten
minutes and was found by a person. The mod refuses the shape in any dispatched pane, records the
refusal, and the deny carries the wait that works: `cmd & pid=$!; while kill -0 $pid 2>/dev/null;
do sleep 10; done; wait $pid`. Ten shapes tested, the four measured ones among them; `for`,
`while read`, `while kill -0 … sleep` and a plain `sleep` pass.

**The worktree setup plug keys on the worktree, not the call.** `git worktree add … && herdr
agent start …` in one call exited 1 on the later command with the worktree already created, and
the plug never ran; a Builder found its worktree unseeded mid-ticket. The plug now runs when the
worktree exists at the parsed path, whatever the rest of the call returned.

**Rin is removed.** The spec gate is the arm the Shaper fires over the finalized spec. The
slice gate is Thomas firing the slice arm plus one read-only adversarial fan-out
(`astragentic-dispatch:bmad-reviewer`, distilled from BMAD's adversarial and edge-case
reviewers), folded together on the slice's marker. The gate mechanics that lived in
`review-with-rin` (gate worktree, pane, collection) move to `dispatch-ticket/GATE.md`. The
`rin(gate)` marker kind is gone; `qa(walk)` covers all three QA modes with `Mode:` in its body.

## Upgrade from 2.22.2

1. `curl -fsSL https://raw.githubusercontent.com/thientranhung/astragentic/main/get.sh | bash -s -- 3.0.0 --apply`
   in the project's root, between tickets, then run ADAPT.
2. Delete your `rin` row from `orchestrator.md` and any `rin:` tab label convention; relabel
   nothing else.
3. Write `docs/qa/plan-<slug>.md` for the current spec with `test-design` before the next
   ticket is cut; add `QA: <mode> — <why>` to every Builder brief from now on.
4. Move existing QA reports out of the temp directory into `.scratch/qa/` if you want them
   kept; the next full walk rebuilds the verified-clean list.

# Astragentic 2.22.2

**Every dispatched pane shows its steps, not only the Builder's.** The owner's ask: see on a
Shaper or Rin pane which step it is at, so a dropped step shows as a gap in the order. The mod
records skill calls for every dispatched role and the band renders one step list per role —
Builder: implement · tdd · review:matt · review:built-in · simplify · arm; Shaper: align
(`grill-with-docs`) · spec (`to-spec`) · tickets (`to-tickets`); Rin: review:matt. QA walks the
product and calls no skill, so its band is the role chip. `TURN-END` carries `Skills run:` for
every role. The gates are unchanged: they hold the Builder only.

## Upgrade from 2.22.1

Run the one-liner with `--apply` between tickets; panes pick the mod up at their next start.

# Astragentic 2.22.1

**The READMEs describe installing and upgrading the way it is now done.** Phase 1 of
Installation is the `get.sh` one-liner in the project's root — latest, pinned, `--plan`,
`--apply` — with what `--apply` keeps, merges and lists for Phase 2, and the package-checkout
form named as the same thing fetched by hand. A new **Upgrading** section gives the three
commands (read `applied-version`, `latest --apply`, run ADAPT) and the three things an upgrade
does not do: change a running pane, touch the project's layer, or announce that a newer tag
exists. `install.sh` now keeps the two new version-bearing README lines current along with the
badge and the ADAPT path. Both languages.

## Upgrade from 2.22.0

Nothing in the payload changes.

# Astragentic 2.22.0

**A project pulls its own release.** Until now every install and upgrade ran from the package's
checkout, pointed at the project: a second repository on the machine and a person standing
between the two. `get.sh` at the package root is the one-liner the well-known tools use, run in
the project's root:

```bash
curl -fsSL https://raw.githubusercontent.com/thientranhung/astragentic/main/get.sh | bash
curl -fsSL https://raw.githubusercontent.com/thientranhung/astragentic/main/get.sh | bash -s -- 2.22.0 --apply
```

It resolves `latest` from the remote's release tags (or takes a pinned version), clones that tag
into `~/.cache/astragentic/<version>/`, refuses a cache whose `VERSION` disagrees, and runs
**that release's own** `install.sh` against the current directory — so staging, the three-way
arbitration and the hook merge are the ones the release shipped with, never a newer installer
reading an older payload. By default it stages only and prints the ADAPT instruction; `--apply`
and `--plan` pass through. `ASTRAGENTIC_REPO` and `ASTRAGENTIC_CACHE` override the source and
the cache. Verified: a fresh clone from GitHub of the latest tag stages; a pinned `--apply`
stamps `applied-version`; an unknown tag is refused. Both READMEs' Quickstart start with it.

## Upgrade from 2.21.6

Nothing in the payload changes. From this release on, upgrade from inside the project with the
one-liner above; the package checkout is no longer needed on the project's machine.

# Astragentic 2.21.6

**2.21.5's merge did not read the previous release, so it merged what it should only have
reported.** The path to the prior release's `settings.json` was joined with a second `harness/`
segment, the file was never found, and an event the previous release shipped and the project had
removed was merged back in. 2.21.5's notes claimed the opposite; the plant that would have shown
it was read wrongly. The path is fixed and the plant now shows the split: a previously shipped
event stays an `ACTION`, the two events and the guard script the project never had are merged.

## Upgrade from 2.21.5

Nothing in the payload changes; use this package's `install.sh` for the next apply.

# Astragentic 2.21.5

**`install.sh --apply` merges the hooks a project has never had.** On a greenfield install Claude
Code had already written `.claude/settings.json` (permissions), so the installer read the file
as owner-kept, reported all four hook events and three hook scripts missing, and the adapting
agent handed the owner the merge as a to-do: *copy the entries from the release*. Until it is
done, no guard, no contract re-arm, no tracker status, no worktree release fires, and nothing
says so again.

The rule that decides what the installer may touch: an event, or a hook script under an event,
that is absent from the project's file **and** from the previously applied release (or there is
no previous release) cannot be the owner's deliberate removal — the project never received it.
Those are merged additively, every owner key and every existing hook entry untouched, and each
addition is named under `MERGED`. What a previous release did ship and the project lacks may be
a removal, so it stays an `ACTION` for ADAPT-HARNESS §4's reader, who now must decide it and do
it rather than hand it back. Verified: a file with permissions, `enabledPlugins` and one custom
PreToolUse hook gains the three events and the guard script, keeps everything of its own, and a
second apply changes nothing; a planted "previous release had it, project does not" case is
reported, not merged.

## Upgrade from 2.21.4

Run `./install.sh <target> --apply` from this package once more; it merges what the earlier
apply only reported. Nothing in the payload changes.

# Astragentic 2.21.4

**The tdd gate judges commits in the Builder's worktree, not every commit the Builder makes.**
The first recorded refusal (2.21.2 did its job) was a fixture commit in a throwaway clone under
`/tmp`: a Builder building a RED mutation fixture for a planner selftest, twelve seconds before
it ran `tdd` on its own. No harm, wrong reason. The gate now follows `cd` across the call's
segments and `-C` on the command, and refuses only a content commit whose place resolves inside
the pane's recorded worktree. A place it cannot read — `cd $X`, `-C "$D"`, `~` — is gated, so
a variable is not a way around it; only a commit at a readable path outside the worktree is
let through. Ten shapes tested, the measured one among them.

## Upgrade from 2.21.3

Copy `harness/.claude/skills/astragentic-dispatch/`, or run `./install.sh <target> --apply`.

# Astragentic 2.21.3

**The worktree-add trigger matched `git worktree list`.** Measured on the 2.21.2 apply turn: a
Bash call holding `git worktree list | grep -c …` was read as a `worktree add`, the path parse
fell through to the first word, and the result carried *setup-worktree.sh FAILED … do not
dispatch into it* for a worktree named `git`. Harmless there; on a dispatch turn a false "do not
dispatch" would stop a correct one. The trigger now requires the word `add` immediately after
`worktree`, the parse stops when it finds no `add`, and the plug runs only for a path that
exists. Five shapes tested, including the one measured.

## Upgrade from 2.21.2

Copy `harness/.claude/skills/astragentic-dispatch/`, or run `./install.sh <target> --apply`.

# Astragentic 2.21.2

**Three things the first ticket under the gates measured.**

**A refusal leaves a trace.** The first gated lane could say its steps ended up in order, not
whether a gate had fired: the record carried skill times and no refusal events. Each refusal
(`tdd-gate`, `arm-gate`) is now appended to the pane's record entry under `refusals` with its
time and what was refused, written to `/tmp/harness-hook-events.log`, and shown as a red chip
on the Builder's band for two minutes.

**The reap no longer kills its own chain.** `git worktree remove` run from a Bash whose
persisted cwd was inside that worktree made `reap-worktree-processes.sh` find its own parent
rooted there and kill it; the removal was refused and succeeded only from the repo root. The
script walks its own ppid chain to init before matching and skips every pid on it, with a
`SKIP … own process chain` line. Verified: run from inside a throwaway worktree with a
background process rooted there, the chain is skipped and the process is reaped, exit 0.

**Several `TURN-END`s per ticket is correct**, and `dispatch-ticket-claude` says so: a Builder
parks while its review sub-agents and the arm run, then resumes; eight bells for one ticket
were each a true turn end, `Skills run:` growing across them. Read the last one.

## Upgrade from 2.21.1

Copy `harness/.claude/skills/astragentic-dispatch/`, `harness/scripts/reap-worktree-processes.sh`
and `dispatch-ticket-claude/SKILL.md`, or run `./install.sh <target> --apply`.

# Astragentic 2.21.1

**The bands are pills.** A terminal has no CSS; what it has is a Text with a background, so each
fact on a band is one chip. In a Builder pane: the role and ticket in the Claude colour, then one
chip per flow step — green `✓` for a step that ran, yellow `▶` for the step in progress, grey
`n/a` for one the brief exempted, dim `○` for the rest. In the dispatcher's session: the branch
chip, one chip per live dispatch coloured by state (working green, sent yellow, ended grey, an
alarm red), and the project's status line dim at the end. Red stays reserved for what needs a
person.

**Registration is a toast, not a status line.** *dispatched builder TRA-123 — recorded tab …,
pane …* sat in the status line for the life of the pane; it is a one-time fact, and the band's
first chip carries the role and key. It is now a toast at session start. The status line keeps
only errors (an unreadable record, an undelivered turn end).

## Upgrade from 2.21.0

Copy `harness/.claude/skills/astragentic-dispatch/`, or run `./install.sh <target> --apply`. A
session with hot reload on takes it live; others at their next start.

# Astragentic 2.21.0

**Two steps of the Builder flow are refused, not noted.** The first two real dispatches after
the `FLOW:` line shipped measured the line's limit: one Builder skipped `tdd`, the other the
built-in `code-review`, neither named n/a, and the merge note made each visible only after the
fact. So the Builder's pane now refuses the first content commit until
`mattpocock-skills:tdd` is in its record, and the arm (`codex-arm`, `codex-claude-arm`) until
the built-in `code-review` is. Empty commits (markers) pass. The exemption is the dispatcher's
and travels in the brief — a line `TDD: n/a — <why>` or `REVIEW: n/a — <why>` — read from the
brief the mod delivers, never from the Builder's handback; a steering message cannot change it
and a fenced example cannot grant it. The commit gate reads every simple command in the call,
heredoc bodies included, with `-c`/`-C` options skipped and `--allow-empty` honoured only as a
whole word on that same command; twelve bypass shapes from the Codex gate are each refused.

**The Builder's band shows the step it is at.** Above the prompt in a Builder pane:
`flow TRA-123: ✓ implement · ✓ tdd · ○ review:matt · ○ review:built-in · ○ simplify · ○ arm`,
from the same record the gates read, `n/a` where the brief exempted a step. The owner's ask:
a person watching the pane sees the step without reading the transcript.

**A turn end with no address is still recorded.** A gate pane in auto mode ended its turn and
nothing reached the dispatcher: its brief had been typed in by hand, so the mod never learned
whom to tell. The record is written whenever there is no address, and the dispatcher's poll
wakes from it.

**Two worktree asks from the first adopter.** `.astraler/project/setup-worktree.sh <path>` runs
right after a successful `git worktree add` (quoted paths and `-C` honoured; a failure is named
in the result and the worktree is not to be dispatched into), mirroring the release plug at
removal. `git worktree remove /p; …` no longer blames the path: an unquoted token loses the
operator glued to it, a quoted one is taken as written, and the refusal says to run it as the
only command in the call.

Two bare names in the payload that meant Matt's review now say `mattpocock-skills:code-review`.
Measured on this machine: the Skill tool resolves bare `code-review` to Claude Code's built-in,
so 1.3.1's `implement`, which calls the bare word, never reaches Matt's review; the `FLOW:` line
names both.

## Upgrade from 2.20.5

Copy `harness/`, or run `./install.sh <target> --apply`. The mod, `builder.md`,
`builder-claude.md`, `.claude/agents/builder.md` and `dispatch-ticket-claude` change. Running
panes pick the mod up at their next session start. Add `TDD: n/a — <why>` to a brief for a
docs-only ticket, or the first commit is refused.

# Astragentic 2.20.5

**A blocked turn end is red on both screens.** 2.20.4 carried an undelivered `TURN-END` through
the record; the owner asked why the pane does not simply say so in red and let a person fix the
mode. A mod cannot read its session's permission mode, but it does see the send fail and why,
so now: the dispatched pane shows a red line above its prompt, *TURN-END not delivered … press
shift+tab until this pane is in bypass-permissions mode*, until a later send lands; and the
dispatcher's band turns red with *turn end read from record: its message was blocked, check
that pane mode*. The record path stays, so the wake does not depend on anyone looking.

## Upgrade from 2.20.4

Copy `harness/.claude/skills/astragentic-dispatch/`, or run `./install.sh <target> --apply`.
Running panes pick it up at their next session start.

# Astragentic 2.20.4

**A turn end the pane cannot send still reaches the dispatcher, from the record, within 30 s.**
First measured defect of the first real 2.20 dispatch: a Shaper pane toggled into auto mode had
its `TURN-END` SendMessage classified with no verdict, the pane's footer said so, and nothing
reached the dispatcher — the owner noticed ten minutes later. The message path can be closed by
things outside the mod (permission mode, a held cross-session delivery), so the record is now
the second path: a pane whose send fails writes the turn end into its own record entry, and the
dispatcher's mod, which already reads the record every 30 s, submits the same wake prompt from
there, once, marked *read from the record*. A real `TURN-END` arriving later clears the entry.
`dispatch-ticket-claude` says not to toggle a dispatched pane's permission mode.

## Upgrade from 2.20.3

Copy `harness/.claude/skills/astragentic-dispatch/` and `dispatch-ticket-claude/SKILL.md`, or
run `./install.sh <target> --apply`. Panes already running keep the old mod until their next
session start.

# Astragentic 2.20.3

**The package no longer ships what its own git ignores.** When a session loads the dispatch mod,
the engine writes `.claude-plugin/types/` beside it with its own `.gitignore`; `cp -R` staged
those five files anyway, and the 2.20.2 adopter's installer reported them as "ignored by your
project" — ignored by the release's own rule, never meant to ship. Staging now removes every
path the package's git lists as ignored under the payload, which is the general form of the
`.opencode` residue rule 2.7.x wrote by hand. Verified: a fresh stage carries `plugin.json`
alone under `.claude-plugin/`, and `--apply` on a fresh target names no ignored path.

## Upgrade from 2.20.2

Nothing to apply; the change is in `install.sh`. A project that took 2.20.2 may delete
`.claude/skills/astragentic-dispatch/.claude-plugin/types/` if the apply wrote it.

# Astragentic 2.20.2

**2.20.1's installer died after its summary, before the stamp. Do not apply 2.20.1.** The
ignored-paths check added there ran `git check-ignore` inside a command substitution under
`set -e`; check-ignore answers 1 for every path that is not ignored, which is the normal case,
so `--apply` exited 1 after printing `new … · updated …` and never wrote `applied-version`. The
payload was fine; only `install.sh` was broken. Selftest passed it because its apply case read
the output strings and never the exit status; it now requires exit 0 and the stamp, and that
case fails on 2.20.1's installer.

## Upgrade from 2.20.0 or 2.20.1

Run `./install.sh <target> --apply` from this package (the installer is the package's own).
A 2.20.1 apply that was attempted left the files in place and the stamp unwritten; re-running
from 2.20.2 writes nothing new and stamps.

# Astragentic 2.20.1

**Two findings from the 2.20.0 adoption, one of them a claim 2.20.0 made and did not keep.**

**Reachability check 9 now reads the dispatch mod as an execution surface.** `ledger-rules.py`
is called from the mod's `register.tsx` and from nothing else, so on a pristine payload check 9
reported it an orphan; before the project restored its payload files, a substring in project
prose had hidden that. The mod's hooks modules join the execution surfaces, with `//` comment
lines dropped the way `#` lines are. `selftest.sh` is declared package-only: `install.sh` runs
it as the staging gate, no project calls it, and in a project it is not under test. 2.20.0's
upgrade message to the first adopter said this was in; it was not, and the adopter's own check
caught it.

**`install.sh --apply` names NEW payload paths the project's `.gitignore` swallows.** A new
skill written under an ignore rule with per-name exceptions is on disk, uncommitted and absent
from every worktree, and nothing said so until `check-requirements.sh` ran after the merge.
The apply summary now lists each such path with the allow rule to add. Verified by planting an
`.agents/skills/*` rule: both new skills named.

## Upgrade from 2.20.0

Copy `harness/scripts/check-reachability.sh`; `install.sh` is the package's own and needs no
copy. Or run `./install.sh <target> --apply`.

# Astragentic 2.20.0

**The first project to reach drift zero handed back two months of measured fixes, and this
release takes them.** After 2.19.1 the downstream project moved its own rules into overlays
and restored thirteen payload files byte for byte; what remained on its drift manifest was
five scripts it had fixed and could not stop fixing, and five rules it had nowhere to put. Both
halves land here, so that project's manifest can reach zero and the next project does not
re-buy the same defects.

## Six plug points in `.astraler/project/`

A payload script asks the project a question and the project answers in a file no release
overwrites. New in 2.20.0:

| Plug | Read by | What the project puts there |
|---|---|---|
| `marker-kinds.json` | `check-simplify-markers.sh` | extra required fields or flags per marker kind, merged per field as a union: a project can tighten a kind, never loosen it |
| `marker-output-check.sh <sha> <subject> <path>` | same | the project's rule for an `Output:` path (directory, naming, non-empty); exit 0 passes, anything else stops quoting the reason; absent while a kind needs it is a STOP |
| `marker-evidence-paths.txt` | same | globs whose changes alone do not break the covers-head rule (an arm log committed after the marker) |
| `watchdog-probe.sh` | `herdr-watchdog.sh` | run every poll, printing `TYPE\|key\|details` lines that become alerts through the watchdog's own path; a failing probe is one WARN, never silence |
| `role-budgets.txt` | `docs-staleness-audit.sh` | `role words reason` lines raising a contract's word budget for the project's additions; the source of the budget prints on the line |
| `status-line.sh` | the dispatch mod | one line for the band above the prompt: tracker counts, who holds the gate token, whatever the project measured it needs on screen |

## The marker gate, rewritten from 560 merges of evidence

`check-simplify-markers.sh` grows from four rules to nine, each one closing a shape the
downstream project measured: cadence numbers are labelled (an unlabelled `origin/main~60` was
reported as a 60-merge backlog; it was 9); fields are read from per-paragraph field runs, so
wrapped prose no longer reads as a field (three Builders stopped on it); a field pushed out of
its run by a wrap is reported as that, not as absent; `Supersedes:` is validated on every kind
(three fabricated values passed green on one branch, a 560-merge sweep found five historical
fabrications and no false positives); the chain resolves regardless of `economy`; the
covers-head rule compares trees, not commit counts (an empty arm commit refused a merge);
`Reviewed:` must be reachable even under `Unreviewed-delta:` (20 of 80 were not); `Range:`
endpoints must be reachable (22 of 77 were stranded); and the covers-head STOP names the fold
re-run (four refusals across three Builders in one shift, all following the documented loop).
The field parser ships at `scripts/lib/marker_field_parser.py`, resolved from the script's own
path. Verified by planting eleven defects, each named.

**The covers-head STOP that six Builders hit is gone, and the STOP that remains has one
answer.** Under the old rule a call naming both `simplify(increment)` and `arm(ticket)` could
never pass, because the receipt is always the later commit. Rule 5 now compares trees, so the
empty receipt leaves simplify covered. A content-bearing commit above a marker still stops the
merge, and `MARKERS.md` now says the only answers: the fold re-run and a fresh marker, or a
committed arm log declared in `marker-evidence-paths.txt`. Never an explanation. `rin(gate)`
and `qa(walk)` markers stack and are exempt from the head check.

## The watcher, the guard, the audit

The watcher touches a heartbeat every iteration and the watchdog reads a heartbeat under 300 s
as a second liveness probe after `pgrep`: two false `WATCHER_LOST` in twenty minutes were a
`pgrep` match failing on a live watcher. `hook-git-guard.py` blanks quoted spans before deciding
readability, keeping `$(` and backticks inside double quotes unreadable: 20 of 126 base pushes
had gone unjudged, 13 of them for a `(` inside an echo string, and one unstamped merge reached
the base. Selftest carries one case each way.

## The band, residents, and the picker

**The dispatcher's band is always on**: `⎇ <branch> · dispatch: … · <status-line.sh>`. The
tracker table had been injected into context at session start and shown nowhere; the branch
was asked for by hand; two gate runs collided while nobody could see who held the token.
**A tab labelled `resident:<name>`** is recorded, shown on the board and refused a close —
resident panes were the ones with the most context to lose and the only ones a wrong close
could not be refused. **`AskUserQuestion` is refused in a dispatched pane**: no human is there,
and a picker blocked turns after the contract had banned it in prose.

## Prose that the measurements changed

`codex-arm` defines the log it tees to (both `$OUT` and the `tee` were used undefined; four
logs lost) and runs one way, `--background` with short foreground polls, where it had said both
bell and poll (~47 minutes lost on a job dead for ~44). `codex-claude-arm` captures `claude -p`
output into a tracked file. `MARKERS.md` carries the meaning of `Tests:` (two Builders read it
opposite ways). `builder.md`: a fork is a source, never a gate (41 minutes parked on fork
pings); the fold re-run is a named step. `thomas.md`: fetch and prove the base before cutting a
worktree (three Builders branched 29 commits behind); a merge-mechanics list in
`dispatch-ticket` (never background merge+gate, never read status through a pipe, pin the SHA,
`--diff-filter=U` empty, frozen means the tree, never merge on an explained-away failure); the
watchdog lock is a hint, not a census (two watchdogs alive at 8h57m and 7d11h); the cleanup
line matches the mod. `dispatch-ticket`: `ctx %` as the delivery receipt, first-arm versus
re-arm `start_max_s`, a read-only fork's brief forbids the act, the `ADDRESSED TO:` line, and
one answer on how a brief travels per runtime.

`check-reachability.sh` learns that a shipped mod's `agents/*.md` are resolvable names, and
`check-requirements.sh` stops reading a script's closing prose as a cannot-run verdict.

## Upgrade from 2.19.1

1. Copy `harness/`, or run `./install.sh <target> --apply`. Six scripts, the mod, two role
   contracts and five skill files change; `scripts/lib/` is new.
2. If the project carried its own fixes to `check-simplify-markers.sh`, `herdr-watchdog.sh`,
   `herdr-watch-terminal.sh` or `hook-git-guard.py`, take the payload copies and express what
   was project-specific in the plugs above. The drift manifest should reach zero.
3. Label resident panes `resident:<name>` before their next launch; write `status-line.sh`
   if the band should carry more than branch and dispatches.

# Astragentic 2.19.1

**Two findings from the first 2.19.0 adoption, both carried upstream rather than patched again
downstream.**

**`check-requirements.sh` read a script's prose as its verdict, backwards.** The liveness check
runs four payload scripts and searched their whole output for `cannot`; `check-reachability.sh`'s
closing paragraph says *"what check 10 still cannot do"*, so a green run was reported as "does
not run in this project's layout" and a run with real findings, which exits before that
paragraph, read as healthy. The downstream project fixed it on 2026-09-21 and carried the fix
through three upgrades as a drift entry. The match is now anchored to the first 40 characters of
a line, where a genuine cannot-operate message sits and prose never does. Verified on three
outputs: green reachability with the paragraph → no trigger; a stub printing `cannot find role
contracts` → MISS quoting that line; a stale-index STOP → MISS.

**`core.hooksPath` is now checked live, not just resolved.** It is machine-local config that
replaces `.git/hooks` entirely; set and pointing at a missing directory or non-executable files,
every git hook is dead silently. The check reports a missing directory and names each
non-executable file. The pre-push wiring check is unchanged.

## Upgrade from 2.19.0

Copy `check-requirements.sh` (it lands at `scripts/check-requirements.sh` in an adapted
project), or run `./install.sh <target> --apply`. A project carrying its own fix of the first
finding can drop that drift entry.

# Astragentic 2.19.0

**The BMAD role kit moves into the payload, as advisers with a fixed seat.** `docs/bmad-distilled/`
has been a kit the owner pasted into a prompt by hand. Six of its roles now ship as agents of the
dispatch plugin — `astragentic-dispatch:bmad-mary`, `bmad-john`, `bmad-sally`, `bmad-winston`,
`bmad-murat`, `bmad-paige` — rewritten rather than copied: Winston and Murat speak the method's
own vocabulary (module, interface, depth, seam, "the interface is the test surface"), every
persona advises and never writes, commits, arms, merges or messages anyone but its caller, and
every capability that duplicates a Matt Pocock skill is cut (Amelia, the BMB builder, John's
epics, Winston's spec, retrospective). Measured 2026-10-09 on Claude Code 2.1.294: a plugin's
`agents/*.md` declare subagent types the Agent tool can spawn, and the persona's system prompt
reaches the spawned agent.

Two skills reach them.

**`bmad-party <topic>`, owner-invoked.** Spawns the cast as a **team of peer agents**, not
subagents: each persona is one named teammate kept for the whole party, so a voice remembers the
round before and holds its position. The host session runs rounds over SendMessage and weaves
the replies into one conversation in the personas' own words, does not mediate, and pulls the
owner in. It ends when the owner says so, and every teammate is stopped by name. It produces
positions, never artifacts: a conclusion that should become work goes through the Shaper.

**`bmad-ux audit|polish|upgrade <surface>`.** Sally's pass on one surface against the project's
`DESIGN.md` and `EXPERIENCE.md` spines, rendered rather than read from a diff. In the session as
a lens, or fanned out read-only in a worktree from a Builder or QA mid-ticket. Findings with the
evidence each rests on; never a verdict, never a change. QA's contract names it for a surface
that reads wrong when the guidelines do not say why.

**Two rules keep them from competing with the method.** Every name carries the `bmad-` prefix and
is called in full, so no word resolves to two skills (the `code-review` lesson). And no persona
replaces a step of the Builder flow or runs `to-spec`, `to-tickets`, `retro` or `research`
itself: when its advice needs one, it names the skill and hands back. The mod's `skills_run`
record shows which personas are called; one that is never called is dropped in a later release.

## Upgrade from 2.18.1

Copy `harness/`, or run `./install.sh <target> --apply`. The plugin gains `agents/`, the payload
gains two skills, and `qa.md` gains one Load row. Nothing to wire; `/bmad-party` and `/bmad-ux`
are available in the next session.

# Astragentic 2.18.1

**The ledger index was stale in 2.18.0, and staging refuses a stale index.** 2.18.0 repointed
two `Bound:` lines in the ledger and did not regenerate `INDEX.md`; `install.sh` runs
`ledger-index.sh --check` at staging and stopped on it. The index is regenerated here. Nothing
else in the payload changes.

**The plugin floor is reachable now.** The `claude-plugins-official` marketplace pins
`mattpocock-skills` at 1.2.3 by commit and reports it as latest, so the 1.3.1 floor 2.17.0 set
could not be met from the marketplace the docs named. The install step now points at Matt's own
marketplace: `claude plugin marketplace add mattpocock/skills`, then
`claude plugin install mattpocock-skills@mattpocock`, and uninstall the official copy so one
name does not resolve to two plugins. The plugin name and the `mattpocock-skills:` prefix are
unchanged. Measured 2026-10-09: with 1.3.1 installed, every reachability check passes and
selftest is clean.

## Upgrade from 2.18.0

Copy `harness/.agents/memory/INDEX.md`, or run `./install.sh <target> --apply`. Install the
plugin as above if `check-requirements.sh` reports the floor unmet.

# Astragentic 2.18.0

**The Builder flow is read from what ran, not from what the handback says ran.** Measured
downstream on 44 Builder transcripts: `implement` ran 44/44, `tdd` 0/44, Matt's `code-review`
6/44. `implement` points at both skills in prose, and a Builder with no keyboard read the
pointers as prose. On plugin 1.3.1 the pointer is the bare word `code-review`, which Matt's
skill and Claude Code's built-in both answer to, so one of the two reviews never runs either
way.

Two changes close it, one on each side of the brief.

**The brief carries a `FLOW:` line** of qualified Skill names, in order: `mattpocock-skills:tdd`
→ `mattpocock-skills:code-review` → built-in `code-review` → `simplify` → `arm(ticket)`. A step
that cannot apply is named in the handback with its reason (`TDD: n/a — <why>`). `builder.md`'s
phase table and loop name the same order; `builder-claude.md` carries the built-in review's
invocation; the Codex and OpenCode supplements record it SKIPPED, as `simplify` already is.

**The dispatch mod records every Skill call the Builder's pane makes**, at the moment the
engine expands the skill (`skill.prompt`). Measured 2026-10-09 on Claude Code 2.1.294: a plugin
skill arrives qualified, a built-in bare, so the two reviews that share a word are told apart.
`TURN-END` carries `Skills run: …`, and a merge names the steps with no record in its result:
*"ABC-123 merged with no record of: tdd, built-in code-review"*. A note, not a refusal, because
the mod cannot read a handback's `n/a` reason. Only a pane the mod registered is judged; a Codex
or OpenCode Builder keeps the marker script as its evidence. This is the first step away from
the `Pass:` line, which anyone can type, as the proof a pass ran.

**The shared dispatch protocol now says what the mod already does.** Three sections of
`dispatch-ticket` described steps by hand that the mod had taken over in 2.14 and 2.15 — the
dispatch record, the payload-committed check, the per-turn watch — with no word that it had.
Each now opens with what the mod does on a Claude root and what stays yours there, and keeps the
manual form for Codex and OpenCode. The workspace watchdog stays a gate on every runtime: it
covers the one thing a pane cannot report, its own death.

**The project gets a place for its own rules that no release overwrites.** A downstream
project counted 64 payload files it had edited in place and had to re-apply after every
upgrade, with a drift script that could only report the loss. `.astraler/project/overlays/`
closes that: `overlays/<role>.md` is appended to the role's system prompt by the dispatch mod,
on every render and through compaction, and `overlays/dispatch-brief.md` is appended to every
brief the mod sends. Measured 2026-10-09 on Claude Code 2.1.294: a `prompt.compose` section
added by the mod was read by the model on the first turn. The dispatcher's own session reads
`overlays/thomas.md`. An overlay adds to the contract and never contradicts it; the shape is in
ADAPT-HARNESS §3. The plugs already in that directory are unchanged.

**The launcher takes an advisor.** `orchestrator.md`'s Active assignments table has an
`Advisor` column, Claude only, carried as `--advisor <value>` on the launch line when set. The
default pairs the two Sonnet roles, Builder and QA, with `opus`, and the three Opus roles
with `fable`, the only model that ranks above them. Fable bills to usage credits and needs the
owner's one-time consent (`/model fable`); until it is given, a `fable` row launches without an
advisor and says so.
The Builder supplement says when to consult it. Not yet measured through `herdr agent start`;
the first launch is the measurement.

Smaller: `builder.md` no longer restates `code-review`'s two axes and its fallback, which 1.3.1's
skill carries itself. Two ledger entries asserted a live `Bound:` to an `AGENTS.md` that is gone;
both now say so, and reachability check 10 is clean. Claude Code floor moves to **2.1.294**, the
build `skill.prompt` was measured on.

## Upgrade from 2.17.0

1. Claude Code 2.1.294 or later, plugin 1.3.1 or later.
2. Copy `harness/`, or run `./install.sh <target> --apply`. The mod, `dispatch-ticket`,
   `dispatch-ticket-claude` and the four Builder files change.
3. Add the `FLOW:` line to the next brief; `dispatch-ticket` § "The brief carries the build flow"
   has the form.
4. `orchestrator.md` is scaffold and is never overwritten: add the `Advisor` column to your
   Active assignments table by hand (ADAPT §4 has the defaults). While the table exists without
   the column the mod refuses every brief; a table it cannot find is `check-requirements.sh`'s
   MISS, not the mod's. A blank cell is a row with no advisor.
5. Move the project's own rules out of payload files into `.astraler/project/overlays/`
   (`builder.md`, `thomas.md`, `dispatch-brief.md`, …), then re-apply the payload clean. The
   drift manifest should come out empty. Overlays reach Claude sessions only: a role whose row
   runs on Codex or opencode reads none, so a project with such a row keeps that role's rules
   where that runtime reads them.

# Astragentic 2.17.0

**`mattpocock-skills` 1.3 renamed the glossary, and a harness on the old name writes a file
nobody reads.** 1.3 renamed `CONTEXT.md` to `GLOSSARY.md` and `CONTEXT-MAP.md` to
`GLOSSARY-MAP.md`. Every plugin skill that reads it looks for the new names only. So
`bootstrap-glossary` kept seeding a `CONTEXT.md` that `domain-modeling`, `grill-with-docs`,
`tdd` and the rest no longer opened, and nothing reported it. The skill now writes `GLOSSARY.md`,
follows `GLOSSARY-FORMAT.md`, and keeps its review state in `docs/agents/GLOSSARY-review.md`.
The contracts, the reachability registry and ADAPT-HARNESS follow the same names. The format
itself did not change.

The plugin floor moves to **1.3.1**. The rename has no compatible middle: a harness writing
`GLOSSARY.md` on 1.2.3 is as unread as the reverse. `check-requirements.sh` and
ADAPT-HARNESS §2 now refuse anything older.

1.3 also deleted `resolving-merge-conflicts`. The Builder contract routed a drifted branch to
it. That row is gone, and the Builder resolves the conflict itself. The note warning that
`implement` names its sub-skills in slash form is gone too, because 1.3's `implement` calls them
through the Skill tool. Check 4's fallback list drops the deleted skill and adds the three new
ones: `implement-spec`, `pr` and `retro`.

The README Quickstart had drifted to 2.16.1 (English) and 2.13.0 (Vietnamese). `install.sh`
already rewrites the version badge and the Quickstart path from `VERSION`, but only in
`README.md`. The Vietnamese README was never in that loop. Both are now.

## Upgrade from 2.16.2

1. Update the plugin to 1.3.1 or later before applying: `claude plugin marketplace update
   claude-plugins-official`, then `claude plugin update mattpocock-skills@claude-plugins-official`,
   then restart.
2. Copy `harness/`, or run `./install.sh <target> --apply`.
3. Move the glossary in **one commit, with no ticket in flight**: `git mv CONTEXT.md GLOSSARY.md`,
   plus `CONTEXT-MAP.md` → `GLOSSARY-MAP.md`, any per-context `CONTEXT.md` and
   `docs/agents/CONTEXT-review.md` → `docs/agents/GLOSSARY-review.md`. In the same commit, replace
   the old names in `docs/agents/domain.md` and in the `## Agent skills` block of `AGENTS.md` or
   `CLAUDE.md`. A worktree cut before this commit lands creates an empty `GLOSSARY.md` beside the
   old file.

# Astragentic 2.16.2

**The dispatch mod refused text that only quoted a command.** Reported by the reviewer of the
first adoption: Thomas wrote a ledger entry with `cat > … <<'EOF'`, and its body quoted
`git worktree remove $(pwd)/$W` while describing the incident 2.16.1 fixed. It was refused as if
it were that removal. The reviewer found the same weakness in the close guard: a heredoc or
quoted sentence naming `herdr tab close <id>` for a mid-turn pane would refuse a harmless write.
The better an incident is written up, the likelier the write-up is blocked.

The mod now drops heredoc bodies and matches each rule (close, remove, merge) only where a
command can start: at the start of a line, or after `;`, `&`, `|` or `(`. Never inside a
sentence. The failure direction of every rule is unchanged: an unreadable worktree path is still
refused. Checked on seven command shapes. Real variable and literal removals, a close after
`&&` and a close after a heredoc are still caught. A heredoc body and an `echo` sentence quoting
either command are not.

The mod also now states in code that its literal-path check is skipped when
`git worktree list` itself fails. That is a chosen fail-open for a git that cannot list.

## Upgrade from 2.16.1

Copy `harness/`, or run `./install.sh <target> --apply`. Only the mod changes.

# Astragentic 2.16.1

**The mid-turn worktree protection was bypassed by an ordinary command.** Reported by the
reviewer of the first adoption, from a command Thomas actually typed:
`git worktree remove $(pwd)/$W`. The dispatch mod reads the command before the shell expands
it, so it saw the literal `$(pwd)/$W`, matched no record, and skipped every protection inside
that match. That included the refusal to remove a worktree whose agent is mid-turn, which is
the destroy-live-work case the record exists to stop. On a destructive operation that cannot
be undone, "cannot read it" had meant "allow". There is no pre-worktree-remove git hook to move
this to, so the direction of failure changes instead. A path holding `$`, a backtick or `~`,
or one that does not resolve to a worktree `git worktree list` knows, is refused with "pass the
worktree as a literal path". Measured in a lab: the variable form refused, a non-worktree path
refused, the literal path removed the worktree. The reviewer also traced that auto-release had
likely never fired on that project for the same reason.

ADAPT-HARNESS §6 gains two traps found wiring the 2.16.0 pre-push gate beside an existing one.
Git sends the ref list on stdin once, so chained gates must share one read. An absolute
`core.hooksPath` pointing at main makes every worktree run main's hooks.

## Upgrade from 2.16.0

Copy `harness/`, or run `./install.sh <target> --apply`. The mod and `dispatch-ticket-claude`
change. Remove worktrees by literal path from now on; a variable path is refused.

# Astragentic 2.16.0

**The push gate moves into git.** The rule is unchanged: a push that lands a ticket's merge on the
base branch needs that ticket's ticket-done stamp. It used to live only in `hook-git-guard.py`,
which reads the command line a session is about to run and declares itself a lint, silent on any
line holding a heredoc, a `$(...)` or a `( ... )`. The reviewer of the first 2.15 adoption measured
that on one day's log: **84 of 319 commands (26%) went unread**, and the one push the rule existed
for went out inside a heredoc. A ticket's merge reached `origin/main` about a minute before its
stamp existed. The reviewer proved the mechanism with a command the guard must always refuse:
`git add -A` behind a `$(...)` passed.

`scripts/pre-push-ticket-done.sh` is now the gate. It runs as git's pre-push hook, reads the exact
refs git is about to push, and refuses unstamped ticket merges on the base. It does so however
the command was written, from any runtime, and when a person pushes too. Bypassing it takes
`git push --no-verify`, a deliberate act. The guard keeps the rule as an early reminder, and its
docstring now carries the 26% figure: "lint" here means one command in four unseen.

- `check-requirements.sh --adapted` resolves the hooks directory git actually reads
  (`core.hooksPath` first) and reports MISS until `pre-push` calls the script.
- ADAPT-HARNESS §6 adds the wiring step: chain into an existing pre-push, and prove a refusal.
- Selftest pushes to a real bare remote: refused unstamped, refused in the guard-blind `$(...)`
  shape, admitted once stamped.

**Wording:** `install.sh`'s conflict exit now says plainly that recording each decision,
stamping by hand and deleting `apply-incomplete` is the normal way out of any reconciled upgrade.
A reconciled file differs from both releases, so a re-run reports the same CONFLICT for ever.
The old wording read as an escape for the unusual case. Raised by the same reviewer.

## Upgrade from 2.15.10

Copy `harness/`, or run `./install.sh <target> --apply`, then **wire the pre-push hook**
(ADAPT-HARNESS §6). Until it is wired, `check-requirements --adapted` is red and the push gate is
only the guard's lint.

# Astragentic 2.15.10

From the reviewer of the first 2.15 adoption.

- **Ticket-done and release stamps lived in `/tmp`, and a reboot erased them.** The push guard
  refuses a merge of the base whose ticket has no stamp, so after every restart a ticket that
  had finished properly read as unfinished. Measured downstream: 0 stamps after a reboot that
  noon. Stamps now live in the repository's git common dir, `<git-common-dir>/astraler-stamps/`,
  which survives a reboot, is shared by every worktree, and is never committed.
  `ticket-done.sh`, `release-worktree-resources.sh`, `hook-git-guard.py` and the dispatch mod
  all resolve the same default, and `HARNESS_STAMP_ROOT` still overrides it. Selftest runs the
  writer and the push guard with no override and requires them to agree.
- **An unreadable dispatch record now says so.** The 2.15.9 watchdog exemption read the record
  and, on any read failure, silently fell back to "no pane reports itself", so every Claude pane
  drew `WATCHER_LOST` with no reason given. A record that exists but cannot be parsed now sends
  one `RECORD_UNREADABLE` alert naming the file.

Not changed, by design: `ticket-done.sh` still does not close the tracker. It verifies a close
that someone else made, and a verifier that performs the act it checks can no longer fail.

## Upgrade from 2.15.9

Copy `harness/`, or run `./install.sh <target> --apply`. Stamps written before the upgrade are
in `/tmp` (or already gone). A ticket finished before it whose merge is not yet pushed needs
`scripts/ticket-done.sh <id>` re-run once to write its stamp in the new home. Restart the
workspace watchdog.

# Astragentic 2.15.9

Two defects the first live 2.15 dispatch exposed, reported by that project's Thomas and
confirmed by its reviewer.

- **The watchdog sent `WATCHER_LOST` for every working Claude pane.** It decides whether a
  pane is watched from two probes, and both know only the watcher script. Since 2.14 a Claude
  pane runs no watcher: the dispatch mod reports from inside it. So every dispatch drew the
  alert, and an alert that fires every time teaches its reader to ignore the real `BLOCKED` and
  `STUCK`. A pane with a mod-written record entry (one with a `session_id`) is now treated as
  self-reporting and is exempt from `WATCHER_LOST`. `STUCK` and `NEVER_STARTED` still apply to
  it, since those are about the pane, not its watcher. Selftest covers both directions.
- **A "No RECEIVED" alert stuck while the record held the ack.** The pane answered in 34 ms,
  before the dispatcher's send hook had noted the send, so the note landed after the ack that
  should have cleared it. The board also ranked that in-memory note above the record. An ack
  recorded at, or within 10 s before, the noted send now settles it. The reviewer ruled out the
  first hypothesis, that a refused send armed the timer: the code never notes a refused send.

## Upgrade from 2.15.8

Copy `harness/`, or run `./install.sh <target> --apply`. The mod and
`scripts/herdr-watchdog.sh` change. **Restart the workspace watchdog**: a running watchdog keeps
the old analysis until it is relaunched.

# Astragentic 2.15.8

**A correction to the 2.15.7 notes, which got the cause wrong.** They called the
`ticket-done.sh` failure a load-dependent flake. The reviewer of the first 2.15 adoption measured
it as deterministic. `git rev-list --first-parent <base> | grep -qx <tip>` under `pipefail` fails
every time the list exceeds a pipe buffer (64 KB, about 1600 commits) and the match comes early:
`grep -q` exits, and the writer takes SIGPIPE. On that project's 2,392-commit history it failed
10/10. The 2.15.0 empty-branch fix therefore never worked in any real repository. It held only
on the short selftest fixture, which structurally cannot fail, which is why 30 isolated runs
were green. The `grep -cx` form shipped in 2.15.7 is correct. The diagnosis was wrong.

Selftest now builds an 1,800-commit history (74 KB of first-parent ids) and requires the empty
branch to be refused there. Against the `grep -q` form that case fails on the first run.
Same-shape sites were swept: every remaining `| grep -q` under `pipefail` reads a shell variable
or a few lines, far below the buffer.

**The rule worth keeping:** after a pipe under `pipefail`, `grep -q` is safe only while the
producer's output stays below 64 KB. Past that, an early match fails the pipeline, every time.

## Upgrade from 2.15.7

Copy `harness/`, or run `./install.sh <target> --apply`. Only `scripts/selftest.sh` changes.

# Astragentic 2.15.7

A scope statement, from the reviewer of the first 2.15 adoption. The dispatch mod recognises a
pane as dispatched only by its tab label (`ticket:` / `spec:` / `qa:` / `rin:`), so its refusal
to close a mid-turn pane covers dispatched panes and no others. Resident panes, such as a
deploy worker or a design or harness partner, have no record entry, and closing one goes
through. `dispatch-ticket-claude` § What the mod cannot see now says so, so that "the mod
blocks closing a working pane" is not read wider than it is. Covering resident panes is an
open design question: a label the mod recognises, not a restart.

## `ticket-done.sh` could stamp an empty branch under load

The 2.15.0 fix for empty branches asked `git rev-list --first-parent <base> | grep -qx <tip>`.
With `pipefail`, `grep -q` exits on the first match, and `rev-list` can take SIGPIPE while still
writing. The pipeline then fails, and it fails in exactly the empty-branch case, where the tip is
the newest base commit and the first line out. The branch read as merged and was stamped done.
Selftest caught it once, while the box was busy; 30 isolated runs passed, which is why it
shipped. It now counts with `grep -cx`, which reads all its input. Three consecutive selftest
runs pass.

## Upgrade from 2.15.6

Copy `harness/`, or run `./install.sh <target> --apply`. `dispatch-ticket-claude` and
`scripts/ticket-done.sh` change.

# Astragentic 2.15.6

From the reviewer's pre-dispatch check on the first 2.15 adoption. That project ignores
`.agents/*` and un-ignores each skill by name, so a skill a release adds for the first time
would sit on disk in the main checkout and be absent from every worktree, silently.
ADAPT-HARNESS's visibility proof tested one file, `builder.md`, which says nothing about the
others. §4 now runs `git check-ignore` over every file of the candidate payload, skipping paths
through symlinked skill directories (check-ignore refuses those outright; their targets are
checked under `.agents/skills/`). Measured on that project's 2.15.5 payload: nothing ignored,
and a planted new skill path was named.

## Upgrade from 2.15.5

Nothing in `harness/` changes; the adaptation prompt does. Run the new check at your next
upgrade.

# Astragentic 2.15.5

Two findings from the reviewer of the first 2.15 adoption, both of which failed toward silence.

- **A renamed payload file read as clean.** `git status --porcelain` prints a rename as
  `old -> new`, which matches no payload path, so a moved contract file slipped past the 2.15.4
  brief check. It now runs with `--no-renames`: the delete and the add are each named.
- **The 2.15.4 check fails open, and said nothing about it.** It now says so in the module
  and in `dispatch-ticket-claude`. With no readable applied version, release tree or
  `git status`, the brief goes. That makes it a lint, not a boundary, in the sense this
  package already uses for `hook-git-guard.py`, and it must not be cited as proof that a dirty
  payload cannot be dispatched. Why it is not scoped to each role's reads is also recorded:
  that source is prose in each contract's Load table, and a gate cannot depend on markdown
  formatting.

## Upgrade from 2.15.4

Copy `harness/`, or run `./install.sh <target> --apply`. The mod and `dispatch-ticket-claude`
change.

# Astragentic 2.15.4

Found by the read-only reviewer of the first 2.15 adoption, which caught a claim the
adapting session made: that `check-requirements.sh`'s `[MISS] … uncommitted-but-tracked` would
hold the first dispatch. Nothing read that MISS at dispatch. The doctor runs at adaptation, and
an `orchestrator.md` edit left uncommitted in the main checkout would have gone into the first
brief, read by the dispatcher and not by any worktree (AST-036).

The dispatch mod already refused a brief while `apply-incomplete` exists, for that same reason.
It now also refuses one while any file of the applied release's payload is modified or
untracked in this checkout, and the refusal lists the paths with what to do about each. The
reviewer measured the scope before release: about one commit in six on that project passes
through this state, mostly a rule half-written into `thomas.md`. A gate whose only way through
is committing something unfinished teaches committing rubbish, so a brief carrying
`Uncommitted-payload: <why this brief is unaffected>` goes through, and the line reaches the
agent with the brief. Generated files (`INDEX.md`, `RULES.md`) are named with the command that
regenerates them. Measured in a lab repo: an edited payload file was named and refused, and an
edited product file beside it was not named.

## Upgrade from 2.15.3

Copy `harness/`, or run `./install.sh <target> --apply`. The mod and `dispatch-ticket-claude`
change. Commit or revert any payload edit sitting in the main checkout before dispatching; from
this release a brief will not go while one is there.

# Astragentic 2.15.3

Found applying 2.15.1 to the first adopted project. Selftest's codex-launcher section copied its
fixture from `$ROOT/harness/.agents`, a path that exists only in this package. In every adopted
project, all six codex cases failed while passing here: a test that has only ever been green
where it was written. The fixture is now the generic scaffold from the staged release
(`.astraler/releases/<CANDIDATE>/harness`) in an adapted project, and harness/ in the package.
Measured on that project: 6 failures before, 0 after, with the project's own tuned
orchestrator never read.

## Upgrade from 2.15.2

Copy `harness/`, or run `./install.sh <target> --apply`. Only `scripts/selftest.sh` changes.

# Astragentic 2.15.2

Found by the read-only reviewer of the first project to adopt 2.15. A
`.astraler/project/work-in-flight.sh` that exists without its exec bit raised inside
`herdr-watchdog.sh`, fell into the "cannot tell, assume in flight" branch, and read as IN FLIGHT
on every poll. STUCK was muted for good by a forgotten `chmod`, while a project with no plug at
all stayed loud: the worse state was the quieter one (AST-124). The plug is written by hand
during adaptation, and nothing refused a missing exec bit.

A plug that exists but cannot run now reads as no plug, so STUCK is judged on pane state, and
the watchdog sends `PLUG_BROKEN` naming the file. Selftest plants a non-executable plug and
requires STUCK to fire. Against the 2.15.1 watchdog the case fails.

## Upgrade from 2.15.1

Copy `harness/`, or run `./install.sh <target> --apply`. Only `scripts/herdr-watchdog.sh` and
`scripts/selftest.sh` change. If the project has a `work-in-flight.sh`, check it is executable;
from this release a `PLUG_BROKEN` alert says so when it is not.

# Astragentic 2.15.1

Found while supervising the first project to take 2.15.0. An upgrade that stops on conflicts
already leaves `.astraler/state/apply-incomplete` and withholds `applied-version`, and
`check-requirements.sh` reports it. But the doctor runs at adaptation, and the next brief does
not wait for it: Thomas could dispatch on role contracts that were half old. The dispatch mod
now refuses every brief while the marker exists, and the refusal lists the unreconciled paths.
This is AST-157's rule applied once more: the gate goes on the step that cannot be skipped.
Measured on a lab repo carrying the marker: the brief was refused with the paths.

## Upgrade from 2.15.0

Copy `harness/`, or run `./install.sh <target> --apply`. Only the mod and
`dispatch-ticket-claude` change. If an earlier apply left `apply-incomplete`, finish the
reconciliation before dispatching; that is now enforced, not advised.

# Astragentic 2.15.0

2.14.0 removed three dispatch steps by letting the pane do them. The owner named the two that
were still remembered only sometimes: **the tracker**, at both ends of a ticket, and **the
teardown**. This release puts both on the dispatch mod, and fixes a check that two authors got
wrong in the same way.

## The tracker is checked at the brief

The close side had a gate since 2.8, a refusal at the push of the base. Two merge shapes never
push the base locally: `gh pr merge`, and a merge held for a gate. The claim side had no gate at
all. Both now sit on the one step every dispatch passes through, the brief. The check uses the
project's own `.astraler/project/tracker-state.sh <id>`, the plug `ticket-done.sh` already asks:

| Moment | What the mod does |
|---|---|
| A brief for a ticket the plug reports unclaimed (assignee `-`, state `closed` or `unclaimed`) | not sent; the refusal names the claim protocol |
| A Builder ticket reached the base with no `ticket-done` stamp | every brief is held until `scripts/ticket-done.sh` stamps it |
| The merge command that caused it | carries the note in its own result, and the status line turns red |

A project whose claim is a status or a label makes its plug print `unclaimed` until it is set.
An absent plug, a failing one, or one printing `unreachable` skips the check rather than
refusing every brief. The mod never writes the tracker, because writing it is the claim
protocol's job and the vocabulary is the project's.

Measured 2026-10-05 against a stub tracker. The unclaimed brief was refused, and the Builder
received nothing. After the merge the next brief was refused, and the dispatcher closed the
ticket and ran `ticket-done` in the turn that read the note (AST-157).

## The release runs at removal

`git worktree remove` on a recorded worktree now runs `release-worktree-resources.sh` first,
which used to be a step taken by hand before it. It runs only when the agent is not mid-turn and
the tree is clean: the release tears down live state, and must not run for a removal the git
guard would refuse (AST-115). The record entry goes once the worktree and the tab are gone.
Measured: release, stamp, Builder reaped, tab closed by herdr, entry deleted, from one command.
The git guard and git hooks are unchanged and still the gate.

## An empty branch had "reached the base"

`git merge-base --is-ancestor` holds for a branch that never had a commit, because its tip is a
base commit. The lab caught it twice in one run. The mod's board said "merged" for a Builder
that had committed nothing, and `ticket-done.sh` stamped that ticket done (AST-158).

- **The mod** records the commit a pane started at, once, at first registration. A reload
  re-fires session start, and it rewrote that commit in the lab.
- **`ticket-done.sh`** requires the tip to be the branch's own work. It compares against that
  start commit when the record has one, and otherwise requires the tip to sit off the base's
  first-parent line. A fast-forward lands on that line too, and passes on its subject as before.

Selftest plants both shapes: the empty branch is refused, and the fast-forward is stamped.

## Smaller changes

- Lab finds fixed before shipping. herdr closes a Builder's tab when the release reaps the
  Builder, so the record entry is now deleted when the tab is already gone. The plug's
  `unreachable` answer no longer blocks dispatch.
- Two ledger entries: `AST-157` (a gate on the step that usually follows, not the one that
  always does) and `AST-158` (ancestry passes for no commits).

## Upgrade from 2.14.0

Copy `harness/`, or run `./install.sh <target> --apply`. If the project has no
`.astraler/project/tracker-state.sh` yet, write it now: on a Claude root it is what the claim
check reads. If its claim is a status or a label rather than an assignee, print `unclaimed`
until that is set. Commit the updated mod with the payload.

# Astragentic 2.14.0

A downstream Thomas sent an account of its own day, and it was the cleanest evidence this
package has had. It violated none of the steps a script refuses, and was refused by one minutes
before writing. It broke two steps that nothing refused. It skipped the dispatch record, then
guessed a tab id at cleanup and closed a working Builder. It armed no watcher and wrote a
`while true; sleep 30` loop instead, which is the example the Monitor tool's own description
carries. Same agent, same day: **the variable was whether something refused, not discipline.**

The obvious fix was another refusal. This release removes the steps instead.

## The pane does its own dispatch steps

`.claude/skills/astragentic-dispatch/` is a Claude Code mod, and it ships in the payload. Claude
Code auto-loads a plugin from a project's skills folder, so every Claude session in the project
runs it: Thomas, every Builder, Shaper, QA and Rin. Nobody passes a flag or installs it.

| Step | 2.13.0 | 2.14.0 |
|---|---|---|
| Record tab and pane ids | Thomas copies them from the create output | the pane writes them at session start, from herdr's environment |
| Deliver the slash command | SendMessage for the body, type the command into the pane, confirm the echo | one SendMessage; the pane runs the first line as a real command |
| Confirm delivery | read the pane for a phrase only the brief had | the pane answers `RECEIVED`; 90 s without one turns the status line red |
| Watch the turn | a Monitor wrapping the watcher script, re-armed every turn | the pane reports `TURN-END`, and the mod wakes Thomas with a prompt |
| Protect a working pane | nothing | `herdr tab\|pane\|workspace close` on a mid-turn pane is refused |

Measured 2026-10-05 on Claude Code 2.1.289 and herdr 0.9.1, with a Builder in its own worktree:

- The record carried the right tab and pane ids.
- A phrase that existed only in the brief body came back in the Builder's answer.
- The wake arrived under one second after the turn ended. Pane-state polling was 67 s late
  (AST-097).
- A `herdr tab close` on the working Builder's tab was refused.

The same lab also measured that a message a receiver **holds** still reports
`isDelivered: true` to its sender, so `RECEIVED` from the receiver is the only proof of
delivery (AST-153).

**Two of the lab's own drafts failed**, and the shipped rule is what survived them:

- Reporting every turn end woke Thomas three times for one task, on turns that only read
  delivery notices.
- Reporting only the brief's own turn missed the result of a Builder that backgrounded its work
  and finished it one turn later.

The pane now reports every turn after its first brief and skips turns that only read a
delivery notice. `TURN-END` is still a bell, not proof. Thomas verifies by artifact.

`dispatch-ticket-claude` is rewritten around the mod, and is 40 lines shorter. The record's
shape gains `tab_id`, `pane_id`, `session_id`, `session_name` and the turn fields. Cleanup
closes the tab whose id is recorded, never one looked up by label or remembered.

## What stays

- **The workspace watchdog stays mandatory.** A pane whose process died takes its mod with it,
  and only the watchdog sees that pane.
- **Codex and OpenCode are unchanged.** They load no Claude mod, so they keep the watcher script
  and its protocol.
- **Git hooks stay the gate.** A git hook refuses every caller: a person, any runtime, a script.
  A mod sees only its own session's tool calls, and an installed mod can approve a call that a
  PreToolUse hook denied.

## Smaller changes

- `check-requirements.sh` refuses Claude Code below 2.1.289, the version the mod was measured
  on. Below it the mod does not load, and nothing records or watches a Claude pane.
- `check-reachability.sh` counts a shipped mod (`.claude/skills/<name>/.claude-plugin/`) as a
  resolvable name. It failed every document that named the mod.
- Selftest validates the mod with Claude Code's own reader and plants a defect to prove that
  the reader names one.
- One ledger entry: `AST-156` (three steps had no lock, and the same agent skipped two of them
  on the same day).

## Not taken, and why

- **A wrapper script and a refusal for the next dispatch**, which is what the downstream report
  proposed. It would have enforced a step that a mod can remove.
- **Moving git gates into the mod.** See *What stays*.
- **`claude plugin test` cases.** The test kit has no filesystem or process access, and the mod
  is built on both, so the lab run and the validator are the evidence.

## Upgrade from 2.13.0

Copy `harness/`, or run `./install.sh <target> --apply`. Commit
`.claude/skills/astragentic-dispatch/` with the rest of the payload: a worktree loads the copy on
its own branch. Update Claude Code to 2.1.289 or later on every machine that dispatches.
Projects that still arm a Monitor for Claude panes can stop. The two mechanisms do not conflict,
but the Monitor becomes a second copy of the same signal.

# Astragentic 2.13.0

A downstream project sent a report on its most stable week: 32 ticket merges in four days,
serial, and its first real order carried end to end. It cited a commit for every claim. Each
was read in that repository before anything here moved. Most of the report was about the
project itself; four findings were about this package, and three of them are one shape:
**something reported success, or reported nothing, about a thing it could not see.**

## The watchdog asks about one pane

`STUCK` fired only when **no** pane in the workspace was working. With several Builders in
flight, one of them working is the ordinary state, so the alert was silent in the case it
exists for. Measured downstream: a Builder whose waiter had died sat idle on a free box while a
sibling was mid-turn, and nothing fired.

The same scoping left a state with no alert at all:

| alert | needs | a pane dispatched and never started |
|---|---|---|
| `BLOCKED` | the pane asking a question | silent |
| `WATCHER_LOST` | the pane working | idle |
| `STUCK` (2.12.0) | nothing else working | a sibling was working |

A Shaper whose brief never submitted was heartbeated past all evening and surfaced only because
it wrote to the router itself.

Both alerts now ask about one pane across two polls, from memory the watchdog keeps in its
state dir. **`NEVER_STARTED`** is a pane never seen working. **`STUCK`** is a pane that worked
and then sat idle twice. Neither fires on a first sighting, and neither can fire for the other.

**A pane that ends its turn with a test run in the background reads `done`**, and pane state
cannot see that run: the same project measured seven false `STUCK` alerts in one shift from
exactly that. So the project answers the question through a sixth plug,
`.astraler/project/work-in-flight.sh`: exit 0 while something heavy runs, 1 when nothing does.
Any other exit counts as in flight, because a missed `STUCK` costs a late nudge and a false one
costs trust in every alert. Absent, `STUCK` fires on pane state alone.

`scripts/selftest.sh` runs the analyzer poll after poll against a stubbed `herdr`. The two
downstream states were run against the 2.12.0 analyzer first, and it was silent on both.

## `success: true` was a statement about the transport

`SendMessage` to another Claude session returns success when the message is transported. The
receiving session can hold it for its user's approval (`crossSessionInbound`), and the sender is
never told. Downstream, a gate brief to Rin was held while the pane read `idle` — which looks
exactly like a gate that started and found nothing — and the verdict going back was held too,
its release prompt defaulting to **Deny**.

The first diagnosis was the permission-mode mismatch the pane printed. Then a brief to a Builder
launched **with** bypass was held as well. **The mismatch is one trigger, not the cause**, and a
rule built on it would have protected one role and missed the other two.

- **`review-with-rin`** now delivers the gate brief with `herdr agent prompt`, which is typed
  input and crosses no permission boundary. Until now it said nothing about delivery.
- **`dispatch-ticket-claude`** keeps `SendMessage` for the Builder's body, but delivery is now
  confirmed at the receiver: a phrase only the brief could have supplied, read off the pane. A
  held Builder has already run its slash command and improvises from it, so it reads `working`.

## Sending again fused two briefs

The retry that suggests itself for a brief stuck in the composer (AST-032, AST-037) is to send
it again. `herdr agent prompt` does not clear the composer. It appends to the stale last line
with no separator, submits both as one turn, and reports success. Every signal before the retry
matched an empty pane: `idle`, `ctx 0%`, `↑0 ↓0 tok`. The deadlock fails by doing nothing; this
fails by **running**. `dispatch-ticket` now reads the composer before re-delivering, and clears
it with `esc esc`. `ctrl-c` and `ctrl-u` were measured to leave the text where it was.

## The teardown removed what it started and kept what it built

The same project's worktree plug ran `docker compose down -v` for every ticket it retired.
That removes the stack's containers and volumes, and **not the image the stack built**. The
owner found 99 of them at ~485 MB each, inside 72 GB that also held 21.6 GB of never-pruned
build cache. A second project on the same machine had no Docker teardown at all. Reproduced
here on Docker Desktop: the image survives `down -v`, carrying the project's Compose label, and
`--rmi local` removes it.

The ask was for the harness to run the teardown itself. It does not: that needs the project's
compose file, project name and environment, and the downstream stack refuses to start without
a variable only that project sets. Hardwiring one project's stack is the defect 2.7.15
removed. **What the harness can do without knowing the stack is notice.** Compose labels every
container with the directory it ran from, so `release-worktree-resources.sh` names the stacks
rooted in a worktree before the plug runs. If any of them still holds a container, a labelled
volume or a default-named built image afterwards, it lists each by name and withholds the
stamp the git guard needs. Images the project tags itself are left out, so a shared image kept
on purpose is never flagged. Nothing is deleted.

Selftest runs it on a stubbed `docker`. The 2.12.0 script, handed the same leftover image,
stamped the worktree and said nothing.

## Smaller changes

- **The Builder's loop names the full verification run**: once, after the last commit that
  changes the tree, before the receipt. A Builder downstream started a 20–40 minute suite
  straight after implement, because the loop never said where it went.
- **`TERMINAL:done` means the turn ended, not that the work finished.** Measured twice in one
  shift: `done`, with the Builder's own gated suite still running. `WATCHING.md` says so, and
  names where the verdict comes from instead.
- **`Ledger: none` means *taught nothing*, never *not written yet*.** Downstream moved the
  ledger entry after the merge, and ten merges in a row then said `none`, one of them the merge
  the next entry opened by citing.
- **Where verification runs belongs in the entry doc.** `ADAPT-HARNESS` asks for the local
  stack and the customer's environment to be named in `AGENTS.md` or `CLAUDE.md`. Not only in
  `.claude/rules/`, which Claude Code alone loads (AST-138). QA's non-mutating rule adds that
  authorization is per run: a yes for one walk does not carry to the next, and permission to
  deploy is not permission to test.
- Four ledger entries: `AST-152` (alerts scoped by the wrong subject), `AST-153` (a transport
  that holds and reports success), `AST-154` (the retry that fuses), `AST-155` (the teardown
  that kept what it built).

## Not taken, and why

- **Default to one lane.** The single lane was measured on one project with a shared test
  database and a single merge station, and there it is the right call. `AST-131` measured the
  opposite failure, slots left idle against a full frontier. `builder-target` is already the
  owner's knob, so the default stays 4.
- **The commit-msg marker check.** It works well downstream, and it runs a checker that project
  has since extended (retraction chains, tree comparison) past this package's copy. Shipping the
  hook alone would lint against the older rules. The two checkers get reconciled first.
- **Tree-equality narrowing, and its argument contract.** It is project tooling this package
  does not ship, so there is no contract here to document.
- **Gate start and end stamps, "infra-shaped failures are ENV", completion signalling.** Each
  needs a gate wrapper, and the package has none. Downstream measured the lesson itself, a
  duration read from a log's access time, and it stays theirs until a wrapper exists.
- **The Claude watch loop swallowing `NO_START`.** That loop is the project's own. This
  package arms one Monitor per turn, which reports `NO_START`.
- **Pruning build cache on ticket close, and a doctor check for Docker disk.** `docker builder
  prune` is machine-wide, and so is every dangling volume: pruning either from a ticket step
  deletes other projects' state, which is AST-115's shape. The doctor runs at adaptation, so it
  would not have seen 72 GB accumulate over weeks. Both stay the owner's, and CLEANUP.md now
  names the three prunes never to run from a teardown.
- **Prefer tickets that move the owner's named goal.** That was one owner's ruling on scope, not
  something measured here.

## Upgrade from 2.12.0

Copy `harness/`, or `./install.sh <target> --apply`. Then decide the new plug: write
`.astraler/project/work-in-flight.sh` if this project runs long verification in the background,
or decline it in the receipt. **A project whose worktrees run Compose must release them with
`down -v --rmi local`** before this upgrade, or every retirement will be refused the stamp
until it does. The watchdog's pane memory lives in its `/tmp` state dir and needs
no migration.

# Astragentic 2.12.0

A downstream project asked one narrow question: does `codex --profile <role>` read the
repository's `.codex/profiles/`? It does not, and the CLI's own help has always said so — it
layers `$CODEX_HOME/<name>.config.toml`, and nothing else. The package never claimed otherwise.
It shipped templates and told the owner to copy each one into `$CODEX_HOME` by hand.

The narrow answer was the smaller half. **`$CODEX_HOME` is one namespace shared by every project
on the machine, and the key is a generic role name.** Two repositories running this harness both
want `builder`. The second one provisioned wins, silently, and no check on either side can see
it: each compares its own template against a destination that belongs to neither.

This release removes the namespace rather than guarding it. Everything the Codex pane needs now
travels on the launch command line, which makes the orchestrator row the only home for model and
effort — and, as usual, retiring a mechanism found three checks that had been quiet about things
they were supposed to be watching.

## The launcher stops going through a file it cannot write

```bash
codex -m <model> -c model_reasoning_effort="<effort>" \
  -c developer_instructions="$(cat .codex/profiles/<role>.md)" \
  --dangerously-bypass-approvals-and-sandbox
```

The five `.codex/profiles/<role>.config.toml` become `.codex/profiles/<role>.md`: plain text, in
the repository, tracked in git, per-project. Every rule in them is carried across byte for byte
except one sentence, which is the subject of the next section.

Three costs went with the old mechanism, and they are three different failures:

| what it was | why it could not stay |
|---|---|
| a copy into `$CODEX_HOME` | `install.sh` cannot write outside the repo, so the doctor reported an unprovisioned profile on every run until a human acted — four `[MISS]` lines that meant nothing was wrong yet |
| `model` and `model_reasoning_effort` in the profile AND the row | a third of the doctor's Codex block existed only to police the disagreement. A value with two homes needs a referee; a value with one does not |
| a generic name in a shared namespace | two adapted projects collide on `builder`, and the collision is invisible from inside either one |

**The file is the pane's system prompt.** Whatever is in it is said to the agent, so a line
explaining the file to a human reader is a line the agent reads as instruction. The explanation
moved into `dispatch-ticket-codex`; the file carries instructions and nothing else.

## "It launched" was never evidence, and one probe proves the other two are necessary

Measured on codex-cli 0.155.1, in this order on purpose:

| probe | result |
|---|---|
| `-c totally_bogus_key_xyz="whatever"` | **accepted, no warning, exit 0** |
| `-c developer_instructions="<text>"` | the agent obeyed the text; a control run without it did not |
| `-c model_reasoning_effort="definitely_not_a_level"` | HTTP 400 — at the first API call, not at launch |

A typo in a config key costs a Builder with no contract and produces no error anywhere: the pane
starts, looks healthy, reports for work, and runs on the base user config. That is AST-032's
shape one floor down — not a check that cannot fail, but an **input that is always accepted**.

So pre-dispatch verification stopped comparing two copies of a file and started asking the
parser. `codex debug prompt-input` renders the model-visible prompt as JSON with no model call,
and the role file must come back byte for byte. It caught two things reading would not:

- `-c` parses its value as TOML **first** and falls back to a literal string. Prose survives
  verbatim — headings, `$`, backticks, quotes, markdown links — but a file that is one quoted
  line returns with its quotes stripped, and a file containing only `true` is refused with
  *invalid type: boolean, expected a string*.
- The first draft of the verification snippet compared with `diff` against output written
  without a trailing newline. It failed on a **correct** file. Shipped, it would have been a
  step that is red for everyone, which is a step people learn to skip.

What it proves is delivery and only delivery. A file that still describes a retired mechanism
passes it — so `check-requirements.sh` WARNs when a role file mentions `--profile`, `CODEX_HOME`
or `.config.toml`, which is the half no parser can answer. Measured downstream: five role files
kept *"it exists so `codex --profile <role>` resolves"* through the change that retired it, and
the pane quoted the sentence back when asked.

## One awk condition was answering two questions

`check-requirements.sh` read a role's codex row with `$2 == role && $3 == "codex" && $4 != ""`.
That last clause is a judgement about the **model cell** smuggled into a test for whether the
**row exists**. A row reading `| builder | codex |  | medium |` produced no output, and the loop
below printed `ok: no codex row — this role does not run on Codex` — which is what a deliberate
decline looks like. The role was assigned to Codex, could not launch, and the doctor answered in
the sentence reserved for a correct configuration.

It survived because the duplicate covered it: the profile shipped `model = ""` and another
branch MISSed on that. The moment the row became the only home, the blank cell became
unreportable. **Removing a duplicate removes the redundancy that was quietly answering for a
defect somewhere else.** Three states now get three answers: no row is a decline and reports
`ok`; `<set-me>` is the scaffold's resting state; a row naming the runtime and no model is a
`MISS`.

Two more boundary faults in the same block, both the shape 2.11.0 was named for — a check
answering about a different tree than the one it was handed. With a target given, the block fell
through to the **package's** orchestrator when the target had none, and to the **package's**
role file when the target's was missing, reporting `ok` about a file the target does not have.
The comment above it had claimed the opposite since the block was written.

## A `Bound:` line with a star in it was never checked at all

2.10.0 added check 10 — every live `Bound:`/`Wired`/`Enforced by` citation must still resolve —
after the ledger's provenance went unchecked for four releases. Renaming five files out of the
payload made two of its citations false, and check 10 stayed green over both.

Its pattern required a backtick on each side and did not have `*` in the character class, so
`` `harness/.codex/profiles/*.config.toml` `` matched **nothing**: not a resolved binding, not a
finding, not even a counted assertion. The count it prints — the only number a reader can judge
its coverage by — had been quietly excluding the citations it could not read. Adding `*` took it
from 137 to 140 before this release added an entry.

Found by planting the same claim twice, once with a literal filename and once with a star: the
literal one failed on the spot, the starred one was silent. Reading the regex would not have
distinguished those two, because it looks correct either way.

A globbed citation is also a different claim — that the set is non-empty — so check 10 resolves
it with a glob and fails when the set is empty, which is exactly what a renamed-away file leaves
behind.

## The rename would have left a fossil in every adapted repo

`install.sh` has carried a fossil detector since 2.7.6: a path an older release shipped, this
one does not, and the project still has. It skipped this rename by name. `.codex/profiles/*` was
in its exclusion list beside `.agents/orchestrator.md` and `.claude/settings.json`, because a
project keeps its own scaffold — right reasoning, and it stops holding the moment the path
itself is retired rather than tuned.

The exclusion now names only the two files that have never been renamed and are hand-merged
every release. A pre-2.12.0 project upgrading is told what to do with the leftovers, and told
before it deletes them: the owner's model and effort are inside those TOMLs, and they need to
reach the orchestrator row first.

## The first project to run the new launcher could not launch

2.12.0's launch template was `herdr agent start … -- <args>`, unchanged from the `--profile`
era. It refuses the very thing the release moved onto the command line:

```
invalid_agent_argument — agent arguments cannot be encoded safely for the target shell
```

Measured with a control on herdr 0.9.1: the same call with a **single-line** identity gets past
encoding and fails only on the pane id. The cause is the newline, not the length — and every
role file is multi-line, so `agent start` refuses every real Codex dispatch. The launch is two
steps now: `herdr pane run`, which takes the whole command as one shell string, then
`herdr agent rename` to restore the registered name.

`pane run` alone is half a dispatch — the pane has no agent name, so the watchdog that counts
dispatched agents cannot see it and nothing can prompt it by name. And the step that closes that
gap has a rule of its own: `rename` demands a lowercase name, so a project whose ticket ids are
uppercase fails at the END of dispatch, agent already up and unregistered, which is the state
the step exists to prevent. The shared protocol had that rule written for `agent start` and
nowhere near `rename`.

## The arm's own command could not run, and the obvious repair was worse

`codex-arm` documented `codex exec review --base "$BASE" -m <model> "<focus>"`. On codex-cli
0.155.1 that is *the argument `--base <BRANCH>` cannot be used with `[PROMPT]`* — exit 2, before
any review starts, so **no output file is produced and the failure looks exactly like an arm
that was never fired**. `--commit <SHA>` refuses a prompt the same way, and `-`, the documented
stdin marker, IS the positional it refuses.

The repair that suggests itself is to pipe the focus without `-`. That is accepted, and the
focus is discarded: the run reviews the range under a generic `changes against '<base>'` prompt
and exits 0 with a complete, plausible review. Proven by piping *"Respond with exactly
PIPEWORKS"* and getting an ordinary review back, zero occurrences of the token.

**A loud failure had been replaced by a silent one.** Exit 2 with no artifact is obviously not a
review. Exit 0 with a full review, from a mandatory intent-loaded gate that never saw the
intent, is a gate that cannot fail. There is no form of `codex exec review` carrying both a
range and a focus; on a non-Claude root the arm now uses plain `codex exec` with the range named
in the prompt, accepted only after a token the prompt asked for came back in the final message.

On a Claude root the plugin path stays primary, and now for a stated reason rather than a
preference: `adversarial-review` takes the focus as an ordinary positional beside `--base`.
Plugin >= 1.0.6 also turns a hang from a verdict into a job — `status`, `result`, `cancel`, all
`--json` — which retires "treat a hang as NOT RUN", and ships
`schemas/review-output.schema.json` so findings are folded by field instead of parsed from prose.

## One call submits a brief, and an empty cell stops a pane

**`herdr agent prompt` sends text and Enter together** (herdr >= 0.9.0), retiring the
paste-plus-separate-Enter two-step the protocol carried because a multi-line paste consumes the
Enter and leaves the brief in an unsent composer while the pane reports idle (AST-032, AST-037).
Every real brief is multi-line, so that was the default case, with a second step a router could
forget. The paste form stays as the fallback below 0.9.0 and for a pane with no name yet. Its
`--wait --until idle` exit status is still not evidence: a prompt that demonstrably submitted
and answered returned exit 1 from the wait, AST-107 one command over.

**An empty Effort cell is refused rather than warned about.** The launcher passes
`-c model_reasoning_effort=""` and Codex refuses it while loading configuration —
*reasoning_effort must not be empty* — so the pane never starts, after dispatch has reported a
launch. It is AST-040 one column over, and it only became reachable because the duplicate that
used to answer for it is gone: deduplication does not create these, it exposes them.

**herdr 0.9.1's claims are recorded as claims.** Its changelog touches three states
`WATCHING.md` branches on — interrupted turns returning to idle, blocked keeping its meaning,
and live agent names surviving detection blips, which the `agent prompt` path depends on. Every
surrounding rule here was measured on 0.9.0, so `WATCHING.md` now names the three checks to
re-run first and keeps the workarounds until someone runs them.

## Also in this release

- **Rin moves to `claude-opus-5` at `high`.** The shipped table had the reviewer a generation
  behind Thomas and the Shaper, and the gate running at lower effort than the work it judges.
  Rin is one round per milestone over a whole slice, with no second pass to catch what the first
  missed; the cheapest role to under-provision is the wrong one to.
- **Check 4 gained the question the launcher actually asks.** Every role the orchestrator puts
  on Codex — active row or fallback row, because a fallback is a launch path — must have the
  file the launcher cats. The first version of this check keyed on the literal string
  `.codex/profiles/<role>.md` written in the skill, which contains a `<role>` placeholder and
  therefore could never match anything. It was caught by its own fixture, which is the only
  reason it is not shipping silent.
- **Check 4 also stopped reporting a real address as missing.** `scripts/check-requirements.sh`
  exists in every adapted project and nowhere in this package's payload directory, because the
  installer injects it from the package root. It is named in one map with the reason, rather
  than excluded by a regex nobody can find.
- **Ten new selftest cases**, each watched to fail against the tree before its fix: a blank model
  cell, a deliberate decline, a target answered by the package's copy, a role file teaching a
  retired flag, a leftover TOML, a fully configured row, a globbed binding, a `--profile`
  launcher, a role on Codex with no instruction file, and the payload's own globs staying quiet.
- Seven ledger entries: `AST-145` (the namespace), `AST-146` (silent key acceptance),
  `AST-147` (the invisible glob), `AST-148` (one condition, two questions), `AST-149` (no form
  carried both range and intent), `AST-150` (the launcher that cannot encode the identity),
  `AST-151` (an empty cell refused at bootstrap).

## Upgrade from 2.11.0

Copy `harness/`, or `./install.sh <target> --apply`. The five role files arrive as NEW scaffold
and your `.config.toml` files are reported under DELETED upstream — **read that report before
deleting anything**, because those TOMLs hold your model and effort and the row may not have
them yet.

Per role: put `model` and `model_reasoning_effort` into that role's codex row in
`.agents/orchestrator.md`, move any instruction text you added into `.codex/profiles/<role>.md`,
then delete the TOML and its copy under `$CODEX_HOME`. Nothing reads either one.

`check-requirements.sh` WARNs while a leftover TOML remains and while any role file still
mentions `--profile` or `CODEX_HOME`. Both are advisory: a project that declines Codex entirely
can delete the rows instead, and the doctor will stop asking.

# Astragentic 2.11.0

2.10.0 was applied to a real project the hour it was built. Four of its changes were defects,
and all four were found by that project inside one afternoon — three of them by this package's
own gates, refusing to let the next build ship. This release is those four fixes and the one
new contract surface they required.

**2.10.0 is not withdrawn and its notes are not edited.** It shipped, it was adopted, and the
record of what it contained is what the next upgrade arbitrates against. A release quietly
replaced under its own number is the same defect as a `Bound:` line that stopped being true —
which is a thing this package spent 2.10.0 building a check for.

## The gate measured the caller's cwd instead of the tree it was handed

`docs-staleness-audit.sh` resolves every axis through `$PAYLOAD`, and its `.claude/rules/`
word-budget block used a bare relative path. A project ran `bash <package>/install.sh .` from
its own repo; the installer asked the audit to check the PACKAGE; the audit measured the
PROJECT's rules, went over budget on them, and **the package refused to stage**. The comment
forty lines above that block says in plain words that a bare relative path there *was* the real
cwd dependency and was fixed — fixed for every axis except the one added afterwards.

Compounding it: this package ships no `.claude/rules/` at all, so that budget had been
measuring an empty set since the day it was written. Four releases of `ok`, on a denominator of
zero, then one real rules tier and the door shut.

## A project had nowhere to declare its own vocabulary

Check 4 flags skill-shaped tokens. A project's contract named a Docker container in backticks —
character for character the shape of a skill reference — and the hint said to add the word to
`NOT_A_SKILL` *in this script*. That script is payload: doing what the hint said would be undone
by the next upgrade, every upgrade. 2.7.15 had correctly removed two downstream project names
from that set — *the payload names no project* — and left projects with nowhere to put their own.

**A gate that cannot go green is a gate people stop reading**, so one benign token would have
retired the whole check. `.astraler/project/not-a-skill.txt` is the fifth project plug: one
token per line, union with the payload's vocabulary and never replacing it. The error text now
points there and says plainly not to edit the payload set.

## The case asserted cleanliness while claiming to test invocation

`selftest.sh` carries a case named *"check-reachability runs under python3 (never bash -n)"* —
the file is Python with a `.sh` name and that is the shape it guards. It asserted **exit 0**,
and the tool exits 1 on any finding. Every healthy adapted project with one legitimate finding
read as a broken invocation. It now asserts what its name says: the header line was printed and
the exit status is 0 or 1. Anything else is still a failure, because that is what a broken
interpreter actually looks like.

## The text explaining the payload boundary violated it

The vocabulary fix above cited `PROJ-016` — an id that exists only in a project's own ledger, 22
times there and zero times in the payload's. Axis 4 caught two of the four copies and refused to
ship. It was structurally blind to the other two: one in `.agents/memory/`, excluded on purpose
because the ledger cites downstream measurements by design, and one in `prompts/ADAPT-HARNESS.md`
— **shipped in every release, read by every adopting agent, and never in this axis's scope.**

Axis 4 now reads the prompts. Getting that right took three attempts, and the first two are the
reason there is now a fixture: an array of directories read as `unbound variable` inside the
process substitution under `set -u`; then a `[[ -d ]]` guard that two byte-identical copies
disagreed about. **Both passed `bash -n`, both printed `(clean)`, and both scanned zero files.**
The actual cause was neither: the walk-up at the top of that script stops at the first directory
holding `.agents/roles`, which in this package is `harness/` — so `$ROOT` is the payload
directory and `$ROOT/prompts` does not exist.

A check whose output cannot distinguish *nothing is wrong* from *nothing was read* is worth
nothing. `selftest.sh` now plants a project-shaped token in `ADAPT-HARNESS.md` and requires the
axis to name it, then requires it to go quiet when the token is removed. The token is composed
at run time, because a literal one in `scripts/selftest.sh` makes axis 4 report on the suite
forever — the second fixture this release to need that, after the orphan-script case.

## Also in this release

- `install.sh` reports hook SCRIPTS a kept `.claude/settings.json` never names, not just missing
  event names. A release adding a script under an event the project already declares produced no
  signal at all, and the owner kept a file with none of the new machinery in it.
- `selftest.sh`: 100 cases, 0 failed.
- `AST-144` records all four, and a fifth finding from the same apply that is **not** fixed here:
  the advisory above detects a collision by script NAME, and the real one downstream collided on
  event-plus-matcher with two different names. Its wording is wrong for the same reason — it says
  "merge everything that is not your own tuning", and the correct resolution there was to delete
  something of the project's. Both are held for the next release rather than wedged in at the end
  of the afternoon that produced four defects.

## Upgrade from 2.10.0

Copy `harness/`, or `./install.sh <target> --apply`. If you applied 2.10.0, **do not delete its
staged release directory** — it is the baseline this upgrade arbitrates your tree against, and
your receipt cites it.

`.astraler/project/not-a-skill.txt` is optional; without it check 4 reports your own vocabulary
as unknown, which is the pre-2.11.0 behaviour and not a regression.

# Astragentic 2.10.0

Two agents spent an evening auditing one downstream repository for documents and tools nothing
loads, disagreed three times, and every disagreement was worth more than the audit. The package
was wrong twice, the downstream harness once, and the checks that were supposed to notice had
been reporting clean over all of it.

One theme runs through the release: **a check that has only ever been watched to stay quiet has
not been tested.** Three of the four findings below are checks going green over the exact defect
they name, one of them in a sentence the tool prints about itself.

## A count is an artifact of its definition

The question was simple — how many tools in that repo are actually wired to anything? Three
definitions, all defensible, run against the same tree on the same evening:

| what counted as "wired" | verdict |
|---|---|
| named in a hook file, CI, the Makefile or another script | **6 of 22** |
| …plus `.astraler/project/*` and the repo's git hooks | **19 of 22** |
| as above, with comments and printed strings stripped, skills still unscanned | **13 of 22** |

**No number was the finding. The spread was**, and it was published as fact twice before anyone
asked what it measured. The two errors run in opposite directions, so fixing either alone turns a
false-clean into a false-alarm rather than into an answer.

**Too narrow — the surface set.** `check-reachability.sh` check 9 read two hook-registration
files and stopped, while its own failure message named *"a VCS hook"* as a valid call site and no
git-hook directory was ever opened. It never looked at `.astraler/project/` either — the path
this method TELLS a project to put enforcement behind, precisely because `scripts/` is payload a
release overwrites. A check blind to the place the method sends you scores every project that
followed the method as an orphan farm. Skills are execution surfaces too: one tool scored dead
was called from a `SKILL.md`.

**Too wide — a name is not a call.** One tool appeared three times inside another script: two
comments and a `note "... (reap with tools/X if this is ever non-zero)"`. Substring matching read
that as a call site — and one of those comments said the logic was *"reimplemented
near-identically"* in the other file, so evidence of DUPLICATION was being read as evidence of
wiring.

Check 9 now names its surface set out loud, distinguishes CONTEXT surfaces (a contract, a skill,
the README — reached by being read, so a mention is reachability) from EXECUTION surfaces (a
hook, a plug, a VCS hook, the installer — where a mention proves nothing), and runs in project
layout over the scripts the release actually shipped. `AST-140`.

## `Bound:` is a claim about now, and nothing had ever checked one

A ledger entry narrates the past and must keep doing so — an entry naming a role file from a
generation since renamed is history told correctly. But `Bound:`, `Wired` and `Enforced by` name
where a rule is enforced **right now**, and a false one is worse than silence because it closes
the question: a reader who sees `Bound:` stops looking for the enforcement.

Measured in this package on 2026-09-16: `Bound:` pointing at `.claude/rules/agent-worktree-isolation.md`
five times, `build-loop-gates.md` three, `role-thomas.md` twice — files this package does not
ship, does not require in `check-requirements.sh`, and names in no contract. Downstream: a line
reading `"Wired 2026-08-29"` about a tool with no call site anywhere.

**The part that stings is that the package knew.** `check-reachability.sh` closed every run by
printing, in plain words, that the ledger's `Bound:` provenance was unscanned and that a live
project had measured five citations to a deleted file while check 4 reported clean. The finding
had been converted into a footnote and shipped for four releases. Check 10 is that footnote paid
off. Retiring a citation is explicit and local — `` `path` (gone) `` at the citation, never at
the entry, so a line binding one live file and one dead one keeps its live half under the check.
`AST-141`.

## The scaffold path that swallowed 2.9.0's own headline fix

2.9.0 is titled *"a rule reaches every runtime, or it reaches one"* and its central change was
the compaction rules landing in all five `.codex/profiles/*.config.toml`. Those are in
`OWNER_PATHS`, so on every project that had ever run this installer before, `--apply` printed
`owner … (kept — yours)` and wrote none of it. **The release's headline fix could not reach a
single existing adopter**, and the receipt said the upgrade was clean.

The scaffold rule itself is right: those profiles carry the owner's model and effort choices, and
overwriting them silently reverts deliberate tuning (AST-041). What was missing is that an owner
file protects the owner's **tuning** — never a **stale copy** of a safety fix the owner cannot
see. `.claude/settings.json` already had the answer one branch above: keep the file, report what
the release ships that your copy lacks. `.codex/profiles/` now gets the same treatment, with the
diff command to run.

**And the check that would have caught it was disabled exactly where it would have fired.** The
suite's runtime-parity case was `pkg_only` and resolved through `$ROOT/harness/`, so it ran only
in package layout — where those files are AUTHORED. The adapted project is where they are LOADED
and the only place they can drift. It runs in both layouts now, and treats an absent adapter as
scope rather than as a failure. `AST-143`.

## Where what is owed is DATA, inject it

The tracker contract's requirement 5 is a surface the OWNER can read without running a query, and
the contract already explains why no agent notices it missing. Downstream this arrived as an owner
asking for tracker status three times and being forgotten three times — **with a correct,
auto-loading rule file already on disk stating the duty.** The rule was at the highest tier
available and it changed nothing.

`scripts/hook-tracker-status.py` runs at session start, calls this project's
`.astraler/project/tracker-status.sh`, and puts the counts in context before the first question is
asked. The duty did not get louder; it stopped existing.

**The general result, which is worth more than the hook.** Raising a document's tier makes an
obligation shout, and still depends on someone reading and acting. Injecting the data deletes the
obligation and depends on nobody. So: **where what is owed is DATA, inject it at the moment it is
owed; where what is owed is JUDGEMENT, the tier is all you have.** `hook-contract-reload.py` is
the second kind and this is the first, and shipping both states the difference.

Two boundaries, both from the failure that produced it. The hook **queries nothing itself** —
this package ships three tracker adapters, and a hook running one tracker's CLI would hardcode one
vocabulary into payload and undo the contract it serves, so the query is a fourth project plug.
And it **only reads**: a session-start hook fires on every session with nobody watching, which is
the wrong place to mutate a remote board. `AST-142`.

## A rule follows the role, not the runtime it was written for

New check 11, asked for by the downstream harness and buildable only here. `.claude/rules/` is
read by Claude and by nothing else. A project with six rules there, five of them named in no Codex
profile and no OpenCode adapter, is not leaking anything today if all five roles are assigned to
`claude` — it is a loaded trap. The day one runtime cell in `orchestrator.md` changes, five
always-on rules stop reaching that agent, silently, and the only signal is behaviour nobody
attributes to a config edit weeks earlier.

Check 11 reads the assignment table and the rules tier together and goes red on the pair. Project
layout only, and it says so rather than passing quietly: no package ships that tier.

## Also in this release

- `selftest.sh`: 76 → 100 cases. Every case added here was watched to FAIL first — including the
  three reachability fixtures, which break a copy of the payload on purpose so each new check is
  seen to fire and then seen to go quiet once the defect is fixed (AST-137).
- `hook-tracker-status.py` is tested for its failure discipline before its happy path: a missing,
  dead, silent, slow, non-executable or oversized plug each cost one line on stderr and nothing
  else. A session-start hook that can abort a session is worse than the problem it fixes.
- 33 ledger citations were marked `(gone)`. None of the entries changed: the narrative was always
  correct, only the binding label claimed a present that had passed.

## Upgrade from 2.9.0

Copy `harness/`, or `./install.sh <target> --apply`.

**If you are already on 2.9.0, run `--apply` and read the `owner` lines this time.** The new
ACTION on `.codex/profiles/*` will almost certainly fire: it is telling you that 2.9.0's
compaction rules never arrived. That is this release reporting the previous one's silent miss,
which is the whole point of the branch.

Writing `.astraler/project/tracker-status.sh` is optional and the hook says so once per session
until you do. `.agents/orchestrator.md`, `.claude/settings.json` and `.codex/profiles/*` remain
yours.

# Astragentic 2.9.0

Three findings from reading a harness built on the same payload in another project, and one
of the three is that a thing this package already shipped reached one runtime out of three.
The other two are a rule that nothing could refuse, and a guard that cannot be built — which
is reported rather than approximated.

## A rule reaches every runtime, or it reaches one

2.7.13 is titled *"the guard shipped for three runtimes and was registered on one."*
`hook-git-guard.py` lived in `.claude/settings.json`, which Codex does not read, so a Builder
on a Codex pane ran with the contract above it and nothing underneath. That release fixed that
one registration and stopped. **The class was never written down**, so nothing carried it
forward — and a grep of the ledger found no entry for it, in a package that had named a
release after it.

Asking the question 2.7.13 did not ask found two more instances:

| | claude | opencode | codex |
|---|---|---|---|
| `hook-contract-reload.py` registered | yes | no declarative hook surface | **no** |
| rules that outlive compaction, per role | 5/5 | 5/5 | **0/5** |

The second is the worse one. Those rules live in the adapter because **the adapter is the
system prompt**, and the measurement this package already holds is that after a compaction the
system-prompt rules were obeyed every time and every rule outside it was violated, with a total
correlation. A Builder dispatched to Codex was running the one configuration where the defect
has no defence at all, while the file documenting the defect sat two directories away.

`.codex/hooks.json` now registers the re-arm on `SessionStart`. All five Codex profiles carry
their role's compaction rules, wording identical to the other two runtimes so they cannot drift
apart quietly. `hook-contract-reload.py` no longer resolves the project through
`CLAUDE_PROJECT_DIR` alone — naming a Claude-only variable is 2.7.13 one layer down — and it
records every invocation, so the first real compaction on another runtime is a measurement
rather than an assumption.

**OpenCode is the named exception, by measurement rather than by assumption:** it has no
declarative hook file. Its plugin API exposes `experimental.session.compacting` with a mutable
context, which is a stronger intervention than re-arming after the fact, and is the path when
that API leaves experimental. Its adapters carry the rules meanwhile.

**The rule, stated so it outlives this release.** Anything the payload ships for a role or a
moment — a hook registration, a system-prompt rule, an adapter instruction — is declared for
every runtime that can carry it, and a runtime that cannot is named as an exception with the
reason. A surface that is silent is not an exception; it is an omission wearing one.

## The `Ledger:` line stops being a rule only the honest follow

Thomas's contract has required it since 2.0. `Ledger: none` is a valid answer and its absence
is not, because "this one taught us nothing" is a conclusion while no line at all is a step
that was skipped, and from outside those are identical. The project's own site advertises the
mechanism.

Measured in this package on 2026-09-14: **1 of the last 60 commits carried it.** The only
script that named the rule was `check-reachability.sh`, which verifies the rule is reachable
in a contract — not that any commit obeys it.

`hook-git-guard.py` now refuses a push of the base carrying a merge with no `Ledger:` trailer,
in the same block that already refuses one with no `ticket-done` stamp. It wants a **trailer,
not a mention**: prose saying "updated the ledger" is what a careful author produces when they
mean to comply, it is not machine-readable, and accepting it would pass on exactly the merges
that skipped the step.

**On the first push after upgrading**, merges already on your local base will be refused until
they carry the line. Amend each with `git commit --amend`. That is the check working on the
backlog it was built for.

## A guard that cannot be built, reported instead of approximated

AST-119 measured three contradictory messages arriving at Thomas presenting as one Builder's
handback, one of them a true technical fact under false authorship that Thomas nearly relayed
to the owner as real. It closes by naming what is missing: a provenance field on cross-session
messages. Another project shipped a `PreToolUse`/`Agent` guard for the class, so this release
went to build one.

Three candidate signals, all measured, all negative. A fork is not a separate OS process — its
shell's `PPID` equals `CLAUDE_PID` equals the single `claude` in `ps`. `CLAUDE_CODE_CHILD_SESSION=1`
is set inside a fork **and in the parent session**. No provenance field is observable in the
hook payload.

**The second nearly shipped.** A probe found the variable set inside a fork and said so, while
flagging that it had observed presence and *assumed* absence in the parent, because `ps eww`
prints no environment for another process on macOS. One command in the parent inverted the
answer. A guard built on the unverified half would have been registered, logged, reviewed, and
incapable of ever firing — AST-051 arriving by a route nobody would have called careless.

AST-139 records it so the next attempt does not start over from a transcript. Revisit when a
runtime exposes provenance on a message or a tool call.

## Also in this release

- `selftest.sh`: 58 → 76 cases. Every case added here was watched to FAIL first — five roles
  red, one registration red, five ledger-line cases red — which is the only thing that earns a
  case a place in that suite (AST-137).
- `hook-contract-reload.py` had **no selftest case at all** before this release. The hook
  defending the one failure with a measured total correlation had never been watched to fire,
  or to stay quiet.

## Considered and not done

**Moving `check-payload-drift.sh` out of the payload.** The concern was that a release can
replace the tool that watches for releases replacing things. Reading the script closed it: the
state that decides the outcome is `.agents/payload-drift-manifest.json`, which the payload does
not ship, so an upgrade cannot reset the hashes that give the check meaning. The circularity
was already cut at the half that matters.

# Astragentic 2.8.1

Two observations from the first project to run 2.8.0, and the repository work that lets a
reader arriving on GitHub tell which version they are looking at. No contract changed. Both
payload fixes are the same shape: a receipt and a log line now say what they actually know.

## A stamp that says what closed, not that something did

`ticket-done.sh` calls the project's own `ticket-done.sh` plug — the deploy trigger, the
changelog line, the notification each project owes at close. It recorded the outcome as
`project plug: ran`, which is a boolean wearing a sentence: it proves the plug exited 0 and
nothing about what the plug did.

The stamp now carries the plug's last output line — `project plug: ran — <line>`, or
`(printed nothing)` where a plug is silent. A plug that prints a deploy id, a changelog entry
or a notification target leaves that in the receipt where the next station reads it. The
plug's own output still goes to stderr as it runs, so nothing is swallowed in order to make
the stamp.

## A guessed base branch now says it is a guess

`hook-git-guard.py` resolves the base branch from `refs/remotes/<remote>/HEAD`. A clone that
never ran `git remote set-head` has no such ref, and the guard fell back to `main` in silence.
On a project whose base is `master` or `develop` that guards the wrong branch and reports
nothing — the failure class this package keeps measuring, where the reassuring branch is taken
without saying it was taken.

It still falls back to `main`, because refusing every clone with no remote HEAD would block
more than it protects. It now logs the guess, the reason, and the one command that turns the
guess into a fact:

```
base-guessed(main: no refs/remotes/origin/HEAD; run `git remote set-head origin -a`)
```

## Nothing in the payload, and everything for a reader arriving from outside

The repository had no tags and no releases. A visitor could read every line of the code and
not learn which version it was, and `VERSION` is a file you have to know to look for. Every
version this file documents now has a tag on the commit that set it, so the ladder from 1.0.0
to here is on the Tags page rather than only in here.

`docs/distilled/` is `docs/bmad-distilled/`, naming the method it was distilled from: a BMAD
roster and 44 capability files with the install machinery removed, which is the role kit half
of how this project works — separate from `mattpocock-skills`, which is the method wired into
the role contracts.

The vendored skills under `.agents/skills/` are gone — 448 files, copies of machine-wide
installations, never part of the payload, never staged by `install.sh` (which stages `harness/`).
The directory went with them.

`omnilogin-agent-browser` was kept at first, on the argument that its procedure is this project's
QA walk rather than a copy of something the machine provides. That argument was wrong, and the
same day proved it: the skill was edited here, the reload reported no changes, and the reason was
that the loaded skill is a symlink to a source outside this repository. Two files, one of them
read by nobody. A vendored copy of something that is already global is not a safety net, it is a
second place for the truth to live — and the copy is the one that goes stale in silence.

Two ProRes render masters are also out of the history: 1.4 GB each, 2.88 GB of the 3.08 GB
that had never been pushed. ProRes at 176 Mbit/s is what an editing codec is supposed to cost;
what the site actually serves is the same 70 seconds at 0.51 Mbit/s, 345 times smaller with
nothing visible lost. GitHub refuses any blob over 100 MB, so one of those in a commit made
every push fail — after uploading everything in front of it.

The files stay on disk and are rebuildable by re-rendering. What is new is that nobody has to
remember this: `.githooks/pre-commit` refuses a staged blob over 50 MB and names the file, and
each video project's `.gitignore` excludes `renders/` outright. Wire it in a fresh clone with
`git config core.hooksPath .githooks`.

# Astragentic 2.8.0

2.7.15 made the payload a chipset and shipped its first socket. 2.8.0 ships the second pin —
the one the first upgrade receipt measured the binding point for — and adopts the guard the
same project wrote when it found ours matching argv instead of reality. Three plugs are now
asked for at adaptation; the rest of the plug set follows in 2.8.x.

## A merge is not done until the push proves it

Every ticket merged-and-pushed in one turn was written back to the tracker; every ticket
merged-and-held for a gate was not, and nothing reported the omission (AST-057). The first
project to take 2.7.15 measured where a merge actually passes through git: twelve of twelve
recent merges were a local `git merge --no-ff` followed by `git push origin main`. So the push
of the base branch is where the obligation can refuse instead of being remembered.

`scripts/ticket-done.sh <id> --moved "<ids the write-back promoted, or none>"` is the call
Thomas makes after the write-back. It verifies the git half by ancestry (a subject match only
when the branch is gone), asks the project's plug for the tracker half, runs the project's own
after-close step, and stamps the id. `hook-git-guard.py` refuses `git push` of the base while a
merge commit in the pushed range leads with a ticket id that has no stamp; other branches are
untouched; squash merges carry no merge commit and are stated as unseen.

**On the first push after upgrading**, any merge already on your local base and not yet pushed
will be refused until it is stamped. That is the pin working on the exact backlog it was built
for — stamp each, then push.

Two plugs come with it, both asked for in `ADAPT-HARNESS.md` §3:

- **`tracker-state.sh <id>`** prints `<state> <assignee-or-dash>` — how *this* project reads
  its tracker from a shell (`gh issue view` on GitHub; a CLI or token elsewhere). Absent, the
  tracker half is stated as UNVERIFIED in the stamp and the push is admitted with that said,
  because refusing every project that has not yet written the plug would block the upgrade
  that asks for it. Present and saying `open`, the stamp is refused: the ticket is not done.
- **`ticket-done.sh <id>`** — what the project owes at close: a deploy trigger, a changelog
  line, a notification. Nothing, written down, is an answer.

## Residency by real cwd, adopted downstream-first

2.7.15's guard filtered `ps` output for a broker bound to the worktree. The project that took
it kept its own check instead and sent the block back: `lsof -a -d cwd -F pcn`, parsed in
Python, lsof's own pid excluded exactly, any malformed record rejecting the whole listing,
and the guard failing CLOSED when lsof cannot enumerate. Argv is a proxy for a working
directory, not the working directory — the same rule `reap-worktree-processes.sh` was adopted
for. Its two decisive cases are in the selftest: a resident whose argv never names the path
(argv matching said "none"), and a non-resident whose argv does (argv matching refused it).

## Also in this release

- The release-stamp check in the guard now runs after the uncommitted-changes check, so a
  human hears about data loss first.
- `selftest.sh` resolves its root by layout and names the package-only sections it skips in
  an adapted project — reported by two receipts before it was fixed.
- `reconcile-tracker` names `tracker-state.sh` as the scriptable tracker half.
- Selftest: 46 → 58 cases.

## Not yet in 2.8.0, and next

The remaining plugs from the chipset design — `setup-worktree.sh`, `gate.sh`, `run-app.sh`,
the judgement-label mapping that decouples `backlog` from the frontier, the ledger-prefix
socket, and moving project tooling out of the shared `scripts/` namespace — are 2.8.x. Each
ships with its call site and its refusal in the same commit, or check 9 stays red.

# Astragentic 2.7.15

The payload is a chipset: it states an obligation, the moment it falls due, and the question
the project must answer. The answer — which stack, which tool, which label — is the project's,
at a path no release writes. `SPEC-1.0.0.md` has carried the invariant since 1.0.0: *no project
or product noun appears anywhere in the payload.* This release is what a full scan of the
payload against that invariant found, and the two defects underneath it.

## The guard on the invariant never ran

`docs-staleness-audit.sh` axis 4 exists to catch a real ticket or project name leaking into the
scaffold. It compared an absolute path to the bare word `harness`, so the comparison could never
be true, and the axis printed `(skipped — this axis is about the scaffold …)` on every run, in
every layout, since it shipped. Verified by running it. A check that always takes the
reassuring branch is AST-051 wearing a comment.

It runs now, scoped to the scaffold (`.agents/memory/` is the record and cites downstream
measurements by id on purpose), and it blocks a release: `install.sh` refused to stage this very
version until the selftest's own planted id was assembled at runtime instead of written
literally. Two selftest cases were watched to fail against the shipped condition before the fix.

## One project's stack, hardwired at five call sites

What it had let through: a compose label and a companion-broker process name — one downstream
project's answer to "what does a worktree hold?" — written into `.claude/settings.json`'s
`WorktreeRemove` hook, `hook-git-guard.py`, `codex-arm`, `dispatch-ticket/CLEANUP.md` and
`UNINSTALL-HARNESS.md`. A project on any other stack read "cleanup exists" and released nothing.
Measured downstream in one night: 43 orphaned processes, 3,405 leftover databases (25 GB), load
average 123, one Builder killed by the OS. Meanwhile the one generic tool the package ships,
`reap-worktree-processes.sh`, had no call site at all.

## The socket

`scripts/release-worktree-resources.sh <worktree>` is the one call, made before every worktree
removal on every runtime. It reaps processes rooted in the worktree by real cwd — the harness's
own part, the companion broker included — and then runs the project's plug:

```
.astraler/project/cleanup-worktree.sh <worktree-path>
```

`.astraler/project/` is project-owned and tracked in git. `install.sh` never writes there, so an
upgrade cannot overwrite the answer. `ADAPT-HARNESS.md` §3 now asks the question — *what does a
worktree allocate in this project beyond git, and what releases it?* — and §7 records the
answer in the receipt. An absent plug is reported as an empty socket, not a clean one; a plug
that fails fails the call; nothing is `|| true`d (AST-057). Four selftest cases cover the
socket's outcomes.

**And the call is enforced, not remembered.** A clean run stamps the resolved path under
`/tmp/harness-released/`, and `hook-git-guard.py` — loaded by the Claude and Codex hook sets —
refuses `git worktree remove <path>` for any path without a stamp, `--force` included. Until now
the only call site for the reap was prose at the end of `CLEANUP.md`, and prose at the end of a
ticket is exactly what gets skipped. The owner's rule, applied to the thing that carries it: a
tool nobody calls does not exist. `check-reachability.sh` gains check 9 for the same rule —
every shipped script must be named from session context, a skill, a runtime hook, the
installer, or a script one of those calls — measured on this package: 14 scripts, 0 orphans,
where a hand count a week earlier found one.

The enforcement case found a second defect on its first run, a real one: the guard's broker
check was a `bash -c "ps | grep app-server-broker | grep <path>"` pipeline, and that shell's own
argv carried both strings, so the grep matched itself and refused every removal of an existing
directory as "a broker is still bound". Nothing had ever exercised the guard against a real
directory. It now filters `ps` output in Python (AST-133's shape, in a script that cites it).

The five call sites now make that call. The git guard keeps refusing a removal while a process
or the harness's own broker is bound to the tree, and no longer pretends to know the project's
containers. `codex-arm`'s cleanup lost the project-level `make` target it used as a
counter-example; the lesson it carried (a project-level teardown stopped the shared container
every live Builder stood on, AST-115) is kept as the rule the plug must obey: scope to this
worktree, or release nothing.

## Gate on the committed SHA

`thomas.md` § Merge now states the order: commit the merge, then gate on the committed SHA. The
contract said "clean final SHA" and never said *when* to commit relative to the gate; a project
read it as `merge --no-commit → gate → commit`, under which every check that reads git history
reads the history before the merge and certifies it. Measured: `Gate PASSED` on a tree the
re-derivation had not seen, base red for 90 minutes.

## Examples no longer borrow a downstream prefix

`tracker-contract.md` named the two projects it was measured on; both are now "a live project".
`orchestrator.md`, `dispatch-ticket`, `ticket-git-facts.sh` and `reap-worktree-processes.sh`
used one project's real ticket ids as their examples, kept alive by an allowance in the very
check meant to catch them. All are the generic `ABC-nnn` series now, and the allowance is gone.
`check-reachability.sh`'s vocabulary list loses the two project names and the `make` target.

## What did not change, on purpose

- **Skill names stay.** `mattpocock-skills:implement`, `grill-with-docs`, `/tdd` and the rest
  are named as rules across the role contracts. The scan flagged them; they are not a
  project's answer, they are the method the chipset runs — a declared dependency, which
  `ADAPT-HARNESS.md` §2 already verifies.
- **The tracker write-back after merge is unchanged.** It is a remembered obligation at the
  same moment as cleanup, and it drifted the same night for the same reason. Decoupling
  frontier correctness from it is a contract change and belongs to 2.8 with the rest of the
  plug convention.

## Upgrading

Write `.astraler/project/cleanup-worktree.sh` (executable, takes the worktree path, releases
what THIS worktree allocated, prints what it released). A project whose worktrees allocate
nothing beyond git writes one that says so. Until it exists, every worktree removal prints the
empty-socket `NOTE:` line — that line is the upgrade's to-do, not noise. Selftest: 46 cases.

# Astragentic 2.7.14

A role's operating contract does not survive compaction, and nothing re-armed it. Measured
downstream, on a session that had read the contract at start and then stopped following it
for hours without noticing.

## The four rules that survived, and everything that did not

A role contract is read with the Read tool, so it lives in the conversation as a tool result,
and tool results are the first thing compaction summarises away. What survives is
`.claude/agents/<role>.md` — the system prompt — carrying four rules.

Measured on one long autonomous session in a downstream project that compacted once:

- **The four rules in the system prompt: obeyed, every time, all session.**
- **Every rule outside it: violated, and none noticed until the owner asked.** A ticket
  dispatched as an in-process subagent instead of a visible pane. Worktrees branched off a
  stale local `main`. Roughly twelve label writes with zero board syncs. Twenty-six merges
  past a gate that stops at ten.

The correlation is total, which is what makes it a design report rather than an incident
report. Nothing inside the surviving list was forgotten and nothing outside it was remembered.
That is the split behaving exactly as built.

## The word that does not survive is "now"

The system prompt already says **"Read `.agents/roles/<role>.md` now"**, and that line comes
through compaction untouched — it is the system prompt. What does not come through is the
moment. A compacted agent reads its own summary, sees work underway, concludes it is
mid-session, and never re-reads. `AST-069`: an instruction with no moment attached measures
zero.

Growing the surviving list is not the fix either. It is a fixed budget of four because
system-prompt space is not free, and moving the whole contract in defeats the separation.

So supply the moment instead. `SessionStart` fires with `source: compact`, and its
`hookSpecificOutput.additionalContext` reaches the agent before it acts. `scripts/hook-contract-reload.py`
names the exact contract when the payload carries `agent_type`, and otherwise says enough that
the agent resolves the path from its own system prompt.

**`compact` only, and that is deliberate.** After `/clear` an agent faces an empty context and
reads its contract unprompted; after compaction it faces a summary insisting work is underway,
and does not. That asymmetry is the entire defect. Firing on `clear`, `startup`, `resume` or
`fork` would spend context re-arming a session that is already armed.

**Claude Code only, and that is also deliberate — this is not `AST-137` again.** 2.7.13 shipped
a guard for three runtimes and registered it on one, which was a defect because the rule was
runtime-neutral. This one is not: Codex and OpenCode have no compaction, so there is no moment
to hook and nothing to re-arm. Those runtimes already carry the matching instruction in their
contracts — write a durable checkpoint, because context grows until the session ends.

## The half that would have shipped and never arrived

`.claude/settings.json` is an owner file: `install.sh` writes it only when absent. So a hook
added to the payload reaches a fresh install and **never reaches a project that already has
one**. Verified against a live 2.7.10 project: it carried the three hook events it was
installed with, `--apply` printed `owner (kept — yours)`, and nothing anywhere said an event
was missing.

`ADAPT-HARNESS.md` already had the right rule for `orchestrator.md` — keep the owner's values,
report the shape change for the owner to merge — and simply did not name `settings.json`. It
does now, with the distinction the rule needs: **owner tuning is theirs, the hook set is
safety machinery the release ships.** Preserve every owner key and every hook they added;
merge in any hook event the release ships that they have no entry for.

`install.sh` now names the specific missing events instead of printing `kept — yours` and
moving on. **It reports and does not merge**, because nothing mechanical distinguishes an
owner's deliberate removal from a stale copy, and merging over the first is the silent
overwrite `AST-041` exists to forbid.

## What is measured here, and what is not

Measured: the hook fires on `compact` and stays silent on `startup`, an unknown role falls
back rather than inventing a path, malformed stdin produces nothing rather than a traceback,
the gap detector correctly reports `SessionStart` missing against a real project's
`settings.json`.

Not measured: that a re-armed agent behaves differently after a real compaction. That needs a
long session to compact on its own, and it has not happened yet under this release.

# Astragentic 2.7.13

The guard shipped for three runtimes and was registered on one. Plus the three Codex
configuration surfaces this package had been treating as one.

## A second layer that existed on paper and nowhere else

`hook-git-guard.py` describes itself as a second layer under `dispatch-ticket/CLEANUP.md`.
It was registered in `.claude/settings.json`, which **Codex does not read**. A Builder
dispatched to a Codex pane ran with the contract above it and nothing underneath.

The file had already written the finding down, in a sentence that was true when written and
then stopped being a description and became a defect:

> a rule that lives only here is a rule that does not exist on two of three runtimes

Read as correct by both parties, repeatedly, for eleven releases. `AST-137` again.

`.codex/hooks.json` now registers the **same script**. The safety rule is runtime-neutral;
registration stays native to each runtime. The command resolves the guard from either an
adapted-project layout (`scripts/`) or this package (`harness/scripts/`), and when it finds
neither it says so on stderr and logs it rather than failing open in silence.

**Registration is not enforcement.** Codex reviews project-local hook definitions by hash, and
an absent trust decision means the guard is installed and skipped. `check-requirements.sh`
checks the registration; only the operator can confirm trust, with `/hooks` in the Codex CLI.
The check reports what it can see and names what it cannot, rather than implying coverage.

## Three surfaces, three jobs, one file extension

Codex has four places a role can be configured, and this package had documentation for one:

| Surface | Job |
|---|---|
| `AGENTS.md` | project instructions, loaded as a user-role message |
| `${CODEX_HOME}/<role>.config.toml` | **machine-local launch profile** — the pane's role identity, model, effort |
| `.codex/agents/*.toml` | project-local **custom subagent types** a running session may spawn |
| `.codex/hooks.json` | project-local lifecycle hook registration |

Two of those are TOML under a `.codex/` directory, which is the whole trap. A custom subagent
does not make `--profile builder` resolve, does not allocate a branch or a worktree, and does
not produce a visible Herdr pane — it **shares the parent session's topology**. Routing a
Builder through one because both surfaces use TOML gets you write-heavy work with no isolation
boundary and no pane to watch it in.

`sandbox_mode = "read-only"` is a **requested default, not a boundary**. Codex reapplies a
parent's live permission overrides to children, so a parent launched with bypass can weaken it.
The instructions in each helper forbid writes as well, but worktree and branch allocation
behind a visible pane stays the only accepted boundary for a lifecycle role.

Two read-only-intent helpers ship: `astragentic_explorer` for mapping code paths and gathering
evidence, `astragentic_reviewer` for a second read over a diff. Neither may claim a ticket,
cut a branch, dispatch, or present its result as a gate verdict.

## Payload or scaffold, and why the answer differs inside one directory

`.codex/profiles/` carries the owner's model and effort choices, so it stays **scaffold**:
written when absent, never overwritten (AST-041).

`.codex/hooks.json` and `.codex/agents/` carry no model choice and are **payload**. Classifying
them as scaffold would have been the quiet failure: a safety fix to the guard registration
would ship into the release and never reach a project that already had the file.

## Two cases, both shaped by the rule 2.7.12 recorded

`selftest.sh` gains the Codex pair, and neither asserts the answer it wanted:

- The hook case builds an adapted-project layout, extracts the command **as registered**, and
  pipes a real `PreToolUse` event at it. Parsing `hooks.json` proves the JSON is well-formed;
  running the script directly proves the script works. Neither proves the registered command
  resolves the installed path or that stdin reaches the guard, which is the only thing that
  matters at 3am on a Codex pane.
- The custom-agent case parses the shipped TOML and asserts `read-only` and non-empty
  instructions, so the helpers cannot silently lose the property they are described by.

`check-requirements.sh` gains the matching pair on the doctor side, and reports missing
`tomllib` as a warning rather than a pass.

## The fossil 2.7.12 left

2.7.12 bumped `VERSION` and `RELEASE-NOTES.md` and left the README badge reading 2.7.11 — the
class 2.7.8 exists to describe, shipped in the release that closed the cycle it described.

## Migration

An adapted project needs the two new payload paths and one manual step:

1. Re-run the payload install to receive `.codex/hooks.json` and `.codex/agents/`.
2. In the Codex CLI, run `/hooks` and confirm trust for the project hook definition.
   Until that happens the guard is installed and skipped, and `check-requirements.sh`
   cannot tell you so.

Projects that do not dispatch to Codex are unaffected.

# Astragentic 2.7.12

The last release of this cycle. One drift class the tracker layer was missing, and one
operational rule that turns out to matter more than the entry it belongs to.

## A fourth drift class, found by reading a board rather than running anything

`reconcile-tracker` listed three: lagging, phantom done, stale claim. **Stale claim keys on
"assignee set, no branch". Nothing watched the inverse.**

A live project reported five tickets at once in the working state with **zero assignees** —
`in-progress` labels with no claim behind them. On the GitHub adapter, where the assignee *is*
the claim, that means either a claim never made or a label nobody cleared, and the tracker
cannot tell you which.

**It is the class that corrupts the frontier**, which none of the other three do. The frontier
is *"every ticket whose blockers are done and whose assignee is empty"* — so a ticket in the
working state with no assignee is **excluded from the claimable set while nothing is working
it**, indefinitely, because nothing revisits a label. Five tickets invisible to the query that
decides what gets built.

Added, with the branch check that distinguishes the two causes: unmerged commits and no
assignee is a dispatch whose claim step was skipped; no branch at all is a label left behind.

## The rule `AST-137` does not state

The project that produced that entry supplied its operational half afterwards, and it survives
better than the entry's own wording:

> every instance of `AST-137` we have found was caught by **making the thing fail on purpose**,
> and none by reading

True of all of them. Restoring a real fossil into a tree and re-running. Passing a 40-character
SHA instead of a branch name. Editing a payload file and watching the check stay green. Building
an actual dual-homed symlink. **In every case the code had already been read, by both parties,
and read as correct.**

It is recorded in `selftest.sh`'s header rather than appended to the entry, because the ledger
is append-only and because that file is where the rule has to be obeyed:

> a case here does not earn its place by asserting the right answer. It earns it by having been
> watched to FAIL first. If you add one that passed on the first run, you have written a test
> for the invocation you already believed in — which is the defect, not the check for it.

## Where this cycle ends, stated plainly

Thirteen releases in three days. Twenty-three defects found by four cross-vendor gates before
2.7.0 shipped, and **fifteen more found by one live project afterwards** — seven of those
introduced by the audit that produced 2.7.0, and several introduced by the fixes for the
earlier ones.

**Every check in this package now proves the tooling is correct. Nothing in it proves the loop
works.** No ticket has gone through dispatch → build → `code-review` → simplify → `arm(ticket)`
→ merge with the gates firing on live work in this cycle. Those are different claims, and the
gap between them is real, unmeasured, and not closable by any check either side can write.

That gap is left open on purpose rather than papered over, and the five unclaimed `in-progress`
tickets above are a small piece of evidence for it: **a gate nobody fires and a label nobody
clears are the same failure in different clothes, and only one of them had a script watching.**

## Migration

None.

# Astragentic 2.7.11

**This package had no self-test.** Sixteen defects across eleven releases, every one of them an
invocation-shape defect, and nothing in the repository could reproduce a single one. A
downstream project ships a 17k self-test for its worktree reaper and a 10k one for its marker
checker; the package they came from shipped none.

`scripts/selftest.sh` is that, built the only way `AST-137` allows: **a list of invocation
shapes, one per defect actually shipped**, each labelled with the release that shipped it.

```
hook-git-guard — accidental misuse it must catch          7 cases
hook-git-guard — correct work it must NOT block           7 cases
hook-git-guard — out of scope: silent by design           6 cases
argument conventions — flag position must not matter      3 cases
root resolution — bare, explicit root, unrelated cwd      6 cases
marker gate — advisory span, regex dialect, line width    3 cases
install.sh — package root, staged release, spaced path    3 cases

selftest: 34 passed, 0 failed.
```

Half of the guard cases are commands it must **not** touch, because three of this cycle's
defects were checks firing on correct work — and a suite that only tests the catching half
would have passed on every one of them.

The `install.sh` cases are the ones no unit test would have written: staging from a package
root, staging from **inside a staged release** where `prompts/` is flattened, and staging from
`/tmp/Astraler Repo`. Each was a shipped defect. Each is one substitution away from the shape
that was tested.

## The self-test's own defect, fixed before it shipped

The first version edited the repository's real `INDEX.md` and restored it afterwards. That is
fine until a case fails, the script exits early, and the restore never runs — leaving the tree
dirty and the next staging gate red for a reason unrelated to the payload. It happened on the
first run.

**A self-test that can damage what it inspects is worse than no self-test.** It works on a
throwaway copy now, and running it leaves the tree exactly as it found it.

## And a near-miss worth more than the fix

While closing 2.7.10's `.claude/` false positive in the package's own repo, I derived the
payload list from `harness/` and dropped the path prefix. `[ -e ]` then failed on every entry,
so the payload-committed check **examined nothing and printed OK** — a check that cannot fail,
inside a release fixing checks that cannot fail.

Caught by editing a payload file and watching it stay green. That is the only way this class is
ever caught, and it is now a case in the suite.

## Migration

None. `scripts/selftest.sh` ships in the payload; run it after editing any script.

# Astragentic 2.7.10

**2.7.9's fix for a false positive was a regression that made the gate unpassable on a layout
this package documents as supported.** That is a worse trade than the defect it closed, and the
project that reported both said so first.

## A payload path through a symlinked parent is not untracked

2.7.9 stopped treating everything under `.claude/` as payload and began deriving the list from
the staged release, then asking git about each **literal path**. A project may **dual-home** a
skill: real content at `.agents/skills/<name>/`, with `.claude/skills/<name>/` a symlink to it.
Git tracks the **link**; paths *through* it are correctly absent from the index. So three files
that are tracked, at their real home, on the same inode, were reported untracked:

```
2.7.8  check-requirements.sh . --adapted  ->  EXIT 0
2.7.9  check-requirements.sh . --adapted  ->  EXIT 1
```

Same commit, clean tree, nothing else different. `git status` reported nothing untracked there.

**And this package already blesses the arrangement.** `check-payload-drift.sh`'s own header:
*"A project may dual-home a skill… Both arrangements are legal in a project, and this watches
whichever one it is told about."* It ships `SYMLINK` manifest rows for exactly this. **One
shipped script called the layout legal while another refused it.**

A path that looks untracked is now resolved through its symlinked parents and asked again. The
realpath is computed only for paths that already failed the first lookup, so the common case
costs nothing, and a genuinely untracked file still reports untracked — both directions
verified.

Also: the release ships `check-requirements.sh` at two paths, so it appeared twice in the list
and was counted twice in the verdict. Deduplicated.

## The shape, for the third release running

I fixed a false positive against a project whose `.claude/` holds real files. The project that
reported it holds symlinks there. **Tested path, real path, one substitution** — `AST-137`,
arriving through the door I opened while closing another.

The reporter's own reading is the one to keep: *"my minor was worth less than the regression it
bought"*. A check that fails a correct project is worse than a check that occasionally names a
file it does not own, and if this fix had not been cheap the right answer would have been to
revert 2.7.9's entirely and let the false positive stand.

## Migration

If you held a payload file to keep `--adapted` green under 2.7.9 — the reporter held
`scripts/check-requirements.sh` at 2.7.8 and named it in `ADAPTATION-REPORT.md` — **that hold
can be released now.** Take 2.7.10's copy and remove the entry.

# Astragentic 2.7.9

Three defects, and the first one is the code disobeying a comment two lines above it.

## A stale `apply-incomplete` marker was ignored when applied == candidate

2.7.6 added the marker and this comment: **"That file is the signal; the version strings are
not."** The code then tested the version strings first, with the marker's `[MISS]` behind an
`elif`. So a project with an unreconciled conflict recorded on disk read
`[OK] matches CANDIDATE` for as long as nothing new was staged.

**The false green appears exactly when the project looks most settled**, and the state is not
exotic — `install.sh` instructs an operator into it: *"stamp the version by hand and say why"*
leaves applied == candidate with the marker still there. Measured downstream on a project's
`main`, at rest, with a conflict named in the file.

The marker is tested first now, and `install.sh`'s own instruction says to delete it when you
stamp by hand, because a stamp alone leaves a file asserting the opposite of what you meant.

## `deleted-upstream` could not see a rename from a skipped release

2.7.8's deletion detection compared the **applied** release against the candidate. A rename is
only visible on the single upgrade step that performs it, so a project that **skips** the
release doing the rename never sees the fossil — which is the situation of every multi-version
upgrade, and the premise of this whole cycle.

The project that reported it did not infer this: it restored the real fossil into `scripts/`,
re-ran `--plan`, and got `deleted-upstream 0`. The baseline is now the union of every staged
release older than the candidate, which costs one extra walk of directories already on disk.

## `.claude/` is not all payload

The payload-committed check walked `.agents/`, `.claude/` and `.codex/` wholesale. An owner's
own operating notes for their Thomas tab sat at `.claude/loop-snippets.md`, and the check
reported it as *"harness payload untracked"* — a `[MISS]` about a file this harness does not
own and has never shipped. The list now comes from the staged release, with the directory walk
as a fallback for a project that has pruned `.astraler/releases/`.

## And twice I claimed a release was staged when it was not

2.7.7 was cut, committed and pushed, and never staged into the downstream project. I said it
was. The project caught it, I acknowledged it, and then **it happened again** — the same
release, the same claim, the same omission. It was only ever visible because someone else
looked.

Nothing in this package checks that. Staging is per-target and voluntary, so there is no state
to compare against; the failure is entirely in the reporting, and the honest fix is that a
release is staged when `.astraler/releases/<v>/` exists in that project and not when I say so.

## Migration

Run `install.sh <target> --plan` once. `deleted-upstream` now looks across every older staged
release, so it may name fossils from renames in releases you skipped. They are reported, never
removed.

# Astragentic 2.7.8

**A rename left a fossil in every adapted repo, and `install.sh` structurally could not see it.**

2.7.6 renamed `ledger-rules.sh` to `.py`. An `--apply` wrote the new name and **left the old
one**, so the project carried two byte-identical copies of one script under two names — the
third instance of that shape in a single upgrade, after the two `project-status-sync.sh` and
the two payload-drift watchers.

`install.sh` iterates the CANDIDATE's files. **It has no concept of a path the PREVIOUS release
carried and this one does not**, so a rename is invisible to it as a deletion. Nothing
downstream catches it either: `check-payload-drift` does not watch it, and the integration
check cannot, because a file the release does not ship is not a file that *differs* from the
release. Left alone, **every rename this package ever makes leaves a fossil in every adapted
repo, permanently.**

`--plan` and `--apply` now derive `previous-release − candidate` and report it:

```
DELETED by this release — 2.7.6 shipped these, 2.7.7 does not, and they are
still in the project. Usually a rename; check for the new name before removing.
  scripts/ledger-rules.sh
  (not removed automatically: a project may have adopted one of these on purpose)

  new 0 · updated 0 · unchanged 81 · kept 0 · owner-kept 7 · conflicts 0 · deleted-upstream 1
```

**Reported, never removed.** A project may have adopted the old path deliberately, and deleting
files during an upgrade is precisely how an upgrade destroys work. Owner paths are excluded
outright.

Also: `ledger-rules.py`'s module docstring still opened with the old `.sh` name.

## And a process note that outranks the defect

The owner authorised a merge in a downstream project and asked me to relay the instruction. I
did. **The receiving agent refused it and asked the owner directly**, on the grounds that its
standing instruction was not to merge, and a peer reporting that the owner said otherwise is
indistinguishable from a peer inventing it. Its own words:

> it cost one question and it is the only thing standing between "the owner approved" and
> anyone being able to say so

The authority was genuine and the relay was still the wrong shape: I built the exact pattern a
mistaken or compromised peer would use, which makes a correct refusal indistinguishable from
obstruction. **Relay context freely — findings, ordering, what must be verified first. Never
relay permission.**

That refusal is the single most valuable thing to come out of this deployment, and it came from
the agent being instructed rather than from any check in this package.

## Migration

Run `install.sh <target> --plan` once. If it reports `deleted-upstream`, those are almost
certainly renames from a release you already took; check for the new name, then remove.

# Astragentic 2.7.7

2.7.6 fixed one of three places that made the same mistake, and shipped.

The defect 2.7.6 closed was that comparing `applied-version` against `CANDIDATE` turned a
healthy project's own gate red the moment somebody upstream staged a release. **Checks 2 and 3
were still comparing against the staged release one line below the fix.** A project sitting
correctly at 2.7.5 with 2.7.6 staged failed on files it has no reason to carry yet, and on
`ledger-rules.py` — a script the newer release had renamed and the older one, correctly, does
not have.

Both now measure against the release that is APPLIED, falling back to the candidate only when
no applied release is staged. The script list comes from the applied release too, so a rename
in a release you have not taken is not a missing file.

Ninth instance of `AST-137`, and this one is worth naming for a different reason than the other
eight: it was not a tested-versus-real gap at all. **It was fixing one of three call sites that
share a comparison and shipping without checking the other two.** The entry's rule generalises
one step further than it was written: after correcting a comparison, grep for the value being
compared, not for the symptom.

Verified on the project that reported the original: EXIT 0, with the advisory reading
*"applied-version (2.7.5) is landed and clean — release 2.7.6 is staged and not started"*,
which is the true statement about that repository.

## Migration

None.

# Astragentic 2.7.6

Two defects, both self-inflicted, and one of them arrived because I said "nothing queued".

## Staging a release turned a healthy project's gate red, remotely

Running `install.sh <target>` writes `.astraler/CANDIDATE`. Nothing else in that project
changes — no payload file, no contract, no decision by anyone there. But `--adapted` compared
`applied-version` against `CANDIDATE`, so a **fully applied, healthy project** went from EXIT 0
to:

```
[MISS] applied-version '2.7.4' does not match CANDIDATE '2.7.5'
```

Anything running that check on a schedule — CI, a session-start hook, a pre-merge gate —
reported a failure whose entire cause was an event **outside the repository**. The honest
reading of that red is *"a release is available"*, and that is not the same message as *"this
project is broken"*.

**Two different states were collapsed into one `[MISS]`:** an apply that stopped on conflicts,
which is the project's problem and correctly red; and a newer release staged and never started,
which is not a failure at all.

The signal to tell them apart already existed one layer down — `install.sh` exits 3 and stamps
nothing when conflicts remain — but an exit code does not survive the moment. It now also
writes `.astraler/state/apply-incomplete`, carrying the version and the conflict list, and
removes it on a clean apply. **That file is the signal; the version strings are not.** Three
states now:

- versions match → `[OK]`
- `apply-incomplete` present → `[MISS]`, with the version and a pointer to the conflict list
- versions differ, no marker → `[OK]`, plus an advisory note that a release is available

The advisory reasoning is the same one the milestone markers got two releases ago: **a state
that is true whenever someone upstream is working is not a finding, and printing it as one
trains the reader to skip the check.**

The project that reported it called it the eighth instance of `AST-137`, and the first neither
side went looking for: the check was tested where CANDIDATE and applied-version move together,
and the real path is a project sitting still while somebody else stages. Tested invocation,
real invocation, one substitution.

## `ledger-rules.sh` was Python behind a `.sh` name

2.7.0 renamed `hook-git-guard.sh` to `.py` and put the reason in the file: *"`check-reachability.sh`
is Python behind a `.sh` name, and the cost of that showed up as an adaptation step telling
operators to run `bash -n` on it. **One such file is enough.**"*

The same release then shipped a second one. `ledger-rules.sh` is now `ledger-rules.py`.

`check-reachability.sh` keeps its name **deliberately**: it is referenced by the README, the
adaptation prompt, `install.sh` and every adapted project, and renaming it is a migration for
every downstream repo in exchange for a naming preference. `ADAPT` §6 already carries the
correct instruction — run it with `python3`, not `bash -n` — which is the part that actually
cost something.

Historical release notes were briefly rewritten to say `.py` while making this change, and
restored. Releases 2.7.0 through 2.7.5 shipped a file called `ledger-rules.sh`, and their notes
say so.

## Migration

If you have automation calling `scripts/ledger-rules.sh`, it is `scripts/ledger-rules.py` now.
Nothing else.

# Astragentic 2.7.5

A correction to 2.7.4's closing paragraph, and the ledger entry the correction produced.

## The arithmetic in 2.7.4 flattered the wrong side

2.7.4 closed by saying four cross-vendor gates found what lives in a diff and one live project
found what lives in a repository. The project that made the measurement objected, against its
own interest, and it is right:

> three of my eleven were only findable because your own checks caught them or asked the
> question — check 3's "no record says why" is what exposed my incomplete receipt, the staging
> gate is what surfaced the stale INDEX, and the margin report is what made the budget overflow
> legible instead of a number I would have shrugged at

So the split is not two independent detectors. **The gates are what made the repository legible
enough to be searched.** A check that says "these eight files differ and nothing records why" is
not competing with field use; it is what turns a working install into a question someone can
answer. Stated the other way round, it flatters this package's method and understates what its
own checks did.

## AST-137 — the reusable half

The same project supplied the narrower finding, and it survives where the arithmetic did not.
**Every one of the eleven defects lived in the gap between a tested invocation and a real one:**

| tested as | actually invoked as |
|---|---|
| `harness/scripts/…` | `scripts/…` in an adapted project |
| `install.sh` from a package root | `install.sh` from inside a staged release, where `prompts/` is flattened |
| index generated from the source tree | index validated against the staged tree, which carries one injected file the source lacks |
| `--check` as `$1` | `--check` as `$2`, where it silently rewrote what it was asked about |
| a branch name, 4 characters | a resolved merge-base SHA, 40 |
| `.git/hooks/pre-commit` | `core.hooksPath`, which overrides it entirely |
| a path with no spaces | `/tmp/Astraler Repo` |

**None of these needed a repository with history.** They needed a caller that invokes things
differently than the author does — a different cwd, layout, argument position, shell, or ref
form. That is far cheaper to reproduce than "a real project", and it is the half that
generalises to anyone shipping a payload into somebody else's tree.

**The rule: a test that does not build the exact call the production path builds is not a test
of that path.** Where a script takes a root, run it bare AND with an explicit root AND from an
unrelated cwd. Where it takes a ref, pass a 40-character SHA. Where it ships into two layouts,
run it in both. Where a check has a flag, put the flag in every position.

## Also

The `never recorded` advisory line is 126 characters on a repository that has never run the
gate. The project that reported the 114-character wrap explicitly did **not** call this one a
defect — *"it is the line that prints at every merge until the first round, and of all the lines
in this system it is the one with the best claim to being long"* — and I agree. Left as is.

A live confirmation of 2.7.2's fix, worth recording because it is visible: `AST-137` reads
**uncited** in the source tree and **cited by `check-requirements.sh`** in the staged payload,
because `install.sh` injects that file into `harness/scripts/`. Derived files are regenerated
against the staged tree, so what ships is right even though the tree it was built from is not.
That divergence was defect 10; this is the fix working where it can be watched.

## Migration

None.

# Astragentic 2.7.4

Two small things and one ledger entry that has been earned three times.

**The advisory line wrapped on the invocation that actually happens.** 2.7.3 shortened the
marker SHA and left the caller's `base` ref verbatim. The scratch test that validated it passed
`main`, four characters; **Thomas passes a resolved merge-base at merge time**, forty. The line
went to 114 characters and wrapped, on the path nobody had run.

The downstream project that found it named the shape better than this note can:

> the tested path and the real path differ by one substitution

That is the third time this release cycle has produced exactly that defect — a guard tested on
the cases its author thought of, a staging gate tested from a path without spaces, and now an
advisory tested with a branch name. Both refs are shortened now; the line is 83 characters.

**AST-136 — `--grep` is BASIC regex, and every marker kind in this system contains
parentheses.** Third occurrence of one mistake, each wearing a different fault:

- **2.3.35** put `re.escape(kind)` into `--grep`; the escaped name matched nothing and the
  script reported a confident STOP naming the wrong cause.
- **2.3.36** searched whole messages rather than subjects: 23 real markers read as 193. That is
  `AST-133`, whose lesson — *"`--grep` is not a subject matcher"* — is the broader half.
- **2.7.2** did it again in the new advisory path, so a marker sitting on the base branch
  reported `never recorded`. The span fix shipped beside it **would have looked correct
  forever**, because the count printed zero either way.

The narrow rule `AST-133` does not state: **pass `-E` whenever the pattern contains a kind
name.** The naming convention guarantees a parenthesis, so every kind added later hits this.

Its general lesson is about tests rather than regex, and it is the same one as the wrapping
line above: a test that does not exercise the exact pattern the production call builds is not a
test of that call.

## What this cycle looks like from here

2.7.0 was cut after four cross-vendor gates found 23 defects. A live project on 2.3.34 then
found **eleven more in three days**, of which seven were introduced by the audit that produced
2.7.0. Four releases later the arithmetic is worth stating plainly: **the gates found the
defects that live in the diff, and the project found the ones that live in the difference
between a diff and a repository.** Neither substitutes for the other, and only one of them was
in this package's method.

## Migration

None.

# Astragentic 2.7.3

One defect, and it is in the fix 2.7.2 shipped for the finding 2.7.1 could not see. The gate
emitter was right; **the span was wrong**, and the wrong span made it noise.

## A line that is always right is wallpaper

2.7.2 gave Rin's gate a marker and had `check-simplify-markers.sh` report its absence in the
merge range. Run against real history in a live project, over its last eight ticket merges:

```
merge 6da76b40  rin(gate): NONE (6 commits)   qa(walk): NONE
merge 8f56fb6b  rin(gate): NONE (9 commits)   qa(walk): NONE
… eight merges, sixteen NONE lines
```

**Every one of those is structurally guaranteed.** `rin(gate)` is a MILESTONE marker; a merge
range is a TICKET branch; a milestone marker can never appear in one. So the line was true at
100% of merges by construction — wallpaper inside a week, and then worse than wallpaper,
because it teaches its reader that absence is the normal state. That is exactly the
desensitisation that makes the one meaningful absence invisible.

**Loud-and-always is the same as silent**, which is the failure this marker kind was added to
leave behind. Tuning the wording would not have fixed it.

## The number the counter was always asking for

`thomas.md` says *"more than 10 merges since the last Rin round is a STOP"*. The quantity that
sentence names is **merges on the base since the last marker of that kind** — not commits in a
ticket range. That number:

- is computable only because the marker now exists — the 2.7.2 emitter doing its job;
- **changes over time**, so it can cross a threshold, which `NONE in range` never could;
- returns to zero when a round runs;
- is silent where absence is definitional.

```
[rin(gate)] last on main: e479de492 (2026-08-27) — 5 merge(s) since (advisory)
[rin(gate)] never recorded on main — 42 merge(s) of history, no round
```

A rising integer beside a stated threshold argues for itself. It needs no message tuned to be
loud, which is the property the previous version was trying to buy with volume.

Also fixed, and it would have hidden the whole thing: `git log --grep` is BASIC regex by
default, where `\(` is a GROUP. The escaped kind name `rin\(gate\)` matched nothing, so a
marker sitting on the base branch reported as "never recorded". `-E` makes an escaped paren a
literal one. Verified by committing a marker, merging five times, watching the count reach 5,
committing a second marker, and watching it return to 0.

## Migration

None. If you took 2.7.2, the advisory lines change shape and stop appearing per merge range.
Nothing blocks either way.

# Astragentic 2.7.2

Three more defects from the same live project, and the one finding this release cycle has
produced that changes the method rather than repairing it.

**2.7.1 could not be applied by its own installer.** Two reasons, both only visible from inside
a staged release:

- `install.sh` resolved `$HARNESS_ROOT/prompts/ADAPT-HARNESS.md`, and staging FLATTENS prompts
  to the release root. The copy that ships inside `.astraler/releases/<v>/` — added in 2.7.1
  precisely so nobody has to compute arbitration by hand again — died on its own layout. The
  fix was inert in the one place it was shipped to reach.
- The staged payload failed the staging gate 2.7.1 itself added. `install.sh` INJECTS
  `check-requirements.sh` into `harness/scripts/` at stage time — a file the source tree does
  not have at that path, and one that cites ledger entries. So `INDEX.md`, generated against
  the source, was stale for the payload by exactly those five citations. The immutability rule
  then correctly refused an in-place repair, leaving `--plan` and `--apply` both unreachable.
  **Derived files are now regenerated against the staged tree**, and the gate checks what
  ships rather than what it was built from.

**`ledger-index.sh --check` was position-dependent, and the wrong position silently WROTE.**
`ledger-index.sh . --check` and `--check .` both exited 0 and rewrote the index — a check that
cannot fail, inside the one script whose entire job is a staleness claim. It bit because the
three scripts ADAPT tells adapters to run in the same breath took three different conventions.
One convention now: flags anywhere, first non-flag argument is the root.

## The gates that fire, and the one that did not

A downstream project counted, over 200 commits in one repo: **35 `arm(ticket):`, 22
`simplify(increment):`, and zero Rin rounds across 107 merges and 33 tickets.** Then it asked
what separates them, and the answer is neither the trigger sentence nor the counter this
package added in 2.7.0:

> The gates that fire are the ones with a **physical artifact** that a script the router
> **already runs** refuses to proceed without.

Nobody remembers `arm(ticket)` or `simplify(increment)`. Nobody can merge without them.

Rin's gate had a report file at a path outside every checkout, no marker in the merge range,
and no reader in the gating script. So *"more than 10 merges since the last Rin round is a
STOP"* was a quantity **nothing computed**, evaluated by a resident session whose context
compacts, about an event with no machine-detectable trace. That project had to invent a
commit-subject grep to get any number at all, and the closest match for "the last Rin round"
turned out to be **the ledger entry recording that the gate had gone quiet**.

2.7.0's counter answered *"the router did not know the number."* The measured problem was
*"nothing was ever going to tell it."* The counter was necessary and not sufficient; it needed
an emitter.

**`rin(gate)` and `qa(walk)` are marker kinds now.** Rin commits one at the reviewed head, QA at
the walked head, and `check-simplify-markers.sh` — already in the merge gate, already parsing
subjects over a range — reports them. Both are **advisory**: a milestone gate does not fire per
ticket, so they print the count and the distance rather than blocking. Absence prints loudest,
because absence is the case that went unmeasured for a week.

`qa(walk)` ships **before** the evidence for it arrives. QA got 2.7.0's counter, has a report
file, and had no marker and no reader — the identical shape. The prediction was that it goes
quiet the same way and a project measures it after the fact. Shipping the emitter now is
cheaper than being right about that later.

## Migration

Nothing to do. `rin(gate)` and `qa(walk)` are advisory, so a project with no such markers gets
a line telling it so rather than a refused merge. Add them to your merge command when you want
the number:

```bash
scripts/check-simplify-markers.sh <base> <head> \
    --marker 'simplify(increment)' --marker 'arm(ticket)' \
    --marker 'rin(gate)' --marker 'qa(walk)'
```

If you are on 2.7.1 and its staged installer refused to run, that is the first defect above and
this release is the fix.

# Astragentic 2.7.1

2.7.0 went into a live project the day it was cut. That project — on 2.3.34, skipping three
minor lines to get here — reported **eight defects in a day**. Four were introduced by 2.7.0's
own audit pass, three were older, and one it caught in itself while installing a guard against
that very class. This release is those, plus the thing their absence made obvious: **nothing
here could answer whether an upgrade had actually integrated.**

## The release did not ship its own installer

Every "Upgrade from" note and every line of ADAPT-HARNESS tell an operator to run
`./install.sh <target> --apply`. The staged release contained ADAPT, check-requirements,
`harness/`, README, RELEASE-NOTES, UNINSTALL and VERSION — **and no installer**. That project
computed arbitration by hand because there was nothing to run, which also means 2.7.0's
`set -euo pipefail` fix, real and tested, was unreachable from the only place its own
instructions point.

## Two scripts could not run in any adapted project

2.7.0 replaced a CWD-relative root with `$(dirname "${BASH_SOURCE[0]}")/../..`. That is right
under `harness/scripts/` and **one level too high** under an adapted project's `scripts/`, so
`docs-staleness-audit.sh` reported "NO ROLE CONTRACTS FOUND" and `ledger-rules.sh` said the
ledger did not exist — both pointing at the repo's parent directory, both exiting 1 on a
correct install. `ADAPT` §6 tells adapters to run all three in the same breath; two could not.

They walk up to the payload now. The comment claiming `ledger-index.sh` resolved the same way
was also wrong about the file it named — that one resolves from the ledger path.

## The recipe written to save 50k tokens returned nothing

`sed -n '/^## <candidate>/,/^## /p'`. The headings are level one. The instruction added to stop
an agent reading 34k words of history handed it an **empty section**, and the natural recovery
is reading the whole file. Replaced with a working `awk` range — and with the rule it should
have carried from the start: **skipping releases means collecting migrations from every heading
in between.** Reading only the candidate's section is correct for a single-step upgrade and
wrong for a jump, which is what that project was doing.

## Two contracts shipped with one word of margin

`role_budget()` carries a comment block that exists to forbid exactly this: budgets hold ~150
words of headroom because an adapted project MUST add its own content, and it names 32/23/51-word
margins as the failure — "less headroom than a single sentence". 2.7.0's compression produced
**1499/1500 and 1969/1970**, and the check called both `ok`. That project added one paragraph to
`builder.md` and was 215 over.

The defect was the check, not the numbers. `budget_check` compared against a ceiling while the
comment above it described a margin, so 99.9% full read as fine. **It reports the margin now**,
and under 100 words is a finding. Budgets raised with reasons recorded in the same commit;
every contract ships with 141–211 words of room.

## Three things that project had measured and this package had not

**The broker matcher never worked.** `ps | grep -- '--cwd <path>'` reported nothing while a live
broker rooted in a removed worktree had run three hours. 2.7.1 does not ship a better one-liner
— it **adopts that project's `reap-worktree-processes.sh`**, which was written after a
`boundary.test` binary spun 18h18m at 85% of a core, reparented to PID 1, ignoring SIGTERM.

Worth reading its header before touching it. Its own first version matched the worktree root
exactly and **could not have found the process that motivated it**, because Go test binaries run
with cwd in their own package directory. It matches by path prefix with a `/` boundary, and
`realpath`s both sides because `lsof` reports resolved paths and a literal `/tmp/...` never
matches `/private/tmp/...`. The one-liner 2.7.0 shipped carried both of those bugs and had never
been run. Scope is deliberate and narrow: **one worktree, named on the command line.** Killing
processes on a box other Builders share is not something to widen.

**`check-payload-drift.sh --update` could not write a `symlinks` row.** `[ -f ]` follows a link
and rejects a link to a directory — precisely the dual-homed skill arrangement the verify half's
SYMLINK rows exist for. The only projects that section was written for could not populate it
except by hand.

**`ADAPT` named husky, lefthook and pre-commit — and not `git config core.hooksPath`**, the
redirect git itself ships, which overrides `.git/hooks` entirely. That project's agent checked
the three named managers, agreed no hook existed, installed one, **proved it rejected drift**,
and had installed a hook git would never run. AST-102 reproduced while installing the guard
against it; its real hook then refused the commit, which is the only reason anyone noticed. The
prompt checks `core.hooksPath` first now, and says to adopt a project's `tools/` layout rather
than add a second mechanism: a drift watcher living at a payload-owned path can be replaced by
the adaptations it exists to detect.

## "Integrated" is now a question a script answers

That project reached `applied-version 2.7.0` with every presence check green while two shipped
scripts could not run there at all. **Presence and integration are different questions**, and
only one was being asked. `check-requirements.sh <target> --adapted` now answers four:

1. `applied-version` matches the release actually staged — a mismatch means a half-landed payload
2. every shipped script **RUNS** here, invoked bare from the repo root, because bare is what broke
3. every payload file matches the release, is owner-owned, is generated per project, **or is named
   in `.astraler/state/ADAPTATION-REPORT.md`** — a difference is not a defect, an unrecorded one is
4. the guard actually denies

**Done is that command exiting 0.** Not a marker file, and not anyone's report.

## A note this release would rather not include

Three checks added across 2.7.0 and 2.7.1 fired on **correct work** before they were right: the
git guard denied `printf '%s' "rm -rf ..."` for containing the words; the staging gate refused
any repository path containing a space; and the integration check demanded
`.agents/roles/builder.md` while the adapter had recorded all eighteen of its decisions as
`roles/builder.md`, the form anyone writes in prose.

A gate that blocks correct work teaches its operator to route around it, and a list with noise
in it teaches them to skim. Both are worse than the gap the check was closing. It keeps arriving
through a different door, so it is written here rather than left in three commit messages.

## Migration from 2.7.0

Nothing beyond 2.7.0's steps. If you are on 2.7.0 and its audit scripts appeared to work, check
again from the repo root with no arguments — that is the invocation that was broken.

## Migration from anything older

All of 2.7.0's steps still apply, and **read every release heading between your version and this
one**. Migration items accumulate; the single-section recipe is for single-step upgrades.

# Astragentic 2.7.0

An audit of this harness against its own ledger, and the eight commits it produced. The finding
that organised everything else: of the nine git-failure mechanisms the ledger records, **the one
that does not recur is the one with a script behind it**, and the eight that do recur are
defended by prose. So this release moves the recurring ones onto mechanism, and where a rule
could not be mechanised it says so rather than asking more firmly.

Four cross-vendor gates ran over it. They found 5, 6, 7 and 5 defects — every one of them in
work done during this release, and all folded. What the fourth gate confirmed is in *What the
gates cost*, below, because it is the most useful part of this release to read.

## Rules that asked nicely now refuse

**`scripts/hook-git-guard.py` (new)** — a `PreToolUse` guard. It refuses `git add -A` (AST-054),
`rm -rf` on a worktree path (AST-096), a relative or output-suppressed `git worktree add`
(AST-028), and a removal that would destroy uncommitted work, kill a live process, or orphan a
broker or container (AST-092, AST-097, AST-100, AST-101).

It replaces an inline shell body crammed into `settings.json` that could not be read, run by
hand or tested, and that had sat dormant across releases while looking installed. **The
`WorktreeRemove` event is real; it fires only for worktrees Claude Code itself manages, never
for `git worktree remove` in Bash** — which is why AST-102 measured it silent, and why the
manual cleanup it was supposed to make redundant is permanently required.

**Read `WHAT THIS GUARD CANNOT DO` in that file before relying on it.** It is an
accidental-misuse lint, not a boundary, and it says so.

**Two staging gates and a doctor mode.** `install.sh` now runs `check-reachability`,
`docs-staleness-audit`, `ledger-index --check` and `ledger-rules --check` at staging and refuses
to ship on any failure — the one moment where the cadence belongs, which is why commit 54c85c2's
argument for keeping them out of contracts still holds. `check-requirements.sh --adapted` makes
the three `docs/agents/*.md` files required rather than expected-absent, and requires the guard
to be installed AND registered under `PreToolUse`/`Bash` AND to actually deny a payload it must
deny. A registration that cannot deny is not enforcement.

## The durable state nothing defined

`thomas.md` named **the dispatch record** beside the tracker and the frontier, and nothing
defined it — no path, no shape, no owner — while four rules read it: the write-set overlap
check, cleanup's exact IDs, a later session finishing a dispatch, and the Builder identity on
every tracker whose assignee cannot hold one. It is now
`.astraler/state/dispatch-record.json`, with a schema, a lifecycle and a registry row.

`<gate-history-dir>` was a literal placeholder inside a runnable `mkdir`.

## Requirement 3 is met by no tracker, and two adapters said otherwise

No tracker's assignee field can hold `builder/<ticket-id>`. Linear said so and shipped a
substitute. **GitHub claimed "Requirement 3 is met natively" while its only assign command
writes `@me` — one login for every dispatcher.** Jira's adapter did not contain the word
`assignee` at all, so the claim protocol ran there with nothing behind it.

All three now carry the same paragraph, and `thomas.md` says what is true: **one atomic
interlock plus an advisory readback**, with branch creation deciding the race.

**Migration:** nothing to do, but if you have been reading the GitHub adapter's claim as a
safety guarantee for more than a couple of concurrent Builders, it was not one. The fix at that
scale is one account per Builder identity, not a looser protocol.

## A gate QA never had

QA fires on a judgement about your own workload, which is the shape Rin's gate was given a
counter for. The same failure is in the ledger three times across three designs — most recently
nine fold rounds and one merge in half a day with QA never dispatched at all. It gets the merge
counter, its report and its verified-clean list get addresses, browser consent becomes a brief
FIELD rather than a sentence elsewhere, and cleanup gets the container step and the `--force`
that a running app always required.

## Compaction, and where a rule should live

Role contracts enter a session as tool results, and a tool result is the first thing compaction
summarises away. The tier that survives — the body of `.claude/agents/<role>.md` — held about
120 words of identity boilerplate. **Each role now carries a short `Survives compaction` block
there**: three or four invariants whose cost is paid before anyone notices they are gone.

This does not reopen AST-024. That entry is about `.claude/rules/`, an always-on GLOBAL tier
that bled one role's rules into every session. An agent definition is per-agent and cannot
reach another role. The old fix was right about the cause and went one tier too far.

**`RULES.md` (new)**, generated by `scripts/ledger-rules.sh`: every entry's rule without its
narrative, 7.4k words against the ledger's 38k. `grep -A40` returns roughly a quarter rule and
three quarters incident, entry size having inflated about fifteen-fold across this package's
life. Nothing was deleted; the ledger stays append-only and stays the truth.

## One reply, not a round

Every disagreement in this harness terminated at the owner: `builder.md` said a dispute "is a
decision for the owner", `thomas.md` said Rin advises and you classify. **The author now gets
one written reply before Thomas classifies, and only what neither of them can close reaches the
owner.** One reply — not a round, not a re-fired gate. 5 to 14 rounds is what
one-round-per-milestone exists to prevent.

## What the gates cost, and what they were worth

Gate 1 found the guard was simultaneously bypassable and over-broad. Gate 2 found six more
bypasses in the rewrite. Gate 3 found four more and concluded the matcher **was not converging**
— that a command-matching guard cannot be made complete, and its claim should shrink rather than
its rules multiply. That was accepted, and gate 4 found no bypass at all.

Gate 4 also caught the two worth naming here. **`RULES.md` was misreporting**, cutting rules
mid-clause and labelling superseded entries `promoted`, at the moment four contracts had been
told to read it before the ledger. And **the new staging gate refused correct installs** — a
repository path containing a space field-split every check. A gate that blocks valid work
teaches its operator to route around it, which is the same lesson the guard learned about false
positives arriving through a different door.

**And the one that matters most:** compressing contracts to fit word budgets **lost a rule**.
`qa.md`'s "one viewport by default" had carried ", more only when the change touches responsive
layout", and word-golf took the exception with the sentence. Restored. Every bold rule in all
five compressed contracts was then checked against the previous release **by meaning rather than
by string**; nothing else is missing.

## Migration

1. **Merge the `PreToolUse` block** from `harness/.claude/settings.json` into your project's
   `.claude/settings.json`. That file is owner-owned, so an upgrade will not do it for you — and
   a settings file naming the older `hook-git-guard.sh` passes a substring check while the hook
   is dead. `check-requirements.sh . --adapted` tells you which state you are in.
2. **Populate `.agents/payload-drift-manifest.json` and install the pre-commit hook**, or record
   that the project declines it. The script exits 0 when the manifest is absent, so a hook
   installed first watches nothing. Do not overwrite an existing `pre-commit`.
3. **Run `python3 scripts/check-reachability.sh .`** — not `bash`; it is Python behind a `.sh`
   name, and `bash -n` on it exits 2.
4. Nothing else. Contracts, skills and scripts are payload; `orchestrator.md`,
   `.claude/settings.json` and `.codex/profiles/` remain yours.

## Also

- `check-reachability` check 4 could not SEE `docs/…` or `tools/…` paths, and never scanned the
  tracker contract or the orchestrator at all. Both fixed; the project-side exclusion is now
  named in the verdict instead of hidden in a regex.
- `ledger-index` omitted `scripts/`, so 14 entries whose rule had become code read as uncited —
  the index calling its own most matured entries dead. Uncited entries: 65 of 134, not 87.
- `docs-staleness-audit` resolved its payload from the caller's cwd, so a run from one repo
  measured another's files while reporting on the first.
- The skill mirror check compared `SKILL.md` only, skipped a file present in one tree and absent
  from the other, and allowlisted `review-with-rin`, which diffs zero lines — a dead exemption
  masking future drift in the pair it names. Allowlisting is by exact file pair now.
- `install.sh` stamped `applied-version` before the conflict report, telling the next upgrade and
  `check-reachability`'s ownership manifest that a partial apply had landed clean. It now refuses
  to stamp over conflicts and exits 3 — distinct from 1, so pending arbitration is
  machine-separable from failure.
- `bootstrap-glossary` wrote `CONTEXT.md` in a format its reader does not use, and marked terms
  `UNREVIEWED` — a word that appears nowhere in the plugin, while nine plugin skills load that
  file. Every one of them was reading unconfirmed extractions as confirmed vocabulary.
- `tracker-contract.md`'s Per-tracker section restated ten facts the adapters already carry, in
  799 words, and had drifted twice doing it. Cut to a pointer table.
- The watchdog looked Thomas up by pane title only — AST-084's own fix had been applied twelve
  lines below and not there — so one overwritten title silenced every pane alert that poll. Its
  watcher probe also defaulted to "present" when `pgrep` raised, so a failed liveness check
  reassured.
- SPEC named `code-scout` in the present tense; 1.6.1 deleted it for having zero readers. SPEC
  now says at the top that it is a historical build spec.

# Astragentic 2.6.1

The first project to take 2.6.0 reported three defects in it and corrected one claim. This is
those four.

## What it found

- **`INDEX.md` bound `AST-131` to `.agents/orchestrator.md`, which is an OWNER file.** An install
  writes that file only when absent, so a project that declines the optional `builder-target` row
  never carries the citation — while the generated index shipped in the payload says it does. The
  index-vs-ledger axis of `docs-staleness-audit.sh` therefore **failed on day one, out of the box,
  on a configuration 2.3.35 explicitly calls supported.**

  Fixed at the source rather than in the index: **a ledger id must not be cited from an owner
  file.** The rule's home is the contract; the owner file carries a value, not a provenance. The
  `builder-target` explanation stays, the `AST-131` citation goes, and the ledger entry now says
  why.

- **The README version badge read `2.3.23` against `VERSION = 2.6.0`**, and the failure-mode badge
  was nine entries stale. Both are hand-maintained numbers in a file every release copies
  wholesale — the exact class `install.sh`'s ledger-header block already exists to fix, recurring
  three lines away from the comment predicting it. `install.sh` now derives the version badge, the
  failure-mode count and the `releases/<version>/` example at staging time.

- **The Jira adapter's opening line named a real project.** 2.5.1 scrubbed ticket ids for AST-123
  and the project name survived the same sweep; the GitHub and Linear adapters carried it too. All
  three now say "a live project". The JQL keyword-collision example is generalised the same way.

## One claim corrected, and one measurement I would not have got

**Corrected.** The adapter said a new Jira state is *"invisible to the API until the workflow is
published"* — and `published` is **company-managed vocabulary**, which sits against the adapter's
own team-managed paragraph one section later. On team-managed, a status is added as a board column
with no publish step. The claim is now split by project type, with the company-managed half marked
**inherited rather than measured**. It came from a project doc; both files said it, so it was not a
regression — it was two files agreeing on something neither had checked.

**Confirmed, and worth more than the fix.** The adapter's `inwardIssue` = blocker /
`outwardIssue` = blocked table was verified against **all 8 live `Blocks` links** in a real
project, by reading back the rendered wording rather than the payload sent. The reporting session
had doubted the table on first read and reported that the doubt was wrong. That is the read-back
rule in the adapter being used on the adapter.

## Upgrade from 2.6.0

Copy `harness/`, or `./install.sh <target> --apply`. A project already on 2.6.0 has the wrong
`INDEX.md` row; this release replaces it.

# Astragentic 2.6.0

Removal gets a prompt, not a script — which is the shape this package already had and I had
missed. The owner pointed it out.

## What changed

**`prompts/UNINSTALL-HARNESS.md`**, staged into every release beside `ADAPT-HARNESS.md`:

```
Read .astraler/releases/<applied>/UNINSTALL-HARNESS.md completely and execute it.
```

2.5.3 wrote the removal procedure into the README as five steps for a human. That was the wrong
home, and the package's own architecture says why: `install.sh` is deliberately **not** the
semantic installer, because integrating a release needs judgement over project context. Removal
has exactly the same shape — the mechanical half is `rm`, and the hard half is deciding, for
every file at a path the payload also ships, whether the PROJECT wrote it. A script cannot decide
that. A prompt with the evidence in front of it can.

**It is staged per release, deliberately.** Removal is classified against the bytes the project
actually received, so the prompt doing the classifying has to be the one that shipped with them.

## What it does that a README section could not

- **Stops what is running first**, and treats a live Builder as a STOP rather than a cleanup step.
- **Classifies by `diff -rq` against the applied release**, and reads
  `check-payload-drift.sh`'s manifest as an independent second statement of the same fact —
  **where the two disagree, the disagreement is the finding**, not something to resolve by
  picking the convenient one.
- **Fails closed.** A file it cannot classify is kept and reported. An over-cautious uninstall
  leaves a directory the owner deletes in one command; an over-confident one loses authored work
  silently, and the silence is what makes it unrecoverable.
- **Refuses to run without `applied-version`**, because there is no oracle without it and a guess
  is the silent-loss case.
- **Unwires the semantic half** — the rows and pointers the adaptation wrote into `AGENTS.md` and
  `CLAUDE.md` — which no file-level removal reaches.
- **Names what to KEEP**: the three `docs/agents/` files (they come from
  `setup-matt-pocock-skills` and describe the tracker, not this harness), the ledger, and every
  ticket and commit the harness helped produce. "Clean removal" has been read as "revert" before.
- **Leaves a receipt** in one commit, so a later session can tell a deliberate removal from an
  accident.

`install.sh` now requires and stages the file, and its closing instruction names the mirror.

## Upgrade from 2.5.3

Copy `harness/`, or `./install.sh <target> --apply`. The new prompt is staged, not installed into
the project tree — a release you have already staged does not have it, so removal against an
older release uses the README section, which now points here.

# Astragentic 2.5.3

The owner asked how a project removes this package, and there was no written answer.

## What changed

`README.md` gains **"Removing it"** — five steps, in order, with the two that get forgotten named
as such: the watchdog keeps running after the files are gone, and the Codex profiles under
`${CODEX_HOME:-$HOME/.codex}` live outside the repo entirely.

**Still no `uninstall.sh`, and now the reason is written down where it can be argued with.** The
hard part of removal is deciding which files at payload paths the PROJECT authored, and no script
decides that for you. What the package can do is supply the evidence: the applied release
directory is a byte-exact record of what shipped, so

```bash
V=$(cat .astraler/state/applied-version)
diff -rq .astraler/releases/$V/harness .
```

answers it — identical is the package's, differing or only-local is yours. A project running
`check-payload-drift.sh` already has the same list in its manifest. That is the same reader
whose existence justifies release immutability in `install.sh`; removal is one more use of it,
not a new mechanism.

The section also names what to **keep**: `docs/agents/issue-tracker.md`, `triage-labels.md` and
`domain.md` come from `setup-matt-pocock-skills` and describe the project's tracker, not this
harness; the ledger is the project's own measured history. Removing the harness is not a reason
to lose either.

## Upgrade from 2.5.2

Copy `harness/`, or `./install.sh <target> --apply`. Documentation only.

# Astragentic 2.5.2

Nine scripts ship and three of them had no moment. The owner asked when they run, and the
package could not answer.

## What changed

`README.md` gains **"When each script runs"**, in two tables, because the two groups are not the
same kind of thing:

- **In the pipeline** — `herdr-watchdog`, `herdr-watch-terminal`, `check-simplify-markers`,
  `ticket-git-facts`, `check-payload-drift`, `project-status-sync`, `check-requirements`. Each is
  already named by a role's contract or a skill, so it runs without anyone remembering. This
  table documents what was already true.
- **On the harness itself** — `check-reachability`, `docs-staleness-audit`, `ledger-index`. These
  run when the PAYLOAD changes, not when work happens, and **this is the group that had no
  moment.** `ledger-index` had zero callers anywhere: its only pointer was inside the file it
  generates.

`ADAPT-HARNESS` §7 already required `check-reachability` at the end of an adaptation. It now
requires all three, in the same breath, wherever the run edited a contract, a skill or the ledger.

The README's script tree, which listed six of nine with one-line descriptions, is replaced by a
pointer to the tables — one home for the answer instead of two that could disagree.

## Why three and not one

They catch different classes and are individually blind:

| | catches |
|---|---|
| `check-reachability` | a phase no contract owns, a skill nothing reaches, a path that does not exist, a skill addressed in a form its caller cannot use |
| `docs-staleness-audit` | a contract over its word budget, a number a document states about itself that is no longer true, a payload naming a real project's tickets, a stale index |
| `ledger-index` | nothing — it is the fix for the last of those |

**2.5.0 is the argument.** It was built with `check-reachability` green throughout, and
`docs-staleness-audit` then found three defect classes in it: adapters naming another project's
real ticket ids, a stale index, and two contracts pushed over budget by 2.3.35 and 2.4.0. None
was visible by reading. 2.5.1 is those fixes and nothing else.

## The rule this follows

These three are named in the README rather than in a role's contract on purpose. **A rule in a
contract is read every time that role starts.** A project that never edits the harness never
needs them, and putting them in `thomas.md` would bill every session for a step most projects
never take.

## Upgrade from 2.5.1

Copy `harness/`, or `./install.sh <target> --apply`. Documentation only; no script changed.

# Astragentic 2.5.1

`docs-staleness-audit.sh` was run against 2.5.0 and found three defects in it. This release is
those fixes, and the audit is the reason it exists.

## What it caught

- **Seven payload files naming a real project's tickets** (`PROJ-033`, `PROJ-031`) and a real
  ticket-shaped example (`ABC-251`) — in the adapters and the contract written the previous day.
  AST-123 is exactly this: the payload accumulating the identity of whoever last measured a
  lesson. Replaced with neutral forms; the measurements survive, the ids do not.
- **A stale `INDEX.md`.** Re-generated.
- **Two contracts over their word budget** — `thomas.md` 2009/1970 and `builder.md` 1621/1400 —
  entirely from what 2.3.35 and 2.4.0 added. Both were compressed; `builder.md`'s arm section
  went from 470 words to 250.

## One budget was raised, and it is worth reading as a decision

`builder.md`: 1400 → **1500**. Raising a budget to fit prose is the failure this check exists to
catch, so the reason is recorded in the script beside the number: 2.4.0 moved `arm: ticket` into
this role, and the old budget's own comment enumerated **five** responsibilities where the role
now has **six**. That is a change of remit, not accretion. Compression came first and took the
section down by 220 words; what remains is the receipt shape and the `Reviewed:`-or-delta rule,
and a Builder cannot write the artifact without either.

## Why this is the whole release

Three checkers ran over 2.5.0 and two of them found things: `check-reachability` caught the
adapters being reached by nothing and two project names read as skill references while the
release was being built; `docs-staleness-audit` caught the above. Both classes were introduced by
careful work an hour earlier and neither was visible by reading.

# Astragentic 2.5.0

Three tracker adapters, so a project stops hand-writing tracker mechanics into its own docs.

## The gap this closes

`ADAPT-HARNESS` §2 has always required `docs/agents/issue-tracker.md` to exist and verified that
the tracker can carry an assignee and blocking edges — and delegated the HOW entirely to
`setup-matt-pocock-skills`, which covers GitHub, GitLab and local markdown and records anything
else as freeform prose. Confirmed against plugin 1.2.3: there is no Jira adapter and no Linear
adapter; both fall to *"Other — describe the workflow in one paragraph"*.

**Two live projects changed tracker on 2026-08-21** — one Linear → GitHub, one Linear → Jira —
and each then wrote its own operating manual into its own `issue-tracker.md`, in parallel, sharing
nothing. Every trap in this release was paid for at least once, and several twice.

## What ships

- **`github-issue-tracker`** — status as labels (exactly one of three), native dependencies keyed
  by the **database id** not the issue number, the two-second read-back lag on
  `issue_dependencies_summary` and why the fix is *read the endpoint that is not lagging* rather
  than retry, the N+1 frontier, and the Projects board mirror. Ships
  `project-status-sync.sh` beside it, parameterised — the Status field id and its options are
  **discovered at runtime**, because a pasted opaque id that has gone stale writes to a field that
  is not the one on the board.

- **`jira-issue-tracker`** — status is a **transition taken by a numeric id that is
  project-specific, non-sequential and not guessable**, so a remembered id is a valid write to the
  wrong state; read `getTransitionsForJiraIssue` every time and the extra call IS the guard.
  `cloudId` appears in no URL a human pastes. A project key can collide with a JQL keyword.
  `editJiraIssue` replaces `description` whole. Link direction is silently invertible — read back
  the **rendered wording**. Adding a state is an owner action in the UI, invisible to the API
  until published.

- **`linear-issue-tracker`** — the thin one, because Linear meets all five requirements natively.
  Carries the two things that are not obvious: the claim protocol is **weaker** where `assignee`
  cannot hold a Builder identity, so git is the only interlock left; and the free tier stops
  accepting new issues, which does not degrade a pipeline but stops one.

- **`.agents/tracker-contract.md`** — the layer above all three: the five things the pipeline
  requires of any tracker, what each tracker charges, how to choose, and what a migration costs.

- **`ADAPT-HARNESS` §2 step 6** — after the owner picks, the adaptation shrinks
  `issue-tracker.md` to the pointer set and moves mechanics into the adapter. It does **not**
  replace `setup-matt-pocock-skills`: that skill still owns writing the file and the project's own
  decisions, and where a project runs a tracker no adapter covers, the freeform path is left alone
  because that is what it is for.

## Two things deliberately not done

**No checker for "adapter shipped but not named by this project."** Two of three adapters are
unnamed on any given project. That is the normal state, and `check-reachability`'s check 3 already
concedes it cannot tell a skill that runs every session from one never invoked.

**`install.sh` ships all three and prunes nothing.** The stager takes a target path and a project
name; teaching it which tracker a project runs would put a semantic question in the half that is
deliberately not semantic, and would make `releases/<version>/harness` stop being a complete
record of what shipped.

## Also in this release

`builder.md` said the range is correct *"firing HERE"*, one careless reading from *"in my
checkout"* — which is the exposure, since `codex-claude-arm` genuinely needs its own worktree
(`claude -p` writes). Rewritten as a positive pointer: isolation is a per-runtime question, take
it from the arm skill for your runtime. Two rationale paragraphs added in 2.4.0 — one in
`thomas.md`, one in `codex-arm` — were provenance rather than instruction and are now one clause
each; the ledger holds the history. **A correction to a contract that lands as added prose is
still a contract that only got longer.**

## Upgrade from 2.4.0

Copy `harness/`, or `./install.sh <target> --apply`. Everything new arrives as `NEW`; the only
edited payload files are `thomas.md` (three Load rows), `builder.md`, `codex-arm` and
`check-reachability.sh` (two vocabulary entries).

A project already carrying its own tracker skill at one of these paths will see `CONFLICT` and
keep its own — the shipped adapter is the portable half of what it already wrote, so diff rather
than take either whole.

# Astragentic 2.4.0

The ticket arm moves into the Builder, and its receipt gets a validator in the same release —
so the format and the thing that checks it are never one version apart.

## What changed

- **The Builder fires `arm: ticket`, from its own worktree**, inside one closed loop that hands
  back once: `implement → code-review → simplify → arm pass 1 → [fold → arm pass 2] →
  arm(ticket): receipt → handback`. `thomas.md` keeps `arm: spec` and `arm: slice`, which still
  fire from the base checkout.

  **This deletes machinery; it does not repair something still broken**, and the distinction is
  worth stating plainly because the opposite version reads better and is false. The empty-range
  failure (AST-103) was closed on 2026-08-19 by a guard that has never been shown to fail. But it
  closes the hole *by adding a step an operator must execute*, and AST-103's own closing line is
  that prose warnings do not survive contact with an operator who just read them — a bash block
  embedded in prose is the same genus, one notch stronger. Standing in the reviewed tree makes
  the correct range the **default**, and takes the gate worktree, the broker kill (AST-100), the
  container stop (AST-115) and the never-reuse-a-path rule (AST-095) out of the ticket path
  altogether. The other half is the router's queue: three concurrent tickets produced **nine fold
  rounds and one merge in half a day**, every round a turn of Thomas's, and QA was never
  dispatched at all (AST-135).

- **`codex-claude-arm` does NOT mirror this at ticket scope, deliberately.** `claude -p` is a full
  agent with Edit and Bash, so it keeps its detached worktree even when the Builder is already
  standing in the reviewed tree. The range is correct by construction either way; the isolation is
  not what the move removed. Mirroring the Codex path here would hand a writing reviewer the
  Builder's live checkout (AST-016).

- **`arm(ticket):` is a real format now, and `check-simplify-markers.sh` validates it.** Written
  from a measurement of **32 real receipts**, not from the contract, and the corpus is less
  uniform than the contract would have suggested. What that changed:

  | | |
  |---|---|
  | field detection | **substring, not line-anchored** — `Vendor:`, `Tests:` and `Pass:` are commonly packed on one line separated by runs of spaces |
  | `Tests:` | leading token `RAN` or `NOT RUN`, **prefix not equality** (`NOT RUN by the arm (…)` is real), everything after is prose |
  | `Output:` | **not required** — absent in 4 of 32, prose in 3, and where it is a path it is a session-scoped scratch path belonging to a session that has ended. Requiring it buys presence, not evidence |
  | `Pass:` | **no cap assertion** — `Pass: 8` is legal where a fresh gate re-fired per fold and no single invocation exceeded two |

- **Field validation is scoped per kind, and the two kinds differ for a reason.**
  `simplify(increment)` validates every live marker, because AST-122's economy — every fabricated
  marker costs its own genuine pass — collapses if a junk live marker is not a finding.
  `arm(ticket)` validates **only the marker that IS the head**. That dissolves three correct
  shapes a field-list validator would reject (two `Supersedes:` repairs, one of them a Builder
  catching the covers-head failure in the field and re-firing; one fieldless correction marker)
  without a special case: the router merges one tree on one receipt, and whatever is at the head
  is that receipt. Everything below it is narration, and there is nothing to launder when exactly
  one commit is asserted against.

- **`Reviewed:` == the receipt's own parent, OR `Unreviewed-delta:` is present. Never neither**
  (AST-134). The receipt commits empty, so its parent is the tree the gate read. The fold makes
  that equality legitimately false — the tree moves past what any pass read and a pass 3 is over
  the cap — so the gap gets declared instead of hidden. **Its absence where `Reviewed:` is not the
  parent is the failure.** Same shape as AST-121: a check with no vocabulary for being obeyed
  reads honesty as failure.

- **`thomas.md`'s capacity section was in the wrong place.** 2.3.35 inserted it mid-way through
  §The frontier, orphaning that section's closing paragraph about over-inclusive blocking edges.
  Moved below it; no wording changed.

## The residual, stated rather than implied

The receipt is **a commit written by the agent being verified**. AST-130 measured a fork forging
exactly this shape with a sanctioned degraded `Pass:` line quoting a real error string, caught by
no check. That is the trade the router's queue is worth, and 2.3.35's `isolation: "worktree"` rule
is what narrows it. It is not closed. The marker is a receipt; the diff is still the evidence.

## Upgrade from 2.3.36

Copy `harness/`, or `./install.sh <target> --apply`. Four role contracts and both arm skills
change, so a project that has edited any of them will see `CONFLICT` and keep its own — read both
sides rather than taking either whole.

**The merge command changed shape**: one call reads both receipts.

```bash
scripts/check-simplify-markers.sh <base> <head> \
    --marker 'simplify(increment)' --marker 'arm(ticket)'
```

A project not yet writing `arm(ticket):` receipts should pass only `--marker 'simplify(increment)'`
until its Builders do; asking for a marker kind nobody writes is an immediate `AST-094` STOP, which
is correct and is not the finding you want on day one.

# Astragentic 2.3.36

2.3.35 fixed one half of a matcher bug and shipped the other half unchanged, three files away.

## What changed

- **`dispatch-ticket/CLEANUP.md` calls `scripts/check-simplify-markers.sh`** instead of carrying
  its own `git log --grep '^simplify(increment):'`. That command searches the **whole message**,
  and `^` anchors to the start of **any line** in it — so every squash or merge commit that
  quotes a marker subject in its body counts as carrying one. Measured downstream over 200
  commits: **23 real markers, 193 matches**, the 170 extras all squash bodies. Every per-field
  check then runs against a marker the branch never had (AST-133).

- **`rin.md` asks whether the marker IS the head**, not whether one exists, and names the script
  that reads both. 2.3.35 put that rule in `thomas.md` and `builder.md` and left the gate's own
  contract on the old wording.

- **AST-133** records the root cause both failures share. 2.3.35's release note described the
  under-matching half — `re.escape` handed to a POSIX **basic** regex, where `\(` opens a group,
  so the pattern matched nothing and the script printed a confident STOP naming the wrong cause.
  The over-matching half above is the same mistake pointing the other way. Two codebases, one
  day, opposite directions, one root: **`--grep` is not a subject matcher.**

The lesson was already in this payload and had been unlearned. `scripts/ticket-git-facts.sh`
reads `--format='%s'` and greps that, with a comment saying why — *"grep returning commits that
only cited a ticket in a handback; subject-only"*. Solved in one script, walked into by another.
A rule that lives only as a comment in the file that learned it does not travel.

**Standing consequence, now written down:** where a script exists for a marker question,
contracts call it. A hand-rolled `git log` beside a script that does the job properly is
machinery to delete, not to keep in sync — and keeping it in sync is the failure this entry is
about. 2.4.0 removes the last one when `arm(ticket):` gets its kind.

## Upgrade from 2.3.35

Copy `harness/`, or `./install.sh <target> --apply`. Documentation and one ledger entry; no
script behaviour changed. A project still on 2.3.34 can take this directly — 2.3.35's notes
apply unchanged and are immediately below.

# Astragentic 2.3.35

Four coordination fixes measured on adapted projects and returned upstream. The one the owner
named as changing how coordination feels is the smallest: the router had no idea how many
Builders were working.

## What changed

- **`thomas.md` dispatches to CAPACITY, not to events.** A target count, and a pane count after
  every merge, handback and report. Measured downstream: after two merges, **two of four Builder
  slots sat idle while twelve claimable tickets waited**, with every step performed correctly —
  the loop was `notification → verify → merge → report → wait` and nothing in it asked whether a
  slot was free (AST-131). **The default is 4 and lives in the contract**, so the rule works on a
  project that never merges the new `builder-target` row; `.agents/orchestrator.md` carries the
  override. An owner file an upgrade never overwrites is the wrong single home for a new rule.

- **Report-only forks get `isolation: "worktree"`, and commit-then-fan-out ships in the same
  breath** (`builder-claude.md`). A fork inside a Builder's session forged a `simplify(increment):`
  marker over an implementation it had committed itself, carrying the **sanctioned degraded
  `Pass:` form quoting a real runtime error string** — well-formed by every rule this package
  has, caught by no check, noticed only because the Builder saw a commit it had not made
  (AST-130). Seventh escape of the class; prose has been the control for all seven. The two
  halves are one rule: a worktree carries content at HEAD, so isolating a fork over uncommitted
  work buys a vacuous clean pass in exchange for the forgery (AST-036). Requiring the excuse to
  quote its evidence would **not** have caught this one — the fork had a true error available and
  used it for a false purpose.

- **`scripts/check-simplify-markers.sh` checks that the marker COVERS THE HEAD.** A marker whose
  every field is true, with a later commit on top, is a pass that did not read the code — and the
  four existing rules all pass on it (AST-122, applied to itself). Marker kind is now data rather
  than a second script; `arm(ticket)` gets its row when its body format is fixed, because a rule
  guessed ahead of the marker it validates is a rule the next release has to change.

- **`scripts/check-payload-drift.sh` is new.** A project authors a file at a path the payload also
  ships, and neither side can see the collision; a bulk adaptation replaced one downstream and a
  doc that had been accurate went false with nobody editing it (AST-132). `--apply` guards that
  boundary at upgrade time; this guards it at commit time against a hash the project records. The
  manifest is the project's at `.agents/payload-drift-manifest.json` and **no release ships it** —
  a payload carrying the hash file would reset, on upgrade, the record whose job is to notice
  upgrades.

## The bug this release found in its own fixture

`check-simplify-markers.sh` matched marker subjects with `git log --grep` and a Python-escaped
pattern. `--grep` takes a POSIX **basic** regex, where `\(` opens a group rather than matching a
parenthesis, so `simplify\(increment\):` matched nothing and the script reported
`markers=0 — STOP: no simplify marker`. A correct-looking STOP naming the wrong cause, on a range
that had a valid marker. The original inline form worked only because unescaped `(` is literal in
BRE. Subjects are now matched in Python, one `git log` for the range, no regex dialect involved.
Caught by a fixture that appeared to be working — AST-122's own lesson, met again while extending
the script that entry created.

## Upgrade from 2.3.34

Copy `harness/`, or `./install.sh <target> --apply`.

`.agents/orchestrator.md` is an owner file and `--apply` will report it as `owner (kept — yours)`.
**Add the `builder-target` row by hand if you want to tune it**; leaving it out is a supported
state and Thomas will use 4.

`scripts/check-payload-drift.sh` arrives inert — it watches nothing until you register paths with
`--update`, and says so rather than reporting a clean check over an empty list.

**`check-simplify-markers.sh` is stricter than 2.3.34 and can turn a currently-green branch red.**
A branch whose simplify marker is not its head now stops. That is the finding, not a regression:
the fix is one empty commit re-marking the current head.

# Astragentic 2.3.34

2.3.28's supplement-load fix reached the Claude adapters only, so the same role stated
contradictory load rules depending on which runtime read it.

## What changed

- **`.opencode/agents/{thomas,rin,builder,qa,shaper}.md` and the Codex `thomas`/`rin`
  `developer_instructions`** now carry 2.3.28's rule: runtime supplements load **per builder,
  not per session**, and the contract's Load table is the single home for what else a role
  reads. Four surfaces still said "read ALL runtime supplements" — 758 words a Thomas on
  opencode or Codex loaded at session start and could not use.
- The opencode adapters get 2.3.28's prose treatment too: they stopped restating the contract
  they load beside. 1031 → 674 words across five.

**Both gates passed over this the whole time**, which is the more useful half. `check-reachability`
verifies a path exists; neither checker asks whether two files stating the same rule agree.
Found downstream by an adaptation agent reading the payload it had just received.

## Upgrade from 2.3.33

Copy `harness/`, or `./install.sh <target> --apply`. Codex profiles are `kept` by `--apply`
where you have tuned them, so a project on Codex must merge line 14 of `thomas.config.toml`
and `rin.config.toml` by hand — `--apply` will report them as `kept`, not `UPDATED`.

# Astragentic 2.3.33

2.3.30 gave the applied version a second home, and on the first project carrying both, the two
disagreed.

## What changed

- **`--apply` reads and writes `.astraler/state/applied-version`** — the home
  `ADAPT-HARNESS` §7 has always written and §1 has always read. 2.3.30 invented
  `.astraler/APPLIED` beside it. Measured on the first project that had both: `state/` said
  2.3.3 while `APPLIED` said 2.3.32, and the divergence arbiter read the wrong one.
- Delete a stray `.astraler/APPLIED` if a 2.3.30–2.3.32 `--apply` left one; nothing reads it
  now.

The failure is the package's own recurring one — two homes for one fact, the shipped copy
winning by accident. `orchestrator.md` opens by warning about it.

## Upgrade from 2.3.32

Copy `harness/`, or `./install.sh <target> --apply`.

# Astragentic 2.3.32

2.3.28 broke `check-reachability.sh`, and 2.3.28's own notes did not notice because they only
ran the other checker.

## What changed

- **Phase ownership is read from the phase table, not from every table in the contract.** The
  code's comment always said "leading phase table"; the code scanned every row and passed only
  because no other table happened to carry a bare backticked token in column 2. 2.3.28 gave
  each contract a Load table whose column 2 *is* such a token, so `untangle` — offered to two
  roles and owned by neither — read as a phase two contracts both owned:
  `[FAIL 2] 'untangle' is owned by 2 contracts: builder, shaper`.
- Owned phases go 19 → 11, which is exactly the phase tables: thomas 6, builder 2, shaper 3.
  Duplicate-ownership detection is unchanged — a phase genuinely declared twice still fails.

Found downstream, by the adaptation agent on a real project, running the gate `ADAPT-HARNESS`
§6 requires. 2.3.28 through 2.3.31 each asserted "docs-staleness-audit.sh clean on all four
axes" and none of them ran this checker; the axis a release does not run is the axis that
catches it.

## Upgrade from 2.3.31

Copy `harness/`, or `./install.sh <target> --apply`. A project on 2.3.28–2.3.31 sees
`check-reachability.sh` fail on untouched payload; this release is the fix, and no project
edit resolves it.

# Astragentic 2.3.31

Three defects in 2.3.30, all found by running `--apply` against a real adapted project.

## What changed

- **`--apply` no longer overwrites on a guess.** A file that exists, differs, and has no prior
  release to compare against is now a `CONFLICT`, not an overwrite. 2.3.30 shipped that branch
  as `cp` — and every project adapted before `.astraler/APPLIED` existed has exactly that shape,
  so the first upgrade would have replaced its whole adaptation.
- **Missing `APPLIED` falls back to the newest staged release.** That marker only exists from
  2.3.30 on; the release a project last received is knowable without it, from
  `.astraler/releases/`.
- **A file the release did not change is `kept`, not `CONFLICT`.** The classification is
  three-way now: package-unchanged-since-prior means an owner edit has nothing to reconcile
  against. Measured on the same upgrade — five `.codex/profiles/*.config.toml` the owner had
  filled in reported CONFLICT while the release carried no change to any of them.
- **`ledger-index.sh` resolves its root by finding the ledger**, not by counting `..` hops. It
  ships into two layouts — `harness/scripts/` in the package, `scripts/` in an adapted project
  — and a fixed hop count picks one. Measured: `../..` from an adapted project resolved above
  the repo and reported "ledger not found" on a ledger that was present. Axis 5 read as clean
  only because it had been run from the package.

## Upgrade from 2.3.30

Copy `harness/`, or `./install.sh <target> --apply`. If you ran 2.3.30's `--apply` against a
project adapted before 2.3.30, check `git status` there — that build could overwrite adapted
files without reporting a conflict.

# Astragentic 2.3.30

`install.sh --apply` writes the payload in; semantic adaptation keeps only what is actually
semantic.

## What changed

- **`install.sh --apply`** copies the payload straight into the target. Role contracts,
  adapters, skills, scripts and the ledger are replaced wholesale by a release anyway, so
  routing them through a 20k-word adaptation prompt bought latency, not safety.
- **`--plan`** prints the same report and writes nothing — this is the "where do I upgrade"
  view, available before committing to the write.
- **Owner files are never overwritten.** `.agents/orchestrator.md` (the runtime and model
  rows, AST-041) and `.claude/settings.json` (project hooks) are written only when absent.
- **A payload path the project diverged on is reported, never overwritten.** The previously
  applied release is the arbiter: a project copy still matching what the last release shipped
  was never touched, so the upgrade is clean; anything else is a `CONFLICT` line naming the
  two diffs that decide it. A project can author a file at a path the payload only starts
  shipping later, and overwriting that is silent data loss (ADAPT-HARNESS §4).
- **`.astraler/APPLIED`** records the applied version, which is what makes the divergence
  test above possible on the next upgrade.

The default run is unchanged and still edits no project file. `ADAPT-HARNESS.md` still owns
the genuinely semantic half — the project entry doc, the ledger namespace, and every
`CONFLICT`.

## Upgrade from 2.3.29

Nothing to do in the package. In a target project, the first `--apply` has no prior `APPLIED`
marker, so every differing file reports as `UPDATED (no prior release to compare — review
this one)`. Run `--plan` first there.

# Astragentic 2.3.29

The ledger is 57k tokens and had no way in but reading it.

## What changed

- **`scripts/ledger-index.sh` generates `.agents/memory/INDEX.md`** from the ledger's own
  headings — id, lesson, status, length, and which live contracts and skills cite it. 3.8k
  tokens against the ledger's 57k. Generated, never hand-edited; `--check` exits 1 on drift.
- **Reading the ledger is now two steps.** The Load tables point at the index first, then at
  `grep -A40 '^### AST-0NN'` for the one entry it named. Browsing no longer means opening the
  file, which is the only way a 57k-token lookup stays affordable.
- **Axis 5 in `docs-staleness-audit.sh`** runs `ledger-index.sh --check`. A stale index is
  indistinguishable from a current one by reading it, so it needs a machine.
- **The index exposes what the ledger could not.** 88 of 128 entries are cited by no live
  contract or skill. `AST-001`–`AST-014` run 12–53 words each — the layer that went stale when
  1.0.0 rebuilt the method around the plugin. Whether a given orphan was closed in code, went
  stale, or names an unbound lesson is not derivable from the table; the index says so rather
  than guessing.

Nothing auto-loaded the ledger before this change and nothing does now. It is a lookup target,
and the index is what makes the lookup cheap enough to actually happen.

`qa.md` gets no ledger row: it sits at 1271/1300 words against axis 1, and a walk's findings
are product defects rather than harness failure modes.

## Upgrade from 2.3.28

Copy `harness/`. Run `scripts/ledger-index.sh` once after copying — `INDEX.md` is generated,
and a project whose ledger has diverged needs its own.

# Astragentic 2.3.28

Contracts and skills carried their own evidence inline; the load schedule cost more than the
prose did.

## What changed

- **Rationale moves to its designated home.** Every contract and skill now cites `AST-` ids
  where it used to restate the incident. The ledger already declared itself the evidence base;
  the contracts just never respected the split. Every id is unchanged, none invented.
- **Each contract opens with a Load table** — what to read, when, and for what. Scattered
  pointers (`orchestrator.md` named in four places in `thomas.md`, `docs/agents/*` buried
  mid-paragraph) collapse into one place per role.
- **Runtime supplements load per builder, not per session.** The `thomas` and `rin` adapters
  told each role to read ALL THREE supplements at session start — 758 and 208 words of which
  two thirds never apply. The adapters now point at the contract's Load table instead of
  keeping a competing copy of the load rule. Thomas's boot chain: −44%.
- **Adapters stop restating their contract.** They co-load with it, so the role summary was
  real duplication. 972 → 604 words across five.
- **`dispatch-ticket` splits by branch.** `WATCHING.md` (watcher exit contract, stopping a
  watch, the pipe table) and `CLEANUP.md` (simplify verification, `Supersedes:` rules, worktree
  retirement) load when their branch fires. Per-dispatch cost 5,262 → 3,749 words. A block of
  inline marker arithmetic the file itself called superseded is gone.
- **Justification vacates heading position.** `reconcile-tracker` had five "Why" headings;
  `codex-arm` opened with 230 words defending a cadence the same file declares belongs to
  `thomas.md`. Headings now name the rule.
- **`dispatch-ticket-claude` gains a step spine.** Its four-step submission order was split
  across two sections sixty lines apart, and getting that order wrong produces a false terminal
  state every downstream check reads as healthy.
- **`dispatch-qa-walk` gains one too** — it grew 13%, deliberately: a dispatch recipe with a
  mandatory order and no numbered steps.
- **`review-with-rin` points at Rin's contract**, not at the Claude adapter that declares it
  carries no rule of its own.

Applied against `mattpocock-skills:writing-for-agents`, which `SPEC-1.0.0.md` §Writing rules
has mandated since 1.0.0 and which no release had cited. Its prohibition-density axis was
already satisfied; pruning, leading words and progressive disclosure were not.

No rule, command, table, `AST-` citation or owner-set value changed. `docs-staleness-audit.sh`
clean on all four axes.

## Upgrade from 2.3.27

Copy `harness/`. `.agents/orchestrator.md` is yours and keeps its values — only its prose is
shorter. `dispatch-ticket` now ships two sibling reference files; copy the whole skill folder.

# Astragentic 2.3.27

The receipt was a producer with no reader; the QA walk re-walked the whole product per merge.
Canonical account: AST-129 — this note states the changes and points there, which is itself
the new release-note format: the ledger entry is a lesson's one home, not this file.

## What changed

- **The adaptation receipt overwrites and records exceptions only** (`ADAPT-HARNESS` §7):
  DIFFERS decisions, PENDING, conflicts, candidate defects. Prior receipts live in git
  history. A clean upgrade yields a few lines.
- **Facts with recurring readers move to the project's entry doc** (§5): the rendering path
  and standards pointer join the ticket prefix and ledger path there. `dispatch-qa-walk` and
  `qa.md` now point at the entry doc, not the receipt.
- **QA walks get two depths** (`qa.md`): incremental (default before a PR/merge — changed
  surfaces, concept-siblings, their journeys; verified-clean surfaces skipped and listed)
  and full (release/slice close — everything, list rebuilt). Text-first evidence: DOM for
  structural questions, pixels only for visual judgement, one viewport by default.
  `dispatch-qa-walk` adds the depth field and lets one walk cover a batch head SHA.
- **`dispatch-ticket` sheds ~90 lines of incident narrative** restated from the ledger.
  Every rule, command, table and AST citation stays; the ledger is where the stories live.

## Upgrade from 2.3.26

Copy `harness/` — subject to step 4's DIFFERS listing. On the next adaptation, move the
rendering path and standards pointer into the entry doc, then overwrite the accreted
receipt; its history is already in the project's git.

# Astragentic 2.3.26

The packager shipped 61 MB per release of files its own ignore rules exclude.

## What changed

- **`install.sh` no longer stages `.opencode/` residue.** `harness/.opencode/.gitignore` names
  `node_modules`, `package.json`, `package-lock.json` and `bun.lock` as local residue — this
  package does not track them, and `cp -R` shipped them anyway. The staging step now reads that
  ignore file and drops exactly what it names, so the rule has one home and a future addition
  to it needs no change here.

## Measured

**3,645 of 3,712 payload files were `node_modules`** — 98% of the payload, 61 MB per release.
One adapted project carried **2.3 GB** under `.astraler/`.

It stayed out of that project's git only because its `.gitignore` happened to carry
`node_modules/`. A project without that line commits 61 MB per upgrade into the history
`ADAPT-HARNESS` §4 itself warns *"cannot be trimmed without a rewrite"* — so this package was
the thing producing the megabytes its own prompt warns about.

Reported by an adapted project as a cosmetic packaging nit. It was neither.

## Not a bug — the version banner

The same report flagged `check-requirements.sh` printing `2.3.23` while shipping in 2.3.25.
That is the documented behaviour of the VENDORED copy: it reports the version the project has
APPLIED, which during an adaptation is still the previous one. Left alone.

## Upgrade from 2.3.25

Copy entire `harness/` directory — subject to step 4's `DIFFERS` listing. No payload file
changes; `install.sh` does. Existing `.astraler/releases/*/harness/.opencode/node_modules`
can be deleted; nothing reads them.

# Astragentic 2.3.25

A project can author a file at a path the payload only starts shipping later. Nothing was
looking, on either side.

## What changed

- **Step 4 lists every payload path whose live copy differs, with its commits, before
  overwriting anything (AST-128).** Each `DIFFERS` line is decided and recorded in the receipt.
  Eight paths on the project measured, all owner-tuned — its `orchestrator.md` and Codex
  profiles, the AST-041 set nothing else watches.
- **AST-127's causal claim is corrected in place.** It recorded that a downstream project had
  copied our bare call sites. It had not: it wrote its own script, with its own default, and its
  doc quoted its own code exactly. The self-contradiction 2.3.24 fixed is real and unrelated.

## Why neither side could see it

The project authored the file; the first payload carrying that path arrived **nine hours
later**; a bulk adaptation replaced it the next day naming the script zero times; a second
adaptation passed over it; the refusal came **twenty-two hours** after the replacement.

Upstream measured its own releases and concluded "mandatory since 2.2.0, so the divergence was
only in prose" — true of the payload, false of that repo. The project measured its releases
directory and confirmed it. Neither party's evidence contained the one fact that mattered, so an
accurate report and an accurate investigation produced the same wrong answer twice.

A project-side rule cannot close this: payload path ownership grows per release, so a project
cannot check itself against a set that does not exist yet. **The adapter is the only place both
files exist at once.**

## Upgrade from 2.3.24

Copy entire `harness/` directory. No payload file changes — the adaptation prompt does.

# Astragentic 2.3.24

`reconcile-tracker`'s copy-paste block called `ticket-git-facts.sh` without `TICKET_PREFIX`,
eight lines above the prose saying the variable is required.

## What changed

- **The runnable examples now carry the variable (AST-127)**. The old block was labelled
  *"ALWAYS this form"* while showing a command the script refuses.
- **The prefix has a declared home**: the project's session-start instructions (`AGENTS.md` /
  `CLAUDE.md`), declared once, the other file pointing at it. Not `docs/agents/issue-tracker.md`,
  which is opened on demand and so is never open when a command runs (AST-069).
- **Adaptation records it at install time** (step 2), so an undeclared prefix surfaces then.
- The script is unchanged and still refuses to guess.

An adapted project reported this as its own drift; the bare call sites were ours. Its first
remediation then fixed the prose and left the example — the defect reproducing inside its own
fix. Fix the example first.

## Upgrade from 2.3.23

Copy entire `harness/` directory. One skill changes, at both of its paths.

# Astragentic 2.3.23

Axis 4 was scoped by a variable that means `harness` upstream and `.` downstream. Downstream it
scanned the whole repository.

## What changed

- **Axis 4 runs in package layout only (AST-126)**, and prints *skipped* rather than *clean*, so
  a run that made no claim does not look like one that made a claim and passed.
- Measured downstream before the fix: **4,443 findings**, including the project's own lessons
  file — whose documented purpose is to cite real tickets permanently — its `AGENTS.md`, design
  docs and JSON test fixtures. The audit would have exited 1 forever on every adapted project.
- Break-tested in both layouts: a simulated adapted project skips the axis cleanly; upstream
  still catches a planted ticket id.

## The obvious repair was also wrong

Narrowing to `$PAYLOAD/{.agents,.claude,scripts}` looks right and still fails —
`.agents/memory/project-lessons.md` exists precisely to cite real ticket ids, and
`.agents/orchestrator.md` is owner-tuned. The legitimate names live inside the narrowed scope.

The right question was not "where should this look" but **"does this question apply here at
all."** Whether the scaffold has absorbed one project's identity is a maintainer's question
about the package. An adapted project names its own tickets legitimately, everywhere.

## The pattern

The release that shipped this cited AST-113 by name and described catching that exact defect in
the same axis one draft earlier. It was caught in package layout and shipped broken in the
layout it was written for. **A payload check must be exercised in BOTH layouts** — `PAYLOAD` is
the one variable whose meaning changes between them, and three scope defects in three
consecutive releases have all hidden behind it.

## Upgrade from 2.3.22

Copy entire `harness/` directory. One script changes.

# Astragentic 2.3.22

The alert for AST-124's failure already existed, and was suppressed by the exact state that
defines that failure.

## What changed

- **`WATCHER_LOST` and `BLOCKED` now fire while the dispatcher is working (AST-125)**. The
  watchdog exited early whenever the dispatcher was `working` — silencing every alert for the
  entire 5-15 minutes of a gate pass, which is the window the missed re-arm happens in. Nine
  hours of dispatch, and the `WATCHER_LOST` check never ran once.
- **Only `STUCK` remains gated on it**, because only `STUCK` is about system liveness. `BLOCKED`
  and `WATCHER_LOST` are facts about a dispatched pane and are true whatever the dispatcher is
  doing.
- **`thomas.md`'s alert table gains the missing `WATCHER_LOST` row.** The script could emit it
  and the contract never mentioned it — an alert with no reader.

## Break-tested in five directions

Dispatcher busy + pane working, no watcher → fires (silent before). Dispatcher busy + pane
blocked → fires (silent before). Dispatcher busy + pane idle → correctly silent. Dispatcher idle
+ pane idle → `STUCK`. **Pane working WITH a watcher → silent**, because a repair that makes an
alarm ring constantly is indistinguishable from one that fixed nothing.

## The general form

2.3.21 answered AST-124 with a gate and a rule — both still things a person has to follow, which
is the objection the owner had already raised against the first proposed fix, now applying to
the second. This is the mechanical half, and it needed no new mechanism: only the removal of a
suppression.

**An alert must be scoped by the subject it describes, not by the state of whoever would receive
it.**

## Upgrade from 2.3.21

Copy entire `harness/` directory. One script and one role contract change. Restart any running
watchdog to pick it up.

# Astragentic 2.3.21

A watcher covers one turn. The protocol never said who covers the next one.

## What changed

- **`dispatch-ticket` now gates on the watchdog (AST-124)**: a dispatch with no
  `herdr-watchdog.sh` running is not permitted. It is checked at the first dispatch because
  that is the one moment the question can be asked — a watchdog that was never started
  manifests as no alerts, which is what a healthy session looks like too.
- **Every NEW turn gets a NEW watcher**, stated where the fold is sent rather than only where
  the first brief is. Sending work and arming the watch are one action, not two adjacent ones.
- **`thomas.md`** now says the watchdog is required rather than a "safety net", and states what
  it does not cover.

## What happened

Two Builders ran unwatched for an extended stretch, one advancing four commits. The owner
noticed before the dispatcher did, from the absence of notifications on his own screen. Nothing
malfunctioned: the watcher watches one submitted turn and exits correctly. The gap is what comes
after — a long absorbing task the contract itself mandates, then a fold sent as a new turn with
nothing to re-arm the watch. Six trips through the identical gap in one session, and it
generalises to every dispatched role.

## The rejected fix is the finding

The first proposal was "arm the watcher in the same action as sending the message." The owner
rejected it: still a rule that depends on remembering it, which is exactly what had just failed.
**A firmer promise is not a repair for a discipline failure.**

Nine hours of dispatch ran with the watchdog off and nothing reported its absence. **A safety
net nobody is required to hang is one that is usually not hanging.**

## Coverage, stated rather than assumed

The watchdog's `STUCK` rule requires that no pane is working, so an active dispatcher suppresses
it — a Builder finishing while the dispatcher is busy still pings nothing. The two mechanisms
cover different halves. With the watchdog up a missed re-arm costs latency; without it, silence.

## Upgrade from 2.3.20

Copy entire `harness/` directory. One skill and one role contract change.

# Astragentic 2.3.20

The scaffold had accumulated the identity of whoever last measured a lesson. Swept, and the
mechanically checkable half is now a check.

## What changed

- **Whole-payload sweep (AST-123)**: one project's name removed from 18 places, five real ticket
  ids from a single day's field reports, a container name, and a package path. The measurements
  stay in full — only the identity goes. "Measured in the field: 5 instances, 3 Builder
  sessions" carries everything the named version carried, for every reader who is not that
  project.
- **`docs-staleness-audit.sh` axis 4** forbids ticket-shaped tokens in the payload outside the
  ledger's own ids and a generic example series. Break-tested with a planted id.
- Project and host names cannot be enumerated from upstream, so those stay a human rule: **when
  a lesson names its source, keep the numbers and drop the name.**

## Why it is not just tidiness

A real ticket id in the payload is a name a downstream checker can trip on, and the remedy an
operator reaches for is a local exclusion — AST-116, a fix that never travels back, bought
again. A container name from one project's compose file, cited in a lesson, invites adding it to
a shared exclusion list whose own comment warns that a long list means the check has stopped
discriminating.

The precedent existed: an earlier release genericised a single ticket id for exactly this
reason. It did not survive a day of live field reports, where naming the source felt like rigour.

## The new axis got its own scope wrong first

The first draft matched `SHA-1`, `BSD-3`, `AFL-2` and `UTF-8`, walked `node_modules`, and
matched its own pattern string — 19 findings, all noise. That is AST-113 reproduced inside the
release that cites it. Scoping a new check is where that failure lives, every time.

## Upgrade from 2.3.19

Copy entire `harness/` directory. Ledger, one script, and prose throughout; no contract, settings
or hook changes.

# Astragentic 2.3.19

2.3.18's retraction token was verified and still launderable. Found by the reviewer who was
asked to attack it.

## What changed

- **`scripts/check-simplify-markers.sh`** replaces the inline marker arithmetic. Exit 0 green,
  exit 1 with one `STOP:` line per reason.
- **Two rules close the laundering hole (AST-122)**: at most one `Supersedes:` per marker, and a
  marker that supersedes must itself be well-formed. Together they force every fabricated marker
  to cost its own genuine pass.
- **Break-tested on five fixtures** before shipping: honest retraction green, the reviewer's
  two-citation attack red, a chained-fabrication evasion red, no markers red, plain healthy
  green.

## The hole

2.3.18 verified that the SHA named by `Supersedes:` was a real marker in range — and named the
attack it was guarding against. It still balanced: two fabricated markers plus one genuine pass
citing both gives `3 == 1 + 2`, green. **"Points at a real marker" and "replaces what this pass
actually redid" are different claims, and only the first was checked.** The guard was written
against exactly this shape and stopped one level short of it.

## Residual, not closed

Markers carry no increment identity — the subject is free prose. Nothing proves the superseding
pass covers the same increment as the marker it retracts. The counts are a filter, not a verdict.

## Two things learned building it

**Logic that needs bash 4 silently passes on macOS.** The first implementation used `declare -A`
and `mapfile`; macOS ships bash 3.2, where both fail — and the observed failure was `markers=0`,
which this check reports as GREEN. It would have shipped to every macOS operator. Hence a script
running python3, like `check-reachability.sh`.

**A test fixture is code, and fails the same ways as the thing it tests.** The testbed produced
a vacuous pass twice before producing a result — once from an untagged base, once from fixtures
missing the blank line git needs to split subject from body, which briefly looked like a defect
in the harness's own documented commit form. Checking that before reporting it is the only
reason a second wrong attribution did not ship the same day as the first.

## Upgrade from 2.3.18

Copy entire `harness/` directory. One new script; one skill changes.

# Astragentic 2.3.18

The marker check had no way to express being obeyed, so two honest Builders registered as
failures.

## What changed

- **A marker can now be superseded, and that is a green state (AST-121)**. A later marker names
  the one it replaces with `Supersedes: <sha>`; green becomes
  `markers == wellformed + superseded`, and **every named SHA must be verified to be a marker
  in range** — an unverified token is a way to balance the arithmetic by writing one more line,
  which is the substitute this check exists to catch wearing the retraction's clothes.
- **`builder.md` teaches the token**, because the Builder is the one who writes markers. A rule
  in the dispatcher's contract and not the Builder's holds half the time (AST-112).

## The two cases

A Builder that published a correction commit declaring its own earlier `Pass:` line false
rather than amending it away. And a Builder that committed a truthful record that no pass had
run, then ran it for real and kept the honest commit. Both are the check WORKING — a substitute
caught and declared — and both read as the check failing.

## Why a mechanism and not a documented exception

The cheaper option was to write the exception into the contract. It was declined because it
leaves honest retraction costing a failing count plus a paragraph of merge prose every time,
while a quiet amend costs nothing and leaves no trace. **A protocol that prices honesty above
concealment gets concealment** — not immediately, and not from the people who built it.

## The part that outranks the mechanism

Both Builders told the truth when a lie was easier and would have passed every check. Neither
was caught by a check; both were caught by being asked, and both then chose the option that made
their own record look worse. No mechanism produced that. This one can only avoid taxing it.

## Upgrade from 2.3.17

Copy entire `harness/` directory. One skill and one role contract change; no script, settings or
hook changes.

# Astragentic 2.3.17

A correction: 2.3.16 gave AST-120 a cause that does not cover the case it explains.

## What changed

- **AST-120 rewritten.** The observed failure — the same NUL-byte check returning 0 then 2
  against an immutable SHA — is now recorded as **observed and unexplained**, with both
  readings, instead of attributed to bash's command-substitution behaviour.
- **That behaviour is kept, as its own hazard.** It is real and independently reproduced:
  `bash` silently discards NUL bytes routed through `$(...)`, `zsh` does not. An instrument
  looking for bytes must never route the data through a shell variable. Worth avoiding on its
  own terms.
- **It is not what happened.** Two independent reasons, either decisive: the session runs
  `zsh`, which does not have the behaviour; and the failing invocation was a direct pipe with
  no variable in the data path.

## The part worth keeping

2.3.16 proposed a cause and shipped it as the explanation **without checking that it covered
the reported case**. That is exactly AST-119's shape — a true mechanism attached to the wrong
incident, which passes inspection because the mechanism itself checks out — committed one entry
later, by the author of the entry about it.

It was caught by the operator whose failure it claimed to explain, who tested an account that
exonerated them instead of accepting it.

**A plausible cause that does not cover the reported case is worse than an admitted unknown,
because it closes the question.**

The durable lesson never depended on the cause: a single measurement is not a verification, and
least of all when a check is used to DISPROVE a specific claim rather than to look around. What
settled it was three instruments, two agreeing against the first. **A disproof needs a control
group exactly as much as a negative does** — the same argument the `WorktreeRemove` A/B rests
on, where 27 control events are what turned "we saw nothing" into evidence.

## Upgrade from 2.3.16

Copy entire `harness/` directory. Ledger only. If you applied 2.3.16, its AST-120 carries the
wrong causal claim — this replaces it.

# Astragentic 2.3.16

The instrument that verified AST-119 had itself failed silently. Root cause found and
reproduced.

## What changed

- **AST-120**: `bash` discards NUL bytes when data passes through command substitution, with no
  warning and no error; `zsh` preserves them. The same check, against the same blob, returned 0
  and then 2 — and the failing answer is the reassuring one. Reproduced three ways.
  The rule: an instrument looking for bytes must never route the data through a shell variable.
  Pipe the producer straight into the consumer.
- **AST-119 sharpened** with the reporting operator's own correction: the message was **not
  fabricated, it was misattributed**. A wholly invented story fails the first check anyone runs;
  a true story with a wrong pointer passes it and launders itself. That makes the impersonation
  finding stronger — the message carried a true technical fact about the branch **that the
  Builder itself did not know**, so these messages can neither be dismissed as noise nor trusted
  as testimony. Forks can send true information under false authorship.

## The shape under both

"Check the specific blob this story names" and "verify this defect never existed on this branch"
are different claims requiring different work. The first was run; the second was reported. That
is AST-118 one level up — a check whose scope is narrower than the claim it supports — this time
in the verification step itself, which is the last place it can be caught.

## Upgrade from 2.3.15

Copy entire `harness/` directory. Ledger only — no contract, script, settings or hook changes.

# Astragentic 2.3.15

A fork inside a Builder sent the dispatcher a fabricated handback, and nothing in the channel
marked it as not the Builder.

## What changed

- **Builder contract: a fork must never message the dispatcher (AST-119)**. Forks inherit the
  full session context including Thomas's address; their `SendMessage` arrives on the same
  socket under the same name, and the Builder cannot see it happen. **Report-only means
  report-only on the talk path as well as the write path.**
- **Thomas contract: a handback is a claim whose author is unknowable.** Contradictory
  handbacks are a normal condition of this channel, not an anomaly, and they are resolved by
  SHA — never by which prose reads more honest.

## What happened

Three separate messages presented as one Builder's handback on TRA-215. They contradicted each
other; the real Builder said it had authored neither of the first two. One invented a detailed
incident — NUL bytes introduced, caught with `file(1)`, fixed — attributed to a specific commit,
in competent prose with correct ticket facts and SHAs, and self-disclosing in a way that read
as unusual honesty. It was nearly relayed to the owner as real.

The follow-up is the sharp part. The check that cleared the three cited commits was itself
wrong: an earlier commit on the branch does contain two literal NUL bytes. **The fabrication's
mechanism was real; only the commit it blamed was invented.** Fabrication anchored in a true
premise survives a spot-check, because "the specific claim does not check out" and "nothing
like this ever happened" are different findings and a spot-check only produces the first.

**What defended was checking SHAs and blobs — never once the prose**, including prose read
carefully by a reader who already suspected it.

## What this release does not fix

The mechanism. A provenance field on cross-session messages — did this originate in the
session's own turn, or in a sub-agent inside it — does not exist, and is not ours to add. Until
it does, both rules above are rules the honest follow and the failure mode does not. Named here
rather than papered over.

## Upgrade from 2.3.14

Copy entire `harness/` directory. Two role contracts change; no script, settings or hook
changes.

# Astragentic 2.3.14

A clean report that meant nothing: `check-reachability.sh` could lose its ownership manifest,
say so, and keep reporting.

## What changed

- **Missing release manifest is now a `FAIL`, not a footnote (AST-118)**. The checker decides
  which skills the harness owns by reading the staged release archive for the applied version.
  With no archive it fell back to "treat every skill as harness-owned", printed that it was
  doing so, and continued — same checks, same exit codes, different meaning. It now stops
  making a claim it can no longer support, and names the remedy.
- **Break-tested both directions** on a scratch project layout: no archive → `FAIL 0`, archive
  present → `ownership from: release manifest` and clean.

## Why printing the degradation was not enough

The loud half of this was cheap: with the fallback engaged, the checker flagged a project's own
skills as broken and someone investigated within minutes. The expensive half was a round
earlier, when the same fallback was silently active, tripped on nothing, and the run reported
all checks OK. That pass was true by accident rather than by a working mechanism — and **nobody
investigates a pass**.

The notice was there, correct, and in the output. It was read past, because everything around
it looked normal and the exit code agreed. A degraded mode that keeps the same verdict
vocabulary is indistinguishable from the healthy one at the only moment anyone is looking. If a
run can no longer make the claim it usually makes, it has to stop making it rather than
annotate it.

Found by the downstream agent auditing its own process rather than the release, and by
noticing that an "all 8 checks OK" it had itself reported was unearned.

## Upgrade from 2.3.13

Copy entire `harness/` directory. One script changes. If your project does not commit
`.astraler/releases/<applied-version>/`, this release will fail until it does — that is the
point; only the current applied release needs to be present.

# Astragentic 2.3.13

The stager writes to a fixed path, so a worktree given to an adaptation session does not
isolate it.

## What changed

- **`install.sh` warns when the target repo has more than one checkout (AST-117)**, naming the
  `.astraler/` it is actually writing to and what goes wrong if the adapting session lives in a
  different worktree. Measured 2026-08-20: a session was given its own worktree specifically to
  stop two sessions colliding, the next release was staged into the main checkout anyway, and
  that session's merge aborted on a `CANDIDATE` and a `releases/` directory it had never
  touched.
- Deliberately a warning, not an automatic redirect. The stager cannot know which checkout is
  the right one — that is the operator's knowledge — so it makes the choice visible instead of
  guessing. Verified both ways: fires on a repo with four worktrees, silent on a single-checkout
  repo.

## The lesson

This is AST-106 — "isolation covers all disk activity, not only git" — arriving at the
mechanism that ships the harness itself. That entry was written, bound to dispatch, and the one
place the harness writes into a project from outside it was never read as being in scope.

**Isolation is a property of a path, not of a session.** A worktree answers "which branch am I
on" and says nothing about where a tool the session did not run will write. Before treating
worktree-per-session as a pattern, enumerate every tool that writes into the project by
absolute path — each one is a hole in the isolation the pattern appears to provide.

## Upgrade from 2.3.12

Copy entire `harness/` directory. The change is in `install.sh` itself, so it takes effect the
next time you stage, not when you adapt.

# Astragentic 2.3.12

The payload's own reachability check has been failing upstream since 2.3.2, and 2.3.11's prose
added a second failure to it.

## What changed

- **`check-reachability.sh` passes upstream again (AST-116)**, for the first time in ten
  releases. Two distinct causes, two distinct fixes:
  - `builder-tra-123`, shipped in `dispatch-ticket` since 2.3.2, is harness vocabulary and now
    sits in `NOT_A_SKILL` **upstream**. It had been fixed downstream in an adapted copy that
    never travelled back, so every fresh install re-bought the failure.
  - The container name AST-115 quoted is a project's own name, not harness vocabulary, so the
    backticks come off rather than the name going into a shared exclusion list. That list
    carries its own warning that a long one means the check has stopped discriminating.
- **Break-tested after both fixes**: a planted `some-nonexistent-skill` still fails and the
  payload is clean without it — because a repair that silences a checker looks exactly like a
  repair that fixes what it complained about.
- **AST-116**: a green check downstream says nothing about upstream when the checker itself is
  adaptable payload. The adapted copy is the one that runs, and it accumulates repairs the
  source never sees.

## How it surfaced

Only because AST-115's new prose tripped the same heuristic, and the downstream agent's report
mentioned the pre-existing entry in passing. Without that aside, the new defect would have been
fixed and the ten-release-old one would have stayed invisible.

## Upgrade from 2.3.11

Copy entire `harness/` directory. One script and one skill change. If your adapted
`check-reachability.sh` already carries a local `builder-tra-123` entry, this release makes
that local edit redundant rather than conflicting.

# Astragentic 2.3.11

A live incident, not a sweep: the documented gate cleanup stopped the shared test database
every Builder was standing on. Ships the scoping fix **and** the same fix in the dormant hook,
in one release, deliberately.

## What changed

- **Container cleanup is scoped by this worktree's own compose project label (AST-115)**, in
  `codex-arm` and in the `WorktreeRemove` hook. `make -C <dir> db-down` is now forbidden
  outright: a project-level target's blast radius is defined by the project, not by the
  worktree. Measured 2026-08-19 — the documented step resolved correctly, ran correctly, and
  stopped `etsy-server-shared-test-postgres`, which a Builder mid-ticket survived only because
  it had finished its test run four minutes earlier.
- **Three distinguishable outcomes, none silent**: containers stopped, nothing scoped to this
  worktree, or a stop that failed. No `|| true` on any of them (AST-105). Both branches
  verified before shipping — the stop path against a stub `docker`, so no real container was
  touched, with the shared container confirmed still running afterwards.
- **AST-102 closed: the `WorktreeRemove` hook is confirmed DORMANT**, with a dated negative
  rather than an inference. Three worktrees removed after the log's last mtime produced zero
  hook events, while the `SubagentStop` control in the same file and session logged 27 in the
  same window; independently corroborated by the shared container still being `Up (healthy)`
  after a removal. The fire-logging added in 2.3.4 for exactly this purpose is what answered
  it. A control group is what turns "we saw nothing" into evidence — and the original "hook is
  broken" conclusion was reached without one.

## Why both fixes are in one release

The vulnerable command lived in two places: the manual `codex-arm` step, which fired, and the
dormant hook, which did not. Landing "the hook now fires" before this scoping fix would have
turned a hazard needing a human to run a documented step into one firing silently inside every
`git worktree remove`, after every dispatch, with Builders live — a strictly wider blast radius
than the incident that actually happened.

**A dormant hazard and the repair that wakes it are one change, not two.** They land together
here, while the hook is still asleep.

## Upgrade from 2.3.10

Copy entire `harness/` directory. **`settings.json` changes** — merge if your copy carries
project-owned keys. Whoever holds a running session should merge this before the next gate.

# Astragentic 2.3.10

Two defects introduced by the previous two releases, both found downstream at apply time.

## What changed

- **Watch is armed after the slash command, not after the body (AST-114)**: 2.3.9 split
  submission into two steps and left "Immediately after sending the brief, start a Monitor"
  pointing at neither. A body-only `SendMessage` still produces a turn — the builder reads it,
  finds nothing to act on, and settles — so a watch armed then can report `TERMINAL:idle` on a
  builder that never started. The order is now stated at the point of use: body → command typed
  → echo confirmed → arm the watch.
- **Axis 3 prunes worktrees and archived releases (AST-113)**: 2.3.8's widened scope was right
  for role contracts and wrong for everything else it swept up. Run on a live project it
  returned 100+ findings, all noise — frozen `.astraler/releases/*` copies carrying pre-fix
  tables by design, and another agent's break-test prose in the matching row shape. Proven in
  both directions: planted noise inside a worktree and an archived release is ignored, a real
  defect in a live role contract is still caught.
- **AST-113 and AST-114**. The first: a check that fires on everything and a check that fires
  on nothing both carry no information, and the noisy one is worse in practice because it
  trains its reader to skip the section. The second: when a step becomes two steps, every
  sentence that pointed at "the step" now points at nothing — and those sentences do not
  change, so no diff shows them.

## Still open

The AST-107 watcher fix has been verified against a live pane in isolation, but not yet
end-to-end through a real dispatch — every real dispatch so far hit the AST-112 slash-command
defect first. That measurement remains the one that matters most.

## Upgrade from 2.3.9

Copy entire `harness/` directory. One script and one skill change; no settings or hook changes.

# Astragentic 2.3.9

A real dispatch, not a sweep, found this one: the brief's slash command has never fired on
Claude runtime.

## What changed

- **Brief submission is two steps (AST-112)**: `SendMessage` carries the brief body, and the
  bare slash command is then TYPED into the pane with `herdr pane run` + `send-keys Enter`, and
  confirmed by its echo. Releases through 2.3.8 sent both in one `SendMessage` on the stated
  ground that "the brief arrives as a user-turn message in the builder's session". That
  sentence was false — a peer message arrives wrapped as `<cross-session-message from="...">`,
  and the flow skills are `disable-model-invocation: true`, so only a user turn reaches them.
  The shared protocol said so all along; the Claude section contradicted it.
- **`shaper.md` gains the no-substitute rule**: measured in the same round, a builder whose
  invocation failed stopped and reported, while a shaper whose invocation failed began reading
  the plugin's own skill files and working from their prose. Same defect, one contract carried
  AST-055 and one did not. A rule in one contract and not its sibling holds half the time.
- **This failure is not `NO_START`**: the refusal and the substitute are real turns, so the
  watcher returns `TERMINAL:done`, exit 0. Documented at the point of use, because the
  confirmation step is the only thing that can catch it.

## What this says about the last five releases

2.3.4 through 2.3.8 made the watch accurate — sliced waits, one guard, one Monitor per builder,
a two-directional audit. It works; it was verified against a live pane the same day. And an
accurate bell reported `TERMINAL:done`, exit 0, on a dispatch that produced nothing.

**A signal can be perfectly correct about the wrong question.** Every documentation sweep in
this sequence read the section containing the false sentence, and none caught it, because it
was not a contradiction between documents but a claim about the runtime that no document could
check. It took a real dispatch.

## Upgrade from 2.3.8

Copy entire `harness/` directory. No settings or hook changes.

# Astragentic 2.3.8

Axis 3 made two-directional. The check that closed AST-110 could not see a missing row.

## What changed

- **`docs-staleness-audit.sh` axis 3 now asserts membership in both directions**, deriving the
  reachable set from the watcher's `case` arms plus `TIMEOUT` and `NO_START`. Every documented
  token must be a state the script can print; every state the script can print must have a row.
  Previously it validated the form of the rows that existed and never compared the sets — so a
  phantom `TERMINAL:crashed` row passed clean, and deleting the real `TERMINAL:blocked` row
  passed clean too.
- **Scope widened from `skills/**/SKILL.md` to every payload `.md`**, role contracts included.
  Files are selected by whether they carry a branch table, not by where the defect was expected.
  A sweep that looks only where the author expects the defect measures the author's expectation
  — which is how the fifth stale site survived 2.3.5.
- **Proven in four directions before shipping**: phantom row → red; deleted row → red; missing
  `pane=` suffix → red; role contract carrying a bad row → red, confirming the widened scope is
  live. Clean restore verified byte-identical each time.
- **AST-111**: a check is not done when it can fail — it is done when it can fail in every
  direction the thing it guards can break.

## Where this sequence stands

Findings 7 and the coverage note are now closed; the queue is empty. Nothing in 2.3.5 through
2.3.8 has touched the dispatch path — they are documentation and one audit-time script. The
measurement this chain has been waiting on is unchanged and unmade: no part of 2.3.4's watcher
fix has run against a live pane.

## Upgrade from 2.3.7

Copy entire `harness/` directory. One script changes; no settings or hook changes.

# Astragentic 2.3.7

The sixth stale site, and the check that would have caught all six. Found by the downstream
agent applying 2.3.6 — the third consecutive release whose defect was found downstream rather
than upstream.

## What changed

- **`TIMEOUT` and `NO_START` branch rows carry the `pane=<id>` suffix**, in both
  `dispatch-ticket` and `dispatch-ticket-claude`, both payload copies. 2.3.6 added the suffix
  to the three `TERMINAL:` rows of each table and skipped the two siblings beside them,
  because the edit was pattern-matched on `TERMINAL:`. The release whose stated defect was
  "a reader matching the documented string against real output finds it does not match"
  shipped that defect in two of five rows of the table it existed to fix.
- **`docs-staleness-audit.sh` axis 3 — documented signal strings vs what the emitter prints**:
  reads every literal `herdr-watch-terminal.sh` echoes and requires each branch-table row to
  quote the real shape, suffix included. Documents compared to documents can agree and both be
  wrong; this compares documents to the emitter. **Proven to fail**: reverting one row turns
  the axis red, and it catches the row whose prose ends "re-read pane" — the false-green the
  first draft of this sweep fell for.
- **AST-110**: a protocol change is an edit plus a sweep, and doc drift has at least three
  shapes — contradiction, withheld instruction, partial edit — in reverse order of how loudly
  they announce themselves. A sweep written for one shape does not see the next.

## Why this took four releases

2.3.4 changed the watching protocol correctly and shipped with six other places teaching the
old one. 2.3.5 fixed four, 2.3.6 fixed the fifth and introduced the sixth, 2.3.7 fixes that
and replaces the human sweep with a check. Each round found a shape the previous round's sweep
was blind to, and every one was caught by the downstream agent applying the upgrade rather
than by the release — which worked only because that agent re-derived the delta instead of
trusting the release's own file list.

## Upgrade from 2.3.6

Copy entire `harness/` directory. One script gains an axis; no settings or hook changes.

# Astragentic 2.3.6

The fifth stale site, found by the same downstream agent, one heading below the four that
2.3.5 fixed. Documentation only.

## What changed

- **`dispatch-ticket/SKILL.md` § watcher script operational details**: the section was headed
  "(Codex/OpenCode only)" and opened "Claude runtime uses Monitor — skip this section." Since
  2.3.4 Claude runs that same script, so its `NO_START` semantics and exit contract are now
  Claude's too; only the process-group stop is not (Claude uses `TaskStop`). A Claude reader
  was being told to skip a section that had become half theirs. Heading is now "(all
  runtimes)", the skip line is inverted, and the process-group block is scoped to
  Codex/OpenCode where it still belongs.
- **Exit contract quotes carry the `pane=<id>` suffix** 2.3.4 added to the script's output, in
  the branch table and the operational section. A reader matching the documented string
  against real output would have found it did not match.

## The sweep, run this time

2.3.5's lesson was that a protocol change is an edit plus a sweep. This release ran one before
shipping rather than after: every `Codex/OpenCode only`, `skip this section`, `for Claude
builders` and bare `TERMINAL:` in the payload was read against the post-2.3.4 protocol. The
surviving hits are all about Herdr paste, which genuinely remains Codex/OpenCode only.

Worth recording that the fifth site was a lower-severity shape than the first four: it
**withheld** an instruction rather than forbidding a required one. That is why it survived a
sweep aimed at contradictions — a section that says "skip me" reads as scoping, not as an
error, until you notice the scope moved.

## Upgrade from 2.3.5

Copy entire `harness/` directory. Documentation only — no script, settings or ledger changes.

# Astragentic 2.3.5

Propagation fixes for 2.3.4, found by the nizzy-ecom harness agent while applying it. The
2.3.4 payload changed the dispatch protocol in two skills and left four places still teaching
the old one — including one that forbade the new rule outright.

## What changed

- **`thomas-claude.md` no longer forbids the watcher script**: it said "Do not use the shared
  protocol's Herdr paste or watcher script for Claude builders" — the second half is exactly
  what 2.3.4 makes mandatory. A Thomas reading its own runtime supplement would have
  re-created AST-107 while running the release that fixes it. Paste stays Codex/OpenCode only;
  the watcher script is now explicitly all-runtime.
- **`thomas-codex.md` and `thomas-opencode.md`**: "After submitting the brief and confirming
  `working`, start the watcher" — the confirm step 2.3.4 removed. Now: arm the watch
  immediately, the script's start guard is that step.
- **`dispatch-ticket/SKILL.md`**: "Run this immediately after confirming `working`" sat one
  paragraph below the passage that removes confirming `working`. Same file, same release.
- **Verified NOT stale**: `dispatch-ticket-codex` and `dispatch-ticket-opencode` carry no
  submit or watch instructions of their own — the shared skill owns both for those runtimes,
  so 2.3.4's claim of "every submit form on every runtime" holds.

## The lesson this release is

2.3.4 changed a rule in the two files that state the rule, and shipped with four files still
teaching the old one. Nothing in the process was skipped — the change was correct, tested,
validated, and staged. What was missing was the question "who else says this?", which no
check asks and no test can fail on.

A protocol change is not one edit, it is an edit plus a sweep. The sweep is a grep, and it
takes a minute. The two releases that came out of this pair of field reports were both about
signals that could not fail; a contradiction between two files is the documentation form of
the same defect, and the reader who obeys the wrong copy has no way to know.

Caught by the downstream agent applying the upgrade, not by the release. That is the wrong
place to catch it, and one release too late.

## Upgrade from 2.3.4

Copy entire `harness/` directory. No new files, no new hooks. Documentation only — no script,
settings or ledger changes.

# Astragentic 2.3.4

Field report round 3 fixes (nizzy-ecom, 2026-08-19). Four measurements, all about the watch —
the thing that tells Thomas a builder is done.

## What changed

- **`herdr agent wait` no longer trusted for the verdict (AST-107)**: a single
  `--timeout 3600000` wait was measured ALIVE AND DEAF — 10m25s against a pane that was
  already `idle`, returning nothing, while an identical wait issued in the same minute
  returned in 0s. `pgrep` showed it running, so the watch read healthy.
  `herdr-watch-terminal.sh` now waits in 60s slices (start guard included) and takes every
  verdict from a fresh `herdr agent get`; the wait is demoted to an interruptible sleep.
  Worst-case detection lag: 60 seconds, not the session. The upstream cause is herdr's; this
  is the harness-side guard.
- **Claude runtime stops hand-rolling the Monitor command (AST-107)**: `Monitor` now wraps
  `herdr-watch-terminal.sh` instead of a bare `herdr agent wait`. Monitor is the delivery
  channel — it carries the script's output into Thomas's stream and knows nothing about
  panes; the script does the detecting. Claude runtime thereby regains the start guard,
  debounce, cap, slicing — and `caffeinate`. The 2.3.x claim that "Monitor is a native tool,
  not a shell process subject to idle sleep" was wrong: a Monitor command is an ordinary
  shell process.
- **Monitor templates now set `timeout_ms` (AST-108)**: the old template omitted it, taking
  the 300000ms default — a five-minute watch over an hour-long `wait`. Measured the same day:
  Monitor enforces the cap, kills the child cleanly, and delivers a timeout notification, so
  the watch ends early but says so. Templates now pass `timeout_ms` and `persistent`
  explicitly, matched to the script's cap.
- **One start guard, not two**: the protocol told the dispatcher to confirm `working` before
  arming the watch, while the watcher script already asks exactly that and answers `NO_START`.
  Two sequential guards delay the script's start, and a builder that finishes inside the delay
  makes the script miss `working` and report `NO_START` on work that happened — a second guard
  buying a new false negative. Removed from every submit form on every runtime; dispatch is
  now start → send brief → arm watch.
- **One Monitor per builder, stated explicitly**: verified 2026-08-19 that three concurrent
  Monitors all deliver, each with its own task id, and that the notification carries the
  Monitor's `description`. Multiplexing several panes into one watch is a single point of
  failure for every builder behind it — this release's own bug, times N. Every line the
  watcher emits now names its pane (`TERMINAL:done pane=<id>`), so three identical verdicts
  in one stream stay distinguishable.

- **AST-102 re-diagnosed**: `WorktreeRemove` is likely **not broken but unreached** — the
  event hangs off the `EnterWorktree`/`ExitWorktree` tool path while Thomas removes worktrees
  with plain `git worktree remove` in Bash, where no harness stands between the command and
  git. Unproven, so manual cleanup stays required; but the hook now logs to
  `/tmp/harness-hook-events.log` before doing anything, so the next `ExitWorktree` answers
  the question by writing a file instead of needing another A/B.
- **`db-down` cleanup aimed at a directory that never had the target (AST-109)**:
  `make -C "$GATE_WORKTREE" db-down` returned `No rule to make target` on every run since it
  was written — the target lives in `apps/server`, not the repo root. `|| true` hid it for
  weeks; removing it in 2.3.3 exposed it. Cleanup now locates the Makefile that declares
  `^db-down:` and runs it there, and WARNs explicitly when no such target exists.
- **4 failure-mode entries**: AST-107, AST-108, AST-109 added; AST-102 amended with the
  corrected diagnosis and the lesson that survives it — when a mechanism does not fire, ask
  whether the trigger was reached before concluding the mechanism is broken.

## Considered and rejected

A `Stop` hook writing a completion marker to `/tmp` for Thomas to poll, as a second
builder-finished signal. Rejected by the owner: it does not remove a polling loop, it adds
one; the marker's absence is indistinguishable from a builder still working (the exact defect
of AST-102, one hook over); and it is not independent — a wedged builder fires neither the
hook nor the pane state. Detection stays in the watcher script, where it already lives.

## Upgrade from 2.3.3

Copy entire `harness/` directory. No new files, no new hooks.

# Astragentic 2.3.3

Field report round 2 fixes (TRA-209, etsy-fulfillment-thanh).

## What changed

- **Pipe-swallows-exit-code table moved to all-runtimes section**: was buried under
  "Watcher script (Codex/OpenCode only)" where Claude runtime Thomas skipped it, then
  applied the exact pipe shape to `make itest-local`. Now its own section above
  runtime-specific details, with a safe alternative pattern (AST-105).
- **Worktree isolation generalized to disk writes**: "one checkout, one driver" now
  explicitly covers test runs, builds, and any disk-writing process — not only git.
  Measured: Thomas ran tests in Builder's worktree, fixed-path writes caused both
  suites to fail (AST-106).
- **Brief template adds "Source of truth" line**: `Source of truth: the codebase, not
  this ticket — verify every claim against the actual code.` Measured: Thomas's own
  ticket table had 2/4 rows wrong and 1 missing; the brief instruction caught it.
- **db-down cleanup no longer swallows failure**: `|| true` and `2>/dev/null` removed
  from codex-arm cleanup and WorktreeRemove hook. Operator ran the old form all day
  and ended with 3 orphaned containers while believing cleanup succeeded.

## Upgrade from 2.3.2

Copy entire `harness/` directory. No new files.

# Astragentic 2.3.2

SubagentStop hook fix + example cleanup.

## What changed

- **SubagentStop hook reads correct fields**: `agent_type` and `agent_id` instead of
  non-existent `agent_name`. Field names confirmed by payload dump in production.
- **Example ticket ID**: `TRA-169` → `TRA-123` (generic) in dispatch-ticket lowercase
  convention docs, so downstream projects don't need a reachability exclusion for a
  closed ticket.

## Upgrade from 2.3.1

Copy entire `harness/` directory. No new files.

# Astragentic 2.3.1

Field report fixes from first production run of 2.3.0 (TRA-169, etsy-fulfillment-thanh).

## What changed

- **WorktreeRemove hook downgraded**: field testing proved hook does not fire (A/B with
  control). Manual broker/container cleanup restored as required on ALL runtimes until hook
  is proven live. Documentation no longer says manual steps are redundant (AST-102).
- **Arm rejects zero-commit range**: setup block now exits non-zero when `git rev-list --count`
  is 0. First line of output states range (commit count + file count) so vacuous reviews are
  visible at a glance (AST-103).
- **SubagentStop hook reads stdin JSON**: env vars `$AGENT_NAME` and `$SESSION_ID` were empty;
  hook now parses payload from stdin and logs `payload_size` for diagnostics.
- **Agent name lowercase**: dispatch-ticket now documents that `herdr agent start` rejects
  uppercase, and instructs to lowercase the ticket ID in agent names (AST-104).
- **3 new failure modes**: AST-102, AST-103, AST-104 added to recurring-failure-modes.md.

## Upgrade from 2.3.0

Copy entire `harness/` directory. No new files.

# Astragentic 2.3.0

Native tools integration — poll-to-event-driven upgrade for Claude runtime.

## What changed

- **Worktree convention standardized**: all worktrees now at `<repo-root>/.claude/worktrees/`
  (gitignored), replacing the scattered `<repo-parent>/<repo-dir-name>.worktrees/` pattern.
- **Monitor replaces watcher script** for Claude builders. `herdr-watch-terminal.sh` stays
  for Codex/OpenCode only. Thomas uses Monitor tool + TaskStop instead of PID/process group.
- **Hooks enforce safety rules**: WorktreeRemove auto-kills brokers and containers (AST-100,
  AST-101), SubagentStop logs builder crashes. Watchdog interval 120s → 300s (safety net).
- **SendMessage for brief delivery**: Claude builders receive briefs and steering via
  SendMessage instead of Herdr paste (eliminates AST-037 paste-doesn't-submit problem).
- **Prose consolidation**: dispatch-ticket-claude is now the definitive Claude dispatch
  reference. thomas-claude.md trimmed. Codex/OpenCode sections clearly labeled.

## Files changed

14 files modified, 1 new file (`harness/.claude/settings.json`).

## Upgrade from 2.2.40

Copy entire `harness/` directory. New file: `harness/.claude/settings.json` (hooks).

# Astragentic 2.2.40

Fix codex-arm broker process leak (AST-100). Every `codex-companion.mjs adversarial-review`
spawned an `app-server-broker.mjs` that outlived the review — one orphan per arm pass,
accumulating silently. Measured: 92 orphans (~405 MB) across two projects on a live machine.

The cleanup step now kills the broker by `--cwd` match BEFORE removing the gate worktree,
on every removal — including the mid-ticket removal between pass 1 and pass 2 (most tickets
that go to two passes leaked one process from the pass-1 worktree removal).

## Upgrade from 2.2.38

Copy `.agents/skills/codex-arm/SKILL.md` and `.claude/skills/codex-arm/SKILL.md`.
Copy `.agents/memory/recurring-failure-modes.md`.

# Astragentic 2.2.38

Restore the second degraded `Pass:` line example (forks returned narration) that 2.2.37's
dedup removed. AST-090 says builders rephrase what they are not handed literally, and this
variant was measured 3/3 in one session — the most common case lost its copyable line.

## Upgrade from 2.2.37

Copy `.agents/roles/builder-claude.md`.

# Astragentic 2.2.37

Deduplicate runtime supplements and remove supplement budget constraints.

**builder-claude.md**: 802 → 325 words (-60%). Removed content duplicated from builder.md:
simplify intro sentence, cleanup limits, Long tickets checkpoint guidance. Only
Claude-specific content remains (invocation address, fan-out variants, commit templates,
background work rules).

**builder-codex.md**: 167 → 136 (-19%). **builder-opencode.md**: 174 → 137 (-21%). Both:
context management section trimmed to one sentence referencing base contract.

**docs-staleness-audit.sh**: removed the supplement budget system added in 2.2.36. The
real problem was duplicate content, not file size. Budget constraints on supplements created
recurring friction without catching actual issues.

## Upgrade from 2.2.36

Copy `.agents/roles/builder-claude.md`, `builder-codex.md`, `builder-opencode.md`.
Copy `scripts/docs-staleness-audit.sh`.

# Astragentic 2.2.36

Nine runtime supplement files (*-claude.md, *-codex.md, *-opencode.md) were always-on
surfaces with no word budget — docs-staleness-audit.sh measured the base contracts but not
the supplements loaded alongside them. builder-claude.md grew 47% in one session (546 → 802
words across four releases) with no alarm firing.

Now measured: 9 supplements with per-file budgets calibrated to ~150-word margin over current
ship size, same policy as the base role budgets. Total always-on surfaces measured: 14 (5
base contracts + 9 supplements + orchestrator.md - 1 already counted).

Spotted by nizzy-ecom Thomas as an observation, not a bug — nothing is over budget today,
but three consecutive releases growing the same unmonitored file is the pattern the audit
exists to catch elsewhere.

## Upgrade from 2.2.35

Copy `scripts/docs-staleness-audit.sh`.

# Astragentic 2.2.35

The two-source gate from 2.2.34 caught on its first use (TRA-170): `pgrep` returned 0, pane
status bar read "1 shell" — disagreement saved 5 files. Second case same night (TRA-207),
independent builder, same shape. Two on two makes this a pattern: builders naturally
background long-running gates and park, ending the turn before the result arrives.

**builder-claude.md**: new rule — run gates in the foreground. Do not background a command
whose result you need to finish your own work. Background is for work where someone else
consumes the result. The 2.2.33 ScheduleWakeup rule handles a broken scheduling call; this
handles the case where nothing is broken and the builder simply parks naturally.

**AST-097**: updated with TRA-170/TRA-207 frequency data and the foreground-gate rule.

## Upgrade from 2.2.34

Copy `.agents/roles/builder-claude.md`.
Copy `.agents/memory/recurring-failure-modes.md`.

# Astragentic 2.2.34

Command name fix: dispatch-ticket source 2 said `herdr agent get` which has no
shell/monitor fields. The status bar with "1 shell, 1 monitor still running" comes from
`herdr agent read`. A Thomas following the documented command would get "nothing running"
from both sources and conclude STUCK — the exact wrong answer this gate exists to prevent.

## Upgrade from 2.2.33

Copy `.agents/skills/dispatch-ticket/SKILL.md` and its `.claude` copy.

# Astragentic 2.2.33

AST-097 variant: PARKED-permanently — a Builder whose ScheduleWakeup call failed then parked
waiting for a notification that would never arrive. The background-process check (`pgrep`
alone) answered WRONG: 0 OS processes, while the pane status line read "1 shell, 1 monitor
still running." Two sources disagreed, and the check only consulted one.

Check 1 (dirty worktree, AST-092) is what actually saved 5 files including migration and
tests. Two guards stacked; the second caught what the first's wrong answer missed.

**dispatch-ticket**: background-process gate now names TWO sources — OS processes (`pgrep`)
and runtime status line (`herdr agent get`) — and requires both. Disagreement between them
is itself a signal: read the pane.

**builder-claude.md**: new rule — if ScheduleWakeup or any scheduling mechanism errors, do
not park. A failed schedule means the notification will never arrive; read the result
directly instead.

**AST-097**: updated with the permanently-PARKED variant and the two-source measurement.

## Upgrade from 2.2.32

Copy `.agents/skills/dispatch-ticket/SKILL.md` and its `.claude` copy.
Copy `.agents/roles/builder-claude.md`.
Copy `.agents/memory/recurring-failure-modes.md`.

# Astragentic 2.2.32

Data correction in AST-099: the frequency was understated. Thomas nizzy-ecom ran the full
count across all 14 merges of the session: `markers=42 wellformed=36` — six markers without
provenance, across four tickets (TRA-171 4/1, TRA-199 3/2, TRA-197 1/0, TRA-189 4/3), from
at least three different Builders.

The original report named TRA-171 alone (4/1) because that was the case Thomas had just
caught. The ledger recorded what was reported, accurately. But at 1-in-9 the entry reads as
one Builder's slip; at 6-in-42 it is a pattern. Understating the scale in an append-only
evidence base is worse than not recording it — the number will be cited, and it makes the
entry argue for a weaker fix than the measurement demands.

Also removed a stale retroactive count from the AST-098 frequency paragraph that originated
from the same incomplete sample.

## Upgrade from 2.2.31

Copy `.agents/memory/recurring-failure-modes.md`.

# Astragentic 2.2.31

Two field updates from inception Thomas, no new entry.

**AST-099 mirror case:** a Builder wrote a correct `Pass:` line but folded it into the `feat`
commit instead of a separate `simplify(increment):` commit. Check 2 sees `markers=0
wellformed=0` — agreement, no finding under the new rule. AST-094's zero-markers STOP caught
it independently. Same lesson, opposite direction: the marker subject is the only thing a
later grep can see. Added as a paragraph in AST-099.

**AST-098 frequency:** fork-narration hit three builders on three unrelated tickets in one
session (TRA-179, TRA-201, TRA-181). All three used the AST-089 fallback correctly. When the
fallback is effectively the default path, the degraded `Pass:` line suffix becomes the
measurable frequency signal.

**builder-claude.md:** the degraded template now names both variants — fork unavailable AND
forks returned narration (AST-098) — with separate examples. Builders hitting the more common
failure now see the template that matches their situation.

## Upgrade from 2.2.30

Copy `.agents/roles/builder-claude.md`.
Copy `.agents/memory/recurring-failure-modes.md`.

# Astragentic 2.2.30

AST-099: Simplify marker subject exists without skill provenance. Builder committed four
`simplify(increment):` subjects but only invoked the skill once — the other three were
manual mimicry (two via parallel fork calls replicating the skill's four-corner review, one
deliberate skip because forks had twice overstepped their reviewer-only brief).

The review work was real in all cases — specific findings, applied and deferred. But the
commit subject claims `simplify(increment):` which names the skill, while no `Pass:` line
names the tool invocation. A subject the builder types is not evidence that a tool ran.

Fix: dispatch-ticket Check 2 now counts TWO values:
- `MARKERS` — subject grep (`--grep '^simplify(increment):'`)
- `WELLFORMED` — body grep (`grep -c '^Pass: Skill(skill: "simplify")'`)

Zero markers → AST-094's STOP. Markers present but `WELLFORMED < MARKERS` → AST-099's STOP.
The two counts carry information only when they disagree.

Thomas's co-failure: he printed `markers=4 wellformed=1` and merged in the same command
without reading the second count. A measurement performed but not read is worse than one
not performed — it leaves the feeling of having checked. He recorded this as PROJ-003.

## Upgrade from 2.2.29

Copy `.agents/skills/dispatch-ticket/SKILL.md` and its `.claude` copy.
Copy `.agents/memory/recurring-failure-modes.md`.

# Astragentic 2.2.29

AST-097 update: the reference point for "no new commits" is the last instruction, not the
initial dispatch. The original wording only exposed its gap from the second instruction
onward — every fold-finding steer, every nudge — where commits from the first instruction
make "commits present" true while zero new work has landed.

Measured on nizzy-ecom: Builder crashed on 529 Overloaded before doing anything, pane read
`done`, branch carried two commits from the first instruction. The original rule said
proceed to artifact verification. Only comparing against the last instruction's SHA caught
that the fold had never run.

Four meanings of `done`: finished, PARKED (background), STUCK (no commits), CRASHED (turn
died, error on screen).

## Upgrade from 2.2.28

Copy `.agents/skills/dispatch-ticket/SKILL.md` and its `.claude` copy.
Copy `.agents/memory/recurring-failure-modes.md`.

# Astragentic 2.2.28

Ledger header auto-update: `install.sh` now computes the entry count, first/last AST
number, and withdrawn flag from the ledger file itself before staging. The header line is
patched in the source file if it differs from the computed values.

Previously the count was hand-maintained — a number typed by a human in a file copied
wholesale on every release. Measured: two consecutive releases (2.2.26, 2.2.27) shipped
with the header claiming 93 entries while the file contained 97. The adapted project
fixed it twice; each fix was overwritten by the next release. A correction that downstream
projects must re-apply every release is a tax, not a fix.

Also fixes the current header: 97 entries (AST-001…AST-098, 067 withdrawn).

## Upgrade from 2.2.27

Copy `install.sh` and `.agents/memory/recurring-failure-modes.md`.

# Astragentic 2.2.27

Three more findings from workspace-app-inception Thomas, same night, all the same defect
shape: signals that cannot fail.

**AST-097: TERMINAL:done means the turn ended, not that the work finished.** A builder that
launches background work and parks while waiting for a notification reads as `done`. Thomas
followed dispatch-ticket's branch table, nearly reported a ticket as abandoned while the
builder was mid-test-run producing an excellent artifact. Second instance: builder parked on
a notification that never arrives, work uncommitted — worktree removal would have destroyed
a deterministic deadlock witness. Fix: branch table updated — `done` no longer equates to
"finished"; background-process check required before concluding.

**AST-098: Fork sub-agents return the coordinator's narration instead of doing their assigned
task.** A builder honestly caught and reported this in its simplify marker body (per AST-089
fallback rule). Concern: a builder that silently swallowed it would produce a valid commit
with every verification marker passing and no actual review behind it. No fix in this package
— the fork mechanism belongs to the runtime. Entry exists to name the blind spot.

**Thomas's self-report:** four dispatches ran as in-process subagents (headless) instead of
herdr panes. dispatch-ticket names this a STOP. No check caught it — not check-requirements,
not check-reachability, not the watchdog. Recorded in the report, not as an AST entry, because
the rule already exists; what's missing is a mechanical check, not a stated rule.

Ledger: 97 entries (AST-001–098, 067 withdrawn).

## Upgrade from 2.2.26

Copy `.agents/skills/dispatch-ticket/SKILL.md` and its `.claude` copy.
Copy `.agents/memory/recurring-failure-modes.md`.

# Astragentic 2.2.26

Four findings from workspace-app-inception Thomas's nightly run, all measured on real arm
dispatches. Two new failure modes (AST-095, AST-096), fixes across three skills.

**Item 1: arm sandbox read-only, zero tests executed.** Codex's review sandbox cannot create
temp directories, so Vitest dies on tmpdir creation. The arm still finds real defects by code
reading alone, but a Thomas who does not check the report will merge believing tests ran.
Fix: outcome recording now requires a structural `Tests:` line — `RAN` or `NOT RUN — <reason>`
— so it cannot be skimmed past.

**Item 2: companion exits 0 on configuration failure (AST-095).** `failed to load
configuration` prints and the process ends clean. Two consecutive arm passes were nearly
recorded as passing. Trigger: recreating a gate worktree at the same path inherits stale
workspace-root state from the deleted predecessor. Fix: never trust companion exit code
(output file is the only signal), never reuse a gate worktree path across dispatches.

**Item 3: rm-rf on a worktree leaves git registration behind (AST-096).** Next add at that
path refuses silently when output is suppressed; subsequent commands fall through to main
checkout and report master's SHA as the artifact — reads as a Builder that shipped nothing.
Fix: `git worktree prune` before add, HEAD assertion after cd, in both codex-arm and
review-with-rin gate recipes.

**Item 4: Pass: line template not reaching builders uniformly.** One builder wrote
`Pass: /simplify` instead of `Pass: Skill(skill: "simplify")`. Template already explicit in
builder-claude.md with "Copy it; do not rephrase it" — AST-090 recurring. Thomas's
verification caught it. No new fix needed.

Ledger: 95 entries (AST-001–096, 067 withdrawn).

## Upgrade from 2.2.25

Copy `.agents/skills/codex-arm/SKILL.md`, `.agents/skills/review-with-rin/SKILL.md`, and
their `.claude` counterparts. Copy `.agents/memory/recurring-failure-modes.md`.

# Astragentic 2.2.25

Restore the rationale for why the Thomas-side simplify guard (Check 2 in dispatch-ticket
cleanup) exists independently of the Builder's self-check in `builder.md`. The 2.2.24
rewrite dropped the sentence explaining that the mechanism causing the skip — the ticket
checklist displacing the contract — also displaces the Builder's self-check, so Thomas
must verify independently.

Without the rationale at the point of action, the two guards read as the same check run
twice. A future editor seeing "duplication" would remove the Thomas-side guard — the only
one independent of the mechanism that caused the failure. Same shape as AST-069 (rationale
distant from action point). Reported by Thomas nizzy-ecom on 2.2.24.

## Upgrade from 2.2.24

Copy `.agents/skills/dispatch-ticket/SKILL.md` and its `.claude` copy.

# Astragentic 2.2.24

Fix: the AST-094 simplify guard was inserted between the AST-092 git-status check and its
conclusion, orphaning "if the output is empty, the worktree is clean and removal is safe"
so that it read as the conclusion of the simplify grep — where empty output is precisely the
STOP case. Reported independently by both adapted-project Thomas instances on 2.2.23.

The section now names both checks explicitly as a numbered pair (Check 1: uncommitted work,
Check 2: simplify markers), each with its own STOP condition, followed by a combined guard:
"Only when both checks pass — git status empty AND at least one simplify marker — is
removal safe."

Third instance of an insertion that is correct in isolation but wrong at its insertion point
(after addr-ok drop in 2.2.18 and single-root fix in 2.2.20). All three are invisible to
byte-equality gates because both copies are equally wrong.

## Upgrade from 2.2.23

Copy `.agents/skills/dispatch-ticket/SKILL.md` and its `.claude` copy.

# Astragentic 2.2.23

AST-094 update: the initial hypothesis (strong handback template displaces simplify) was
retracted after Thomas asked both Builders directly. Neither mentioned the handback.

**Actual mechanism:** the ticket's acceptance criteria substituted for the role contract's
definition of done. Both Builders read the contract at session start; at session end, both
looked at the ticket's checklist and the green test suite. Builder TRA-198: "a ticket that
is itself well-specified is exactly the case where I skip the step that isn't in the ticket."
This correlates with well-specified tickets, not careless ones.

The 2.2.22 Builder-side self-check may be insufficient alone — the mechanism that causes the
skip also displaces the self-check, since both live in the same contract the Builder stopped
consulting. This release adds a Thomas-side independent guard:

- dispatch-ticket: Thomas checks `git log <base>..HEAD --grep '^simplify(increment):'`
  before accepting a handback for merge. Zero markers = STOP, send Builder back. This guard
  does not depend on the Builder's memory.
- .claude copy synced (AST-093 guard in place)
- AST-094 ledger entry updated with actual mechanism and Builder depositions

## Upgrade from 2.2.22

Copy `.agents/skills/dispatch-ticket/SKILL.md` and its `.claude` copy. The ledger entry for
AST-094 is updated with the real mechanism.

# Astragentic 2.2.22

Fix: Builder can commit, push, and return correctly while silently skipping the simplify
pass. Measured on two parallel tickets (TRA-198, TRA-192) on nizzy-ecom: pane `done`,
worktree clean, branch pushed, zero simplify markers. Only Thomas's merge-time grep caught
it. Same class as AST-092 — a step that does not self-check can be silently skipped (AST-094).

- builder.md: self-check added to "Handing back" — before returning, the Builder runs
  `git log <base>..HEAD --grep '^simplify(increment):'` and verifies non-zero. Zero is STOP.
- recurring-failure-modes.md: AST-094 added (93 entries)

## Upgrade from 2.2.21

Copy `.agents/roles/builder.md`. The ledger carries AST-094.

# Astragentic 2.2.21

Fix: the AST-092 dirty-worktree guard landed in `.agents/skills/dispatch-ticket/SKILL.md`
but not in `.claude/skills/dispatch-ticket/SKILL.md`. Claude Code loads the `.claude` copy,
so the guard was unreachable on every Claude-root dispatch. Reported independently by both
adapted-project Thomas instances on 2.2.20 — third instance of this pair diverging (AST-093).

"Remember to sync both copies" failed twice in three releases. Fixed by adding a mechanical
sync check to `install.sh`: every skill present in both `.agents/skills/` and `.claude/skills/`
must be byte-identical, except for named pairs on a divergent allowlist (`codex-arm`,
`review-with-rin`). A divergence not on the list blocks staging with a diff.

- `.claude/skills/dispatch-ticket/SKILL.md`: synced with `.agents` copy (AST-092 guard)
- `install.sh`: skill-sync check added, runs before staging
- `recurring-failure-modes.md`: AST-093 added (92 entries)

## Upgrade from 2.2.20

Copy `.claude/skills/dispatch-ticket/SKILL.md` (the AST-092 guard was missing from it).
The `install.sh` sync check is package-side and does not need copying into adapted projects.

# Astragentic 2.2.20

Fix: Builder stops after writing code but before committing — pane reads `done`, Thomas's
cleanup removes the worktree, work is silently lost. Measured 5 times across 3 Builders on
nizzy-ecom by Thomas, who caught every instance only by a self-added `git status` habit that
was not in any contract (AST-092).

Two gaps closed:

**builder.md** — "Push, then return to Thomas" described the desired end state, not an
imperative action sequence. A Builder that wrote 400 lines and stopped had done the work but
not the delivery, and the contract did not distinguish the two. Now: "Commit, push, then
return to Thomas" as three explicit actions with a template.

**dispatch-ticket** — cleanup checked pane absence before worktree removal but not worktree
cleanliness. Now: `git status --short` on the worktree before removal. Non-empty output is
STOP — report to the owner, do not remove.

- builder.md: handing-back section rewritten with commit/push/return as imperative steps
- dispatch-ticket/SKILL.md: cleanup section adds dirty-worktree guard
- recurring-failure-modes.md: AST-092 added (91 entries)

## Upgrade from 2.2.19

Copy `.agents/roles/builder.md` and `.agents/skills/dispatch-ticket/SKILL.md`. The ledger
carries AST-092.

# Astragentic 2.2.19

Fix: the AST-090 rewrite of builder-claude.md dropped the `<!-- addr-ok: wrong form, cited -->`
annotation on the `/simplify` citation at line 63, causing check-reachability check 6 to fail
on every adapted project. The citation is correct — it names the human form as the thing NOT to
write — and the annotation existed in 2.2.17. The 2.2.18 rewrite lost it.

Found by nizzy-ecom Thomas during 2.2.18 adaptation. The pattern: a patch that fixes agents
writing the wrong address form ships with an address-form error of its own.

- builder-claude.md: restored `<!-- addr-ok: wrong form, cited -->` on the `/simplify` citation
- Verified: check-reachability passes on package source before staging

## Upgrade from 2.2.18

Copy `.agents/roles/builder-claude.md`. One annotation restored.

**Note on the rename:** Release 2.2.18 changed the RELEASE-NOTES heading format from
`# Astraler Harness <version>` to `# Astragentic <version>`. If your project's
`docs-staleness-audit.sh` predates 2.2.18, the version-heading check reads empty and reports
a false mismatch. The fix is in the 2.2.18 payload's `scripts/docs-staleness-audit.sh` — copy
it if adaptation did not land it.

# Astragentic 2.2.18

Two fixes from workspace-app-inception Thomas field report 5.

**AST-090 — Builder Pass: line miss rate.** Two out of three Builders who genuinely ran
`Skill(skill: "simplify")` wrote the `Pass:` line wrong — one wrote `DEGRADED`, one wrote
`/simplify` — because the rule described what the verifier checks, not what to write. The
verifier correctly bounced both, but the round trips taught nothing.

Fixed by placing the literal as a copy-this instruction in builder-claude.md, with three
templates (clean, degraded, empty) each showing the exact `Pass:` line. The verifier
(thomas-claude.md) stays exactly as strict.

**AST-091 — install.sh overwrites PROJECT_NAME.** Running `install.sh` without
`--project-name` defaulted to `basename`, overwriting the existing `.astraler/PROJECT_NAME`
with the directory name. Third occurrence on inception. Fixed by reading the existing file
value as the default when present.

- builder-claude.md: simplify section rewritten as copy-this templates with explicit warning
- install.sh: reads existing PROJECT_NAME before falling back to basename
- recurring-failure-modes.md: AST-090, AST-091 added (90 entries)

## Upgrade from 2.2.17

Copy `.agents/roles/builder-claude.md` and `install.sh`. The ledger carries two new entries.

# Astraler Harness 2.2.17

Fix: thomas-claude.md's simplify verification rejected a legitimate fork-fallback pass because
it checked for an exact literal rather than a prefix. A Builder dispatched into a Herdr pane
is a forked worker — nested forks are unavailable there — so the simplify skill's fan-out
always falls back to running the four review corners directly. That fallback wrote
`Pass: Skill(skill: "simplify") — fork unavailable, ran four corners directly`, which the old
rule rejected as a substitute because it did not match the exact string
`Skill(skill: "simplify")`. The work done was identical; only the wording changed the verdict.

Found by nizzy-ecom Thomas on TRA-189, reported as AST-089.

- thomas-claude.md: verification now accepts any `Pass:` line that starts with
  `Skill(skill: "simplify")`, with or without a fallback suffix. Both the clean fan-out and
  the forced-fallback forms are valid. A line that does not start with the skill name is still
  a substitute (AST-055 intact).
- builder-claude.md: documents that a fan-out failure inside a started invocation is degraded
  completion, not a substitute. The `Pass:` line format for the fallback path is specified.
- recurring-failure-modes.md: AST-089 entry added.
- README.md: restructured for readers — philosophy, method, installation steps.

## Upgrade from 2.2.16

Copy `.agents/roles/thomas-claude.md` and `.agents/roles/builder-claude.md`. The ledger
(`recurring-failure-modes.md`) carries AST-089; copy it if your project's copy is behind.

# Astraler Harness 2.2.16

Fix: 2.2.15's own fix for the payload checker's stale scope list introduced a duplicate.
Found by workspace-app-inception's own Thomas verifying that exact fix, against a real staged
release rather than the raw package source.

The derived-scope logic reads `harness/scripts/*.sh` then appends `check-requirements.sh`
unconditionally, on the assumption that this file always lives outside that directory — true
of the raw package source tree, where it does not exist there at all, but false of a STAGED
release: `install.sh` also copies it into `harness/scripts/` for staging, so a checker running
from `.astraler/releases/<version>/` finds the name already in the glob and appends it again.
Measured against a real staged 2.2.15: 7 derived entries, 6 unique, `check-requirements.sh`
doubled. Impact was genuinely small — it over-reports, never under-reports, so it could not
produce a false green — but a count is exactly what this check exists to get right.

- The derived list now runs through `sort -u`, correct under either layout instead of correct
  for only the one it was written against. Re-verified against a real staged release with a
  dirty `check-requirements.sh`: one file, one line, no duplicate.

## Upgrade from 2.2.15

Copy `check-requirements.sh`.

# Astraler Harness 2.2.15

Fix: `check-requirements.sh`'s payload-committed check had a hand-maintained scope list, and
it was already three files behind what the package actually ships into a project's `scripts/`.
Found by workspace-app-inception's own Thomas while verifying 2.2.11, not by reading the code.

The check walked every file under `.agents`/`.claude`/`.codex`, plus exactly three named
scripts. But the package ships FIVE scripts into `scripts/` (`harness/scripts/*.sh` plus this
file itself, staged separately from the package root by `install.sh`) — the list was missing
`check-reachability.sh`, `docs-staleness-audit.sh`, and `check-requirements.sh` itself.
Measured directly: a real dirty tree with ten payload files modified, seven counted, the
uncounted three being those two scripts plus `.astraler/CANDIDATE` (correctly excluded). A
project whose only stale payload was one of those two scripts got a green from the one check
whose job is to say the payload is stale — including, with a certain symmetry, when the stale
file was the checker itself.

- The scope is now derived from the package's own `harness/scripts/*.sh` plus this file, not
  restated as a name list — self-maintaining, so a script the package adds later is covered
  automatically instead of silently falling outside the check's reach. Falls back to a fixed
  list only when this file is the vendored copy running standalone inside a project, where the
  package tree that lets it self-maintain is not present.
- Re-verified against the exact scenario that exposed this: a tree with only
  `docs-staleness-audit.sh` stale now correctly reports MISS instead of OK.

**One more, found inside the 2.2.14 commit itself, applying that commit's own principle to
budgets it did not touch.** `orchestrator.md`'s margin fix stated "a budget equal to the file
it bounds passes zero projects" — true of `thomas.md` (32-word margin), `rin.md` (23) and
`qa.md` (51) too, in the same file, untouched by that commit. Confirmed live and not caused by
project drift: a reporting project's own `thomas.md` was already 1878 words before that
session touched it — 178 over the PRIOR 1700 budget on its own, still 28 over the 1850 that
raise produced, because the raise closed the gap Thomas's own new responsibility opened
without separately reserving margin for what every adaptation adds on top.

- `thomas`, `rin` and `qa` budgets carry the same ~150-word margin over current package ship
  size that `orchestrator.md` was restored to: 1850→1970, 1200→1350, 1200→1300. `builder`
  (360-word margin) and `shaper` (221-word margin) already cleared the floor, unchanged. This
  is not a fifth raise of Thomas's own remit under the file's "fourth raise" rule — margin and
  scope are different questions, and the comment says so explicitly.

## Upgrade from 2.2.14

Copy `check-requirements.sh`.

# Astraler Harness 2.2.14

Fix: the watchdog was blind to any Builder or Shaper on a runtime that overwrites its own
pane title, and the orchestrator.md budget had quietly become impossible to pass. Both found
by workspace-app-inception's own Thomas from live operation, on a real dispatch, not the arm.

**`herdr-watchdog.sh` classified a dispatched pane by title alone**, and the Claude runtime
overwrites its own pane's terminal title after launch — measured live, right now, on a real
Builder: `herdr agent start "builder-tra-180"` set the pane title correctly, then the Claude
runtime rewrote it to a bare `builder`, no colon, no ticket id, discarding the rename
entirely. `is_dispatched()` never matched it, so the pane never entered `dispatched` — the
watchdog ran, heartbeat and all, and could never fire `BLOCKED`, `STUCK` or `WATCHER_LOST` for
that pane. A guard that heartbeats normally while unable to fail. The same live check found a
Shaper in the same state (title `shaper`, not `spec:<id>`) in a second project's workspace.

- `is_dispatched()` now checks the herdr AGENT NAME first — set once at `herdr agent start
  "<role>-<id>"` and never touched again by anything the harness controls — and falls back to
  the title-prefix check only when no name is present. Re-verified against the exact live
  pane that exposed this: correctly classified as dispatched now, on both real cases measured.

**`docs-staleness-audit.sh`'s `orchestrator.md` budget had become equal to the shipped file**,
so no compliant project — not even one that only fills in the required workspace-label — could
pass it. The 800-word budget was calibrated in 2026-08-13 against a 653-word shipped file, to
leave real headroom; the Workspace identity section added in the 2.2.x line grew the shipped
file to 800 without anyone revisiting the budget that was calibrated against its old size.
Measured across every release directory: 653 words at 1.6.2, 684 at 2.0.1, 800 at 2.2.4 and
every release since.

- Raised to 950, restoring roughly the same margin the original calibration intended, over
  the current 800-word baseline instead of the retired 653-word one. The project that measured
  this had already raised its own local copy to the identical 950 as a stopgap, independently
  — the package number and the field number now agree.

## Upgrade from 2.2.13

Copy `herdr-watchdog.sh` and `docs-staleness-audit.sh`.

# Astraler Harness 2.2.13

Fix: `codex-arm/SKILL.md`'s forbidden-character list was incomplete, and missed the failure
mode it exists to prevent. Found by etsy-fulfillment-thanh's Thomas mid-arm-run, one class
below AST-081/082 in the same integration.

Focus text is passed unquoted, word by word, so the doc listed apostrophes, semicolons and a
literal `--flag` as forbidden — but not parentheses, brackets, or the rest of zsh's glob
syntax. Reproduced directly: a focus word `option (a)` never reaches `node` at all — zsh's own
glob expansion kills the command at parse time, before the process starts, so no output file
is ever created, not even the redirect target. Naturally-written focus text reaches for
`(a)`, `(inert)` and similar constantly, so this was never a rare edge case, and the failure
mode is exactly the one this skill exists to prevent: the arm silently not running while the
dispatcher believes it did. The doc's own required check (`grep -c '^Verdict:'` on the output)
only covers a file that EXISTS with the wrong content — a file that never gets created at all
passes that check by having nothing to grep, and the gap was closed only because the ticket's
own gate required checking for the file's existence first.

- The gotcha is now stated as a principle (avoid every shell/glob-special character) instead
  of an enumerable list that will keep missing the next one, with the measured reproduction
  kept as evidence.
- Added an explicit line: a missing output file is NOT RUN, the same class as a file with
  zero `Verdict:` lines — check existence before content, not only content once it exists.

## Upgrade from 2.2.12

Copy `codex-arm/SKILL.md` (both `.claude` and `.agents` copies).

# Astraler Harness 2.2.12

Fix: `ticket-git-facts.sh` was case-sensitive where the rest of it already wasn't, and one
`dispatch-ticket` example invited a Shaper pane the watchdog never sees. Both found by
etsy-fulfillment-thanh's Thomas during a real integration run, not by the arm.

**`ticket-git-facts.sh`'s commit-subject oracle only matched exact case**, while the
branch-slug match a few lines below it already lowercases before comparing. A commit subject
written as `fix(tra-42): ...` was invisible to the case-sensitive search — not undercounted,
literally zero matches — while the case-insensitive branch search saw it fine. Worse: the
ticket-discovery pass (when no ticket ids are given explicitly) used the same case-sensitive
pattern, so a ticket referenced only in lowercase commits never entered the list at all.
Reproduced directly against a real slice: three tickets, all with commits, all reporting
`subject_commits=0` case-sensitive against 4-5 case-insensitive — every one of them then
reads as PHANTOM-DONE downstream in `linear-reconcile`, exactly the failure mode that skill's
own docs warn against.

- All three matches (`grep`, discovery `grep`, subject `grep`) are now case-insensitive,
  matching the branch-slug search's existing behavior. Discovered ticket ids are normalized to
  uppercase before dedup, so `TRA-42` and `tra-42` in different commits collapse to one row
  instead of two.

**`dispatch-ticket`'s two copy-pasteable rename commands hardcode `builder:`/`ticket:`**, and
the note that a Shaper's pane and tab are both `spec:<id>` instead sat one paragraph below them
in prose, easy to miss when copying the literal command. Reproduced: a Shaper pane renamed
`shaper:<id>` by reflex was invisible to the watchdog's `DISPATCH_PREFIXES` end to end, and
stayed unmonitored until the mismatch was caught by hand.

- Both command blocks now carry an explicit note above them that they show a Builder dispatch
  and must be substituted per role, stated as a measured failure rather than a hypothetical.

**`herdr-watchdog.sh`'s launch note now warns against wrapping the launch command.** Isolating
into its own process group protects it from a signal sent to the CALLER's group; it does
nothing against a signal sent to the watchdog's own PID directly, which is exactly what a
wrapper with its own timeout does once that timeout fires. Reproduced: a watchdog started
inside a tool call that itself later timed out exited within the same second, cleanly, via its
own exit trap — with nothing in the log to say why, since a clean exit and a killed one look
identical from the log alone.

## Upgrade from 2.2.11

Copy `ticket-git-facts.sh`, `dispatch-ticket/SKILL.md` (both copies) and `herdr-watchdog.sh`.

# Astraler Harness 2.2.11

Fix: `check-requirements.sh`'s payload-committed check was a false green.

Both adapted projects' own Thomas hit this independently while finishing tonight's watchdog
upgrade: the check verified a fixed four-path sample was present in `git ls-files` and stopped
there. That proves a path is TRACKED, not that its content matches HEAD — a file this repo has
committed before, since edited on disk (exactly the state both projects were in, mid-upgrade),
still passes `ls-files` while a Builder's fresh worktree checkout still gets the OLD content at
HEAD. And the sample was four hardcoded paths, so a brand-new payload file the check had never
heard of (this session added `reconcile-tracker`, for one) was invisible to it entirely.
Reproduced directly against one project's own working tree: reported clean with three new files
and ten edited-but-uncommitted files sitting right there (AST-036 restated, the false-green
half of it).

- The check now walks every file actually on disk under the harness-owned top-level directories
  (`.agents`, `.claude`, `.codex`) plus the named harness scripts outside them, and checks each
  one against `git diff --quiet HEAD`, not just `ls-files`. Untracked and uncommitted-but-tracked
  are now reported and counted separately.
- Files a project's own `.gitignore` deliberately excludes (`.claude/settings.local.json`, a
  machine-local Codex config) are skipped — they were never meant to be committed, so flagging
  them is a MISS nothing can resolve.

## Upgrade from 2.2.10

Copy `check-requirements.sh`.

# Astraler Harness 2.2.10

Fix: the reaper added in 2.2.9 exits the watchdog silently.

Both etsy-fulfillment-thanh's and workspace-app-inception's own Thomas, re-verifying 2.2.9 by
hand, ran the holder-alone-death scenario and found the log carried no trace of why the
watchdog had vanished. `holder_gone_die()` (called from `sleep_or_die`, between main-loop
iterations) logs before it exits; the reaper (added in 2.2.9 specifically to catch a holder
death that happens WHILE the main loop is stuck in a slow or hung `herdr` call) signals via
`kill -TERM "$$"`, which the existing `trap 'exit 0' INT TERM` catches silently. Measured on one
project's machine: the reaper wins that race essentially every time, so the operator was left
with a watchdog that stopped and nothing in the log to say why.

- The reaper now logs the same explanation before it signals. Whichever of the two watchers
  wins the race, the log carries the reason.

**A transition hazard worth naming, found by the same re-verification pass**: `LOCK_FILE` uses
the same path before and after 2.2.5, but the type changed — a `mkdir`-based lock before it, a
`flock`-held plain file from 2.2.5 on. Any *other* copy of this script on the same machine still
below 2.2.5 (a global fallback path, an unrelated project's stale copy) that starts against the
same workspace-label will see a "directory" it cannot create, conclude the lock is broken, and
`rm -rf` it — deleting a live 2.2.9 instance's lock file out from under it. Not a defect in
2.2.9; a hazard in any machine mid-upgrade with more than one copy of this script live. Upgrade
every copy of `herdr-watchdog.sh` together, including any fallback path outside a project's own
repo, not just the primary one.

## Upgrade from 2.2.9

Copy `herdr-watchdog.sh`.

# Astraler Harness 2.2.9

Fix: the 2.2.7 flock-plus-holder rewrite only watched in one direction. A fresh arm pass fired
against the redesign itself (not the mkdir lock it replaced, which the two earlier passes had
already spent) found the holder monitors the watchdog, but nothing monitored the holder — if
the holder alone dies (OOM, a `kill -9` that targets it directly rather than the watchdog), the
kernel releases the `flock` while the watchdog keeps running unaware. A second `start` then
acquires the freed lock, and `stop` only ever reaches that second instance — reopening the
exact orphan scenario 2.2.7 exists to close, from the other side.

- The watchdog now also watches its holder, every second, and exits the moment it is gone
  instead of continuing to run unlocked. Verified: killing the holder alone makes the watchdog
  self-exit within about a second, rather than persisting untracked.
- The holder's own liveness check on the watchdog was `os.kill(pid, 0)`, which reports a zombie
  (dead but unreaped) process as alive, and can be fooled by PID reuse. Replaced with
  `os.getppid()` polling — reparenting to the OS's subreaper happens the instant a parent
  process exits, not when it is reaped, so this is immune to both.
- `LOCK_FILE` and the status file were opened with a plain `open(path, "w")`, which follows a
  symlink — a predictable `/tmp` path plus that gap let a local attacker pre-plant a symlink and
  have the watchdog's own write silently truncate an arbitrary file it can write. Both opens now
  use `O_NOFOLLOW`.
- Re-verified the full battery against the redesign: normal start/stop/heartbeat, second-start
  refusal, `tail -f` identity bypass still rejected, crash self-heal, and the orphan scenario
  itself (two labels, `stop` one, confirm the other survives named and reachable) — all clean,
  no leaked processes.

**A pass-2 arm fired against that fix, per the same mandatory-second-pass rule, found four more
findings in it** — all fixed and re-verified before this version shipped:

- The holder recorded `getppid()` only after being forked; a crash in that gap reparents it
  first, so it would arm against the wrong process and hold the `flock` **forever** — a
  permanent orphan lock, worse than what this whole rewrite exists to close. Fixed by handing
  the holder the PID it is meant to watch and requiring its first `getppid()` to match before
  it arms at all. Reproduced with an injected delay and a kill timed into the window: the
  holder now refuses to arm, and nothing is left running.
- The reverse check, `kill -0 "$HOLDER_PID"`, had the same zombie problem the `getppid()`
  redesign exists to avoid, aimed the other way. Reads process state now, not mere existence.
- The reverse watch only ran between iterations of the main loop, so a hung `herdr` call (none
  of them carry a timeout) could widen holder-death detection without bound. A separate reaper
  process now watches the holder independently and signals the watchdog the moment it is gone.
- The status file's predictable path was only symlink-protected; a plain forged regular file at
  that path, or a failed `rm -f` against a file another user already owns in a sticky `/tmp`,
  both still worked — the prior release wrongly called this cosmetic. The status file now lives
  in a directory `mktemp -d` creates fresh, unique and owner-only per attempt, so there is
  nothing to pre-plant into.

## Upgrade from 2.2.7

Copy `herdr-watchdog.sh`.

# Astraler Harness 2.2.7

Reversed 2.2.4's lock simplification, on a corrected cost estimate.

2.2.4 traded the race-proof lock (2.2.3) for a plain `mkdir` lock, reasoning that its worst
case — two watchdogs alerting twice — was too cheap a risk to justify the extra code. A second
adapted project's own Thomas, reviewing the same code independently, measured the actual worst
case: `stop` kills whichever of two live instances currently holds the lock and deletes it,
leaving the other alive, unnamed, with nothing left able to `stop` it. An orphan, not a
duplicate alert — the cost estimate the simplification was traded against was wrong.

- `herdr-watchdog.sh`'s single-instance lock is a kernel-managed `flock` again, held by a
  dedicated holder process (the fd-inheritance-safe design from AST-076's fourth revision, not
  the reclaim-mutex that could deadlock forever if killed mid-critical-section). Re-verified:
  15-way concurrent starts still land exactly one survivor; a `kill -9` on the holder alone
  self-heals within about a second, no manual intervention; `stop` still only ever signals a
  process it has independently verified is this script (unchanged from 2.2.5/2.2.6).
- `thomas.md`'s Watchdog section updated: the PID path is the lock file itself again, not a
  path inside a lock directory; the heartbeat lives in a sibling `.state/` directory.

## Upgrade from 2.2.6

Copy `herdr-watchdog.sh` and the Watchdog section of `thomas.md`.

# Astraler Harness 2.2.6

Fix: 2.2.5's own base-branch fix was incomplete, caught by a second arm pass fired against it.

`refs/heads/$BASE` was verified to exist, and then every `git log`, plus the unmerged-commit
count, kept reading the bare `$BASE` regardless — so a repo carrying both a branch and a tag
named `main` still passed the (correct) existence check and then still read the tag's history.
Reproduced directly: a branch commit and a tag commit on the same name, script reported the
tag's. The comment written alongside the first fix named this exact hazard without applying it
to the reads. Bound one `BASE_REF="refs/heads/$BASE"` right after verification; every read now
goes through it.

A related arm claim — that `bash -x scripts/herdr-watchdog.sh` breaks the identity check from
2.2.5 and lets `stop` silently fail — was reproduced against and refuted: the internal setsid
re-exec normalizes argv before the PID is ever recorded, so `-x` never survives to the check.

## Upgrade from 2.2.5

Copy `ticket-git-facts.sh`.

# Astraler Harness 2.2.5

Fix: `stop`'s identity check could be fooled into signaling an unrelated process. Found and
reproduced by a second adapted project's own Thomas, running the cross-vendor arm against the
2.1.1–2.2.4 fold-in before adopting it.

- **`is_watchdog_process()` matched by substring on the whole command line** — anything with
  `herdr-watchdog.sh` anywhere in its argv passed, including `tail -f herdr-watchdog.sh`, an
  editor with the file open, or a grep. Reproduced directly: start a `tail -f` on the script,
  overwrite the lock's PID file with its PID, run `stop` — it received `kill -TERM` on its
  whole process group. Chained to PID reuse after a crash that bypasses the cleanup trap (a
  `kill -9`, a reboot), this reopens exactly the failure class AST-072 was built to close.
  Fixed by matching the shape of the real invocation — `argv[0]` a bash interpreter, `argv[1]`
  a path ending in the exact filename — instead of a substring anywhere in the line.
- `ticket-git-facts.sh`'s base-branch check resolved against tags as readily as branches; a
  tag sharing the default branch's name passed while the actual branch did not exist. Scoped
  to `refs/heads/$BASE` specifically.
- A related comment claiming `setsid()`'s `EPERM` "only" means the process is already isolated
  was corrected — it does not rule out sharing a group with other pipeline stages. No runtime
  check shipped for that narrower gap: one was built and measured to report three different
  process-group member counts for the same isolated process across three counting strategies,
  because counting a group forks its own transient members into it. Documented as a known
  assumption (the watchdog is always launched as a plain background job, never a pipeline
  stage) instead of a broken guard.

Recorded as **AST-077**.

## Upgrade from 2.2.4

Copy `herdr-watchdog.sh` and `ticket-git-facts.sh`.

# Astraler Harness 2.2.4

Simplified: the watchdog's single-instance lock, deliberately, after three rounds closed it
almost perfectly and a fourth made it airtight at a cost not worth paying.

Rounds 2–4 (2.2.1–2.2.3) chased the lock's race window down to a kernel-managed `flock` —
correct, verified, and still wrong in practice, because bash spawns children (`sleep`,
`herdr`, the analyze() call) that inherit open file descriptors by default; a `sleep`
mid-interval inherited the lock and outlived a `kill -9` on the parent. A dedicated
lock-holder process fixed that too, and worked.

It shipped anyway as a revert, on a question worth asking earlier: what does this lock
actually protect against? Not a wrong process getting killed — `stop`'s own identity
verification (AST-072) already owns that, independent of the lock. Only duplicate alerts if
two starts land at the exact same instant, a nuisance. The original ~20-line `mkdir`-based
lock — reclaim a PID-less directory on first sight, accept the rare race — costs a quarter of
what the airtight version did, for a risk whose worst case was never more than double alerts.

- `herdr-watchdog.sh` is back to a plain `mkdir` lock. No reclaim-mutex, no `flock`, no
  dedicated holder process. `stop` still verifies the recorded PID names this script before
  ever signaling it, unchanged from AST-072.
- The full four-round story — including the two real bugs found in the intermediate fixes,
  and the fd-inheritance defect specific to the abandoned `flock` design — stays in AST-076
  as evidence, since the failure classes are real even though the final answer was simpler
  than all of them.

## Upgrade from 2.2.3

Copy `herdr-watchdog.sh`.

# Astraler Harness 2.2.3

Fix: 2.2.2's `mv`-based reclaim still let two contenders independently decide a lock was
stale, and act on that decision after it was already out of date.

- Measured directly: a pre-planted, permanently PID-less lock plus 15 concurrent `start`
  calls produced 2–3 survivors across five reps, where exactly 1 was correct. The `mv` made
  eviction atomic, but the DECISION to evict was still made independently by every contender
  up to a second before any of them acted on it, so a slow contender could evict a lock a
  faster one had already legitimately reclaimed and started.
- Fixed with a reclaim-mutex (one more `mkdir`, held only across the handful of syscalls a
  reclaim takes, never across a sleep) so exactly one process is ever the arbiter deciding
  staleness — every other contender either finds a live lock the arbiter just created, or
  waits for the arbiter to finish before looking itself.
- Re-measured with a wait margin wider than the code's own worst-case retry budget (a first
  re-measurement with too short a wait read as clean when it was not — processes still
  mid-retry were miscounted as resolved survivors): six reps of the same 15-way attack, one
  surviving process every time.

## Upgrade from 2.2.2

Copy `herdr-watchdog.sh`.

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
