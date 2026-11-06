# Kiểm chứng phát hành 6.0.2

Ngày: 2026-11-06. Baseline: 6.0.1 (`86b0039`).

- Nguyên nhân đã xác định từ log startup của đúng worker: direct
  `collaboration.spawn_agent` có đủ năm helper; worker tìm trong nested `ALL_TOOLS`
  rồi báo thiếu. Không có lần spawn thất bại trong đoạn log được kiểm tra. Bản sửa
  hướng dẫn đọc đúng declaration và gọi direct tool; không sửa trust để che triệu chứng.
- Suite Codex hiện tại: **34/34 đạt**, gồm installer, distribution, launcher,
  transport và probe tránh nhận tên helper trong prose là đăng ký công cụ.
- CLI 0.166.0: fixture trusted thấy 5/5 helper trong tool schema; chưa trust hoặc
  agents.enabled=false thấy 0/5; linked worktree có repo cha trusted thấy 5/5.
  Đây là discovery của tiến trình mới, không chứng minh phiên cũ đã refresh.
- Nâng cấp từ tag 6.0.1 thật qua shared stage → Codex apply → doctor đạt trong fixture;
  owner orchestrator và file Claude giữ byte-identical. Sau sửa procedure, chạy lại
  đạt với recursion guard; staging đầy đủ đã chạy trên candidate trước đó.
- Ví dụ kiểm tra identity: UUID hợp lệ được chấp nhận; nil, sai cú pháp và thiếu env
  bị từ chối (4/4). Đây là procedure, không phải gate ghi file được runtime cưỡng chế.
- Astra review độc lập: đã sửa mâu thuẫn pre-arm trong DISPATCH.md; pass source ở vòng
  cuối. Finding tài liệu dùng report 6.0.0 đã sửa bằng báo cáo này. Review là đọc source,
  tách biệt với test và probe do maintainer chạy; không phải cross-vendor.
- Claude payload, hooks, shared skill mirrors và mechanical installer không đổi.
  Không có thao tác sửa/restart worker dự án thật trong kiểm chứng patch.
- Phép gọi helper native trong fixture riêng đạt: parent Sol gọi trực tiếp
  astragentic_reviewer, fork context mới, không override model/effort; nhận kết quả
  từ helper rồi kết thúc exit 0. Đây là bài kiểm tra claim đơn giản, không chứng nhận
  chất lượng review sản phẩm hay mọi model/role. Không chạy trong worker dự án thật.
- Published-artifact smoke test chỉ thực hiện sau push/tag; kết quả ghi tại GitHub
  Release notes, không suy ra từ fixture local. Chưa cài vào dự án downstream ở đây.

## Bằng chứng lịch sử 6.0.0


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
