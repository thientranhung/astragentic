#!/usr/bin/env python3
"""hook-contract-reload.py — SessionStart(compact) hook. Re-arms the role contract after
compaction.

THE DEFECT THIS EXISTS FOR. A role's contract lives in `.agents/roles/<role>.md` and is
loaded with the Read tool, so it enters the conversation as a tool result. Tool results are
what compaction summarises away first. What survives is `.claude/agents/<role>.md` — the
system prompt — which carries four rules. Measured on one long autonomous session that
compacted once: the four rules in the system prompt were obeyed every time all session, and
every rule outside it was violated, none noticed until the owner asked. The correlation was
total. That is the budget behaving as built, not an attention failure.

WHY THE SYSTEM PROMPT ALONE DOES NOT FIX IT. It already says "Read `.agents/roles/<role>.md`
now", and that line survives compaction intact. The word that does not survive is "now". A
compacted agent reads its summary, sees work in progress, concludes it is mid-session, and
never re-reads. The instruction is present and inert — an instruction with no moment attached
measures zero (AST-069). This hook is the moment.

WHY compact AND NOT clear. After `/clear` the agent faces an empty context and the same
system-prompt line, and it reads the contract, because nothing suggests it already did. After
compaction it faces a summary that says work is underway, and it does not. The asymmetry is
the whole defect, so firing on `clear` would spend context re-arming a session that is
already armed. `startup`, `resume` and `fork` are excluded for the same reason.

WHY THIS NAMES ONE FILE AND NOT THE WHOLE LOAD SET. Each contract's Load table is the single
home for what else that role reads and when. A hook that also named supplements would be a
second home for that fact, and the two would drift — Thomas's supplement is chosen by the
BUILDER's runtime, not his own, which is exactly the kind of rule a hook gets wrong. Name the
contract; let the contract dispatch the rest.

RUN IT BY HAND — this is the test:

    echo '{"hook_event_name":"SessionStart","source":"compact","agent_type":"thomas"}' \
      | python3 scripts/hook-contract-reload.py

    echo '{"hook_event_name":"SessionStart","source":"startup"}' \
      | python3 scripts/hook-contract-reload.py    # expect: no output

A hook that fails is silent by construction, which is the failure class this whole file is
about. So every exit path below is either valid JSON on stdout or nothing at all, and no path
raises: a traceback on stderr would be read by the runtime as a broken hook and disabled, and
the operator would keep shipping a harness that looks armed.
"""

import json
import os
import subprocess
import sys

# Sources that leave an agent believing it is mid-session while its contract is gone.
REARM_ON = {"compact"}

ROLES_DIR = os.path.join(".agents", "roles")
EVENTS_LOG = "/tmp/harness-hook-events.log"


def _utcnow():
    try:
        import datetime
        return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    except Exception:
        return "?"


def note(line):
    """Append one line to the shared hook log. Never raises: a hook that dies while
    recording that it ran is worse than one that stays quiet."""
    try:
        with open(EVENTS_LOG, "a") as fh:
            fh.write(line.rstrip("\n") + "\n")
    except Exception:
        pass


def project_dir(payload):
    """Where the contract lives, resolved without assuming one runtime.

    `CLAUDE_PROJECT_DIR` is set by Claude Code and by nothing else. Codex sets its own, and
    the repository root is what both mean, so ask git before falling back to the payload.
    2.7.13 shipped a guard that only Claude could reach because its registration named a
    Claude-only file; naming a Claude-only variable is the same defect one layer down."""
    for var in ("CLAUDE_PROJECT_DIR", "CODEX_PROJECT_DIR"):
        val = os.environ.get(var)
        if val:
            return val
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=5,
        )
        if out.returncode == 0 and out.stdout.strip():
            return out.stdout.strip()
    except Exception:
        pass
    return payload.get("cwd") or os.getcwd()


def emit(text):
    """SessionStart injects via hookSpecificOutput.additionalContext. Bare stdout is also
    read on some versions, but the documented key is unambiguous, so use it."""
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": text,
            }
        },
        sys.stdout,
    )
    sys.stdout.write("\n")


def contract_path(project_dir, agent_type):
    """The contract for this role, if we can name it and it is really there.

    `agent_type` is optional in the SessionStart payload. When it is absent, or names a role
    with no contract on disk, fall back to wording that makes the agent resolve the path from
    its own system prompt — which names it correctly for every role, and is the one statement
    of it that cannot go stale here."""
    if not agent_type:
        return None
    if not agent_type.replace("-", "").isalnum():  # never build a path from unvetted input
        return None
    rel = os.path.join(ROLES_DIR, "%s.md" % agent_type)
    return rel if os.path.isfile(os.path.join(project_dir, rel)) else None


def message(rel_path):
    named = "`%s`" % rel_path if rel_path else (
        "the role contract your system prompt names under `.agents/roles/`"
    )
    return (
        "CONTEXT WAS JUST COMPACTED. Every file you had read is gone from your context, "
        "including your role contract. What you can still see is your system prompt, which "
        "carries only a few rules — the rest of your operating contract is NOT in front of "
        "you right now, and nothing else will tell you so.\n\n"
        "Before your next action of any kind — before any dispatch, merge, label write or "
        "report — re-read %s, and follow its Load table for whatever else that role loads.\n\n"
        "You have not already done this in the current context. Reading the summary above is "
        "not the same as holding the contract." % named
    )


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return  # malformed stdin is the runtime's problem, not a reason to print noise

    if not isinstance(payload, dict):
        return

    event = payload.get("hook_event_name") or "?"
    source = payload.get("source")

    if source not in REARM_ON:
        # Every runtime this package supports has a compaction event; only Claude Code is
        # known to spell the reason `source: "compact"`. Record what a runtime actually
        # sent so the first real compaction elsewhere becomes a measurement instead of an
        # assumption — the hook stays silent either way.
        note("%s hook-contract-reload INERT event=%s source=%s keys=%s"
             % (_utcnow(), event, source, ",".join(sorted(payload))[:120]))
        return

    root = project_dir(payload)
    note("%s hook-contract-reload FIRED event=%s role=%s root=%s"
         % (_utcnow(), event, payload.get("agent_type") or "?", root))
    emit(message(contract_path(root, payload.get("agent_type"))))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass  # see the module docstring: never raise, never disable ourselves
