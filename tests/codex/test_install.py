import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'runtimes/codex'))
from install import operate


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='astra install ')
        self.project = Path(self.tmp.name).resolve()
        subprocess.run(['git', 'init', '-q', str(self.project)], check=True)

    def tearDown(self):
        self.tmp.cleanup()

    def test_install_upgrade_launch_and_uninstall_preserve_owner_and_claude(self):
        old_skill = self.project / '.agents/skills/astra-to-spec/SKILL.md'
        old_skill.parent.mkdir(parents=True)
        old_skill.write_text('existing runtime skill')
        claude = self.project / '.claude/skills/astra-to-spec/SKILL.md'
        claude.parent.mkdir(parents=True)
        claude.write_text('existing Claude contract')
        agents = self.project / 'AGENTS.md'
        agents.write_text('owner instructions')
        operate(self.project, 'install', True)
        merge = self.project / '.codex/astragentic/merge.py'
        self.assertEqual(merge.read_bytes(), (ROOT / 'runtimes/codex/merge.py').read_bytes())
        subprocess.run([sys.executable, str(merge), '--help'], check=True, capture_output=True)
        mapping = self.project / '.codex/astragentic/skill-map.json'
        self.assertEqual(len(json.loads(mapping.read_text())), 20)
        config = self.project / '.agents/orchestrator-for-codex.md'
        config.write_text(config.read_text().replace('| thomas | gpt-6-astra | medium |',
                                                   '| thomas | gpt-6-astra | high |'))
        operate(self.project, 'install', True)
        self.assertEqual(operate(self.project, 'doctor')['status'], 'files-intact')
        result = subprocess.run([sys.executable, str(self.project / '.codex/astragentic/launch.py'),
                                 'thomas', '--project', str(self.project), '--dry-run'],
                                capture_output=True, text=True, check=True)
        data = json.loads(result.stdout)
        self.assertIn('model_reasoning_effort="high"', data['argv'])
        self.assertEqual(data['contract'], str(self.project / '.codex/roles/thomas.md'))
        operate(self.project, 'uninstall', True)
        self.assertTrue(config.is_file())
        self.assertEqual(old_skill.read_text(), 'existing runtime skill')
        self.assertEqual(claude.read_text(), 'existing Claude contract')
        self.assertEqual(agents.read_text(), 'owner instructions')
        self.assertFalse((self.project / '.codex/astragentic/launch.py').exists())
        self.assertFalse(mapping.exists())
        self.assertFalse(merge.exists())

    def test_shared_skill_reuses_legacy_copy_without_claiming_or_removing_it(self):
        source = ROOT / 'harness/.agents/skills/astragentic-update-install/SKILL.md'
        mirror = ROOT / 'harness/.claude/skills/astragentic-update-install/SKILL.md'
        bundled = ROOT / 'runtimes/codex/.agents/skills/astragentic-update-install/SKILL.md'
        self.assertEqual(source.read_bytes(), mirror.read_bytes())
        self.assertEqual(source.read_bytes(), bundled.read_bytes())
        shared = self.project / '.agents/skills/astragentic-update-install/SKILL.md'
        shared.parent.mkdir(parents=True)
        shared.write_bytes(source.read_bytes())
        operate(self.project, 'install', True)
        operate(self.project, 'doctor')
        operate(self.project, 'uninstall', True)
        self.assertEqual(shared.read_bytes(), source.read_bytes())

    def test_shared_skill_migration_keeps_ownership_and_mirrors(self):
        source = ROOT / 'runtimes/codex/.agents/skills/astragentic-update-install/SKILL.md'
        shared = self.project / '.agents/skills/astragentic-update-install/SKILL.md'
        mirror = self.project / '.claude/skills/astragentic-update-install/SKILL.md'
        prior = b'pristine previous release skill'
        for path in (shared, mirror):
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(prior)
        with self.assertRaisesRegex(ValueError, 'unowned path'):
            operate(self.project, 'install', True)
        self.assertEqual(shared.read_bytes(), prior)
        self.assertFalse((self.project / '.codex').exists())
        # Semantic migration after baseline comparison; the installer never guesses.
        for path in (shared, mirror):
            self.assertEqual(path.read_bytes(), prior)
            path.write_bytes(source.read_bytes())
        operate(self.project, 'install', True)
        operate(self.project, 'doctor')
        operate(self.project, 'uninstall', True)
        self.assertEqual(shared.read_bytes(), source.read_bytes())
        self.assertEqual(mirror.read_bytes(), shared.read_bytes())

    def test_dry_run_does_not_create_files(self):
        result = operate(self.project, 'install')
        self.assertFalse(result['apply'])
        self.assertFalse((self.project / '.codex').exists())
        self.assertFalse((self.project / '.agents').exists())

    def test_symlink_parent_rejected_even_inside_checkout(self):
        owner = self.project / 'owner-files'
        owner.mkdir()
        (self.project / '.codex').symlink_to(owner, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, 'symlink'):
            operate(self.project, 'install', True)
        self.assertEqual(list(owner.iterdir()), [])

    def test_invalid_manifest_rejected_without_writes(self):
        manifest = self.project / '.codex/astragentic/manifest.json'
        manifest.parent.mkdir(parents=True)
        for invalid in ({'schema': 2, 'files': {}}, {'schema': 1, 'files': []},
                        {'schema': 1, 'files': {'.codex/roles/thomas.md': 4}}):
            manifest.write_text(json.dumps(invalid))
            with self.assertRaisesRegex(ValueError, 'manifest'):
                operate(self.project, 'install', True)
            self.assertFalse((self.project / '.agents').exists())

    def test_non_directory_parent_refused_before_any_install_write(self):
        collision = self.project / '.codex/agents'
        collision.parent.mkdir()
        collision.write_text('owner file')
        with self.assertRaisesRegex(ValueError, 'non-directory parent'):
            operate(self.project, 'install', True)
        self.assertEqual(collision.read_text(), 'owner file')
        self.assertFalse((self.project / '.agents').exists())
        self.assertEqual(list(collision.parent.iterdir()), [collision])

    def test_source_launcher_prefers_installed_contracts(self):
        operate(self.project, 'install', True)
        result = subprocess.run([sys.executable, str(ROOT / 'runtimes/codex/launch.py'),
                                 'ba', '--project', str(self.project), '--dry-run'],
                                capture_output=True, text=True, check=True)
        data = json.loads(result.stdout)
        self.assertEqual(data['contract'], str(self.project / '.codex/roles/ba.md'))
        self.assertIn(str(self.project / '.codex/roles/common.md'), data['argv'][-1])
        self.assertIn(str(self.project / '.codex/DISPATCH.md'), data['argv'][-1])

    def test_collision_refuses_before_any_install_write(self):
        collision = self.project / '.codex/roles/thomas.md'
        collision.parent.mkdir(parents=True)
        collision.write_text('owner role')
        with self.assertRaisesRegex(ValueError, 'unowned path'):
            operate(self.project, 'install', True)
        self.assertFalse((self.project / '.agents').exists())
        self.assertEqual(collision.read_text(), 'owner role')

    def test_local_edit_blocks_upgrade_and_uninstall_without_deleting_it(self):
        operate(self.project, 'install', True)
        changed = self.project / '.codex/roles/thomas.md'
        changed.write_text('owner customized role')
        for action in ('install', 'uninstall', 'doctor'):
            with self.assertRaisesRegex(ValueError, 'changed'):
                operate(self.project, action, True)
        self.assertEqual(changed.read_text(), 'owner customized role')


if __name__ == '__main__': unittest.main()
