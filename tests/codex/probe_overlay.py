#!/usr/bin/env python3
"""Render the actual overlay skill catalog in a disposable Codex home; no inference."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'runtimes/codex'))
from install import operate


def main():
    with tempfile.TemporaryDirectory(prefix='astra overlay ') as tmp:
        root = Path(tmp)
        project, home = root / 'project', root / 'home'
        project.mkdir()
        home.mkdir()
        subprocess.run(['git', 'init', '-q', str(project)], check=True)
        operate(project, 'install', True)
        integrity = operate(project, 'doctor')
        (home / 'config.toml').write_text('[projects.' + json.dumps(str(project.resolve())) + ']\ntrust_level="trusted"\n')
        result = subprocess.run(['codex', 'debug', 'prompt-input', 'Overlay discovery probe'],
                                cwd=project, env={**os.environ, 'CODEX_HOME': str(home)},
                                text=True, capture_output=True, timeout=45)
        if result.returncode:
            print(json.dumps({'status': 'failed', 'exit_code': result.returncode,
                              'reason': 'prompt rendering failed; private output withheld'}))
            return 1
        rendered = json.dumps(json.loads(result.stdout), ensure_ascii=False)
        discovered, missing = [], []
        for skill in sorted((project / '.agents/skills').glob('*/SKILL.md')):
            text = skill.read_text()
            line = next(line for line in text.splitlines() if line.startswith('description: '))
            description = json.loads(line.removeprefix('description: '))
            # The CLI truncates discovery descriptions (observed at ~90 chars).
            # Match the named catalog entry plus its distinctive prefix, not the
            # full authoring text, which is intentionally not all in context.
            catalog_entry = '- ' + skill.parent.name + ': ' + description[:60]
            (discovered if catalog_entry in rendered else missing).append(skill.parent.name)
        print(json.dumps({'discovered_count': len(discovered), 'missing': missing,
                          'installer_doctor': integrity['status'],
                          'scope': 'actual skill descriptions in native prompt catalog; helper spawn and role behavior unmeasured'}, indent=2))
        return 1 if missing else 0


if __name__ == '__main__': sys.exit(main())
