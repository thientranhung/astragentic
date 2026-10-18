# Phụ lục — số đo thực địa từ nizzy-ecom (Thomas, 2026-10-17)

Nguồn: Thomas của nizzy-ecom quét 404 transcript (373 Builder, 31 Thomas) chỉ-đọc, cộng log
watchdog và hook. M = đo (có nguồn), E = ước. Nguyên văn giữ tiếng Anh ở bảng.

**Cảnh báo phạm vi:** `/tmp/harness-hook-events.log` bắt đầu 2026-10-15 dù máy boot 10-05 — file
bị tạo lại giữa chừng (nghi `logRefusal` trong register.tsx ghi đè cả file). Watchdog log có
giờ không có ngày. `refusals` trong dispatch-record luôn rỗng vì entry bị xoá khi pane retire.

## 1. Thomas đọc gì (M)

| Khi | File | Từ |
|---|---|---|
| mỗi turn | AGENTS.md 7342 · CLAUDE.md 760 · .claude/rules ~5130 · overlays/thomas.md 2763 · agents/thomas.md 255 | ~16.2k |
| session start | thomas.md 2046 · orchestrator.md 980 · THOMAS-RESUME.md 3087 | ~6.1k |
| mỗi dispatch | dispatch-ticket 6127 · dispatch-ticket-claude 3932 | ~10.1k |
| mỗi merge | thomas-claude 414 · CLEANUP 1698 · merge-station 3274 (hôm nay không mở, hook dẫn) | 0–5.4k |
| slice gate | codex-arm 2457 | 2.5k |

Tổng trong tầm một session Thomas: ~43k từ. **Phần harness đã 20 ticket không cần**: toàn bộ
watcher protocol (mod thay cho pane Claude), headless STOP, workspace create/rename, paste +
Enter và AST-154, cảnh báo `herdr integration install`, hàng `<set-me>`/Fallback, "Long
tickets" /compact, Merge mechanics (trùng station-gate).

## 2. Refusal/alert 2026-09-17 → 10-17 (M, transcript)

| Loại | n | Đổi hành vi | Lách / ồn |
|---|---|---|---|
| tdd-gate | 30 | ~3 | **24/30 commit lại y nguyên, 0 sửa**, 20 trong 3 tool call |
| arm-gate | 3 | 3/3 | — |
| wait-gate | 2 | 2/2 | — |
| picker-gate | 6 | — | 3 là TRA-1050 cố tình thử |
| brief refusals | 4 | 3 | 1 sai: brief test-design đọc thành ticket chưa claim |
| guard `git add -A`/`.` | 163 | 102 | **~100/163 đã giới hạn path** (`git add -A -- apps/x`) |
| agent-isolation guard (plug project) | 253 | — | **225 retry thẳng**; fan-out review dính gần như mọi ticket |
| push thiếu stamp ticket-done | 24 (đều Thomas) | 10 chạy ticket-done | thật: thứ duy nhất chặn quên write-back |
| worktree remove thiếu stamp | 17 | 16/17 | — |
| hook EPERM ([Errno 1]) | 27 | — | chặn MỌI Bash call 4 ngày; fail CLOSED trong khi AGENTS.md:425 nói fail open |
| commit-msg marker REFUSED (plug project) | 288 | 76 | thiếu `Pass: Skill(simplify)` 103 · thiếu `Output:` 51 · `Reviewed:` sai 25 |
| check-simplify-markers STOP | 214 | — | **194/214 một lý do: marker không ở head**; 106 lần commit marker rỗng |
| watchdog (10-05→11, E) | STUCK 65 (26 cho một pane) · RECORD_UNREADABLE 6 · THOMAS_CRASHED 4 · WATCHER_LOST 2 · BLOCKED 1; 72 restart | — | 26× một pane là ồn |

## 3. Chi phí 10 ticket merge gần nhất (phút M, $ E theo giá Sonnet 5)

≈ $368 / 10 ticket, median 66 phút. **Cache read chiếm 70–87% chi phí mỗi ticket**: Builder đọc
lại context đứng (AGENTS.md, rules, overlays) ở mọi request. TRA-1131 pane đọc $40.57 ở phút 96.

## 4. Rule Thomas tự canh bằng tay (E)

Write-back frontier sau merge (mỗi merge) · đếm >10 merge cho arm(slice) (mỗi merge) ·
write-set giữa hai lane (mỗi dispatch 2 lane) · dòng `Visual evidence:` (mỗi brief) · grep ledger
khi dispatch (bỏ khi bận) · lý do QA owed/waived trên commit merge · phân loại finding bị từ chối ·
bảng tracker trong mỗi report · upkeep resume · bàn giao junior (3 lần hôm nay).

## 5. Đã đi vòng / tắt trong project (M)

`check-payload-drift.sh` của payload không phải cái chạy (tools/) · `core.hooksPath=tools/git-hooks`
· 8 path owner-kept · `settings.json onFailure block` trái với doc "fails open" ·
`marker-tail-order.md` override builder.md vì station từ chối cái builder.md cho phép ·
`hook-tracker-status.py` thay bằng plug · CI tắt · doc còn 3 chỗ cấm `--cdp` đã rút lại.
Restatement: claim-before-worktree 14 file · marker tail order 9 · cdp 6 (3 stale).

## 6. Giữ / bỏ, theo Thomas nizzy

**Giữ bằng mọi giá:** claim → `worktree add -b` + release-stamp trước remove · station-gate chạy
planner của base · mod SendMessage + RECEIVED + TURN-END · ticket-done stamp + push guard ·
arm(ticket) + slice gate.

**Bỏ trước:** tdd-gate dạng refusal (đo Skill call, không đo test) · guard `git add -A` khi có
pathspec · agent-isolation guard trên fan-out read-only · STOP "marker không ở head" khi cây
không đổi · commit-msg refusal về format trùng với record của mod. Cộng: gom claim-before-worktree
về một nhà (14 bản), và sửa hook EPERM fail-closed.

## 7. Thử nghiệm tắt arm ở scope ticket (nizzy, 2026-10-17 → 18, Thomas session mới)

Owner bật `ticket | no` (cbdf0cd3e). 10 ticket merge với arm ticket tắt. Station bắt **0 lỗi
code**; mọi gate đỏ đều do quy trình. Slice gate (ép bởi bộ đếm ở 13 merge) đọc 9 ticket: **7
finding** — 5 liên ticket (chỉ slice thấy), **2 nhìn thấy trong một ticket** (test rỗng chỉ
assert timestamp; đếm connection gồm cả inactive) là loại arm ticket thường bắt. Tức là tắt arm
ticket đẩy ~2 lỗi/10 ticket xuống slice gate, không mất.

Phát hiện kèm theo (không liên quan arm):

| # | Việc | Loại |
|---|---|---|
| F0 | Rule file của project (`.claude/rules/marker-tail-order.md`, AGENTS.md) vẫn nói arm ticket bắt buộc sau khi 4.0.2 biến nó thành công tắc; apply không báo | restatement ở project; đề nghị `--adapted` grep rule project khi một rule thành switch |
| F1 | Builder chạy `make db-down` tắt Postgres test dùng chung toàn máy (AST-115) vì brief dặn `make dev-down`; không có gì chặn | cần plug "lệnh pane dispatched không được chạy" do project khai, mod từ chối |
| F4 | Push guard đòi `Ledger:` trên **mọi** merge trong range, kể cả merge sync origin/main của Builder → 2 lần từ chối, 10 phút/ticket sửa history | lỗi guard: chỉ đòi trên merge first-parent vào base |
| OBS2 | Một TURN-END trễ trả lời lại brief cũ sau khi pane đã bị reap | chưa tái hiện; đường re-raise của mod |
| OBS5 | Builder nhắn cho fork simplify của chính nó, mod readdress sang Thomas | readdress phải loại trừ agent con của pane |
| OBS6/7 | TURN-END tới Thomas trong khi band pane báo "4 agent còn chạy": fork review thoát, 4 cháu chưa được đếm, turn /loop kết thúc với count 0 → chuông rò; review sub-agent im >20 phút ở cả hai Builder | đếm cả agent cháu; Builder có trần tự xử lý angle im lặng |
