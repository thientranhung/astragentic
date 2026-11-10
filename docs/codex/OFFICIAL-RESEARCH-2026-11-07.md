# Nghiên cứu native Codex cho Astragentic — 2026-11-07

Đã dùng **3 subagent GPT-6 Luna/high** theo yêu cầu tiết kiệm; maintainer đối chiếu lại
các kết luận quan trọng với tài liệu gốc và contract đang có. Không gọi Claude.
Đây là nghiên cứu và lựa chọn hướng thử, không phải xác nhận tính năng đã tích hợp.

## Phạm vi đã rà

- **32 entry phát hành từ 0.150.0 đến 0.167.0**: 18 bản chính và 14 bản vá, trên
  [changelog chính thức](https://learn.chatgpt.com/docs/changelog). Maintainer đếm lại
  heading độc lập, khớp 32. Có bảng từng version/ngày/nội dung/loại trừ ở báo cáo nhánh.
  0.157.1 có entry nhưng upstream không xác định được highlights; không bịa thay đổi.
- Tài liệu official theo nhóm: hooks, trust/permissions/rules, subagents/custom agents,
  queue/resume/fork, app-server lifecycle, worktrees, discovery và diagnostics.
- CLI trên máy được maintainer kiểm tra: **0.167.0**. Đọc help queue/doctor; không chạy
  doctor connectivity, đổi backend, mở session mới, hook hay inference trong lượt này.
- Không tuyên bố rà mọi release trước 0.150.0, đọc mọi PR/source implementation hoặc
  kiểm chứng runtime chỉ vì tài liệu đã mô tả. Các lợi ích bên dưới là suy luận ứng dụng.

## Những việc thực sự đáng thử

| Ưu tiên | Đề xuất | Vấn đề giải quyết | Phạm vi nhỏ nhất / điều kiện đạt |
|---|---|---|---|
| 1 | Hook SessionStart cho startup/resume/compact | Sau nén context, role dễ mất liên kết với dispatch/checkpoint | Một hook Codex project-local chỉ bổ sung pointer ngắn tới contract/checkpoint đã bind. Fixture chứng minh đúng UUID/artifact/gate được đọc lại, không replay, không ghi đè authorization. |
| 2 | Giảm capability/skill không cần ở helper | Helper đọc quá nhiều hướng dẫn/công cụ ngoài nhiệm vụ, tăng khả năng lạc việc | Một custom helper fixture, giữ nguyên model/effort owner. So sánh catalog/tool surface và cùng bài review với baseline. Chỉ áp dụng nếu không mất chức năng; chưa đo token/chi phí nên không hứa tiết kiệm. |
| 3 | Quy trình chẩn đoán bằng native doctor | Lỗi runtime/network bị nhầm với lỗi harness hoặc thiếu helper | Runbook dùng doctor JSON đã redacted cùng overlay doctor/probe và artifact identity. Hai doctor có phạm vi khác nhau; chưa cần viết support-bundle service. |
| 4 | Ma trận phục hồi queue/resume | Accepted bị hiểu là đã nhận; retry làm trùng việc; phiên owner dừng bị bật lại | Fixture loaded/unloaded/busy/owner-paused và cảnh báo resume exit0. Đo native delivery riêng với xử lý event-id của Astragentic. Không tự đưa --resume vào adapter mặc định. |
| Giữ lại sau | Stop kiểm tra close-out | Thomas merge xong quên xử lý tài nguyên | Trước hết dùng disposition Markdown đang sửa. Chỉ thử hook khi xác định được trạng thái từ record có authority và không chặn lượt chờ ACK. Không tự cleanup. |

### 1. Khôi phục context theo vòng đời native

[Hooks](https://learn.chatgpt.com/docs/hooks) mô tả SessionStart với nguồn startup,
resume, compact; sau compaction, additionalContext có thể tới continuation kế tiếp.
Không cần viết bộ nén hay daemon mới. Hook phải nhỏ, có timeout, đọc đúng binding,
không tìm UUID theo phiên mới nhất, không lấy tin peer làm quyền owner và không tự
sửa checkpoint. Missing/invalid pointer phải báo thiếu, không suy đoán role/task.

Hook project-local cần project trust và review hook theo hash. Hook mới/đổi definition
có thể bị skip tới khi trusted. Không tự sửa trust hoặc thêm bypass flag. Khả năng
được tài liệu mô tả chưa chứng minh hoạt động trong toàn bộ launch mode của Astragentic.

### 2. Helper gọn bằng cấu hình native, không tạo role engine

[Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents) tài liệu hóa
custom agent có thể tắt các capability được hỗ trợ và từng skill. Ví dụ các nhóm
features.shell_tool/apps/plugins/memories/request_permissions_tool, skills.config;
không mặc định tắt shell vì reviewer hiện cần đọc Git/source. Không bỏ hàng loạt
instructions cần thiết chỉ để giảm context. Thiết kế fixture trước khi đổi helpers.py.

Custom TOML model/effort có quyền ưu tiên. Thứ tự explicit spawn → agents defaults →
parent là bước phân giải TRƯỚC khi custom file được áp dụng. Không dùng builtin explorer
để lách model table; Astragentic đã có astragentic_explorer/reviewer và các lens.
Child vẫn kế thừa quyền/provider/MCP của parent; giảm tool không chứng minh sandbox
read-only độc lập và có thể vẫn còn đường ghi khác. Herdr CLI worker là tiến trình
riêng, không tự có các tính chất inheritance này.

### 3. Diagnostics có sẵn, không phải dựng công cụ mới

[CLI reference](https://learn.chatgpt.com/docs/cli/reference) và help hiện tại có
`codex doctor --json` (report redacted), `--network-only` (config/network/provider HTTP/
Responses WebSocket). Dùng để phân loại lỗi trước khi nghi harness hỏng. Nó có thể
kiểm tra auth/config và thực hiện kết nối mạng; không gọi là hoàn toàn offline hay
không đọc credential. Không xuất toàn bộ env/auth/transcript. Xem output trước chia sẻ.
Overlay `install.py doctor` vẫn chỉ chứng minh integrity; helper probe chỉ chứng minh
fresh declaration. Không gộp các lớp bằng chứng thành một chữ PASS.

### 4. Native queue cải thiện, nhưng không thay contract của mình

Changelog 0.166.0 thêm queue --resume; reference nói resume cần daemon/server và vẫn
có thể exit0 kèm warning khi resume thất bại. Chỉ nghiên cứu cho phiên chưa loaded và
được phép tiếp tục. Owner-paused không phải lỗi cần tự phục hồi. Các sửa reconnect,
interrupt và queue từ 0.159–0.165 không chứng minh codex queue sẽ steer mọi phiên busy.
Fixture đo delivery; event-id của Astragentic chống lặp THAO TÁC, không giả định queue
native tự deduplicate các lần gửi. Giữ ACK != accepted != kết quả được xác minh.

## Các đề xuất đã loại hoặc hạ ưu tiên

- Thay Herdr bằng command center hay viết app-server scheduler/readback engine: chưa
  có nhu cầu đủ mạnh. Dynamic-tool restore chỉ hữu ích nếu sau này có tích hợp đó.
- Thêm native explorer như khả năng mới: đã có helper tương ứng; tránh route trùng.
- Tự xóa worktree/branch/process bằng Stop/SessionEnd: không có đủ authority về task.
  SessionEnd không xảy ra ngay chỉ vì chuyển view và không đồng nghĩa ticket done.
- Stop decision=block không phải chặn hành động đã xảy ra; nó tạo continuation.
  Có nguy cơ vòng lặp/giữ lượt. Chưa đưa vào đường cleanup hoặc chờ queue.
- Copy nguyên hook Claude: schema/handler/failure semantics khác; một số output
  PreToolUse không được hỗ trợ làm hook lỗi mà tool vẫn tiếp tục. Background hook
  không block/approve/rewrite thao tác. Không quảng bá hook như gate fail-closed.
- prompt-user/gate merge bắt buộc: còn thiếu bằng chứng cho cấu hình/yolo hiện tại;
  không lấy tiêu đề changelog hoặc prompt nhắc nhở làm chứng nhận enforcement.
- Tự đổi model/provider theo capacity hay tự mở lại session: vẫn là lựa chọn owner.

## Cách làm tiếp để không over-engineering

Một pilot duy nhất trước: SessionStart nạp lại pointer checkpoint, trong fixture riêng,
không đụng Etsy/Nizzy. So sánh startup, resume đúng UUID và compaction; chặn replay;
thử thiếu checkpoint, hook chưa trusted và timeout. Nếu không cải thiện được tính
nhất quán hoặc phải thêm state engine mới, không đưa vào sản phẩm. Sau đó mới xem
capability trimming của một helper. Native diagnostic chỉ cần hướng dẫn sử dụng.

Kết quả này không yêu cầu nâng CLI (đã 0.167.0), thay model table, sửa Claude hay
release Astragentic ngay. Không triển khai các thử nghiệm kể trên trong lượt nghiên cứu.

## Báo cáo nhánh để kiểm tra lại

- [32 changelog entries](../../.scratch/codex/official-research-20261107/changelog.md)
- [Hooks và permissions](../../.scratch/codex/official-research-20261107/hooks-permissions.md)
- [Agents và recovery](../../.scratch/codex/official-research-20261107/agents-recovery.md)
- [Đối chiếu và loại đề xuất của maintainer](../../.scratch/codex/official-research-20261107/maintainer-checks.md)

Các báo cáo nhánh là nghiên cứu local trong .scratch, không phải tài liệu bắt buộc cho
role/skill đã phát hành. Bản tổng hợp này có các hiệu chỉnh so với shorthand ở nhánh
agents (model precedence, builtin helper) và nhánh hooks (SessionEnd không phải đổi view).
