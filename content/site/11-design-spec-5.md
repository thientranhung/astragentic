# Design spec đợt 5: docs sáng, một accent, màu mang nghĩa (2026-09-05)

Chủ site chê (có ảnh /skills): "khai thác không gian, spacing rất phí phạm trong khi đây là
website cung cấp kiến thức nên sẽ nhiều text" và "màu sắc và style rất nhàm chán". Chủ site đã
chọn hướng **Docs sáng, một accent điện** (tham chiếu Mobbin: Mintlify, Cloudflare, OpenAI
Platform). PRD `09-prd.md` giữ nguyên.

## 1. Token mới (thay `--paper/--ink` cũ, giữ tên biến để không sửa component hàng loạt)

```
--paper: #FBFAF7        nền chính, sáng hơn cũ
--paper-sunk: #F1EFE9   panel, code, sidebar
--ink: #16181D
--ink-muted: rgba(22,24,29,.70)
--rule: rgba(22,24,29,.10)
--rule-faint: rgba(22,24,29,.05)
--accent: #0B6E4F       MỘT accent: link, nav active, node đang chọn, nhóm đang xem, nút chính
--accent-soft: #E3F1EB  nền nhạt của accent cho highlight, badge, hàng active
--pass: var(--accent)   giữ alias cho code cũ
--defect: #B4462F       chỉ cho lỗi thật (AST), giữ

Màu vai (chỉ dùng trong diagram, badge vai, và hàng của vai):
--role-thomas: #2F5DA8   --role-thomas-soft: #E6EEF9
--role-shaper: #7A4FBF   --role-shaper-soft: #EFE8F8
--role-builder: #0B6E4F  --role-builder-soft: #E3F1EB
--role-rin:    #B4462F   --role-rin-soft:    #F6E7E3
--role-qa:     #B07A16   --role-qa-soft:     #F7EEDD

Màu nhóm skill (nền nhạt + chữ đậm cùng họ), 7 nhóm:
entry #E6EEF9/#2F5DA8 · main-flow #E3F1EB/#0B6E4F · shaping #EFE8F8/#7A4FBF ·
gate #F6E7E3/#B4462F · brownfield #F7EEDD/#B07A16 · upkeep #ECECEC/#4A4F57 ·
adapter #E8F0F2/#2B6777
```

Chữ: giữ Source Serif 4 cho prose và JetBrains Mono cho khung. Body **16px/1.6**, prose
measure 68ch. h1 trang nội dung 30px, h2 22px, h3 18px. Không còn hero to ở trang nội dung.

## 2. Layout Read mode cho mọi trang nội dung

Áp cho: /skills, /skills/<n>, /vai/<id>, /hooks, /vi-sao, /tech-stack, /cau-truc, /loi,
/bang-chung, /cai, /dictionary/<t>, và bản /en tương ứng.

```
┌ header 56px: wordmark · nav mono · VI/EN · GitHub ──────────────────────────┐
├──────────────┬──────────────────────────────────────────┬───────────────────┤
│ SIDEBAR 240  │ CONTENT 720 (max 68ch prose, diagram bung │ TOC 200           │
│ sticky       │ ra 100% cột)                              │ sticky, "Trên     │
│ mục lục site │ eyebrow mono + h1 30px + 1 câu, KHÔNG hero│ trang này", các h2│
│ theo nhóm    │ nội dung bắt đầu ngay, cách 2rem          │ + h3, highlight   │
│ mục hiện tại │ section cách 3rem, có hairline            │ theo scroll       │
│ nền sunk,    │                                           │ (IntersectionObs) │
│ highlight    │                                           │                   │
│ accent-soft  │                                           │                   │
└──────────────┴──────────────────────────────────────────┴───────────────────┘
```

- Sidebar: cây cố định: Cấu trúc · Vai (5) · Skills (7 nhóm, mỗi nhóm liệt kê skill) · Hooks
  (4) · Vì sao (5) · Tech stack (9) · Lỗi · Bằng chứng · Cài. Mục hiện tại nền `--accent-soft`,
  chữ `--accent`, thanh 2px bên trái là ngoại lệ được phép vì nó là indicator điều hướng
  (Mintlify dùng), không phải trang trí card. Nhóm mở/đóng bằng `<details>` với nhóm hiện tại
  mở sẵn. Mobile: sidebar thành `<details>` "Mục lục" trên đầu trang, TOC ẩn.
- Danh sách skill trong /skills: bảng 3 cột `tên mono | dòng động từ | nhóm badge màu`, hàng
  cao ~44px, hover nền `--accent-soft`, cả hàng là link. Tiêu đề nhóm: dot màu nhóm + tên +
  1 câu, cách 2rem, không 6rem.
- Trang skill: hai cột trong content: bên trái nội dung, bên phải meta card (source, runtimes,
  group badge, updated, "cited by" AST) sticky; trên mobile meta lên đầu.
- Landing `/` giữ 9 section nhưng: padding-block 3.5rem, hero min-height 70vh bỏ, h1 36px, stat
  strip ngay dưới hero; section nền xen kẽ `--paper`/`--paper-sunk`.

## 3. Màu mang nghĩa

- **Diagram**: CSS trong diagram.css tô node theo `data-node-id` cho 5 vai (fill soft, stroke
  role) trên five-roles, hub-and-spokes, structure (node `roles` dùng thomas), cross-vendor-arm
  (participant Builder/Thomas), frontier-query (thomas). Node khác giữ trung tính. Hover/active:
  stroke `--accent` 2px + fill `--accent-soft`. Legend đã ẩn, thay bằng chú thích riêng của
  site dưới diagram khi có vai: 5 chấm màu + tên vai (component `RoleKey.astro`, theo lang).
- **Badge vai** trên /vai/*, trong thẻ vai landing, trong sidebar: chấm màu vai.
- **Badge nhóm skill**: nền soft + chữ đậm cùng họ, mono 11px, uppercase.
- **Mã AST**: giữ `--defect`.
- **Link trong prose**: `--accent`, underline 1px offset 3px; hover đậm hơn.
- **Nút chính**: nền `--accent`, chữ trắng; nút phụ viền `--rule`.
- Không dùng gradient, không shadow màu, không glow.

## 4. Ranh giới và kiểm

- Frontend sửa `site/src/**` trừ `src/content/**`, `src/data/*.json`, `src/assets/diagrams/**`.
- Sau khi sửa: `pnpm build` pass; detector impeccable 0 finding (thanh 2px sidebar active nếu
  bị flag thì persist ignore-value với reason "navigation indicator, Mintlify pattern, chủ site
  chọn hướng docs"); chụp 1440 và 390: /, /skills, /skills/dispatch-ticket, /vai/builder,
  /vi-sao, /cau-truc; tự nhìn và sửa một vòng; kiểm contrast accent trên paper ≥ 4.5:1.
- Tiêu chí nghiệm thu của chủ site: trang /skills ở 1440 hiển thị ≥ 8 skill trong màn đầu
  không cuộn; không khoảng trống > 3rem giữa hai khối nội dung; nhìn vào biết ngay vai nào,
  nhóm nào bằng màu.
