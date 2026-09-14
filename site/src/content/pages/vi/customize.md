---
title: "Tuỳ biến bộ khung theo cách bạn làm việc"
description: "Astragentic là scaffold, không phải sản phẩm: cài vào repo, rồi sửa nó cho khớp cách bạn làm việc — và người sửa có thể là một agent."
---

Astragentic không phải một sản phẩm bạn dùng như nó được giao. Nó là **scaffold**: một bộ khung
sinh ra để bị sửa. Role là file, skill là thư mục, hook là script — không có gì trong đó bị khoá,
và không có phần nào phải giữ nguyên để phần còn lại chạy được.

Điều đó quan trọng vì **mỗi người có một cách làm việc với AI khác nhau**, và không có cách nào
đúng cho tất cả. Trang này là hai việc: đưa bộ khung vào repo, rồi đổi nó thành của bạn.

## install

Bộ cài cố tình **không tự sửa project của bạn**. `./install.sh` chỉ stage một release bất biến vào
`.astraler/releases/<version>` rồi dừng. Phần tích hợp do một agent chạy ngay trong repo của bạn
thực hiện, sau khi nó đọc build command, agent config và trạng thái Git thật.

Tôi tách hai bước vì một bộ cài chép đè sẽ luôn đè nhầm file. Nó không phân biệt được thứ thuộc về
harness, thứ thuộc về project và thứ do bạn sở hữu.

**Đánh đổi.** Bạn phải chạy thêm một session agent và đọc kỹ những gì nó định làm, thay vì gõ một
lệnh rồi bỏ đi.

## customize

Một bản checkout Astragentic phục vụ **nhiều project**. Bạn sửa trong bản checkout đó, không sửa
trong từng repo — rồi phát hành và cài lại. Đường đi luôn là một chiều: checkout → release →
project.

```bash
# trong bản checkout Astragentic của bạn
vim .agents/roles/builder.md          # sửa contract của một role
echo "2.9.0" > VERSION                # đánh dấu bản mới
vim RELEASE-NOTES.md                  # ghi bạn đã đổi gì
./install.sh /path/to/project         # stage bản mới vào project
```

Bước thích nghi trong project so bản mới với bản đang chạy và **giữ nguyên các file thuộc về bạn**,
ví dụ `orchestrator.md` — nơi khai role nào chạy runtime nào, model nào, effort nào.

Ba mức tuỳ biến, từ nhẹ tới nặng:

- **Đổi hạ tầng.** Đổi tracker, đổi runtime, thêm một bước review riêng. Sửa một dòng trong
  `orchestrator.md` hoặc đổi adapter tracker; không đụng tới role nào.
- **Đổi hình dạng team.** Năm role là mặc định, không phải luật. Bỏ bớt xuống hai agent — một người
  đại diện và một người thi công — nếu vòng SDLC đầy đủ là thừa với bạn.
- **Đổi phương pháp.** Skill là thư mục chứa quy trình viết bằng chữ. Viết lại một skill là đổi
  cách team làm một việc, và nó có hiệu lực ở lần dispatch kế tiếp.

**Đánh đổi.** Bạn sở hữu bản fork của mình. Bản Astragentic sau này sẽ không mang theo thay đổi của
bạn, và bước thích nghi sẽ hỏi bạn ở những chỗ hai bên bất đồng.

## agent-customize

Đây là phần khác với một scaffold thông thường: **người sửa bộ khung không nhất thiết là bạn.**

Toàn bộ Astragentic là văn bản — contract viết bằng tiếng Anh, skill viết bằng tiếng Anh, hook là
script ngắn. Không có binary, không có config schema phải học, không có file sinh tự động mà sửa
tay là hỏng. Một coding agent đọc được tất cả, và sửa được tất cả.

Nên cách tuỳ biến nhanh nhất thường là mở một session ngay trong bản checkout Astragentic và mô tả
cách bạn muốn làm việc:

> Đọc `.agents/roles/` và `.agents/skills/`. Tôi làm một mình, không có milestone, và tôi muốn xem
> diff trước mỗi lần merge. Rút xuống hai role, bỏ gate theo milestone, và thêm một bước bắt buộc
> đưa diff cho tôi duyệt. Nói cho tôi biết bạn định sửa file nào trước khi sửa.

Agent đọc bộ khung, đề xuất diff, bạn duyệt. Nó biết `orchestrator.md` là của bạn và không được đè.
Nó biết một role là một contract chứ không phải một prompt. Những thứ đó viết ngay trong file nó
đang đọc.

**Đánh đổi.** Agent sẽ tự tin ngay cả khi nó sai. Đọc diff trước khi nhận, và đừng để nó sửa
`VERSION` hay `RELEASE-NOTES.md` thay bạn — đó là hai chỗ ghi lại bạn đã quyết gì.

## self-repair

Bộ khung không chỉ sửa được bằng tay. Nó còn **sửa chính nó theo thời gian**, và cơ chế là một
cuốn sổ.

Mỗi lần có thứ hỏng, sự cố được ghi một dòng vào một file chỉ thêm, mang mã cố định, không bao giờ
đánh số lại hay xoá đi. Dòng nào rút ra được luật thì luật đó **đi vào một file mà agent thật sự
đọc** — một role contract, một skill, một hook. Lần sau cả team làm khác đi, không phải vì ai đó
nhớ, mà vì văn bản đã đổi.

Đó là vòng khép kín: lỗi → một dòng trong sổ → một luật trong contract → hành vi khác ở lần dispatch
sau. Cuốn sổ là bộ nhớ dài hạn của bộ khung, còn contract là chỗ bộ nhớ đó có hiệu lực.

Dòng nào chưa rút ra được luật vẫn nằm nguyên trong sổ chứ không bị lọc đi. Một hồ sơ chờ thì trung
thực hơn một cuốn sổ chỉ chứa những lần đã giải quyết xong.

**Đánh đổi.** Cuốn sổ dài ra và không bao giờ ngắn lại. Nó không phải thứ để đọc từ đầu tới cuối —
nó là thứ để tra khi một luật trong contract khiến bạn thắc mắc *vì sao lại có luật này*.

## brownfield

Bốn skill dưới đây có mặt vì repo thật hiếm khi sạch.

- **`bootstrap-glossary`.** Rút từ vựng miền ra từ chính code; mỗi từ mang theo file nó được đọc ra
  và bị đánh dấu chưa duyệt cho tới khi owner xác nhận. Nguyên tắc là trích, không bịa: một glossary
  do agent tưởng tượng ra nhưng viết bằng giọng chắc chắn còn nguy hiểm hơn là không có glossary.
- **`batch-triage`.** Xử lý một backlog thừa kế trong một lượt thay vì từng ticket một.
- **`legacy-testing`.** Dựng seam cho đoạn code không có điểm bám nào để test.
- **`untangle`.** Dành cho repo không còn module boundary nào để cải thiện, nơi một cú restructure
  sạch sẽ tạo ra một diff không ai review nổi.

**Đánh đổi.** Chung cho cả bốn: đây là việc phải làm xong trước khi ticket đầu tiên chạy được.
