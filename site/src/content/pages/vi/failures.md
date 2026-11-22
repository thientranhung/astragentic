---
harness: v6.1.19
title: "Sáu bài học tôi đo được"
description: "Sáu sự cố thật, có ngày, xếp theo stage mà nó rơi ra. Mỗi sự cố kèm cách chữa và cái giá của cách chữa đó."
---

Sáu sự cố dưới đây không phải rủi ro giả định. Mỗi sự cố có ngày, có số lần đo, và có một file
đang mang luật sinh ra từ nó. Tôi xếp chúng theo stage mà lỗi rơi ra chứ không theo mức nặng
nhẹ, vì thứ cần nhớ là chỗ nào trong vòng đời hay thủng. Phần đáng đọc là cách chữa và cái
giá của nó. Không cách chữa nào miễn phí.

## AST-131

Queue còn mười hai ticket claim được trong khi hai trên bốn slot Builder ngồi không, và không
có gì báo lỗi. Vòng lặp của router là nhận thông báo, xác minh, merge, báo cáo, chờ; không
bước nào hỏi có bao nhiêu Builder đang chạy.

Tôi sửa bằng cách cho frontier query một mục tiêu chứ không chỉ một trigger: sau mỗi lần
merge, router phải hỏi nên claim thêm bao nhiêu ticket, không chỉ hỏi ticket nào claim được.

Mục tiêu mặc định là 4 Builder, và `.agents/orchestrator.md` mang override của owner.

**Đánh đổi.** Mỗi merge, handback và báo cáo cho owner đều kèm một lượt đếm pane. Tôi chấp nhận đánh
đổi đó, vì một slot ngồi không thì không phát ra tín hiệu nào.

## AST-097

Một Builder khởi động tiến trình nền dài rồi kết thúc lượt trong lúc chờ. Pane hiện `done`,
watcher báo `TERMINAL:done`, và bảng nhánh trong `dispatch-ticket` nói builder đã xong. Tôi
suýt báo ticket đó bỏ dở, trong khi Builder đang ở phút thứ hai mươi của một việc tử tế.

Thứ cứu được tình huống này không phải protocol, mà là artifact tự mâu thuẫn: file bị sửa chỉ
có thêm đúng một dòng comment, không phải thứ một Builder bỏ dở để lại.

Tôi sửa bảng nhánh của `dispatch-ticket`: `done` không còn nghĩa là xong. Trước khi kết luận,
kiểm tiến trình nền trong worktree; nếu chúng đã thoát và không có commit mới kể từ chỉ thị cuối
cùng thì đọc pane, còn có commit mới thì mới sang bước kiểm artifact. Git guard từ chối
`git worktree remove` khi còn tiến trình sống trong worktree.

**Đánh đổi.** Mỗi lần pane báo `done` tốn thêm một lượt kiểm tiến trình nền và commit.

## AST-092

Vẫn là chữ đó, và lần này hậu quả nặng hơn. Builder viết xong code rồi dừng trước khi commit,
pane vẫn về `done`, và bước cleanup chạy `git worktree remove` đè lên. Năm lần trên ba
session, mỗi lần 93 tới 433 dòng nằm chưa commit. Cả năm lần được bắt trước khi mất, nhờ thói
quen chạy `git status` của Thomas, một thói quen chưa nằm trong contract.

Tôi đặt chốt chặn ngay tại bước nguy hiểm thay vì trông vào thói quen đó. Cleanup phải đọc
`git status --short` của worktree trước khi xoá; thấy dirty là dừng và báo owner. Handback của
Builder cũng thành ba hành động tường minh: commit, push, rồi trả việc.

**Đánh đổi.** Mỗi worktree dirty chặn cleanup cho tới khi có người xử lý. So với mất một ngày làm
việc thì giá đó rẻ.

## AST-015

Một bước export commit thẳng secret đang dùng thật và PII của người mua vào file được track. Vòng
review same-vendor đọc qua và cho pass. Vòng cross-vendor bắt được và xếp mức P1.

Đó là lý do cuối phase vẫn còn một vòng arm chạy bằng vendor khác, dù tốn thêm tiền và thời
gian. Hai lăng kính bắt hai loại lỗi khác nhau, và loại mà same-vendor bỏ sót là loại đắt nhất
khi lọt.

**Đánh đổi.** Một giá trị đã chạm vào file được track thì coi như cháy và phải rotate. Phía sau
không có phương án nào rẻ hơn.

## AST-074

Bốn ticket nằm in-progress với assignee vẫn còn sau khi code đã merge, ticket cũ nhất trễ trọn
một ngày. Không có gì báo lỗi: merge chạy, phần ghi frontier ngược lại thì không, và không
artifact nào ghi lại chỗ thiếu đó.

Không check nào chỉ nhìn tracker mà bắt được lỗi này, vì một trạng thái sai vẫn nhất quán với
chính nó. Tracker phải được đối chiếu với Git sau mỗi lần merge, thay vì tự xác nhận chính
nó.

**Đánh đổi.** Thêm một lượt đọc sau mỗi merge và lúc đầu session. `reconcile-tracker` chỉ đọc, nên
mọi bản vá vẫn do Thomas làm tay.

## AST-056

Hai ticket không có blocking edge nào giữa chúng, đúng mọi luật tôi đã viết, và cùng sửa ba
dòng của một file. Ticket thứ nhất merge trước. Ticket thứ hai dựng trên commit trước cú merge
đó, đẻ ra hai khối conflict, và một cú merge sai chiều sẽ revert phần đã review mà không phát
ra tín hiệu nào.

Một worktree cho mỗi Builder chỉ giải quyết va chạm ở checkout. Nó dời va chạm xuống merge,
chỗ tìm ra muộn và phải xử tay. Vì vậy write-set là một trường bắt buộc của mỗi dispatch song song: brief mang dòng
`Owned elsewhere:` liệt kê file mà ticket khác đang giữ, nên một conflict ở merge thành một ghi chú
handback.

**Đánh đổi.** Mỗi dispatch khi còn ticket khác đang chạy phải tính write-set từ body ticket cộng quy
tắc docs-sync của repo, rồi ghi vào dispatch record.
