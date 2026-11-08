#!/usr/bin/env python3
"""Install/upgrade, check or remove only this Codex overlay's unchanged owned files.

Default is a dry run. --apply performs the requested install/uninstall. Existing
owner orchestrator settings and all unowned files are preserved. No trust/config
changes, hooks, package installation or background services.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

from helpers import render

SOURCE = Path(__file__).resolve().parent
MANIFEST = '.codex/astragentic/manifest.json'
CONFIG = '.agents/orchestrator-for-codex.md'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def destination(root, relative):
    path = root / relative
    if Path(relative).is_absolute() or '..' in Path(relative).parts or path.is_symlink():
        raise ValueError('unsafe managed path: ' + relative)
    if any(parent.is_symlink() for parent in (path, *path.parents) if parent != root and parent.is_relative_to(root)):
        raise ValueError('managed path traverses a symlink: ' + relative)
    if any(parent.exists() and not parent.is_dir() for parent in path.parents
           if parent.is_relative_to(root)):
        raise ValueError('managed path has a non-directory parent: ' + relative)
    if not path.resolve().is_relative_to(root):
        raise ValueError('managed path escapes project: ' + relative)
    return path


def owned_path(relative):
    return (relative.startswith('.agents/skills/codex-') and relative.endswith('/SKILL.md')
            or relative == '.agents/skills/astragentic-update-install/SKILL.md'
            or relative.startswith('.codex/roles/') and relative.endswith('.md')
            or relative.startswith('.codex/agents/astragentic-') and relative.endswith('.toml')
            or relative in {'.codex/DISPATCH.md', '.codex/astragentic/launch.py',
                            '.codex/astragentic/helpers.py', '.codex/astragentic/transport.py',
                            '.codex/astragentic/merge.py',
                            '.codex/astragentic/skill-map.json'})


def operate(project, action, apply=False):
    root = Path(project).resolve(strict=True)
    top = subprocess.check_output(['git', '-C', str(root), 'rev-parse', '--show-toplevel'], text=True).strip()
    if Path(top).resolve() != root:
        raise ValueError('--project must name the checkout root')
    manifest = destination(root, MANIFEST)
    if action not in {'install', 'doctor', 'uninstall'}:
        raise ValueError('unknown action: ' + action)
    old = {}
    if manifest.exists():
        recorded = json.loads(manifest.read_text())
        if not isinstance(recorded, dict) or recorded.get('schema') != 1 or not isinstance(recorded.get('files'), dict):
            raise ValueError('invalid Codex overlay manifest')
        old = recorded['files']
        if any(not isinstance(p, str) or not isinstance(v, str) or len(v) != 64
               or any(c not in '0123456789abcdef' for c in v) for p, v in old.items()):
            raise ValueError('invalid Codex overlay manifest hashes')
    for relative, expected in old.items():
        if not owned_path(relative):
            raise ValueError('manifest contains an unexpected path: ' + relative)
        path = destination(root, relative)
        if not path.is_file() or sha(path.read_bytes()) != expected:
            raise ValueError('owned file missing or changed; preserve and reconcile: ' + relative)
    if action == 'doctor':
        if not manifest.exists():
            raise ValueError('Codex overlay is not installed')
        for name, profile in render(destination(root, CONFIG)).items():
            path = destination(root, '.codex/agents/astragentic-' + name)
            if not path.is_file() or path.read_text() != profile:
                raise ValueError('helper models differ from orchestrator; run install to regenerate: ' + name)
        return {'status': 'files-intact', 'files': len(old),
                'scope': 'file integrity/config only; trust, model access and live workflow unmeasured'}
    payload = {}
    config = destination(root, CONFIG)
    if action == 'install':
        for directory in ('.agents/skills', '.codex/roles'):
            for source in (SOURCE / directory).rglob('*.md'):
                payload[str(source.relative_to(SOURCE))] = source.read_bytes()
        payload['.codex/DISPATCH.md'] = (SOURCE / '.codex/DISPATCH.md').read_bytes()
        for name in ('launch.py', 'helpers.py', 'transport.py', 'merge.py', 'skill-map.json'):
            payload['.codex/astragentic/' + name] = (SOURCE / name).read_bytes()
        for name, content in render(config if config.exists() else SOURCE / CONFIG).items():
            payload['.codex/agents/astragentic-' + name] = content.encode()
        # A legacy/shared install may already own this identical skill. Reuse it
        # without taking ownership, so Codex uninstall cannot delete its copy.
        shared = '.agents/skills/astragentic-update-install/SKILL.md'
        existing = destination(root, shared)
        if shared not in old and existing.is_file() and existing.read_bytes() == payload.get(shared):
            del payload[shared]
        for relative in payload:
            path = destination(root, relative)
            if path.exists() and relative not in old:
                raise ValueError('unowned path exists; will not overwrite: ' + relative)
    removed = sorted(set(old) - set(payload))
    result = {'action': action, 'apply': apply, 'write': sorted(payload), 'remove': removed,
              'owner_config': 'preserved' if config.exists() else ('create' if action == 'install' else 'absent')}
    if not apply:
        return result
    # All collisions/drift are checked before any mutation. No recursive deletion.
    for relative in removed:
        destination(root, relative).unlink()
    for relative, data in payload.items():
        path = destination(root, relative)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    if action == 'install':
        if not config.exists():
            config.parent.mkdir(parents=True, exist_ok=True)
            config.write_bytes((SOURCE / CONFIG).read_bytes())
        manifest.parent.mkdir(parents=True, exist_ok=True)
        manifest.write_text(json.dumps({'schema': 1, 'files': {p: sha(v) for p, v in payload.items()}}, indent=2) + '\n')
    elif manifest.exists():
        manifest.unlink()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('install', 'doctor', 'uninstall'))
    parser.add_argument('--project', required=True, type=Path)
    parser.add_argument('--apply', action='store_true', help='Write changes; omitted means dry run')
    args = parser.parse_args()
    try:
        print(json.dumps(operate(args.project, args.action, args.apply), indent=2))
        return 0
    except (ValueError, OSError, KeyError, subprocess.CalledProcessError) as exc:
        print('astra-codex install: ' + str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__': sys.exit(main())
