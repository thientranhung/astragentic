---
title: dispatch-ticket-claude
oneLiner: "Launcher Claude Code, hành vi của dispatch mod và bước kiểm trước dispatch cho một pane được giao việc."
group: adapter
order: 1
runtimes: [claude]
source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md
rented: false
lang: vi
updated: 2026-11-22
harness: v6.1.19
---

## Nó làm gì

**`dispatch-ticket-claude` là nửa Claude Code của `dispatch-ticket`: launcher và mod làm những bước mà dispatcher từng bỏ sót.** Giao thức chung (danh tính, luật worktree, định dạng brief, cleanup) ở `dispatch-ticket`. Mod `astragentic-dispatch` nằm trong payload, và mọi session Claude trong project tự nạp nó, không cần cờ hay setup.

Mod thay cho các bước thủ công sau:

- **Ghi tab và pane id** của pane vào record lúc session start, từ môi trường của host (nhãn tab Herdr, hoặc `ORCA_*` cộng `ASTRA_DISPATCH`, 6.1.0).
- **Giao slash command bằng một SendMessage**: pane chạy dòng đầu như lệnh thật; pane trả `RECEIVED`.
- **Báo `TURN-END`** khi một lượt kết thúc mà không còn agent con nào chạy, và đánh thức dispatcher.
- **Bảo vệ pane đang chạy**: lệnh đóng tab, pane hoặc terminal trên pane giữa lượt bị từ chối; lệnh của host kia bị từ chối hẳn (một host cho một session).
- **Chặn `ScheduleWakeup`** trong pane được dispatch (4.6.1).
- **Hiện band** gồm các chip bước: Builder implement · tdd · ui · review · simplify · arm; Shaper align · spec · arm:spec · test-design · tickets; QA chỉ chip role.

**Số đo.** Từ lúc một turn kết thúc tới lúc dispatcher được đánh thức: dưới một giây, so với khoảng trễ 67 giây của polling trạng thái pane (AST-097, AST-107).

**Cái giá.** Mod là chuông, không phải bằng chứng: `TURN-END` chỉ nói một lượt đã xong. Nó không thấy pane có process đã chết (watchdog của workspace thấy), và không phủ pane gate hay pane junior, vì hai loại này không chạy mod.
<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md; harness/.claude/skills/astragentic-dispatch/hooks/register.tsx -->

## Khi nào Thomas gọi nó

| Trước mặt bạn là | Dùng |
|---|---|
| Ticket đã claim, role chạy trên Claude | `dispatch-ticket` cộng `dispatch-ticket-claude` |
| Pane QA gate hoặc pane junior | Watcher script trong `dispatch-ticket`; pane junior thêm `dispatch-junior` |
| Role ghi (Builder, Shaper) | Launch với `--dangerously-skip-permissions --allowedTools Grep,Glob` |
| QA | Launch không có `--dangerously-skip-permissions`: gate chạy dưới permission |
| Ticket label `quick` | Dòng launcher `builder-quick` |

<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## Điều kiện cần có

- **Claude Code 2.1.294 trở lên.** `check-requirements.sh` từ chối bản cũ hơn; dưới ngưỡng này mod không nạp.
- **Nhãn tab đặt trước khi launch**: mod đọc `ticket:`, `spec:`, `qa:` từ tab lúc session start.
- **Mod đã commit trên branch** mà worktree checkout.
- **Hai file có trong worktree**: `.claude/agents/<role>.md` và `.claude/skills/astragentic-dispatch/hooks/register.tsx`.

Sau launch, đọc record ngược lại: `.astraler/state/dispatch-record.json` phải có key của ticket với `pane_id` bằng pane vừa tạo. Không có thì một điều kiện đã hỏng; dừng, vì pane mod không biết là pane không ai giám sát.
<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## Launcher theo role

Mỗi dòng là argv sau `--`; `herdr agent start --kind claude` tự cấp executable `claude`.

| Role | Cờ |
|---|---|
| builder, shaper | `--dangerously-skip-permissions --allowedTools Grep,Glob --agent <role> --model <Model> --autocompact 300000` |
| qa | `--agent qa --model <Model> --autocompact 300000` |
| builder, ticket `quick` | dòng `builder-quick` nếu `orchestrator.md` có, ngược lại dòng `builder` |

`--effort` và `--advisor` chỉ thêm khi dòng role đặt giá trị. Model và effort lấy từ `orchestrator.md`, không lấy từ trí nhớ.

- **`--allowedTools Grep,Glob` đi cùng `--dangerously-skip-permissions`.** Chỉ cờ bypass thì pane mất tool `Grep` và `Glob` (Claude Code 2.1.318, đo 2026-11-04).
- **`--autocompact 300000` là trần context, không tuỳ chọn.** Cửa sổ của engine là 1M và pane chạy cả flow trong một context. Một project có Builder chạy trung vị 400–550k token context mỗi lượt gọi. Mod cũng compact pane kết thúc lượt trên trần này (`ASTRAGENTIC_CONTEXT_CEILING` đổi nó).
- **Dán cả chữ `claude` vào đầu dòng** sẽ chạy `claude claude --agent …`; mod từ chối launch đó.

<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## Brief và những gì quay về

Brief đi bằng một `SendMessage` tới tên session lấy từ `ListAgents`; dòng đầu là slash command. Đừng arm Monitor, gõ vào pane hay ghi tab và pane id bằng tay: mỗi việc đó là bản sao thứ mod đã làm.

- **`RECEIVED`** bị tiêu thụ im lặng. Không thấy trong 90 giây thì dòng chuyển đỏ.
- **`TURN-END`** đến như một prompt kèm lời cuối của pane và `Skills run:`. Đọc dòng này trước khi tin handback.
- **Lượt kết thúc khi sub-agent của pane còn chạy thì bị giữ**; trần là 20 phút, sau đó chuông `reason=held-stale` và dòng chuyển đỏ.
- **`reason=command-failed`**: pane từ chối dòng đầu, thường do tên lệnh sai.
- **Pane QA luôn nhận TURN-END từ record** trong 30 giây, vì nó chạy dưới permission (đo 2026-10-27: 6 trên 6).
- **`/dispatch-board`** mở danh sách mọi dispatch đang sống.
- **`AskUserQuestion` bị từ chối** trong pane được dispatch.

<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## Các bước bị từ chối, không chỉ ghi chú

| Điều bị chặn | Cho tới khi |
|---|---|
| Commit nội dung đầu tiên của Builder | Có file test và một lần chạy test RED sau brief (4.5.2) |
| Arm (`codex-arm`) | Built-in `code-review` đã có trong record |
| Brief Builder không có `QA plan:` | Có `docs/qa/plan-<slug>.md` đã commit |
| Brief Shaper không có `UX:` | Có PRD đã commit trên base và heading `### UJ-n` cho từng id (5.0.9) |
| Brief cho ticket tracker báo chưa claim | Ticket được claim |
| Mọi brief, khi một merge chưa có stamp ticket-done | `scripts/ticket-done.sh <id>` chạy |
| Mọi brief, khi payload sửa mà chưa commit | Commit, hoặc dòng `Uncommitted-payload: <lý do>` |
| Lệnh Bash chờ theo tên process (`until ! pgrep -f …`) hoặc vòng không có sleep | Dùng `cmd & pid=$!; while kill -0 $pid …; wait $pid` |

Miễn trừ thuộc về dispatcher và đi trong brief: `TDD: n/a`, `REVIEW: n/a`, `SIMPLIFY: n/a`, `UX: n/a`, cùng lý do. Ticket label `quick` được miễn toàn bộ tdd, `astra-review`, simplify và ui; built-in review vẫn nợ ở arm và lúc merge. Mod đọc miễn trừ từ brief nó giao, không từ handback.

Project thêm luật từ chối qua `.astraler/project/refused-in-dispatched-panes`: một regex mỗi dòng, dòng `# reason:` ngay trên là lời của lần từ chối.
<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## Cleanup và overlay

`git worktree remove <path>` trên worktree đã ghi record chạy `release-worktree-resources.sh <path>` trước: nó dọn process gốc ở đó, chạy teardown plug của project và đóng dấu đường dẫn. Đường dẫn phải là literal; đường dẫn có `$`, backtick hoặc `~` bị từ chối. Entry record bị xoá khi worktree và tab đều đã mất.

`.astraler/project/overlays/` là của project, release không ghi vào: `overlays/<role>.md` nối vào system prompt của role mỗi lần render, `overlays/thomas.md` làm vậy trong session dispatcher, `overlays/dispatch-brief.md` nối vào mọi brief. Overlay bổ sung hợp đồng, không ghi đè; luật phải từ chối thì thuộc về plug script, vì văn bản chỉ dặn, chỉ hook mới chặn.
<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## Đang chạy đúng nếu

- Record đọc lại có `pane_id` khớp pane vừa tạo.
- Launch không có chữ `claude` thừa và có `--autocompact 300000`.
- `TURN-END` có dòng `Skills run:` và merge không báo thiếu bước nào.
- Mọi lần từ chối gate để lại dấu trong `refusals` của entry record và trong `~/.local/state/astragentic/harness-hook-events.log`.
- Pane QA chạy không có `--dangerously-skip-permissions`.

<!-- source: harness/.claude/skills/dispatch-ticket-claude/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

`dispatch-ticket` (giao thức chung) → **`dispatch-ticket-claude`** (launcher, mod, kiểm trước) → pane Builder → `TURN-END`. Mod là plugin `astragentic-dispatch`, có trang riêng. Pane gate và pane junior ở ngoài phạm vi của mod.
