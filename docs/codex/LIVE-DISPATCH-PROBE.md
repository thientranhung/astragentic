# Probe dispatcher thật: worktree → Herdr → UUID → queue → ACK

> Cập nhật sau góp ý owner: dùng harness gọn, native Herdr/Codex và record Markdown.
> Prototype engine đã gỡ; trạng thái hiện hành ở [IMPLEMENTATION-STATUS.md](IMPLEMENTATION-STATUS.md).
> Các chi tiết triển khai cũ bên dưới là lịch sử, không phải hướng dẫn runtime hiện hành.

Ngày 2026-11-05; Codex CLI 0.166.0; model `gpt-6.1-sol`, effort `low`.
Đây là probe khởi động/giao tiếp, không phải ticket sản phẩm hoặc toàn bộ QA pipeline.

## Kết quả

| Bước | Số đo / bằng chứng |
|---|---|
| Preflight | Resolve base `f484b22a4a37157ca8fc9a0e723299ccb61e0442`, model/effort và brief hash trước mutation |
| Worktree | Tạo branch `astra-codex/live-identity-001` và checkout riêng dưới `.scratch`; không commit |
| Herdr | Trả pane `wW:pN`, tab `wW:tF`, đúng cwd; pane owner không đổi |
| Startup | `agent start` timeout sau 30 giây; readback cùng pane xác nhận phiên vẫn sống rồi done; không relaunch |
| Identity | Worker tự chạy `session.py`, đọc `CODEX_THREAD_ID`: `01a1abf7-b754-7060-9e70-e0401a111992` |
| Binding | `observe.py` đối chiếu dispatch/nonce/cwd và Herdr pane rồi bind UUID |
| Brief | `observe.py --send-brief` gửi event `brief-1` qua native queue; ban đầu queued_unconfirmed |
| ACK | Worker kiểm tra brief SHA-256 rồi ghi `ack-brief-1.json`; coordinator đọc lại thành acknowledged |
| Thực thi giới hạn | Worker chạy `python3 -c "print(2 + 2)"`, output `4`, exit 0, ghi diagnostic |
| Gửi lại qua adapter | Gọi lại `--send-brief` trả `sent: false`, status acknowledged; không gọi queue lần hai |
| Cleanup | Lưu artifact/transcript, xác nhận done rồi đóng đúng tab; kiểm tra không đổi tracked files; xóa chỉ receipt đã lưu và worktree bằng Git, branch bằng `-d`, không force |

Bằng chứng gốc: [record trước cleanup](evidence/live-identity-001/record.json),
[identity](evidence/live-identity-001/identity.json),
[ACK](evidence/live-identity-001/ack-brief-1.json),
[diagnostic](evidence/live-identity-001/diagnostic.md),
[transcript](evidence/live-identity-001/transcript.txt).

## Giới hạn và việc phải sửa tiếp

- Timeout startup không đồng nghĩa process chết. Dispatcher hiện trả lỗi cần reconcile;
  observer đã phục hồi binding thành công. Chưa có tự động xác nhận sau timeout.
- Chỉ gửi lại qua adapter đã kiểm tra; chưa ép native queue giao hai bản của cùng event.
- ACK là nhận việc, không là verdict. Dispatcher chưa có handback/verification/integration
  state machine hoàn chỉnh. Record bằng chứng được chụp trước cleanup nên phase còn ready.
- Cleanup probe được coordinator thực hiện có kiểm tra; chưa có CLI cleanup sản phẩm.
- Đây là model inference thật cho một worker Sol/low, không chứng minh mọi model đã có
  quyền truy cập hoặc đạt chất lượng mong muốn.
- Worker đọc skill/contract từ source path; packaging và native discovery trong một
  project đã có bộ skill cũ vẫn phải giải quyết trước bàn giao.
- Chưa chứng minh worker gửi queue ngược về Thomas trong sandbox, Shaper release live,
  Junior chia sẻ write-set, QA live, arm hoặc full-ticket gates.
- Identity/nonce là đối chiếu phối hợp trong workspace, không phải authentication trước
  một worker có ý định giả mạo. Không coi queued peer text là owner approval.
