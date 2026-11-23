---
name: codex-arm
description: Invocation mechanics for the cross-vendor arm on a Claude root — the Codex pass fired over a completed artifact by a direct, read-only `codex exec` with an Astragentic lens (no plugin). Covers the call, the lens per scope, the verdict rules, quota and failover, and where the outcome is recorded. The BUILDER fires the ticket arm from its own worktree, the SHAPER fires the spec arm, and Thomas fires the slice arm from the base checkout. Cadence lives in thomas.md and builder.md.
---

# The cross-vendor arm on a Claude root

**When it fires belongs to `thomas.md` and `builder.md`, not here** — three scopes, at most two
passes **per gate invocation**. Do not restate the cadence in this file; this skill owns the HOW.

**Who fires it depends on the scope**: the one who owns the artifact at that scope.

| Scope | Fired by | Standing in | Lens |
|---|---|---|---|
| `arm: ticket` | **the Builder**, inside its own closed loop | its own worktree, which holds the reviewed commits | `edge-lens.md` |
| `arm: spec` | **the Shaper**, before it cuts tickets | a detached checkout at the spec commit | `astra-adversarial-lens.md` |
| `arm: slice` | Thomas | a detached checkout at the slice head | `edge-lens.md` |

Whoever fires it records which vendor actually ran.

**What the arm wins at: internal inconsistency against the project's own standard**, because
the author reads the ticket and the arm reads the repository. Measured, for why the cadence in
`thomas.md` is per ticket rather than per phase: a slice-scope payload reached 6,904 added
lines across 31 files against 1,238 for one ticket, and three hollow tests survived that skim
in a single day. Pass 2 earns its cost the same way — on one ticket it found a real 40P01
deadlock inside the code pass 1's fix had just added.

**Why a direct call with our own lens (6.1.18, 6.1.19).** Seven merged tickets were replayed at their
merge trees and 336 findings verified blind (upstream, 2026-11-21). Codex reading with the edge
lens found 21 of the 34 real high/medium defects, the most of any single cell, at 0.77 precision and
about 79k tokens, and 32 of 32 direct runs exited 0 with schema-valid JSON. The spec and slice lenses
were not measured at those scopes (chưa đo): the Codex quota ran out before they could be. The
Codex plugin is not used: it allowed no effort setting, no lens of ours, leaked a broker per pass
(AST-100) and exited 0 on a configuration failure (AST-095). `codex exec review --base` still refuses
a prompt beside `--base` (codex-cli 0.171, exit 2), so the lens goes through plain `codex exec`.

## Model

**Every arm pass uses gpt-6.2-astra at medium effort, explicitly** (owner, 2026-11-21: Astra found 18
to 21 real defects per run against Sol's 16 to 20, at 70 to 79k tokens against 102 to 124k). Never
inherit the Codex default model, never substitute another one: changing the model is the owner's
decision.

## Stand on the reviewed head

**Ticket**: the Builder's cwd is the worktree holding the reviewed commits, so `HEAD` is the head
under review. **Spec and slice**: resolve the head yourself and stand in a detached checkout at it.
A run that reads the wrong head reads nothing and comes back clean, a gate that cannot fail
(measured twice in two days, AST-103):

```bash
git worktree prune                         # clear stale registrations BEFORE add (AST-096)
git worktree add --detach <repo-root>/.claude/worktrees/gate-arm-<key> <head-sha>
cd <that worktree>
[ "$(git rev-parse HEAD)" = "<head-sha>" ] || { echo "STOP: HEAD mismatch"; exit 1; }
```

Before removing that checkout, run `scripts/release-worktree-resources.sh "<that worktree>"`: it
reaps what the checkout holds and stamps the path, and `hook-git-guard.py` refuses the removal of an
unstamped one. It never removes the Builder's worktree.

## The call

`$OUT` is the arm's log, on the worktree whose branch carries the artifact (the ticket worktree, the
base checkout at slice, the Shaper's worktree at spec), **never the gate checkout**, which is removed
with the log in it. Use `.md` and check `git check-ignore -v "$OUT"`. Header and run go in ONE brace
group piped to `tee`: four logs were lost to a separate "copy it out first" step. Commit the log
before the receipt that names it on `Output:`. Run it with the Bash tool's `timeout: 600000`: runs
took 36 to 158 s, and a call that drops to the background ends the turn with the arm open (6.1.7).

```bash
OUT="<artifact-worktree>/.scratch/gates/arm-<key>-<scope>-pass<N>.md"; mkdir -p "$(dirname "$OUT")"
SK="$(git rev-parse --show-toplevel)/.claude/skills"
LENS="$SK/codex-arm/edge-lens.md"        # spec: $SK/astragentic-dispatch/agents/astra-adversarial-lens.md
NOTE=""   # spec: "This change is a specification: check each requirement and each claim about existing behaviour against the code it names."
          # slice: "This change is a whole slice of several tickets: also look for contradictions between them."
INTENT="<the owner's goals and must-not-break lines, plain words, no quotes, no dollar signs, no backticks>"
D="$(mktemp -d)"; git diff "$BASE"...HEAD > "$D/diff.patch"; git log --format=%B "$BASE"..HEAD > "$D/claims.txt"
[ -s "$D/diff.patch" ] || { echo "STOP: $BASE...HEAD is empty"; exit 1; }
{ echo "arm range: $(git rev-list --count "$BASE"..HEAD) commits, $(git diff --name-only "$BASE"...HEAD | wc -l | tr -d ' ') files changed ($BASE..HEAD) head=$(git rev-parse HEAD) model=gpt-6.2-astra lens=$(basename "$LENS")"
  perl -e 'alarm 540; exec @ARGV' -- env -u ORCA_PANE_KEY codex exec --cd "$PWD" --sandbox read-only \
    --skip-git-repo-check --model gpt-6.2-astra -c 'model_reasoning_effort="medium"' -c 'notify=[]' \
    --output-schema "$SK/codex-arm/lens-schema.json" -o "$D/arm.json" \
    "Your instructions are in $LENS: read it first and follow it (ignore any YAML header). The staged diff is $D/diff.patch; the repository is the current directory. The change's own description (claims) is $D/claims.txt; if your instructions say when to open it, open it then. $NOTE Owner intent: $INTENT. Read only: no edits, no test runs, no builds, no network. Return only the JSON object the instructions name." \
    < /dev/null > "$D/codex.log" 2>&1
  echo "exit=$?"
  python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(json.dumps(d, indent=1)); print("findings=%d" % len(d["findings"]))' "$D/arm.json" \
    || echo "cross-vendor arm: NOT RUN — no schema-valid output ($(grep -m1 -i -E 'usage limit|revoked|401|error' "$D/codex.log" || tail -1 "$D/codex.log"))"
} 2>&1 | tee "$OUT"
```

**The intent is what makes the pass worth running.** An intent-blind pass finds internal
inconsistencies; an intent-loaded pass finds betrayals of what the owner wants (a production-database
wipe surfaced only once intent was packed in). Measured at ticket scope, without: the shipped proof
named a planted defect in 39 s, left the tree untouched under an AGENTS.md that said "fix and
commit", gave exit 1 and NOT RUN on an unknown model, and stopped an empty range before launch.

## The verdict is yours, and it fails closed

- **No output is not a pass.** No `findings=` line in `$OUT` is `cross-vendor arm: NOT RUN` with the
  exit code and the reason, never a clean arm.
- **Every finding gets a disposition in `$OUT`.** Verify it at its line by the `astra-review` §3 rule,
  then record fixed (high or medium), low (with what you did), by design (cite where), false
  (evidence), or deferred (why). A finding with no line is an unread finding.
- **Pass 2** is owed when pass 1 left any fixed finding, over the full range again, under the rule
  in `thomas.md` (§The cross-vendor arm). About 0.7 of the edge lens's findings were real in the blind
  check, so most tickets run pass 2: about 160k Codex tokens per ticket.

## Quota and failover

Codex unavailable, out of quota (`usage limit` in the log; on 2026-11-21 the whole account stopped
until a date a week out), signed out (`401` / `token revoked` in the log, while `codex login status`
still says logged in, measured 2026-11-23: the owner runs `codex logout && codex login`), or the model refused → **the arm DID NOT RUN.** Record
`cross-vendor arm: NOT RUN — <reason>`; only the OWNER may accept proceeding without it, on the terms
`thomas.md` sets. Still read adversarially, as when the arm row is `no`, and record it as same-vendor
and advisory: at ticket scope `astra-review`'s adversarial lens on Opus; at spec scope the Shaper, and
at slice scope Thomas beside the fan-out, run `astra-adversarial-lens` on Opus (6.1.22), unless
that scope's Claude lens column in `orchestrator.md` is `no`. A same-vendor lens never
completes the arm, so the recorded vendor is always the one that actually ran.

Record the outcome once. **At ticket scope the `arm(ticket):` record IS the receipt**, with
`Vendor: codex gpt-6.2-astra (direct, <lens>)`; its shape and its `Tests:` field are in
`dispatch-ticket/MARKERS.md`. At spec and slice scope the merge decision trail carries the date, the
findings and their dispositions, the vendor that ran, and a `Tests:` line read the same way. **You
classify which findings are real** — the arm advises. Escalate to the owner on a genuine fork.

## Other runtime: a ticket built by the other vendor (6.1.6)

"Other vendor" is counted from the diff's author, never from the station's runtime. A Codex-built
ticket reaching a Claude station is armed by Claude, so the Codex pass in this file is not its arm.
The Codex side's exemption does not travel: the station's arm row decides, and only the owner
waives it. Thomas dispatches a Claude Builder pane on the ticket branch with a brief for the arm
alone; it runs the Codex payload's cross-vendor pass with Claude as the reviewer over
`<base>..<head>` and commits the `arm(ticket):` receipt naming the vendor that ran. Without the
Codex payload installed, record `cross-vendor arm: NOT RUN — no Claude pass installed` and ask the
owner. Field 2026-11-10: two Codex-built tickets under arm `no` read `markers=0` at a Claude
station's `--marker 'arm(ticket)'`. No handover arm has run yet.
