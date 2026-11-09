#!/bin/bash
# Codex notify callback: project + appended agent-turn-complete JSON.
# No timer, daemon, model prompt, queue or resume. Failures never block turn exit.
if [ "${2:-}" = "--stop" ]; then
  HOOK_PAYLOAD="$(cat)"
  set -- "$1" "$HOOK_PAYLOAD" --stop
fi
python3 - "$@" <<'PY'
import datetime, fcntl, hashlib, json, os, pathlib, re, subprocess, sys, uuid

state = None
def log(kind, **fields):
    row = dict(at=datetime.datetime.now(datetime.timezone.utc).isoformat(), event=kind, **fields)
    try:
        with (state / 'coordinator-turn-end.log').open('a') as f:
            f.write(json.dumps(row, sort_keys=True) + '\n')
    except OSError:
        print(json.dumps(row), file=sys.stderr)

def stamp(s):
    d = datetime.datetime.fromisoformat(s.replace('Z', '+00:00'))
    if d.tzinfo is None: raise ValueError('timestamp lacks timezone')
    return d

def main():
    global state
    stop = len(sys.argv) == 4 and sys.argv[3] == '--stop'
    if len(sys.argv) not in (3, 4): raise ValueError('expected project and payload')
    project = pathlib.Path(sys.argv[1])
    if not project.is_absolute() or not project.is_dir(): raise ValueError('invalid project')
    project = project.resolve()
    state = project / '.astraler/codex/state'
    # Never follow state directories outside the selected project.
    if not state.resolve().is_relative_to(project): raise ValueError('state escapes project')
    state.mkdir(parents=True, exist_ok=True)
    payload = json.loads(sys.argv[2])
    if (payload.get('hook_event_name') != 'Stop' if stop else payload.get('type') != 'agent-turn-complete'):
        log('skip', reason='event-type'); return
    thread = str(uuid.UUID(payload['session_id'] if stop else payload['thread-id']))
    turn = str(uuid.UUID(payload['turn_id'] if stop else payload['turn-id']))
    if stop and not isinstance(payload.get('stop_hook_active'), bool): raise ValueError('missing stop_hook_active')
    if not uuid.UUID(thread).int or not uuid.UUID(turn).int: raise ValueError('nil identity')
    if pathlib.Path(payload['cwd']).resolve() != project: raise ValueError('payload cwd mismatch')
    if (state / 'bell-off').exists():
        log('skip', reason='bell-off'); return
    root = project / '.scratch/codex'
    if not root.resolve().is_relative_to(project): raise ValueError('records escape project')
    records = sorted(root.glob('*.md'))
    if not records: log('skip', reason='no-records')
    terminal = {'worker_running', 'external_wait', 'owner_paused', 'completed', 'idle'}
    for path in records:
        try:
            if path.is_symlink() or path.stat().st_size > 1048576: raise ValueError('unsafe/oversize record')
            text = path.read_text()
            owners = re.findall(r'^Coordinator thread UUID:\s*([0-9a-fA-F-]{36})(?:[;\s]|$)', text, re.M)
            if len(owners) != 1 or str(uuid.UUID(owners[0])) != thread:
                log('skip', record=path.name, reason='coordinator-binding'); continue
            handbacks, dispositions = {}, {}
            for line in text.splitlines():
                if not line.startswith(('handback:', 'disposition:')): continue
                parts = line.split()
                hb = parts[0] == 'handback:'
                if len(parts) != (3 if hb else 4): raise ValueError('malformed machine line')
                key = parts[1]
                if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.:-]{0,159}', key): raise ValueError('invalid handback id')
                at = stamp(parts[-1])
                if hb:
                    if key in handbacks and handbacks[key] != at: raise ValueError('conflicting handback timestamp')
                    handbacks[key] = at
                else:
                    if parts[2] not in terminal | {'coordinator_pending'}: raise ValueError('invalid disposition state')
                    prior = dispositions.get(key)
                    if prior and at <= prior[1]: raise ValueError('unordered disposition')
                    dispositions[key] = (parts[2], at)
            if not handbacks:
                log('skip', record=path.name, reason='no-handback-lines'); continue
            if any(k not in handbacks or at < handbacks[k] for k, (_, at) in dispositions.items()):
                raise ValueError('disposition without matching earlier handback')
            if any(at > datetime.datetime.now(datetime.timezone.utc) for at in handbacks.values()):
                raise ValueError('future handback')
            for handback, received in handbacks.items():
                if handback in dispositions and dispositions[handback][0] in terminal: continue
                if stop and not payload['stop_hook_active']:
                    # Defensive duplicate-hook guard in addition to native stop_hook_active.
                    with (state / 'coordinator-turn-end.continued').open('a+') as continued:
                        fcntl.flock(continued, fcntl.LOCK_EX)
                        continued.seek(0)
                        continuation_key = thread + ' ' + turn
                        if continuation_key not in continued.read().splitlines():
                            continued.write(continuation_key + '\n'); continued.flush(); os.fsync(continued.fileno())
                            reason = ('Unresolved handback ' + handback + ' in ' + path.name
                                      + '. Continue the authorized coordinator disposition: perform the next action, '
                                      'or record the actual external blocker/owner pause with evidence and next owner/trigger. '
                                      'A status answer does not cancel work. Do not bypass approvals, replay work or spawn substitutes.')
                            log('stop_block', record=path.name, handback=handback, turn=turn)
                            print(json.dumps({'decision': 'block', 'reason': reason}))
                            return
                # Stable per (dispatch record, original handback), independent of turn.
                key = hashlib.sha256(json.dumps([path.stem, handback]).encode()).hexdigest()
                with (state / 'coordinator-turn-end.seen').open('a+') as seen:
                    fcntl.flock(seen, fcntl.LOCK_EX)
                    seen.seek(0)
                    if key in seen.read().splitlines():
                        log('skip', record=path.name, handback=handback, reason='duplicate'); continue
                    if (state / 'bell-off').exists():
                        log('skip', reason='bell-off'); return
                    # Reserve before external effect. Ambiguous failures require manual reconciliation.
                    seen.write(key + '\n'); seen.flush(); os.fsync(seen.fileno())
                    log('attempt', record=path.name, handback=handback, turn=turn, received_at=received.isoformat())
                    try:
                        result = subprocess.run(['herdr', 'notification', 'show', 'Astragentic: unresolved handback',
                            '--body', f'{path.stem}: {handback} has no stopping disposition; Thomas turn ended.',
                            '--sound', 'none'], capture_output=True, text=True, timeout=5)
                        log('accepted_unconsumed' if result.returncode == 0 else 'notify_failed',
                            record=path.name, handback=handback, turn=turn, exit=result.returncode,
                            stdout=result.stdout[:2000], stderr=result.stderr[:2000])
                    except (OSError, subprocess.TimeoutExpired) as exc:
                        log('notify_unknown', record=path.name, handback=handback, error=str(exc))
        except (OSError, ValueError, TypeError) as exc:
            log('skip', record=path.name, reason=str(exc))

try:
    main()
except Exception as exc:
    if state is not None: log('skip', reason=str(exc))
    else: print('coordinator-turn-end skip: ' + str(exc), file=sys.stderr)
PY
exit 0
