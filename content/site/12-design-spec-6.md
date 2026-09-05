# Design spec đợt 6: hệ màu và chữ đo từ aihero (2026-09-05)

Chủ site: "mình học được cách Design System về màu sắc và fontbase không? Anh thấy của mình về
màu sắc nó sao sao ấy." Đo trực tiếp `aihero.dev/skill-test-driven-development-claude-code`
bằng browser (computed style), không đoán.

## 1. Aihero đo được

| Vai trò | Giá trị | Ghi chú |
|---|---|---|
| Canvas | `#F1F2F5` xám lạnh | không kem |
| Surface | `#FFFFFF` | bài viết, code block, card, TOC panel đều trắng trên canvas |
| Ink | `#14161A` | một mực, thang alpha 1 · .88 · .7 · .64 · .62 · .35 · .22 · .14 · .1 · .07 |
| Body | DM Sans 18.5px / 1.55, màu ink .7 | measure 607px |
| H1 | DM Sans 700 44px, tracking −0.034em, ink 1 | |
| H2 | 30px 700 | |
| Link trong bài | ink .64, không underline, hover đậm | link không có màu riêng |
| Code inline/pre | trắng, chữ ink .88, 14px, từ khoá xanh `#0F6B52` | |
| Một màu nóng | `#F5C451` vàng, chỉ trên nút CTA | không xuất hiện chỗ khác |
| Màu phụ hiếm | lam `#1F4C8C`, tím `#6D3F9C` chỉ trong icon/badge nhỏ | |

Bài học: **độ sâu bằng trắng trên xám, thứ bậc bằng alpha của một mực, màu chỉ một chỗ.**

## 2. Chẩn đoán site mình

- Không có surface: content, code, thẻ, diagram đều nằm trên kem `#FBFAF7`, phẳng.
- Kem ấm + serif + lục + năm pastel vai tô đầy node + bảy tông nhóm: quá nhiều nhiệt độ màu
  cùng lúc, nhìn đục.
- Muted dùng một alpha .7 cho mọi thứ phụ, không có thang.

## 3. Token v2 (thay §1 của spec 5, giữ tên biến)

```
--canvas: #F2F3F6          nền trang (thay --paper ở body)
--surface: #FFFFFF         bài, card, code, bảng, khung diagram, TOC panel
--surface-2: #F7F8FA       hàng hover, sidebar
--ink: #14161A
--ink-88: rgba(20,22,26,.88)   body prose
--ink-70: rgba(20,22,26,.70)   lede, mô tả
--ink-62: rgba(20,22,26,.62)   link trong bài (hover → ink)
--ink-35: rgba(20,22,26,.35)   nhãn phụ, caption
--ink-22: rgba(20,22,26,.22)   placeholder
--ink-10: rgba(20,22,26,.10)   hairline, viền
--accent: #0F6B52          code keyword, nav active, node đang chọn, link mono
--cta: #F5C451             DUY NHẤT trên nút chính (chữ ink), không chỗ nào khác
--defect: #B4462F          mã AST, giữ

Alias giữ code cũ: --paper → --canvas, --paper-sunk → --surface-2, --ink-muted → --ink-70,
--rule → --ink-10, --pass → --accent.

Màu vai: giữ 5 hue nhưng ĐỔI CÁCH DÙNG: chỉ là chấm 8px, stroke 1.5px của node, gạch dưới
tên vai. Node fill = --surface (trắng). Không còn fill pastel. Node đang chọn: fill
--surface, stroke --accent 2px, bóng nhẹ 0 1px 2px rgba(20,22,26,.08).
Màu nhóm skill: bỏ 7 tông nền. Badge nhóm = viền --ink-10, chữ ink-70, chấm màu nhóm 6px.
```

## 4. Chữ

- Body sang **sans**: `"DM Sans Variable"` từ `@fontsource-variable/dm-sans` (có glyph tiếng
  Việt), 17px/1.55, màu ink-88, measure 66ch. Nếu DM Sans thiếu dấu tiếng Việt ở test render
  thì dùng `"Inter Variable"`.
- Serif Source Serif 4 chỉ còn ở **h1 và headline hero** (giữ chút bản sắc), weight 600,
  tracking −0.02em. h2/h3 sang sans 700, h2 26px, h3 19px.
- Mono JetBrains giữ cho nhãn, eyebrow, code, tên skill.

## 5. Bề mặt và độ sâu

- Content column của DocsLayout là một **surface trắng** bo 8px, viền ink-10, padding 2rem,
  nằm trên canvas. Sidebar và TOC nằm trực tiếp trên canvas (như aihero).
- Code block: surface trắng, viền ink-10, thanh 3 chấm nhỏ ở đầu như aihero, keyword accent.
- Diagram: khung surface trắng, viền ink-10, bo 8px. Trong DocsLayout, `.figure` được phép
  **breakout sang phải qua cột TOC** (width tới ~960px) để hình to; TOC chỉ sticky ở phần
  chữ. Áp ngay cho /hooks (4 sơ đồ nhỏ đang hẹp).
- Landing: section xen kẽ canvas / surface (thay paper / sunk). Thẻ trên landing = surface
  trắng viền ink-10, hover viền ink-22, không tint màu.
- Nút chính: nền --cta chữ ink, bo 6px, 40px cao; nút phụ: surface viền ink-10.

## 6. Kiểm

- Contrast: ink-70 trên surface ≥ 4.5 (đo), ink-62 link ≥ 4.5, accent trên surface ≥ 4.5,
  ink trên cta ≥ 4.5.
- Detector 0. Chụp 1440: /, /skills, /skills/dispatch-ticket, /hooks, /vai/builder,
  /vi-sao, /cau-truc; 390: /, /skills. Đặt cạnh ảnh aihero `/tmp/astra-shots/aihero-tdd-mid.png`
  để tự so: có độ sâu trắng/xám chưa, có còn màu thừa không, chữ Việt DM Sans có đủ dấu.
- Không sửa content/data/diagram SVG.
