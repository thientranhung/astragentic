---
title: "Cấu trúc"
description: "Bốn lớp: runtime chạy agent, harness chứa role và luật, coordination giữ trạng thái, dưới cùng là repo của bạn. Astragentic chỉ nằm ở giữa."
---

Astragentic không phải một runtime, cũng không phải một method. Nó nằm giữa hai thứ đó:
bên dưới là Claude Code, Codex hoặc OpenCode đang chạy model, bên trên là repo thật của bạn,
còn phương pháp thì dùng `mattpocock-skills`. Phần Astragentic tự viết là phần điều phối, và chỉ
phần đó.

Tôi chia làm bốn lớp vì mỗi lớp trả lời một câu hỏi khác nhau, và câu hỏi đó quyết định ai sở
hữu file nào. Lớp runtime trả lời "agent này chạy bằng gì". Lớp harness trả lời "nó được phép
làm gì". Lớp coordination trả lời "các agent đang ở đâu". Lớp cuối trả lời "dự án này là gì",
và đó là phần Astragentic không bao giờ được trả lời thay bạn.

## runtime

Ba runtime, và agent ở role nào chạy trên runtime nào là một dòng trong `.agents/orchestrator.md`,
file của bạn, upgrade không bao giờ đè lên. Claude Code là runtime gốc: agent của cả năm role đều
chạy được ở đây. Codex và OpenCode là tuỳ chọn, và chúng có mặt vì lý do cụ thể chứ không phải để
danh sách dài thêm.

Codex có mặt để làm nhân chứng. Cross-vendor arm cần một model của vendor khác đọc lại diff, nên
nếu chỉ có một runtime thì arm đó không tồn tại. OpenCode là lựa chọn thứ ba cho role Builder khi
bạn cần.

**Đánh đổi.** Dựa trên ba runtime khiến enforcement không đều nhau. `hook-git-guard.py` được đăng
ký ở Claude Code qua `.claude/settings.json` và ở Codex qua `.codex/hooks.json`. Một Builder chạy
OpenCode không có hook tương đương, và cả Claude lẫn Codex đều có thể chạy với hook tắt hoặc chưa
được trust. Vì vậy luật thứ tự dọn dẹp phải nằm trong contract trước, trong hook sau. Hook đứng
sau, không phải hàng rào.

## harness

`install.sh` mang vào repo của bạn năm role, mười sáu skill, bốn hook, và ledger lỗi. Role không
chia theo chức danh mà chia theo tuổi thọ session, vì tuổi thọ session quyết định agent ở role đó
còn nhớ được gì.

- **Thomas.** Session chạy thường trực.
- **Shaper.** Đúng một session không đứt quãng.
- **Builder.** Một session cho mỗi ticket.
- **Rin.** Một session cho mỗi milestone.
- **QA.** Một session cho mỗi lượt walk.

Mỗi role có hai file, và chỗ đặt luật quan trọng hơn nội dung luật. `.claude/agents/<role>.md`
là system prompt, chỉ mang bốn dòng. `.agents/roles/<role>.md` là contract đầy đủ, vào session
qua tool Read nên nó nằm trong context như một tool result.

**Bằng chứng.** Tôi đo được điều này trong một session dài có compact đúng một lần: bốn dòng trong
system prompt được tuân đúng cả session, còn mọi luật nằm ngoài nó đều bị vi phạm, và không vi
phạm nào được phát hiện cho tới lúc chủ dự án hỏi. Tương quan là tuyệt đối. Đó không phải chuyện
agent lơ đãng, đó là budget context hoạt động đúng như thiết kế. Vì vậy bốn dòng đó cố định ở
bốn, và phần còn lại được nạp lại bằng hook chứ không bằng lời nhắc.

## coordination

Ba thứ giữ cho nhiều agent chạy cùng lúc mà không va nhau: tracker, pane của herdr, và git
worktree. Điểm chung của cả ba là chúng nằm ngoài context của agent. Thứ gì chỉ tồn tại trong
context của một session sẽ biến mất lúc session đó compact, và không ai biết nó đã biến mất.

- **Tracker giữ trạng thái công việc.** Astragentic không ship tracker riêng; nó ship adapter cho
  GitHub Issues, Jira và Linear, nên bạn dùng tiếp board đang có. Trạng thái nằm ở đó nghĩa là câu
  "ticket nào đang sẵn sàng" là một truy vấn, không phải một trí nhớ.
- **herdr giữ pane.** Mỗi Builder có một pane nhìn thấy được, và đây không phải chuyện thẩm mỹ:
  Tôi đo được một lần dispatch chỉ được kể ra bằng chữ chứ chưa từng chạy, không có tín hiệu
  nào để phân biệt. Một pane là thứ đếm được.
- **git worktree giữ ranh giới ghi.** Mỗi ticket một checkout, và Builder là người ghi duy nhất
  trong đó. Lần khác tôi đo được điều ngược lại: nhiều agent chung một checkout thì HEAD của người này
  bị người kia kéo đi, và kể cả một reviewer chỉ đọc cũng `git switch` được checkout của người
  khác.

**Đánh đổi.** Ba dependency ngoài: một tracker phải cấu hình, một herdr phải cài, và disk cho mỗi
worktree.

## project

Lớp dưới cùng là repo của bạn, và luật ở đây là Astragentic không biết gì về nó ngoài những thứ
chính bạn khai.

- **Tracker.** Dùng tracker nào nằm ở `docs/agents/issue-tracker.md`.
- **Runtime và model.** Agent ở role nào chạy runtime nào, model nào nằm ở `.agents/orchestrator.md`.
- **Từ vựng miền.** `CONTEXT.md` giữ từ vựng miền dùng chung.
- **Quyết định đã chốt.** ADR giữ những quyết định đã chốt.

Không file nào trong số đó bị release ghi đè.

Ranh giới này tôi học được ở nơi tốn kém nhất: lúc dọn worktree. Harness biết đúng một thứ mà
mọi worktree đều cấp phát, là tiến trình có cwd nằm trong đó. Mọi thứ còn lại thuộc về project:
database, port đã đăng ký, container, broker, lease trên cluster dùng chung. Harness không thể
gọi tên bất kỳ thứ nào trong số đó mà không gọi tên stack của đúng một dự án.

**Bằng chứng.** Suốt bốn release nó đã làm đúng chuyện đó: một compose label và một tiến trình broker
được hardcode ở năm chỗ gọi khác nhau. Một project chạy stack khác đọc thấy dòng chữ "đã có
cleanup" rồi không giải phóng gì cả. Đo được ở downstream trong một đêm: 43 tiến trình mồ côi,
3.405 database thừa chiếm 25 GB, load average 123, một Builder bị hệ điều hành giết.

Nên bây giờ project tự khai bước dọn riêng thành một plug chạy được ở
`.astraler/project/cleanup-worktree.sh`, và `release-worktree-resources.sh` gọi nó sau khi đã
reap tiến trình. Một project không cấp phát gì ngoài git thì vẫn phải viết một file nói đúng
điều đó, vì một no-op im lặng không phân biệt được với một lần giải phóng thành công.

## good-parts

### Ledger lỗi chỉ thêm, không sửa

Mỗi lần có thứ hỏng, tôi ghi một dòng vào một file chỉ thêm, mỗi dòng một mã `AST-<n>` không
bao giờ được đánh số lại hay xoá đi. Hiện có {{meta.total}} dòng, và {{meta.cited}} trong số
đó đã buộc vào một file đang bắt ai đó làm khác đi hôm nay. Phần còn lại vẫn nằm nguyên trong
bảng chứ không bị lọc đi.

### Cross-vendor arm chốt trên đúng SHA

Sau khi Claude viết xong, một model của vendor khác đọc lại diff và để lại receipt buộc vào
đúng SHA nó đã đọc. Lý do không phải là đa dạng cho vui: một lần review cùng vendor đã cho lọt
một defect đem secret đang dùng thật và PII vào file được track, và chính vòng cross-vendor bắt
được nó ở mức P1.

### Tracker là substrate giữ trạng thái

Trạng thái công việc được lưu trên tracker của chính dự án, không nằm trong một file plan trong
branch. Khác biệt kiểm chứng được: một file plan không trả lời được câu "ticket nào đang sẵn
sàng ngay bây giờ", còn một truy vấn trên blocking edge và assignee thì trả lời được.

### Claim chạy trước khi tạo worktree

Thứ tự là ghi assignee lên tracker, đọc lại, rồi mới `git worktree add -b`. Nhờ vậy hai session
nhìn thấy nhau trên chính tracker thay vì phát hiện va chạm sau khi cả hai đã viết code, và
không cần lock file hay dispatcher trung tâm nào.

### Review chạy đúng một vòng

Mỗi ticket đi qua ba tầng đúng một lượt: `code-review` trên hai trục Standards và Spec, rồi
simplify pass, rồi cross-vendor arm. Hệ trước đó đo được 5 tới 14 vòng review cho một ticket,
phần lớn vòng sau dùng để dọn phần vòng trước để lại. Tôi bỏ vòng lặp và giữ nguyên độ nặng.
