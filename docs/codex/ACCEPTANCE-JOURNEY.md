# Hành trình acceptance offline — đã hoàn tất

**PASS cho luồng chính native:** Thomas → Shaper/release → ticket local → Builder
red/green → ba reviewer Astra/high → simplify → QA đúng artifact → verify/handback.
[Final report](evidence/acceptance-fixture/journey/final-report.md) ·
[Native audit](evidence/acceptance-fixture/native-evidence-summary.json).

Đã đóng TUI và resume đúng UUID Thomas; checkpoint và artifact/tracker khớp, không
redispatch hoặc làm lại task. [Recovery report](evidence/acceptance-fixture/journey/resume-verification.md).
Controller so sánh độc lập full tracker listing và source/test hashes trước/sau: không đổi.

Thomas đã đóng hai worker workspaces sau archive. Sau recovery, controller archive và
xác minh **619 file** thuộc fixture, rồi dọn ba worktree/branch cùng tab Thomas, không
force. [Cleanup](evidence/acceptance-fixture/controller-cleanup.json) và archive
`evidence/acceptance-fixture/owned-fixture-files.tar.gz` giữ toàn bộ dữ liệu thử.
Các đường dẫn temp trong transcript là lịch sử; report/artifact lâu dài ở `journey/`.

Phạm vi: bốn tiêu chí arithmetic, tracker br local, model business-role Sol override,
reviewers Astra. Cross-vendor OFF chỉ pilot, không có commit/tích hợp hoặc external
publication. Queue sandbox vẫn lỗi; native Thomas dùng Herdr fallback đúng điều kiện.
Host→Thomas queue cho synthetic decision đã được xử lý ở turn boundary.

Phần dưới giữ thiết kế phép thử trước khi chạy, không phải trạng thái còn chờ.

## Đã chuẩn bị

- Source `boxes_needed` còn bug floor division, hash được pin; bốn criteria
  `(0,3)=0`, `(6,3)=2`, `(7,3)=3`, `(1,3)=1`. Chưa tạo test hoặc sửa bug.
- Overlay cài và doctor thật trên worktree. Snapshot riêng dùng Sol cho Thomas,
  Shaper theo chỉ định owner; reviewer Astra, giữ reasoning effort nguồn; Builder/QA
  vốn dùng Sol. Các hàng helper không sử dụng vẫn giữ mặc định. Cross-vendor OFF chỉ trong fixture theo quyết định owner. Không sửa runtime/config/trust cá nhân.
- Tracker **br 0.1.13** local SQLite/JSONL được init thực sự; parent effort `acpt-22g`
  ở trạng thái open/needs-triage. Đây là parent chuẩn bị, chưa phải ticket implementation.
  Không có dependency giả hoặc ticket ID dự kiến.
- [Mapping tracker](evidence/acceptance-fixture/docs/agents/issue-tracker.md) chỉ định
  DB tuyệt đối, trạng thái/labels/actor, native IDs, parent-child và blocks dependency.
  Init/create/show đã chạy; dep/claim có help nhưng chưa đo mutation trong journey.
  Đây là project mapping dùng CLI có sẵn, không có custom tracker engine hoặc dịch vụ.

Spec issue và full ticket sẽ do Shaper tạo trong journey, theo revision được Thomas release
và breakdown đã được kiểm tra qua synthetic fixture decision. Thomas tự đọc readiness/claim/deps và tự dispatch.
Khởi tạo parent không chứng minh tracker adapter general-purpose đã được hỗ trợ.

## Chuỗi acceptance

Owner-authorized pilot → Thomas native → Shaper Align/Spec **dừng** → synthetic
fixture decision gắn hash → Thomas release revision →
cùng Shaper test-design/Tickets → Builder red/green → ba context Astra review độc lập →
simplify/cross-vendor disposition → QA read-only đúng hash → Thomas verify/handback.

Thomas phải tự chạy Herdr và queue/observation, lưu UUID↔pane↔worktree↔ticket.
Nếu queue chiều ngược bị chặn, fallback report chỉ được ghi đạt khi Thomas tự quan
sát và đọc artifact. Host không dựng hộ từng bước rồi gọi đây là Thomas E2E.
Fresh worktree không có source/overlay untracked: task hướng dẫn Thomas cài overlay,
mang snapshot owner và copy đúng source hash như fixture input trước launch.

Các artifact đều dirty/untracked, base HEAD không pin scenario. Completion dựa trên
exact file hashes, red/green thực tế, ba review reports/dispositions, QA matrix và
Thomas verify. QA inspect cùng Builder worktree với mọi writer đã pause và manifest
hash trước/sau, không cần commit hoặc snapshot engine. Không commit/tích hợp hoặc close ticket như đã integrated. Chỉ công bố
vertical fixture acceptance nếu chuỗi thật hoàn tất; optional flows và review cuối
harness vẫn có phạm vi kiểm chứng riêng.

## Prerequisites đã xử lý trong phép thử

1. Scoped Herdr profile đã đo get/read/wait thành công; Thomas cần dùng đúng profile đó. Không bật bypass hay sửa personal config.
2. Cross-vendor spec/ticket/slice OFF chỉ cho fixture đã được owner cho phép. Astra review ba contexts vẫn bắt buộc, không phải cross-vendor.
3. Sau khi owner cho phép pilot cô lập, fixture-controller được inspect Spec và
   breakdown thực tế rồi gửi **SYNTHETIC FIXTURE DECISION** gắn dispatch ID và hash
   của cả hai, như test input. Không ghi thành real owner approval hoặc quyền publish
   bên ngoài. Thomas tự kiểm tra input và phát release đúng revision theo Shaper phase
   5; controller không thao tác worker thay Thomas. Chưa có decision/release được tạo
   trong bước chuẩn bị. Spec/breakdown đổi cần decision mới; scope lệch hoặc product
   intent chưa rõ thì block. Không cần hỏi owner duyệt lại từng chi tiết toy fixture.

Không thêm UI, Junior, concurrency, service tracker, commit/merge hoặc receipt engine
làm điều kiện của tracer journey này. Native tracker ready/claim và review/QA hiện
có là contract thật; prose vẫn không trở thành gate tự động cưỡng chế.
