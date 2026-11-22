---
title: astra-to-tickets
oneLiner: "Cắt spec đã commit thành ticket tracer-bullet có cạnh prerequisite và publish theo thứ tự build."
group: shaping
order: 4
runtimes: [claude]
source: harness/.claude/skills/astra-to-tickets/SKILL.md
rented: false
lang: vi
harness: v6.1.19
updated: 2026-11-22
---

## Nó làm gì

`astra-to-tickets` là pha Tickets của Shaper, do Thomas mở bằng `/astra-to-tickets <spec-id>`. Skill cắt spec như đã commit sau arm thành các ticket tracer-bullet: đường hẹp nhưng đầy đủ xuyên mọi layer, cỡ vừa một session Builder trong một context mới.

Cạnh chỉ là prerequisite, vì frontier query của Thomas đọc chúng. Mỗi ticket có What to build, Criteria (given, when, then, trích một FR), Must not change, Evidence và nhãn `quick` hoặc `full`. Ticket đổi một surface còn có Glance (đúng một must-see cho mỗi màn hình) và States.

**Cái giá.** Ticket UI thiếu Glance và States thì không được cắt, vì dispatch mod từ chối brief nó. Không gì lên tracker cho tới khi owner trả lời bài quiz (độ mịn, cạnh, gộp hay tách).

## Khi nào dùng

| Trước mặt bạn là | Dùng |
|---|---|
| Spec đã commit qua arm, cùng plan QA | `astra-to-tickets`, trên dòng release của Thomas |
| Thay đổi có blast radius lan khắp codebase | Xếp theo expand, migrate, contract |
| Chữ "for now" hay "placeholder" trong ticket nháp | Tách thành ticket thứ hai, không thu nhỏ |

## Nó để lại gì

| Chuyện gì xảy ra | Nằm ở đâu |
|---|---|
| Ticket theo thứ tự build | Tracker, với blocking relation gốc, sub-issue của spec nếu tracker có, readiness `needs-triage` |
| `quick` / `full` | Nhãn trên tracker |
| Handback | Id ticket kèm cạnh, đường dẫn plan, set check, cách xử lý từng finding ở giai đoạn spec |
| Thay đổi về sau | Tại chỗ, giữ id; ticket bị bỏ có ghi chú `Dropped:` |

## Đang chạy đúng nếu

- Mọi requirement của spec và case của plan nằm trong một ticket hoặc một deferral có tên.
- Mỗi `Given` mở bằng tên actor trong PRD.
- Mỗi ticket có nhãn, và test nằm trong chính ticket.
- Spec và các parent không bao giờ bị đóng hay sửa.

## Nó nằm ở đâu trong chuỗi

`/skills/astra-to-spec` → `/skills/test-design` → `astra-to-tickets` → `/skills/dispatch-ticket`.
