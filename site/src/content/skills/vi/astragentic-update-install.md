---
title: astragentic-update-install
oneLiner: "Kiểm tra phiên bản Astragentic đã cài, hoặc cài và cập nhật nó trong project hiện tại."
group: upkeep
order: 0
runtimes: [claude]
source: harness/.claude/skills/astragentic-update-install/SKILL.md
rented: false
lang: vi
harness: v6.1.19
updated: 2026-11-22
---

## Nó làm gì

Skill kiểm tra project, xác định release tag, stage nó và adapt ngay trong session hiện tại. Yêu cầu chỉ kiểm tra cho phép inspect và báo cáo, không cho phép stage. Yêu cầu cài hoặc cập nhật tường minh cho phép stage và adapt.

- **Inspect.** Bằng chứng phiên bản được đọc riêng: applied version cũ, installed và adapted version của Codex, và các release đã stage. Thiếu state nghĩa là chưa biết; đã stage không có nghĩa đã adapt.
- **Resolve.** Tag lấy từ `ASTRAGENTIC_REPO` hoặc repository chuẩn, không bao giờ từ `origin` của project. Tag phiên bản mới nhất đã publish được chọn, trừ khi owner chỉ định.
- **Stage.** `get.sh` stage vào `.astraler/releases/<version>/` và không ghi file nào của project.
- **Adapt.** Session đọc trọn `ADAPT-RUNTIME.md` và theo route của runtime thực tế.

**Cái giá.** Skill không launch runtime khác và không đóng dấu hoàn tất để bỏ qua việc chưa xong. Nó không sửa cấu hình cấp user, không commit, publish hay deploy nếu không được cho phép riêng.

## Khi nào dùng

| Trước mặt bạn là | Dùng |
|---|---|
| "Kiểm tra phiên bản" | Chỉ kiểm tra: inspect và báo cáo |
| "Cài" hoặc "cập nhật Astragentic" | Stage, rồi adapt trong session này |
| Release không có `ADAPT-RUNTIME.md` trong session Codex | Để nguyên trạng thái staged và nêu lý do |

## Nó để lại gì

| Chuyện gì xảy ra | Nằm ở đâu |
|---|---|
| Một release đã fetch | `.astraler/releases/<version>/` |
| File project đã adapt, receipt, version state | Theo contract adapt được chọn |
| Một báo cáo | Phân biệt fetched, staged, installed, adapted, kèm xung đột chưa giải quyết |

## Đang chạy đúng nếu

- Báo cáo phân biệt fetched, staged, installed và adapted.
- Kiểm tra static, mocked và live-session được liệt kê như các bằng chứng riêng.
- Không có tuyên bố live startup hay gate được thực thi mà chưa đo.

## Nó nằm ở đâu trong chuỗi

Chạy theo yêu cầu, trước khi `dispatch-ticket` có gì mới để dispatch. Release tag luôn có tiền tố `v`; updater chỉ đọc `refs/tags/v*`.
