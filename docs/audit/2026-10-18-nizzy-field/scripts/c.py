import re,collections
L=open('/tmp/harness-hook-events.log',errors='replace').read().split('\n')
ts=re.compile(r'^(\d{4}-\d\d-\d\d)T(\d\d:\d\d:\d\d)')
ents=[];cur=None
for l in L:
    m=ts.match(l)
    if m:
        cur=[m.group(1),m.group(2),l];ents.append(cur)
    elif cur: cur[2]+="\n"+l
    # untimestamped lines before first ts ignored
print('entries',len(ents),'first',ents[0][:2],'last',ents[-1][:2])
def kind(t):
    rest=t.split(' ',1)[1]
    w=rest.split()
    k=w[0]
    if k=='HOOK:': return 'HOOK:'+w[1]
    if k=='allow(' or k.startswith('allow'): return k
    if k.startswith('no-opinion'): return k
    if k.startswith('base-guessed'): return 'base-guessed'
    if k=='astragentic-dispatch': return 'dispatch '+w[1]+' '+(w[2] if w[1]=='REFUSED' else '')
    if k=='hook-contract-reload': return k+' '+w[1]
    if k=='DENY:' or k=='DENY': return 'DENY'
    return k
K=collections.Counter();D=collections.defaultdict(collections.Counter)
for d,t,x in ents:
    k=kind(d+'T'+t+' '+x.split(' ',1)[1]) if ' ' in x else 'x'
    K[k]+=1;D[d][k]+=1
print('\nKIND TOTALS');
for k,v in K.most_common(60):print(v,k)
print('\nPER DAY (top kinds)')
top=[k for k,_ in K.most_common(14)]
print('day',top)
for d in sorted(D):print(d,[D[d][k] for k in top])

print('\n==== git-guard verdicts')
G=collections.Counter();GD=collections.defaultdict(collections.Counter);deny=[]
proj=collections.Counter()
for d,t,x in ents:
    m=re.match(r'\S+ hook-git-guard (\S+) \| (.*)',x,re.S)
    if not m: continue
    v=m.group(1);G[v]+=1;GD[d][v]+=1
    cmd=m.group(2)
    p='inception' if 'workspace-app-inception' in cmd else 'astragentic' if '/astragentic' in cmd and 'etsy' not in cmd else 'nizzy' if 'etsy-fulfillment' in cmd else 'unattributed'
    proj[p]+=1
    if v.startswith('DENY'):deny.append((d,t,cmd))
for k,v in G.most_common():print(v,k)
print('attribution by path text in command:',dict(proj))
print('DENY per day',{d:GD[d]['DENY'] for d in sorted(GD)})
print('\n==== DENY classification')
def cls(c):
    c1=c.strip()
    for name,rx in [('git push',r'git\s+(-C\s+\S+\s+)?push'),('git merge',r'git\s+(-C\s+\S+\s+)?merge'),('make db-down',r'db-down'),('git reset --hard',r'reset\s+--hard'),('git branch -D',r'branch\s+-D'),('git worktree remove',r'worktree\s+remove'),('git checkout/switch',r'git\s+(checkout|switch)'),('git commit',r'git\s+(-C\s+\S+\s+)?commit'),('gh pr merge',r'gh\s+pr\s+merge'),('rm -rf',r'rm\s+-\w*r'),('git add',r'git\s+add'),('git stash',r'git stash'),('git clean',r'git clean'),('git rebase',r'git rebase')]:
        if re.search(rx,c1):return name
    return 'other'
DC=collections.Counter(cls(c) for _,_,c in deny)
for k,v in DC.most_common():print(v,k)
import json
json.dump([[d,t,c[:300]] for d,t,c in deny],open('/tmp/nizzy-audit/deny.json','w'))
print('\n==== isolation guard verdicts')
I=collections.Counter()
for d,t,x in ents:
    m=re.match(r'\S+ hook-agent-isolation-guard (\S+(?: [^|]{0,60})?)',x)
    if m:I[re.sub(r"subagent_type='[^']*'","subagent_type=X",m.group(1)[:70])]+=1
for k,v in I.most_common(10):print(v,k)
print('\n==== REFUSED by gate,key')
R=collections.Counter()
for d,t,x in ents:
    m=re.match(r'\S+ astragentic-dispatch REFUSED (\S+) key=(\S+)\s*(.{0,80})',x)
    if m:R[(d,m.group(1),m.group(2))]+=1
for k,v in sorted(R.items()):print(v,k)
print('\n==== reload')
RL=collections.Counter()
for d,t,x in ents:
    m=re.match(r'\S+ hook-contract-reload (FIRED|INERT) event=(\S+) (.{0,40})',x)
    if m:RL[(m.group(1),m.group(2),re.sub(r'=\S*','=',m.group(3))[:30])]+=1
for k,v in RL.most_common(12):print(v,k)
RR=collections.Counter()
for d,t,x in ents:
    m=re.match(r'\S+ hook-contract-reload FIRED event=\S+ role=(\S+) root=(\S+)',x)
    if m:RR[(m.group(1),m.group(2).split('/')[-1])]+=1
print(RR.most_common(10))
print('\n==== tracker-status')
TS=collections.Counter()
for d,t,x in ents:
    m=re.match(r'\S+ hook-tracker-status (.{0,60})',x)
    if m:TS[re.sub(r'\d+','N',m.group(1))]+=1
for k,v in TS.most_common(8):print(v,k)
