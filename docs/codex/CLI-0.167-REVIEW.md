# Đánh giá Codex CLI 0.167.0 cho Astragentic

Ngày kiểm tra: 2026-11-07. Kết luận: đáng tận dụng cho quan sát và phục hồi;
chưa có cơ sở thay Herdr/queue/ACK hoặc thêm một engine điều phối. Máy hiện đã là
codex-cli 0.167.0, không cần chạy update chỉ để đạt phiên bản này.

## Bằng chứng thực tế

| Kiểm tra | Kết quả | Giới hạn |
|---|---|---|
| `codex --version` | 0.167.0 | CLI hiện tại, không phải tất cả tiến trình đang mở |
| `codex agents --help` | Có command center và `--no-daemon` embedded app-server | Chưa mở UI/chuyển phiên |
| `codex resume --help` | Có UUID, profile, model, quyền và remote options | Chưa resume hay đổi backend |
| Suite `tests/codex/test_*.py` | 34/34 đạt trên checkout hiện tại | Bao gồm local close-out Markdown patch; không chứng nhận mọi hành vi native |
| `tests/codex/probe_overlay.py` | 21/21 skill, doctor files-intact | Fresh prompt catalog, không chứng minh tự chọn skill |
| Helper probe trong Git fixture/CODEX_HOME tạm | 5/5 tên trong spawn schema | Không inference; không sửa trust/config cá nhân |

Nguồn chính thức: [changelog 0.167.0, ngày 2026-11-06](https://learn.chatgpt.com/docs/changelog).
Trang đã đọc xác nhận command center/unread, chuyển backend giữ draft, giữ hội thoại
khi đổi provider, fallback đọc transcript/chuẩn bị prompt mới nếu không resume được,
và sửa ước lượng context cho phản hồi lỗi hoặc thiếu usage. Những điều này là mô tả
upstream, không phải bằng chứng đã chạy được từng nhánh trong Astragentic.

## Đề xuất tối thiểu, theo thứ tự

1. **Thêm tùy chọn quan sát vào runbook:** `codex agents --no-daemon`. Chỉ là màn hình
   hỗ trợ người vận hành. Chọn đúng UUID/cwd/backend; không dùng --last, nhãn hoặc focus
   thay binding. Unread/read không thay ACK, kết quả review hay xác minh artifact.
   Lệnh vẫn dùng embedded app-server; không diễn giải là không có server. Chưa đưa nó
   vào đường dispatch hay cleanup tự động. Thử UI trong fixture riêng trước khi tuyên
   bố hoạt động trực tiếp; không chọn/archive/delete phiên production để thử.
2. **Ưu tiên kiểm chứng checkpoint qua compaction/resume:** runtime đã sửa cách ước
   lượng context; Astragentic không cần tự viết bộ đếm hay cơ chế nén. Một fixture có
   dispatch/event ID, base/head + dirty manifest, model/quyền, việc đã xong, gate đang
   chờ và resource disposition; sau nén/resume phải phục hồi đúng và không replay.
   Mô phỏng tình huống thiếu usage chỉ khi có test seam tái lập được; không cố gây lỗi
   mạng/provider trên phiên thật hoặc gọi một resume thường là đã test nhánh lỗi.
3. **Bổ sung fallback phục hồi thủ công khi đổi provider/backend:** chỉ dưới quyết
   định owner; đây không phải tự động failover. Đọc transcript/checkpoint, xác minh
   artifact và quyền, kiểm tra session cũ còn chạy không. Nếu phải mở chat mới, lấy
   UUID mới từ shell, lưu predecessor và cập nhật binding trước khi queue; không giả
   UUID cũ. Không tự thay model/provider, replay lệnh có tác dụng ngoài, hoặc coi
   provider switch là cross-vendor review đã chạy. Chưa có nhu cầu buộc thay backend
   trong luồng hiện tại nên ưu tiên thấp hơn kiểm chứng checkpoint.
4. **Giữ prompt-user ở mức nghiên cứu:** changelog nói về managed command rules cần
   fresh human approval. [Rules](https://developers.openai.com/codex/rules/) hiện mô
   tả `prompt`, còn [app-server](https://developers.openai.com/codex/app-server/) có
   `configRequirements/read`; hai trang đã đọc không cung cấp đủ hợp đồng prompt-user
   cho cấu hình này. Không đánh đồng prompt với prompt-user, không tự viết key vào
   config hoặc coi nó thay được gate nghiệp vụ. Trước áp dụng cần fixture chứng minh
   đúng rule source/cú pháp, duyệt mới từng lần, deny/cancel, --yolo/never, thao tác
   tương đương qua shell/script và các runtime liên quan. Không bật ở bản nghiên cứu.

Đây là các đề xuất vận hành của maintainer, không phải tính năng Astragentic đã có.
Chưa đổi runbook/launcher vì CLI mới; chưa thêm daemon, hook, tool hay cấu hình user.

## Phạm vi release và cleanup

Phản hồi cleanup TRA-1340 đã được xử lý riêng bằng local patch ba Markdown Codex:
explicit close-out disposition trước full done/refill, giữ tài nguyên shared/active,
released có readback hoặc retained có lý do/owner/checkpoint/capacity impact.
Đây là sửa hướng dẫn vận hành, không phải tính năng mới của CLI 0.167.0. Thomas đã
trả receipt cleanup; hash được xác minh. Maintainer không cleanup hoặc sửa Etsy.

Không bump version, commit, publish hay nâng cấp dự án downstream trong lượt này.
Không sửa Claude payload, hook, paired shared skills hoặc personal Codex config.
Bước triển khai hợp lý tiếp theo: runbook command center + fixture checkpoint trước;
provider/backend recovery và prompt-user chỉ sau khi có nhu cầu và phép đo cụ thể.


## Rà rộng changelog: các mục sát harness hơn

Nguồn đã đọc: [changelog](https://learn.chatgpt.com/docs/changelog) và
[Hooks](https://learn.chatgpt.com/docs/hooks), ngày 2026-11-07. Những ứng dụng dưới
đây là đề xuất, chưa cài hook hay đo live. Hooks là khả năng hiện có; không khẳng định
toàn bộ vừa xuất hiện ở 0.167.0.

- **Ưu tiên 1 — nạp lại binding/checkpoint:** SessionStart hỗ trợ startup/resume/compact.
  Theo docs, sau compaction context bổ sung được đưa vào continuation kế tiếp. Có thể
  nạp một bản tóm tắt ngắn từ checkpoint đã kiểm chứng: role, dispatch, artifact,
  gate đang chờ, resource disposition; không nạp tất cả role hoặc tự chạy lại công việc.
  Đề xuất một hook Codex project-local thay vì thêm daemon hoặc chỉ hy vọng agent nhớ.
- **Ưu tiên 2 — kiểm tra close-out có điều kiện ở Stop:** chỉ khi dispatch đã integrated
  và agent đang báo hoàn tất, kiểm tra thiếu disposition. Nhắc hoàn thiện record hoặc
  báo retained; tuyệt đối không tự xóa tài nguyên. Phải phân biệt kết thúc lượt chờ ACK
  với ticket done và dùng stop_hook_active/chặn lặp hữu hạn; không giữ coordinator trong
  vòng lặp khiến queue không được xử lý. SessionEnd không đại diện cho ticket done.
- **0.164.0 — queue/resume:** changelog ghi sửa resume lịch sử nén/khôi phục settings
  (#54008/#55923), giữ -c qua cấp subcommand (#56022), queue chờ permission selection
  (#55682) và pending injections đánh thức wait/sleep (#55644). Đây là lợi ích native;
  cần test ACK/safe-wait trên đúng transport, không suy ra mọi codex queue đều steer
  được busy session và không bỏ checkpoint/dedup từ tiêu đề PR.
- **0.167.0 — subagent/tool/diagnostic nền:** #58129 lưu quan hệ subagent sớm hơn;
  #58166 làm rõ recording failure/completion; #58144 ghi thêm context/truncation metrics;
  #58368 thay thứ tự PreToolUse trước Guardian review. Đây là đầu mối kiểm chứng/research,
  không đủ để tự phát minh API, policy gate hay tuyên bố khắc phục lỗi app cụ thể.

Lựa chọn đề nghị: thử SessionStart phục hồi checkpoint trong fixture trước; chỉ thử
Stop close-out nếu xác định được trạng thái từ record có authority, không dựa vào
substring trong câu trả lời. Hiện patch close-out vẫn là prose, chưa phải hook/gate.
Không đổi Claude hooks và không ghi cấu hình/trust cá nhân. Native child inheritance
không được suy diễn sang các CLI worker độc lập do Herdr mở.
