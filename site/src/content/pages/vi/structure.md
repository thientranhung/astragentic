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

Khác biệt này quyết định luật nào còn hiệu lực sau compact: thứ nằm trong system prompt thì còn,
thứ nằm ngoài thì không, và agent không hề biết mình vừa mất luật. Đó không phải chuyện agent lơ
đãng, đó là budget context hoạt động đúng như thiết kế. Vì vậy bốn dòng đó cố định ở bốn, và phần
còn lại được nạp lại bằng hook chứ không bằng lời nhắc.

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

Rủi ro cụ thể: một bước dọn dẹp viết cứng theo stack của một dự án sẽ đọc đúng cú pháp nhưng
không giải phóng gì trên dự án dùng stack khác. Khi đó tiến trình mồ côi và database thừa tích lại
âm thầm cho tới lúc máy hết tài nguyên.

Nên bây giờ project tự khai bước dọn riêng thành một plug chạy được ở
`.astraler/project/cleanup-worktree.sh`, và `release-worktree-resources.sh` gọi nó sau khi đã
reap tiến trình. Một project không cấp phát gì ngoài git thì vẫn phải viết một file nói đúng
điều đó, vì một no-op im lặng không phân biệt được với một lần giải phóng thành công.

## good-parts

### Ledger lỗi: cơ chế tự học của harness

Mỗi lần có thứ hỏng, sự cố được ghi một dòng vào một file chỉ thêm, có mã cố định, không bao giờ
đánh số lại hay xoá đi. Dòng nào rút ra được luật thì luật đó đi vào một file mà agent thật sự
đọc, nên lần sau cả team làm khác đi. Dòng chưa rút ra được gì vẫn nằm nguyên đó chứ không bị lọc.

Đây là chỗ harness học từ chính lỗi của nó: lỗi không biến mất theo trí nhớ, nó thành luật hoặc
thành hồ sơ chờ.

### Cross-vendor arm chốt trên đúng SHA

Sau khi Claude viết xong, một model của hãng khác đọc lại diff và để lại receipt buộc vào đúng
SHA nó đã đọc. Lý do không phải là đa dạng cho vui: một model đọc lại diff của chính nó thì đọc
lại luôn giả định của nó, còn model của hãng khác không mang giả định đó.

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
simplify pass, rồi lượt đọc chéo của hãng khác. Ba tầng có biên rõ, nên độ chặt giữ nguyên mà số
vòng không tự nhân lên.
