# WALK007 stall-detection — implementation handback

**SUPERSEDED / rejected proposal:** checker-only approach below was declined by
Thomas. Current implementation and evidence: [STALL-FIX-WALK007-2026-11-09.md](STALL-FIX-WALK007-2026-11-09.md).

**Bàn giao phần bounded; chưa có giám sát tự động sau khi model idle.** Đã sửa contract
disposition/status-question, làm checker một lần và cảnh báo Herdr chống trùng, kèm
thiết kế observer thường trực chưa bật. Không sửa tracked main, không sửa/cài Nizzy,
không publish, không tạo daemon/agent mới, không đổi user config/trust hay ARM.

Worktree `/tmp/astragentic-stall-walk007`, base
`3ff486e2c1e9dd2e6d17348c301a036773c74d8c`. Giữ worktree để Thomas review.
[Patch](evidence/stall-walk007/proposed.patch) SHA256
`b59d227b8dc459eeb606cb390c1f0cb75ba1e32affb4e02b43ea62c1f0697384`.
[Manifest 7 file](evidence/stall-walk007/manifest.json) pin từng source.

## Incident và capability đã đối chiếu

| Số đo | Nguồn / giới hạn |
|---|---|
| Handback 12:42:12.736, turn end 12:42:40.909, owner complaint 14:33:16.186 (+07) | Exact rollout event lines 5504/5524/5546; [sources.json](evidence/stall-walk007/sources.json) lưu hash yêu cầu/audit và mốc gốc |
| Stall từ turn end 1h50m35.277s; từ handback 1h51m03.450s | Phù hợp audit; không kết luận queue loss |
| Status turn 13:57:38.496–13:57:51.781 kết thúc bằng lời hứa, không tool/action | Rollout 5526–5534; không phải owner cancellation |
| Codex CLI 0.167.0; Herdr 0.9.5 | [CLI receipts](evidence/stall-walk007/capabilities.json) |
| 322 generated protocol schemas; có thread/read, thread/status/changed, turn/completed | [Schema extract](evidence/stall-walk007/native-schema-extract.json); schema generation, không chạy server mới |
| Herdr có notification show; queue --resume là tùy chọn riêng | Installed help; checker không gọi queue/resume |

[Official hooks](https://learn.chatgpt.com/docs/hooks) mô tả Stop có thể yêu cầu
continuation và Interrupt không được restart turn.
[Official app-server](https://learn.chatgpt.com/docs/app-server) mô tả sự kiện lifecycle
và runtime status. Những khả năng đó không tự biểu diễn nghĩa vụ sản phẩm, cũng chưa
chứng minh timer tương lai khi coordinator đã idle. Không tìm thấy scheduler nghĩa vụ
quá hạn trong CLI/protocol được kiểm tra; không khẳng định mọi sản phẩm Codex đều thiếu.
Không cài hook, bypass trust, thử resume phiên sản phẩm hoặc replay model turn.

## Đã làm

- Thomas contract: sau handback phải disposition thành next action cụ thể hoặc wait/
  blocked/paused/completed có evidence, owner, trigger. Status question không hủy việc.
  Process heartbeat và lời hứa không được ghi là task progress.
- `coordinator_check.py` (147 dòng): đánh giá một record và observation do caller cung
  cấp; yêu cầu UUID nonnil, exact endpoint/cwd/epoch, record digest và snapshot <=30s.
  Chỉ báo overdue khi nghĩa vụ coordinator_pending quá hạn và runtime idle. Sai binding,
  mất transport, unloaded/stale không tự sửa hoặc resume. Không đọc semantic prose để
  đoán owner pause/completion.
- `--notify`: một Herdr notification attempt per endpoint/thread/cwd/obligation ID;
  flock và fsync receipt trước send; dedup giữ qua reconnect đã rebind. Không tự retry
  timeout/failure/crash. `accepted_unconsumed` khác owner đọc và khác thực thi task.
- Installer đóng gói checker + contract riêng, không bật gì. Install/uninstall fixture
  giữ Claude/owner config và kiểm không tạo hooks.json.

Input evidence là ranh giới quan trọng: checker **không tự lấy live native state**, không
xác minh sự thật của trạng thái do model ghi, không biết handback bị bỏ quên nếu caller
không tạo obligation. Snapshot checksum không phải authentication. Vì vậy đây là
diagnostic hữu dụng để kiểm chứng thiết kế, **không phải bản chữa xong silent stall**.

## Verification

| Kết quả | Phạm vi |
|---|---|
| 62 tests / 0 failures, 18.990s | Suite Codex cuối cùng trên exact candidate; [log](evidence/stall-walk007/tests.log). Không phải full release selftest/public smoke. |
| 12 test methods mới | Replay WALK007; deadline boundary; status/PID heartbeat không reset; completed/idle/owner pause/external wait/worker running không alarm; active coordinator không stall; stale/future/nil/binding/cwd/endpoint/epoch/record mismatch; transport/unloaded; duplicate/reconnect dedup; crash reservation; corruption; notifier failure/timeout |
| Real Herdr notification accepted: 5.750ms | Synthetic overdue snapshot, **real notifier subprocess**. Detector computation 0.030ms. Một mẫu, không percentile/SLO. [Receipt](evidence/stall-walk007/live-notifier.json). |
| Duplicate invocation: không gọi notifier thêm | Cùng receipt file; thực tế một success attempt; receipt không tuyên bố owner đã nhìn popup |
| Executable missing: outcome_unknown có lỗi gốc | PATH rỗng chỉ trong fixture subprocess, không đổi config; tests mock bổ sung exit1/timeout |
| Install/help/doctor/uninstall checks | Disposable Git fixtures; không cài sản phẩm; owner/Claude preserved |
| Patch apply --check và diff --check PASS | Trên main 3ff486e và worktree; main tracked diff vẫn rỗng |

Replay dùng timestamp audit, không chạy lại QA hay coordinator. Timing policy đề xuất
5 phút từ handback để disposition; một status answer không thay deadline. **Autonomous
detection latency: NOT MEASURED / NOT ENABLED.** 5.750ms là notifier acceptance sau khi
checker đã được gọi, không thể dùng thay cho thời gian phát hiện stall.

Temporary notifier fixture đã xóa sau khi lưu receipt; không có thread/tab/process
observer nào được tạo. Worktree proposal còn giữ có chủ ý để review. Generated schema
scratch là dữ liệu tĩnh, không phải server. Không dừng shared daemon/worker.

## Phần cần quyết định riêng, không âm thầm triển khai

Thiết kế cụ thể ở
`/tmp/astragentic-stall-walk007/runtimes/codex/.codex/COORDINATOR-CHECK.md`, phần
“Persistent observation proposal”. Đã tự đối chiếu với các yêu cầu an toàn; **chưa có
independent review**, chưa có chấp thuận activation.

Đề xuất duy nhất: observer được supervisor quản lý, đăng ký exact coordinator binding,
nhận handback độc lập model, lưu obligation/deadline/dedup, đối chiếu lifecycle và
disposition trước một cảnh báo owner-visible. Không auto-resume. Deadline 300s và
sweep <=30s cho target <=330s khi khỏe; đây là design target chưa đo. Reconnect phải
reconcile; pause và external approval giữ nguyên. Supervisor phải báo được observer
chết; receipt/notifier lỗi không được xem là healthy. Cleanup chỉ observer/subscription
sở hữu, không chạm shared daemon.

Native Stop hook là lựa chọn prevention khác, nhưng không được bật ở đây: auto
continuation/trust cần policy và live tests riêng, không dùng hook để ngụy trang
self-queue keepalive. Cũng không đủ để báo deadline tương lai khi không còn event.

Bước tiếp cho Thomas: review patch và quyết định có giữ diagnostic độc lập trong
payload hay giữ nó ở phạm vi fixture; muốn đáp ứng unattended detection đầy đủ thì
owner cần duyệt observer/supervision contract trước triển khai và đo đầu-cuối. Không
release/install với thông điệp “đã chống silent stall tự động” từ bằng chứng hiện tại.
