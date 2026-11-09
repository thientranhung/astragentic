import json
import os
from pathlib import Path
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
GUARD = ROOT / 'runtimes/codex/host-guard.py'
BASE = {k: v for k, v in os.environ.items() if k not in ('ORCA_PANE_KEY', 'HERDR_ENV')}


def run(command, **env):
    payload = {'hook_event_name': 'PreToolUse', 'tool_name': 'Bash', 'tool_input': {'command': command}}
    p = subprocess.run([sys.executable, str(GUARD)], input=json.dumps(payload), text=True, capture_output=True, env={**BASE, **env})
    assert p.returncode == 0, p.stderr
    return json.loads(p.stdout)['hookSpecificOutput']['permissionDecisionReason'] if p.stdout.strip() else None


class HostGuardTests(unittest.TestCase):
    # Owner rule 2026-11-09: one host per session. Both CLIs answer from either pane (measured), so
    # the guard, not the environment, keeps a Codex Thomas opened in Orca out of Herdr.
    def test_orca_session_refuses_herdr_and_keeps_orca_and_mentions(self):
        orca = {'ORCA_PANE_KEY': 'tab:leaf', 'HERDR_ENV': '1'}  # inherited HERDR_* loses to Orca
        self.assertIn('runs in Orca', run('herdr agent start x --kind codex -- --model m', **orca))
        self.assertIn('runs in Orca', run('cd /w && herdr tab create --workspace w --label t', **orca))
        self.assertIsNone(run('orca terminal create --worktree active --command codex', **orca))
        self.assertIsNone(run('cat docs/herdr-notes.md; echo herdr', **orca))
        self.assertIsNone(run('git status', **orca))

    def test_herdr_session_refuses_orca_and_keeps_paths_named_orca(self):
        herdr = {'HERDR_ENV': '1'}
        self.assertIn('runs in Herdr', run('orca orchestration worker-start --spec x', **herdr))
        self.assertIn('runs in Herdr', run('/Applications/Orca.app/Contents/Resources/bin/orca terminal list', **herdr))
        self.assertIsNone(run('herdr agent start x --kind codex', **herdr))
        self.assertIsNone(run('sed -n 1,5p docs/codex/ORCA-DESIGN.md', **herdr))

    def test_no_host_and_bad_payload_print_nothing(self):
        self.assertIsNone(run('herdr tab list'))
        self.assertIsNone(run('orca terminal list'))
        p = subprocess.run([sys.executable, str(GUARD)], input='not json', text=True, capture_output=True, env=BASE)
        self.assertEqual((p.returncode, p.stdout), (0, ''))

    def test_template_registers_the_guard_beside_the_stop_hook(self):
        hooks = json.loads((ROOT / 'runtimes/codex/coordinator-hooks.json').read_text())['hooks']
        self.assertIn('coordinator-turn-end.sh', hooks['Stop'][0]['hooks'][0]['command'])
        pre = hooks['PreToolUse'][0]
        self.assertEqual(pre['matcher'], '^Bash$')
        self.assertIn('.codex/astragentic/host-guard.py', pre['hooks'][0]['command'])


if __name__ == '__main__':
    unittest.main()
