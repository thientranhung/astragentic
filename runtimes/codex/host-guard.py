#!/usr/bin/env python3
"""Codex PreToolUse hook: one host per session (6.1.0, owner rule 2026-11-09).

Reads the PreToolUse payload on stdin. A shell command that starts with `herdr <sub>` while
ORCA_PANE_KEY is set, or `orca <sub>` while HERDR_ENV=1 and ORCA_PANE_KEY is unset, is denied
with the reason; everything else prints nothing. Measured 2026-11-09: both CLIs answer from either
pane, so without this a Codex Thomas opened in Orca would create its Builders in Herdr.
"""
import json
import os
import re
import sys

HERDR = re.compile(r'(?:^|[\n;&|(])\s*herdr\s+(agent|tab|pane|workspace|notification|command)\b')
ORCA = re.compile(r'(?:^|[\n;&|(])\s*(?:\S*/)?orca\s+(terminal|orchestration|worktree|agent|repo|project)\b')


def decide(command, env):
    host = 'orca' if env.get('ORCA_PANE_KEY') else 'herdr' if env.get('HERDR_ENV') == '1' else None
    if host == 'orca' and HERDR.search(command):
        return 'this session runs in Orca (ORCA_PANE_KEY is set); a herdr command would put the work in Herdr. Use the Orca section of DISPATCH.md, or stop and tell the owner.'
    if host == 'herdr' and ORCA.search(command):
        return 'this session runs in Herdr (HERDR_ENV=1); an orca command would put the work in Orca. Use the Herdr text of DISPATCH.md, or stop and tell the owner.'
    return None


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    command = str((payload.get('tool_input') or {}).get('command') or '')
    reason = decide(command, os.environ)
    if reason:
        print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'deny',
                                                 'permissionDecisionReason': 'astragentic host guard: ' + reason}}))
    return 0


if __name__ == '__main__':
    sys.exit(main())
