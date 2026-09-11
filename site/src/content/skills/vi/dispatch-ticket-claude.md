---
title: dispatch-ticket-claude
oneLiner: "Launch, giao brief và canh một pane Claude Code, theo đúng thứ tự không thể giả một lượt đã xong."
group: adapter
order: 1
runtimes: [claude]
source: harness/.agents/skills/dispatch-ticket-claude/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`dispatch-ticket-claude` là nửa Claude Code của `dispatch-ticket`. Skill dùng chung giữ phần định
danh, chốt input, luật worktree, khuôn brief, cách gửi, cách canh, simplify và dọn dẹp. Skill này
thêm bảng lệnh launch, bước kiểm trước khi dispatch, thứ tự gửi brief và những sự thật đã đo
được của runtime Claude. Nó là adapter, không phải một giao thức thứ hai. Hãy đọc `dispatch-ticket`
trước, vì mọi thứ không viết ở đây đều lấy từ đó.
<!-- source: harness/.agents/skills/dispatch-ticket-claude/SKILL.md -->

Xương sống của file là bốn hành động theo một thứ tự cố định: gửi phần thân brief bằng
`SendMessage`, gõ lệnh slash trần vào pane, xác nhận nó đã echo, rồi mới arm Monitor. Làm sai thứ
tự sẽ sinh ra một trạng thái kết thúc giả mà mọi lớp kiểm phía sau đều đọc thành khoẻ mạnh. Thứ tự
này đến từ hai lỗi riêng biệt rơi vào cùng bốn bước. Tin nhắn giữa hai session không phải một lượt
của người dùng, nên lệnh slash không bao giờ chạy (AST-112). Và một `SendMessage` chỉ có phần thân
vẫn tạo ra một lượt, nên watch arm quá sớm sẽ thấy *lượt đó* kết thúc rồi báo idle cho một Builder
chưa hề bắt đầu (AST-114). Giờ thứ tự được ghi ngay tại chỗ dùng, không để người đọc tự suy.
<!-- source: harness/.agents/skills/dispatch-ticket-claude/SKILL.md -->

## Khi nào Thomas gọi nó

| Tình huống trước mặt bạn | Gọi cái nào |
|---|---|
| Một ticket đã claim, và `orchestrator.md` ghi agent ở role này chạy trên Claude | `dispatch-ticket` + `dispatch-ticket-claude` |
| Cũng vậy, nhưng trên Codex hoặc OpenCode | `dispatch-ticket-codex` / `dispatch-ticket-opencode` |
| Builder hoặc Shaper, tức role có ghi | Launch kèm `--dangerously-skip-permissions` |
| Rin hoặc QA, tức role review | Launch không kèm; Rin không có dòng dự phòng nào |
| Monitor báo `blocked` | Đọc pane, trả lời bằng `SendMessage`, arm một Monitor **mới** |

<!-- source: harness/.agents/skills/dispatch-ticket-claude/SKILL.md -->

## Cần sẵn gì

- **Adapter của role có mặt trong worktree**: `test -f <worktree-path>/.claude/agents/<role>.md`.
  Thiếu nghĩa là payload chưa được commit hoặc đã bị gitignore, và đây đúng là file mà
  `claude --agent <role>` sẽ nạp.
- **Dòng `orchestrator.md` của role này đã chốt**, có model và, chỉ khi dòng đó đặt, có effort.
  Model và effort lấy từ dòng đó, không lấy từ trí nhớ.
- **Tên session của Builder tra được** bằng `ListAgents`, vì `SendMessage` gọi session theo tên.
- **Thứ đặt trong Monitor là `herdr-watch-terminal.sh`.** Monitor là kênh chuyển tin; script
  mới là cái canh.

## Nó để lại gì

| Kết quả | Nơi nó nằm lại |
|---|---|
| Phần thân brief | Session của Builder, gửi bằng `SendMessage` |
| Lệnh gọi phase | Một lượt người dùng thật trong pane: một lệnh slash có tiền tố plugin, kèm Enter |
| Bằng chứng nó đã tới | Lệnh echo trong pane, đọc lại trước khi làm bất cứ việc gì khác |
| Cái canh | Mỗi pane một Monitor, `description: "builder-<ticket-id> status"`, `timeout_ms` và `persistent` đều ghi tường minh |
| Dòng phán quyết | `TERMINAL:done` / `blocked` / `idle`, `TIMEOUT`, hoặc `NO_START`, mỗi dòng đều nêu pane của nó |

<!-- source: harness/.agents/skills/dispatch-ticket-claude/SKILL.md -->

## Lỗi đã biết

Lấy từ `harness/.agents/memory/recurring-failure-modes.md`. Tất cả đều `promoted`.

- **AST-112**: skill từng bảo Thomas gửi cả brief, kèm luôn lệnh slash, bằng một `SendMessage`,
  với lý do rằng nó tới nơi như một lượt người dùng. Câu đó sai, và nó tồn tại qua bốn bản phát
  hành. Đã sửa: phần thân đi bằng `SendMessage`, lệnh thì gõ.
- **AST-055**: cùng một lỗi trong cùng một vòng cho ra một cú từ chối ồn ào ở pane Builder và
  một cú thay thế im lặng ở pane Shaper, vì một hợp đồng có câu "chính cú fail là phát hiện" còn
  hợp đồng song song thì không. Giờ cả hai đều có, và đó là lý do bước kiểm echo là bằng chứng
  dương chứ không phải phép lịch sự.
- **AST-114**: tách bước gửi thành hai bước làm cái watch arm nhầm vào bước còn lại. Đã sửa: arm
  sau khi echo, không bao giờ arm sau phần thân.
- **AST-107**: một `herdr agent wait` trần đặt trong Monitor vẫn chạy nhưng không phản hồi. Đo được nó
  ngồi 10 phút 25 giây trước một pane vốn đã idle, trong khi một lệnh wait y hệt phát ra cùng
  phút đó trả về sau 0 giây. Đã sửa: Monitor bọc script canh, script cắt lệnh wait thành lát và
  lấy mọi phán quyết từ một `herdr agent get` mới.
- **AST-108**: một Monitor không đặt `timeout_ms` cắt một ca canh dài một tiếng xuống năm phút,
  nên ticket càng lớn thì khả năng cái watch đã biến mất càng cao. Đã sửa: cả hai trường đều
  tường minh trong mọi template, và thông báo `Monitor timed out` nghĩa là arm lại, không phải
  nhiễu.
- **AST-097**: `TERMINAL:done` nghĩa là lượt đó đã kết thúc, không phải công việc đã xong.
- **AST-036**: một worktree chỉ mang nội dung đã tracked, đúng thứ mà bước kiểm adapter ở trên
  sinh ra để bắt.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Bốn hành động diễn ra đúng thứ tự, và echo được đọc trước khi arm Monitor.
- Ba Builder đang chạy nghĩa là ba Monitor, mỗi pane một cái, mỗi cái một description riêng.
- Agent ở role review launch không kèm `--dangerously-skip-permissions`, agent ở role ghi thì có kèm.
- Mọi thông báo đều được kiểm lại bằng `herdr agent get <pane-id>` trước khi ai đó hành động.
- Không tin bất kỳ `idle` nào cho tới khi bộ chặn khởi động đã thấy `working` trước. Ô soạn thảo
  Claude trống khớp luật idle, nên một brief chưa gửi đọc ra thành một Builder xong tức thì.

<!-- source: harness/.agents/skills/dispatch-ticket-claude/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

`dispatch-ticket` claim ticket rồi dựng worktree, tab và pane → `dispatch-ticket-claude` khởi
chạy runtime, giao brief và arm cái watch → Builder chạy vòng khép kín của nó rồi handback →
`WATCHING.md` và `CLEANUP.md` của skill dùng chung quyết định chuyện gì xảy ra ở mỗi dòng phán
quyết. Hai skill song song với nó là `dispatch-ticket-codex` và `dispatch-ticket-opencode`; cả ba
đều là adapter dưới một giao thức.
