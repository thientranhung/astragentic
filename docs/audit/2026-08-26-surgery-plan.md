# Kế hoạch phẫu thuật — Astragentic

Đối chiếu với `2026-08-26-dissection.md`. Trạng thái: **đề xuất, chưa thi công.**
Bốn tầng còn lại (QA walk · herdr/pane · release & ADAPT · brownfield) đang audit; các
phase dưới đây sẽ hấp thụ kết quả chứ không đổi cấu trúc.

---

## Năm nguyên tắc ràng buộc mọi phase

Rút ra từ chính bằng chứng trong bảng giải phẫu, không phải từ sở thích.

1. **Không thêm chữ để chữa một rule bị bỏ qua.** Ledger đã ghi bản án cho cách đó
   (`recurring-failure-modes.md:856`): *"The signal was present and was read past… More
   qualifying prose in the same place that was skimmed is not a fix."* Trong 22 mục P0,
   chỉ **1** cần viết mới thật sự (D1 — dispatch record).
2. **Rule kiểm được bằng máy phải rời prompt.** Hook tốn 0 token và miễn nhiễm compaction.
   Đây là cách duy nhất vừa giảm token vừa tăng tuân thủ.
3. **Rule không kiểm được bằng máy phải nằm ở khoảnh khắc nó được đọc**, không phải ở
   chương hợp logic. `CLEANUP.md` không có chữ "broker" là mẫu hình của cả lớp lỗi này.
4. **Một nhà cho một rule** — luật của chính `SPEC:117`. Mọi phase phải giảm số nhà, không tăng.
5. **Không thêm role.** Matt, Murat, Winston kết luận độc lập cùng một điều. Bề mặt
   always-on của Thomas đang vượt ngân sách; mọi role mới đều bắt buộc phải sửa vào đó.

---

## Phase 0 — Đóng băng và đo (0 thay đổi)

Không đụng file nào. Ghi baseline để mọi phase sau có before/after:

```bash
python3 harness/scripts/check-reachability.sh .     > docs/audit/baseline-reachability.txt
bash    harness/scripts/docs-staleness-audit.sh .   > docs/audit/baseline-staleness.txt
git worktree list; git branch -vv; ls .git/hooks/   > docs/audit/baseline-git.txt
```

**Vì sao đứng riêng:** `docs-staleness-audit.sh` đang **đỏ** và không ai biết vì không
contract nào chạy nó. Nếu không chốt baseline trước, ta sẽ không phân biệt được lỗi do ta
gây ra với lỗi đã có sẵn.

---

## Phase 1 — Gắn răng (HOOK) · không thêm một từ prompt nào

Đánh vào B1–B6, C1–C5, và một phần H4. Đây là phase có tỷ lệ giá trị/chi phí cao nhất.

Schema đã xác minh với tài liệu chính thức: `matcher` là **chuỗi khớp TÊN TOOL**; payload vào
qua **stdin JSON** (`tool_name`, `tool_input.command`, `cwd`); `PreToolUse` chặn bằng
`permissionDecision: "deny"`; `Stop` chặn việc kết thúc lượt; `PostToolUse` không chặn nhưng
`additionalContext` bơm được text Claude thấy.

| Bước | Hook | Làm gì | Đóng mục |
|---|---|---|---|
| 1.1 | `PostToolUse` / `Bash` | lọc `git worktree remove` → kill broker theo `--cwd` + `docker stop` theo compose label. **Thay hẳn hook `WorktreeRemove` đang nằm im** | B6, C4 |
| 1.2 | `PreToolUse` / `Bash` | `git worktree remove <p>`: tự kiểm `git -C <p> status --short` và `pgrep -f <p>`; **dọn tài nguyên TRƯỚC** rồi mới cho gỡ | C3, C4 |
| 1.3 | `PreToolUse` / `Bash` | `git worktree add`: từ chối đường dẫn tương đối và mọi `>/dev/null`; **tự chạy `git worktree prune`** trước khi cho qua | C1, C2 |
| 1.4 | `PreToolUse` / `Bash` | `rm -rf` trỏ vào `.claude/worktrees/` → deny, nêu AST-096 | C2 |
| 1.5 | `PreToolUse` / `Bash` | `git add -A` / `git add .` → deny, nêu path cần stage | nhóm tracked-content |
| 1.6 | `PreToolUse` / `Bash` | `git merge`: chạy `check-simplify-markers.sh <base> <head>`; non-zero → deny, lấy dòng `STOP:` làm reason. Deny thêm khi `rev-list --count base..head` = 0 | B2, B3 |
| 1.7 | `PostToolUse` / `Bash` | sau `git merge`: `additionalContext` bơm checklist — markers · `Ledger:` · frontier write-back · reconcile · **đếm pane, top-up về `builder-target`** | B2, B3, B4 |
| 1.8 | `Stop` | chạy `ticket-git-facts.sh`; **chặn kết thúc lượt** khi còn branch đã merge chưa xoá, hoặc assignee không có branch | B4, C5, H4 |
| 1.9 | `PreToolUse` / `Bash` | dispatch: watchdog chưa chạy → **deny thật**, thay cho `echo` | B1 |

**Vì sao 1.7 quan trọng hơn vẻ ngoài:** checklist merge **không nằm trong prompt ngày thường**
nên tốn 0 token, xuất hiện đúng giây phút cần, và **compaction không xoá được** vì nó được bơm
lại ở mỗi lần merge. Đây là lời giải cho câu hỏi "Thomas full context thì quên dần" — chuyển
rule từ *ký ức* sang *sự kiện*.

**Ranh giới xuống cấp (ràng buộc của anh):** mọi hook ở đây sống trong session **Thomas** và
**Rin** — hai vai luôn Claude. **Builder chạy Codex/OpenCode khi hết quota**, nên không rule
sống còn nào của Builder được đặt ở đây; 1.6 và 1.8 chặn ở **phía Thomas lúc merge**, nên
Builder chạy vendor nào cũng bị chặn như nhau.

**Rủi ro và cách rút lui:** phase này sửa `settings.json` — một hook viết sai có thể chặn
nhầm công việc hợp lệ. Cách làm: mỗi bước bật **một** hook, chạy thử trên một worktree rác,
đọc `/tmp/harness-hook-events.log`, rồi mới bật bước kế. Rút lui = xoá khối hook đó.
**Không bật cả 9 bước cùng lúc.**

**Không đụng:** `WorktreeCreate`/`WorktreeRemove` chỉ bắn cho worktree do Claude Code quản lý.
Chỉ nối `WorktreeCreate` cho một việc: assert payload đã tracked trên worktree của
fork/subagent (AST-036 × AST-130). **Không** được lấy đó làm cớ tuyên bố đường dọn tay là thừa —
AST-102 chính là entry về đúng câu nói đó.

---

## Phase 2 — Di dời (MOVE) · tổng số từ ≈ không đổi

Không viết mới. Cắt chữ đã có, dán về đúng chỗ.

| Bước | Từ | Về | Đóng mục |
|---|---|---|---|
| 2.1 | `thomas.md:230` (§Watchdog) rule dọn broker | `CLEANUP.md`, cạnh lệnh gỡ | C4 |
| 2.2 | `CLEANUP.md:113-115` thứ tự `remove → branch -d → prune` | sửa: dọn tài nguyên → remove → `branch -d` → `prune`; và ghi rõ `prune` phục vụ lần `add` **kế tiếp** | C3 |
| 2.3 | `dispatch-ticket/SKILL.md:159-161` | thêm `git worktree prune` trước `add`, cấm nuốt output, assert HEAD — chép từ `codex-arm` nơi bản vá AST-096 đã sống | C1 |
| 2.4 | `thomas.md:87` *"remove any worktree **directory**"* | đổi động từ sang `git worktree remove` | C2 |
| 2.5 | — | thêm 1 hàng Load `builder.md:17`: `\| ticket sửa SKILL.md/AGENTS.md/CLAUDE.md \| writing-for-agents \|` | D3 |
| 2.6 | — | thêm 1 hàng Load `shaper.md:17`: `improve-codebase-architecture` cho refactor **có** module boundary | F7 |
| 2.7 | — | thêm 1 hàng Load `shaper.md`: `legacy-testing` để handback seam lớn có nơi đáp | F5 |
| 2.8 | `CLEANUP.md:118` | ghi lối đi hợp lệ khi `git branch -d` từ chối sau squash merge | C6 |

### 2.9 — Ca mổ lớn của phase này: chuyển lõi contract lên tầng bền

Đây là câu trả lời cho **A1 + A2**, và là thay đổi có ảnh hưởng sâu nhất trong cả kế hoạch.

**Hiện trạng:** `.claude/agents/thomas.md` là stub ~120 từ, thân nói *"Read
`.agents/roles/thomas.md` now"*. 2.095 từ nguyên tắc vận hành vào context qua kết quả `Read`
→ **lịch sử hội thoại** → compaction nuốt trước tiên.

**Đề xuất:** chuyển phần **bất biến, luôn cần** lên **thân `.claude/agents/<role>.md>`** —
tầng system prompt của riêng agent đó, sống qua compaction, **và không thể rò sang role khác**
vì mỗi agent chỉ nạp file của chính nó.

Với Thomas, phần bất biến là: claim protocol · thứ tự merge · quy tắc top-up · bảng cảnh báo
watchdog. Phần tình huống (adapter tracker, supplement runtime, bảng phase) **ở lại**
load-on-demand.

**Vì sao điều này không tái phạm AST-024:** role-bleed đến từ `.claude/rules/role-thomas.md` —
tầng **always-on toàn cục**, nạp vào *mọi* session. Thân agent definition là tầng **riêng từng
agent**. Cách chữa cũ đúng với nguyên nhân cũ; nó chỉ đi quá xa một tầng.

**Ràng buộc bắt buộc:** phase này phải làm **cùng lúc** với 5.3 (hạ số từ), vì `thomas.md`
đang vượt ngân sách 125 từ và `builder.md` vượt 332. Chuyển chữ mà không cắt chữ = vượt trần
ở cả hai nhà.

**Xuống cấp:** tầng này là Claude-only. Thomas và Rin luôn Claude → an toàn. Builder có thể
chạy Codex → phần bất biến của Builder **phải** vẫn nằm trong `.agents/roles/builder.md` để
Codex đọc được; chỉ **nhân bản con trỏ**, không chuyển nhà.

---

## Phase 3 — Định nghĩa thứ không tồn tại (DEFINE)

| Bước | Việc | Đóng mục |
|---|---|---|
| 3.1 | **Định nghĩa "the dispatch record"**: path, schema 7 trường (ticket→branch→worktree→workspace→tab→pane→write-set), ai ghi, ai đọc, vòng đời. Cho nó heading `## N. Write \`path\`` để check 8 phủ được | D1, H4 |
| 3.2 | `<gate-history-dir>` → path thật | D2 |
| 3.3 | Tuyên bố chính sách gương `.agents/` ↔ `.claude/`: giống hệt, hay được phép khác? Nếu được phép, khai báo **ở đâu** và **vì sao** — hiện `codex-arm` đã khác mà không dòng nào cho phép | A8 |

**3.1 là mục duy nhất trong 22 P0 thật sự phải viết mới.** Và nó là mục chặn: H4 (chuỗi
stale-claim), C-nhóm write-set, và cleanup đều treo lên nó. **Làm trước 3.2 và 3.3.**

---

## Phase 4 — Nói thật về tracker (FIX)

| Bước | Việc | Đóng mục |
|---|---|---|
| 4.1 | Sửa `github:41` — bỏ *"Requirement 3 is met natively"*, thay bằng sự thật đo được (`--add-assignee @me` là một login cho mọi dispatcher) | H1 |
| 4.2 | Chép `linear:80-89` nguyên văn sang GitHub và Jira: git quyết định race · thua thì để assignee y nguyên · release bằng xác nhận worktree+branch đã mất | H1, H2 |
| 4.3 | Hạ `thomas.md:75` từ *"two independent atomic interlocks"* xuống *"một interlock nguyên tử cộng một readback tham khảo"* | H3 |
| 4.4 | Thêm `git branch --merged` vào lớp stale-claim của `reconcile-tracker` | H4, C5 |
| 4.5 | Sửa 4 dòng check 4: thêm `docs\|tools` vào allowlist `:328`; thêm `.agents/*.md` vào `sources` `:321`; in dòng scope nêu rõ phần loại trừ | H5, H6, H7 |
| 4.6 | Sửa `tracker-contract.md:152` → path thật của `project-status-sync.sh` | H6 |
| 4.7 | Sửa `to-spec` race: publish ở `needs-triage`, thăng `ready-for-agent` **sau khi** `arm: spec` trả về | F1, H11 |

**4.5 phải làm trước 4.6**, để bộ kiểm bắt được lỗi thay vì ta sửa tay rồi vẫn mù.

---

## Phase 5 — Cắt (CUT)

| Bước | Việc | Tiết kiệm | Đóng mục |
|---|---|---|---|
| 5.1 | `tracker-contract.md` §Per tracker (`:94-177`) → bảng 3 dòng trỏ adapter | −799 từ, −10 sự kiện trùng, bỏ 1 tuyên bố đã rút lại + 1 path sai | H8 |
| 5.2 | Ledger: tách `ledger-rules.md` (id + rule ~40 từ + status) khỏi `ledger-evidence.md` | `grep -A40` trả về ~100% tín hiệu thay vì ~25% | A7 |
| 5.3 | Hạ `thomas.md` và `builder.md` về dưới ngân sách | 125 + 332 từ | A3 |
| 5.4 | Chạy `ledger-index.sh` | INDEX hết stale | A4 |
| 5.5 | Gộp `codex-arm` + `codex-claude-arm` thành một skill có nhánh theo root runtime | ~1.100 token, xoá drift đang sống | A8 |
| 5.6 | Gỡ trùng: luật two-pass arm (`builder.md` **hoặc** `rin.md`, không cả hai) | | E1 |

**5.2 cần anh quyết trước:** ledger tuyên bố chính sách **append-only** thành văn
(`recurring-failure-modes.md:17`). Tách file là sửa chính sách đó. **Em không tự làm.**

**5.3 lưu ý:** đây là chỗ dễ làm hỏng nhất trong cả kế hoạch. Văn xuôi trong `thomas.md`
dày đặc bằng chứng đo được; cắt sai là mất lý do một rule tồn tại. Cách an toàn: cắt **câu
chuyện**, giữ **rule + mã AST** — vì ledger đã giữ câu chuyện rồi. Đúng nguyên tắc 4.

---

## Thứ tự thi công đề xuất

```
Phase 0  (đo)          →  Phase 1.1–1.5  (răng cho nhóm git — cơn đau thường trực)
                       →  Phase 2.1–2.4  (di dời rule git về đúng khoảnh khắc)
                       →  Phase 3.1      (định nghĩa dispatch record — mục chặn)
                       →  Phase 1.6–1.9  (răng cho merge/report/dispatch)
                       →  Phase 4        (sự thật tracker)
                       →  Phase 2.9 + 5.3 (chuyển tầng context + hạ ngân sách, cùng lúc)
                       →  Phase 5 còn lại
```

Lý do thứ tự: nhóm git là cơn đau anh nói là thường trực **và** là nhóm tái phát số 1 trong
ledger (7 entry, phòng thủ tệ nhất). Phase 3.1 chèn giữa vì nó chặn phần còn lại. Phase 2.9
để sau cùng trong nhóm nặng vì nó cần 5.3 đi kèm.

---

## Em sẽ KHÔNG làm, trừ khi anh bảo

- **Không thêm role thứ sáu.** Ba chuyên gia kết luận độc lập cùng một điều.
- **Không gỡ đường Codex/OpenCode.** Hết quota là chuyện thường ngày — bảo hiểm đang có hiệu lực.
- **Không mở lại vòng lặp review của Rin.** Một-vòng-một-milestone bị cắt có chủ ý sau khi đo 5–14 vòng.
- **Không đụng `check-simplify-markers.sh`** ngoài việc thêm `--marker` kind. Nó là bộ phận khoẻ nhất trong máy.
- **Không sửa `thomas.md:47`** (thêm *"and whose state is the claimable state"*). Năm chữ đó đóng H11 trên cả ba tracker nhưng đổi ngữ nghĩa frontier và va vào `:52`. **Quyết định của owner.**
- **Không tách ledger** (5.2) khi chưa có anh gật — nó sửa chính sách append-only thành văn.
- **Không đưa cơ chế debate ngang hàng vào harness.** Đề xuất cụ thể có sẵn (`thomas.md:120-124`, đổi *"Rin advises and you classify"* thành quyền phản biện một lượt có chặn cứng), nhưng đó là câu hỏi triết lý sản phẩm, không phải lỗi kỹ thuật.

---

## Cách nghiệm thu từng phase

| Phase | Xanh nghĩa là |
|---|---|
| 1 | `/tmp/harness-hook-events.log` ghi nhận hook bắn cho một lần gỡ worktree thật; một `git merge` thiếu marker **bị từ chối**; một lượt Thomas còn branch bẩn **không dừng được** |
| 2 | `grep broker CLEANUP.md` > 0; `dispatch-ticket` có `prune` trước `add`; ba hàng Load mới tồn tại |
| 3 | `check-reachability.sh` check 8 nhìn thấy dispatch record; `grep '<gate-history-dir>'` = 0 |
| 4 | check 4 **đỏ** trên `tools/project-status-sync.sh` trước khi sửa, **xanh** sau khi sửa — nếu nó xanh cả hai lần thì 4.5 chưa có tác dụng |
| 5 | `docs-staleness-audit.sh` xanh mục 1 và mục 5 |

**Tiêu chí nghiệm thu của Phase 4 là quan trọng nhất:** nó bắt bộ kiểm phải **chứng minh nó bắt
được lỗi** trước khi ta tin màu xanh của nó. Đó chính là bài học AST-052/AST-060 mà gói này đã
trả giá nhiều lần — một bộ kiểm xanh trên thứ nó chưa từng mở.
