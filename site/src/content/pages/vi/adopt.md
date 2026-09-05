---
title: "Cài vào repo của anh em"
description: "Bộ cài chỉ stage một release bất biến rồi dừng. Việc tích hợp do một agent làm sau khi đọc project thật."
---

Bộ cài này cố tình không tự sửa project của anh em. `./install.sh` chỉ stage một release bất
biến vào `.astraler/releases/<version>` rồi dừng ở đó. Phần tích hợp do một agent chạy ngay
trong repo của anh em làm, sau khi nó đọc build command, agent config và trạng thái Git thật.

Mình tách hai bước vì một bộ cài kiểu chép đè thì sẽ luôn đè nhầm. Nó không phân biệt được
thứ thuộc về harness với thứ thuộc về project và thứ do owner sở hữu. Cái giá là anh em phải
chạy thêm một phiên agent và ngồi đọc những gì nó định làm, thay vì gõ một lệnh rồi đi pha
cà phê.

## brownfield

Bốn skill dưới đây có mặt vì repo thật hiếm khi sạch. `bootstrap-glossary` rút từ vựng miền
ra từ chính code, mỗi từ mang theo file nó được đọc ra và bị đánh dấu chưa duyệt cho tới khi
owner gật. Nguyên tắc là trích, không bịa, vì một glossary do agent tưởng tượng ra nhưng viết
bằng giọng chắc chắn còn nguy hiểm hơn là không có glossary.

`batch-triage` xử một backlog thừa kế trong một lượt thay vì từng món một. `legacy-testing`
dựng seam cho đoạn code không có chỗ nào để bám vào mà test. `untangle` dành cho repo không
còn module boundary nào để cải thiện, nơi một cú restructure sạch sẽ ra thành một diff không
ai review nổi.

Cái giá chung của cả bốn: đây là việc phải làm xong trước khi ticket đầu tiên chạy được.
