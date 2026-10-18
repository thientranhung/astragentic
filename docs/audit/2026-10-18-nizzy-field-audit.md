# Điều tra toàn bộ Astragentic trên nizzy-ecom — 2026-10-18

**Đây là file anh đọc.** Mọi số ở đây là đếm được, có nguồn; không có đề xuất trong file này.
Ba lượt đo chỉ-đọc chạy song song, bản gốc ở `/tmp/nizzy-audit/` (transcripts.md 764 dòng,
logs-git-state.md 196 dòng, inventory.md 744 dòng, joined.md = bảng ghép). Cửa sổ: 30 ngày
(18/09 → 18/10) và 7 ngày (11/10 → 18/10, sau các bản 4.0.x).

Nguồn: (1) 2.137 file transcript `~/.claude/projects/*etsy*` (408 session chính, còn lại là
subagent), usage và tool call từng lần gọi model; (2) git của nizzy; (3)
`/tmp/harness-hook-events.log` (chỉ còn 3,3 ngày), `/tmp/herdr-watchdog-*.log`; (4)
`.astraler/state/*`, `.astraler/project/*`, `settings.json`, AGENTS.md, rules, overlays.

## 1. Quy mô

| | 30 ngày | 7 ngày |
|---|---|---|
| Ticket merge | 312 merge / 303 ticket | — |
| Commit trên nhánh ticket | 3.307 (median 10/merge) | — |
| Lần gọi model (dedupe theo message id) | 138.600 | 42.854 |
| Token gửi vào (input + cache) | 44,07 tỷ | 12,62 tỷ |
| Token output | 67,9 triệu | 20,3 triệu |
| Ước phí theo model đã chạy | **$11.711** | **$3.362** |
| … trong đó Builder (own + subagent) | $8.732 (75%) | $2.891 (86%) |
| … Thomas | $1.956 (17%) | $340 |
| … Shaper / QA / khác | $288 / $287 / $304 | $68 / $58 / — |

Builder chạy `claude-sonnet-5` (111.404/111.457 call); Thomas chủ yếu `claude-opus-5-5`.
Nguồn: transcripts.md §6.

## 2. Phần harness được dùng và có tác dụng (số đếm)

| Thành phần | Số | Nguồn |
|---|---|---|
| `mattpocock-skills:implement` | 278 call, ~90% của 299 ticket Builder | transcripts §1 |
| `simplify` | 327 call; 874 marker `simplify(increment)` trong git | transcripts §1, git A |
| `codex-arm` | 288 call; 457 marker `arm(ticket)` | transcripts §1, git A |
| `mattpocock-skills:code-review` | 175 call | transcripts §1 |
| `mattpocock-skills:tdd` | 82 call; **27% ticket (30d) → 95% (7d)** sau khi tdd-gate ra đời | transcripts §1 |
| tdd-gate (mod) | 39 lần từ chối, **39/39 lần call kế tiếp là Skill tdd** | transcripts §3b |
| arm-gate (mod) | 3 lần, 3/3 chạy code-review ngay sau | transcripts §3b |
| `check-simplify-markers.sh` | 1.911 lần chạy | transcripts §2 |
| `ticket-done.sh` + stamp | 351 lần chạy; 134 stamp; 137 ticket merge từ 05/10, 4 thiếu stamp (đều là cancel NOT_PLANNED) | transcripts §2, git B |
| Write-back tracker | 0 ticket đã merge còn open | git H |
| `release-worktree-resources.sh` | 384 lần; guard "remove thiếu stamp" 22 lần, 11 đổi hành vi | transcripts §2, §3b |
| Mod TURN-END bell | 811 bell tới Thomas (792 answer, 17 error, 2 aborted), 7 bell held | transcripts §3d |
| Brief qua mod | 148 brief `/…`, 787 peer message từ 05/10 | transcripts §4 |
| Guard `git add -A` | 167 lần; 93 đổi hành vi, **71 gõ lại y nguyên ngay sau** | transcripts §3b |
| Guard push main thiếu stamp | 27 lần (đều Thomas); 15 đổi hành vi, 11 gõ lại | transcripts §3b |
| Guard worktree (rm -rf / live process / uncommitted / relative path) | 4 / 7 / 3 / 3 | transcripts §3 |
| `Ledger:` trên merge | 213/312 ghi `none`; 4 merge không có dòng (29–30/09), 0 từ đó | git A |
| `Supersedes:` (rút marker) | 104 | git A |
| Plug `tracker-state.sh` | 152 lần chạy | transcripts §2 |
| `check-requirements.sh` / `check-reachability.py` / `docs-staleness` | 129 / 66 / 47 lần | transcripts §2 |

## 3. Phần chưa bao giờ dùng trong 30 ngày (0 lần)

| Loại | Thành phần | Ghi chú |
|---|---|---|
| Skill harness | `atdd`, `batch-triage`, `bmad-party`, `bootstrap-glossary`, `dispatch-junior`, `legacy-testing`, `untangle`, `jira-issue-tracker`, `linear-issue-tracker` | 0 Skill/slash, body chưa từng được nạp |
| Skill harness | `github-issue-tracker` | 0 Skill, nhưng **SKILL.md được Read 35 lần** → dùng bằng cách đọc file |
| Skill plugin | `mattpocock-skills:triage`, `wayfinder`, `ask-matt`, `to-questionnaire`, `diagnosing-bugs` | 0 |
| Agent plugin | `bmad-john`, `bmad-mary`, `bmad-paige`, `bmad-winston` | 0 spawn; `bmad-sally` 35, `bmad-reviewer` 9, `bmad-murat` 2 |
| Gate mod | merge-gate, refused-command, close-refusal, brief-refused (QA line / upgrade incomplete) | 0 lần bắn; ba cái đầu mới ra 4.0.2–4.0.3 |
| Script | `check-payload-drift.sh` 1 lần; `ledger-rules.py` 2; `pre-push-ticket-done.sh` 2; `reap-worktree-processes.sh` 2 | gần 0 |

Transcript không phân biệt "chết" với "được tuân thủ nên không bao giờ bắn"; muốn biết phải trồng
lỗi (transcripts §10).

## 4. Rule chỉ là prose, không để lại dấu vết nào

57 rule trong các hợp đồng role không trỏ tới skill, script, lệnh hay marker nào; 31 rule nữa chỉ
tồn tại trong chữ của handback. Theo file: builder.md 12+4, builder-claude.md 7+2, thomas.md
12+3, shaper.md 8+3, qa.md 10+18, junior.md 5, junior-grok.md 1 (inventory §11, có số dòng).
Thêm: **không code nào đọc** `builder-target`, hàng Junior, ô model/effort của orchestrator
(mod và doctor chỉ kiểm tra tiêu đề cột Advisor); dòng `FLOW:` trong brief không ai parse;
`check-payload-drift.sh` không được install.sh hay settings.json gọi (inventory, mục "prose-only
wiring").

## 5. Subagent và chi phí

| Số | Nguồn |
|---|---|
| Builder sinh ~1.900 subagent / 30 ngày, 17.974 lần gọi model trong đó, $939 | transcripts §5, §6 |
| 970 spawn xảy ra khi skill đang chạy là `simplify`; phần lớn loại Explore và general-purpose | transcripts §5 |
| Isolation hook của nizzy (không phải payload): 475 lần từ chối, 443 đổi hành vi | transcripts §3 |
| Compact: 38 `compact_boundary` (13 tự động, đều Thomas) + ~70 lần context tụt >50% | transcripts §7 |
| Context median mỗi call Builder 206k–561k (14 ticket gần nhất) | đếm riêng 18/10 |

## 6. QA

13 plan, 14 report (10 walk, 3 probe), 16 commit `qa(walk):`. **23/303 ticket** merge có report
nhắc tên (27% của 84 ticket từ khi có chuỗi QA 3.0.0). 22/23 report commit **sau** merge; QA
chưa bao giờ chặn một merge nào. (git G)

## 7. Project đổi gì trong payload và đặt gì bên cạnh

- 89/92 file payload y nguyên. Khác: `settings.json` (thêm hook isolation cho `Agent` và `Bash`,
  `onFailure: block`, `enabledPlugins`), `orchestrator.md` (22 dòng ruling của owner,
  builder-target 2), INDEX.md sinh lại. (git F)
- Bên cạnh payload: `core.hooksPath=tools/git-hooks` (276 dòng: pre-push đòi claim, commit-msg
  kiểm marker), tools/ (isolation guard, db guard, gate-plan, ticket-claim…), 14 plug trong
  `.astraler/project/` (role-budgets nâng thomas 3930 / builder 1960 từ), AGENTS.md 704 dòng
  (worktree 21 dòng, arm 18, Ledger 14), rules 34,5KB, overlays 33,7KB.

## 8. Nguồn thiếu hoặc hỏng

- Hook log bắt đầu 15/10 (bị tạo lại), dùng chung máy, chỉ ~14% dòng gán được cho nizzy.
- Watchdog log không có ngày, **dừng ở 14/10 15:06** dù tiến trình còn sống; **4 watchdog chạy
  cùng lúc** cho một workspace.
- `ADAPTATION-REPORT.md` không có receipt 3.3.1, 4.0.1, 4.0.2.
- `dispatch-record.json`: 131 entry, **129 không có trường `role`**, 21 không status, không
  `refusals` nào (entry bị xoá khi pane retire).
- Stamp chỉ từ 05/10; 166 merge trước đó không kiểm được.
- Transcript không ghi: RECEIVED, chip, toast, hook pass (chỉ thấy deny), advisor.

## 9. Bảng ghép từng thành phần

456 dòng, một dòng một thành phần, ghép inventory × hai lượt đo, cột kết luận để trống cho tới
khi anh đọc xong: `docs/audit/2026-10-18-nizzy-field/joined.md`. Bản gốc ba lượt đo và script
đếm (chạy lại được) nằm cùng thư mục. Chỗ hai lượt đo lệch nhau được ghi cả hai số, có index ở
cuối joined.md (merge-gate 0 vs 52 dòng log — 52 dòng là selftest của astragentic, không phải
nizzy; tdd-gate 39 vs 16 vì log chỉ còn 3,3 ngày). 94 thành phần trong inventory không có số ở
cả hai lượt đo (phần lớn là trường của dispatch-record, message của mod, bước ADAPT/UNINSTALL).
