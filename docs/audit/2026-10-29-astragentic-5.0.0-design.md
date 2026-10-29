# Astragentic 5.0.0 — thiết kế bộ skill `astra-*` và flow làm việc (2026-10-29; owner chốt cùng ngày "theo đề xuất của em" cho 9 câu §8; từng SKILL.md gật riêng khi có nháp)

Owner 2026-10-29: bộ cài chỉ còn skill `astra-*`; Matt Pocock và BMAD chỉ còn là hai bộ chưng cất trong
`docs/` (`matt-pocock-distilled/`, `bmad-distilled/`, `bmad-distilled-latest/` đang kéo). Mỗi mục dưới có
`số | nguồn`. Trạng thái: **đã quyết** (owner nói rõ) hay **chờ gật**. Bảng việc ở §9.

## 0. Vì sao là 5.0.0

Phá hợp đồng bên ngoài harness, không chỉ bên trong:

| Hợp đồng bị đổi | Số | Nguồn |
|---|---|---|
| Prefix brief Builder `/mattpocock-skills:implement <ticket>` mà mod dùng để nhận diện pane Builder | 4 regex | `register.tsx:1636,1655,1692,1716` |
| Tên skill trong `skills_run`/`skills_log` của record (gate tdd đọc literal) | 11 dòng | `register.tsx:58-59,95,97,293,295,2301,2331` |
| Tên trong overlay và rule của project downstream | nizzy 12 chỗ / 4 file; inception 2 chỗ / 1 file (overlay + AGENTS.md + ui-glance-map) | grep hai repo |
| `subagent_type: astragentic-dispatch:bmad-sally/reviewer/murat` gọi từ role và project | sally 243, reviewer 78, murat 17 lần spawn | transcript hai project |
| Chip trên band: implement · tdd · ux · review:matt · review:built-in · simplify · arm | 1 bảng FLOW_BY_ROLE | `register.tsx:290-306` |
| selftest cases nhắc tên cũ | 28 mattpocock + 4 bmad | `grep -c scripts/selftest.sh` |

## 1. Bộ skill cài vào project (7 skill, hai bản `.agents/` + `.claude/` như nay)

| Skill | Thay cho | Lấy từ (đã chưng cất) | Người gọi (wired) | Trần byte |
|---|---|---|---|---|
| `astra-grill-with-docs` | Matt grill-with-docs = grilling + domain-modeling | grilling: cây quyết định, frontier theo vòng, "yes" nhận đề nghị, fact là của agent, decision là của owner. domain-modeling: GLOSSARY/ADR inline, ADR chỉ khi 3 điều kiện. BMAD advanced-elicitation: brain dump trước, hỏi mở | Shaper phase Align; chip `align` | 4.0k (Matt 1.9k+3.1k+0.2k) |
| `astra-ux` | **mới** (lấp khoảng trống: Shaper không hỏi owner về UX; `to-questionnaire` 0 lần) | BMAD prd: journey UJ-N "captured, not authored", nhân vật có tên, persona inline; form-factor; "drop UJ cho internal single-operator"; dùng engine vòng của grilling với bộ câu hỏi journey/actor/state | **Pane có owner**: BA (ba.md) hoặc Thomas, trước khi Shaper nhận việc; ghi UJ-N vào PRD của project. Shaper không hỏi ai (shaper.md:68-78); chip không có vì không phải pane dispatch | 3.5k |
| `astra-to-spec` | Matt to-spec | Matt: seams first, no interview, template 7 mục, story đánh số. BMAD: FR id ổn định, UX-DR tách mục, đọc PRD để giữ tên actor | Shaper phase Spec; chip `spec` | 3.5k (Matt 3.0k) |
| `astra-to-tickets` | Matt to-tickets | Matt: vertical slice, prefactor, expand–contract, frontier, quiz owner. BMAD mới: **không `As a`** (§8.6a), actor ở PRD và mở đầu dòng Given; criteria `Given/When/Then` gắn FR id; 1 agent 1 phiên; edge chỉ là prerequisite; Set check FR→ticket đi trong handback (không file riêng). Harness: ticket UI có **Glance / States / Criteria** (backlog A3), nhãn quick/full với 3 dòng bằng chứng (4.6.0) | Shaper phase Tickets; chip `tickets`; router kiểm 3 mục lúc dispatch (B6) | 6.5k (Matt 5.8k) |
| `astra-implement-with-tdd` | Matt implement + tdd (+tests.md, mocking.md) | Matt: seam thoả thuận trước, anti-pattern (coupled, tautological, horizontal), mock chỉ ở biên, red trước green, refactor không thuộc loop. BMAD dev-story bước 5–8: RED/GREEN/REFACTOR, gate "no lying" (test tồn tại và pass 100%, implementation khớp task, không thêm feature), HALT khi cần dependency mới / 3 lần fail liên tiếp | Brief Builder dòng đầu `/astra-implement-with-tdd <ticket>`; chip `implement`, `tdd` | 6.0k (Matt 7.9k) |
| `astra-ui` | bmad-ux + persona bmad-sally | bmad-ux hiện tại (3 intent audit/polish/upgrade, spine là DESIGN.md, surface phải render, không volunteer màu/hướng) **bỏ EXPERIENCE.md**, đọc 3 mục ticket; spawn persona read-only như nay nhưng persona đổi tên `astragentic-dispatch:astra-ui-lens` | Builder trước review khi FLOW nêu; QA walk khi surface đọc sai; chip `ux` → `ui` | 3.5k (bmad-ux 3.6k + sally 3.3k) |
| `astra-review` | Matt code-review + built-in `/code-review` chạy riêng | Matt: 2 trục Standards (Fowler smells) / Spec, không rerank chéo trục. BMAD code-review: Blind Hunter + Edge Case Hunter + Acceptance Auditor, đọc code trước khi chấm, route patch/defer/dismiss. **Gọi built-in `Skill(code-review)` làm lớp correctness** thay Blind Hunter. Quick ticket: gọi thẳng built-in, không qua astra-review (4.6.0 giữ) | Builder sau tdd và ui; chip `review` (một chip thay hai) | 5.0k (Matt 6.7k) |

Ngân sách theo pane (byte SKILL.md nạp một phiên), vì Builder chiếm 95% token (memory 2026-10-18):

| Pane | Hôm nay | 5.0.0 |
|---|---|---|
| Builder full | implement 0.6k + tdd 7.3k + bmad-ux 3.6k + Matt code-review 6.7k = 18.2k | astra-implement-with-tdd 6.0k + astra-ui 3.5k + astra-review 5.0k = 14.5k |
| Shaper | grill 5.2k + to-spec 3.0k + to-tickets 5.8k = 14.0k | 4.0k + 3.5k + 6.5k = 14.0k |
| BA / Thomas (owner ngồi) | 0 | astra-ux 3.5k, chỉ khi việc chạm UI |

Giữ nguyên, đã là của harness: `test-design`, `codex-arm`, `dispatch-*`, `*-issue-tracker`, `reconcile-tracker`.

## 2. Những thứ mang tên bmad còn lại

| Thứ | Số | Đề xuất (chờ gật) |
|---|---|---|
| `bmad-party` | 0 Skill call hai project; 4.0k | **bỏ**. Owner cần bàn tròn thì gọi `Agent` nhiều persona bằng tay; không cần skill |
| 7 persona `agents/bmad-*.md` (32.5k tổng với party) | sally 243 / reviewer 78 / murat 17 spawn; john, mary, winston, paige 0 spawn riêng | giữ 3 có số, đổi tên: `astra-ui-lens` (sally), `astra-slice-reviewer` (reviewer, thomas.md:40), `astra-test-architect` (murat, test-design:75). **Bỏ 4** không spawn; ba.md:19 trỏ mary/john/winston sửa thành "hỏi owner" |
| `docs/bmad-distilled/`, `docs/bmad-distilled-latest/`, `docs/matt-pocock-distilled/` | 45 + ? + 7 file | giữ ở `docs/` của repo astragentic, **không nằm trong payload cài** (đã kiểm: `install.sh:20` PAYLOAD=`harness/` only; `install.sh:67-104` bắt mỗi skill có hai bản `.agents/`+`.claude/` giống nhau, nên 7 skill `astra-*` ship cả hai bản) |

## 3. Flow theo pane (5.0.0)

**BA hoặc Thomas, nơi owner đang nói** (trước Shaper): khi việc chạm UI, `astra-ux` hỏi owner journey /
actor / trạng thái theo vòng kiểu grilling ("yes" nhận đề nghị; fact agent tự tìm), ghi UJ-N vào PRD của
project (tạo `docs/prd.md` nếu chưa có). Thứ tự này là của BMAD: journey trước story. `to-questionnaire`
mất cùng Matt; câu Shaper không trả lời được đi trong handback đầu như nay.

**Shaper** (một phiên, 5 phase như 4.6.x): Align `astra-grill-with-docs` (Shaper tự trả lời fact có nguồn;
câu không nguồn để mở, không hỏi ai) → Spec `astra-to-spec` (đọc PRD để giữ tên actor) → Arm `codex-arm` →
Test design `test-design` → Tickets `astra-to-tickets` (ticket UI có 3 mục; nhãn quick/full).
Chip: align · spec · arm:spec · test-design · tickets.

**Thomas (router)**: dispatch như 4.6.x; thêm một kiểm: ticket chạm UI thiếu Glance/States/Criteria thì
không cắt brief, trả về Shaper (B6). Brief dòng đầu `/astra-implement-with-tdd <ticket>`; FLOW line nêu
`astra-ui` khi UI.

**Builder full**: `astra-implement-with-tdd` → `astra-ui` [UI] → `astra-review` (trong có built-in) →
`simplify` một lần cuối → `codex-arm`. Chip: implement · tdd · ui · review · simplify · arm (6, thay 7).
`implement` sáng khi skill expand; **`tdd` sáng từ RED run trong log `hook-test-run.py`**, không từ Skill
call, vì một skill chỉ cho một dòng `skills_run`.
**Builder quick** (4.6.0): code, test sẵn có xanh, built-in `Skill(code-review)`, commit, push, handback.
Không đổi.

**QA**: như 3.x; `astra-ui` thay `bmad-ux` ở bước walk khi surface đọc sai (qa.md:21); walk đọc States
của ticket làm checklist thay danh sách cố định loading/empty/error/permission-denied.

## 4. Mod `astragentic-dispatch` — từng dòng

| Dòng | Đổi | Selftest (fail trước, pass sau) |
|---|---|---|
| 58-61 alias bảng | `astra-implement-with-tdd`→tdd, `astra-review`→review, giữ `code-review`, `simplify` | — |
| 95, 97 `tddCalledAfter` | **bỏ kiểm tên skill**; gate = test file staged + RED run (đúng comment 4.1.0) | case: commit đầu có test file + red run, không có Skill call nào → phải pass |
| 290-306 FLOW_BY_ROLE | bảng mới §3; chip `tdd` đọc `redRunAfter` thay `ran` | case: red run có, không Skill tdd → chip ✓ |
| 1291 text quick | đổi tên trong câu "Not owed" | — |
| 1362-1367 uxOwed | regex `\bastra-ui\b` | case: FLOW không có astra-ui → ux n/a |
| 1636,1655,1692,1716 | regex `^/astra-implement-with-tdd\b` | **case: brief prefix mới vào regex cũ không nhận → fail; regex mới nhận** |
| 1919, 1831, 1905, 2157 | sửa text/comment deny | — |
| 2301 quickDrop, 2331 isNa | tên mới | — |
| ~~mới~~ | ~~mod đọc cả tên cũ và mới một release~~ **Bỏ khi build (2026-10-29):** giữ tên cũ trong mod là trái ruling "không dấu hiệu matt/bmad" và làm doctor phải có ngoại lệ. Thay bằng dòng ADAPT/RELEASE-NOTES "apply giữa hai lane": Builder đang chạy giữ prefix cũ nên phải xong hoặc re-brief trước khi apply | — |
| mới (B6) | prompt.submit: brief UI thiếu 3 mục → từ chối cắt. Mod chỉ thấy brief, không thấy tracker, nên `dispatch-ticket` phải dán Glance/States/Criteria vào brief như đang dán acceptance criteria | case: brief thiếu `## States` → deny |

Bài học 4.3.2 (record giữa chừng làm vỡ apply) được trả lời bằng "apply giữa hai lane" thay vì alias trong mod.

## 5. Tài liệu harness viết lại

- 6 role (`thomas.md`, `shaper.md`, `builder.md`, `builder-claude.md`, `ba.md`, `qa.md`): 125 chỗ mattpocock +
  26 file bmad. `ba.md` nhận `astra-ux`; `ba.md:19` còn `mattpocock-skills:research` → thay bằng WebSearch/`research` của harness hoặc bỏ.
- `dispatch-ticket*/SKILL.md`: FLOW line, bảng chip, định nghĩa `skills_run`.
- `RULES.md` AST-042 (hai skill cùng tên `code-review`): đơn giản hơn khi Matt mất; ghi lại.
- `selftest.sh`: 28 + 4 case đổi tên, thêm 5 case §4.
- `RELEASE-NOTES.md` 5.0.0 theo khuôn 4.6.1; `prompts/ADAPT-HARNESS.md`: project đổi tên trong overlay
  (nizzy 12 chỗ/4 file, inception 2/1), không gửi bước apply (rule consult-not-impose).
- Doctor (D1) dòng: `grep -r "mattpocock-skills:\|bmad-" <payload+plug+overlay>` = 0; 7 skill `astra-*` có
  SKILL.md hợp lệ ở cả hai bản; regex brief và FLOW_BY_ROLE trỏ tên có thật.

## 6. Gỡ plugin Matt

`claude plugin uninstall mattpocock-skills` là việc của owner trên máy (TTY). Harness không phụ thuộc
sau 5.0.0; `grilling`/`domain-modeling` anh vẫn có thể giữ dùng tay ngoài harness nếu muốn (9+9 lần).

## 7. Ngân sách và đo sau release

Đo trên nizzy sau 10 ticket 5.0.0: (a) ticket UI có đủ 3 mục / tổng; (b) ticket sửa UI cùng surface
trong 14 ngày sau (so 65/209); (c) refusal tdd-order giả (so 0 ở 4.5.x); (d) byte skill nạp một phiên
Builder (so 27k); (e) `astra-review` finding Spec dẫn tới sửa code (so 35/272 Matt).

## 8. Quyết định — owner chốt 2026-10-29 theo đề xuất (giữ nguyên văn để truy vết)

1. `astra-ux` chạy ở pane BA hay pane Thomas (đề xuất BA: ba.md đã là chỗ owner nói chuyện và trả handoff md
   cho Shaper), và là skill riêng (đề xuất) hay bộ câu hỏi trong `astra-grill-with-docs`.
2. Bỏ `bmad-party` và 4 persona 0 spawn.
3. domain-modeling (GLOSSARY/ADR) nằm trong `astra-grill-with-docs` (đề xuất) hay bỏ khỏi harness.
4. Doctor: thứ tự owner là "thiết kế → gỡ Matt → doctor xác nhận", nên 5.0.0 cần **doctor tối thiểu**
   (`astragentic.sh doctor`: 0 tên ngoài trong payload+plug+overlay; 7 cặp SKILL.md nạp; regex brief và
   FLOW_BY_ROLE trỏ tên có thật). Doctor 8 nhóm (D1 đầy đủ) đi 5.1. Hay gộp cả vào 5.0.0.
5. 5.0.0 chứa §1–§6 + doctor tối thiểu. Gate B1–B5, mẫu DESIGN.md A1, ESLint B3 đi 5.1/5.2 để đo riêng.
6. ~~Khi `bmad-distilled-latest` về~~ Đã về (BMAD HEAD 61e01f8 2026-10-18, bản v7 chưa phát hành; tag v6.12.4;
   TEA v3.4.0). Ba chỗ **quyết định hôm nay trích BMAD cũ, BMAD mới đã đổi** (audit `2026-10-29-bmad-latest-distill.md` §c),
   owner chọn mỗi chỗ:
   - 6a. Ticket: BMAD mới **bỏ `As a {user_type}`**; Description một câu, criteria GWT gắn id `R<m>`; actor sống ở
     FR của PRD dạng `[Actor] can [capability] [under conditions]`. Giữ `As a` trong astra-to-tickets là lựa chọn
     của harness, hoặc theo mới: actor ở PRD + dòng Given mở đầu bằng actor (đã có trong A3).
   - 6b. Build: BMAD mới **không còn RED/GREEN/REFACTOR và gate "NO LYING"** trong bmad-build; giữ "Judge against the
     diff, not the subagent's report" + Matrix Test Audit; đỏ-trước chuyển sang TEA red mode. Nguồn RED/GREEN
     còn lại là bản distill cũ và Matt tdd. astra-implement-with-tdd lấy đỏ-trước từ Matt + TEA red ("one
     smallest criterion-defining assertion that must fail first", "never weaken a test to pass"), lấy
     "judge the diff" từ bmad-build.
   - 6c. Spec: BMAD mới **bỏ liệt kê UX-DR**, thay bằng "UI ticket links its design in References; criteria stay
     functional". Khớp Glance/States hơn. Đề xuất theo mới: bỏ mục UX-DR khỏi astra-to-spec.
   Thêm đáng lấy cho astra-review: 5 verdict kèm câu bằng chứng, bỏ `dismiss`, lens Verification Gap ("would
   any test fail?") và Intent Alignment thay Acceptance Auditor. Cho astra-to-spec: PRD có Glossary, FR id ổn
   định, Non-Goals, counter-metrics.

## 9. Bảng việc (owner chốt → chuyển vào danh sách nâng cấp)

| # | Việc | Trạng thái | Số | Nguồn |
|---|---|---|---|---|
| 1 | Viết nháp 7 SKILL.md `astra-*` theo §1, mỗi cái gật riêng | đã chốt; **`astra-to-tickets` owner gật 2026-10-29 (cùng 10.2/10.3/10.4 theo đề xuất)**; `astra-to-spec` 2026-10-29 (§11); **từ đây owner uỷ quyền: "em đừng hỏi anh nữa", các nháp còn lại tôi quyết** (6 509 byte, trần 6.5k; 0 chữ matt/bmad; hai bản `.agents/`+`.claude/` giống nhau; 4 lựa chọn ở §10) | trần 32k | §1; `wc -c`, `cmp` |
| 2 | Bỏ `bmad-party`, 4 persona 0 spawn | **đã làm 2026-10-29** (git rm) | 0 call; 0 spawn riêng | transcript |
| 2b | Viết lại 3 persona thành `astra-ui-lens`, `astra-slice-reviewer`, `astra-test-architect` | **đã làm 2026-10-29** | 243/78/17 spawn; 3.3k+2.9k+4.0k | transcript, wc -c |
| 3 | Mod: 11 điểm §4 + 5 selftest case | **đã làm 2026-10-29**; thêm: `red_run_at` reset khi brief mới, đọc log chỉ ở pane Builder; bỏ dòng alias tên cũ (xem §4) | 23 dòng register.tsx | grep |
| 4 | Viết lại 6 role + 2 dispatch skill + RULES AST-042 | **đã làm 2026-10-29**; thomas.md 2038/2150 từ, shaper.md 1087/1200 (budget docs-staleness) | 125 chỗ + 26 file | grep |
| 5 | selftest: đổi 32 case, thêm 5 | **đã làm 2026-10-29**: B6 3 case, tdd không cần Skill call, chip tdd từ red run, re-brief reset chip, doctor fail-first | 28+4 | grep selftest.sh |
| 6 | `astra-ux` ở pane BA/Thomas + PRD UJ-N (backlog A2) | đã chốt (pane BA) | nizzy 3 actor, 0 PRD | backlog mục 2 |
| 7 | Ticket UI 3 mục + router từ chối thiếu (A3, B6) | đã chốt, trong 5.0.0 | 65/209; 101/202 | git, transcript nizzy |
| 8 | RELEASE-NOTES 5.0.0 + ADAPT-HARNESS | **đã viết 2026-10-29**; ADAPT §2 không còn bước plugin, §3 bảng đổi tên + "apply giữa hai lane"; check-requirements.sh bỏ yêu cầu plugin, TARGET kiểm 7 cặp skill | nizzy 12/4, inception 2/1 | grep |
| 9 | Doctor tối thiểu trong 5.0.0: `astragentic.sh doctor` 3 dòng kiểm §5 | **đã làm 2026-10-29**: exit 0 sạch, exit 1 với 3 lỗi trồng (đo tay + case selftest) | project-side hiện chỉ `update|version` | nizzy astragentic.sh:42-44 |
| 10 | Owner gỡ plugin mattpocock-skills trên máy | sau khi nizzy chạy 5.0.0 ổn | — | §6 |
| 11 | Đo 7 ngày sau trên nizzy (§7) | sau release | 5 số | §7 |
| 12 | Ba lựa chọn 6a/6b/6c sau khi rà `bmad-distilled-latest` | đã chốt 2026-10-29 | 3 chỗ lệch, 3 chỗ khớp | audit bmad-latest §c |

## 10. Nháp `astra-to-tickets` — 4 chỗ Matt/BMAD để "the user"; owner gật 2026-10-29: 10.1 theo ruling, 10.2–10.4 theo đề xuất

| # | Chỗ | Chọn trong nháp | Vì sao |
|---|---|---|---|
| 10.1 | Matt bước 4 "quiz the user, iterate until approved" | **Giữ nguyên "hỏi owner" trước khi publish.** Owner 2026-10-29: "việc hỏi rất quan trọng… cứ xem như anh luôn ngồi máy, còn anh cho phép Thomas trả lời hay anh trả lời là vấn đề của anh và Thomas." Skill viết cho owner; đường trả lời đi qua pane dispatch, skill không biết ai nói | owner ruling; áp dụng cho mọi astra-* còn lại |
| 10.2 | Tên heading 3 mục để mod B6 so khớp | `## Glance`, `## States`, `## Criteria` trần, không hậu tố | mod so chuỗi đúng; hậu tố kiểu nizzy `(what <role> must see…)` cần regex |
| 10.3 | Nhãn readiness lúc publish | `needs-triage`; `quick`/`full` là label tracker | thomas.md:55 Thomas promote sau arm; 4.6.0 nhãn đọc từ tracker |
| 10.4 | Coverage map FR→ticket (BMAD Set check) | Một đoạn trong handback, không file, không section | không ai đọc sau lúc cắt (feedback wired-or-orphan) |

Không ghi dòng attribution Matt/BMAD trong payload: doctor grep tên = 0; attribution MIT nằm ở `docs/*-distilled/README.md`.
Owner quyết có cần dòng MIT trong payload không.

## 11. Nháp `astra-to-spec` — chỗ chọn (owner uỷ quyền 2026-10-29)

| # | Chỗ | Chọn trong nháp | Vì sao |
|---|---|---|---|
| 11.1 | Matt "User Stories: a LONG numbered list `As an <actor>, I want…`" | Thay bằng **Requirements FR-n** dạng BMAD mới `[Actor] can [capability] [under conditions]. Realizes UJ-x.` + Consequences (testable); id không đánh lại | §8.6a actor sống ở FR; ticket cite FR-n (astra-to-tickets §3); "As a" dài không ai đọc lại |
| 11.2 | Matt "no interview" vs ruling "hỏi như anh luôn ngồi máy" | Giữ "không mở lại frontier"; **một câu hỏi duy nhất là seam** (Matt cũng "check with the user") | Align đã hỏi; hỏi lại là lặp |
| 11.3 | UX-DR | Bỏ (§8.6c): "UI spec links its design in References; requirements stay functional"; Glance để ticket | BMAD mới `validate-checks.md:21` |
| 11.4 | Thêm từ BMAD PRD | Non-goals có lý do, Open questions đánh số, Consequences testable, cấm "gracefully/reasonable" | prd-template `:90`, rubric chiều 4 |
| 11.5 | Nhãn | `needs-triage` rồi STOP | shaper.md:45; thomas.md:54 |

## 12. Build 2026-10-29 — những gì khác với thiết kế, và nợ

| Khác | Vì sao |
|---|---|
| Bỏ alias tên cũ trong mod (§4 dòng gạch) | trái ruling "không dấu hiệu matt/bmad"; thay bằng "apply giữa hai lane" |
| Thomas mất 4 hàng Triage / Wayfinding / Owner decisions / Method questions | 0 Skill call trong transcript pane Thomas nizzy (`"name":"Skill","input":{"skill":"…"}`); owner decision về thẳng owner |
| `check-reachability.py` đọc invocability từ frontmatter payload, không từ plugin cache | plugin không còn; sửa luôn lỗi đọc flag trong body (dispatch-ticket nhắc flag trong prose) |
| Chip `review` một cái; quick ticket sáng chip từ built-in | hai review gộp một theo §3 |
| Byte Builder 11.9k (kế hoạch 14.5k) | astra-implement-with-tdd 4.0k, astra-ui 3.3k, astra-review 4.6k |

Nợ sau release: §7 năm số đo trên nizzy; site/ còn 95 chỗ nhắc plugin/BMAD (deliverable riêng); doctor 8 nhóm (5.1);
`docs/bmad-distilled/` cũ giữ hay bỏ (README trỏ bản latest).
