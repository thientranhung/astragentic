# Trang chủ v2: kể từ vì sao và feature (2026-09-06)

Chủ site duyệt bản chữ dưới đây ("ok bạn thử đi nào"). Chữ tiếng Việt là **nguyên văn đã
duyệt**, không sửa ý; chỉ được rút gọn khi tràn khung. Bản Anh dịch giữ nhịp, "I/you".

## Nguyên tắc

- Người đọc là dân dev vibe coding vào tìm hiểu: trả lời theo thứ tự câu hỏi trong đầu họ:
  vì sao cái này ra đời → nó làm được gì → nó chạy thế nào → hợp với ai → bắt đầu ra sao.
- Triết lý không mở bài. Mỗi section một câu hỏi, một hình, ít chữ.
- Định vị "cho dự án nhiều milestone" nằm ngay trong hero.
- Giữ layout đợt 5-7: khung, token, đỏ Astraler, đảo trên giấy kẻ ô, sơ đồ client-studio.

## Nav (đổi thứ tự)

Vì sao · Cấu trúc · Vai · Skills · Hooks · Tech stack · Cài (en: Why · Structure · Roles ·
Skills · Hooks · Tech stack · Adopt).

## Hero

Eyebrow: `AGENTIC ENGINEERING · CHO DỰ ÁN NHIỀU MILESTONE · V{{meta.version}}`
(en: `AGENTIC ENGINEERING · FOR MULTI-MILESTONE PROJECTS`)

Headline: **Một đội outsource bằng AI agent. Vận hành đúng quy trình, liên tục 24/7, cho
những dự án lớn.**
(en: **An outsourcing team made of AI agents. Running by process, around the clock, for
large projects.**)

Sub: Astragentic đưa bạn vào vị trí khách hàng của một đơn vị phát triển phần mềm hoàn
chỉnh: một người đại diện để trao đổi, một đội agent có vai trò rõ ràng để thi công, và
một issue tracker làm trung tâm để mọi việc đều có dấu vết. Bạn giữ quyền quyết định và
toàn quyền giám sát; phần thực thi thuộc về đội.

Nút: **Xem đội vận hành ↓** (tới #lifecycle) · Triển khai vào repo → (/cai)

Hình: `client-studio` full band, tương tác, như hiện tại. Không stat strip.

## Section 1 · why (nền surface)

H2: **AI đã làm việc như một developer thực thụ. Câu hỏi còn lại là ai dẫn dắt.**

Đoạn 1: Vibe coding chứng minh một agent có thể nhận việc, viết code và tự kiểm thử như
một kỹ sư. Khi năng lực thực thi không còn là nút thắt, giá trị của người kỹ sư chuyển
sang chỗ khác: đặt yêu cầu đúng, quyết định đúng, và giữ toàn bộ quy trình đi đúng hướng.

Đoạn 2: Astragentic được xây để bạn làm đúng phần đó. Nó tổ chức các agent thành một đội
outsource theo kỷ luật SDLC quen thuộc, nhưng thiết kế lại cách phân việc, review và bàn
giao để khai thác tốc độ và khối lượng công việc mà một đội người không thể duy trì.

Link đi tiếp: "Đọc đủ năm câu vì sao →" (/vi-sao). Hình: không, hai cột chữ 62ch.

## Section 2 · features (nền canvas), lưới 3×2 thẻ trắng, mỗi thẻ: hình nhỏ (diagram
sẵn có, tĩnh, crop) + tiêu đề + 2-3 câu + link

1. **Cổng review hai lớp, hai vendor.** Mọi ticket đi qua review built-in của Claude Code,
   rồi qua một lượt đọc chéo của Codex. Hai model soi cùng một diff, tranh luận trước khi
   merge. Chất lượng không phụ thuộc vào việc Builder hôm nay giỏi hay kém.
   Hình `cross-vendor-arm`. Link /skills/codex-arm.
2. **Vận hành liên tục quanh issue tracker.** Mọi phân tích, slice và task đều nằm trên
   tracker. Review phát hiện việc mới thì tự nạp vào hàng đợi. Đội chạy 24/7 mà không cần
   bạn ngồi canh, và không có việc nào rơi ra ngoài hệ thống.
   Hình `frontier-query`. Link /cau-truc#coordination.
3. **Đội có tên, có vai, có hợp đồng.** Thomas đại diện, Shaper định hình, Builder thi công,
   Rin gác cổng, QA nghiệm thu. Mỗi vai có system context riêng, nên trách nhiệm rõ và
   không ai làm thay việc của ai. Claude Code và Codex đều hỗ trợ agent profile ở mức này.
   Hình `five-roles`. Link /vai/thomas.
4. **Không lệ thuộc runtime.** Chỉ có Codex, chỉ có Claude Code, hay cả hai đều vận hành
   được. Bạn khai báo vai nào chạy trên provider nào trong `orchestrator.md`; đổi provider
   không đổi quy trình.
   Hình `structure` (crop dải Runtime). Link /tech-stack#claude-code.
5. **Đúng model cho đúng việc.** Sonnet cho Builder thi công nhanh, Opus cho phân tích và
   slice cần suy luận sâu. Chi phí và chất lượng được cân theo từng vai thay vì một model
   cho tất cả.
   Hình: bảng nhỏ vai → model (đọc từ harness/.claude/agents/*.md trường `model:` nếu có;
   không có thì để chữ, không bịa). Link /vai/builder.
6. **Toàn quyền giám sát, không cần ra tay.** Board tracker, pane herdr, thiết kế và quyết
   định đều đọc lại được. Thomas hỏi lại bạn ở những điểm quan trọng: UI/UX, lựa chọn tech
   stack. Bạn quyết, đội làm.
   Hình `hub-and-spokes`. Link /vai/thomas.

## Section 3 · lifecycle (nền surface), id="lifecycle"

H2: **Từ issue tới merge, tracker ở giữa.**
Hình `ticket-lifecycle` tương tác (như đợt 3) + dải 7 bước một dòng (caption có sẵn trong
landing yaml `stages`). Link "Sáu lỗi đo được →" (/loi).

## Section 4 · fit (nền canvas)

H2: **Sinh ra cho dự án nhiều story, nhiều milestone.**
Đoạn: Astragentic không dành cho một script hay một prototype cuối tuần. Nó phát huy khi
backlog dài, milestone nối tiếp, và bạn cần một đội chạy ổn định trong nhiều tuần. Nếu dự
án của bạn ở quy mô đó, phần còn lại của site là dành cho bạn.
Hai cột nhỏ "Hợp khi" / "Chưa hợp khi", mỗi cột 3 gạch đầu dòng (viết từ đoạn trên, không
thêm claim).

## Section 5 · adopt (nền surface)

H2: **Bốn lệnh, một orchestrator.md.**
AdoptBlock (4 lệnh từ data), ba link mono: Cấu trúc · Vai · Skills.

## Bỏ khỏi trang chủ

Section "Bốn lớp", "Hook đứng gác", "Vì sao" (5 thẻ), "Tech stack" (dải 9), "Skill có sẵn"
(lưới 16), QuoteBlock thú nhận. Tất cả vẫn có trang riêng và nằm trong nav.

## Kỹ thuật

- `landing/{vi,en}.yaml`: thêm `hero.eyebrow`, `why {headline, p1, p2, more}`,
  `features[6] {id, title, body, diagram, href}`, `fit {headline, body, yes[3], no[3]}`,
  `adopt {headline}`; giữ key cũ để trang khác không gãy.
- HomeBody dựng lại theo 5 section; xoá section không dùng; giữ component sẵn có.
- Nav order đổi trong lib/site hoặc Nav.astro.
- Thẻ feature: hình là `Diagram` tĩnh với `crop` nếu component hỗ trợ, không thì hiển thị
  full nhỏ trong khung 4:3, không link explore ở thẻ.
- Build, detector 0, chụp 1440 và 390: /, /en; kiểm không còn chữ "mình/anh em/chúng tôi".
