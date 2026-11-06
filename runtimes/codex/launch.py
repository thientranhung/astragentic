#!/usr/bin/env python3
"""Owner-session launcher. Dispatch workers use a separate verified dispatch path."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
# Source tree keeps scripts beside .codex/.agents. Installed scripts live in
# <project>/.codex/astragentic; contracts remain in the standard project folders.
if ROOT.name == 'astragentic' and ROOT.parent.name == '.codex':
    ROOT = ROOT.parent.parent
OWNER_ROLES = ('thomas', 'ba', 'quick-builder')
EFFORTS = {'low', 'medium', 'high', 'xhigh', 'max', 'ultra'}


def assignments(path):
    rows = {}
    active = False
    for line in path.read_text().splitlines():
        if line.startswith('## '):
            active = line.strip() == '## Model assignments'
            continue
        if not active or not line.startswith('|'):
            continue
        cells = [x.strip().strip('`') for x in line.strip('|').split('|')]
        if cells == ['Role', 'Model', 'Effort'] or all(set(x) <= {'-', ':', ' '} for x in cells):
            continue
        if len(cells) != 3:
            raise ValueError('model assignment must have Role, Model, Effort')
        role, model, effort = cells
        if role in rows:
            raise ValueError('duplicate role assignment: ' + role)
        if not re.fullmatch(r'[a-z0-9][a-z0-9.-]*', model) or effort not in EFFORTS:
            raise ValueError('invalid model/effort for ' + role)
        rows[role] = (model, effort)
    return rows


def main():
    parser = argparse.ArgumentParser(description='Open an owner Codex role using Astragentic model assignments. Workers use the separate native Herdr/queue skill procedure.', epilog='Examples: python3 launch.py thomas --project /repo --dry-run; python3 launch.py ba --project /repo. No config files are written; permissions stay with Codex. Dry-run renders JSON without starting a session.')
    parser.add_argument('role', choices=OWNER_ROLES)
    parser.add_argument('--project', required=True, type=Path, help='Git checkout in which the role will work')
    parser.add_argument('--orchestrator', type=Path, help='Explicit model assignment file; otherwise prefer the project Codex orchestrator')
    parser.add_argument('--herdr', action='store_true', help='Opt in to granting the Herdr API socket per launch using a native workspace permission profile; requires HERDR_ENV=1 and absolute HERDR_SOCKET_PATH naming an existing socket')
    parser.add_argument('--dry-run', action='store_true', help='Print launch argv as JSON without invoking Codex')
    args = parser.parse_args()
    try:
        project = args.project.resolve(strict=True)
        if not project.is_dir():
            raise ValueError('project is not a directory')
        git = subprocess.run(['git', '-C', str(project), 'rev-parse', '--show-toplevel'], text=True, capture_output=True)
        if git.returncode:
            raise ValueError('project must be a Git checkout')
        project = Path(git.stdout.strip()).resolve()
        project_config = project / '.agents/orchestrator-for-codex.md'
        config = (args.orchestrator or (project_config if project_config.is_file() else ROOT / '.agents/orchestrator-for-codex.md')).resolve(strict=True)
        table = assignments(config)
        if args.role not in table:
            raise ValueError('missing model assignment for ' + args.role)
        model, effort = table[args.role]
        runtime = project if (project / '.codex/astragentic/manifest.json').is_file() else ROOT
        installed = (project / '.codex/astragentic/manifest.json').is_file()
        if installed:
            # Deferred because the helper renderer imports the assignment parser.
            from helpers import render
            for name, profile in render(config).items():
                helper = project / '.codex/agents' / ('astragentic-' + name)
                if not helper.is_file() or helper.read_text() != profile:
                    raise ValueError('installed helpers do not match selected orchestrator: ' + name
                                     + '; reconcile the project orchestrator and run install/doctor '
                                     'before launching; no model was substituted')
        contract = runtime / '.codex/roles' / (args.role + '.md')
        if not contract.is_file():
            raise ValueError('missing Codex role contract: ' + str(contract))
        common = runtime / '.codex/roles/common.md'
        dispatch = runtime / '.codex/DISPATCH.md'
        for required in (common, dispatch):
            if not required.is_file():
                raise ValueError('missing Codex contract: ' + str(required))
        # Native project/global policies remain intact; never replace developer_instructions.
        prompt = ('Start an Astragentic Codex owner session. Your role is ' + args.role + '. '
                  'Read the Codex role contract at ' + json.dumps(str(contract)) + ' and the common contract at ' + json.dumps(str(common)) + ' before acting. '
                  'Project: ' + json.dumps(str(project)) + '. Model assignments: ' + json.dumps(str(config)) + '. '
                  'Do not start work from a previous session or infer a ticket. After loading your role, end the turn and await the owner task; do not run a sleep or polling loop. '
                  'For authorized worker dispatch, read ' + json.dumps(str(dispatch)) + '. '
                  'Follow that native procedure; do not claim custom commit or merge guards are active.')
        if not installed:
            prompt += (' This project has no installed Astragentic overlay. The bundled role contract is available, '
                       'but native skill and helper discovery in this project has not been established. '
                       'Report missing capabilities before using them; source files alone do not register tools.')
        argv = ['codex', '--cd', str(project), '--model', model,
                '-c', 'model_reasoning_effort=' + json.dumps(effort)]
        if args.herdr:
            if os.environ.get('HERDR_ENV') != '1':
                raise ValueError('--herdr requires HERDR_ENV=1')
            socket = Path(os.environ.get('HERDR_SOCKET_PATH', ''))
            if not socket.is_absolute() or not socket.is_socket():
                raise ValueError('--herdr requires absolute HERDR_SOCKET_PATH naming an existing Unix socket')
            # Keep the pathname inside TOML, not a CLI dotted key: path dots
            # otherwise become config-key separators in Codex 0.166.0.
            profile = ('permissions.astragentic-local={extends=":workspace",network={enabled=true,'
                       'unix_sockets={' + json.dumps(str(socket)) + '="allow"}}}')
            argv += ['-c', 'default_permissions="astragentic-local"',
                     '-c', 'features.network_proxy=true', '-c', profile]
        argv.append(prompt)
        if args.dry_run:
            print(json.dumps({'role': args.role, 'orchestrator': str(config), 'contract': str(contract),
                              'overlay_installed': installed, 'argv': argv}, ensure_ascii=False, indent=2))
            return 0
        binary = shutil.which('codex')
        if not binary:
            raise ValueError('codex executable not found')
        if not installed:
            print('astra-codex: source-only role launch; install the overlay for project-native skills and helpers', file=sys.stderr)
        os.chdir(project)
        os.execv(binary, argv)
    except (OSError, ValueError) as exc:
        print('astra-codex: ' + str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
