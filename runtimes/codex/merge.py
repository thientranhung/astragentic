#!/usr/bin/env python3
"""Validate an exact merge message before an explicitly authorized GitHub merge.

This is an opt-in command boundary, not a hook intercepting other gh invocations.
Project policy supplies required trailers and, when needed, a message validator.
"""
import argparse
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path


def run(args, **kwargs):
    return subprocess.run(args, text=True, capture_output=True, **kwargs)


def merge(project, repo, pr, head, subject, body_file, required, validator=None, execute=False):
    project = Path(project).resolve(strict=True)
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repo):
        raise ValueError('repo must be explicit OWNER/REPO on github.com')
    if not re.fullmatch(r'[0-9a-f]{40}', head):
        raise ValueError('head must be an exact 40-character commit SHA')
    if not str(pr).isdigit() or int(pr) < 1:
        raise ValueError('PR must be a positive number')
    if not subject.strip() or '\n' in subject or '\r' in subject:
        raise ValueError('subject must be one nonempty line')
    if not required or any(not re.fullmatch(r'[A-Za-z][A-Za-z0-9-]*', k) for k in required):
        raise ValueError('declare project-required trailer keys')
    actual = run(['git', 'rev-parse', 'HEAD'], cwd=project)
    if actual.returncode or actual.stdout.strip() != head:
        raise ValueError('checkout HEAD differs from reviewed candidate')
    body = Path(body_file).read_text()
    message = subject + '\n\n' + body.rstrip('\n') + '\n'
    parsed = run(['git', 'interpret-trailers', '--parse'], input=message, cwd=project)
    if parsed.returncode:
        raise ValueError('cannot parse merge trailers')
    trailers = {}
    for line in parsed.stdout.splitlines():
        key, sep, value = line.partition(':')
        if sep:
            trailers.setdefault(key.lower(), []).append(value.strip())
    for key in required:
        values = trailers.get(key.lower(), [])
        if len(values) != 1 or not values[0]:
            raise ValueError('missing, empty or duplicate required trailer: ' + key)
    digest = hashlib.sha256(message.encode()).hexdigest()
    with tempfile.TemporaryDirectory(prefix='astragentic-merge-') as d:
        exact = Path(d) / 'message.txt'
        exact.write_text(message)
        if validator is not None:
            # Project-owned executable receives the complete message, never shell text.
            checked = run([str(Path(validator).resolve(strict=True)), str(exact)], cwd=project)
            if checked.returncode:
                raise ValueError('project merge-message validator refused; no merge attempted')
            if exact.read_text() != message:
                raise ValueError('validator changed the message; no merge attempted')
        result = {'status': 'message-validated', 'repo': repo, 'pr': str(pr), 'head': head, 'message_sha256': digest,
                  'required_trailers': required, 'project_validator': str(validator) if validator else None,
                  'scope': 'message and local HEAD only; review, QA, gates and authorization remain separately required'}
        if execute:
            # REST immediate merge cannot enable auto-merge or enqueue a PR. No bypass.
            current = run(['git', 'rev-parse', 'HEAD'], cwd=project)
            if current.returncode or current.stdout.strip() != head:
                raise ValueError('HEAD changed during validation; no merge attempted')
            payload = {'commit_title': subject, 'commit_message': body.rstrip('\n') + '\n',
                       'sha': head, 'merge_method': 'merge'}
            sent = run(['gh', 'api', '--hostname', 'github.com', '--method', 'PUT',
                        'repos/' + repo + '/pulls/' + str(pr) + '/merge', '--input', '-'],
                       input=json.dumps(payload), cwd=project)
            try:
                response = json.loads(sent.stdout)
            except ValueError:
                response = None
            confirmed = (sent.returncode == 0 and isinstance(response, dict)
                         and response.get('merged') is True
                         and re.fullmatch(r'[0-9a-f]{40}', str(response.get('sha', ''))) is not None)
            result.update(status='merge-api-confirmed' if confirmed else 'merge-outcome-unconfirmed',
                          exit_code=0 if confirmed else (sent.returncode or 1),
                          stdout=sent.stdout, stderr=sent.stderr)
            # No retry or cleanup: even a nonzero result may have published remotely.
        return result


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--project', type=Path, required=True)
    p.add_argument('--repo', required=True, help='Explicit github.com OWNER/REPO; ignores ambient GH_REPO')
    p.add_argument('--pr', required=True)
    p.add_argument('--head', required=True)
    p.add_argument('--subject', required=True)
    p.add_argument('--body-file', type=Path, required=True)
    p.add_argument('--require-trailer', action='append', required=True)
    p.add_argument('--validator', type=Path)
    p.add_argument('--execute', action='store_true', help='Publish only with existing owner merge authorization')
    a = p.parse_args()
    try:
        result = merge(a.project, a.repo, a.pr, a.head, a.subject, a.body_file, a.require_trailer, a.validator, a.execute)
        print(json.dumps(result, indent=2))
        return result.get('exit_code', 0)
    except (OSError, ValueError) as e:
        print('astra-codex merge: ' + str(e), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
