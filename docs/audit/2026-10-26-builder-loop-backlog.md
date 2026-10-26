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

## Thứ tự làm (owner 2026-10-26: đủ việc, bắt đầu)

1. **4.5.0 — vòng Builder:** A + B + C (+ D giữ nguyên). Một release, mod + builder.md + FLOW + marker script + selftest cùng lúc.
2. **E ngay:** gửi bảng tải nền cho nizzy và inception, không release.
3. **4.6.0 — ticket quick/full:** M (nhãn → miễn trừ, Shaper/BA ghi nhãn, band/board hai hàng, quick-builder).
4. Đo 30 merge sau 4.6.0: $ ticket nhỏ, tỉ lệ nhãn sai, p25 thật. Rồi mới xét F–L.

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

- [ ] **M. Ticket `quick` / `full` — chốt 2026-10-26 (owner "rất hài lòng").**
  - **Cách dựng: không lane mới.** Nhãn `quick` trên tracker → mod tự đặt miễn trừ cho pane Builder
    (tdd, review:matt, simplify, ux); Thomas chỉ claim + dispatch như mọi ticket. Thêm hai cờ
    `SIMPLIFY: n/a`, `UX: n/a` bên cạnh `TDD: n/a`, `REVIEW: n/a` đã có; merge gate tôn trọng.
    Quick = Builder code, chạy test có sẵn, tự review built-in `code-review` inline, handback.
  - **Lý luận phân loại, hỏi theo thứ tự, "có" đầu tiên = `full`:** (1) chạm `risky-paths` của
    project (migration, route/API, auth, thanh toán, ghi dữ liệu)? (2) sai thì phải test mới biết
    (logic, phép tính, trạng thái, dữ liệu) hay nhìn là thấy (chữ, label, vị trí, màu, config)?
    (3) `git grep` chữ/component ticket nhắc → >3 file? (mốc đầu; sau 30 merge thay bằng p25 của
    project). Ví dụ: TRA-1223 quick; TRA-1210 full (311 file); TRA-1218 full (logic lọc).
  - **Ai quyết:** người cắt ticket (Shaper `to-tickets`, BA) ghi ba dòng bằng chứng lên ticket
    (rủi ro / kiểm bằng / số file). Nhãn bắt buộc; không nhãn = trả về nơi cắt. Thomas không hỏi
    lại. Quick vượt câu 3 khi làm → nói trong handback, Thomas chuyển `full`.
  - **Band/board:** Thomas: hàng 1 trạng thái chung (`⎇ main · astragentic 4.4.0 ↑4.5.0 · tracker
    12 claimable · 3 lane`), mỗi lane một hàng cột thẳng `TRA-1218  builder  working  12m`, lệnh
    update rời band. Builder: hàng 1 `builder TRA-1218 · quick · astragentic 4.4.0`, hàng 2 chỉ các
    bước; bước miễn trừ bỏ khỏi hàng, không in n/a. Loại đọc từ nhãn, cùng nguồn với miễn trừ.
  - **Selftest:** trồng ticket `quick` → chip đổi, commit gate không đòi test, merge gate không
    đòi simplify; ticket không nhãn → gate bắt như cũ. Fail trên bản cũ, pass trên bản mới.
  - Tên: giữ `builder`; `quick` (role owner gõ tay) đổi `quick-builder`, là cửa phụ. Không
    senior/junior. Model quick: Sonnet low, đo 10 ticket rồi mới thử Haiku.
  - Tiền: sau A–C ticket nhỏ ≈ $10–12, quick ≈ $5 (ước); 15–32% ticket nizzy; ≈3–5%. Làm vì tổ
    chức và tốc độ, sau A–C.

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
