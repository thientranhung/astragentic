---
title: "Sáu lỗi mình đo được"
description: "Sáu lỗi thật, có ngày, xếp theo chặng mà nó rơi ra. Mỗi lỗi kèm cách mình chữa và cái giá của cách chữa đó."
---

Sáu lỗi dưới đây không phải rủi ro giả định. Mỗi cái có ngày, có số lần đo, và có một file
đang mang luật sinh ra từ nó. Mình xếp theo chặng mà nó rơi ra, không theo mức nặng nhẹ:
thứ cần nhớ là chỗ nào trong vòng đời hay thủng.
Phần đáng đọc là cách chữa và cái giá của nó. Không cách nào miễn phí.

## AST-131

Queue còn mười hai ticket claim được, hai trên bốn slot Builder ngồi không. Không có gì lỗi.
Vòng lặp của router là nhận thông báo, xác minh, merge, báo cáo, chờ; không bước nào hỏi
có bao nhiêu Builder đang chạy.

Mình sửa bằng cách cho frontier query một mục tiêu, không chỉ một trigger: sau mỗi lần
merge, router phải hỏi nên claim thêm mấy cái, không chỉ hỏi cái nào claim được. Cái giá là
router bận hơn và thỉnh thoảng claim quá tay. Mình chấp nhận, vì một slot
ngồi không thì không phát ra tín hiệu nào.

## AST-097

Một Builder khởi động tiến trình nền dài rồi kết thúc lượt trong lúc chờ. Pane hiện
`done`, watcher báo `TERMINAL:done`, và bảng nhánh trong `dispatch-ticket` nói builder đã
xong. Mình suýt báo ticket đó bỏ dở, trong khi Builder đang ở phút
thứ hai mươi của việc tử tế.

Thứ cứu được không phải protocol. Là artifact tự mâu thuẫn: file bị sửa chỉ có thêm đúng một
dòng comment. Nên mình bỏ niềm tin vào trạng thái pane: mỗi chữ `done` phải đọc diff
trước khi kết luận. Cái giá là mỗi lần đóng ticket tốn thêm một vòng đọc.

## AST-092

Cùng chữ đó, hậu quả nặng hơn. Builder viết xong code rồi dừng trước khi commit, pane vẫn về
`done`, và bước cleanup chạy `git worktree remove` đè lên. Năm lần trên ba session, mỗi lần
93 tới 433 dòng, không lần nào lấy lại được.

Mình đặt chốt chặn ngay tại bước nguy hiểm, thay vì trông vào việc Builder commit cẩn thận
hơn. Cleanup phải đọc `git status` của worktree trước khi xoá, thấy dirty là dừng và đưa về
cho người. Cái giá là worktree mồ côi tồn đọng, thỉnh thoảng phải dọn tay. So với mất một
ngày thì rẻ.

## AST-015

Một bước export commit thẳng secret sống và PII của người mua vào file được track. Review
same-vendor đọc qua và cho pass. Vòng cross-vendor bắt được, xếp P1.

Đó là lý do cuối phase vẫn còn một vòng arm chạy bằng vendor khác, dù tốn thêm tiền và thời gian. Hai lăng kính bắt hai lớp lỗi khác nhau, và lớp mà same-vendor bỏ sót là lớp đắt
nhất khi lọt. Một giá trị đã chạm vào file được track thì coi như cháy, phải rotate. Phía sau không có gì rẻ hơn.

## AST-074

Bốn ticket nằm in-progress với assignee sống sau khi code đã merge, cái cũ nhất trễ
trọn một ngày. Không có gì lỗi: merge chạy, phần ghi ngược lại frontier thì không, và không
artifact nào ghi lại chỗ thiếu đó.

Không check nào chỉ nhìn tracker mà bắt được: một trạng thái sai vẫn nhất quán với chính nó. Nên tracker phải được đối chiếu với Git sau mỗi lần merge, thay vì tự xác nhận
chính mình. Cái giá là thêm một bước reconcile không ai vui khi chạy, và phần lớn thời gian
không tìm ra gì.

## AST-056

Hai ticket không có blocking edge nào giữa chúng, đúng mọi luật mình viết, và cùng sửa
ba dòng của một file. Cái thứ nhất merge trước. Cái thứ hai dựng trên commit trước cú merge
đó, đẻ ra hai khối conflict, và một cú merge sai chiều sẽ revert phần đã review, không tín hiệu nào.

Một worktree cho mỗi Builder chỉ giải quyết va chạm ở checkout. Nó dời va chạm xuống merge,
chỗ tìm ra muộn và phải xử tay. Nên ticket phải khai write-set, và những ticket có
write-set giao nhau bị xếp tuần tự kể cả khi không gì buộc chúng theo thứ tự. Cái giá là số
ticket chạy song song giảm xuống, đúng thứ mình dựng cả hệ thống này để tăng.
