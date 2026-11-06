#!/usr/bin/env python3
"""Stage a Codex release and print its agent setup prompt; --apply installs files only."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile
import sys
from install import destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('project', type=Path)
    flags = parser.add_mutually_exclusive_group()
    flags.add_argument('--plan', action='store_true', help='Preview without writing or staging')
    flags.add_argument('--apply', action='store_true', help='Stage and install files; semantic setup still required')
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[2]
    root = args.project.resolve(strict=True)
    top = subprocess.check_output(['git', '-C', str(root), 'rev-parse', '--show-toplevel'], text=True).strip()
    if Path(top).resolve() != root:
        raise ValueError('target must be the Git checkout root')
    version = (source / 'VERSION').read_text().strip()
    if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', version):
        raise ValueError('invalid release version')
    notes = (source / 'RELEASE-NOTES.md').read_text()
    if '# Astragentic ' + version not in notes.splitlines():
        raise ValueError('release notes missing version heading')
    relative = '.astraler/codex/releases/' + version
    release = destination(root, relative)
    candidate = destination(root, '.astraler/codex/CANDIDATE')
    stamp = destination(root, '.astraler/codex/state/installed-version')
    wrapper = destination(root, '.astraler/astragentic.sh')
    payload = {}
    for name in ('VERSION', 'RELEASE-NOTES.md', 'install.sh', 'get.sh', 'astragentic.sh'):
        payload[name] = (source / name).read_bytes()
    runtime = source / 'runtimes/codex'
    for path in runtime.rglob('*'):
        if path.is_file() and '__pycache__' not in path.parts and path.suffix != '.pyc':
            if path.is_symlink():
                raise ValueError('symlink in release source')
            payload[str(path.relative_to(source))] = path.read_bytes()
    prompt = 'runtimes/codex/ADAPT-HARNESS-CODEX.md'
    if prompt not in payload:
        raise ValueError('Codex adaptation prompt missing')
    if release.exists():
        actual = {}
        for path in release.rglob('*'):
            if '__pycache__' in path.parts or path.suffix == '.pyc':
                continue
            if path.is_symlink():
                raise ValueError('symlink in staged release')
            if path.is_file():
                actual[str(path.relative_to(release))] = path.read_bytes()
        if actual != payload:
            raise ValueError('immutable release differs; bump VERSION, do not overwrite staged bytes')
    if (args.apply or args.plan) and wrapper.exists() and wrapper.read_bytes() != payload['astragentic.sh']:
        baselines = []
        for state, releases in (('.astraler/state/applied-version', '.astraler/releases'),
                                ('.astraler/codex/state/installed-version', '.astraler/codex/releases')):
            previous = destination(root, state)
            if previous.is_file():
                old_version = previous.read_text().strip()
                if re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', old_version):
                    baseline = destination(root, releases + '/' + old_version + '/astragentic.sh')
                    if baseline.is_file():
                        baselines.append(baseline.read_bytes())
        if wrapper.read_bytes() not in baselines:
            raise ValueError('shared wrapper customized or baseline unavailable; preserve and reconcile .astraler/astragentic.sh')
    if args.plan:
        subprocess.run([sys.executable, str(runtime / 'install.py'), 'install', '--project', str(root)], check=True)
        print('Plan only; no release or project files written.')
        return
    if not release.exists():
        release.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='.stage-', dir=release.parent) as temporary:
            tree = Path(temporary) / 'release'
            tree.mkdir()
            for name, data in payload.items():
                target = tree / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
            tree.rename(release)
    candidate.write_text(version + '\n')
    if args.apply:
        subprocess.run([sys.executable, str(release / 'runtimes/codex/install.py'), 'install', '--project', str(root), '--apply'], check=True)
        stamp.parent.mkdir(parents=True, exist_ok=True)
        stamp.write_text(version + '\n')
        # Shared command entrypoint only; legacy payload and applied-version stay intact.
        wrapper.write_bytes(payload['astragentic.sh'])
        wrapper.chmod(0o755)
        print('Codex files installed. Agent adaptation is still required.')
    else:
        print('Codex release staged. No project configuration or runtime files changed.')
    print('\nGive your Codex agent this instruction:\n')
    print('Read ' + relative + '/' + prompt + ' completely and execute it for this project.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as exc:
        print('astragentic codex: ' + str(exc), file=sys.stderr)
        sys.exit(1)
