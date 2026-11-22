---
title: "Review"
description: "Mỗi thay đổi được đọc từ bốn phía trước khi merge: ba lens của Claude trên ticket, một model của vendor khác, QA trên sản phẩm đang chạy, và một slice gate khi nhiều ticket đã gộp lại."
harness: v6.1.19
source: "harness/.claude/skills/astra-review/SKILL.md, harness/.claude/skills/codex-arm/, harness/.claude/skills/astragentic-dispatch/agents/, harness/.agents/roles/builder.md, harness/.agents/roles/thomas.md, harness/scripts/check-simplify-markers.sh"
---

Review trong Astragentic chạy một lượt cho mỗi tầng, theo thứ tự cố định, và để lại receipt mà
script merge kiểm được. Không tầng nào được tính là đã chạy chỉ vì handback nói vậy.

## Thứ tự các pha của Builder là luật, không phải gợi ý

Kiểm tra trực quan làm đổi code, nên chạy trước review. Review tìm và báo, nên chạy trước
simplify. Simplify dọn code đã xong, nên chạy một lần, cuối cùng.

| pha | skill | kết thúc khi |
|---|---|---|
| Build | `astra-implement-with-tdd` | mỗi criterion có test từng đỏ và nay xanh |
| UI pass | `astra-ui audit` (ticket UI) | mọi bề mặt đã đổi có bằng chứng từ trình duyệt |
| Review | `astra-review` | ba lens đã chạy, mọi finding đã verify và route |
| Simplify | `simplify` | có commit `simplify(increment):` |
| Cross-vendor arm | `codex-arm` | có receipt `arm(ticket):` ở head |

**Số đo.** Trước luật "simplify một lần, cuối cùng", 57 trong 244 session Builder chạy simplify hai
tới năm lần, cho một lần rebase, một file sinh lại hay một dòng fold: khoảng $335 trong 14 ngày.

## `astra-review` chạy ba lens cùng lúc, mỗi lens một context riêng

- **Correctness.** Built-in `code-review` của Claude Code, chạy trên diff đã stage. Nó không nhận
  ticket, và đó là chủ ý: nó tìm cả thứ bị thiếu, không chỉ thứ bị sai.
- **Intent.** Một subagent chỉ đọc, nhận đúng ticket và diff. Với mỗi criterion: test nào chứng
  minh nó, test đó có chạy không, và criterion có được đáp ứng ở đúng bề mặt không.
- **Standards.** Một subagent chỉ đọc, nhận coding standard của repo và diff. Vi phạm có trích file
  và luật; vi phạm cứng tách khỏi phần phán đoán.

Ba lens được launch trong một message, trước khi đọc kết quả nào. Lens nào lỗi thì báo là lỗi,
không bao giờ báo là sạch.

### Lens thứ tư khi không có vendor khác

Khi arm của ticket bị tắt hoặc không chạy được, `astra-review` thêm lens adversarial: subagent
`astra-adversarial-lens` chạy trên Opus, đọc thay đổi để phá niềm tin vào nó thay vì xác nhận nó.
Lens này không phải arm và không ghi arm receipt.

**Số đo.** Đo blind trên bảy ticket replay: Opus tìm 13 defect thật mức high hoặc medium, precision
0.71; Sonnet tìm 7, precision 0.46. Khoảng 109k token mỗi ticket.

## Mỗi finding được kiểm tại dòng code trước khi có verdict

Finding được đánh số `R1, R2…` theo lens, chưa gộp. Với từng finding, Builder đọc dòng được dẫn,
cả caller và guard: trạng thái đó có xảy ra được không, có phải điều không mong muốn không.

- **Verdict.** `high`, `medium`, `low`, `false` hoặc `maybe false`, kèm đúng một câu bằng chứng.
  Mức nghiêm trọng là tác hại của một lần xảy ra, không phải độ hiếm hay chi phí sửa.
- **Gộp theo nguyên nhân gốc.** Finding còn lại được gom thành `F1, F2…`. Finding intent và
  standards không bao giờ xếp hạng chéo với nhau.
- **Route.** `patch` khi cách sửa không mơ hồ; `decision_needed` khi cách sửa phụ thuộc ý owner;
  `defer` khi lỗi có từ trước. Finding do chính thay đổi gây ra và đã verify thì không bao giờ
  được hoãn.

## Một model của vendor khác đọc lại tree đã simplify

Sau simplify, Builder chạy `codex-arm`: một lệnh `codex exec` chỉ đọc, không cần plugin Codex, model
gpt-6.2-astra ở effort medium. Ticket và slice đọc bằng edge lens; spec đọc bằng adversarial lens.
Finding được fold, lượt hai chạy nếu lượt một có sửa, rồi receipt `arm(ticket):` được ghi ở head.

Lý do dùng vendor khác: một model đọc lại diff của chính nó cũng đọc lại giả định của nó.

**Số đo.** Đo blind trên 7 ticket replay, 72 lượt, 336 finding:

| reader | defect thật / lượt | precision | token |
|---|---|---|---|
| Codex, edge lens, gpt-6.2-astra | 21 | 0.77 | ~79k |
| Claude, adversarial lens, Opus | 13 | 0.71 | ~109k |
| Claude, adversarial lens, Sonnet | 7 | 0.46 | |

Trên 34 defect thật, các ô Codex cộng lại tìm 29, các ô Claude tìm 17.

### Hết quota là NOT RUN, không bao giờ là pass

Hết quota, hoặc không có output đúng schema, thì arm ghi `NOT RUN` kèm lý do. Ticket khi đó rơi về
lens adversarial Opus ở trên, được ghi là same-vendor và chỉ mang tính tư vấn.

**Số đo.** Chạy thử với quota đã hết: exit 1, `NOT RUN — usage limit`, không có gì được tính là
pass. Một `AGENTS.md` thù địch yêu cầu "fix and commit" không làm arm ghi vào tree.

## Thomas merge bằng artifact, không bằng lời handback

`check-simplify-markers.sh` chạy trên SHA sắp merge và từ chối merge khi thiếu receipt
`simplify(increment)` hoặc `arm(ticket)` mà một ticket full còn nợ. Thay đổi chạm bề mặt người dùng thấy được hoặc endpoint
public được QA đi qua trên sản phẩm đang chạy trước merge, với marker `qa(walk)`.

### Ticket quick chỉ chạy built-in review

Ticket gắn nhãn `quick` không chạy ba lens, simplify hay arm, và không nợ marker nào. Nhãn là của
người cắt ticket, không phải của Thomas.

## Khi một slice đóng, Thomas đọc cả slice một lần nữa

Hai lượt đọc trên base branch: slice arm, và subagent `astra-slice-reviewer` chạy trong worktree
riêng, chỉ đọc, săn giả định ẩn, edge case chưa được chặn và hành vi bị xoá. Lượt này thấy những
mâu thuẫn giữa các ticket mà không review từng ticket nào nhìn thấy. Kết quả được fold và ghi
trên marker `arm(slice):`.

**Cái giá.** Hơn 10 merge kể từ `arm(slice)` cuối là điểm STOP.

## Những gì chưa đo

- **Lens ở scope spec và slice.** Chưa đo; quota Codex hết từ 2026-11-21 tới 2026-11-28.
- **6.1.18 và 6.1.19 trên project thật.** Chưa đo. Sau khoảng 10 ticket mỗi project, arm hoặc lens
  nào không tìm ra defect thật sẽ được đề xuất bỏ.
