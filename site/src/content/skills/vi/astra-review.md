---
title: astra-review
oneLiner: "Review một thay đổi trên ba trục, mỗi trục một context, rồi kiểm từng finding tại dòng và route nó."
group: gate
order: 0
runtimes: [claude]
source: harness/.claude/skills/astra-review/SKILL.md
rented: false
lang: vi
harness: v6.1.19
updated: 2026-11-22
---

## Nó làm gì

`astra-review` chạy sau test và lượt UI, trước `simplify`, trên ticket full. Ticket quick chỉ chạy `code-review` built-in. Diff là `git diff <base>...HEAD`, gồm cả file untracked, stage vào file tạm ngoài repo; diff rỗng thì skill dừng.

Ba lens được launch cùng lúc, trước khi đọc bất kỳ kết quả nào:

- **Correctness.** `code-review` built-in trên diff, do chính reviewer gọi, không bao giờ gọi trong subagent. Nó đọc mà không biết intent, nên tìm ra cái còn thiếu.
- **Intent.** Subagent chỉ đọc, nhận ticket và diff: với mỗi criterion, test chứng minh nó và test đã chạy chưa, hành vi không ai yêu cầu, từng dòng Must not change.
- **Standards.** Subagent chỉ đọc, nhận coding standards của repo và danh sách smell chuẩn: vi phạm phải trích file và rule.

Lens thứ tư, adversarial (`astra-adversarial-lens`, Opus), chỉ chạy khi dòng arm `ticket` là `no` hoặc arm không chạy được. Nó không phải arm và không ghi receipt arm.

**Số đo.** Blind-verified trên bảy ticket replay: Opus tìm 13 defect thật mức high hoặc medium với precision 0,71, Sonnet 7 với 0,46, khoảng 109k token mỗi ticket.

## Triage và route

Finding được đánh số R1, R2… và mỗi cái được kiểm tại dòng được trích, gồm cả caller và guard. Mỗi cái nhận một verdict kèm một câu bằng chứng: `high`, `medium`, `low`, `false` hoặc maybe false. Finding còn lại gom theo root cause thành F1, F2…. Finding của standards và intent không bao giờ bị xếp hạng lại với nhau.

| Route | Khi nào |
|---|---|
| patch | Cách sửa rõ ràng và không thêm public surface: sửa, chạy lại test liên quan, stage lại |
| decision_needed | Cách sửa phụ thuộc owner muốn gì: phương án và đề xuất đưa vào handback |
| defer | Có sẵn từ trước, hoặc toàn bộ là maybe false: một dòng kèm điều sẽ chốt được nó |

**Cái giá.** Finding do thay đổi này gây ra và đã có verdict được kiểm thì không bao giờ defer. Không có finding nhưng một lens thất bại thì ghi "có thể chưa đầy đủ", không ghi là sạch.

## Nó để lại gì

| Chuyện gì xảy ra | Nằm ở đâu |
|---|---|
| Một dòng cho mỗi trục: số finding và verdict tệ nhất | Handback |
| Lời gọi, và `code-review` built-in bên trong | `skills_run` trên record; merge gate đọc nó |
| Decision cần owner và các deferral | Handback |

## Đang chạy đúng nếu

- Ba lens được launch trong một message, và kết quả mỗi lens có trên record; lens thất bại được báo là thất bại.
- Mỗi finding có verdict và một câu bằng chứng.
- Không patch nào thêm public surface hoặc guard một trạng thái chưa ai chứng minh là tới được.
- `simplify` chạy một lần, sau bước này.

## Nó nằm ở đâu trong chuỗi

`astra-implement-with-tdd` → `astra-ui` → `astra-review` → `simplify` → arm. Lân cận: `codex-arm`, rơi về lens adversarial khi hết quota.
