# STALL-FIX — WALK007: Stop hook + notification fallback

**Bản thay thế checker không có caller đã bị từ chối.** Source chỉ ở worktree
`/tmp/astragentic-stall-walk007`, base `3ff486e2c1e9dd2e6d17348c301a036773c74d8c`.
Không commit/publish/install sản phẩm, không sửa tracked main hoặc Claude/ARM.

[Patch 10 files](evidence/stall-turn-end/proposed.patch), SHA256
`3048f76c88bcd0a82c7f30e0a98d446739641e71db7107367719edf52d007b20`.
[Source manifest](evidence/stall-turn-end/manifest.json) pin từng file.
`coordinator_check.py`, `COORDINATOR-CHECK.md` và bộ test cũ đã bỏ khỏi candidate.

## Luồng cuối cùng

1. Thomas ghi `handback: <id> <iso-ts>` ngay khi nhận, rồi ghi
   `disposition: <id> <state> <iso-ts>` sau hành động/disposition thực sự.
   Năm trạng thái dừng hợp lệ: worker_running, external_wait, owner_paused,
   completed, idle; thiếu disposition hoặc coordinator_pending vẫn còn nghĩa vụ.
2. Project Stop hook gọi **cùng script** `coordinator-turn-end.sh <project> --stop`.
   Payload native UUID/cwd phải khớp binding record. Còn pending và
   stop_hook_active=false: stdout JSON block, reason nêu đúng handback + hành động
   theo contract. Một guard bền theo session/turn bổ sung chống gọi hook trùng.
3. stop_hook_active=true: không block nữa; nếu còn pending, hiện Herdr notification
   một lần per dispatch/handback. Reserve/fsync trước external effect; failure/timeout
   log rõ, không tự retry. bell-off và disposition pause hợp lệ giữ im lặng.
4. Đã đo Stop chạy trong TUI Herdr, nên **launcher bình thường không thêm notify**.
   Khi một môi trường chưa xác minh được Stop, `--coordinator-notify` là opt-in
   fallback chỉ cảnh báo; BA/Quick Builder không nhận flag này. Không queue/resume.
5. Installer ship script + template `coordinator-hooks.json`; ADAPT yêu cầu cấu hình
   `.codex/hooks.json` ở coordinator checkout, preserve hook khác, owner `/hooks`
   trust, restart và kiểm chứng. Không tự ghi trust hoặc kích hoạt hook vào workers.

Đoạn Thomas mới đúng **6 dòng**. Status question không cancel; promise/PID heartbeat
không phải progress. Không timer, daemon, scheduler, self-queue hoặc agent thay thế.

## Số đo | nguồn

| Số đo | Nguồn / phạm vi |
|---|---|
| CLI 0.167.0, Herdr 0.9.5 | CLI help/version đã lưu ở evidence/stall-walk007/capabilities.json |
| **1 payload Stop thật** từ TUI `herdr agent start`, Astra/medium, qua recorded Unix daemon | [live-stop-payload.json](evidence/stall-turn-end/live-stop-payload.json); owner trust folder + capture hook tại wW:p0/wW:tT. Capture at 2026-11-09T08:05:32.975553Z. |
| session_id/turn_id nonnil; session_meta UUID/cwd khớp | So sánh raw local trong capture, không dùng UUID nil do renderer; cùng evidence |
| Native capture có stop_hook_active=false, turn_id, cwd, last_assistant_message=STOP_CAPTURE_OK | Actual stdin capture; hook fixture chỉ capture và trả `{}` |
| Replay payload Stop thật + WALK007 marker: block một lần, reason đúng event | [stop-replay.json](evidence/stall-turn-end/stop-replay.json); chỉ remap cwd sang disposable fixture, đổi stop_hook_active để mô phỏng lượt tiếp tục |
| Replay true: exit0, stdout rỗng, **1 Herdr shown:true**; gọi trùng không thêm; completed sạch không block/alert | Cùng replay; accepted_unconsumed không đồng nghĩa owner đã đọc |
| Replay callback notify với bản sao record thật: shown:true sau **40.642ms** từ callback start; process kết thúc sau 45.030ms | [replay.json](evidence/stall-turn-end/replay.json). Thêm marker mới **chỉ trong fixture**, vì record legacy chưa có hai dòng machine-readable. Native envelope ở lượt này được dựng từ task_complete WALK007, không giả nhận là payload notify đã capture. |
| Replay Stop: block function/process 47.783ms; true→notification process 54.427ms; duplicate 42.664ms | stop-replay.json; một mẫu, không SLO/percentile |
| **63/63 tests PASS**, 35.214s | [tests.log](evidence/stall-turn-end/tests.log); suite Codex cuối trên candidate, không full release selftest |
| Mutation test bỏ dedup: assertion “lần hai vẫn 1” thất bại như yêu cầu | test_planted_missing_dedup_is_caught; outer test xác nhận mutant bị bắt |
| git diff --check, git apply --check PASS; main tracked diff rỗng | Candidate patch/manifest và main 3ff486e |

**Không đánh tráo latency:** turn WALK007 thật kết thúc 12:42:40.909 (+07), đã xảy ra
trước probe. Trường historical_turn_end_to_receipt_ms là khoảng cách tới lần replay,
không phải độ trễ native notify. Con số 40.642ms đo callback→receipt thực. Latency
model turn-end→notification khi production hook chạy và **Codex thực sự tạo
continuation từ block của script này** còn NOT MEASURED. Đã đo native Stop dispatch;
block/second-pass behavior được kiểm qua script replay, không qua một native
continuation mới. Không tuyên bố fixture capture `{}` đã chứng minh phần đó.

## Tests và giới hạn

12 tests callback: WALK007 pending, coordinator_pending, cả năm disposition,
duplicate turn/new turn, new handback, bell-off, thiếu/hỏng/legacy record,
UUID/cwd/event sai, notifier exit1, Stop false→block/true→alert, duplicate false
không loop, và planted dedup defect. Launcher tests kiểm Stop-default không notify,
fallback explicit argv/TOML, role restriction; installer tests kiểm template/script,
doctor/uninstall và preserve owner/Claude.

Các run đầu có lỗi fixture assertions (và callback alert chưa có log khi clean);
không dùng làm PASS. Fixture notifier cuối là shell stub, cùng real Herdr receipts
độc lập nêu trên. Không chạy quá hạn tự động; cảnh báo/hold xảy ra tại lifecycle event.

- Record chưa ghi handback, disposition sai sự thật, malformed/legacy record: log skip
  hoặc không thể phát hiện. Không tự diễn giải prose hay suy đoán task đã hoàn tất.
- Hook chưa trust/phiên chưa restart, process chết, provider lỗi không phát lifecycle:
  chưa có coverage. Notify fallback cũng không bảo đảm bắn khi provider lỗi.
- Owner trust capture hook là bằng chứng fixture; không phải quyền trust/cài hook
  sản phẩm. Installer chỉ ship template; ADAPT mới đặt entry sau review/authorization.
- Không kiểm chứng linked-worktree hooks, `codex exec` hooks hay app-server thuần.
  Đường đã đo là **TUI trên Herdr kết nối daemon**, có actual Stop stdin.

## Official docs / issue scope

[Hooks](https://learn.chatgpt.com/docs/hooks) mô tả Stop block tạo continuation,
stop_hook_active và trust review. Các issues được đọc là báo cáo theo phiên bản,
không được coi là hành vi chắc chắn của 0.167.0:

- [#38213](https://github.com/openai/codex/issues/38213): app-server 0.147 alpha thiếu Stop;
  không phủ định capture TUI 0.167 ở đây.
- [#32491](https://github.com/openai/codex/issues/32491): exec 0.144.1 bỏ qua persisted trust;
  không dùng dangerous bypass để làm probe xanh.
- [#27133](https://github.com/openai/codex/issues/27133), [#23996](https://github.com/openai/codex/issues/23996): worktree discovery/cwd; setup giới hạn coordinator checkout.
- [#21160](https://github.com/openai/codex/issues/21160): live-edit/rate-limit hook failure;
  adaptation yêu cầu restart có checkpoint, không hot-edit phiên sản phẩm.
- [#58011](https://github.com/openai/codex/issues/58011): trust invalidation;
  ghi hash và owner review lại sau thay đổi.
- [#45977](https://github.com/openai/codex/issues/45977): provider-error/idle signal gaps;
  không claim error-turn coverage từ happy-path probe.

## Cleanup và handoff

[Cleanup receipt](evidence/stall-turn-end/cleanup.json): đúng fixture UUID được đọc
idle/cwd khớp rồi archive; tab wW:tT đóng và readback absent; fixture directory xóa.
Baseline loaded threads đều còn, không thao tác lên chúng. Owner trust storage để
nguyên; không sửa ~/.codex/config.toml. Không còn probe agent/observer chạy.

Worktree giữ để Thomas review/tích hợp; main chưa nhận patch. Không bump version,
tag, push hay cài Nizzy. Bước còn lại trước activation là owner review/trust đúng
production hash, restart coordinator có kiểm soát và native continuation smoke;
không suy ra các bước đó đã xong từ 63 tests hoặc fixture capture.
