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

# 1. Claude Code CLI. Claude is the only role runtime and the dispatch mod loads only there,
# so a missing Claude means the machine cannot gate at all — a MISS rather than a warning.
# Codex remains the cross-vendor arm (checked below, WARN when absent).
if [ "$HAVE_CLAUDE" -eq 1 ]; then
  ok "claude CLI ($(command -v claude))"
  # The dispatch mod is what records, briefs and watches every Claude pane; there is no watcher
  # left behind it on a Claude root. Below the version it was measured on it does not load, and
  # each pane runs unwatched while looking dispatched — a MISS, not a warning.
  CLAUDE_FLOOR="2.1.294"
  CLAUDE_VER="$(claude --version 2>/dev/null | awk '{print $1}')"
  if [ -n "$CLAUDE_VER" ] && [ "$(printf '%s\n%s\n' "$CLAUDE_FLOOR" "$CLAUDE_VER" | sort -V | head -1)" = "$CLAUDE_FLOOR" ]; then
    ok "Claude Code $CLAUDE_VER loads the dispatch mod (floor $CLAUDE_FLOOR)"
  else
    miss "Claude Code ${CLAUDE_VER:-unknown} is below $CLAUDE_FLOOR — the dispatch mod will not load" \
      "update Claude Code (claude update). Without the mod a Claude pane is neither recorded nor watched"
  fi
else
  miss "claude CLI not on PATH — the milestone gate cannot run" \
    "install Claude Code: https://claude.com/claude-code. With no Claude the answer is STOP and ask the owner"
fi

# 2. The mattpocock-skills plugin — the method itself. Every spine step this package routes
# to lives in the plugin, so an absent plugin leaves the whole chain pointing at nothing.
PLUGINS_JSON="$HOME/.claude/plugins/installed_plugins.json"
PLUGIN_FLOOR="1.3.1"
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
    "claude plugin marketplace add mattpocock/skills, then claude plugin install mattpocock-skills@mattpocock (the claude-plugins-official copy is pinned at 1.2.3). This package routes every spine step into it"
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

# 6–8. Codex surfaces — the cross-vendor arm (codex-arm: a Claude builder fires `codex exec
# review` through the codex plugin). Claude is the only role runtime, so neither surface gates
# the flow: absent, the arm cannot run and is recorded `NOT RUN — <reason>` for the OWNER to
# accept. A same-vendor lens never completes it.
if command -v codex >/dev/null 2>&1; then
  ok "codex CLI ($(command -v codex))"
else
  warn "codex CLI not on PATH" \
    "the cross-vendor arm needs it; install the OpenAI Codex CLI, e.g. brew install codex. Until then the arm is recorded 'NOT RUN — <reason>' for the OWNER to accept"
fi

# Codex plugin inside Claude Code (provides the companion runtime the arm invokes).
if [ -f "$PLUGINS_JSON" ] && grep -q '"codex@' "$PLUGINS_JSON"; then
  ok "Codex plugin in Claude Code (codex@… in installed_plugins.json)"
else
  warn "Codex plugin not installed in Claude Code" \
    "the cross-vendor arm needs it; in an interactive claude session: /plugin → install 'codex' (marketplace: openai-codex)"
fi

# `.agents/orchestrator.md` is the single owner of role → runtime/model/effort/advisor.
# A named target owns the answer: its table is the one its dispatches read. Only with no
# target does the package's own copy stand in. A fallback across the target boundary answers
# about the wrong tree: a target with no table of its own must not borrow the package's.
ORCH=""
if [ -n "$TARGET" ]; then
  [ -f "$TARGET/.agents/orchestrator.md" ] && ORCH="$TARGET/.agents/orchestrator.md"
else
  for CAND in ".agents/orchestrator.md" "harness/.agents/orchestrator.md"; do
    [ -f "$CAND" ] && { ORCH="$CAND"; break; }
  done
fi

# 2.18.0 added an Advisor column to the Active assignments table. The file is the owner's
# scaffold, so no release writes the column; this check and the dispatch mod's brief refusal
# are what make it land. The CELLS are not judged: blank means no advisor, by design.
if [ -n "$ORCH" ]; then
  ACTIVE_HEADER="$(awk '/^[ \t]*##[ \t]*Active assignments/{f=1;next} /^[ \t]*##[ \t]/{f=0} f && /^[ \t]*\|[ \t]*Role[ \t]*\|/{print; exit}' "$ORCH")"
  if [ -z "$ACTIVE_HEADER" ]; then
    miss "orchestrator: no Active assignments table found in $ORCH" "the launcher reads role → runtime/model/effort/advisor from that table; restore it"
  elif ! printf '%s' "$ACTIVE_HEADER" | grep -qi '|[[:space:]]*Advisor[[:space:]]*|'; then
    miss "orchestrator: Active assignments has no Advisor column (added 2.18.0; the launcher reads it)" "add the column — header Advisor, one cell per row: opus, fable, or blank for none; the dispatch mod refuses every brief until it exists"
  else
    ok "orchestrator: Active assignments carries the Advisor column"
  fi
fi

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
  # THE PUSH GATE IS A GIT HOOK, AND A HOOK GIT NEVER RUNS IS NOT ONE. hook-git-guard.py is a
  # lint that is silent on a heredoc, a $(...) or a ( ... ), measured at 26% of one day's
  # commands downstream, and a ticket's merge went out unstamped inside one. The gate is
  # scripts/pre-push-ticket-done.sh run as git's pre-push hook, which sees the exact refs
  # whatever the command looked like. Resolve the directory git actually reads: core.hooksPath
  # first, because it overrides .git/hooks entirely (ADAPT-HARNESS §6).
  if [ "$ADAPTED" = "1" ]; then
    HP="$(git -C "$TARGET" config --get core.hooksPath 2>/dev/null || true)"
    if [ -n "$HP" ]; then
      case "$HP" in /*) HD="$HP" ;; *) HD="$TARGET/$HP" ;; esac
    else
      HD="$(git -C "$TARGET" rev-parse --path-format=absolute --git-path hooks 2>/dev/null || true)"
    fi
    # core.hooksPath is MACHINE-LOCAL and replaces .git/hooks entirely: set and pointing at a
    # directory that is missing or holds non-executable files, every hook is dead and nothing
    # says so. Measured downstream: the setting survived a clone, the files did not.
    if [ -n "$HP" ]; then
      if [ ! -d "$HD" ]; then
        miss "git core.hooksPath is '$HP' but $HD is not a directory — every git hook is dead" \
          "point core.hooksPath at the directory that holds the hooks, or unset it"
      else
        DEAD_HOOKS=""
        for H in "$HD"/*; do
          [ -f "$H" ] && [ ! -x "$H" ] && DEAD_HOOKS="$DEAD_HOOKS $(basename "$H")"
        done
        if [ -n "$DEAD_HOOKS" ]; then
          miss "core.hooksPath -> $HP holds hooks that are not executable:$DEAD_HOOKS" \
            "the setting is live and these hooks are not; chmod +x them"
        else
          ok "git core.hooksPath -> $HP (directory present, hooks executable)"
        fi
      fi
    fi
    PP="$HD/pre-push"
    if [ ! -f "$TARGET/scripts/pre-push-ticket-done.sh" ]; then
      miss "scripts/pre-push-ticket-done.sh is missing after adaptation" "re-run the payload install"
    elif [ ! -x "$PP" ]; then
      miss "no executable pre-push hook at $PP — unstamped ticket merges can reach the base branch" \
        "wire it: a pre-push hook that runs scripts/pre-push-ticket-done.sh \"\$@\" (chain it into an existing pre-push rather than replacing it)"
    elif [ "$(grep -c 'pre-push-ticket-done' "$PP" 2>/dev/null || true)" -eq 0 ]; then
      miss "the pre-push hook at $PP does not call scripts/pre-push-ticket-done.sh" \
        "add a line running it with the hook's arguments and stdin; the push gate is not armed"
    else
      ok "pre-push gate wired ($PP calls pre-push-ticket-done.sh)"
    fi
  fi

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
      # ANCHORED NEAR THE START OF A LINE. A substring search over the whole output read the
      # scripts' own prose as their verdict, backwards: check-reachability's closing paragraph
      # says "what check 10 still cannot do", so a GREEN run was reported as "does not run
      # here" while a run with real FAILs exited before that paragraph and read as healthy.
      # Found and fixed downstream 2026-09-21, carried upstream 2.19.1. A genuine cannot-operate
      # message leads its line; 40 characters of slack absorbs bullets and indentation.
      TRIGGER="$(printf '%s' "$OUT" | grep -m1 -iE '^.{0,40}(not found|no role contracts|measured nothing|cannot)' | sed 's/^ *//')"
      case "$TRIGGER" in
        ?*) miss "scripts/$SC does not run in this project's layout" "$TRIGGER" ;;
        *)  ok "scripts/$SC runs here" ;;
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
          .agents/orchestrator.md|.claude/settings.json) continue ;;
          # GENERATED PER PROJECT: INDEX.md and RULES.md are derived from the ledger, and an
          # adapted project's ledger carries its own citations — so these differ from the
          # release by construction and will differ forever. Flagging them would train the
          # reader to skim this list, which is the one thing it cannot afford.
          .agents/memory/INDEX.md|.agents/memory/RULES.md) continue ;;
        esac
        # An ABSENT payload file is judged like a differing one: a recorded decision in the
        # report excuses it. Until 3.1.1 absence short-circuited before the report was read, so
        # a file an adopter had every reason not to materialise (a build artifact a release
        # shipped by mistake) was a MISS nothing could clear (found downstream on 3.1.0).
        [ -f "$TARGET/$f" ] && { diff -q "$REL/$f" "$TARGET/$f" >/dev/null 2>&1 && continue; }
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
        if [ -f "$TARGET/$f" ]; then UNDECLARED="$UNDECLARED  $f\n"; else UNDECLARED="$UNDECLARED  $f (absent)\n"; fi
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
        # PAYLOAD IS WHAT THE RELEASE SHIPS, not everything under .agents/.claude. A
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
        # PACKAGE LAYOUT has its own authoritative list: the payload IS `harness/`. Falling
        # through to the directory walk here reported the owner's `.claude/loop-snippets.md` as
        # untracked harness payload in the package repo itself — the same false positive this
        # check was just fixed for downstream, surviving upstream because no release is staged.
        # PACKAGE LAYOUT: the payload is `harness/`, and the paths it yields need that prefix
        # back or `[ -e ]` fails on every one and the check silently examines NOTHING. A first
        # attempt at this omitted the prefix and turned the payload-committed check into a
        # check that cannot fail — caught by editing a payload file and watching it stay green,
        # which is the only way that class is ever caught.
        _PREFIX=""
        [ -n "$_RELSRC" ] || { [ -d "$TARGET/harness/.agents/roles" ] && { _RELSRC="$TARGET/harness"; _PREFIX="harness/"; }; }
        if [ -n "$_RELSRC" ]; then
          while IFS= read -r F; do
            [ -n "$F" ] && [ -e "$TARGET/$_PREFIX$F" ] && PAYLOAD_PATHS+=("$_PREFIX$F")
          done < <(cd "$_RELSRC" && find . -type f ! -name '.DS_Store' | sed 's|^\./||' | sort)
        else
          for D in .agents .claude; do
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
        # check-reachability.py, docs-staleness-audit.sh AND this file itself — so a
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
check-reachability.py
docs-staleness-audit.sh
check-requirements.sh'
        fi
        while IFS= read -r S; do
          [ -n "$S" ] && [ -f "$TARGET/scripts/$S" ] && PAYLOAD_PATHS+=("scripts/$S")
        done <<< "$NAMED_SCRIPTS"
        # DEDUPE. The release ships check-requirements.sh at two paths, so it appeared twice in
        # the list and was counted twice in the verdict.
        if [ "${#PAYLOAD_PATHS[@]}" -gt 0 ]; then
          IFS=$'\n' PAYLOAD_PATHS=($(printf '%s\n' "${PAYLOAD_PATHS[@]}" | sort -u)); unset IFS
        fi
        for PATHNAME in "${PAYLOAD_PATHS[@]}"; do
          # A deliberately gitignored file under .claude/ (settings.local.json) is not payload going stale — it was never meant
          # to be committed at all, so flagging it here is a MISS nothing can resolve.
          git -C "$TARGET" check-ignore -q -- "$PATHNAME" 2>/dev/null && continue
          # RESOLVE A SYMLINKED PARENT BEFORE BELIEVING "untracked". A project may DUAL-HOME a
          # skill — real content at `.agents/skills/<name>/`, `.claude/skills/<name>/` a symlink
          # to it — an arrangement `check-payload-drift.sh` documents as supported and ships
          # SYMLINK manifest rows for. Git tracks the LINK; paths *through* it are correctly
          # absent from the index, so a literal-path lookup calls three tracked files untracked
          # and fails a project for doing something this package blesses. One shipped script
          # cannot call an arrangement legal while another refuses it.
          #
          # The realpath is only computed for paths that already look untracked, so the common
          # case costs nothing.
          if ! git -C "$TARGET" ls-files --error-unmatch -- "$PATHNAME" >/dev/null 2>&1; then
            REALREL="$(cd "$TARGET" && python3 -c '
import os, sys
try:
    print(os.path.relpath(os.path.realpath(sys.argv[1]), os.path.realpath(".")))
except Exception:
    pass' "$PATHNAME" 2>/dev/null)"
            if [ -n "$REALREL" ] && [ "$REALREL" != "$PATHNAME" ] \
               && git -C "$TARGET" ls-files --error-unmatch -- "$REALREL" >/dev/null 2>&1; then
              PATHNAME="$REALREL"      # tracked at its real home; fall through to the diff check
            else
              printf '         · untracked: %s\n' "$PATHNAME"; UNTRACKED_PAYLOAD=$((UNTRACKED_PAYLOAD + 1))
              continue
            fi
          fi
          if ! git -C "$TARGET" diff --quiet HEAD -- "$PATHNAME" 2>/dev/null; then
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
