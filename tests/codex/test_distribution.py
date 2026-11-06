"""Real shell/bootstrap boundary with a local tagged release; no network/public release."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]

class DistributionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.source = self.base / 'source'
        self.source.mkdir()
        for name in ('install.sh', 'get.sh', 'astragentic.sh'):
            shutil.copy2(ROOT / name, self.source / name)
        shutil.copytree(ROOT / 'runtimes/codex', self.source / 'runtimes/codex', ignore=shutil.ignore_patterns('__pycache__'))
        (self.source / 'VERSION').write_text('6.0.0\n')
        (self.source / 'RELEASE-NOTES.md').write_text('# Astragentic 6.0.0\nTest fixture only.\n')
        self.project = self.base / 'old project'
        self.project.mkdir()
        self.run_cmd(['git', 'init', '-q'], self.project)
        self.legacy = {'.astraler/state/applied-version': b'5.1.4\n', '.claude/settings.json': b'{"owner":true}\n', '.agents/orchestrator.md': b'owner legacy models\n', 'AGENTS.md': b'Project instructions\n'}
        for name, data in self.legacy.items():
            p = self.project / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(data)
        old_wrapper = (ROOT / 'tests/codex/fixtures/legacy-5.1.4-astragentic.sh').read_bytes()
        for name in ('.astraler/astragentic.sh', '.astraler/releases/5.1.4/astragentic.sh'):
            path = self.project / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(old_wrapper)
        self.env = dict(os.environ, ASTRAGENTIC_REPO=str(self.source), ASTRAGENTIC_CACHE=str(self.base / 'cache'))

    def tearDown(self): self.temp.cleanup()

    def run_cmd(self, argv, cwd=None, ok=True):
        result = subprocess.run(argv, cwd=cwd or self.project, env=getattr(self, 'env', None), text=True, capture_output=True)
        if ok: self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def install(self, *args, ok=True):
        return self.run_cmd(['bash', str(self.source / 'install.sh'), str(self.project), '--runtime', 'codex', *args], ok=ok)

    def test_stage_prompt_apply_and_owner_preservation(self):
        self.install('--plan')
        self.assertFalse((self.project / '.astraler/codex').exists())
        out = self.install()
        self.assertIn('ADAPT-HARNESS-CODEX.md', out.stdout)
        self.assertFalse((self.project / '.codex').exists())
        staged = self.project / '.astraler/codex/releases/6.0.0/install.sh'
        self.run_cmd(['bash', str(staged), str(self.project), '--runtime', 'codex', '--apply'])
        wrapper = self.project / '.astraler/astragentic.sh'
        self.assertIn('adapted: none', self.run_cmd(['bash', str(wrapper), 'version', '--runtime', 'codex']).stdout)
        self.run_cmd(['bash', str(wrapper), 'doctor', '--runtime', 'codex'])
        for name, data in self.legacy.items(): self.assertEqual((self.project / name).read_bytes(), data)
        config = self.project / '.agents/orchestrator-for-codex.md'
        config.write_text(config.read_text() + '\nOwner note.\n')
        before = config.read_bytes()
        self.install('--apply')
        self.assertEqual(config.read_bytes(), before)
        owned = self.project / '.codex/DISPATCH.md'
        owned.write_text('owner edit')
        self.assertNotEqual(self.install('--apply', ok=False).returncode, 0)
        self.assertEqual(owned.read_text(), 'owner edit')

    def test_bootstrap_tag_and_wrapper_update(self):
        self.run_cmd(['git', 'init', '-q'], self.source)
        self.run_cmd(['git', 'add', '.'], self.source)
        self.run_cmd(['git', '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'fixture'], self.source)
        self.run_cmd(['git', 'tag', 'v6.0.0'], self.source)
        result = self.run_cmd(['bash', str(self.source / 'get.sh'), 'latest', '--runtime', 'codex'])
        self.assertIn('ADAPT-HARNESS-CODEX.md', result.stdout)
        self.assertFalse((self.project / '.codex').exists())
        self.install('--apply')
        self.run_cmd(['bash', str(self.project / '.astraler/astragentic.sh'), 'update', '--runtime', 'codex'])
        (self.source / 'VERSION').write_text('6.0.1\n')
        (self.source / 'RELEASE-NOTES.md').write_text('# Astragentic 6.0.1\nUpgrade fixture.\n')
        dispatch = self.source / 'runtimes/codex/.codex/DISPATCH.md'
        dispatch.write_text(dispatch.read_text() + '\nUpgrade fixture.\n')
        self.run_cmd(['git', 'add', '.'], self.source)
        self.run_cmd(['git', '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'upgrade fixture'], self.source)
        self.run_cmd(['git', 'tag', 'v6.0.1'], self.source)
        self.run_cmd(['bash', str(self.project / '.astraler/astragentic.sh'), 'update', '--runtime', 'codex', '--apply'])
        self.assertEqual((self.project / '.astraler/codex/state/installed-version').read_text(), '6.0.1\n')
        self.assertTrue((self.project / '.codex/DISPATCH.md').read_text().endswith('Upgrade fixture.\n'))
        for name, data in self.legacy.items(): self.assertEqual((self.project / name).read_bytes(), data)


    def test_common_stage_routes_without_owner_runtime_flag(self):
        for name in ('harness', 'prompts'):
            shutil.copytree(ROOT / name, self.source / name)
        for name in ('README.md', 'check-requirements.sh'):
            shutil.copy2(ROOT / name, self.source / name)
        # Exercise real stage checks; skip recursive legacy selftest inside installer.
        self.env['ASTRALER_IN_SELFTEST'] = '1'
        result = self.run_cmd(['bash', str(self.source / 'install.sh'), str(self.project)])
        self.assertIn('/ADAPT-RUNTIME.md completely', result.stdout)
        release = self.project / '.astraler/releases/6.0.0'
        self.assertTrue((release / 'ADAPT-HARNESS.md').is_file())
        self.assertTrue((release / 'runtimes/codex/ADAPT-HARNESS-CODEX.md').is_file())
        claude_project = self.base / 'fresh legacy project'
        claude_project.mkdir()
        self.run_cmd(['git', 'init', '-q'], claude_project)
        self.run_cmd(['bash', str(release / 'install.sh'), str(claude_project), '--apply'])
        shared_name = 'skills/astragentic-update-install/SKILL.md'
        self.assertEqual((claude_project / '.agents' / shared_name).read_bytes(),
                         (claude_project / '.claude' / shared_name).read_bytes())

        self.assertFalse((self.project / '.codex').exists())
        # What the Codex route executes internally from the common release.
        self.run_cmd(['bash', str(release / 'install.sh'), str(self.project), '--runtime', 'codex', '--apply'])
        installed = self.project / '.agents/skills/astragentic-update-install/SKILL.md'
        self.assertEqual(installed.read_bytes(), (ROOT / 'harness/.agents/skills/astragentic-update-install/SKILL.md').read_bytes())
        for name, data in self.legacy.items(): self.assertEqual((self.project / name).read_bytes(), data)

    def test_custom_wrapper_is_preserved_before_apply(self):
        wrapper = self.project / '.astraler/astragentic.sh'
        wrapper.write_text('# owner customization')
        self.assertNotEqual(self.install('--plan', ok=False).returncode, 0)
        self.assertNotEqual(self.install('--apply', ok=False).returncode, 0)
        self.assertEqual(wrapper.read_text(), '# owner customization')
        self.assertFalse((self.project / '.codex').exists())

    def test_immutable_and_unsafe_staging(self):
        self.install()
        (self.source / 'runtimes/codex/README.md').write_text('changed release')
        self.assertNotEqual(self.install(ok=False).returncode, 0)
        self.assertFalse((self.project / '.codex').exists())

if __name__ == '__main__': unittest.main()
