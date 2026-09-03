#!/usr/bin/env bash
# docs-staleness-audit.sh — two measurements of the surfaces that bill every session.
#
#   scripts/docs-staleness-audit.sh
#
#   1. BUDGETS  — always-on files against their ceilings. The prior package reached 100k
#                 words by accretion nobody measured; this is what stops that returning.
#   2. CLAIMS   — numbers a document states about itself, re-derived from the thing counted.
#
# Output is a report; exit 1 if either found something.
#
# THREE AXES WERE REMOVED IN 1.6.3, on the same test this package applied to five skills the
# same day — what has it caught, measured, not imagined:
#   AGE (>21 days = suspect) caught nothing here, and "old" is a candidate, not a defect.
#   FOSSILS (retired names in live docs) cost a hand-maintained marker list on every rename
#     and an exemption per false positive that outlives its reason; in three weeks its one
#     real catch was a marker of its own that had never matched anything.
#   DEAD LINKS scanned three router files, of which this package has ZERO and one project
#     has one. It printed "(skip)" three times and then "(clean)" — a green line over
#     nothing looked at, the exact class this file exists to catch (AST-051).
# Nothing replaces them: the plugin measures method, not document drift. That is the trade,
# stated rather than discovered later.
set -uo pipefail

# Self-locate rather than trust the caller's cwd: a CWD-relative root once measured one tree
# while reporting on another. But self-locating by a FIXED depth is worse — `../..` is right
# under `harness/scripts/` and lands on the repo's PARENT in every adapted project, where this
# audit reported "NO ROLE CONTRACTS FOUND" on a correct install. Walk up to the payload instead.
# (`ledger-index.sh` does not do it this way at all: it resolves from the ledger path it finds.
# An earlier version of this comment claimed otherwise and was wrong about the file it named.)
ROOT="${1:-}"
if [[ -z "$ROOT" ]]; then
  # Walk up from this script until a payload appears. Two layouts, one rule: the package keeps
  # the payload under `harness/`, an adapted project keeps it at the repo root.
  _d="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  while [[ "$_d" != "/" ]]; do
    if [[ -d "$_d/harness/.agents/roles" || -d "$_d/.agents/roles" ]]; then ROOT="$_d"; break; fi
    _d="$(dirname "$_d")"
  done
  ROOT="${ROOT:-$(pwd)}"
fi
# Derive the payload from ROOT, not from the caller's cwd. A bare relative `harness` here was
# the real CWD dependency: every axis below resolves through $PAYLOAD.
PAYLOAD="$ROOT/harness"
[[ -d "$PAYLOAD/.agents/roles" ]] || PAYLOAD="$ROOT"
FOUND=0

echo "=== 1. always-on word budgets (these surfaces bill every session) ==="
# Budgets guard the always-on surfaces against regrowth — the accretion that took the
# prior package past 100k words. Raise one only with an owner decision in the same commit.
# MARGIN IS THE MEASUREMENT, not the ceiling. The comment on role_budget() says every budget
# carries ~150 words of headroom because an adapted project MUST add its own content, and it
# names 32/23/51-word margins as the failure — "less headroom than a single sentence". This
# function then reported `ok` on exactly that state, so 2.7.0 shipped two contracts with ONE
# word of margin and the check called both fine. A downstream project hit it immediately:
# adding one paragraph to builder.md put it 215 over. A ceiling that passes at 99.9% is not
# measuring what the comment above it says it measures.
MIN_MARGIN=100
budget_check() { # <label> <limit> <count>
  if [[ "$3" -gt "$2" ]]; then
    echo "OVER: $1 = $3 words (budget $2)"; FOUND=1
  elif [[ $(( $2 - $3 )) -lt "$MIN_MARGIN" ]]; then
    echo "TIGHT: $1 = $3/$2 words — only $(( $2 - $3 )) words of margin, under the $MIN_MARGIN"
    echo "       an adapted project adds its own content to this file; that is the point of"
    echo "       adapting, and this margin does not fit a paragraph. Trim the payload copy or"
    echo "       raise the budget with a reason in the same commit."
    FOUND=1
  else
    echo "ok: $1 = $3/$2 words ($(( $2 - $3 )) margin)"
  fi
}
if [[ -d .claude/rules ]]; then
  # Path-scoped rules (frontmatter `paths:`) load only when matching files are touched —
  # they don't bill every session, so the always-on budget excludes them.
  RULES_TOTAL=0
  for r in .claude/rules/*.md; do
    if head -1 "$r" | grep -q '^---$' && sed -n '2,20p' "$r" | grep -q '^paths:'; then
      continue
    fi
    RULES_TOTAL=$((RULES_TOTAL + $(wc -w < "$r")))
  done
  budget_check ".claude/rules/ always-on total" 1100 "$RULES_TOTAL"
fi
# Per-role budgets, not a flat one. Thomas is the resident router: it owns seven phases, the
# frontier query, the claim protocol with both interlocks and its loss branch, three gate
# dispatches and merge. A uniform ceiling there stops measuring growth and starts shaving
# meaning — the last four words cut to reach 1200 all carried some. Raise a budget only with
# a reason recorded in the same commit.
role_budget() {
  # Every number below carries a MARGIN over the package's own shipped word count for that
  # role — the ~150-word headroom AST-085 restored for orchestrator.md, applied here for the
  # same reason: an adapted project MUST add its own content to these files (that is the
  # point of adapting), and a budget with near-zero margin over ship size fails a project the
  # moment it does the one thing adaptation requires. Measured 2026-08-18, package vs budget:
  # thomas 1818/1850 (32 margin), rin 1177/1200 (23), qa 1149/1200 (51) — all three read as
  # "raised enough" while leaving less headroom than a single sentence. Found live, by an
  # adapted project whose own thomas.md sat at 1878 words before anyone touched it that
  # session: 178 over the PRIOR 1700 budget, then still 28 over the 1850 this file raised it
  # to the same day, because that raise closed the gap thomas's OWN new responsibility opened
  # without separately budgeting the margin every adaptation needs on top. This is that
  # margin, applied once, to every role, not a fifth raise of thomas's remit — the case below
  # still needs a stated reason before its OWN ceiling moves again.
  case "$1" in
    thomas)  echo 2150 ;;
                           # RAISED 2.7.0, reason in this commit: that release added real
                           # scope here — the tracker interlock told honestly, the
                           # ready-for-agent gate, reading QA's coverage gaps, the
                           # compaction tier, and the one-reply rebuttal. Compression
                           # brought the file back under the OLD ceiling with ONE word
                           # spare, which is the failure the block above names, not a
                           # pass. The margin is the budget; 1969 ship + ~181 headroom.  # widest remit: claim protocol + three dispatch points + the arm
                           # cadence at three scopes. Raised from 1400 by owner decision
                           # 2026-08-13, porting a project ruling: the arm fires per ticket
                           # before its merge, so Thomas owns three fire points instead of
                           # one. Only the RULE landed here; the measurements that justify
                           # it went to codex-arm, which loads when the arm runs rather than
                           # every session. 1550 was the estimate and the port landed at
                           # 1557; the extra 50 is headroom rather than another trim, since
                           # the words being shaved to reach a round number still carried
                           # meaning — the failure this comment block already warns about.
                           # 1600 -> 1700, owner decision 2026-08-13, the THIRD raise in one
                           # day and worth saying so: Thomas gained two responsibilities that
                           # day, the arm at three scopes and the ledger write anchored to
                           # merge. The budget exists to make growth visible and deliberate,
                           # not to forbid it — but a fourth raise without a role gaining a
                           # phase is the signal that something belongs in a skill instead.
                           # 1700 -> 1850, owner decision 2026-08-18, the FOURTH raise and it
                           # clears the bar the comment above set for itself: Thomas gained a
                           # fourth anchored duty, `reconcile-tracker` at merge and at session
                           # start, alongside the arm and the ledger write. Only the wiring and
                           # the read-only ruling landed here; the drift classes, the join rule
                           # and the exercise-it lesson live in the skill, which loads only
                           # when the check runs. 1850 -> 1970 the SAME day: not a fifth raise
                           # of remit, the margin-calibration pass above — 1850 had shipped at
                           # 1818, a 32-word margin no project's own required addition fits in.
    builder) echo 1660 ;;
                           # RAISED 2.7.0, reason in this commit: that release added real
                           # scope here — the tracker interlock told honestly, the
                           # ready-for-agent gate, reading QA's coverage gaps, the
                           # compaction tier, and the one-reply rebuttal. Compression
                           # brought the file back under the OLD ceiling with ONE word
                           # spare, which is the failure the block above names, not a
                           # pass. The margin is the budget; 1499 ship + ~161 headroom.  # widest DOING surface: build, increment review, simplify,
                           # THE CROSS-VENDOR ARM, visual verification, the two correctness
                           # rules, handback.
                           # 1400 -> 1500 in 2.5.0, and the reason is a change of REMIT, not
                           # accretion: 2.4.0 moved arm: ticket into this role, and the old
                           # budget's own comment enumerated five responsibilities where the
                           # role now has six. Raising a budget to fit prose is the failure
                           # this check exists to catch; raising it because the role gained a
                           # phase is calibration. The arm section was compressed from 470 to
                           # 250 words first, and what is left is the receipt shape and the
                           # Reviewed-or-delta rule — a Builder cannot write the artifact
                           # without either.
    rin)     echo 1460 ;;
                           # RAISED 2.7.0, reason in this commit: that release added real
                           # scope here — the tracker interlock told honestly, the
                           # ready-for-agent gate, reading QA's coverage gaps, the
                           # compaction tier, and the one-reply rebuttal. Compression
                           # brought the file back under the OLD ceiling with ONE word
                           # spare, which is the failure the block above names, not a
                           # pass. The margin is the budget; 1305 ship + ~155 headroom.  # ships at 1177 (23-word margin before this pass) — second
                           # opinion, artifact verification, the arm's standard. Raised
                           # under the same margin-calibration pass as thomas and qa.
    qa)      echo 1450 ;;
                           # RAISED 2.7.0, reason in this commit: that release added real
                           # scope here — the tracker interlock told honestly, the
                           # ready-for-agent gate, reading QA's coverage gaps, the
                           # compaction tier, and the one-reply rebuttal. Compression
                           # brought the file back under the OLD ceiling with ONE word
                           # spare, which is the failure the block above names, not a
                           # pass. The margin is the budget; 1294 ship + ~156 headroom.  # ships at 1149 (51-word margin before this pass) — the running-
                           # product walk, interface/journey/contract/data axes. Raised
                           # under the same margin-calibration pass as thomas and rin.
    *)       echo 1200 ;;  # shaper ships at 979, a 221-word margin already above the floor.
  esac
}
BUDGETS_RUN=0
for ROLE in thomas shaper builder rin qa; do
  RF="$PAYLOAD/.agents/roles/$ROLE.md"
  if [[ -f "$RF" ]]; then
    BUDGETS_RUN=$((BUDGETS_RUN + 1))
    budget_check "roles/$ROLE.md" "$(role_budget "$ROLE")" "$(wc -w < "$RF" | tr -d ' ')"
  fi
done


# `orchestrator.md` is always-on too — Thomas reads it at session start — and until now
# nothing measured it, so it was the one billed surface that could grow without a verdict.
# It also cannot be repaired by a release: it is SCAFFOLD, written once and never
# overwritten, so a project that lets it accrete keeps that weight through every upgrade.
# THIS SCRIPT is payload, which is the whole reason the guard belongs here — an upgrade
# carries the check into a project even though it may not touch the file the check reads.
# Measured 2026-08-13: package 653 words, one project 941, another 1,477 — the last with 505
# words arguing which model a row should carry, including a decision, its reversal the same
# day, and an instruction not to undo the reversal. The table is the file's job; the argument
# for a row belongs in that project's decision record, which loads when someone re-opens the
# decision instead of on every session.
#
# 800 was calibrated to leave real room over that 653 — headroom the shipped file itself has
# since spent. An adapted project's own Thomas measured the package copy across releases:
# 653 words at 1.6.2, 684 at 2.0.1, 800 at 2.2.4 and every release since (the Workspace
# identity section added in the 2.2.x line consumed the entire margin). A budget equal to the
# file it bounds passes zero projects, including one that only fills in the required
# workspace-label blank — a compliant adaptation cannot pass a gate calibrated to a version of
# itself that no longer ships. Re-measured 2026-08-18 and raised to 950, restoring
# approximately the same ~150-word margin the original calibration intended, over the current
# 800-word baseline rather than the retired 653-word one. The adapted project that measured
# this had already raised its own local copy to the same 950 as a stopgap, independently,
# before this fix landed — the package number and the field number agree.
ORCH_F="$PAYLOAD/.agents/orchestrator.md"
if [[ -f "$ORCH_F" ]]; then
  budget_check ".agents/orchestrator.md" 950 "$(wc -w < "$ORCH_F" | tr -d ' ')"
fi
# Zero roles measured is the vacuous pass this axis shipped with. Say so rather than
# printing nothing and letting the run read as a success.
if [[ $BUDGETS_RUN -eq 0 ]]; then
  echo "  NO ROLE CONTRACTS FOUND under $PAYLOAD/.agents/roles — this axis measured nothing"
  FOUND=1
else
  echo "  ($BUDGETS_RUN contracts measured)"
fi

echo
echo "=== 2. self-reported counts vs the thing counted ==="
# A document that states a number states a fact nothing re-derives. README claimed "35
# measured failure modes" through sixteen releases while the ledger grew to 51, and named
# the ledger under .codex/profiles/ after it moved. Neither drifted loudly; both read fine.
# Each axis reports ITS OWN result. Reading the shared FOUND here made this axis silent
# whenever an earlier one had fired. A check whose verdict cannot be read is AST-052 again, and this one
# reproduced it inside the release that fixed it.
A5=0
RM="$ROOT/README.md"
VF="$ROOT/VERSION"
LEDGER="$ROOT/harness/.agents/memory/recurring-failure-modes.md"
[[ -f "$LEDGER" ]] || LEDGER="$ROOT/.agents/memory/recurring-failure-modes.md"

if [[ -f "$RM" && -f "$VF" ]]; then
  WANT="$(tr -d ' \n' < "$VF")"
  GOT="$( { grep -m1 -oE '^# (Astragentic|Astraler Harness) [0-9.]+' "$RM" || true; } | awk '{print $NF}' )"
  if [[ -n "$GOT" && "$GOT" != "$WANT" ]]; then
    echo "  README heading says $GOT, VERSION says $WANT"
    A5=1; FOUND=1
  fi
fi

if [[ -f "$RM" && -f "$LEDGER" ]]; then
  REAL="$( { grep -c '^### AST-' "$LEDGER" || true; } | tr -d ' ' )"
  CLAIM="$( { grep -m1 -o '[0-9]\{1,\} measured failure modes' "$RM" || true; } | awk '{print $1}' )"
  if [[ -n "$CLAIM" && "$CLAIM" != "$REAL" ]]; then
    echo "  README claims $CLAIM failure modes, the ledger holds $REAL"
    A5=1; FOUND=1
  fi
fi

# The ledger's claim ABOUT ITSELF went unread until 2026-08-13: this axis compared README to
# the ledger and stopped there, so the header sat at "50 entries (AST-001 … AST-050)" while
# the file held 66 — sixteen entries of drift, in the one file every rule here cites as
# evidence. Read the header the same way README's line is read, and read the RANGE too: a
# count can match while the highest id has moved past it.
# No ledger at either supported path is itself the finding. The header repair sat inside this
# guard, so an incomplete install — or someone deleting the evidence base — got the same green
# line as a valid one. Three depths of one vacuous pass in a single check: the comparison, the
# parse, and the file existing at all. Each was found by the pass after the one that fixed it.
if [[ ! -f "$LEDGER" ]]; then
  echo "  no failure-mode ledger under .agents/memory/ in either layout —"
  echo "  every rule in this package cites it as evidence, so its absence is a finding"
  A5=1; FOUND=1
else
  REAL="$( { grep -c '^### AST-' "$LEDGER" || true; } | tr -d ' ' )"
  # Read the Status LINE first, then parse inside it. Scanning the whole file for the range
  # matched the first `(AST-0NN)` citation in some entry's prose instead — a check reading
  # the wrong line reports a number it never meant to compare, which is this axis's own
  # failure class landing on the axis itself, an hour after it was written.
  HEAD_LINE="$( { grep -m1 '^Status:' "$LEDGER" || true; } )"
  HEAD_CLAIM="$( echo "$HEAD_LINE" | grep -oE '[0-9]+ entries' | awk '{print $1}' )"
  # The range is the parenthesised group, and only that: the Status line also carries a
  # "AST-001…034 carried into 1.0.0" note, so reading the last id ON THE LINE picked that up
  # instead. Second wrong-substring bug in this one check — the lesson is that a check parsing
  # prose needs its boundary stated, not narrowed until the current file happens to pass.
  HEAD_LAST="$( echo "$HEAD_LINE" | sed -n 's/.*(\([^)]*\)).*/\1/p' \
                | grep -oE 'AST-[0-9]+' | tail -1 | grep -oE '[0-9]+' )"
  REAL_LAST="$( { grep -oE '^### AST-[0-9]+' "$LEDGER" || true; } | grep -oE '[0-9]+' \
                | sort -n | tail -1 )"
  # ABSENCE IS A FINDING, not a pass. Both comparisons were guarded on the parsed values
  # being non-empty, so deleting the Status line — or rewording it past the parser — made
  # this axis print clean having read no claim at all. That is the vacuous pass this axis
  # exists to catch, rebuilt inside the check written to catch it, within the hour.
  if [[ -z "$HEAD_CLAIM" || -z "$HEAD_LAST" ]]; then
    echo "  the ledger has no parsable 'Status: … N entries (AST-001 … AST-NNN)' header —"
    echo "  this axis cannot verify what it cannot read, so it fails rather than passing"
    A5=1; FOUND=1
  else
    if [[ "$HEAD_CLAIM" != "$REAL" ]]; then
      echo "  the ledger's own header claims $HEAD_CLAIM entries, the file holds $REAL"
      A5=1; FOUND=1
    fi
    if [[ -z "$REAL_LAST" ]]; then
      echo "  the ledger holds no '### AST-NNN' entry to compare its header range against"
      A5=1; FOUND=1
    elif [[ "$HEAD_LAST" != "$REAL_LAST" ]]; then
      echo "  the ledger's header range ends at AST-$HEAD_LAST, the last entry is AST-$REAL_LAST"
      A5=1; FOUND=1
    fi
  fi
fi
[[ $A5 -eq 1 ]] || echo "(clean)"

echo
echo "=== 3. documented signal strings vs what the emitter actually prints ==="
# Documents compared to documents can agree and both be wrong. This axis compares the
# branch tables to the EMITTER: it reads every literal the watcher script echoes and
# requires each documented row to quote the real shape, suffix included.
#
# It exists because a partial edit passed every other check. 2.3.4 added a `pane=<id>`
# suffix to the watcher's output; 2.3.6 propagated it to the three TERMINAL: rows of each
# branch table and silently skipped the TIMEOUT and NO_START rows beside them, because the
# author was pattern-matching on `TERMINAL:`. Three rows updated reads as a finished table
# to anyone diffing it.
#
# The first sweep written for this asked whether the word "pane" appeared on the row. Both
# broken rows passed — their prose ends "inspect pane" and "re-read pane". A check whose
# green means A WORD OCCURRED rather than THE DOCUMENTED STRING MATCHES THE EMITTED ONE is
# AST-032 in a sweep's costume. Match the token AND its required suffix, or match nothing.
A6=0
WATCHER="$PAYLOAD/scripts/herdr-watch-terminal.sh"
if [[ -f "$WATCHER" ]]; then
  # THE REACHABLE SET, derived from the script and never from a doc. Terminal states are the
  # case arms; TIMEOUT and NO_START are the two the loop prints on its own.
  CASE_STATES="$( { grep -oE '^ *(done\|blocked\|idle|[a-z|]+)\)$' "$WATCHER" || true; } \
                  | tr -d ' )' | tr '|' '\n' | grep -E '^[a-z]+$' | sort -u )"
  REACHABLE="$( { for st in $CASE_STATES; do echo "TERMINAL:$st"; done; echo TIMEOUT; echo NO_START; } | sort -u )"
  EMITS_PANE=0
  grep -q 'pane=\$PANE' "$WATCHER" && EMITS_PANE=1

  # Docs that carry a branch table: any file with at least one `- \`TOKEN…\` → ` row naming a
  # state. Scope is every skill AND every role contract — the fifth stale site survived because
  # a sweep looked only where the author expected the defect, not everywhere it can live.
  # SCOPE. Widening this in 2.3.8 was right for role contracts and wrong for everything else
  # it swept up: run downstream, it walked other agents' worktrees and archived releases and
  # produced 100+ findings, every one of them a frozen historical copy or another agent's
  # break-test prose in the same `- \`TOKEN\` → text` shape. An audit that always screams is an
  # audit nobody reads — the same defect class as one that can never fail, from the other end.
  # Archived releases are history by design and must NOT be corrected; worktrees are other
  # agents' checkouts and not this payload.
  DOCS="$(find "$PAYLOAD/.agents" "$PAYLOAD/.claude" \
            -path '*/worktrees/*' -prune -o \
            -path '*/.astraler/*' -prune -o \
            -name '*.md' -print 2>/dev/null)"

  if [[ -z "$CASE_STATES" || -z "$REACHABLE" ]]; then
    echo "  the watcher script exposes no parsable terminal states — this axis read nothing"
    A6=1; FOUND=1
  elif [[ $EMITS_PANE -eq 0 ]]; then
    echo "  the watcher script no longer prints pane=\$PANE — the suffix rule below is unverifiable"
    A6=1; FOUND=1
  else
    while IFS= read -r doc; do
      [[ -f "$doc" ]] || continue
      ROWS="$( { grep -nE '^- .*`(TERMINAL:[a-z]+|TIMEOUT|NO_START)[^`]*`.*→' "$doc" || true; } )"
      [[ -n "$ROWS" ]] || continue        # no branch table here, nothing to check

      # (1) FORM — every row quotes the suffix the script actually emits.
      while IFS= read -r row; do
        [[ -n "$row" ]] || continue
        if [[ "$row" != *"pane="* ]]; then
          echo "  ${doc#$ROOT/}: branch row omits the pane= suffix the script emits"
          echo "    $(echo "$row" | sed 's/^[0-9]*://' | cut -c1-90)"
          A6=1; FOUND=1
        fi
      done <<< "$ROWS"

      # (2) MEMBERSHIP, both directions. Form-only was one-directional: it validated the rows
      # that existed and never compared the documented SET against the reachable one. Measured:
      # a phantom `TERMINAL:crashed` row (a state the case arms cannot produce) passed clean,
      # and DELETING the `TERMINAL:blocked` row — the one state that means a builder is waiting
      # for an answer — also passed clean. A green meaning "the rows I found look right" rather
      # than "the documented set matches the emitted set" is AST-032 one level up, inside the
      # check written to end that class (AST-110).
      DOC_TOKENS="$(echo "$ROWS" | grep -oE '`(TERMINAL:[a-z]+|TIMEOUT|NO_START)' | tr -d '`' | sort -u)"
      while IFS= read -r tok; do
        [[ -n "$tok" ]] || continue
        if ! echo "$REACHABLE" | grep -qx "$tok"; then
          echo "  ${doc#$ROOT/}: branch row documents \`$tok\`, which the script can never print"
          A6=1; FOUND=1
        fi
      done <<< "$DOC_TOKENS"
      while IFS= read -r tok; do
        [[ -n "$tok" ]] || continue
        if ! echo "$DOC_TOKENS" | grep -qx "$tok"; then
          echo "  ${doc#$ROOT/}: branch table has no row for \`$tok\`, which the script can print"
          A6=1; FOUND=1
        fi
      done <<< "$REACHABLE"
    done <<< "$DOCS"
  fi
else
  echo "  no watcher script at $WATCHER — this axis measured nothing"
  A6=1; FOUND=1
fi
[[ $A6 -eq 1 ]] || echo "(clean)"

echo
echo "=== 4. payload names no real project, ticket or host ==="
# This is a SCAFFOLD. Every project that installs it reads this payload, so a real ticket id,
# project name or container name from whoever happened to measure a lesson is noise to every
# other reader — and worse, it invites a downstream local edit (AST-116) to silence a checker
# that trips on it.
#
# The measurement is the evidence; the identity adds nothing a stranger can use. Keep the
# numbers, drop the name: "measured in the field: 5 instances, 3 sessions" carries everything
# "measured by <project> Thomas on <TICKET>" carried.
#
# Ticket ids are the mechanically checkable half, and the half that actually leaked — five in
# one day. Only the generic example series is allowed. Project and host names cannot be
# enumerated from up here, so those stay a human rule stated in the entry (AST-123).
A7=0
# PACKAGE LAYOUT ONLY. This axis asks whether the SCAFFOLD has absorbed one project's
# identity — a maintainer question. An adapted project names its own tickets legitimately and
# everywhere, including inside the payload directories: `.agents/memory/project-lessons.md`
# exists precisely to cite them permanently, and `.agents/orchestrator.md` is owner-tuned.
#
# Shipped without this guard, the axis scoped on the bare $PAYLOAD, which is `harness` here and
# `.` in an adapted project — so downstream it walked the entire repository: 4,443 findings,
# and exit 1 forever (AST-126). Narrowing to $PAYLOAD/{.agents,.claude,scripts} was the obvious
# repair and was still wrong, because the legitimate ticket ids live inside those directories.
# The axis does not belong downstream at all.
#
# Skipped is not clean: say which, so a reader knows this run made no claim.
#
# 2.7.15: compare against the RESOLVED package path. $PAYLOAD is absolute (line 44), so the
# bare `!= "harness"` it shipped with could never be false — this axis printed "(skipped)" on
# every run in every layout since it was written, and the only guard on the SPEC invariant
# "no project noun in the payload" measured nothing. Found by a full-payload scan, verified by
# running it. A check that always reports the reassuring branch is AST-051 wearing a comment.
# "Package layout" is a fact about the PACKAGE, not about which directory the caller named:
# invoked bare from the repo root, self-location resolves ROOT to `harness/` itself (it is the
# first ancestor carrying `.agents/roles`), so a `$ROOT/harness` compare skips there too. The
# package is the tree whose payload dir is literally `harness` with `install.sh` beside it.
if [[ "$(basename "$PAYLOAD")" != "harness" || ! -f "$PAYLOAD/../install.sh" ]]; then
  echo "(skipped — this axis is about the scaffold, and an adapted project names its own tickets)"
else
# SHAPE, not "any uppercase token with a dash". The first draft matched SHA-1, BSD-3, AFL-2 and
# UTF-8, walked node_modules, and matched its own pattern string — 19 findings, every one noise,
# which is AST-113 reproduced inside the release that cites it. Three letters and two digits is
# the ticket shape; ledger ids and the generic example series `ABC-nnn` are allowed by name.
# No downstream prefix is: 2.7.15 retired a `TRA-1[23][0-9]` allowance that had let one
# project's ids serve as the payload's examples for four releases.
ALLOW='AST-[0-9]+|ABC-[0-9]+'
while IFS= read -r hit; do
  [[ -n "$hit" ]] || continue
  echo "  ${hit#$ROOT/} — payload must not name a real ticket (AST-123)"
  A7=1; FOUND=1
# `.agents/memory/` is excluded: the ledger is the RECORD, and it cites downstream measurements
# by ticket id on purpose. The scaffold — roles, skills, scripts, hooks — is what must not.
# SCOPE BY SUBDIRECTORY, never by $PAYLOAD alone. In package layout $PAYLOAD is `harness`;
# in an ADAPTED PROJECT it is `.` — the repo root — so a bare $PAYLOAD grep walks the whole
# project. Measured downstream: 4,443 findings, including the project's own lessons file whose
# documented purpose is to cite real tickets permanently, its AGENTS.md, its design docs and
# its JSON test fixtures. The axis would have exited 1 forever on every adapted project
# (AST-126). Axis 3 already scoped this way; axis 4 shipped without it.
done < <( { grep -rnoE '\b[A-Z]{3,5}-[0-9]{2,}\b' \
              "$PAYLOAD/.agents" "$PAYLOAD/.claude" "$PAYLOAD/scripts" \
              --include='*.md' --include='*.sh' --include='*.json' --include='*.py' \
              --exclude-dir=node_modules --exclude-dir=memory \
              --exclude='docs-staleness-audit.sh' 2>/dev/null || true; } \
          | grep -vE "$ALLOW" )
[[ $A7 -eq 1 ]] || echo "(clean)"
fi

echo
echo "=== 5. ledger index vs the ledger ==="
# The index is what makes the ledger browsable without reading it (~57k tokens). A stale index
# sends a reader to an id that moved, or hides one that was added — and the failure is silent,
# because a stale index is indistinguishable from a current one by reading it.
IDX_GEN="$ROOT/harness/scripts/ledger-index.sh"
[[ -x "$IDX_GEN" ]] || IDX_GEN="$ROOT/scripts/ledger-index.sh"
if [[ -x "$IDX_GEN" ]]; then
  if OUT="$("$IDX_GEN" --check 2>&1)"; then
    echo "  $OUT"
  else
    echo "  $OUT"; FOUND=1
  fi
else
  echo "(skipped — no ledger-index.sh on this layout)"
fi

echo
[[ $FOUND -eq 1 ]] && echo "RESULT: findings above — verify each against code/truth-model before editing." || echo "RESULT: all clean."
exit $FOUND
