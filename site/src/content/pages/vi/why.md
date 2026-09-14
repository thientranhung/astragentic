---
title: "Cách tiếp cận"
description: "Cách tiếp cận đứng sau Astragentic: mô hình orchestrator agent, issue tracker giữ trạng thái, vì sao không đặt điều phối vào subagent, và review chéo giữa hai hãng AI."
---

Astragentic hướng tới autonomous coding: một team AI agent tự vận hành phần thi công, còn con
người giữ định hướng và quyết định.

Mỗi team có một cách làm việc riêng, và không quy trình nào nhập khẩu nguyên vẹn được. Vì vậy
Astragentic là một scaffold: bộ khung đã giải quyết sẵn những phần khó, còn mọi thành phần trong
đó đều mở để bạn tuỳ biến.

Năm phần dưới đây là năm quyết định thiết kế lớn nhất của bộ khung: cơ chế, bằng chứng đo được,
và đánh đổi. Đây là lựa chọn của tôi trên dự án của tôi, không phải khuôn mẫu bắt buộc.

## why-astragentic

Coding agent hôm nay đã đủ sức đảm nhận phần thi công: nhận việc, viết code, chạy test, trả kết
quả.

Việc còn lại của bạn không phải viết code. Nó là hai thứ khác, và chúng ăn hết thời gian: trả lời
câu hỏi agent đặt ra trong lúc làm, và review chất lượng kết quả trả về.

Cả hai có chung một điểm nghẽn. Câu hỏi kỹ thuật của agent thường vượt quá chuyên môn của người
điều hành. Cách xử lý phổ biến là mang câu hỏi sang một AI khác rồi chuyển câu trả lời về. Khi đó
con người chỉ còn là khâu trung chuyển, và quyết định trên thực tế đã do AI đưa ra.

Astragentic bỏ khâu trung chuyển đó bằng hai cơ chế.

### Thomas, người đại diện của team

Thomas nắm ngữ cảnh dự án và đứng giữa bạn với các agent:

- **Đọc artifact** các agent trả về, thay vì đẩy nguyên log sang cho bạn.
- **Đánh giá phương án** và tech stack được đề xuất.
- **Trả lời câu hỏi kỹ thuật** ngay tại chỗ.
- **Chuyển lên bạn** những gì thuộc thẩm quyền của bạn: hướng sản phẩm, trải nghiệm người dùng,
  thứ tự ưu tiên.

Bạn làm việc như khách hàng của một đơn vị phát triển: đặt yêu cầu, theo dõi tiến độ, và can thiệp
khi thấy team đi lệch.

### Một team vận hành công khai

Mỗi agent là một session có tên, có pane riêng trong herdr, và lịch sử làm việc ở lại trong session
đó. Bạn quan sát được từng agent làm gì. Thomas truy vết được khi có sự cố. Cách các agent phối hợp
trở thành dữ liệu để bạn cải tiến chính bộ khung.

Subagent và agent team bên trong một runtime chạy ẩn trong tiến trình cha. Không có gì để nhìn.

**Đánh đổi.** Thêm một bộ công cụ phải cài, hiểu và nâng cấp, và mỗi bản nâng cấp là một sự kiện dự
án phải hấp thụ. Tới nay tôi mới chứng minh được từng công cụ chạy đúng; cả vòng từ dispatch tới
merge với đủ gate trên việc thật vẫn đang được đo.

## why-tracker

Trạng thái công việc cần nằm ngoài context của agent, và bạn mở ra là đọc được. Issue tracker là
nơi duy nhất thoả cả hai.

Cách làm phổ biến trước đó là để AI cắt việc thành file markdown rồi theo dõi bằng ô tick. Nó hỏng
ở hai đầu: agent phải nhớ quay lại sửa, còn bạn phải mở file ra đọc.

| | File markdown | Issue tracker |
|---|---|---|
| Cập nhật trạng thái | Agent phải nhớ quay lại sửa ô tick | Một trường status, đổi bằng một lệnh |
| Xem tiến độ | Mở file, đọc vài trăm dòng | Mở board, nhìn cột |
| Phụ thuộc giữa các việc | Nằm trong câu chữ | Một cạnh chặn (blocking edge), truy vấn được |
| Hai agent cùng nhận một việc | Không có gì chặn | Assignee đóng vai xí phần, ghi và đọc lại được |
| Máy thao tác | Sửa văn bản tự do | CLI và MCP chính thức |
| Duyệt hoặc yêu cầu sửa | Nhắn ở một chỗ khác | Comment ngay trên ticket |
| Nhiều người cùng góp ý | Sửa chung một file, giẫm lên nhau | Mỗi người một comment, có tên, có thứ tự |
| Agent hỏi lại | Không có chỗ để hỏi | Đặt câu hỏi ngay trong ticket, ai trả lời cũng được, rồi agent làm tiếp |
| Khi session đóng | Trạng thái mất theo context | Board vẫn còn nguyên |

Hai dòng về comment là chỗ thay đổi cách làm việc rõ nhất. Agent không còn phải chờ đúng một
người: nó đặt câu hỏi trên ticket, ai trong team trả lời được thì trả lời, rồi nó chạy tiếp. AI
làm việc như một thành viên trong nhóm chứ không phải một công cụ bạn phải ngồi canh.

Một chi tiết dễ bỏ sót: danh sách việc làm được ngay, gọi là frontier, phải được ghi lại. Nếu nó
chỉ được tính trong context của agent thì bạn mở board ra không thấy, và ticket đã hết blocker vẫn
trông như đang bị chặn. Vì vậy contract mang cả hai nửa: tính xong thì ghi câu trả lời ngược lại
lên tracker, và không đọc nhãn sẵn sàng như thể nó là trạng thái.

**Đánh đổi.** Astragentic thừa kế giới hạn của tracker bạn đang dùng. Không tracker nào có ô assignee
thiết kế để chứa `builder/<ticket-id>`. GitHub Issues không có trường status thật, nên status nằm
trong label và cột trên Project board chỉ là bản sao phải giữ đồng bộ. Và vì tracker giữ trạng thái
chứ không phải bản ghi thụ động, nó lệch được với thực tế; `reconcile-tracker` đo tracker bằng git.

## why-not-subagents

Claude Code có subagent và agent team. Cả hai chạy tốt bên trong một session, và Astragentic vẫn
dùng chúng: Builder spawn subagent cho việc đọc và báo cáo, còn Thomas dùng cả hai khi cần khảo
sát hay lên plan.

Câu hỏi hay gặp là: đã có hai thứ đó thì cần gì thêm một bộ điều phối nữa.

Ranh giới nằm ở phạm vi. Subagent và agent team điều phối công việc **bên trong một session**.
Thứ một team cần là điều phối **qua nhiều session**, và quan sát được từng session một. Với cách
làm việc tôi muốn, nhìn thấy agent đang làm gì, sai ở đâu, lệch hướng lúc nào, một tiến trình
chạy ẩn không đủ.

Khi đặt điều phối vào subagent, bốn điều dưới đây thiếu, và chúng thiếu theo cùng một kiểu: khi
có lỗi, không có tín hiệu nào báo ra.

- **Checkout dùng chung.** Subagent chạy trong cùng worktree với session cha, nên nhiều agent kéo
  HEAD của nhau đi. Tôi bắt được một reviewer chỉ đọc đã `git switch` checkout của người khác.
- **Context dùng chung.** Một fork thừa kế nguyên context của cha, kèm cả những gì không ai định
  trao. Có lần fork thừa kế cả model của cha, nên việc đáng chạy bằng model rẻ lại chạy bằng model
  đắt nhất. Lần khác, một fork bên trong Builder gửi báo cáo kết thúc việc, gọi là handback, cho
  dispatcher dưới đúng tên Builder, và Builder không hề thấy. Và một fork ký marker
  `simplify(increment):` lên code do chính nó vừa commit, đúng form được phép.
- **Không có tracker giữ trạng thái.** Trạng thái của subagent nằm trong context của session cha,
  mất đi khi session compact, và trong lúc tồn tại thì bạn không đọc được.
- **Không có pane để nhìn.** Có lần một lượt dispatch chỉ được kể ra bằng chữ mà chưa từng được
  gọi. Một pane trong herdr là thứ đếm được; một subagent trong tiến trình thì không.

Và còn một điều nữa: subagent của Claude vẫn là Claude, nên không có lượt review chéo từ một hãng
khác.

Vì vậy Astragentic để subagent làm đúng việc của nó, bên trong một session, với một luật: fork
phải có `isolation: "worktree"` và không được nhắn cho dispatcher.

**Đánh đổi.** Bạn phải cài herdr và cấu hình một tracker, hai dependency mà subagent không cần.
Mỗi Builder tốn một worktree trên disk và vài giây setup. Mỗi lần dispatch tốn một lượt ghi và một
lượt đọc trên tracker. Quy trình dài hơn, nhiều tên hơn phải nhớ. Tôi chọn trả giá đó vì lỗi im
lặng đắt hơn nhiều.

## why-mattpocock

Astragentic không viết phương pháp riêng. Phần craft là `mattpocock-skills`: `wayfinder`,
`grill-with-docs`, `to-spec`, `to-tickets`, `implement`, `code-review`. Astragentic bọc điều phối
quanh đó.

Lý do nằm ở chỗ vòng lặp được đặt ở đâu.

- **Phương pháp này lặp ở đầu.** `grilling` hỏi cho tới khi không còn câu hỏi mở, nên spec chốt
  xong mới viết code. Mọi review phía sau là một lượt có biên.
- **Cách làm thường gặp lặp ở cuối.** Quyết định chưa chốt được đưa vào code, rồi mới chốt ở
  review. Đó là khâu tốn kém nhất, và số vòng review không có điểm dừng tự nhiên.

Khác biệt nằm ở chỗ dừng. Hỏi cho hết ở đầu thì có điểm dừng: hết câu hỏi mở là xong. Chốt ở
review thì không, vì mỗi vòng lại sinh câu hỏi mới, và vòng sau chủ yếu dọn thứ vòng trước để
lại.

**Về Superpowers**, câu hay được hỏi kèm: đó là một hệ tốt và team của tôi có dùng ở dự án khác.
Nó gói phương pháp và điều phối vào chung một session, trạng thái nằm trong file plan trên branch,
và không có gì tương đương `to-tickets` sinh ticket kèm blocking edge lên tracker. Chạy cả hai
trong một repo là hai bộ điều phối cùng quản lý một trạng thái, nên Astragentic không kết hợp.

**Đánh đổi.** Đây là phụ thuộc thật. `check-requirements.sh` dừng cứng khi thiếu
`mattpocock-skills >= 1.2.3`. Tên skill nằm thẳng trong các contract, nên đổi phương pháp là viết
lại contract. Và Astragentic chỉ vá được đường nối, không vá được plugin: khi một defect nằm bên
trong `to-tickets`, cách xử lý đúng là để contract tính tới nó thay vì fork một bản vá.

## why-cross-vendor

Sau khi Claude viết xong và tự review, một model của hãng khác đọc lại diff. Ở đây là Codex của
OpenAI.

Lượt đọc lại đó gọi là arm, và đây là review chéo chứ không phải tranh luận: hai model không cãi
nhau để thuyết phục ai, mỗi bên đọc và kết luận độc lập, cả hai kết luận đều được giữ lại.

Cơ chế thì đơn giản: arm đọc cả repository, còn tác giả chỉ đọc ticket. Nên arm bắt được mâu thuẫn với
chính tiêu chuẩn dự án đã khai, điều người viết code khó nhận ra vì đang làm theo yêu cầu của ticket.

- **Một defect lọt qua vòng cùng hãng**: nó đem secret đang dùng thật và PII của người
  mua vào file được track. Lượt đọc của hãng khác bắt được và xếp P1.
- **Hai lăng kính bắt hai loại defect khác nhau**, nên chúng chạy song song chứ không
  thay thế nhau.
- **Một ca trên diff lớn.** 6.904 dòng thêm mới trên 31 file đi qua lượt đọc cùng hãng bỏ sót ba
  test rỗng. Lượt đọc phạm vi ticket trên diff nhỏ hơn bắt được một deadlock thật mà bản vá của lượt
  trước vừa tạo ra.

**Đánh đổi.** Ma sát lúc gọi. Cách quote và argv khác nhau giữa các runtime. `codex exec` đã có lần
treo im lặng, nên cần timeout và một dispatcher theo dõi. Nguy hiểm nhất là phạm vi: nếu `--base` và
`HEAD` resolve lệch nhau, companion so một branch với chính nó và trả về sạch trên không commit nào.
Vì vậy mọi lượt đọc phải in ra dòng range trước khi verdict được tin.
