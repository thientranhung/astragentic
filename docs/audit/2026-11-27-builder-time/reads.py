
import json, glob, os, re, datetime, collections, statistics as st
P=os.path.expanduser('~/.claude/projects')
NZ='/Users/tranthien/Documents/2.DEV/2.PRIVATE/etsy-fulfillment-thanh'
rec=json.load(open(NZ+'/.astraler/state/dispatch-record.json'))
rows=[]; filecount=collections.Counter(); dirc=collections.Counter()
for d in glob.glob(P+'/*etsy-fulfillment-thanh--claude-worktrees-builder-TRA-*'):
  key=re.search(r'builder-(TRA-\d+)',d).group(1)
  fs=[f for f in glob.glob(d+'/*.jsonl') if os.path.getmtime(f)>=datetime.datetime(2026,11,24).timestamp()]
  if not fs: continue
  ws=set((rec.get(key) or {}).get('write_set') or [])
  reads=[]; greps=0; shell_reads=0; edits=set(); compactions=0
  for f in fs:
    for line in open(f,errors='ignore'):
      try: j=json.loads(line)
      except: continue
      if j.get('type')=='system' and 'compact' in json.dumps(j)[:400].lower(): compactions+=1
      m=j.get('message',{}); cc=m.get('content') if isinstance(m,dict) else None
      if not isinstance(cc,list): continue
      for b in cc:
        if b.get('type')!='tool_use': continue
        n=b['name']; i=b.get('input') or {}
        if n=='Read':
          p=i.get('file_path',''); p=re.sub(r'.*/worktrees/builder-TRA-\d+/','',p); reads.append((p,i.get('offset')))
        elif n in('Grep','Glob'): greps+=1
        elif n in('Edit','Write','MultiEdit'):
          p=re.sub(r'.*/worktrees/builder-TRA-\d+/','',i.get('file_path','')); edits.add(p)
        elif n=='Bash':
          c=i.get('command','')
          if re.search(r'^\s*(cd [^;&]+(&&|;)\s*)?(rg|grep|cat|sed -n|head|tail|find|git (log|show|diff|grep|blame))\b',c): shell_reads+=1
  if len(reads)<5: continue
  pc=collections.Counter(p for p,_ in reads)
  distinct=len(pc); total=len(reads)
  reread=total-distinct
  edited_reads=sum(v for p,v in pc.items() if p in edits)
  for p in pc: filecount[p]+=1; dirc['/'.join(p.split('/')[:3])]+=1
  top=pc.most_common(3)
  rows.append(dict(edits=list(edits),key=key,total=total,distinct=distinct,reread=reread,edited_reads=edited_reads,greps=greps,shell_reads=shell_reads,compactions=compactions,top=top))
med=lambda a: sorted(a)[len(a)//2]
T=sum(r['total'] for r in rows); D=sum(r['distinct'] for r in rows); E=sum(r['edited_reads'] for r in rows)
docs=[p for p,c in filecount.most_common(400) if re.search(r'\.(md)$',p)]
json.dump(rows, open('/tmp/readrows.json','w'))
print(json.dumps(dict(n=len(rows), reads_total=T, distinct_total=D, reread_pct=round((T-D)/T*100,1), reads_of_edited_files_pct=round(E/T*100,1),
  med_reads=med([r['total'] for r in rows]), med_distinct=med([r['distinct'] for r in rows]), med_greps=med([r['greps'] for r in rows]), med_shell_reads=med([r['shell_reads'] for r in rows]),
  files_read_by_most_tickets=filecount.most_common(25), top_dirs=dirc.most_common(12),
  max_reread=sorted([(r['key'],r['top'][0]) for r in rows], key=lambda x:-x[1][1])[:8])))
