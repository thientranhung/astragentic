# Học gì từ AWS CLI Agent Orchestrator cho Astragentic Codex?

Ngày: 2026-11-07. Khảo sát source/docs/test tại CAO commit
[`cba4f89c67027a2e93e394f8bcc1366ac1ddd302`](https://github.com/awslabs/cli-agent-orchestrator/commit/cba4f89c67027a2e93e394f8bcc1366ac1ddd302), đối chiếu Astragentic v6.0.3.
Chưa cài, chạy CAO hoặc chạy test upstream. Đây là kết luận từ mã nguồn, không phải chứng nhận runtime.

## Kết luận cho anh

CAO có cơ chế giao tiếp thực chất: server điều phối, inbox lưu DB, đánh thức theo sự kiện và quét lại tin đang chờ. Nhưng với Codex, họ vẫn gửi prompt qua tmux và đọc màn hình để xác định trạng thái. Điều này hữu ích khi muốn điều phối nhiều CLI khác nhau bằng một giao diện chung; chưa phải lý do để thay native queue đã đo được của Astragentic.

Nên học cách quan sát và phục hồi của họ. Chưa nên đưa CAO, thêm mailbox DB hay scheduler vào Astragentic.

## Họ giao tiếp thế nào?

| Đường giao tiếp | Hành vi trong source | Giới hạn cần hiểu |
|---|---|---|
| `handoff` | Tạo worker, gửi việc, chờ kết quả, lấy output và dọn worker khi thành công | `job_id` không bảo đảm chống chạy lặp; retry có thể tạo execution mới |
| `send_message` | Lưu inbox trước, thử giao ngay; nếu bận thì chờ | Thành công API chưa phải agent ACK |
| Nhận tin khi rảnh | Sự kiện IDLE/COMPLETED kích hoạt dispatch; sweep tìm pending bị bỏ sót | Cần server và nhận diện trạng thái hoạt động đúng |
| Codex provider | Đọc terminal/TUI, gửi input qua tmux | Phụ thuộc hình thức output và phiên bản CLI |

Nguồn: [handoff và retry contract](https://github.com/awslabs/cli-agent-orchestrator/blob/cba4f89c67027a2e93e394f8bcc1366ac1ddd302/src/cli_agent_orchestrator/utils/orchestration.py#L2035-L2098),
[inbox event dispatch](https://github.com/awslabs/cli-agent-orchestrator/blob/cba4f89c67027a2e93e394f8bcc1366ac1ddd302/src/cli_agent_orchestrator/services/inbox_service.py#L90-L155),
[reconciliation sweep](https://github.com/awslabs/cli-agent-orchestrator/blob/cba4f89c67027a2e93e394f8bcc1366ac1ddd302/src/cli_agent_orchestrator/services/inbox_service.py#L547-L590),
[Codex status detection](https://github.com/awslabs/cli-agent-orchestrator/blob/cba4f89c67027a2e93e394f8bcc1366ac1ddd302/docs/codex-cli.md#L54-L123).

Một chi tiết quan trọng: inbox đánh dấu DELIVERED trước thao tác gửi để tránh race trong process. Confirmation dựa trên trạng thái/output mới; khi kết quả mơ hồ thì hạn chế gửi lại toàn bộ prompt. Vì vậy DELIVERED không đồng nghĩa agent đã xử lý. Lock theo terminal là trong process; upstream test cũng ghi nhận chưa có atomic DB claim. Không nên gọi đây là exactly-once phân tán.
[Delivery và confirmation](https://github.com/awslabs/cli-agent-orchestrator/blob/cba4f89c67027a2e93e394f8bcc1366ac1ddd302/src/cli_agent_orchestrator/services/inbox_service.py#L250-L517),
[race test](https://github.com/awslabs/cli-agent-orchestrator/blob/cba4f89c67027a2e93e394f8bcc1366ac1ddd302/test/services/test_inbox_service.py#L855-L928).

## Đối chiếu Astragentic 6.0.3

| Bài học | Astragentic hiện tại | Việc đáng làm tiếp |
|---|---|---|
| Tách gửi / nhận / hoàn tất | DISPATCH đã tách queue acceptance, ACK và artifact result | Giữ nguyên; không thêm trạng thái `delivered` nếu native không chứng minh được |
| Tin đến lúc worker bận | Stage2 đã đo xử lý sau lượt hiện tại; hai Builder chạy chồng thời gian | Không cần thêm inbox engine |
| Phục hồi khi mất tín hiệu | Có checkpoint, event ID, đối chiếu receipt trước retry | Đo thêm mất kết nối, coordinator restart và recipient unloaded bằng fixture riêng |
| Coordinator tiếp tục sau review | Có hướng dẫn thu kết quả, disposition, follow-up hoặc blocker có người chịu trách nhiệm | Thêm ca acceptance khôi phục kết quả đã xong sau gián đoạn; không dùng self-queue để giữ sống |
| Quan sát công việc chờ | Có bảng event/ACK/result và UUID/endpoint binding | Dùng bảng hiện có để chỉ rõ tin nào thiếu ACK, việc nào thiếu result, ai quan sát tiếp |

Hợp đồng đối chiếu: [DISPATCH](../../runtimes/codex/.codex/DISPATCH.md),
[OPERATIONS](OPERATIONS.md), [release validation](RELEASE-VALIDATION.md).
Pause và dedup của Astragentic vẫn là quy trình, chưa phải bảo đảm runtime tự cưỡng chế.

## Ba ưu tiên nhỏ, chưa tự triển khai

1. **Kiểm chứng phục hồi:** fixture mới cho coordinator gián đoạn và recipient unloaded. Tiêu chí: thu được kết quả cũ, không phát lại tác vụ, không vượt owner pause, không bỏ quên follow-up. Chỉ dùng hành vi native đã xác nhận; ghi NOT MEASURED cho nhánh chưa chạy.
2. **Làm rõ bảng đang chờ:** bổ sung thời điểm quan sát gần nhất và hành động tiếp theo khi thật sự cần. Dùng Markdown hiện có, không thêm database hay daemon. Queue ID, ACK và result là ba bằng chứng riêng.
3. **Kiểm chứng nhận diện phiên đã đóng:** không gửi fallback vào pane đã thành shell hoặc pane được tái sử dụng. Xác minh lại UUID, endpoint, cwd và binding trước mỗi recovery. Không suy luận sở hữu từ tên tab hoặc trạng thái idle.

Các đề xuất trên là suy luận áp dụng từ source CAO và khoảng trống đo lường của Astragentic, chưa phải tính năng vừa triển khai.

## Không sao chép vào Astragentic

- Bộ điều phối server + DB + tmux chỉ để thay queue native.
- Parser màn hình Codex như nguồn xác nhận hoàn thành chính.
- Default yolo hoặc tự chấp nhận workspace trust. Quyền và trust vẫn do owner chọn.
- Tự động resend khi timeout, tự đánh thức phiên owner-paused, hoặc xem ACK là hoàn tất.

Tài liệu Codex của CAO mô tả profile, quyền launch và trust handling; đó là lựa chọn sản phẩm của họ, không phải yêu cầu cho Astragentic.
[Codex provider documentation](https://github.com/awslabs/cli-agent-orchestrator/blob/cba4f89c67027a2e93e394f8bcc1366ac1ddd302/docs/codex-cli.md).

## Phạm vi bàn giao

Đã đọc và đối chiếu source/docs/test, không benchmark hay security audit toàn bộ CAO. Không thay đổi runtime Astragentic, Claude, project Nizzy/Etsy hoặc phiên đang hoạt động trong nghiên cứu này. Không phát hành thêm version cho báo cáo.

Bản phân tích nguồn chi tiết nằm tại `.scratch/codex/cao-research-20261107/agent-findings.md` trong checkout nghiên cứu; đây là evidence cục bộ, không thuộc gói cài đặt.
