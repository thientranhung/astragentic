import importlib.util
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('transport', Path(__file__).resolve().parents[2] / 'runtimes/codex/transport.py')
m = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(m)

THREAD = '12345678-1234-4234-8234-123456789abc'

class QueueTests(unittest.TestCase):
    def test_queue_is_not_delivery(self):
        with patch.object(m.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, 'Queued message', 'resume failed')) as run:
            result = m.send(THREAD, 'event-1', 'builder', 'handback', 'quotes " and $(no)\nnext')
        self.assertEqual(result['status'], 'queued_unconfirmed')
        argv = run.call_args.args[0]
        self.assertNotIn('--resume', argv)
        self.assertNotIn('shell', run.call_args.kwargs)
        self.assertIn('$(no)', argv[-1])
        self.assertIn('not owner approval', argv[-1])

    def test_unknown_failure_not_retried(self):
        with patch.object(m.subprocess, 'run', side_effect=subprocess.TimeoutExpired('codex', 10)) as run:
            result = m.send(THREAD, 'event-1', 'builder', 'handback', 'done')
        self.assertEqual(result['status'], 'outcome_unknown')
        self.assertEqual(run.call_count, 1)

    def test_invalid_identity_rejected_before_execution(self):
        for thread in ['--help', 'latest', '', '../x']:
            with self.assertRaises(ValueError):
                m.send(thread, 'event-1', 'builder', 'handback', 'done')

    def test_nonzero_is_unconfirmed(self):
        with patch.object(m.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, '', 'offline')):
            self.assertEqual(m.send(THREAD, 'event-1', 'builder', 'handback', 'done')['status'], 'outcome_unknown')

if __name__ == '__main__':
    unittest.main()
