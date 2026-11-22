---
title: astra-grill-with-docs
oneLiner: "Chất vấn kế hoạch cùng owner theo từng vòng câu hỏi đánh số cho tới khi cây quyết định không còn nhánh chưa đi qua."
group: shaping
order: 2
runtimes: [claude]
source: harness/.claude/skills/astra-grill-with-docs/SKILL.md
rented: false
lang: vi
harness: v6.1.19
updated: 2026-11-22
---

## Nó làm gì

`astra-grill-with-docs` là pha Align của Shaper. Effort là một cây quyết định, và skill đi qua mọi nhánh cùng owner thay vì tự điền bằng phán đoán của mình.

Mỗi vòng skill hỏi toàn bộ frontier (mọi quyết định đã có đủ prerequisite), có đánh số, mỗi câu kèm câu trả lời đề xuất và nguồn của nó, rồi chờ. Fact là việc của agent tra cứu; quyết định là của owner. Câu trả lời không có nguồn thì câu hỏi vẫn mở.

**Cái giá.** Một chữ "đồng ý" cho cả vòng không chốt được gì: mỗi câu chỉ được chốt bằng câu trả lời riêng của nó. Phương án thay thế phải được nêu cạnh đề xuất, và skill không chọn hộ owner phạm vi MVP hay cách chia pha.

## Khi nào dùng

| Trước mặt bạn là | Dùng |
|---|---|
| Một kế hoạch, hướng đi hay effort owner muốn chất vấn trước khi viết spec | `astra-grill-with-docs`, pha đầu của Shaper |
| Câu hỏi cần fact từ code, config, log hay web | Không hỏi owner: tra cứu, rồi chỉ hỏi những gì phụ thuộc vào fact đó |
| Spec đã viết xong | Không dùng skill này; câu hỏi còn mở đi vào spec |

## Nó để lại gì

| Chuyện gì xảy ra | Nằm ở đâu |
|---|---|
| Một thuật ngữ được chốt | `GLOSSARY.md`, cập nhật ngay, không gom lô |
| Một trade-off khó đảo ngược, bất ngờ nếu thiếu ngữ cảnh | `docs/adr/NNNN-<slug>.md`, chỉ khi đủ cả ba điều kiện |
| Cây đã trả lời | Chuyển cho pha Spec: quyết định kèm nguồn, câu hỏi còn mở kèm lý do |

## Đang chạy đúng nếu

- Mỗi câu hỏi có đề xuất và "đồng ý" nghĩa là chấp nhận nó.
- Mỗi câu trả lời nêu một nguồn: file và dòng, ADR, ghi chú nghiên cứu, hoặc lời owner trong vòng đó.
- Thuật ngữ dùng trái định nghĩa trong glossary bị chất vấn ngay.
- Spec chưa được viết cho tới khi owner xác nhận cách hiểu chung.

## Nó nằm ở đâu trong chuỗi

`/skills/astra-ux` → `astra-grill-with-docs` → `/skills/astra-to-spec`. Skill chạy trong context của Shaper, liền một phiên với hai skill kế tiếp.
