# Astragentic Codex runtime

Overlay Codex riêng, không thay payload Claude. Trong release đã stage, đọc
[ADAPT-HARNESS-CODEX.md](ADAPT-HARNESS-CODEX.md) để setup project.

| Thành phần | Trách nhiệm |
|---|---|
| `.codex/roles/` | Bảy vai trò và common contract, độc lập với Claude |
| `.agents/skills/` | 20 entrypoint `codex-*` và skill chung `astragentic-update-install`; mapping cài tại `.codex/astragentic/skill-map.json` |
| `turn-end.sh` | bell TURN-END: Codex `notify` của worker queue một dòng về Thomas khi lượt kết thúc (cài tại `.codex/astragentic/turn-end.sh`) |
| `.agents/orchestrator-for-codex.md` | 14 model/effort assignment do owner kiểm soát |
| `.codex/DISPATCH.md` | Quy trình native Herdr/Git/queue và record Markdown |
| `launch.py` | Mở Thomas, BA, Quick Builder với model/effort đúng bảng |
| `helpers.py` | Render năm native helper TOML; `--probe PROJECT` kiểm tra fresh tool schema, không chứng minh model access |
| `transport.py` | Queue adapter tùy chọn, gửi một lần; không tự retry/resume hoặc xác nhận delivery |
| `install.py` | Install/upgrade/doctor/uninstall file do manifest quản lý |

Trong project có skill, chỉ cần nói: “Astragentic có bản mới rồi, kiểm tra phiên
bản và cập nhật.” Skill `astragentic-update-install` dùng quy trình chung cho
runtime hiện tại. Nếu chưa có skill, bootstrap bằng bộ cài chung rồi làm theo
prompt được in ra. Từ checkout nguồn đã được owner chỉ định:

```sh
bash install.sh /absolute/path/to/project
```

Khi đang ở release Codex nội bộ (thay vì package chung), dùng `--runtime codex`;
đây là chi tiết adapter dành cho agent, không phải lệnh owner cần nhớ.
Lệnh stage release rồi in prompt cho Codex. Agent đọc project, preview, apply qua
entrypoint và hoàn tất adaptation. `--plan` không ghi file; `--apply` cài file và
refresh wrapper nhưng vẫn cần adaptation. Phiên bản file ở
`.astraler/codex/state/installed-version`; phiên bản đã setup ở `state/adapted-version`.
Sau setup, trong project đích:

```sh
bash .astraler/astragentic.sh version --runtime codex
bash .astraler/astragentic.sh doctor --runtime codex
bash .astraler/astragentic.sh update --runtime codex
python3 .codex/astragentic/launch.py thomas --project .
```

Wrapper cũ chưa hiểu `--runtime`; bootstrap bằng get.sh của release mới một lần.
Installer nội bộ `install.py` hỗ trợ preview/doctor/uninstall. Dùng direct apply
cho worktree overlay khi không cần bookkeeping release; setup project chính dùng
entrypoint phía trên. Gỡ chỉ xóa file nguyên vẹn thuộc manifest, giữ bảng owner.
Xung đột/file đã sửa làm dừng trước khi ghi. Không sửa trust/config cá nhân.
Mở phiên Codex mới sau cài để tải catalog/helper.
Launcher có `--dry-run`, `--orchestrator PATH` và opt-in `--yolo` (từ 6.0.1). Yolo không ghép với `--herdr`; dispatch mới phải truyền flag tường
minh theo permission mode trong bootstrap/record. Không suy ra quyền từ môi trường. Worktree mới cần cài overlay và
chạy doctor riêng, mang snapshot config owner nếu chưa có; xem DISPATCH.md.

Kiểm tra tiện ích/installer:

```sh
python3 -m unittest discover -s tests/codex -p 'test_*.py'
```

Hiện có 49 tests đạt. Probe `python3 tests/codex/probe_overlay.py` chạy installer/doctor
thật và discover 21/21 skill; `python3 tests/codex/probe_context.py` đạt 10 assertions.
Các probe có phạm vi riêng, không thay cho
hành trình Thomas → worker → handback → QA → verify. Native explorer đã được spawn
đúng Luna/high trong fixture; Spec và ba reviewer Builder đã đo Astra/high
trong pilot riêng. Không có custom scheduler, state machine hay verifier engine.

Bằng chứng phát triển và hướng dẫn chi tiết nằm trong checkout nguồn tại
`docs/codex/OPERATIONS.md` và `docs/codex/IMPLEMENTATION-STATUS.md`; chúng không
được đóng gói trong release Codex. Pilot đã nối Thomas → Shaper → Builder → ba
Astra reviews → QA → verify. Queue trong sandbox lỗi pre-accept; Herdr fallback
đã đo. Dùng launcher `--herdr` để opt-in socket profile, không ghi personal config.

## Merge message preflight

`.codex/astragentic/merge.py` validates required project trailers and the candidate HEAD
before an explicitly authorized GitHub merge. It defaults to check-only. See
`.codex/DISPATCH.md` for the exact command and optional project validator contract.
This is a command boundary, not a hook intercepting direct `gh` use; it does not replace
review, QA, station, owner permission or post-merge readback.
