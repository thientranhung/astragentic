# Làm mới site theo v6.1.19 (2026-11-22)

Lời chủ site (chat 2026-11-22): site rời xa harness; viết lại cơ chế review; bỏ archify, thay bằng
diagram-design; thêm đủ role (BA, Quick Builder…); nêu Herdr + Orca, Codex runtime thứ hai và các
kỹ thuật Claude Code; mỗi bài mang version lúc viết, khớp release GitHub, để lần nâng cấp sau
biết căn cứ mà cập nhật. Chia việc theo model để tối ưu chi phí.

## Hiện trạng đo được

| số đo | nguồn |
|---|---|
| site đứng ở 4.0.4, harness 6.1.19 (khoảng 40 bản) | `site/src/data/meta.json`, `RELEASE-NOTES.md:1` |
| lần sửa cuối `site/` + `content/`: 2026-10-18 | `git log -1 -- site content` |
| Rin vẫn là role, 697 hit / 34 file; BA, Quick Builder 0 hit | audit subagent 2026-11-22, `site/src/lib/roles.ts` |
| mattpocock/BMAD 74 hit; `astra-*` 0 hit | audit subagent |
| Orca 0 file | `grep -rIl -i orca site/src content` |
| 17 diagram archify (`src/assets/diagrams/*.svg` + `public/explore/*`), 79 file nhắc archify | `ls`, `grep -rIl -i archify site/src site/public` |
| tag `v*` trên origin: 254, có `v6.1.19`; GitHub Releases mới tới `v6.1.0` | `git ls-remote --tags origin`, `gh release list` |
| `pnpm build` pass, 61 trang | audit subagent |

## Version stamp (theo từng bài, không theo site)

- `meta.json` là stamp toàn site, và chính nó đã trôi (4.0.4) mà không ai biết. Stamp phải nằm ở
  từng bài.
- Thêm một field frontmatter `harness: v6.1.19` (tag `v*` có thật trên origin) cho mọi
  collection; layout in "Viết theo v6.1.19" và link tới `…/tree/v6.1.19`. Dùng lại field
  `source` để liệt kê đường dẫn harness mà bài mô tả.
- Lần cập nhật sau: `git diff <harness>..HEAD -- <source>` cho ra đúng những gì bài phải xem lại.
  Không thêm checker mới.
- Chỉ stamp bài đã được kiểm lại trong đợt này; bài chưa kiểm để trống field, build in cảnh báo
  "chưa stamp", không bulk-stamp.
- Link trỏ tag (luôn có). GitHub Releases dừng ở v6.1.0: chủ site quyết có đăng release cho tag
  hay không; site không phụ thuộc.

## Thứ tự và chia model

Mỗi file chỉ một người viết. Điểm tranh chấp: `landing/*.yaml`, `content.config.ts`, `roles.ts`,
`skill-catalog.json`: làm tuần tự ở đợt 1.

| # | việc | model | vì sao model này |
|---|---|---|---|
| 0 | Fact sheet `content/site/23-facts-6.1.19.md`: role, skill, hook (settings + mod), luồng review mới (astra-review, codex-arm, 4 lens agent, 6.1.18/6.1.19), host Herdr/Orca, Codex runtime, tính năng Claude Code dùng thật; mỗi dòng `số \| nguồn` đọc ở tag v6.1.19 | Opus | sai ở đây lan ra mọi bài |
| 1 | Nền: field `harness` trong schema + hiển thị; xoá Rin khỏi `roles.ts`, `skill-catalog.json`, `HomeBody`; `_redirects` cho `/roles/rin`, `/skills/review-with-rin` (+ `/vi/`); `meta.json` 6.1.19 | Sonnet | cơ học, có build loop |
| 2 | Pilot diagram: `five-roles` → sáu role bằng diagram-design (font Newsreader cho vi); chốt pipeline thay archify: số phận của `diagram.css` `.c-*`, `lib/diagram.ts`, `public/explore/*`, `normalise-explore-pages.mjs` trong `build`/`deploy`, `InteractiveDiagram.astro` | Opus | quyết định kiến trúc một lần |
| 3 | Văn tiếng Việt: home, why, structure, roles (6 role), trang review mới; English mirror cùng commit | Opus viết vi, Sonnet mirror en | chủ site chỉ duyệt vi |
| 4 | Thay mattpocock/BMAD bằng `astra-*`: tech-stack, tips, landing; trang skill mới cho `astra-*`, `test-design`, `astragentic-dispatch`; xoá `review-with-rin`; sửa `codex-arm` theo 6.1.19 | Sonnet (theo fact sheet) | khối lượng lớn, khuôn có sẵn |
| 5 | Lệnh cài `get.sh --plan/--apply`, quickstart, "seven things", số đếm role/skill/hook | Sonnet | đối chiếu README |
| 6 | Hooks page theo `settings.json` + hook mod; Herdr/Orca + Codex runtime vào tech-stack, structure | Sonnet | theo fact sheet |
| 7 | Vẽ lại diagram còn giữ theo pipeline đã chốt ở bước 2 | Sonnet | lặp khuôn pilot |
| 8 | Quét: hit Rin / mattpocock / archify / `install.sh` (có ranh giới từ) trước và sau, link chết, id heading vi (mẫu `[^"\s]+`), vi/en đủ cặp | Haiku | grep thuần |
| 9 | Build từ clone sạch: exit code + số trang; chủ site duyệt vi; deploy khi chủ site đồng ý | Sonnet build, Opus báo cáo | |

Giọng: `14-voice-v2.md`, research register (một khung mỗi mục: trả lời, cơ chế, số đo, cái giá),
văn kỹ thuật đọc lướt, thuật ngữ vi chuẩn ngành, không nêu tên dự án nào. Brief cho mỗi subagent
chép các luật này vào, vì subagent không thừa hưởng memory.

## Diagram: giữ hay bỏ (chốt sau fact sheet)

| diagram | dự kiến |
|---|---|
| five-roles | vẽ lại thành sáu role (pilot) |
| client-studio, layer-map, structure, parallel-lanes | vẽ lại: thêm BA/Quick, Herdr/Orca, Codex |
| cross-vendor-arm, ticket-lifecycle, ticket-states | vẽ lại theo luồng review 6.1.18/6.1.19 |
| hooks, hook-pre-tool-use, hook-session-start, hook-subagent-stop, hook-worktree-remove | vẽ lại theo `settings.json` hiện tại; thêm PostToolUse(Failure) nếu giữ trang từng hook |
| skill-routing | vẽ lại theo `astra-*` |
| frontier-query, hub-and-spokes, customize-loop | đối chiếu fact sheet, còn đúng thì vẽ lại, không thì bỏ |

## PRD: chủ site sửa `09-prd.md` (agent không sửa)

Đề xuất đổi: §2.3 role → Thomas, BA, Shaper, Builder, QA, Quick Builder (bỏ Rin); §2.5 bỏ câu
mattpocock-skills vs Superpowers, thay bằng vì sao skill riêng `astra-*`; §2.6 tech stack →
Claude Code (mod, hook, agent, skill, subagent, advisor), Codex, Herdr, Orca, git worktree,
tracker adapters, diagram-design cho chính site (bỏ OpenCode, archify); §3 ngôi → "tôi/bạn"
(đã chốt 2026-09-05); thêm §: mỗi bài mang version harness lúc viết.
