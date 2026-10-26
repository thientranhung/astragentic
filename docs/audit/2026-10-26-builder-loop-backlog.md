# Backlog vòng Builder — thảo luận 2026-10-25/26, implement lần lượt

Mỗi mục: `[ ]` chưa làm, `[x]` đã làm (ghi release), `[-]` owner bỏ. Số đo ở
`2026-10-25-builder-token-levers.md`. Owner muốn bàn hết một lần rồi làm từng mục; không gom
thành release cho tới khi owner gật từng mục.

## Owner đã gật

- [ ] **A. Simplify một lần, ở cuối, trước handback.** Bỏ câu "sau fold chạy lại simplify trên
  marker..HEAD" trong `builder.md`; `check-simplify-markers.sh` không bắt marker là HEAD, chấp
  nhận fold sau marker. Số: 57/244 session 2–5 vòng, ≈$335 / 14 ngày. Owner 2026-10-26.
- [ ] **B. Thứ tự phase mới:** code + tdd → UX audit + bằng chứng (ticket UI) → `mattpocock-skills:code-review`
  → built-in `code-review` → simplify → `Validation:` → commit, push, handback. Arm Codex
  (nếu project bật) sau simplify, đọc cây cuối; fold từ arm không đòi simplify lại. Owner
  2026-10-26: "UX trước cả hai review, simplify sau cùng".
- [ ] **C. Builder chỉ chạy dòng `Validation:` của brief.** Bỏ "the ONE full verification run"
  trong `builder.md`; station chạy gate ở merge (median 6.7 phút). Số: đuôi sau Skill cuối 19%
  (gồm handback + push, chưa tách).
- [ ] **D. Arm Codex: giữ như project đặt.** nizzy tắt cấp ticket (arm = 1% sau trần), giữ cấp
  slice. Không bật lại cấp ticket: 10 merge tắt = 0 lỗi (2026-10-18). Owner 2026-10-26 "ok".
- [ ] **E. Gửi nizzy và inception bảng tải nền** (đoạn "Gửi cho hai bên" trong doc số): AGENTS.md
  → chỉ mục + docs/agents; rule gắn `paths:`; `enabledPlugins` theo project; đo bằng
  `claude -p --model haiku --output-format json`. Owner 2026-10-26: "để cho nó lo". Chỉ gửi số,
  không gửi bước áp.

## Chưa quyết (owner đọc giải thích 2026-10-26, chưa chốt)

- [ ] **F. `usage-report.py` in thêm dòng tải nền** (context call 1 theo role), mốc 91.9k nizzy /
  53.5k inception. Chỉ hiển thị, không từ chối.
- [ ] **G. Reviewer subagent nhận một file diff và bị cấm crawl repo; model rẻ cho review diff
  nhỏ** (hai thứ superpowers 7.0 làm). Chưa đo lợi trên harness này.
- [ ] **H. Trần context cho Thomas**: median 251k, $11 / merge, chưa compact bao giờ. Owner trước
  đây chỉ hỏi để biết.
- [ ] **I. Guard isolation từ chối 467 spawn / 14 ngày** rồi Builder gõ lại với `isolation: worktree`.
  ~$0.04 mỗi lần; để sau.
- [ ] **K. Làm gọn code soi ba lần** (trục Standards mattpocock, 5/8 góc built-in, simplify). Giữ cho
  tới khi đo được finding Standards dẫn tới commit.
- [ ] **L. Thomas trả về sau handback: 29/164 ticket, 6% tiền Builder.** Kỳ vọng giảm sau A; đo lại.

- [ ] **M. Hai lane: Builder và quick-builder, phân loại bằng probe, không bằng tiêu đề.** Lúc claim,
  Thomas `git grep -c` / `git log --stat` vùng ticket nhắc → số file + có chạm `risky-paths` không;
  ≤3 file, không rủi ro, không đổi hành vi (câu phán duy nhất, ghi lý do lên ticket) → nhãn
  `quick`, dispatch pane quick-builder (nhận ticket, không gate, trước/sau, Thomas ff-merge).
  Leo thang một chiều quick → Builder khi diff vượt ngưỡng. Ngưỡng = p25 cỡ merge của chính
  project sau 30 merge. Số: nizzy 1/128 ticket là label thuần, "rename" TRA-1210 chạm 311 file;
  `TDD: n/a` 11/346 → Thomas không tự phán nếu không có phép đo; ≤50 dòng vẫn $18 / 290 call.
  Chạm: thomas.md, dispatch-ticket, quick.md, mod (chip/bell lane quick), tracker label. Owner
  2026-10-26: bàn cùng "vận hành ticket và năng lực Shaper".
  Bổ sung 2026-10-26 (owner): **ai phân loại** = vòng thẩm định sau BA. BA chạy probe và đánh
  dấu từng dòng handoff `quick` / `ticket` / `epic` kèm số file; owner gật → ticket mang nhãn.
  **Nhãn là bắt buộc lúc cắt ticket** (owner 2026-10-26): `to-tickets` của Shaper và ticket BA cắt
  đều mang `quick`/`builder` + số file dự kiến (từ code đã đọc lúc Align, không đoán); ticket
  không nhãn = cắt chưa xong, Thomas trả về nơi cắt. **Thomas điều phối theo nhãn** (owner 2026-10-26): `quick` →
  pane quick-builder, Thomas nhìn diff + trước/sau rồi ff-merge; không nhãn → Builder. Thomas
  chỉ probe khi ticket không nhãn hoặc quick-builder trả về vì vượt ngưỡng. Owner gọi
  quick-builder tay chỉ là cửa phụ khi cần, không phải đường vận hành.
  **`quick.md` viết lại thành quick-builder = junior dev** (owner 2026-10-26, bỏ ops/*, trước/sau,
  ff-merge, chờ gật): nhận brief từ Thomas, worktree + nhánh ticket như Builder; sửa code, chạy test
  có sẵn của phần chạm; tự review một lần bằng built-in `code-review` (inline, 0 spawn, 6%);
  commit, push, handback như Builder; Thomas merge bằng đường hiện nay, merge gate không đòi
  tdd/simplify/arm cho role này. Không tdd bắt buộc, không mattpocock 2 trục, không simplify,
  không UX audit, không arm. Vượt ngưỡng → nói trong handback, Thomas chuyển lane Builder.
  Tên: giữ `builder`,
  `quick` → `quick-builder`; không dùng senior/junior (`junior-<runtime>` đã có nghĩa khác).

## Owner đã bỏ

- [-] **J. Tier ticket theo diff + `risky-paths` của project.** Owner 2026-10-26: cỡ ticket không phải
  vấn đề; vấn đề là vận hành ticket và năng lực Shaper, bàn sau.
- [-] **Thử nghiệm 10 merge tắt review.** Owner 2026-10-26: bỏ hẳn.

## Đã xem, không có việc

- QA: 2 session / 14 ngày, ~235 call, một skill mỗi session, không có luật chạy lại. 2.5% chi phí.
- Shaper: 4 session, 116–493 call, Align → Spec → Arm → Test design → Tickets, mỗi skill một
  lần, không loop. 2% chi phí.

## Chỗ phải đổi đồng bộ khi làm A–C (đếm 2026-10-26)

| Nơi | Đang có | Đổi | Mục |
|---|---|---|---|
| `harness/.agents/roles/builder.md` | bảng phase; "After a fold, re-run simplify over marker..HEAD"; "the ONE full verification run" | thứ tự mới; bỏ hai câu | A, B, C |
| `harness/.agents/skills/dispatch-ticket/SKILL.md` dòng `FLOW:` (và `-claude`) | tdd → matt → built-in → (ux) → simplify → arm | tdd → ux (UI) → matt → built-in → simplify → arm | B |
| Mod `register.tsx` `FLOW_BY_ROLE.builder` (chip "→ bước kế") | implement, tdd, review:matt, review:built-in, ux, simplify, arm | implement, tdd, ux, review:matt, review:built-in, simplify, arm | B |
| Mod arm gate (arm chỉ sau built-in code-review) | đúng với thứ tự mới | giữ | — |
| Mod merge gate (record có tdd/test file, hai review, simplify; không xét thứ tự, không xét HEAD) | | giữ | — |
| `harness/scripts/check-simplify-markers.sh` rule 5 "marker mới nhất COVERS head, không thì re-run" | bắt marker là HEAD | marker phủ commit nội dung cuối; fold sau marker được phép | A |
| `harness/scripts/selftest.sh` | case cho thứ tự chip và rule 5 | sửa case theo | A, B |
| `harness/.agents/roles/builder-claude.md` | "built-in code-review sau mattpocock, trước simplify" | vẫn đúng | — |
