# PRD site Astragentic (2026-09-04)

Viết bằng lời chủ site, gom từ cả phiên. Đây là tài liệu duy nhất mọi đợt build phải đối chiếu.
Chủ site sửa trực tiếp file này; agent không sửa.

## 1. Người đọc

**Dân dev vibe coding.** Đã dùng Claude Code hoặc Codex một mình, có thể chưa chạy nhiều agent.
Không giả định họ đã đau, không giả định họ đã cài.

## 2. Đọc xong, họ phải hiểu được

1. **Cấu trúc** của Astragentic: các lớp, cái gì nằm ở đâu, chạy trên gì.
2. **Các skill** được cung cấp: có gì, dùng khi nào, để lại gì.
3. **Các role** phân vai: Thomas, Shaper, Builder, Rin, QA, mỗi vai làm gì, sống bao lâu.
4. **Hook** hỗ trợ: có những hook nào, chúng giúp làm việc gì, chặn cái gì.
5. **Vì sao**: vì sao phải dùng Astragentic; vì sao dùng mattpocock-skills thay vì Superpowers;
   vì sao dùng cái này mà không dùng subagent hay agent team của Claude Code; và các câu
   "vì sao" khác chủ site đã trả lời trong ADR, ledger, release notes.
6. **Tech stack**: mình dùng gì và vì sao (Claude Code, Codex, OpenCode, git worktree, herdr,
   mattpocock-skills, tracker adapters, script Python/Bash, archify cho chính site này).
7. **Các phần hay** của Astragentic: ledger, cross-vendor arm, tracker là substrate, claim
   trước worktree, review một vòng.

## 3. Giọng và mục đích

- Truyền cảm hứng và giới thiệu. Chủ site kể vì sao mình chọn vậy, thiết kế vậy. Không phải
  thầy giáo, nhưng **được phép giải thích**; cấm giọng dạy, không cấm cấu trúc giải thích.
- Ngôi "mình" với "anh em" (Việt), "I" (Anh).

## 4. Ngôn ngữ

- Song ngữ, **mỗi trang một ngôn ngữ sạch**. Trang Việt: chữ Việt, nhãn diagram Việt, nav Việt,
  caption Việt. Trang Anh: toàn Anh. Không lẫn.
- Giữ nguyên ở cả hai bản: tên vai, tên skill, lệnh, mã AST, tên file, trích dẫn nguyên văn từ
  ledger và release notes (đặt trong khối trích rõ ràng, có nhãn "nguyên văn").
- Tiếng Việt ở `/`, tiếng Anh ở `/en/`.

## 5. Hình và chữ

- **Hình phải to, chữ phải nhỏ.** Diagram chiếm hết bề ngang khung, nhãn trong diagram đọc
  được không cần zoom. Body text cỡ đọc bình thường (17px), headline vừa phải, không choán.
- Trang chủ là landing: hero, rồi diagram archify hoạt động, bấm node là sang trang của node
  đó (vai, chặng, skill), rồi workflow nhận task từ tracker giữa các vai, rồi các section còn
  lại. Mỗi section một hình, ít chữ.
- Thích cấu trúc catalog skill của aihero.dev/skills: nhóm theo lúc cần dùng, mỗi skill một
  dòng động từ và một trang riêng.

## 6. Không làm

- Không bịa số, không bịa ảnh, không ô "Not yet captured".
- Không giọng quảng cáo, không stat khoe.
- Không thay đổi mục tiêu site theo ý agent; câu nào cần chủ site quyết thì hỏi, không tự chốt.

## 7. Thành công khi

Một dev vibe coding đọc trang chủ rồi trả lời được năm câu: Astragentic gồm những lớp nào; vai
nào làm gì; skill nào dùng lúc nào; hook nào chặn cái gì; vì sao không chỉ cần subagent. Và đi
được từ trang chủ tới trang của một vai, một skill, một hook, một câu "vì sao" trong một cú
bấm.
