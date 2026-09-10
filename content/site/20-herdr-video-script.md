# Kịch bản video "herdr trong Astragentic" (2026-09-10, bản nháp cho chủ site duyệt)

Vị trí: trang chủ, mục Comms, thay placeholder "Workspace herdr với năm pane đang chạy". Dựng
bằng HyperFrames như video dispatch, 16:9, không tiếng, lặp, khoảng 42 giây. Khung hình dựng
lại đúng bố cục herdr thật theo ảnh chủ site gửi 2026-09-10: sidebar `spaces` (project + branch),
danh sách `agents · grouped` với chấm trạng thái, hàng tab, ô search, pane chính, status line.

Sự thật lấy từ chính herdr (`herdr --help`, `herdr agent --help`): "terminal workspace manager
for AI coding agents"; nhận diện agent trong pane và trạng thái của nó; socket API với các lệnh
`herdr agent list/read/prompt/wait/start`; `herdr --remote <ssh-target>` và `herdr machine add`
để gắn pane lên server. Lời thoại là viết mới. Không so sánh với công cụ khác.

## Ngôn ngữ hình (theo ảnh hero của herdr.dev, chủ site gửi 2026-09-10)

- Nền rất tối, chữ mono; sidebar trái hai khối: `spaces` (tên project đậm, branch mờ bên
  dưới, chấm màu trước tên) và `agents · grouped` (tên agent đậm, dòng dưới `trạng thái ·
  runtime`, ví dụ `working · claude`, `idle · opencode`, `blocked · claude`, `done · codex`).
- Màu chấm theo trạng thái: working vàng, idle vòng rỗng, blocked đỏ/hồng, done xanh ngọc.
- Hàng tab trên cùng, tab đang chọn nền tím nhạt; pane có viền mảnh và tiêu đề gắn trên
  viền (`claude`, `bun`), pane đang focus viền tím.
- Status line trong pane Claude Code: đường dẫn, branch, ctx bar, dòng `bypass permissions`.
- Video dựng lại đúng các vùng này với dữ liệu của Astragentic; không dùng ảnh thật của herdr.

## Ba phần

### Phần 1 · herdr là gì (0–9 s)

| t | Hình | Chữ trên hình |
|---|---|---|
| 0.0 | Cửa sổ herdr mở ra: sidebar `spaces` với `astragentic · main`, `nizzy-ecom · main`; danh sách agents trống. | Card góc trên: **herdr** · terminal workspace manager for AI coding agents |
| 2.0 | Năm pane lần lượt xuất hiện trong danh sách agents của `astragentic`: `thomas · claude`, `builder-tra-142 · claude`, `builder-tra-143 · codex`, `rin · claude`, `qa · claude`. Mỗi dòng có chấm trạng thái. | Card: Mỗi agent một pane, có tên. |
| 5.0 | Chấm của `builder-tra-142` chuyển vàng "working", `rin` xám "idle", `builder-tra-143` đỏ "blocked". Pane chính đang là `thomas`. | Card: herdr nhận diện agent trong pane và trạng thái của nó: working, blocked, idle. |
| 7.5 | Con trỏ bấm `builder-tra-143`; pane chính đổi sang session Codex đang chờ câu trả lời. | Card: Bấm một tên là đọc được pane đó. |

### Phần 2 · Thomas đọc và chờ được pane của người khác (9–19 s)

| t | Hình | Chữ trên hình |
|---|---|---|
| 9.0 | Danh sách agents phóng to: chấm đỏ tự sáng ở `builder-tra-143`, chữ `blocked` hiện cạnh tên. Không ai cuộn màn hình. | Card: Trạng thái pane là tín hiệu, không phải thứ phải ngồi canh. |
| 12.0 | Pane `thomas`: `⏺ Bash(herdr agent read builder-tra-143)` · `⎿ Empty state dùng widget chung hay vẽ riêng?` | Card: Thomas đọc được pane của mọi agent, không cần ai copy dán. |
| 15.0 | Pane `thomas`: `⏺ Bash(herdr agent wait builder-tra-143 --state idle,blocked)` · `⎿ blocked` | Card: và chờ đúng tín hiệu, thay vì đoán. |
| 17.0 | Pane `thomas`: `⏺ Bash(herdr agent list)` · bốn dòng tên và trạng thái. | Card: Một API cho cả workspace. |

### Phần 3 · trong Astragentic (19–42 s)

| t | Hình | Chữ trên hình |
|---|---|---|
| 19.0 | Pane chính chia hai: trái `builder-tra-142 · claude`, phải `builder-tra-143 · codex`. | Card: Claude Code, Codex, OpenCode cùng một workspace. |
| 21.0 | Trái: dòng preview `› Message from @thomas: …` (cross-session messaging của Claude Code). Phải: `thomas` gõ `herdr agent prompt builder-tra-143 "Dùng EmptyState chung theo contract UI."`, pane Codex nhận prompt và chạy tiếp. | Card: Cùng provider thì nhắn thẳng; khác provider thì đi qua herdr. Thomas nói được với cả hai. |
| 26.0 | Danh sách agents: chấm `builder-tra-143` từ đỏ về vàng rồi xanh "done"; pane `thomas` hiện `⎿ TERMINAL:done pane=…` từ Monitor. | Card: Watcher đọc trạng thái pane, Thomas hành động theo đó. |
| 29.0 | Trong `spaces` xuất hiện `prod-1 · remote` (gắn bằng `herdr machine add prod-1`). Pane mới `deploy · prod-1` mở, prompt hiện hostname server. | Card: Pane không nhất thiết ở máy bạn. |
| 32.0 | Pane `deploy`: `git pull`, `pnpm build`, `systemctl restart app` chạy, log trôi, kết thúc `active (running)`. | Card: Deploy thẳng từ workspace, cùng chỗ với đội. |
| 36.0 | Pane `qa` mở URL vừa deploy, chạy walk; chấm `qa` xanh. | Card: QA walk trên bản vừa lên. |
| 39.0 | Toàn cảnh: năm chấm xanh, sidebar hai space, pane `thomas` ở giữa. | Card cuối: Bạn nhìn thấy mọi pane. Thomas đọc được mọi pane. |
| 42.0 | Giữ 1 giây rồi lặp. | |

## Điều người xem phải nhận ra

1. herdr là một workspace cho agent: mỗi agent một pane có tên, có trạng thái, có API.
2. Vì pane có tên, trạng thái và API, Thomas đọc và chờ được pane của người khác.
3. Nhờ vậy các agent khác provider vẫn làm việc chung, và deploy làm ngay trong workspace.

## Chỗ cần chủ site quyết

- Đoạn deploy: cách anh làm thật là gắn server bằng `herdr machine add` rồi mở pane trên đó, hay
  agent chạy `ssh` từ pane local? Tôi vẽ theo cách thật.
- Ba lệnh deploy trong pane (`git pull`, `pnpm build`, `systemctl restart app`) là ví dụ; đổi
  sang lệnh anh dùng (Docker, Cloudflare, Coolify…) để người xem thấy quen.
- Cần thêm hai ảnh thật: danh sách agents lúc có chấm blocked/idle (lấy đúng màu và chữ), và
  một pane Codex trong herdr.
- Tên tab và tên space: dùng `astragentic`, `nizzy-ecom`, `prod-1` như trên, hay đổi.
