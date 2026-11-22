---
title: dispatch-qa-walk
oneLiner: "Khởi động app trong worktree riêng và để QA dùng nó như một người dùng, trước PR, merge hoặc phát hành."
group: gate
order: 3
runtimes: [claude]
source: harness/.claude/skills/dispatch-qa-walk/SKILL.md
rented: false
lang: vi
updated: 2026-11-22
harness: v6.1.19
---

## Nó làm gì

`dispatch-qa-walk` là recipe để Thomas dispatch QA, gate phán hệ thống đang chạy thay vì phán cái diff. Nó chọn mode theo surface của ticket, dựng target tại SHA đang review trong worktree riêng, đóng gói plan và brief, thu report rồi commit.

Đọc diff và dùng sản phẩm là hai hành vi khác nhau, và suite xanh không chứng minh được hành vi nào. QA chạy trong một gate pane trên cả hai host, Herdr hoặc Orca; cơ chế gate nằm ở `dispatch-ticket/GATE.md`.

| Ticket thay đổi | Mode | QA làm |
|---|---|---|
| màn hình, journey, link | walk | dùng UI: journey, số liệu giữa các màn, deeplink |
| một endpoint hoặc hợp đồng service | probe | gọi API: hợp đồng, status code, đường lỗi và bị từ chối |
| một job, pipeline hoặc luồng dữ liệu | verify | kiểm job đã chạy, dữ liệu đã tới, log sạch |

**Số đo.** Từng có một agent đi bộ bằng trình duyệt được ship qua nhiều bản phát hành mà chưa chạy lần nào, và một nửa ngày có chín vòng fold cùng một merge mà QA chưa hề được dispatch. Vì vậy skill mang bộ đếm: quá 10 merge chạm surface người dùng thấy hoặc endpoint công khai kể từ lần chạy gần nhất là STOP. "Không merge nào chạm surface" là câu trả lời hợp lệ; "chưa đếm" thì không.

**Cái giá.** Một lượt walk khởi động app là thao tác tốn tài nguyên nhất của harness. Cleanup theo thứ tự: dừng app, xác nhận port trống, giải phóng tài nguyên của worktree, rồi `git worktree remove --force`.

## Khi nào Thomas dùng nó

| Trước mặt bạn là | Dùng |
|---|---|
| PR hoặc merge chạm surface hay endpoint công khai | `dispatch-qa-walk`, độ sâu incremental |
| Một release hoặc một slice đang đóng | `dispatch-qa-walk`, độ sâu full |
| Quá 10 merge chạm surface kể từ lần chạy gần nhất | `dispatch-qa-walk`; đây là STOP |
| Nhiều ticket cùng về một PR | một lượt tại SHA đầu của lô, phạm vi là hợp các surface |
| Không có surface, endpoint hay job nào | Không dùng; ghi rằng nó không áp dụng |

## Cần sẵn gì

- **Chỉ Thomas.** Recipe thuộc về station, không thuộc về Builder.
- **Một cách chạy project.** Repo không có thì không walk được, và đó là phát hiện gửi owner.
- **Consent và mọi thao tác ghi được phép, gọi tên chính xác.** Thiếu chúng thì QA từ chối và ghi COVERAGE GAP.
- **Plan** `docs/qa/plan-<slug>.md` làm oracle; không có thì QA suy journey từ source với độ tin cậy thấp hơn.

## Nó để lại gì

| Chuyện gì xảy ra | Nơi nó nằm lại |
|---|---|
| Report của QA | `.scratch/qa/<key>-<mode>-<sha>.md`, commit riêng, hoặc đường dẫn của plug `qa-report-path.sh` |
| Trace matrix và verdict | trong report: PASS, CONCERNS hoặc FAIL, rồi COVERAGE GAPS |
| Lượt chạy đã xảy ra | commit rỗng `qa(walk): <key> — <verdict>` kèm `Mode:`, `Scope:`, `Verdict:`, `Report:` |
| Danh sách verified-clean | `.astraler/state/qa-verified-clean.md`, chép trước khi cleanup |

Một loại marker phủ cả ba mode. Lượt chạy chỉ để lại report thì không để lại gì mà merge gate đếm được.

## Đang chạy đúng nếu

- App chạy trong worktree riêng tại SHA đang review, không bao giờ trong checkout của Builder.
- Cả `$GATE_FILE` và `$VERIFIED_CLEAN_FILE` tồn tại, không rỗng và đã được chép ra trước khi gỡ worktree.
- Brief gọi tên mọi surface hiển thị khái niệm đã đổi, không chỉ các surface đã đổi.
- App đã bị dừng và port xác nhận trống trước khi gỡ.
- Có marker `qa(walk):` tại head đã walk.

## Nó nằm ở đâu trong chuỗi

`dispatch-ticket` → Builder handback → `dispatch-qa-walk` → marker `qa(walk):` → merge. QA khuyến nghị, Thomas phân loại, Builder sửa, và quyết định sản phẩm lên owner.
