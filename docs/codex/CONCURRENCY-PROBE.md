# Probe concurrency: hai quick Builder native

Ngày đo: 2026-11-05. Chạy đúng một cặp `codex exec`, hai process native
`gpt-6.1-sol`/`low`, trên hai worktree/branch riêng từ base
`f484b22a4a37157ca8fc9a0e723299ccb61e0442`. Đây là fixture **host-driven**, chưa chứng
minh Thomas native tự dispatch hoặc quan sát hai worker qua Herdr.

## Nhận diện và phạm vi

| Fixture | UUID native | Branch | Tracked write-set |
|---|---|---|---|
| A | `01a1ac63-8da4-7961-b303-23f869733fe5` | `codex-concurrency-20261105-a` | `README.md` |
| B | `01a1ac63-8da4-7081-86c3-d262682d4185` | `codex-concurrency-20261105-b` | `README.vn.md` |

Mỗi checkout được cài overlay hiện hành; task yêu cầu đọc Builder/common contract,
quick classification, xác minh cwd/branch/HEAD, sửa đúng một heading và viết report
riêng trong `.scratch/concurrency/report.md`. Không commit/push/tracker/provider khác,
Claude, delegation hay thay đổi config/quyền. Model/effort được xác nhận từ native
turn_context, không chỉ argv. Policy của cả hai: `workspace-write`, network off,
hai exclude flags false; approval `never` là mặc định được đo của `codex exec` trong
phép thử này. Không truyền sandbox/approval override.

## Bằng chứng overlap và cô lập

| Process | Bắt đầu UTC | Kết thúc UTC | Exit |
|---|---|---|---|
| A | 15:46:07.698443 | 15:46:47.511995 | 0 |
| B | 15:46:07.699970 | 15:46:44.389958 | 0 |

Process intervals overlap **36.6897 giây**, được tính bằng monotonic clock của host.
Đây là overlap của hai process native, chưa chứng minh hai shell mutation xảy ra
cùng một thời điểm. Không dùng sleep để tạo overlap.
[process-timing.json](evidence/concurrency/process-timing.json) giữ argv/PID/thời gian.

Coordinator kiểm tra byte độc lập: trong A chỉ README.md khác base đúng một replacement,
README.vn.md có SHA256 nguyên base; trong B chỉ README.vn.md khác base đúng một
replacement, README.md có SHA256 nguyên base. `git diff --name-only` chỉ trả đúng
write-set tương ứng, `git diff --check` exit 0 cho cả hai; HEAD cả hai không đổi.
Hash đầy đủ ở [coordinator-checks.json](evidence/concurrency/coordinator-checks.json).
Hai report ghi dirty handback, chưa integration-ready. Không suy diễn isolation thành
một write-set gate được cưỡng chế bởi harness.

Git từ chối thử tạo worktree thứ hai bằng **cùng branch deterministic của A**:
exit 255, `fatal: a branch named 'codex-concurrency-20261105-a' already exists`.
Không tạo duplicate directory, không xoá branch để vượt lỗi.
[deterministic-duplicate.txt](evidence/concurrency/deterministic-duplicate.txt).

## Artifact, cleanup và giới hạn

Đã giữ [patch A](evidence/concurrency/a-artifact.patch),
[patch B](evidence/concurrency/b-artifact.patch), hai worker report, native JSONL events,
policy/model snapshots và inventory tracked/untracked/ignored. Sau cả hai process exit 0,
uninstall overlay fixture, lưu owner config fixture, reverse đúng patch đã lưu và xoá
report đã lưu. Kiểm tra status trống kể cả ignored/untracked và HEAD bằng base rồi
remove đúng hai worktree/branch không force. [cleanup.txt](evidence/concurrency/cleanup.txt).

Không có QA độc lập, merge/integration, claim tracker, shared checkout contention,
Junior hoặc autonomous native Thomas trong phép thử này. Correctness inspection của
Builder và coordinator byte/diff checks không thay review độc lập cuối cùng. Đây là
phép thử concurrency tối thiểu; không xác nhận toàn bộ goal hoàn tất. Dừng thêm probe
sau cặp fixture này.
