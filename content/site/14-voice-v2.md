# Giọng văn v2 cho site (2026-09-05)

Chủ site đọc bản đợt 6 và nói: "văn phong nó kì kì… Nó không ra sáng site công nghệ gì cả",
trích hai câu: "Chín thứ mình đứng lên / Món nào bỏ ra mà chỉ hơi bất tiện thì mình bỏ rồi" và
"Một agent chạy một mình thì không cần gì ở đây; cái này dành cho lúc anh em chạy bốn agent
cùng lúc." Voice guide cũ (`content/vibe-engineering-story/03-voice-guide.md`, "mình / anh em")
viết cho bài kể chuyện, không cho site. File này thay nó cho mọi chữ trên site.

## Luật

1. **Ngôi**: "tôi" cho tác giả (chủ site nói rõ: đây là công trình nghiên cứu cá nhân, không
   phải của tổ chức); "bạn" cho người đọc. Không "mình", "anh em", "chúng tôi", "tụi mình".
   Bản Anh: "I" và "you".
2. **Register**: tiếng Việt kỹ thuật chuẩn, như tài liệu của một công ty phần mềm. Không tiếng
   lóng, không từ sinh hoạt ("món", "ngon", "đứng lên", "chín thứ", "rồi đó", "thôi").
   Không ẩn dụ đời sống. Không câu cảm thán.
3. **Câu**: chủ ngữ rõ, một ý một câu, 12–22 từ. Ưu tiên khẳng định: "Astragentic tách mỗi
   ticket vào một worktree riêng." thay cho "Mỗi Builder có checkout riêng, và mọi thứ hỏng
   dọc đường đều có một chặng để treo vào."
4. **Vẫn giải thích vì sao**, nhưng bằng nguyên nhân và hệ quả kỹ thuật, không bằng chuyện
   kể: "Tôi chọn X vì Y; đổi lại phải trả Z."
5. **Thuật ngữ**: giữ tiếng Anh cho tên vai, skill, lệnh, mã AST, git, tracker, runtime,
   worktree, hook, ledger, commit, review. Không dịch "worktree" thành "cây làm việc".
6. **Headline**: câu khẳng định kỹ thuật ≤ 12 từ, có danh từ sản phẩm hoặc cơ chế. Không tục
   ngữ, không chơi chữ. Ví dụ: "Lớp điều phối cho nhiều coding agent trên một repo."
7. **Số liệu và trích dẫn**: giữ nguyên, có nguồn, không thêm.
8. **Không** từ dạy/học/tutorial/lesson (PRD §3 vẫn giữ).

## Ví dụ chuyển đổi

| Cũ | Mới |
|---|---|
| Một agent chạy một mình thì không cần gì ở đây; cái này dành cho lúc anh em chạy bốn agent cùng lúc. | Một agent không cần lớp điều phối. Bốn agent trên cùng một repo thì cần: Astragentic tách checkout, trạng thái và review cho từng agent. |
| Chín thứ mình đứng lên | Chín thành phần của stack |
| Món nào bỏ ra mà chỉ hơi bất tiện thì mình bỏ rồi. | Thành phần nào bỏ đi mà chỉ gây bất tiện nhỏ, tôi đã bỏ. Còn lại là những thứ không thay được. |
| Sống suốt phiên. Giữ tracker, frontier, claim, dispatch và merge. | Thomas sống suốt phiên, giữ tracker, frontier, claim, dispatch và merge. |
| Bảy cái tên có ở đây để khi một thứ hỏng, mình có chỗ treo nó vào. | Bảy chặng có tên để mỗi lỗi đo được gắn vào đúng một chặng. |

## Phạm vi viết lại

- `site/src/content/landing/vi.yaml`, `en.yaml`
- `site/src/content/pages/{vi,en}/*.md` (structure, why, tech-stack, hooks, home, failures,
  evidence, adopt)
- `site/src/content/roles/{vi,en}/*.md`
- `site/src/content/skills/{vi,en}/*.md` (32 file)
- Chuỗi UI trong `site/src/lib/ui.ts`, `site/src/lib/anchors.ts` (các trường when/effect/oneLine),
  `site/src/lib/skills.ts`, heading/lede cứng trong `site/src/components/pages/*.astro`.
- Không đổi frontmatter key, anchor, heading id, mã AST, trích dẫn nguyên văn.

## Bổ sung spacing (ảnh chủ site gửi, trang /skills)

- Nhịp dọc trong bảng nhóm phải đều: khoảng cách giữa hai nhóm 32px; heading nhóm → lede 4px;
  lede → hàng đầu 12px; padding hàng 12px trên dưới; hairline giữa hàng.
- Cột: tên skill 200px cố định, mô tả `minmax(0, 62ch)`, badge 132px canh phải nhưng
  không trôi xa mô tả (grid 3 cột, gap 24px, bảng không rộng hơn 860px).
- Mô tả tối đa 2 dòng; câu dài hơn thì writer rút.
