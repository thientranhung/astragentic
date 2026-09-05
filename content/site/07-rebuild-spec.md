# Rebuild spec, đợt 2 (2026-09-04)

Rút từ `06-roundtable-minutes.md`. Mọi agent đọc file này trước. Ai lệch phải báo team-lead.

## 0. Giả định đang chạy (chủ site chưa trả lời, sẽ sửa khi có)

| # | Câu | Giả định |
|---|---|---|
| 1 | Người đọc | Anh em dev trong team đã dùng một agent (Claude Code / Codex), có thể chưa chạy nhiều agent. `[ASSUMPTION]` |
| 2 | Ngôi kể | Ngôi thứ nhất, "mình", theo `03-voice-guide.md`. Bản Anh dùng "I". |
| 3 | Ngôn ngữ | Tiếng Việt là bản chính ở `/`. Tiếng Anh mirror ở `/en/...`. Viết Việt trước, dịch sau. |
| 4 | Lời thú nhận | Kéo "Nothing in it proves the loop works" lên: màn 4 trang chủ và đầu `/evidence`. |
| 5 | Nav | 5 mục: Trang chủ (logo), Lỗi, Bằng chứng, Kiến trúc, Cài. Skills và Dictionary giữ URL, bỏ khỏi nav. |
| 6 | Năm ô kẹt | Xoá. Không có ảnh worktree sống, không có arm report, không có ảnh board. Không bịa. |

## 1. Ba luật của đợt này

1. **Prose là content, bằng chứng là data, layout là code.** Writer chỉ viết văn vào markdown.
   Mọi mã AST, dòng ledger, commit, lệnh đều đến từ `site/src/data/*.json` do script sinh ra
   từ repo. Frontend quyết định bố cục. Không ai nhúng component vào MDX nữa.
2. **Bằng chứng là link đi được.** Mỗi mã AST trên site phải bấm được tới đúng chỗ: dòng entry
   trong ledger (hiển thị nguyên văn) và file đang mang luật (skill page nếu có, hoặc đường dẫn
   GitHub tới file harness). Không có ảnh chụp.
3. **Khung dịch, bằng chứng không dịch.** Mã AST, tiêu đề entry, dòng ledger, commit message,
   trailer, tên skill, lệnh, trích RELEASE-NOTES giữ tiếng Anh ở cả hai bản.

## 2. Sitemap

```
/                 hành trình 4 màn trên một trang cuộn (tiếng Việt)
/loi              6 lỗi thật xếp theo chặng, 2 chặng trống nói thẳng      (en: /en/failures)
/bang-chung       bảng 136 dòng, 71 link, 65 mồ côi, thú nhận ở đầu       (en: /en/evidence)
/kien-truc        5 role + 7 chặng, trang tham chiếu, giữ từ đợt 1        (en: /en/architecture)
/cai              4 prerequisite + 4 lệnh từ README, 4 skill brownfield   (en: /en/adopt)
/skills/<name>    giữ nguyên đợt 1, chỉ tiếng Anh, bỏ khỏi nav
/dictionary/<t>   giữ nguyên đợt 1, chỉ tiếng Anh, bỏ khỏi nav
/explore/*.html   giữ
/en/              mirror 5 trang trên
XOÁ: /compare, /essays (giữ file, không route), hub /skills (index), /dictionary (index)
```

Slug tiếng Việt không dấu. Astro i18n: `defaultLocale: 'vi'`, `locales: ['vi','en']`,
`prefixDefaultLocale: false`. Nút VI · EN ở nav trỏ sang trang tương ứng.

## 3. Trang chủ: bốn màn

Mỗi màn là một `<section>` full-width trong khung 1200, có nền riêng nhẹ để mắt thấy ranh giới
(xen kẽ `--paper` và `--paper-sunk`). Cột đọc 680 cho văn, bằng chứng phá ra 1040.

### Màn 1 · Nhận ra (nền paper)
- Eyebrow mono: `AST-016 · promoted 2026-07-11`
- Headline serif 2 dòng (writer viết), ví dụ tinh thần: "Một agent chạy ngon. Ba agent thì bắt
  đầu giẫm lên nhau."
- **DefectCard** phá khung 1040: mã, tiêu đề entry (Anh), 2-4 dòng entry nguyên văn (Anh) từ
  data, một câu của mình (Việt) dưới, chân card: `INDEX.md:31 · 38 words · cited by
  dispatch-ticket, codex-claude-arm` với hai tên skill là link.
- Một đoạn văn ngắn (writer) rồi mũi tên xuống. Không stat, không CTA, không animation.

### Màn 2 · Hình dạng (nền sunk)
- Headline + 1 đoạn (writer): vì sao mình chia ticket thành 7 chặng.
- **StageRail** phá khung: 7 chặng ngang `claim · brief · build · code-review · simplify · arm
  · merge`. Dưới mỗi chặng treo các lỗi thật thuộc chặng đó từ data (`stage` field): claim
  AST-131; build AST-097, AST-092; arm AST-015; merge AST-074, AST-056. Chặng không có lỗi in
  chữ mono nhỏ "chưa đo được lỗi nào ở đây". Mỗi lỗi là DefectCard thu nhỏ, bấm ra `/loi#ast-xxx`.
- Link đi tiếp mono: "Sáu lỗi, đọc đủ →" tới `/loi`.

### Màn 3 · Đi xuyên qua, climax (nền paper)
- Headline (writer) + 1 đoạn nói con số thật: 71 trên 136 đã buộc vào file, 65 chưa.
- **LedgerTable** phá khung, cao tối đa 60vh, cuộn trong: cột `ID | Lesson | Status | Cited by`.
  Dòng có cited-by: mũi tên và số; bấm mở **inline drawer** ngay dưới dòng: entry nguyên văn
  (từ data) + danh sách file mang luật, mỗi file là link (skill page nội bộ nếu có, không thì
  GitHub blob). Dòng trống: gạch ngang mono, không link, hover hiện "chưa có gì trỏ về".
  Ô tìm nhanh mono phía trên bảng (lọc client-side, không JS framework, vanilla).
- Mặc định mở sẵn dòng AST-016 để người đọc thấy drawer là gì.
- Link đi tiếp: "Cả bảng, và 65 dòng mồ côi →" tới `/bang-chung`.

### Màn 4 · Giới hạn (nền sunk)
- **QuoteBlock** to, nguyên văn Anh: "Every check in this package now proves the tooling is
  correct. Nothing in it proves the loop works." nguồn `RELEASE-NOTES.md:393` là link GitHub.
- Đoạn văn (writer): mình đặt dòng này lên đây vì sao.
- **AdoptBlock**: 4 prerequisite (từ data, README) và 4 lệnh quickstart (từ data) trong khối
  mono có nút copy. Link "Cài cho repo của anh em →" tới `/cai`.
- Chân trang.

## 4. Data (script sinh, commit kết quả JSON)

`site/scripts/build-data.mjs`, chạy bằng `pnpm data`, ghi:

- `site/src/data/ledger.json`: mảng 136 phần tử `{ id, lesson, status, words, citedBy:
  string[], indexLine: number, entryLine: number, promotedOn: string|null, entry: string
  (nguyên văn tới heading tiếp theo, tối đa 1200 ký tự), refs: [{ name, kind:
  'skill'|'file', href }] }`. `refs` map từng cited-by: nếu trùng tên skill có trang
  `site/src/content/skills/<name>.md` → `/skills/<name>`; không thì tìm file trong `harness/`
  theo tên → `https://github.com/thientranhung/astragentic/blob/main/<path>`; không tìm thấy →
  kind 'file', href null, giữ tên.
- `site/src/data/failures.json`: 6 lỗi của `content/site/pages/why.md` với `{ id, stage,
  costLine }` (đọc why.md để lấy id và câu chi phí; stage theo bảng ở §3 màn 2).
- `site/src/data/adopt.json`: `{ prerequisites: [{name, version, href}], commands: string[] }`
  từ `README.md` mục Quickstart và Prerequisites, nguyên văn.
- `site/src/data/commits.json`: 20 commit gần nhất có dòng `Ledger:` trong body:
  `{ sha, date, subject, ledger: string }`.
- `site/src/data/meta.json`: `{ total, cited, orphan, generatedAt, version }` (version từ
  README badge).

Script không được bịa: thiếu nguồn thì để null và in cảnh báo.

## 5. Content (writer)

Đường dẫn: `site/src/content/pages/<lang>/<slug>.md`, lang ∈ {vi, en}, slug ∈ {home, failures,
evidence, adopt}. Frontmatter:

```yaml
title: "…"
description: "…"
acts:                      # chỉ home
  - id: act-1
    eyebrow: "AST-016 · promoted 2026-07-11"   # giữ Anh
    headline: "Một agent chạy ngon. Ba agent thì bắt đầu giẫm lên nhau."
  - id: act-2 …
```

Body: với home, đúng 4 mục `## act-1` … `## act-4`, mỗi mục 1-3 đoạn văn, không heading con,
không component, không mã AST viết tay (frontend chèn từ data). Với failures: 1 đoạn mở + 6
mục `## AST-xxx` mỗi mục 1-2 đoạn "vì sao mình sửa vậy, cái giá". Với evidence: 1 đoạn mở
(vì sao mình ghi ledger), 1 mục `## orphan` (65 dòng chưa buộc, nói thẳng). Với adopt: 1 đoạn
mở, 1 mục `## brownfield` (4 skill).

Giọng: `03-voice-guide.md`, ngôi "mình", nói với "anh em". Viết Việt trước; bản Anh là dịch
giữ nhịp, ngôi "I". Không từ dạy/học/tutorial. Không bịa số; số nào cần thì viết
`{{meta.cited}}` `{{meta.orphan}}` `{{meta.total}}` để frontend thay.

## 6. Layout và style (frontend)

- Giữ token đợt 1 (`--paper --paper-sunk --ink --ink-muted --rule --pass --defect`), font
  Source Serif 4 + JetBrains Mono, khung 1200 viền hai bên, cột 680, breakout 1040.
- Bỏ LaneDiagram, StatTrio, CompareGrid, Receipt. Thêm DefectCard (to và nhỏ), StageRail,
  LedgerTable (+drawer, +filter), QuoteBlock, AdoptBlock, LangSwitch.
- Mỗi màn: padding-block 6rem, ranh giới bằng nền xen kẽ, không đường kẻ eyebrow nữa.
- Màu: `--defect` chỉ cho DefectCard viền và mã AST. `--pass` chỉ cho mũi tên/số cited-by và
  link đi tiếp. Không màu nào khác.
- Không animation ngoài mở/đóng drawer (150ms). `prefers-reduced-motion` tắt luôn.
- Tiêu chí nghiệm thu (John): trên trang chủ, bấm một mã AST → tới đúng entry và file mang
  luật mà không đi qua nav. Team-lead sẽ kiểm bằng browser thật ở 1440 và 1800px.

## 7. Bổ sung từ vòng 2 trễ (2026-09-04)

- **AST-135 là mã duy nhất khép cả bốn mắt** (Paige đếm: 23 mã có trailer `Ledger:`, 21 mã trên
  skill page, 1 mã khép đủ): INDEX cited by `dispatch-qa-walk, thomas.md` → skill page
  `dispatch-qa-walk.md:73` → commit `4d35e51` trailer `Ledger: AST-134, AST-135`. Màn 3 mở sẵn
  drawer **AST-135** thay vì AST-016, và drawer hiện đủ bốn nhịp: entry, file mang luật, skill
  page, commit. Màn 1 vẫn là AST-016.
- Data: mỗi phần tử `ledger.json` thêm `commits: [{sha, date, subject}]` từ trailer `Ledger:`
  (rỗng nếu không có). `meta.json` thêm `closedChains: 1` (số mã có đủ refs + skill page +
  commit, tính bằng script, không hardcode).
- Không dựng gallery chuỗi: một chuỗi khép là bằng chứng, mười chuỗi hở là tự bắn vào chân.
- Hai bản ngôn ngữ có thể là hai người đọc: Việt là đồng nghiệp đã chạy một agent, Anh là
  người lạ chưa có dữ liệu. Đợt này bản Anh là dịch giữ nhịp; cho phép khác chuyện là câu chờ
  chủ site.
