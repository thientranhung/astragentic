# Kết quả probe Codex, 2026-11-05

CLI: `codex-cli 0.166.0`. Lệnh tái lập: `python3 tests/codex/probe_context.py`.
Fixture: Git repo tạm có khoảng trắng trong path, nested cwd, CODEX_HOME riêng,
AGENTS root/nested, một skill .agents, một skill chỉ .claude, một helper TOML.
Trust chỉ ghi trong config fixture; không sửa user config. Không gọi model.
Script xóa fixture khi kết thúc, chỉ in assertion sentinel, không in prompt người dùng.

## Context — 10/10 assertion PASS

- AGENTS root và nested xuất hiện trong prompt render.
- `-c developer_instructions=...` xuất hiện cùng user prompt.
- Description skill .agents xuất hiện; body chưa bị nạp sẵn.
- Skill chỉ trong .claude không xuất hiện ở catalog của fixture Codex.
- Body helper TOML không lẫn vào prompt parent.
- Lần render sau không truyền override không còn role sentinel; control prompt đúng.

Đây là prompt rendering thật qua CLI, không phải mock. Nó không chứng minh model
đã tuân thủ role, skill được invoke, hoặc context giữ được sau compact/resume.
Đường launcher có thể dùng argv `-c` để truyền hướng dẫn role mà không sửa user
config. Cần kết hợp các developer instructions hiện có; không được âm thầm thay
mất policy project. Phải kiểm tra riêng trước khi launcher dùng trong project thật.

## Helper TOML — chưa xác minh registration

Probe ban đầu kỳ vọng description helper nằm trong prompt JSON: kết quả FALSE.
Body helper không ở parent là đúng nhưng không chứng minh agent đã đăng ký.
Custom agents có thể được trình bày qua tool schema ngoài prompt-input; đó mới là
hypothesis, chưa kiểm chứng. Không kết luận CLI không hỗ trợ custom agents và
không ghi C03 PASS. Cần probe schema hoặc spawn fixture có kiểm soát.

## Transport — help được kiểm tra, chưa chạy session gửi nhận

`codex queue --help` của CLI này có `--thread`, `--message`, `--resume`.
Help ghi rõ failed resume chỉ warning, command vẫn success. Do đó:

- Exit 0 của queue chỉ chứng minh enqueue thành công theo CLI, không là RECEIVED.
- Record cần dispatch/attempt/message ID; worker phải ack đúng brief.
- Không retry bằng cách tự tạo worker thứ hai khi chưa reconcile session cũ.
- Chưa gửi vào session thật, chưa đo idle/busy delivery, duplicate hay crash recovery.

Không chọn transport production chỉ từ help. C01/C02 mới được chứng minh một phần;
C03/C04/D01–D05 còn chưa xác minh. Chưa có launcher được tuyên bố sẵn sàng dùng.

## Điều chỉnh transport: Herdr là đường chính

Đã đọc skill Herdr và kiểm tra binary `herdr 0.9.5` qua các nhóm help.
Có agent start (kind codex, pane ID), prompt, wait, get/read; pane records có
agent_status. Không cần mặc định tự xây queue/inbox để thay khả năng này.
Codex queue ở trên chỉ là khảo sát phụ, không còn là transport đề xuất chính.

Probe `pane current --current` trả pane có cwd astraler-video-studio, khác repo
astragentic của task. Không gửi prompt, launch hay mutate pane đó. Dispatch thực
phải resolve workspace/project và ID cụ thể; biến môi trường không đủ xác nhận
đúng project. Chưa thực hiện end-to-end Herdr dispatch trong lượt này.

Help nhóm `herdr wait` trả unknown command (exit 2). Cú pháp đúng của binary là
`herdr agent wait <target> --until STATUS --timeout MS`. Đây là khác biệt skill/binary
đã đo, không phải thiếu khả năng theo dõi trạng thái.
