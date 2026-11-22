---
title: test-design
oneLiner: "Viết plan QA xếp theo rủi ro trước khi ticket được cắt."
group: shaping
order: 5
runtimes: [claude]
source: harness/.claude/skills/test-design/SKILL.md
rented: false
lang: vi
harness: v6.1.19
updated: 2026-11-22
---

## Nó làm gì

`test-design` viết `docs/qa/plan-<slug>.md`, plan mà QA chạy theo sau này. Plan viết sau khi build chỉ liệt kê cái đã làm; plan viết trước liệt kê cái có thể sai. Thiếu plan, QA phải suy oracle từ source và phán quyết mất độ tin cậy.

Phương pháp: nhận diện surface (mode walk, probe hoặc verify), đọc test hiện có, chấm rủi ro bằng xác suất nhân tác động (từ sáu trở lên là cao), xếp mọi journey, endpoint và job từ P0 đến P3, rồi tách thành case nguyên tử, mỗi case một level. Surface ghi dữ liệu còn có thêm misuse case. Ngưỡng lấy từ spec, nếu không thì ghi UNKNOWN.

**Số đo.** 19 lượt walk trên một surface upload không chạy misuse case nào; lượt đầu tiên có chạy tìm ra một P1: một tên file trùng trong lần thả thứ hai làm mất mọi tile đang chờ.

**Cái giá.** Đầu vào không nêu cách biết là nó chạy đúng thì skill dừng. Skill không viết test, không cắt ticket và không sửa spec.

## Khi nào dùng

| Trước mặt bạn là | Dùng |
|---|---|
| Spec đã chốt, ticket sắp được cắt | `test-design`, trong session Shaper sau spec arm |
| Ticket rời có acceptance criteria nhưng không có spec | `test-design`, mỗi ticket một mục |
| Cần phương pháp đầy đủ về rủi ro và coverage | Spawn `astragentic-dispatch:astra-test-architect`, chỉ đọc |

## Nó để lại gì

| Chuyện gì xảy ra | Nằm ở đâu |
|---|---|
| Plan | `docs/qa/plan-<slug>.md`: Surfaces, Journeys/endpoints/jobs, Per-ticket cases, Mandatory checks per mode, Open questions |
| Case theo ticket | Thomas chép vào brief của ticket, nêu plan làm nguồn |

## Đang chạy đúng nếu

- Mỗi journey, endpoint và job P0 có ít nhất một case với kết quả mong đợi quan sát được.
- Không hành vi nào được lập kế hoạch ở hai level mà không nêu lý do.
- Ngưỡng chưa biết nằm trong Open questions, không bị bịa.

## Nó nằm ở đâu trong chuỗi

`/skills/astra-to-spec` → spec arm → `test-design` → `/skills/astra-to-tickets`; về sau `/skills/dispatch-qa-walk` đọc plan.
