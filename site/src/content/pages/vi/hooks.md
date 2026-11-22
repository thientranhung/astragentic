---
title: "Hook"
description: "Sáu loại sự kiện hook Claude Code, bảy lệnh, cộng một mod. Hook chặn lệnh git sai, ghi lần chạy test, nạp lại contract sau compact, đưa trạng thái tracker vào đầu session, ghi log subagent và giải phóng tài nguyên worktree."
harness: v6.1.19
source: harness/.claude/settings.json, harness/scripts/hook-git-guard.py, harness/scripts/hook-test-run.py, harness/scripts/hook-contract-reload.py, harness/scripts/hook-tracker-status.py, harness/scripts/release-worktree-resources.sh, harness/.claude/skills/astragentic-dispatch/hooks/register.tsx
---

`harness/.claude/settings.json` đăng ký 6 loại sự kiện hook của Claude Code, tổng cộng 7 lệnh. Mod `astragentic-dispatch` đăng ký thêm các sự kiện của riêng nó.

Hook luôn đứng sau contract. Luật nào quan trọng phải nằm trong contract, vì hook có thể bị tắt hoặc chưa được trust. Mỗi lệnh dưới đây là một file chạy được bằng tay, và lệnh trong `settings.json` chỉ gọi file đó.

## pre-tool-use

Một lệnh chạy `scripts/hook-git-guard.py` trước mỗi lần agent gọi tool `Bash`. Script từ chối lệnh git có thể phá việc của người khác, hoặc không nói gì.

Hook từ chối kèm câu lệnh cần chạy thay thế và không bao giờ tự thi hành gì. `PreToolUse` chạy khi quyền còn đang được quyết, nên mọi thứ nó sửa là tác dụng phụ của một lệnh có thể vẫn bị từ chối.

- **Staging.** `git add -A` và `git add .` không có pathspec bị từ chối, kèm danh sách file đang thay đổi để lần sau stage theo đường dẫn.
- **Worktree.** `git worktree add` cần đường dẫn tuyệt đối. `git worktree remove` bị từ chối khi worktree còn thay đổi chưa commit, khi tài nguyên chưa được giải phóng, hoặc khi còn tiến trình có cwd thật nằm trong đó.
- **Role chỉ đọc.** Pane BA không chạy lệnh ghi lên repo. Pane Quick Builder chỉ được nhánh `ops/<slug>`, merge `--ff-only` và push của nhánh đó.
- **Push.** Push mang merge chưa có bằng chứng `ticket-done` hoặc chưa có dòng `Ledger:` bị từ chối. Luật này còn nằm ở `scripts/pre-push-ticket-done.sh`, chạy như hook `pre-push` của git.

Script tách token và soi argv thay vì match regex trên chuỗi lệnh thô. Bản regex đầu tiên vừa cho lọt `/usr/bin/git add -A` vừa chặn nhầm một `printf` chỉ chứa mấy chữ đó.

**Số đo.** Trên log một ngày, 84 của 319 lệnh (26%) chứa heredoc, `$(...)` hoặc `( ... )` và không được đọc. Sau khi bỏ qua dấu `(` nằm trong chuỗi có quote, 13 của 20 lệnh push base từng không được xét hóa ra chỉ có dấu đó trong một câu `echo`. Với staging, 71 của 167 lần bị từ chối sau đó là đúng lệnh cũ gõ lại, nên từ 4.1.0 lần từ chối liệt kê sẵn các path.

**Cái giá.** Đây là lint chống nhầm tay, không phải hàng rào. Ba lượt gate đối kháng, mỗi lượt tìm được một đường đi qua. Script chỉ nhận một dạng lệnh, là các lệnh đơn ngăn nhau bằng toán tử không nằm trong ngoặc, và im lặng trước heredoc, substitution, comment, wrapper hay interpreter. Pane junior chạy runtime khác gửi tên tool khác nên hook không thấy lệnh của nó.

## post-tool-use

Hai lệnh cùng chạy `scripts/hook-test-run.py`: một ở `PostToolUse`, một ở `PostToolUseFailure`, cả hai với matcher `Bash`. Script ghi mỗi lần chạy test vào `/tmp/harness-test-runs/<git toplevel>.log`, mỗi dòng là thời điểm, exit status và 200 ký tự đầu của lệnh.

Lý do tồn tại: commit gate cần biết một test đã đỏ trước commit nội dung đầu tiên hay chưa. Một lần gọi skill chỉ là một dòng trong record, còn test đỏ mới là thứ TDD đòi. Mod không thấy kết quả của tool vì sự kiện của nó chạy trước lời gọi, nên hook ghi trạng thái và mod đọc file.

Hai trạng thái đặc biệt không bao giờ được tính là 0:

- **`background`.** Lệnh chạy nền chưa có exit code. Hook nhắc pane chạy test ở foreground trước commit đầu tiên.
- **`masked`.** Sau lệnh test có `;`, `|`, `||` hoặc xuống dòng, nên exit code tool báo là của lệnh sau. Hook nhắc pane chạy test một mình.

Lệnh nào là test do `.astraler/project/test-command-pattern` quyết, hoặc theo danh sách mặc định gồm `go test`, `pytest`, `vitest`, `jest`, `cargo test`, `npm test` và các runner phổ biến.

**Số đo.** 61 của 161 ticket downstream trong 14 ngày tới 2026-10-26 viết code trước rồi mới gọi skill tdd, và 15 ticket không gọi lần nào. Bản 4.5.2 chỉ đăng ký `PostToolUse`, mà lệnh thoát non-zero đi vào `PostToolUseFailure`, nên không lần đỏ nào được ghi và mọi Builder trung thực bị từ chối ở commit đầu tiên. 4.5.3 đăng ký cả hai sự kiện.

**Cái giá.** Hook chỉ nhận ra runner nằm trong pattern. Project dùng runner khác thêm đúng một dòng vào plug.

## session-start

Hai lệnh bắn ở `SessionStart`, một có matcher `compact` và một không có matcher.

`scripts/hook-contract-reload.py` bắn sau khi session compact, với `source: compact`. Nó nạp lại đường dẫn contract của role qua `hookSpecificOutput.additionalContext`, trước khi agent hành động.

Contract nằm ở `.agents/roles/<role>.md` và vào hội thoại như kết quả của tool Read, mà compaction tóm tắt kết quả tool trước tiên. Thứ còn lại là system prompt với bốn luật. Dòng "đọc contract ngay" trong system prompt vẫn còn sau compact, nhưng chữ "ngay" thì không: agent thấy bản tóm tắt báo việc đang dở và kết luận mình đang giữa session.

Hook bắn ở `compact` mà không ở `clear`. Sau `/clear` agent gặp context rỗng và tự đọc contract. Mọi nhánh thoát của script in JSON hợp lệ hoặc không in gì, vì traceback trên stderr khiến runtime coi hook là hỏng.

`scripts/hook-tracker-status.py` bắn ở đầu mọi session. Nó chạy plug `.astraler/project/tracker-status.sh` của project, hoặc `scripts/tracker.sh counts` với project khai tracker `jira <KEY>`, rồi đưa số đếm vào context. Counts nằm sẵn trong context nên báo cáo trạng thái không tốn gì, và bỏ sót là thấy ngay. Plug vắng chỉ sinh một dòng ghi chú, và đầu ra bị cắt ở 4.000 ký tự kèm lời báo đã cắt.

**Số đo.** Trong một session dài compact một lần, bốn luật nằm trong system prompt được tuân thủ trọn session và mọi luật ngoài system prompt đều bị vi phạm.

**Cái giá.** Hook chỉ có hiệu lực trên Claude Code. Hook tracker chỉ đọc, và nếu mirror cần push thì contract của role nói việc đó.

## subagent-stop

Hook bắn mỗi khi một subagent kết thúc. Lệnh nằm thẳng trong `settings.json`: đọc JSON từ stdin và ghi một dòng vào `~/.local/state/astragentic/harness-hook-events.log`, gồm `agent_type`, `agent_id`, `session_id` và kích thước payload. Biến `HARNESS_HOOK_LOG` đổi đường dẫn.

Hook không chặn gì. Log này là file chung của máy: git guard, hai hook `SessionStart`, `tracker.sh` và mod cùng ghi vào đó. Từ 6.1.8 nó nằm ngoài `/tmp`, vì `/tmp` bị xóa khi reboot và log đếm được bắt đầu từ lần khởi động cuối.

**Số đo.** Chưa đo số sự kiện `SubagentStop` mỗi ngày.

**Cái giá.** Hook rẻ nhất trong bảy lệnh, nhưng nó chỉ ghi. Nó cho biết một subagent đã dừng, không cho biết việc đó đúng hay sai.

## worktree-remove

Hook chạy `scripts/release-worktree-resources.sh` với `$WORKTREE_PATH` khi Claude Code gỡ một worktree, và ghi một dòng vào log hook.

Script giải phóng đúng thứ tự những gì worktree đã cấp phát. Trước là phần harness biết, tức tiến trình có cwd thật nằm trong worktree, do `reap-worktree-processes.sh` reap. Sau là phần project khai, qua plug `.astraler/project/cleanup-worktree.sh`.

Thứ tự này chịu lực. Tài nguyên buộc vào một thư mục theo cwd hoặc theo tên suy ra từ đường dẫn không còn khớp được khi thư mục đã mất, nên bước này chạy trước `git worktree remove`. Plug phải giới hạn trong đúng worktree đó. Plug vắng được báo là rỗng, vì một no-op im lặng không phân biệt được với một lần giải phóng thành công.

Thomas gỡ worktree bằng `git worktree remove` trong lệnh Bash. Đường đó có hai lớp đỡ: git guard từ chối khi tài nguyên chưa được giải phóng, và mod chạy script này trước lệnh gỡ trên worktree đã ghi record, sạch, mà agent không còn giữa lượt.

**Số đo.** Khi harness chưa có plug, một đêm downstream để lại 43 tiến trình mồ côi, 3.405 database (25 GB), load average 123, và OS giết một Builder.

**Cái giá.** Chưa đo việc sự kiện `WorktreeRemove` có bắn khi worktree bị gỡ bằng lệnh `git worktree remove` trần hay không. Vì vậy hai lớp đỡ ở trên giữ nguyên.

## mod

Mod `astragentic-dispatch` (v1.0.3) là plugin của Claude Code, ở `harness/.claude/skills/astragentic-dispatch/hooks/register.tsx`. Nó thay ba bước dispatch mà dispatcher hay quên bằng việc pane tự làm.

- **Record.** Pane có tab label `ticket:`, `spec:`, `qa:` hoặc `resident:` tự ghi tab id và pane id vào `.astraler/state/dispatch-record.json` ở đầu session.
- **Brief.** Tin nhắn từ dispatcher thành một lượt user thật: dòng đầu bắt đầu bằng `/` chạy qua `$.command.run`, còn lại qua `$.prompt.submit`. Pane trả lời `RECEIVED` ngay.
- **TURN-END.** Khi lượt do dispatcher khởi động kết thúc, pane gửi `TURN-END` kèm lời cuối, và bản mod của dispatcher đánh thức dispatcher.

Mod đăng ký các sự kiện `session.start`, `turn.start`, `turn.complete`, `prompt.compose`, `prompt.submit`, `session.send`, `session.receive`, `skill.prompt`, `tool.call` và `ui.render`, cùng hai lệnh `dispatch-board` và `tracker-refresh`. Từ 4.6.1 mod chặn `ScheduleWakeup` trong pane được dispatch, và nó chặn lệnh `herdr` trong session Orca cũng như lệnh `orca` trong session Herdr.

**Số đo.** Từ lúc turn kết thúc đến lúc dispatcher được đánh thức là dưới 1 giây, so với khoảng trễ 67 giây của việc poll trạng thái pane.

**Cái giá.** TURN-END là cái chuông, không phải bằng chứng. Nó nói một lượt đã kết thúc, không nói việc đúng, nên Thomas vẫn kiểm bằng artifact. Mod chết cùng pane nên không báo được pane đã chết.
