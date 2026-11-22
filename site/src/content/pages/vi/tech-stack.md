---
title: "Tech stack"
description: "Tám thành phần của stack: Claude Code, các kỹ thuật Claude Code dùng thật, Codex, Herdr, Orca, git worktree, tracker adapter và diagram-design. Mỗi thành phần nêu nó là gì, vì sao chọn nó, cơ chế và cái giá."
harness: v6.1.19
source: README.md, harness/.claude/settings.json, harness/.claude/agents/, harness/.claude/skills/astragentic-dispatch/hooks/register.tsx, harness/.claude/skills/dispatch-ticket-claude/SKILL.md, harness/.claude/skills/codex-arm/SKILL.md, harness/.claude/skills/astra-review/SKILL.md, harness/.agents/orchestrator.md, harness/scripts/herdr-watch-terminal.sh, runtimes/codex/README.md
---

Mỗi thành phần ở đây phải trả lời được câu "bỏ nó ra thì cái gì gãy". Thành phần nào chỉ gây bất tiện nhỏ khi bỏ đi thì tôi đã bỏ. Hai thành phần đầu là runtime chính, hai thành phần tiếp theo là runtime phụ và host terminal, phần còn lại là cơ chế dùng chung.

## claude-code

Claude Code là runtime của cả sáu role. Mỗi role là một custom agent trong `harness/.claude/agents/`, và router mở bằng `claude --dangerously-skip-permissions --agent thomas --model claude-opus-5 --effort medium --advisor fable`.

Tôi chọn nó vì ba cơ chế cần runtime hỗ trợ sẵn:

- **Custom agent.** `.claude/agents/<role>.md` là system prompt của role và sống sót qua compaction. Contract đầy đủ ở `.agents/roles/<role>.md` vào session như một tool result.
- **Hook.** 6 loại sự kiện, 7 lệnh trong `settings.json`: git guard, ghi lần chạy test, nạp lại contract sau compact, trạng thái tracker, log subagent, giải phóng worktree. Chi tiết ở trang hook.
- **Mod.** Plugin `astragentic-dispatch` (v1.0.3) làm các bước dispatch mà dispatcher hay quên: ghi record, chuyển brief thành một lượt user, báo `TURN-END`, kiểm tracker trước brief.

**Cái giá.** Hook và mod chỉ có hiệu lực trên Claude Code. Một runtime khác nhận contract bằng overlay riêng, như Codex ở mục dưới, và không nhận cơ chế hook của lane này.

## claude-techniques

Các tính năng Claude Code dưới đây được harness dùng thật. Mỗi mục có vị trí trong payload.

- **Subagent review.** Plugin có 4 subagent: adversarial lens, slice reviewer, test architect và UI lens. `astra-review` chạy ba lens cùng lúc, mỗi lens một context: correctness bằng built-in `code-review`, intent bằng subagent đọc ticket và criteria, standards bằng subagent đọc coding standards của repo.
- **Built-in `code-review` và `simplify`.** Harness không viết lại hai bước này. Simplify chạy một lần, sau commit nội dung cuối.
- **Advisor.** Cột Advisor trong `.agents/orchestrator.md` quyết định cờ `--advisor`: dòng Opus nhận `fable`, dòng Sonnet nhận `opus`, để trống là không có. Advisor phải xếp ngang hoặc cao hơn model chính.
- **`--effort`.** Chỉ thêm khi dòng orchestrator đặt giá trị `low|medium|high|xhigh|max`.
- **Auto-compact window.** `CLAUDE_CODE_AUTO_COMPACT_WINDOW` đặt trần context cho pane được dispatch, và `dispatch-ticket-claude` truyền cùng giá trị qua cờ `--autocompact 300000`.
- **SendMessage và ListAgents.** Hai session nói chuyện xuyên session, và mod biến tin nhắn của dispatcher thành lượt user thật.
- **Monitor.** Watcher của lane Herdr bọc `herdr agent wait` trong một Monitor. Lane Claude bỏ bước đó vì mod gửi `TURN-END`.

**Số đo.** Simplify từng chạy 2–5 lần trong 57 của 244 session Builder, khoảng $335 trong 14 ngày, nên nó chạy một lần ở cuối. Builder của một project downstream giữ trung vị 400–550k token context mỗi lần gọi, và trần 300k làm pane compact sau khoảng 170 lần gọi thay vì để context phình.

**Cái giá.** Tôi chỉ dùng tính năng có trong payload. Một tính năng mới của Claude Code chưa vào harness thì chưa tính. Code Mode đang tắt và không thuộc stack.

## codex

Codex CLI là runtime thứ hai theo hai cách khác nhau. Cách đầu là cross-vendor arm: một lần `codex exec` trực tiếp, read-only, không cần plugin Codex, model `gpt-6.2-astra` effort medium. Cách sau là overlay Codex v6, nơi cả bộ role chạy trên Codex.

Arm dùng vendor thứ hai vì model đọc lại diff của chính nó đọc lại luôn giả định của nó. Ticket và slice đọc bằng `edge-lens.md`, spec đọc bằng adversarial lens. Plugin Codex không còn được dùng ở 6.1.19 vì nó không cho đặt effort hay lens, để rò một broker mỗi lượt và thoát 0 khi cấu hình sai.

Overlay Codex nằm ở `runtimes/codex/`, không thay payload Claude. Nó có vai riêng trong `.codex/roles/`, 20 entrypoint `codex-*`, host guard, Stop hook của coordinator và bell TURN-END. Lane Claude là chuẩn tham chiếu: một rule Codex được diff với Claude trước khi đổi.

**Số đo.** Đo blind trên 7 ticket replay, 336 finding: Codex với edge lens tìm 21 defect thật mỗi lượt, precision 0.77, khoảng 79k token. Codex tìm 29 của 34 defect thật, Claude 17. Arm rút từ 2.893 xuống 1.553 từ ở 6.1.19.

**Cái giá.** Hết quota hoặc đầu ra sai schema thì arm báo `NOT RUN` kèm lý do, không bao giờ tính là pass, và ticket rơi về lens adversarial Opus. Lens ở scope spec và slice chưa đo, vì quota Codex hết tới 2026-11-28.

## herdr

Herdr là host terminal mặc định, phiên bản tối thiểu 0.8.0. Mỗi agent có một pane nhìn được, và Thomas nhắc, chờ, đọc từng pane. Việc đang chạy nhờ vậy là thứ đếm được thay vì đoán.

Watcher `herdr-watch-terminal.sh` chờ theo lát và lấy verdict từ một lệnh `herdr agent get` mới ở mỗi lát. Một lần `herdr agent wait` dài từng sống mà không bắn (AST-107), nên wait bị hạ xuống thành giấc ngủ có thể ngắt. `herdr-watchdog.sh` chạy nền, mặc định poll mỗi 300 giây, và preflight của `dispatch-ticket` ở lần dispatch đầu tiên của session đòi watchdog đang chạy.

**Số đo.** Poll trạng thái pane để lại khoảng trễ 67 giây giữa pane idle và dispatcher biết. Bell của mod rút nó xuống dưới 1 giây.

**Cái giá.** Status là cái chuông, không phải bằng chứng. Thomas vẫn kiểm artifact. Một host cho một session: lệnh `orca` trong session Herdr bị từ chối.

## orca

Orca là host terminal thứ hai từ 6.1.0. Session mở trong Orca chỉ dispatch bằng Orca, và lệnh `herdr` trong session đó bị từ chối. Pane tự ghi record từ biến môi trường `ORCA_*` và `ASTRA_DISPATCH` trong lệnh khởi động.

Mod nhận ra host từ môi trường của pane: có `ORCA_PANE_KEY` là Orca. Record, brief và bell `TURN-END` dùng cùng cách như ở Herdr. `orca terminal close` trên pane đang giữa lượt bị từ chối.

**Cái giá.** Mod chặn lệnh chéo host. Một terminal Orca có `connected: false` được coi là đã mất, còn `orphaned: true` đơn độc là một PTY còn sống không có pane UI.

## git-worktree

Worktree là ranh giới isolation thật, và nó là git chứ không phải nội quy. Mỗi ticket một checkout riêng, tạo bằng `git worktree add -b <ticket-branch> <worktree-path> <base>` với đường dẫn tuyệt đối. Builder là người ghi duy nhất trong đó.

Worktree giữ nội dung git được track và không giữ gì khác:

- **Database container.** Không bị cô lập.
- **Tiến trình nền.** Không bị cô lập.
- **Đường dẫn cố định ngoài checkout.** Không bị cô lập.

Phần không được cô lập là việc của hook `WorktreeRemove` và plug `cleanup-worktree.sh` của project. Xóa bằng `git worktree remove`, không bằng `rm -rf`, và git guard từ chối `rm -rf` trên đường dẫn worktree.

**Số đo.** Một đêm không có bước giải phóng để lại 43 tiến trình mồ côi, 3.405 database (25 GB) và load average 123.

**Cái giá.** Mỗi worktree là một checkout đầy đủ, nên disk và runtime phải được xử lý riêng. Trang tips mô tả cách.

## trackers

Astragentic không ship tracker. Nó ship ba adapter là `github-issue-tracker`, `jira-issue-tracker` và `linear-issue-tracker`, mỗi adapter mô tả cách vận hành đúng một backend: status biểu diễn thế nào, claim ghi ở đâu, blocking edge diễn đạt ra sao.

Thứ cố định không phải adapter mà là `.agents/tracker-contract.md`: những thứ pipeline cần ở bất kỳ tracker nào. Thomas đọc `docs/agents/issue-tracker.md`, biết project dùng adapter nào, rồi thao tác như nhau bất kể backend. Tracker là bộ nhớ chung: cái gì sẵn để làm là một câu truy vấn.

**Cái giá.** Mỗi backend mang cái bẫy riêng. GitHub Issues không có trường status thật nên status nằm trong label.

## diagram-design

Các figure của chính site này được vẽ bằng plugin `diagram-design`. Font serif tiếng Việt là Newsreader, vì Instrument Serif mặc định của plugin không có dấu tiếng Việt. Mỗi figure là một file HTML có SVG nhúng, với một bản `vi` và một bản `en`.

Site song ngữ, nên chỉ nhãn được dịch. Tên role, tên skill, lệnh và tên file giữ nguyên.

**Cái giá.** Pipeline figure còn đang chuyển sang plugin này. Số figure đã vẽ lại chưa đo.
