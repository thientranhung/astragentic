---
title: "Astragentic"
description: "Astragentic là scaffold để vận hành một team AI agent theo mô hình orchestrator: bạn trao đổi với một người đại diện, mọi việc đi qua issue tracker."
acts:
  - id: act-1
    eyebrow: "AST-016 · thành luật 2026-07-11"
    headline: "Hai session trên một checkout làm mất commit mà không ném lỗi."
  - id: act-2
    eyebrow: "BẢY CHẶNG"
    headline: "Bảy stage có tên, bốn trong số đó đã có lỗi đo được."
  - id: act-3
    eyebrow: "harness/.agents/memory/INDEX.md"
    headline: "Mỗi mục ledger chỉ ra file đang mang luật của nó."
harness: v6.1.19
---

## act-1

Hai session gốc dùng chung một checkout. Một session chạy `git switch` khi session kia đang
commit, ba commit rơi vào nhánh sai và biến mất khi nhánh được đổi lại. Không lỗi nào được ném ra,
vì mỗi session đều đúng nếu xét riêng.

Cách chữa thô nhất: mọi agent được spawn mà có quyền chạy git đổi trạng thái đều phải có
checkout riêng, kể cả agent chỉ đọc. Ngoại lệ "chỉ đọc" là giả định đã sinh ra AST-016: một
reviewer chỉ đọc đã `git switch` HEAD của người khác. Đánh đổi: mỗi Builder tốn thêm một
worktree trên disk.

## act-2

Hệ thống trước đó đo được 5 tới 14 vòng gate cho mỗi artifact, và một phần lớn các vòng sau
dùng để sửa phần vòng trước để lại (RELEASE-NOTES.md, bản 1.0.0). Lỗi không nằm ở reviewer.
Lỗi nằm ở khâu trước đó: những quyết định chưa từng được chốt được đưa thẳng vào code, rồi
mới chốt ở khâu tốn kém nhất của quy trình.

Tôi đẩy vòng lặp lên đầu quy trình và cắt phần còn lại thành bảy stage có tên. Bảy stage có
tên để mỗi lỗi đo được gắn vào đúng một stage; không có tên thì lần sau lỗi rơi vào chỗ không
ai chỉ ra được. Đánh đổi: quy trình dài hơn, và ba trong bảy stage vẫn trống vì tôi chưa đo
được lỗi nào ở đó.

## act-3

Mỗi lần có thứ hỏng, tôi ghi một mục vào ledger. Ghi lại thì rẻ và gần như vô dụng. Một mục
chỉ có giá trị khi nó được buộc vào một file đang bắt ai đó làm khác đi ngay hôm nay: contract
của một role, một skill, một hook, hoặc một check chạy được.

`harness/.agents/memory/INDEX.md` có một cột **Cited by** nói rõ mục nào đã buộc và mục nào chưa.
{{meta.cited}} trên {{meta.total}} mục có file trích dẫn; {{meta.orphan}} mục còn lại chưa trỏ về
đâu. Tôi giữ nguyên phần chưa buộc trong bảng thay vì lọc đi, vì một ledger chỉ hiện phần đã
xong thì không dùng để tự kiểm được nữa.
