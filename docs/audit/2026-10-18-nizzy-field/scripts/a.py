import subprocess,re,collections,json,datetime
R="/Users/tranthien/Documents/2.DEV/2.PRIVATE/etsy-fulfillment-thanh"
def g(*a):
    return subprocess.run(["git","-C",R,*a],capture_output=True,text=True).stdout
SINCE="30 days ago"
out=g("log","main","--first-parent","--since="+SINCE,"--format=%H%x1f%P%x1f%cs%x1f%s%x1f%b%x1e")
recs=[r for r in out.split("\x1e") if r.strip()]
rows=[]
for r in recs:
    h,p,d,s,b=(r.strip("\n").split("\x1f")+[""]*5)[:5]
    m=re.match(r"^(Merge )?(TRA-\d+)\b",s)
    if not m or s.startswith("Merge origin") : continue
    parents=p.split()
    # branch commits
    if len(parents)==2:
        nb=int(g("rev-list","--count",parents[0]+".."+parents[1]).strip() or 0)
        subj=g("log","--format=%s",parents[0]+".."+parents[1]).splitlines()
        bodies=g("log","--format=%B%x1e",parents[0]+".."+parents[1])
        kind="merge"
    else:
        nb=1;subj=[s];bodies=b;kind="squash"
    full=s+"\n"+b
    rows.append(dict(h=h[:9],date=d,tid=m.group(2),kind=kind,nb=nb,subj=subj,full=full,bodies=bodies))
print(len(rows))
def cnt(rx,txt,fl=re.M): return len(re.findall(rx,txt,fl))
tot=collections.Counter()
wk=collections.defaultdict(collections.Counter)
tab=[]
for r in rows:
    f=r["full"];sj=r["subj"];bd=r["bodies"] if isinstance(r["bodies"],str) else ""
    allsubj="\n".join(sj)
    d=dict(
     simp=sum(1 for x in sj if x.startswith("simplify(increment)")),
     armt=sum(1 for x in sj if x.startswith("arm(ticket)")),
     arms=sum(1 for x in sj if x.startswith("arm(slice)")),
     qaw=sum(1 for x in sj if x.startswith("qa(walk)")),
     sup=cnt(r"^Supersedes:",bd+f),
     ledger=("present" if re.search(r"^Ledger:\s*\S",f,re.M) else "absent"),
     ledger_none=bool(re.search(r"^Ledger:\s*none",f,re.M|re.I)),
     pass_=cnt(r"^Pass:",bd+f),
     pass_skill=cnt(r"^Pass:.*Skill",bd+f),
     junior=cnt(r"^Implemented-by:",bd+f),
     fold=sum(1 for x in sj if re.search(r"fold|review|simplif|finding",x,re.I)),
     revert=sum(1 for x in sj if x.startswith("Revert")),
     armline=(re.search(r"^Arm:.*$",f,re.M) or [""])[0] if re.search(r"^Arm:.*$",f,re.M) else "",
    )
    r.update(d)
    dt=datetime.date.fromisoformat(r["date"]);wkk=dt.isocalendar()
    key=f"{wkk[0]}-W{wkk[1]:02d}"
    r["wk"]=key
    wk[key]["merged"]+=1;wk[key]["commits"]+=r["nb"]
    for k in("simp","armt","arms","qaw","sup","pass_","pass_skill","junior","fold","revert"):wk[key][k]+=d[k]
    wk[key]["ledger_absent"]+=d["ledger"]=="absent"
    wk[key]["ledger_none"]+=d["ledger_none"]
    wk[key]["armoff"]+=bool(re.search(r"Arm:\s*off",f))
json.dump([{k:v for k,v in r.items() if k not in("bodies",)} for r in rows],open("/tmp/nizzy-audit/a.json","w"),default=str)
cols=["merged","commits","simp","armt","arms","qaw","sup","pass_","pass_skill","junior","fold","revert","ledger_absent","ledger_none","armoff"]
print("| week | "+" | ".join(cols)+" |");print("|"+"---|"*(len(cols)+1))
T=collections.Counter()
for k in sorted(wk):
    print(f"| {k} | "+" | ".join(str(wk[k][c]) for c in cols)+" |")
    T.update(wk[k])
print("| TOTAL | "+" | ".join(str(T[c]) for c in cols)+" |")
print()
print("| tid | date | kind | commits | simp | arm(t) | arm(s) | qa(walk) | Supersedes | Ledger | Pass | Pass+Skill | Implemented-by | fold-ish | Arm line |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
for r in sorted(rows,key=lambda r:r["date"]):
    print(f"| {r['tid']} | {r['date']} | {r['kind']} | {r['nb']} | {r['simp']} | {r['armt']} | {r['arms']} | {r['qaw']} | {r['sup']} | {r['ledger']}{'(none)' if r['ledger_none'] else ''} | {r['pass_']} | {r['pass_skill']} | {r['junior']} | {r['fold']} | {r['armline'][:40]} |")
