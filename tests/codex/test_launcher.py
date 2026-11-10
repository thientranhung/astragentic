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
    def test_notify_fallback_is_explicit_thomas_only(self):
        with tempfile.TemporaryDirectory() as d:
            subprocess.run(['git','init','-q',d],check=True)
            ordinary=self.run_cli('thomas','--project',d,'--dry-run')
            self.assertFalse(any(x.startswith('notify=') for x in json.loads(ordinary.stdout)['argv']))
            fallback=self.run_cli('thomas','--project',d,'--coordinator-notify','--dry-run')
            self.assertEqual(fallback.returncode,0,fallback.stderr)
            value=next(x for x in json.loads(fallback.stdout)['argv'] if x.startswith('notify='))
            self.assertEqual(tomllib.loads(value)['notify'], ['bash',str(ROOT/'runtimes/codex/coordinator-turn-end.sh'),str(Path(d).resolve())])
            self.assertNotEqual(self.run_cli('ba','--project',d,'--coordinator-notify','--dry-run').returncode,0)

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
                values = [argv[i + 1] for i, value in enumerate(argv) if value == '-c']
                expected = ['model_reasoning_effort=' + json.dumps(effort)]
                self.assertEqual(values, expected)
                self.assertFalse(any('developer_instructions=' in a for a in argv))
                self.assertIn('Read the Codex role contract',argv[-1])
                self.assertEqual(list(Path(d).iterdir()),[Path(d)/'.git'])

    def test_dispatch_opens_with_the_host_check_as_a_hard_stop(self):
        dispatch = (ROOT / 'runtimes/codex/.codex/DISPATCH.md').read_text()
        self.assertLess(dispatch.index('## The host (6.1.0)'), dispatch.index('## Before launch'))
        self.assertIn('if [ -n "${ORCA_PANE_KEY:-}" ]; then HOST=orca', dispatch)
        self.assertIn('else echo "no host: stop and report to the owner"; exit 2; fi', dispatch)
        self.assertIn('never a fallback', dispatch)
        self.assertRegex(dispatch, r'(?m)^## Orca\b')  # a real section, not the mention in the host paragraph

    def test_herdr_dispatch_text_is_byte_identical_to_6_0_9(self):
        # 6.1.0 adds Orca beside Herdr; the Herdr path nizzy runs on 6.0.9 must not move (owner rule:
        # one host per session, the Herdr text stays as it is).
        old = subprocess.run(['git', '-C', str(ROOT), 'show', 'v6.0.9:runtimes/codex/.codex/DISPATCH.md'], text=True, capture_output=True)
        if old.returncode != 0:
            self.skipTest('no v6.0.9 tag in this checkout')
        start = old.stdout.index('# Run this block with bash (arrays preserve argv boundaries).')
        end = old.stdout.index('The per-worker `-c notify` replaces any global `notify`')
        block = old.stdout[start:end]
        self.assertIn('herdr agent start', block)
        self.assertIn(block, (ROOT / 'runtimes/codex/.codex/DISPATCH.md').read_text())

    def test_launcher_names_its_host_and_refuses_the_other_hosts_flag(self):
        # 6.1.0, owner 2026-11-09: one host per session. The launcher reads the host from its own
        # environment, Orca first, and says so; --herdr inside an Orca pane is refused.
        base = {k: v for k, v in os.environ.items() if k not in ('HERDR_ENV', 'HERDR_SOCKET_PATH', 'ORCA_PANE_KEY')}
        for extra, host in [({'ORCA_PANE_KEY': 'tab:leaf', 'HERDR_ENV': '1'}, 'orca'), ({'HERDR_ENV': '1'}, 'herdr'), ({}, 'none')]:
            with self.subTest(host=host):
                result = self.run_cli('thomas', '--project', str(ROOT), '--dry-run', env={**base, **extra})
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads(result.stdout)['host'], host)
        refused = self.run_cli('thomas', '--project', str(ROOT), '--herdr', '--dry-run',
                               env={**base, 'ORCA_PANE_KEY': 'tab:leaf', 'HERDR_ENV': '1', 'HERDR_SOCKET_PATH': '/tmp/x.sock'})
        self.assertNotEqual(refused.returncode, 0)
        self.assertIn('one host per session', refused.stderr)

    def test_herdr_requires_managed_environment_and_existing_absolute_socket(self):
        with tempfile.TemporaryDirectory() as d:
            regular = Path(d) / 'regular.sock'
            regular.write_text('owner file')
            missing_env = {k: value for k, value in os.environ.items()
                           if k not in ('HERDR_ENV', 'HERDR_SOCKET_PATH', 'ORCA_PANE_KEY')}
            missing = self.run_cli('thomas', '--project', str(ROOT), '--herdr', '--dry-run', env=missing_env)
            self.assertNotEqual(missing.returncode, 0)
            self.assertIn('HERDR_ENV=1', missing.stderr)
            for managed, path in [('0', str(regular)), ('1', ''), ('1', 'relative.sock'),
                                  ('1', str(Path(d) / 'missing.sock')), ('1', str(regular))]:
                with self.subTest(managed=managed, path=path):
                    env = {**os.environ, 'HERDR_ENV': managed, 'HERDR_SOCKET_PATH': path}
                    env.pop('ORCA_PANE_KEY', None)  # these are Herdr cases; the suite may itself run in an Orca pane
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
                env = {**os.environ, 'HERDR_ENV': '1', 'ORCA_PANE_KEY': '', 'HERDR_SOCKET_PATH': str(sock_path),
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
                   'MODEL': 'gpt-6.1-sol', 'EFFORT': 'medium', 'BOOTSTRAP': 'Read /tmp/bootstrap.md',
                   'THOMAS_UUID': '01a1bb4e-972f-7f10-baf8-be8979a45637', 'AGENT_NAME': 'builder-tra-1345'}
            bell = ['bash', '/tmp/tree with spaces/.codex/astragentic/turn-end.sh', 'worker-1',
                    '01a1bb4e-972f-7f10-baf8-be8979a45637']

            def notify_of(native):
                values = [native[i + 1] for i, value in enumerate(native) if value == '-c' and native[i + 1].startswith('notify=')]
                self.assertEqual(len(values), 1, native)
                return tomllib.loads('v=' + values[0].partition('=')[2])['v']

            for mode in ('default', 'yolo'):
                result = subprocess.run(['bash', '-c', script], env={**env, 'WORKER_PERMISSION_MODE': mode},
                                        text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                argv = json.loads(result.stdout)
                native = argv[argv.index('--') + 1:]
                self.assertEqual('--dangerously-bypass-approvals-and-sandbox' in native, mode == 'yolo')
                self.assertEqual(native[native.index('--cd') + 1], '/tmp/tree with spaces')
                self.assertEqual(native[-1], 'Read /tmp/bootstrap.md')
                self.assertEqual(notify_of(native), bell)
                self.assertNotIn('--resume', native)
                # The Herdr display name comes from the naming table (6.0.7); the dispatch id stays the
                # bell/record key. Nizzy's sidebar showed the raw id twice (owner, 2026-11-09).
                self.assertEqual(argv[argv.index('start') + 1], 'builder-tra-1345')
                self.assertNotIn('worker-1', argv[:argv.index('--')])
            missing_name = {k: v for k, v in env.items() if k != 'AGENT_NAME'}
            result = subprocess.run(['bash', '-c', script], env={**missing_name, 'WORKER_PERMISSION_MODE': 'default'},
                                    text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(result.stdout)
            self.assertIn('AGENT_NAME', result.stderr)
            missing_uuid = {k: v for k, v in env.items() if k != 'THOMAS_UUID'}
            result = subprocess.run(['bash', '-c', script], env={**missing_uuid, 'WORKER_PERMISSION_MODE': 'default'},
                                    text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(result.stdout)
            self.assertIn('THOMAS_UUID', result.stderr)
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
                self.assertEqual(notify_of(argv[argv.index('--') + 1:]), bell + [uri])
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

    def test_review_lives_in_the_builder_session_not_a_thomas_pane(self):
        dispatch = (ROOT / 'runtimes/codex/.codex/DISPATCH.md').read_text()
        thomas = (ROOT / 'runtimes/codex/.codex/roles/thomas.md').read_text()
        builder = (ROOT / 'runtimes/codex/.codex/roles/builder.md').read_text()
        # 6.0.3 to 6.0.8 shipped reviewer panes (rev:TRA-1345:correct) and "separate reviewer
        # sessions"; nizzy paid 25 briefs / 7 review rounds / 0 merges for 2 tickets in 16 h.
        self.assertNotIn('rev:TRA', dispatch)
        # REHEARSAL-609: Builder stopped on a failed probe while its session could spawn the reviewer.
        common = (ROOT / 'runtimes/codex/.codex/roles/common.md').read_text()
        self.assertIn('Before stopping for a missing helper, attempt one real `spawn_agent` call', common)
        self.assertNotIn('agent-type inventory', common)
        self.assertNotIn('helper configuration', builder + dispatch)
        self.assertIn('Helpers are not a startup check', builder)
        # 4 of 4 rehearsal Builders stopped at review; both told to call the tool did. The inventory
        # passage and two added sentences did not help, so the check is gone and the step names the call.
        review = (ROOT / 'runtimes/codex/.agents/skills/codex-astra-review/SKILL.md').read_text()
        self.assertIn('correctness via `$review-agent`', builder)
        # A6: this line in the brief, 0 corrections, code to QA in 7m13s, after 5 stops of 5 without it.
        self.assertIn('spawn three astragentic_reviewer helpers yourself with\nspawn_agent', dispatch)
        self.assertIn('Use $review-agent to review <base>..<head>', review)
        self.assertNotIn('codex review', review)
        self.assertIn('A failed commit or push is a blocker', builder)
        self.assertRegex(dispatch, r"workspace-write sandbox keeps `\.git` read-only")
        self.assertNotRegex(dispatch + thomas, r'(?i)reviewer (session|context|pane)s?\b')
        self.assertIn('spawn the three `astragentic_reviewer` helpers yourself', builder)
        self.assertIn('astra-codex-simplify', builder)
        self.assertTrue((ROOT / 'runtimes/codex/.agents/skills/astra-codex-simplify/SKILL.md').is_file())
        self.assertFalse((ROOT / 'runtimes/codex/.agents/skills/codex-simplify').exists())
        self.assertIn('never opens a review session', dispatch)
        # Parity with the Claude lane, each row read from both contracts, 2026-11-09.
        self.assertIn('one run\ncovers a batch', dispatch)
        self.assertIn('More than 10 such merges', dispatch)
        self.assertIn('a fix\nowes no second QA run', dispatch)
        self.assertNotRegex(dispatch, r'QA re-runs')
        self.assertIn('Review runs once over the increment', builder)
        self.assertNotIn('invalidate coverage', builder)
        self.assertIn('ONE written reply', thomas)
        self.assertIn('## The false no-tool stop', thomas)
        self.assertIn('Send ONE steer', thomas)
        # nizzy 2026-11-10: the "call it directly" steer, read back inside an exec output, failed 2 of 2;
        # a second stop now sends the namespace probe and reports failed with the list attached.
        self.assertNotIn('the\nsteer worked 2 of 2 times', thomas)
        self.assertIn('0 of 2 as an Orca `orchestration send`', thomas)
        self.assertIn('list every tool namespace and tool', thomas)
        self.assertIn('same shape is not a second steer', thomas)
        for text in (thomas, builder, (ROOT / 'runtimes/codex/.codex/roles/common.md').read_text()):
            self.assertIn('`ALL_TOOLS`', text)
        # 6.1.3: the Orca preamble silences spawn_agent (0 of 10 with it, 7 of 7 without, 2026-11-10);
        # a fresh session, a task line or an AGENTS.md rule recovered 0 of 6; a child codex exec ran 3 of 3.
        self.assertIn('no subagents or helper workers unless the task asks', thomas)
        self.assertNotIn('no call means a fresh session on the committed head', thomas)
        self.assertIn('## On Orca: a lens is a child process', review)
        self.assertIn('["env", "-u", "ORCA_PANE_KEY"', review)
        self.assertIn('"codex", "exec", "--cd", worktree', review)
        # 6.1.4: a child inheriting ORCA_PANE_KEY posts its Stop as the parent pane's (3 hook POSTs vs 0).
        self.assertIn('Worker stopped without reporting', thomas)
        self.assertIn('child\n   `codex exec`', builder)
        self.assertIn('**Review on Orca (6.1.3).**', dispatch)
        # The Codex pass has its own Pass: form; the checker accepts it beside the Claude one (6.1.2).
        simplify = (ROOT / 'runtimes/codex/.agents/skills/astra-codex-simplify/SKILL.md').read_text()
        self.assertIn('`Pass: $astra-codex-simplify`', simplify)
        checker = (ROOT / 'harness/scripts/check-simplify-markers.sh').read_text()
        self.assertIn('"$astra-codex-simplify"', checker)
        self.assertNotIn('''"required": ['Pass: Skill(skill: "simplify")']''', checker)
        tdd = (ROOT / 'runtimes/codex/.agents/skills/codex-astra-implement-with-tdd/SKILL.md').read_text()
        self.assertIn('a test failing three times in a row', tdd)
        self.assertIn('Run exactly the commands', tdd)
        self.assertNotIn('Missing command mapping blocks', (ROOT / 'runtimes/codex/.agents/skills/codex-dispatch-ticket/SKILL.md').read_text())
        self.assertNotIn('needs renewed review', (ROOT / 'runtimes/codex/.agents/skills/astra-codex-simplify/SKILL.md').read_text())
        # Polling path the first review of 6.0.9 found still prescribed (DISPATCH.md:376-379).
        self.assertNotRegex(dispatch, r'Once working has been observed, use\s+bounded `herdr agent wait')
        self.assertIn('`agent wait` loops and repeated\n`agent get` are forbidden while a bell is configured', dispatch)
        # 0 commits, 47 and 58 dirty files, 46 of 83 messages on QA, 2 tickets: nizzy 2026-11-09.
        qa = (ROOT / 'runtimes/codex/.agents/skills/codex-dispatch-qa-walk/SKILL.md').read_text()
        qa_role = (ROOT / 'runtimes/codex/.codex/roles/qa.md').read_text()
        common = (ROOT / 'runtimes/codex/.codex/roles/common.md').read_text()
        self.assertIn('Commit and push to your\nticket branch at every phase boundary', builder)
        self.assertNotRegex(builder, r'(?i)only when\s+the active task authorizes')
        for text in (dispatch, thomas, qa, qa_role):
            self.assertNotRegex(text, r'(?i)freeze ACK|dirty[- ](no-commit|artifact)|content manifest')
        for text in (dispatch, thomas, common):
            self.assertNotRegex(text, r'\bACK\b')
        self.assertIn('hands over the WHOLE ticket', dispatch)
        # The second review of 6.0.9: a receipt commit must not void its own receipt.
        arm = (ROOT / 'runtimes/codex/.agents/skills/codex-cross-vendor-review/SKILL.md').read_text()
        review = (ROOT / 'runtimes/codex/.agents/skills/codex-astra-review/SKILL.md').read_text()
        junior = (ROOT / 'runtimes/codex/.codex/roles/junior.md').read_text()
        self.assertIn('under 100 changed non-test lines', arm)
        self.assertNotIn('a later commit invalidates the receipt', arm)
        self.assertNotRegex(review, r'committed-plus-dirty')
        self.assertNotRegex(junior, r'(?i)commits are not authorized')

    def test_shipped_orchestrator_arm_table_is_not_read_as_roles(self):
        config = ROOT / 'runtimes/codex/.agents/orchestrator-for-codex.md'
        text = config.read_text()
        self.assertIn('## Cross-vendor arm', text)
        self.assertRegex(text, r'\| ticket \| claude-code \| claude-[a-z0-9.-]+ \|')
        sys.path.insert(0, str(ROOT / 'runtimes/codex'))
        from launch import assignments
        rows = assignments(config)
        self.assertEqual(len(rows), 14)
        self.assertNotIn('ticket', rows)
        self.assertNotIn('spec', rows)
        self.assertNotIn('slice', rows)

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
