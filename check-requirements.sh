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
# Two questions, two strictness levels. Before adaptation the three docs/agents files are
# EXPECTED to be absent, so their absence is a warning. After adaptation their absence is a
# broken install — and until this flag existed the run said "All required checks passed" on a
# repo containing no harness at all, because every TARGET finding was a warn.
ADAPTED=0

while [ $# -gt 0 ]; do
  case "$1" in
    --optional-too) CHECK_OPTIONAL=1; shift ;;
    --adapted) ADAPTED=1; shift ;;
    -h|--help)
      echo "Usage: $0 [target-repo-path] [--optional-too] [--adapted]"
      echo "  --adapted   the target has finished adapting: the docs/agents files are"
      echo "              REQUIRED, not expected-absent. ADAPT-HARNESS runs this form."
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
# Two homes, on purpose: this file sits at the package root next to VERSION, and is also
# vendored into an adapted project's scripts/, where the version to report is the one the
# project actually applied. Look for both rather than printing "?" in the vendored copy —
# a doctor that cannot name the version it is checking invites the wrong answer.
PKG_VERSION="$(cat "$PKG_DIR/VERSION" 2>/dev/null \
            || cat "$PKG_DIR/../.astraler/state/applied-version" 2>/dev/null \
            || echo "?")"
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

# 2b. Bundled skills reachable by the model. The Builder's simplify pass is a Claude Code
# built-in skill it invokes itself. Three switches take that reach away, and all three fail
# the same silent way: the Builder cannot invoke, so it rolls its own pass and reports a
# success that is real but weaker, leaving no marker (AST-051). Nothing errors, which is why
# this belongs in the doctor rather than being left to be discovered per project.
SETTINGS="$HOME/.claude/settings.json"
BUNDLED_OFF=""
[ -n "${CLAUDE_CODE_DISABLE_BUNDLED_SKILLS:-}" ] && BUNDLED_OFF="env CLAUDE_CODE_DISABLE_BUNDLED_SKILLS"
if [ -z "$BUNDLED_OFF" ] && [ -f "$SETTINGS" ]; then
  grep -q '"disableBundledSkills"[[:space:]]*:[[:space:]]*true' "$SETTINGS" \
    && BUNDLED_OFF="settings.json disableBundledSkills"
fi
SIMPLIFY_OVERRIDE=""
if [ -f "$SETTINGS" ]; then
  SIMPLIFY_OVERRIDE="$( { grep -o '"simplify"[[:space:]]*:[[:space:]]*"[a-z-]*"' "$SETTINGS" || true; } | head -1 )"
fi
if [ -n "$BUNDLED_OFF" ]; then
  warn "bundled skills are disabled ($BUNDLED_OFF)" \
    "the Builder's simplify pass cannot be invoked and will be silently hand-rolled; clear it, or accept that the simplify(increment): marker will be absent and Thomas's merge check will block"
elif [ -n "$SIMPLIFY_OVERRIDE" ] && ! printf '%s' "$SIMPLIFY_OVERRIDE" | grep -q '"on"'; then
  warn "skillOverrides restricts 'simplify' ($SIMPLIFY_OVERRIDE)" \
    "the Builder invokes this skill itself; anything but \"on\" puts it out of reach"
else
  ok "bundled skills reachable by the model (simplify is the Builder's own pass)"
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
# A role with NO codex row never runs on Codex, so it needs no machine-local profile and
# warning about one is noise the owner cannot act on. Absence is how this table already
# says "not this runtime" — `rin` has said it since 1.0.0 — so read it the same way here.
# `rin` stays in the loop because its template is the pane launcher for the day the trade
# is revisited; every other role follows its row.
for ROLE in thomas shaper builder rin qa; do
  ROW_EXISTS="$(orchestrator_codex_row "$ROLE" 2>/dev/null)"
  if [ "$ROLE" != "rin" ] && [ -n "$ORCH" ] && [ -z "$ROW_EXISTS" ]; then
    ok "Codex ${ROLE}: no codex row — this role does not run on Codex"
    continue
  fi
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
      # UNDECIDED is a legitimate resting state, not a defect: the owner picks a runtime per
      # project and per situation, and may genuinely not know yet. Warning here every run is
      # a nag they cannot act on, and a nag they learn to skip costs the warnings that matter.
      # The check that IS actionable happens at dispatch, where using it is the actual risk.
      [ -n "$TARGET" ] && ok "Codex ${ROLE}: undecided (<set-me>) — dispatch to codex will STOP until it is set"
      ROW=""
      SKIP_PROFILE=1
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
    if [ "${SKIP_PROFILE:-0}" = "1" ]; then
      SKIP_PROFILE=0
    elif [ -f "$DEST" ] && cmp -s "$TEMPLATE" "$DEST"; then
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

# 9. Watcher script — project-local, since install already stages it and a global copy is
# never touched by a release (measured: it drifted out of sync with the shipped version).
WATCHER=""
for CAND in "${TARGET:+$TARGET/scripts/herdr-watch-terminal.sh}" \
            "scripts/herdr-watch-terminal.sh" "harness/scripts/herdr-watch-terminal.sh"; do
  [ -n "$CAND" ] && [ -f "$CAND" ] && { WATCHER="$CAND"; break; }
done
if [ -n "$WATCHER" ]; then
  ok "$WATCHER present"
else
  warn "scripts/herdr-watch-terminal.sh missing" \
    "run install.sh; dispatch-ticket calls this file at <repo-root>/scripts/herdr-watch-terminal.sh"
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
      if [ "$ADAPTED" = "1" ]; then
        miss "docs/agents/${DOC}.md is missing after adaptation" \
          "thomas.md reads it at session start; the OWNER types /setup-matt-pocock-skills in that repo (no model can invoke it)"
      else
        warn "docs/agents/${DOC}.md not present yet" \
          "the OWNER types /setup-matt-pocock-skills in that repo (no model can invoke it) during adaptation; expected to be absent before then"
      fi
      TARGET_READY=0
    fi
  done
  # The guard is enforcement, and enforcement that is absent fails OPEN: the hook command
  # allows every Bash call when it cannot find the script, and `.claude/settings.json` is
  # owner-kept, so an upgraded project can carry an old settings file that never invokes it.
  # Neither state announces itself at runtime. It is caught here instead, where a doctor is
  # supposed to answer "is this install complete".
  if [ "$ADAPTED" = "1" ]; then
    if [ -f "$TARGET/scripts/hook-git-guard.py" ]; then
      ok "scripts/hook-git-guard.py present"
    else
      miss "scripts/hook-git-guard.py is missing after adaptation" \
        "the PreToolUse hook allows every command when the script is absent; re-run the payload install"
    fi
    # A SUBSTRING MATCH CERTIFIES A DEAD HOOK, AND SO DOES RUNNING THE FILE DIRECTLY.
    # Two ways this was wrong: it grepped for a name an older release's owner-kept
    # settings.json still contains while pointing at a script that no longer exists, and it
    # then executed that script by path — which proves the script works, not that anything
    # invokes it. A settings file registering it under the wrong event, or with matcher
    # `Read`, passes both. So: parse the file, require a PreToolUse entry whose matcher is
    # Bash and whose command names the installed script, THEN run it against a payload it
    # must refuse.
    GUARD_REG=$(python3 - "$TARGET" <<'PYEOF'
import json, sys, os
path = os.path.join(sys.argv[1], ".claude", "settings.json")
try:
    with open(path, encoding="utf-8") as fh:
        cfg = json.load(fh)
except FileNotFoundError:
    print("absent"); raise SystemExit
except Exception as exc:
    print("unparseable: %s" % exc); raise SystemExit
for e in ((cfg.get("hooks") or {}).get("PreToolUse") or []):
    if "Bash" not in str(e.get("matcher", "")):
        continue
    for h in (e.get("hooks") or []):
        if h.get("type") == "command" and "hook-git-guard.py" in (h.get("command") or ""):
            print("ok"); raise SystemExit
print("absent")
PYEOF
)
    case "$GUARD_REG" in
      ok)
        ok ".claude/settings.json has a PreToolUse/Bash command hook naming hook-git-guard.py"
        SMOKE='{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git add -A"}}'
        if printf '%s' "$SMOKE" | python3 "$TARGET/scripts/hook-git-guard.py" 2>/dev/null | grep -q '"permissionDecision": *"deny"'; then
          ok "the guard denies a command it must deny (smoke test: git add -A)"
        else
          miss "the registered guard did not deny a command it must deny" \
            "it is installed and inert; run scripts/hook-git-guard.py by hand against the same payload"
        fi ;;
      absent)
        miss ".claude/settings.json has no PreToolUse/Bash hook naming hook-git-guard.py" \
          "settings.json is owner-kept so an upgrade never rewrites it, and a file naming the older hook-git-guard.sh or registering it under another event passes a substring check while the hook is dead" ;;
      *)
        miss ".claude/settings.json could not be parsed ($GUARD_REG)" \
          "the registration cannot be confirmed, so enforcement cannot be assumed" ;;
    esac
  fi

  if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ok "target is a git work tree (worktree isolation available)"
    # AST-036: a worktree carries CONTENT AT HEAD only, so an uncommitted payload is
    # invisible to every Builder. A fixed four-path sample checked only with
    # `ls-files` passed this even when tracked-but-modified — a file this repo HAS
    # committed before, since edited on disk, still shows as "tracked" while a fresh
    # worktree checkout still gets the OLD content (measured directly: this check
    # reported OK for a payload with three new files and one edited file, none of
    # them yet committed). Walk every payload file actually on disk instead of a
    # sample, and check content against HEAD, not just presence in the index.
    # ---------------------------------------------------------------------------------------
  # INTEGRATION, NOT INSTALLATION. Everything above asks whether files are PRESENT. A live
  # upgrade showed that is not the same question: two shipped scripts resolved their root one
  # level too high and could not run at all in an adapted layout, while every presence check
  # passed and `applied-version` read 2.7.0. A marker is a claim, and this package has spent
  # four releases learning that a claim nothing tests is a claim that goes wrong quietly.
  #
  # Four conditions, each answerable:
  #   1. the marker matches the release that is actually staged
  #   2. every shipped script RUNS here — not exists, runs. AST-137: every defect a live
  #      upgrade returned lived between a TESTED invocation and a REAL one — a package layout
  #      vs an adapted one, `--check` first vs second, a branch name vs a 40-char SHA. None of
  #      them needed history; they needed a caller that invokes differently than the author.
  #   3. every payload file matches the release, is owner-owned, or has a recorded decision
  #   4. the mechanisms the release adds actually fire (the guard smoke test above)
  if [ "$ADAPTED" = "1" ]; then
    echo
    echo "INTEGRATION $TARGET:"

    CAND="$(cat "$TARGET/.astraler/CANDIDATE" 2>/dev/null || true)"
    APPL="$(cat "$TARGET/.astraler/state/applied-version" 2>/dev/null || true)"
    # THREE STATES, NOT TWO. Comparing applied-version against CANDIDATE collapses "an apply
    # stopped on conflicts" — this project's problem — with "somebody upstream staged a newer
    # release and nobody here has started it", which is not a failure at all. The second turned
    # a fully-applied, healthy project's own acceptance gate RED remotely, with no action by
    # that project: anything running this on a schedule reported a failure whose entire cause
    # was an event outside the repository. The honest reading of that red is "a release is
    # available", and that is not the same message as "this project is broken".
    #
    # install.sh already distinguishes them — it exits 3 and stamps nothing when conflicts
    # remain — but an exit code does not survive the moment, so it now also leaves
    # `.astraler/state/apply-incomplete`. That file is the signal; the version strings are not.
    PENDING="$TARGET/.astraler/state/apply-incomplete"
    # THE MARKER IS TESTED FIRST, because the comment above is what this code has to obey:
    # the file is the signal and the version strings are not. Ordering them the other way put a
    # `[MISS]` behind an `elif`, so a project with an unreconciled conflict recorded on disk
    # read `[OK] matches CANDIDATE` for as long as nothing new was staged — the false green
    # appearing exactly when the project looks most settled. And the state is not exotic:
    # `install.sh` INSTRUCTS an operator into it ("stamp the version by hand and say why"),
    # which leaves applied == candidate with the marker still there.
    if [ -f "$PENDING" ]; then
      miss "an apply stopped part-way: $(grep -m1 '^version:' "$PENDING" | cut -d' ' -f2-)" \
        "conflicts are unreconciled; see $PENDING. If you resolved them and stamped applied-version by hand, delete that file — it is what says the work is finished, not the version string"
    elif [ -n "$APPL" ] && [ "$APPL" = "$CAND" ]; then
      ok "applied-version ($APPL) matches CANDIDATE"
    elif [ -n "$APPL" ]; then
      # ADVISORY, and deliberately not a finding — the same reasoning as the milestone markers.
      # A state that is true whenever someone upstream is working is not a defect, and printing
      # it as one trains the reader to skip the check.
      ok "applied-version ($APPL) is landed and clean"
      echo "         → note: release $CAND is staged and not started. Not a finding; run"
      echo "           install.sh --plan when you want it."
    else
      miss "no applied-version marker" \
        "nothing records which release this project actually carries"
    fi

    # 2. RUNS, not exists. Each script is invoked exactly as ADAPT tells an adapter to invoke
    #    it — bare, from the repo root — because that is the invocation that was broken.
    # The script list comes from the APPLIED release too: a newer staged release may rename or
    # add scripts, and a project that has not applied it is not missing anything.
    APPLIED_REL="$TARGET/.astraler/releases/${APPL:-$CAND}/harness"
    [ -d "$APPLIED_REL" ] || APPLIED_REL="$TARGET/.astraler/releases/$CAND/harness"
    for SC in $( (cd "$APPLIED_REL/scripts" 2>/dev/null && ls *.sh *.py 2>/dev/null) | grep -E '^(docs-staleness-audit|ledger-index|ledger-rules|check-reachability)\.(sh|py)$'); do
      SP="$TARGET/scripts/$SC"
      [ -f "$SP" ] || { miss "scripts/$SC is missing" "the release you have applied ships it; re-run the payload install"; continue; }
      if head -1 "$SP" | grep -q python; then
        OUT="$(cd "$TARGET" && python3 "scripts/$SC" 2>&1 || true)"
      else
        OUT="$(cd "$TARGET" && bash "scripts/$SC" 2>&1 || true)"
      fi
      case "$OUT" in
        *"not found"*|*"NOT FOUND"*|*"NO ROLE CONTRACTS"*|*"measured nothing"*|*"cannot"*)
          miss "scripts/$SC does not run in this project's layout" \
            "$(printf '%s' "$OUT" | grep -m1 -iE 'not found|no role contracts|measured nothing|cannot' | sed 's/^ *//')" ;;
        *) ok "scripts/$SC runs here" ;;
      esac
    done

    # 3. Payload files that differ, minus the ones allowed to. A difference is not a defect —
    #    an adapted project SHOULD carry its own content — but an UNRECORDED one is, because
    #    then nobody can tell a deliberate merge from a half-applied release.
    # MEASURE AGAINST WHAT IS APPLIED, NOT WHAT IS STAGED. Check 1 was fixed to stop calling a
    # healthy project broken the moment someone upstream staged a release; checks 2 and 3 were
    # left comparing against $CAND and did exactly the same thing one line down — a project
    # sitting correctly at 2.7.5 with 2.7.6 staged failed on files it has no reason to carry
    # yet, and on a script the newer release renamed. Ninth instance of AST-137, created by
    # fixing one of the three places that compare.
    REL="$TARGET/.astraler/releases/${APPL:-$CAND}/harness"
    [ -d "$REL" ] || REL="$TARGET/.astraler/releases/$CAND/harness"
    REPORT="$TARGET/.astraler/state/ADAPTATION-REPORT.md"
    if [ -d "$REL" ]; then
      UNDECLARED=""
      while IFS= read -r f; do
        case "$f" in
          # OWNER-OWNED: the project's, never written by an upgrade.
          .agents/orchestrator.md|.claude/settings.json|.codex/profiles/*) continue ;;
          # GENERATED PER PROJECT: INDEX.md and RULES.md are derived from the ledger, and an
          # adapted project's ledger carries its own citations — so these differ from the
          # release by construction and will differ forever. Flagging them would train the
          # reader to skim this list, which is the one thing it cannot afford.
          .agents/memory/INDEX.md|.agents/memory/RULES.md) continue ;;
        esac
        [ -f "$TARGET/$f" ] || { UNDECLARED="$UNDECLARED  $f (absent)\n"; continue; }
        diff -q "$REL/$f" "$TARGET/$f" >/dev/null 2>&1 && continue
        # MATCH THE WAY A HUMAN WRITES IT, not the way find prints it. An adapter recorded
        # all eighteen of its decisions as `roles/builder.md` and `dispatch-ticket/CLEANUP.md`
        # — the payload-relative form with the tree prefix dropped, which is how anyone refers
        # to these files in prose. Demanding `.agents/roles/builder.md` reported a diligent
        # adapter as non-compliant, which is the third time in this release cycle a new check
        # fired on correct work. Accept the prefixed form, the unprefixed form, and the
        # skill-plus-file form.
        F_NOPREFIX="${f#.agents/}"; F_NOPREFIX="${F_NOPREFIX#.claude/}"
        F_NOPREFIX="${F_NOPREFIX#skills/}"
        if grep -qF -- "$f" "$REPORT" 2>/dev/null \
           || grep -qF -- "$F_NOPREFIX" "$REPORT" 2>/dev/null; then
          continue
        fi
        UNDECLARED="$UNDECLARED  $f\n"
      done < <(cd "$REL" && find . -type f | sed 's|^\./||' | sort)
      if [ -z "$UNDECLARED" ]; then
        ok "every payload file matches the release, is owner-owned, or is named in ADAPTATION-REPORT.md"
      else
        miss "payload files differ from the release and no record says why" \
          "$(printf "%b" "$UNDECLARED" | head -8 | tr '\n' ' ')— record each in .astraler/state/ADAPTATION-REPORT.md as a kept-on-purpose decision, or re-apply"
      fi
    fi
  fi

  # AST-036 does not depend on the docs. Gating it on TARGET_READY meant three missing
    # markdown files suppressed the check that Builder worktrees can see the contracts at
    # all — the weaker finding silencing the stronger. Run it always.
    if true; then
      if ! git -C "$TARGET" rev-parse --verify --quiet HEAD >/dev/null; then
        miss "target repo has no commits yet" \
          "every payload file is uncommitted by definition; commit at least once before dispatching a Builder"
      else
        UNTRACKED_PAYLOAD=0
        STALE_PAYLOAD=0
        # PAYLOAD IS WHAT THE RELEASE SHIPS, not everything under .agents/.claude/.codex. A
        # project keeps its own files in those directories — an owner's operating notes for
        # their Thomas tab lived at `.claude/loop-snippets.md` and this check counted it as
        # "harness payload untracked", a MISS about a file the harness does not own and never
        # shipped. Where a staged release is on disk, derive the list from it; the directory
        # walk is the fallback for a project that has pruned `.astraler/releases/`.
        PAYLOAD_PATHS=()
        _RELSRC=""
        for _v in "$(cat "$TARGET/.astraler/state/applied-version" 2>/dev/null)" \
                  "$(cat "$TARGET/.astraler/CANDIDATE" 2>/dev/null)"; do
          [ -n "$_v" ] && [ -d "$TARGET/.astraler/releases/$_v/harness" ] \
            && { _RELSRC="$TARGET/.astraler/releases/$_v/harness"; break; }
        done
        if [ -n "$_RELSRC" ]; then
          while IFS= read -r F; do
            [ -n "$F" ] && [ -e "$TARGET/$F" ] && PAYLOAD_PATHS+=("$F")
          done < <(cd "$_RELSRC" && find . -type f ! -name '.DS_Store' | sed 's|^\./||' | sort)
        else
          for D in .agents .claude .codex; do
            [ -d "$TARGET/$D" ] || continue
            while IFS= read -r -d '' F; do
              PAYLOAD_PATHS+=("${F#"$TARGET"/}")
            done < <(find "$TARGET/$D" -type f -print0)
          done
        fi
        # The set of harness-owned scripts install.sh stages into a project's scripts/ —
        # derived from the package's own harness/scripts/*.sh, plus this file (staged
        # separately from the package ROOT; see install.sh), rather than a hand-written
        # name list. A fixed list is correct the day it is written and silently stops
        # covering whatever the package later adds beside it: measured directly, this list
        # named three scripts while the package shipped five into scripts/, missing
        # check-reachability.sh, docs-staleness-audit.sh AND this file itself — so a
        # project whose only stale payload was one of those got a green from the one check
        # whose job is to say the payload is stale, up to and including the checker being
        # the stale file. Falls back to a fixed list only when this file is the VENDORED
        # copy running inside a project, where the package tree that lets this
        # self-maintain is not present.
        if [ -d "$PKG_DIR/harness/scripts" ]; then
          # This file is staged separately from the RAW package source tree — true there,
          # but not of a STAGED release, where install.sh copies it into harness/scripts/
          # too, so the glob already contains it. Appending unconditionally assumed the
          # source layout inside code that also runs against the staged layout; measured
          # against a real staged release, the duplicate over-counted one file (never
          # under-counted, so it never produced a false green — but a count is exactly the
          # thing this check exists to get right). `sort -u` makes the append correct under
          # either layout instead of correct for only the one it was written against.
          NAMED_SCRIPTS=$(cd "$PKG_DIR/harness/scripts" && printf '%s\n' *.sh)
          NAMED_SCRIPTS="$(printf '%s\ncheck-requirements.sh\n' "$NAMED_SCRIPTS" | sort -u)"
        else
          NAMED_SCRIPTS='herdr-watchdog.sh
herdr-watch-terminal.sh
ticket-git-facts.sh
check-reachability.sh
docs-staleness-audit.sh
check-requirements.sh'
        fi
        while IFS= read -r S; do
          [ -n "$S" ] && [ -f "$TARGET/scripts/$S" ] && PAYLOAD_PATHS+=("scripts/$S")
        done <<< "$NAMED_SCRIPTS"
        for PATHNAME in "${PAYLOAD_PATHS[@]}"; do
          # A deliberately gitignored file under .claude/ or .codex/ (settings.local.json,
          # a machine-local codex config) is not payload going stale — it was never meant
          # to be committed at all, so flagging it here is a MISS nothing can resolve.
          git -C "$TARGET" check-ignore -q -- "$PATHNAME" 2>/dev/null && continue
          if ! git -C "$TARGET" ls-files --error-unmatch -- "$PATHNAME" >/dev/null 2>&1; then
            printf '         · untracked: %s\n' "$PATHNAME"; UNTRACKED_PAYLOAD=$((UNTRACKED_PAYLOAD + 1))
          elif ! git -C "$TARGET" diff --quiet HEAD -- "$PATHNAME" 2>/dev/null; then
            printf '         · uncommitted change: %s\n' "$PATHNAME"; STALE_PAYLOAD=$((STALE_PAYLOAD + 1))
          fi
        done
        if [ "$UNTRACKED_PAYLOAD" -eq 0 ] && [ "$STALE_PAYLOAD" -eq 0 ]; then
          ok "harness payload is committed and matches HEAD (visible inside Builder worktrees)"
        else
          miss "harness payload has $UNTRACKED_PAYLOAD untracked and $STALE_PAYLOAD uncommitted-but-tracked file(s)" \
            "a worktree checks out HEAD only, so a Builder dispatched now reads stale or missing contract content (AST-036). Commit the payload before dispatching"
        fi
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
