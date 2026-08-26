# Bảng quyết định — Astragentic, 2026-08-26

**Đây là file anh đọc.** Hai file kia là phụ lục:
`2026-08-26-dissection.md` (bằng chứng, 12 nhóm ~95 mục) ·
`2026-08-26-surgery-plan.md` (cách thi công từng phase).

Audit đã phủ **8 tầng**: điều phối · token/context · rule & enforcement · git/worktree ·
issue tracker · QA walk · herdr/pane · brownfield · release/install.
Chưa sửa một dòng nào trong `harness/`.

---

## Phần 1 — Bốn linh cảm ban đầu của anh, đối chiếu bằng chứng

| Linh cảm | Phán quyết |
|---|---|
| Dư thừa token | **Sai.** Cold-start không phình: Thomas ~8.9k · Builder ~4.8k · Shaper ~2.5k · sàn chung ~1.16k. Ledger 51k **không** nạp sẵn |
| Đốt token | **Đúng, nhưng ở chỗ khác.** Mỗi `grep -A40` mang về ~20–25% là rule; entry lạm phát ~15× (21 từ → 519 từ) |
| Quên vận hành ở Thomas | **Đúng, và không phải lỗi model.** Rule đúng nhưng nằm sai khoảnh khắc, và nạp ở tầng bị compaction nuốt trước tiên |
| Không bám rule/convention | **Đúng, và là lỗi dụng cụ.** 26% ledger là chuyện **máy kiểm tra** hỏng, không phải agent hỏng |

**Điều em đã nói sai với anh và đã rút lại:** *"phanh chống phình đang ĐỎ"*. Không.
2.6.1 ship xanh; đỏ là do sửa đổi chưa commit trong working tree của anh. Nghĩa là kỷ luật
word-budget **vẫn đang hoạt động**, và lập luận của commit `54c85c2` chưa từng bị bác bỏ.
Hai đính chính khác: ledger uncited là **54%** không phải 65%; `SPEC:31` **không** sai.

---

## Phần 2 — Tám quyết định chỉ anh mới ra được

Mỗi mục: điều đang xảy ra · hai lựa chọn · khuyến nghị của em.

### Q1. Có bật hook chặn không? *(quyết định lớn nhất)*

Năm rule sống còn hiện chỉ là văn xuôi nhờ vả. Claude Code có sẵn cơ chế chặn:
`PreToolUse` từ chối bằng `permissionDecision: "deny"`, `Stop` chặn kết thúc lượt.
Hôm nay harness ship **0 hook chặn** — chỉ một `WorktreeRemove` nằm im và một `SubagentStop` ghi log.

- **A. Bật** — nhóm lỗi git tái phát số 1 được đóng bằng cơ chế; rule rời prompt nên tốn 0 token và miễn nhiễm compaction.
- **B. Không bật** — giữ mọi thứ ở văn xuôi, không rủi ro chặn nhầm việc hợp lệ.

**Em đề xuất A**, bật **từng hook một**, mỗi lần thử trên một worktree rác trước.
Rủi ro thật: một hook viết sai chặn nhầm việc đúng. Rút lui = xoá khối hook đó.

### Q2. `thomas.md:47` — thêm 5 chữ vào định nghĩa frontier?

Frontier hiện là *"every ticket whose blockers are all done and whose assignee is empty"* —
**không lọc state, không lọc review**. Hệ quả: `to-spec` gắn nhãn `ready-for-agent` lúc publish,
**trước** khi `arm: spec` chạy → trên Linear ticket chưa review **nổi lên frontier thật**;
trên GitHub chỉ bị chặn **tình cờ** vì lệch từ vựng nhãn; trên Jira **không có frontier query nào**.

- **A. Thêm** *"and whose state is the claimable state"* — đóng lỗ trên cả ba tracker bằng 5 chữ.
- **B. Không đổi** — sửa ở phía `to-spec` (publish `needs-triage`, thăng nhãn sau khi arm trả về).

**Em đề xuất B**, vì A đổi ngữ nghĩa frontier và va vào `thomas.md:52`
(*"Read edges and state, **never the readiness label**"*). Nhưng A rẻ hơn nhiều và anh có thể
thấy đánh đổi đó xứng.

### Q3. Có tách ledger không?

Ledger tuyên bố **append-only thành văn** (`recurring-failure-modes.md:17`).
Mỗi `grep -A40` trả về ~75% là tường thuật.

- **A. Tách** `ledger-rules.md` (id + rule ~40 từ) khỏi `ledger-evidence.md` — grep trả gần 100% tín hiệu.
- **B. Giữ nguyên** — chính sách append-only là một phần bản sắc của gói.

**Em đề xuất A**, nhưng đây là **sửa chính sách anh đã viết ra**, nên em không tự làm.

### Q4. Có đưa cơ chế debate ngang hàng vào harness không?

Toàn bộ harness **không có tranh luận ngang hàng**. Mọi bất đồng thoát qua hai cửa: leo thang
lên anh, hoặc gọi vendor khác. `builder.md:81` *"disagreement is a decision for the owner"*;
`thomas.md:122` *"Rin advises and **you classify**"*. Harness thậm chí phải van ngược ở
`thomas.md:235`: *"Resolve open questions rather than routing every one to the owner —
**that is the point of this harness**."*

- **A. Thêm quyền phản biện có giới hạn** ở `thomas.md:120-124`: tác giả được **đúng một lượt** đáp lại, ghi vào hồ sơ, chỉ phản biện chưa ngã ngũ mới leo lên anh.
- **B. Giữ nguyên** — một-vòng-một-milestone bị cắt **có chủ ý** sau khi đo 5–14 vòng.

**Em không đề xuất bên nào.** Đây là câu hỏi triết lý sản phẩm. Nhưng em ghi nhận: triết lý
"phòng ban có tranh luận" của anh hiện sống trong `docs/distilled/capabilities/party-mode.md`
và **chưa bao giờ được đưa vào `harness/`**.

### Q5. Vai trò thứ sáu cho bộ dụng cụ mattpocock?

Anh đặt câu hỏi này giữa phiên. **Ba chuyên gia độc lập cùng bác** — Matt (chủ plugin),
Murat (test architect), Winston (kiến trúc). Lý do hội tụ: thất bại đo được là ở **việc GỌI**,
không phải **việc BIẾT**; và role mới bắt buộc phải sửa vào `thomas.md`, bề mặt always-on
nhạy cảm nhất.

Nhưng **linh cảm của anh đúng**: 13/35 skill vô hình và không ai có nhiệm vụ nhận ra.
Cái thiếu là **hai hàng Load**, không phải một cái ghế:
`writing-for-agents` → `builder.md:17` · `improve-codebase-architecture` → `shaper.md:17`.

**Em đề xuất: không thêm role, thêm hai hàng.** Cần anh xác nhận vì anh là người nêu ý tưởng.

### Q6. `check-requirements.sh` — sửa thế nào?

Đo trực tiếp: `git init` một thư mục rỗng, **không có harness gì** → `All required checks
passed. EXIT=0`. Và thiếu ba doc `docs/agents/*.md` set `TARGET_READY=0`, thứ này **chặn luôn**
phép kiểm payload-đã-commit của AST-036 — **phát hiện yếu bịt miệng phát hiện mạnh**.

- **A. `warn` → `miss`** (điều tra viên đề xuất) — nhưng text cảnh báo ghi *"expected to be absent **before then**"*, tức `warn` là **có chủ ý** cho ca trước-adaptation. Sửa thế sẽ phá ca dùng hợp lệ.
- **B. Thêm chế độ sau-adaptation** — một cờ, hai mức nghiêm ngặt cho hai câu hỏi khác nhau.

**Em đề xuất B.** Và tách `TARGET_READY` khỏi cổng AST-036 bất kể chọn gì.

### Q7. Chính sách gương `.agents/` ↔ `.claude/`

18 file nhân đôi, đồng bộ **bằng tay**. `install.sh:45` có kiểm nhưng ba lỗ: chỉ phủ `SKILL.md`
(bỏ `WATCHING.md`, `CLEANUP.md`, `project-status-sync.sh` — mà `WATCHING.md` **đang được sửa
tay ở cả hai cây ngay lúc này**); skill chỉ có ở một cây thì bị bỏ qua; và allowlist miễn trừ
`review-with-rin` **lệch 0 dòng** — một miễn trừ chết đang che mọi drift tương lai của cặp đó.

- **A. Sinh `.claude/` từ `.agents/`** — một nguồn sự thật, xoá cả lớp lỗi.
- **B. Giữ hai bản, siết kiểm** — mở rộng vòng lặp sang mọi file, bỏ miễn trừ chết.

**Em đề xuất B** trước (rẻ, không đụng runtime), A là hướng đi dài hạn.

### Q8. Thứ tự thi công

**Em đề xuất:**
```
Phase 0 (đo baseline)
  → hook nhóm git          (cơn đau anh nói là thường trực + nhóm tái phát #1)
  → di dời rule git        (broker → CLEANUP.md; sửa thứ tự prune; sửa động từ ở thomas.md:87)
  → định nghĩa dispatch record   (mục CHẶN — 4 thứ khác treo lên nó)
  → hook merge/report/dispatch
  → sự thật tracker        (github req3, jira claim, thomas.md:75)
  → tầng release (L)       (check-requirements, applied-version, payload-drift)
  → chuyển tầng context + hạ ngân sách  (làm cùng lúc)
  → cắt
```

---

## Phần 3 — Sáu thứ em sẽ KHÔNG làm nếu anh không bảo

1. Thêm role thứ sáu *(Q5)*
2. Gỡ đường Codex/OpenCode — hết quota là chuyện thường ngày, bảo hiểm đang có hiệu lực
3. Mở lại vòng lặp review của Rin — bị cắt có chủ ý sau khi đo 5–14 vòng
4. Đụng `check-simplify-markers.sh` ngoài việc thêm `--marker` kind — nó là bộ phận khoẻ nhất
5. Sửa `thomas.md:47` *(Q2)*
6. Tách ledger *(Q3)*

---

## Phần 4 — Ba con số đáng nhớ nhất

**Một.** Trong 9 cơ chế lỗi git, cơ chế **duy nhất không tái phát** là cơ chế **duy nhất có
script** (marker↔head, `check-simplify-markers.sh`). Tám cơ chế còn lại được bảo vệ bằng văn
xuôi và cả tám vẫn đang tái phát. Đó là toàn bộ luận điểm của cuộc audit, gói trong một dòng.

**Hai.** Cùng một thất bại — *"QA/browser walker ship qua nhiều release, chưa chạy lần nào"* —
được ghi vào ledger **ba lần** qua ba thiết kế (AST-045 → AST-057 → AST-135) và **chưa lần nào
sinh ra một cơ chế**. Họ AST-032 tái phát qua **sáu** release.

**Ba.** Trong ~95 mục, **chỉ 1 mục cần viết mới thật sự** (định nghĩa `dispatch record`).
Phần còn lại là `HOOK` · `MOVE` · `CUT` · `FIX`. **Đây không phải đợt viết thêm tài liệu.
Đây là đợt chuyển rule từ ký ức sang sự kiện.**
