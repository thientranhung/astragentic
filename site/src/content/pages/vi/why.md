---
title: "Vì sao"
description: "Năm câu vì sao tôi đã phải tự trả lời: vì sao cần lớp này, vì sao thuê method của mattpocock, vì sao không dừng ở subagent, vì sao tracker, vì sao hai vendor."
---

Năm câu dưới đây là năm chỗ tôi bị hỏi nhiều nhất, và cũng là năm chỗ tôi đã đổi ý ít nhất một
lần. Mỗi câu trả lời nêu rõ cái giá phải trả, vì một lựa chọn không có giá thường là lựa chọn
chưa được thử.

## why-astragentic

Một agent chạy đơn lẻ không cần lớp điều phối. Một agent, một branch, không có bài toán điều
phối nào, và nếu bạn đang ở đó thì cứ ở đó.

Vấn đề bắt đầu ở agent thứ hai và thứ ba, trên một repo thật. Lỗi lúc đó không ồn ào: agent ghi
đè việc của nhau mà không exception nào được ném ra, review kéo dài vòng này qua vòng khác, và
tới cuối không ai nói được chính xác cái gì đã thật sự chạy. Tôi mất một buổi chiều làm việc
theo đúng kiểu đó: ba session trên cùng một checkout, không lỗi nào, công việc biến mất, rồi
mất thêm một buổi nữa để hiểu nguyên nhân.

Astragentic tồn tại để những lỗi đó khó xảy ra về mặt cấu trúc, thay vì thành thứ phải canh
bằng mắt mỗi lần. Isolation là git worktree chứ không phải nội quy. Claim là một dòng trên
tracker chứ không phải một câu trong chat. Bằng chứng là commit và receipt chứ không phải lời
báo cáo của chính agent vừa làm.

Cái giá có hai phần. Phần thứ nhất: đây là thêm một lớp phải cài, phải hiểu và phải nâng cấp,
và mỗi bản upgrade là một sự kiện project phải hấp thụ. Phần thứ hai quan trọng hơn: cả vòng
này chưa từng chạy trọn một lần từ dispatch tới merge với đủ gate nổ trên việc thật bên trong
repo này. Chứng minh công cụ chạy đúng và chứng minh cả vòng chạy đúng là hai tuyên bố khác
nhau, và tôi mới làm được tuyên bố thứ nhất.

## why-mattpocock

Astragentic không viết method riêng. Nó thuê `mattpocock-skills` làm toàn bộ phần craft
(`wayfinder`, `grill-with-docs`, `to-spec`, `to-tickets`, `implement`, `code-review`) rồi bọc
lớp điều phối quanh đó. Bản 1.0.0 gỡ đi 19 skill đã được vendor vào repo này để nhường chỗ cho
plugin upstream, và ADR-0001 ghi lại quyết định đó.

Lý do chọn nằm gọn trong một câu ở ADR: method đó loop ở đầu quy trình, còn tôi đã loop ở cuối.
Hai tuần dùng thật sinh ra những plan phải đi qua 5 tới 14 vòng review-gate. Vòng 2 thêm một
cái lock, vòng 3 cắt nó đi vì đó là sự yên tâm giả, và vòng 8 vẫn đang sửa một câu vòng 2 để
lại. Chỗ hỏng không phải reviewer. Chỗ hỏng là những quyết định chưa từng được chốt đi thẳng
vào code, rồi được chốt ở điểm đắt nhất của quy trình. Trong hệ đó, `grilling` chạy cho tới khi
frontier quyết định rỗng, còn mọi review là một lượt có biên, không có điều kiện hội tụ.

Về Superpowers tôi nói cho rõ, vì đây là câu hay bị hỏi kèm: Superpowers là một hệ rất tốt và
team của tôi có dùng nó thật ở project khác. Nó chỉ nằm khác lớp. Nó gói method và điều phối
vào chung một session: 14 skill, không có role, một hook `SessionStart`, và state công việc
sống trong file plan nằm trong branch. Astragentic thì để state trên tracker và tách vai theo
ranh giới session. Nửa sau của spine thì Superpowers gánh được, có chỗ còn mạnh hơn; nửa đầu
thì không có thứ tương đương với `to-tickets` sinh ra ticket kèm blocking edge trên tracker, mà
tracker chính là substrate điều phối ở đây. Chạy cả hai trong cùng một repo cũng không phải vấn
đề thừa skill, mà là hai orchestrator tranh nhau cùng một chỗ: hai lược đồ worktree, hai
substrate state, và một bootstrap dạy "đừng dừng lại hỏi người" đâm thẳng vào giao thức handback
ở đây.

Cái giá của việc thuê ngoài là phụ thuộc thật. `check-requirements.sh` fail cứng khi thiếu
`mattpocock-skills >= 1.2.3`. Địa chỉ `/mattpocock-skills:<name>` được hardcode khắp các
contract, nên đổi method không phải sửa config mà là viết lại contract. Và tôi chỉ vá được
đường nối, không vá được chính plugin: AST-057 là một defect nằm ở `to-tickets`, và câu trả lời
đúng ở đây là dạy contract sống chung với nó chứ không phải fork một bản vá.

## why-not-subagents

Claude Code có subagent và có agent team, và chúng chạy tốt. Câu hỏi không phải chúng có dùng
được không, mà là chúng có làm được lớp điều phối không. Tôi đã thử, và năm thứ còn thiếu đều
thiếu theo cùng một kiểu: chúng không phát ra tín hiệu khi sai.

Checkout bị dùng chung. Subagent chạy trong cùng worktree với session cha. AST-016 đo được hệ
quả: nhiều agent chung một checkout kéo HEAD của nhau đi, và trường hợp bắt được là một reviewer
chỉ đọc đã `git switch` checkout của người khác. Ngoại lệ "agent này chỉ đọc" chính là giả
định tôi đã tin, và nó sai. Từ đó isolation thành vô điều kiện.

Context window cũng bị dùng chung. Một fork thừa kế nguyên context của cha, kèm theo những thứ
tôi không định trao. AST-006: fork thừa kế luôn model của cha, đè lên bậc thang model đã khai,
nên một việc đáng chạy bằng model rẻ lại chạy bằng model đắt nhất mà không ai khai gì. Nặng
hơn, fork thừa kế cả địa chỉ của dispatcher: AST-119 ghi lại một fork bên trong Builder gửi
handback cho dispatcher, đến trên đúng socket đó dưới đúng cái tên đó, và Builder không hề nhìn
thấy chuyện đó xảy ra. Tin nhắn ấy còn mang một sự thật kỹ thuật về branch mà chính Builder
không biết, nên nó không bỏ qua được như nhiễu, cũng không tin được như lời khai. AST-130 là
bước tiếp theo của cùng một lớp lỗi: một fork ký một marker `simplify(increment):` lên phần code
do chính nó vừa commit, đúng form được phép, không check nào bắt được, chỉ lộ vì Builder thấy
một commit nó không hề tạo ra.

Không có tracker nào giữ state. State của subagent sống trong context của session cha, nghĩa là
nó biến mất khi session compact, và trong lúc còn sống thì chủ dự án không nhìn thấy được. Chủ
dự án không chạy được truy vấn nào, họ mở board ra và nhìn. Một frontier chỉ được tính mà không
được ghi lại thì phục vụ agent hoàn hảo và vô hình với đúng người không tính được (AST-057).

Không có pane để nhìn, và đây là chỗ đau nhất vì nó im lặng nhất. AST-018 đo được một lần
dispatch chỉ được kể ra bằng chữ mà chưa từng được gọi; kể lại một tool call không phải là gọi
nó, và không có tín hiệu sống nào để phân biệt hai chuyện đó. Trong một session dài ở downstream
có compact một lần, một ticket bị dispatch thành subagent chạy trong tiến trình thay vì thành
một pane nhìn thấy được, và không ai phát hiện cho tới lúc chủ dự án hỏi. Một pane là thứ đếm
được; một subagent trong tiến trình thì không.

Và không có vendor thứ hai: subagent của Claude vẫn là Claude. Cross-vendor arm cần một model
của vendor khác đọc lại artifact, và không cách spawn nào bên trong một runtime tạo ra được
điều đó.

Astragentic vẫn dùng fork bên trong Builder cho việc chỉ báo cáo, và luật đi kèm là fork đó phải
có `isolation: "worktree"` và tuyệt đối không được nhắn cho dispatcher. Subagent làm được việc
thật. Nó chỉ không phải chỗ để đặt lớp điều phối.

Cái giá của cách này nặng thật. Bạn phải cài herdr và phải có một tracker được cấu hình đàng
hoàng, hai dependency ngoài mà một subagent không cần. Mỗi Builder tốn một worktree trên đĩa và
vài giây setup. Mỗi lần dispatch tốn thêm một lượt ghi lên tracker và một lượt đọc lại. Còn một
cái giá không đo bằng máy: quy trình dài hơn và nhiều tên hơn phải nhớ. Tôi trả giá đó vì buổi
chiều biến mất kia đắt hơn nhiều.

## why-tracker

Trạng thái công việc phải sống ở một chỗ mà agent không giữ được trong context và chủ dự án mở
ra nhìn được. Tracker là chỗ duy nhất thoả cả hai vế đó, nên ADR-0001 gọi nó là substrate điều
phối chứ không phải sổ ghi chép.

Tôi lấy ba thứ từ đó. Blocking edge cho một đồ thị phụ thuộc, nên "cái gì đang chờ cái gì" là dữ
liệu chứ không phải trí nhớ. Truy vấn frontier trả lời "cái gì sẵn sàng ngay bây giờ". Và
assignee làm claim: ghi tên lên ticket trước khi tạo worktree là thứ giữ cho hai session đồng
thời không đụng nhau, không cần lock file, không cần queue, không cần một dispatcher trung tâm
quyết ai đi trước.

Nhưng một frontier chỉ được tính thì vô hình với người không tính được. AST-057 đo trên một dự
án thật: suốt cả đời dự án đó, không ticket nào từng bước vào trạng thái chưa bắt đầu, và một
ticket ngồi trông như đang bị chặn suốt nhiều giờ sau khi cả hai blocker của nó đã merge. Bốn
ticket đeo nhãn sẵn sàng trong lúc đang bị chặn. Không check nào của harness từng nhìn tới đó;
chủ dự án bắt được bằng cách mở hai board ra so bằng mắt. Vì vậy contract mang cả hai nửa: tính
xong thì ghi câu trả lời ngược lại lên tracker, và không bao giờ đọc một nhãn sẵn sàng như thể
nó là trạng thái.

Cái giá là tôi thừa kế nguyên mọi giới hạn của tracker bạn đang dùng. Không tracker nào có ô
assignee được thiết kế để chứa `builder/<ticket-id>`. GitHub Issues không có trường status thật,
nên status sống trong label và cột trên Project board chỉ là bản sao ai đó phải giữ đồng bộ. Mỗi
adapter vì thế mang theo workaround riêng và cái bẫy riêng. Và vì tracker là substrate chứ không
phải bản ghi thụ động, nó lệch được với thực tế: một ticket nói `in-progress` với assignee còn
sống rất lâu sau khi branch của nó đã merge. Đó là việc của `reconcile-tracker`: nó đo tracker
bằng git, không bao giờ đo tracker bằng chính tracker, vì một trạng thái sai vẫn tự nhất quán
hoàn hảo.

## why-cross-vendor

Sau khi Claude viết xong và đã tự review, một model của vendor khác đọc lại diff. Nghe như thừa,
cho tới lúc tôi có số đo.

AST-015: một vòng review đúng sai cùng vendor đã cho lọt một defect đem secret sống và PII của
người mua vào file được track; vòng cross-vendor bắt được nó và xếp P1. AST-012 rút ra phần tổng
quát: hai lăng kính bắt hai lớp defect khác nhau, nên chúng tồn tại song song chứ không thay thế
nhau. Một ca khác đo trên diff lớn: một payload phạm vi slice gồm 6.904 dòng thêm mới trên 31
file đi qua một lượt đọc cùng vendor bỏ sót ba cái test rỗng trong một ngày, trong khi một lượt
phạm vi ticket trên diff nhỏ hơn bắt được một deadlock thật mà chính bản vá của lượt trước vừa
tạo ra.

Lý do cơ chế thì đơn giản: arm đọc repository trong khi tác giả đọc ticket. Nên thứ nó thắng là
mâu thuẫn nội bộ với chính tiêu chuẩn dự án đã tự khai, đúng cái mà người viết code không nhìn
ra được vì họ đang nhìn từ phía yêu cầu.

Cái giá là ma sát lúc gọi, và ma sát đó có thật. Cách quote và argv khác nhau giữa các runtime.
Đường `codex exec` trực tiếp đã có lần treo im lặng, nên nó cần timeout và cần một dispatcher
đứng canh. Nguy hiểm nhất là chuyện phạm vi: nếu `--base` và `HEAD` được resolve lệch nhau thì
companion đem một branch so với chính nó và trả về sạch trên không commit nào. Vì vậy mọi phạm
vi phải in ra dòng range trước khi ai đó được phép tin cái verdict.
