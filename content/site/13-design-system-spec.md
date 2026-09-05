# Design system và token, đợt 7 (2026-09-05)

Chủ site: "màu chủ đạo là đỏ của logo astraler.com" và "tạo design system và design token".
Đỏ đo được: CSS astraler.com `rgb(229,54,37)` = `#E53625`; pixel logo PNG trội `#E43424`.
Chọn **`#E53625`** làm brand.

## 1. Đầu ra

1. `site/src/styles/tokens.css`: nguồn duy nhất của mọi biến `:root`. `global.css` import nó
   và không khai báo màu/cỡ nào nữa. Alias cũ (`--paper`, `--ink-muted`, `--rule`, `--pass`,
   `--cta`, `--accent`) giữ để code cũ chạy, trỏ về token mới.
2. `site/design-tokens.json`: cùng bộ token theo W3C Design Tokens format (`$type`, `$value`),
   nhóm `color`, `font`, `size`, `space`, `radius`, `shadow`, `motion`. Script
   `site/scripts/build-tokens.mjs` sinh `tokens.css` từ JSON để hai file không lệch
   (`pnpm tokens`).
3. `site/DESIGN.md`: spine theo impeccable: YAML frontmatter tokens + body đúng thứ tự
   **Brand & Style · Colors · Typography · Layout & Spacing · Elevation & Depth · Shapes ·
   Components · Do's and Don'ts**. Viết từ thứ đã ship, ghi rõ nguồn đo (aihero, astraler).
4. Áp token mới lên site.

## 2. Token

### Màu

```
brand.primary        #E53625   nút chính, nav active, node đang chọn, link mono "đi tiếp",
                               focus ring, dot mục hiện tại trong sidebar
brand.primary-hover  #C92D1F
brand.primary-soft   #FBE9E6   nền highlight mục hiện tại, hàng active
brand.on-primary     #FFFFFF

canvas.base          #F2F3F6
canvas.grid-a        #E8EEF6   gradient giấy kẻ ô: đổi sang lạnh trung tính nhạt để đỏ nổi
canvas.grid-b        #C9D2E6
canvas.grid-c        #AEB9D6
canvas.grid-line     rgba(255,255,255,.6)

surface.base         #FFFFFF
surface.raised       #F7F8FA

ink.100  #14161A   ink.88  rgba(20,22,26,.88)   ink.70  .70   ink.62  .62
ink.35   .35       ink.22  .22                  ink.10  .10   ink.05  .05

semantic.defect      #8C2F1F   gạch đỏ tối cho mã AST và lỗi đo được; khác brand vì tối và
                               nâu hơn, không bao giờ làm nút
semantic.code        ink.88    code không có màu riêng; keyword đậm 600
semantic.focus       brand.primary

role.thomas  #2F5DA8   role.shaper  #7A4FBF   role.builder #0B6E4F
role.rin     #0E7C86   (đổi từ đỏ sang teal để không đụng brand)
role.qa      #B7791F
```

Luật: brand xuất hiện ở đúng danh sách trên, không xuất hiện trong prose, không làm nền
section, không tô diagram ngoài node đang chọn. Vàng `#F5C451` bỏ hẳn. Lục accent cũ bỏ
khỏi nav/link; lục chỉ còn là màu vai Builder.

### Chữ

```
font.sans   "Inter Variable", system-ui      body, h2, h3, UI
font.serif  "Source Serif 4 Variable"        h1 và headline hero
font.mono   "JetBrains Mono Variable"        eyebrow, nhãn, code, tên skill, mã AST

size: 12 · 13 · 14 · 15 · 17 (body) · 19 (h3) · 26 (h2) · 30 (h1 docs) · 36 (hero)
line-height: body 1.55 · heading 1.15 · mono 1.4
tracking: h1 −0.02em · eyebrow +0.1em
```

### Không gian, bo góc, bóng

```
space: 4 · 8 · 12 · 16 · 24 · 32 · 48 · 64 (px)   section gap 48, block gap 24, row 44 cao
radius: 2 (badge) · 6 (nút, input) · 8 (card, code) · 14 (island)
shadow.island  0 1px 2px rgba(20,22,26,.06), 0 12px 40px rgba(40,52,110,.18)
shadow.raised  0 1px 2px rgba(20,22,26,.08)
motion: 120ms ease-out (hover), 150ms (drawer); reduced-motion → 60ms
frame 1200 · docs frame 1440 · content 924 · side 232 · toc 180 · gutter clamp(20px,4vw,48px)
```

## 3. Áp dụng

- Nút chính: nền brand, chữ trắng, hover primary-hover. Nút phụ: surface viền ink.10.
- Nav active: chữ ink.100 + gạch dưới 2px brand. Sidebar mục hiện tại: nền primary-soft,
  chữ brand, thanh 2px brand.
- InteractiveDiagram hover/active: stroke brand 2px, fill surface.
- Link "đi tiếp" mono: brand, gạch dưới 1px. Link trong prose: ink.62 gạch dưới ink.22.
- Focus ring: brand.
- Mã AST: mono ink.88, gạch dưới 1px semantic.defect; DefectCard viền semantic.defect.
- Diagram Rin: đổi stroke sang role.rin teal (chỉ CSS, không sửa SVG).
- Canvas gradient đổi sang bộ lạnh trung tính nhạt ở trên.

## 4. Kiểm

- `pnpm tokens` sinh tokens.css khớp JSON; build pass; detector 0.
- Contrast: trắng trên brand ≥ 4.5 (E53625 trên trắng ≈ 4.6, kiểm); brand trên surface;
  ink.62 link; defect trên surface.
- Chụp /, /skills, /vai/rin, /hooks ở 1440 và 390. Không còn vàng, không còn lục ngoài
  Builder.
