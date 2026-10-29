# Đề xuất flow UI/UX cho Astragentic — bản thảo luận 2026-10-29

Trạng thái: **đề xuất, chưa mục nào được owner gật.** Mục nào được gật thì chuyển sang
`2026-10-29-ui-ux-gate-backlog.md` § Đang bàn. Mỗi mục mang `số | nguồn`; chưa có số ghi `chưa đo`.

Nguồn nghiên cứu (cùng ngày, cùng thư mục): `2026-10-29-research-design-standards.md` (chuẩn tài liệu
và token), `2026-10-29-research-ux-methods.md` (phương pháp UX cho agent),
`2026-10-29-research-ui-skills.md` (skill, plugin, MCP). Số đo nizzy: bảng cuối file backlog.

Trong tài liệu này **"router"** là vai Thomas trong harness (pane điều phối), không phải người viết.

## 0. Ba câu kết luận

1. **UI và UX là hai tầng, không chung công cụ.** UI gate là kiểm máy có exit code, mod đọc ở
   `tool.call` và ở merge. UX là "ai nhìn màn hình nào ở trạng thái nào", người hoặc LLM phán ở
   những thời điểm có tên. Không công cụ nào trong khảo sát làm được cả hai; cái duy nhất ngồi giữa
   là guard script của chính project (nizzy có 3).
2. **Thế giới đã có một chuẩn tài liệu cho UI, chưa có cho UX.** `DESIGN.md` theo spec Google: 28.6k
   star, 390,741 lượt tải npm một tuần, lint/diff/export có exit code, được Stitch, Impeccable, BMAD,
   Bolt đọc. Cho UX: không có schema chung, không linter; thứ gần nhất có adoption là Given/When/Then
   trong ticket (Spec Kit 143.7k star, OpenSpec 73.3k, BMAD) và journey có nhân vật tên thật (BMAD).
3. **Lỗi UI thật của nizzy nằm ở ô mà mọi linter đang trống.** 65/209 ticket UI 45 ngày là sửa
   affordance (link, nút, modal, glance). Impeccable detect tìm được 1 finding, Hallmark bắt được phần
   token và a11y nhưng không bắt link affordance, zero-primary, glance, trạng thái. Chỗ trống đó chỉ
   lấp được bằng (a) actor + trạng thái trong ticket và (b) guard script theo rule của chính anh.

## 1. Chuẩn tài liệu: một spine, một từ vựng

| Quyết | Số | Nguồn |
|---|---|---|
| `DESIGN.md` theo spec Google là spine duy nhất về UI | 28,626 star, 390,741 tải/tuần (21–27/10), lint 11 rule, `diff` có cờ `regression` | research-design-standards §1 |
| Không có `EXPERIENCE.md` | owner quyết 2026-10-29; 0 lần Read trên nizzy | backlog mục 1 |
| Từ vựng token: tên khuyến nghị của spec (`primary`, `on-surface`, `error`, `headline-*`, `body-*`, `label-*`) là normative trong harness | spec nói các tên này non-normative; không chuẩn nào trong 4 (DTCG, M3, shadcn, DESIGN.md) định nghĩa `status.*` hay `text.link` | research-design-standards §7 |
| Bổ sung nhóm thiếu bằng token contract của anti-slop, đặt tên theo quy ước spec: `status-<level>`, `status-<level>-container`, `link`, `link-hover`, `link-pressed`, `row-hover` | contract hiện có trong `references/token-contract.md` của skill | anti-slop |
| Sidecar cho thứ 8 property component không chứa (shadow, motion, focus ring) | impeccable dùng `.impeccable/design.json` vì lý do này | research-design-standards §1 |

Hệ quả cho nizzy: file `docs/stakeholder/design-guidelines/DESIGN.md` (1211 dòng, 0 token YAML)
giữ phần prose và ruling, nhưng frontmatter token phải được kéo từ `apps/dashboard/src/index.css`
(46 CSS var). Map 46 var vào 5 nhóm schema: **chưa đo**.

## 2. UX vào ticket: mở rộng rule Glance, không thêm artefact mới

Owner đã ra rule Glance ngày 2026-10-28 (`.claude/rules/ui-glance-map.md` trên nizzy) với bảng vai
trò: Shaper viết, router kiểm lúc dispatch ("no section = no dispatch"), Builder gọi anti-slop,
bmad-ux soát từng dòng, QA walk theo ghế. Đề xuất mở rộng đúng mục đó thành **UX contract của
ticket**, ba phần, tất cả đọc được bởi người và LLM, không cần tool mới:

```markdown
## Glance (ai thấy gì trước, mỗi màn hình)
- **<Màn hình / trạng thái>:** <vai trò> phải thấy <X> trước; <Y> lùi lại.

## States (mỗi màn hình đã nêu ở Glance)
| Màn hình | empty | loading | error | partial | permission-denied |
(ô ghi cách xử lý hoặc `n/a — vì sao`)

## Criteria có trạng thái (chỉ khi trạng thái quyết định đúng/sai)
1. **<Hành vi>** — Given <trạng thái trước> · When <một hành động> · Then <quan sát được>
```

| Phần | Nguồn phương pháp | Adoption | Ai viết / ai kiểm / ai đọc |
|---|---|---|---|
| Glance | anti-slop Step 0 + R2; owner ruling 2026-10-28 | rule đã chạy trên nizzy từ 28/10 (chưa đếm ticket) | Shaper / router / Builder, bmad-ux, QA |
| States | Hurff "UI stack" 5 trạng thái; BMAD State Patterns (empty, cold-load, error, offline, permission-denied); anti-slop R8 | BMAD 54.7k star | Shaper / router / Builder, QA walk (checklist "loading, empty, error, permission-denied" đã có trong `qa.md`) |
| Given/When/Then | Gherkin; Spec Kit, OpenSpec, BMAD PO ticket template | 143.7k / 73.3k / 54.7k star | Shaper / router / Builder (tdd đọc thẳng), QA verify |

Chỗ cắm trong harness: `to-tickets` template của Matt chỉ có "What to build" + acceptance
criteria (`to-tickets/SKILL.md:73-100`); Shaper contract thêm ba phần này vào thân ticket cho mọi
ticket chạm surface; brief của router chép nguyên (`dispatch-ticket/SKILL.md` § The brief). Actor
đã có sẵn ở spec (`to-spec` "As an <actor>"), chỉ cần kéo xuống dòng Glance.

**Không cần Sally đứng trong Shaper** để làm việc này: ba phần trên là việc của Shaper với spec
trong tay. `bmad-ux` giữ vai advisor như contract hiện tại.

### 2a. Actor và user story nằm ở đâu (owner hỏi 2026-10-29; **quyết: theo BMAD**, backlog mục 2)

Hai mức actor, hai chỗ ở:

| Mức | Hôm nay | Số | Chỗ ở đề xuất |
|---|---|---|---|
| Story theo feature: "As an <actor>, I want…, so that…" | `to-spec` của Matt viết, danh sách dài có số | `to-spec/SKILL.md:31-41` | giữ nguyên, Shaper phase Spec |
| Actor trong ticket | `to-tickets` bỏ: template chỉ What to build / Blocked by / criteria | `to-tickets/SKILL.md:44`, research-ux-methods:182 | mục Glance của ticket mở đầu bằng actor; dòng Given của GWT mở đầu bằng actor (§2) |
| Dàn nhân vật cố định của sản phẩm (operator, seller, admin; thiết bị, áp lực thời gian) | harness: không có. nizzy: rải ở anti-slop Step 0, DESIGN.md §0/§6 prose, rule ui-glance-map | 3 chỗ, không chỗ nào máy đọc | **chưa có chuẩn thế giới**: DESIGN.md Google 8 section không có section Users (research-design-standards:20); BMAD PRD "Target Users", impeccable PRODUCT.md "Users", Spec Kit per-feature. Đề xuất: một block `## Actors` trong PRD của project (quy ước BMAD), `to-spec` đọc nó qua phase Align để tên actor không đổi giữa các spec |

Chưa đo: trên nizzy, các spec `to-spec` đã viết có dùng cùng tên actor không (đếm tên actor
trong "As a …" qua các spec).

## 3. UI gate theo tầng: cái gì máy kiểm được, cái gì không

Ma trận phủ, đo trên nizzy `apps/dashboard/src/{screens,components}` (609 file) ngày 2026-10-29:

| Rule anti-slop (lỗi thật của nizzy) | design.md lint | impeccable detect (62 rule) | Hallmark sloplint (static) | taste inspect --app | guard nizzy | axe / pa11y |
|---|---|---|---|---|---|---|
| R1 label vs value | — | — | 67 tracked-caps label (15 hit), 64 mono as costume (6) | chưa đo | — | — |
| R1b empty marker | — | — | — | — | — | — |
| R2 glance | — | — | — | — | — | — |
| R3 màu chỉ theo token | — | design-system-color (cần DESIGN.md có token) | 48 colour literal (1), 74 palette class thay token (1, `badge.jsx` bg-red-100) | — | — | — |
| R4 link nhìn ra link | — | — | 63 arrow glued to link (12) chỉ nửa copy | — | rowOpenItemGuard (một phần) | — |
| R6 show status, don't hide | — | — | — | — | — | — |
| R7 money action | — | — | — | — | — | — |
| R7b một Primary, không Ghost | — | — | F4/F15 ">1 primary" (finish, không chặn) | — | buttonRoleGuard, buttonGhostGuard | — |
| R8 states | — | — | — | — | — | — |
| R10 copy | — | marketing-buzzword, em-dash-overuse | 19 copy tells (43 hit, trên nizzy là dấu "—") | — | — | — |
| a11y floor (focus, reduced-motion, contrast) | contrast-ratio trên token | low-contrast | 26a focus-visible (9), 27 reduced-motion (4) | — | — | WCAG 2.x A/AA một phần |

Đọc ma trận:

- **Hàng trống hoàn toàn**: R1b, R2, R6, R7, R8. Đó là 5 trong 10 rule, và là nơi 65 ticket sửa UI
  rơi vào. Không linter nào ngoài kia kiểm được; chỉ ticket (§2) và guard script của project lấp.
- **Hallmark** bắt được thật: focus-visible thiếu toàn bộ (9 file), reduced-motion thiếu (4), label
  uppercase 12px (15), palette class qua mặt token (1). Nhưng: 148 finding của nó có 43 là dấu "—"
  trong copy; Floor của nó là **không waive được** và chứa rule trang marketing (58 "80 từ một màn",
  44d "container cap 1360–1520 và căn giữa") đối đầu ruling "fluid full-width LOCKED" của nizzy;
  `--scope app` không lọc rule (148 cả hai lần); chỉ có `--tier floor`, không có cờ chọn gate. Dùng
  được **chỉ khi harness lọc JSON của nó theo danh sách gate** (10a, 26a, 26b, 27, 48, 63, 67, 74,
  F4), không dùng grade FAIL tổng.
- **impeccable detect** 1 finding/609 file: không phải nizzy sạch, mà 62 rule của nó là slop
  marketing. Bốn rule `design-system-*` của nó chỉ chạy khi DESIGN.md có token (§1).
- **taste-skill**: `lint.mjs` ra 272 FAIL trên nizzy nhưng chính `app-screens.md` của nó nói hairline,
  label nhỏ, panel lặp là bình thường ở app screen; số đó là nhiễu. `inspect.mjs --app` là tool đúng,
  cần Chrome đang chạy: **chưa đo**.
- **design.md lint**: 0 token để lint trên nizzy hiện tại; có giá trị ngay khi §1 xong, và `diff
  --regression` là gate token-drift duy nhất có sẵn.

Đề xuất bốn tầng gate, mỗi tầng một exit code, mod đọc được:

| Tầng | Lệnh | Exit | Mod làm gì | Khi nào |
|---|---|---|---|---|
| G1 spec | `npx @google/design.md lint DESIGN.md`; `diff <base> <head>` | lint 1 lỗi; diff 1 regression | **từ chối** commit đụng DESIGN.md khi lint lỗi hoặc diff regression | commit chạm `DESIGN.md` |
| G2 code | Hallmark `sloplint --json` lọc theo danh sách gate harness chọn | tự tính từ JSON | **ghi chú** trên record, chip trên band; từ chối chỉ với 26a/27 (a11y floor) | commit chạm file UI |
| G3 project guard | `.astraler/project/ui-guards/*.js` (mẫu: 3 guard nizzy) | mỗi guard 0/1 | **từ chối** theo plug của project | commit chạm file UI |
| G4 render + a11y | axe (`--exit`), pa11y (exit 2), Lighthouse CI assert | 1 / 2 / non-zero | **ghi chú** ở merge; QA walk đọc | station lúc merge, cần dev stack |

Hiện trạng để so: mod từ chối 2 bước (test file, arm) và 3 tool; `bmad-ux` chỉ ghi chú; 101/202
ticket UI bỏ qua UX audit không ai thấy. Bốn tầng trên là lần đầu UI có một từ chối.

### 3a. Đính chính 2026-10-29 (sau khi viết §3): nizzy đã có gate UI hai tầng

> **Rút lại cùng ngày (owner):** "rubric 2 tầng" và `frontend-gate-rubric.md` là khuôn tự chế của
> nizzy (một agent viết 2026-07-16, "distilled from DESIGN.md"), không có ở chuẩn nào ngoài kia.
> Owner ruling: bám chuẩn thế giới để nâng cấp theo thế giới; cái không chuẩn thì bỏ, không bê lên
> harness. Mục này giữ làm **bằng chứng lỗi nào lặp** (14 rule L1, 8 rule §B cho biết nizzy đã vấp
> gì), không làm mẫu. Phần "Hệ quả cho đề xuất" bên dưới **không còn hiệu lực**; thay bằng §3b.

### 3b. Thay thế bằng chuẩn có người ngoài bảo trì

| Việc nizzy tự chế | Chuẩn thế giới làm cùng việc | Ai bảo trì | Số |
|---|---|---|---|
| DESIGN.md 1211 dòng prose | DESIGN.md spec Google: frontmatter YAML token + 8 section prose ngắn, AI đọc thẳng | google-labs-code | 28.6k star, 390k npm/tuần |
| `design-lint/scan.mjs` 14 rule trong vitest (vì repo không có ESLint) | ESLint + plugin Tailwind, Stylelint cho CSS; `design.md lint/diff` cho token | ESLint/Stylelint/Google | eslint-plugin-tailwindcss: **chưa đo** rule nào khớp 14 rule |
| Rubric §B 8 rule LLM đọc trong `/code-review` | Không có chuẩn. Gần nhất: `/code-review` built-in đọc DESIGN.md (ngắn theo spec) + rule trong `.claude/rules/` | Anthropic | spec DESIGN.md 8 section |
| 3 guard `src/design-system/` | cùng hàng ESLint rule (custom rule local) | ESLint | — |
| Token: 46 CSS var tên tự đặt | tên khuyến nghị của spec DESIGN.md; export DTCG (W3C 2025.10) | Google / W3C DTCG | — |
| Trạng thái màn hình, actor | Gherkin Given/When/Then trong ticket | Spec Kit / OpenSpec / BMAD | 143.7k / 73.3k star |
| a11y | WCAG 2.x qua axe/pa11y | Deque / W3C | — |

Lý lẽ "LLM không nên đọc cả DESIGN.md vì đắt" (FW-025 của nizzy) chỉ đúng với file 1211 dòng;
DESIGN.md theo spec ngắn, và đó là lý do spec tồn tại. Mất projection file, mất rubric, còn một file.


Ma trận trên đếm "guard nizzy" là 3 script trong `src/design-system/`. Thiếu. nizzy có sẵn:

| Thứ có sẵn | Số | Nguồn |
|---|---|---|
| `docs/stakeholder/design-guidelines/frontend-gate-rubric.md` — projection của DESIGN.md, 2 tầng: §A máy kiểm (L1), §B LLM đọc trong `/code-review` (L2) | 185 dòng, §B 8 rule | file đó, verified 2026-07-16 |
| `apps/dashboard/design-lint/scan.mjs` — L1, chạy trong `pnpm -r test`, baseline ratchet | 14 rule id, baseline 6 violation còn nợ | `grep id: scan.mjs`, `baseline.json` |
| Guard khác cùng cơ chế: `url-state-guard`, `role-string-guard`, `prod-build-guard`, 3 guard `src/design-system/` | 6 bộ | `ls apps/dashboard` |
| Dòng gọi tất cả guard khi diff chạm dashboard | 1 dòng trong overlay dispatch-brief | `.astraler/project/overlays/dispatch-brief.md:11` |
| `frontend-implement` skill (TS/React standards, 15 rule, D2 = design-lint) / `golang-implement` | 277 / 508 dòng; Skill tool gọi 24 / 13 lần | `.claude/skills/*/SKILL.md`, transcript nizzy |

14 rule L1: no-hex-literal, no-arbitrary-color-value, no-raw-status-palette, no-forbidden-palette-family,
no-black-white-class, no-emoji, no-arbitrary-text-size, no-disallowed-text-size-token,
no-banned-font-weight, no-invalid-button-size, no-button-height-override,
no-hand-rolled-destructive-button, no-raw-table, no-arbitrary-thumb-size.

Hệ quả cho đề xuất:

- **G3 không phải tầng mới**: nizzy đã có nó, dưới dạng vitest + baseline, gọi bằng một dòng prose
  trong overlay. Việc harness cần làm là cho mod **đọc exit của bộ guard đó** khi commit chạm UI,
  thay vì tin Builder đã chạy. Mẫu `.astraler/project/ui-guards/` nên là hợp đồng "một lệnh, một
  exit", để nizzy trỏ `npx vitest run design-lint/ …` vào đó, không viết lại.
- **L2 §B của rubric chính là chỗ anti-slop R1–R10 nên đứng**, vì nó đã được `/code-review` đọc
  (có đường chạy), còn anti-slop thì 0 lần gọi. Hàng trống R1b/R2/R6/R7/R8 trong ma trận là rule
  LLM-judge, đúng dạng §B. Harness generic hoá khuôn "rubric 2 tầng, projection của DESIGN.md" chứ
  không bê rule nizzy lên.
- Ma trận cột "guard nizzy": R3 có `no-hex-literal`/`no-raw-status-palette`/`no-arbitrary-color-value`;
  R7b thêm `no-hand-rolled-destructive-button`/`no-invalid-button-size`; R1 có `no-emoji`,
  `no-banned-font-weight`. Hàng trống vẫn là R1b, R2, R6, R7, R8.
- **Chưa đo**: 6 violation baseline là gì; bao nhiêu trong 65 ticket sửa UI thuộc 14 rule L1 hay 8 rule
  §B; L2 §B có thật được `/code-review` đọc trong Builder pane không (đếm transcript).

## 4. Bộ skill: giữ, đổi vai, không dùng

| Skill | Vai đề xuất | Lý do có số | Byte nạp |
|---|---|---|---|
| `astraler-ui-anti-slop` | **house rule set**, viết lại tên token theo §1, gọi ở mốc "trước khi viết code UI" của Builder (rule Glance đã đặt mốc này) | 0 lần gọi từ khi viết; nội dung 10 rule có số đo, 228 dòng lessons từ review thật | 16k + refs 20k |
| `frontend-design` (Anthropic, đã cài 1.1.1) | nạp cùng anti-slop cho ticket tạo surface mới; không gate | prose, 5 cụm default tránh; 184.5k star repo | 9.4k |
| `bmad-ux` (Sally) | advisor sau code như hiện tại; đọc Glance + States của ticket thay vì EXPERIENCE.md | 101/202 gọi; contract đã nói "impeccable là executor" | 3.6k |
| `impeccable` | **chỉ khi có người ngồi** (BA pane, owner session) để dựng DESIGN.md và direction; không bao giờ trong pane dispatch | init/shape/critique phỏng vấn; comp-led chờ browser 30 phút; ≈140k byte so trần 200k; hook không deny | 12k + 63k new-work |
| Hallmark | **chỉ linter** (G2); không dùng flow build, không cài `install-hook` (trùng mod) | Floor không waive, có rule marketing | script, 0 byte prompt |
| `ui-ux-pro-max` | tra cứu khi Shaper cần pattern; không gate | query "ops dashboard" trả "Hero + Features + CTA" | 16k |
| design.md CLI | G1 | 11 rule, exit code, 390k tải/tuần | 0 |

## 5. Flow đầy đủ, theo pane

```
Shaper (align → spec → arm → test-design → tickets)
  spec: user stories "As an <actor>"            (có sẵn, to-spec)
  tickets: + Glance / States / Given-When-Then  (§2, mới)  ← ticket UI không có = không cắt
  DESIGN.md: Shaper không viết; thiếu token nhóm nào → ticket "token" riêng, G1 kiểm

Router (dispatch)
  đọc label quick/full (có sẵn) + kiểm 3 phần UX có mặt (rule Glance, có sẵn trên nizzy) → chép vào brief

Builder (implement)
  trước code UI: Skill(astraler-ui-anti-slop) [+ frontend-design nếu surface mới]
  commit chạm DESIGN.md → G1 (từ chối)
  commit chạm UI → G2 ghi chú + G3 từ chối theo plug
  bmad-ux audit: soát từng dòng Glance/States trên màn hình đã render (như hiện tại, có chuẩn để so)
  handback: bằng chứng theo Glance (viewport, thấy gì), như rule 2026-10-28

Station (merge)
  G4 axe/pa11y/lhci → ghi chú; "merged with no record of" nay có thêm G1–G3

QA walk
  ngồi ghế vai trò trong Glance; checklist states đã có trong qa.md
```

## 6. Lộ trình nizzy (thứ tự đo trước, làm sau)

1. Map 46 CSS var → 5 nhóm schema; đếm thiếu. **chưa đo.**
2. Chạy `taste inspect --app` và Hallmark `--render` trên dev stack nizzy; đếm theo gate. **chưa đo.**
3. 65 ticket sửa UI đối chiếu R1–R10 và 3 guard: bao nhiêu guard-able. **chưa đo.**
4. 101 ticket bỏ bmad-ux: bao nhiêu có ticket sửa cùng surface sau đó. **chưa đo.**
5. `skills_run` của `bmad-*` từ 2.19.0. **chưa đo** (nợ từ 2.19.0).

## 7. Không đề xuất, và vì sao

- **EXPERIENCE.md**: owner đã bỏ. Ghi nhận: BMAD main hiện viết nó và có rubric coverage; nội dung
  actor/state/flow của nó được đưa vào ticket (§2) thay vì file riêng. Mở lại là quyết định của owner.
- **impeccable trong pane dispatch**, **Claude Design `/design-sync`** (React-only, "vài giờ", standalone
  đóng 14/12/2026, không có gate), **taste page-run trên dashboard**, **Hallmark flow build**: lý do ở §3–§4.
- **Role UX mới trong Shaper**: ba phần §2 là việc của Shaper; thêm vai mới chưa có số nào nói cần.

## 8. Quyết định chờ owner

1. §1 từ vựng token: lấy tên khuyến nghị của spec làm normative, bổ sung `status-*` / `link*`.
2. §2 ba phần UX trong ticket, ticket UI thiếu thì Shaper không cắt.
3. §3 G1 từ chối, G3 từ chối theo plug, G2/G4 ghi chú.
4. §4 vai của từng skill; đặc biệt impeccable chỉ khi có người ngồi.
5. Có mở lại EXPERIENCE.md sau khi biết BMAD main viết nó hay không.

## 9. `astragentic doctor` — khám toàn scaffold, không chỉ design (owner gợi ý 2026-10-29, chưa gật)

Owner: "Doctor còn khám bịnh nhiều cái khác chớ không phải mỗi cho design." Phạm vi là **toàn bộ
những gì harness cần để một pane chạy được**, chia nhóm; design là một nhóm trong đó.

| Nhóm | Dòng khám | Nguồn lỗi đã gặp |
|---|---|---|
| Harness | `applied-version` khớp release có thật (tag `v*`); 18 plug `.astraler/project/*` có mặt, `+x`, chạy `--selftest`/no-arg ra exit 0; overlays đọc được; `not-a-skill.txt` không trỏ file đã mất | tag 4.0.0 không `v`; 4.1.0 lộ 4 defect sau apply |
| Mod | plugin `astragentic-dispatch` nạp được trong Claude Code đang cài (version tối thiểu); `hooks.json` hợp lệ; `dispatch-record.json` parse được, không giữ lane đã chết | 4.3.2 vỡ apply; held-stale bell |
| Tracker | `tracker.sh` trả về trong N giây với token hiện có; nhãn quick/full tồn tại trên tracker | UNVERIFIED unreachable tracker 3.2.x |
| Worktree / tiến trình | không worktree mồ côi, không tiến trình giữ port của worktree đã xoá; `cleanup-worktree.sh`/`setup-worktree.sh` chạy khô được | reap-worktree-processes.sh ra đời vì việc này |
| Dev stack | portless route khớp port framework; compose stack khai trong `shared-compose-projects` lên được | 502 do lệch port (CLAUDE.md máy) |
| Test contract | `test-command-pattern`, `test-file-pattern` match ít nhất một file/lệnh thật trong repo | gate tdd từ chối sai khi pattern lệch |
| Herdr / watchdog | herdr trả lời; `watchdog-probe.sh` exit 0; log watchdog không có lỗi lặp | herdr deaf-wait |
| Design (mục trước) | `design.md lint/diff`; `components.json` schema; `eslint`/`stylelint --print-config`; axe khi stack chạy; plug ticket UI | §3b |

Nguyên tắc giữ nguyên: mỗi dòng gọi checker **đã có** (của chuẩn hoặc của chính harness: `tracker.sh`,
`watchdog-probe.sh`, `check-reachability.py`), doctor chỉ gom và in ✓/✗, exit 1 khi có ✗. Không
viết checker mới trong doctor.

Hiện trạng: `.astraler/astragentic.sh` phía project chỉ có `update | update --apply | version`
(nizzy `.astraler/astragentic.sh:42-44`). Mod đọc 18 plug `.astraler/project/*` (grep `register.tsx` +
`scripts/`), không có bước nào kiểm plug có mặt và hợp lệ. `selftest.sh` 2277 dòng chạy ở upstream,
không chạy ở project. Ba lần apply gần nhất phát hiện lỗi bằng tay: 4.1.0 trên nizzy lộ 4 defect
(→ 4.1.1), 4.3.2 vỡ vì tie cùng ms, tag 4.0.0 không có `v` nên nizzy không thấy (memory 2026-10-17/18/22).

Khuôn: `claude doctor`, `brew doctor`, `flutter doctor`: mỗi dòng một thành phần, ✓/✗, exit 1 nếu có ✗.
Doctor **không viết checker mới**; mỗi dòng gọi checker của chuẩn đó:

| Thành phần | Checker | Exit |
|---|---|---|
| Harness: version, 18 plug, overlays, mod nạp được | `astragentic.sh version`; test -x/-f từng plug; `node register.tsx --selftest` nếu có | 0/1 |
| DESIGN.md theo spec | `npx -y @google/design.md lint DESIGN.md` | 0/1 |
| Token drift so với release trước | `design.md diff <base> <head>` | regression flag |
| Lớp component | `components.json` có và `npx shadcn diff`/schema | 0/1 |
| Rule máy trên code | `eslint --print-config` ra config; `stylelint --print-config` | 0/1 |
| a11y | `axe --exit` trên URL dev (khi stack chạy) | 0/1 |
| Ticket UI contract | plug `ui-ticket-sections` có mặt, mod đọc được | 0/1 |

Gọi từ: `astragentic.sh doctor` (tay, sau apply), `get.sh --apply` bước cuối, mod `session.start`
(chip trên band khi ✗). Ba nơi gọi, không mồ côi. **Chưa đo**: nizzy và inception hôm nay ✗ bao nhiêu
dòng (ước từ bảng §3b: inception ✗ DESIGN.md, Stylelint, ui-guards; nizzy ✗ DESIGN.md spec, ESLint, Stylelint).

## 10. Bỏ Matt Pocock — tính toán (owner nêu 2026-10-29, "đang tính", chưa quyết)

Owner: "đang tính bỏ luôn matt-pocock, vận hành thiết kế theo cách chúng ta thì hợp lý hơn."
Hai quyết định tách nhau vì số đo tách nhau: lớp Shaper (spec/ticket) và lớp Builder (gate).

### 10.1 Matt đang làm gì trong harness

| Skill | Dung lượng | Harness nhắc | Mod `register.tsx` | Gọi nizzy / inception | Thay bằng |
|---|---|---|---|---|---|
| `implement` | 622 byte: "fetch ticket, call tdd, run tests, call code-review, commit" | 37 | 5 dòng, trong đó 4 là regex `^/mattpocock-skills:implement` **nhận diện brief Builder** | 0 Skill call (là prefix prompt) | prefix brief của harness; nội dung đã nằm trong builder.md |
| `tdd` | 3.6k + tests.md 2.2k + mocking.md 1.5k (seam, anti-pattern, red trước green) | 38 | 11 dòng; `tddCalledAfter` khoá tên literal `mattpocock-skills:tdd` | 224 / 111 | BMAD `dev-story` bước 5 (RED/GREEN/REFACTOR) đã distill; gate đo test file + RED run (4.1.0, 4.5.2) không cần tên skill |
| `code-review` | 6.7k, 2 trục Standards (Fowler smells) + Spec, 2 subagent | 29 | 4 dòng chip | 272 / 130; nizzy 679 subagent spawn; 35 handback có dòng `## Spec` nêu thiếu/lệch | BMAD `code-review` đã distill: Blind Hunter + Edge Case Hunter + **Acceptance Auditor** (= trục Spec); built-in `/code-review` chỉ correctness |
| `to-spec` | 3.0k, user story "As an <actor>" | 2 | 1 dòng chip | 6 / 5 | BMAD `prd` → `create-epics-and-stories` (owner đã chọn BMAD cho actor, backlog mục 2) |
| `to-tickets` | 5.8k: vertical slice, prefactor, expand–contract, tiêu chí | 5 | 1 dòng chip | 3 / 4 | BMAD `create-epics-and-stories` bước 3 (story 1 agent 1 phiên, không phụ thuộc tới, GWT) + 3 mục UI (A3) |
| `grill-with-docs` | 247 byte | 4 | 1 dòng chip | 0 / 0 | BMAD `advanced-elicitation` / phase Align hiện có |
| `grilling`, `domain-modeling`, `writing-for-agents`, `wizard`, `diagnosing-bugs` | — | 0–1 | 0 | 9+9+2+1 / 6+6+1+2 | công cụ cá nhân của owner, không nằm trong flow; giữ hay bỏ không ảnh hưởng harness |

Tổng: 125 chỗ nhắc `mattpocock-skills:` trong 22 file harness; mod 23 dòng. Downstream: nizzy 50 chỗ /
2 file, inception 50 / 4 file, đều trong overlay project tự sở hữu (chi phí của project, release note
chỉ nêu thay đổi).

### 10.2 Hai quyết định, giá riêng

**(a) Lớp Shaper: `to-spec` + `to-tickets` + `grill-with-docs` → BMAD.** Gọi 9 / 9 lần hai project,
harness nhắc 11 chỗ, mod 3 dòng chip. Thay bằng chuỗi BMAD đã distill (`prd` → `create-epics-and-stories`
→ `create-story`), cộng 3 mục UI. Đây đúng là "vận hành thiết kế theo cách mình", và khớp mục 2 đã quyết.
Rủi ro thấp: không gate nào của mod phụ thuộc. Mất: quy tắc expand–contract cho wide refactor của
`to-tickets` (5.8k) — chép lại một đoạn vào skill ticket của harness nếu cần.

**(b) Lớp Builder: `implement` + `tdd` + `code-review` → BMAD `dev-story` + `code-review`.** Gọi
~500 / ~240 lần, harness nhắc 104 chỗ, mod 20 dòng. Hai bẫy phải đi cùng release, mỗi bẫy một case selftest:

1. `register.tsx:1636,1655,1692,1716` nhận diện brief Builder bằng regex `^/mattpocock-skills:implement`.
   Đổi prefix brief mà không đổi regex → không có `last_brief_received_at` → mọi gate Builder lặng im.
   Selftest: brief prefix mới vào regex cũ, phải thấy không phân loại được.
2. `tddCalledAfter` (dòng 95) khoá literal `mattpocock-skills:tdd`. Gỡ plugin → trả null → **100% từ chối**
   ở commit nội dung đầu. Đề xuất theo đúng comment 4.1.0 "gate đo test, không đo skill call": bỏ kiểm tên
   skill, giữ test file + RED run. Gate nhỏ hơn, hợp rule không thêm meta-machinery. Quyết của owner.

Mất gì ở (b): trục Spec của Matt (35 handback có finding thiếu/lệch trên 272 lần gọi nizzy) → BMAD
Acceptance Auditor làm cùng việc, và QA chain đã có trace matrix spec→bằng chứng (qa.md:139). Built-in
`/code-review` không có trục này. Skill `verify` của Claude Code **không có trên máy** (ls skills) → không
dựa vào.

### 10.3 Chưa đo

- Token thật của 679 subagent spawn Matt code-review trên nizzy (`usage-report.py`/ccusage theo session) —
  không viết "tiết kiệm" khi chưa có số.
- Trong 35 finding trục Spec, bao nhiêu dẫn tới sửa code (đối chiếu commit sau handback).
- Dung lượng BMAD `dev-story` + `code-review` nạp một phiên so với 20k byte của Matt; distill hiện
  5.5k + 5.8k = 11.3k.
- Tỷ lệ RED run thật sau gate 4.5.2 (đã log, chưa tổng).

### 10.4 Quyết hướng 2026-10-29: bộ skill `astra-*`, triết lý BMAD, độ gọn Matt

Owner: Matt có hạn chế (ticket không actor/state, review 2 trục cứng, grill quá mỏng), BMAD rườm rà
(story file, sprint-status.yaml, HALT từng bước) nhưng triết lý sản xuất đúng. Viết lại năm skill của
harness, mỗi skill ghi rõ lấy gì từ đâu, và **dung lượng không vượt skill Matt tương ứng**:

| Skill mới | Lấy từ Matt | Lấy từ BMAD | Bỏ của BMAD | Mốc mod |
|---|---|---|---|---|
| `astra-grill-with-docs` | hỏi tới cùng, đọc docs trước khi hỏi (247 byte) | advanced-elicitation; brain dump trước, "elicitation, not direction"; stakes calibration | menu, memlog | chip `align` |
| `astra-to-spec` | spec ngắn, user story đánh số | PRD: UJ-N journey nhân vật có tên, persona inline; FR id ổn định; UX-DR tách mục | addendum, reviewer gate nhiều tầng | chip `spec`; đọc PRD project |
| `astra-to-tickets` | vertical slice, prefactor, expand–contract, tracer bullet | story `As a {user_type}` + GWT; 1 agent 1 phiên; không phụ thuộc tới; coverage map FR→story | epics.md, sprint-status.yaml | chip `tickets`; ticket UI phải có Glance/States/Criteria (B6) |
| `astra-implement-with-tdd` | seam pre-agreed, anti-pattern test, red trước green, tests.md/mocking.md | dev-story bước 5–8: RED/GREEN/REFACTOR, "NO LYING" gate, HALT khi cần dependency mới / 3 lần fail | story file regions, Dev Agent Record, sprint sync | **prefix brief mới** (đổi regex 4 chỗ); gate đo test file + RED run, bỏ literal tên skill |
| `astra-review` | 2 trục tách, Fowler smell baseline, không rerank chéo trục | Blind Hunter + Edge Case Hunter + Acceptance Auditor; đọc code trước khi chấm; route patch/defer/dismiss | HALT chờ số, ghi vào story file | chip `review`; **gọi built-in `/code-review` làm một lớp** (correctness), không chạy 2 review riêng như nay |

Trần dung lượng (đo `wc -c`): Matt tương ứng 247 / 3.0k / 5.8k / 7.3k (tdd+refs) / 6.7k = 23k; BMAD
distill 20k. Mục tiêu bộ `astra-*` ≤ 23k tổng. Mỗi skill một bản nháp, owner gật riêng. Cùng release:
regex brief + gate tdd + 2 case selftest (§10.2b).
