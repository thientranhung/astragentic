import os,json,re,sqlite3,sys
from multiprocessing import Pool
B=os.path.expanduser('~/.claude/projects')
OUT='/tmp/nizzy-audit/t.db'
T=lambda s,n: s if s is None or len(s)<=n else s[:n]
def flat(c):
    if isinstance(c,str): return c
    if isinstance(c,list):
        o=[]
        for x in c:
            if isinstance(x,dict):
                if x.get('type')=='text': o.append(x.get('text',''))
                else: o.append(json.dumps(x)[:500])
            else:o.append(str(x))
        return '\n'.join(o)
    return json.dumps(c) if c is not None else ''
def uinfo(t):
    ref=None;rl=None
    if '<task-notification>' in t[:200]:
        m=re.search(r'<tool-use-id>([^<]*)</tool-use-id>',t[:800]);ref=m.group(1) if m else None
        m=re.search(r'<result>(.*)</result>',t,re.S);rl=len(m.group(1)) if m else 0
    return len(t),ref,rl
def proc(p):
    sub='/subagents/' in p
    parts=p.split('/')
    d=parts[parts.index('projects')+1] if 'projects' in parts else ''
    dn=p[len(B)+1:].split('/')[0]
    sess=os.path.basename(p)[:-6]
    parent=None;agent_type=None;meta=None
    if sub:
        parent=p[len(B)+1:].split('/')[1]
        mp=p[:-6]+'.meta.json'
        if os.path.exists(mp):
            try: meta=json.load(open(mp))
            except: meta=None
            if meta: agent_type=meta.get('agentType')
    role=None;first=None;last=None
    msgs={};tus={};res={};users=[];evs=[];atts=[];seq=0
    for l in open(p,errors='replace'):
        seq+=1
        try:d=json.loads(l)
        except: continue
        t=d.get('type');ts=d.get('timestamp')
        if ts:
            if first is None:first=ts
            last=ts
        if t=='agent-setting': role=d.get('agentSetting')
        elif t=='assistant':
            m=d.get('message') or {}
            mid=m.get('id')
            u=m.get('usage') or {}
            if mid:
                cur=msgs.get(mid)
                row=[mid,ts,m.get('model'),u.get('input_tokens',0) or 0,u.get('cache_read_input_tokens',0) or 0,u.get('cache_creation_input_tokens',0) or 0,u.get('output_tokens',0) or 0,seq]
                if cur is None: msgs[mid]=row
                else:
                    if row[6]>=cur[6]: row[1]=cur[1];row[7]=cur[7];msgs[mid]=row
            for b in (m.get('content') or []):
                if isinstance(b,dict) and b.get('type')=='tool_use':
                    tid=b.get('id')
                    if tid not in tus: tus[tid]=[tid,ts,seq,b.get('name'),T(json.dumps(b.get('input')),8000),mid]
        elif t=='user':
            m=d.get('message') or {}
            c=m.get('content')
            if d.get('isCompactSummary'): evs.append(('compact_summary',ts,seq,'',None))
            if isinstance(c,list):
                for b in c:
                    if isinstance(b,dict) and b.get('type')=='tool_result':
                        tid=b.get('tool_use_id')
                        if tid not in res: _f=flat(b.get('content'));res[tid]=[tid,ts,seq,1 if b.get('is_error') else 0,T(_f,6000),len(_f)]
                    elif isinstance(b,dict) and b.get('type')=='text':
                        users.append((ts,seq,(d.get('origin') or {}).get('kind') if isinstance(d.get('origin'),dict) else None,d.get('promptSource'),T(b.get('text',''),2500),d.get('uuid'))+uinfo(b.get('text','')))
            elif isinstance(c,str):
                users.append((ts,seq,(d.get('origin') or {}).get('kind') if isinstance(d.get('origin'),dict) else None,d.get('promptSource'),T(c,2500),d.get('uuid'))+uinfo(c))
        elif t=='system':
            st=d.get('subtype')
            if st=='compact_boundary':
                cm=d.get('compactMetadata') or {}
                evs.append(('compact_boundary',ts,seq,json.dumps({k:cm.get(k) for k in('trigger','preTokens','postTokens')}),None))
            elif st in('scheduled_task_fire','turn_duration'):
                evs.append((st,ts,seq,str(d.get('durationMs','')),None))
        elif t=='attachment':
            a=d.get('attachment') or {}
            at=a.get('type')
            txt=''
            if at and at.startswith('hook'):
                txt=T((a.get('stdout') or '')+(a.get('stderr') or '')+(a.get('content') or '') if isinstance(a.get('content'),str) else (a.get('stdout') or '')+(a.get('stderr') or ''),1500)
                atts.append((ts,seq,at,a.get('hookName'),a.get('exitCode'),txt,T(a.get('command') or '',600)))
            else:
                atts.append((ts,seq,at,None,None,T(json.dumps(a),300) if at in('queued_command','command_permissions') else '',None))
        elif t=='queue-operation':
            evs.append(('queue_'+str(d.get('operation')),ts,seq,T(d.get('content') or '',2500) if isinstance(d.get('content'),str) else '',None))
    return dict(path=p,dirname=dn,sess=sess,sub=sub,parent=parent,agent_type=agent_type,meta=json.dumps(meta) if meta else None,role=role,first=first,last=last,
                msgs=list(msgs.values()),tus=list(tus.values()),res=list(res.values()),users=users,evs=evs,atts=atts)
if __name__=='__main__':
    files=[]
    for d in os.listdir(B):
        if 'etsy-fulfillment-thanh' in d:
            for r,_,fs in os.walk(os.path.join(B,d)):
                for f in fs:
                    if f.endswith('.jsonl'): files.append(os.path.join(r,f))
    print(len(files),flush=True)
    if os.path.exists(OUT):os.remove(OUT)
    db=sqlite3.connect(OUT)
    db.executescript('''
    create table files(path text primary key,dirname,sess,sub,parent,agent_type,meta,role,first,last,nmsg,ntu);
    create table msgs(id text primary key,path,ts,model,inp,cr,cc,out,seq);
    create table tus(tuid text primary key,path,ts,seq,name,input,msgid);
    create table res(tuid text primary key,path,ts,seq,is_error,text,len);
    create table users(path,ts,seq,origin,src,text,uuid,ulen,refid,reslen);
    create table evs(path,kind,ts,seq,info);
    create table atts(path,ts,seq,atype,hook,exitcode,text,cmd);
    create table dups(kind,n);
    ''')
    dup={'msgs':0,'tus':0}
    results=[]
    with Pool(8) as pool:
        for i,r in enumerate(pool.imap_unordered(proc,files,chunksize=4)):
            results.append(r)
            if i%200==0:print(i,flush=True)
    results.sort(key=lambda r:(r['first'] or 'z'))
    for r in results:
        p=r['path']
        db.execute('insert into files values(?,?,?,?,?,?,?,?,?,?,?,?)',(p,r['dirname'],r['sess'],int(r['sub']),r['parent'],r['agent_type'],r['meta'],r['role'],r['first'],r['last'],len(r['msgs']),len(r['tus'])))
        for m in r['msgs']:
            c=db.execute('insert or ignore into msgs values(?,?,?,?,?,?,?,?,?)',(m[0],p,m[1],m[2],m[3],m[4],m[5],m[6],m[7]))
            if c.rowcount==0: dup['msgs']+=1
        for t in r['tus']:
            c=db.execute('insert or ignore into tus values(?,?,?,?,?,?,?)',(t[0],p,t[1],t[2],t[3],t[4],t[5]))
            if c.rowcount==0: dup['tus']+=1
        db.executemany('insert or ignore into res values(?,?,?,?,?,?,?)',[(x[0],p,x[1],x[2],x[3],x[4],x[5]) for x in r['res']])
        db.executemany('insert into users values(?,?,?,?,?,?,?,?,?,?)',[(p,)+u for u in r['users']])
        db.executemany('insert into evs values(?,?,?,?,?)',[(p,e[0],e[1],e[2],e[3]) for e in r['evs']])
        db.executemany('insert into atts values(?,?,?,?,?,?,?,?)',[(p,)+a for a in r['atts']])
    for k,v in dup.items():db.execute('insert into dups values(?,?)',(k,v))
    db.commit();print('done',dup)
