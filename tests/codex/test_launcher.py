import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import socket
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[2]
CLI = ROOT / 'runtimes/codex/launch.py'

class LauncherTests(unittest.TestCase):
    def run_cli(self, *args, env=None):
        return subprocess.run([sys.executable, str(CLI), *args], text=True, capture_output=True, env=env)

    def test_explicit_unix_endpoint_reaches_native_argv_without_permission_changes(self):
        with tempfile.TemporaryDirectory() as d:
            endpoint = Path(d) / 'codex socket'
            with socket.socket(socket.AF_UNIX) as listener:
                listener.bind(str(endpoint))
                uri = 'unix://' + str(endpoint)
                result = self.run_cli('thomas', '--project', str(ROOT), '--remote', uri, '--dry-run')
                self.assertEqual(result.returncode, 0, result.stderr)
                data = json.loads(result.stdout)
                self.assertEqual(data['lifecycle_endpoint'], uri)
                self.assertEqual(data['argv'][data['argv'].index('--remote') + 1], uri)
                self.assertIn('both queue directions', data['argv'][-1])
                self.assertNotIn('--dangerously-bypass-approvals-and-sandbox', data['argv'])
                self.assertNotIn('resume', data['argv'])

    def test_remote_rejects_unverified_address_shapes_and_non_socket(self):
        for value in ['', 'unix://relative', 'unix:///nonexistent-astra.sock', 'ws://localhost:1234',
                      'unix://' + str(CLI)]:
            result = self.run_cli('thomas', '--project', str(ROOT), '--remote', value, '--dry-run')
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('existing Codex socket', result.stderr)

    def test_owner_models_and_no_config_or_permission_overrides(self):
        with tempfile.TemporaryDirectory(prefix='astra project ') as d:
            subprocess.run(['git','init','-q',d], check=True)
            for role,model,effort in [('thomas','gpt-6-astra','medium'),('ba','gpt-6-astra','high'),('quick-builder','gpt-6-astra','low')]:
                result=self.run_cli(role,'--project',d,'--dry-run')
                self.assertEqual(result.returncode,0,result.stderr)
                data=json.loads(result.stdout); argv=data['argv']
                self.assertFalse(data['overlay_installed'])
                self.assertIn('no installed Astragentic overlay', argv[-1])
                self.assertEqual(argv[argv.index('--model')+1],model)
                self.assertIn('model_reasoning_effort='+json.dumps(effort),argv)
                self.assertNotIn('--sandbox',argv)
                self.assertEqual([argv[i + 1] for i, value in enumerate(argv) if value == '-c'],
                                 ['model_reasoning_effort=' + json.dumps(effort)])
                self.assertFalse(any('developer_instructions=' in a for a in argv))
                self.assertIn('Read the Codex role contract',argv[-1])
                self.assertEqual(list(Path(d).iterdir()),[Path(d)/'.git'])

    def test_herdr_requires_managed_environment_and_existing_absolute_socket(self):
        with tempfile.TemporaryDirectory() as d:
            regular = Path(d) / 'regular.sock'
            regular.write_text('owner file')
            missing_env = {k: value for k, value in os.environ.items()
                           if k not in ('HERDR_ENV', 'HERDR_SOCKET_PATH')}
            missing = self.run_cli('thomas', '--project', str(ROOT), '--herdr', '--dry-run', env=missing_env)
            self.assertNotEqual(missing.returncode, 0)
            self.assertIn('HERDR_ENV=1', missing.stderr)
            for managed, path in [('0', str(regular)), ('1', ''), ('1', 'relative.sock'),
                                  ('1', str(Path(d) / 'missing.sock')), ('1', str(regular))]:
                with self.subTest(managed=managed, path=path):
                    env = {**os.environ, 'HERDR_ENV': managed, 'HERDR_SOCKET_PATH': path}
                    result = self.run_cli('thomas', '--project', str(ROOT), '--herdr', '--dry-run', env=env)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn('--herdr requires', result.stderr)
                    self.assertFalse(result.stdout)
            self.assertEqual(regular.read_text(), 'owner file')

    def test_herdr_exec_emits_only_measured_native_profile_without_writes(self):
        # Fake Codex captures the real launcher exec boundary; no inference,
        # configuration activation or live Herdr call occurs here.
        with tempfile.TemporaryDirectory(prefix='ah-') as d:
            root = Path(d)
            project = root / 'project'
            subprocess.run(['git', 'init', '-q', str(project)], check=True)
            sock_path = root / 'herdr.api.sock'
            with socket.socket(socket.AF_UNIX) as unix:
                unix.bind(str(sock_path))
                binary = root / 'codex'
                binary.write_text('#!' + sys.executable + '\nimport json, sys\nprint(json.dumps(sys.argv[1:]))\n')
                binary.chmod(0o755)
                before = sorted(str(p.relative_to(project)) for p in project.rglob('*'))
                env = {**os.environ, 'HERDR_ENV': '1', 'HERDR_SOCKET_PATH': str(sock_path),
                       'PATH': str(root) + os.pathsep + os.environ['PATH']}
                result = self.run_cli('thomas', '--project', str(project), '--herdr', env=env)
                self.assertEqual(result.returncode, 0, result.stderr)
                argv = json.loads(result.stdout)
                values = [argv[i + 1] for i, value in enumerate(argv) if value == '-c']
                self.assertEqual(values[:3], ['model_reasoning_effort="medium"',
                                             'default_permissions="astragentic-local"',
                                             'features.network_proxy=true'])
                self.assertEqual(len(values), 4)
                self.assertEqual(tomllib.loads(values[3]), {'permissions': {'astragentic-local': {
                    'extends': ':workspace', 'network': {'enabled': True, 'unix_sockets': {
                        str(sock_path): 'allow'}}}}})
                self.assertEqual(argv[argv.index('--model') + 1], 'gpt-6-astra')
                self.assertNotIn('--sandbox', argv)
                self.assertEqual(before, sorted(str(p.relative_to(project)) for p in project.rglob('*')))
                self.assertTrue(sock_path.is_socket())

    def test_yolo_exec_explicit_opt_in_and_dispatch_policy(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            project = root / 'project'
            subprocess.run(['git', 'init', '-q', str(project)], check=True)
            binary = root / 'codex'
            binary.write_text('#!' + sys.executable + '\nimport json, sys\nprint(json.dumps(sys.argv[1:]))\n')
            binary.chmod(0o755)
            env = {**os.environ, 'PATH': str(root) + os.pathsep + os.environ['PATH']}
            for role in ('thomas', 'ba', 'quick-builder'):
                result = self.run_cli(role, '--project', str(project), '--yolo', env=env)
                self.assertEqual(result.returncode, 0, result.stderr)
                argv = json.loads(result.stdout)
                self.assertEqual(argv.count('--dangerously-bypass-approvals-and-sandbox'), 1)
                self.assertIn('Worker CLI permission mode: yolo', argv[-1])
                self.assertNotIn('default_permissions="astragentic-local"', argv)
            normal = self.run_cli('thomas', '--project', str(project), '--dry-run', env=env)
            self.assertEqual(normal.returncode, 0, normal.stderr)
            argv = json.loads(normal.stdout)['argv']
            self.assertNotIn('--dangerously-bypass-approvals-and-sandbox', argv)
            self.assertIn('Worker CLI permission mode: default', argv[-1])
            self.assertEqual(list(project.iterdir()), [project / '.git'])

    def test_yolo_and_scoped_herdr_profile_conflict(self):
        result = self.run_cli('thomas', '--project', str(ROOT), '--yolo', '--herdr', '--dry-run')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('not allowed with argument', result.stderr)
        self.assertFalse(result.stdout)

    def test_documented_worker_dispatch_passes_permission_flags_at_herdr_boundary(self):
        document = (ROOT / 'runtimes/codex/.codex/DISPATCH.md').read_text()
        blocks = [part.split('```', 1)[0] for part in document.split('```sh\n')[1:]]
        script = next(block for block in blocks if 'PERMISSION_ARGS=()' in block)
        with tempfile.TemporaryDirectory() as d:
            binary = Path(d) / 'herdr'
            binary.write_text('#!' + sys.executable + '\nimport json, sys\nprint(json.dumps(sys.argv[1:]))\n')
            binary.chmod(0o755)
            env = {**os.environ, 'PATH': d + os.pathsep + os.environ['PATH'],
                   'DISPATCH_ID': 'worker-1', 'PANE_ID': 'w1:p1', 'WORKTREE': '/tmp/tree with spaces',
                   'MODEL': 'gpt-6.1-sol', 'EFFORT': 'medium', 'BOOTSTRAP': 'Read /tmp/bootstrap.md'}
            for mode in ('default', 'yolo'):
                result = subprocess.run(['bash', '-c', script], env={**env, 'WORKER_PERMISSION_MODE': mode},
                                        text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                argv = json.loads(result.stdout)
                native = argv[argv.index('--') + 1:]
                self.assertEqual('--dangerously-bypass-approvals-and-sandbox' in native, mode == 'yolo')
                self.assertEqual(native[native.index('--cd') + 1], '/tmp/tree with spaces')
                self.assertEqual(native[-1], 'Read /tmp/bootstrap.md')
            endpoint = Path(d) / 'endpoint.sock'
            with socket.socket(socket.AF_UNIX) as listener:
                listener.bind(str(endpoint))
                uri = 'unix://' + str(endpoint)
                result = subprocess.run(['bash', '-c', script],
                                        env={**env, 'WORKER_PERMISSION_MODE': 'yolo', 'CODEX_LIFECYCLE_ENDPOINT': uri},
                                        text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                argv = json.loads(result.stdout)
                self.assertEqual(argv[argv.index('--remote') + 1], uri)
                self.assertIn('--dangerously-bypass-approvals-and-sandbox', argv)
            result = subprocess.run(['bash', '-c', script],
                                    env={**env, 'WORKER_PERMISSION_MODE': 'default', 'CODEX_LIFECYCLE_ENDPOINT': 'unix:///missing'},
                                    text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(result.stdout)
            for mode in ('', 'typo'):
                result = subprocess.run(['bash', '-c', script], env={**env, 'WORKER_PERMISSION_MODE': mode},
                                        text=True, capture_output=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(result.stdout)

    def test_dispatch_role_is_not_owner_launch(self):
        self.assertNotEqual(self.run_cli('builder','--project',str(ROOT),'--dry-run').returncode,0)

    def test_exec_uses_project_assignment_and_project_cwd(self):
        # Execute the real launcher process with a fake CLI at the PATH boundary.
        # This measures argv/cwd, not model inference or Codex role compliance.
        with tempfile.TemporaryDirectory(prefix='astra exec ') as d:
            root = Path(d)
            project = root / 'project with spaces'
            subprocess.run(['git', 'init', '-q', str(project)], check=True)
            nested = project / 'nested'
            nested.mkdir()
            config = project / '.agents/orchestrator-for-codex.md'
            config.parent.mkdir()
            config.write_text('## Model assignments\n| Role | Model | Effort |\n|---|---|---|\n| thomas | gpt-6-astra | high |\n')
            binary = root / 'codex'
            binary.write_text('#!' + sys.executable + '\nimport json, os, sys\nprint(json.dumps({"argv": sys.argv[1:], "cwd": os.getcwd()}))\n')
            binary.chmod(0o755)
            result = subprocess.run([sys.executable, str(CLI), 'thomas', '--project', str(nested)],
                                    env={**os.environ, 'PATH': str(root) + os.pathsep + os.environ['PATH']},
                                    text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            output = json.loads(result.stdout)
            self.assertEqual(output['cwd'], str(project.resolve()))
            self.assertIn('model_reasoning_effort="high"', output['argv'])
            self.assertIn(str(config.resolve()), output['argv'][-1])
            self.assertIn('source-only role launch', result.stderr)

    def test_explicit_assignment_overrides_project(self):
        with tempfile.TemporaryDirectory() as d:
            project = Path(d) / 'project'
            subprocess.run(['git', 'init', '-q', str(project)], check=True)
            cfg = Path(d) / 'custom.md'
            cfg.write_text('## Model assignments\n| Role | Model | Effort |\n|---|---|---|\n| thomas | gpt-6.1-sol | medium |\n')
            result = self.run_cli('thomas', '--project', str(project), '--orchestrator', str(cfg), '--dry-run')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('gpt-6.1-sol', json.loads(result.stdout)['argv'])

    def test_missing_project_rejected(self):
        self.assertNotEqual(self.run_cli('ba','--project','/nonexistent-astra-probe','--dry-run').returncode,0)

    def test_installed_helpers_must_match_selected_orchestrator(self):
        with tempfile.TemporaryDirectory() as d:
            project = Path(d) / 'project'
            subprocess.run(['git', 'init', '-q', str(project)], check=True)
            subprocess.run([sys.executable, str(CLI.parent / 'install.py'), 'install',
                            '--project', str(project), '--apply'], check=True, capture_output=True)
            cfg = Path(d) / 'custom.md'
            config = (project / '.agents/orchestrator-for-codex.md').read_text()
            cfg.write_text(config.replace('| thomas | gpt-6-astra | medium |',
                                          '| thomas | gpt-6.1-sol | medium |'))
            args = ('thomas', '--project', str(project), '--orchestrator', str(cfg), '--dry-run')
            self.assertEqual(self.run_cli(*args).returncode, 0)
            profiles = {p: p.read_bytes() for p in (project / '.codex/agents').glob('*.toml')}
            cfg.write_text(cfg.read_text().replace('| reviewer | gpt-6-astra | high |',
                                                   '| reviewer | gpt-6.1-sol | high |'))
            rejected = self.run_cli(*args)
            self.assertNotEqual(rejected.returncode, 0)
            self.assertIn('helpers do not match selected orchestrator', rejected.stderr)
            self.assertEqual(profiles, {p: p.read_bytes() for p in profiles})

    def test_duplicate_assignment_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            cfg=Path(d)/'orchestrator.md'
            cfg.write_text('## Model assignments\n| Role | Model | Effort |\n|---|---|---|\n| ba | gpt-6-astra | high |\n| ba | gpt-6-luna | high |\n')
            result=self.run_cli('ba','--project',str(ROOT),'--orchestrator',str(cfg),'--dry-run')
            self.assertNotEqual(result.returncode,0)
            self.assertIn('duplicate',result.stderr)

if __name__=='__main__': unittest.main()
