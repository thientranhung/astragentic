# Trạng thái Astragentic Codex 6.0.3

Khung vận hành Codex độc lập với Claude; dùng chung skill install/update và entrypoint
stage → adaptation. Có bảy role, 20 skill Codex và một skill cập nhật chung, năm helper
TOML cùng bảng 14 model assignment. Hướng dẫn: [OPERATIONS.md](OPERATIONS.md).

| Phạm vi | Bằng chứng và giới hạn |
|---|---|
| Installer / distribution | 36 tests: stage chung, apply Claude/Codex, upgrade local tag, giữ owner config, chặn drift/collision, uninstall giữ shared skill không thuộc Codex |
| Discovery | Native Codex catalog 21/21, không thiếu; không phải phép thử model tự chọn skill |
| Model / helpers | Một bảng cấu hình cho launcher/helper; lệch bảng thì dừng. Model access phụ thuộc tài khoản của project |
| Pilot tích hợp | Thomas → Shaper/release → Builder → ba Astra review → QA → verify đã chạy trong fixture; QA suite và oracle đều 4/4, không drift |
| Queue / Herdr | CLI 0.167.0: fixture hai Builder trên cùng daemon, queue hai chiều/follow-up, busy deferred processing; Herdr TUI attach cùng endpoint giữ writer/quyền, queue trả kết quả, detach/archive. Không chứng nhận migration phiên sản phẩm cũ |
| Resume | Pilot đóng TUI/resume đúng UUID, không redispatch, tracker và artifact không đổi |
| Review | Astra review core và distribution; các finding đã xử lý. Đây là review độc lập cùng provider, không phải cross-vendor |
| Chưa đo | Agent tự chọn update skill từ câu tự nhiên; adaptation toàn bộ trên project thật; mọi tổ hợp model/role và remote tracker |

Pilot dùng Sol override cho Thomas/Shaper, Sol cho Builder/QA và Astra/high cho
reviewer. Model production mặc định vẫn theo orchestrator; không suy diễn pilot là
benchmark tất cả assignment. Cross-vendor OFF chỉ thuộc pilot được cho phép, không
phải mặc định sản phẩm. Chọn provider khác hoặc quyết định OFF rõ ràng cho gate còn
thiếu cấu hình. Không tự thay model khi lỗi quota/capacity.

Raw fixture/rollout và archive phát triển được giữ cục bộ, không xuất bản. Các kết
quả trên là báo cáo phạm vi đã đo; kiểm tra release mới được ghi riêng tại
[RELEASE-VALIDATION.md](RELEASE-VALIDATION.md). Prose không phải sandbox hay gate
commit/merge tự cưỡng chế.
