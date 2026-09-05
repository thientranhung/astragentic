---
title: github-issue-tracker
oneLiner: "Chạy GitHub Issues làm tracker của harness, với trạng thái ở label và board là bản sao phải ghi tay."
group: adapter
order: 4
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/github-issue-tracker/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`github-issue-tracker` là một trong ba adapter tracker. `.agents/tracker-contract.md` nêu đúng
năm thứ mà pipeline đòi ở *bất kỳ* tracker nào, không hơn. File này là phần cách làm cho một
trong ba: trạng thái nằm ở label, cách claim, quan hệ phụ thuộc gốc, vòng lặp tính frontier, và
bản sao Status trên Projects. Phần thuộc dự án ở lại trong dự án: `<owner>/<repo>`, tiền tố
ticket và bảng ánh xạ label sang cột đều nằm trong `docs/agents/issue-tracker.md` của dự án đó.
Tôi truy cập tracker bằng `gh` CLI thay vì MCP server, vì `gh` đã xác thực sẵn ở nơi pull request
đang được đẩy lên.
<!-- source: harness/.agents/skills/github-issue-tracker/SKILL.md -->

Một sự thật quyết định mọi thứ còn lại: **GitHub Issues không có trường trạng thái.** Trạng thái
sống ở hai nơi không đồng bộ với nhau. Label là sự thật, còn cột `Status` trên Project là bản sao
phải có người ghi. GitHub không đồng bộ hai nơi đó, nên mỗi lần đổi trạng thái là hai lần ghi,
vĩnh viễn. Đó là chi phí thường trực của cái tracker rẻ nhất để bắt đầu. Mọi cái bẫy trên trang
này đều đã bị trả giá trên một dự án thật chuyển từ Linear sang GitHub ngày 2026-08-21.
<!-- source: harness/.agents/skills/github-issue-tracker/SKILL.md, harness/.agents/tracker-contract.md -->

## Khi nào Thomas gọi nó

| Thứ đang ở trước mặt | Gọi cái này |
|---|---|
| `issue-tracker.md` của dự án ghi GitHub | `Skill(skill: "github-issue-tracker")`, và không adapter nào khác |
| Đang chọn tracker, hoặc đang chuyển từ tracker này sang tracker khác | `.agents/tracker-contract.md` |
| Một lần đổi trạng thái | Hai lần ghi: label trước, rồi `project-status-sync.sh` cho board |
| Cần thêm một cạnh chặn | Lấy **database id** dạng số của ticket chặn, không phải `#number` và không phải node id |
| Tracker đang nói khác git | `reconcile-tracker` |

<!-- source: harness/.agents/skills/github-issue-tracker/SKILL.md -->

## Cần sẵn gì

- **`gh` có scope OAuth `project`**, vốn không nằm trong tập mặc định. Thiếu scope này,
  `--json projectItems` trả về `[]` chứ không báo lỗi, và kết quả đó không phân biệt được với
  "issue này không nằm trên board nào". Chủ dự án chạy `gh auth refresh -s project` một lần.
- **`issue-tracker.md` của dự án có tồn tại** và mang repo, tiền tố ticket, bảng ánh xạ label
  sang cột, tên tracker cũ, và quyết định coi pull request là mặt tiếp nhận yêu cầu.
- **Đúng một trong `backlog` / `todo` / `in-progress`** trên mọi issue đang mở, nên đổi trạng
  thái là một lần gỡ cộng một lần thêm.
- **`GH_PROJECT_OWNER` và `GH_PROJECT_NUMBER` đã đặt** cho `project-status-sync.sh`, vì script
  này từ chối đoán cả hai giá trị.

## Nó để lại gì

| Chuyện gì đã xảy ra | Nó nằm lại ở đâu |
|---|---|
| Cú claim | `--add-assignee @me`, ghi trước khi worktree tồn tại |
| Danh tính Builder | `.astraler/state/dispatch-record.json`, vì không trường nào của GitHub giữ được `builder/<ticket-id>` |
| Mã ticket ổn định | Token `<PREFIX>-<n>` mở đầu tiêu đề issue, thứ giữ cho mọi trích dẫn còn resolve được |
| Đồ thị chặn | Dependencies và sub-issues gốc của GitHub, cả hai đều hiện trên UI, cả hai đều khoá theo database id |
| Cái chủ dự án nhìn thấy | Cột `Status` trên Project, do `project-status-sync.sh` ghi, mặc định chỉ đọc và cần `--apply` mới ghi |

<!-- source: harness/.agents/skills/github-issue-tracker/SKILL.md -->

## Lỗi đã biết

Lấy từ `harness/.agents/memory/recurring-failure-modes.md`. Cả hai đều `promoted`.

- **AST-057**: một frontier chỉ được tính ra thì vô hình với đúng người không tính được nó. Agent
  chạy lại truy vấn bất cứ lúc nào và không bao giờ nhận ra thiếu thứ gì, còn chủ dự án thì mở
  board ra nhìn. Đo trên một dự án thật: suốt cả đời dự án, không một issue nào từng đi qua trạng
  thái chưa bắt đầu. Hợp đồng sửa việc này bằng hai nửa. Nửa thứ nhất: ghi kết quả tính được trở
  lại thành trạng thái. Nửa thứ hai: không bao giờ đọc một label "sẵn sàng" như một cái chặn.
  Kèm theo là một bước ở merge bắt buộc phải báo cáo, trong đó `none` là báo cáo hợp lệ còn im
  lặng thì không.
- **AST-074**: một tracker chỉ được đo bằng chính nó thì không phát hiện được nó đang trôi. Bốn
  ticket nằm nguyên trạng thái đã claim, đang làm, có người nhận, sau khi code của chúng đã merge
  vào nhánh gốc, cái cũ nhất trễ trọn một ngày, và không có gì báo lỗi. Một trạng thái sai vẫn
  hoàn toàn nhất quán với chính nó, nên oracle phải độc lập với thứ nó đo. Bản sửa là
  `reconcile-tracker` cộng `scripts/ticket-git-facts.sh`, chỉ đọc theo một phán quyết được ghi
  lại chứ không phải do bỏ sót.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- `gh auth status` có liệt kê `project`, kiểm trước khi tin bất kỳ kết quả rỗng nào từ truy vấn
  board.
- Mọi lần ghi label đều đi kèm một lần ghi board trong cùng hành động.
- Cạnh chặn được đọc lại qua `.../dependencies/blocked_by`, không bao giờ qua
  `issue_dependencies_summary`, vốn trễ khoảng hai giây sau một lần ghi.
- Mọi phần thân issue đều tạo bằng `--body-file`, không bao giờ bằng `--body`.
- Mã ticket trong tiêu đề là định danh mà mọi trích dẫn dùng, và số issue của GitHub không bao
  giờ được coi là thứ thay thế cho nó.

<!-- source: harness/.agents/skills/github-issue-tracker/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

`thomas.md` đọc `issue-tracker.md` của dự án lúc mở phiên → file đó gọi tên adapter này → truy
vấn frontier chạy dưới dạng một lệnh liệt kê cộng một vòng lặp N+1, vì GitHub không có ngôn ngữ
truy vấn → `dispatch-ticket` claim ticket thắng cuộc bằng `--add-assignee @me` → merge đóng issue
và ghi `todo` cho thứ nó vừa mở khoá, trong cùng một lượt → `reconcile-tracker` đem kết quả ra đo
với git. Hai adapter cùng nhóm là `jira-issue-tracker` và `linear-issue-tracker`, và
`.agents/tracker-contract.md` đứng trên cả ba.
