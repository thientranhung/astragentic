---
title: jira-issue-tracker
oneLiner: "Chạy Jira làm tracker của harness, nơi một trạng thái là một transition đánh số phải đọc trước khi lấy."
group: adapter
order: 5
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/jira-issue-tracker/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`jira-issue-tracker` là một trong ba adapter tracker. `.agents/tracker-contract.md` nêu năm thứ
pipeline đòi ở bất kỳ tracker nào; file này là phần CÁCH LÀM cho Jira — trạng thái dưới dạng
transition, hai toạ độ mà một phiên không tự tìm ra được, các issue link và hướng của chúng dễ
bị đảo ngược, chuyện ghi đè trọn trường description, và những thứ chỉ con người mới đổi được.
Phần thuộc dự án ở lại trong dự án: site, `cloudId`, project key và bảng transition id đều nằm
trong `docs/agents/issue-tracker.md` của dự án đó. Chạm vào Jira qua bộ công cụ MCP của
Atlassian. Mọi thứ ở đây đo trên một dự án thật, kiểu team-managed, chuyển từ Linear sang Jira
ngày 2026-08-21.
<!-- source: harness/.agents/skills/jira-issue-tracker/SKILL.md -->

Khác biệt lớn nhất so với mọi tracker khác là **bạn không gán một trạng thái, bạn lấy một
transition** — và transition được định danh bằng số, riêng theo từng dự án, không liên tục và
không đoán được, với những trạng thái thêm sau lại mang id thấp. Nên một transition id nhớ trong
đầu là một lệnh ghi hợp lệ vào trạng thái bạn không định ghi: nó thành công, không có lỗi nào,
và không truy vấn nào đánh dấu. Đọc danh sách transition mỗi lần; chính cú gọi thêm đó *là* cái
chốt, và nó rẻ hơn nhóm lỗi mà nó chặn. Bù lại, lợi thế của Jira là thật: `Blocks` biểu diễn
được trong một truy vấn JQL, nên frontier là một cú gọi thay vì vòng lặp N+1 mà GitHub ép.
<!-- source: harness/.agents/skills/jira-issue-tracker/SKILL.md -->

## Khi nào Thomas gọi nó

| Thứ đang ở trước mặt | Gọi cái này |
|---|---|
| `issue-tracker.md` của dự án ghi Jira | `Skill(skill: "jira-issue-tracker")`, và chỉ mình nó |
| Một lần đổi trạng thái | `getTransitionsForJiraIssue`, rồi `transitionJiraIssue` với id lấy từ *chính* phản hồi đó |
| Một description cần vá | Đọc nó, thay chỗ cần thay, gửi lại trọn trường — không có cập nhật từng phần |
| Một trạng thái dự án chưa có | Dừng; thêm trạng thái là việc của chủ dự án trên giao diện Jira, công cụ MCP không chạm được vào workflow |
| Một ticket trùng | Một link `Duplicate` cộng trạng thái đã huỷ, không bao giờ là một trạng thái riêng |

<!-- source: harness/.agents/skills/jira-issue-tracker/SKILL.md -->

## Cần sẵn gì

- **`cloudId` đã được ghi lại.** Nó không xuất hiện trong bất kỳ URL nào người ta dán, nên thiếu
  nó thì mỗi phiên đều mở đầu bằng việc đi săn nó qua `getAccessibleAtlassianResources`.
- **Project key được đặt trong dấu nháy khi viết JQL.** Một key trùng từ khoá JQL làm
  `project = <KEY>` không parse được, và thông báo lỗi không hề nói là phải nháy.
- **Bạn biết dự án là team-managed hay company-managed**, vì điều đó quyết định các trạng thái
  *chính là* board hay chỉ ánh xạ sang board.
- **accountId dùng để claim đã được resolve một lần** bằng `lookupJiraAccountId`, rồi ghi vào
  `issue-tracker.md` của dự án.

## Nó để lại gì

| Chuyện gì đã xảy ra | Nó nằm lại ở đâu |
|---|---|
| Cú claim | Trường `assignee`, đặt bằng accountId của chính bạn |
| Danh tính Builder | `.astraler/state/dispatch-record.json`, vì `assignee` nhận accountId và không giữ được `builder/<ticket-id>` |
| Frontier | Một truy vấn JQL duy nhất: chưa ai nhận, chưa xong, trừ đi những ticket còn link `is blocked by` chưa đóng |
| Đồ thị chặn | Issue link gốc của Jira, mà thứ cần đọc lại là dòng chữ nó hiển thị ra |
| Nguồn gốc di trú | Một label provenance và một dòng đầu description trỏ ngược về, không bao giờ được xoá cái nào |

<!-- source: harness/.agents/skills/jira-issue-tracker/SKILL.md -->

## Lỗi đã biết

Lấy từ `harness/.agents/memory/recurring-failure-modes.md`. Cả hai đều `promoted`.

- **AST-057**: một frontier chỉ được tính ra thì vô hình với đúng người không tính được nó.
  Trạng thái sẵn-sàng tồn tại cho con người, và một agent sẽ không nhận ra nó thiếu, vì agent tự
  suy lại độ sẵn sàng bất cứ lúc nào. Đã sửa trong hợp đồng: ghi kết quả tính được trở lại thành
  trạng thái, ngay trong hành động đóng cái chặn cuối cùng, và không bao giờ đọc một label
  "sẵn sàng" như một cái chặn. Sẵn sàng mà vẫn còn link `is blocked by` đang mở là một mâu thuẫn,
  nên kéo ticket lùi lại ngay trong hơi thở thêm cái link đó.
- **AST-074**: một tracker chỉ được đo bằng chính nó thì không phát hiện được nó đang trôi — bốn
  ticket vẫn đã claim và đang làm sau khi code đã merge, không có gì báo lỗi, và độ trôi nằm
  trong *nội dung* của tracker, chỗ mà không lớp kiểm reachability nào nhìn tới. Đã sửa:
  `reconcile-tracker` đem tracker ra đo với git, và nó chỉ-đọc theo một phán quyết được ghi lại,
  vì khoá nối là mã ticket trong tiêu đề commit, mà một lần nhắc tới thì không phải một lần làm
  xong.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Mọi transition id đều đến từ một `getTransitionsForJiraIssue` vừa gọi, không từ bảng và không
  từ trí nhớ.
- Mọi link mới đều được kiểm bằng cách đọc lại **dòng chữ hiển thị**, để một `Blocks` ngược
  hướng không thể lặng lẽ phá frontier.
- Không description nào bị gõ lại từ trí nhớ, và mọi payload JSON đều dựng bằng chương trình.
- Link `Relates` bị để ngoài; một câu nhắc trong phần thân mang đúng lượng thông tin đó ở chỗ
  đọc được.
- Một cái chặn không phải issue thì được cấp một issue — một ticket quyết định là ticket hạng
  nhất, không bao giờ giao cho agent, và nó đóng khi chủ dự án trả lời.

<!-- source: harness/.agents/skills/jira-issue-tracker/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

`thomas.md` đọc `issue-tracker.md` của dự án lúc mở phiên → file đó gọi tên adapter này →
frontier là một truy vấn JQL → `dispatch-ticket` claim ticket thắng cuộc bằng cách đặt assignee,
rồi git quyết mọi cuộc đua trong cùng một giây → merge lấy transition sang Done và kéo thứ nó
vừa mở khoá sang trạng thái sẵn-sàng → `reconcile-tracker` đem kết quả ra đo với git. Hai adapter
anh em là `github-issue-tracker` và `linear-issue-tracker`, và `.agents/tracker-contract.md`
đứng trên cả ba.
