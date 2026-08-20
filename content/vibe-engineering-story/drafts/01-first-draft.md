# Code chạy chưa có nghĩa là đã ship: Từ Vibe Coding đến Vibe Engineering

Lần đầu dùng một AI coding agent đủ tốt, tôi có cảm giác khoảng cách giữa ý tưởng và phần mềm
đột nhiên co lại.

Tôi mô tả thứ mình muốn bằng ngôn ngữ tự nhiên. Agent đọc codebase, tìm đúng file, tạo
component, sửa lỗi và chạy test. Một công việc trước đây mất vài giờ có thể hoàn thành trong
vài phút. Những vòng lặp nhỏ — đổi một trạng thái, thêm một endpoint, sửa một interaction —
trở nên nhanh đến mức gần như không còn ma sát.

Đó là cảm giác rất dễ gây nghiện.

Bạn nghĩ ra một thứ. Bạn nói ra. Code xuất hiện.

Đây là điều tuyệt vời nhất của Vibe Coding: nó giải phóng chúng ta khỏi một phần lớn chi phí
để biến ý định thành code.

Nhưng rồi tôi thử dùng cách đó cho một feature thật.

Không phải một button. Không phải một function. Một feature có mười ticket, nhiều dependency,
chạm vào code cũ và cần nhiều phiên làm việc để hoàn thành.

Tôi mở ba agent cùng lúc.

Một agent hoàn thành sớm. Một agent đang đợi thứ mà agent đầu tiên chưa merge. Agent còn lại
dừng giữa chừng, nhưng không có gì báo cho tôi biết nó đã dừng. Hai agent cùng chạm vào một
module. Năm câu hỏi đến gần như đồng thời. Câu đầu có thể trả lời trong vài giây. Câu thứ hai
cần đọc lại code. Câu thứ ba liên quan đến một quyết định sản phẩm từ tuần trước.

Tôi không còn chỉ xây sản phẩm nữa.

Tôi trở thành router, project manager, reviewer, debugger và bộ nhớ chung cho một đội AI mà
chính mình vừa tạo ra.

> **[HÌNH 01 — Hero]** Một developer trước “engineering cockpit”: tracker, terminal panes,
> dependency graph và sản phẩm đang chạy. Tránh hình robot hoặc não AI chung chung.

## Một agent giỏi không tự tạo thành một đội giỏi

Một AI coding agent có thể làm rất tốt một task. Nhưng một sản phẩm thật không chỉ có một
task.

Một feature đi qua nhiều trạng thái:

```text
Ý tưởng
  → Làm rõ yêu cầu
  → Spec
  → Chia task
  → Quản lý dependency
  → Implement
  → Review
  → Merge
  → QA
```

Agent đang implement một ticket không tự nhiên biết nó đang đứng ở đâu trong vòng đời đó. Nó
không biết ticket nào nên chạy tiếp theo. Nó không biết một agent khác đang viết cùng file.
Nó không biết câu hỏi nào có thể tự giải quyết từ codebase và câu hỏi nào phải đưa về owner.
Nó cũng không biết lời báo cáo “done” của mình sẽ được ai xác minh, bằng cách nào.

Nếu chỉ spawn thêm agent, chúng ta có thêm năng lực tạo code. Chúng ta chưa có thêm năng lực
điều hành engineering.

Đây là ranh giới tôi thấy giữa **Vibe Coding** và **Vibe Engineering**.

| Vibe Coding | Vibe Engineering |
|---|---|
| Tối ưu một prompt | Tối ưu toàn bộ vòng đời feature |
| Tạo code nhanh | Ship thay đổi an toàn |
| Một agent, một context | Nhiều role, nhiều session |
| Tin vào câu trả lời | Xác minh bằng artifact |
| “Done” khi agent báo xong | “Done” khi code, test, review và QA có bằng chứng |
| Context là bộ nhớ | Tracker và Git là bộ nhớ |
| Con người điều phối thủ công | Hệ thống điều phối theo protocol |

Vibe Coding không sai. Nó chỉ dừng quá sớm.

Nó giải quyết rất tốt khoảnh khắc code được tạo ra. Nhưng khi tốc độ tạo code tăng lên, phần
còn lại của engineering không biến mất. Ownership, isolation, coordination, review,
observability, provenance và recovery trở nên quan trọng hơn, không phải ít hơn.

> **[HÌNH 02 — Diagram]** Bên trái: `Prompt → Code`. Bên phải:
> `Intent → Spec → Tickets → Build → Review → QA → Merge`.

## Một đội AI cũng cần quản lý dự án như một đội ngoài đời

Ngoài đời, một engineering team không nhận một câu mô tả rồi tất cả cùng lao vào viết code.

Team có thể nhận một spec tương đối rõ, một feature request còn thiếu chi tiết, hoặc đôi khi
chỉ là một ý tưởng. Trước khi build, một người phải hiểu mục tiêu thật sự là gì, điều gì nằm
ngoài scope, hệ thống hiện tại đang vận hành ra sao và feature sẽ chạm vào những module, dữ
liệu hay user journey nào.

Sau đó team phải chia công việc.

Task nào có thể làm độc lập? Task nào bị block? Hai task không có dependency nghiệp vụ nhưng
có cùng sửa một module hay không? Acceptance criteria nào chứng minh task đã hoàn thành? Ai
sẽ làm? Khi nào nên bắt đầu? Khi một người bị block, ai là người gỡ?

Đó là project management ở dạng rất đời thường.

Một đội AI không được miễn khỏi những câu hỏi này. Model thông minh hơn không loại bỏ project
management. Nó chỉ khiến project management trở thành bottleneck tiếp theo mà chúng ta phải
thiết kế.

Quy trình có thể được tóm lại như sau:

1. **Nhận spec hoặc feature:** hiểu owner intent và kết quả mong muốn.
2. **Phân tích:** đọc codebase, xác định constraint, dependency, seam và blast radius.
3. **Chia task:** mỗi task đủ nhỏ cho một session, có acceptance criteria kiểm chứng được.
4. **Quản trị task:** ghi trạng thái, blocking edge, ownership và vùng code dự kiến thay đổi.
5. **Phân phối task:** chỉ giao những task đang sẵn sàng và không va chạm nhau.
6. **Theo dõi và gỡ block:** phát hiện agent đang chờ, đã dừng hoặc cần quyết định.
7. **Tích hợp:** review, QA, merge theo dependency rồi mở những task tiếp theo.

Đến đây, orchestration không còn có nghĩa là “gọi nhiều agent cùng lúc”.

**Orchestration là project management được mã hóa thành protocol.**

> **[CLIP 01 — 20–30 giây]** Mở một feature/spec → hiện dependency graph → highlight ticket
> đang bị block → claim hai ticket trên frontier → hai terminal pane xuất hiện với đúng ticket
> ID.

## Astragentic là gì?

Astragentic là operating framework giúp nhiều AI agent cùng phát triển phần mềm trên một
codebase thật.

Nó không tạo ra một model mới. Nó cũng không thay thế Claude Code, OpenAI Codex hay OpenCode.
Những runtime đó vẫn là nơi agent suy nghĩ, đọc code và thực hiện công việc.

Astragentic tổ chức chúng thành một đội có vai trò, ranh giới và vòng đời rõ ràng.

Mục tiêu của framework là trả lời bốn câu hỏi:

1. Làm thế nào để nhiều agent làm việc song song mà không đụng nhau?
2. Làm thế nào để owner nhìn thấy công việc đang diễn ra?
3. Làm thế nào để agent chỉ đưa con người vào những quyết định thực sự cần con người?
4. Làm thế nào để biết một bước đã thực sự chạy, thay vì chỉ tin agent nói rằng nó đã chạy?

Kiến trúc tổng thể nhìn như thế này:

```text
Owner / Issue Tracker
          ↓
Thomas — orchestration layer
          ↓
Shaper · Builder · Rin · QA
          ↓
Claude Code · Codex · OpenCode
          ↓
Git worktrees · Herdr · Tests · Browser
```

Issue tracker giữ trạng thái công việc. Git giữ sự thật về code. Herdr làm cho các agent đang
chạy trở nên nhìn thấy được. Role contract xác định mỗi agent chịu trách nhiệm cho giai đoạn
nào. Các artifact như commit, test output và gate report chứng minh điều gì đã thực sự xảy ra.

## Từ một feature đến một dependency graph

Hãy quay lại feature có mười ticket.

Trong một workflow thông thường, chúng ta dễ bắt đầu bằng cách đưa feature cho một agent và
yêu cầu nó “lên plan”. Nhưng một plan đẹp chưa chắc đã giải quyết được các quyết định đang
mở. Nếu các quyết định đó đi thẳng vào implementation, reviewer sẽ phải xử lý chúng ở giai
đoạn đắt nhất.

Astragentic cố tình đặt vòng lặp ở đầu quy trình.

Nếu effort còn mơ hồ và lớn hơn một session, Thomas bắt đầu bằng wayfinding. Nếu scope vừa một
session shaping, Shaper đi thẳng vào quá trình làm rõ yêu cầu. Shaper giữ requirements, spec
và ticket graph trong một context liền mạch để không đánh mất toàn bộ bức tranh giữa chừng.

Mỗi câu trả lời quan trọng phải có nguồn. Nguồn có thể là codebase, một ADR cũ, research, một
prototype hoặc quyết định của owner. Nếu không có nguồn, câu hỏi vẫn được xem là đang mở.

Sau đó spec được tạo ra. Nhưng Shaper chưa cắt ticket ngay.

Spec dừng lại để được review trước. Đây là một điểm nhỏ nhưng quan trọng: sửa một seam sai
trong spec có thể chỉ mất một đoạn văn; phát hiện nó sau khi mười ticket đã được build có thể
mất cả một slice.

Khi spec đã đủ chắc, nó được chia thành các ticket có thể thực hiện trong một session. Các
blocking edge tạo thành dependency graph. Từ graph đó, Thomas có thể xác định **frontier**:
tập hợp các ticket không còn blocker và chưa được ai claim.

> **[HÌNH 03 — Diagram]** Feature → Spec + constraints → Dependency graph → Frontier.

## Claim trước, worktree sau

Khi có nhiều Builder, câu hỏi “ai đang làm ticket này?” không thể chỉ được trả lời trong một
đoạn chat.

Trong Astragentic, assignee trên tracker là claim. Thomas ghi assignee trước khi tạo
worktree, sau đó đọc lại ticket để xác nhận claim thuộc về đúng dispatch. Chỉ khi claim giữ
được, branch và worktree mới được tạo.

Mỗi Builder nhận một chuỗi identity riêng:

```text
ticket → assignee → pane → worktree → branch → PR
```

Builder là người duy nhất ghi trong worktree đó. Thomas, reviewer và các Builder khác chỉ đọc.

Worktree giải quyết collision ở checkout, nhưng chưa đủ để giải quyết collision khi merge.
Hai ticket có thể không block nhau về nghiệp vụ nhưng vẫn cùng sửa một module. Vì vậy mỗi
dispatch còn có write-set: vùng file dự kiến thay đổi. Nếu write-set giao nhau, Thomas phải
xếp chúng tuần tự hoặc điều chỉnh seam trước khi chạy song song.

Đây là một ví dụ điển hình về khác biệt giữa prompt và engineering mechanism. Viết thêm vào
prompt rằng “đừng conflict với agent khác” không tạo ra atomic claim, không tạo ra checkout
riêng và cũng không cho agent biết một worktree khác đang sửa gì.

> **[CLIP 02 — 8–12 giây]** Hai Builder chạy song song trong hai Herdr pane. Hiển thị ticket
> ID, branch và cwd khác nhau.

## Năm vai trò, năm ranh giới trách nhiệm

Astragentic dùng năm vai trò. Chúng không được chia theo cấp bậc senior hay junior; chúng được
chia theo session boundary và loại context mà mỗi giai đoạn cần.

### Thomas — router thường trú

Thomas tồn tại xuyên nhiều ticket và nhiều phase. Nó quản lý frontier, claim công việc,
dispatch agent, theo dõi trạng thái và xác minh artifact trước khi merge.

Thomas cũng là bộ lọc quyết định. Câu hỏi kỹ thuật có thể trả lời từ convention hoặc codebase
thì Thomas tự giải quyết và ghi nguồn. Câu hỏi thay đổi scope, sản phẩm hoặc risk thuộc owner
thì được đưa về con người.

Mục tiêu không phải loại con người khỏi quy trình. Mục tiêu là chỉ kéo con người vào nơi phán
đoán của họ tạo ra giá trị lớn nhất.

### Shaper — người giữ toàn bộ bức tranh

Shaper chạy quá trình làm rõ, viết spec và cắt ticket trong một context liền mạch. Đây là nơi
quyết định seam, module boundary và dependency khi toàn bộ feature vẫn còn trong context.

Nếu những quyết định đó được để cho từng Builder tự giải quyết, mỗi Builder sẽ tối ưu ticket
của mình nhưng không ai tối ưu toàn bộ feature.

### Builder — một ticket, một session

Mỗi Builder biết rõ một ticket thay vì biết mơ hồ mười ticket. Nó có một branch, một worktree,
một pane và một contract hoàn thành rõ ràng.

Builder implement, chạy test, review increment của mình, thực hiện simplify pass và tạo bằng
chứng browser nếu thay đổi thứ người dùng nhìn thấy.

### Rin — reviewer đối kháng

Rin chạy trong một pane và detached worktree riêng tại đúng SHA cần review. Rin không ngồi
trong checkout của Builder và không sửa code ở đó.

Nhiệm vụ của Rin là đưa ra một second opinion và kiểm tra xem quy trình có để lại dấu vết mà
nó phải để lại hay không: acceptance criteria, validation output, simplify marker, browser
evidence và gate report.

### QA — sử dụng sản phẩm, không chỉ đọc diff

Rin đọc thay đổi. QA sử dụng sản phẩm đang chạy.

QA nhìn vào interface, journey, API contract và dữ liệu như người dùng trải nghiệm. Một test
suite xanh chỉ chứng minh những điều ai đó đã nghĩ tới để assert. Nó không phát hiện một
control tồn tại nhưng không ai nhìn thấy, một trạng thái selected trông như unselected hoặc
hai màn hình đang hiển thị hai con số khác nhau cho cùng một khái niệm.

> **[HÌNH 04 — Role map]** Mapping giữa team ngoài đời và Astragentic: owner, delivery lead,
> product/technical design, engineers, reviewer và QA.

## Review không nên là một vòng lặp vô tận

Phiên bản trước của phương pháp này từng đo được từ 5 đến 14 vòng review cho một plan hoặc
slice.

Các vòng review rất kỹ. Kết quả cuối thường tốt. Nhưng throughput thì không.

Một pattern lặp lại xuất hiện: vòng thứ hai thêm một cơ chế bảo vệ, vòng thứ ba nhận ra cơ chế
đó tạo false confidence và bỏ nó, những vòng sau tiếp tục dọn phần văn bản hoặc design còn sót
lại từ những vòng trước. Review loop bắt đầu tự tạo thêm công việc cho chính nó.

Vấn đề không phải reviewer chưa đủ thông minh. Vấn đề là exit condition thuộc về bên luôn có
thể tìm thêm một finding, trong khi những quyết định đáng lẽ phải được giải quyết ở đầu
pipeline lại chưa từng được giải quyết.

Astragentic chuyển loop về phía trước: làm rõ câu hỏi cho tới khi frontier quyết định trống,
review spec trước khi cắt ticket, sau đó giữ review ở cuối thành các pass có giới hạn.

Mỗi ticket có các lens khác nhau:

- Review theo standards thật của repo.
- Review theo spec và acceptance criteria.
- Simplify pass với provenance trong commit.
- Cross-vendor arm trước merge.
- Rin gate tại milestone.
- QA walk trên sản phẩm đang chạy khi bề mặt thay đổi.

Cross-vendor arm là một lớp riêng. Nếu Builder chạy Claude, Codex có thể đọc artifact; nếu
root là Codex, Claude có thể làm lens còn lại. Mục tiêu không phải tổ chức một cuộc thi model.
Mục tiêu là tránh một hệ thống tự đánh giá chính mình bằng đúng cùng một góc nhìn.

Một design-level blocker không quay lại thêm mười vòng review. Nó được chuyển thành câu hỏi
cho owner. Review không thể thay con người đưa ra một quyết định sản phẩm.

> **[CLIP 03 — 8–12 giây]** Gate report xuất hiện, hiển thị artifact key và SHA; sau đó
> chuyển sang commit hoặc diff đúng SHA đó.

## “Agent nói đã chạy” không phải là bằng chứng

Một trong những bài học khó nhất khi vận hành agent là văn bản thuyết phục không đồng nghĩa
với trạng thái đúng.

Agent có thể nói rằng test đã chạy. Nó có thể nói rằng review đã sạch. Nó có thể báo “done”
trong khi thay đổi còn chưa được commit. Một pane chuyển sang idle cũng không chứng minh
artifact đã hoàn thành.

Vì vậy Astragentic ưu tiên artifact hơn handback:

- Git SHA xác định đúng phiên bản được review.
- Diff cho biết code thật sự đã thay đổi gì.
- Test output cho biết command nào thực sự chạy.
- Marker commit ghi provenance của simplify pass.
- Gate report được viết ra file thay vì chỉ nằm trong terminal viewport.
- Tracker được reconcile với Git thay vì được tin chỉ vì trạng thái của chính nó trông hợp lý.

Status của pane là một cái chuông. Nó nói rằng có điều gì đó cần được đọc. Nó không phải verdict.

Nguyên tắc này nghe có vẻ cứng nhắc cho tới khi một agent báo hoàn thành nhưng chưa commit.
Nếu worktree được cleanup dựa trên lời báo đó, toàn bộ công việc chỉ tồn tại trên disk và biến
mất cùng worktree.

Prompt không sửa được failure class này. Một check trước cleanup thì có.

## Nhìn thấy đội AI đang làm việc

Mỗi agent trong Astragentic chạy trong một Herdr pane có tên rõ ràng:

```text
thomas
spec:<id>
ticket:<id>
rin:<id>
qa:<id>
```

Workspace trở thành một Kanban board bằng terminal. Owner có thể nhìn thấy agent nào đang
working, blocked hoặc idle; mở pane và đọc đúng context; biết task nào đang sống và task nào
đã trở thành orphan.

Watcher theo dõi một turn. Watchdog phát hiện những trạng thái lớn hơn như pane bị block,
watcher biến mất hoặc toàn bộ hệ thống không còn tiến triển. Nhưng ngay cả ở đây, alert chỉ
đánh thức Thomas. Thomas vẫn phải đọc artifact trước khi quyết định.

Observability không chỉ để debug. Nó là một phần của sản phẩm. Một hệ thống multi-agent mà
owner không thể nhìn thấy đang làm gì vẫn đang yêu cầu owner tin vào lời của orchestrator.

> **[CLIP 04 — 10–15 giây]** Toàn cảnh Herdr workspace: Thomas, hai Builder, một pane blocked
> và một Rin gate. Caption giải thích từng pane như một card trên board.

## Tech stack: mỗi công nghệ giữ một trách nhiệm

Astragentic không có một “AI stack” duy nhất. Nó kết hợp nhiều lớp, mỗi lớp giải quyết một
failure mode khác nhau.

### AI runtimes

**Claude Code**, **OpenAI Codex** và **OpenCode** là các runtime thực thi. Owner có thể chọn
runtime, model và reasoning effort theo từng role. Shaping có thể cần context rộng và reasoning
sâu, trong khi một build ticket rõ ràng có thể chạy trên model nhanh hoặc tiết kiệm hơn.

Multi-runtime vì thế không chỉ là khả năng đổi model. Nó là quyết định phân bổ chi phí và tạo
review lens độc lập.

### Engineering method

Các skill của Matt Pocock cung cấp spine kỹ thuật: wayfinding, grilling, spec, ticket,
implementation và code review.

Astragentic bọc spine đó bằng lớp orchestration và bổ sung những khoảng trống của brownfield:
bootstrap glossary từ code thật, triage backlog cũ, tạo seam cho legacy testing và untangle
code chưa có module boundary rõ ràng.

Nguyên tắc ở đây là **extract, never invent**. Một glossary do agent tự tưởng tượng nhưng được
viết bằng giọng chắc chắn nguy hiểm hơn việc chưa có glossary.

### Isolation và source of truth

**Git branch** giữ lịch sử thay đổi. **Git worktree** tạo checkout riêng cho từng Builder.
**Linear hoặc Jira** giữ ticket state, assignee và dependency graph. **SHA và commit** giữ
identity của artifact được review.

Tracker nói công việc được dự định như thế nào. Git nói điều gì thực sự đã xảy ra. Hai nguồn
được reconcile thay vì một nguồn tự xác nhận chính mình.

### Observability

**Herdr** quản lý workspace, tab và pane. Watcher và watchdog cung cấp liveness signal. Gate
report và evidence file giữ thông tin vượt ra ngoài giới hạn viewport của terminal.

### Configuration và packaging

Role contract và skill được viết bằng **Markdown**. Codex profile dùng **TOML**. Runtime
configuration dùng các format native như JSON hoặc YAML. Operational check dùng **Bash** và
structural reachability check dùng **Python**.

Release được stage bất biến dưới `.astraler/releases/<version>`. Bộ cài cơ học không tự ý sửa
project. Một adaptation agent đọc project thật, phân biệt phần nào thuộc harness, phần nào là
project truth và phần nào là cấu hình do owner sở hữu rồi mới tích hợp.

> **[HÌNH 05 — Stack diagram]** Chia theo tầng trách nhiệm: method, orchestration, runtime,
> coordination/isolation, verification. Không dùng logo wall.

## Cài Astragentic vào một project

Quy trình cài đặt cũng phản ánh triết lý của framework: stage trước, hiểu project rồi mới sửa.

Đầu tiên, kiểm tra máy:

```bash
./check-requirements.sh
```

Doctor kiểm tra runtime, plugin, Git worktree, Herdr và các capability cần thiết.

Sau đó stage release vào project đích:

```bash
./install.sh /path/to/project
```

Bước này chỉ ghi candidate vào `.astraler/`. Nó không chép đè role, rule hay tài liệu dự án.

Trong project đích, yêu cầu root agent đọc adaptation prompt của candidate:

```text
Read .astraler/releases/<version>/ADAPT-HARNESS.md completely and execute it.
```

Adaptation agent đọc instruction, manifest, build/test command, agent configuration và trạng
thái Git của project. Nó phân loại:

- Harness-owned runtime cần được cài hoặc nâng cấp.
- Project-owned truth cần được giữ nguyên.
- Owner-owned configuration chỉ được tạo lần đầu hoặc merge có chủ đích.
- Runtime-specific adapter phải giữ đúng cơ chế native của Claude, Codex hoặc OpenCode.

Sau khi cấu hình workspace, runtime, model và effort cho từng role, Thomas được khởi động:

```bash
claude --agent thomas
```

Thomas đọc orchestrator config, reconcile tracker với Git, xác định frontier và bắt đầu phân
phối công việc.

> **[CLIP 05 — 45–60 giây]** Requirements check → stage release → mở orchestrator config →
> start Thomas → Thomas đọc frontier → dispatch một Builder → Herdr xuất hiện pane ticket.

## Vibe Engineering bắt đầu tại nơi prompt engineering không còn đủ

Chúng ta có thể viết một prompt tốt hơn để agent hiểu ticket rõ hơn.

Nhưng prompt không thay thế được atomic claim. Prompt không tạo ra Git isolation. Prompt không
chứng minh test đã chạy. Prompt không giữ tracker và Git nhất quán. Prompt không ngăn hai agent
sửa cùng một write-set. Prompt cũng không biến terminal output thành durable artifact.

Đây không còn là vấn đề wording. Đây là vấn đề system design.

Astragentic được phát triển bằng cách ghi lại những failure mode quan sát được trong quá trình
vận hành: agent dùng chung checkout khiến commit rơi vào nhầm branch; review kéo dài nhiều vòng
vì quyết định chưa được giải quyết ở đầu pipeline; agent báo xong nhưng công việc chưa commit;
watcher tồn tại nhưng không còn nghe được trạng thái; một file được tạo ra nhưng không có reader
nào được giao trách nhiệm đọc nó.

Mỗi incident đi qua một chuỗi:

```text
Failure thực tế
    ↓
Bài học
    ↓
Rule hoặc mechanism
    ↓
Executable check
```

Con số failure mode không nên được dùng như vanity metric. Điều quan trọng là guardrail có
provenance. Chúng ta biết vì sao nó tồn tại, failure nào đã tạo ra nó và check nào sẽ phát hiện
nếu hệ thống quay lại trạng thái cũ.

Đó cũng là cách tôi nghĩ về Vibe Engineering.

Không phải thêm bureaucracy để làm AI chậm lại. Không phải biến mọi thay đổi thành một quy
trình nặng nề. Mà là tìm ra những cấu trúc tối thiểu giúp tốc độ của AI có thể mở rộng mà không
đẩy toàn bộ rủi ro và coordination cost về cho con người.

## Vibe Coding vẫn là điểm khởi đầu

Tôi không nghĩ Vibe Engineering thay thế Vibe Coding.

Vibe Coding vẫn là một bước tiến lớn. Nó mở khóa tốc độ, khả năng khám phá và niềm vui khi biến
ý tưởng thành thứ có thể chạy được.

Nhưng một demo chạy được và một thay đổi có thể ship là hai tuyên bố khác nhau.

Khi chúng ta bắt đầu dùng nhiều agent, nhiều runtime và nhiều ticket song song, câu hỏi quan
trọng không còn chỉ là:

> Model này viết code tốt đến đâu?

Mà là:

> Hệ thống nào giúp tất cả năng lực đó cùng tạo ra một sản phẩm đúng?

Tương lai của software engineering có lẽ không chỉ là một developer nói chuyện với một AI
thông minh hơn. Đó là nhiều agent có vai trò rõ ràng, làm việc song song trên cùng một mục
tiêu, để lại bằng chứng con người có thể kiểm tra và chỉ kéo con người vào những quyết định
thực sự cần con người.

**Vibe Coding cho chúng ta tốc độ. Vibe Engineering biến tốc độ đó thành một hệ thống.**

---

Bạn đã gặp failure nào khi bắt đầu chạy nhiều coding agent cùng lúc?

