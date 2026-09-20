#!/usr/bin/env python3
"""hook-tracker-status.py — SessionStart hook. Injects the live tracker counts.

THE DEFECT THIS EXISTS FOR. The tracker contract's requirement 5 is that the OWNER has a
surface he can read without running a query, and the entry it is bound to says the failure is
never noticed by an agent: an agent recomputes what is ready whenever it wants, so it does not
feel the state missing. Downstream this arrived as the owner asking for tracker status three
times and being forgotten three times, with a rule file already on disk stating the obligation.

WHY A RULE WAS NOT ENOUGH, AND THIS IS THE POINT OF THE WHOLE MECHANISM. The rule was correct,
auto-loaded, and inert. An instruction with no moment attached measures zero (AST-069) — and
`hook-contract-reload.py` next door exists for the same reason, one layer up. But this hook
does something that one does not: it does not make the obligation louder, it makes the
obligation unnecessary. The counts are in context before the first question is asked, so
reporting them costs nothing and omitting them is visible. Raising a document's tier makes a
duty shout; injecting the data deletes the duty. Prefer the second where the thing owed is
data rather than judgement.

WHY IT CALLS A PLUG AND QUERIES NOTHING ITSELF. This package ships three tracker adapters and
the contract says a project's `docs/agents/issue-tracker.md` names which one, its coordinates
and its status map. A hook that ran `gh issue list` would hardcode one tracker, one label
vocabulary and one project's taxonomy into payload — the exact shape the tracker contract
exists to prevent. So the query is a fourth project plug, `.astraler/project/tracker-status.sh`,
beside `tracker-state.sh`, `ticket-done.sh` and `cleanup-worktree.sh`. The package owns the
moment and the failure discipline; the project owns the question.

AN ABSENT PLUG IS AN EMPTY SOCKET, NOT A FAULT. Same rule as `ticket-done.sh`: a project that
has not written the plug gets one note, not a broken session. Silence would make a harness
that looks armed and is not, which is the class this file is about.

WHY IT ONLY READS. The plug is called with no arguments and its stdout is injected. A
session-start hook fires on every session including read-only ones, with nobody watching the
outcome, so it is the wrong place to mutate a remote board. If the project's mirror needs a
push, its contract tells the role to run the sync; this hook tells the role the numbers.

FAILS OPEN, LOUDLY ENOUGH TO SEE. No plug, a non-executable plug, a plug that exits non-zero,
a plug that hangs, a plug that prints nothing — every one exits 0 with a line on stderr and a
line in /tmp/harness-hook-events.log. Nothing here raises: a traceback is read by the runtime
as a broken hook and disables it silently, and the operator keeps shipping a harness that looks
armed.

WHY THE OUTPUT IS TRUNCATED. The plug is project-authored and this runs at the top of every
session, so an unbounded plug would spend the session's context before the first turn. The cap
is stated to the reader rather than applied quietly — a count that was cut off and does not say
so is worse than no count.

RUN IT BY HAND — this is the test:

    echo '{"hook_event_name":"SessionStart","source":"startup"}' \
      | python3 scripts/hook-tracker-status.py        # expect: note if no plug, exit 0

    printf '#!/bin/sh\necho "open 4"\n' > .astraler/project/tracker-status.sh
    chmod +x .astraler/project/tracker-status.sh
    echo '{"hook_event_name":"SessionStart","source":"startup"}' \
      | python3 scripts/hook-tracker-status.py        # expect: JSON carrying "open 4"
"""

import json
import os
import subprocess
import sys

PLUG_REL = os.path.join(".astraler", "project", "tracker-status.sh")
PLUG_TIMEOUT_SECONDS = 15
MAX_CHARS = 4000
EVENTS_LOG = "/tmp/harness-hook-events.log"

# `compact` is excluded on purpose. After a compaction the counts already in the summary are
# the ones the session has been reasoning about, and a second set fetched seconds later
# invites the agent to reconcile two snapshots that differ for no reason it can see.
# Re-arming the contract is that moment's job; this one belongs to a session that has none.
INJECT_ON = {"startup", "resume", "clear"}


def _utcnow():
    try:
        import datetime
        return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    except Exception:
        return "?"


def log(line):
    try:
        with open(EVENTS_LOG, "a") as fh:
            fh.write("%s hook-tracker-status %s\n" % (_utcnow(), line))
    except Exception:
        pass


def bail(reason):
    """Fail OPEN. Say so on stderr, log it, exit 0 — never block a session from starting."""
    try:
        sys.stderr.write(
            "hook-tracker-status: %s — tracker counts not injected this session\n" % reason)
    except Exception:
        pass
    log(reason)
    sys.exit(0)


def project_dir(payload):
    """The repository root, resolved without assuming one runtime.

    `CLAUDE_PROJECT_DIR` is set by Claude Code and by nothing else; Codex sets its own. Both
    mean the repository root, so ask git before falling back to the payload. Naming a
    Claude-only variable is 2.7.13's defect one layer down (AST-138)."""
    for var in ("CLAUDE_PROJECT_DIR", "CODEX_PROJECT_DIR"):
        val = os.environ.get(var)
        if val:
            return val
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, timeout=5)
        if out.returncode == 0 and out.stdout.strip():
            return out.stdout.strip()
    except Exception:
        pass
    return payload.get("cwd") or os.getcwd()


def emit(text):
    """SessionStart injects via hookSpecificOutput.additionalContext. Bare stdout is also read
    on some versions, but the documented key is unambiguous, so use it."""
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


def run_plug(root):
    path = os.path.join(root, PLUG_REL)
    if not os.path.isfile(path):
        bail("no plug at %s (empty socket; ADAPT-HARNESS §3)" % PLUG_REL)
    if not os.access(path, os.X_OK):
        bail("%s is not executable" % PLUG_REL)
    try:
        out = subprocess.run([path], capture_output=True, text=True,
                             cwd=root, timeout=PLUG_TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired:
        bail("%s timed out after %ss" % (PLUG_REL, PLUG_TIMEOUT_SECONDS))
    except OSError as exc:
        bail("%s could not run (%s)" % (PLUG_REL, exc.__class__.__name__))
    if out.returncode != 0:
        # A plug's stderr can carry a token hint from the tracker CLI underneath it. Report
        # the class, never the text.
        bail("%s exited %d (offline, unauthenticated, or the tracker refused)"
             % (PLUG_REL, out.returncode))
    body = (out.stdout or "").strip()
    if not body:
        bail("%s printed nothing" % PLUG_REL)
    return body


def render(body):
    truncated = False
    if len(body) > MAX_CHARS:
        body = body[:MAX_CHARS]
        truncated = True
    lines = [
        "## Tracker status (live, injected at session start)",
        "",
        body,
        "",
    ]
    if truncated:
        lines.append(
            "**Cut off at %d characters by the hook** — what you see above is partial, so do "
            "not report it as a complete picture. Query the tracker directly, or shorten "
            "`%s`." % (MAX_CHARS, PLUG_REL))
        lines.append("")
    lines.append(
        "Produced by `%s`, this project's own plug. It is a READ: nothing was written to the "
        "tracker, and any board mirror this project keeps is still whatever it was. The "
        "obligation these numbers exist for is requirement 5 of `.agents/tracker-contract.md` "
        "— a surface the OWNER can read without running a query." % PLUG_REL)
    return "\n".join(lines)


def main():
    raw = ""
    try:
        raw = sys.stdin.read()
    except Exception:
        pass
    try:
        payload = json.loads(raw) if raw.strip() else {}
    except ValueError:
        # Stdin that does not parse means the moment is unknown, and a hook that cannot tell
        # which moment it is in has no business spending the session's context. Silent, the
        # same answer `hook-contract-reload.py` gives.
        bail("stdin was not JSON")
    if not isinstance(payload, dict):
        bail("stdin was JSON but not an object")

    source = payload.get("source")
    # A payload that PARSED but names no source is injected for: a runtime that does not send
    # one is a runtime whose sessions would otherwise never see the counts, and the cost of
    # being wrong is one extra table.
    if source is not None and source not in INJECT_ON:
        sys.exit(0)

    root = project_dir(payload)
    body = run_plug(root)
    try:
        emit(render(body))
    except Exception as exc:  # a broken render must never look like a broken hook
        bail("could not render counts (%s)" % exc.__class__.__name__)
    log("injected %d chars from %s" % (len(body), PLUG_REL))


if __name__ == "__main__":
    main()
