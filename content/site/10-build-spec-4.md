# Build spec đợt 4 (2026-09-04)

Đối chiếu với `09-prd.md`. Giữ từ đợt 3: Astro site ở `site/`, i18n vi mặc định + `/en/`, data
JSON sinh bằng `pnpm data`, InteractiveDiagram, token màu, khung 1200. Mọi thứ dưới đây sửa
hoặc thêm.

## 1. Ngôn ngữ sạch từng trang (PRD §4)

- **Diagram có bản Việt.** Mỗi JSON archify ở `content/site/diagrams/<slug>.<type>.json` có
  bản dịch `content/site/diagrams/vi/<slug>.<type>.json`: dịch title, label, sublabel, nhãn
  edge, tên lane/group, note. Giữ nguyên tên vai (Thomas, Shaper, Builder, Rin, QA), tên
  skill, lệnh, mã AST, tên file. Deliver ra `site/public/explore/vi/<slug>.html`, SVG ra
  `site/src/assets/diagrams/vi/<slug>.svg`. Frontend chọn theo lang.
- Nav, caption, tooltip, nhãn nút, chữ trong bảng: theo lang, không chèn Anh vào trang Việt.
- Trích nguyên văn ledger/release notes: khối riêng, nhãn mono "nguyên văn · tiếng Anh" trên
  trang Việt, giới hạn 2-3 dòng trên landing.

## 2. Cỡ (PRD §5)

- Body 17px/1.6. h1 clamp(34px, 3.6vw, 52px). h2 26-30px. Sub 18px muted.
- Diagram: khung rộng hết `--frame` trừ gutter (khoảng 1120px), không viền hộp dày, nền
  paper. Text trong SVG scale lên: CSS `.diagram-svg text { font-size: 1.18em }` hoặc render
  SVG ở width 100% với `min-height` theo tỉ lệ viewBox. Nhãn node phải ≥ 13px thực tế trên
  màn 1440.
- Landing: mỗi section ≤ 2 câu chữ, phần còn lại là hình, thẻ, hoặc danh sách ngắn.

## 3. Sitemap

```
/                    landing, 9 section (mục 4)
/cau-truc            các lớp của Astragentic + diagram structure     (en /en/structure)
/vai/<id>            5 vai, giữ đợt 3                                 (en /en/roles/<id>)
/skills              catalog kiểu aihero, nhóm theo lúc cần dùng      (en /en/skills)
/skills/<name>       16 trang, cả vi lẫn en                           (en /en/skills/<name>)
/hooks               4 hook + script chúng gọi                        (en /en/hooks)
/vi-sao              5 câu vì sao, mỗi câu một mục có anchor          (en /en/why)
/tech-stack          mình dùng gì, vì sao                             (en /en/tech-stack)
/loi, /bang-chung, /cai   giữ đợt 2-3
/kien-truc           gộp vào /cau-truc, redirect
/dictionary/<t>      giữ, không nav
```

Nav 7 mục, mono: Cấu trúc · Vai · Skills · Hooks · Vì sao · Tech stack · Cài (en tương ứng).
"Vai" trỏ `/vai/thomas`. Logo về `/`. VI · EN bên phải.

## 4. Landing, 9 section

1. **Hero**: headline mới theo PRD §2 (writer), 1 câu, 2 nút (Xem cấu trúc ↓ · Cài). Hình:
   diagram `structure` (mục 5) tĩnh.
2. **Cấu trúc**: diagram `structure` tương tác. Click lớp → `/cau-truc#<layer>`; click vai →
   `/vai/<id>`; click "skills" → `/skills`; click "hooks" → `/hooks`; click tracker →
   `/dictionary/tracker`.
3. **Năm vai**: giữ đợt 3.
4. **Một ticket qua bảy chặng**: giữ đợt 3.
5. **Từ tracker tới pane**: giữ đợt 3.
6. **Skill có sẵn**: lưới 16 thẻ nhỏ (tên mono + 1 dòng động từ, nhóm màu nhạt theo group),
   bấm → `/skills/<name>`. Nút "Cả catalog →" `/skills`.
7. **Hook đứng gác**: 4 thẻ (PreToolUse git guard · WorktreeRemove release · SessionStart
   compact reload · SubagentStop log), mỗi thẻ: khi nào bắn, chặn hay ghi gì, 1 dòng. Bấm →
   `/hooks#<hook>`.
8. **Vì sao**: 5 thẻ câu hỏi (mục 7), bấm → `/vi-sao#<slug>`.
9. **Tech stack + cài**: dải logo/tên mono 9 mục bấm → `/tech-stack#<slug>`; AdoptBlock 4
   lệnh; QuoteBlock thú nhận thu nhỏ (2 dòng) ở cuối, không phải mở đầu.

Section "Hai bên soi nhau" và "Bằng chứng" của đợt 3 chuyển thành một thẻ trong "Các phần hay"
ở `/cau-truc`, không còn trên landing.

## 5. Diagram mới (archify, cả vi lẫn en)

- `structure` (architecture): 4 dải ngang từ trên xuống: **Runtime** (Claude Code · Codex ·
  OpenCode), **Harness** (Roles: 5 · Skills: 16 · Hooks: 4 · Memory/ledger), **Coordination**
  (Tracker GitHub/Jira/Linear · herdr panes · git worktrees), **Project của anh em** (repo,
  CONTEXT.md, ADR). Edge: Thomas → tracker "hỏi frontier"; Builder → worktree; hooks → git
  "chặn lệnh nguy hiểm". Node id: runtime_claude, runtime_codex, runtime_opencode, roles,
  skills, hooks, ledger, tracker, herdr, worktrees, project. Tối đa 12 node.
- `hooks` (workflow): một lệnh Bash đi qua PreToolUse → git guard (cho/chặn) → chạy → …;
  WorktreeRemove → release; SessionStart(compact) → reload contract. Node id trùng tên hook.

## 6. Nội dung mới (writer), `site/src/content/`

- `pages/<lang>/structure.md`: 1 đoạn mở; `## runtime`, `## harness`, `## coordination`,
  `## project` mỗi mục 1-2 đoạn "vì sao lớp này tồn tại"; `## good-parts` 5 thẻ: ledger,
  cross-vendor arm, tracker là substrate, claim trước worktree, review một vòng (mỗi thẻ 2 câu).
- `pages/<lang>/why.md`: 5 mục có anchor: `## why-astragentic`, `## why-mattpocock`
  (nguồn: `content/positioning/superpowers-vs-astragentic.md`, ADR-0001; chỉ claim đã xác
  minh trong file đó), `## why-not-subagents` (nguồn: ledger AST-006 fork inherited Opus,
  AST-016 shared checkout, AST-018 dispatch narrated not executed, thomas.md; luận điểm: subagent
  chung checkout và chung context, không có tracker làm state, không có pane để nhìn),
  `## why-tracker`, `## why-cross-vendor`. Mỗi mục 2-4 đoạn, có cái giá.
- `pages/<lang>/tech-stack.md`: `## <slug>` cho 9 mục: claude-code, codex, opencode,
  git-worktree, herdr, mattpocock-skills, trackers, scripts (Python/Bash: git guard, watchdog,
  ledger-index), archify. Mỗi mục: làm gì trong Astragentic, vì sao chọn, 1-3 đoạn ngắn.
- `pages/<lang>/hooks.md`: 1 đoạn mở; `## pre-tool-use`, `## worktree-remove`,
  `## session-start`, `## subagent-stop`: khi nào bắn, script nào chạy
  (`scripts/hook-git-guard.py`, `release-worktree-resources.sh`, `hook-contract-reload.py`),
  chặn/ghi gì, lỗi ledger nào sinh ra nó (grep ledger theo tên script). Nguồn:
  `harness/.claude/settings.json`, `harness/.codex/hooks.json`, script.
- `skills/<lang>/<name>.md` cho 16 skill: 6 skill đã có bản en (đợt 1) → viết bản vi giữ
  cấu trúc; 10 skill còn lại (batch-triage, codex-claude-arm, dispatch-ticket-claude,
  dispatch-ticket-codex, dispatch-ticket-opencode, github-issue-tracker, jira-issue-tracker,
  legacy-testing, linear-issue-tracker, untangle) viết cả en lẫn vi, cấu trúc như đợt 1
  (What it does · When Thomas reaches for it · Prerequisites · What it leaves behind · Known
  failures · It's working if · Where it fits), heading dịch ở bản vi. Frontmatter thêm `lang`
  và `group` ∈ entry | main-flow | shaping | gate | brownfield | upkeep | adapter.
- `landing/<lang>.yaml`: thêm `hero` mới, `sections.structure`, `sections.skills`,
  `sections.hooks`, `sections.why`, `sections.stack`; `hooksCards` 4 dòng; `whyCards` 5 câu
  hỏi; `stackItems` 9 tên.

## 7. Ranh giới agent

- diagrammer: `content/site/diagrams/**`, `site/public/explore/**`, `site/src/assets/diagrams/**`.
- writer-core: `site/src/content/pages/**`, `site/src/content/landing/**`.
- writer-skills-a, writer-skills-b: `site/src/content/skills/**` (chia đôi danh sách).
- frontend: mọi thứ còn lại trong `site/`. Không sửa content/data thật.
- Không ai commit.
