# Chưng cất BMAD mới nhất cho bộ `astra-*` — 2026-10-29

Mọi dòng dưới đây có `path:line` (đường dẫn tương đối từ `/tmp/bmad-latest/` hoặc `/tmp/bmad-tea-latest/`)
hoặc một con số đo bằng `wc -c`. Bản distill mới nằm ở `docs/bmad-distilled-latest/`; bản cũ
`docs/bmad-distilled/` không đổi. Không file nào trong `harness/` hay memory bị chạm; không commit.

## (a) Phiên bản

| Sự thật | Giá trị | Nguồn |
|---|---|---|
| BMAD-METHOD HEAD | `61e01f82644c4bb533750cfa0d6d61ab61d2cc9b`, 2026-10-18T10:46:50-07:00 | `git log -1` trong `/tmp/bmad-latest` |
| Tag mới nhất | `v6.12.4` tại `eecafe9d4bcad92166bee08623e0526009d862c4` | `git ls-remote --tags` |
| HEAD là bản chưa phát hành | `## Unreleased` … "a first draft for v7" | `CHANGELOG.md:3-5` |
| `package.json` gốc | không có; chỉ `docs-site/package.json` | `find . -maxdepth 2 -name package.json` |
| Layout | `skills/` phẳng, 32 mục; 48 skill bị gỡ, 2 đổi tên | `ls skills \| wc -l`; `grep -c '^  "bmad' skills/bmod-method/retired.toml` = 48; `retired.toml:3-6` (renamed) |
| TEA (repo riêng) | HEAD `59c164c80f34a118fe33b84b1f6c5770d6b43389`, 2026-10-27; `version: 3.4.0`; tag `v3.4.0` | `/tmp/bmad-tea-latest`: `git log -1`, `package.json`, `git ls-remote --tags` |
| License cả hai repo | MIT, Copyright (c) 2025 BMad Code, LLC | `LICENSE:1-3` mỗi repo |
| Bản distill cũ | vào repo này 2026-09-14 (rename từ `docs/distilled`), file đề ngày 2026-08-28, không ghi version nguồn | `git log --diff-filter=A -- docs/bmad-distilled/README.md` → `aa7d27e`; grep `version\|v6\.\|sha\|commit` trong README/roster cũ: 5 khớp, tất cả là chữ "version" trong câu ("distilled version"), không có số phiên bản |

Sáu trong mười bốn capability không còn skill cùng tên: `bmad-bmm-create-story` (`retired.toml:32`),
`bmad-bmm-dev-story` (`:34`), `bmad-check-implementation-readiness` (`:50`), `bmad-create-epics-and-stories`
(`:51`), `bmad-correct-course` (`:53`), `bmad-spec` (`:54`). Hai skill review thành lens từ v6.11.0
(`CHANGELOG.md:71`). `testarch-atdd` gộp vào `bmad-tea-automate` red mode (TEA `CHANGELOG.md:189`).

## (b) Thay đổi theo capability

Byte đo `wc -c` cũ → mới. Tổng 58 549 → 96 720 (+65%).

| Capability | Cũ → mới | Nhà mới | Thêm | Bỏ / đổi |
|---|---|---|---|---|
| prd | 4286 → 9229 | `skills/bmad-prd/` | Đọc ticket trước, Requirements của nó là đã chốt (`SKILL.md:46`); research subagent mặc định (`:48`); **§3 Glossary** (`assets/prd-template.md:52-58`); form FR `[Actor] can [capability] [under conditions]` + "Consequences (testable)" (`:70-74`); UJ có entry state / path / climax / resolution (`:34-40`); counter-metrics SM-Cn (`:110-111`); rubric 7 chiều, "Persona theater … More than four personas" (`assets/prd-validation-checklist.md:58`); cụm "Small-scope all-inclusive" với `As a [persona], I can [action]` (`:164`) | Checklist boolean → rubric phán xét (`prd-validation-checklist.md:3`); bước kế tiếp là Sofia, không phải `create-epics` (`SKILL.md:97`) |
| create-epics-and-stories | 4571 → 9673 | `bmad-agent-po/references/{spec,slice,validate-checks}.md` | Dòng `R<n> (FR-2, FR-5)` (`spec.md:29`); Spec Law 8 điều (`:50-59`); ranh giới epic = ranh giới deploy (`slice.md:42-43`); epic viết mỏng `refined: false` rồi refine riêng (`:55,61-69`); story = entry trong `tickets.toml`, không file (`help/ticketing-and-epics.md:3`); tracer bullet trước, story ít chắc nhất kế (`customize.toml:136-138`); refactor sweep đóng epic >3 entry (`:141-143`); 8–12 story (`:151-153`); "Split, never shrink" (`slice.md:81`); check Set/Tree/Dependencies (`validate-checks.md:16-59`) | **Mục UX-DR riêng không còn**: "UX, architecture, constraint and integration work is covered without ids … citing an id alone is not coverage" (`validate-checks.md:21`); `epics.md` → `tickets.toml` |
| create-story | 5157 → 6241 | `bmad-agent-po/references/ticket.md`, `assets/*-template.md` | Criteria GWT `(R<m>)`, "a rule, not an instance, with its failure path" (`ticket-template.md:33-39`); risk mỗi ticket (`ticket.md:19`); bug không kèm fix, có tiêu chí "no change is needed, with proof" (`bug-template.md:42-45`); spike dùng `Verify:` (`spike-template.md:29-36`); "No source-code paths or snippets" (`ticket.md:16`) | **Không còn `As a {user_type}`**: Description story là "one sentence" (`ticket-template.md:25`); "story context engine" chuyển sang Code Map của plan (`bmad-build/step-02-plan.md:11`); `sprint-status.yaml`, `ready-for-dev` trên story file bỏ |
| dev-story | 5450 → 10053 | `skills/bmad-build/` | Plan `<frozen-after-approval>` (`plan-template.md:23`); 900–1600 token (`workflow.md:25`); oneshot ≤100 dòng (`customize.toml:41`); handoff subagent không context (`customize.toml:85-91`); "Judge against the diff, not just the implementation subagent's report" (`step-03-implement.md:39`); Matrix Test Audit (`:43-45`); loopback intent_gap / bad_plan / patch / defer, trần 5 vòng (`step-04-review.md:78-84`); kết thúc ở `built` (`step-05-present.md:15`) | **RED/GREEN/REFACTOR từng task, gate "NO LYING", vùng sửa story file, sync sprint**: không có trong `bmad-build` (`grep -rli 'tdd\|red-green\|failing test\|red phase\|test-first' skills/bmad-build/`: 0 file) |
| code-review | 5818 → 10365 | `skills/bmad-code-review/` | 5 verdict high/medium/low/false/maybe-false + câu bằng chứng (`step-03-triage.md:59-67`); verification-gap pre-verified, cố định medium (`:38,47`); route decision_needed/patch/defer (`step-04-route.md:10-13`); "never `defer`" cho lỗi do change này gây ra (`:15`); Intent Alignment Auditor (`customize.toml:137-154`); Blind Hunter sàn `N = min(floor(sqrt(kB)+1),10)` (`:96`); claims file chỉ tới edge lens (`step-01-gather-context.md:35`); không đổi `status` plan (`step-05-present.md:10`); chế độ non-interactive và handoff không-sửa-code (`workflow.md:4-9`) | Bucket `dismiss` → reject `false` + reject `low` tốn complexity (`step-03-triage.md:69-72`); Acceptance Auditor → Intent Alignment Auditor; ghi vào story file → ghi vào `## Code Review` của plan |
| ux | 5153 → 9603 | `skills/bmad-ux/` | Ticket trước, "never re-derive requirements from a PRD or brief it already distilled" (`SKILL.md:59`); bảng token design.md (`references/design-md-spec.md:11-19`); rubric 8 mục, State coverage "empty, cold-load, focus, error, offline, permission-denied" (`references/validate.md:27`); key-screen 2–4 màn, "Do not invent layout" (`assets/key-screens.md:26-27`) | Vẫn **hai spine** DESIGN.md + EXPERIENCE.md (`SKILL.md:11`) — ngược quyết định owner (xem §c) |
| advanced-elicitation | 3895 → 5247 | `skills/bmad-advanced-elicitation/` | Chọn 2–4 category trước rồi 5 method khác góc (`SKILL.md:37`); Apply/Reject mỗi method, "Never change the work unless the user accepts" (`:60-65`); catalog 71 method (`assets/methods.csv`, 72 dòng) | Menu `1-5, r, a, x` → menu chữ; không đổi về phương pháp |
| review-adversarial-general | 1673 → 2821 | `bmad-review/references/lens-adversarial.md`; Blind Hunter `bmad-code-review/customize.toml:88-105` | Sàn ≥10 giữ (`lens-adversarial.md:5`); sàn theo kích cỡ diff ở Blind Hunter (`customize.toml:96`); shape 4 trường (`lens-adversarial.md:12-17`) | Persona "cynical, jaded reviewer … clueless weasel" bỏ, lý do A/B (`CHANGELOG.md:107`) |
| review-edge-case-hunter | 4036 → 5608 | `bmad-code-review/review-prompts/edge-case-hunter.md` | Handle lifetime (`:35`); kiểm call-site với declaration, kể cả test (`:36`); Claims Check đọc narrative **sau** khi trace (`:13,49-51`, `references/claims-check.md`) | Không bỏ gì |
| testarch-test-design | 4115 → 6802 | TEA `skills/bmad-tea-test-design/` | Một risk mỗi gap statement (`steps-c/step-03-risk-and-testability.md:69`); ô P/I/Score chỉ số nguyên (`:80`); band high ≥6 / 3–4 / 1–2 (`:76`); một dòng coverage mỗi risk, level nơi lỗi lộ ra đầu tiên (`step-04-coverage-plan.md:50`); **P0 cần cả impact critical và không workaround** (`:62-69`); validation mở lại sau mỗi fix (`step-05-generate-output.md:237`) | Không bỏ; gate P0 100% / P1 ≥95% / coverage ≥80% giữ (`step-04:112-115`) |
| testarch-atdd | 3041 → 6652 | TEA `skills/bmad-tea-automate/red/` | Routing red/expand (`resources/test-generation-routing.md:16-21`); registry criterion ổn định (`red/steps-c/step-01-preflight-and-context.md:76-80`); một scaffold đỏ mỗi criterion, assertion định nghĩa criterion phải fail trước (`step-03-test-strategy.md:43-44,80`); "production test code that happens to be skipped" (`step-04-generate-tests.md:176`); run-and-heal: copy dùng một lần, phân loại trước khi sửa, ≤3 vòng (`resources/run-and-heal.md:13,38,58-74`), "Never add skip, `test.fixme()`… weakened assertions" (`:60`) | Skill `atdd` riêng bỏ (TEA `CHANGELOG.md:189`); "generation completion cannot imply … verified red" (`instructions.md:62`) |
| testarch-trace | 3250 → 5122 | TEA `skills/bmad-tea-trace/` | Oracle ledger, priority của oracle là thẩm quyền (`steps-c/step-01-load-context.md:85`); test chỉ được tính khi chứng minh một phần criterion (`step-03-map-criteria.md:66`); UNIT-ONLY/INTEGRATION-ONLY định nghĩa lại (`:46-47`); live evidence trần CONCERNS (`step-05-gate-decision.md:352`); "WAIVED is never derived" (`:318-320`) | Không bỏ; quy tắc 1–5 giữ (`step-05:285-316`) |
| check-implementation-readiness | 4055 → 6018 | `bmad-agent-po/references/validate.md`, `validate-checks.md` | Subagent context mới chạy từng section (`validate.md:3`); fix / suggest / ask (`:15`); không nêu lại suggestion đã có `Decision:` (`:16`); Closure theo bằng chứng (`validate-checks.md:63`) | Report READY/NEEDS WORK/NOT READY, coverage matrix FR→epic, phân loại Critical/Major/Minor: bỏ |
| correct-course | 4049 → 3286 | `bmad-agent-po/references/replan.md` | "Leave the remaining tickets true and nothing already built rewritten. No proposal file." (`replan.md:3`); 5 bước (`:7-11`); "never edit its plan" (`:7`), "never edit the companion" (`:11`) | Sprint Change Proposal, checklist tương tác, Incremental/Batch, routing Minor/Moderate/Major: bỏ |

## (c) Fit cho bộ `astra-*`

Đối chiếu với `docs/audit/2026-10-29-ui-ux-flow-proposal.md` §10.4 (bảng "Lấy từ BMAD" / "Bỏ của BMAD")
và các quyết định owner ở §2, §2a. Ba chỗ **quyết định owner trích BMAD cũ, BMAD mới đã đổi** — báo để
owner quyết, không tự sửa:

1. **Ticket `As a {user_type}` + GWT** (§2a, §10.4 dòng astra-to-tickets). Template ticket mới bỏ form
   `As a`: story Description là "one sentence" (`bmad-agent-po/assets/ticket-template.md:25`), criteria là
   GWT `(R<m>)` (`:35-39`). Form `As a` chỉ còn ở cụm PRD nhỏ `Story-n: As a [persona], I can [action]`
   (`bmad-prd/assets/prd-template.md:164`). Actor giờ sống ở FR của PRD: `[Actor] can [capability]`
   (`prd-template.md:70`). Nếu giữ `As a` trong ticket thì đó là lựa chọn của harness, không còn là "theo BMAD".
2. **RED/GREEN/REFACTOR + gate "NO LYING"** (§10.4 dòng astra-implement-with-tdd). Không còn trong
   `bmad-build`; `step-03-implement.md` chỉ có handoff subagent (`customize.toml:85-91`), "Judge against the
   diff" (`:39`) và Matrix Test Audit "A covering test that exists but did not run … counts as missing" (`:45`).
   Kỷ luật đỏ-trước chuyển sang TEA red mode (`red/steps-c/step-03-test-strategy.md:80`, `step-04:176`). Nguồn
   duy nhất còn lại cho bước 5–8 cũ là `docs/bmad-distilled/capabilities/dev-story.md` (baseline).
3. **UX-DR tách mục** (§10.4 dòng astra-to-spec). BMAD mới thay liệt kê UX-DR bằng companion adopted:
   "A UI ticket links its design in References; criteria stay functional" (`ticket.md:17`);
   "UX … work is covered without ids" (`validate-checks.md:21`). Khớp hơn với rule Glance/States của §2
   (ticket nêu màn hình và trạng thái, không chép token).

Ba chỗ **khớp**: UJ-N nhân vật có tên, persona inline, không mục persona (`bmad-prd/SKILL.md:65`,
`prd-template.md:29-44`, rubric `prd-validation-checklist.md:110,134`) · một agent một phiên (`slice.md:77`) ·
không phụ thuộc tới ("prerequisites only, not sequence", `tickets-template.toml:16`; `after` chỉ nhìn
sibling trước hoặc epic trước, `ticket-template.md:10`).

| Skill `astra-*` | Lấy (trích) | Bỏ (máy móc BMAD) |
|---|---|---|
| `astra-grill-with-docs` | "Brain dump first … even when the user opens with paragraphs (that is intake, not the dump)" (`bmad-prd/SKILL.md:46`); "Elicitation, not direction … When you find yourself naming wedges, picking MVP cuts, or proposing phases, stop" (`:50`); "Stakes calibration. One short probe: hobby / internal / launch" (`:52`); "Do not ask the human during investigation … Keep looking until you know, or until those sources have nothing more to say" (`bmad-build/step-02-plan.md:15`); elicitation: chọn 2–4 category rồi 5 method khác góc, "Never change the work unless the user accepts" (`bmad-advanced-elicitation/SKILL.md:37,65`) | menu 1-5/r/a/x, `pick_methods.py`, memlog, roster resolver |
| `astra-to-spec` | PRD §2.3 UJ-N: "Persona + context … Entry state … Path: 3-5 concrete beats … Climax … Resolution" (`prd-template.md:34-40`); §3 Glossary "introducing a synonym anywhere … is a discipline violation" (`:53`); FR "globally numbered … stable references even if features get reorganized" (`:61`), form `[Actor] can [capability] [under conditions]` + Consequences testable (`:70-74`); Non-Goals "prevents the 'let me also add this nearby thing' failure mode" (`:90`); counter-metrics (`:110`); rubric chiều 4 "Done-ness clarity … Be unforgiving here" (`prd-validation-checklist.md:78-88`); Spec Law 8 điều (`spec.md:50-59`); "load-bearing" test (`:41`) | addendum.md, reviewer gate nhiều lens, HTML report, memlog, headless |
| `astra-to-tickets` | Tracer bullet "the thinnest path through every layer the epic touches … Next is the story the user is least sure of" (`customize.toml:137`); "Split, never shrink" (`slice.md:81`); "Tests go in every story; the only test story is the closing end-to-end suite" (`:82`); "Stories touching the same code form one ordered lane; an interface two lanes share gets a stub as its own early story" (`:79`); refactor sweep (`customize.toml:142`); criteria "a rule, not an instance, with its failure path" (`ticket-template.md:33`); "Risk on every ticket" (`ticket.md:19`); check Dependencies: Needs / Collisions / Shared setup / Handoffs (`validate-checks.md:52-55`); "A builder could write each story's acceptance criteria from the epic, entry, and references; if not, fix the epic" (`:23`) | `tickets.toml`, `tickets.py`, tracker store/publish, `hitl`/`plan_checkpoint` keys, memlog |
| `astra-implement-with-tdd` | Từ `bmad-build`: "Judge against the diff, not just the implementation subagent's report" (`step-03-implement.md:39`); Matrix Test Audit (`:45`); "If a test disagrees with the matrix, never edit the expectation to match the code" (`:45`); "Stop coding if the request left out something the user would notice … do not guess" (`step-oneshot.md:29`). Từ TEA red: "Identify the one smallest criterion-defining assertion that must fail first" (`red/steps-c/step-03-test-strategy.md:44`); "A passing red test may expose behavior that already exists: report it … without inventing a failing assertion" (`run-and-heal.md:56`); "Never add skip, `test.fixme()`, expected-failure annotations, weakened assertions, increased test timeouts or SUT success mocks to suppress a failure" (`run-and-heal.md:60`); classify before repair, ≤3 rounds (`:13,58`). Từ baseline cũ (không còn upstream): RED/GREEN/REFACTOR, "NO LYING" gate (`docs/bmad-distilled/capabilities/dev-story.md`) | plan-template frontmatter, route oneshot/full, `deferred-work.md`, story file regions, Dev Agent Record, sprint sync, verifier CLI |
| `astra-review` | Lens độc lập, song song, "spawn every reviewer before reading or reacting to any of their output" (`step-02-review.md:18`); Blind Hunter không intent, sàn `min(floor(sqrt(kB)+1),10)` (`customize.toml:96`); Edge Case Hunter + Claims Check sau trace (`review-prompts/edge-case-hunter.md:13`); Verification Gap 4 shape, "A gap finding is a request to add or change one test. File it only when you can name a specific regression" (`verification-gap.md:5`); Intent Alignment "strictly descriptive … which surface the intent's expectations live at versus which surface the diff's changes and its tests exercise" (`customize.toml:150`); triage: "Do not decide about finding B because it's similar to finding A" (`step-03-triage.md:34`); 5 verdict + câu bằng chứng (`:59-67`); "Reject a `low` finding if … the fix creates extra complexity" (`:71`); route decision_needed/patch/defer, "never `defer`" cho lỗi do change này (`step-04-route.md:10-15`); "Never change a plan's `status`" (`step-05-present.md:10`); dừng khi "findings are mostly minor notes about unlikely corner cases" (`bmod-method/help/review-choices.md:21`) | HALT chờ số, ghi vào story file / plan `## Code Review`, `deferred-work.md`, chunk >3000 dòng, handoff_format |

Trần dung lượng §10.4: bộ `astra-*` ≤ 23k tổng. Bản distill mới 96.7k là **nguồn trích**, không phải skill;
mỗi dòng trích ở trên đều ≤ 2 câu.

## (d) Chưa đo / not verified

- Số commit giữa `v6.12.4` và HEAD `61e01f8`: clone `--depth 1` không đếm được.
- Phiên bản BMAD mà bản distill 2026-08-28 lấy từ: không ghi trong file; theo ngày CHANGELOG nằm giữa
  v6.11.0 (2026-08-09, `CHANGELOG.md:55`) và v6.12.0 (2026-09-03, `:36`) — suy luận, chưa xác minh.
- Hình ticket v7 (`R<n>`, `tickets.toml`, không `As a`) đã dùng ở nizzy/inception chưa: chưa đếm.
- Trên nizzy, các spec `to-spec` có dùng cùng tên actor giữa các spec không: proposal §2a đã ghi chưa đo, vẫn chưa.
- Claim A/B "cynical reviewer framing made no difference" (`CHANGELOG.md:107`): số mẫu không nêu trong repo.
- Verification-gap "Across 16 reviewer runs, prompt-only diffs went from 2/2 false gaps to 0/2" (`CHANGELOG.md:106`):
  dữ liệu không có trong repo.
- Blind Hunter sàn `sqrt(kB)+1`: không thấy lý do đo. `grep -rn sqrt CHANGELOG.md skills/ docs/`: 6 khớp, 3 trong `bmad-eval/scripts/aggregate_benchmark.py` (stddev), 3 là chính công thức trong `customize.toml` của build / build-auto / code-review; 0 trong CHANGELOG.
- TEA `bmad-tea-automate` red mode chưa chạy thật trên máy này; mô tả distill là từ nguồn, không từ run.
- Kích cỡ bản distill mới +65% so với cũ: chưa đo xem phần nào bị `astra-*` thực sự trích; cắt sau khi
  owner gật từng skill.
