---
title: "Tech stack"
description: "Chín thành phần của stack, và vì sao là thành phần đó chứ không phải thứ khác. Mỗi thành phần kèm chỗ nó đã gây lỗi."
---

Danh sách này ngắn có chủ đích. Mỗi thành phần ở đây phải trả lời được câu "bỏ nó ra thì cái gì
gãy", và thành phần nào chỉ gây bất tiện nhỏ khi bỏ đi thì tôi đã bỏ. Ba thành phần đầu là
runtime, ba thành phần giữa là cơ chế, ba thành phần cuối là thứ tôi tự viết hoặc tự chọn để
dựng chính trang này.

## claude-code

Runtime gốc. Agent của cả năm role đều chạy được ở đây, và `claude --dangerously-skip-permissions --agent thomas --model claude-opus-5 --effort medium` là câu lệnh mở đầu một
session. Nếu bạn chỉ cài đúng một runtime thì phải là runtime này.

Nó bắt buộc vì hai cơ chế sau chỉ tồn tại ở đây:

- **System prompt tách khỏi contract.** `.claude/agents/<role>.md` là system prompt và sống sót
  qua compaction, còn `.agents/roles/<role>.md` vào session như một tool result và bị compaction
  tóm tắt đi trước tiên.
- **Compaction.** Codex và OpenCode không có cơ chế đó, nên `hook-contract-reload.py` chỉ đăng ký
  ở Claude Code, và đó là quyết định có chủ đích chứ không phải chỗ quên.

## codex

Runtime tuỳ chọn, có mặt vì cross-vendor arm. Không có vendor thứ hai thì arm đó không tồn tại,
và arm là cơ chế có sản lượng bắt lỗi cao nhất trong hệ này.

Ba thư mục mang phần Codex:

- **`.codex/profiles/`.** Template khởi động pane cho từng role.
- **`.codex/agents/`.** Hai helper agent chỉ đọc.
- **`.codex/hooks.json`.** Đăng ký git guard.

Giới hạn nằm ở thư mục cuối: Codex duyệt định nghĩa hook project-local theo hash, nên nếu chưa có
quyết định trust thì guard vẫn nằm đó, vẫn trông như đã cài, và bị bỏ qua. Doctor kiểm phần đăng
ký, còn xác nhận trust thì phải gõ `/hooks` trong Codex CLI.

## opencode

Runtime thứ ba cho dispatch role, adapter nằm ở `.opencode/agents/`. Nó có mặt để
`.agents/orchestrator.md` không bị kẹt vào đúng một vendor.

Giới hạn: một Builder chạy OpenCode không có hook tương đương `hook-git-guard.py`. Đó là một
trong hai lý do luật thứ tự dọn dẹp phải nằm trong `dispatch-ticket/CLEANUP.md` trước, trong hook
sau. Lý do còn lại là cả Claude lẫn Codex cũng có thể chạy với hook tắt.

## git-worktree

Đây là ranh giới isolation thật, và nó là git chứ không phải nội quy. Mỗi ticket một checkout
riêng tại `.claude/worktrees/<branch-slug>`, đường dẫn tuyệt đối và nằm trong repo, tạo bằng
`git worktree add -b <ticket-branch> <worktree-path> <base>`. Builder là người ghi duy nhất
trong đó. Thomas, Rin và Builder khác đều chỉ đọc, không ai ghi.

Chỗ dễ hiểu nhầm là worktree giữ cái gì. Nó giữ nội dung git được track và không giữ gì khác:

- **Database container.** Không bị cô lập.
- **Tiến trình nền.** Không bị cô lập.
- **Đường dẫn cố định ngoài checkout.** Bất cứ gì một công cụ ghi ra đó cũng không bị cô lập.

Xoá thì phải bằng `git worktree remove`, không bao giờ bằng `rm -rf`. Xoá thô để lại đăng ký
trong `.git/worktrees/`, rồi lần `add` sau ở đúng đường dẫn đó sẽ bị từ chối.

## herdr

Trình quản lý workspace terminal, floor `>= 0.8.0`. Nó cho mỗi agent một pane mở ra nhìn được,
và cho phép nhắc, chờ, đọc từng pane. Đây là thứ biến dispatch từ một câu kể thành một vật đếm
được.

`dispatch-ticket` từ chối dispatch nếu `herdr-watchdog.sh` chưa chạy, và nó kiểm ngay ở lần
dispatch đầu tiên. Giới hạn tôi phải học lại: AST-107 cho thấy `herdr agent wait` không đáng tin
cho phần verdict. Bây giờ `herdr-watch-terminal.sh` chờ theo lát 60 giây và lấy verdict từ một
lệnh `herdr agent get` mới tinh ở mỗi lát; wait bị hạ xuống thành giấc ngủ có thể ngắt. Độ trễ
phát hiện xấu nhất là 60 giây, không phải cả session.

## mattpocock-skills

Toàn bộ phần craft được thuê từ đây, floor `>= 1.2.3`, cài dưới dạng plugin.

- **Bước có người gọi.** `wayfinder`, `grill-with-docs`, `to-spec`, `to-tickets`, `implement`,
  `code-review`.
- **Phần craft model tự gọi khi cần.** `grilling`, `tdd`, `codebase-design`, `domain-modeling`,
  `research`, `prototype`, `diagnosing-bugs`, `wizard`, `resolving-merge-conflicts`.

Lợi ích của việc cài một lần là cả team có craft, vì skill model-invoked không cần đấu dây gì
thêm.

**Đánh đổi.** `check-requirements.sh` fail cứng khi thiếu nó, và địa chỉ
`/mattpocock-skills:<name>` nằm rải khắp các contract. Đổi method là viết lại contract chứ không
phải sửa một dòng config.

## trackers

Astragentic không ship tracker. Nó ship ba adapter là `github-issue-tracker`,
`jira-issue-tracker` và `linear-issue-tracker`, mỗi adapter mô tả cách lái đúng một backend:
status biểu diễn thế nào, claim ghi ở đâu, blocking edge diễn đạt ra sao.

Thứ cố định không phải adapter mà là `.agents/tracker-contract.md`: năm thứ mà pipeline cần ở
bất kỳ tracker nào. Nhờ vậy Thomas đọc `docs/agents/issue-tracker.md`, biết dự án này dùng
adapter nào, rồi lái y hệt nhau bất kể backend.

**Đánh đổi.** Đã nêu ở trang vì sao: mỗi backend mang theo cái bẫy riêng, và GitHub Issues không
có trường status thật nên status phải nằm trong label.

## scripts

Phần Python và Bash tôi tự viết. Ba script đại diện cho ba loại:

- **`hook-git-guard.py`.** Chặn trong lúc quyền còn đang được quyết.
- **`herdr-watchdog.sh`.** Chạy nền suốt session và phải đang chạy trước mọi dispatch.
- **`ledger-index.sh`.** Chạy sau khi payload đổi, không phải sau khi công việc đổi.

Luật tôi rút ra: mỗi script phải có một khoảnh khắc gọi và một người sở hữu. Script thiếu một
trong hai là script không ai chạy cho tới khi mọi chuyện đã hỏng.

**Đánh đổi.** Bản 2.5.0 là bằng chứng ngược: nó ship adapter mang id ticket thật của một dự án
khác, một index đã cũ, và hai contract vượt hạn mức chữ. Ba loại lỗi, không loại nào nhìn thấy
được bằng cách đọc, tất cả do một giờ làm việc cẩn thận trước đó sinh ra. Bản 2.5.1 là đúng ba
cái vá đó và không có gì khác.

## archify

Mọi diagram trên trang này được dựng bằng `archify`. Nguồn là JSON ở
`content/site/diagrams/<slug>.<type>.json`, đầu ra là HTML đứng độc lập cùng SVG nhúng, nên một
hình vừa bấm được trên trang vừa đọc được ngoài trang.

Diagram được mô tả bằng dữ liệu thay vì vẽ tay, vì trang này song ngữ. Mỗi diagram có
một bản dịch ở `content/site/diagrams/vi/`, dịch title, label, nhãn edge, tên lane và note, giữ
nguyên tên role, tên skill, lệnh, mã AST và tên file. Vẽ tay hai lần thì hai bản sẽ lệch nhau ở
lần sửa thứ ba.
