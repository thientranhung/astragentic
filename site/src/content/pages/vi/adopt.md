---
title: "Install vào repo của bạn"
description: "Bộ cài chỉ stage một release bất biến rồi dừng. Việc tích hợp do một agent làm sau khi đọc project thật."
---

Bộ cài này cố tình không tự sửa project của bạn. `./install.sh` chỉ stage một release bất biến
vào `.astraler/releases/<version>` rồi dừng ở đó. Phần tích hợp do một agent chạy ngay trong
repo của bạn thực hiện, sau khi nó đọc build command, agent config và trạng thái Git thật.

Tôi tách thành hai bước vì một bộ cài chép đè sẽ luôn đè nhầm file. Nó không phân biệt
được thứ thuộc về harness, thứ thuộc về project và thứ do owner sở hữu.

**Đánh đổi.** Bạn phải chạy thêm một session agent và đọc kỹ những gì nó định làm, thay vì gõ một
lệnh rồi bỏ đi.

## brownfield

Bốn skill dưới đây có mặt vì repo thật hiếm khi sạch.

- **`bootstrap-glossary`.** Rút từ vựng miền ra từ chính code; mỗi từ mang theo file nó được đọc
  ra và bị đánh dấu chưa duyệt cho tới khi owner xác nhận. Nguyên tắc là trích, không bịa: một
  glossary do agent tưởng tượng ra nhưng viết bằng giọng chắc chắn còn nguy hiểm hơn là không có
  glossary.
- **`batch-triage`.** Xử lý một backlog thừa kế trong một lượt thay vì từng ticket một.
- **`legacy-testing`.** Dựng seam cho đoạn code không có điểm bám nào để test.
- **`untangle`.** Dành cho repo không còn module boundary nào để cải thiện, nơi một cú restructure
  sạch sẽ tạo ra một diff không ai review nổi.

**Đánh đổi.** Chung cho cả bốn: đây là việc phải làm xong trước khi ticket đầu tiên chạy được.
