# Kiểm chứng bounded full Builder trên fixture

Ngày đo 2026-11-05, native `codex exec`, Sol/low theo chỉ định probe của owner.
Đây là kiểm chứng một increment Python theo full Builder contract, **không phải full
E2E hoặc ticket đã hoàn tất**. Independent review chưa có; cross-vendor chưa cấu hình,
owner chưa chọn off. Cả hai giữ trạng thái completion BLOCKED.

## Setup và nhận diện

Clone local riêng ở base `f484b22a4a37157ca8fc9a0e723299ccb61e0442`, branch
`codex-full-builder-fixture`; overlay được cài bằng installer nguồn. Scenario là file
untracked do operator tạo, không phải sản phẩm đã commit ở base đó. Builder đọc common,
Builder, DISPATCH và bốn skill TDD/review/simplify/cross-vendor từ overlay đã cài.
Snapshot contract giữ tại [contracts](evidence/full-builder/contracts/).

Native thread `01a1ac61-ad31-7761-8be5-97c992c7ab26`, dispatch `full-builder-001`,
event `full-builder-event-001`; ACK được in, không cấu hình coordinator UUID/queue.
Phiên dùng `--ignore-user-config --ephemeral --sandbox workspace-write`, approval
never và network false; chỉ thêm quyền ghi thư mục evidence. Không sửa cấu hình/trust
cá nhân. Không có AGENTS.md tại root clone; model báo rõ sự vắng mặt, dùng brief và
contract được giao. [command.json](evidence/full-builder/command.json) giữ argv thật.

Attempt detached ban đầu kết thúc mà không tạo events/report hoặc sửa fixture; không
có outcome inference để khẳng định. Chạy lại bằng process attached cùng argv; native
process kết thúc exit 0 sau 100.01s. Exit 0 chỉ là process kết thúc, không là completion.
[process.json](evidence/full-builder/process.json) ghi cả giới hạn startup này.

## Hành vi và kiểm tra artifact

Bug: `boxes_needed` làm tròn xuống khi item không chia hết capacity. Brief yêu cầu
đầu vào hợp lệ nonnegative item count, positive capacity; không mở rộng validation.
Write-set chỉ hai file scenario; không Junior/helper/provider khác hoặc model bổ sung.

1. Builder viết test `(7,3)=3`, chạy thật và nhận AssertionError exit 1 trước sửa:
   [red.json](evidence/full-builder/red.json). Đây là red hành vi, không phải lỗi import.
2. Sửa thành `(item_count + capacity - 1) // capacity`, slice test exit 0; thêm coverage
   `(0,3)=0`, `(6,3)=2`, `(1,3)=1`; cả bốn assertions đạt. Chỉ claim red cho case partial;
   hai case zero/exact vốn đã đúng. [green.json](evidence/full-builder/green.json).
3. Simplify kiểm tra increment, chọn no-change có lý do: biểu thức integer duy nhất,
   không float/state/abstraction/dependency. Rerun checks exit 0 tại
   [post-simplify.json](evidence/full-builder/post-simplify.json). Đây là local inspection,
   không thay review độc lập còn thiếu.
4. Operator chạy lại test độc lập với output bốn case pass; kiểm tra HEAD không đổi,
   tracked diff rỗng, toàn bộ file manifest của overlay nguyên vẹn; scenario chỉ có
   hai file, không bytecode. [operator-audit.json](evidence/full-builder/operator-audit.json).

Final source SHA256 `5c54883f22808fd82143fa1e0ad150798b80e0c517669f21d34cb8a3f6d60bb1`;
test SHA256 `cd47be2b4b3ecb169048bc9a49997c1cbe3b142222ae099e99fd24fc91a92a6c`.
[Outputs](evidence/full-builder/outputs/) và [patch](evidence/full-builder/artifact.patch)
giữ artifact thực tế. HEAD/tree không bao gồm scenario untracked; không dùng diff rỗng
để gọi artifact clean. Brief, input hash và đường dẫn fixture giữ trong
[fixture.json](evidence/full-builder/fixture.json).

## Handback và phần chưa đạt

[Report](evidence/full-builder/report.md) và [checkpoint](evidence/full-builder/checkpoint.md)
giữ identity, criteria, command evidence, hash và disposition **BLOCKED / NOT
INTEGRATION-READY**. Independent correctness/intent/standards đều MISSING; không gọi
self-inspection là clean review. Cross-vendor NOT RUN vì thiếu owner policy/capability;
không gọi Codex là provider khác. UI không áp dụng; Junior disabled.

Không commit, tích hợp, tracker/service write, publish hoặc gọi Claude/provider khác.
Chưa đo launcher business role, Herdr/queue, resume/concurrency hoặc toàn bộ Thomas
journey. Operator rerun không là review độc lập. Không sửa runtime trong pass này.

## QA read-only trên đúng handback và cleanup

Một phiên native Sol/low riêng dùng sandbox read-only, explicit owner consent cho
fixture local synthetic; không quyền sửa file hoặc gọi dịch vụ. QA đọc QA/common,
pin đúng hai SHA256 Builder trả, inspect function/test và chạy lại test `python3 -B`
exit 0. QA còn kiểm tra độc lập bốn lời gọi function, actual `[0,2,3,1]`, exit 0.
[QA handback](evidence/full-builder/qa-last.md) có trace matrix 4/4 covered/pass;
[QA argv](evidence/full-builder/qa-command.json) và
[events](evidence/full-builder/qa-events.jsonl) giữ lệnh/output thật. Process exit 0
sau 40.674s không tự nó là QA verdict; verdict dựa trên kiểm tra artifact/criteria.

Heredoc đầu tiên không chạy được Python vì read-only shell không tạo được temp file;
QA chuyển sang `python3 -B -c` thành công. Git còn phát cảnh báo xcrun cache không
ghi được nhưng trả status. Giữ nguyên các lỗi trong transcript, không nới quyền.
Không bytecode hoặc file mutation trong fixture. Đây là functional QA giới hạn đúng
bốn criteria, không thay independent code review hoặc cross-vendor. Integration
vẫn **BLOCKED**, không có completion claim.

Operator post-audit xác nhận source/test hash không đổi, HEAD/staged/tracked diff
không đổi, toàn bộ managed overlay nguyên vẹn, không untracked lạ hay bytecode:
[qa-post-audit.json](evidence/full-builder/qa-post-audit.json). Mọi file untracked
của fixture (overlay, brief và scenario) được archive kèm hash trong
[fixture-archive](evidence/full-builder/fixture-archive/); committed source được pin
bằng base HEAD. Sau native processes kết thúc, xóa đúng thư mục clone tạm do probe
tạo, không shared worktree hoặc pane; [cleanup.json](evidence/full-builder/cleanup.json)
xác nhận đường dẫn không còn. Không dùng Git force hoặc dọn tài nguyên owner.
