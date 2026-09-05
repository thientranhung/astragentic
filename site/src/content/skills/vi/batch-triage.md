---
title: batch-triage
oneLiner: "Đọc một backlog thừa kế đối chiếu với code trong một lượt, rồi để lại ticket có label và quan hệ blocking."
group: entry
order: 2
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/batch-triage/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`batch-triage` là phiên bản một-lượt của triage, dành cho backlog đi kèm sẵn với repo.
`mattpocock-skills:triage` của plugin xử một item vừa tới lúc này. Một backlog thừa kế thì có
hình dạng khác: hàng trăm item không rõ tuổi, viết bởi những người giờ không còn ở đây, nói về
đoạn code đã dịch chuyển từ lâu. Skill này phân loại từng item bằng cách đọc chính chữ của item
và đoạn code nó gọi tên, gộp trùng mà cách diễn đạt đang che, đánh dấu cái đã chết, rồi tạo
ticket trên tracker mang theo label và quan hệ blocking. Luật của nó là **rút ra, không bao giờ
bịa ra**: mọi lượt phân loại đều trích chính chữ của item hoặc code nó gọi tên, và một item không
phân loại được từ bằng chứng thì rơi vào `NEEDS-OWNER`, đó là một kết quả thật và tốn đúng một dòng.
<!-- source: harness/.agents/skills/batch-triage/SKILL.md -->

Rắc rối nó gỡ chính là thứ Thomas đụng ngay ngày đầu ở một repo mới nhận: **một backlog thừa kế
không có cạnh thì không có frontier.** Câu truy vấn frontier là mọi ticket đã hết blocker và còn
trống assignee, nên một backlog mà không gì chặn gì thì mọi ticket trông như sẵn sàng cùng lúc, và
thứ tự rơi về phỏng đoán. Skill này còn mang theo một chỗ đã được đính chính, đo ngay trong harness
này. Trước đây nó xin *"the code map"* bằng văn xuôi, và đó là lý do `CODE-MAP.md` sống được nhiều
tuần như một artifact mà một lượt grep theo tên file gọi là mồ côi, trong khi một skill đã ship cần
nó mỗi lượt chạy (AST-071). Giờ nó resolve từng item đối chiếu với cây code hiện tại bằng `rg` và
`git log` — đó mới là điều lẽ ra nó phải nói, vì một cái map cũ đúng ở chỗ triage cần nó nhất: trên
đoạn code đã dời hoặc đã chết.
<!-- source: RELEASE-NOTES.md (Astraler Harness 1.6.1), harness/.agents/memory/recurring-failure-modes.md -->

## Khi nào Thomas gọi nó

| Trước mặt anh em là gì | Gọi cái nào |
|---|---|
| Một repo anh em đang nhận về có sẵn backlog | `batch-triage`, gọi đích danh, một lần cho mỗi repo |
| Một item mới vừa rơi vào inbox | Không phải cái này. `mattpocock-skills:triage` mới là dáng một-lần-một-cái |
| Backlog lớn hơn mức một lượt chạy hết | `batch-triage` chia lô **theo khu vực**, và báo lại chỗ đã dừng |
| Một repo trống, chưa có backlog nào | Bỏ qua. Nó đọc thứ chưa tồn tại |
| Tracker và git đã lệch nhau từ lúc đó | `reconcile-tracker`, cái đo trạng thái chứ không phân loại item |

<!-- source: harness/.agents/roles/thomas.md, README.md, harness/.agents/skills/batch-triage/SKILL.md -->

## Cần sẵn gì

- `docs/agents/triage-labels.md` tồn tại và được nạp trước tiên. Bộ label là của project, do
  `setup-matt-pocock-skills` tạo ra, và bịa một bộ từ vựng song song bên trong skill này là chẻ đôi
  nó. <!-- source: harness/.agents/skills/batch-triage/SKILL.md -->
- Cây code hiện tại, không phải một cái map của nó. Phần lớn quyết định triage xoay quanh chuyện
  đoạn code mà item gọi tên có còn tồn tại không, nên từng item được resolve bằng `rg` và `git log`
  trên cây như nó đang là. <!-- source: harness/.agents/skills/batch-triage/SKILL.md -->
- Thomas sở hữu cái này như một chặng. Nó là skill do người gọi, chạy một lần cho mỗi repo và chạy
  lại khi cũ, và kết thúc ở lượt duyệt của chủ project — một skill do người gọi thì không với tới
  được skill khác, đó là lý do vai này tồn tại. <!-- source: harness/.agents/roles/thomas.md -->
- Có một adapter tracker đang dùng, vì các item còn sống sẽ thành ticket thật. Cái nào
  (`github-issue-tracker`, `jira-issue-tracker`, `linear-issue-tracker`) không đổi cách phân loại,
  chỉ đổi cách ghi ticket. <!-- source: harness/.agents/roles/thomas.md -->

## Nó để lại gì

| Chuyện gì xảy ra | Nó nằm lại ở đâu |
|---|---|
| Số đếm theo từng lớp | Bản báo cáo, trước khi động vào tracker, để chủ project thấy hình dạng thứ mình vừa thừa kế |
| Các item `STALE` và `DONE` kèm bằng chứng | Chỉ nằm trong báo cáo. **Đóng thì chờ chủ project** — đóng nhầm một thứ còn thật mới là cái sai đắt ở đây |
| Các nhóm trùng lặp | Bản báo cáo, gộp theo đường code và theo triệu chứng chứ không theo tiêu đề |
| Một item còn sống | Một ticket thật trên tracker, gắn label từ bộ từ vựng của project, ước lượng là một ticket hay là một effort cần `wayfinder` |
| Một phụ thuộc rõ ràng của item này lên item kia | Một cạnh blocking trên tracker, đúng thứ câu truy vấn frontier đọc |
| Một item mà bằng chứng không phân định được | `NEEDS-OWNER` trong báo cáo, một dòng, không đoán |
| Ô assignee của mọi ticket vừa tạo | Để **trống**. Gán là cú claim, và nó thuộc về Thomas lúc dispatch |

<!-- source: harness/.agents/skills/batch-triage/SKILL.md -->

## Lỗi đã biết

Lấy từ `harness/.agents/memory/recurring-failure-modes.md`.

- **AST-071** · promoted. Bảy lượt kiểm reachability hỏi xem một thứ có được gọi tên không, một
  đường dẫn có tồn tại không, một địa chỉ có gọi được không — không cái nào hỏi xem có gì đọc thứ
  gói này tạo ra hay không. `batch-triage` là ví dụ ngược ngay trong mục đó: nó xin "the code map"
  bằng văn xuôi, nên một lượt grep theo tên file tuyên bố artifact ấy là mồ côi trong khi một skill
  đã ship cần nó mỗi lượt chạy. **Grep một cái tên không phải là đi tìm một người tiêu thụ.** Đã
  sửa: check 8 đòi một dòng trong registry viết tay có gọi tên người đọc, và `batch-triage` đọc
  thẳng cây code thay vì đọc một cái map.
- **AST-050** · promoted. Không phải lỗi của chính skill này, nhưng nó rơi trúng file mà skill này
  nạp đầu tiên: một regex quét cả loạt để viết lại `/triage` đã viết luôn ba đường dẫn
  `docs/agents/triage-labels.md` thành vô nghĩa, vì `\b` khớp giữa đường dẫn. Bị bắt nhờ đọc diff,
  không phải nhờ lượt kiểm nào.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Mọi lượt phân loại đều trích chính chữ của item hoặc code nó gọi tên, và không có gì bị phân loại
  chỉ dựa vào tiêu đề.
- Bản báo cáo số đếm theo lớp tới tay chủ project **trước** khi bất cứ ticket nào được tạo hay đóng.
- Không item `STALE` hay `DONE` nào bị đóng bởi chính lượt chạy này. Đó là đề xuất đang chờ chủ project.
- Cạnh blocking được đặt ở mọi chỗ một item rõ ràng phụ thuộc vào item khác, vì một cạnh bỏ sót là
  một ticket thành sẵn sàng quá sớm.
- Mọi ticket vừa tạo đều chưa gán ai, và Thomas chạy được câu truy vấn frontier trên kết quả ngay lập tức.

<!-- source: harness/.agents/skills/batch-triage/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

`batch-triage` chạy sớm, bên cạnh chặng bootstrap còn lại mà Thomas sở hữu:
`/skills/bootstrap-glossary` gieo bộ từ vựng từ code, còn `batch-triage` đọc backlog đối chiếu với
đúng đoạn code đó. Cả hai đều gọi đích danh, chạy một lần cho mỗi repo, và kết thúc ở lượt duyệt
của chủ project, nên không cái nào biến thành phần việc mà ai cũng tưởng người khác đã chạy. Thứ nó
tạo ra đi thẳng vào câu truy vấn frontier trong `thomas.md`, và đó là chỗ `/skills/dispatch-ticket`
claim. Một item quá lớn cho một ticket thì đi sang `mattpocock-skills:wayfinder` và một phiên
Shaper; một item mới tới sau này thì đi sang `mattpocock-skills:triage`, không quay lại đây.
