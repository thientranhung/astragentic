---
title: batch-triage
oneLiner: "Đọc một backlog thừa kế đối chiếu với code trong một lượt, rồi tạo ticket kèm label và quan hệ blocking."
group: entry
order: 2
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/batch-triage/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`batch-triage` là phiên bản một lượt của triage, dành cho backlog có sẵn khi bạn nhận repo.
`mattpocock-skills:triage` của plugin xử lý một item vừa tới; một backlog thừa kế có hình dạng
khác: hàng trăm item không rõ tuổi, do những người đã rời dự án viết, mô tả đoạn code đã dịch
chuyển từ lâu.

Skill này xử lý từng item theo bốn bước:

- **Phân loại** bằng cách đọc chính văn bản của item và đoạn code item gọi tên.
- **Gộp bản trùng** mà cách diễn đạt đang che.
- **Đánh dấu item đã chết.**
- **Tạo ticket trên tracker**, kèm label và quan hệ blocking.

Luật của nó là **rút ra, không bao giờ bịa ra**: mọi lượt phân loại đều trích văn bản của item
hoặc code item gọi tên, và một item không phân loại được từ bằng chứng sẽ rơi vào `NEEDS-OWNER`,
một kết quả hợp lệ tốn đúng một dòng.
<!-- source: harness/.agents/skills/batch-triage/SKILL.md -->

**Một backlog thừa kế không có cạnh thì không có frontier.** Đó là vấn đề skill này xử lý, xuất
hiện ngay khi Thomas nhận một repo mới. Câu truy vấn frontier trả về mọi ticket đã hết
blocker và còn trống assignee, nên trong một backlog không gì chặn gì, mọi ticket đều trông như
sẵn sàng cùng lúc và thứ tự rơi về phỏng đoán.

Skill này còn mang theo một đính chính đo được ngay trong harness này. Trước đây nó yêu cầu
*"the code map"* bằng văn xuôi, và đó là lý do `CODE-MAP.md` tồn tại nhiều tuần như một artifact
mà một lượt grep theo tên file gọi là mồ côi, trong khi một skill đã ship cần nó mỗi lượt chạy. Hiện nó resolve từng item đối chiếu với cây code hiện tại bằng `rg` và `git log` —
điều nó lẽ ra phải nói từ đầu, vì một cái map cũ sẽ sai đúng chỗ triage cần nó nhất: trên đoạn
code đã dời hoặc đã chết.
<!-- source: RELEASE-NOTES.md (Astraler Harness 1.6.1), harness/.agents/memory/recurring-failure-modes.md -->

## Khi nào Thomas gọi nó

| Tình huống trước mặt bạn | Gọi cái nào |
|---|---|
| Một repo bạn đang nhận về đã có sẵn backlog | `batch-triage`, gọi đích danh, một lần cho mỗi repo |
| Một item mới vừa vào inbox | Không phải skill này. `mattpocock-skills:triage` mới là dạng một item một lượt |
| Backlog lớn hơn mức một lượt chạy hết | `batch-triage` chia lô **theo khu vực** và báo lại chỗ đã dừng |
| Một repo trống, chưa có backlog nào | Bỏ qua. Nó đọc thứ chưa tồn tại |
| Tracker và git đã lệch nhau kể từ đó | `reconcile-tracker`, skill đo trạng thái chứ không phân loại item |

<!-- source: harness/.agents/roles/thomas.md, README.md, harness/.agents/skills/batch-triage/SKILL.md -->

## Cần sẵn gì

- `docs/agents/triage-labels.md` tồn tại và được nạp trước tiên. Bộ label thuộc về project, do
  `setup-matt-pocock-skills` tạo ra, nên bịa một bộ từ vựng song song bên trong skill này sẽ tách
  bộ label thành hai bản. <!-- source: harness/.agents/skills/batch-triage/SKILL.md -->
- Cây code hiện tại, không phải một cái map của nó. Phần lớn quyết định triage phụ thuộc vào việc
  đoạn code mà item gọi tên còn tồn tại hay không, nên từng item được resolve bằng `rg` và `git log`
  trên cây ở trạng thái hiện tại. <!-- source: harness/.agents/skills/batch-triage/SKILL.md -->
- Thomas sở hữu skill này như một stage. Đây là skill do người gọi, chạy một lần cho mỗi repo và
  chạy lại khi đã cũ, và kết thúc ở lượt duyệt của chủ project. Một skill do người gọi không tự gọi
  được skill khác, đó là lý do vai này tồn tại. <!-- source: harness/.agents/roles/thomas.md -->
- Có một adapter tracker đang hoạt động, vì các item chưa đóng sẽ trở thành ticket thật. Chọn adapter
  nào (`github-issue-tracker`, `jira-issue-tracker`, `linear-issue-tracker`) không đổi cách phân
  loại, chỉ đổi cách ghi ticket. <!-- source: harness/.agents/roles/thomas.md -->

## Nó để lại gì

| Kết quả | Nơi nó nằm lại |
|---|---|
| Số đếm theo từng nhóm | Bản báo cáo, phát hành trước khi động vào tracker, để chủ project thấy hình dạng backlog vừa thừa kế |
| Các item `STALE` và `DONE` kèm bằng chứng | Chỉ nằm trong báo cáo. **Đóng ticket chờ chủ project quyết định**, vì đóng nhầm một item còn thật là sai lầm đắt nhất ở đây |
| Các nhóm trùng lặp | Bản báo cáo, gộp theo đường code và theo triệu chứng chứ không theo tiêu đề |
| Một item chưa đóng | Một ticket thật trên tracker, gắn label từ bộ từ vựng của project, ước lượng là một ticket hoặc một effort cần `wayfinder` |
| Một phụ thuộc rõ ràng của item này lên item kia | Một cạnh blocking trên tracker, đúng thứ câu truy vấn frontier đọc |
| Một item mà bằng chứng không phân định được | `NEEDS-OWNER` trong báo cáo, một dòng, không đoán |
| Ô assignee của mọi ticket vừa tạo | Để **trống**. Gán assignee là hành động claim, và nó thuộc về Thomas lúc dispatch |

<!-- source: harness/.agents/skills/batch-triage/SKILL.md -->

## Lỗi đã biết

Lấy từ `harness/.agents/memory/recurring-failure-modes.md`.

- **Một map bị gắn nhãn mồ côi nhầm.** Bảy lượt kiểm reachability hỏi xem một thứ có được gọi tên không, một
  đường dẫn có tồn tại không, một địa chỉ có gọi được không. Không lượt nào hỏi có gì đọc thứ mà
  gói này tạo ra hay không. `batch-triage` là ví dụ ngược ngay trong mục đó: nó yêu cầu "the code
  map" bằng văn xuôi, nên một lượt grep theo tên file tuyên bố artifact ấy là mồ côi trong khi một
  skill đã ship cần nó mỗi lượt chạy. **Grep một cái tên không phải là đi tìm người tiêu thụ.** Đã
  sửa: check 8 đòi một dòng trong registry viết tay gọi tên người đọc, và `batch-triage` đọc thẳng
  cây code thay vì đọc một cái map.
- **Một regex rewrite làm hỏng ba đường dẫn.** Đây không phải lỗi của chính skill này, nhưng nó rơi trúng file mà skill
  này nạp đầu tiên: một regex quét cả loạt để viết lại `/triage` đã viết luôn ba đường dẫn
  `docs/agents/triage-labels.md` thành vô nghĩa, vì `\b` khớp ở giữa đường dẫn. Bị bắt nhờ đọc
  diff, không phải nhờ lượt kiểm nào.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Mọi lượt phân loại đều trích văn bản của item hoặc code item gọi tên, và không có gì bị phân loại
  chỉ dựa vào tiêu đề.
- Bản báo cáo số đếm theo nhóm tới tay chủ project **trước** khi bất cứ ticket nào được tạo hay đóng.
- Không item `STALE` hay `DONE` nào bị đóng bởi chính lượt chạy này. Đó là đề xuất đang chờ chủ project.
- Cạnh blocking được đặt ở mọi chỗ một item rõ ràng phụ thuộc vào item khác, vì một cạnh bỏ sót làm
  một ticket trở thành sẵn sàng quá sớm.
- Mọi ticket vừa tạo đều chưa gán ai, và Thomas chạy được câu truy vấn frontier trên kết quả ngay lập tức.

<!-- source: harness/.agents/skills/batch-triage/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

`batch-triage` chạy sớm, bên cạnh stage bootstrap còn lại mà Thomas sở hữu:
`/skills/bootstrap-glossary` gieo bộ từ vựng từ code, còn `batch-triage` đọc backlog đối chiếu với
đúng đoạn code đó. Cả hai đều gọi đích danh, chạy một lần cho mỗi repo, và kết thúc ở lượt duyệt
của chủ project, nên không cái nào biến thành phần việc mà ai cũng tưởng người khác đã chạy.

Kết quả của nó đi thẳng vào câu truy vấn frontier trong `thomas.md`, và đó là chỗ
`/skills/dispatch-ticket` claim. Một item quá lớn cho một ticket thì chuyển sang
`mattpocock-skills:wayfinder` và một session Shaper; một item mới tới sau này thì chuyển sang
`mattpocock-skills:triage`, không quay lại đây.
