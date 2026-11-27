
import json, os, re, glob, sys, datetime, statistics as st
P = os.path.expanduser('~/.claude/projects')
NZ = '/Users/tranthien/Documents/2.DEV/2.PRIVATE/etsy-fulfillment-thanh'
rec = json.load(open(NZ + '/.astraler/state/dispatch-record.json'))
TESTF = re.compile(r'(_test\.|\.test\.|\.spec\.|/tests?/|/__tests__/|/spec/|_test$)')
TESTCMD = re.compile(r'\b(go test|pytest|vitest|jest|npm (run )?test|pnpm (run )?test|yarn test|cargo test|playwright test|make test)\b')
def ts(s): return datetime.datetime.fromisoformat(s.replace('Z','+00:00')).timestamp()
dirs = sorted(glob.glob(P + '/*etsy-fulfillment-thanh--claude-worktrees-builder-TRA-*'))
out = []
for d in dirs:
    key = re.search(r'builder-(TRA-\d+)', d).group(1)
    files = glob.glob(d + '/*.jsonl')
    if not files: continue
    mt = max(os.path.getmtime(f) for f in files)
    if mt < datetime.datetime(2026,11,24).timestamp(): continue
    kind = (rec.get(key) or {}).get('kind')
    ev = []
    for f in files:
        for line in open(f, errors='ignore'):
            try: j = json.loads(line)
            except: continue
            if 'timestamp' not in j: continue
            ev.append(j)
    ev.sort(key=lambda j: j['timestamp'])
    if len(ev) < 20: continue
    # brief
    tb = None
    for j in ev:
        if j.get('type') == 'user':
            c = j.get('message',{}).get('content')
            s = c if isinstance(c,str) else json.dumps(c)
            if 'astra-implement-with-tdd' in s: tb = ts(j['timestamp']); break
    if tb is None: tb = ts(ev[0]['timestamp'])
    calls = {}   # id -> (t, cat, cmd)
    seq = []
    results = {}
    for j in ev:
        m = j.get('message',{}); c = m.get('content')
        if not isinstance(c, list): continue
        for b in c:
            if b.get('type') == 'tool_use':
                n = b.get('name'); i = b.get('input',{}) or {}
                cat = 'other'
                if n in ('Edit','Write','MultiEdit','NotebookEdit'):
                    fp = i.get('file_path','')
                    cat = 'test-edit' if TESTF.search(fp) else 'code-edit'
                elif n == 'Bash':
                    cmd = i.get('command','')
                    if TESTCMD.search(cmd): cat = 'test-run'
                    elif re.search(r'\bgit commit\b', cmd): cat = 'commit'
                    elif re.search(r'\b(agent-browser|bsk|playwright-cli|curl)\b', cmd): cat = 'browser/http'
                    elif re.search(r'\b(tsc|go build|go vet|gofmt|npm run (build|lint|typecheck)|pnpm (build|lint|typecheck)|eslint|golangci-lint|sqlc|make (build|lint|gen|sqlc))\b', cmd): cat = 'build/lint/gen'
                    elif re.search(r'\b(docker|make (db|up|down|migrate)|sleep)\b', cmd): cat = 'env/wait'
                    elif re.search(r'\b(check-simplify-markers|gate-plan)', cmd): cat = 'gates'
                    elif re.search(r'^\s*(cd [^;&]+(&&|;)\s*)?(rg|grep|cat|sed|head|tail|ls|find|wc|awk|jq|git (log|show|diff|status|grep|blame|rev-parse|branch))\b', cmd): cat = 'read'
                    elif re.search(r'\bgit\b', cmd): cat = 'git'
                    else: cat = 'bash-other'
                elif n == 'Read':
                    cat = 'read'
                elif n in ('Grep','Glob'):
                    cat = 'read'
                elif n in ('Skill','Agent','Task'):
                    cat = 'review/skill'
                elif n == 'SendMessage':
                    cat = 'herdr'
                t = ts(j['timestamp'])
                calls[b['id']] = (t, cat, i)
                seq.append((t, cat, b['id']))
            elif b.get('type') == 'tool_result':
                results[b.get('tool_use_id')] = b
    if not seq: continue
    seq = [s for s in seq if s[0] >= tb - 1]
    if not seq: continue
    # first events
    def first(cat, pred=None):
        for t, c, i in seq:
            if c == cat and (pred is None or pred(i)): return t
        return None
    def isred(i):
        r = results.get(i) or {}
        s = json.dumps(r.get('content',''))
        return bool(r.get('is_error')) or bool(re.search(r'\bFAIL\b|--- FAIL|failed|Exit code [1-9]', s))
    t_test_edit = first('test-edit'); t_code_edit = first('code-edit')
    t_red = first('test-run', isred)
    t_commit = None
    for t, c, i in seq:
        if c == 'commit':
            r = results.get(i) or {}
            if not r.get('is_error'): t_commit = t; break
    # active time attribution: gap after each call (capped 300s) to that call's category
    tot = {}
    for k in range(len(seq)-1):
        g = min(seq[k+1][0] - seq[k][0], 300)
        tot[seq[k][1]] = tot.get(seq[k][1], 0) + g
    active = sum(tot.values())
    nruns = sum(1 for s in seq if s[1]=='test-run')
    nred = sum(1 for s in seq if s[1]=='test-run' and isred(s[2]))
    out.append(dict(key=key, kind=kind, active_min=round(active/60,1),
        brief_to_first_test_edit=round((t_test_edit-tb)/60,1) if t_test_edit else None,
        brief_to_first_code_edit=round((t_code_edit-tb)/60,1) if t_code_edit else None,
        test_before_code=(t_test_edit is not None and (t_code_edit is None or t_test_edit <= t_code_edit)),
        brief_to_red=round((t_red-tb)/60,1) if t_red else None,
        red_to_commit=round((t_commit-t_red)/60,1) if (t_red and t_commit and t_commit>t_red) else None,
        share={k: round(v/active*100,1) for k,v in sorted(tot.items(), key=lambda x:-x[1])} if active else {},
        runs=nruns, reds=nred))
json.dump(out, sys.stdout)
