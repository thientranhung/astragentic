---
title: "Tech stack"
description: "Chín thứ Astragentic đứng lên, và vì sao là thứ đó chứ không phải thứ khác. Mỗi món kèm chỗ nó đã làm mình đau."
---

Danh sách này ngắn có chủ đích. Mỗi món ở đây phải trả lời được câu "nếu bỏ nó ra thì cái gì
gãy", và món nào chỉ trả lời được "thì hơi bất tiện" thì mình đã bỏ rồi. Ba món đầu là runtime,
ba món giữa là cơ chế, ba món cuối là thứ mình tự viết hoặc tự chọn để dựng chính trang này.

## claude-code

Runtime gốc. Cả năm vai đều chạy được ở đây, và `claude --agent thomas` là câu lệnh mở đầu một
phiên. Nếu anh em chỉ cài đúng một runtime thì phải là cái này.

Nó cũng là nơi mình đặt hai hook quan trọng nhất, vì hai cơ chế mình cần chỉ tồn tại ở đây. Thứ
nhất là chỗ tách system prompt khỏi contract: `.claude/agents/<role>.md` là system prompt và
sống sót qua compaction, còn `.agents/roles/<role>.md` vào session như một tool result và bị
compaction tóm tắt đi trước tiên. Thứ hai là chính compaction: Codex và OpenCode không có cơ
chế đó, nên `hook-contract-reload.py` chỉ đăng ký ở Claude Code, và đó là quyết định có chủ
đích chứ không phải chỗ quên.

## codex

Runtime tuỳ chọn, và lý do nó có mặt là cross-vendor arm. Không có một hãng thứ hai thì cái arm
không tồn tại, và arm là thứ có sản lượng bắt lỗi cao nhất trong toàn bộ hệ này.

Ba thư mục mang phần Codex: `.codex/profiles/` là template khởi động pane cho từng vai,
`.codex/agents/` là hai helper agent chỉ-đọc, và `.codex/hooks.json` đăng ký git guard. Chỗ cần
để ý là cái cuối: Codex duyệt định nghĩa hook project-local theo hash, nên nếu chưa có quyết
định trust thì guard vẫn nằm đó, vẫn trông như đã cài, và bị bỏ qua. Doctor kiểm đăng ký, còn
xác nhận trust thì phải gõ `/hooks` trong Codex CLI.

## opencode

Runtime thứ ba cho dispatch vai, adapter nằm ở `.opencode/agents/`. Nó có mặt để
`.agents/orchestrator.md` không bị kẹt vào đúng một hãng.

Mình nói thẳng chỗ nó yếu hơn hai runtime kia: một Builder chạy OpenCode không có hook tương
đương `hook-git-guard.py`. Đó là một trong hai lý do luật thứ tự dọn dẹp phải nằm trong
`dispatch-ticket/CLEANUP.md` trước, trong hook sau. Lý do còn lại là cả Claude lẫn Codex cũng
có thể chạy với hook tắt.

## git-worktree

Đây là ranh giới isolation thật, và nó là git chứ không phải nội quy. Mỗi ticket một checkout
riêng tại `.claude/worktrees/<branch-slug>`, đường dẫn tuyệt đối và nằm trong repo, tạo bằng
`git worktree add -b <ticket-branch> <worktree-path> <base>`. Builder là người ghi duy nhất
trong đó. Thomas, Rin và Builder khác đều chỉ đọc, không ai ghi.

Chỗ dễ hiểu nhầm là worktree giữ cái gì. Nó giữ nội dung git được track, và không gì khác: nó
không cô lập database container, không cô lập tiến trình nền, không cô lập thứ mà một công cụ
ghi ra một đường dẫn cố định bên ngoài checkout. Và xoá thì phải bằng `git worktree remove`,
không bao giờ bằng `rm -rf`. Xoá thô để lại đăng ký trong `.git/worktrees/`, rồi lần `add` sau
ở đúng đường dẫn đó sẽ bị từ chối.

## herdr

Trình quản lý workspace terminal, floor `>= 0.8.0`. Nó cho mỗi agent một pane có thể mở ra
nhìn, và cho phép nhắc, chờ, đọc từng pane. Đây là thứ biến "dispatch" từ một câu kể thành một
vật đếm được.

`dispatch-ticket` từ chối dispatch nếu `herdr-watchdog.sh` chưa chạy, và kiểm ngay ở lần
dispatch đầu tiên. Còn chỗ mình phải học lại: AST-107 cho thấy `herdr agent wait` không đáng
tin cho phần verdict. Bây giờ `herdr-watch-terminal.sh` chờ theo lát 60 giây và lấy verdict từ
một lệnh `herdr agent get` mới tinh mỗi lát; wait bị hạ xuống thành giấc ngủ có thể ngắt. Độ
trễ phát hiện xấu nhất là 60 giây, không phải cả session.

## mattpocock-skills

Toàn bộ phần craft được thuê từ đây, floor `>= 1.2.3`, cài dưới dạng plugin. `wayfinder`,
`grill-with-docs`, `to-spec`, `to-tickets`, `implement`, `code-review` là các bước có người
gọi; `grilling`, `tdd`, `codebase-design`, `domain-modeling`, `research`, `prototype`,
`diagnosing-bugs`, `wizard`, `resolving-merge-conflicts` là lớp craft được model tự gọi khi
cần.

Cái hay của việc cài một lần là cả đội có craft, vì skill model-invoked không cần đấu dây gì
thêm. Cái giá là `check-requirements.sh` fail cứng khi thiếu nó, và địa chỉ
`/mattpocock-skills:<name>` nằm rải khắp các contract. Đổi method là viết lại contract chứ
không phải sửa một dòng config.

## trackers

Astragentic không ship tracker. Nó ship ba adapter là `github-issue-tracker`,
`jira-issue-tracker` và `linear-issue-tracker`, mỗi cái mô tả cách lái đúng một backend: status
biểu diễn thế nào, claim ghi ở đâu, blocking edge diễn đạt ra sao.

Thứ cố định không phải adapter mà là `.agents/tracker-contract.md`: năm thứ mà pipeline cần ở
bất kỳ tracker nào. Nhờ vậy Thomas đọc `docs/agents/issue-tracker.md`, biết dự án này dùng
adapter nào, rồi lái y hệt nhau bất kể backend. Cái giá đã nói ở trang vì sao: mỗi backend mang
theo cái bẫy riêng, và GitHub Issues không có trường status thật nên status phải sống trong
label.

## scripts

Phần Python và Bash mình tự viết. Ba cái đại diện cho ba kiểu: `hook-git-guard.py` là lớp chặn
chạy trong lúc quyền còn đang được quyết; `herdr-watchdog.sh` là thứ chạy nền suốt và phải sống
trước mọi dispatch; `ledger-index.sh` là thứ chạy sau khi payload đổi, không phải sau khi công
việc đổi.

Luật mình rút ra: mỗi script phải có một khoảnh khắc và một người sở hữu. Script không có cả
hai là script không ai chạy cho tới khi mọi chuyện đã hỏng rồi. Bản 2.5.0 là bằng chứng ngược:
nó ship adapter mang id ticket thật của một dự án khác, một index đã cũ, và hai contract vượt
hạn mức chữ. Ba lớp lỗi, không cái nào nhìn thấy được bằng cách đọc, tất cả do một giờ làm việc
cẩn thận trước đó sinh ra. Bản 2.5.1 là đúng ba cái vá đó và không có gì khác.

## archify

Mọi diagram trên trang này được dựng bằng `archify`. Nguồn là JSON ở
`content/site/diagrams/<slug>.<type>.json`, đầu ra là HTML đứng độc lập cùng SVG nhúng, nên một
hình vừa bấm được trên trang vừa đọc được ngoài trang.

Mình chọn cách mô tả bằng dữ liệu thay vì vẽ tay vì trang này song ngữ. Mỗi diagram có một bản
dịch ở `content/site/diagrams/vi/`, dịch title, label, nhãn edge, tên lane và note, giữ nguyên
tên vai, tên skill, lệnh, mã AST và tên file. Vẽ tay hai lần thì hai bản sẽ lệch nhau ở lần sửa
thứ ba.
