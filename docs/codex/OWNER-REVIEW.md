# Báo cáo phạm vi Astragentic cho Codex — owner đã cho phép triển khai

> Cập nhật sau góp ý owner: dùng harness gọn, native Herdr/Codex và record Markdown.
> Prototype engine đã gỡ; trạng thái hiện hành ở [IMPLEMENTATION-STATUS.md](IMPLEMENTATION-STATUS.md).
> Các chi tiết triển khai cũ bên dưới là lịch sử, không phải hướng dẫn runtime hiện hành.

Ngày 2026-11-05. Đây là đề xuất phạm vi, không phải thông báo hệ thống đã chạy.
Mục tiêu: owner dùng Astragentic trên Codex với đủ role và astra-*; cơ chế phù hợp
Codex, không phải bản sao mọi tính năng Claude. Owner đã cho phép triển khai trong hội thoại; ưu tiên kiểm chứng queue + Herdr.

## 1. Anh sẽ dùng như thế nào?

Ba lối vào dự kiến: mở Thomas để điều phối; mở BA để bàn bài toán; mở Quick Builder
để làm việc nhỏ. Đây là ba phiên Codex độc lập, không phải subagent của nhau.

Thomas giao effort cho Shaper; Shaper đi Align → Spec → dừng chờ release → test-design
→ Tickets. Thomas giao ticket cho Builder, rồi tổ chức QA và kiểm tra kết quả trước
khi tích hợp. Junior là lựa chọn của Builder theo cấu hình, không tự bật.
Quick ticket do Thomas giao khác với role Quick Builder do anh mở.

Tên lệnh launcher cụ thể chưa chốt; ví dụ `astra-codex thomas` chỉ là giao diện dự kiến.

## 2. Các thành phần cần làm

| Thành phần | Phạm vi tối thiểu | Vì sao cần |
|---|---|---|
| Orchestrator Codex riêng | Cấu hình đầy đủ role/model/effort, capacity, junior, arm | Owner điều chỉnh đội Codex mà không sửa cấu hình Claude |
| 7 role | Thomas, BA, Quick Builder, Shaper, Builder, QA, Junior | Giữ toàn bộ hành trình hiện có |
| Context và entrypoint | AGENTS định tuyến; launcher nạp đúng một role; resume đúng phiên | Role độc lập phải vào đúng việc, không nạp tất cả contract |
| Skill Codex | Mapping đủ 17 skill, gồm 7 astra-*; viết lại phần phụ thuộc runtime | Đúng folder nhưng nội dung Claude vẫn không đủ để chạy |
| Helper agents | Chuyển 3 helper hiện có khi cần; reviewer phục vụ review | Tác vụ nhỏ trong phiên; không dùng TOML thay mọi role |
| Dispatch qua Herdr | Tạo/định danh pane và worktree, khởi động Codex, đọc trạng thái | Tận dụng hạ tầng owner đang dùng |
| Giao tiếp qua codex queue | Ưu tiên thử gửi brief/follow-up/handback vào session UUID | Native messaging giữa các phiên Codex, theo lựa chọn owner |
| Review và simplify | Dùng review có sẵn; simplify thành quy trình Codex riêng | Có kiểm tra chất lượng mà không giả lời gọi/receipt Claude |
| Evidence và gates | Test/review/QA gắn đúng artifact; verify trước tích hợp | Trạng thái idle/done không chứng minh ticket đạt |
| Packaging | Install/upgrade/doctor/uninstall theo runtime; giữ owner config | Không copy đè hoặc để skill nạp nhầm bản |

Hai skill adoption batch-triage/bootstrap-glossary cũng thuộc phạm vi packaging.
Cross-vendor arm cần adapter reviewer khác provider, hoặc owner chọn off rõ ràng;
Codex tự review không được gọi là cross-vendor.

## 3. Ưu tiên codex queue

Phân công dự kiến:

```text
Herdr: mở phiên, pane/tab, theo dõi trạng thái, đọc terminal
Codex queue: gửi thông điệp vào session UUID đã xác minh
Astragentic: role, nội dung brief, checkpoint, handback, kiểm tra artifact
```

Ví dụ cần thử, chưa phải flow đã hoạt động:

```text
Thomas --queue(brief)--> Builder
Thomas <--queue(handback + đường dẫn report)-- Builder
```

Giữ UUID ↔ pane ↔ role ↔ ticket trong dispatch record. Message ngắn chứa loại,
người gửi, ticket/dispatch ID và đường dẫn artifact; không chuyển cả log dài.
Tin agent là dữ liệu phối hợp, không đại diện phê duyệt của owner.

Probe tối thiểu trên CLI 0.166.0:

| Tình huống | Điều kiện chấp nhận |
|---|---|
| Recipient idle | Nhận tin và bắt đầu xử lý, trả ack đúng message ID |
| Recipient busy | Không mất tin; xử lý tiếp được, không nhân đôi công việc |
| Recipient vừa interrupt | Nhận biết pending/paused; không báo giao thành công chỉ vì exit 0 |
| Recipient resume | Đúng session/project; tiếp tục được hoặc báo rõ cần can thiệp |
| Gửi lại cùng event | Không dispatch/merge/tạo ticket lần thứ hai |
| Shaper đợi release | Handback không tự thành release; chỉ tiếp tục khi nhận đúng quyết định |

`--resume` cần daemon/server phù hợp. Exit 0 chỉ là queue chấp nhận, không là recipient
đã xử lý. Không tự động resume sau khi owner đã yêu cầu dừng công việc.
Nếu queue không đạt một tình huống quan trọng, ghi đúng thiếu hụt rồi mới cân nhắc
Herdr agent prompt làm fallback. Không gửi cả hai đường đồng thời hoặc fallback
mù khi chưa biết tin đầu đã được nhận chưa.

Nguồn cộng đồng để thiết kế probe, chưa chứng minh lỗi trên máy này:
- [Dùng queue báo hoàn tất tác vụ nền](https://www.reddit.com/r/codex/comments/1wmovt8/how_using_codex_queue_i_was_able_to_avoid_gpt/).
- [CLI 0.164.0: pending sau interrupt](https://github.com/openai/codex/issues/56914).
- [Desktop/goal làm queue chờ](https://github.com/openai/codex/issues/52705).
- [Thông điệp queue mang vai user](https://github.com/openai/codex/issues/54991).

## 4. Những gì chưa cần xây

- Không xây message broker, daemon hoặc cơ sở dữ liệu queue riêng ở bước đầu.
- Không viết lại Herdr, bộ nhận diện trạng thái, hoặc bảng điều khiển chỉ để giống Claude.
- Không xây plugin mới nếu AGENTS/skills/launcher/hooks đã đủ.
- Không biến tất cả role thành custom subagent TOML.
- Không thêm advisor tự động hay tự chọn model tốn phí.
- Không port mọi guard trước khi biết nó phục vụ hành vi nào của Codex.
- Không mở hai Thomas cùng tranh một frontier trong pilot; concurrency cross-runtime
  chỉ làm khi thực sự có nhu cầu. Builder song song vẫn nằm trong phạm vi hệ thống.

Record nhỏ và report file là đủ cho pilot. Chỉ thêm retry service/inbox/locking phức
hợp khi phép thử chỉ ra cần thiết. Khi hỗ trợ Builder song song, cập nhật record vẫn
phải tránh ghi đè và duplicate dispatch; tối giản không đồng nghĩa bỏ correctness.

## 5. Quy tắc tài liệu

Markdown Claude chỉ dùng tham khảo trong quá trình xây. Role/agent/skill Codex phải
có nội dung riêng hoặc dẫn tới tài liệu Codex, không bắt runtime đọc contract Claude.
Code thuần có thể dùng chung sau kiểm tra; không đồng nghĩa tài liệu runtime dùng chung.
Không sửa .claude hoặc cấu hình người dùng để bù cho phần Codex còn thiếu.

## 6. Trình tự đề xuất và điểm dừng

1. **Đo giao tiếp queue + Herdr:** hai phiên thử, đủ idle/busy/interrupt/resume,
   lưu kết quả. Chưa triển khai broker hay toàn bộ gates.
2. **Lối vào và context:** orchestrator, launcher, đủ 7 contract và mapping skills;
   owner mở được Thomas/BA/Quick Builder đúng role.
3. **Một hành trình dọc:** Thomas → Shaper (pause/release) → Builder → QA → verify;
   có review/simplify và báo cáo thật. Không cần UI giống Claude.
4. **Hoàn thiện phạm vi:** junior, arm, quick hai loại, adoption, concurrency,
   install/upgrade/cleanup và thử hồi quy Claude.

Sau mỗi bước, cập nhật điều đã chạy, chưa chạy và phần phải bổ sung; không coi prototype
thành production. Owner đã duyệt toàn bộ phạm vi; tiếp tục qua các mốc, không chờ duyệt lại.

## 7. Snapshot tại thời điểm lập đề xuất (đã cũ)

Trạng thái hiện tại nằm ở [IMPLEMENTATION-STATUS.md](IMPLEMENTATION-STATUS.md).

- Kiểm kê 37 file nguồn: 7 role, 17 skill chính, 3 helper, 2 adoption.
- Probe CLI prompt rendering: 10/10 assertion đạt; AGENTS/role override/skill catalog.
- Herdr 0.9.5 có start/prompt/get/read/wait; Codex 0.166.0 có queue.
- Chưa thử giao tiếp hai phiên thật, chưa xác minh helper spawn/compact/resume.
- Chưa có launcher, bộ role/skill Codex hoàn chỉnh hoặc dispatch end-to-end.
- Chưa commit/release; ba file nền đầu tiên chỉ là scaffold, không là sản phẩm đã xong.

## 8. Các điểm góp ý trong đề xuất ban đầu

Đây là câu hỏi lịch sử của bản đề xuất, không phải yêu cầu owner trả lời lại.

- Phạm vi có thành phần nào anh chưa cần hoặc muốn đưa lên trước không?
- Pilot có chấp nhận một Thomas hoạt động trên project, nhiều Builder sau khi luồng đơn đạt không?
- Cross-vendor arm nên có ngay ở pilot hay bổ sung sau luồng chính?

Lựa chọn đã chốt: ưu tiên thử codex queue; Herdr là hạ tầng quản lý phiên; tài liệu
Codex độc lập với tài liệu Claude. Không hỏi lại ba quyết định này.
