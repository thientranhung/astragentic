---
title: bootstrap-glossary
oneLiner: "Gieo CONTEXT.md từ chính các thuật ngữ code đang dùng, đánh dấu chưa duyệt cho tới khi được xác nhận."
group: entry
order: 1
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/bootstrap-glossary/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`bootstrap-glossary` đọc bộ từ vựng mà một codebase đã cam kết theo: tên type, class và table
trước, rồi tên module và thư mục, rồi tên hàm trên các bề mặt public, rồi giá trị enum, rồi những
từ lặp lại trong comment và commit message. Nó chuyển các thuật ngữ có tần suất cao nhất thành mục
từ điển. Mỗi mục có một định nghĩa rút ra từ cách code thật sự dùng thuật ngữ đó, một dòng
`_Avoid_` gọi tên các từ đồng nghĩa mà nó đang thay thế, và một trích dẫn tới đúng file đã đọc ra
nó. Phần định nghĩa đi vào `CONTEXT.md` theo đúng format mà `domain-modeling` và các skill cùng
nhóm vốn đã trông đợi. Phần trích dẫn, chỗ nhập nhằng và trạng thái duyệt theo từng thuật ngữ đi
vào một file riêng, `docs/agents/CONTEXT-review.md`, để vệt bằng chứng không bị nhầm thành chính
bộ từ vựng.
<!-- source: harness/.agents/skills/bootstrap-glossary/SKILL.md -->

Thứ nó thay thế là một buổi phỏng vấn domain năm mươi câu ở đầu một project brownfield, loại buổi
mà không ai rảnh một tiếng và câu trả lời rồi cũng lệch khỏi thứ code thật sự làm. Nhưng bài toán
khó hơn mà nó được dựng lên để chống thì kín đáo hơn: một bộ từ điển do agent viết mà trông như đã
được xác nhận còn tệ hơn không có từ điển nào, vì các session sau sẽ coi văn xuôi nghe chắc chắn là
sự thật đã chốt. Nên skill này rút ra chứ không bịa ra, và nó đánh dấu mọi thuật ngữ là
`UNREVIEWED` cho tới khi chủ project nhìn qua. Dấu đó nằm ở chỗ nhìn thấy được, trong một header
mà mọi người đọc đều thấy, vì bản thân trường trạng thái duyệt không tồn tại ở bất cứ đâu khác
trong plugin mà nó nuôi, và chín skill phía sau nạp `CONTEXT.md` mà không có cách nào biết trường
đó đang thiếu trừ khi header nói ra bằng chữ.
<!-- source: harness/.agents/skills/bootstrap-glossary/SKILL.md -->

## Khi nào Thomas gọi nó

| Tình huống trước mặt bạn | Gọi cái nào |
|---|---|
| Một repo brownfield chưa có `CONTEXT.md` | Chạy nó lúc bootstrap, một lần, thay cho một buổi phỏng vấn |
| Một repo đã có `CONTEXT.md` do người viết | Chạy nó để bồi thêm: giữ nguyên các mục đang có, và ghi mọi mâu thuẫn thành một quan sát nằm dưới mục sẵn có |
| Một thuật ngữ mà code dùng theo hai nghĩa không tương thích | Để nó rơi vào `AMBIGUOUS` thay vì đoán nghĩa nào mới đúng |
| Một thuật ngữ domain mà nghĩa của nó không đọc ra được từ cách dùng | Để nó rơi vào `definition: UNKNOWN` kèm trích dẫn, thay vì bịa một nghĩa |
<!-- source: harness/.agents/skills/bootstrap-glossary/SKILL.md -->

## Cần sẵn gì

Kiểm hình dạng của repo trước khi ghi bất cứ thứ gì: một bounded context thì một `CONTEXT.md` ở
gốc; nhiều context thì một `CONTEXT-MAP.md` ở gốc cộng một `CONTEXT.md` bên trong mỗi context.
Gieo một file gốc duy nhất lên một repo nhiều context sẽ trộn các bộ từ vựng không liên quan vào
một tài liệu mà mọi người đọc phía sau đều coi là chuẩn, mà repo brownfield lại chính là loại dễ
có nhiều context nhất. Đọc `CONTEXT-FORMAT.md` trước, vì `domain-modeling` và tám skill plugin
khác tiêu thụ `CONTEXT.md` theo một hình dạng cố định, và một lượt gieo từ code sẽ sai chi tiết
nếu thiếu nó.
<!-- source: harness/.agents/skills/bootstrap-glossary/SKILL.md -->

## Nó để lại gì

| Kết quả | Nơi nó nằm lại |
|---|---|
| Một thuật ngữ rút từ code, kèm định nghĩa nháp | `CONTEXT.md`, dưới `## Language`, đánh dấu bằng chính bộ đếm trong header của file |
| Trích dẫn, từ đồng nghĩa và trạng thái duyệt của thuật ngữ đó | `docs/agents/CONTEXT-review.md`, đúng một file bất kể repo có bao nhiêu context |
| Một thuật ngữ chủ project đã kiểm | `CONFIRMED <ngày>` trong `docs/agents/CONTEXT-review.md`, kèm cập nhật bộ đếm trong header của `CONTEXT.md` cho khớp |
| Một thuật ngữ code dùng theo hai nghĩa không tương thích | `AMBIGUOUS` trong `docs/agents/CONTEXT-review.md`, giữ cho nhìn thấy được thay vì xử lý bằng cách đoán |
<!-- source: harness/.agents/skills/bootstrap-glossary/SKILL.md -->

## Đang chạy đúng nếu

- Mọi mục trong `CONTEXT.md` truy ngược được về một trích dẫn thật trong
  `docs/agents/CONTEXT-review.md`. Một định nghĩa mà trích dẫn không chống lưng chính là kiểu hỏng
  mà skill này được dựng lên để tránh.
- Header của `CONTEXT.md` nêu tỉ lệ đã duyệt bằng văn xuôi mà người đọc thấy được dù không biết
  trường đó tồn tại, ví dụ "23 terms · 0 CONFIRMED · 21 UNREVIEWED · 2 AMBIGUOUS."
- Các mục do người viết sẵn có được giữ nguyên; thứ gì code mâu thuẫn thì ghi lại thành một quan
  sát, không phải ghi đè.
- Chi tiết cài đặt và khái niệm lập trình chung không bao giờ lọt vào `CONTEXT.md`, dù code có
  dùng chúng nhiều tới đâu.
- Lượt duyệt của chủ project phủ các thuật ngữ `AMBIGUOUS`, các định nghĩa `UNKNOWN`, và mười
  thuật ngữ tần suất cao nhất trước. Đó đúng là danh sách ngắn mà skill này tồn tại để đưa họ, thay
  vì bắt đọc lại từ đầu tới cuối.
<!-- source: harness/.agents/skills/bootstrap-glossary/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

`bootstrap-glossary` chạy một lần, gọi đích danh, sớm trong đời một project brownfield, cùng nhóm
với các lượt bootstrap khác cũng gọi một lần và được chủ project duyệt: `extract-standards` cho quy
ước code và `batch-triage` cho một backlog thừa kế. Thomas sở hữu cả ba như những stage, để không
cái nào biến thành phần việc mà ai cũng tưởng người khác đã chạy. Khi các thuật ngữ đã `CONFIRMED`,
`domain-modeling` là chỗ chúng được mài sắc thêm. Việc của skill này kết thúc ở chỗ trao cho
`domain-modeling` một bộ từ vựng rút từ code đang có thật, chứ không phải một bộ từ vựng ai đó đoán
ra trong một buổi phỏng vấn.
