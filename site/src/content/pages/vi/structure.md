---
title: "Cấu trúc"
description: "Bốn lớp: runtime chạy agent, harness chứa vai và luật, coordination giữ trạng thái, dưới cùng là repo của anh em. Astragentic chỉ là lớp ở giữa."
---

Astragentic không phải một runtime, cũng không phải một method. Nó là lớp nằm giữa hai thứ đó:
bên dưới là Claude Code, Codex hay OpenCode đang chạy model, bên trên là repo thật của anh em,
còn method thì mình thuê ngoài từ `mattpocock-skills`. Phần Astragentic tự viết là phần điều
phối, và chỉ phần đó thôi.

Mình chia làm bốn lớp vì mỗi lớp trả lời một câu hỏi khác nhau, và câu hỏi đó quyết định ai sở
hữu file nào. Lớp runtime trả lời "con agent này chạy bằng gì". Lớp harness trả lời "nó được
phép làm gì". Lớp coordination trả lời "cả đám đang ở đâu". Lớp cuối trả lời "dự án này thật ra
là cái gì", và đó là phần Astragentic không bao giờ được tự trả lời hộ.

## runtime

Ba runtime, và vai nào chạy trên runtime nào là dòng trong `.agents/orchestrator.md`, file của
anh em, upgrade không bao giờ đè lên. Claude Code là runtime gốc: cả năm vai đều chạy được ở
đây. Codex và OpenCode là tuỳ chọn, và chúng có mặt vì lý do rất cụ thể chứ không phải để khoe
số lượng.

Codex có mặt để làm nhân chứng. Cross-vendor arm cần một model của hãng khác đọc lại diff, nên
nếu chỉ có một runtime thì cái arm đó không tồn tại. OpenCode là lựa chọn thứ ba cho vai
Builder khi anh em muốn vậy.

Cái giá của việc đứng trên ba runtime thì mình nói thẳng: enforcement không đều nhau.
`hook-git-guard.py` được đăng ký ở Claude Code qua `.claude/settings.json` và ở Codex qua
`.codex/hooks.json`. Một Builder chạy OpenCode không có hook tương đương, và cả Claude lẫn
Codex đều có thể chạy với hook tắt hoặc chưa được trust. Nên luật thứ tự dọn dẹp phải nằm trong
contract trước, trong hook sau. Hook là lớp thứ hai, không phải hàng rào.

## harness

Đây là thứ `install.sh` mang vào repo của anh em: năm vai, mười sáu skill, bốn hook, và cuốn sổ
lỗi. Vai không chia theo chức danh mà chia theo tuổi thọ session, vì tuổi thọ session quyết
định vai đó còn nhớ được gì. Thomas sống suốt phiên. Shaper sống đúng một session không đứt.
Builder sống một ticket. Rin sống một vòng. QA sống một chuyến đi.

Mỗi vai có hai file, và chỗ đặt luật quan trọng hơn nội dung luật. `.claude/agents/<role>.md`
là system prompt, chỉ mang bốn dòng. `.agents/roles/<role>.md` là contract đầy đủ, vào session
qua tool Read nên nó nằm trong context như một tool result.

Mình đo được một chuyện trong một session dài có compact đúng một lần: bốn dòng trong system
prompt được tuân đúng cả phiên, còn mọi luật nằm ngoài nó đều bị vi phạm, và không luật nào
được ai phát hiện cho tới lúc chủ dự án hỏi. Tương quan là tuyệt đối. Đó không phải chuyện
agent lơ đãng, đó là budget context hoạt động đúng như nó được dựng. Nên bốn dòng đó cố định ở
bốn, và phần còn lại được nạp lại bằng hook chứ không bằng lời nhắc.

## coordination

Ba thứ giữ cho nhiều agent chạy cùng lúc mà không nổ: tracker, pane của herdr, và git worktree.
Điểm chung của cả ba là chúng đều nằm ngoài đầu của agent. Cái gì chỉ tồn tại trong context của
một session thì biến mất lúc session đó compact, và không ai biết nó đã biến mất.

Tracker giữ trạng thái công việc. Astragentic không ship tracker riêng, nó ship adapter cho
GitHub Issues, Jira và Linear, nên cái nào anh em đang dùng thì dùng tiếp. Trạng thái nằm ở đó
nghĩa là câu "ticket nào đang sẵn sàng" là một truy vấn, không phải một trí nhớ.

herdr giữ pane. Mỗi Builder một pane nhìn thấy được, và đây không phải chuyện thẩm mỹ: AST-018
đo được một lần dispatch chỉ được kể ra bằng chữ chứ chưa từng chạy, không có tín hiệu sống nào
để phân biệt. Một pane là thứ có thể đếm.

git worktree giữ ranh giới ghi. Mỗi ticket một checkout, Builder là người ghi duy nhất trong
đó. AST-016 đo được cái ngược lại: nhiều agent chung một checkout thì HEAD của người này bị
người kia kéo đi, kể cả một reviewer chỉ-đọc cũng `git switch` được checkout của người khác.

Cái giá là ba dependency ngoài: một tracker phải cấu hình, một herdr phải cài, và disk cho mỗi
worktree.

## project

Lớp dưới cùng là repo của anh em, và luật ở đây là Astragentic không được biết gì về nó ngoài
những thứ chính anh em khai. `docs/agents/issue-tracker.md` nói dùng tracker nào.
`.agents/orchestrator.md` nói vai nào chạy runtime nào, model nào. `CONTEXT.md` giữ từ vựng
miền, và ADR giữ những quyết định đã chốt. Không file nào trong số đó bị release ghi đè.

Chỗ mình học được ranh giới này đắt nhất là lúc dọn worktree. Harness biết đúng một thứ mà mọi
worktree đều cấp phát: tiến trình có cwd nằm trong đó. Mọi thứ còn lại là chuyện của project:
database, cổng đã đăng ký, container, broker, lease trên cluster dùng chung. Harness không thể
gọi tên bất kỳ thứ nào trong số đó mà không gọi tên stack của đúng một dự án.

Suốt bốn release nó đã làm đúng chuyện đó: một compose label và một tiến trình broker được
hardcode ở năm chỗ gọi khác nhau. Một project chạy stack khác đọc thấy dòng chữ "đã có cleanup"
rồi không giải phóng gì cả. Đo được ở downstream trong một đêm: 43 tiến trình mồ côi, 3.405
database thừa chiếm 25 GB, load average 123, một Builder bị hệ điều hành giết.

Nên bây giờ project tự khai bước dọn của mình thành một plug chạy được ở
`.astraler/project/cleanup-worktree.sh`, và `release-worktree-resources.sh` gọi nó sau khi đã
reap tiến trình. Một project không cấp phát gì ngoài git thì vẫn phải viết một file nói đúng
điều đó, vì một no-op im lặng không phân biệt được với một lần giải phóng thành công.

## good-parts

### Cuốn sổ lỗi

Mỗi lần có thứ hỏng, mình ghi một dòng vào một file chỉ thêm, không sửa, mỗi dòng một mã
`AST-<n>` không bao giờ được đánh số lại hay xoá đi. Hiện có {{meta.total}} dòng, và
{{meta.cited}} trong số đó đã bị buộc vào một file đang bắt ai đó làm khác đi hôm nay. Phần còn
lại vẫn nằm nguyên trong bảng chứ không bị lọc cho đẹp.

### Cross-vendor arm

Sau khi Claude viết xong, một model của hãng khác đọc lại diff và để lại biên nhận buộc vào
đúng SHA nó đã đọc. Lý do không phải là thích cho vui: một lần review cùng hãng đã cho lọt một
defect đem secret và PII vào file được track, và chính vòng cross-vendor bắt được nó ở mức P1.

### Tracker là substrate

Trạng thái công việc sống trên tracker của chính dự án chứ không trong một file plan nằm trong
branch. Khác biệt kiểm chứng được: một file plan không trả lời được câu "ticket nào đang sẵn
sàng ngay bây giờ", còn một truy vấn có blocking edge và assignee thì trả lời được.

### Claim trước worktree

Thứ tự là ghi assignee lên tracker, đọc lại, rồi mới `git worktree add -b`. Nhờ vậy hai session
nhìn thấy nhau trên chính tracker thay vì phát hiện va chạm sau khi cả hai đã viết code, và
không cần lock file hay dispatcher trung tâm nào cả.

### Review một vòng

Mỗi ticket đi qua ba tầng đúng một lượt: `code-review` hai trục Standards và Spec, simplify
pass, rồi cross-vendor arm. Hệ trước đó đo được 5 tới 14 vòng review cho một ticket, phần lớn
vòng sau là đi dọn thứ vòng trước để lại, nên mình bỏ vòng lặp và giữ nguyên độ nặng.
