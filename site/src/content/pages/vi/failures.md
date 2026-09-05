---
title: "Sáu lỗi tôi đo được"
description: "Sáu lỗi thật, có ngày, xếp theo chặng mà nó rơi ra. Mỗi lỗi kèm cách chữa và cái giá của cách chữa đó."
---

Sáu lỗi dưới đây không phải rủi ro giả định. Mỗi lỗi có ngày, có số lần đo, và có một file
đang mang luật sinh ra từ nó. Tôi xếp chúng theo chặng mà lỗi rơi ra chứ không theo mức nặng
nhẹ, vì thứ cần nhớ là chỗ nào trong vòng đời hay thủng. Phần đáng đọc là cách chữa và cái
giá của nó. Không cách chữa nào miễn phí.

## AST-131

Queue còn mười hai ticket claim được trong khi hai trên bốn slot Builder ngồi không, và không
có gì báo lỗi. Vòng lặp của router là nhận thông báo, xác minh, merge, báo cáo, chờ; không
bước nào hỏi có bao nhiêu Builder đang chạy.

Tôi sửa bằng cách cho frontier query một mục tiêu chứ không chỉ một trigger: sau mỗi lần
merge, router phải hỏi nên claim thêm bao nhiêu ticket, không chỉ hỏi ticket nào claim được.
Cái giá là router bận hơn và thỉnh thoảng claim quá tay. Tôi chấp nhận đánh đổi đó, vì một
slot ngồi không thì không phát ra tín hiệu nào.

## AST-097

Một Builder khởi động tiến trình nền dài rồi kết thúc lượt trong lúc chờ. Pane hiện `done`,
watcher báo `TERMINAL:done`, và bảng nhánh trong `dispatch-ticket` nói builder đã xong. Tôi
suýt báo ticket đó bỏ dở, trong khi Builder đang ở phút thứ hai mươi của một việc tử tế.

Thứ cứu được tình huống này không phải protocol, mà là artifact tự mâu thuẫn: file bị sửa chỉ
có thêm đúng một dòng comment. Từ đó tôi bỏ hoàn toàn niềm tin vào trạng thái pane, và mỗi
chữ `done` phải đọc diff trước khi kết luận. Cái giá là mỗi lần đóng ticket tốn thêm một vòng
đọc.

## AST-092

Vẫn là chữ đó, và lần này hậu quả nặng hơn. Builder viết xong code rồi dừng trước khi commit,
pane vẫn về `done`, và bước cleanup chạy `git worktree remove` đè lên. Năm lần trên ba
session, mỗi lần 93 tới 433 dòng, không lần nào lấy lại được.

Tôi đặt chốt chặn ngay tại bước nguy hiểm thay vì trông vào việc Builder commit cẩn thận hơn.
Cleanup phải đọc `git status` của worktree trước khi xoá; thấy dirty là dừng và đưa lại cho
người. Cái giá là worktree mồ côi tồn đọng và thỉnh thoảng phải dọn tay. So với mất một ngày
làm việc thì giá đó rẻ.

## AST-015

Một bước export commit thẳng secret sống và PII của người mua vào file được track. Vòng review
same-vendor đọc qua và cho pass. Vòng cross-vendor bắt được và xếp mức P1.

Đó là lý do cuối phase vẫn còn một vòng arm chạy bằng vendor khác, dù tốn thêm tiền và thời
gian. Hai lăng kính bắt hai lớp lỗi khác nhau, và lớp mà same-vendor bỏ sót là lớp đắt nhất
khi lọt. Một giá trị đã chạm vào file được track thì coi như cháy và phải rotate. Phía sau
không có phương án nào rẻ hơn.

## AST-074

Bốn ticket nằm in-progress với assignee sống sau khi code đã merge, ticket cũ nhất trễ trọn
một ngày. Không có gì báo lỗi: merge chạy, phần ghi frontier ngược lại thì không, và không
artifact nào ghi lại chỗ thiếu đó.

Không check nào chỉ nhìn tracker mà bắt được lỗi này, vì một trạng thái sai vẫn nhất quán với
chính nó. Tracker phải được đối chiếu với Git sau mỗi lần merge, thay vì tự xác nhận chính
nó. Cái giá là thêm một bước reconcile không ai vui khi chạy, và phần lớn thời gian nó
không tìm ra gì.

## AST-056

Hai ticket không có blocking edge nào giữa chúng, đúng mọi luật tôi đã viết, và cùng sửa ba
dòng của một file. Ticket thứ nhất merge trước. Ticket thứ hai dựng trên commit trước cú merge
đó, đẻ ra hai khối conflict, và một cú merge sai chiều sẽ revert phần đã review mà không phát
ra tín hiệu nào.

Một worktree cho mỗi Builder chỉ giải quyết va chạm ở checkout. Nó dời va chạm xuống merge,
chỗ tìm ra muộn và phải xử tay. Vì vậy ticket phải khai write-set, và những ticket có
write-set giao nhau bị xếp tuần tự kể cả khi không có gì buộc chúng theo thứ tự. Cái giá là số
ticket chạy song song giảm xuống, đúng thứ mà cả hệ thống này tồn tại để tăng lên.
