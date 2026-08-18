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

ROOT="."
PAYLOAD="harness"
[[ -d "$PAYLOAD/.agents/roles" ]] || PAYLOAD="."
FOUND=0

echo "=== 1. always-on word budgets (these surfaces bill every session) ==="
# Budgets guard the always-on surfaces against regrowth — the accretion that took the
# prior package past 100k words. Raise one only with an owner decision in the same commit.
budget_check() { # <label> <limit> <count>
  if [[ "$3" -gt "$2" ]]; then echo "OVER: $1 = $3 words (budget $2)"; FOUND=1; else echo "ok: $1 = $3/$2 words"; fi
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
    thomas)  echo 1970 ;;  # widest remit: claim protocol + three dispatch points + the arm
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
    builder) echo 1400 ;;  # widest DOING surface: build, increment review, simplify,
                           # visual verification, the two correctness rules, handback.
                           # Ships at 1040; the 360-word margin already clears the floor
                           # above, so this pass leaves it unchanged.
    rin)     echo 1350 ;;  # ships at 1177 (23-word margin before this pass) — second
                           # opinion, artifact verification, the arm's standard. Raised
                           # under the same margin-calibration pass as thomas and qa.
    qa)      echo 1300 ;;  # ships at 1149 (51-word margin before this pass) — the running-
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
  GOT="$( { grep -m1 -o '^# Astraler Harness [0-9.]*' "$RM" || true; } | awk '{print $4}' )"
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
[[ $FOUND -eq 1 ]] && echo "RESULT: findings above — verify each against code/truth-model before editing." || echo "RESULT: all clean."
exit $FOUND
