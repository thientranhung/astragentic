---
title: linear-issue-tracker
oneLiner: "Chạy Linear làm tracker của harness, và kiểm trần issue của gói đang dùng trước khi dựng pipeline."
group: adapter
order: 6
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/linear-issue-tracker/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`linear-issue-tracker` là một trong ba adapter tracker. `.agents/tracker-contract.md` nêu năm thứ
pipeline đòi ở bất kỳ tracker nào, còn file này là phần cách làm cho Linear. Đây là adapter mỏng
nhất, và lý do là một lời khen cho sản phẩm: workflow state gốc, một trường trạng thái thật, một
board đi theo trạng thái đó mà không cần ghi lần hai, quan hệ gốc, assignee gốc. Cả năm yêu cầu
đều được đáp ứng, nên phần lớn thứ mà hai adapter kia phải viết dài ở đây không tồn tại. Tôi truy
cập Linear qua bộ công cụ MCP `linear-server` chứ không qua CLI. Mọi số liệu ở đây đo trên một dự
án thật chạy Linear tới 2026-08-21.
<!-- source: harness/.agents/skills/linear-issue-tracker/SKILL.md -->

Có hai thứ nên biết trước khi chọn Linear, và thứ nhất không liên quan tới mô hình dữ liệu. **Gói
free ngừng nhận issue mới.** `save_issue` trả về *"You've exceeded the free issue limit"*. Lỗi đó
không làm pipeline yếu đi, nó làm pipeline dừng, vì bước đầu tiên của phương pháp là `create`.
Một dự án đâm vào đúng chỗ này và phải di trú ngay trong ngày. Yêu cầu 1 tới 5 nói về *mô hình*
của một tracker, nhưng một tracker còn phải chịu nhận lệnh ghi, nên hãy kiểm trần của gói đang
dùng trước. Thứ hai là giao thức claim, ở đây yếu hơn mức phương pháp giả định, và git mới là thứ
gánh nó.
<!-- source: harness/.agents/skills/linear-issue-tracker/SKILL.md -->

## Khi nào Thomas gọi nó

| Thứ đang ở trước mặt | Gọi cái này |
|---|---|
| `issue-tracker.md` của dự án ghi Linear | `Skill(skill: "linear-issue-tracker")`, và không adapter nào khác |
| Tạo, đọc, gắn label, nối quan hệ hoặc đóng | `save_issue`, gần như là toàn bộ bề mặt |
| Một tài liệu bản đồ cho một đợt việc | `save_document` trên Linear project, một nguyên thuỷ hạng nhất chứ không phải cách lách của GitHub |
| Một ticket đọc ra là sẵn sàng trong khi epic cha của nó đang bị chặn | Lọc thêm theo trạng thái cha, vì chặn không di truyền xuống con |
| Tìm trong các issue của chính bạn | `list_issues` kèm `query`; `search_documentation` là tài liệu sản phẩm của Linear |

<!-- source: harness/.agents/skills/linear-issue-tracker/SKILL.md -->

## Cần sẵn gì

- **Gói đang dùng còn nhận lệnh ghi.** Kiểm trần issue trước khi pipeline phụ thuộc vào `create`.
- **`issue-tracker.md` của dự án mang** workspace, tên và key của team, tên và id của project,
  tiền tố ticket, mọi chỗ nhập nhằng về mã do lịch sử để lại, và **có những seat nào**, vì giao
  thức claim phụ thuộc vào đó.
- **Bộ trạng thái đã ánh xạ sang ngôn ngữ của phương pháp**: mở là mọi thứ không phải `Done`,
  `Canceled` hay `Duplicate`; đang chạy là `In Progress` hoặc `In Review`.
- **`Todo` được coi là trạng thái phải ghi**, không phải trạng thái tự nhiên sẽ tới.

## Nó để lại gì

| Chuyện gì đã xảy ra | Nó nằm lại ở đâu |
|---|---|
| Cú claim | `assignee: "me"` cộng trạng thái `In Progress`, là lệnh ghi đầu tiên của session |
| Danh tính Builder | Bản ghi dispatch và một comment, vì `assignee` chỉ trỏ tới một thành viên thật trong workspace |
| Frontier, đã thành hình | Trạng thái `Todo`, ghi vào lúc cái chặn cuối cùng đóng lại |
| Đồ thị chặn | Quan hệ gốc, qua trường `blockedBy` của `save_issue` |
| Bản đồ của đợt việc | Một document trên Linear project chứa Notes, Decisions-so-far và Fog, mỗi đợt việc một cái |

<!-- source: harness/.agents/skills/linear-issue-tracker/SKILL.md -->

## Lỗi đã biết

Lấy từ `harness/.agents/memory/recurring-failure-modes.md`. Cả hai đều `promoted`.

- **AST-057**: một frontier chỉ được tính ra thì vô hình với đúng người không tính được nó. Đo
  trên chính workspace này: **không một issue nào từng đi vào `Todo`**, và một ticket nằm lại
  `Backlog` hàng giờ sau khi cả hai cái chặn của nó đã merge. Nguyên nhân gốc nằm ở một skill của
  plugin: nó ghi một *label* sẵn sàng lúc tạo ticket rồi không bao giờ quay lại, nên hai cách
  biểu diễn độ sẵn sàng nằm cạnh nhau mà không cách nào trả lời được câu hỏi của người dispatch.
  Hợp đồng sửa việc này bằng cách ghi kết quả tính được trở lại thành trạng thái, và không bao
  giờ đọc một label sẵn sàng như một cái chặn.
- **AST-074**: đẩy ticket lên frontier chỉ dựa vào cạnh chặn thì bao quá rộng. Điều đó đo lại
  được trên Linear khi ba ticket nổi lên như claim được ngay giữa một phase trước đó, vì một
  sub-issue không có cái chặn nào đọc ra là sẵn sàng ngay cả khi epic cha của nó đang bị chặn.
  Bản sửa giữ việc đẩy lên frontier làm phán đoán của người điều phối, ghi thẳng trong
  `thomas.md`, chứ không phải kết quả của một truy vấn.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Một ticket đi vào `Todo` ngay trong hành động đóng cái chặn cuối cùng của nó, thay vì nhảy
  thẳng từ `Backlog` sang `In Progress`.
- Mọi cái chặn vô hình, dù là một lần deploy, một credential hay một quyết định, đều được cấp một
  issue và một cạnh, vì một cái chặn không phải issue thì vô hình và đồ thị sẽ nói dối rất tự tin.
- Cú claim được nhả ra bằng cách xác nhận branch và worktree đã biến mất, không phải bằng cách
  đọc lại assignee, vì đọc lại không cho biết đó là claim của ai.
- Trạng thái của ticket cha nằm trong bộ lọc sẵn sàng, không chỉ mỗi `blockedBy`.
- Không ai coi `list_agent_skills` là ghi được, vì kệ skill đó do chủ workspace soạn trên chính
  giao diện Linear.

<!-- source: harness/.agents/skills/linear-issue-tracker/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

`thomas.md` đọc `issue-tracker.md` của dự án lúc mở session → file đó gọi tên adapter này →
frontier là `list_issues` với điều kiện chưa ai nhận, trạng thái chưa kết thúc và không còn
`blockedBy` nào dang dở → `dispatch-ticket` claim ticket thắng cuộc bằng `assignee: "me"`, và
`git worktree add -b` quyết mọi cuộc đua trong cùng một giây → merge kéo ticket sang `Done` và
kéo ticket nó vừa mở khoá sang `Todo` → `reconcile-tracker` đem kết quả ra đo với git. Hai adapter
cùng nhóm là `github-issue-tracker` và `jira-issue-tracker`, và `.agents/tracker-contract.md`
áp dụng cho cả ba.
