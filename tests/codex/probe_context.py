#!/usr/bin/env python3
"""Probe installed Codex prompt rendering in disposable fixtures; no model calls.

Print only sentinel assertions, never the full prompt or user configuration.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    binary = shutil.which('codex')
    if not binary:
        raise SystemExit('UNAVAILABLE: codex is not installed')
    version = subprocess.check_output([binary, '--version'], text=True).strip()
    results = []
    with tempfile.TemporaryDirectory(prefix='astra-codex-context-') as tmp:
        root = Path(tmp)
        home, project = root / 'codex-home', root / 'project with spaces'
        home.mkdir()
        project.mkdir()
        subprocess.run(['git', 'init', '-q', str(project)], check=True)
        nested = project / 'nested'
        nested.mkdir()
        (project / 'AGENTS.md').write_text('ASTRA_ROOT_CONTEXT_1903\n')
        (nested / 'AGENTS.md').write_text('ASTRA_NESTED_CONTEXT_1903\n')
        skills = project / '.agents' / 'skills' / 'astra-probe'
        skills.mkdir(parents=True)
        (skills / 'SKILL.md').write_text(
            '---\nname: astra-probe\ndescription: ASTRA_SKILL_DESCRIPTION_1903\n---\n'
            'ASTRA_SKILL_BODY_1903\n')
        claude = project / '.claude' / 'skills' / 'claude-only-probe'
        claude.mkdir(parents=True)
        (claude / 'SKILL.md').write_text(
            '---\nname: claude-only-probe\ndescription: ASTRA_CLAUDE_ONLY_1903\n---\nBody\n')
        agents = project / '.codex' / 'agents'
        agents.mkdir(parents=True)
        (agents / 'astra-probe-reader.toml').write_text(
            'name = "astra_probe_reader"\n'
            'description = "ASTRA_HELPER_DESCRIPTION_1903"\n'
            'developer_instructions = "ASTRA_HELPER_BODY_1903"\n')
        env = dict(os.environ, CODEX_HOME=str(home))
        # Fixture-local trust only, never alter the real user's project settings.
        (home / 'config.toml').write_text(
            '[projects.' + json.dumps(str(project)) + ']\ntrust_level = "trusted"\n')
        command = [binary, 'debug', 'prompt-input', '-c',
                   'developer_instructions=' + json.dumps('ASTRA_ROLE_CONTEXT_1903'),
                   'ASTRA_USER_PROMPT_1903']
        try:
            run = subprocess.run(command, cwd=nested, env=env, text=True,
                                 capture_output=True, timeout=45)
        except subprocess.TimeoutExpired:
            raise SystemExit('UNAVAILABLE: prompt rendering exceeded 45 seconds')
        if run.returncode:
            print(json.dumps({'version': version, 'status': 'unavailable',
                              'exit_code': run.returncode,
                              'reason': 'prompt-input failed; prompt/config output withheld'}))
            raise SystemExit(1)
        try:
            rendered = json.dumps(json.loads(run.stdout))
        except json.JSONDecodeError:
            raise SystemExit('FAIL: prompt-input did not return JSON')
        checks = {
            'root_instructions': 'ASTRA_ROOT_CONTEXT_1903' in rendered,
            'nested_instructions': 'ASTRA_NESTED_CONTEXT_1903' in rendered,
            'explicit_role_instructions': 'ASTRA_ROLE_CONTEXT_1903' in rendered,
            'user_prompt': 'ASTRA_USER_PROMPT_1903' in rendered,
            'skill_catalog_discovery': 'ASTRA_SKILL_DESCRIPTION_1903' in rendered,
            'skill_body_not_eagerly_loaded': 'ASTRA_SKILL_BODY_1903' not in rendered,
            'helper_body_not_in_parent': 'ASTRA_HELPER_BODY_1903' not in rendered,
            'claude_only_skill_not_discovered': 'ASTRA_CLAUDE_ONLY_1903' not in rendered,
        }
        observations = {
            'helper_description_in_prompt': 'ASTRA_HELPER_DESCRIPTION_1903' in rendered,
            'helper_discovery_verdict': 'unverified: prompt-input does not prove tool-schema registration',
        }
        control = subprocess.run(
            [binary, 'debug', 'prompt-input', 'ASTRA_CONTROL_1903'],
            cwd=nested, env=env, text=True, capture_output=True, timeout=45)
        if control.returncode:
            raise SystemExit('FAIL: negative control could not render')
        control_text = json.dumps(json.loads(control.stdout))
        checks['role_override_does_not_persist'] = 'ASTRA_ROLE_CONTEXT_1903' not in control_text
        checks['control_prompt_present'] = 'ASTRA_CONTROL_1903' in control_text
        results.append(checks)
    print(json.dumps({'version': version, 'checks': results, 'observations': observations,
                      'scope': 'prompt rendering only; no model execution or dispatch'}, indent=2))
    return 0 if all(checks.values()) else 1


if __name__ == '__main__':
    raise SystemExit(main())
