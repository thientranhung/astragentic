---
title: astra-ux
oneLiner: "Ghi lại user journey và actor của owner vào PRD trước khi viết spec."
group: shaping
order: 1
runtimes: [claude]
source: harness/.claude/skills/astra-ux/SKILL.md
rented: false
lang: vi
harness: v6.1.19
updated: 2026-11-22
---

## Nó làm gì

`astra-ux` ghi user journey `UJ-n` và actor của owner vào PRD của project (`docs/prd.md`). Skill chỉ ghi lại, không tự soạn: owner kể một phiên thật, skill cấu trúc hoá nó.

Skill hỏi theo vòng, có đánh số, mỗi câu kèm một cách hiểu đề xuất để "đúng" là xác nhận: actor là ai, phiên làm việc trong ba đến năm nhịp, form factor và mức độ rủi ro, điều mỗi surface phải cho thấy trong hai giây, và các state (empty, loading, error, partial, permission-denied).

**Cái giá.** Chỉ bỏ qua khi owner nói surface là công cụ nội bộ một operator và nêu tên operator đó; dòng ấy được ghi vào PRD. Hơn bốn actor bị coi là dàn persona và skill hỏi owner hai actor nào quan trọng.

## Khi nào dùng

| Trước mặt bạn là | Dùng |
|---|---|
| Effort đổi một surface có người nhìn, và PRD chưa có journey cho nó | `astra-ux`, trong pane nơi owner nói (BA hoặc Thomas) |
| Journey trong PRD không còn khớp lời owner mô tả | `astra-ux`, cập nhật tại chỗ |
| Công cụ nội bộ một operator | Bỏ qua, ghi tên operator vào PRD |

## Nó để lại gì

| Chuyện gì xảy ra | Nằm ở đâu |
|---|---|
| Journey và actor | `docs/prd.md`: id `UJ-n`, không đánh số lại, không tái sử dụng |
| Danh từ miền nghiệp vụ | Glossary của PRD, mỗi từ một định nghĩa |
| Điều owner chưa nói | Open questions có đánh số trong PRD |
| Handback | Đường dẫn PRD, các UJ đã chạm, tên actor, open questions |

Skill không viết `DESIGN.md`, mock hay ticket.

## Đang chạy đúng nếu

- Mỗi actor trong PRD được gọi bằng đúng một tên, là tên project đang dùng.
- Mỗi surface có đúng một must-see và đủ năm state đã được trả lời ("không thể xảy ra" kèm lý do vẫn tính).
- Không có màu, pattern hay hướng thiết kế nào mà owner không đưa ra.
- Chỗ trống là Open question, không phải suy đoán đã điền.

## Nó nằm ở đâu trong chuỗi

`astra-ux` → `/skills/astra-grill-with-docs` → `/skills/astra-to-spec` → `/skills/astra-to-tickets`. Spec đọc PRD để lấy tên actor; ticket biến "must see" và "states" thành Glance và States.
