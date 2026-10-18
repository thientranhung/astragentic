import sys;sys.path.insert(0,'/tmp/nizzy-audit')
from lib import *
import datetime
OUT=[]
LIM='''
## 10. Limits of the method (what transcripts cannot show)

- **Silent successes are invisible.** A PreToolUse hook that allows a call leaves no line in the transcript, so hook-git-guard.py invocation counts are unknowable; only its denials are visible (section 3). The same holds for the mod gates: a passing tdd/arm/wait/merge gate leaves nothing. The refusal counts are numerator only, with no denominator of "times the gate evaluated and passed".
- **Mod UI output is not recorded.** `$.ui.status`, toasts, the status-line chips, the `RECEIVED` ack, `confirmed receipt`, `TURN-END held`, `readdressed`, `compaction skipped`, `context compacted at the Nk ceiling` and `recorded tab...` are rendered in the terminal or consumed by the mod. None of them is a transcript line. The only mod outputs that reach the model are bells (user turn, origin plugin), deny texts (tool_result), brief refusals (SendMessage result) and prompt-submit notes. Pane-screen captures that Thomas pasted back via herdr do contain the status text, but those are quotations and are excluded from every count.
- **The dispatch record is the better source for gates.** `.astraler/state/dispatch-record.json[key].refusals` and `skills_run` (written by `logRefusal`) hold refusal events and the Skill calls the merge gate checks. That file is outside the transcripts and was not read (read-only brief, no access requested).
- **Script "run" is a parse, not an exit.** Bash commands are matched textually. A script invoked inside another script (watchdog-probe.sh from herdr-watchdog.sh, lib/marker_field_parser.py from check-simplify-markers.sh, hooks from settings.json) is not seen as a Bash call. Commands over 8000 characters were truncated before matching. STOP/MISS/FAIL is a keyword hit in output, not a verdict.
- **Non-zero exit coverage.** Claude Code writes `Exit code N` into the tool_result text only when it is non-zero; a result without it is treated as exit 0. Background Bash calls (run_in_background) return only a launch acknowledgement, so their real exit is not in the call's own result.
- **Role is inferred.** Sessions without an `agent-setting` line (8 main-checkout sessions) are labelled `thomas(untagged)`; `rin` is merged into `qa`. Subagents take their parent's role. Spawns from a resumed or forked session may be attributed to the file where the line was first written.
- **Cost is an estimate from usage fields.** Only the supplied Sonnet 5 and Opus 5.5 rates were used; fable and haiku calls are priced at Opus and Sonnet rates. Opus cache-write was assumed at 2x input. Subscription billing, 1-hour cache premiums, batch discounts, and the advisor tool's separate model calls are not modelled; an advisor call appears in neither the parent usage nor as a subagent. `<synthetic>` messages (156) were excluded.
- **A skill counted once is not a skill that mattered.** Invocation shows a skill was loaded, not that it changed the output. Skills read by `Read` of a SKILL.md (column in section 9) were loaded without being invoked and can explain a zero.
- **Skill-by-ticket for Thomas and Shaper** uses the first `TRA-n` in the call arguments, so skills called without a ticket in the args (dispatch-ticket, dispatch-ticket-claude, dispatch-qa-walk, reconcile-tracker) show 0 tickets. They are session-scoped, not ticket-scoped.
- **Windows.** 30d starts 2026-09-18 and 7d starts 2026-10-11 at 00:00 UTC. The 7d window follows the 4.0.x releases; 30d spans earlier harness versions (the tdd/arm/wait gates, the brief `/` convention and the TURN-END bells only exist from about 2026-10-05, so their 30d totals are a fortnight of data, not a month). Transcripts before 2026-09-18 exist back to 2026-07-15 and were only used for the all-time columns of section 9.
- **Ticket attribution** for older Builder directories (`ticket-tra-NNN-slug`) and QA gate directories (`gate-*`) uses the number in the directory name; batch gates covering several tickets are attributed to the first.
- **Transcripts show what happened, not what a component prevented.** A refusal that stops a mistake is counted; a rule that is obeyed without ever firing (the agent never attempts the forbidden command) looks identical to a rule that is dead. Zero fires means either, and needs a planted-defect test to tell apart.
'''
def w(s=''):OUT.append(s)
def table(h,rows,al=None):
    w('| '+' | '.join(h)+' |');w('|'+'|'.join(['---']*len(h))+'|')
    for r in rows:w('| '+' | '.join(str(x) for x in r)+' |')
    w()
def rl(f):
    r=f['r']
    if r=='main?':return 'thomas(untagged)'
    if r and r.startswith('other'):return 'other'
    return r
for f in files.values():f['role_label']=rl(f)
def topsess(f):return f['parent'] if f['sub'] else f['sess']
ROLES=['thomas','thomas(untagged)','builder','shaper','qa','other']
# ---- global maps
tu_by_file=collections.defaultdict(list)
for tuid,p,ts,seq,name,inp in db.execute('select tuid,path,ts,seq,name,input from tus'):
    tu_by_file[p].append((seq,tuid,ts,name,inp))
for p in tu_by_file:tu_by_file[p].sort()
res={}
for tuid,p,ts,seq,ie,text,ln in db.execute('select tuid,path,ts,seq,is_error,text,len from res'):
    res[tuid]=(ie,text,ln,ts)
tuinfo={}
for p,L in tu_by_file.items():
    for seq,tuid,ts,name,inp in L:tuinfo[tuid]=(p,seq,ts,name,inp)
NOW='2026-10-18'
# ================= 0. coverage
w('# Harness usage measured from nizzy-ecom transcripts');w()
w(f'Generated from `~/.claude/projects/*etsy-fulfillment-thanh*` (read-only), extracted into sqlite `/tmp/nizzy-audit/t.db` by `/tmp/nizzy-audit/extract.py`; analysis `/tmp/nizzy-audit/analyze.py`. Windows: 30d = events with timestamp >= {C30}Z, 7d = >= {C7}Z (today 2026-10-18). Transcripts span '+db.execute('select min(first),max(last) from files').fetchone()[0][:10]+' to '+db.execute('select min(first),max(last) from files').fetchone()[1][:10]+'.');w()
w('## 0. Coverage and how sessions were told apart');w()
w('- **Top-level vs subagent**: by file path. A transcript at `<project-dir>/<session>.jsonl` is a top-level session. A transcript at `<project-dir>/<session>/subagents/agent-<id>.jsonl` is a subagent run, with `agent-<id>.meta.json` beside it giving `agentType`, `description`, `toolUseId`. No line in any file carried `isSidechain: true` that was needed; path is the discriminator. Fork subagents begin with a `fork-context-ref` line pointing at the parent session instead of copying its history.')
w('- **Role**: the `agent-setting` line of a top-level file (`thomas`, `builder`, `shaper`, `qa`, and the older name `rin`, merged into `qa` here). Files without that line are mapped by project directory name: `...thanh` (main checkout) = `thomas(untagged)`; `deploy-agent`, `harness-partner`, `design-partner`, `observer-*` = `other`. A subagent inherits the role of its parent session.')
w('- **Dedupe**: assistant messages by `message.id` (a streamed message appears on several lines; the line with the largest `output_tokens` is kept), tool_use by block `id`, tool_result by `tool_use_id`. Duplicates dropped across all files: '+str(dict(db.execute('select kind,n from dups').fetchall()))+' (resumed sessions re-copy few messages).')
rows=[]
for role in ROLES:
    top=[f for f in files.values() if not f['sub'] and f['role_label']==role]
    sub=[f for f in files.values() if f['sub'] and f['role_label']==role]
    def act(L,c):return sum(1 for f in L if (f['last'] or '')>=c)
    rows.append((role,len(top),act(top,C30),act(top,C7),len(sub),act(sub,C30),act(sub,C7)))
table(['role','top-level sessions (all)','active 30d','active 7d','subagent runs (all)','active 30d','active 7d'],rows)
w('Source: `files` table; "active" = last timestamp in the file inside the window. Counts of events below are by event timestamp, not file activity.');w()
# ================= 1. skills
w('## 1. Skill invocations');w()
BUILTIN_CMDS={'compact','clear','model','login','loop','advisor','feedback','reload-skills','config','help','fast'}
ev=[]  # (role,sess,ticket,skill,kind,ts)
def tk(f,txt):
    m=re.search(r'\b(?:TRA|tra)-?(\d{3,4})\b',txt or '')
    if m:return 'TRA-'+m.group(1)
    return ticket(f)
for p,L in tu_by_file.items():
    f=files[p]
    for seq,tuid,ts,name,inp in L:
        if name=='Skill':
            d=loose(inp);sk=(d.get('skill') or '').lstrip('/')
            t=ticket(f) if f['role_label']=='builder' else tk(f,str(d.get('args','')))
            ev.append((f['role_label'],topsess(f),t,sk,'tool',ts,f['sub']))
for p,ts,seq,t in db.execute("select path,ts,seq,text from users where text like '%<command-name>%'"):
    m=re.search(r'<command-name>/?([^<]*)</command-name>',t)
    if not m:continue
    sk=m.group(1).strip()
    f=files[p]
    a=re.search(r'<command-args>([^<]*)',t)
    tkt=ticket(f) if f['role_label']=='builder' else tk(f,a.group(1) if a else '')
    if sk in BUILTIN_CMDS:ev.append((f['role_label'],topsess(f),tkt,'/'+sk,'builtin',ts,f['sub']))
    else:ev.append((f['role_label'],topsess(f),tkt,sk,'slash',ts,f['sub']))
# body injections
body=[]
for p,ts,t in db.execute("select path,ts,substr(text,1,400) from users where text like 'Base directory for this skill:%'"):
    m=re.match(r'Base directory for this skill: (\S+)',t)
    pth=m.group(1).rstrip('/');nm=pth.split('/')[-1]
    f=files[p];body.append((f['role_label'],topsess(f),nm,ts))
# doc reads
docread=[]
for p,L in tu_by_file.items():
    f=files[p]
    for seq,tuid,ts,name,inp in L:
        if name in('Read','Bash','Grep'):
            for m in re.finditer(r'skills/([\w:-]+)/(?:SKILL\.md|[\w./-]+\.md)',inp):
                docread.append((f['role_label'],topsess(f),m.group(1),ts,name))
def sel(L,wn,idx_ts):return [e for e in L if inwin(e[idx_ts],wn)]
skills=sorted({e[3] for e in ev if e[4] in('tool','slash')})
def rowfor(sk):
    r=[sk]
    for wn in ('30d','7d'):
        t=[e for e in ev if e[3]==sk and e[4]=='tool' and inwin(e[5],wn)]
        s=[e for e in ev if e[3]==sk and e[4]=='slash' and inwin(e[5],wn)]
        ss={e[1] for e in t+s};tks={e[2] for e in t+s if e[2]}
        r+= [len(t),len(s),len(ss),len(tks)]
    return r
rows=[rowfor(sk) for sk in skills]
rows=[r for r in rows if r[1]+r[2]+r[5]+r[6]>0]
rows.sort(key=lambda r:-(r[1]+r[2]))
table(['skill','30d Skill-tool calls','30d slash-command','30d distinct sessions','30d distinct tickets','7d tool calls','7d slash','7d sessions','7d tickets'],rows)
w('Sources: Skill tool_use `input.skill` (tool); user turn containing `<command-name>/skill</command-name>` (slash, includes the brief `/mattpocock-skills:implement TRA-N` that the mod/Thomas sends a Builder); sessions = distinct top-level session ids (subagent counted under its parent); tickets = ticket in the worktree directory name (Builder) or first `TRA-n` in the args/command-args (other roles). Skill-tool calls made inside subagent runs are included.');w()
w('### 1b. Skill x role (30d, tool + slash counts, with 7d in brackets)');w()
rows=[]
for sk in skills:
    r=[sk]
    for role in ['thomas','thomas(untagged)','builder','shaper','qa','other']:
        a=len([e for e in ev if e[3]==sk and e[0]==role and e[4] in('tool','slash') and inwin(e[5],'30d')])
        b=len([e for e in ev if e[3]==sk and e[0]==role and e[4] in('tool','slash') and inwin(e[5],'7d')])
        r.append(f'{a} [{b}]' if a else '.')
    rows.append(r)
rows.sort(key=lambda r:r[0])
table(['skill','thomas','thomas(untagged)','builder','shaper','qa','other'],rows)
w('### 1c. Builtin slash commands seen (30d) with role');w()
c=collections.Counter((e[3],e[0]) for e in ev if e[4]=='builtin' and inwin(e[5],'30d'))
table(['command','role','30d count'],[(a,b,v) for (a,b),v in sorted(c.items())])
w('### 1d. Skill bodies injected into context (user turn `Base directory for this skill: <dir>/<name>`), 30d')
w()
c=collections.Counter();cs=collections.defaultdict(set)
for role,s,nm,ts in body:
    if inwin(ts,'30d'):c[(nm,role)]+=1;cs[(nm,role)].add(s)
table(['skill dir name','role','injections 30d','distinct sessions'],[(a,b,v,len(cs[(a,b)])) for (a,b),v in sorted(c.items(),key=lambda x:-x[1])])
w('Source: first line of the expanded skill text. This also catches skills loaded through a slash command or the brief, not just the Skill tool. The directory name is the last path segment, so `implement` is `mattpocock-skills:implement`.');w()
w('### 1e. Share of Builder tickets that used each phase skill (30d)');w()
bt30={ticket(f) for f in files.values() if f['role_label']=='builder' and not f['sub'] and (f['first'] or '')>=C30 and ticket(f)}
bt7={ticket(f) for f in files.values() if f['role_label']=='builder' and not f['sub'] and (f['first'] or '')>=C7 and ticket(f)}
rows=[]
for sk in ['mattpocock-skills:implement','mattpocock-skills:tdd','code-review','mattpocock-skills:code-review','simplify','codex-arm','bmad-ux','frontend-implement','golang-implement','omnilogin-agent-browser','astraler-omnilogin-agent-browser','atdd']:
    t30={e[2] for e in ev if e[3]==sk and e[0]=='builder' and e[4] in('tool','slash') and inwin(e[5],'30d') and e[2]}
    t7={e[2] for e in ev if e[3]==sk and e[0]=='builder' and e[4] in('tool','slash') and inwin(e[5],'7d') and e[2]}
    n30=sum(1 for e in ev if e[3]==sk and e[0]=='builder' and e[4] in('tool','slash') and inwin(e[5],'30d'))
    rows.append((sk,len(t30&bt30),f'{100*len(t30&bt30)//max(1,len(bt30))}%',f'{n30/max(1,len(t30&bt30)):.1f}',len(t7&bt7),f'{100*len(t7&bt7)//max(1,len(bt7))}%'))
table(['skill',f'30d Builder tickets using it (of {len(bt30)})','share','calls per using ticket','7d tickets (of '+str(len(bt7))+')','7d share'],rows)
w('Source: Builder top-level sessions started in the window (one worktree dir = one ticket id); skill events attributed to the ticket in the worktree directory name. A ticket can have several Builder sessions (restarts); each counts once.');w()
# ================= 2. scripts
w('## 2. Harness scripts run through Bash');w()
HS=['check-payload-drift.sh','check-reachability.py','check-simplify-markers.sh','docs-staleness-audit.sh','herdr-watch-terminal.sh','herdr-watchdog.sh','hook-contract-reload.py','hook-git-guard.py','hook-tracker-status.py','ledger-index.sh','ledger-rules.py','pre-push-ticket-done.sh','reap-worktree-processes.sh','release-worktree-resources.sh','selftest.sh','ticket-done.sh','ticket-git-facts.sh','lib/marker_field_parser.py','check-requirements.sh']
LOCAL=['gate-token.sh','herdr-prompt.sh','check-server-bans.sh','check-no-hardcoded-pg-port.sh','check-no-hardcoded-pg-port.sh']
PLUGS=['cleanup-worktree.sh','marker-output-check.sh','setup-worktree.sh','status-line.sh','ticket-done.sh','tracker-state.sh','tracker-status.sh','watchdog-probe.sh','work-in-flight.sh','refused-in-dispatched-panes','qa-report-path.sh']
def segs(cmd):
    cmd=cmd.replace('\\n','\n')
    return [s.strip() for s in re.split(r'&&|\|\||;|\||\n|\$\(|`',cmd) if s.strip()]
def runs(cmd,pathre):
    """True if some segment *runs* the script (first command token ends with it, after env vars / interpreter)."""
    for s in segs(cmd):
        toks=s.split()
        while toks and (re.match(r'^\w+=\S*$',toks[0]) or toks[0] in('exec','time','sudo','env','nohup','command')):toks.pop(0)
        if toks and toks[0] in('bash','sh','zsh','python3','python','/bin/bash'):
            toks.pop(0)
            while toks and toks[0].startswith('-'):toks.pop(0)
        if toks and re.search(pathre+r'$',toks[0].strip('"\'')):return True
    return False
bash_by=collections.defaultdict(list)
for p,L in tu_by_file.items():
    for seq,tuid,ts,name,inp in L:
        if name=='Bash':
            d=loose(inp);bash_by[p].append((seq,tuid,ts,d.get('command','') or ''))
def result_flag(tuid):
    r=res.get(tuid)
    if not r:return (None,False,False)
    ie,text,ln,_=r
    m=re.match(r'Exit code (\d+)',text)
    nz=bool(m and m.group(1)!='0') or (ie and not m and True)
    kw=bool(re.search(r'\b(STOP|MISS|FAIL(?:ED|URE)?)\b',text))
    return (nz,kw,True)
def scriptrows(names,prefixre,label):
    rows=[]
    for nm in names:
        pat=prefixre+re.escape(nm)
        cnt={'30d':collections.Counter(),'7d':collections.Counter()}
        for p,L in bash_by.items():
            f=files[p]
            for seq,tuid,ts,cmd in L:
                if not re.search(pat+r'(?![\w-])',cmd):continue
                ran=runs(cmd,pat)
                nz,kw,has=result_flag(tuid)
                for wn in('30d','7d'):
                    if not inwin(ts,wn):continue
                    c=cnt[wn]
                    c['mention']+=1
                    if ran:
                        c['run']+=1;c['run:'+f['role_label']]+=1
                        if nz:c['nz']+=1
                        if kw:c['kw']+=1
        rows.append((nm,cnt))
    return rows
def emit_scripts(rows,title):
    w(f'### {title}');w()
    out=[]
    for nm,cnt in rows:
        a,b=cnt['30d'],cnt['7d']
        roles=', '.join(f'{r}:{a["run:"+r]}' for r in ROLES if a['run:'+r]) or '.'
        out.append((nm,a['mention'],a['run'],a['nz'],a['kw'],roles,b['mention'],b['run'],b['nz'],b['kw']))
    table(['script','30d Bash calls naming it','30d run (first token)','30d non-zero exit / is_error','30d output has STOP/MISS/FAIL','30d runs by role','7d naming','7d run','7d non-zero','7d STOP/MISS/FAIL'],out)
emit_scripts(scriptrows(HS,r'(?<![\w.-])(?:[\w./~${}"-]*?/)?scripts/','Harness payload scripts (match `scripts/<name>` or `harness/scripts/<name>`)')if False else scriptrows(HS,r'scripts/','x'),'2a. Harness payload scripts (`scripts/<name>` or `harness/scripts/<name>`)')
emit_scripts(scriptrows(LOCAL[:4],r'scripts/','x'),'2b. Scripts in nizzy `scripts/` that are NOT in the harness payload (context only)')
emit_scripts(scriptrows(PLUGS,r'\.astraler/project/','x'),'2c. Project plugs (`.astraler/project/<name>`)')
# astragentic.sh
rows=scriptrows(['astragentic.sh'],r'\.astraler/','x')
emit_scripts(rows,'2d. `.astraler/astragentic.sh`')
w('Definitions: "naming it" = the Bash `input.command` contains the path (includes `cat`, `grep`, `git diff` of the file, heredocs that quote it). "run" = a command segment (split on `&&`, `||`, `;`, `|`, newline, `$(`) whose first token, after env assignments and an interpreter, ends with the path. "non-zero" = tool_result text starts with `Exit code N` (N != 0) or `is_error` true. "STOP/MISS/FAIL" = regex `\\b(STOP|MISS|FAIL|FAILED|FAILURE)\\b` anywhere in that tool_result text (a loose signal: selftest output prints the words in test names). Commands are truncated to 8000 chars in the extract, so a script named only past that point in a long heredoc is not seen.');w()
# hook attachments
w('### 2e. Script hooks seen as attachments (hooks that produced output or a recorded success)');w()
rows=[]
HK=['hook-git-guard.py','hook-contract-reload.py','hook-tracker-status.py','release-worktree-resources.sh']
for hk in HK:
    r=[hk]
    for wn in('30d','7d'):
        L=[(p,ts,ec) for p,ts,ec,cm in db.execute("select path,ts,exitcode,cmd from atts where cmd like ?",('%'+hk+'%',)) if inwin(ts,wn)]
        r+= [len(L),sum(1 for x in L if x[2] not in(0,None)), len({topsess(files[x[0]]) for x in L})]
    rows.append(r)
table(['hook script','30d attachments','30d exit!=0','30d sessions','7d attachments','7d exit!=0','7d sessions'],rows)
w('Source: `attachment` lines of type `hook_*` whose `command` contains the script name. Claude Code records an attachment only when a hook produced output or was blocking; a silent allow from hook-git-guard.py leaves no line, so this undercounts guard invocations. Denials are counted in section 3.');w()
# ================= 3. gates
w('## 3. Mod and hook outputs (gates, refusals)');w()
def classify(name,text):
    t=text
    if t.startswith('<tool_use_error>astragentic-dispatch:') or t.startswith('<tool_use_error>\nastragentic-dispatch:'):
        b=t.split('astragentic-dispatch:',1)[1].strip()
        if b.startswith('no record of mattpocock-skills:tdd'):return 'mod: tdd-gate'
        if b.startswith('no record of the built-in code-review'):return 'mod: arm-gate'
        if b.startswith('refused'):return 'mod: wait-gate'
        if b.startswith('no human is at this pane'):return 'mod: no-human-picker'
        if b.startswith('this command matches'):return 'mod: refused-command'
        if 'Closing it' in b[:200] or b.startswith('resident pane'):return 'mod: close-refusal'
        if b.startswith('cannot tell which worktree') or 'is not a worktree' in b[:200] or 'Removing its worktree' in b[:200] or b.startswith('releasing'):return 'mod: worktree-remove refusal'
        if 'has no record of:' in b[:200]:return 'mod: merge-gate'
        return 'mod: other ('+re.sub(r'\d+','N',b[:50])+')'
    if t.startswith('PreToolUse:') and 'hook error:' in t[:60]:
        b=t.split('hook error:',1)[1].strip()
        hk=t[:t.index(' hook')]
        if 'hook-agent-isolation-guard' in b[:300] or 'no isolation, dispatched from inside' in b[:200] or b.startswith('a sub-agent ('):return 'downstream hook-agent-isolation-guard (nizzy tools/, not payload)'
        if b.startswith('git add -A') or b.startswith('this line stages with'):return 'guard: git add -A / . refused'
        if 'no `Ledger:` line' in b[:200]:return 'guard: push main with merge lacking Ledger: line'
        if b.startswith('git worktree add needs an ABSOLUTE'):return 'guard: git worktree add relative path'
        if 'no ticket-done evidence' in b[:200]:return 'guard: push main without ticket-done stamp'
        if b.startswith('nothing has released'):return 'guard: worktree remove without release stamp'
        if b.startswith('rm -rf on a worktree'):return 'guard: rm -rf worktree'
        if 'has uncommitted changes' in b[:200]:return 'guard: worktree remove with uncommitted changes'
        if b.startswith('processes are still running'):return 'guard: worktree remove with live processes'
        if 'hook-git-guard' in b[:300] or 'hook-git-guard' in t[:400]:return 'guard: hook-git-guard (hook script failed or not found)'
        return 'guard: other ('+re.sub(r'\d+','N',b[:60])+')'
    if name=='SendMessage' and 'Not sent: a plugin hook refused it' in t[:200]:
        m=re.search(r'not sent\. (.{0,60})',t);b=(m.group(1) if m else '')
        if b.startswith('Payload files'):return 'mod: brief refused (payload edited/untracked)'
        if b.startswith('The tracker says'):return 'mod: brief refused (ticket not claimed)'
        if 'no ticket-done evidence' in t[:400] or b.startswith('TRA'):return 'mod: brief refused (base ticket with no ticket-done)'
        if b.startswith('The brief carries no') or b.startswith('QA'):return 'mod: brief refused (QA line/plan)'
        if b.startswith('A harness upgrade'):return 'mod: brief refused (upgrade incomplete)'
        return 'mod: brief refused (other)'
    return None
gates=[]  # (cls,role,ts,tuid,path,seq,sub)
for tuid,(ie,text,ln,rts) in res.items():
    inf=tuinfo.get(tuid)
    if not inf:continue
    p,seq,ts,name,inp=inf
    c=classify(name,text)
    if c:
        f=files[p];gates.append((c,f['role_label'],ts,tuid,p,seq,f['sub']))
cnt=collections.Counter();
for c,role,ts,*_ in gates:
    for wn in('30d','7d'):
        if inwin(ts,wn):cnt[(c,wn,role)]+=1
classes=sorted({g[0] for g in gates})
rows=[]
for c in classes:
    r=[c]
    for wn in('30d','7d'):
        tot=sum(cnt[(c,wn,ro)] for ro in ROLES)
        r.append(tot)
        r.append(', '.join(f'{ro}:{cnt[(c,wn,ro)]}' for ro in ROLES if cnt[(c,wn,ro)]) or '.')
    rows.append(r)
rows.sort(key=lambda r:-r[1])
table(['gate / refusal (by message text)','30d total','30d by role','7d total','7d by role'],rows)
w('Source: tool_result text anchored at the start of the result: `<tool_use_error>astragentic-dispatch: ...` (mod deny on Bash/Skill/etc.), `PreToolUse:<Tool> hook error: ...` (a settings.json PreToolUse hook; hook-git-guard.py reason text), and SendMessage results `Not sent: a plugin hook refused it ([astragentic-dispatch] not sent. ...)` (brief refusals). Results that merely quote these strings (cat/grep of register.tsx, pane screen captures, `box-pressure-check: REFUSING`) are excluded by the anchoring. The `permissionDecision` string appears in tool_results only inside file contents or docs (10 results, all quoted source), never as a live deny, because Claude Code turns a hook deny into the `hook error:` text above.');w()
# followups
w('### 3b. What the agent did after a refusal (next 3 tool calls in the same transcript, 30d refusals)');w()
def nextcalls(p,seq,n=3):
    L=tu_by_file[p];return [x for x in L if x[0]>seq][:n]
def norm_cmd(name,inp):
    d=loose(inp)
    return name+':'+(d.get('command') or d.get('skill') or d.get('file_path') or d.get('to') or inp)[:100]
fol=collections.defaultdict(lambda:collections.Counter())
fix=collections.defaultdict(lambda:collections.Counter())
for c,role,ts,tuid,p,seq,sub in gates:
    if not inwin(ts,'30d'):continue
    own=tuinfo[tuid]
    nx=nextcalls(p,seq)
    me=norm_cmd(own[3],own[4])
    # same command retried verbatim (first 100 chars) within next 3
    imm=bool(nx) and norm_cmd(nx[0][3],nx[0][4])==me
    late=any(norm_cmd(x[3],x[4])==me for x in nx[1:])
    if not nx:k='no further call (turn ended / session over)'
    elif imm:k='retried same command'
    elif late:k='did something else, then retried'
    else:k='changed course'
    fol[c][k]+=1
    # did the prescribed fix appear?
    if c=='mod: tdd-gate':
        fix[c]['called Skill mattpocock-skills:tdd within next 3' if any(x[3]=='Skill' and 'tdd' in x[4] for x in nx) else 'did not call tdd skill next']+=1
    if c=='mod: arm-gate':
        fix[c]['called Skill code-review within next 3' if any(x[3]=='Skill' and 'code-review' in x[4] for x in nx) else 'did not call code-review next']+=1
rows=[]
for c in sorted(fol):
    t=sum(fol[c].values())
    rows.append((c,t,fol[c]['changed course'],fol[c]['retried same command'],fol[c]['did something else, then retried'],fol[c]['no further call (turn ended / session over)'],'; '.join(f'{k}: {v}' for k,v in fix[c].items()) or '.'))
rows.sort(key=lambda r:-r[1])
table(['refusal','30d count','changed course','retried identical command as the very next call','did something else, then repeated it within 3 calls','no further call','did it do the prescribed fix'],rows)
w('Source: tool_use calls with a higher line index in the same file than the refused call. "Changed course" means none of the next three calls repeats the refused call; it does not prove the new call obeyed the refusal. Window: refusals in 30d.');w()
# examples of next-calls for mod gates
w('### 3c. First next call after each mod refusal class (most common, 30d)');w()
rows=[]
for c in ['mod: tdd-gate','mod: arm-gate','mod: wait-gate','mod: no-human-picker','mod: refused-command','mod: worktree-remove refusal','mod: close-refusal','mod: merge-gate','guard: git add -A / . refused','guard: push main without ticket-done stamp','guard: worktree remove without release stamp']:
    cn=collections.Counter()
    for cc,role,ts,tuid,p,seq,sub in gates:
        if cc!=c or not inwin(ts,'30d'):continue
        nx=nextcalls(p,seq,1)
        if nx:
            d=loose(nx[0][4]);lab=nx[0][3]
            if lab=='Skill':lab+=':'+str(d.get('skill'))
            elif lab=='Bash':lab+=':'+' '.join(str(d.get('command','')).split()[:3])[:40]
            cn[lab]+=1
    rows.append((c,'; '.join(f'{k} x{v}' for k,v in cn.most_common(4)) or '.'))
table(['refusal','top first next calls'],rows)
# bells / pane-echo
w('### 3d. Mod bells and notices that reach the model as user turns');w()
bell=collections.Counter()
def bellclass(t):
    if 'sent a message:' in t[:80] and '[astragentic-dispatch]' in t[:140]:
        if re.search(r'ended its turn \((\w+)\)',t[:300]):return 'TURN-END bell ('+re.search(r'ended its turn \((\w+)\)',t[:300]).group(1)+')'
        if 'has held its turn end' in t[:300]:return 'held bell (turn end held, builder still had agents)'
        if 'turn ends arrived while you were busy' in t[:300]:return 'batched bell (N turn ends arrived while you were busy)'
        return 'other mod message'
    if 'readdressed' in t[:300]:return 'readdressed notice'
    return None
bellrows=[]
for p,ts,o,t,seq in db.execute("select path,ts,origin,substr(text,1,400),seq from users where text like '%[astragentic-dispatch]%' or text like '%readdressed to the dispatcher%'"):
    c=bellclass(t)
    if c:
        f=files[p]
        for wn in('30d','7d'):
            if inwin(ts,wn):bell[(c,wn,f['role_label'])]+=1
cl=sorted({k[0] for k in bell})
rows=[]
for c in cl:
    r=[c]
    for wn in('30d','7d'):
        r.append(sum(bell[(c,wn,ro)] for ro in ROLES));r.append(', '.join(f'{ro}:{bell[(c,wn,ro)]}' for ro in ROLES if bell[(c,wn,ro)]) or '.')
    rows.append(r)
table(['bell','30d total','30d received by role (the session that read it)','7d total','7d by role'],rows)
w('Source: `user` lines with `origin.kind == "plugin"` and text `The astragentic-dispatch plugin sent a message: [astragentic-dispatch] <role> <key> ended its turn (answer|error|aborted)`. These are the TURN-END bells; they land in the dispatcher (Thomas) transcript. RECEIVED acks, the status-line toasts (`recorded tab..`, `confirmed receipt`, `TURN-END held`, `readdressed`, `compaction skipped`, `context compacted at the Nk ceiling`) go to `$.ui.status`/`toast` and the mod `consumed` path; they are not written to the transcript, so their count here is 0 by construction (see limits). A `No RECEIVED came back for:` note was seen '+str(db.execute("select count(*) from users where text like '%No RECEIVED came back for:%' and text like '%MOD prompt%'").fetchone()[0])+' times as a live note.');w()
# ================= 4 messaging per day
w('## 4. SendMessage / cross-session traffic per day (last 30 days)');w()
days=[(datetime.date(2026,10,18)-datetime.timedelta(days=i)).isoformat() for i in range(30,-1,-1)]
D=collections.defaultdict(collections.Counter)
for p,L in tu_by_file.items():
    f=files[p]
    for seq,tuid,ts,name,inp in L:
        if name=='SendMessage' and ts[:10] in days:
            d=loose(inp);m=d.get('message')
            D[ts[:10]]['SendMessage calls']+=1
            if isinstance(m,str) and m.lstrip().startswith('/'):D[ts[:10]]['briefs (first line starts with /)']+=1
            if isinstance(m,str) and f['role_label'].startswith('thomas') and re.search(r'\bbrief\b',m.split('\n')[0][:120],re.I) and not m.lstrip().startswith('/'):D[ts[:10]]['prose briefs from Thomas (first line has the word brief, heuristic)']+=1
            if isinstance(m,str) and re.match(r'\s*(TURN-END|RECEIVED)\b',m):D[ts[:10]]['agent-written TURN-END/RECEIVED text']+=1
for p,ts,o,t in db.execute("select path,ts,origin,substr(text,1,400) from users where origin='plugin' or origin='peer' or text like '%teammate-message%'"):
    if ts[:10] not in days:continue
    c=bellclass(t)
    if c and c.startswith('TURN-END'):D[ts[:10]]['TURN-END bells']+=1
    elif c and c.startswith('held'):D[ts[:10]]['held bells']+=1
    elif c and c.startswith('batched'):D[ts[:10]]['batched bells']+=1
    elif c=='readdressed notice':D[ts[:10]]['readdressed notices']+=1
    if o=='peer':D[ts[:10]]['peer messages received']+=1
for p,ts in db.execute("select path,ts from users where text like '%No RECEIVED came back for:%' and origin is null"):
    pass
cols=['SendMessage calls','briefs (first line starts with /)','prose briefs from Thomas (first line has the word brief, heuristic)','TURN-END bells','held bells','batched bells','peer messages received','readdressed notices','agent-written TURN-END/RECEIVED text']
rows=[[d]+[D[d][c] or '.' for c in cols] for d in days]
rows.append(['**total**']+[sum(D[d][c] for d in days) for c in cols])
table(['day (UTC)']+cols,rows)
w('Sources: SendMessage tool_use `input.message` (briefs = first non-blank character is `/`); user turns with `origin.kind == "plugin"` (mod bells), `origin.kind == "peer"` (cross-session message from another Claude session). "readdressed notices" is the mod string `a reply to "<x>" readdressed to the dispatcher`; it is a UI status, so a non-zero here would only be a quoted mention.');w()
w('Briefs by role of sender, 30d / 7d: '+', '.join(f'{ro}: {sum(1 for p,L in tu_by_file.items() if files[p]["role_label"]==ro for (seq,tuid,ts,name,inp) in L if name=="SendMessage" and isinstance(loose(inp).get("message"),str) and loose(inp)["message"].lstrip().startswith("/") and inwin(ts,"30d"))} / {sum(1 for p,L in tu_by_file.items() if files[p]["role_label"]==ro for (seq,tuid,ts,name,inp) in L if name=="SendMessage" and isinstance(loose(inp).get("message"),str) and loose(inp)["message"].lstrip().startswith("/") and inwin(ts,"7d"))}' for ro in ROLES));w()
# ================= 5 subagents
w('## 5. Subagent spawns (Agent tool)');w()
# map notification result lengths
notif={}
for refid,rlen,ts in db.execute("select refid,reslen,ts from users where refid is not null"):
    notif[refid]=rlen
sp=[]
for p,L in tu_by_file.items():
    f=files[p]
    last_skill=None
    for seq,tuid,ts,name,inp in L:
        if name=='Skill':last_skill=loose(inp).get('skill')
        if name in('Agent','Task'):
            d=loose(inp)
            st=d.get('subagent_type') or '(default general-purpose)'
            r=res.get(tuid)
            ln=notif.get(tuid)
            src='notification'
            if ln is None:
                ln=r[2] if r else None;src='tool_result'
            sp.append((f['role_label'],st,ts,last_skill,ln,src,f['sub'],tuid,p))
def stnorm(s):
    if re.match(r'^(angle|simplify|tra\d|standards|spec-|code-review|fork)',s) and s!='fork':return 'custom/ad-hoc name'
    return s
rows=[]
for wn in('30d','7d'):
    pass
agg=collections.defaultdict(lambda:collections.defaultdict(list))
for role,st,ts,ls,ln,src,sub,tuid,p in sp:
    for wn in('30d','7d'):
        if inwin(ts,wn):agg[(role,st)][wn].append(ln)
rows=[]
for (role,st),dd in agg.items():
    a=dd['30d'];b=dd['7d']
    med=lambda L:(int(statistics.median([x for x in L if x is not None])) if [x for x in L if x is not None] else '.')
    rows.append((role,st,len(a),med(a),len(b),med(b)))
rows.sort(key=lambda r:(-r[2]))
rows=[r for r in rows if r[2]>0 or r[4]>0]
table(['spawning role','subagent_type (Agent input)','30d spawns','30d median chars returned','7d spawns','7d median chars'],rows[:60])
if len(rows)>60:w(f'(+{len(rows)-60} more low-count rows omitted)');w()
w('Source: Agent tool_use `input.subagent_type` (empty means the default general-purpose type); role = role of the spawning session; chars returned = length of the `<result>` body in the later `task-notification` user turn for background spawns (joined by `tool-use-id`), else the length of the Agent tool_result. A subagent that is spawned from inside a subagent is attributed to the top-level role.');w()
w('### 5b. Skill phase active at spawn (last Skill call before the Agent call in the same transcript), 30d');w()
c=collections.Counter()
for role,st,ts,ls,ln,src,sub,tuid,p in sp:
    if inwin(ts,'30d'):c[(role,str(ls))]+=1
table(['role','last Skill called before spawn','30d spawns'],[(a,b,v) for (a,b),v in sorted(c.items(),key=lambda x:-x[1])[:25]])
w('"None" = no Skill call earlier in that transcript (spawn from the Builder transcript after its brief loaded the skill by slash command counts as None, because the slash command is a user turn, not a Skill call).');w()
w('### 5c. Subagent runs on disk by `agentType` from meta.json (all files, 30d by first timestamp)');w()
c=collections.Counter()
for f in files.values():
    if f['sub'] and (f['first'] or '')>=C30:
        t=f['atype'] or '(none)'
        c[(f['role_label'],'named/ad-hoc' if t not in('general-purpose','Explore','fork','Plan','rin-pr-reviewer','simplify-simplification','simplify-reuse','simplify-efficiency','simplify-altitude','code-scout','feature-dev:code-reviewer') and not t.startswith('astragentic-dispatch:') else t)]+=1
table(['parent role','agentType','runs started 30d'],[(a,b,v) for (a,b),v in sorted(c.items(),key=lambda x:-x[1])])
# ================= 6 cost
w('## 6. Cost per role');w()
P={'S':(2.0,10.0,0.20,4.0),'O':(4.0,20.0,0.20,8.0)}
def cost(i,cr,cc,o,k):
    pi,po,pcr,pcw=P[k];return (i*pi+cr*pcr+cc*pcw+o*po)/1e6
def fam(m):
    if not m:return 'S'
    if 'opus' in m or 'fable' in m:return 'O'
    return 'S'
agg=collections.defaultdict(lambda:collections.Counter())
modelmix=collections.defaultdict(collections.Counter)
for p,ts,model,i,cr,cc,o in db.execute('select path,ts,model,inp,cr,cc,out from msgs'):
    f=files[p]
    if model=='<synthetic>':continue
    key=(f['role_label'],'subagent' if f['sub'] else 'own')
    for wn in('30d','7d'):
        if inwin(ts,wn):
            a=agg[(key,wn)];a['calls']+=1;a['in']+=i;a['cr']+=cr;a['cc']+=cc;a['out']+=o
            a['S']+=cost(i,cr,cc,o,'S');a['O']+=cost(i,cr,cc,o,'O');a['asrun']+=cost(i,cr,cc,o,fam(model))
            modelmix[(key[0],wn)][model]+=1
for wn in('30d','7d'):
    w(f'### 6.{ "a" if wn=="30d" else "b"} {wn}');w()
    rows=[];tot=collections.Counter()
    for role in ROLES:
        for kind in('own','subagent'):
            a=agg.get(((role,kind),wn))
            if not a:continue
            rows.append((role,kind,a['calls'],f'{a["in"]:,}',f'{a["cr"]:,}',f'{a["cc"]:,}',f'{a["in"]+a["cr"]+a["cc"]:,}',f'{a["out"]:,}',f'${a["S"]:,.0f}',f'${a["O"]:,.0f}',f'${a["asrun"]:,.0f}'))
            for k in('calls','in','cr','cc','out','S','O','asrun'):tot[k]+=a[k]
    rows.append(('**total**','',tot['calls'],f'{tot["in"]:,}',f'{tot["cr"]:,}',f'{tot["cc"]:,}',f'{tot["in"]+tot["cr"]+tot["cc"]:,}',f'{tot["out"]:,}',f'${tot["S"]:,.0f}',f'${tot["O"]:,.0f}',f'${tot["asrun"]:,.0f}'))
    table(['role','own vs subagent','assistant calls (deduped by message.id)','input_tokens','cache_read','cache_creation','sum input+cache','output_tokens','est. @Sonnet 5 ($2/$10, read $0.20, write $4)','est. @Opus 5.5 ($4/$20, read $0.20, write $8*)','est. as-run (model per call)'],rows)
w('Source: `message.usage` of each deduped assistant message. *Opus cache-write price was not given; assumed 2x input ($8/M) to match the Sonnet 2x ratio. "As-run" prices each call by `message.model` family: opus-* and fable-* at the Opus rates, sonnet-* and haiku-* at the Sonnet rates (the haiku and fable rates were not supplied, so those ~700 calls are approximate). Thinking tokens are inside `output_tokens`. 1h-cache write premiums are not modelled.');w()
w('### 6c. Model used (assistant calls by `message.model`, 30d) per role');w()
rows=[]
for role in ROLES:
    mm=modelmix.get((role,'30d'))
    if mm:rows.append((role,'; '.join(f'{m}: {n}' for m,n in mm.most_common())))
table(['role','calls by model'],rows)
w('### 6d. Model per session (top-level sessions with a call in 30d; dominant model by call count)');w()
sm=collections.defaultdict(collections.Counter)
for p,ts,model in db.execute('select path,ts,model from msgs'):
    f=files[p]
    if f['sub'] or model=='<synthetic>' or not inwin(ts,'30d'):continue
    sm[p][model]+=1
c=collections.Counter()
for p,mm in sm.items():
    f=files[p];c[(f['role_label'],mm.most_common(1)[0][0],'mixed' if len(mm)>1 else 'single')]+=1
table(['role','dominant model','single/mixed within the session','sessions'],[(a,b,cc,v) for (a,b,cc),v in sorted(c.items())])
w('Subagent runs: a subagent line carries its own `message.model`; fork subagents showed `model: inherit` in meta.json. Section 6c includes subagent calls under their parent role.');w()
# ================= 7 compactions
w('## 7. Compactions');w()
rows=[]
cb=collections.defaultdict(list)
for p,k,ts,seq,info in db.execute("select path,kind,ts,seq,info from evs where kind in('compact_boundary','compact_summary')"):
    cb[p].append((k,ts,seq,info))
cnt=collections.Counter()
for p,L in cb.items():
    f=files[p]
    for k,ts,seq,info in L:
        if k=='compact_boundary':
            tr=json.loads(info).get('trigger')
            for wn in('30d','7d'):
                if inwin(ts,wn):cnt[(f['role_label'],tr,wn)]+=1
rows=[]
for role in ROLES:
    for tr in('manual','auto'):
        a=cnt[(role,tr,'30d')];b=cnt[(role,tr,'7d')]
        if a or b:rows.append((role,tr,a,b))
table(['role','trigger (compactMetadata.trigger)','30d `compact_boundary` events','7d'],rows)
# sudden drop heuristic
drops=collections.defaultdict(list)
for p in tu_by_file.keys() | set(files.keys()):
    pass
last=collections.defaultdict(lambda:None)
byfile=collections.defaultdict(list)
for p,ts,i,cr,cc,seq in db.execute('select path,ts,inp,cr,cc,seq from msgs order by path,seq'):
    byfile[p].append((seq,ts,i+cr+cc))
dropcnt=collections.Counter();dsess=collections.defaultdict(lambda:collections.Counter())
for p,L in byfile.items():
    f=files[p]
    prev=None
    for seq,ts,tot in L:
        if prev and prev>=50000 and tot<prev*0.5 and inwin(ts,'30d'):
            dropcnt[(f['role_label'],'sub' if f['sub'] else 'own')]+=1
            dsess[topsess(f)]['drops']+=1
        prev=tot
rows=[(a,b,v) for (a,b),v in sorted(dropcnt.items())]
w('Heuristic count: consecutive assistant messages in one transcript where total prompt tokens (input+cache read+cache write) fall by more than 50% and the earlier one was at least 50,000 tokens (30d):');w()
table(['role','own/subagent','drops >50%'],rows)
# per session list
w('### 7b. Per-session compaction count (30d, top-level sessions with at least one compact_boundary or drop)');w()
ps=collections.defaultdict(lambda:collections.Counter())
for p,L in cb.items():
    f=files[p]
    for k,ts,seq,info in L:
        if k=='compact_boundary' and inwin(ts,'30d'):ps[p]['boundary']+=1
for p,L in byfile.items():
    f=files[p];prev=None
    if f['sub']:continue
    for seq,ts,tot in L:
        if prev and prev>=50000 and tot<prev*0.5 and inwin(ts,'30d'):ps[p]['drop']+=1
        prev=tot
rows=[]
for p,c in sorted(ps.items(),key=lambda x:-(x[1]['boundary']+x[1]['drop'])):
    f=files[p]
    rows.append((f['sess'][:8],f['role_label'],f['dirname'].split('thanh')[1][-30:] or 'main',(f['first'] or '')[:10],c['boundary'],c['drop']))
table(['session','role','dir','first day','compact_boundary events','>50% drops'],rows[:40])
if len(rows)>40:w(f'(+{len(rows)-40} more sessions)');w()
w('Sources: `system` lines with `subtype == compact_boundary` and `compactMetadata.trigger`; `user` lines with `isCompactSummary` (same count as boundaries: '+str(db.execute("select count(*) from evs where kind='compact_summary'").fetchone()[0])+' all-time); the drop heuristic above. The mod auto-compaction at a context ceiling reports via `$.ui.status` and would appear as `trigger: manual`/`auto` boundary; the drop heuristic counts `/clear` resets and subagent restarts too. User `/compact` commands seen are in 1c.');w()
# ================= contract sections
w('## 8. Role contract sections vs what was measured');w()
SEC=[
('builder.md','Phases you own','Skill mattpocock-skills:implement (slash), mattpocock-skills:tdd, code-review, simplify, codex-arm, bmad-ux, atdd',['mattpocock-skills:implement','mattpocock-skills:tdd','code-review','mattpocock-skills:code-review','simplify','codex-arm','bmad-ux','atdd'],'builder'),
('builder.md','Load','legacy-testing, untangle, dispatch-junior',['legacy-testing','untangle','dispatch-junior'],'builder'),
('builder.md','With a junior','dispatch-junior, atdd',['dispatch-junior','atdd'],'builder'),
('builder.md','Handing back','scripts/check-simplify-markers.sh',['@script:check-simplify-markers.sh'],'builder'),
('builder-claude.md','Two gates the mod holds','tdd-gate, arm-gate',['@gate:mod: tdd-gate','@gate:mod: arm-gate'],'builder'),
('builder-claude.md','Long tickets','/compact, /clear',['/compact','/clear'],'builder'),
('thomas.md','Load','github-issue-tracker, reconcile-tracker, dispatch-ticket, dispatch-ticket-claude',['github-issue-tracker','jira-issue-tracker','linear-issue-tracker','reconcile-tracker','dispatch-ticket','dispatch-ticket-claude'],'thomas'),
('thomas.md','Phases you own','batch-triage, bootstrap-glossary, codex-arm, bmad-reviewer, mattpocock-skills:{triage,wayfinder,ask-matt,to-questionnaire}',['batch-triage','bootstrap-glossary','codex-arm','mattpocock-skills:triage','mattpocock-skills:wayfinder','mattpocock-skills:ask-matt','mattpocock-skills:to-questionnaire','@agent:astragentic-dispatch:bmad-reviewer'],'thomas'),
('thomas.md','Dispatch','/mattpocock-skills:grill-with-docs, dispatch-junior, dispatch-ticket*',['mattpocock-skills:grill-with-docs','dispatch-junior','dispatch-ticket','dispatch-ticket-claude'],'thomas'),
('thomas.md','Review','dispatch-qa-walk, simplify',['dispatch-qa-walk','simplify'],'thomas'),
('thomas.md','Slice gate','bmad-reviewer fan-out',['@agent:astragentic-dispatch:bmad-reviewer'],'thomas'),
('thomas.md','Merge','scripts/ticket-done.sh, merge-gate',['@script:ticket-done.sh','@gate:mod: merge-gate'],'thomas'),
('thomas.md','Watchdog','scripts/release-worktree-resources.sh, herdr-watchdog.sh, herdr-watch-terminal.sh',['@script:release-worktree-resources.sh','@script:herdr-watchdog.sh','@script:herdr-watch-terminal.sh'],'thomas'),
('thomas-claude.md','Dispatch routing / simplify verification','dispatch-ticket-claude, scripts/ticket-done.sh, simplify',['dispatch-ticket-claude','simplify'],'thomas'),
('shaper.md','Phases you own','mattpocock-skills:{grill-with-docs,to-spec,to-tickets}, test-design, codex-arm',['mattpocock-skills:grill-with-docs','mattpocock-skills:to-spec','mattpocock-skills:to-tickets','test-design','codex-arm'],'shaper'),
('shaper.md','Load','legacy-testing, untangle',['legacy-testing','untangle'],'shaper'),
('shaper.md','Align','bmad-party',['bmad-party'],'shaper'),
('shaper.md','STOP after Spec','/compact, /clear',['/compact','/clear'],'shaper'),
('qa.md','Load','bmad-ux, dispatch-qa-walk',['bmad-ux','dispatch-qa-walk'],'qa'),
('qa.md','Where the report lives','.astraler/project/qa-report-path.sh',['@script:qa-report-path.sh'],'qa'),
]
scr_cache={}
def script_runs(nm,role,wn):
    pat=(r'\.astraler/project/' if nm in PLUGS and nm not in HS else r'scripts/')+re.escape(nm)
    n=0
    for p,L in bash_by.items():
        if files[p]['role_label']!=role:continue
        for seq,tuid,ts,cmd in L:
            if inwin(ts,wn) and re.search(pat+r'(?![\w-])',cmd) and runs(cmd,pat):n+=1
    return n
rows=[]
for doc,sec,desc,ptrs,role in SEC:
    parts30=[];parts7=[]
    for ptr in ptrs:
        if ptr.startswith('@script:'):
            nm=ptr[8:];a=script_runs(nm,role,'30d');b=script_runs(nm,role,'7d');lab=nm
        elif ptr.startswith('@gate:'):
            g=ptr[6:];a=sum(1 for x in gates if x[0]==g and x[1]==role and inwin(x[2],'30d'));b=sum(1 for x in gates if x[0]==g and x[1]==role and inwin(x[2],'7d'));lab=g
        elif ptr.startswith('@agent:'):
            st=ptr[7:];a=sum(1 for s in sp if s[1]==st and s[0]==role and inwin(s[2],'30d'));b=sum(1 for s in sp if s[1]==st and s[0]==role and inwin(s[2],'7d'));lab='agent '+st.split(':')[1]
        else:
            a=sum(1 for e in ev if e[3]==ptr.lstrip('/') or e[3]==ptr if e[0]==role and e[4] in('tool','slash','builtin') and inwin(e[5],'30d'))
            b=sum(1 for e in ev if (e[3]==ptr.lstrip('/') or e[3]==ptr) and e[0]==role and e[4] in('tool','slash','builtin') and inwin(e[5],'7d'))
            lab=ptr
        parts30.append(f'{lab}={a}');parts7.append(str(b))
    rows.append((f'{doc} § {sec}',role,desc,'; '.join(parts30),'/'.join(parts7)))
table(['contract section','measured role','what the section points at','30d count per pointer, that role only','7d counts in same order'],rows)
w('Source: pointers extracted by regex from each `## ` section of `harness/.agents/roles/*.md`; counts are Skill-tool + slash-command invocations (skills), first-token Bash runs (scripts), refusals (gates) or Agent spawns (agents) by sessions of that role.');w()
# ================= 8 zero
w('## 9. Components with ZERO occurrences');w()
used30=collections.Counter();usedall=collections.Counter()
for e in ev:
    if e[4] in('tool','slash'):
        usedall[e[3]]+=1
        if inwin(e[5],'30d'):used30[e[3]]+=1
bodyall=collections.Counter(nm for r,s,nm,ts in body);body30=collections.Counter(nm for r,s,nm,ts in body if inwin(ts,'30d'))
dr30=collections.Counter(nm for r,s,nm,ts,k in docread if inwin(ts,'30d'));drall=collections.Counter(nm for r,s,nm,ts,k in docread)
INV_SK=['atdd','batch-triage','bmad-party','bmad-ux','bootstrap-glossary','codex-arm','dispatch-junior','dispatch-qa-walk','dispatch-ticket','dispatch-ticket-claude','github-issue-tracker','jira-issue-tracker','legacy-testing','linear-issue-tracker','reconcile-tracker','test-design','untangle']
PLG=['mattpocock-skills:tdd','mattpocock-skills:code-review','mattpocock-skills:implement','mattpocock-skills:to-spec','mattpocock-skills:to-tickets','mattpocock-skills:grill-with-docs','mattpocock-skills:triage','mattpocock-skills:wayfinder','mattpocock-skills:ask-matt','mattpocock-skills:to-questionnaire','mattpocock-skills:grilling','mattpocock-skills:domain-modeling','mattpocock-skills:diagnosing-bugs','mattpocock-skills:simplify','simplify','code-review']
rows=[]
for sk in INV_SK+PLG:
    short=sk.split(':')[-1]
    rows.append((sk,'harness skill' if sk in INV_SK else 'plugin/builtin skill',used30[sk],usedall[sk],body30[short],dr30[short],drall[short]))
table(['skill','kind','Skill-tool+slash 30d','all-time (since Jul 15)','body injected 30d','SKILL.md/doc read via Read/Bash/Grep 30d','doc reads all-time'],rows)
# agents
AG=['bmad-john','bmad-mary','bmad-murat','bmad-paige','bmad-reviewer','bmad-sally','bmad-winston']
rows=[]
for a in AG:
    st='astragentic-dispatch:'+a
    n30=sum(1 for s in sp if s[1]==st and inwin(s[2],'30d'));nall=sum(1 for s in sp if s[1]==st)
    fl30=sum(1 for f in files.values() if f['sub'] and f['atype']==st and (f['first'] or '')>=C30)
    rows.append((st,n30,nall,fl30))
table(['plugin agent','Agent spawns 30d','all-time','subagent transcripts started 30d'],rows)
# scripts zero
w('Scripts and hooks, 30d run count (zero rows are the candidates):');w()
rows=[]
for nm,cnt in scriptrows(HS,r'scripts/','x'):
    rows.append((nm,cnt['30d']['run'],cnt['30d']['mention']))
atts_by=collections.Counter()
for hk in HK:
    atts_by[hk]=db.execute("select count(*) from atts where cmd like ? and ts>=?",('%'+hk+'%',C30)).fetchone()[0]
rows=[(nm,r,m,atts_by.get(nm,'')) for nm,r,m in rows]
table(['script','Bash runs 30d','Bash mentions 30d','hook attachments 30d'],rows)
zero_gate=[g for g in ['mod: tdd-gate','mod: arm-gate','mod: wait-gate','mod: merge-gate','mod: refused-command','mod: close-refusal','mod: worktree-remove refusal','mod: no-human-picker','mod: brief refused (payload edited/untracked)','mod: brief refused (ticket not claimed)','mod: brief refused (QA line/plan)','mod: brief refused (base ticket with no ticket-done)','mod: brief refused (upgrade incomplete)','guard: git add -A / . refused','guard: push main without ticket-done stamp','guard: worktree remove without release stamp','guard: rm -rf worktree','guard: worktree remove with uncommitted changes','guard: worktree remove with live processes'] ]
rows=[(g,sum(1 for x in gates if x[0]==g and inwin(x[2],'30d')),sum(1 for x in gates if x[0]==g)) for g in zero_gate]
w('Gates, observed refusals:');w()
table(['gate','30d fires','all-time fires (since Jul 15)'],rows)
ZERO=[]
for sk in INV_SK+PLG:
    short=sk.split(':')[-1]
    if used30[sk]==0:ZERO.append(('skill',sk,'0 Skill/slash 30d; body injected %d; doc read %d'%(body30[short],dr30[short])))
for a in AG:
    st='astragentic-dispatch:'+a
    if not any(s[1]==st and inwin(s[2],'30d') for s in sp):ZERO.append(('plugin agent',st,'0 spawns 30d'))
for nm,cnt in scriptrows(HS,r'scripts/','x'):
    if nm in HK[:3]:
        n=atts_by.get(nm,0)
        if n==0:ZERO.append(('hook script',nm,'0 hook attachments 30d and 0 Bash runs (a silent allow leaves no trace)'))
        continue
    if nm.startswith('lib/'):
        ZERO.append(('library',nm,'not run directly (0 Bash runs); it is imported by check-simplify-markers.sh, so this is expected, not a finding'));continue
    if cnt['30d']['run']==0:ZERO.append(('script',nm,'0 runs 30d (%d mentions)'%cnt['30d']['mention']))
for nm,cnt in scriptrows(PLUGS,r'\.astraler/project/','x'):
    if cnt['30d']['run']==0:ZERO.append(('plug' if not nm.startswith('refused') else 'plug data file',nm,'0 runs 30d (%d mentions)%s'%(cnt['30d']['mention'],'; a regex list read by the mod, never run; its only observable effect is the refused-command gate, 0 fires' if nm.startswith('refused') else ('; may be called by another script, invisible to Bash logging' if nm in('watchdog-probe.sh','qa-report-path.sh') else ''))))
for g,a,b in rows:
    if a==0:ZERO.append(('gate',g,'0 fires 30d, %d all-time'%b))
w('### 9b. Explicit zero list (30 days)');w()
table(['kind','component','evidence'],ZERO)
OUT.append(LIM)
open('/tmp/nizzy-audit/transcripts.md','w').write('\n'.join(OUT))
print('ok',len(OUT))
