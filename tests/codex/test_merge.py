import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[2] / 'runtimes/codex/merge.py'
spec = importlib.util.spec_from_file_location('merge_boundary', SOURCE)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class MergeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        def git(*args):
            return subprocess.check_output(['git', *args], cwd=self.root, text=True).strip()
        git('init', '-q')
        git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
            '-c', 'core.hooksPath=/dev/null', 'commit', '--allow-empty', '-qm', 'fixture')
        self.head = git('rev-parse', 'HEAD')
        self.body = self.root / 'body.txt'
        self.body.write_text('Review complete\n\nLedger: none\n')
        self.calls = self.root / 'gh-call.json'
        shim = self.root / 'gh'
        shim.write_text('#!' + sys.executable + '\nimport json,sys,pathlib\na=sys.argv[1:]\n'
                       'b=json.load(sys.stdin)\n'
                       'pathlib.Path(' + repr(str(self.calls)) + ').write_text(json.dumps({"argv":a,"payload":b}))\n'
                       'print(json.dumps({"merged":True,"sha":"' + '1'*40 + '"}))\n')
        shim.chmod(0o755)
        self.env = patch.dict(os.environ, {'PATH': str(self.root) + os.pathsep + os.environ['PATH']})
        self.env.start()
        self.addCleanup(self.env.stop)

    def call(self, **kw):
        return m.merge(self.root, 'fixture/project', '42', self.head, 'Merge ticket', self.body, ['Ledger'], **kw)

    def test_missing_empty_duplicate_or_prose_trailer_never_calls_gh(self):
        for body in ['text only', 'text\n\nLedger:\n', 'Ledger: one\nLedger: two\n',
                     'Ledger: none\n\nordinary prose after trailer']:
            with self.subTest(body=body):
                self.body.write_text(body)
                with self.assertRaises(ValueError):
                    self.call(execute=True)
                self.assertFalse(self.calls.exists())

    def test_dry_check_does_not_publish(self):
        self.assertEqual(self.call()['status'], 'message-validated')
        self.assertFalse(self.calls.exists())

    def test_cli_passes_validated_body_and_head_to_gh(self):
        r = subprocess.run([sys.executable, str(SOURCE), '--project', str(self.root),
                            '--repo', 'fixture/project', '--pr', '42', '--head', self.head, '--subject', 'Merge ticket',
                            '--body-file', str(self.body), '--require-trailer', 'Ledger', '--execute'],
                           text=True, capture_output=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        c = json.loads(self.calls.read_text())
        self.assertEqual(c['payload']['commit_message'], self.body.read_text())
        self.assertEqual(c['payload']['sha'], self.head)
        self.assertEqual(c['payload']['merge_method'], 'merge')
        self.assertEqual(c['argv'], ['api', '--hostname', 'github.com', '--method', 'PUT',
                                     'repos/fixture/project/pulls/42/merge', '--input', '-'])
        self.assertNotIn('--admin', c['argv'])
        self.assertNotIn('--auto', c['argv'])
        self.assertEqual(json.loads(r.stdout)['status'], 'merge-api-confirmed')

    def test_wrong_head_blocks_before_publication(self):
        self.head = '0' * 40
        with self.assertRaisesRegex(ValueError, 'HEAD'):
            self.call(execute=True)
        self.assertFalse(self.calls.exists())

    def test_project_validator_refusal_or_message_mutation_blocks(self):
        v = self.root / 'validator'
        for script in ['#!/bin/sh\nexit 1\n', '#!/bin/sh\nprintf changed > "$1"\n']:
            v.write_text(script)
            v.chmod(0o755)
            with self.assertRaises(ValueError):
                self.call(validator=v, execute=True)
            self.assertFalse(self.calls.exists())

    def test_unmerged_malformed_or_queue_refusal_is_not_success(self):
        original = m.run
        for code, response in [(0, '{"merged":false}'), (0, 'invalid json'),
                               (0, '{"merged":true,"sha":""}'),
                               (1, '{"message":"Merge queue required"}')]:
            calls = []
            def command(args, **kwargs):
                if args[0] == 'gh':
                    calls.append(args)
                    return subprocess.CompletedProcess(args, code, response, '')
                return original(args, **kwargs)
            with self.subTest(response=response), patch.object(m, 'run', command):
                r = self.call(execute=True)
            self.assertEqual(r['status'], 'merge-outcome-unconfirmed')
            self.assertNotEqual(r['exit_code'], 0)
            self.assertEqual(len(calls), 1)

    def test_ambiguous_gh_failure_is_not_retried(self):
        original = m.run
        calls = []
        def command(args, **kwargs):
            if args[0] == 'gh':
                calls.append(args)
                return subprocess.CompletedProcess(args, 1, '', 'connection lost')
            return original(args, **kwargs)
        with patch.object(m, 'run', command):
            r = self.call(execute=True)
        self.assertEqual(r['status'], 'merge-outcome-unconfirmed')
        self.assertEqual(len(calls), 1)


if __name__ == '__main__':
    unittest.main()
