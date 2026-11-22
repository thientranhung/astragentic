---
title: codex-arm
oneLiner: "Một lệnh Codex trực tiếp, chỉ đọc, đọc artifact đã xong bằng lens của Astragentic trước khi merge."
group: gate
order: 2
runtimes: [claude]
source: harness/.claude/skills/codex-arm/SKILL.md
rented: false
diagram: cross-vendor-arm
lang: vi
updated: 2026-11-22
harness: v6.1.19
---

## Arm là gì

Cross-vendor arm là một lần gọi `codex exec`, chỉ đọc, chạy trên artifact đã hoàn thành bởi vendor khác với tác giả. Nó không cần plugin Codex. `codex-arm` sở hữu lệnh gọi; `thomas.md` và `builder.md` sở hữu thời điểm chạy.

Tôi thay plugin bằng lệnh trực tiếp ở 6.1.18 và 6.1.19. Plugin không cho đặt effort, không nhận lens của ta, rò một broker mỗi lượt (AST-100) và trả exit 0 khi cấu hình hỏng (AST-095). Skill giảm từ 2.893 xuống 1.553 từ.

**Số đo.** Bảy ticket đã merge được replay tại merge tree, 72 lượt chạy cho 336 finding, verify blind. Codex với edge lens tìm 21 defect thật mỗi lượt, precision 0,77, khoảng 79k token. Trên 34 defect thật, Codex tìm 29 và Claude 17.

**Cái giá.** Pass 2 phát sinh khi pass 1 để lại finding đã fix, nên đa số ticket chạy hai pass: khoảng 160k token Codex mỗi ticket.

## Ai chạy, với lens nào

| Phạm vi | Người chạy | Đứng ở | Lens |
|---|---|---|---|
| `arm: ticket` | Builder | worktree của chính nó | edge lens (`edge-lens.md`) |
| `arm: spec` | Shaper | checkout detached tại commit của spec | adversarial lens |
| `arm: slice` | Thomas | checkout detached tại head của slice | edge lens |

**Số đo.** Lens ở ticket đã đo. Lens ở spec và slice là `chưa đo`: quota Codex hết trước khi đo được.

## Một lệnh, một model

Mọi pass chạy `gpt-6.2-astra` ở effort medium, đặt tường minh, không kế thừa. Đổi model là quyết định của owner.

**Số đo.** Astra tìm 18 đến 21 defect thật mỗi lượt so với 16 đến 20 của Sol, tốn 70 đến 79k token so với 102 đến 124k.

Lệnh truyền diff, commit message làm claim và ý định của owner bằng lời thường. Ý định quan trọng: pass không biết ý định chỉ tìm mâu thuẫn nội tại, pass có ý định tìm được chỗ phản lại điều owner muốn.

## Phán quyết là của bạn và fail closed

- **Không có output không phải là pass.** Lượt không có JSON đúng schema ghi `cross-vendor arm: NOT RUN` kèm lý do, không bao giờ tính là arm sạch.
- **Mỗi finding có một disposition.** Verify tại dòng được trỏ, rồi ghi fixed, low, by design, false hoặc deferred.
- **Tên model sai là NOT RUN.** Range rỗng thì dừng trước khi chạy.

**Số đo.** Proof live 2026-11-21: một defect cài sẵn được nêu tên sau 39 giây, `AGENTS.md` thù địch ghi "fix and commit" không làm tree thay đổi, model lạ trả exit 1 và NOT RUN. Các lượt trực tiếp: 32/32 exit 0 với JSON hợp lệ.

## Khi Codex hết quota

Usage limit nghĩa là arm không chạy. Người đã chạy arm ghi `NOT RUN — usage limit`, và chỉ owner được chấp nhận đi tiếp mà không có arm. Ở phạm vi ticket, ticket vẫn được đọc theo hướng adversarial: `astra-review` chạy adversarial lens bằng Opus, ghi là cùng vendor và chỉ mang tính tham khảo. Lens cùng vendor không bao giờ hoàn tất arm.

**Số đo.** Khi quota cạn, lệnh trả exit 1 với `NOT RUN — usage limit`. Trên lens đó, Opus tìm 13 defect thật, precision 0,71; Sonnet 7, precision 0,46.

## Nó để lại gì

| Chuyện gì xảy ra | Nơi nó nằm lại |
|---|---|
| Log của arm và disposition | `.scratch/gates/arm-<key>-<scope>-pass<N>.md` trên branch của artifact |
| Kết quả ở ticket | receipt `arm(ticket):`, một commit rỗng ghi `Vendor: codex gpt-6.2-astra (direct, <lens>)` |
| Kết quả ở spec và slice | decision trail của merge; slice gate ghi thêm `arm(slice):` |

## Nó nằm ở đâu trong chuỗi

`astra-review` → `simplify` → `codex-arm` pass 1 → fold → pass 2 → receipt `arm(ticket):` → handback. Ticket do Codex build rồi merge ở station Claude được Claude arm, không phải file này.
