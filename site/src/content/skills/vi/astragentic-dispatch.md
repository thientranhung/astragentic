---
title: astragentic-dispatch
oneLiner: "Mod Claude Code khiến pane được dispatch tự ghi record, chạy brief như một lượt user và báo turn end."
group: adapter
order: 0
runtimes: [claude]
source: harness/.claude/skills/astragentic-dispatch/hooks/register.tsx
rented: false
lang: vi
updated: 2026-11-22
harness: v6.1.19
---

## Nó làm gì

`astragentic-dispatch` (plugin v1.0.3) là một mod Claude Code. Nó bỏ ba bước dispatch từng không có khoá và bị bỏ qua ở production: ghi dispatch record, arm watcher, và gõ slash command vào pane.

- **Tự ghi record.** Pane có nhãn tab `ticket:`, `spec:`, `qa:` hoặc `resident:` tự ghi tab id và pane id vào `.astraler/state/dispatch-record.json` lúc session start.
- **Brief như một lượt user.** Message của dispatcher bắt đầu bằng `/` chạy qua `$.command.run`; còn lại qua `$.prompt.submit`. Pane trả RECEIVED ngay.
- **Turn end như một tín hiệu.** Khi lượt do message của dispatcher khởi động kết thúc, pane gửi TURN-END, dispatcher được đánh thức và xem board.

**Số đo.** Thời gian đánh thức dưới một giây kể từ turn end, so với khoảng trễ 67 s của việc poll trạng thái pane.

**Cái giá.** Nó là tín hiệu, không phải bằng chứng: TURN-END chỉ nói một lượt đã kết thúc, không nói việc đúng, nên nghiệm thu bằng artifact vẫn là việc của dispatcher. Nó không báo được pane mà process đã chết.

## Gate trên brief

Brief là thời điểm mọi dispatch đều đi qua, nên các kiểm tra đặt ở đó: ticket chưa claim thì không gửi, và brief UI thiếu Glance, States, Criteria thì không gửi. Mod chặn `ScheduleWakeup` trong pane được dispatch (4.6.1) và từ chối lệnh chéo host, vì một session chỉ có một host.

## Đang chạy đúng nếu

- Mỗi dispatch đang sống hiện thành một dòng phía trên prompt của dispatcher.
- Pane mới có entry trong record trước khi brief được gửi.
- TURN-END đến sau mỗi lượt do message của dispatcher khởi động.

## Nó nằm ở đâu trong chuỗi

Plugin ship bốn subagent review: `astra-adversarial-lens`, `astra-slice-reviewer`, `astra-test-architect` và `astra-ui-lens`. Nó nằm dưới `dispatch-ticket` và `dispatch-ticket-claude`, nơi mô tả launcher và các bước bị từ chối.
