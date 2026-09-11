---
title: legacy-testing
oneLiner: "Ghim hành vi hiện tại của code chưa có test, cắt một seam vào nó, rồi mới cho TDD bắt đầu."
group: brownfield
order: 1
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/legacy-testing/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`legacy-testing` là bộ nguyên tắc cho đúng cái ca mà `tdd` không phủ. `tdd` viết một test đỏ
trước, và điều đó giả định có sẵn một **seam**, tức một chỗ để bạn thay thế thứ mà code phụ thuộc
vào.

Code đang tồn tại thường không có chỗ nào như vậy: hàm gọi thẳng tới đồng hồ, tới mạng, tới
database, hoặc tới một singleton ở cấp module. Skill này chốt thứ tự cho ca đó, và thứ tự ấy
ngược với greenfield: characterise xem code đang làm gì, tạo một seam, rồi mới chạy `tdd` bình
thường với các characterisation test làm lưới đỡ bên dưới.
<!-- source: harness/.agents/skills/legacy-testing/SKILL.md -->

Vấn đề nó gỡ là một Builder đứng khựng trên một ticket mà không có gì để viết test đối chiếu, cùng
hai lối thoát sai khỏi cú khựng đó.

- **Lối thứ nhất.** Một characterisation test khẳng định thứ code *đáng lẽ* phải làm: nó đỏ ngay
  ngày đầu và không cho bạn biết thứ nào an toàn để đổi.
- **Lối thứ hai, tệ hơn và im hơn.** Một test lặng lẽ phong một con bug thành chủ ý, và đó chính là
  cách một con bug trở thành một yêu cầu.

Kỷ luật ở đây nằm trong một comment: cứ khẳng định đúng giá trị gây ngạc nhiên đó, rồi đánh dấu nó
là đã ghim nhưng chưa phán kèm một mã ticket, để cả hai cách đọc cùng tồn tại.

Skill này cũng là lý do tôi coi brownfield là mặc định chứ không phải ca đặc biệt. Các agent skill
ở thượng nguồn đều giả định seam có sẵn, còn phần lớn repo đi tới thì không có.
<!-- source: harness/.agents/skills/legacy-testing/SKILL.md, README.md -->

## Khi nào Thomas gọi nó

Thomas hiếm khi gọi thẳng skill này. Đây là **craft do model tự gọi**, chạm tới khi tình huống
xuất hiện, và lúc nhận repo thì không cần đấu dây gì ngoài việc xác nhận nó đã được đặt sẵn.

| Thứ đang ở trước mặt | Gọi cái này |
|---|---|
| Đoạn code dưới một ticket không có seam nào để test xuyên qua | `legacy-testing`, gọi từ chính hợp đồng của Builder |
| Một cái test sẽ đòi cả hệ thống phải boot lên | `legacy-testing`: characterise các đường mà thay đổi chạm tới, seam phần còn lại |
| Một seam quá lớn để tạo bên trong một ticket | Handback cho Thomas, người sẽ định tuyến nó sang một Shaper; `codebase-design` là bộ từ vựng cho cuộc trao đổi đó |
| Bán kính ảnh hưởng phình ra trong lúc bạn đọc | Không phải skill này. `untangle` mới là đường đi khi bản thân mớ rối là vấn đề |
| Một refactor ở nơi module boundary đã có sẵn | `mattpocock-skills:improve-codebase-architecture`, vì skill đó đã có thứ để làm việc cùng |

<!-- source: harness/.agents/roles/builder.md, harness/.agents/roles/shaper.md, harness/.agents/skills/legacy-testing/SKILL.md -->

## Cần sẵn gì

- Dữ liệu coverage, trước khi chọn input. Input cho characterisation được chọn **theo coverage,
  không theo trực giác**: nhắm chúng vào những nhánh mà thay đổi sẽ chạm. Characterise cả một file
  thì hiếm khi đáng, còn characterise những đường mà thay đổi có thể làm hỏng thì luôn đáng.
- Một mã ticket để tham chiếu từ các comment đã ghim, vì một con bug bị ghim là một ticket về sau
  chứ không phải một cú xoá.
- Nhận thức rằng một seam lớn không phải quyết định của Builder. Thêm một tham số vào một hàm là
  việc của Builder. Một interface mới mà vài module sẽ phụ thuộc vào thì đang định hình module
  boundary, và việc đó thuộc về nơi có cả bức tranh trong ngữ cảnh.

<!-- source: harness/.agents/skills/legacy-testing/SKILL.md -->

## Nó để lại gì

| Chuyện gì xảy ra | Nó nằm lại ở đâu |
|---|---|
| Hành vi hiện tại, đã ghim | Các characterisation test, xanh ngay ngày đầu do chính cách dựng, nằm trong cây test của project |
| Một giá trị gây ngạc nhiên mà bạn vẫn khẳng định | Một comment `// CHARACTERISATION:` nói rõ đã ghim gì, rằng nó chưa được phán là đúng, và mã ticket |
| Bản thân cái seam | Một commit **bảo toàn hành vi**, tách rời khỏi mọi thay đổi hành vi |
| Hành vi được đổi dưới lưới đỡ | Các commit mà `tdd` sinh ra sau khi seam đã có |
| Một seam quá lớn cho một ticket | Một cú handback cho Thomas, gọi tên các đường code, chỗ tắc, và cái seam nhỏ nhất bạn nhìn thấy |
| Một characterisation test mà đường của nó giờ đã có test hành vi phủ | Cho nghỉ, và nếu nó đang ghim một con bug thì chuyển thành ticket |

<!-- source: harness/.agents/skills/legacy-testing/SKILL.md -->

## Đang chạy đúng nếu

- Mọi characterisation test đều khẳng định thứ code trả về hôm nay, không phải thứ nó nên trả về,
  và mọi khẳng định gây ngạc nhiên đều mang comment đã ghim nhưng chưa phán kèm một ticket.
- Việc tạo seam và việc đổi hành vi không bao giờ chung một commit. Nếu test vỡ, bạn cần biết chắc
  đó là do cái seam.
- Seam được chọn là cái nhỏ nhất đủ gỡ tắc cho ticket: parameterise trước khi extract interface,
  sprout hay wrap trước khi phá một phụ thuộc tĩnh.
- Một cái seam mà Builder không biện minh được bên trong một ticket đã được báo lên Thomas như một
  kết quả, chứ không bị ép qua dưới áp lực ticket.
- Các characterisation test được cho nghỉ dần khi test hành vi tiếp quản đường của chúng, thay vì
  tích lại thành một bộ test thứ hai tồn tại mãi.

<!-- source: harness/.agents/skills/legacy-testing/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

Chuỗi bên trong một ticket là `characterise` → `seam` → `mattpocock-skills:tdd`, và skill này sở
hữu hai bước đầu. Nó được với tới từ bảng Load của `builder.md`, ở dòng "no seam to test through",
còn đường leo thang của nó đáp xuống bảng Load của `shaper.md`, ở dòng nói về một seam quá lớn để
tạo bên trong một ticket. Dòng đáp đó tồn tại vì một lượt audit đã phát hiện cú leo thang này trỏ
vào một hợp đồng không có dòng nào cho nó. Bên cạnh nó là các câu trả lời brownfield còn lại:
`untangle` khi code rối tới mức không scope nổi một refactor, còn `/skills/bootstrap-glossary` và
`/skills/batch-triage` lo bộ từ vựng và cái backlog mà một repo đi mượn mang theo. Thứ skill này
tạo ra vẫn đi qua đường đóng bình thường: `/skills/review-with-rin` đọc diff,
`/skills/codex-arm` nhận SHA cuối.

<!-- source: harness/.agents/roles/builder.md, harness/.agents/roles/shaper.md, docs/audit/2026-08-26-dissection.md -->
