#!/usr/bin/env bash
# Doctor for the Astraler harness. Two axes, separately runnable, because they fail for
# different reasons and get fixed by different people:
#
#   MACHINE  what this machine needs before the harness can run anywhere.
#   TARGET   what one repo needs before the harness can be installed into it.
#
# Usage: ./check-requirements.sh [target-repo-path] [--optional-too]
# Exit:  0 = all REQUIRED checks pass · 1 = at least one REQUIRED check failed · 2 = usage
set -uo pipefail

TARGET=""
CHECK_OPTIONAL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --optional-too) CHECK_OPTIONAL=1; shift ;;
    -h|--help)
      echo "Usage: $0 [target-repo-path] [--optional-too]"
      exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *)
      [ -z "$TARGET" ] || { echo "Unexpected argument: $1" >&2; exit 2; }
      TARGET="$1"; shift ;;
  esac
done

if [ -n "$TARGET" ]; then
  [ -d "$TARGET" ] || { echo "Target does not exist: $TARGET" >&2; exit 2; }
  TARGET="$(cd "$TARGET" && pwd)"
fi

fail=0
ok()   { printf '  [OK]   %s\n' "$1"; }
miss() { printf '  [MISS] %s\n         → %s\n' "$1" "$2"; fail=1; }
warn() { printf '  [WARN] %s\n         → %s\n' "$1" "$2"; }

# Compare two dotted versions; succeeds when $1 >= $2.
version_ge() {
  [ -n "$1" ] && [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_VERSION="$(cat "$PKG_DIR/VERSION" 2>/dev/null || echo "?")"
echo "Astraler harness $PKG_VERSION — requirements check"
echo
echo "MACHINE (required):"

HAVE_CLAUDE=0; command -v claude >/dev/null 2>&1 && HAVE_CLAUDE=1
HAVE_CODEX=0;  command -v codex  >/dev/null 2>&1 && HAVE_CODEX=1

# 1. Claude Code CLI. Rin's milestone gate runs as a Herdr pane on the root provider's
# runtime, and no Codex or opencode adapter can host it, so a missing Claude means the
# machine cannot gate at all — a MISS rather than a warning. Codex remains the
# cross-vendor arm, which Thomas fires at phase end.
if [ "$HAVE_CLAUDE" -eq 1 ]; then
  ok "claude CLI ($(command -v claude))"
elif [ "$HAVE_CODEX" -eq 1 ]; then
  miss "claude CLI not on PATH — the milestone gate cannot run" \
    "install Claude Code: https://claude.com/claude-code. Rin has no fallback row by design (AST-030): with no Claude the answer is STOP and ask the owner, and Codex stays the cross-vendor arm"
else
  miss "no runtime CLI on PATH (need claude or codex)" \
    "install Claude Code (https://claude.com/claude-code) and/or the OpenAI Codex CLI"
fi

# 2. The mattpocock-skills plugin — the method itself. Every spine step this package routes
# to lives in the plugin, so an absent plugin leaves the whole chain pointing at nothing.
PLUGINS_JSON="$HOME/.claude/plugins/installed_plugins.json"
PLUGIN_FLOOR="1.2.3"
plugin_version() {
  [ -f "$PLUGINS_JSON" ] || return 1
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$PLUGINS_JSON" <<'PY' 2>/dev/null
import json,sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
for name, installs in (d.get("plugins") or {}).items():
    if name.split("@")[0] == "mattpocock-skills":
        for i in installs or []:
            v = i.get("version")
            if v and v != "unknown":
                print(v); sys.exit(0)
        print("unknown"); sys.exit(0)
sys.exit(1)
PY
  else
    grep -q '"mattpocock-skills@' "$PLUGINS_JSON" && echo unknown
  fi
}
MP_VERSION="$(plugin_version)"
if [ -z "$MP_VERSION" ]; then
  miss "mattpocock-skills plugin not installed" \
    "in an interactive claude session: /plugin → install 'mattpocock-skills' (marketplace: claude-plugins-official). This package routes every spine step into it"
elif [ "$MP_VERSION" = "unknown" ]; then
  warn "mattpocock-skills plugin present, version unreadable" \
    "the install record carries no version; confirm it is >= $PLUGIN_FLOOR with /plugin"
elif version_ge "$MP_VERSION" "$PLUGIN_FLOOR"; then
  ok "mattpocock-skills plugin $MP_VERSION (>= $PLUGIN_FLOOR)"
else
  miss "mattpocock-skills plugin $MP_VERSION is below the $PLUGIN_FLOOR floor" \
    "update it: /plugin → update 'mattpocock-skills'"
fi

# 3. git with worktree support (>= 2.5) — the isolation boundary for concurrent Builders.
if command -v git >/dev/null 2>&1 && git worktree --help >/dev/null 2>&1; then
  ok "git with worktree support ($(git --version))"
else
  miss "git with worktree support" "install or upgrade git >= 2.5"
fi

# 4. herdr floor 0.8.0. VERSION and command surface are separate checks on purpose: the
# capability probe alone cannot establish the floor, because prompt/wait/read/start all
# exist in 0.7.5 too, so a probe-only check silently passed an under-floor herdr (AST-032 —
# a check that cannot fail is not a check). The floor exists for the 0.8.0
# prompt-submission fix, a BEHAVIOUR change no --help probe can observe.
HERDR_FLOOR="0.8.0"
if command -v herdr >/dev/null 2>&1; then
  HERDR_VERSION="$(herdr --version 2>/dev/null | awk '{print $NF}')"
  HERDR_VERSION_OK=0
  version_ge "$HERDR_VERSION" "$HERDR_FLOOR" && HERDR_VERSION_OK=1
  if herdr agent prompt --help >/dev/null 2>&1 &&
     herdr agent wait   --help >/dev/null 2>&1 &&
     herdr agent read   --help >/dev/null 2>&1 &&
     herdr agent start  --help >/dev/null 2>&1; then
    HERDR_API_OK=1
  else
    HERDR_API_OK=0
  fi
  if [ "$HERDR_VERSION_OK" = "1" ] && [ "$HERDR_API_OK" = "1" ]; then
    ok "herdr $HERDR_VERSION >= $HERDR_FLOOR (agent prompt/wait/read/start present)"
  elif [ "$HERDR_VERSION_OK" = "0" ]; then
    miss "herdr ${HERDR_VERSION:-unknown} is below the required $HERDR_FLOOR floor" \
      "upgrade herdr (>= $HERDR_FLOOR) — the floor is the prompt-submission fix, which no capability probe can detect"
  else
    miss "herdr lacks the required agent API" \
      "upgrade herdr; dispatch requires agent prompt, wait, read, and start"
  fi
else
  miss "herdr not on PATH" \
    "install herdr (terminal multiplexer for coding agents), e.g. brew install herdr"
fi

# 5. herdr skill — agents drive herdr through this skill.
if [ -d "$HOME/.agents/skills/herdr" ]; then
  ok "herdr skill (~/.agents/skills/herdr)"
else
  miss "herdr skill missing" "install the herdr skill into ~/.agents/skills/herdr"
fi

# 6–8. Codex surfaces — required for the cross-vendor arm, DEGRADABLE to single-provider
# mode: with claude present and codex absent these report WARN and the harness runs
# Claude-only. The milestone gate still runs (it is Claude-side); what is lost is the arm,
# recorded `NOT RUN` for the owner to accept. A same-vendor lens never completes it.
codex_gap() {
  if [ "$HAVE_CLAUDE" -eq 1 ] && [ "$HAVE_CODEX" -eq 0 ]; then
    warn "$1 — single-provider mode (Claude-only)" \
      "the milestone gate is unaffected; the cross-vendor arm cannot run and is recorded 'NOT RUN — <reason>' for the OWNER to accept. $2"
  else
    miss "$1" "$2"
  fi
}

if [ "$HAVE_CODEX" -eq 1 ]; then
  ok "codex CLI ($(command -v codex))"
else
  codex_gap "codex CLI not on PATH" \
    "install the OpenAI Codex CLI to restore the cross-vendor arm, e.g. brew install codex"
fi

# Codex plugin inside Claude Code (provides the companion runtime the arm invokes) — a
# Claude-side surface, so it is moot in Codex-only mode.
if [ "$HAVE_CLAUDE" -eq 0 ] && [ "$HAVE_CODEX" -eq 1 ]; then
  warn "Codex plugin check skipped — single-provider mode (Codex-only)" \
    "the plugin lives inside Claude Code; install Claude Code to restore the arm on a Claude root"
elif [ -f "$PLUGINS_JSON" ] && grep -q '"codex@' "$PLUGINS_JSON"; then
  ok "Codex plugin in Claude Code (codex@… in installed_plugins.json)"
else
  codex_gap "Codex plugin not installed in Claude Code" \
    "in an interactive claude session: /plugin → install 'codex' (marketplace: openai-codex)"
fi

# Codex role profiles — machine-local, provisioned only with explicit owner confirmation, so
# drift and absence are reported rather than repaired.
#
# The template is NOT the authority. `.agents/orchestrator.md` is the single owner of role →
# runtime/model/effort, and a template shipped with placeholder values agrees with a profile
# copied from it while BOTH disagree with the table — drift that is invisible to a
# template-vs-profile comparison, and that surfaces as "Codex is down" at the first
# cross-vendor call rather than as a config error. So compare against the table too.
# A named target owns the answer: its table is the one its dispatches read. Only with no
# target does the package's own copy stand in.
ORCH=""
for CAND in "${TARGET:+$TARGET/.agents/orchestrator.md}" \
            ".agents/orchestrator.md" "harness/.agents/orchestrator.md"; do
  [ -n "$CAND" ] && [ -f "$CAND" ] && { ORCH="$CAND"; break; }
done

# Read a role's codex row from either table; prints "<model>|<effort>".
orchestrator_codex_row() {
  [ -n "$ORCH" ] || return 1
  awk -F'|' -v role="$1" '
    $0 ~ /^\|/ {
      gsub(/^[ \t]+|[ \t]+$/, "", $2); gsub(/^[ \t]+|[ \t]+$/, "", $3)
      gsub(/^[ \t]+|[ \t]+$/, "", $4); gsub(/^[ \t]+|[ \t]+$/, "", $5)
      gsub(/`/, "", $4)
      if ($2 == role && $3 == "codex" && $4 != "") { print $4 "|" $5; exit }
    }' "$ORCH"
}

profile_field() { grep -E "^$2 *=" "$1" 2>/dev/null | head -1 | cut -d'"' -f2; }
for ROLE in thomas shaper builder rin qa; do
  # Three places the template can live: an adapted project (.codex/), this package
  # (harness/.codex/), or a target where the release is staged but not yet adapted.
  TEMPLATE=""
  for CAND in "${TARGET:+$TARGET/.codex/profiles/${ROLE}.config.toml}" \
              ".codex/profiles/${ROLE}.config.toml" \
              "harness/.codex/profiles/${ROLE}.config.toml" \
              $(ls -d .astraler/releases/*/harness/.codex/profiles/${ROLE}.config.toml 2>/dev/null | tail -1); do
    [ -n "$CAND" ] && [ -f "$CAND" ] && { TEMPLATE="$CAND"; break; }
  done
  DEST="${CODEX_HOME:-$HOME/.codex}/${ROLE}.config.toml"
  if [ -n "$TEMPLATE" ]; then
    # Authority check first: does the profile agree with the orchestrator row?
    ROW="$(orchestrator_codex_row "$ROLE")"
    ROW_MODEL="${ROW%%|*}"; ROW_EFFORT="${ROW##*|}"
    # `<set-me>` is the scaffold's way of saying "the owner has not chosen yet". It is not a
    # value to compare against — comparing it would report every real config as drift.
    if [ "$ROW_MODEL" = "<set-me>" ]; then
      [ -n "$TARGET" ] && warn "orchestrator.md ${ROLE} codex row still reads <set-me>" \
        "fill it with a model id for this account before dispatching ${ROLE} to codex; until then the fallback cannot run"
      ROW=""
    fi
    if [ -n "$ROW" ]; then
      PROF_SRC="$TEMPLATE"; [ -f "$DEST" ] && PROF_SRC="$DEST"
      PROF_MODEL="$(profile_field "$PROF_SRC" model)"
      PROF_EFFORT="$(profile_field "$PROF_SRC" model_reasoning_effort)"
      # A placeholder that LOOKS like a real id is the trap: it resolves nowhere and fails
      # at the moment the cross-vendor arm runs — end of phase, when the work looks done —
      # reading as "the provider is down" rather than as a config error. So the package
      # ships an EMPTY model and the doctor refuses it (AST-040).
      if [ -z "$PROF_MODEL" ]; then
        miss "Codex ${ROLE} profile has no model set" \
          "the package ships this empty on purpose. Copy the model from the ${ROLE} codex row in .agents/orchestrator.md into $PROF_SRC — a placeholder id would fail only at the first cross-vendor call"
      elif [ "$PROF_MODEL" != "$ROW_MODEL" ]; then
        miss "Codex ${ROLE} profile model '$PROF_MODEL' disagrees with its orchestrator.md row '$ROW_MODEL'" \
          "orchestrator.md owns role → model; a profile that disagrees fails at invoke time and looks like the provider being down. Fix $PROF_SRC"
      elif [ -n "$ROW_EFFORT" ] && [ "$PROF_EFFORT" != "$ROW_EFFORT" ]; then
        warn "Codex ${ROLE} profile effort '$PROF_EFFORT' disagrees with its row '$ROW_EFFORT'" \
          "align $PROF_SRC with .agents/orchestrator.md"
      fi
    fi
    if [ -f "$DEST" ] && cmp -s "$TEMPLATE" "$DEST"; then
      ok "Codex ${ROLE} profile installed and matches the tracked template"
    elif [ -f "$DEST" ]; then
      warn "Codex ${ROLE} profile drift detected" \
        "compare $TEMPLATE with $DEST; adaptation needs explicit confirmation before overwrite"
    else
      warn "Codex ${ROLE} profile not provisioned" \
        "adaptation needs explicit confirmation before copying $TEMPLATE to $DEST"
    fi
  else
    warn "Codex ${ROLE} profile template not found" \
      "run this check from the package root or an adapted project root"
  fi
done

# 9. Canonical watcher location used by the dispatch recipes.
if [ -f "$HOME/.claude/scripts/herdr-watch-terminal.sh" ]; then
  ok "~/.claude/scripts/herdr-watch-terminal.sh present"
else
  warn "~/.claude/scripts/herdr-watch-terminal.sh missing" \
    "the adaptation agent syncs harness/scripts/herdr-watch-terminal.sh after inspecting local drift"
fi

# opencode — optional third provider; it never gates the required flow.
if command -v opencode >/dev/null 2>&1; then
  ok "opencode CLI ($(command -v opencode)) — optional third provider"
fi

# ---------------------------------------------------------------------------
# TARGET axis
# ---------------------------------------------------------------------------
# These three files are what the spine reads to find the tracker, the triage vocabulary,
# and the domain language. `setup-matt-pocock-skills` produces them, which is why the
# remedy is always that skill rather than a hand-written file.

echo
if [ -z "$TARGET" ]; then
  echo "TARGET: not checked (no target path given)"
  echo "         → ./check-requirements.sh <target-repo-path> also checks"
  echo "           docs/agents/issue-tracker.md, triage-labels.md and domain.md there"
else
  # This axis describes a target that has finished adapting. Before adaptation these files
  # do not exist yet, and that is the normal starting state rather than something to fix
  # first — setup-matt-pocock-skills produces them DURING the adaptation run.
  echo "TARGET $TARGET (post-adaptation state):"
  TARGET_READY=1
  for DOC in issue-tracker triage-labels domain; do
    if [ -f "$TARGET/docs/agents/${DOC}.md" ]; then
      ok "docs/agents/${DOC}.md"
    else
      warn "docs/agents/${DOC}.md not present yet" \
        "the OWNER types /setup-matt-pocock-skills in that repo (no model can invoke it) during adaptation; expected to be absent before then"
      TARGET_READY=0
    fi
  done
  if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ok "target is a git work tree (worktree isolation available)"
    # AST-036: a worktree carries TRACKED content only, so an uncommitted payload is
    # invisible to every Builder. Ask git what it tracks rather than what exists on disk.
    if [ "$TARGET_READY" = "1" ]; then
      UNTRACKED_PAYLOAD=0
      for PATHNAME in .agents/roles/builder.md .claude/agents/builder.md \
                      .agents/orchestrator.md docs/agents/issue-tracker.md; do
        [ -e "$TARGET/$PATHNAME" ] || continue
        git -C "$TARGET" ls-files --error-unmatch "$PATHNAME" >/dev/null 2>&1 || {
          printf '         · untracked: %s\n' "$PATHNAME"; UNTRACKED_PAYLOAD=1; }
      done
      if [ "$UNTRACKED_PAYLOAD" -eq 0 ]; then
        ok "harness payload is committed (visible inside Builder worktrees)"
      else
        miss "harness payload is present but NOT tracked by git" \
          "a worktree contains tracked content only, so a Builder dispatched now reads no contract at all (AST-036). Check .gitignore for .agents/ or .claude/ rules, then commit the payload"
      fi
    fi
  else
    miss "target is not a git work tree" \
      "run 'git init' in the target; concurrent Builders are isolated by worktree and branch"
  fi
fi

if [ "$CHECK_OPTIONAL" -eq 1 ]; then
  echo
  echo "OPTIONAL (project-dependent):"
  if ! command -v opencode >/dev/null 2>&1; then
    warn "opencode CLI not on PATH" \
      "optional third provider; needed only when orchestrator.md assigns roles to opencode"
  fi
  if command -v agent-browser >/dev/null 2>&1; then
    ok "agent-browser CLI ($(command -v agent-browser))"
  else
    warn "agent-browser CLI not on PATH" \
      "needed only for projects that browser-test through a real logged-in Chrome session"
  fi
  if [ -d "$HOME/.agents/skills/agent-browser" ]; then
    ok "agent-browser skill (~/.agents/skills/agent-browser)"
  else
    warn "agent-browser skill missing" "needed only for browser-backed projects"
  fi
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "All required checks passed."
else
  echo "REQUIRED checks failed — fix the [MISS] items above before installing the harness."
fi
exit "$fail"
