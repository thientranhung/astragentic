---
title: "Astragentic"
description: "Vì sao mình dựng lớp điều phối này, mình đã chọn gì, và cái giá của từng lựa chọn."
acts:
  - id: act-1
    eyebrow: "AST-016 · promoted 2026-07-11"
    headline: "Một agent thì ngon. Ba agent thì việc biến mất mà không ai báo lỗi."
  - id: act-2
    eyebrow: "BẢY CHẶNG"
    headline: "Mình không cắt bảy chặng cho gọn mắt. Mỗi chặng là chỗ đã có thứ rơi ra."
  - id: act-3
    eyebrow: "harness/.agents/memory/INDEX.md"
    headline: "Đừng tin mình. Bấm vào một dòng và tự kiểm."
  - id: act-4
    eyebrow: "RELEASE-NOTES.md:393"
    headline: "Cái vòng này chưa từng chạy trọn một lần trên việc thật."
---

## act-1

Lúc đó mình chạy ba session trên cùng một checkout. Không có lỗi nào được ném ra. Chỉ là
một buổi chiều làm việc biến mất, và mình mất thêm một buổi nữa để hiểu vì sao.

Nên mình chọn cách chữa thô nhất. Mọi agent được spawn mà có quyền chạy git đổi trạng thái
đều phải có checkout riêng, kể cả agent chỉ đọc. Cái ngoại lệ "chỉ đọc" chính là thứ mình đã
tin, và nó sai. Cái giá là mỗi Builder tốn thêm một worktree trên đĩa và vài giây setup. Mình
trả, vì buổi chiều kia đắt hơn nhiều.

## act-2

Ban đầu mình chỉ có hai chặng: agent làm, mình review. Review kéo từ năm tới mười bốn vòng,
phần lớn vòng sau là đi dọn thứ vòng trước để lại. Reviewer không phải
chỗ hỏng. Chỗ hỏng là những quyết định chưa từng được chốt đi thẳng vào code, rồi được chốt ở
điểm đắt nhất của quy trình.

Nên mình đẩy vòng lặp lên đầu và cắt phần còn lại thành bảy chặng có tên. Bảy cái tên không
phải để trang trí. Khi một thứ hỏng, mình cần một chỗ để treo nó vào, nếu không lần sau nó
hỏng ở một chỗ không ai chỉ tay vào được. Cái giá là quy trình dài hơn, và ba trong bảy chặng
vẫn trống vì mình chưa đo được lỗi nào ở đó.

## act-3

Mỗi lần có thứ hỏng, mình ghi một dòng. Ghi thôi thì rẻ và gần như vô dụng. Một dòng chỉ đáng
giá khi nó bị buộc vào một file đang bắt ai đó làm khác đi ngay hôm nay: một rule luôn bật,
một mục Known failures trong skill, một check chạy được.

Nên bảng này có một cột nói thẳng dòng nào đã buộc, dòng nào chưa. {{meta.cited}} trên
{{meta.total}} dòng có file mang nó. {{meta.orphan}} dòng còn lại chưa trỏ về đâu. Mình để
nguyên phần chưa buộc trong bảng thay vì lọc đi, vì một cuốn sổ chỉ hiện phần đã xong thì
không tự kiểm được nữa. Anh em bấm vào một dòng có mũi tên là ra đúng file, không
cần chạy gì.

## act-4

Dòng ở trên là mình tự viết trong release notes của mình, và mình kéo nó lên đây vì để ở cuối
trang thì nó chỉ là một câu khiêm tốn cho có.

Nó vạch đúng một ranh giới: chứng minh công cụ chạy đúng và chứng minh cái vòng chạy đúng là
hai tuyên bố khác nhau, và mình mới làm được cái thứ nhất. Chưa có ticket nào đi hết từ
dispatch tới merge với đủ gate nổ trên việc thật bên trong repo này. Sáu lỗi anh em vừa đọc
đều đo ở downstream hoặc lúc dựng, không phải trong một vòng khép kín.

Mình để khoảng trống đó mở. Nếu anh em cài và nó gãy ở chỗ mình chưa đo, đó là dữ liệu mình
chưa có.
