# Notify → queue: busy coordinator và profile Herdr

Ngày đo: 2026-11-08. CLI **0.167.0**; worktree detached từ **a73d4053777320d264e2fc700d1ca93dd9ca1b16**. Chỉ fixture riêng; không sửa checkout source main hoặc `~/.codex/config.toml`.

## Kết quả

| Ca | Queue exit 0 | ACK | Mất / trùng ACK quan sát | Median queue | Median queue-return → ACK | Median send → ACK |
|---|---:|---:|---:|---:|---:|---:|
| Thomas bận, queue local, không resume | 5/5 | 5/5 | 0 / 0 | 0.188 s | 15.273 s | 15.461 s |
| Worker profile Herdr, queue local | 5/5 | 5/5 | 0 / 0 | 0.201 s | 2.846 s | 3.019 s |
| Worker profile Herdr, queue explicit remote | 5/5 | 5/5 | 0 / 0 | 0.026 s | 3.071 s | 3.099 s |

Năm lượt profile-local thành công nên chạy thêm năm lượt explicit-remote theo nhánh owner cho phép. Tổng cộng **15 worker mới**, một coordinator mới. Mọi queue argv đều **không có `--resume`**; không retry. Trong phạm vi quan sát có đúng một ACK cho mỗi dispatch, không có queue error. Raw stdout/stderr/exit nằm trong từng log; không thay lỗi bằng mô tả.

## Topology, quyền và đồng bộ

- Coordinator Astra/medium, approval never, sandbox workspace-write; được tạo mới trên endpoint dưới đây, xác minh UUID/cwd/loaded trước lượt đầu rồi gắn một TUI Herdr no-focus. Initial attach dùng native `codex resume --remote ... UUID` cho chính UUID fixture mới; đó không phải tự resume coordinator khi bell đến.
- Endpoint đã bind: `unix:///Users/tranthien/.codex/app-server-control/app-server-control.sock`. Route local trong fixture này đến cùng coordinator; không suy ra local route luôn tương đương mọi endpoint.
- Worker chạy `codex exec`, Astra/medium, approval never. Ca busy dùng workspace-write, network_access=false. Ca Herdr dùng đúng ba override do launch.py --herdr --dry-run sinh ra: default_permissions=astragentic-local; features.network_proxy=true; permissions.astragentic-local extends :workspace, network enabled, allow đúng socket Herdr. Không thêm socket Codex vào allowlist. Rollout ghi workspace-write/network_access=true cho các worker profile Herdr.
- Callback notify nhận agent-turn-complete thật. Worker UUID trong callback khớp thread.started và session_meta/cwd; UUID và turn-id nonnil. Callback gọi subprocess codex queue thật, không gọi mock hoặc host thay hộ.
- **Đồng bộ ca busy:** callback ghi fired rồi chờ barrier chỉ trong fixture. Controller bắt đầu workload Python sleep(10), đợi native commandExecution started và thread/read active, mới mở barrier cho callback queue. Cả queue-start và queue-return đều nằm giữa command-start/end trong 5/5 lượt. Command duration quan sát 9.986–9.998 s. ACK thuộc turn khác, sau busy turn completed, 5/5. Không chen/steer vào workload.
- Barrier nhằm đặt send đúng vào cửa sổ busy; bảng dùng thời điểm queue-send, **không phải latency notify-fired tự nhiên**. queue→ACK gồm phần workload còn lại và model trả lời. Timestamp ACK là thời điểm observer nhận native item/completed, không tách riêng độ trễ wake.
- Với profile Herdr, coordinator idle khi nhận bell. Thành công này đo tiến trình notify callback; **không chứng minh codex queue chạy từ model tool shell bị sandbox cũng được phép**. Không đo riêng tổ hợp busy + profile + explicit-remote cùng lúc.
- Per-invocation notify override thay notifier mặc định chỉ trong fixture. Không kiểm chứng chaining với Computer Use notifier; config file hash trước/sau không đổi.

## Từng lượt

| Dispatch | Queue seconds | Queue-return → ACK seconds | ACK count |
|---|---:|---:|---:|
| busy-1 | 0.194 | 15.291 | 1 |
| busy-2 | 0.195 | 14.308 | 1 |
| busy-3 | 0.180 | 14.922 | 1 |
| busy-4 | 0.188 | 15.273 | 1 |
| busy-5 | 0.155 | 15.362 | 1 |
| herdr-1 | 0.225 | 2.628 | 1 |
| herdr-2 | 0.201 | 2.987 | 1 |
| herdr-3 | 0.208 | 5.049 | 1 |
| herdr-4 | 0.156 | 2.393 | 1 |
| herdr-5 | 0.173 | 2.846 | 1 |
| herdr-remote-1 | 0.026 | 4.303 | 1 |
| herdr-remote-2 | 0.028 | 3.071 | 1 |
| herdr-remote-3 | 0.026 | 2.684 | 1 |
| herdr-remote-4 | 0.029 | 2.406 | 1 |
| herdr-remote-5 | 0.026 | 8.454 | 1 |

## Evidence và cleanup

- [Summary và context thực tế](evidence/notify-busy-herdr-summary.log).
- [Kết quả/argv/binding/readback toàn bộ](evidence/notify-busy-herdr-results.log).
- [Native turn/item events](evidence/notify-busy-events.log).
- Từng lượt: `evidence/notify-busy-busy-N.log`, `notify-herdr-herdr-N.log`, `notify-herdr-herdr-remote-N.log` (N=1..5).
- [Source fixture và hash](evidence/notify-busy-fixture-source.log): code thí nghiệm đã lưu để audit, không phải payload triển khai.
- [Cleanup](evidence/notify-herdr-cleanup.log): tab fixture wW:tS / pane wW:pZ đóng và readback; coordinator cùng 15 worker thread archived, absent loaded. Bảy thread baseline còn nguyên. Resource helper exit 0, không còn process thuộc worktree, không có project cleanup plug; git worktree remove bình thường, không --force. Fixture/temp root đã xóa. Không động product worker.

## Giới hạn và kết luận cho 6.0.5

Có bằng chứng live cho busy queue-only và notify dưới profile Herdr, gồm route explicit Unix endpoint đã bind. Đây không phải chứng nhận mọi lifecycle: owner-pause/Esc, unloaded, crash, compaction, duplicate callback injection, notify failure/retry, global notifier chaining, worker TUI thay exec, endpoint khác và hơn năm lượt mỗi nhánh **chưa đo**. Không suy ra exactly-once runtime từ 0 duplicate ACK trong mẫu này.

Bell vẫn chỉ là tín hiệu quan sát; ACK không phải task-done. Các check identity/pause/dedup của turn-end.sh production do Thomas viết không được kiểm chứng bởi script fixture này. Không tự đổi DISPATCH sang bỏ các cơ chế quan sát dự phòng. Quyết định tích hợp/phát hành 6.0.5 vẫn thuộc owner.
