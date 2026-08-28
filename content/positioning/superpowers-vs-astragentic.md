# Superpowers vs Astragentic — tư liệu định vị

Ghi ngày **2026-08-28**, đối chiếu **Astragentic 2.7.12** với **Superpowers 6.3.0**.

Đây là **tư liệu nguồn** cho website giới thiệu Astragentic, không phải bài viết. Mọi con số
trong phần "Đã xác minh" đọc trực tiếp từ file trên máy hoặc từ repo này — dùng được trên
trang public. Phần "Chưa xác minh" thì không.

---

## 1. Cách thu thập

| Nguồn | Trạng thái |
|---|---|
| `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.3.0/` — đọc `skills/`, `hooks/hooks.json`, `RELEASE-NOTES.md` | Đã xác minh |
| `~/.claude/plugins/installed_plugins.json`, `~/.claude.json` — version, scope, usage | Đã xác minh |
| Repo này — `README.md`, `check-requirements.sh`, `docs/adr/0001`, `docs/audit/2026-08-26-dissection.md` | Đã xác minh |
| Bài blog / review bên thứ ba về token cost, danh sách open issue | **Chưa xác minh — không đưa lên web** |

---

## 2. Đã xác minh về Superpowers 6.3.0

Tác giả Jesse Vincent (obra), MIT, cài qua marketplace `claude-plugins-official`.

- **14 skills**: `brainstorming`, `writing-plans`, `executing-plans`,
  `subagent-driven-development`, `dispatching-parallel-agents`, `test-driven-development`,
  `systematic-debugging`, `requesting-code-review`, `receiving-code-review`,
  `verification-before-completion`, `using-git-worktrees`, `finishing-a-development-branch`,
  `writing-skills`, `using-superpowers`.
- **0 agents, 0 commands.**
- **1 hook**: `SessionStart`, matcher `startup|clear|compact` — bơm bootstrap vào *mọi*
  session mới, kể cả session sinh ra sau `/clear` và sau compact.
- Hỗ trợ nhiều harness: Claude Code, Codex, Cursor, Copilot CLI, OpenCode, Devin, Hermes,
  Pi, Kimi, Antigravity, Grok Build.

### Nhịp release (từ `RELEASE-NOTES.md` của chính plugin)

| Version | Ngày | Nội dung chính |
|---|---|---|
| 6.3.0 | 2026-08-12 | Ceremony phân loại spike/bounded/architectural; controller tự ra *Ruling* thay vì dừng hỏi người; batch micro-task vào 1 dispatch; `worktree remove` không còn xoá file chưa commit |
| 6.2.0 | 2026-07-23 | Plan-scoped workspace; resume vòng review-fix |
| 6.1.1 / 6.1.0 | 2026-07-02 / 06-30 | Nén bootstrap; thêm marketplace Codex |
| **6.0.0** | **2026-06-16** | Viết lại review: gộp 2 reviewer prompt thành 1 `task-reviewer-prompt.md`; diff và task đi qua **file** thay vì paste vào context; **mọi dispatch bắt buộc khai model** |
| 5.1.0 | 2026-04-30 | — |

Tuyên bố của tác giả cho 6.0.0, nguyên văn trong release notes:
*"in our evals, Claude Code and Codex produce similar high-quality results roughly twice as
fast and while spending almost 50% fewer tokens."*
Đây là so 6.x với 5.x của chính nó — **không phải** so với Astragentic hay với mattpocock.

---

## 3. Bảng so sánh

Điểm mấu chốt: **hai thứ này không nằm cùng một lớp.** Astragentic là lớp điều phối và thuê
method từ ngoài; Superpowers gói method và điều phối vào chung một session.

| | **Astragentic 2.7.12** | **Superpowers 6.3.0** |
|---|---|---|
| Lớp | Orchestration; method thuê ngoài (`mattpocock-skills`) | Method **+** orchestration trong 1 session |
| Nơi giữ state công việc | **Issue tracker** — Linear / Jira / GitHub Issues, có frontier query, blocking edge, assignee-as-claim | File plan nằm trong branch |
| Isolation | 1 worktree + 1 herdr pane cho mỗi ticket; nhiều Builder chạy song song | Thư mục `.worktrees/` trong project; controller nằm trong session, gọi subagent |
| Vai trò | 5 role có contract — Thomas, Shaper, Builder, Rin, QA — nhân 3 runtime | Không có role; một controller |
| Review | 4 tầng: `code-review` 2 trục → simplify pass → **cross-vendor arm (Codex review artifact của Claude)** → Rin gate ở milestone | 1 reviewer cho mỗi task (trả 2 verdict) + 1 broad review cuối nhánh |
| QA sản phẩm chạy thật | Có — `dispatch-qa-walk` dựng app ở SHA đã review, đi journey thật | Không có |
| Brownfield | Có — `legacy-testing`, `untangle`, `batch-triage`, `bootstrap-glossary` | Không có |
| Enforcement | Hook Python + 12 script: git-guard, payload-drift, simplify-marker, reconcile-tracker, reap-worktree | 1 SessionStart hook |
| Đa runtime | Claude Code / Codex / OpenCode | 12+ harness |
| Nhịp release | 1–2 ngày; mỗi bản vá đúng một defect đo được | 4–6 tuần |

**Chi tiết đáng kể cho bài viết:** cả hai hệ đều tự đi tới cùng một hình dạng — worktree
isolation, một subagent tươi cho mỗi task, review hai trục spec + quality. Superpowers mất 6
major version để tới đó. Astragentic tới đó qua ADR 0001. Đây là bằng chứng hội tụ, không
phải chuyện ai sao chép ai, và nó là luận điểm mạnh hơn bất kỳ câu so sánh tính năng nào.

---

## 4. Bản đồ phủ: Superpowers có gánh được `mattpocock-skills` không?

Nửa sau: có. Nửa trước: không.

| Bước trong spine Astragentic | Superpowers |
|---|---|
| `wayfinder` / `grill-with-docs` | `brainstorming` — **một phần**. `grilling` chạy design-tree frontier và dừng khi frontier rỗng; brainstorming là Socratic tuyến tính. ADR 0001 chọn mattpocock **chính vì** cơ chế loop-ở-đầu này |
| `to-spec` | `brainstorming` đẻ spec doc — một phần |
| `to-tickets` | **Không có.** `writing-plans` đẻ ra plan markdown, không đẻ ra ticket trên tracker kèm blocking edge. Mà tracker là substrate điều phối của Astragentic |
| `implement` | `test-driven-development` + `subagent-driven-development` — **mạnh hơn**: RED-GREEN có evidence, thêm `verification-before-completion` |
| `code-review` | Từ 6.0.0 đúng 2 verdict spec + quality trong một pass — **rẻ hơn** bản mattpocock vốn spawn 2 subagent song song |
| `diagnosing-bugs` | `systematic-debugging` |
| `writing-for-agents` | `writing-skills` |
| `domain-modeling`, `codebase-design`, `research`, `wizard`, `resolving-merge-conflicts`, `grilling` | Không có |

### Ba rào cản cứng nếu muốn thay

1. `check-requirements.sh:108` **fail cứng** khi thiếu `mattpocock-skills >= 1.2.3`.
2. Harness hardcode địa chỉ `/mattpocock-skills:<name>` ở khắp contract. AST-051 ghi rõ
   `/implement` trần là fail. Đổi method = viết lại contract, không phải sửa config.
3. `docs/audit/2026-08-26-dissection.md` mục F đang liệt kê 7 defect ở **đường nối hiện tại**
   với mattpocock, F1 hạng P0. Đường nối này còn chưa vá xong.

---

## 5. Vì sao không chạy cả hai trong cùng một repo

Không phải vì thừa skill. Vì **hai orchestrator tranh nhau cùng một cái bàn**:

- `subagent-driven-development`, `using-git-worktrees`, `finishing-a-development-branch`,
  `dispatching-parallel-agents` là bản cài đặt cạnh tranh trực tiếp của Thomas,
  `dispatch-ticket` và CLEANUP.
- Hai lược đồ worktree khác nhau; hai substrate state khác nhau — plan file so với tracker.
- SessionStart hook bắn vào **mọi** pane Builder / Shaper / QA / Rin. Bootstrap đó dạy
  *"Do not pause to check in with your human partner"* và *"Rulings, not stalls"* — mâu thuẫn
  trực tiếp với giao thức handback và escalation-on-blocking-finding.
- Dissection E3 (P1) đã ghi: một diff hiện bị review 3 lần bằng cùng nhạc cụ. Thêm reviewer
  thứ tư làm nặng đúng chỗ đang đau.

Ngoài Astragentic — repo solo, không tracker, một session — Superpowers đứng một mình hoàn
chỉnh hơn. Hai thứ này sống chung được trên cùng một máy, chỉ là không chung một repo.

---

## 6. Dùng được gì cho website

### Luận điểm chống đỡ được bằng bằng chứng

1. **"Astragentic không cạnh tranh với method — nó điều phối method."** ADR 0001 là bằng
   chứng công khai: 19 skill vendored bị gỡ để nhường cho plugin upstream.
2. **"Ticket, không phải plan file."** Đây là khác biệt sạch nhất và kiểm chứng được: một
   plan markdown không trả lời được *ticket nào đang sẵn sàng*, tracker thì có.
3. **"Review có nhân chứng bên thứ ba."** Cross-vendor arm — Codex đọc artifact của Claude —
   không hệ nào ở trên có.
4. **"QA đi trên sản phẩm đang chạy, không đọc diff."** `dispatch-qa-walk`.
5. **"Brownfield là mặc định, không phải case đặc biệt."** `legacy-testing`, `untangle`,
   `batch-triage`, `bootstrap-glossary`.
6. **Hội tụ độc lập** — dùng đúng theo tinh thần mục 3.

### Không được viết

- Bất kỳ so sánh nào ngụ ý Superpowers kém. Nó rất tốt trong phạm vi của nó, và nó **được
  team dùng thật** ở project khác (`usageCount: 113`). Định vị là *khác lớp*, không phải
  *hơn kém*.
- Trích lại con số "2x nhanh hơn, 50% ít token hơn" như thể là so với Astragentic.
- Bất kỳ claim nào về token cost hay open issue của Superpowers lấy từ blog bên thứ ba —
  chưa xác minh.
- Giọng catalogue tính năng. Theo `content/vibe-engineering-story/README.md`: Astragentic chỉ
  xuất hiện sau khi người đọc đã cảm thấy vấn đề vận hành.

### Việc còn mở

- Một món đáng mượn từ Superpowers 6.0.0, không tốn dòng code nào: quy tắc **mọi dispatch
  phải khai model**. Họ đo được một run đặt cả 26 reviewer lên tier đắt nhất vì controller
  không khai. Đáng soi lại `dispatch-ticket*` và `codex-arm` xem có chỗ nào dispatch mà
  không pin model. *Đây là việc kỹ thuật, không phải nội dung website.*
