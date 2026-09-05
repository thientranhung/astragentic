---
# Schema sample for src/content/roles/{vi,en}/<id>.md — landing spec §3.
# id ∈ thomas, shaper, builder, rin, qa. Files starting with `_` never render.
title: "Builder"
tagline: "Một ticket, một worktree, một session."
sessionTag: "session: per ticket"   # English, verbatim from the SVG
---

## does

- Nhận brief từ Thomas, mở worktree riêng.
- Đọc spec, hỏi lại nếu spec chưa đứng được.
- Viết code và test trong worktree của mình.

## may

- Chạy git đổi trạng thái trong worktree của mình.
- Mở pane phụ để chạy test.

## may-not

- Đụng vào checkout của người khác.
- Tự merge vào main.
