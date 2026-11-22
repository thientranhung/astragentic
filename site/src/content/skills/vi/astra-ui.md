---
title: astra-ui
oneLiner: "Một lượt UI trên một surface đã render, đối chiếu DESIGN.md và Glance, States của ticket: audit, polish hoặc upgrade."
group: main-flow
order: 0
runtimes: [claude]
source: harness/.claude/skills/astra-ui/SKILL.md
rented: false
lang: vi
harness: v6.1.19
updated: 2026-11-22
---

## Nó làm gì

`astra-ui` đọc một surface đã render đối chiếu với chuẩn thiết kế bằng văn bản của project và Glance, States của ticket. Có ba intent: `audit` báo cái gì sai, `polish` liệt kê các sửa nhỏ nhất, `upgrade` đặt một hướng mà thiết kế hiện tại không tới được bằng polish thành câu hỏi với hai hoặc ba lựa chọn. Không nêu intent thì là `audit`.

Design spine là chuẩn. Đường dẫn của nó là các dòng trong `.astraler/project/design-spine`; một finding là khoảng cách giữa surface và một mục được trích dẫn. Mỗi dòng Glance là một mục checklist: must-see thua là P0, không phải polish.

**Cái giá.** Skill chỉ tư vấn. Nó không phải gate, không viết `DESIGN.md`, mock hay component. Một `polish` là danh sách để Builder áp dụng trong vòng lặp của chính nó. Diff không phải surface: repo không có cách render thì lượt dừng và báo.

## Khi nào dùng

| Trước mặt bạn là | Dùng |
|---|---|
| FLOW của Builder nêu tên nó trên ticket UI | `astra-ui audit <surface>` |
| QA walk thấy một surface đọc sai | `astra-ui` |
| Owner yêu cầu một lượt UI | `astra-ui` |
| Builder muốn lượt này mà không tốn context của mình | `Skill(astra-ui)`, rồi subagent `astra-ui-lens` chỉ đọc |

## Nó để lại gì

| Chuyện gì xảy ra | Nằm ở đâu |
|---|---|
| Finding kèm bằng chứng (mục spine, dòng Glance, viewport, cái đã thấy) | Báo cáo gửi caller |
| Chính lời gọi | `skills_run` trên record; làm sáng chip `ui` |
| Báo cáo của lens fan-out | Trả về caller, người quyết định |

Chỉ spawn `Agent` thì không để lại record; chỉ lời gọi `Skill(astra-ui)` mới có.

## Đang chạy đúng nếu

- Mỗi finding trích một mục spine hoặc một dòng Glance hay States.
- Báo cáo nêu viewport và cái đã thấy.
- Mọi tab trình duyệt mà lượt này mở đã đóng trước khi báo cáo.
- Không có màu, pattern hay hướng nào mà owner không yêu cầu.

## Nó nằm ở đâu trong chuỗi

`astra-implement-with-tdd` → anti-slop read → `astra-ui audit` → `astra-review`. Lân cận: subagent `astra-ui-lens` và QA walk.
