import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
BELL = ROOT / 'runtimes/codex/turn-end.sh'
THOMAS = '01a1bb4e-972f-7f10-baf8-be8979a45637'
WORKER = '01a1bb50-f2c3-7571-b74a-6dbd890c3a6b'
TURN = '01a1bb50-f48c-7271-9d47-ff2ca3e16400'
FAKE_CODEX = '''#!/bin/bash
printf '%s\\n' "$*" >> "$FAKE_CODEX_CALLS"
echo "Queued message fake for thread $4."
'''


def payload(**overrides):
    data = {'type': 'agent-turn-complete', 'thread-id': WORKER, 'turn-id': TURN,
            'cwd': '/tmp/w', 'client': 'codex_exec', 'input-messages': ['x'],
            'last-assistant-message': 'ROUND-1\nsecond line'}
    data.update(overrides)
    return json.dumps(data)


class TurnEndBellTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='astra-bell-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        fake_bin = self.root / 'bin'
        fake_bin.mkdir()
        fake = fake_bin / 'codex'
        fake.write_text(FAKE_CODEX)
        fake.chmod(0o755)
        self.calls = self.root / 'calls.txt'
        self.state = self.root / 'state'
        self.env = {**os.environ, 'PATH': f'{fake_bin}:{os.environ["PATH"]}',
                    'FAKE_CODEX_CALLS': str(self.calls), 'ASTRAGENTIC_BELL_STATE': str(self.state)}

    def ring(self, *fixed, body=None):
        result = subprocess.run(['bash', str(BELL), *fixed, payload() if body is None else body],
                                env=self.env, capture_output=True, text=True, cwd=self.root)
        self.assertEqual(result.returncode, 0, result.stderr)
        return self.calls.read_text().splitlines() if self.calls.exists() else []

    def test_valid_turn_queues_once_without_resume_and_logs(self):
        calls = self.ring('D1', THOMAS)
        self.assertEqual(len(calls), 1)
        call = calls[0]
        self.assertTrue(call.startswith(f'queue --thread {THOMAS} --message TURN-END dispatch=D1 worker={WORKER} turn={TURN} last=ROUND-1'), call)
        self.assertNotIn('--resume', call)
        self.assertNotIn('--remote', call)
        self.assertNotIn('second line', call)
        log = (self.state / 'turn-end.log').read_text()
        self.assertIn('sent rc=0', log)
        self.assertIn('Queued message fake', log)

    def test_same_turn_twice_queues_once_and_new_turn_queues_again(self):
        self.ring('D1', THOMAS)
        calls = self.ring('D1', THOMAS)
        self.assertEqual(len(calls), 1)
        self.assertIn('duplicate', (self.state / 'turn-end.log').read_text())
        other = TURN[:-1] + ('1' if TURN[-1] != '1' else '2')
        calls = self.ring('D1', THOMAS, body=payload(**{'turn-id': other}))
        self.assertEqual(len(calls), 2)

    def test_other_event_types_and_bad_ids_are_skipped_silently(self):
        for fixed, body in [(('D1', THOMAS), payload(type='agent-turn-start')),
                            (('D1', THOMAS), 'not json'),
                            (('D1', 'thomas'), payload()),
                            (('D1', '00000000-0000-0000-0000-000000000000'), payload()),
                            (('D1', THOMAS), payload(**{'turn-id': ''})),
                            (('D1', THOMAS, 'ws://host:1'), payload())]:
            with self.subTest(fixed=fixed, body=body[:30]):
                self.assertEqual(self.ring(*fixed, body=body), [])
        log = (self.state / 'turn-end.log').read_text()
        self.assertEqual(log.count('skip'), 6)

    def test_bell_off_marker_silences_until_removed(self):
        self.state.mkdir()
        (self.state / 'bell-off').write_text('')
        self.assertEqual(self.ring('D1', THOMAS), [])
        self.assertIn('bell-off', (self.state / 'turn-end.log').read_text())
        (self.state / 'bell-off').unlink()
        self.assertEqual(len(self.ring('D1', THOMAS)), 1)

    def test_recorded_endpoint_is_carried_as_remote(self):
        calls = self.ring('D1', THOMAS, 'unix:///tmp/app-server-control.sock')
        self.assertEqual(len(calls), 1)
        self.assertTrue(calls[0].startswith(f'queue --remote unix:///tmp/app-server-control.sock --thread {THOMAS} '), calls[0])
        self.assertNotIn('--resume', calls[0])

    def test_dispatch_argv_in_dispatch_md_is_valid_toml_for_codex(self):
        # Render the documented NOTIFY string with bash and parse it as Codex would (-c key=TOML value).
        text = (ROOT / 'runtimes/codex/.codex/DISPATCH.md').read_text()
        line = next(l for l in text.splitlines() if l.startswith('NOTIFY='))
        for endpoint in ('', 'unix:///tmp/x.sock'):
            with self.subTest(endpoint=endpoint):
                env = {**os.environ, 'WORKTREE': '/w t', 'DISPATCH_ID': 'D1', 'THOMAS_UUID': THOMAS,
                       'CODEX_LIFECYCLE_ENDPOINT': endpoint}
                out = subprocess.run(['bash', '-c', 'BELL="$WORKTREE/.codex/astragentic/turn-end.sh"; ' + line + '; printf %s "$NOTIFY"'],
                                     env=env, capture_output=True, text=True, check=True).stdout
                key, _, value = out.partition('=')
                self.assertEqual(key, 'notify')
                import tomllib
                parsed = tomllib.loads('v=' + value)['v']
                expected = ['bash', '/w t/.codex/astragentic/turn-end.sh', 'D1', THOMAS] + ([endpoint] if endpoint else [])
                self.assertEqual(parsed, expected)


if __name__ == '__main__':
    unittest.main()
