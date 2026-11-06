# Kiểm chứng phát hành 6.0.0

Ngày: 2026-11-06. Đây là báo cáo release, tách khỏi pilot vận hành native trước đó.

- Astra review độc lập: không có blocker runtime mới; đã cập nhật tài liệu phiên bản,
  số skill/test và yêu cầu Python 3.9+ (tests dùng Python 3.11+).
- Suite Codex: 30/30 đạt, bao gồm shell thật cho stage/apply/upgrade local tags,
  cả hai adapter và bảo toàn shared skill/owner config.
- Native catalog: 21/21 skill được discover trong temporary CODEX_HOME, không sửa
  config/trust cá nhân. Không chạy Claude hoặc suy diễn tự chọn skill từ catalog.
- Legacy selftest đầy đủ: **228 passed, 0 failed**, không skip section.
- Reachability, docs-staleness, shell syntax và staged whitespace: đạt.
- Snapshot đúng Git index: default stage → shared prompt → Codex apply/doctor,
  launcher dry-run đạt trên project trống. Staging snapshot dùng recursion guard;
  full legacy selftest phía trên chạy riêng không guard.
- Fixture nâng cấp dùng wrapper 5.1.4 cố định, byte-identical với commit f484b22,
  để test còn đúng trong shallow clone 6.0.0. Nhóm distribution rerun: 5/5 đạt.
- Kiểm tra download/install từ GitHub được thực hiện sau push tag; kết quả được
  ghi tại GitHub Release notes khi hoàn tất, không suy ra từ snapshot local.

Raw session, archive, temporary worktree và dữ liệu khảo sát cục bộ không đưa lên
GitHub. Chỉ source, tests và tài liệu vận hành/review hiện hành được phát hành.
Bằng chứng pilot và giới hạn: [IMPLEMENTATION-STATUS.md](IMPLEMENTATION-STATUS.md).
