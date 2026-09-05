# Hợp đồng build đợt 1 (2026-09-04)

Mọi agent tham gia đọc file này trước. Nó là giao diện giữa người dựng khung, người viết
nội dung, và người vẽ diagram. Ai đổi gì ở đây phải báo team-lead.

## 0. Nguyên tắc viết

- Site là **người làm ra Astragentic kể vì sao mình chọn như vậy**. Không phải khoá học.
  Cấm các từ: dạy, học, bài học, tutorial, lesson, learn, teach, "bước 1/bước 2" kiểu hướng dẫn.
  Dùng: vì sao, lý do, quyết định, cái giá, nhìn vào bên trong.
- Giọng theo `content/vibe-engineering-story/03-voice-guide.md`. Ngôn ngữ: **tiếng Anh**
  cho site (khớp README, RELEASE-NOTES, page draft). Tên skill, lệnh, mã ticket giữ nguyên.
- **Không bịa số liệu.** Mọi con số, mã defect (AST-xxx), tên project downstream phải có
  nguồn trong repo. Không chắc thì bỏ, không thì đánh `<!-- UNVERIFIED: … -->`.
- Không có gì thì nói không có. Ranh giới tự nêu ("Nothing yet proves the whole loop")
  giữ nguyên, không làm mềm.

## 1. Vị trí và stack

- Code site: `site/` trong repo này. Riêng `package.json`, không dùng workspace.
- Astro 5 + Tailwind 4 (qua `@tailwindcss/vite`), static output, không SSR, không CMS.
- `site/portless.json` = `{ "name": "astragentic" }`. `astro.config.mjs` đọc
  `PORT`/`HOST` từ env như quy ước ở `~/.claude/CLAUDE.md`, không hardcode port,
  không auto-open khi có `PORTLESS_URL`.
- Font: Source Serif 4 (prose, display) và JetBrains Mono (khung, nhãn, số), self-host
  qua `@fontsource-variable/source-serif-4` và `@fontsource-variable/jetbrains-mono`.
  Không font thứ ba.
- Token màu và component: theo `content/site/02-design-direction.md` §3 và §5. Tên token
  giữ đúng: `--paper --paper-sunk --ink --ink-muted --rule --pass --defect`.
- Motion duy nhất: lane diagram ở trang chủ (`02-design-direction.md`). Tôn trọng
  `prefers-reduced-motion`.

## 2. Content collections (hợp đồng frontmatter)

Đường dẫn: `site/src/content/<collection>/<slug>.md`. Người viết chỉ tạo file trong
các thư mục này. Người dựng khung tạo schema trong `site/src/content.config.ts` đúng như dưới.

### `skills/` — một skill một trang, route `/skills/<slug>`

```yaml
title: dispatch-ticket            # tên skill đúng như trong harness
oneLiner: "Hand one ready ticket to one Builder in its own worktree."  # câu động từ
group: main-flow                  # entry | main-flow | shaping | gate | brownfield | upkeep
order: 1                          # thứ tự trong group
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/dispatch-ticket/SKILL.md   # đường dẫn trong repo
rented: false                     # true nếu skill thuê từ mattpocock-skills
diagram: ticket-lifecycle         # slug diagram, tuỳ chọn
updated: 2026-09-04
```

Body theo đúng thứ tự heading H2, bỏ mục nào không có nội dung thật:

1. `## What it does` (2 đoạn; đoạn hai nói điểm khác và nguồn rắc rối)
2. `## When Thomas reaches for it` (bảng "What is in front of you → Reach for")
3. `## Prerequisites`
4. `## What it leaves behind` (bảng "What happened → Where it lands": commit, gate file, tracker field)
5. `## Known failures` (kéo từ `harness/.agents/memory/recurring-failure-modes.md`,
   ghi mã AST, nói rõ fixed hay open)
6. `## It's working if` (5 gạch kiểm tra được)
7. `## Where it fits` (chain text `a → b → c`, láng giềng gần, link)

### `dictionary/` — một thuật ngữ một trang, route `/dictionary/<slug>`

```yaml
term: Worktree
oneLiner: "One checkout per ticket, so two agents never share a HEAD."
order: 3                          # thứ tự khái niệm trong index, không theo ABC
related: [claim, frontier]        # slug khác trong dictionary
diagram: parallel-lanes           # tuỳ chọn
updated: 2026-09-04
```

Body: (1) một câu định nghĩa in đậm đứng riêng; (2) hai đoạn cơ chế, mọi thuật ngữ
khác đều link `/dictionary/<slug>`; (3) một đoạn `Why it matters here`, nói vì sao
Astragentic chọn vậy và cái giá; (4) `Seen in:` liệt kê nơi nó xuất hiện thật (file,
skill, release note); (5) `Usage:` hai câu hội thoại minh hoạ.

### `essays/` — bài dài, route `/essays/<slug>`

```yaml
title: "Vibe coding gives you speed. Vibe engineering keeps it."
description: "…"
date: 2026-09-04
readingMinutes: 9
```

### `pages/` — 5 trang mặt tiền, route theo slug (`home` → `/`)

Frontmatter: `title`, `description`. Body là markdown có thể dùng component MDX
(`site/src/content/pages/*.mdx`) để gọi Lane diagram, Stat trio, Receipt, Defect card…

## 3. Đợt 1: danh sách cụ thể

**Skill pages (6):** dispatch-ticket, codex-arm, review-with-rin, dispatch-qa-walk,
reconcile-tracker, bootstrap-glossary. Nguồn: `harness/.agents/skills/<name>/`,
`harness/.claude/skills/<name>/`, `harness/.agents/roles/`, `docs/distilled/`,
`RELEASE-NOTES.md`, ledger.

**Hub `/skills`:** liệt kê đủ 16 skill trong `harness/.agents/skills/` và 5 role trong
`harness/.claude/agents/`, nhóm theo lúc cần dùng. Skill chưa có trang: hiện tên + một
dòng, không link. Khối bốn ô "What Astragentic is": The problem / What it does /
Why it compounds / Runs on what you already use. Changelog: 5 bản gần nhất từ
`RELEASE-NOTES.md`, version + ngày + một dòng.

**Dictionary (12), theo thứ tự index:** harness, role, tracker, frontier, claim,
blocking-edge, worktree, brief, pass-marker, gate, cross-vendor-arm, ledger.

**Essay (1):** từ `content/vibe-engineering-story/drafts/01-first-draft.md` và
`01-outline.md`.

**Pages (5):** từ `content/site/pages/{home,why,architecture,compare}.md`. Trang
`/evidence` viết mới từ `RELEASE-NOTES.md` và `harness/.agents/memory/INDEX.md`,
khung "vì sao mình ghi ledger", không phải bảng số.

## 4. Diagram (archify)

Nguồn JSON: `content/site/diagrams/<slug>.<type>.json`. Validate profile `showcase`, 0 lỗi
0 warning. Deliver HTML vào `site/public/explore/<slug>.html` (bản tương tác, có pan/zoom).
Trích inline `<svg>` từ HTML đã deliver ra `site/src/assets/diagrams/<slug>.svg`, gỡ
`width/height` cứng, giữ `viewBox`, để component `Diagram.astro` nhúng và đổi màu theo token.

| slug | type | dùng ở |
|---|---|---|
| five-roles | architecture | /architecture, hub |
| ticket-lifecycle | workflow | /architecture, skills/dispatch-ticket |
| parallel-lanes | sequence | /, dictionary/worktree |
| ticket-states | lifecycle | dictionary/claim, /evidence |
| frontier-query | dataflow | dictionary/frontier, /why |
| layer-map | architecture | /compare |
| hub-and-spokes | architecture | /architecture |
| cross-vendor-arm | sequence | /evidence, skills/codex-arm |

Nhãn node và edge viết theo giọng lý do, không khô: "asks the tracker what is ready,
instead of remembering" thay cho "queries frontier". Ngôn ngữ tiếng Anh.

## 5. Thứ tự và ranh giới

- Builder tạo `site/` và mọi thứ ngoài `site/src/content/**` và `site/src/assets/diagrams/**`.
- Writer chỉ tạo file trong `site/src/content/{skills,dictionary,essays,pages}/`.
- Diagrammer chỉ tạo `content/site/diagrams/**`, `site/public/explore/**`,
  `site/src/assets/diagrams/**`.
- Humanizer chạy **sau cùng** trên mọi file trong `site/src/content/**`, dùng
  `03-voice-guide.md` và `drafts/01-first-draft.md` làm mẫu giọng, không đổi claim, không
  đổi frontmatter.
- Không ai commit. Team-lead review rồi commit.
