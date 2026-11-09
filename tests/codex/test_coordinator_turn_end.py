import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'runtimes/codex/coordinator-turn-end.sh'
# WALK007 session/turn times from the owner audit; fixture has no product writes.
THREAD = '01a1bc2d-e4e9-7561-8e2d-e162669fb983'
TURN = '12345678-1234-4234-8234-123456789abc'
HB = 'tra1344-qa-walk007-handback001'


class CoordinatorBellTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='astra coordinator ')
        self.root = Path(self.tmp.name).resolve()
        self.record = self.root / '.scratch/codex/tra-1344-603-20261109.md'
        self.record.parent.mkdir(parents=True)
        self.base = ('# Dispatch tra-1344-603-20261109\nCoordinator thread UUID: ' + THREAD + '; worker UUID bound\n'
                     + 'handback: ' + HB + ' 2026-11-09T05:42:12.736Z\n')
        self.record.write_text(self.base)
        self.state = self.root / '.astraler/codex/state'
        self.calls = self.root / 'calls.jsonl'
        binary = self.root / 'herdr'
        binary.write_text('#!/bin/bash\nprintf "%s\\t" "$@" >> "$CALLS"\nprintf "\\n" >> "$CALLS"\n'
                          'printf "notification accepted\\n"\nexit "${FAIL_NOTIFY:-0}"\n')
        binary.chmod(0o755)
        self.env = {**os.environ, 'PATH': str(self.root)+os.pathsep+os.environ['PATH'], 'CALLS': str(self.calls)}
        self.payload = {'type': 'agent-turn-complete', 'thread-id': THREAD, 'turn-id': TURN, 'cwd': str(self.root)}

    def tearDown(self): self.tmp.cleanup()

    def ring(self, script=SCRIPT):
        p = subprocess.run(['bash', str(script), str(self.root), json.dumps(self.payload)],
                           env=self.env, text=True, capture_output=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        log = (self.state/'coordinator-turn-end.log').read_text() if (self.state/'coordinator-turn-end.log').exists() else p.stderr
        self.assertNotIn('notify_unknown', log, log)
        return self.calls.read_text().splitlines() if self.calls.exists() else []

    def test_walk007_pending_alert_and_duplicate_turn_no_extra(self):
        calls = self.ring(); self.assertEqual(len(calls), 1)
        argv = calls[0].split('\t'); self.assertEqual(argv[:2], ['notification', 'show'])
        self.assertIn(HB, argv[4]); self.assertNotIn('queue', argv); self.assertNotIn('resume', argv)
        self.assertEqual(len(self.ring()), 1)
        self.payload['turn-id'] = '22345678-1234-4234-8234-123456789abc'
        self.assertEqual(len(self.ring()), 1)

    def test_all_stopping_dispositions_suppress(self):
        for state in ['completed', 'owner_paused', 'external_wait', 'worker_running', 'idle']:
            self.record.write_text(self.base+f'disposition: {HB} {state} 2026-11-09T05:42:33.596Z\n')
            self.assertEqual(self.ring(), [], state)

    def test_coordinator_pending_still_alerts(self):
        self.record.write_text(self.base+f'disposition: {HB} coordinator_pending 2026-11-09T05:42:33.596Z\n')
        self.assertEqual(len(self.ring()), 1, (self.state/'coordinator-turn-end.log').read_text())

    def test_bell_off(self):
        self.state.mkdir(parents=True);(self.state/'bell-off').touch()
        self.assertEqual(self.ring(), [])
        self.assertIn('bell-off', (self.state/'coordinator-turn-end.log').read_text())

    def test_missing_malformed_and_legacy_records_skip(self):
        for data in ['', self.base.split('handback:')[0], self.base+'handback: broken\n',
                     self.base+f'disposition: {HB} typo 2026-11-09T05:43:00Z\n']:
            self.record.write_text(data); self.assertEqual(self.ring(), [])
        self.record.unlink();self.assertEqual(self.ring(), [])
        self.assertIn('skip', (self.state/'coordinator-turn-end.log').read_text())

    def test_wrong_identity_cwd_and_event_skip(self):
        for key, value in [('thread-id','00000000-0000-0000-0000-000000000000'),
                           ('thread-id',TURN),('cwd','/tmp/other'),('type','other')]:
            old=self.payload[key];self.payload[key]=value;self.assertEqual(self.ring(), []);self.payload[key]=old

    def test_failed_notifier_logged_and_not_retried(self):
        self.env['FAIL_NOTIFY']='1'
        self.assertEqual(len(self.ring()), 1);self.assertEqual(len(self.ring()), 1)
        self.assertIn('notify_failed', (self.state/'coordinator-turn-end.log').read_text())

    def test_new_handback_can_alert_after_previous_completed(self):
        self.record.write_text(self.base+f'disposition: {HB} completed 2026-11-09T05:43:00Z\n'
                               +'handback: next-handback 2026-11-09T05:44:00Z\n')
        calls=self.ring();self.assertEqual(len(calls),1);self.assertIn('next-handback',calls[0])

    def test_planted_missing_dedup_is_caught(self):
        mutant=self.root/'mutant.sh'
        text=SCRIPT.read_text();needle='if key in seen.read().splitlines():'
        self.assertIn(needle,text);mutant.write_text(text.replace(needle,'if False: # planted dedup defect'))
        self.assertEqual(len(self.ring(mutant)),1)
        # The required "second invocation still one" assertion must fail for the mutant.
        with self.assertRaises(AssertionError): self.assertEqual(len(self.ring(mutant)),1)

    def stop(self, active, turn=TURN):
        payload={'hook_event_name':'Stop','session_id':THREAD,'turn_id':turn,
                 'cwd':str(self.root),'stop_hook_active':active,'last_assistant_message':'QA CONCERNS; pending'}
        return subprocess.run(['bash',str(SCRIPT),str(self.root),'--stop'], input=json.dumps(payload),
                              env=self.env, capture_output=True,text=True)

    def test_stop_blocks_once_then_alerts_without_second_block(self):
        first=self.stop(False);self.assertEqual(first.returncode,0)
        decision=json.loads(first.stdout);self.assertEqual(decision['decision'],'block')
        self.assertIn(HB,decision['reason']);self.assertFalse(self.calls.exists())
        # The continuation turn Codex creates carries a NEW turn_id with stop_hook_active=true:
        # the loop guard must be the flag, not the per-turn dedup file.
        second=self.stop(True, '32345678-1234-4234-8234-123456789abc');self.assertEqual(second.returncode,0);self.assertEqual(second.stdout,'')
        self.assertEqual(len(self.calls.read_text().splitlines()),1)
        self.stop(True, '42345678-1234-4234-8234-123456789abc');self.assertEqual(len(self.calls.read_text().splitlines()),1)

    def test_stop_duplicate_false_cannot_loop(self):
        self.assertEqual(json.loads(self.stop(False).stdout)['decision'],'block')
        self.assertEqual(self.stop(False).stdout,'')

    def test_stop_clean_and_pause_and_bell_off_do_not_block(self):
        for state in ['completed','owner_paused','worker_running','external_wait','idle']:
            self.record.write_text(self.base+f'disposition: {HB} {state} 2026-11-09T05:43:00Z\n')
            self.assertEqual(self.stop(False).stdout,'');self.assertFalse(self.calls.exists())
        self.record.write_text(self.base);self.state.mkdir(parents=True,exist_ok=True);(self.state/'bell-off').touch()
        self.assertEqual(self.stop(False).stdout,'');self.assertFalse(self.calls.exists())


if __name__ == '__main__': unittest.main()
