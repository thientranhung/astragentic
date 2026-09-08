---
title: "Astragentic"
description: "Vì sao tôi dựng lớp điều phối này, tôi đã chọn gì, và cái giá của từng lựa chọn."
acts:
  - id: act-1
    eyebrow: "AST-016 · promoted 2026-07-11"
    headline: "Ba agent trên một checkout làm mất việc mà không ném lỗi."
  - id: act-2
    eyebrow: "BẢY CHẶNG"
    headline: "Bảy stage đánh dấu bảy chỗ đã có thứ rơi ra."
  - id: act-3
    eyebrow: "harness/.agents/memory/INDEX.md"
    headline: "Mỗi dòng ledger có link tới file để bạn tự kiểm."
  - id: act-4
    eyebrow: "RELEASE-NOTES.md:393"
    headline: "Vòng này chưa từng chạy trọn một lần trên việc thật."
---

## act-1

Tôi từng chạy ba session trên cùng một checkout và không lỗi nào được ném ra. Một buổi chiều
làm việc biến mất, và tôi mất thêm một buổi nữa để tìm ra nguyên nhân.

Tôi chọn cách chữa thô nhất: mọi agent được spawn mà có quyền chạy git đổi trạng thái đều
phải có checkout riêng, kể cả agent chỉ đọc. Ngoại lệ "chỉ đọc" chính là giả định tôi đã tin,
và nó sai. Cái giá là mỗi Builder tốn thêm một worktree trên đĩa và vài giây setup. Tôi trả
giá đó vì buổi chiều kia đắt hơn nhiều.

## act-2

Ban đầu quy trình chỉ có hai stage: agent làm, tôi review. Review kéo từ năm tới mười bốn
vòng, và phần lớn vòng sau dùng để dọn thứ vòng trước để lại. Reviewer không phải chỗ hỏng.
Chỗ hỏng nằm xa hơn về phía đầu: những quyết định chưa từng được chốt đi thẳng vào code, rồi
bị chốt ở điểm đắt nhất của quy trình.

Tôi đẩy vòng lặp lên đầu quy trình và cắt phần còn lại thành bảy stage có tên. Bảy stage có
tên để mỗi lỗi đo được gắn vào đúng một stage; không có tên thì lần sau lỗi rơi vào chỗ không
ai chỉ ra được. Cái giá là quy trình dài hơn, và ba trong bảy stage vẫn trống vì tôi chưa đo
được lỗi nào ở đó.

## act-3

Mỗi lần có thứ hỏng, tôi ghi một dòng vào ledger. Ghi lại thì rẻ và gần như vô dụng. Một dòng
chỉ có giá trị khi nó được buộc vào một file đang bắt ai đó làm khác đi ngay hôm nay: một rule
luôn bật, một mục Known failures trong skill, hoặc một check chạy được.

Bảng này có một cột nói rõ dòng nào đã buộc và dòng nào chưa. {{meta.cited}} trên
{{meta.total}} dòng có file mang nó. {{meta.orphan}} dòng còn lại chưa trỏ về đâu. Tôi giữ
nguyên phần chưa buộc trong bảng thay vì lọc đi, vì một ledger chỉ hiện phần đã xong thì
không dùng để tự kiểm được nữa. Bạn bấm vào một dòng có mũi tên là ra đúng file, không cần
chạy thêm lệnh nào.

## act-4

Dòng ở trên do tôi viết trong release notes của tôi, và tôi kéo nó lên đây vì đặt ở cuối
trang thì nó chỉ còn là một câu khiêm tốn.

Nó vạch đúng một ranh giới: chứng minh công cụ chạy đúng và chứng minh cả vòng chạy đúng là
hai tuyên bố khác nhau, và tôi mới làm được tuyên bố thứ nhất. Chưa có ticket nào đi hết từ
dispatch tới merge với đủ gate nổ trên việc thật bên trong repo này. Sáu lỗi bạn vừa đọc đều
đo ở downstream hoặc trong lúc dựng, không phải trong một vòng khép kín.

Tôi giữ khoảng trống đó mở. Nếu bạn cài và nó gãy ở chỗ tôi chưa đo, đó là dữ liệu tôi chưa
có.
