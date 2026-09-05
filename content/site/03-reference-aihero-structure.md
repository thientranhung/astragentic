# Tham chiếu cấu trúc aihero.dev (đo từ sitemap.xml)

Ghi 2026-09-04. Nguồn: `https://www.aihero.dev/sitemap.xml` (189 URL) và ba trang đọc trực tiếp:
`/skills`, `/skills-grill-with-docs`, `/ai-coding-dictionary/harness`. Bổ sung cho
`02-design-direction.md`, vốn chỉ đo trang chủ và kết luận "không bám aihero". Kết luận đó
vẫn đúng cho trang chủ. Phần dưới đây là về **kiến trúc nội dung**, không phải bề mặt.

## 1. Bốn lớp nội dung

| Lớp | URL | Số trang | Việc |
|---|---|---|---|
| Hub | `/skills` | 1 (+`/skills-catalog`, `/skills/subscribe`) | Catalog nhóm theo lúc cần dùng + "What is a skill?" + changelog |
| Skill page | `/skills-<name>` | 27 | Một skill một trang, template cố định |
| Dictionary | `/ai-coding-dictionary/<term>` | 70 | Một thuật ngữ một trang, cross-link dày |
| Essay | `/<slug>` | ~80 | Bài dài, kể chuyện, quan điểm |
| Workshop | `/workshops/<name>` | 3 | Khoá học, **không lấy** |

Changelog nằm trong hub và ở `/skills/skills-changelog-<slug>` (5 bản), không có trang
changelog tổng riêng.

## 2. Hub `/skills`

- Sáu nhóm theo **lúc cần dùng**: Getting Started, The Main Flow, Shaping, Upkeep,
  Productivity, Reference. Mỗi nhóm: một câu mục đích + "Start with /x".
- Mỗi skill: một dòng động từ ("Get interviewed about a plan, and record the decisions.").
- Khối "What is a skill?" chia bốn ô: **The problem / The fix / Why it compounds /
  Works in whatever agent you already use**.
- Changelog: version + ngày + một dòng, 5 mục gần nhất.

## 3. Template trang skill (đo từ `/skills-grill-with-docs`)

Thứ tự cố định, mọi trang giống nhau:

1. Header: số thứ tự trong series (`03 / 25`), thời gian đọc, ngày cập nhật, một dòng động từ.
2. Install: lệnh + "Then type /x". Link source.
3. **What it does** (2 đoạn, đoạn hai nói điểm khác biệt và nguồn rắc rối).
4. **When to reach for it**: bảng "What you have → Reach for", so với skill láng giềng.
5. **Prerequisites**: cần skill nào khác, viết vào đâu.
6. **The paper trail**: bảng "What resolved → Where it lands". Artifact là trọng tâm.
7. **Common questions**: 6-8 câu hỏi, câu trả lời **nêu cả bug đã biết và chưa fix**.
8. **It's working if**: 5 gạch đầu dòng có thể kiểm tra.
9. **Where it fits**: chain dạng text `a → b → c`, láng giềng gần.

Giọng: người làm ra nó kể lại, thừa nhận chỗ hỏng ("Nobody is happy with the name"),
không rao bán. Mọi thuật ngữ đều link sang dictionary.

## 4. Template trang dictionary (đo từ `/ai-coding-dictionary/harness`)

1. Một câu định nghĩa in đậm, đủ để đọc riêng.
2. Hai đoạn giải thích cơ chế, mỗi thuật ngữ khác đều link.
3. Một đoạn "This matters for…": vì sao nên quan tâm.
4. Examples: liệt kê sản phẩm thật.
5. Usage: một đoạn hội thoại hai câu minh hoạ cách dùng từ.

Trang index liệt kê toàn bộ 70 mục, mỗi mục tên + một câu, theo thứ tự khái niệm
(model → token → context → agent → harness → …), không theo bảng chữ cái.

## 5. Điều rút ra cho Astragentic

- Dictionary là **chất kết dính**: nó cho phép trang skill ngắn vì không phải định nghĩa
  lại từ. Với Astragentic, đây là chỗ triết lý lộ ra: worktree, frontier, claim, blocking
  edge, gate, receipt, `Pass:`, cross-vendor arm, ledger, residency, milestone, brief.
- "Common questions" ghi bug chưa fix là thứ Astragentic có sẵn nhiều nhất: ledger 136
  failure mode. Mỗi skill page kéo đúng các mode liên quan.
- "The paper trail" trùng khớp triết lý artifact-over-assertion.
- Không lấy: workshop, newsletter CTA, chân dung tác giả, số học viên.
