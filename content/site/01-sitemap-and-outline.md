# Site giới thiệu Astragentic — sitemap và outline

Ghi 2026-08-28, dựa trên Astragentic 2.7.13.

Tư liệu nguồn: `content/positioning/superpowers-vs-astragentic.md` (luận điểm và mục cấm),
`content/vibe-engineering-story/` (bài viết, voice guide, media plan), `README.md` (kiến trúc).

---

## 0. Quyết định nền

**Từ định vị: "lớp điều phối" / orchestration layer.** Không dùng *framework* (hàm ý viết code
gọi vào), không dùng *harness* trên mặt tiền (tiếng lóng nội bộ, giữ trong repo), không dùng
*operating system* (voice guide cấm giọng đó).

**Luận điểm xương sống, mọi trang phải phục vụ nó:**

> Astragentic điều phối. Method thì đi thuê. Đó là lý do nó không thay thế bộ skill bạn đang
> dùng — nó là thứ nằm dưới, giữ cho nhiều agent chạy cùng lúc mà không đụng nhau.

**Luật kể chuyện, kế thừa từ `content/vibe-engineering-story/README.md`:** Astragentic chỉ
xuất hiện sau khi người đọc đã cảm thấy vấn đề vận hành. Không mở bài bằng danh sách tính năng.

---

## 1. Sitemap

Site nhỏ. Sáu trang, không hơn.

| Trang | Việc nó làm | Nguồn đã có |
|---|---|---|
| `/` | Từ vấn đề đến hình dạng lời giải, trong một lần cuộn | README §Why this exists |
| `/how-it-works` | Spine và topology — hai sơ đồ | README mermaid ×2 |
| `/evidence` | **Trang khác biệt nhất.** Mỗi luật ở đây đều có biên lai | RELEASE-NOTES, ledger 136 mode |
| `/install` | Sự thật 5 bước, không giấu | README Quickstart, check-requirements.sh |
| `/vibe-engineering` | Bài viết dài — mũi nhọn kéo người về | `content/vibe-engineering-story/` |
| `/faq` | Nơi trả lời thẳng "có đá nhau với X không" | `content/positioning/` |

Không làm: blog, changelog riêng (RELEASE-NOTES trên GitHub đã là changelog và nó hay hơn bất
kỳ bản rút gọn nào), trang pricing, trang team.

---

## 2. Outline trang chủ

Bảy khối, theo đúng thứ tự cảm xúc: đau → hiểu → tin → thử.

### 2.1 Hero
Một câu nói nó là gì, một dòng chứng minh. Không slogan.

- Dòng chính: Astragentic là **lớp điều phối cho nhiều AI coding agent trên một codebase thật.**
- Dòng phụ: cô lập, dispatch, review, provenance.
- Không CTA "Get started" ở đây — người đọc chưa có lý do.

### 2.2 Khoảnh khắc nó vỡ
Ba thất bại cụ thể, viết như chuyện đã xảy ra chứ không như rủi ro lý thuyết:
1. Hai agent ghi đè công việc của nhau trên cùng một branch.
2. Một vòng review chạy 5–14 lượt, và lượt thứ 8 vẫn đang sửa câu mà lượt 2 để lại.
3. Không ai biết thực sự cái gì đã chạy.

Đây là chỗ **duy nhất** được phép nói về nỗi đau. Sau khối này thì thôi.

### 2.3 Bốn cơ chế
Không phải danh sách tính năng — bốn thứ, mỗi thứ một câu và một bằng chứng nhìn thấy được.

| Cơ chế | Một câu | Bằng chứng hiển thị |
|---|---|---|
| Cô lập | mỗi ticket một worktree, một branch, một pane | ảnh chụp workspace nhiều pane |
| Dispatch | tracker giữ trạng thái, frontier query trả lời "cái gì sẵn sàng" | ảnh board |
| Review | hai trục một lượt, cộng một AI khác hãng đọc lại | trích một arm report thật |
| Provenance | mỗi commit mang dòng `Pass:` | trích git log thật |

### 2.4 Spine
Sơ đồ mermaid đã có trong README. Kèm một câu: hai cửa vào tuỳ quy mô, cùng đổ về một đường
ống. Và câu quan trọng: **method trong sơ đồ này là của người khác** — link ra mattpocock.

### 2.5 Bằng chứng
Ba con số, mỗi con số click được sang `/evidence`:
- 136 failure mode đo được, có sổ
- 13 release trong 3 ngày, mỗi bản vá một defect có thật
- 4 gate khác hãng tìm ra 23 defect trước khi 2.7.0 ship

### 2.6 Nó KHÔNG phải cái gì
Khối này làm site đáng tin hơn mọi khối khác cộng lại.
- Không phải model, không phải agent CLI — nó chạy trên Claude Code / Codex / OpenCode.
- Không phải bộ method. Method đi thuê.
- Không chạy nếu không có issue tracker.
- Chưa chứng minh được vòng lặp end-to-end (xem §4).

### 2.7 Đường vào, nói thật
Năm bước, ghi rõ là năm bước. Link repo. Đây mới là chỗ đặt CTA.

---

## 3. Outline các trang còn lại

**`/how-it-works`** — hai sơ đồ README, rồi năm role mỗi role ba dòng (Thomas, Shaper, Builder,
Rin, QA). Kết bằng vòng đời một ticket từ claim tới merge.

**`/evidence`** — mở bằng một entry RELEASE-NOTES nguyên văn, vì giọng của nó *là* lập luận.
Rồi: ledger là gì, cross-vendor arm là gì, và §4 dưới đây.

**`/install`** — prerequisites (Claude Code, git worktree, herdr, mattpocock-skills), rồi
`check-requirements.sh` → `install.sh` → ADAPT-HARNESS → cấu hình tracker. Nói thẳng là phải
qua 5 bước mới thấy giá trị đầu tiên. Giấu thì người ta bỏ ở bước 3 và không quay lại.

**`/faq`** — ba câu bắt buộc có:
- Có thay thế Superpowers / mattpocock-skills không? Không, khác lớp. Rút gọn từ
  `content/positioning/`, giữ nguyên luật "không được viết" trong đó.
- Có bắt buộc dùng tracker không? Có, và tại sao.
- Chạy được với model khác Claude không? Có, ba runtime.

---

## 4. Ranh giới trung thực

`RELEASE-NOTES.md` của 2.7.12 tự viết, và site không được mâu thuẫn với nó:

> Every check in this package now proves the tooling is correct. Nothing in it proves the loop
> works.

Chưa có ticket nào đi trọn dispatch → build → code-review → simplify → arm → merge với đầy đủ
gate trên việc sống. **Site không được viết như thể đã có.** Đưa chính câu này lên `/evidence`
là nước đi mạnh, không phải điểm yếu: một trang giới thiệu tự nêu giới hạn của mình đáng tin
hơn mọi lời quảng cáo quanh nó.

---

## 5. Việc tiếp theo

1. Đọc `content/vibe-engineering-story/drafts/01-first-draft.md`, quyết xem nó đủ làm mũi nhọn chưa.
2. Chọn một feature thật chạy xuyên suốt để làm ví dụ và để chụp ảnh — story README yêu cầu.
3. Chụp bằng chứng thật (workspace nhiều pane, board, arm report, git log) trước khi dựng trang.
4. Dựng `/` trước, bốn trang còn lại sau.
