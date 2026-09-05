---
title: review-with-rin
oneLiner: "Chạy cửa gate milestone của Rin trong một pane quan sát được, rồi phân loại các phát hiện."
group: gate
order: 1
runtimes: [claude]
source: harness/.agents/skills/review-with-rin/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

Đây là công thức Thomas chạy để lấy ý kiến thứ hai tại một milestone: một spec đã chốt, một
ticket hay PR sắp đóng, một epic đang khép lại. Nó resolve khoá artifact, mở một pane Herdr với
detached worktree riêng tại đúng SHA đang được review, đóng gói cho Rin một bản brief gồm mode,
đường dẫn spec hoặc ticket, acceptance criteria, một đoạn về ý định của chủ project, và với việc
UI thì thêm con trỏ tới design guidelines cùng bằng chứng trình duyệt của Builder. Sau đó nó
dispatch Rin, rồi thu về mọi thứ Rin ghi vào gate-file trước khi động vào bất cứ thứ gì khác.

Điểm khác một lượt review PR bình thường là skill này cố ý chỉ chạy **một lần mỗi milestone**.
Vấn đề nó đang trả lời là một vòng lặp. Một phiên bản trước của phương pháp cho phép các vòng
review lặp lại, và một project chạy nó đo được 5 đến 14 vòng mỗi milestone, phần lớn là vòng
review lại chính các bản vá trước đó. Vì vậy skill này coi phát hiện của Rin là lời khuyên mà
Thomas phân loại đúng một lần. Những thứ blocking ở mức thiết kế đi thẳng lên chủ project như một
quyết định, không bao giờ thành vòng thứ hai, còn lại gộp thành một work order gửi cho người sở
hữu artifact. Cơ chế gate-file tồn tại vì một lý do liên quan: một lượt đọc pane trong Herdr âm
thầm cắt cụt theo số dòng đang hiển thị mà vẫn báo thành công, trong khi báo cáo gate thường dài
hơn 300 dòng, nên toàn bộ báo cáo phải rơi vào một file do Thomas đặt tên và kiểm lại trước mọi
bước cleanup.
<!-- source: harness/.agents/skills/review-with-rin/SKILL.md -->

## Khi nào Thomas gọi nó

| Thứ đang ở trước mặt | Gọi cái này |
|---|---|
| Một spec vừa được commit, đã chốt | `review-with-rin`, `mode=adversarial` |
| Một ticket hoặc PR sẵn sàng đóng | `review-with-rin`, `mode=code-review` |
| Một epic vừa đóng | `review-with-rin`, `mode=code-review` (báo cáo lên chủ project, không có gì để merge) |
| Bạn đang review một increment bên trong một ticket còn mở | Không phải skill này, mà là `mattpocock-skills:code-review` cộng lượt simplify, vốn tự nó đã trọn vẹn |
<!-- source: harness/.agents/skills/review-with-rin/SKILL.md -->

## Cần sẵn gì

- Bạn là Thomas, vì đây là công thức chỉ dành cho Thomas.
- Herdr với tới được và workspace gọi được tên. Một daemon đang sống không đủ làm bằng chứng, và
  nếu không gọi được tên workspace thì đó là STOP, không phải lùi về dùng subagent.
- Có launcher cho runtime ghi ở dòng `rin` trong `orchestrator.md`. Thiếu adapter cho runtime cần
  dùng thì cũng là một STOP báo lên chủ project.
- `check-requirements.sh` vốn đã coi Herdr là bắt buộc cứng, nên chỗ này không thêm phụ thuộc mới
  nào lên trên nó.
<!-- source: harness/.agents/skills/review-with-rin/SKILL.md -->

## Nó để lại gì

| Chuyện gì xảy ra | Nó nằm lại ở đâu |
|---|---|
| Báo cáo đầy đủ của Rin | `$GATE_FILE`, rồi chép sang `.astraler/state/gate-history/<artifact-key>-<short-sha>.md` trước khi cleanup |
| Vệt phán quyết của Rin tại head đã review | Một commit rỗng `rin(gate):` mang theo `Scope:`, `Verdict:`, `Report:` |
| Một phát hiện blocking ở mức thiết kế | `to-questionnaire`, định tuyến lên chủ project |
| Một phát hiện không blocking hoặc không thuộc thiết kế | Một work order gửi Shaper đang tạm dừng (gate spec) hoặc Builder của ticket đó (gate ticket/PR) |
| Một quyết định merge | Chỉ sau khi cánh tay cross-vendor đã chạy trên SHA cuối, xem `codex-arm` |
<!-- source: harness/.agents/skills/review-with-rin/SKILL.md -->

## Lỗi đã biết

- `AST-030`: orchestrator ghi tên một runtime cho dòng `rin` mà runtime đó không có đường dispatch
  nào, nên Rin thành không dispatch được. Promoted: ma trận launcher giờ là nhà duy nhất của mọi vai.
- `AST-033`: cách tra cũ "có tab ticket nào đang sống không?" trả lời "không" mọi lần ở một gate
  spec, âm thầm biến mọi gate spec thành một subagent vô hình. Promoted, đã được thay bằng câu hỏi
  "có gọi được tên workspace không?"
- `AST-043`: cửa gate đòi bản brief mang theo "bằng chứng browser-verify của Builder", trong khi
  `builder.md` chưa từng nhắc là phải tạo ra thứ đó. Promoted: hợp đồng nào nợ nó thì giờ đã nói ra.
- `AST-032`: một pipeline sinh token có thể hỏng giữa ống mà vẫn thoát mã 0 dưới `set -e` trần, làm
  rỗng token freshness trong im lặng. Promoted, sửa bằng `set -euo pipefail` cộng một lượt kiểm độ dài.
<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Cửa gate chạy trong pane Herdr của riêng nó, trong một detached worktree tại đúng SHA đang
  review, không bao giờ bên trong checkout của Builder.
- `$GATE_FILE` tồn tại, không rỗng, và đã được chép vào `.astraler/state/gate-history/` trước khi
  gate worktree bị gỡ.
- Có một marker `rin(gate):` nằm tại head đã review, với `Scope:`, `Verdict:` và `Report:` đã điền.
- Thomas thật sự có bác hoặc hoãn ít nhất một phát hiện trong các gate gần đây. Một chuỗi không bác
  cái nào là dấu hiệu anh ấy đang chuyển tiếp nhãn của Rin chứ không phải đang phân loại chúng.
- Không gì được merge trước khi cánh tay cross-vendor chạy trên SHA cuối.
<!-- source: harness/.agents/skills/review-with-rin/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

Một ticket đi qua worktree của `/skills/dispatch-ticket`, và khi nó sẵn sàng đóng thì
`review-with-rin` gác cửa: đọc diff, kiểm xem marker simplify và dòng `Ledger:` có thật sự tồn tại
không, và bằng chứng trình duyệt có chống lưng cho mọi thay đổi UI không. Thứ Rin không phán được,
tức sản phẩm đang chạy có còn liền mạch không, là việc của `dispatch-qa-walk`. Khi các phát hiện
đã được gộp và kiểm lại, `/skills/codex-arm` nhận SHA cuối cho lượt cross-vendor trước khi bất cứ
thứ gì được merge. Bản thân vai `rin` sống trong các khái niệm ở `/dictionary/role`, và toàn bộ
việc này diễn ra bên trong một `/dictionary/gate`, trên một `/dictionary/worktree` mà không ai
ngoài Rin ghi vào.
<!-- source: harness/.agents/skills/review-with-rin/SKILL.md -->
