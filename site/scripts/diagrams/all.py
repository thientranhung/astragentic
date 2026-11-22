"""Regenerates every site diagram: python3 site/scripts/diagrams/all.py -> site/public/diagrams/<slug>.<lang>.html
All diagrams use an 800-unit viewBox so type is at its px floor when rendered 800 px wide (see dd_lib.py)."""
import os,sys
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from dd_lib import *
V="v6.1.19"
def mk(slug,lang,title,desc,eb): return D(slug,lang,title,desc,f"{eb} · ASTRAGENTIC {V}")
def T(lang): return lambda e,v: e if lang=='en' else v

def client_studio(lang):
    t=T(lang)
    d=mk('client-studio',lang,t("The client's studio","Studio của khách hàng"),
      t("Every role reads and writes the tracker; the owner talks to Thomas and opens BA directly; Quick Builder takes small work without a ticket.",
        "Mọi role đọc và ghi tracker; owner làm việc với Thomas và tự mở BA; Quick Builder nhận việc nhỏ không cần ticket."),t("TEAM","ĐỘI"))
    d.path([(400,104),(400,152)],'acc'); d.lab_v(400,104,152,t("TALKS TO","LÀM VIỆC VỚI"))
    d.path([(300,68),(124,68),(124,152)],dash=True); d.lab_h(124,300,68,t("OPENS","MỞ"))
    d.path([(500,188),(596,188)]); d.lab_h(500,596,188,"DISPATCH")
    d.path([(400,224),(400,304)],start=True); d.lab_v(400,224,304,"FRONTIER")
    d.path([(124,224),(124,304)],dash=True); d.lab_v(124,224,304,"TICKET")
    for cx,l in [(136,"SPEC"),(400,"RECEIPT"),(664,t("REPORT","BÁO CÁO"))]:
        d.path([(cx,376),(cx,448)],start=True); d.lab_v(cx,376,448,l)
    d.node('client',300,32,200,72,'input',t("CLIENT","KHÁCH"),"Owner",t("client seat","ghế khách hàng"))
    d.node('thomas',300,152,200,72,'focal',t("RESIDENT","THƯỜNG TRÚ"),"Thomas","deputy · claim, merge")
    d.node('ba',24,152,200,72,'optional',t("ON DEMAND","KHI CẦN"),"BA",t("user's seat · read-only","ghế người dùng · chỉ đọc"))
    d.node('quick-builder',596,152,180,72,'backend',t("PER TASK","MỖI VIỆC"),"Quick Builder",t("ops/* · no ticket","ops/* · không ticket"))
    d.node('tracker',24,304,752,72,'store',"TRACKER","Tracker",t("shared memory · GitHub · Jira · Linear","bộ nhớ chung · GitHub · Jira · Linear"))
    d.node('shaper',32,448,208,72,'backend',t("UNBROKEN","LIỀN MẠCH"),"Shaper","grill → spec → ticket")
    d.node('builder',296,448,208,72,'backend',t("PER TICKET","MỖI TICKET"),"Builder",t("one worktree","một worktree"))
    d.node('qa',560,448,208,72,'backend',t("PER WALK","MỖI LƯỢT"),"QA",t("walks the running product","chạy sản phẩm thật"))
    d.legend([('focal',"deputy"),('input',t("client","khách hàng")),('optional',t("opened by the owner","owner tự mở")),('store',t("shared state","trạng thái chung")),('backend',"role")],560)
    return d

def structure(lang):
    t=T(lang)
    d=mk('structure',lang,t("Four layers","Bốn lớp"),
      t("Runtime, harness, coordination and your project, with the parts each layer holds.","Runtime, harness, coordination và project của bạn, cùng các phần mỗi lớp giữ."),t("STRUCTURE","CẤU TRÚC"))
    ys=[32,140,248,356]
    d.band(ys[0],"01","Runtime",t("runs the agent","chạy agent"),'runtime')
    d.band(ys[1],"02","Harness",t("roles and rules","role và luật"),'harness')
    d.band(ys[2],"03","Coordination",t("state outside context","trạng thái ngoài context"),'coordination')
    d.band(ys[3],"04","Project",t("your repository","repo của bạn"),'project')
    y=lambda i:ys[i]+12; X=[232,412,592]; w=168
    d.node('runtime_claude',X[0],y(0),w,72,'backend',t("ALL ROLES","MỌI ROLE"),"Claude Code",t("every role runs here","mọi role chạy ở đây"))
    d.node('runtime_codex',X[1],y(0),w,72,'optional',"OVERLAY","Codex",t("second runtime","runtime thứ hai"))
    d.node('roles',X[0],y(1),w,72,'focal',t("6 ROLES","6 ROLE"),"Roles","custom agents")
    d.node('skills',X[1],y(1),w,72,'backend',t("20 SKILL DIRS","20 THƯ MỤC"),"Skills","astra-* + dispatch")
    d.node('hooks',X[2],y(1),w,72,'backend',t("6 EVENTS","6 SỰ KIỆN"),"Hooks","settings.json + 1 mod")
    d.node('tracker',X[0],y(2),w,72,'focal',t("STATE","TRẠNG THÁI"),"Tracker","GitHub · Jira · Linear")
    d.node('herdr',X[1],y(2),w,72,'backend',"HOST","Herdr · Orca",t("one host per session","một host mỗi session"))
    d.node('worktrees',X[2],y(2),w,72,'backend',t("ISOLATION","CÁCH LY"),"git worktree",t("one Builder, one tree","một Builder, một cây"))
    d.node(None,X[0],y(3),w,72,'input',t("YOURS","CỦA BẠN"),t("Your repository","Repo của bạn"),t("staged, never written","chỉ stage, không ghi"))
    d.legend([('focal',t("what Astragentic writes","phần Astragentic tự viết")),('backend',t("part","thành phần")),('optional',t("second runtime","runtime thứ hai")),('input',t("yours","của bạn"))],484)
    return d

def layer_map(lang):
    t=T(lang)
    d=mk('layer-map',lang,t("The stack, layer by layer","Stack theo từng lớp"),
      t("Tracker on top; Claude Code and Codex runtimes; Herdr and Orca hosts; git worktree and hook scripts at the bottom.",
        "Tracker ở trên; runtime Claude Code và Codex; host Herdr và Orca; git worktree và hook script ở dưới cùng."),"STACK")
    ys=[32,140,248,356]
    d.band(ys[0],"L1","Tracker",t("holds the state","giữ trạng thái"),'l1')
    d.band(ys[1],"L2","Runtime",t("runs each role","chạy từng role"),'l2')
    d.band(ys[2],"L3","Host",t("where panes live","chỗ các pane đứng"),'l3')
    d.band(ys[3],"L4",t("Isolation","Cách ly"),t("and guards","và chốt chặn"),'l4')
    y=lambda i:ys[i]+12; xa,xb,w=232,500,256
    d.node(None,xa,y(0),w*2+12,72,'store',"TRACKER","Issue tracker",t("GitHub · Jira · Linear · shared memory","GitHub · Jira · Linear · bộ nhớ chung"))
    d.node(None,xa,y(1),w,72,'focal',t("EVERY ROLE","MỌI ROLE"),"Claude Code",t("custom agent per role","custom agent theo role"))
    d.node(None,xb+12,y(1),w-12,72,'optional',"OVERLAY","Codex",t("second runtime","runtime thứ hai"))
    d.node(None,xa,y(2),w,72,'backend',t("DEFAULT","MẶC ĐỊNH"),"Herdr",t("one host per session","một host mỗi session"))
    d.node(None,xb+12,y(2),w-12,72,'backend',t("SINCE 6.1.0","TỪ 6.1.0"),"Orca",t("one host per session","một host mỗi session"))
    d.node(None,xa,y(3),w,72,'backend',t("ISOLATION","CÁCH LY"),"git worktree",t("one Builder, one tree","một Builder, một cây"))
    d.node(None,xb+12,y(3),w-12,72,'backend',t("GUARDS","CHỐT CHẶN"),"Python · Bash","hook scripts")
    d.legend([('focal',"runtime"),('backend',t("part","thành phần")),('optional',t("second runtime","runtime thứ hai")),('store',t("state","trạng thái"))],484)
    return d

def parallel_lanes(lang):
    t=T(lang)
    d=mk('parallel-lanes',lang,t("Parallel lanes","Các lane song song"),
      t("The tracker feeds claimable tickets to several Builders, each in its own worktree; Thomas merges the results into main.",
        "Tracker đưa ticket claimable cho nhiều Builder, mỗi Builder một worktree; Thomas merge kết quả vào main."),t("WORKTREES","WORKTREE"))
    cy=[76,184,292]
    d.path([(172,184),(196,184)],end=False); d.path([(196,76),(196,292)],end=False)
    for c in cy: d.path([(196,c),(220,c)])
    for c in cy: d.path([(452,c),(476,c)],end=False)
    d.path([(476,76),(476,292)],end=False); d.path([(476,184),(500,184)])
    d.path([(588,220),(588,284)]); d.lab_v(588,220,284,"MERGE")
    d.node('tracker',24,148,148,72,'store',"TRACKER","Tracker","frontier · claim")
    for i,c in enumerate(cy):
        d.node(None,220,c-36,232,72,'backend',t("PER TICKET","MỖI TICKET"),f"Builder {i+1}",t("own worktree · sole writer","worktree riêng, ghi độc quyền"))
    d.node('thomas',500,148,176,72,'focal',"GATE","Thomas",t("receipts · merge","receipt · merge"))
    d.node(None,500,284,176,72,'store',"MAIN","main",t("merged","đã merge"))
    d.legend([('store',t("state or store","trạng thái hoặc kho")),('backend',"Builder"),('focal',"Thomas")],396)
    return d

def ticket_lifecycle(lang):
    t=T(lang)
    d=mk('ticket-lifecycle',lang,t("One ticket, from claim to merge","Một ticket, từ claim đến merge"),
      t("Thomas claims and briefs; the Builder builds, reviews, simplifies once and runs the cross-vendor arm; Thomas merges on receipts.",
        "Thomas claim và brief; Builder build, review, simplify một lần và chạy cross-vendor arm; Thomas merge dựa trên receipt."),"TICKET")
    d.zone(24,32,752,116,"THOMAS · TRACKER, CLAIM, MERGE")
    d.zone(24,196,752,236,t("BUILDER · OWN WORKTREE","BUILDER · WORKTREE RIÊNG"),lx=260)
    X=[44,280,516]; w=192
    d.path([(236,96),(280,96)])
    d.path([(376,132),(376,172),(140,172),(140,224)]); d.label(258,172,"DISPATCH")
    d.path([(236,260),(280,260)]); d.path([(472,260),(516,260)])
    d.path([(612,296),(612,320),(140,320),(140,344)])
    d.path([(236,380),(280,380)])
    d.path([(472,380),(732,380),(732,96),(710,96)]); d.label(732,172,"HANDBACK")
    d.node('claim',X[0],60,w,72,'backend',"01","Claim","assignee, readback")
    d.node('brief',X[1],60,w,72,'backend',"02","Brief",t("dispatch into a pane","dispatch vào pane"))
    d.node('merge',X[2],60,w,72,'focal',"GATE","Merge",t("QA walk + receipts","QA walk + receipt"))
    d.node('implement',X[0],224,w,72,'backend',"BUILD","Build",t("test red first","test đỏ trước"))
    d.node(None,X[1],224,w,72,'optional',t("UI TICKETS","TICKET UI"),"UI pass","astra-ui audit")
    d.node('code_review',X[2],224,w,72,'backend',"REVIEW","Review",t("three lenses, once","ba lens, một lần"))
    d.node('simplify',X[0],344,w,72,'backend',"SIMPLIFY","Simplify",t("once, after last commit","một lần, cuối cùng"))
    d.node('arm',X[1],344,w,72,'focal',"ARM",t("Cross-vendor arm","Arm cross-vendor"),"pass 1 · fold · pass 2")
    d.legend([('focal',t("focal","trọng tâm")),('backend',t("step","bước")),('optional',t("optional","tùy chọn"))],480)
    return d

def ticket_states(lang):
    t=T(lang)
    d=mk('ticket-states',lang,t("A ticket's claim, state by state","Claim của một ticket, từng trạng thái"),
      t("Write the assignee, read it back, create the worktree; a different assignee or an existing branch means the claim is lost.",
        "Ghi assignee, đọc lại, tạo worktree; assignee khác hoặc branch đã tồn tại nghĩa là mất claim."),"CLAIM")
    X=[24,320,616]; w=160
    d.path([(184,68),(320,68)]); d.lab_h(184,320,68,t("WRITE","GHI"))
    d.path([(480,68),(616,68)]); d.lab_h(480,616,68,t("READ","ĐỌC LẠI"))
    d.path([(724,104),(724,152)]); d.lab_v(724,104,152,"MATCH")
    d.path([(650,104),(650,128),(400,128),(400,152)]); d.label(525,128,t("OTHER ASSIGNEE","ASSIGNEE KHÁC"))
    d.path([(616,188),(492,188)]); d.lab_h(492,616,188,t("BRANCH EXISTS","BRANCH ĐÃ CÓ"))
    d.path([(308,188),(104,188),(104,104)],dash=True); d.lab_h(104,308,188,t("NEXT TICKET","TICKET KẾ"))
    d.path([(696,224),(696,272)]); d.lab_v(696,224,272,"MERGE")
    d.node('unclaimed',X[0],32,w,72,'input',"START","Unclaimed",t("on the frontier","trên frontier"))
    d.node('claimed',X[1],32,w,72,'backend',"STATE","Claimed",t("assignee written","đã ghi assignee"))
    d.node('readback',X[2],32,w,72,'focal',t("DECISION","QUYẾT ĐỊNH"),"Readback",t("assignee re-read","đọc lại assignee"))
    d.node('lost',308,152,184,72,'security',t("LOST","MẤT CLAIM"),t("Claim lost","Mất claim"),t("assignee left as found","giữ nguyên assignee"))
    d.node('worktree',X[2],152,w,72,'backend',"STATE","Worktree","git worktree add -b")
    d.node('merged',X[2],272,w,72,'store',"END","Merged",t("assignee cleared","đã xóa assignee"))
    d.legend([('input','start'),('backend',t("state","trạng thái")),('focal',t("decision","quyết định")),('store',t("terminal success","kết thúc tốt")),('security',t("lost claim","mất claim"))],392)
    return d

def cross_vendor(lang):
    t=T(lang)
    d=mk('cross-vendor-arm',lang,t("Cross-vendor arm: one read-only codex exec","Cross-vendor arm: một lần codex exec, read-only"),
      t("The Builder's diff goes to codex exec; findings are folded and written as the arm(ticket) receipt; when Codex cannot run, the ticket falls back to the Opus adversarial lens.",
        "Diff của Builder đi qua codex exec; finding được fold và ghi thành receipt arm(ticket); khi Codex không chạy được, ticket rơi về lens adversarial của Opus."),"ARM")
    X=[24,304,584]; w=192
    d.path([(216,68),(304,68)]); d.lab_h(216,304,68,"DIFF")
    d.path([(496,68),(584,68)]); d.lab_h(496,584,68,t("FINDINGS","FINDING"))
    d.path([(680,104),(680,152)]); d.lab_v(680,104,152,t("WRITES","GHI"))
    d.path([(400,104),(400,152)]); d.lab_v(400,104,152,t("USAGE LIMIT","HẾT QUOTA"))
    d.path([(304,196),(216,196)],dash=True); d.lab_h(216,304,196,t("FALLBACK","DỰ PHÒNG"))
    d.path([(120,240),(120,272),(680,272),(680,240)],dash=True); d.label(400,272,t("ADVISORY","THAM KHẢO"))
    d.node(None,X[0],32,w,72,'backend',"BUILDER","Builder",t("diff at HEAD","diff tại HEAD"))
    d.node(None,X[1],32,w,72,'focal',"READ-ONLY","codex exec","gpt-6.2-astra · medium")
    d.node(None,X[2],32,w,72,'backend',"BUILDER",t("Fold findings","Fold finding"),t("then pass 2","rồi pass 2"))
    d.node(None,X[0],152,w,88,'optional',"OPUS","Opus adversarial",t("same vendor\nastra-review","cùng vendor\nastra-review"))
    d.node(None,X[1],152,w,88,'security',"NOT RUN","NOT RUN",t("never counted as pass","không tính là pass"))
    d.node(None,X[2],152,w,88,'store',"RECEIPT","arm(ticket):",t("merge refused without","thiếu thì merge\nbị từ chối"))
    d.legend([('focal',"codex exec"),('backend',t("step","bước")),('store',"receipt"),('security',"NOT RUN"),('optional',t("fallback","dự phòng"))],312)
    return d

def hooks(lang):
    t=T(lang)
    d=mk('hooks',lang,t("Hooks: six events and one mod","Hook: sáu sự kiện và một mod"),
      t("Claude Code runs seven commands across six settings.json events; the dispatch mod hooks in through the mod API instead.",
        "Claude Code chạy bảy lệnh trên sáu sự kiện trong settings.json; mod dispatch gắn vào qua mod API."),"HOOKS")
    cy=[68,152,236,320,404]
    d.path([(240,236),(264,236)],end=False); d.path([(264,68),(264,404)],end=False)
    for c in cy: d.path([(264,c),(288,c)])
    d.path([(132,272),(132,320)],dash=True); d.lab_v(132,272,320,"MOD API")
    d.node(None,24,200,216,72,'focal',"RUNTIME","Claude Code",t("6 events · 7 commands","6 sự kiện · 7 lệnh"))
    d.node(None,24,320,216,72,'optional',"MOD","Dispatch mod","astragentic-dispatch v1.0.3")
    rows=[("DENY","PreToolUse · Bash","hook-git-guard.py · "+t("git guard by role","git guard theo role")),
     ("LOG","PostToolUse · PostToolUseFailure · Bash","hook-test-run.py · "+t("logs each test run, failures too","ghi mỗi lần chạy test, cả lần fail")),
     ("RELOAD","SessionStart · compact","hook-contract-reload.py · "+t("re-arms the contract","nạp lại contract")),
     ("STATUS","SessionStart","hook-tracker-status.py · "+t("tracker state at start","trạng thái tracker đầu session")),
     ("LOG","SubagentStop · WorktreeRemove",t("writes harness-hook-events.log","ghi harness-hook-events.log"))]
    for c,(tg,n,s) in zip(cy,rows): d.node(None,288,c-36,488,72,'backend',tg,n,s)
    d.legend([('focal',"runtime"),('backend',"hook"),('optional',"mod")],480)
    return d

def skill_routing(lang):
    t=T(lang)
    d=mk('skill-routing',lang,t("Which skill each role runs","Mỗi role chạy skill nào"),
      t("A ticket comes off the tracker; Thomas dispatches it; Shaper, Builder and QA run their astra-* skills.",
        "Ticket được lấy từ tracker; Thomas dispatch; Shaper, Builder và QA chạy các skill astra-* của mình."),"SKILLS")
    C=[144,400,656]; X=[24,280,536]; w=240
    d.path([(400,104),(400,152)]); d.lab_v(400,104,152,"FRONTIER")
    d.path([(400,224),(400,264)],end=False); d.lab_v(400,224,264,"DISPATCH")
    d.path([(144,264),(656,264)],end=False)
    for cx in C: d.path([(cx,264),(cx,296)])
    for cx in C[:2]:
        for y in (368,464): d.path([(cx,y),(cx,y+24)])
    d.node('tracker',X[1],32,w,72,'store',"TRACKER",t("Ticket on the tracker","Ticket trên tracker"),"frontier query")
    d.node('dispatch_ticket',X[1],152,w,72,'focal',"THOMAS","dispatch-ticket","claim · worktree · pane")
    ys=[296,392,488]
    for y,(k,n,s) in zip(ys,[('grill',"astra-grill-with-docs",t("numbered questions","câu hỏi đánh số")),('to_spec',"astra-to-spec",t("spec onto the tracker","spec lên tracker")),('to_tickets',"astra-to-tickets",t("tracer-bullet tickets","ticket tracer-bullet"))]):
        d.node(k,X[0],y,w,72,'backend',"SHAPER",n,s)
    d.node('implement',X[1],296,w,72,'backend',"BUILDER","astra-implement-with-tdd",t("a red test per criterion","mỗi criterion một test đỏ"))
    d.node('review',X[1],392,w,72,'backend',"BUILDER","astra-review",t("three lenses, once","ba lens, một lần"))
    d.node('arm',X[1],488,w,72,'optional',"BUILDER","codex-arm",t("off when the arm row is no","tắt khi dòng arm là no"))
    d.node('qa_walk',X[2],296,w,72,'backend',"QA","dispatch-qa-walk","walk · probe · verify")
    d.legend([('store',"tracker"),('focal',"Thomas"),('backend',"skill"),('optional',t("optional","tùy chọn"))],600)
    return d

def frontier(lang):
    t=T(lang)
    d=mk('frontier-query',lang,t("The frontier query","Frontier query"),
      t("Open tickets, blocking edges and the assignee field feed the frontier query; its answer is the claimable board that Thomas, a Builder and the owner read.",
        "Ticket mở, blocking edge và trường assignee đi vào frontier query; câu trả lời là board claimable mà Thomas, Builder và owner đọc."),"TRACKER")
    C=[128,400,672]; X=[24,296,568]; w=208
    d.path([(400,104),(400,168)])
    for cx in (128,672): d.path([(cx,104),(cx,136),(400,136)],end=False)
    d.path([(400,240),(400,312)]); d.lab_v(400,240,312,t("WRITES","GHI"))
    d.path([(400,384),(400,416)],end=False)
    d.path([(128,416),(672,416)],end=False)
    for cx,dash in zip(C,(False,False,True)): d.path([(cx,416),(cx,448)],dash=dash)
    d.node('tickets',X[0],32,w,72,'store',"TRACKER",t("Open tickets","Ticket mở"),t("every open ticket","mọi ticket đang mở"))
    d.node('blocking_edges',X[1],32,w,72,'store',"TRACKER","Blocking edges",t("blocked_by graph","đồ thị blocked_by"))
    d.node('assignee_field',X[2],32,w,72,'store',"TRACKER",t("Assignee field","Trường assignee"),t("empty or held","trống hoặc đã giữ"))
    d.node('frontier_query',280,168,240,72,'focal',t("DERIVED","SUY RA"),"Frontier query",t("not remembered","không lưu trong trí nhớ"))
    d.node('board',280,312,240,72,'backend',"BOARD",t("Claimable board","Board claimable"),t("claimable, unclaimed","claimable, chưa claim"))
    d.node('thomas',X[0],448,w,72,'backend',t("RESIDENT","THƯỜNG TRÚ"),"Thomas",t("reruns after merge","chạy lại sau merge"))
    d.node('builder',X[1],448,w,72,'backend',t("PER TICKET","MỖI TICKET"),"Builder",t("claims, works","claim, làm việc"))
    d.node(None,X[2],448,w,72,'input',t("CLIENT","KHÁCH"),"Owner",t("reads the board","đọc board"))
    d.legend([('store',t("tracker field","trường tracker")),('focal',t("query","truy vấn")),('backend',t("board or role","board hoặc role")),('input',"owner")],560)
    return d

def six_roles(lang):
    t=T(lang)
    d=mk('six-roles',lang,t("Six roles, one front door","Sáu role, một đầu mối"),
      t("The owner talks to Thomas; Thomas dispatches Shaper, Builder, QA and Quick Builder; the owner opens BA directly.",
        "Owner làm việc với Thomas; Thomas dispatch Shaper, Builder, QA và Quick Builder; owner tự mở BA."),"ROLES")
    xs=[24,214,404,594]; w=182
    d.path([(400,104),(400,152)],'acc'); d.lab_v(400,104,152,t("TALKS TO","LÀM VIỆC VỚI"))
    d.path([(300,68),(124,68),(124,152)],dash=True); d.lab_h(124,300,68,t("OPENS","MỞ"))
    d.path([(400,224),(400,268)],end=False); d.lab_v(400,224,268,"DISPATCH")
    d.path([(xs[0]+w//2,268),(xs[3]+w//2,268)],end=False)
    for x in xs: d.path([(x+w//2,268),(x+w//2,296)])
    d.node('owner',300,32,200,72,'input',t("CLIENT","KHÁCH"),"Owner",t("client seat","ghế khách hàng"))
    d.node('thomas',280,152,240,72,'focal',t("RESIDENT","THƯỜNG TRÚ"),"Thomas","deputy · tracker, claim, merge")
    d.node('ba',24,152,200,72,'optional',t("ON DEMAND","KHI CẦN"),"BA",t("user's seat · read-only","ghế người dùng · chỉ đọc"))
    rows=[('shaper',t("UNBROKEN","LIỀN MẠCH"),"Shaper",t("grill → spec → ticket","grill → spec → ticket")),
      ('builder',t("PER TICKET","MỖI TICKET"),"Builder",t("one ticket · worktree","một ticket · worktree")),
      ('qa',t("PER WALK","MỖI LƯỢT"),"QA",t("walks running product","chạy sản phẩm thật")),
      ('quick-builder',t("PER TASK","MỖI VIỆC"),"Quick Builder",t("ops/* · no ticket","ops/* · không ticket"))]
    for x,(k,tg,n,s) in zip(xs,rows): d.node(k,x,296,w,72,'backend',tg,n,s)
    d.legend([('focal',"deputy"),('backend',t("dispatched role","role được dispatch")),('optional',t("opened by the owner","owner tự mở"))],408)
    return d

ALL=dict(client_studio=client_studio,structure=structure,layer_map=layer_map,parallel_lanes=parallel_lanes,ticket_lifecycle=ticket_lifecycle,
  ticket_states=ticket_states,cross_vendor=cross_vendor,hooks=hooks,skill_routing=skill_routing,frontier=frontier,six_roles=six_roles)
if __name__=='__main__':
    here=os.path.dirname(os.path.abspath(__file__))
    out=os.path.normpath(os.path.join(here,'..','..','public','diagrams'))
    os.makedirs(out,exist_ok=True)
    for n,f in ALL.items():
        for lang in ('en','vi'):
            d=f(lang)
            open(f"{out}/{d.slug}.{lang}.html",'w').write(d.html())
            print(d.slug,lang,d.W,d.H)
