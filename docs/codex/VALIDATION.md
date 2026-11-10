# Kiểm chứng Astragentic Codex

Đã đo: CLI 0.166.0; help có review và debug prompt-input; source inventory.
C01/C02 đã có probe prompt-rendering một phần, xem [PROBE-RESULTS.md](PROBE-RESULTS.md).
Queue idle/busy và recovery đã thử trên hai phiên, xem [LIVE-QUEUE-PROBE.md](LIVE-QUEUE-PROBE.md).
Peer-send từ sandbox read-only bị chặn; interrupt không tự wake. Compact, helper spawn và dispatch nghiệp vụ vẫn **chưa chạy**. File tồn tại không là PASS.

| ID | Probe | Điều kiện đạt |
|---|---|---|
| C01 | Thomas/BA/Quick Builder | đúng identity/model/effort; root và nested instructions đúng |
| C02 | Skills | 17 skill có mapping; không gọi nhầm Claude/trùng tên; policy đúng |
| C03 | TOML helper | gọi đúng tên/context; trả parent; không giả sandbox riêng |
| C04 | Resume/compact | giữ role/brief/pending phase/approval |
| D01 | Dispatch/ack | claim/pane/worktree/branch đúng; brief có quotes/newlines an toàn |
| D02 | Notification | Thomas idle/busy đều nhận; duplicate xử lý một lần; retry được |
| D03 | Crash/restart | không sinh hai worker; attempt cũ bị từ chối |
| D04 | Shaper | Spec dừng; chưa release không Tickets; cùng session |
| D05 | Claim/capacity | cạnh tranh không nhận cùng ticket, không vượt capacity |
| G01 | Hooks | allow/deny/error/malformed/nested cwd/tool aliases; không false pass |
| G02 | Test evidence | red/green/fail/long-running có đúng final exit |
| G03 | Review/simplify | failed lens không clean; stale head bị phát hiện |
| G04 | QA | walk/probe/verify đúng SHA và consent |
| G05 | Quick/BA | phân biệt hai quick; BA không code; không suy diễn owner approval |
| G06 | Junior/arm | write-set/trailer; khác provider hoặc explicit off |
| P01 | Install/upgrade | owner edits giữ được; runtime manifest đúng |
| P02 | Coexist/uninstall | Claude load đúng bản; không duplicate; chỉ xóa file sở hữu |
| P03 | Full journey | BA→Thomas→Shaper→Builder→QA→verify→cleanup có evidence |

Mỗi kết quả lưu command/version/fixture/exit/evidence path/giới hạn. Dùng fixture
trước; không gửi message/tracker hoặc merge project thật chỉ để thử hạ tầng.
Thiếu tool/account ghi unavailable, không pass.
