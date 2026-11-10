# Kiểm chứng native quick-ticket trên fixture

Ngày đo: 2026-11-05; Codex CLI 0.166.0. Đây là functional fixture validation,
chưa phải review độc lập hoặc xác nhận toàn bộ harness sẵn sàng phát hành.

## Phạm vi và nhận diện

Dùng Builder contract với nhãn quick, model `gpt-6.1-sol`, effort `low`, theo bảng
orchestrator hiện hành. Không dùng owner Quick Builder. Một worktree từ HEAD
`f484b22a4a37157ca8fc9a0e723299ccb61e0442`, branch riêng
`codex-native-quick-20261105-sol`, overlay cài bằng installer hiện hành.
Herdr workspace `wW`, tab riêng `wW:tG`, pane riêng `wW:pP`; không chạm pane owner.
Worker tự in UUID `01a1ac4e-1195-76f3-af37-5c89768a24f7` bằng shell.
Các đường dẫn, brief hash và nhận diện đầy đủ ở
[evidence/native-quick-flow/identities.json](evidence/native-quick-flow/identities.json).

## Hành trình đã đo

`herdr agent start` hết 30 giây và trả timeout. Quan sát chính pane đó cho thấy worker
đã chạy bootstrap, tự in UUID/cwd/branch/HEAD và đợi; không khởi động lại.
Bootstrap hoàn tất ở `done`, sequence 3217. Queue unique event
`native-quick-event-001` được chấp nhận với message ID
`01a1ac4e-9f2f-7d91-8ec7-6aea94ed2f52`; sau gửi, cùng pane chuyển `working`, sequence
3218. Transcript có ACK đúng dispatch/event; worker đọc brief và contract, xác minh
SHA256 và checkpoint trước khi sửa.

Worker đổi đúng `## Quickstart` thành `## Quickstart (native Codex fixture)` trong
README. `git diff --check`, so byte với base sau đúng một replacement, và kiểm tra
write-set đều đạt. Coordinator kiểm tra diff thực tế, không lấy trạng thái done làm
verdict. Handback có checkpoint/report, HEAD không đổi, ghi rõ dirty artifact chưa
integration-ready. Không commit, push, tracker write, provider khác hoặc delegation.

Gửi lại **cùng message/event** để đo duplicate, queue message ID mới
`01a1ac4f-e7b8-79d3-b64f-5ef33d9fc64d`. Quan sát working sequence 3221.
Worker đọc checkpoint completed, xác minh README hash, in `DUPLICATE acknowledged`
và kết thúc ở done sequence 3222. Coordinator so byte độc lập với base + đúng một
replacement, kiểm tra hash README trước/sau duplicate bằng nhau
`8d4e3ffcb2b1bcc11f42b48f339b829cc894f30f962ed8357923c36af1c0d385`,
write-set vẫn chỉ README và `git diff --check` vẫn exit 0. Checkpoint/report trước
và sau được giữ nguyên trong evidence; không chỉ dựa vào lời xác nhận của worker.

Đã lưu patch, report, checkpoint, transcript và inventory gồm tracked/untracked/ignored.
Sau khi xác nhận worker done, chỉ đóng tab `wW:tG`, uninstall overlay thuộc fixture,
lưu rồi xoá config fixture do coordinator tạo, reverse patch đã lưu, xoá ba artifact
scratch đã lưu. Kiểm tra Git status trống cả ignored/untracked rồi remove worktree
và branch không có commit riêng, không dùng force. Log: [cleanup.txt](evidence/native-quick-flow/cleanup.txt).

Snapshot DISPATCH đã được worker đọc được trích nguyên văn từ output lệnh shell trong
session log để giữ đúng phiên bản trước thay đổi hướng dẫn worktree mới của coordinator.
SHA256 `4b0deb25cd0bf59bc341606b678ddc08db4182492e907bc99dd64d06ce0f2648`:
[fixture-DISPATCH.md](evidence/native-quick-flow/fixture-DISPATCH.md).
Bảng model fixture được giữ ở [fixture-orchestrator.md](evidence/native-quick-flow/fixture-orchestrator.md).

Bằng chứng chính: [worker-report.md](evidence/native-quick-flow/worker-report.md),
[duplicate-transcript.txt](evidence/native-quick-flow/duplicate-transcript.txt),
[coordinator-checks.json](evidence/native-quick-flow/coordinator-checks.json),
[artifact.patch](evidence/native-quick-flow/artifact.patch).

## Probe chiều ngược worker → coordinator

Đo riêng transport với hai phiên native Sol/low, không coi đây là Thomas/Builder
business-role E2E. Cả hai phiên có `sandbox_policy.type=workspace-write`,
`network_access=false`, hai exclude flags `false`; approval `on-request`, reviewer `user`.
Filesystem restricted: root read, worktree và vùng tmp write; `.git/.agents/.codex/.aws`
trong worktree read-only. Trích nguyên policy/command từ từng turn_context ở
[native-session-policy-and-commands.json](evidence/native-quick-flow/reverse-queue/native-session-policy-and-commands.json).
Không phiên native nào trong probe này tự chạy Herdr get/read/wait: toàn bộ lệnh Herdr
do external controller chạy; native coordinator chỉ đọc report/log chung bằng `cat`.
Do đó bằng chứng này chưa chứng minh autonomous Thomas observation capability.
Mỗi phiên tự chạy shell in UUID: coordinator
`01a1ac55-682f-7181-aac0-a62396f89a58` ở `wW:pQ`/`wW:tH`, worker
`01a1ac55-6c48-7141-b963-ff0da3ea8a74` ở `wW:pR`/`wW:tJ`. Dùng worktree fixture riêng,
overlay hiện hành; không sửa tracked file. Bằng chứng riêng trong
[evidence/native-quick-flow/reverse-queue](evidence/native-quick-flow/reverse-queue/identities.json).

Bootstrap “wait” bị cả hai model hiểu thành gọi `clock.sleep(60000)` hai lần, giữ turn
active. Queue setup/task được chấp nhận nhưng chưa được tiêu thụ trong turn đang sleep.
Đây là hạn chế đã đo; không gọi acceptance là automatic wake-up. Control event riêng
`reverse-stop-sleep-001` qua Herdr yêu cầu kết thúc turn và xử lý queue **đã tồn tại**,
không chứa lại task. Sau control, transcript cho thấy cả setup queue gốc và send-task
gốc được tiêu thụ, không gửi lại chúng. Xem [sleep-loop.json](evidence/native-quick-flow/reverse-queue/sleep-loop.json)
và transcript cuối của hai pane. Cả hai lệnh `agent start` timeout; không relaunch.

Worker thử đúng một lần `codex queue` tới UUID coordinator đã xác minh, event
`reverse-handback-event-001`: exit **1**, stdout trống, stderr:

```text
WARNING: proceeding, even though we could not create PATH aliases: Operation not permitted (os error 1)
Error: failed to start embedded app server: Operation not permitted (os error 1)
```

Đã lưu [worker-queue.txt](evidence/native-quick-flow/reverse-queue/worker-queue.txt)
và [worker.md](evidence/native-quick-flow/reverse-queue/worker.md). Không retry,
`--resume`, nới quyền, escalation hoặc sửa config. Đây là lỗi process boundary trong
quyền hiệu lực của worker, chưa chứng minh chiều ngược queue hoạt động.

Fallback do host điều khiển được đo thực tế: external controller đọc pointer/report qua Herdr, gửi control riêng
`fallback-observation-001` cho coordinator; coordinator đọc artifact hiện có và lưu
[coordinator.md](evidence/native-quick-flow/reverse-queue/coordinator.md), in
`FALLBACK OBSERVED reverse-handback-event-001`. Coordinator ghi rõ **không có queue
receipt/RECEIVED ACK**. Done của coordinator sequence 3233, worker 3231. Sau readback,
đã lưu report/transcript/manifest/inventory, đóng đúng hai tab sở hữu, uninstall fixture,
kiểm tra status trống cả ignored/untracked và HEAD không đổi, remove worktree/branch
không force. Xem [cleanup.txt](evidence/native-quick-flow/reverse-queue/cleanup.txt).

## Native coordinator tự gọi Herdr read-only

Probe riêng, một native session Sol/low, UUID do model shell in:
`01a1ac60-4a7c-7a33-835f-6ab2d5b69422`, pane sở hữu `wW:pS`, tab `wW:tK`.
Model đọc Herdr skill, xác minh `HERDR_ENV=1`, rồi tự chạy subprocess bình thường
**trong sandbox của native session**, không phải external controller chạy thay.
Target là chính pane fixture đang active; không truy cập pane owner.

| Lệnh native | Exit | Kết quả |
|---|---|---|
| `herdr --help` | 0 | CLI khả dụng; chưa chứng minh socket access |
| `herdr agent get wW:pS` | 1 | PermissionDenied |
| `herdr agent read wW:pS --source visible --lines 20` | 1 | PermissionDenied |
| `herdr agent wait wW:pS --until working --timeout 1000` | 1 | PermissionDenied |

Ba lệnh cuối có stdout trống, không timeout; cùng exact stderr:

```text
Error: Os { code: 1, kind: PermissionDenied, message: "Operation not permitted" }
```

Mỗi thao tác chạy đúng một lần; không retry, escalation, sandbox/config/trust edit.
Turn_context xác nhận policy vẫn `workspace-write`, `network_access=false`, hai
exclude flags `false`, approval `on-request`/reviewer `user`, cùng restricted filesystem
như probe chiều ngược. Bằng chứng:
[result.json](evidence/native-quick-flow/native-herdr-readonly/result.json),
[native-policy-and-commands.json](evidence/native-quick-flow/native-herdr-readonly/native-policy-and-commands.json),
[final-transcript.txt](evidence/native-quick-flow/native-herdr-readonly/final-transcript.txt).

Do đó **autonomous native Thomas quan sát Herdr đang bị chặn ở boundary quyền đã đo**.
Host controller quan sát được Herdr không chứng minh native Thomas có cùng quyền.
Đây là probe capability tối thiểu trên pane của chính nó, chưa phải điều phối worker
hoặc kiểm chứng business role.

Lần start đầu bị Herdr từ chối trước khi launch vì dòng shell 1445 byte vượt canonical
limit 1024. Controller kiểm tra pane vẫn là shell, đưa đúng task vào file và dùng
bootstrap ngắn; phiên duy nhất sau đó chạy, start timeout nhưng không relaunch model.
Native session kết thúc done sequence 3236; đã lưu report/task/result/manifest, đóng
đúng tab sở hữu và remove worktree/branch không force sau kiểm tra status trống cả
ignored/untracked. [cleanup.txt](evidence/native-quick-flow/native-herdr-readonly/cleanup.txt).

## Giới hạn

Không có UUID coordinator được xác minh là phiên riêng của subagent điều phối;
`CODEX_THREAD_ID` kế thừa không đủ để gắn nhận diện đó. Vì vậy trong quick-task fixture đầu không gửi queue về
owner/root. Probe chiều ngược riêng ở trên bổ sung phép thử thực tế với UUID riêng
và đo được lỗi quyền; return queue ACK/handback thành công vẫn chưa được chứng minh.
Handback dùng durable report và Herdr observation có giới hạn; không mở rộng quyền.

Đây là thay đổi nội dung nhỏ, không có full ticket, Shaper release, QA độc lập,
Junior, concurrency, resume/interrupt hoặc tích hợp artifact. Correctness inspection
của Builder và kiểm tra diff của coordinator không thay cho review độc lập cuối cùng.
Không có bằng chứng ở đây để tuyên bố toàn bộ goal hoàn tất.
