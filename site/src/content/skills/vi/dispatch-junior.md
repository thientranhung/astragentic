---
title: dispatch-junior
oneLiner: "Giao phần gõ code của một ticket cho pane junior trên runtime khác, rồi nhận lại cây để review, simplify và arm."
group: main-flow
order: 4
runtimes: [claude]
source: harness/.agents/skills/dispatch-junior/SKILL.md
rented: false
lang: vi
updated: 2026-10-17
---

## Nó làm gì

`dispatch-junior` là recipe để Builder giao phần implement của một ticket cho một pane junior. Builder commit red test, mở một pane ngay cạnh mình trong cùng tab, launch junior trên runtime mà dòng Junior chỉ định (Grok trước), gửi một brief, chờ, rồi đọc lại cây.

Chỉ phần gõ code được chuyển đi. `tdd`, cả hai lượt review, simplify, arm, marker, handback và push vẫn là việc của Builder, chạy trên commit của junior y như trên commit của chính nó.

<!-- source: harness/.agents/skills/dispatch-junior/SKILL.md -->

## Khi nào Builder dùng nó

| Trước mặt bạn là | Dùng |
|---|---|
| Dòng `builder` trong `## Junior` của `orchestrator.md` có tên runtime, và red test đã commit | `dispatch-junior` |
| Dòng ghi `none`, hoặc không có dòng | Không dùng: Builder tự implement |
| Dòng chỉ một runtime nhưng worktree không có supplement `junior-<runtime>.md` | Dừng và báo Thomas |
| Thomas muốn có junior | Không được: Thomas không bao giờ dispatch junior, và junior không bao giờ báo cáo cho Thomas |

<!-- source: harness/.agents/skills/dispatch-junior/SKILL.md -->

## Hình dạng của một lần giao việc

1. **Một pane trong tab của Builder**, split sang phải, đặt tên `junior:<ticket-id>`. Cwd của nó là worktree của Builder: một worktree, hai người ghi nối tiếp nhau, không bao giờ cùng lúc.
2. **Một lệnh launch có cờ lấy từ dòng Junior.** Model và effort đọc từ dòng đó. Pane chạy với `--always-approve` vì không ai ngồi đó để trả lời prompt, và với một rule deny `git push` do chính runtime thực thi.
3. **Một brief, gửi theo tên.** Ticket, tiêu chí, red test cùng lệnh chạy chính xác, write-set, file chỉ đọc, và head trước đó. Brief thiếu lệnh test hoặc write-set thì không được gửi.
4. **Chờ bằng watcher script.** Builder không sửa worktree khi junior đang giữ nó. Junior kết thúc lượt bằng `JUNIOR-DONE` hoặc `JUNIOR-BLOCKED`, và Builder đọc pane để tìm dòng đó.
5. **Đọc lại trước khi tin.** Mọi commit phải có trailer `Implemented-by:`. Thay đổi ngoài write-set, red test bị sửa hay base branch bị chạm là vi phạm ranh giới: Builder lấy lại ticket và ghi chú.
6. **Đóng pane lúc handback.** Builder đóng pane mà nó đã mở, và báo cáo trả cho Thomas có đúng một dòng `Junior:`.

<!-- source: harness/.agents/skills/dispatch-junior/SKILL.md -->

## Nó để lại gì

| Chuyện gì xảy ra | Nằm ở đâu |
|---|---|
| Ai viết code | Trailer `Implemented-by: <runtime>/<model>` trên từng commit |
| Junior đã xong | Dòng cuối `JUNIOR-DONE <ticket> head=<sha> tests=<pass hoặc fail> changed=<n>` trong pane |
| Câu hỏi junior không tự quyết được | `JUNIOR-BLOCKED <ticket> <why>`, trả lời bằng brief tiếp theo |
| Có dùng junior | `Junior: <runtime>/<model> — <n> commits <first>..<last>` trong handback, hoặc `Junior: none` |

<!-- source: harness/.agents/skills/dispatch-junior/SKILL.md -->

## Cái gì không được thực thi cứng

Dispatch mod và các gate của nó đọc pane của Builder, không đọc pane của junior, và git guard của project đọc tên tool của Claude. Vì vậy ranh giới của junior là việc của chính nó, và cách Builder kiểm là đọc log: push, checkout base branch hay commit ngoài write-set đều hiện ra ở đó và kết thúc phiên.

<!-- source: harness/.agents/roles/junior-grok.md -->
