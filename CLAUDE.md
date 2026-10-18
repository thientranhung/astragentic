# Astragentic — quy tắc làm việc trong repo này

**Không có số thì không có mục.** Mỗi mục trong một đề xuất, kế hoạch hay release note mang hai
cột `số đo | nguồn` (một con số đếm được, một dòng log, một tổng từ transcript, một test trồng
sẵn và thấy nó fail). Mục chưa có số ghi `chưa đo` và đi vào bước đo, không vào kế hoạch.
"Có thể", "nhiều khả năng", "thường" trong câu đề xuất là dấu hiệu đang đoán.

Đặt ngày 2026-10-18, sau khi đếm thấy: advisor của Builder 0 lần gọi trong 14 ticket (đã từng
được đề xuất bỏ vì "đắt nhất"), và 42/99 guard trong harness chưa bao giờ bắn ngoài selftest.

Nguồn đo có sẵn: transcript `~/.claude/projects/<project>/*.jsonl` (usage từng lần gọi, tool
call), `/tmp/harness-hook-events.log`, `/tmp/herdr-watchdog-*.log`, git log của project
(marker, `Ledger:`, stamp), `.astraler/state/dispatch-record.json`, `npx ccusage@latest`.
