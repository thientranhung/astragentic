# Landing spec, đợt 3 (2026-09-04)

Chủ site xem đợt 2 và nói: "đọc vào nó rất đặc quánh chữ nghĩa thay vì trực quan. Làm nó như
landing page: hero; xuống dưới có archify hoạt động, click vào Builder thì sang page về Builder
hoạt động thế nào; xuống nữa là workflow khi nhận task từ issue tracker giữa các role."

Giữ nguyên: luật ba điều ở `07-rebuild-spec.md` §1 (prose là content, bằng chứng là data, layout
là code; bằng chứng là link đi được; khung dịch, bằng chứng không dịch), token, khung 1200,
song ngữ `/` vi và `/en/`, các trang `/loi`, `/bang-chung`, `/kien-truc`, `/cai`, data JSON.

## 1. Nguyên tắc landing

- **Mỗi section một hình, một câu, một hành động.** Chữ trên trang chủ tối đa 2 câu mỗi
  section. Chữ dài sống ở trang con.
- **Hình là archify SVG có sẵn** trong `site/src/assets/diagrams/`, đã có `id="node-<id>"`
  và `data-node-id`. Frontend làm chúng tương tác: hover sáng node, click node → route.
  Không vẽ diagram mới trừ khi bắt buộc.
- **Chạm được**: mọi node có trang đích. Node không có trang thì không sáng khi hover.

## 2. Trang chủ, thứ tự section

1. **Hero** (nền paper, min-height 80vh). Trái: eyebrow mono `Orchestration layer for coding
   agents · v{{meta.version}}`, headline 2 dòng (writer), một câu dưới (writer), hai nút:
   primary "Xem nó chạy ↓" (cuộn tới section 2), secondary mono "Cài cho repo của anh em →"
   (`/cai`). Phải: diagram `five-roles` thu nhỏ, tĩnh, làm hình hero (không tương tác ở đây,
   chỉ là ảnh). Dưới hero một dải mono 3 số từ meta: `{{meta.total}} failure modes logged ·
   {{meta.cited}} bound to a file · 3 runtimes`.
2. **Năm vai** (nền sunk). Headline ngắn + 1 câu. Diagram `five-roles` phá khung 1040,
   **tương tác**: hover node sáng viền `--pass` và hiện tooltip mono (sublabel + session tag
   lấy từ data-node-* trong SVG); click → `/vai/<id>` (en `/en/roles/<id>`). Dưới diagram 5
   thẻ nhỏ ngang (mono tên vai + 1 dòng) cũng link cùng chỗ, cho mobile.
3. **Một ticket đi qua bảy chặng** (nền paper). Headline + 1 câu. Diagram `ticket-lifecycle`
   phá khung, tương tác: hover chặng sáng, click chặng → `/loi#<stage>` (claim, brief, build,
   code-review, simplify, arm, merge; map `implement`→build, `code_review`→code-review). Dưới
   diagram: dải 7 bước mono, mỗi bước 1 dòng caption (writer), bước có lỗi thật thì gắn mã AST
   nhỏ màu `--defect` link `/loi#ast-xxx` (từ failures.json).
4. **Từ tracker tới pane** (nền sunk). Headline + 1 câu: Thomas hỏi tracker cái gì sẵn, thay vì
   nhớ. Diagram `frontier-query` phá khung, tương tác: click `thomas` → `/vai/thomas`, click
   `board`/`frontier_query`/`blocking_edges`/`assignee_field` → `/bang-chung#ast-074` (lỗi
   tracker) hoặc dictionary tương ứng nếu có (`/dictionary/frontier`, `/dictionary/blocking-edge`,
   `/dictionary/claim`); node không map thì không sáng. Bên phải diagram (desktop) một khối
   mono "Requirement 5" trích nguyên văn `tracker-contract.md:42` với link GitHub.
5. **Hai bên soi nhau** (nền paper). Diagram `cross-vendor-arm` phá khung, tĩnh có hover. 1 câu:
   Claude build, Codex đọc lại, biên nhận buộc vào SHA. Link `/skills/codex-arm`.
6. **Bằng chứng, không phải lời hứa** (nền sunk). Trái: DefectCard nhỏ AST-016. Phải: khối số
   `{{meta.cited}} / {{meta.total}}` mono to, 1 câu, nút "Mở cuốn sổ →" `/bang-chung`. KHÔNG
   nhúng bảng 136 dòng ở trang chủ nữa.
7. **Giới hạn + cài** (nền paper). QuoteBlock "Nothing in it proves the loop works" nhỏ hơn đợt
   2, AdoptBlock 4 lệnh, nút `/cai`.

Không còn 4 màn prose. Nội dung act-1..4 của writer đợt 2 chuyển sang `/loi` (act-1, act-2 mở
đầu) và `/bang-chung` (act-3, act-4 mở đầu); frontend giữ file, đổi chỗ render.

## 3. Trang vai: `/vai/<id>` và `/en/roles/<id>`, id ∈ thomas, shaper, builder, rin, qa

Layout: hero nhỏ (eyebrow mono `ROLE · session: <tag>`, h1 tên vai, 1 câu), rồi diagram
`five-roles` với node của vai đó sáng sẵn (class `is-active`), rồi ba khối:
- **Nó làm gì mỗi lượt**: prose writer (3-5 đoạn ngắn, hoặc danh sách 4-6 bước).
- **Nó được phép và không được phép**: bảng 2 cột từ prose writer.
- **Lỗi nó đã gây ra hoặc bắt được**: DefectCard nhỏ cho mọi mã AST trong `ledger.json` có
  `citedBy` chứa `<id>.md` hoặc tên skill của vai (thomas: dispatch-ticket, reconcile-tracker;
  builder: builder.md, CLEANUP.md, MARKERS.md; rin: review-with-rin, rin.md; qa:
  dispatch-qa-walk, qa.md; shaper: shaper.md). Không có thì in "chưa có mục nào trỏ về vai này".
- Chân trang vai: link nguyên văn tới file contract trên GitHub (`harness/.claude/agents/<id>.md`)
  và các skill page liên quan.

Content writer: `site/src/content/roles/<lang>/<id>.md`, frontmatter `title`, `tagline`,
`sessionTag` (Anh, giữ nguyên từ SVG), body: `## does` (danh sách hoặc đoạn), `## may` (danh
sách "được"), `## may-not` (danh sách "không được"). Nguồn bắt buộc: `harness/.claude/agents/<id>.md`,
`harness/.agents/roles/<id>*.md`, README mục roles, `docs/adr/0001`. Không bịa quyền hạn.

## 4. Caption và headline (writer), file `site/src/content/landing/<lang>.yaml`

```yaml
hero:
  headline: "…"      # 2 dòng, ≤ 12 từ
  sub: "…"           # 1 câu
  primary: "Xem nó chạy"
  secondary: "Cài cho repo của anh em"
sections:
  roles:   { headline: "…", sub: "…" }
  lifecycle: { headline: "…", sub: "…" }
  tracker: { headline: "…", sub: "…" }
  arm:     { headline: "…", sub: "…" }
  evidence: { headline: "…", sub: "…", cta: "Mở cuốn sổ" }
  limit:   { headline: "…", sub: "…" }
stages:
  claim: "…"         # 1 dòng mỗi chặng, 7 chặng
  brief: "…"
  build: "…"
  code-review: "…"
  simplify: "…"
  arm: "…"
  merge: "…"
roleCards:
  thomas: "…"        # 1 dòng mỗi vai
  shaper: "…"
  builder: "…"
  rin: "…"
  qa: "…"
```

Giọng như đợt 2: "mình", "anh em"; Anh: "I". Không từ dạy/học.

## 5. Frontend

- Component `InteractiveDiagram.astro`: props `slug`, `hrefMap: Record<nodeId, href>`,
  `activeId?`. Nhúng SVG inline (đã có Diagram.astro làm nền), gắn vanilla JS: với mỗi
  `g[data-node-id]` có trong hrefMap → cursor pointer, hover thêm class `is-hover` (stroke
  `--pass`, stroke-width 2), click → `location.href`; Enter trên focus cũng vậy. Tooltip mono
  từ `data-node-sublabel` và `data-node-tag`. Node không có trong map: không đổi gì.
- Hero diagram: cùng SVG, `pointer-events: none`, opacity 0.9, max-width 520.
- Section: padding-block 5rem, xen kẽ nền. Headline h2 36px, sub 20px muted, max-width 620.
- Mobile: diagram cuộn ngang trong khung; 5 thẻ vai là fallback.
- Nav thêm mục "Vai" (`/vai/thomas`)? Không. Nav giữ 5 mục; vai đi từ trang chủ và từ
  `/kien-truc`.
- Nghiệm thu bằng browser thật: hover node Builder sáng, click Builder ra `/vai/builder`,
  trang vai có node Builder sáng sẵn và ít nhất một DefectCard.
