import importlib.util
from pathlib import Path
import sys
import tempfile
import tomllib
import unittest

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

    def test_missing_assignment_fails_instead_of_fallback(self):
        with tempfile.TemporaryDirectory() as d:
            config = Path(d) / 'empty.md'
            config.write_text('## Model assignments\n')
            with self.assertRaisesRegex(ValueError, 'missing helper'):
                helpers.render(config)


if __name__ == '__main__':
    unittest.main()
