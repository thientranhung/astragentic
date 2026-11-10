# Review độc lập bản Codex harness

Hai context Sol độc lập review snapshot `astragentic-codex-review-96fruhxq`, baseline
`f484b22a4a37157ca8fc9a0e723299ccb61e0442`. Phạm vi là các additions chưa tracked
trong AGENTS.md, docs/codex, runtimes/codex, tests/codex; không dùng empty Git diff
để kết luận sạch. Đây là same-provider independent review, **không phải cross-vendor**.

## Standards

Một finding medium: launcher chọn `--orchestrator` khác nhưng helper TOML đã cài
vẫn theo bảng project, có thể chạy model ngoài lựa chọn owner.

Đã sửa: trước khi launch, đối chiếu helper đã cài với bảng thực sự được chọn;
không khớp thì dừng và hướng dẫn reconcile/install/doctor. Không tự đổi model/file.
Regression test cho owner-only override hợp lệ và helper override bị từ chối,
kiểm tra không mutation. Reviewer đọc lại diff xác nhận finding đã giải quyết,
không thấy defect mới. Reviewer không chạy tests; root chạy suite **20/20 đạt**.

## Spec

Một finding medium: QA dispatch chỉ checkout target SHA, trong khi Builder được
phép handback artifact chưa commit. QA có thể kiểm tra nhầm base hoặc đòi commit
không được owner cho phép.

Đã sửa contract: committed artifact dùng checkout riêng; dirty artifact dùng đúng
worktree với writers tạm dừng, hoặc snapshot đã xác minh. Pin manifest/hash gồm
tracked, untracked, deletion/symlink và ignored inputs cần thiết; ghi report ngoài
artifact, kiểm tra drift trước/sau và không tạo temporary commit. Reviewer đọc lại
xác nhận đã giải quyết ở cấp contract. Chưa đo live route theo contract mới.

Một yêu cầu còn partial: journey thực tế theo model/role, Thomas-driven dispatch,
restart/compaction và acceptance liên tục chưa đủ bằng chứng. Quyền Herdr và policy
cross-vendor vẫn là giới hạn riêng; review này không thay các phép đo đó.

Kết quả: Standards 1 finding đã sửa; Spec 1 finding đã sửa ở contract và 1 khoảng
trống acceptance còn mở. Chưa tuyên bố goal hoặc vận hành đầu-cuối hoàn tất.
