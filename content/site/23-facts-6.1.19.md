# Fact sheet — harness v6.1.19 (tag `v6.1.19`, commit fa96d34)

Mọi bài viết trong đợt làm mới (`22-refresh-6.1.19.md`) chỉ được khẳng định điều có trong bảng
này hoặc trong nguồn mà bảng trỏ tới. Đường dẫn tính từ gốc repo. Site không nêu tên dự án,
khách hàng hay vendor nghiệp vụ nào (ruling 2026-09-13): số đo giữ, danh tính bỏ.

## 1. Mô hình

| sự thật | nguồn |
|---|---|
| Astragentic dựng lại quan hệ khách hàng / công ty outsource bằng agent; kỹ sư ngồi ghế khách hàng, chỉ nói với Thomas, xem được mọi thứ, không điều khiển từng agent | memory `project_astragentic_mental_model`; hero đã duyệt "Vibe coding đặt kỹ sư vào vai người gõ. Astragentic đặt kỹ sư vào vai khách hàng." |
| Tracker là bộ nhớ chung; adapter GitHub Issues, Jira, Linear | `harness/.claude/skills/{github,jira,linear}-issue-tracker/` |

## 2. Role: sáu, mỗi role là một custom agent Claude Code

| role | làm gì | không làm | nguồn |
|---|---|---|---|
| Thomas | deputy của owner; session thường trú; giữ tracker, frontier query, claim, dispatch, merge; chạy `reconcile-tracker`, `astra-ux` cùng owner, các skill dispatch, QA walk trước merge, slice gate | không tự quyết việc quan trọng thay owner | `harness/.claude/agents/thomas.md`, `harness/.agents/roles/thomas.md` |
| BA | ngồi ghế người dùng; chỉ đọc repo; bàn vấn đề tới khi rõ, đi thử sản phẩm đang chạy như actor mà không ghi; nêu trade-off và việc đang chạy bị quyết định làm mất giá trị; bàn giao bằng file markdown hoặc ticket owner duyệt. Owner tự mở (`claude --agent ba`), Thomas không dispatch | không sửa code, commit, dispatch, merge | `harness/.claude/agents/ba.md`; `thomas.md:24` |
| Shaper | `astra-grill-with-docs` → `astra-to-spec` → `astra-to-tickets` trong một context liền | | `harness/.claude/agents/shaper.md` |
| Builder | một ticket, một worktree, là người ghi duy nhất ở đó; thứ tự phase cố định (mục 4) | | `harness/.claude/agents/builder.md`, `harness/.agents/roles/builder.md:24-40` |
| QA | đi sản phẩm ĐANG CHẠY như người dùng (giao diện, journey, hợp đồng API, dữ liệu), không đọc diff; mặc định read-only, ghi phải có cho phép từng lượt; viết một file report. Mode: walk (UI), probe (API), verify (job) | | `harness/.claude/agents/qa.md`, `skills/dispatch-qa-walk` |
| Quick Builder | việc nhỏ theo lời owner (dòng catalog, ảnh, đẩy dữ liệu, sửa plug của project, thay đổi nhỏ) trên nhánh `ops/*` fast-forward vào main; không ticket, không vòng lặp; việc cần test/review thành ticket theo lời owner | không sửa harness upstream | `harness/.claude/agents/quick-builder.md`; 4.3.0, 6.1.11 |

Rin không còn từ 3.0.0. Ticket có hai loại `quick`/`full` theo label tracker (4.6.0); ticket quick chỉ chạy built-in review, không nợ marker.

## 3. Skill: 19 thư mục (18 skill + plugin mod `astragentic-dispatch`)

Chỉ skill tên `astra-*` (và skill vận hành riêng) được ship; tên Matt Pocock và BMAD đã bị thay từ 5.0 (quyết định 2026-10-29). `harness/.claude/skills/` và `harness/.agents/skills/` là bản soi, giống từng byte.

| nhóm | skill | nguồn |
|---|---|---|
| Shaping | `astra-ux` (journey UJ-n, actor vào PRD, trước spec), `astra-grill-with-docs` (câu hỏi đánh số, mỗi câu có đề xuất; agent tìm fact, owner quyết), `astra-to-spec` (spec lên tracker), `astra-to-tickets` (tracer-bullet ticket, cạnh prerequisite; ticket có surface mang Glance, States, Criteria), `test-design` (plan QA xếp theo rủi ro `docs/qa/plan-<slug>.md`) | `harness/.claude/skills/*/SKILL.md` |
| Build | `astra-implement-with-tdd` (mỗi criterion một test đỏ trước), `astra-ui` (audit/polish/upgrade theo DESIGN.md + Glance/States) | như trên |
| Review | `astra-review`, `codex-arm` | mục 4 |
| Dispatch | `dispatch-ticket` (Herdr pane), `dispatch-ticket-claude` (mod, launcher, runtime facts), `dispatch-qa-walk`, `dispatch-junior` (Builder giao phần cài đặt cho pane runtime khác, Grok trước; chỉ khi `orchestrator.md` có dòng Junior) | như trên |
| Tracker | `reconcile-tracker` (đối chiếu tracker với git, chỉ đọc), ba adapter | như trên |
| Vòng đời cài đặt | `astragentic-update-install` | như trên |

## 4. Luồng review (viết lại ở 6.1.18 / 6.1.19)

Thứ tự phase của Builder (full ticket): Build (`astra-implement-with-tdd`) → anti-slop read (UI) → UI pass (`astra-ui audit`, có bằng chứng trình duyệt) → Review (`astra-review`) → Simplify (một lần, sau commit nội dung cuối) → cross-vendor arm pass 1 → [fold → pass 2] → receipt `arm(ticket):` → handback. Nguồn: `harness/.agents/roles/builder.md:24-40,110-117`.

| sự thật | số đo | nguồn |
|---|---|---|
| `astra-review`: ba lens chạy cùng lúc, mỗi lens một context: correctness (built-in `code-review` của Claude Code), intent (subagent đọc ticket + criteria), standards (subagent đọc coding standards của repo) | | `harness/.claude/skills/astra-review/SKILL.md` §2 |
| lens thứ tư, adversarial (`astra-adversarial-lens`, Opus), chạy khi arm tắt hoặc arm NOT RUN | Opus 13 defect thật high/medium, precision 0.71; Sonnet 7, 0.46; ~109k token/ticket | `astra-review` §2; RELEASE-NOTES 6.1.18 |
| triage: đánh số R1…, kiểm từng finding tại dòng, một verdict + một câu bằng chứng (high/medium/low/false/maybe false), gom theo root cause F1…; route patch / decision_needed / defer; finding do thay đổi gây ra và đã verify thì không bao giờ defer | | `astra-review` §3–4 |
| Simplify chạy một lần, cuối | 57/244 session Builder từng chạy simplify 2–5 lần, ≈$335 / 14 ngày | `builder.md:36-40` |
| cross-vendor arm = một lần `codex exec` trực tiếp, read-only, không cần plugin Codex; model gpt-6.2-astra effort medium; ticket và slice đọc bằng `edge-lens.md`, spec bằng adversarial lens | arm 2,893 → 1,553 từ | `harness/.claude/skills/codex-arm/SKILL.md`; RELEASE-NOTES 6.1.19 |
| đo blind 7 ticket replay, 72 lượt, 336 finding | Codex edge (Astra) 21 defect thật/lượt, precision 0.77, ~79k token; Codex 29 / Claude 17 trên 34 defect thật | RELEASE-NOTES 6.1.18; `docs/audit/2026-11-21-review-dispatch-design.md` |
| hết quota / không có output đúng schema → `NOT RUN` kèm lý do, không bao giờ tính là pass; ticket rơi về lens adversarial Opus (same-vendor, advisory) | thử với quota hết: exit 1, `NOT RUN — usage limit` | RELEASE-NOTES 6.1.19 |
| AGENTS.md thù địch ("fix and commit") không làm arm ghi vào tree; model sai → NOT RUN | proof live 2026-11-21 | RELEASE-NOTES 6.1.18 |
| Slice gate do Thomas chạy khi slice đóng: slice arm + `astra-slice-reviewer` (fan-out adversarial, worktree riêng); ghi marker `arm(slice):`; >10 merge từ `arm(slice)` cuối = STOP | | `harness/.agents/roles/thomas.md:34,131,137-143` |
| Merge: Thomas kiểm bằng artifact; `check-simplify-markers.sh` từ chối merge thiếu receipt `simplify(increment)` / `arm(ticket)`; QA walk trước merge, marker `qa(walk)` | | `thomas.md:163-182` |

Chưa đo: lens ở scope spec và slice (quota Codex hết tới 2026-11-28); live downstream của 6.1.18/6.1.19.

## 5. Hook và mod: kỹ thuật Claude Code dùng thật

Hook Claude Code (`harness/.claude/settings.json`): 6 loại sự kiện, 7 lệnh.

| sự kiện | matcher | script | việc |
|---|---|---|---|
| PreToolUse | Bash | `hook-git-guard.py` | git guard theo role |
| PostToolUse, PostToolUseFailure | Bash | `hook-test-run.py` | ghi lần chạy test (4.5.3: cả lần fail) |
| SessionStart | compact | `hook-contract-reload.py` | nạp lại contract sau compact |
| SessionStart | | `hook-tracker-status.py` | trạng thái tracker đầu session |
| SubagentStop, WorktreeRemove | | ghi log `~/.local/state/astragentic/harness-hook-events.log` | |

Mod Claude Code: plugin `astragentic-dispatch` (`harness/.claude/skills/astragentic-dispatch/hooks/register.tsx`, v1.0.3). Pane được dispatch tự ghi record, chạy brief như một lượt user, báo turn end; dispatcher được đánh thức và xem board. Sự kiện: `session.start`, `turn.start`, `turn.complete`, `prompt.compose`, `prompt.submit`, `session.send`, `session.receive`, `skill.prompt`, `tool.call` (Bash ×6, Agent, Skill, AskUserQuestion, ScheduleWakeup), `ui.render` (AbovePrompt, Pane), lệnh `dispatch-board`, `tracker-refresh`. Mod chặn `ScheduleWakeup` trong pane được dispatch (4.6.1) và chặn lệnh chéo host.

Kỹ thuật Claude Code khác, có trong payload: custom agent theo role (`harness/.claude/agents/`), skill, subagent review (4 agent trong plugin: adversarial lens, slice reviewer, test architect, UI lens), built-in `code-review` và `simplify`, advisor (8 file, `grep -rwl advisor harness`), `--effort`, `CLAUDE_CODE_AUTO_COMPACT_WINDOW` cho pane (`dispatch-ticket-claude/SKILL.md:272`), SendMessage / ListAgents xuyên session, Monitor, git worktree. Code Mode: tắt (owner hoãn 2026-11-20), không đưa lên site.

## 6. Host và runtime

| sự thật | nguồn |
|---|---|
| Host terminal: Herdr (mặc định) và Orca (từ 6.1.0); một host cho một session: lệnh `herdr` trong session Orca và ngược lại bị từ chối | `dispatch-ticket-claude/SKILL.md:15,21,24`; RELEASE-NOTES 6.1.0 |
| Codex là runtime thứ hai (v6): overlay riêng, không thay payload Claude; vai riêng trong `.codex/roles/`, 20 entrypoint `codex-*`, host guard, Stop hook coordinator, bell TURN-END | `runtimes/codex/README.md`; `docs/codex/` |
| Claude lane là chuẩn tham chiếu; rule Codex được diff với Claude trước khi đổi | `AGENTS.md`; memory `feedback_claude_lane_is_the_reference` |

## 7. Cài đặt

| sự thật | nguồn |
|---|---|
| `curl -fsSL https://raw.githubusercontent.com/thientranhung/astragentic/main/get.sh \| bash` (ghim bản: `\| bash -s -- 6.1.19`), stage vào `.astraler/releases/<v>/`, không ghi file project | `README.md` Quickstart |
| `bash .astraler/releases/<v>/check-requirements.sh`; đưa `ADAPT-RUNTIME.md` cho agent hiện tại thực thi | `README.md` |
| `.astraler/astragentic.sh update`: bản đã cài, bản mới nhất, thay đổi, cách nâng | `README.md` |
| khởi động router: `claude --dangerously-skip-permissions --agent thomas --model claude-opus-5 --effort medium --advisor fable` | `README.md` |
| tag luôn có tiền tố `v`; updater chỉ đọc `refs/tags/v*`; trên origin có 254 tag | memory `project_release_tag_v_prefix`; `git ls-remote --tags origin` |

## 8. Số đếm dùng được trên site

6 role · 19 skill dir (gồm mod) · 6 loại hook Claude Code (7 lệnh) + 1 mod · 4 subagent review · 67 failure mode đã ghi (`harness/.agents/memory/recurring-failure-modes.md`) · 2 host · 2 runtime.
