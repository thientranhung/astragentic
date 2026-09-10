# Kịch bản video hero "Một ngày làm việc với Thomas" (2026-09-10, bản nháp cho chủ site duyệt)

Vị trí: trang chủ, hero, ngay dưới hai nút CTA, cùng khung Shot có badge "mô phỏng" như hai
video kia. Dựng bằng HyperFrames, 16:9, không tiếng, lặp, khoảng 70 giây. Độ dài không phải
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

## Bốn cảnh, khoảng 70 giây (bản 2, 2026-09-11: ba ticket song song)

Card chữ ngắn giữa vùng chính, mỗi cảnh một câu, như video herdr.

Status line của mỗi pane Builder theo mẫu thật chủ site gửi 2026-09-11 (ba dòng, không cần
giống y, phải có model, runtime, branch git, thư mục worktree):

```
[Sonnet 5·medium] 📁 tra-200 | 🌿 builder/TRA-200 | 🌳 tra-200
ctx 12% | ↑41k ↓3k tok | $1.20 | ⏱ 4m 10s
▶▶ bypass permissions on · 1 shell · ← for agents
```

Pane Thomas giữ status line như bản 1 (`~/inception · main · bypass permissions`), thêm dòng
`[Opus 5·medium] 📁 inception | 🌿 main`.

### Cảnh 1 · Mở herdr, gọi Thomas (0–9 s)

| t | Hình | Card |
|---|---|---|
| 0.0 | Cửa sổ herdr tối: `spaces` có `inception · main` (chọn) và `shop-demo · main`; `agents · grouped` trống; hàng tab `+`; pane chính là shell trống với prompt `~/inception $`. | Một buổi sáng, mở herdr. |
| 1.5 | Gõ theo nhịp người: `claude --dangerously-skip-permissions --agent thomas --model claude-opus-5 --effort medium` rồi Enter. | |
| 5.0 | Màn hình chào Claude Code hiện trong pane; tab đổi tên `thomas`; sidebar `agents` thêm `thomas` với `working · claude`, chấm vàng. | Thomas là người đại diện của team. Bạn chỉ nói chuyện với Thomas. |

### Cảnh 2 · Chào hỏi, Thomas đọc board và tìm ra ba ticket (9–30 s)

| t | Hình | Card |
|---|---|---|
| 9.0 | Ô nhập `>`: bạn gõ `Hello Thomas, dự án thế nào rồi? Tiếp tục triển khai nhé.` Enter. | |
| 12.0 | `⏺ Bash(linear issue list --project Inception --state "In Progress,Todo,Backlog")` · `⎿ 7 issues` | Thomas lên tracker trước khi trả lời. |
| 13.5 | Cắt sang board Linear: toàn cảnh 1 giây, rồi zoom vào ba cột Backlog, Todo, In Progress; viền sáng lần lượt quanh TRA-196 (In Progress), TRA-200 và TRA-204 (Backlog), mỗi thẻ sáng cách nhau 0,7 giây, giữ 2,5 giây. | Board là nguồn sự thật. Thomas đọc nó thay bạn. |
| 19.5 | Quay về pane `thomas`. `⏺ Bash(linear issue view TRA-196 TRA-200 TRA-204 --fields write-set)` · `⎿ TRA-196 src/jobs/fanout/* · TRA-200 src/ingest/validation/* · TRA-204 src/rank/movers/*` | |
| 21.0 | `⏺` Thomas: `Tiến độ: 50 done. Bốn ticket đang needs-info (TRA-54, TRA-182, TRA-183, TRA-141), tôi gom câu hỏi gửi bạn sau. Ba ticket làm được ngay: TRA-196 bug fan-out đang In Progress nhưng chưa có session nào chạy, TRA-200 ready-for-agent và mở đường cho TRA-179, TRA-204 không bị chặn. Write-set của ba ticket nằm ở ba module khác nhau, không giao nhau, nên tôi mở ba Builder chạy song song, mỗi Builder một worktree.` | Thomas không lấy ticket đầu hàng. Thomas đọc trạng thái, loại việc bị chặn, tìm ra ba việc chạy được cùng lúc. |
| 28.0 | Ô nhập: bạn gõ `ok`. Enter. | Bạn giữ quyền quyết định; một chữ là đủ. |

### Cảnh 3 · Thomas dispatch ba ticket và điều hành (30–58 s)

| t | Hình | Card |
|---|---|---|
| 30.0 | Pane `thomas`, ba cụm lệnh chạy liền, mỗi cụm cách 1 giây: `⏺ Bash(linear issue update TRA-196 --state "In Progress" --assignee builder)` · `⏺ Bash(git worktree add ../wt/TRA-196 -b builder/TRA-196 main)` · `⏺ Bash(herdr agent start builder-tra-196 -- claude --agent builder --model claude-sonnet-5 --effort medium)` · `⎿ started`; rồi tương tự cho TRA-200 và TRA-204. | Ba lần claim, ba worktree, ba session Builder. |
| 31.0 → 33.0 | Sidebar `agents` thêm lần lượt `builder-tra-196`, `builder-tra-200`, `builder-tra-204`, đều `working · claude` chấm vàng; ba tab mới. | |
| 34.0 | Pane chính chia bốn: trái `thomas` (cột rộng), phải ba pane xếp dọc `builder-tra-196`, `builder-tra-200`, `builder-tra-204`. Mỗi pane Builder có status line ba dòng theo mẫu, khác nhau ở branch và thư mục. Mỗi pane nhận `› Message from @thomas: Ticket TRA-xxx: … (ctrl+o to expand)` cách nhau 0,6 giây, vệt sáng từ trái sang từng pane. Pane trái: `⏺ Monitor(scripts/herdr-watch-terminal.sh builder-tra-196 builder-tra-200 builder-tra-204)` · `⎿ watching 3 panes`. | Mỗi Builder một session, một worktree, một brief. |
| 37.0 | Ba pane Builder chạy lệch nhịp: `⏺ Read(...)`, `⏺ Edit(...)`, `⏺ Bash(pytest …)` với đường dẫn theo write-set của từng ticket (`src/jobs/fanout/sweep.py`, `src/ingest/validation/app_id.py`, `src/rank/movers/window.py`). | |
| 41.0 | Pane `builder-tra-200`, `⏺` Builder: `Surface "search" không có app-id trong payload cũ, bỏ qua hay coi là lỗi?` rồi `TERMINAL:blocked`; chấm đổi đỏ. Vệt sáng về trái. | Một Builder kẹt, herdr báo, Thomas thấy ngay. |
| 43.0 | Pane trái: `⎿ TERMINAL:blocked pane=builder-tra-200` · `⏺ Bash(herdr agent read builder-tra-200)` · `⏺` Thomas: `Câu hỏi kỹ thuật, có trong spec TRA-179: payload cũ thiếu app-id thì bỏ qua và ghi warning. Trả lời Builder, không cần làm phiền bạn.` | Câu hỏi kỹ thuật, Thomas tự trả lời. Chỉ quyết định sản phẩm mới lên bạn. |
| 45.5 | Pane `builder-tra-200` nhận `› Message from @thomas: Payload cũ thiếu app-id thì bỏ qua và ghi warning, theo spec TRA-179. Tiếp tục. (ctrl+o to expand)`; chấm về vàng; chạy tiếp. | |
| 47.0 | Pane `builder-tra-196` xong trước: `⏺ Bash(pytest tests/jobs/test_fanout.py)` · `⎿ 9 passed` · `⏺ Bash(git push)` · `TERMINAL:done`; chấm xanh `done · claude`. | |
| 48.5 | Pane trái, trong khi hai Builder kia vẫn chạy: `⎿ TERMINAL:done pane=builder-tra-196` · `⏺ Bash(scripts/check-simplify-markers.sh main builder/TRA-196)` · `⎿ exit 0` · `⏺ Bash(linear issue update TRA-196 --state Done)` · `⎿ updated`. | Xong cái nào, Thomas kiểm receipt và đóng cái đó. Không chờ cả ba. |
| 52.0 | Pane `builder-tra-200`: `⎿ 17 passed` · `git push` · `TERMINAL:done`, chấm xanh. Pane `builder-tra-204` vẫn `working`, đang `⏺ Edit(src/rank/movers/window.py)`. | |
| 54.0 | Pane trái: `⎿ TERMINAL:done pane=builder-tra-200` · `check-simplify-markers … exit 0` · `linear issue update TRA-200 --state Done` · `⎿ updated`. | |

### Cảnh 4 · Báo cáo về tay bạn (58–70 s)

| t | Hình | Card |
|---|---|---|
| 58.0 | Pane chính gộp lại một pane `thomas`. `⏺` Thomas gửi bạn: `Sáng nay: TRA-196 và TRA-200 xong, receipt hợp lệ, đã chuyển Done. TRA-204 đang chạy, tôi sẽ báo khi xong. Builder TRA-200 hỏi một câu kỹ thuật, tôi trả lời theo spec TRA-179. Bốn ticket needs-info tôi đã gom câu hỏi, bạn xem lúc rảnh.` | Bạn nhận báo cáo, không nhận log. |
| 63.0 | Cắt sang board: hai thẻ TRA-196 và TRA-200 dựng chồng lên cột Done với dấu xanh, TRA-204 ở cột In Progress với chấm vàng, 2 giây. | Mọi việc để lại dấu vết trên board. |
| 66.0 | Toàn cảnh herdr: `thomas` working, hai Builder done, một Builder working. Giữ 1,5 giây rồi lặp. | |

## Điều người xem phải nhận ra

1. Bắt đầu một ngày chỉ là mở herdr và gọi Thomas bằng một lệnh.
2. Bạn nói chuyện tự nhiên; Thomas lên board đọc trước rồi mới trả lời.
3. Thomas suy luận để tìm việc: loại ticket bị chặn, tìm ra ba ticket không giao nhau, chạy song song.
4. Ba Builder, ba worktree, ba status line; Thomas trả lời câu kỹ thuật, đóng từng ticket khi xong.
5. Bạn nhận một báo cáo ngắn và board đã cập nhật.

## Đã chốt với chủ site (2026-09-10, cập nhật 2026-09-11)

- Dùng board Linear thật. Space đặt theo tên dự án được cài, không phải `astragentic`.
- Thomas phải suy luận rồi chọn ticket, không lấy ticket đầu hàng.
- Bản 2: ba ticket song song để gây ấn tượng về khả năng điều hành; status line Builder có
  model, runtime, git branch, thư mục worktree theo ảnh mẫu.
- Độ dài không quan trọng, truyền tải được là chính. Vị trí dưới hai nút hero.
