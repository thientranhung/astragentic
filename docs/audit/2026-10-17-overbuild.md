# Vòng check "có quá hàn lâm không" — Astragentic 4.0.1, 2026-10-17

**Đây là file anh đọc.** Số đo do ba lượt quét chỉ-đọc trên repo ở tag v4.0.1 và trên
etsy-fulfillment-thanh (nizzy) cùng log `/tmp/harness-hook-events.log` (2026-10-15 → 10-17).
Chưa sửa gì trong harness. Mục *Đề xuất* là để anh chọn; làm xong gom một release.

## 1. Kích thước và tốc độ

| | v2.0.0 | v2.12.0 | v3.0.0 | v3.3.1 | v4.0.1 |
|---|---|---|---|---|---|
| Tổng từ | 57k | 193k | 236k | 244k | 233k |
| Số file | 57 | 99 | 114 | 115 | 97 |

68 ngày, gấp 4,1 lần; **187 tag** trong 68 ngày (có ngày 31 tag). 4.0.0 là bản đầu tiên giảm.

Khối lượng nằm ở đâu (233k từ):

| Lớp | Từ | Ghi chú |
|---|---|---|
| Ledger `recurring-failure-modes.md` | 46k | 157 entry; **33 không file nào trích**, 41 chỉ release note trích |
| Skill | 34k ×2 = 68k | hai bản y hệt (`.agents/skills` và `.claude/skills`); `dispatch-ticket` 12k |
| Script kiểm tra + selftest | 31k | selftest 1.285 dòng, reachability 1.074, marker gate 928, doctor 696, staleness 538 |
| Mod `register.tsx` | 12k | 16 hook, 5 gate deny, 6 kiểu từ chối gửi, 3 bell |
| Hợp đồng role | 8.8k | mỗi role 1.1k–2k, **vừa** |
| Tỉ lệ dòng comment | 23–40% | watchdog 40%, reachability 39%, install 32% |

Chi phí cố định mỗi session: ~3.9k từ (Builder hay Thomas). Thomas lên ~24k khi dispatch
(`dispatch-ticket` 12k + `dispatch-ticket-claude` 4k + tracker skill).

## 2. Guard nào từng bắt lỗi thật

99 guard đếm được (mod, git guard, doctor, reachability, staleness, selftest, watchdog, marker gate, ticket-done):

| Trạng thái | Số |
|---|---|
| Bắt lỗi thật (21 ở project, 5 lúc build release) | 26 |
| Chưa từng có bằng chứng bắn (33 cái chỉ có release note sinh ra nó) | 42 |
| Chỉ bắn trong selftest | 17 |
| Bắn nhầm, không phải lỗi | 14 |

Đã làm việc thật: tdd-gate (9 lần), arm-gate, TURN-END + hold, git guard `add -A` (7) /
stamp trước remove (3) / `Ledger:` trước push (2), ticket-done (121 stamp), marker
`Supersedes`/`Reviewed` (5 giá trị bịa trong 560 merge), doctor payload (3 lần), reachability
3/9/10, staleness 1/2/5, watchdog NEVER_STARTED và BLOCKED.

Bị vượt qua ngay chỗ quan trọng:
- `git add -A && git commit -m "$(cat <<EOF` **lọt 6 lần**: guard không đọc heredoc, ghi "no-opinion" (557 dòng no-opinion loại này trong 2 ngày).
- Push main qua ticket chưa stamp **lọt 1 lần** (PROJ-273, 5e881cfa9).
- Marker `Pass: Skill(simplify)` **giả lọt gate** (TRA-1124); Thomas bắt bằng tay qua record `skills_run` của mod.
- tdd-gate: cả 9 lần từ chối, cùng nội dung commit lại sau 17–26 giây. Gate kiểm tra "đã gọi
  skill" **theo thiết kế** (`builder-claude.md:8`); gọi skill có đồng nghĩa với có test đỏ hay
  không thì **chưa đo**, 17–26 giây là dấu hiệu nó có thể không. Hai trong chín là ticket xoá
  code, lẽ ra brief phải có `TDD: n/a` — lỗi ở dispatcher, không ở gate.

Ồn, tách theo "đã vá chưa":
- Còn ồn: marker gate chặn 6 Builder vì so cây và 3 Builder vì parser; staleness axis 4 từng ra
  4.443 finding giả; WATCHER_LOST 2 lần/5 phút sai (pgrep false positive, RN 2.20.0 ghi nhận).
- Đã vá, sau vá chưa có số: watchdog STUCK 26 lần một đêm là trước 3.2.0 (từ 3.2.0 pane có mod
  không còn STUCK, giờ chỉ bắn được trên pane QA gate; 1 lần đúng AST-152); held-stale rung 2
  lần là trên 3.3.0, 3.3.1 ra để sửa đúng chỗ đó, sau 3.3.1 chưa thấy bắn lần nào.

Hook bắn nhiều nhất trong log **không nằm trong 99 guard trên**: `hook-agent-isolation-guard`
**40 lần DENY** trong 2 ngày, phần lớn là subagent review spawn thiếu `isolation: "worktree"`.
Gate chạy đúng, nhưng Builder quên hoài — rule đang đánh nhau với mặc định của skill, đó là mùi
thiết kế. Chi phí mỗi turn chưa tính ở §1: `hook-contract-reload` 98 bắn / 82 không làm gì,
`hook-tracker-status` 203 lần chèn.

## 3. Nói một rule ở bao nhiêu chỗ

| Rule | Số đoạn nói | Từ | Nơi thực thi |
|---|---|---|---|
| Watchdog bắt buộc | 35 | 2.058 | **không có** |
| Claim trước worktree | 22 | 1.896 | một phần (mod giữ brief) |
| Dọn worktree | 22 | 1.596 | 5 file code |
| Write-set | 14 | 1.059 | **không có** |
| TURN-END / hold | 10 | 947 | mod |
| Marker ở head | 9 | 708 | marker gate |
| Arm hai lượt | 10 | 572 | **không có** |
| Một writer một worktree | 10 | 476 | **không có** |

Bộ kiểm tra tự kiểm tra: 322/1.285 dòng selftest chứng minh "check có thể fail"; staleness 5
axis (492 dòng) canh tài liệu; reachability 10 (128 dòng) canh dòng `Bound:` của ledger;
install.sh 78 dòng canh hai bản skill bằng nhau. Phần lớn sinh ra từ một sự cố đóng gói, không
từ sự cố của project.

Tỉ lệ "kể chuyện" trong file agent đọc: `builder-claude.md` 34%, `codex-arm` 23%,
`dispatch-ticket/*` 18–23%.

## 4. Kết luận

Hợp đồng role không hàn lâm. Phần quá tay nằm ở ba chỗ, theo thứ tự:

1. **Prose lặp**: cùng một rule nói 10–35 chỗ, trong đó bốn rule nặng nhất không có gì thực thi.
   Đây là chỗ Thomas trả 24k từ mỗi lần dispatch.
2. **Guard xây cho sự cố một lần**: 42 guard chưa bắn, 14 guard ồn. Mỗi cái kéo theo case
   selftest, đoạn release note, entry ledger.
3. **Ledger 46k từ** trong payload, gần một nửa không ai trích.

Và ngược lại, ba gate có giá trị nhất đang hổng: `add -A` qua heredoc, `Pass:` giả, tdd-gate
đo sai thứ.

## 5. Đề xuất — anh chọn, gom một release

| # | Việc | Bằng chứng | Ước lượng |
|---|---|---|---|
| A | **Mỗi rule một nhà.** Rule đã có mod/script thực thi: xoá prose lặp, giữ một câu trong role contract trỏ tới nơi thực thi. Rule không thực thi (watchdog, write-set, arm hai lượt, sole writer): một câu trong contract, hết. `dispatch-ticket` 12k → ~4k | §3 | −15k từ, Thomas dispatch −50% |
| B | **Bỏ guard còn ồn hoặc chưa bắn**: WATCHER_LOST + THOMAS_CRASHED (giữ NEVER_STARTED, BLOCKED, RECORD_UNREADABLE; STUCK giờ chỉ còn trên pane QA gate — giữ hay bỏ là lựa chọn, không phải finding); staleness axis 3, 4; reachability 1, 2, 4, 6, 7, 8 (giữ 3, 5, 9, 10); marker gate chỉ giữ Supersedes + endpoint + tồn tại, bỏ so cây và parser `Pass:`; doctor bỏ 5 check không bằng chứng; xem lại `hook-agent-isolation-guard` (40 DENY: siết rule hay đổi mặc định skill). held-stale **không** bỏ: đã vá ở 3.3.1, chờ số. Case selftest tương ứng đi theo | §2 | −~2k dòng script, −~300 dòng selftest |
| C | **Sửa ba gate đang hổng**: git guard đọc heredoc (hoặc deny "no-opinion" cho lệnh có `git add -A`); tdd-gate đọc record run đỏ của tdd thay vì "đã gọi skill"; thay `Pass:` bằng record `skills_run` của mod (đã là thứ Thomas dùng để bắt lần trước) | §2 bypass | 3 việc nhỏ, giá trị cao nhất |
| D | **Ledger ra khỏi payload**: giữ `RULES.md` (8.7k, mỗi session đọc) và 83 entry có file vận hành trích; 74 entry còn lại chuyển sang `docs/ledger-archive/` ngoài payload. **Kéo theo**: `RULES.md` và `INDEX.md` sinh từ cùng file (ledger-rules.py, ledger-index.sh) nên phải sinh lại; dòng Load của `builder.md` grep `'^### AST-0NN'` trong payload — id đã archive sẽ không thấy; check 10 đọc một file | §1 | −~25k từ payload |
| E | **Một bản skill**: `.claude/skills` là symlink tới `.agents/skills` (cần đo Claude Code và Grok có theo symlink không); bỏ 78 dòng sync trong install.sh | §1 | −34k từ git, −78 dòng |
| F | **Nhịp release**: gom theo tuần, không theo lần sửa; mỗi bản phải có một số đo từ project trước khi bản sau ra | §1 | 187 tag/68 ngày → ~10 |

Thứ tự em đề xuất: **chưa đụng gì cho tới khi nizzy báo receipt v4.0.1 và ticket thử junior có
số** (C đổi ba gate; đo lane junior trên một harness đang đổi là đo hai thứ cùng lúc). Sau đó
**C** (vá chỗ hổng, nhỏ), rồi **A + D** (giảm thứ agent phải đọc), rồi **B** (bớt máy), **E** và
**F** sau khi đo.
