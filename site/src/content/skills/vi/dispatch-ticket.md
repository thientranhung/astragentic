---
title: dispatch-ticket
oneLiner: "Giao một ticket đã sẵn sàng cho một Builder, trong worktree riêng của nó."
group: main-flow
order: 1
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/dispatch-ticket/SKILL.md
rented: false
diagram: ticket-lifecycle
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`dispatch-ticket` là chuỗi thao tác Thomas chạy mỗi lần một ticket đi từ "claim được" sang "đang
có Builder làm thật". Chín bước, luôn theo đúng thứ tự đó:

- **Preflight** ở lần dispatch đầu của session: watchdog đang chạy, payload đã commit.
- **Resolve dòng orchestrator**: runtime, model, effort, và write-set.
- **Claim ticket, rồi cắt branch và worktree**, theo đúng thứ tự đó.
- **Mở tab kèm pane** trong Herdr, gate trên `foreground_cwd`.
- **In ra bản dispatch đã resolve**, rồi launch bằng skill của runtime tương ứng.
- **Giao brief**, dòng đầu là slash command của pha đó.
- **Arm watcher ngay sau khi submit**: hai việc này là một, không phải hai.
- **Rẽ nhánh theo exit status của watcher**, không bao giờ theo mỗi pane status.
- **Nghiệm thu bằng artifact**, rồi cleanup.

Bước nào không ai kiểm là bước bị bỏ trong im lặng, và harness này chạy song song vài chuỗi như
vậy cùng lúc, nên im lặng ở đây nghĩa là một Builder ngồi không trong một pane không ai nhìn.
<!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->

Điểm khác của nó nằm ở chỗ đặt ranh giới: **claim xảy ra trước khi worktree tồn tại.** Ticket được
gán trên tracker trước, nên hai session Thomas cùng nhặt trên frontier sẽ thấy claim của nhau thay vì
đua nhau tạo cùng một branch. Vấn đề sinh ra luật này là hai session dùng chung một checkout và mất
commit trong im lặng vì một lệnh `git switch` chạy song song. Mỗi session một worktree là cách chữa,
và sự cô lập đó phủ mọi lệnh có ghi xuống đĩa, không riêng git.
<!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->

## Khi nào Thomas gọi nó

| Tình huống trước mặt bạn | Gọi cái nào |
|---|---|
| Một ticket trên frontier, ô assignee còn trống | `dispatch-ticket` (claim trước, worktree sau) |
| Chính cú dispatch, sau khi đã claim | `dispatch-ticket` cộng skill đi kèm theo runtime (`dispatch-ticket-claude`, `-codex`, `-opencode`) |
| Shaper, QA hay Rin cần pane chứ không chỉ Builder | Vẫn skill đó, vẫn cơ chế đó; chỉ khác tiền tố nhãn tab và pane |
| Một pane đứng im hoặc kẹt giữa lượt | `WATCHING.md` (tài liệu đi kèm, không phải skill riêng) |
| Builder đã handback, tới lúc gỡ worktree | `CLEANUP.md` (tài liệu đi kèm) |

<!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->

## Cần sẵn gì

- Watchdog của workspace đang chạy cho project này. Dispatch mà không có watchdog là dừng hẳn,
  không phải cảnh báo (`exit 1`, không phải `echo`).
  <!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->
- Payload harness đã được commit, không phải chỉ được allow-list qua mặt `.gitignore`. Worktree
  chỉ chứa nội dung đã tracked, nên một file `.agents/roles/builder.md` còn untracked nghĩa là
  Builder khởi động mà không có hợp đồng nào.
  <!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->
- `.agents/orchestrator.md` có một dòng thật (runtime, model, effort) cho role sắp dispatch. Một
  dòng ghi `<set-me>` nghĩa là chưa quyết, và chưa quyết là dừng ngay tại lúc dispatch.
  <!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->
- Đọc hợp đồng của role sắp dispatch trước (`builder.md` cho một Builder), vì skill này chỉ mang
  phần cơ chế, không nói role đó phải làm gì với cơ chế ấy.
  <!-- source: harness/.agents/roles/builder.md -->

## Nó để lại gì

| Kết quả | Nơi nó nằm lại |
|---|---|
| Cú claim | Ô assignee trên tracker: `builder/<ticket-id>` |
| Chính bản dispatch | `.astraler/state/dispatch-record.json`, khoá theo ticket id: branch, worktree, workspace, tab, pane, runtime, write-set |
| Worktree và branch | `<repo-root>/.claude/worktrees/<branch-slug>`, đã gitignore, gỡ lúc cleanup |
| Bản brief | Gửi đi ở dòng đầu như một slash command, có tiền tố plugin (`/mattpocock-skills:implement <ticket>`) |
| Phần việc của chính Builder | Commit trên branch của ticket, push trước khi handback |

<!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md -->

## Lỗi đã biết

Lấy từ `harness/.agents/memory/recurring-failure-modes.md`. Mọi mục dưới đây đều đang ở trạng
thái `promoted`: đã sửa và đã nằm trong hợp đồng mà trang này mô tả.

- **AST-016 / AST-027**: hai session root dùng chung một checkout, mất commit trong im lặng vì
  một `git switch` chạy song song. Đã sửa: mỗi session một worktree, không ngoại lệ.
- **AST-036**: harness được allow-list nhưng chưa commit thì vô hình bên trong mọi worktree của
  Builder. Đã sửa: kiểm tra commit trước cú dispatch đầu tiên.
- **AST-032 / AST-037**: một brief nhiều dòng dán vào composer mà không submit, và pane báo
  `idle` trong lúc nó nằm đó chưa gửi. Đã sửa: bấm Enter tường minh sau khi dán, cộng thêm bắt
  watcher phải thấy trạng thái `working` rồi mới tin là lượt đã bắt đầu.
- **AST-097**: `TERMINAL:done` nghĩa là lượt đã kết thúc, không phải việc đã xong; một Builder
  đang đỗ ở background đọc ra thành done. Đã sửa: kiểm tiến trình OS và dòng status của runtime
  trước khi kết luận là xong.
- **AST-124**: watcher theo lượt chỉ phủ một lượt rồi thoát; không có gì arm lại, và cú arm lại
  chính là bước hay bị bỏ ngay sau một tác vụ dài. Đã sửa: mỗi lượt mới có watcher mới.
- **AST-092**: một Builder dừng trước khi commit để lại phần việc chỉ tồn tại trên đĩa;
  `git worktree remove` xoá nó không nói gì. Đã sửa: "commit, push, rồi mới trả về" là ba hành
  động tách bạch.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Watchdog được xác nhận đang chạy trước cú dispatch đầu tiên của session, không phải mặc định là có.
- `.astraler/state/dispatch-record.json` có một entry cho mọi ticket đang mở, kèm write-set.
- Mọi brief đã gửi đều có watcher arm ngay trong cùng hành động đó, không phải một bước riêng
  làm sau.
- Nhãn tab và nhãn pane khớp với role đã dispatch (`builder:<id>` so với `spec:<id>`,
  `qa:<id>`, `rin:<id>`), vì tiền tố sai thì watchdog không nhìn thấy.
- Cleanup chỉ gỡ worktree sau khi `git status --short` trống và `check-simplify-markers.sh` xanh.

<!-- source: harness/.agents/skills/dispatch-ticket/SKILL.md, CLEANUP.md -->

## Nó nằm ở đâu trong chuỗi

Câu truy vấn frontier (nằm trong `thomas.md`) quyết định ticket nào tới lượt → `dispatch-ticket`
claim nó và đặt một role `builder` vào pane → Builder chạy vòng khép kín của riêng nó
(`implement` → review → simplify → `/skills/codex-arm`) rồi handback → `CLEANUP.md` của
`dispatch-ticket` thu hồi worktree sau khi artifact đã được kiểm → cửa milestone đi qua
`/skills/review-with-rin` trước khi merge. `thomas` và `builder` là hai hợp đồng role mà skill
này nằm ở giữa.
