# Outline: Từ Vibe Coding đến Vibe Engineering

## Gợi ý tiêu đề

1. **Từ Vibe Coding đến Vibe Engineering: Khi một AI agent là chưa đủ**
2. **Code chạy chưa có nghĩa là đã ship**
3. **Tôi đã xây một đội AI để phát triển phần mềm như thế nào**
4. **Sau Vibe Coding là gì?**
5. **Astragentic: Operating System cho một đội AI Engineering**

## Thông điệp chính

Vibe Coding giúp một người biến ý tưởng thành code nhanh hơn.

Vibe Engineering giải quyết bài toán lớn hơn: làm thế nào để nhiều AI agent cùng đưa một
feature từ ý tưởng đến production mà không đụng nhau, không mất dấu và không bắt con người
trở thành project manager toàn thời gian.

---

# ACT I — Sự phấn khích của Vibe Coding

## 1. Mở bài bằng một khoảnh khắc quen thuộc

### Nội dung

Kể lại trải nghiệm đầu tiên khi dùng AI coding agent:

- Mô tả ý tưởng bằng ngôn ngữ tự nhiên.
- Agent đọc code, tạo component, sửa bug.
- Một công việc mất vài giờ giờ chỉ còn vài phút.
- Cảm giác gần như “có một senior engineer luôn ngồi cạnh”.

Sau đó chuyển cảnh:

> Một agent làm tốt một task. Nhưng một sản phẩm thật không chỉ có một task.

### Visual

- Hero image: một developer đang điều khiển một “engineering cockpit”, không dùng hình robot
  bắt tay sáo rỗng.
- Ảnh before/after: “ý tưởng → code” rút ngắn từ vài giờ xuống vài phút.
- Clip 8–12 giây: nhập một yêu cầu và agent tạo ra thay đổi đầu tiên.

### Mục đích

Tạo sự đồng cảm trước khi phản biện Vibe Coding. Không phủ nhận giá trị của nó.

---

# ACT II — Khi tốc độ tạo code trở thành vấn đề phối hợp

## 2. Thử chạy ba agent cùng lúc

### Nội dung

Đặt độc giả vào một tình huống cụ thể:

- Một feature có 10 ticket.
- Ba agent được chạy song song.
- Một agent hoàn thành.
- Một agent đang chờ dependency.
- Một agent đã dừng nhưng không ai nhận ra.
- Hai agent cùng sửa một module.
- Năm câu hỏi được gửi về owner cùng lúc.

Câu hỏi chuyển tiếp:

- Ai chọn ticket tiếp theo?
- Ai biết agent nào đang làm gì?
- Ai review?
- Review theo tiêu chuẩn nào?
- Merge theo thứ tự nào?
- Ai lưu lại những quyết định đã được đưa ra?

### Visual

Một sơ đồ “multi-agent chaos”:

```text
Agent A ── sửa auth.ts ─┐
Agent B ── sửa auth.ts ─┼── conflict
Agent C ── blocked ─────┘

Owner = router + reviewer + debugger + historian
```

### Clip

Screen recording 10–15 giây:

- Nhiều terminal chạy cùng lúc.
- Một pane đứng yên hoặc bị blocked.
- Không có nhãn ticket hoặc trạng thái rõ ràng.

### Câu chốt

> Khi số agent tăng lên, vấn đề không còn là viết code. Vấn đề trở thành vận hành một hệ
> thống engineering.

---

## 3. Vibe Coding không sai — nó chỉ dừng quá sớm

### Nội dung

| Vibe Coding | Vibe Engineering |
|---|---|
| Tối ưu cho một prompt | Tối ưu cho vòng đời feature |
| Tạo code nhanh | Ship thay đổi an toàn |
| Một agent, một context | Nhiều role, nhiều session |
| Tin vào câu trả lời | Xác minh bằng artifact |
| “Done” khi agent báo xong | “Done” khi code, test, review và QA có bằng chứng |
| Context là bộ nhớ | Tracker và Git là bộ nhớ |
| Con người điều phối thủ công | Hệ thống điều phối theo protocol |

Vibe Engineering không làm giảm tính sáng tạo hay tốc độ của AI. Nó bổ sung các cấu trúc
mà một tổ chức engineering bình thường vẫn cần:

- Ownership
- Isolation
- Coordination
- Review
- Observability
- Provenance
- Recovery

### Visual

```text
Prompt → Code
     ↓
Vibe Coding

Intent → Spec → Tickets → Build → Review → QA → Merge
     ↓
Vibe Engineering
```

---

# ACT III — Một đội AI cũng cần quản lý dự án như một đội ngoài đời

## 4. Công việc không bắt đầu từ một prompt hoàn hảo

### Nội dung

Ngoài đời, một engineering team không nhận một prompt rồi tất cả cùng lao vào viết code.
Team nhận một spec, một feature request hoặc đôi khi chỉ là một ý tưởng còn mơ hồ. Trước khi
build, team phải trả lời:

- Mục tiêu thật sự là gì?
- Điều gì nằm ngoài scope?
- Hệ thống hiện tại đang vận hành ra sao?
- Feature chạm vào những module, dữ liệu và user journey nào?
- Quyết định nào là kỹ thuật, quyết định nào thuộc về owner?
- Làm thế nào biết feature đã hoàn thành?

Một đội AI cũng cần trải qua quá trình đó. Model thông minh hơn không loại bỏ project
management; nó làm project management trở thành bottleneck tiếp theo cần được thiết kế.

### Visual

Một feature request ngắn dần mở ra thành các lớp: intent, constraint, dependency, acceptance
criteria và risk.

### Câu chốt

> Prompt là đầu vào. Project management mới là cơ chế biến đầu vào đó thành công việc có thể
> thực hiện.

---

## 5. Từ feature đến một kế hoạch có thể vận hành

### Nội dung

Mô tả chuỗi công việc giống một team thật:

1. **Nhận spec hoặc feature** — hiểu owner intent và kết quả mong muốn.
2. **Phân tích** — đọc codebase, xác định seam, constraint, dependency và blast radius.
3. **Chia task** — mỗi task đủ nhỏ cho một session, có acceptance criteria và kết quả kiểm
   chứng được.
4. **Quản trị task** — thiết lập trạng thái, blocking edge, ownership và write-set.
5. **Phân phối task** — chỉ giao những task đang nằm trên frontier và không va chạm nhau.
6. **Theo dõi và gỡ block** — phát hiện agent đang chờ, đã chết hoặc cần quyết định.
7. **Tích hợp** — review, QA, merge theo dependency rồi mở frontier tiếp theo.

### Mapping giữa đội người và đội AI

| Project ngoài đời | Astragentic |
|---|---|
| Product/technical owner | Owner |
| Engineering manager hoặc delivery lead | Thomas |
| Product discovery và technical design | Shaper |
| Engineers | Builders |
| Pull request reviewer | Rin và cross-vendor arm |
| Product QA | QA |
| Project board | Linear/Jira tracker |
| Local development environment | Git worktree + Herdr pane |

### Visual

```text
Feature
   ↓ phân tích
Spec + constraints
   ↓ chia nhỏ
Dependency graph
   ↓ frontier + claim
Builder A · Builder B · Builder C
   ↓ review + integration
Shippable increment
```

### Clip

Một sequence 20–30 giây:

1. Mở feature/spec.
2. Chuyển sang dependency graph trên tracker.
3. Highlight các ticket đang bị block.
4. Thomas claim hai ticket trên frontier.
5. Hai pane Builder xuất hiện với đúng ticket ID.

### Câu chốt

> Orchestration không phải là gọi nhiều agent cùng lúc. Nó là project management được mã hóa
> thành protocol.

---

## 6. Phân phối đúng việc cho đúng agent

### Nội dung

Project management không chỉ quyết định *việc gì* được làm, mà còn quyết định *ai* nên làm,
*khi nào* và với *mức đầu tư nào*.

- Shaping cần context rộng và reasoning sâu.
- Một ticket rõ ràng có thể dùng model nhanh hoặc tiết kiệm hơn.
- Review nên dùng một lens độc lập với Builder.
- QA cần sản phẩm đang chạy, không chỉ cần diff.
- Hai ticket cùng sửa một write-set phải được xếp tuần tự dù không có dependency nghiệp vụ.

Đây là nơi multi-runtime trở thành một quyết định vận hành thay vì một bảng so sánh model.

### Visual

Một dispatch board thể hiện `task → role → runtime → model → effort`, kèm dependency và
write-set.

---

# ACT IV — Astragentic xuất hiện như một câu trả lời

## 7. Astragentic là gì?

> Astragentic là operating framework giúp nhiều AI agent cùng phát triển phần mềm trên một
> codebase thật.

Nó không cố tạo ra model mới và không thay thế Claude Code, Codex hay OpenCode. Nó tổ chức
chúng thành một đội có vai trò, ranh giới và quy trình rõ ràng.

### Bốn giá trị chính

1. Nhiều agent có thể làm việc song song.
2. Mỗi agent có phạm vi và checkout riêng.
3. Owner nhìn thấy công việc đang diễn ra.
4. Mỗi kết luận quan trọng đều có artifact để kiểm chứng.

### Visual

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

---

## 8. Một feature đi qua Astragentic như thế nào?

Đây là phần kể chuyện trung tâm của bài. Dùng một feature thật hoặc một feature giả định
xuyên suốt, ví dụ: “Thêm đăng nhập bằng Google vào một sản phẩm đang có người dùng.”

### Chặng 1 — Từ ý tưởng đến spec

- Thomas xác định đây là effort lớn hay nhỏ.
- Shaper làm rõ yêu cầu.
- Câu trả lời phải có nguồn: codebase, ADR, research, prototype hoặc quyết định owner.
- Spec được review trước khi cắt ticket.

### Chặng 2 — Từ spec đến dependency graph

- Shaper cắt feature thành các ticket có thể build trong một session.
- Blocking edges xác định thứ tự.
- Tracker cho biết ticket nào đang nằm trên frontier.

### Chặng 3 — Builders chạy song song

- Thomas claim ticket bằng assignee.
- Mỗi Builder nhận một branch, worktree và Herdr pane.
- Builder là người duy nhất được ghi trong worktree đó.
- Các ticket có write-set giao nhau không được chạy đồng thời.

### Chặng 4 — Review bằng nhiều lăng kính

- Review theo standards của repo.
- Review theo spec.
- Simplify pass.
- Cross-vendor review.
- Rin kiểm tra milestone.
- QA sử dụng sản phẩm đang chạy.

### Chặng 5 — Merge và mở frontier tiếp theo

- Thomas xác minh SHA, diff, test và review artifact.
- Merge.
- Tracker được reconcile với Git.
- Các ticket vừa được unblock được đưa vào frontier.

### Visual

Một timeline ngang cho toàn bộ feature.

### Chuỗi clip đề xuất

1. Tracker hiển thị dependency graph.
2. Thomas claim một ticket.
3. Herdr tạo pane mang tên ticket.
4. Hai Builder chạy trong hai worktree.
5. Một Builder chuyển sang trạng thái blocked.
6. Gate report xuất hiện.
7. Ticket được merge và ticket tiếp theo trở thành claimable.

Mỗi clip chỉ chứng minh một ý, dài khoảng 6–15 giây.

---

# ACT V — Giới thiệu năm vai trò như một đội thật

## 9. Thomas — người điều phối

Không trực tiếp viết mọi thay đổi. Thomas quản lý frontier, claim và dispatch ticket, trả lời
câu hỏi cấp kỹ thuật, đưa quyết định cấp owner về cho con người và xác minh artifact trước
merge.

### Visual

Ảnh workspace Herdr với pane `thomas` ở vị trí trung tâm.

---

## 10. Shaper — người giữ toàn bộ bức tranh

Shaper giữ requirements, spec và ticket graph trong một context liền mạch.

> Quyết định về seam và module boundary phải được đưa ra khi toàn bộ feature còn nằm trong
> context, không phải khi Builder đã đi được nửa ticket.

### Visual

Spec biến thành dependency graph.

---

## 11. Builder — một ticket, một session

Builder có một ticket, một branch, một worktree, một pane, một write-set và một contract hoàn
thành rõ ràng.

### Clip

Hai terminal Builder chạy song song, mỗi pane có ticket ID và thư mục khác nhau.

---

## 12. Rin — reviewer đối kháng

Rin không sửa code trong checkout của Builder. Rin review đúng SHA, kiểm tra intent,
acceptance criteria và dấu vết quy trình, viết report thành artifact và đưa design-level
blocker về owner thay vì tạo vòng review vô tận.

### Visual

```text
“Agent nói đã review”
           vs.
“Report X được tạo cho SHA Y”
```

---

## 13. QA — sử dụng sản phẩm, không chỉ đọc diff

QA kiểm tra giao diện có render đúng không, journey có hoàn thành không, API có đúng contract
không và dữ liệu có nhất quán giữa các màn hình không.

### Clip

Một user journey ngắn trên sản phẩm đang chạy, kèm caption chỉ ra điều QA đang quan sát.

---

# ACT VI — Tech stack và lý do lựa chọn

## 14. Tech stack của Astragentic

Không trình bày như một danh sách logo. Chia theo trách nhiệm kiến trúc.

### AI runtimes

- **Claude Code:** runtime chính và nơi chạy các role/gate cần Claude-native behavior.
- **OpenAI Codex:** Builder tùy chọn và cross-vendor review.
- **OpenCode:** runtime thứ ba để linh hoạt model và chi phí.

### Engineering method

- **Matt Pocock Skills:** wayfinding, requirements grilling, spec, tickets, implementation
  và code review.
- **Astragentic skills:** dispatch, brownfield bootstrap, legacy testing, untangle, review
  gates và tracker reconciliation.

### Isolation và source of truth

- **Git branches:** lịch sử thay đổi.
- **Git worktrees:** checkout riêng cho từng agent.
- **Linear/Jira:** ticket state, assignee và dependency graph.
- **SHA và commits:** bằng chứng bất biến cho artifact được review.

### Observability và orchestration

- **Herdr:** workspace, tab và terminal pane cho từng agent.
- **Watcher/watchdog:** phát hiện blocked, stuck hoặc mất watcher.
- **Artifact files:** lưu gate report ngoài terminal viewport.

### Configuration và packaging

- **Markdown:** role contract, skill và adaptation protocol.
- **TOML:** Codex profiles.
- **JSON/YAML:** runtime-specific configuration.
- **Bash:** staging, doctor và operational scripts.
- **Python:** structural reachability checks.
- **Immutable release staging:** `.astraler/releases/<version>`.

### Visual

Một stack diagram theo tầng, tránh “logo wall”.

---

# ACT VII — Cách sử dụng

## 15. Cài Astragentic vào một project

### Bước 1 — Kiểm tra môi trường

```bash
./check-requirements.sh
```

### Bước 2 — Stage release

```bash
./install.sh /path/to/project
```

Bước này chưa sửa project; nó chỉ stage một release bất biến.

### Bước 3 — Semantic adaptation

Agent đọc project thật, phân biệt harness-owned runtime, project-owned truth, owner-owned
configuration và runtime-specific adapter. Nó tích hợp thay vì chép đè mù quáng.

### Bước 4 — Cấu hình đội

Thiết lập workspace label, runtime cho từng role, model, reasoning effort và fallback nếu có.

### Bước 5 — Khởi động Thomas

```bash
claude --agent thomas
```

### Clip chính

Một video 45–60 giây:

1. Chạy requirements check.
2. Stage release.
3. Mở orchestrator config.
4. Start Thomas.
5. Thomas đọc frontier.
6. Dispatch một Builder.
7. Herdr xuất hiện pane ticket.

---

# ACT VIII — Vì sao đây là Engineering?

## 16. Những thứ không thể giải quyết bằng prompt tốt hơn

- Prompt không thay thế được atomic claim.
- Prompt không tạo ra Git isolation.
- Prompt không chứng minh test đã chạy.
- Prompt không làm terminal output trở thành durable artifact.
- Prompt không giữ tracker và Git nhất quán.
- Prompt không phân biệt owner decision với implementation detail.
- Prompt không giúp hai agent tránh cùng sửa một write-set.

> Vibe Engineering bắt đầu tại nơi prompt engineering không còn đủ.

---

## 17. Hệ thống được xây từ failure, không chỉ từ nguyên tắc

Astragentic giữ một ledger append-only về các failure mode đã quan sát.

Ba incident tiêu biểu:

1. Hai agent dùng chung checkout khiến commit rơi vào nhầm branch.
2. Review kéo dài 5–14 vòng vì các quyết định chưa được giải quyết ở đầu pipeline.
3. Agent báo hoàn thành nhưng thay đổi chưa được commit; cleanup worktree làm mất toàn bộ
   công việc.

```text
Failure thực tế
    ↓
Bài học
    ↓
Rule hoặc mechanism
    ↓
Executable check
```

Không dùng con số failure mode như vanity metric. Ý nghĩa của nó là các guardrail có
provenance.

---

# ACT IX — Kết luận

## 18. Vibe Coding vẫn là điểm khởi đầu

- Vibe Coding mở khóa tốc độ và khả năng sáng tạo.
- Vibe Engineering làm tốc độ đó có thể mở rộng.
- Một cái tạo ra code.
- Một cái tạo ra khả năng ship code liên tục bằng một đội người–AI.

### Đoạn kết đề xuất

> Tương lai của software engineering không chỉ là một developer nói chuyện với một AI thông
> minh hơn.
>
> Đó là nhiều agent có vai trò rõ ràng, làm việc song song trên cùng một mục tiêu, để lại
> bằng chứng mà con người có thể kiểm tra và chỉ kéo con người vào những quyết định thực sự
> cần con người.
>
> Vibe Coding cho chúng ta tốc độ. Vibe Engineering biến tốc độ đó thành một hệ thống.

## CTA

Chọn một CTA chính:

- Xem repository và thử cài Astragentic vào một project.
- Xem video walkthrough đầy đủ.
- Đọc failure-mode ledger.
- Tham gia thảo luận: “Bạn đã gặp failure nào khi chạy nhiều coding agent?”

