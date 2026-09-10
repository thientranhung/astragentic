# Kịch bản video "herdr trong Astragentic" (2026-09-10, bản nháp cho chủ site duyệt)

Vị trí: trang chủ, mục Comms, thay placeholder "Workspace herdr với năm pane đang chạy". Dựng
bằng HyperFrames như video dispatch, 16:9, không tiếng, lặp, khoảng 32 giây. Khung hình dựng
lại đúng bố cục herdr thật theo ảnh chủ site gửi 2026-09-10: sidebar `spaces` (project + branch),
danh sách `agents · grouped` với chấm trạng thái, hàng tab, ô search, pane chính, status line.

Sự thật lấy từ herdr.dev (đọc 2026-09-10: trang chủ, llms.txt, agent-guide.md, docs/agents,
docs/reference/cli, docs/reference/socket-api, docs/how-to-work, docs/integrations/claude) và
từ `herdr --help` trên máy:

- Tagline: "the runtime coding agents run on". Định nghĩa: một background server giữ các
  terminal session cho coding agent, chạy liên tục trên nhiều máy mà không cần người đang attach.
- Tự nhận diện trạng thái agent: `working`, `blocked`, `done`, `idle`, `unknown`.
- "Agents can split panes, start each other, prompt each other, and wait until another agent is
  genuinely blocked instead of firing keystrokes and hoping." CLI và socket API là cùng một bề
  mặt mà agent điều khiển: `herdr agent list/read/prompt/wait/start`.
- 21 agent nhận diện sẵn, trong đó Claude Code, Codex, opencode. Mouse-first.
- Remote: chạy herdr trên máy có code và credential rồi `herdr --remote <host>`, hoặc
  `herdr machine add <host> --label <label>` để workspace phối hợp nhiều máy.
- Herdr, Inc., Apache 2.0, v0.9.0. Lời thoại là viết mới. Không so sánh với công cụ khác.

## Ngôn ngữ hình (theo ảnh hero của herdr.dev, chủ site gửi 2026-09-10)

- Nền rất tối, chữ mono; sidebar trái hai khối: `spaces` (tên project đậm, branch mờ bên
  dưới, chấm màu trước tên) và `agents · grouped` (tên agent đậm, dòng dưới `trạng thái ·
  runtime`, ví dụ `working · claude`, `idle · opencode`, `blocked · claude`, `done · codex`).
- Màu chấm theo trạng thái: working vàng, idle vòng rỗng, blocked đỏ/hồng, done xanh ngọc.
- Hàng tab trên cùng, tab đang chọn nền tím nhạt; pane có viền mảnh và tiêu đề gắn trên
  viền (`claude`, `bun`), pane đang focus viền tím.
- Status line trong pane Claude Code: đường dẫn, branch, ctx bar, dòng `bypass permissions`.
- Video dựng lại đúng các vùng này với dữ liệu của Astragentic; không dùng ảnh thật của herdr.

## Hai phần, khoảng 32 giây

Người xem là dev chưa từng thấy herdr. Câu hỏi của họ theo thứ tự: nó trông thế nào, nó
cho tôi thấy gì, rồi Astragentic dùng nó làm gì. Video trả lời đúng thứ tự đó, mỗi nhịp một
card chữ ngắn ở góc trên bên phải.

### Phần 1 · herdr trông thế nào (0–11 s)

| t | Hình | Card |
|---|---|---|
| 0.0 | Cửa sổ herdr mở ra, nền tối: sidebar `spaces` với `astragentic · main` (đang chọn) và `shop-demo · main`; khối `agents · grouped` trống; hàng tab `thomas` `+`; pane chính trống. | **herdr** · the runtime coding agents run on |
| 2.0 | Năm agent lần lượt xuất hiện trong `agents`, mỗi dòng tên đậm và dòng dưới `trạng thái · runtime`: `thomas` working · claude, `builder-tra-142` working · claude, `builder-tra-143` working · codex, `rin` idle · claude, `qa` idle · claude. Chấm màu theo trạng thái. Pane chính hiện session `thomas` (Claude Code TUI thu nhỏ). | Mỗi agent một pane, có tên, có trạng thái. |
| 6.0 | Chấm của `builder-tra-143` đổi sang đỏ, chữ đổi `blocked · codex`. Không ai gõ gì. | herdr tự nhận diện: working, blocked, done, idle. |
| 8.5 | Con trỏ bấm `builder-tra-143`; tab mới mở, pane chính đổi sang session Codex đang chờ, thấy câu hỏi "Empty state dùng widget chung hay vẽ riêng?". | Bấm một tên là đọc được pane đó. Bạn là khách hàng, bạn xem được mọi pane. |

### Phần 2 · Astragentic dùng herdr thế nào (11–32 s)

| t | Hình | Card |
|---|---|---|
| 11.0 | Quay về pane `thomas`. Dòng `⎿ TERMINAL:blocked pane=builder-tra-143` hiện từ Monitor. | Watcher đọc trạng thái pane, Thomas biết ngay ai đang kẹt. |
| 13.0 | Pane `thomas`: `⏺ Bash(herdr agent read builder-tra-143)` · `⎿ Empty state dùng widget chung hay vẽ riêng?` | Thomas đọc pane của Builder, không cần ai copy dán. |
| 16.0 | Pane `thomas`: `⏺ Bash(herdr agent prompt builder-tra-143 "Dùng EmptyState chung theo contract UI. Tiếp tục.")`. Chia đôi pane chính: phải là `builder-tra-143 · codex` nhận đúng dòng đó và chạy tiếp. | Builder chạy Codex, không có cross-session messaging: Thomas nói qua herdr. |
| 20.0 | Pane trái đổi sang `builder-tra-142 · claude`: dòng preview `› Message from @thomas: … (ctrl+o to expand)`. | Builder chạy Claude Code: Thomas nhắn thẳng. Cùng một workspace, hai runtime. |
| 23.0 | Pane `thomas`: `⏺ Bash(herdr agent wait builder-tra-143 --state idle,done)`. Danh sách `agents`: chấm `builder-tra-143` từ đỏ về vàng, rồi xanh `done · codex`. | Thomas chờ đúng tín hiệu, thay vì đoán. |
| 26.5 | Bấm space `shop-demo`: danh sách agents đổi sang đội của project đó, `thomas`, `builder-shop-17`, `qa`, cũng đang chạy. Bấm lại `astragentic`. | Mỗi project một space, một đội. Cùng lúc. |
| 29.5 | Toàn cảnh: hai space, năm agent, chấm xanh và vàng, pane `thomas` ở giữa. | Bạn nhìn thấy mọi pane. Thomas đọc được mọi pane. |
| 32.0 | Giữ 1 giây rồi lặp. | |

## Điều người xem phải nhận ra

1. herdr là một workspace cho agent: mỗi agent một pane có tên và trạng thái tự nhận diện.
2. Khách hàng bấm một tên là đọc được pane đó; không có gì giấu.
3. Thomas đọc, nhắn và chờ pane của người khác qua CLI, kể cả Builder chạy runtime khác.
4. Nhiều project, nhiều đội, cùng lúc, trong một cửa sổ.

## Đã chốt với chủ site (2026-09-10)

- Không so sánh với công cụ khác. Không có đoạn deploy. Tên hiển thị: `astragentic` và project
  demo `shop-demo`. Không cần thêm ảnh thật; ảnh hero của herdr.dev là chuẩn hình.
