---
title: "Hook"
description: "Bốn hook, ba script. Một hook chặn lệnh git nguy hiểm, một hook nạp lại contract sau compact, một hook ghi log, và một hook tôi đo được là không còn được kích hoạt."
---

Bốn hook đăng ký ở `harness/.claude/settings.json`, riêng git guard đăng ký thêm ở
`harness/.codex/hooks.json`. Nguyên tắc chung của cả bốn là hook luôn đứng sau, contract luôn
đứng trước. Luật nào quan trọng thì phải nằm trong contract, vì contract được đọc
ở mọi runtime, còn hook thì có thể bị tắt, có thể chưa được trust, và có thể treo trên một
đường thi hành không ai đi qua.

Trường hợp cuối không phải giả thuyết. Một trong bốn hook dưới đây không còn được kích hoạt, tôi đo được điều
đó, và tôi để nguyên nó ở đây thay vì lặng lẽ gỡ đi.

## pre-tool-use

Hook bắn trước mỗi lần một agent định chạy tool `Bash`, trên cả Claude Code lẫn Codex, và nó
chạy `scripts/hook-git-guard.py`.

Script đọc lệnh sắp chạy rồi làm đúng một trong hai việc: từ chối kèm câu lệnh chính xác cần
chạy thay thế, hoặc không nói gì. Nó không bao giờ tự thi hành. Bản đầu tiên có chạy `git
worktree prune` và giết broker từ trong hook, và đó là sai về nguyên tắc. Hook `PreToolUse`
chạy trong lúc quyền còn đang được quyết, nên mọi thứ nó sửa là tác dụng phụ của một lệnh có
thể vẫn bị từ chối ngay sau đó.

Script tách token và soi argv chứ không match regex trên chuỗi lệnh thô. Một lượt cross-vendor
chứng minh bản regex vừa cho lọt vừa quá tay trong cùng một hơi thở: `/usr/bin/git add -A` và
`git -c k=v add -A` đi qua được, trong khi `printf '%s' "rm -rf .claude/worktrees/x"` bị chặn
chỉ vì chứa mấy chữ đó. Một guard vừa trượt trường hợp thật vừa chặn trường hợp vô hại thì dạy
chính người dùng nó cách đi vòng, và như vậy tệ hơn không có guard.

**Giới hạn.** Đây là lint chống nhầm tay, không phải hàng rào. Ba lượt gate đối kháng, mỗi lượt
tìm ra một đường mới đi xuyên qua nó, và lượt thứ ba kết luận matcher này không hội tụ. Câu trả
lời là thu nhỏ tuyên bố lại chứ không phải thêm luật. Bây giờ nó chỉ chấp nhận đúng một dạng
lệnh, là các lệnh đơn ngăn nhau bằng toán tử không nằm trong ngoặc, và im lặng trước mọi thứ có
substitution, heredoc, comment, từ khoá, wrapper hay interpreter. Im lặng ở đó là thiết kế, không
phải lỗ hổng: một tuyên bố phủ sóng không đúng sự thật còn tệ hơn không tuyên bố gì.

Còn một lý do nó là file `.py` chứ không phải một dòng shell nhét trong `settings.json`. Bản cũ
đúng là một dòng như vậy: không đọc được, không chạy tay được, không test được, và nó không
được kích hoạt qua nhiều release trong lúc trông vẫn như đã cài. Bản này chạy độc lập
được, nên nó kiểm tra được.

## worktree-remove

Hook bắn khi một worktree bị gỡ qua đường tool `EnterWorktree` / `ExitWorktree`, và nó chạy
`scripts/release-worktree-resources.sh` với `$WORKTREE_PATH`.

Việc của script là giải phóng theo đúng thứ tự những gì một worktree đã cấp phát. Trước hết là
phần harness biết: tiến trình có cwd thật nằm trong worktree, do `reap-worktree-processes.sh`
reap. Sau đó là phần project tự khai, qua plug `.astraler/project/cleanup-worktree.sh`. Thứ tự
này chịu lực. Tài nguyên buộc vào một thư mục, theo cwd hoặc theo label suy ra từ đường dẫn
hoặc theo cái tên project tự tính từ nó, không còn khớp được sau khi thư mục biến mất, nên bước
này phải chạy trước `git worktree remove`, không bao giờ sau.

**Vì sao biết.** Hook này không còn được kích hoạt, và tôi xác nhận bằng log: worktree bị gỡ,
kể cả bằng lệnh `git worktree remove` trần, mà không sự kiện `WorktreeRemove` nào được ghi, trong
khi một hook khác nằm cùng file vẫn ghi bình thường trong cùng khoảng thời gian đó.
Tôi kiểm lại theo một đường độc lập: container test dùng chung vẫn `Up (healthy)` sau lần gỡ, mà
một hook đang chạy thì đã dừng nó.

Nguyên nhân không phải hook hỏng, mà là hook không được chạm tới. `WorktreeRemove` treo trên
đường tool `EnterWorktree` / `ExitWorktree`, còn Thomas gỡ worktree bằng `git worktree remove`
trong một lệnh Bash. Đó là git thuần, không có gì đứng giữa lệnh và repo, nên không có sự kiện
nào để bắn. Một hook treo trên đường thi hành không ai đi qua thì bắn đúng bằng một hook hỏng,
và nhìn từ bên ngoài hai thứ đó không phân biệt được.

Vì vậy bước dọn thủ công vẫn bắt buộc trên mọi runtime, và lệnh trong hook vẫn phải giữ an toàn
cho ngày nó được kích hoạt lại. Bài học tồn tại lâu hơn chính cái hook này: khi một cơ
chế không bắn, hãy hỏi trigger có được chạm tới không, trước khi kết luận cơ chế đã hỏng.

## session-start

Hook bắn ngay sau khi một session Claude Code compact, với `source: compact`, và nó chạy
`scripts/hook-contract-reload.py`.

Script nạp lại đúng một thứ: đường dẫn contract của role agent đang đảm nhiệm, qua
`hookSpecificOutput.additionalContext`, tới tay agent trước khi agent kịp hành động.

Lỗi sinh ra nó, gọn trong một dòng: một chỉ dẫn không gắn với khoảnh khắc nào thì
đo được bằng không. System prompt đã có sẵn dòng "Read `.agents/roles/<role>.md` now", và dòng
đó đi qua compaction nguyên vẹn vì nó là system prompt. Thứ không đi qua được là chữ "now". Một
agent vừa compact đọc bản tóm tắt của chính nó, thấy công việc đang dở, kết luận nó đang giữa
session, và không bao giờ đọc lại. Chỉ dẫn vẫn nằm đó, và trơ.

Hai chi tiết là cố ý. Hook bắn ở `compact` chứ không ở `clear`, vì sau `/clear` agent đối diện
một context rỗng và tự đọc contract, còn sau compaction nó đối diện một bản tóm tắt khẳng định
việc đang chạy nên nó không đọc. Chính sự bất đối xứng đó là toàn bộ defect. Và hook chỉ có ở
Claude Code, vì Codex với OpenCode không có compaction, nên ở đó không có khoảnh khắc nào để
gắn vào.

Mọi nhánh thoát của script hoặc in ra JSON hợp lệ hoặc không in gì, và không nhánh nào ném
exception. Một traceback trên stderr sẽ bị runtime đọc là hook hỏng rồi tắt đi, và người vận
hành sẽ tiếp tục ship một harness trông như đã lên đạn.

## subagent-stop

Hook bắn mỗi lần một subagent kết thúc. Không có script riêng: hook đọc JSON từ stdin và ghi
thêm một dòng vào `/tmp/harness-hook-events.log`.

Nó ghi `agent_type`, `agent_id`, `session_id` và kích thước payload. Chỉ vậy, và nó không chặn
gì. Bản đầu đọc biến môi trường `$AGENT_NAME` và `$SESSION_ID` rồi nhận về chuỗi rỗng. Bản hiện
tại đọc stdin và lấy đúng trường.

Đây là hook rẻ nhất trong bốn cái, và nó trả lại giá trị lớn nhất ở một chỗ không ai thiết kế
trước. Nó là nhóm đối chứng. 27 sự kiện nó ghi được trong cùng cửa sổ thời gian là thứ biến
"không quan sát được gì" thành bằng chứng cho việc `WorktreeRemove` không còn được kích hoạt.
Không có chúng thì quan sát đó không phân biệt được với "toàn bộ hook đã bị tắt", và kết luận
đầu tiên, rằng hook đã hỏng, được rút ra khi chưa có nhóm đối chứng nào.

Ngoài chức năng đó, hook còn ghi lại lúc một Builder chết, thứ mà nếu không có log thì chỉ hiện
ra dưới dạng một pane im lặng.
