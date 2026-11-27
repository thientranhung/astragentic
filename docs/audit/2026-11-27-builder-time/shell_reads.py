
import json, glob, os, re, datetime, collections
P=os.path.expanduser('~/.claude/projects'); c=collections.Counter(); per=collections.Counter(); outsz=[]
for d in glob.glob(P+'/*etsy-fulfillment-thanh--claude-worktrees-builder-TRA-*'):
  for f in glob.glob(d+'/*.jsonl'):
    if os.path.getmtime(f)<datetime.datetime(2026,11,24).timestamp(): continue
    ids={}
    for line in open(f,errors='ignore'):
      try: j=json.loads(line)
      except: continue
      m=j.get('message',{}); cc=m.get('content') if isinstance(m,dict) else None
      if not isinstance(cc,list): continue
      for b in cc:
        if b.get('type')=='tool_use' and b['name']=='Bash':
          cmd=b['input'].get('command','')
          cmd2=re.sub(r'^\s*cd [^;&]+(&&|;)\s*','',cmd)
          w=cmd2.split()[0] if cmd2.split() else ''
          k = 'sed -n' if cmd2.startswith('sed -n') else ('git '+cmd2.split()[1] if w=='git' and len(cmd2.split())>1 else w)
          if k in ('grep','rg','sed -n','cat','head','tail','git log','git show','git diff','git grep','find','ls','wc','awk'):
            c[k]+=1; ids[b['id']]=k
        if b.get('type')=='tool_result' and b.get('tool_use_id') in ids:
          s=b.get('content'); s=s if isinstance(s,str) else json.dumps(s)
          per[ids[b['tool_use_id']]]+=len(s)
print(json.dumps({'counts':c.most_common(), 'chars':{k:per[k] for k in per}}))
