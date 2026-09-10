# Kịch bản video "Dispatch một ticket" (2026-09-10, bản nháp cho chủ site duyệt)

Vị trí: trang chủ, mục Comms, thay placeholder "ẢNH THẬT · SẼ CẬP NHẬT" dưới đoạn
"Dispatch một ticket là mở một cuộc trao đổi có địa chỉ." Dựng bằng HyperFrames, render
mp4/webm lặp, không tiếng, 16:9, khoảng 35 giây. Mọi dòng tool và lệnh lấy từ
`harness/.agents/skills/dispatch-ticket{,-claude}/SKILL.md` và `roles/builder.md`; chỉ lời
chat là viết mới, và là chỗ chủ site sửa.

## Bố cục

Hai pane terminal nền tối cạnh nhau, tiêu đề pane kiểu herdr:

- Trái: `thomas` · Claude Code · session `thomas`
- Phải: `builder-TRA-142` · Claude Code · worktree `../wt/TRA-142`

Thông điệp đi từ pane trái sang phải (và ngược lại) được vẽ bằng một vệt sáng ngắn nối hai
pane, cùng ngôn ngữ chuyển động với sơ đồ trên site. Chữ gõ theo nhịp người thật; kết quả tool
hiện gần như tức thì.

## Timeline

| t (s) | Pane | Nội dung |
|---|---|---|
| 0.0 | trái | Ô nhập `>` nhấp nháy. Bạn gõ: `TRA-142 sẵn sàng rồi, dispatch đi. Builder không được đụng module thanh toán, có gì hỏi lại.` |
| 2.5 | trái | `⏺` Thomas: `Claim TRA-142 trên tracker trước, rồi tạo branch và worktree.` |
| 3.5 | trái | `⏺ Bash(gh issue edit 142 --add-assignee builder)` · `⎿ assigned` |
| 4.3 | trái | `⏺ Bash(git worktree add ../wt/TRA-142 -b feat/TRA-142 main)` · `⎿ Preparing worktree` |
| 5.2 | trái | `⏺ Bash(herdr pane create --workspace astragentic --tab TRA-142)` · `⎿ pane 7a3f` |
| 6.0 | phải | Pane bên phải sáng lên, tiêu đề `builder-TRA-142`, dòng launch: `claude --agent builder --model claude-sonnet-5 --effort medium` rồi màn hình chào của Claude Code. |
| 7.5 | trái | `⏺ SendMessage(to: "builder-TRA-142")` · `⎿ Ticket TRA-142: màn hình Lịch sử đơn hàng thêm pull-to-refresh và empty state. Acceptance: kéo xuống gọi lại API orders, danh sách rỗng hiện EmptyState, flutter test pass. Không đụng module thanh toán. Write-set: lib/features/orders/*.` |
| 8.0 | → | Vệt sáng chạy từ pane trái sang phải. |
| 8.4 | phải | Hộp `<cross-session-message from="thomas">` hiện đúng nội dung brief. |
| 9.0 | trái | `⏺ Bash(herdr pane run 7a3f '/mattpocock-skills:implement TRA-142')` · `⎿ echoed` |
| 9.6 | phải | Ô nhập gõ `/mattpocock-skills:implement TRA-142` và Enter. |
| 10.2 | trái | `⏺ Monitor(scripts/herdr-watch-terminal.sh 7a3f 3 3600 120)` · `⎿ watching builder-TRA-142` |
| 10.5 | trái | Dòng trạng thái: `builder-TRA-142 · working` |
| 11.0 | phải | Builder làm việc: `⏺ Read(lib/features/orders/orders_screen.dart)`, `⏺ Edit(lib/features/orders/orders_screen.dart)`, `⏺ Bash(flutter test test/features/orders)` · `⎿ 9 passed`. Dòng chạy nhanh, cắt gọn. |
| 14.0 | phải | `⏺` Builder: `Empty state dùng widget EmptyState chung của design system hay vẽ riêng có illustration? Ticket không nói.` rồi `TERMINAL:blocked` |
| 14.8 | ← | Vệt sáng chạy từ phải sang trái. |
| 15.0 | trái | `⎿ TERMINAL:blocked pane=7a3f` · `⏺ Bash(herdr agent read 7a3f)` · `⎿ Empty state dùng widget EmptyState chung hay vẽ riêng?` |
| 16.0 | trái | `⏺` Thomas: `Câu hỏi kỹ thuật, trả lời từ contract UI: mọi màn hình danh sách dùng EmptyState chung, không thêm asset mới.` |
| 16.8 | trái | `⏺ SendMessage(to: "builder-TRA-142")` · `⎿ Dùng EmptyState chung theo contract UI, không thêm asset. Tiếp tục.` |
| 17.2 | → | Vệt sáng trái sang phải. |
| 17.5 | phải | `<cross-session-message from="thomas">` hiện câu trả lời; Builder tiếp tục: `⏺ Edit(lib/features/orders/orders_screen.dart)`, `⏺ Bash(flutter test test/features/orders)` · `⎿ 11 passed`. |
| 17.6 | trái | `⏺ Monitor(...)` · `⎿ watching builder-TRA-142` (Monitor mới) |
| 20.0 | phải | `⏺` Builder: `EmptyState có thêm nút "Mua sắm ngay" dẫn về Home không? Spec chỉ nói hiện thông báo rỗng.` rồi `TERMINAL:blocked` |
| 20.8 | ← | Vệt sáng phải sang trái. |
| 21.0 | trái | `⎿ TERMINAL:blocked pane=7a3f` · `⏺ Bash(herdr agent read 7a3f)` · `⎿ EmptyState có thêm nút "Mua sắm ngay" dẫn về Home không?` |
| 22.0 | trái | `⏺` Thomas: `Đây là quyết định UX, không có trong spec và contract. Đưa lên bạn.` |
| 22.8 | trái | `⏺ Skill(mattpocock-skills:to-questionnaire)` rồi hộp câu hỏi hiện trong pane Thomas: `TRA-142 · Empty state màn Lịch sử đơn hàng` · `A. Chỉ thông báo rỗng (theo spec)` · `B. Thêm nút "Mua sắm ngay" về Home` · `Chọn A/B:` |
| 25.0 | trái | Ô nhập `>` nhấp nháy, bạn gõ: `B` và Enter. |
| 26.0 | trái | `⏺` Thomas: `Ghi quyết định vào ticket, chuyển cho Builder.` · `⏺ Bash(gh issue comment 142 --body "Decision: B, thêm nút Mua sắm ngay về Home")` · `⏺ SendMessage(to: "builder-TRA-142")` · `⎿ Chủ dự án chọn B: thêm nút "Mua sắm ngay" điều hướng về Home. Tiếp tục.` |
| 27.0 | → | Vệt sáng trái sang phải. |
| 27.3 | phải | `<cross-session-message from="thomas">` hiện quyết định; Builder: `⏺ Edit(lib/features/orders/orders_screen.dart)`, `⏺ Bash(flutter test test/features/orders)` · `⎿ 12 passed`. |
| 27.4 | trái | `⏺ Monitor(...)` · `⎿ watching builder-TRA-142` |
| 30.0 | phải | `⏺ Bash(git commit --allow-empty -m "arm(ticket): TRA-142 — green, 1 pass")` · `⏺ Bash(git push)` · `⏺` Builder: `Handback TRA-142: 4 commit, 12 test pass, receipt đã commit. Chưa chạy trên máy thật, QA walk sẽ kiểm.` rồi `TERMINAL:done` |
| 31.0 | ← | Vệt sáng phải sang trái. |
| 31.3 | trái | `⎿ TERMINAL:done pane=7a3f` · `⏺ Bash(scripts/check-simplify-markers.sh main feat/TRA-142 --marker 'arm(ticket)')` · `⎿ exit 0` |
| 32.2 | trái | `⏺` Thomas gửi bạn: `TRA-142 xong: 4 commit, 12 test pass, receipt hợp lệ. Builder hỏi hai câu: empty state dùng widget chung, tôi trả lời theo contract UI; nút "Mua sắm ngay" là quyết định của bạn, đã ghi vào ticket. PR sẵn sàng; QA walk sẽ chạy trên simulator trước khi merge.` |
| 34.5 | | Giữ 1 giây rồi lặp. |

## Điều người xem phải nhận ra

1. Bạn chỉ nói một câu với Thomas; mọi thứ còn lại Thomas làm.
2. Thông điệp có địa chỉ: `to: "builder-TRA-142"`, và câu trả lời về đúng session gửi.
3. Câu hỏi kỹ thuật không lên tới bạn; Thomas trả lời từ contract rồi báo lại.
4. Quyết định UX thật thì Thomas quay về hỏi bạn, thu gọn thành A/B; bạn gõ một chữ.
5. Quyết định được ghi vào ticket trước khi chuyển cho Builder, nên đọc lại được.
6. Handback về Thomas kèm receipt, và Thomas kiểm marker trước khi báo bạn.

## Chỗ cần chủ site quyết

- Lời chat của bạn, của Thomas, của Builder: sửa thẳng trong bảng.
- Ticket TRA-142 đặt trong bối cảnh app mobile Flutter (màn hình Lịch sử đơn hàng); đổi sang React Native hay việc thật của Astraler nếu muốn.
- Có giữ dòng `herdr pane run` cho slash command không, hay ẩn đi cho gọn. Tôi đề nghị giữ, vì
  đó là chi tiết thật mà người đã dùng Claude Code sẽ nhận ra (SendMessage không gửi được
  slash command).
