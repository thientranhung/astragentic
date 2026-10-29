# Backlog UI/UX trong Shaper và gate UI — thảo luận 2026-10-29, chưa implement

Mỗi mục: `[ ]` chưa làm, `[x]` đã làm (ghi release), `[-]` owner bỏ. Hai cột `số | nguồn` theo
CLAUDE.md. Owner đang bàn; **đã gật mục 1–4; A3, B6, C2, C3, D2 đi 5.0.0 theo mục 4; còn lại chờ**. Không gom thành release cho tới
khi owner gật từng mục.

## Owner đã quyết

- [ ] **1. Bỏ triết lý `EXPERIENCE.md`.** Owner 2026-10-29: "'EXPERIENCE.md' chắc bỏ triết lý này
  nhé." Việc: gỡ `EXPERIENCE.md` khỏi `bmad-ux/SKILL.md` (cả hai bản `.agents` và `.claude`),
  `agents/bmad-sally.md`, `docs/bmad-distilled/capabilities/ux.md`; `DESIGN.md` theo spec Google
  là spine duy nhất.
  Số: 0 Read tool call / 10 Bash chạm trên toàn bộ transcript nizzy; chỉ 3 file trong harness
  nhắc tên nó | transcript `~/.claude/projects/*etsy*`, `grep -rl EXPERIENCE.md harness`.
  Gốc: quy ước của bộ distill `thientranhung/bmad-distilled` (2026-07-08), không có trong BMAD
  upstream (xuất `ux-design-specification.md`).

- [ ] **2. Actor và journey theo BMAD.** Owner 2026-10-29: "đúng theo BMAD đi". Theo BMAD PRD: journey
  "captured, not authored", dạng UJ-N với nhân vật có tên, persona viết inline trong journey, **không có
  section persona riêng**; story `As a {user_type}, I want, So that` + AC Given/When/Then/And; UX-DR là
  requirement hạng nhất. Việc: (a) Shaper phase Align có bước ghi UJ-N vào PRD của project (file đã
  có hoặc `docs/prd.md`), (b) `to-spec` đọc PRD để tên actor giữ nguyên, (c) ticket UI mang actor ở
  Glance và ở Given (mục 2 proposal), (d) UX-DR tách thành mục riêng trong spec.
  Số: nizzy 3 actor nhất quán qua spec (seller 76, system admin 36, dev 15 dòng "As a"), 0 PRD, 0 file
  định nghĩa actor | `grep "As a" docs/ issues/` nizzy; `find -iname "*prd*"`; `bmad-distilled/capabilities/prd.md`,
  `create-epics-and-stories.md`. Lưu ý BMAD: bỏ UJ cho "internal single-operator tools"; nizzy có 3 actor
  nên không rơi vào ngoại lệ đó.
  **Rà BMAD mới (HEAD 61e01f8, 2026-10-18):** UJ-N nhân vật có tên, persona inline vẫn khớp; nhưng ticket không
  còn form `As a {user_type}`, actor chuyển sang FR `[Actor] can …` trong PRD. Giữ `As a` là lựa chọn harness
  (design 5.0.0 §8.6a, chờ gật).

- [ ] **3. Bộ cài astragentic chỉ còn skill `astra-*`.** Owner 2026-10-29: "khi cài bộ astragentic vào thì
  sẽ chỉ toàn skill astra thôi, không có dấu hiệu của bmad hay matt-pocock nữa; mình chỉ dùng chưng cất ra
  cái hay, cái phù hợp." Hệ quả: `bmad-ux` → `astra-ux`, thêm `astra-ui` (phía gate UI), `bmad-party` →
  tên astra hoặc bỏ, 7 persona `agents/bmad-*.md` → tên astra hoặc gộp; hai bộ chưng cất ở `docs/` là
  nguồn, không phải thứ cài vào project.
  Số: harness 26 file nhắc `bmad` (6 role, 5 skill ×2 bản, 7 agent, register.tsx, types, selftest);
  `bmad-ux` gọi 115 lần nizzy / 3 inception; persona spawn: sally 243, reviewer 78, murat 17 | grep harness;
  transcript hai project. Kéo theo D2 (Matt) và D1 (doctor xác nhận không còn tên ngoài).

- [ ] **4. 5.0.0 chốt theo đề xuất (owner 2026-10-29: "theo đề xuất của em").** Chín câu trong design
  `2026-10-29-astragentic-5.0.0-design.md` §8 đều gật: astra-ux ở pane BA, skill riêng · bỏ bmad-party + 4
  persona 0 spawn · GLOSSARY/ADR giữ trong astra-grill-with-docs · doctor tối thiểu trong 5.0.0, doctor 8 nhóm
  5.1 · 5.0.0 = skill + flow + mod + docs + doctor tối thiểu; gate UI B1–B5, mẫu DESIGN.md A1, ESLint B3 đi
  5.1/5.2 · ticket theo BMAD mới: actor ở PRD, Given mở đầu bằng actor, không `As a` · đỏ-trước từ Matt + TEA
  red, "chấm theo diff" từ bmad-build · bỏ UX-DR khỏi astra-to-spec · ticket UI bắt buộc Glance/States/Criteria,
  router từ chối cắt khi thiếu (A3 + B6 vào 5.0.0). Từng SKILL.md vẫn gật riêng khi có nháp.
  Số: 13 việc §9 design; Builder 18.2k → 14.5k byte | design §1, §9.

## Đang bàn, chưa gật

(ghi vào đây khi owner nói "ok" từng mục; mục chưa có số đi vào § Chưa đo)

## Chuẩn bị làm lần này — ghi từ thảo luận 2026-10-29, chờ gật từng mục

Owner 2026-10-29: "ghi lại các tài liệu và tương tác cần ta đã thảo luận về design UI/UX, note vào hệ
thống task chuẩn bị làm lần này." Mỗi mục trỏ về mục proposal (`2026-10-29-ui-ux-flow-proposal.md`)
và có số|nguồn. Thứ tự là thứ tự phụ thuộc, không phải ưu tiên.

### A. Tài liệu tham gia vận hành (ai viết, ai đọc, mốc đọc)

- [ ] **A1. Mẫu `DESIGN.md` theo spec Google** trong `harness/`: frontmatter YAML 5 nhóm token
  (colors/typography/rounded/spacing/components), 8 section theo thứ tự spec. Từ vựng token: tên
  khuyến nghị của spec là bắt buộc, cộng `status-<level>`, `link*`, `row-hover` của harness.
  Số: spec 28.6k star, npm 390k/tuần; nizzy 0 token YAML, 46 CSS var; inception 0 DESIGN.md, 221 CSS var
  | proposal §1, §3b; `design.md lint`; grep index.css.
- [ ] **A2. PRD của project có journey UJ-N theo BMAD** (actor + bối cảnh inline, không section persona).
  Shaper phase Align ghi, `to-spec`/bước spec đọc. Số: nizzy 3 actor nhất quán, 0 PRD
  | backlog mục 2; `bmad-distilled/capabilities/prd.md`.
- [ ] (5.0.0, gật qua mục 4) **A3. Ticket UI mang 3 mục Glance / States / Criteria** (mở rộng rule `ui-glance-map` của nizzy
  lên harness; States = empty/loading/error/partial/permission-denied; Criteria dạng Given/When/Then,
  Given mở đầu bằng actor). Shaper viết, router kiểm lúc dispatch, Builder/bmad-ux/QA đọc.
  Số: template ticket hiện không có actor/screen/state; 65/209 merge UI nizzy là sửa lại
  | proposal §2, §2a; `to-tickets/SKILL.md:44`; git nizzy.
- [ ] **A4. Khuôn "implement skill theo stack"** trong `.astraler/project/`: harness quy định cấu trúc
  và mốc gọi, project điền luật (nizzy đã có `frontend-implement` 277 dòng gọi 24 lần, `golang-implement`
  508 dòng gọi 13 lần; inception `frontend-implement` 190 dòng gọi 2 lần). Không viết skill generic ở harness
  | transcript hai project.
- [x] **A5. Bỏ `EXPERIENCE.md`** (= mục 1 Owner đã quyết). Journey về PRD (A2), trạng thái về ticket (A3).
- [-] Không làm: `frontend-gate-rubric.md` kiểu nizzy, PRODUCT.md, sidecar impeccable, role Sally trong Shaper.

### B. Gate UI, mỗi tầng một exit code, mod đọc

- [ ] **B1. G1 spec**: mod chạy `npx -y @google/design.md lint` và `diff --regression` khi commit chạm
  `DESIGN.md`; **từ chối** khi lint lỗi hoặc token regression. Số: lint 11 rule, exit code có sẵn | proposal §3.
- [ ] **B2. Hợp đồng `.astraler/project/ui-guards/`**: một lệnh, một exit, mod gọi khi commit chạm file UI,
  **từ chối** theo plug. Project trỏ ESLint/Stylelint của mình vào đây. Số: mod hiện từ chối 2 bước + 3 tool,
  0 cho UI | `register.tsx` 7 handler `tool.call`.
- [ ] **B3. ESLint + Stylelint cho mỗi project** thay linter tự chế: 14 rule `design-lint` của nizzy viết lại
  thành rule ESLint (chưa đo: bao nhiêu có plugin sẵn); inception đã có eslint recommended, 0 rule design
  | `design-lint/scan.mjs`; `web/eslint.config.js`.
- [ ] **B4. G2 Hallmark `sloplint --json`** lọc theo 9 gate (10a, 26a, 26b, 27, 48, 63, 67, 74, F4) → ghi chú;
  từ chối chỉ 26a/27 (a11y floor). Số: nizzy 148 finding, 43 là em-dash, 9 focus-visible, 4 reduced-motion
  | `/tmp/ui-linters/hallmark-nizzy.json`.
- [ ] **B5. G4 axe/pa11y ở station merge** → ghi chú, QA walk đọc. Số: WCAG tự động một phần | proposal §3.
- [ ] (5.0.0, gật qua mục 4) **B6. Mod từ chối cắt ticket UI thiếu 3 mục A3** (router kiểm ở dispatch). Số: 101/202 ticket UI bỏ bmad-ux
  không ai thấy | transcript nizzy 30 ngày.

### C. Skill: cài thêm, đổi vai, bỏ

- [ ] **C1. Cài**: `@google/design.md` CLI (npx), Hallmark `sloplint.mjs` (chỉ linter), axe/pa11y. Đã có:
  `frontend-design` Anthropic 1.1.1 (nạp kèm surface mới), `ui-ux-pro-max` (lookup).
- [ ] (5.0.0, gật qua mục 4) **C2. Tách `astraler-ui-anti-slop`**: R1–R10 → rule LLM đọc trong `/code-review` cùng DESIGN.md
  (hàng trống ma trận R1b/R2/R6/R7/R8 là rule LLM); token contract → từ vựng A1; phần còn lại là house rule
  gọi ở mốc "trước code UI" hoặc bỏ. Số: 0 lần gọi mọi project | transcript toàn máy.
- [ ] (5.0.0, gật qua mục 4) **C3. `bmad-ux`**: gỡ EXPERIENCE.md, giữ advisor, đọc 3 mục ticket. Số: 101/202 ticket UI bỏ qua
  | transcript nizzy.
- [-] Không dùng trong pane dispatch: impeccable (interactive, ≈140k byte/surface), taste `lint.mjs` (272 FAIL
  nhiễu trên app screen), Claude Design `/design-sync` (code → claude.ai/design, không có gate; inception
  đang trial, chưa đo có ai dùng).

### D. Doctor và cải tổ lớp vận hành

- [ ] **D1. `astragentic doctor`**: khám toàn scaffold theo 8 nhóm (harness, mod, tracker, worktree, dev
  stack, test contract, herdr, design), mỗi dòng gọi checker đã có, ✓/✗, exit 1. Gọi từ `astragentic.sh
  doctor`, cuối `get.sh --apply`, mod `session.start`. Số: phía project chỉ có `update|version`; 18 plug
  không ai kiểm; 3 lần apply lộ lỗi bằng tay | proposal §9.
- [ ] (5.0.0, gật qua mục 4) **D2. Viết bộ skill `astra-*` thay Matt, lấy triết lý BMAD, giữ độ gọn của Matt.** Owner 2026-10-29:
  "kết hợp matt và bmad… viết lại astra-to-spec, astra-to-tickets, astra-grill-with-docs,
  astra-implement-with-tdd, astra-review (kết hợp review matt và built-in)". Lý do owner: Matt có hạn chế,
  BMAD rườm rà nhưng triết lý sản xuất phần mềm chuẩn. Hướng đã quyết; từng skill gật riêng khi có bản nháp.
  Số: Matt 6 skill 20k byte, 125 chỗ nhắc / 22 file harness, mod 23 dòng (2 bẫy: regex brief, literal tdd);
  BMAD distill tương ứng prd 4.3k + epics-stories 4.6k + dev-story 5.5k + code-review 5.8k; nizzy gọi
  code-review 272 / tdd 224 | proposal §10, §10.4; `wc -c` hai bộ skill.
  Thứ tự owner chốt 2026-10-29: (1) thiết kế `astra-*` từ hai bộ chưng cất `docs/matt-pocock-distilled/`
  (xong, 7 file 17.1k byte) và `docs/bmad-distilled-latest/` (subagent đang kéo BMAD mới nhất);
  (2) gỡ plugin `mattpocock-skills` khỏi harness + overlays; (3) doctor (D1) có dòng xác nhận: không còn
  `mattpocock-skills:` trong harness/plug/overlay, 5 skill `astra-*` nạp được, regex brief và gate tdd
  trỏ tên mới.

### E. Đo trước khi làm (chưa đo, không vào kế hoạch)

- 46 CSS var nizzy / 221 inception map vào 5 nhóm schema được bao nhiêu.
- 65 ticket sửa UI nizzy: rơi vào 14 rule L1 / 8 rule LLM / ngoài cả hai; bao nhiêu không nêu actor.
- 14 rule `design-lint`: bao nhiêu có rule ESLint/Stylelint sẵn.
- `/code-review` trong Builder pane có đọc rubric §B không; `skills_run` của `bmad-*` từ 2.19.0.
- Doctor chạy thử trên nizzy và inception: bao nhiêu ✗.
- inception: bao nhiêu actor trong spec; 16 merge UI có bao nhiêu là sửa lại; design-sync có ai dùng.
- `taste inspect --app`, Hallmark `--render` trên dev stack nizzy.

## Số đã đo trong buổi (nguồn cho các mục sau)

| Số | Giá trị | Nguồn |
|---|---|---|
| Ticket merge 45 ngày / chạm UI / dạng sửa UI | 400 / 209 / 65 | git nizzy first-parent main, phân loại tiêu đề (±4/30 sai) |
| Brief UI nêu bmad-ux / gọi thật / ghi n/a | 202 / 101 / 8 | transcript nizzy 30 ngày |
| `astraler-ui-anti-slop` được gọi | 0 lần, mọi project | transcript toàn máy |
| DESIGN.md stakeholder nizzy | 1211 dòng, 68 commit, 0 token YAML | `design.md lint`: "No YAML content found" |
| DESIGN.md design-library | khoá `tokens:` ngoài schema, export bỏ qua | `design.md lint` |
| CSS var trong `apps/dashboard/src/index.css` | 46, có link/row-hover, không status.* | grep |
| `impeccable detect` trên dashboard nizzy | 1 finding / 609 file | engine 0.1.18 |
| Mod `astragentic-dispatch` từ chối | 2 bước (test file, arm) + 3 tool; bmad-ux chỉ ghi chú | `register.tsx` 7 handler `tool.call` |
| nizzy frontend gate có sẵn | rubric 185 dòng (§A L1 + §B L2 8 rule); design-lint 14 rule, baseline 6; 6 bộ guard; `frontend-implement` 277 dòng gọi 24 lần, `golang-implement` 508 dòng gọi 13 lần | `frontend-gate-rubric.md`, `design-lint/scan.mjs`, overlay dispatch-brief:11, transcript nizzy |
| Rule Glance nizzy | `.claude/rules/ui-glance-map.md` 2026-10-28, nửa generic nợ upstream | file đó |

## Chưa đo

- 6 violation trong `design-lint/baseline.json` là rule nào; 65 ticket sửa UI rơi vào 14 rule L1 / 8 rule §B / ngoài cả hai bao nhiêu.
- `/code-review` trong Builder pane có đọc rubric §B không (đếm transcript nizzy).

- 46 CSS var nizzy map vào 5 nhóm schema Google được bao nhiêu.
- 65 ticket sửa UI đối chiếu 3 guard script nizzy và R1–R10 anti-slop: bao nhiêu máy bắt được.
- `skills_run` của `bmad-*` trên nizzy từ 2.19.0.
- Trong 101 ticket UI bỏ bmad-ux, bao nhiêu có ticket sửa cùng surface sau đó.
