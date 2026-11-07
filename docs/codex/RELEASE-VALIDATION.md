# Kiểm chứng phát hành 6.0.3

Ngày: 2026-11-07. Baseline: 6.0.2 (`cf583c0`).

- Stage1/2 được coordinator dự án chấp nhận trong phạm vi fixture trên daemon local
  CLI 0.167.0: UUID mới, binding trước lượt chạy; Astra/medium coordinator và hai
  Sol/medium Builder, owner yolo. Hai lượt Builder chồng 10,929941 giây; hai ACK,
  một follow-up/effect; duplicate trả DUPLICATE không lặp thao tác. Busy event được
  nhận lúc active, xử lý sau lượt workload. Queue acceptance tách ACK/effect.
- Native default local route cũng trả LOCAL_ACK đúng fixture. Không thử resume UUID
  sản phẩm. Pause exclusion là thủ tục không gửi, không phải runtime gate.
- Herdr fixture mới: native `resume --remote unix://... UUID` gắn cùng daemon, writer
  PID giữ nguyên; không thêm inference turn khi attach. Hai queue lượt mới hiển thị
  marker đúng trong toàn viewport, tổng ba turn; model/effort/approval/sandbox giữ
  nguyên. Đóng tab không làm mất daemon thread; archive idle rồi readback absent.
- Các phép đọc viewport đầu bị cắt 60 dòng cuối nên thiếu output phía trên; không
  tính là pass. Một probe khác dừng vì baseline đổi trong lúc chạy; không
  quy thành lỗi runtime. Fixture cuối đạt, baseline preserved; mọi tab/thread thử
  đều đã đóng/archive, scratch giữ audit. Stage1/2 không chạy lại.
- Launcher thêm opt-in Unix endpoint, không đổi default hay config/trust; test kiểm
  tra argv thật qua subprocess và worker shell recipe. Không gọi socket tồn tại là
  proof về ownership. Tài liệu giữ separate-session binding, continuation và close-out.
- Suite Codex: 36/36 đạt; Astra/high review source PASS, không P1/P2, một P3
  route resume đã sửa. Upgrade thực từ tag 6.0.2 qua shared stage → plan/apply →
  doctor và launcher endpoint dry-run đạt; owner orchestrator/Claude sentinel giữ byte.
- Source reachability, docs-staleness, ledger-index và whitespace đạt. Source
  RULES.md có một dòng stale từ baseline 6.0.2, ba input byte-identical; không sửa
  payload Claude cho Codex. Installer vốn regenerate rồi check RULES trên staged
  package (gate thực tại install.sh); candidate staging đạt gate này.
- Full selftest trên archive bất biến ngoài repo cha: **228 passed, 0 failed**,
  không skip section. Lượt mutable-tree và archive đặt dưới Git-ignored `.scratch`
  không dùng làm bằng chứng pass; log chẩn đoán giữ cục bộ. Final exact-index
  stage/upgrade kiểm tra riêng; nested recursion guard dùng sau full selftest này.
- Public install smoke thực hiện sau tag; kết quả ở release notes/handoff. Không
  suy ra installed/adapted hoặc startup sản phẩm từ fixture.
- Claude payload/shared skill mirrors không đổi. Unloaded/crash/compaction, mọi
  permission mode, và migration phiên sản phẩm cũ chưa đo. Không có product waiver.

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
