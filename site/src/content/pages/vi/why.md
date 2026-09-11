---
title: "Vì sao"
description: "Năm câu hỏi về thiết kế của Astragentic: vì sao cần nó, vì sao tracker giữ trạng thái, vì sao không dùng subagent để điều phối, vì sao chọn mattpocock-skills, vì sao để một vendor khác đọc lại diff."
---

Năm câu dưới đây là năm quyết định thiết kế lớn nhất của Astragentic. Mỗi câu trả lời theo cùng
một khung: trả lời trong một dòng, cơ chế, số đo đã ghi nhận, và cái giá phải trả. Số đo mang mã
AST-xxx và có bài học tương ứng ở trang Bài học.

## why-astragentic

Một agent trong một branch không cần điều phối. Vấn đề xuất hiện từ agent thứ hai trên cùng một
repo: các session ghi đè việc của nhau mà không báo lỗi, review kéo dài vòng này qua vòng khác,
và cuối ngày không ai nói được chính xác cái gì đã chạy.

Astragentic làm cho những lỗi đó khó xảy ra về mặt cấu trúc, thay vì phải canh bằng mắt. Mỗi
Builder có worktree riêng, nên không ai ghi đè ai. Claim là một dòng assignee trên tracker, nên
hai session không nhận cùng một việc. Kết quả là commit và receipt, không phải lời báo cáo của
chính agent vừa làm.

Số đo: AST-016, ba session trên cùng một checkout, không lỗi nào được ném ra, một buổi làm việc
mất trắng và thêm một buổi nữa để tìm nguyên nhân. Từ đó isolation là vô điều kiện, kể cả với
agent chỉ đọc.

Cái giá: thêm một bộ công cụ phải cài, hiểu và nâng cấp, và mỗi bản nâng cấp là một sự kiện dự
án phải hấp thụ. Còn một điểm tôi nói thẳng: tới nay tôi mới chứng minh được từng công cụ chạy
đúng; cả vòng từ dispatch tới merge với đủ gate trên việc thật vẫn đang được đo.

## why-tracker

Trạng thái công việc phải sống ở một chỗ mà agent không giữ được trong context và bạn mở ra
nhìn được. Tracker là chỗ duy nhất thoả cả hai vế, nên ADR-0001 gọi nó là nền điều phối của
team, không phải sổ ghi chép.

Astragentic lấy ba thứ từ tracker. Blocking edge làm thành đồ thị phụ thuộc, nên "cái gì đang
chờ cái gì" là dữ liệu chứ không phải trí nhớ. Frontier query trả lời "cái gì sẵn sàng ngay bây
giờ". Assignee làm claim: ghi tên lên ticket trước khi tạo worktree là thứ giữ cho hai session
đồng thời không đụng nhau, không cần lock file, không cần queue, không cần một dispatcher đứng
giữa quyết ai đi trước.

Số đo: AST-057, trên một dự án thật, một ticket trông như đang bị chặn suốt nhiều giờ sau khi cả
hai blocker của nó đã merge, và bốn ticket đeo nhãn sẵn sàng trong lúc đang bị chặn. Frontier
được tính đúng nhưng chỉ nằm trong đầu agent. Vì vậy contract mang cả hai nửa: tính xong thì ghi
câu trả lời ngược lại lên tracker, và không bao giờ đọc nhãn sẵn sàng như thể nó là trạng thái.

Cái giá: Astragentic thừa kế nguyên giới hạn của tracker bạn đang dùng. Không tracker nào có ô
assignee thiết kế để chứa `builder/<ticket-id>`. GitHub Issues không có trường status thật, nên
status sống trong label và cột trên Project board chỉ là bản sao phải giữ đồng bộ. Mỗi adapter vì
thế có workaround riêng. Và vì tracker là nơi giữ trạng thái chứ không phải bản ghi thụ động, nó
lệch được với thực tế; `reconcile-tracker` đo tracker bằng git, không bao giờ đo tracker bằng
chính tracker.

## why-not-subagents

Claude Code có subagent và agent team, và chúng chạy tốt cho việc bên trong một session. Chúng
không đủ để điều phối một team, vì bốn thứ còn thiếu đều thiếu theo cùng một kiểu: không phát ra
tín hiệu khi sai.

Checkout dùng chung. Subagent chạy trong cùng worktree với session cha, nên nhiều agent kéo HEAD
của nhau đi. AST-016 bắt được một reviewer chỉ đọc đã `git switch` checkout của người khác.

Context dùng chung. Một fork thừa kế nguyên context của cha, kèm những thứ không ai định trao.
AST-006: fork thừa kế cả model của cha, nên một việc đáng chạy bằng model rẻ lại chạy bằng model
đắt nhất. AST-119: một fork bên trong Builder gửi handback cho dispatcher dưới đúng tên Builder,
và Builder không hề thấy. AST-130: một fork ký marker `simplify(increment):` lên code do chính nó
vừa commit, đúng form được phép, chỉ lộ vì Builder thấy một commit mình không tạo ra.

Không có tracker giữ trạng thái. State của subagent sống trong context của session cha, biến
mất khi session compact, và trong lúc còn sống thì bạn không nhìn thấy.

Không có pane để nhìn. AST-018: một lần dispatch chỉ được kể ra bằng chữ mà chưa từng được gọi,
và không có tín hiệu nào phân biệt hai chuyện đó. Một pane trong herdr là thứ đếm được; một
subagent trong tiến trình thì không.

Và không có vendor thứ hai: subagent của Claude vẫn là Claude, nên không có lượt review chéo.

Astragentic vẫn dùng fork bên trong Builder cho việc chỉ báo cáo, với luật: fork phải có
`isolation: "worktree"` và không được nhắn cho dispatcher.

Cái giá: bạn phải cài herdr và cấu hình một tracker, hai dependency mà subagent không cần. Mỗi
Builder tốn một worktree trên đĩa và vài giây setup; mỗi lần dispatch tốn một lượt ghi và một
lượt đọc trên tracker. Quy trình dài hơn và nhiều tên hơn phải nhớ. Tôi chọn trả giá đó vì lỗi
im lặng đắt hơn nhiều.

## why-mattpocock

Astragentic không viết phương pháp riêng. Phần craft, từ khảo sát tới spec, ticket, implement và
code review, là `mattpocock-skills` (`wayfinder`, `grill-with-docs`, `to-spec`, `to-tickets`,
`implement`, `code-review`). Astragentic bọc điều phối quanh đó. Bản 1.0.0 gỡ 19 skill từng
vendor vào repo để nhường chỗ cho plugin upstream; ADR-0001 ghi lại quyết định này.

Lý do nằm ở chỗ vòng lặp được đặt ở đâu. Phương pháp này lặp ở đầu quy trình: `grilling` chạy
cho tới khi không còn câu hỏi mở, rồi mọi review phía sau là một lượt có biên. Cách làm cũ lặp ở
cuối: quyết định chưa chốt đi thẳng vào code, rồi bị chốt ở review, là điểm đắt nhất.

Số đo: hai tuần dùng thật sinh ra những plan phải đi qua 5 tới 14 vòng review. Vòng 2 thêm một
cái lock, vòng 3 cắt nó đi vì đó là sự yên tâm giả, và vòng 8 vẫn đang sửa một câu vòng 2 để
lại. Chỗ hỏng không phải reviewer; chỗ hỏng là quyết định được chốt quá muộn.

Về Superpowers, câu hay được hỏi kèm: đó là một hệ tốt và team của tôi có dùng ở dự án khác. Nó
gói phương pháp và điều phối vào chung một session, state nằm trong file plan trên branch, và
không có gì tương đương `to-tickets` sinh ticket kèm blocking edge lên tracker. Chạy cả hai trong
một repo là hai bộ điều phối tranh nhau cùng một chỗ, nên Astragentic không kết hợp.

Cái giá: phụ thuộc thật. `check-requirements.sh` fail cứng khi thiếu `mattpocock-skills >=
1.2.3`. Địa chỉ `/mattpocock-skills:<name>` nằm trong các contract, nên đổi phương pháp là viết
lại contract. Và Astragentic chỉ vá được đường nối, không vá được plugin: AST-057 là một defect
nằm ở `to-tickets`, và câu trả lời đúng là dạy contract sống chung với nó chứ không fork một bản
vá.

## why-cross-vendor

Sau khi Claude viết xong và tự review, một model của vendor khác đọc lại diff. Lý do cơ chế: arm
đọc repository trong khi tác giả đọc ticket, nên nó bắt được mâu thuẫn với chính tiêu chuẩn dự án
đã khai, thứ người viết code không nhìn ra vì đang nhìn từ phía yêu cầu.

Số đo: AST-015, một vòng review cùng vendor cho lọt một defect đem secret sống và PII của người
mua vào file được track; vòng cross-vendor bắt được và xếp P1. AST-012 rút ra phần tổng quát: hai
lăng kính bắt hai lớp defect khác nhau, nên chúng tồn tại song song chứ không thay thế nhau. Một
ca khác trên diff lớn: 6.904 dòng thêm mới trên 31 file đi qua lượt đọc cùng vendor bỏ sót ba test
rỗng, trong khi lượt đọc phạm vi ticket trên diff nhỏ hơn bắt được một deadlock thật mà bản vá
của lượt trước vừa tạo ra.

Cái giá: ma sát lúc gọi. Cách quote và argv khác nhau giữa các runtime. `codex exec` đã có lần
treo im lặng, nên cần timeout và một dispatcher đứng canh. Nguy hiểm nhất là phạm vi: nếu
`--base` và `HEAD` resolve lệch nhau, companion so một branch với chính nó và trả về sạch trên
không commit nào. Vì vậy mọi lượt đọc phải in ra dòng range trước khi verdict được tin.
