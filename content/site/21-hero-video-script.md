# Kịch bản video hero "Một ngày làm việc với Thomas" (2026-09-10, bản nháp cho chủ site duyệt)

Vị trí: trang chủ, hero, ngay dưới hai nút CTA, cùng khung Shot có badge "mô phỏng" như hai
video kia. Dựng bằng HyperFrames, 16:9, không tiếng, lặp, khoảng 55 giây. Độ dài không phải
ràng buộc; điều phải truyền tải là: mở herdr, gọi Thomas, nói chuyện như với một người đại
diện, Thomas tự suy luận chọn việc trên board, điều phối team, rồi báo kết quả về.

Nguyên liệu dùng lại:

- Khung herdr (sidebar `spaces`, `agents · grouped`, tab, pane, status line) từ `video/herdr`.
- TUI Claude Code, dòng preview `› Message from @thomas: … (ctrl+o to expand)`, các dòng
  `⏺ Bash(...)`, `⏺ Monitor(...)`, `⎿ TERMINAL:blocked` từ `video/dispatch`.
- Board: ảnh thật `public/shots/tracker-linear.jpg` (project Inception trên Linear). Đoạn
  zoom là GSAP scale + translate lên ảnh, không dựng lại board.
- Space đặt theo tên dự án được cài Astragentic: `inception · main` (không phải `astragentic`,
  vì Astragentic là bộ cài vào dự án khác). Space thứ hai mờ bên dưới: `shop-demo · main`.

Sự thật trên board (đọc từ ảnh): Backlog 5 (TRA-182 QA needs-info, TRA-204, TRA-183 needs-info,
TRA-141 needs-info, TRA-200 ready-for-agent), Todo 1 (TRA-54 needs-info), In Progress 1
(TRA-196 Bug ready-for-agent), Done 50. Thomas suy luận trên đúng dữ liệu này.

## Bốn cảnh, khoảng 55 giây

Card chữ ngắn góc trên bên phải, mỗi cảnh một câu, như video herdr.

### Cảnh 1 · Mở herdr, gọi Thomas (0–9 s)

| t | Hình | Card |
|---|---|---|
| 0.0 | Cửa sổ herdr tối: `spaces` có `inception · main` (chọn) và `shop-demo · main`; `agents · grouped` trống; hàng tab `+`; pane chính là shell trống với prompt `~/inception $`. | Một buổi sáng, mở herdr. |
| 1.5 | Gõ theo nhịp người: `claude --dangerously-skip-permissions --agent thomas --model claude-opus-5 --effort medium` rồi Enter. | |
| 5.0 | Màn hình chào Claude Code hiện trong pane; tab đổi tên `thomas`; sidebar `agents` thêm `thomas` với `working · claude`, chấm vàng. Status line: `~/inception · main · bypass permissions`. | Thomas là người đại diện của team. Bạn chỉ nói chuyện với Thomas. |

### Cảnh 2 · Chào hỏi, Thomas đọc board và chọn việc (9–27 s)

| t | Hình | Card |
|---|---|---|
| 9.0 | Ô nhập `>`: bạn gõ `Hello Thomas, dự án thế nào rồi? Tiếp tục triển khai nhé.` Enter. | |
| 12.0 | `⏺ Bash(linear issue list --project Inception --state "In Progress,Todo,Backlog")` · `⎿ 7 issues` | Thomas lên tracker trước khi trả lời. |
| 13.5 | Cắt sang board Linear: ảnh thật hiện toàn cảnh 1 giây, rồi camera zoom vào cột Backlog và Todo (vùng TRA-200, TRA-54), dừng 2 giây, viền sáng nhẹ quanh thẻ TRA-200. | Board là nguồn sự thật. Thomas đọc nó thay bạn. |
| 18.0 | Quay về pane `thomas`. `⏺` Thomas: `Tiến độ: 50 done, TRA-196 (bug APPTWEAK_FANOUT_MAX) đang In Progress, để Builder chạy tiếp. Todo chỉ có TRA-54 nhưng đang needs-info, chưa làm được. Backlog có 3 ticket needs-info nữa, tôi gom câu hỏi gửi bạn sau. TRA-200 là ticket duy nhất ready-for-agent và không bị chặn, nó mở đường cho TRA-179. Tôi dispatch TRA-200.` | Thomas không lấy ticket đầu hàng. Thomas đọc trạng thái, loại việc bị chặn, chọn việc mở đường. |
| 24.0 | Ô nhập: bạn gõ `ok`. Enter. | Bạn giữ quyền quyết định; một chữ là đủ. |

### Cảnh 3 · Thomas điều phối team (27–45 s)

| t | Hình | Card |
|---|---|---|
| 27.0 | Pane `thomas`: `⏺ Bash(linear issue update TRA-200 --state "In Progress" --assignee builder)` · `⎿ updated`; `⏺ Bash(git worktree add ../wt/TRA-200 -b feat/TRA-200 main)` · `⎿ Preparing worktree`; `⏺ Bash(herdr agent start builder-tra-200 -- claude --agent builder --model claude-sonnet-5 --effort medium)` · `⎿ started`. | Claim trên board, mở worktree, mở session Builder. |
| 30.0 | Sidebar `agents` thêm `builder-tra-200` `working · claude` (vàng) ngay dưới `thomas`; tab `builder-tra-200` xuất hiện. Pane chính chia đôi: trái `thomas`, phải `builder-tra-200`. | Mỗi agent một session, có tên, có trạng thái. |
| 31.5 | Pane phải nhận `› Message from @thomas: Ticket TRA-200: app-id validation mới chỉ phủ featured surface, mở rộng cho mọi surface trong payload… (ctrl+o to expand)`. Vệt sáng trái sang phải. Pane trái: `⏺ Monitor(scripts/herdr-watch-terminal.sh builder-tra-200)` · `⎿ watching`. | Brief đi thẳng vào session của Builder. |
| 34.0 | Pane phải, Builder làm việc nhanh: `⏺ Read(src/ingest/validation/app_id.py)`, `⏺ Edit(src/ingest/validation/app_id.py)`, `⏺ Bash(pytest tests/ingest/test_app_id.py)` · `⎿ 14 passed`. | |
| 37.0 | Pane phải, `⏺` Builder: `Surface "search" không có app-id trong payload cũ, bỏ qua hay coi là lỗi?` rồi `TERMINAL:blocked`; chấm `builder-tra-200` đổi đỏ `blocked · claude`. Vệt sáng phải sang trái. | Builder kẹt, herdr báo, Thomas thấy ngay. |
| 39.0 | Pane trái: `⎿ TERMINAL:blocked pane=builder-tra-200` · `⏺ Bash(herdr agent read builder-tra-200)` · `⏺` Thomas: `Câu hỏi kỹ thuật, có trong spec TRA-179: payload cũ thiếu app-id thì bỏ qua và ghi warning. Trả lời Builder, không cần làm phiền bạn.` | Câu hỏi kỹ thuật, Thomas tự trả lời. Chỉ quyết định sản phẩm mới lên bạn. |
| 41.5 | Pane phải nhận `› Message from @thomas: Payload cũ thiếu app-id thì bỏ qua và ghi warning, theo spec TRA-179. Tiếp tục. (ctrl+o to expand)`; chấm về vàng `working`; Builder: `⏺ Edit(src/ingest/validation/app_id.py)`, `⏺ Bash(pytest tests/ingest/test_app_id.py)` · `⎿ 17 passed`, `⏺ Bash(git push)`, rồi `TERMINAL:done`; chấm xanh `done · claude`. | |

### Cảnh 4 · Kết quả về tay bạn (45–55 s)

| t | Hình | Card |
|---|---|---|
| 45.0 | Pane chính gộp lại một pane `thomas`. `⎿ TERMINAL:done pane=builder-tra-200` · `⏺ Bash(scripts/check-simplify-markers.sh main feat/TRA-200)` · `⎿ exit 0` · `⏺ Bash(linear issue update TRA-200 --state Done)` · `⎿ updated`. | Thomas kiểm receipt trước khi báo cáo. |
| 48.0 | `⏺` Thomas gửi bạn: `TRA-200 xong: 3 commit, 17 test pass, receipt hợp lệ, đã chuyển Done. Builder hỏi một câu kỹ thuật, tôi trả lời theo spec TRA-179. Còn 4 ticket needs-info (TRA-54, TRA-182, TRA-183, TRA-141), tôi đã gom câu hỏi, bạn xem lúc rảnh. TRA-196 vẫn đang chạy.` | Bạn nhận báo cáo, không nhận log. |
| 52.0 | Cắt nhanh sang board: thẻ TRA-200 nằm ở cột Done (ảnh thật với thẻ được dựng chồng lên cột Done, 1,5 giây). | Mọi việc để lại dấu vết trên board. |
| 54.0 | Toàn cảnh herdr: `thomas` working, `builder-tra-200` done. Giữ 1 giây rồi lặp. | |

## Điều người xem phải nhận ra

1. Bắt đầu một ngày chỉ là mở herdr và gọi Thomas bằng một lệnh.
2. Bạn nói chuyện tự nhiên; Thomas lên board đọc trước rồi mới trả lời.
3. Thomas suy luận để chọn việc: loại ticket bị chặn, chọn ticket mở đường, giải thích vì sao.
4. Thomas mở session Builder, gửi brief, trả lời câu kỹ thuật, chờ đúng tín hiệu.
5. Bạn nhận một báo cáo ngắn và board đã cập nhật.

## Đã chốt với chủ site (2026-09-10)

- Dùng board Linear thật. Space đặt theo tên dự án được cài, không phải `astragentic`.
- Thomas phải suy luận rồi chọn ticket, không lấy ticket đầu hàng.
- Độ dài không quan trọng, truyền tải được là chính. Vị trí dưới hai nút hero.
