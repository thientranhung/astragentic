---
title: astra-implement-with-tdd
oneLiner: "Build một ticket theo test-first: mỗi criterion một test đỏ trước khi có code làm nó xanh."
group: main-flow
order: 0
runtimes: [claude]
source: harness/.claude/skills/astra-implement-with-tdd/SKILL.md
rented: false
lang: vi
harness: v6.1.19
updated: 2026-11-22
---

## Nó làm gì

`astra-implement-with-tdd` là dòng đầu của mọi brief Builder: `/astra-implement-with-tdd <ticket>`. Builder lấy ticket, đọc What to build, Criteria, Must not change (cùng Glance và States với ticket UI), rồi mới mở file.

Vòng lặp chạy từng criterion một: một test đỏ, lượng code ít nhất để nó xanh, một commit. Test quan sát hành vi tại các seam mà spec đã thống nhất, không bao giờ tại method private.

**Số đo.** Harness biết bước đỏ đã xảy ra nhờ log chạy test, không nhờ handback. Commit gate đo một file test và một lần chạy đỏ, merge gate đọc dấu đó.

**Cái giá.** Skill đặt `disable-model-invocation: true`, nên chỉ chạy khi brief đến như một lượt user. Brief mô tả skill bằng văn xuôi thì Builder bắt đầu code mà không qua skill.

## Khi nào dùng

| Trước mặt bạn là | Dùng |
|---|---|
| Brief Builder của một ticket full | `astra-implement-with-tdd` (dòng đầu của brief) |
| Ticket mơ hồ | Handback, không đoán |
| Test mâu thuẫn với criterion | Sửa code; nếu criterion mơ hồ thì dừng và handback |

## Nó để lại gì

| Chuyện gì xảy ra | Nằm ở đâu |
|---|---|
| Một lần đỏ rồi xanh cho mỗi criterion | Log chạy test do hook ghi |
| Một commit cho mỗi slice | Branch của ticket |
| Hành vi mà seam đã thống nhất không thấy được | Một finding trong handback |
| Test đỏ nhưng pass ngay | Một dòng trong handback: hành vi đã tồn tại |

## Đang chạy đúng nếu

- Mỗi criterion có một test đã chạy và pass ở lượt full suite cuối.
- Không test nào mang `skip`, `fixme`, assertion nới lỏng hay timeout nâng lên.
- Mock chỉ nằm ở ranh giới hệ thống: API ngoài, thời gian, randomness.
- Mỗi dòng Must not change có lý do cụ thể cho việc nó vẫn đúng.
- Full suite chạy một lần ở cuối; từng slice chỉ chạy file test đơn lẻ.

## Nó nằm ở đâu trong chuỗi

`astra-to-tickets` → `dispatch-ticket` → `astra-implement-with-tdd` → `astra-ui` (ticket UI) → `astra-review` → `simplify` → arm.
