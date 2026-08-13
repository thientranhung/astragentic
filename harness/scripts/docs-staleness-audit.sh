#!/usr/bin/env bash
# docs-staleness-audit.sh — one-command staleness sweep of every tracked markdown.
# The reading layer's measure step: it says which docs are old enough to distrust, which
# still name something retired, and which links have died. Run from the repo root.
#
#   scripts/docs-staleness-audit.sh [age_days]   # default 21
#
# Three axes:
#   1. AGE       — harness-surface *.md not committed in >age_days (old = suspect).
#                  Scope = root entry docs + docs/ + .claude/ + shared .agents role/skill
#                  surfaces (owner 2026-07-17);
#                  history classes excluded (archive, *.vi.md, references, stakeholder,
#                  distilled).
#   2. FOSSILS   — live docs mentioning RETIRED names. Maintain the marker list below:
#                  every time something is retired/renamed, ADD its old name here in
#                  the same commit (that is what makes this audit total).
#   3. DEAD LINKS— md links in the routers (INDEX/AGENTS/SYSTEM) pointing at missing files.
#
# Output is a report; exit code 1 if any axis found something. Judgment stays human:
# an old file is a candidate, not a verdict — verify before editing (truth-model §5).
set -uo pipefail

AGE_DAYS="${1:-21}"
# The payload sits under harness/ in this package and at the repo root once adapted. Detect
# it. Until 1.5.0 this script assumed the root, so in package layout AXIS 4 tested five
# paths that did not exist, ran its loop zero times and printed "all clean" — a budget check
# that could not fail, reporting success for sixteen releases (AST-051's class).
ROOT="."
PAYLOAD="harness"
[[ -d "$PAYLOAD/.agents/roles" ]] || PAYLOAD="."
# Scope = ONLY the surfaces that run the harness (owner 2026-07-17): the root entry docs,
# docs/, .claude/, and shared .agents roles/skills. Product code folders
# (apps/, packages/), prototypes, .scratch are
# out of scope. Within scope, history classes are excluded.
# AXES 1-3 carried the blindness AXIS 4 was fixed for in 1.5.0: these globs are relative to
# the repo root, so in package layout — payload under harness/ — they matched ONE file, and
# three axes reported clean over docs they never opened. The payload surfaces now carry
# $PAYLOAD.
# `SPEC-<version>.md` stays OUT of scope, and that is a decision rather than an oversight: a
# shipped version's build spec names files in the repo it copied FROM, so its retired names
# are accurate history. Rewriting them would falsify the record.
scoped_md() {
  local P="$PAYLOAD"
  [[ "$P" == "." ]] && P="" || P="$P/"
  git ls-files 'CLAUDE.md' 'AGENTS.md' 'CONTEXT.md' 'README.md' \
               'docs/**/*.md' 'docs/*.md' \
               "${P}.claude/**/*.md" "${P}.claude/*.md" "${P}.agents/roles/*.md" \
               "${P}.agents/skills/*/SKILL.md" \
  | grep -v -e 'archive' -e '\.vi\.md$' -e '^docs/references/' -e '^docs/stakeholder/' \
            -e '^docs/governance/distilled/' -e 'worktrees'
}
FOUND=0

echo "=== AXIS 1: tracked *.md older than ${AGE_DAYS} days (candidates, not verdicts) ==="
CUTOFF=$(date -v-"${AGE_DAYS}"d +%Y-%m-%d 2>/dev/null || date -d "-${AGE_DAYS} days" +%Y-%m-%d)
# Collect-then-test: piping the while-loop into sort ran it in a subshell, so FOUND=1
# died there and stale files printed WITHOUT failing the exit code (bug found by the
# inception port's end gate, 2026-07-17).
AGE_HITS=$(while read -r f; do
  d=$(git log -1 --format=%as -- "$f")
  [[ "$d" < "$CUTOFF" ]] && echo "$d  $f"
done < <(scoped_md) | sort)
if [[ -n "$AGE_HITS" ]]; then echo "$AGE_HITS"; FOUND=1; else echo "(clean)"; fi

echo
echo "=== AXIS 2: fossils of retired names in LIVE docs ==="
# Marker list — APPEND the old name whenever something is retired/renamed, and append only a
# name this repo's history can be shown to have carried. `agents/dan\.md|agents/rin\.md` rode
# this list from v0.1.0 of the prior package: `agents/dan.md` has no referent in either
# repo's history, and the ONLY match `agents/rin.md` has ever had is the live
# `.claude/agents/rin.md` adapter. The real old names — dan-senior, rin-reviewer,
# dan-implementor, rin-pr-reviewer — are already here on their own. While the scope bug
# above hid every payload file, a pattern that fires on a live file cost nothing; the moment
# the audit could see, it was the first thing it reported.
FOSSILS='worker\.md|subagent_type:? ?"worker"|Worker Herdr|THOMAS\.md|evolution-loop|governance-maturity|4-lens|/agent-skills:|both PR lenses|implementer\.md|--agent dan[^-]|docs/superpowers|memory/README|herdr agent send|codex-dispatch-dan|\.codex/agents/dan-implementor\.toml|dan-implementor|dispatch-dan|rin-pr-reviewer|subagent_type:? ?"rin-reviewer"|live slice tab|plan-challenger'
# Retired by 1.0.0 (ADR 0001) — the roles Dan and James left the build loop, the review
# loop became one bounded round, and the method moved to the mattpocock-skills plugin:
FOSSILS="$FOSSILS"'|dan-senior|james-dev|rin-reviewer|thomas-leader|dispatch-slice|codex-plan-gate|codex-review-with-rin|codex-gate|slice:<|slice tab|simplify\(slice\)|working-method|gate loop|re-gate|findings exhausted'
# Lines that legitimately mention a retired name (tombstones) are filtered:
TOMBSTONES='retired|Retire|folded|superseded|relic|history|archive|migration|demolished|Replaces the'
# Same scope as axis 1 (harness surfaces only), minus the ledger (history may name names).
if scoped_md | grep -v 'recurring-failure-modes' \
   | xargs grep -n -E "$FOSSILS" 2>/dev/null \
   | grep -v -E "$TOMBSTONES"; then FOUND=1; else echo "(clean)"; fi

echo
echo "=== AXIS 3: dead md links in the routers ==="
DEAD=0
for router in docs/INDEX.md docs/SYSTEM.md AGENTS.md; do
  # A router a project has not created yet is absent, not dead — say so and move on.
  [[ -f "$router" ]] || { echo "(skip: $router not present)"; continue; }
  while read -r target; do
    base_dir=$(dirname "$router")
    [[ -f "$base_dir/$target" || -f "$target" ]] || { echo "DEAD: $router -> $target"; DEAD=1; }
  done < <(grep -oE '\]\((\./)?[A-Za-z0-9_./-]+\.md' "$router" | sed 's/](//;s/^\.\///')
done
[[ $DEAD -eq 0 ]] && echo "(clean)" || FOUND=1

echo
echo "=== AXIS 4: always-on word budgets (these surfaces bill every session) ==="
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
  case "$1" in
    thomas)  echo 1700 ;;  # widest remit: claim protocol + three dispatch points + the arm
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
    builder) echo 1400 ;;  # widest DOING surface: build, increment review, simplify,
                           # visual verification, the two correctness rules, handback
    *)       echo 1200 ;;
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
# decision instead of on every session. 800 leaves real room over the shipped 653.
ORCH_F="$PAYLOAD/.agents/orchestrator.md"
if [[ -f "$ORCH_F" ]]; then
  budget_check ".agents/orchestrator.md" 800 "$(wc -w < "$ORCH_F" | tr -d ' ')"
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
echo "=== AXIS 5: self-reported counts vs the thing counted ==="
# A document that states a number states a fact nothing re-derives. README claimed "35
# measured failure modes" through sixteen releases while the ledger grew to 51, and named
# the ledger under .codex/profiles/ after it moved. Neither drifted loudly; both read fine.
# Each axis reports ITS OWN result. Reading the shared FOUND here made this axis silent
# whenever an earlier one had fired — which in a real project is every run, since AXIS 1
# always has aged docs. A check whose verdict cannot be read is AST-052 again, and this one
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
if [[ -f "$LEDGER" ]]; then
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
