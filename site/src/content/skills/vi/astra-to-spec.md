---
title: astra-to-spec
oneLiner: "Biến frontier đã trả lời cùng code thành spec và publish lên tracker."
group: shaping
order: 3
runtimes: [claude]
source: harness/.claude/skills/astra-to-spec/SKILL.md
rented: false
lang: vi
harness: v6.1.19
updated: 2026-11-22
---

## Nó làm gì

`astra-to-spec` là pha Spec của Shaper. Skill tổng hợp frontier đã trả lời và code thành spec; nó không mở lại phần phỏng vấn. Câu hỏi còn mở trở thành open question trong spec.

Điều duy nhất skill kiểm với owner là các test seam: seam nào, vì sao, và test ở mỗi seam chứng minh điều gì. Chỉ viết sau khi có câu trả lời. Spec gồm Problem, Solution, Requirements (`FR-n`, mỗi FR có hệ quả kiểm thử được), Implementation decisions, Testing decisions, Non-goals, Open questions và References.

**Cái giá.** Spec không chứa đường dẫn file hay code snippet, trừ prototype snippet chính là quyết định. Không có gì được viết như lời owner nếu owner chưa nói hoặc chưa chấp nhận trong Align.

## Khi nào dùng

| Trước mặt bạn là | Dùng |
|---|---|
| Frontier của Align đã được trả lời | `astra-to-spec` |
| Việc đổi một surface mà PRD chưa có journey | Nói rõ trong handback: `/skills/astra-ux` chưa chạy |
| Một câu hỏi frontier vẫn mở | Ghi vào Open questions, không mở vòng mới |

## Nó để lại gì

| Chuyện gì xảy ra | Nằm ở đâu |
|---|---|
| Spec | Tracker, qua skill `*-issue-tracker`, ở trạng thái `needs-triage` |
| Id requirement `FR-n` | Trong spec, không đánh số lại; ticket trích dẫn chúng |
| Handback | Spec id, các seam đã thống nhất, open questions kèm lý do, ba quyết định skill ít chắc nhất |

Sau đó skill dừng. Thomas promote spec sau khi spec arm đã chạy.

## Đang chạy đúng nếu

- Tên actor và id `UJ-n` khớp từng chữ với PRD.
- Mỗi FR có ít nhất một hệ quả kiểm thử được, không có "gracefully" hay "reasonable".
- Các seam trong Testing decisions là những seam owner đã đồng ý.
- Spec ở `needs-triage`, không bao giờ ở `ready-for-agent`.

## Nó nằm ở đâu trong chuỗi

`/skills/astra-grill-with-docs` → `astra-to-spec` → spec arm → `/skills/test-design` → `/skills/astra-to-tickets`.
