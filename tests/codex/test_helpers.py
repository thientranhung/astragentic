import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'runtimes/codex'))
import helpers


class HelperTests(unittest.TestCase):
    def test_profiles_parse_and_use_owner_assignments(self):
        with tempfile.TemporaryDirectory() as d:
            config = Path(d) / 'owner.md'
            config.write_text('## Model assignments\n' + ''.join(
                '| ' + role + ' | gpt-6.1-sol | low |\n' for role in helpers.HELPERS))
            profiles = helpers.render(config)
            self.assertEqual(len(profiles), 5)
            for content in profiles.values():
                parsed = tomllib.loads(content)
                self.assertEqual(parsed['model'], 'gpt-6.1-sol')
                self.assertEqual(parsed['model_reasoning_effort'], 'low')
                self.assertNotIn('sandbox_mode', parsed)
                self.assertTrue(parsed['developer_instructions'])

    def test_probe_ignores_prose_and_partial_catalog(self):
        prose = '\n'.join('astragentic_' + r.replace('-', '_') + ': {' for r in helpers.HELPERS)
        self.assertEqual(helpers.discover([{'content': prose}])['status'], 'capability-gap')
        tool = {'type': 'function', 'name': 'spawn_agent', 'parameters': {'properties': {
            'agent_type': {'description': 'Available roles:\nastragentic_reviewer: {'}}}}
        result = helpers.discover([tool])
        self.assertEqual(result['visible'], ['astragentic_reviewer'])
        self.assertEqual(len(result['missing']), 4)
        tool['parameters']['properties']['agent_type']['description'] = prose
        self.assertEqual(helpers.discover([tool])['status'], 'catalog-visible')

    def test_a_probe_that_cannot_run_is_not_a_missing_helper(self):
        # REHEARSAL-609: inside workspace-write the CLI died with EPERM, the wrapper said "failed", and
        # the Builder stopped before work while the same session could spawn the reviewer.
        denied = subprocess.CompletedProcess([], 1, stdout='', stderr='Error: Operation not permitted')
        with tempfile.TemporaryDirectory() as d, mock.patch.object(helpers.subprocess, 'run', return_value=denied):
            result = helpers.probe(Path(d))
        self.assertEqual(result['status'], 'inconclusive')
        self.assertEqual(result['cli_exit'], 1)
        self.assertNotIn('missing', result)
        self.assertNotIn('Operation not permitted', str(result))
        self.assertIn('spawn', result['next_action'])

    def test_missing_assignment_fails_instead_of_fallback(self):
        with tempfile.TemporaryDirectory() as d:
            config = Path(d) / 'empty.md'
            config.write_text('## Model assignments\n')
            with self.assertRaisesRegex(ValueError, 'missing helper'):
                helpers.render(config)


if __name__ == '__main__':
    unittest.main()
