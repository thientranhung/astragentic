---
title: untangle
oneLiner: "Cắt ranh giới vào đống code vốn không có ranh giới nào, mỗi lần một ticket review được."
group: brownfield
order: 2
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/untangle/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`untangle` là đường refactor cho đống code không có ranh giới nào để cải thiện. Skill upstream
`improve-codebase-architecture` cải thiện những ranh giới đã có, nhưng một số repo thì không có
ranh giới nào: một module import ba mươi module khác, chu trình là chuyện thường, và mọi cú tái
cấu trúc tử tế đều là một thay đổi không ai review nổi. Upstream gọi tên khoảng trống đó nhưng
không lấp, nên đây là đường cho nó.

Skill có năm nước đi: đọc đồ thị phụ thuộc thật, cắt ở chỗ đồ thị mỏng nhất, mỗi ticket một ranh
giới theo hình expand-contract, xử lý chu trình bằng một trong ba nhát cắt, và dừng có chủ đích.
<!-- source: harness/.agents/skills/untangle/SKILL.md -->

**Thứ nó chặn là cú refactor big-bang**, tức một branch phình lên hàng tuần, xung đột với tất cả,
rồi bị bỏ hoặc bị merge mà không ai review. Mọi bước tồn tại để giữ công việc ở dạng từng mảnh
ship được, và hai bước trong đó đi ngược bản năng.

- **Bản năng thứ nhất** là xông vào chỗ rối nhất. Skill nói hãy bắt đầu ở một lá, vì một lá có thể
  được cấp ranh giới mà không phải dời gì khác, và nó chứng minh cách làm trên một thứ rẻ.
- **Bản năng thứ hai** là thêm cửa trước mới rồi xoá đường cũ trong cùng một ticket. Skill tách hai
  việc ra, vì một ticket không merge được cho tới khi mọi caller đã chuyển chính là hình big-bang
  tái xuất ở tầng thấp hơn.
<!-- source: harness/.agents/skills/untangle/SKILL.md -->

## Khi nào Thomas gọi nó

Không ai dispatch skill này. Đây là craft do model tự gọi, được chào cho hai role và không thuộc
role nào, nên nó được với tới khi tình huống xuất hiện chứ không nối cứng vào một phase.

| Thứ đang ở trước mặt | Gọi cái này |
|---|---|
| Một thay đổi mà bán kính ảnh hưởng cứ phình ra theo mỗi dòng đọc thêm | `untangle`, cho một Builder đang cố khoanh vùng một cú refactor không chịu khoanh |
| Một đợt việc là cú refactor rối tới mức không khoanh vùng nổi | `untangle`, cho một Shaper, trước khi cắt ticket |
| Ranh giới đã có sẵn và chỉ cần cải thiện | `improve-codebase-architecture`, ở upstream |
| Một ranh giới sắp được vẽ mà bên dưới chưa có lưới test | `legacy-testing`, trước đã |
| Chính việc tách ticket expand-contract | Trả hình dạng đó về, vì `to-tickets` do người dùng gọi và Shaper mới là người lái |

<!-- source: harness/.agents/skills/untangle/SKILL.md, harness/.agents/roles/builder.md, harness/.agents/roles/shaper.md -->

## Cần sẵn gì

- **Đồ thị import được trích ra, không phải nhớ lại.** Một đồ thị bạn trích thắng một đồ thị bạn
  nhớ, và bất ngờ thường nằm ở chỗ module nào mới là hub thật.
- **Hành vi đi ngang ranh giới được đặc tả trước**, qua `legacy-testing`, để cú refactor có lưới.
- **Một mặt ticket đủ chỗ cho mỗi ticket một ranh giới**, vì cả phương pháp là một ranh giới một
  ticket.
- **Một chỗ để ghi ghi chú kiến trúc.** Skill này nêu thẳng `docs/agents/boundaries.md`, và lý do
  nó nêu hẳn một đường dẫn nằm ngay bên dưới.

## Nó để lại gì

| Chuyện gì đã xảy ra | Nó nằm lại ở đâu |
|---|---|
| Đồ thị đã đo | Chu trình, hub, lá và các cú gọi xuyên qua, được gọi tên chứ không phải đoán |
| Mỗi ranh giới | Một ticket tự ship được: đặc tả, expand, chuyển caller, contract |
| Đường đi cũ | Gỡ ở một ticket sau, kiểm bằng tìm kiếm chứ không bằng niềm tin |
| Thứ tự công việc | Suy ra từ đồ thị, và đó là thứ khiến nó cãi được trong lúc review |
| Ranh giới đã vẽ và đường nối cố tình để lại | `docs/agents/boundaries.md`, do Shaper đọc khi khoanh vùng cú refactor kế tiếp trên cùng đống code |

<!-- source: harness/.agents/skills/untangle/SKILL.md -->

## Lỗi đã biết

Có một entry trong `harness/.agents/memory/recurring-failure-modes.md` gọi tên skill này. Nó ở
trạng thái `promoted`.

- **AST-051**: một địa chỉ mà người gọi không dùng được thì sinh ra một thứ thay thế, không sinh
  ra lỗi. Một hợp đồng gọi tên một lượt chạy bằng lệnh slash, vốn là dạng *con người* gõ, và một
  agent không có bàn phím thì không gọi được. Hệ quả là hai Builder mỗi người tự làm một cú dọn
  dẹp thủ công, cả hai lần handback đều mô tả trung thực một lượt chạy có thật, và skill thật bắn
  lại sau đó trên cùng diff tìm ra một chỗ tách mà cả hai đều bỏ sót. Luật chung: một địa chỉ chỉ
  đúng tương đối với người phải dùng nó. Skill này mang luật đó ở bước expand-contract, chỗ trỏ
  sang `to-tickets`, vốn do người dùng gọi nên model không tự với tới được.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Nhát cắt đầu tiên rơi vào một lá, gọn trong một thay đổi review được, trước khi động tới thứ gì
  khó hơn.
- Mỗi ticket vẽ đúng một ranh giới, và expand với contract nằm ở hai ticket khác nhau ở mọi chỗ
  mà việc chuyển caller là lớn.
- Mọi chu trình đều bị cắt bằng một trong ba nước đi đã nêu, và một cú gộp trông như đi lùi thì
  mang theo lý lẽ của nó ngay trong ticket.
- Công việc dừng khi những ranh giới mà việc hiện tại cần đã có, không phải khi đồ thị trở nên
  đẹp.
- `docs/agents/boundaries.md` tồn tại và nêu cả thứ đã vẽ lẫn thứ cố tình để lại.

<!-- source: harness/.agents/skills/untangle/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

Một Builder hoặc Shaper đâm vào cú refactor không chịu khoanh vùng → `untangle` trích đồ thị và
chọn nhát cắt mỏng nhất → `legacy-testing` đặt lưới dưới ranh giới sắp vẽ → hình dạng đó quay về
Shaper, người lái `to-tickets` → mỗi ticket chạy vòng bình thường qua `dispatch-ticket` → các ranh
giới đọng lại trong `docs/agents/boundaries.md` cho lượt sau. Skill dừng và mang việc lên chủ dự
án khi đồ thị cho thấy kiến trúc dự định còn code thì nói khác, vì đó là một quyết định chứ không
phải một cú refactor.
