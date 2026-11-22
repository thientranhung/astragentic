---
title: dispatch-ticket
oneLiner: "Giao một ticket đã claim cho một Builder trong pane nhìn thấy được, trên Herdr hoặc Orca, với worktree và branch riêng."
group: main-flow
order: 10
runtimes: [claude]
source: harness/.claude/skills/dispatch-ticket/SKILL.md
rented: false
diagram: ticket-lifecycle
lang: vi
updated: 2026-11-22
harness: v6.1.19
---

## Nó làm gì

**`dispatch-ticket` là giao thức chung để Thomas đưa một ticket từ "đã claim" sang "có Builder đang làm".** Mỗi ticket có đúng một Builder, một worktree, một branch và một pane. Launcher, mod và bước kiểm trước dispatch nằm ở `dispatch-ticket-claude`; đọc cả hai skill.

Tám bước, theo thứ tự cố định:

- **Preflight** ở lần dispatch đầu của session: watchdog chạy, payload đã commit.
- **Resolve dòng role** trong `orchestrator.md`: runtime, model, effort; thu write-set.
- **Claim, rồi mới tạo branch và worktree.**
- **Resolve workspace**, tạo tab và pane, qua cwd gate.
- **In bản dispatch đã resolve**, launch, đọc record ngược lại.
- **Gửi brief**: dòng đầu là slash command của pha.
- **Rẽ nhánh theo turn end**: `TURN-END` với pane có mod, exit của watcher với pane gate hoặc junior.
- **Verify bằng artifact**, rồi cleanup.

Chuỗi nhận danh tính là `ticket → assignee (claim) → pane → worktree → branch → PR`, mỗi mắt xích một-một. Claim có trước worktree, nên hai session Thomas không cùng nhặt một ticket.

**Số đo.** Một ticket nhỏ (≤ 20 dòng không phải test) đi qua Builder pane tốn trung vị 114 lượt gọi model và 8 phút pane; 5 ticket như vậy đã merge giữa 2026-10-27 và 11-12. Con số này là lý do Quick Builder tồn tại.

**Cái giá.** Mỗi dispatch cần payload đã commit, workspace, tab, pane và record. Việc quá nhỏ không đáng chi phí này đi sang Quick Builder (mục dưới).
<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## Host: Herdr hoặc Orca, một host cho một session

**Biến `ORCA_PANE_KEY` có nghĩa là Orca; ngược lại `HERDR_ENV=1` là Herdr.** Pane, watching và cleanup lấy dạng Orca từ `ORCA.md`, và không lệnh `herdr` nào chạy trong session Orca. Từ 6.1.0, mod từ chối lệnh `herdr` trong session Orca và lệnh `orca` trong session Herdr.

| Tình huống | Quy tắc |
|---|---|
| Session khởi động trong Herdr | Chỉ dùng `herdr`; tab `ticket:<id>`, pane `builder:<id>` |
| Session khởi động trong Orca | Chỉ dùng `orca`; xử lý handle theo `ORCA.md` |
| Lệnh của host kia | Mod từ chối |

<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md; harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## Khi nào Thomas gọi nó

| Tình huống trước mặt bạn | Gọi cái nào |
|---|---|
| Một ticket trên frontier, assignee còn trống | `dispatch-ticket` (claim trước, worktree sau) |
| Cú dispatch sau khi đã claim | `dispatch-ticket` cộng `dispatch-ticket-claude` |
| Cần pane cho Shaper hoặc QA | Cùng skill; chỉ khác tiền tố tab (`spec:`, `qa:`) |
| Việc nhỏ owner phán bằng mắt | Quick Builder pane, không ticket |
| Pane đứng im hoặc kẹt giữa lượt | `WATCHING.md` (tài liệu đi kèm) |
| Builder đã handback, tới lúc gỡ worktree | `CLEANUP.md` (tài liệu đi kèm) |

<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## Cần sẵn gì

- **Watchdog chạy** cho workspace, xác nhận ở lần dispatch đầu của session (`WATCHING.md`).
- **Payload đã commit**, không bị gitignore. Worktree chỉ chứa nội dung đã tracked; `PAYLOAD NOT VISIBLE` là dừng.
- **Dòng của role trong `orchestrator.md` có giá trị thật.** `<set-me>`, dòng thiếu hoặc mơ hồ là dừng; không bao giờ mượn model của role khác.
- **Base đã cập nhật**: `git rev-parse <base>` bằng `origin/<base>` trước khi tạo worktree.
- **Write-set** của ticket, và write-set của mọi ticket đang chạy khác, khi còn dispatch nào đang sống.
- **Với brief UI**: hai plug `design-spine` và `anti-slop-skills` trong `.astraler/project/` (5.1.0).

<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## Brief

**Dòng đầu của brief là slash command của pha**: `/astra-implement-with-tdd <ticket>` cho Builder, `/astra-grill-with-docs` hoặc `/astra-to-tickets <spec-id>` cho Shaper. Các skill flow có `disable-model-invocation: true`, nên chỉ văn bản đến như lượt user mới tới được chúng.

- **`FLOW:`** liệt kê các lệnh Skill theo thứ tự: skill anti-slop của project rồi `astra-ui` (ticket UI), `astra-review`, `simplify`, arm. TDD nằm bên trong `astra-implement-with-tdd`.
- **`quick` / `full`** là label của ticket trên tracker (4.6.0), không bao giờ là dòng trong brief. Mod đọc label lúc gửi và ghi `kind` vào record. Ticket quick chỉ chạy built-in `code-review` và không nợ marker.
- **`QA: walk|probe|verify|none`** và `QA plan: docs/qa/plan-<slug>.md`: mod từ chối brief thiếu plan.
- **Brief UI dán nguyên `## Glance`, `## States`, `## Criteria`** của ticket (5.0.0). Thiếu một mục, brief không được gửi.
- **Brief Shaper có dòng `UX:`** (5.0.9): `UX: docs/prd.md — UJ-1, UJ-2`, hoặc `UX: n/a — <lý do>`. PRD phải đã commit trên base.
- **`Owned elsewhere:`** biến xung đột merge thành ghi chú handback; **`ADDRESSED TO:`** là dòng thứ hai để fork không nhận nhầm vai.

**Số đo.** Trước khi có plug design, luật bằng văn xuôi đòi Builder đọc skill anti-slop chỉ chạy ở 1 trên 14 merge UI (2026-10-28 → 11-01).
<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## Quick Builder: việc không phải ticket

Thay đổi owner phán bằng cách nhìn kết quả (`thomas.md`: Not a ticket) đi tới Quick Builder pane: không issue, không claim, không record, không marker lúc merge. Pane tự tạo worktree `ops/<slug>` và fast-forward vào main; git guard giữ nó trong hình dạng đó. Model và effort lấy từ dòng `builder-quick`.

Thomas gửi lời owner trong một SendMessage; pane trả before/after. Việc cần test hoặc review thành ticket theo lời owner. Pane không phải lane: không có bell TURN-END và không có watchdog, nên pane im lặng thì đọc nó, không đợi.

**Cái giá.** Lời của Thomas là một lượt trên root checkout, nên base local phải bằng origin và không merge nào còn chưa push trước khi giao.
<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## Nó để lại gì

| Kết quả | Nơi nó nằm lại |
|---|---|
| Claim | assignee trên tracker, hoặc `identity` trong record khi assignee không giữ được `builder/<id>` |
| Bản dispatch | `.astraler/state/dispatch-record.json`, khoá theo ticket: branch, worktree, workspace, tab, pane, runtime, write-set, `kind` |
| Worktree và branch | `<repo-root>/.claude/worktrees/<branch-slug>`, gitignore, gỡ lúc cleanup |
| Pane đã chạy flow nào | `skills_run` trong record; `TURN-END` mang dòng `Skills run:` |
| Công việc của Builder | commit trên branch ticket, push trước handback |

Record là thứ cleanup dùng để đóng đúng tab theo `tab_id`; entry bị xoá sau khi worktree và branch đã mất.

<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## Lỗi đã biết

Lấy từ `harness/.agents/memory/recurring-failure-modes.md`; cả ba đều `promoted`.

- **AST-097.** `TERMINAL:done` chỉ nghĩa là lượt đã kết thúc, không phải việc đã xong. Từ đó `TURN-END` là bell, và verify luôn theo artifact.
- **AST-107.** `herdr agent wait` kéo dài có thể điếc và không bao giờ bắn. Pane có mod thay watcher bằng `TURN-END`.
- **AST-154.** Gửi lại brief sau `NO_START` nối vào composer chưa gửi và submit cả hai. Đọc composer trước, xoá bằng `esc esc`.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Mọi ticket đang mở có entry trong `dispatch-record.json`, kèm write-set.
- Tab và pane mang đúng tiền tố role (`ticket:`, `spec:`, `qa:`); tiền tố ngoài `TITLE_PREFIXES` của watchdog thì dispatch không được giám sát, không báo lỗi.
- Record đọc lại có `pane_id` bằng pane vừa tạo.
- Brief UI có đủ Glance, States, Criteria, và project đã khai hai plug.
- Cleanup chỉ gỡ worktree sau khi `git status --short` trống.

<!-- source: harness/.claude/skills/dispatch-ticket/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

Frontier query → claim → **`dispatch-ticket`** (+ `dispatch-ticket-claude`) → Builder chạy `astra-implement-with-tdd` → `astra-ui` → `astra-review` → simplify → arm (`codex-arm`) → handback → `dispatch-qa-walk` → merge → `CLEANUP.md`. Hợp đồng role nằm ở `thomas.md` và `builder.md`.
