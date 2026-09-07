# Trang chủ: năm section giải thích sau hero (2026-09-08)

Chèn ngay sau sơ đồ hero, trước section "why" hiện có. Chữ tiếng Việt dưới đây là bản đã
viết theo sự thật có nguồn (facts từ harness, xem báo cáo facts-agents); giữ nguyên, chỉ rút
khi tràn. Bản Anh dịch giữ nhịp, "I/you". Mọi lệnh giữ nguyên tiếng Anh, đặt trong khối
code có nút chép. Section xen kẽ nền surface/canvas nối tiếp hero. Mỗi section có một hình
sẵn có (không vẽ mới) hoặc một khối lệnh.

## A · agents (id="agents")

H2: **Một agent là một session coding-agent được giao một vai.**
Eyebrow: AGENT TRONG ASTRAGENTIC

P1: Mỗi agent là một phiên làm việc của Claude Code, Codex hoặc OpenCode, khởi chạy từ dòng
lệnh với một vai xác định. Nó nhận nhiệm vụ như một nhân viên, làm xong thì trả kết quả, và
có thể nhân bản thành nhiều phiên chạy song song: nhiều Builder cùng thi công, nhiều QA cùng
kiểm, giống một đội thật.

P2: Mỗi vai mang tên người: Thomas, Shaper, Builder, Rin, QA. Tên riêng giữ cho vai không bị
trôi trong context dài, và giúp các skill gắn theo vai được kích hoạt đúng.

P3: Vai được định nghĩa bằng một file khai báo theo chuẩn của từng runtime, nạp vào system
prompt khi phiên mở: Claude Code đọc `.claude/agents/<vai>.md`, Codex đọc launch profile
`.codex/profiles/<vai>.config.toml`, OpenCode đọc `.opencode/agents/<vai>.md`. Runtime, model
và effort của từng vai khai ở một chỗ, `orchestrator.md`.

Khối lệnh (3 dòng, nhãn "Khởi chạy một vai trên ba runtime"):
```
claude   --agent builder --model <model>
codex    --profile builder
opencode --agent builder -m <provider>/<model>
```
Hình: `five-roles` nhỏ bên phải hoặc trên khối lệnh (tĩnh). Link: Xem năm vai → /vai/thomas.

## B · comms (id="comms")

H2: **Giao tiếp có địa chỉ, có xác nhận, có người canh.**
Eyebrow: CÁCH CÁC AGENT NÓI CHUYỆN

P1: Khi hai agent cùng chạy Claude Code, chúng dùng SendMessage, kênh nhắn tin nguyên bản
giữa các session. Bên gửi chuyển nội dung và tham chiếu artifact; bên nhận trả lời về đúng
phiên gửi. Thomas dùng chính kênh này để trả lời khi Builder bị chặn, rồi đặt Monitor chờ tín
hiệu làm xong hoặc cần trao đổi.

P2: Khi hai agent khác runtime, ví dụ Builder trên Codex, Thomas đi qua herdr: gửi brief bằng
`herdr agent prompt`, gõ lệnh vào pane bằng `herdr pane run`, đọc lại màn hình bằng
`herdr agent read`, và theo dõi trạng thái bằng watcher.

P3: herdr là terminal multiplexer và runtime cho coding agent: nó tổ chức phiên thành
workspace, tab, pane; nhận diện agent nào đang chạy và ở trạng thái gì; và mở toàn bộ phiên
đang chạy ra ngoài qua CLI. Nhờ đó Thomas nhìn thấy từng agent, gửi đúng địa chỉ, và đọc
đúng pane, điều một terminal thường không cung cấp.

Khối lệnh (nhãn "Thomas điều một Builder trên Codex qua herdr"):
```
herdr agent start "builder-TRA-142" --kind codex --pane <id> -- codex --profile builder
herdr agent prompt <pane-id> "<brief>"
herdr agent read   <pane-id>
```
Hình: `hub-and-spokes` (Thomas hub, pane spoke), tĩnh. Link: Xem tech stack → /tech-stack#herdr.

## C · roles (id="roles")

H2: **Năm vai, năm vòng đời session.**
Eyebrow: CHỨC NĂNG VÀ NHIỆM VỤ

Năm thẻ ngang (hoặc 5 hàng), mỗi thẻ: chấm màu vai, tên, dòng session, 2-3 câu, link /vai/<id>.

- **Thomas · người đại diện.** Session thường trực, sống qua nhiều ticket. Giữ tracker, chạy
  frontier query, claim, dispatch và merge. Là vai duy nhất còn ở đó khi Builder đã đóng phiên,
  nên mọi trạng thái bền đều thuộc Thomas. Hỏi lại bạn ở những quyết định quan trọng.
- **Shaper · định hình.** Một session liền mạch từ đầu tới cuối, không compact. Chạy
  grill-with-docs, to-spec, to-tickets theo thứ tự, dừng sau spec để bạn duyệt.
- **Builder · thi công.** Một session mỗi ticket, trong worktree riêng, là người viết duy nhất
  ở đó. Implement, code review hai trục, simplify, rồi lượt review chéo vendor. Commit ở mỗi
  ranh giới, không chỉ lúc bàn giao.
- **Rin · gác cổng.** Một session mỗi milestone, worktree tách riêng tại đúng SHA được review.
  Chỉ đọc và viết đúng một file: báo cáo gate. Một vòng mỗi milestone, không lặp.
- **QA · nghiệm thu.** Một session mỗi lượt walk, với sản phẩm đang chạy thật trong worktree
  riêng. Dùng sản phẩm như người dùng, không đọc diff. Mặc định chỉ đọc, mọi thao tác ghi cần
  bạn cho phép từng lần.

Hình: `five-roles` tương tác (bấm vai → trang vai), như đợt 3.

## D · tracker (id="tracker")

H2: **Mọi việc đi qua tracker, nên không việc nào lạc hướng.**
Eyebrow: ISSUE TRACKER

P1: Tracker là nơi trạng thái công việc sống, không phải chat hay trí nhớ của một agent.
Thomas hỏi tracker cái gì đã sẵn sàng; claim là một dòng assignee được ghi và đọc lại; mọi
điều kiện tiên quyết là một cạnh truy vấn được; và bạn mở board là đọc được mà không cần chạy
query. Astragentic đặt năm yêu cầu này lên bất kỳ tracker nào, nên GitHub Issues, Jira hay
Linear đều dùng được.

Danh sách 5 yêu cầu (mono, nguyên văn Anh từ tracker-contract.md, nhãn "nguyên văn · tiếng Anh"):
1. A stable ticket id in the TITLE
2. A status with five states — Backlog / Todo / In Progress / Done / Won't fix
3. An assignee, written and read back atomically
4. Every precondition as a queryable EDGE
5. A surface the OWNER can open and read without running a query

Hình: `frontier-query` tương tác (như đợt 3). Link: Xem cấu trúc → /cau-truc#coordination.

## E · method (id="method")

H2: **Astragentic không tự nghĩ ra SDLC. Nó điều phối một SDLC đã chuẩn.**
Eyebrow: MATTPOCOCK-SKILLS

P1: Bộ skill của Matt Pocock là xương sống phương pháp: wayfinder và triage cho Thomas;
grill-with-docs, to-spec, to-tickets cho Shaper; implement cho Builder; cùng lớp craft dùng
chung: tdd, code-review, domain-modeling, diagnosing-bugs. Tôi chọn nó thay vì Superpowers vì
nó đặt vòng lặp hỏi đáp ở đầu, trước khi viết code, đúng chỗ Astragentic từng thất bại khi
lặp ở cuối. Astragentic không cạnh tranh với phương pháp; nó điều phối phương pháp.

Bảng nhỏ: Vai → skill mattpocock (Thomas: triage, wayfinder, to-questionnaire, ask-matt ·
Shaper: grill-with-docs → to-spec → to-tickets · Builder: implement · Dùng chung: grilling,
tdd, code-review, codebase-design, domain-modeling, research, prototype, diagnosing-bugs).
Hình: `layer-map` tĩnh. Link: Xem lý do chọn → /vi-sao#why-mattpocock.

## Kỹ thuật

- Thêm vào landing yaml (vi, en): `explain: { agents, comms, roles, tracker, method }`, mỗi mục
  {eyebrow, headline, paragraphs[], commands?{label, lines[]}, items?[], more{label, href}}.
  Schema nới, key cũ giữ.
- HomeBody: chèn 5 section sau hero, trước why. Nền xen kẽ tiếp từ hero (hero là canvas →
  A surface → B canvas → C surface → D canvas → E surface → why canvas…; điều chỉnh các
  section cũ cho xen kẽ đúng).
- Khối lệnh dùng cùng codeframe của AdoptBlock (3 chấm, số dòng, nút chép); tách thành
  `CodeFrame.astro` nếu cần tái dùng.
- Danh sách 5 yêu cầu: khối trích nguyên văn tiếng Anh, nhãn "nguyên văn · tiếng Anh".
- Build, detector 0, chụp /, /en ở 1440 và 390; kiểm không "mình/anh em/chúng tôi".
