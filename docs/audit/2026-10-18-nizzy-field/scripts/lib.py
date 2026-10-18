import sqlite3,json,re,collections,statistics
db=sqlite3.connect('/tmp/nizzy-audit/t.db')
C30='2026-09-18T00:00:00';C7='2026-10-11T00:00:00'
files={}
for r in db.execute('select path,dirname,sess,sub,parent,agent_type,role,first,last from files'):
    files[r[0]]=dict(path=r[0],dirname=r[1],sess=r[2],sub=r[3],parent=r[4],atype=r[5],role=r[6],first=r[7],last=r[8])
bysess={f['sess']:f for f in files.values() if not f['sub']}
def dirrole(dn):
    k=dn.split('thanh')[1] if 'thanh' in dn else dn
    if k=='':return 'main?'
    if 'builder' in k or 'ticket-tra' in k:return 'builder'
    if 'gate' in k or 'qa-walk' in k:return 'qa'
    if 'shaper' in k or 'spec-' in k:return 'shaper'
    return 'other:'+k.replace('--claude-worktrees-','')
for f in files.values():
    if f['sub']:
        p=bysess.get(f['parent'])
        f['prole']=p['role'] if p and p['role'] else (dirrole(f['dirname']))
    r=f['role']
    if r=='rin':r='qa'
    f['r']= r or dirrole(f['dirname']) if not f['sub'] else None
for f in files.values():
    if f['sub']:
        pr=f['prole']; pr='qa' if pr=='rin' else pr
        f['r']=pr
        f['rr']=pr
    else: f['rr']=f['r']
def ticket(f):
    m=re.search(r'(?:TRA|tra)-?(\d+)',f['dirname'])
    return 'TRA-'+m.group(1) if m else None
def win(ts):
    w=[]
    if ts and ts>=C30:w.append('30d')
    if ts and ts>=C7:w.append('7d')
    return w
WINS=['all','30d','7d']
def inwin(ts,w):
    return w=='all' or (ts or '')>=(C30 if w=='30d' else C7)

def loose(inp,keys=('to','message','skill','args','command','subagent_type','description','file_path','prompt','name','run_in_background','isolation')):
    try:
        d=json.loads(inp)
        if isinstance(d,dict):return d
    except Exception:pass
    d={}
    for k in keys:
        m=re.search(r'"%s": ?"((?:[^"\\]|\\.)*)'%k,inp)
        if m:
            s=m.group(1)
            try:s=json.loads('"'+s+'"')
            except Exception:
                s=s.replace('\\n','\n').replace('\\"','"')
            d[k]=s
    return d
