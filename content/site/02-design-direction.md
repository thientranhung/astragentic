# Hướng UI/UX cho site Astragentic

Ghi 2026-08-28. Đo trực tiếp từ `pi.dev` và `aihero.dev` qua browser, không lấy từ bài viết.

---

## 1. Hai tham chiếu, đo được gì

| | **pi.dev** | **aihero.dev** |
|---|---|---|
| Nền | `#EBE7E4` kem ấm, phủ lưới giấy kẻ ô rất mờ | `#F1F2F5` xám lạnh nhạt |
| Chữ | `rgba(37,47,61,.96)` xanh đá, không đen tuyền | `#14161A` |
| Font prose | **Plantin MT Pro** serif, 18px | **DM Sans** 16px |
| Font tiêu đề | cùng serif, **nghiêng**, 400, ~48px | cùng sans, **bold 700**, 76px |
| Font mono | Departure Mono + Commit Mono | JetBrains Mono |
| Cột đọc | 590px | 563px |
| Accent | đúng **một** màu xanh `#6A9FCC`, chỉ dùng cho 1 từ trong headline | vàng hổ phách, chỉ dùng cho nút CTA chính |
| Hero | logo pixel + headline serif nghiêng căn giữa + khối cài đặt có tab + **terminal chạy theo scroll** | chia đôi: chữ trái, ảnh chân dung + gradient cầu vồng phải |
| Nav | 5 mục, mono in hoa giãn chữ | 4 mục + 2 CTA, sans thường |

**Bốn thứ cả hai đều làm, và đó là phần nên học:**

1. Nền **không bao giờ trắng tinh**. Cả hai đều lệch khỏi `#FFF`.
2. **Mono dành cho phần khung** — nhãn, eyebrow, nav, con số thống kê — còn prose thì không bao giờ mono. Đây là chữ ký chung của cả hai.
3. **Một cột đọc hẹp ~560–590px**, kể cả khi màn hình rất rộng.
4. **Đúng một màu nhấn**, và nó xuất hiện ít tới mức mỗi lần xuất hiện đều có nghĩa.

---

## 2. Bám hướng nào

**Bám pi.dev về cấu trúc, không bám aihero.**

aihero bán một người thầy và một khoá học: chân dung, gradient, nút vàng, số học viên. Astragentic không có người để bán và không bán khoá học — bắt chước cấu trúc đó sẽ phải bịa ra một nhân vật trung tâm không tồn tại.

pi.dev bán đúng thứ Astragentic bán: **một agent harness, cho người đã biết vấn đề.** Nó tin người đọc, viết dài, không có ảnh minh hoạ nào, và để terminal tự nói. Register đó khớp với giọng `RELEASE-NOTES.md` sẵn có.

**Lấy từ aihero đúng hai thứ:** dải số thống kê mono (rất hợp với "136 failure mode"), và cách chia nav nhiều trang.

**Không sao chép pi.dev:** khác font, khác texture, khác accent. Cùng bộ xương, khác da.

---

## 3. Design tokens đề xuất

### Màu

| Token | Giá trị | Việc |
|---|---|---|
| `--paper` | `#F4F2EE` | nền chính, giấy ấm |
| `--paper-sunk` | `#EAE7E1` | khối code, bảng, panel chìm |
| `--ink` | `#1A1D21` | chữ chính |
| `--ink-muted` | `rgba(26,29,33,.62)` | chú thích, nhãn |
| `--rule` | `rgba(26,29,33,.12)` | đường kẻ, viền |
| `--pass` | `#2F6F5E` | **accent duy nhất** — gate xanh, đã xác minh |
| `--defect` | `#B4462F` | **chỉ** dùng khi trích một defect có thật |

Hai màu có việc, không có màu nào để trang trí. `--defect` không được dùng cho nút, cho hover, cho bất cứ thứ gì không phải một lỗi thật đã xảy ra. Ràng buộc đó chính là thông điệp.

### Chữ

- **Prose + display: `Source Serif 4`.** Serif báo hiệu "tài liệu, biên bản" — đúng thứ Astragentic là. Không dùng nghiêng cho headline (đó là chữ ký của pi.dev).
- **Khung: `JetBrains Mono`.** Nav, eyebrow, nhãn, số, tên file, tên role, mã ticket.
- Hai họ font, không có họ thứ ba.

| Vai trò | Cỡ | Ghi chú |
|---|---|---|
| Display | 56–64px serif 600 | tối đa 2 dòng |
| H2 | 32px serif 600 | |
| Prose | 18px serif 400, line-height 1.75 | cột 620px |
| Eyebrow / nhãn | 12px mono, in hoa, letter-spacing .08em | |
| Số thống kê | 40px mono 500 | nhãn mono 11px dưới nó |

### Không gian và texture

- Cột đọc **620px**. Sơ đồ được phá khung ra tới 1100px.
- Texture nền: **những làn dọc rất mờ** (`--rule` ở 4% alpha, lặp mỗi 220px). Không phải lưới ô như pi.dev — là **làn**, vì làn dọc chính là hình ảnh của worktree song song. Texture ở đây mang nghĩa, không phải hoạ tiết.
- Bo góc 2px. Không đổ bóng ở bất cứ đâu.

### Chuyển động

Gần như không. Đúng **một** hiệu ứng trên toàn site: ở trang chủ, bốn làn dọc chạy song song, mỗi làn là một ticket đi qua các chặng, lệch pha nhau. CSS thuần, dừng khi `prefers-reduced-motion`. Nó minh hoạ đúng luận điểm cốt lõi — nhiều agent chạy cùng lúc mà không đụng nhau — nên nó là nội dung, không phải trang trí.

---

## 4. Điều hướng

Năm mục. Cài đặt bị hạ xuống footer theo đúng ý: nó đơn giản, không đáng chiếm chỗ của nav.

| Mục | Trang | Việc nó làm |
|---|---|---|
| — | `/` | Vấn đề → hình dạng lời giải → bằng chứng. Cửa vào. |
| Architecture | `/architecture` | Năm role, vòng đời một ticket, thang review, tech stack. Chủ yếu là sơ đồ. |
| Why | `/why` | Pain point có thật + case study từ hai project downstream. |
| Compare | `/compare` | Bản đồ AI coding: Astragentic nằm ở đâu, cạnh ai, khác lớp nào. |
| Evidence | `/evidence` | Ledger, cross-vendor arm, và ranh giới tự nêu. |
| GitHub ↗ | ngoài | |

`/install` vẫn tồn tại nhưng chỉ link từ footer và từ cuối trang chủ.

---

## 5. Bộ component

Tám cái, dùng lại khắp nơi. Không đẻ thêm.

1. **Eyebrow** — nhãn mono in hoa trên mỗi khối.
2. **Lane diagram** — nhiều làn dọc song song, mỗi làn một ticket. Component chủ lực của site.
3. **Step rail** — vòng đời tuần tự, đánh số mono, mỗi bước ghi artifact nó để lại.
4. **Stat trio** — ba số mono + nhãn nhỏ. Mượn từ aihero.
5. **Receipt** — khối `--paper-sunk` chứa một artifact thật: git log, arm report, board. Có nhãn nguồn.
6. **Defect card** — một mã `AST-xxx`, một câu chuyện gì đã xảy ra, một dòng "cái giá". Đây là chỗ duy nhất `--defect` được xuất hiện.
7. **Compare grid** — bảng đối chiếu, cột chứ không phải thẻ.
8. **Quote block** — trích nguyên văn từ RELEASE-NOTES, serif, cỡ lớn hơn prose.

---

## 6. Stack frontend đề xuất

**Astro + Tailwind, deploy tĩnh.**

- Site này 90% là nội dung và sơ đồ, gần như không có state. Astro ship 0 JS mặc định — đúng thứ cần.
- MDX cho phép nhúng component sơ đồ thẳng vào bài viết, nên `/architecture` và `/why` viết được như văn bản.
- Sơ đồ: **SVG viết tay**, không dùng thư viện chart. Mermaid trong README chỉ dùng để chốt cấu trúc, không render lên site — nó trông như tài liệu kỹ thuật, không như một trang được thiết kế.
- Không CMS. Nội dung nằm trong repo, cạnh thứ nó mô tả.

---

## 7. Luật viết cho toàn site

Từ `content/positioning/` và voice guide, cộng thêm ý người chủ:

1. **Ít chữ.** Mỗi khối một ý. Nếu một sơ đồ nói được thì cắt đoạn văn.
2. **Không khối nào không có bằng chứng.** Mỗi tuyên bố hoặc dẫn được ra một artifact, hoặc bị cắt.
3. **Cài đặt không phải điểm bán.** Nhắc một lần, ngắn, ở cuối.
4. **So sánh là để định vị, không phải để thắng.** Giữ nguyên mục "không được viết" trong `content/positioning/`.
5. **Nêu giới hạn.** `/evidence` phải mang câu của 2.7.12: *"Nothing in it proves the loop works."*
