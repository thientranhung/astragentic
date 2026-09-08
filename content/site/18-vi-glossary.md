# Glossary bản tiếng Việt: từ nào giữ tiếng Anh (2026-09-08)

Chủ site: "Tiếng Việt cho dân IT, Dev chứ không tiếng Việt toàn bộ." Ví dụ đưa ra: nút "CHÉP"
phải là "Copy". Áp cho mọi chuỗi trên site tiếng Việt: UI, landing yaml, pages, roles, skills.

## Giữ nguyên tiếng Anh (không dịch)

Hành động và UI: Copy, Copied, Install, Deploy, Build, Run, Read more, Explore, Open, Close,
Search, Filter, Back, Next.

Kỹ thuật chung: repo, branch, commit, merge, PR, diff, checkout, worktree, HEAD, SHA, push,
pull, CLI, API, terminal, pane, session, context, prompt, system prompt, profile, config, flag,
script, hook, plugin, runtime, provider, model, effort, token, log, watcher, timeout.

Từ vựng Astragentic: agent, role (khi là danh từ kỹ thuật; "vai" vẫn dùng trong văn kể),
skill, dispatch, claim, brief, frontier, blocking edge, gate, receipt, artifact, ledger,
contract, handback, milestone, story, backlog, ticket, issue, tracker, board, spec, review,
code review, simplify, arm, cross-vendor, walk (QA walk), compact, orchestrator.

Tên riêng: Claude Code, Codex, OpenCode, herdr, mattpocock-skills, Matt Pocock, Superpowers,
GitHub Issues, Jira, Linear, SendMessage, Monitor, Thomas, Shaper, Builder, Rin, QA.

## Dịch sang tiếng Việt (giữ)

Câu văn, động từ nối, giải thích: vì sao, cách, khi nào, bạn, tôi, đội, khách hàng, người
đại diện, quyết định, giám sát, quy trình, phương pháp, yêu cầu, lý do, bằng chứng, lỗi, cấu
trúc, tech stack (giữ), bắt đầu.

## Thay cụ thể (đã thấy trên site)

| Đang có | Đổi thành |
|---|---|
| Chép / Đã chép | Copy / Copied |
| Cài đặt (heading, nhãn, nav "Cài") | Install |
| Triển khai vào repo của bạn → | Deploy vào repo của bạn → |
| biên nhận | receipt |
| gác cổng (Rin) | gate |
| cổng review / cửa gate | review gate |
| chặng (7 chặng) | stage (bảy stage) |
| bàn giao | handback |
| nhánh | branch |
| thư mục làm việc | worktree |
| bảng (tracker) | board |
| phiên (session) | session |
| bộ nhớ chung | shared memory (giữ "bộ nhớ chung" trong văn kể, thêm "shared memory" lần đầu) |
| dòng lệnh | CLI |
| nhãn bắt buộc / tuỳ chọn / chọn một | required / optional / pick one |
| Khởi chạy | Launch |
| Đọc lại (log/pane) | Read |

Không đổi tên vai sang tiếng Anh trong headline lớn nếu câu đang đọc tự nhiên ("Năm vai"),
nhưng bảng và nhãn dùng "Role".

## Cách rà

grep toàn bộ `site/src/lib/ui.ts`, `anchors.ts`, `skills.ts`, `src/content/landing/vi.yaml`,
`src/content/{pages,roles,skills}/vi/*.md` theo cột "Đang có"; đổi trong ngữ cảnh, không thay
máy móc làm gãy câu. Không đổi heading id, anchor, frontmatter key, mã AST, trích nguyên văn.
