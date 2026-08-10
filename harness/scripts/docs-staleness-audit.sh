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
# Scope = ONLY the surfaces that run the harness (owner 2026-07-17): the root entry docs,
# docs/, .claude/, and shared .agents roles/skills. Product code folders
# (apps/, packages/), prototypes, .scratch are
# out of scope. Within scope, history classes are excluded.
scoped_md() {
  git ls-files 'CLAUDE.md' 'AGENTS.md' 'CONTEXT.md' 'docs/**/*.md' 'docs/*.md' \
               '.claude/**/*.md' '.claude/*.md' '.agents/roles/*.md' \
               '.agents/skills/*/SKILL.md' \
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
if [[ -n "$AGE_HITS" ]]; then echo "$AGE_HITS"; FOUND=1; fi

echo
echo "=== AXIS 2: fossils of retired names in LIVE docs ==="
# Marker list — APPEND the old name whenever something is retired/renamed:
FOSSILS='worker\.md|subagent_type:? ?"worker"|Worker Herdr|THOMAS\.md|evolution-loop|governance-maturity|4-lens|/agent-skills:|both PR lenses|implementer\.md|agents/dan\.md|agents/rin\.md|--agent dan[^-]|docs/superpowers|memory/README|herdr agent send|codex-dispatch-dan|\.codex/agents/dan-implementor\.toml|dan-implementor|dispatch-dan|rin-pr-reviewer|subagent_type:? ?"rin-reviewer"|live slice tab|plan-challenger'
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
for ROLE in thomas shaper builder rin; do
  [[ -f ".agents/roles/$ROLE.md" ]] && \
    budget_check "roles/$ROLE.md" 1200 "$(wc -w < ".agents/roles/$ROLE.md" | tr -d ' ')"
done

echo
[[ $FOUND -eq 1 ]] && echo "RESULT: findings above — verify each against code/truth-model before editing." || echo "RESULT: all clean."
exit $FOUND
