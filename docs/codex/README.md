# Astragentic cho Codex

Harness gọn dựa trên Markdown, native Codex và Herdr: bảy role contract, 20 skill Codex và một skill install/update chung,
bảng 14 model assignment, launcher, helper và installer riêng. **Luồng chính đã chạy
đầu-cuối**: Thomas → Shaper/release → Builder → ba reviewer Astra → QA → verify.
Suite hiện tại 33 tests đạt; QA fixture 4/4 không drift. Bắt đầu theo OPERATIONS.md; xem bảng
trạng thái để phân biệt cấu hình đã đo, policy mỗi project và các nhánh chưa benchmark.

Đọc theo thứ tự:

1. [OPERATIONS.md](OPERATIONS.md): cài/cập nhật/gỡ, mở role, dispatch và phục hồi.
2. [IMPLEMENTATION-STATUS.md](IMPLEMENTATION-STATUS.md): bằng chứng và phần còn thiếu.
3. [Runtime README](../../runtimes/codex/README.md): cấu trúc source và tiện ích.
4. [RELEASE-VALIDATION.md](RELEASE-VALIDATION.md): kiểm chứng bản phát hành.
5. [ASTRA-REVIEW.md](ASTRA-REVIEW.md): review Astra và disposition.

Source hiện hành chỉ ở `runtimes/codex`; contract pilot trùng lặp đã gỡ. Prototype
state/receipt/verifier đã gỡ theo yêu cầu owner. Install/update dùng skill chung `astragentic-update-install` và prompt chung
`ADAPT-RUNTIME.md`; agent tự chọn contract riêng cho runtime hiện tại. Flag runtime
là chi tiết adapter nội bộ. Cấu hình/trust cá nhân được giữ nguyên. Raw probe/fixture và tài liệu khảo sát cục bộ không thuộc gói phát hành; xem bảng
trạng thái và báo cáo release cho phạm vi kiểm chứng.
