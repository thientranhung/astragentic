# PRD site Astragentic (2026-09-04, cập nhật 2026-11-22)

Viết bằng lời chủ site, gom từ cả phiên. Đây là tài liệu duy nhất mọi đợt build phải đối chiếu.
Chủ site sửa trực tiếp file này. Bản 2026-11-22 do agent cập nhật theo lời chủ site ("cân nhắc giữ
hay xoá hay merge"): giữ, và gộp các quyết định đã chốt từ 09-05 tới 11-22 vào đúng mục.

## 1. Người đọc

**Dân dev vibe coding.** Đã dùng Claude Code hoặc Codex một mình, có thể chưa chạy nhiều agent.
Không giả định họ đã đau, không giả định họ đã cài.

## 2. Đọc xong, họ phải hiểu được

1. **Cấu trúc** của Astragentic: các lớp, cái gì nằm ở đâu, chạy trên gì.
2. **Các skill** được cung cấp: có gì, dùng khi nào, để lại gì.
3. **Các role** phân vai: Thomas, BA, Shaper, Builder, QA, Quick Builder, mỗi vai làm gì, sống
   bao lâu.
4. **Hook và mod** hỗ trợ: có những hook nào, mod dispatch làm gì, chúng chặn cái gì.
5. **Vì sao**: vì sao phải dùng Astragentic; vì sao harness tự viết bảy skill `astra-*`;
   vì sao dùng cái này mà không dùng subagent hay agent team của Claude Code; và các câu
   "vì sao" khác chủ site đã trả lời trong ADR, ledger, release notes.
6. **Tech stack**: dùng gì và vì sao (Claude Code và các kỹ thuật của nó, Codex, Herdr, Orca, git
   worktree, tracker adapters, script Python/Bash, diagram-design cho chính site này).
7. **Các phần hay** của Astragentic: ledger, review ba lens cộng cross-vendor arm, tracker là
   substrate, claim trước worktree, review một vòng.

## 3. Giọng và mục đích

- Truyền cảm hứng và giới thiệu. Chủ site kể vì sao mình chọn vậy, thiết kế vậy. Không phải
  thầy giáo, nhưng **được phép giải thích**; cấm giọng dạy, không cấm cấu trúc giải thích.
- Ngôi "tôi" với "bạn" (Việt), "I/you" (Anh), từ 2026-09-05. Giọng nghiên cứu, giới thiệu
  công nghệ, không phải blog (2026-09-11): mỗi mục một khung trả lời, cơ chế, số đo, cái giá.
  Không nêu tên dự án, khách hàng hay vendor nào (2026-09-13). Luật viết đầy đủ:
  `24-writer-rules.md`.

## 4. Ngôn ngữ

- Song ngữ, **mỗi trang một ngôn ngữ sạch**. Trang Việt: chữ Việt, nhãn diagram Việt, nav Việt,
  caption Việt. Trang Anh: toàn Anh. Không lẫn.
- Giữ nguyên ở cả hai bản: tên vai, tên skill, lệnh, mã AST, tên file, trích dẫn nguyên văn từ
  ledger và release notes (đặt trong khối trích rõ ràng, có nhãn "nguyên văn").
- Tiếng Anh ở `/`, tiếng Việt ở `/vi/` (từ 2026-09-11). Chủ site chỉ duyệt bản Việt; bản Anh
  dịch song song trong cùng commit.

## 5. Hình và chữ

- **Hình phải to, chữ phải nhỏ.** Diagram chiếm hết bề ngang khung, nhãn trong diagram đọc
  được không cần zoom. Body text cỡ đọc bình thường (17px), headline vừa phải, không choán.
- Trang chủ là landing: hero, rồi diagram (diagram-design, profile `astragentic`) bấm được, bấm node là sang trang của node
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

## 8. Mỗi bài mang version harness lúc viết (2026-11-22)

- Mỗi bài có `harness: vX.Y.Z` (một tag `v*` có thật trên GitHub) và `source:` liệt kê các file
  harness bài đó mô tả. Trang in "Viết theo vX.Y.Z", link tới tag.
- Chỉ gắn version cho bài đã đối chiếu lại thật. Lúc build in danh sách bài chưa gắn.
- Lần nâng cấp sau: `git diff <tag của bài>..HEAD -- <source>` cho biết bài nào phải xem lại.
  Sự thật cho mỗi đợt nằm trong một fact sheet (`23-facts-6.1.19.md` cho đợt này).
