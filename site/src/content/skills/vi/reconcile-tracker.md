---
title: reconcile-tracker
oneLiner: "Đo tracker đối chiếu với git rồi báo chỗ nào hai bên nói khác nhau."
group: upkeep
order: 1
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/reconcile-tracker/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`reconcile-tracker` kéo về hai sự thật độc lập rồi so chúng: tracker nói trạng thái một ticket là
gì, và git thật sự cho thấy chuyện gì đã xảy ra với nó. Nửa phần git đến từ
`scripts/ticket-git-facts.sh` (shell thuần, không mạng, không gọi tracker), script này đếm số
commit trên base branch có subject khớp một ticket id, tìm branch local nếu còn, và báo số commit
chưa merge. Nửa phần tracker đến từ công cụ đọc mà tracker của project đó cung cấp. Thomas nối hai
hàng bằng tay, vì cú nối đó cần phán đoán mà script không cấp được, rồi báo bốn lớp lệch: lagging
(đã merge nhưng tracker không hay), phantom done (tracker bảo đã ship, git không thấy gì), stale
claim (có assignee nhưng phía sau không có branch nào), và unclaimed in-progress (ticket kẹt ở
trạng thái đang làm mà không ai giữ). Nó không bao giờ ghi vào tracker; nó chỉ báo.
<!-- source: harness/.agents/skills/reconcile-tracker/SKILL.md -->

Thứ skill này được dựng lên để chống là một kiểu hỏng rất cụ thể: một tracker chỉ được kiểm đối
chiếu với chính nó. In-progress kèm một assignee đang sống trông y hệt nhau, dù ticket thật sự
đang chạy hay dù cú merge kết thúc nó chỉ đơn giản là không bao giờ được ghi ngược lại. Trạng
thái tự nó nhất quán trong cả hai trường hợp, nên riêng cái tracker không nói được anh em đang
nhìn cái nào. Git là nguồn thứ hai, độc lập, để phá thế hoà, y như giá trị kỳ vọng của một cái
test phải sống bên ngoài đoạn code mà nó kiểm. Skill này tồn tại vì một project thật đã đo trực
tiếp: bốn ticket nằm in-progress với assignee đang sống sau khi code của chúng đã merge, cái cũ
nhất trễ tròn một ngày, và không có gì trong đường ống báo lỗi để nói ra chuyện đó.
<!-- source: harness/.agents/skills/reconcile-tracker/SKILL.md -->

## Khi nào Thomas gọi nó

| Trước mặt anh em là gì | Gọi cái nào |
|---|---|
| Một cú merge vừa vào | Chạy ngay: đây chính là chỗ độ lệch sinh ra, và bước merge vốn đã bắt chạy lại frontier và báo cái gì đã đổi |
| Một phiên mới đang bắt đầu | Chạy nó để bắt bất cứ thứ gì phiên trước bỏ dở giữa chừng lúc dispatch |
| Chủ project hỏi "tracker có đúng không?" | Chạy nó. Câu trả lời phải được đo, không bao giờ được nhớ lại |
<!-- source: harness/.agents/skills/reconcile-tracker/SKILL.md -->

## Cần sẵn gì

`TICKET_PREFIX` phải được set. Nó không có giá trị mặc định, và một lượt quét trần `[A-Z]+-[0-9]+`
sẽ vơ luôn cả ADR id và spec id cùng với ticket thật. Đọc nó từ chỉ dẫn đầu phiên của project
(`AGENTS.md` / `CLAUDE.md`); giá trị chưa set là một điểm dừng, không phải chỗ để đoán. Kéo ticket
id từ tracker trước rồi truyền tường minh cho script. Dạng trần của `ticket-git-facts.sh` suy ra
danh sách của nó từ các subject đã nằm trên base branch, nên một ticket chưa từng merge sẽ không
xuất hiện chút nào, mà đúng những ticket đang bay đó mới là thứ lớp stale-claim cần kiểm. Adapter
tracker nào đang dùng (`github-issue-tracker`, `jira-issue-tracker`, hay `linear-issue-tracker`)
quyết định cách đọc nửa phần tracker, nhưng bản thân `reconcile-tracker` không phụ thuộc tracker;
nó chỉ cần `id`, `status` và `assignee`.
<!-- source: harness/.agents/skills/reconcile-tracker/SKILL.md -->

## Lỗi đã biết

- **AST-074**: một tracker chỉ được đo đối chiếu với chính nó thì không tự phát hiện được độ lệch
  của mình. Bốn ticket nằm in-progress với assignee đang sống sau khi code của chúng đã merge, và
  không gì báo lỗi, vì in-progress-kèm-assignee không phân biệt được với một ticket đang bay thật
  nếu thiếu nguồn thứ hai. Đã sửa: bản vá được ship chính là `reconcile-tracker` cộng
  `ticket-git-facts.sh`, cố ý để chỉ-đọc, để một tracker sai-nhưng-gọn không bao giờ bị đánh dấu
  done dựa trên một khoá nối mờ. <!-- source: harness/.agents/memory/recurring-failure-modes.md -->
- **AST-127**: ví dụ chạy được ngay trong chính tài liệu của skill này gọi `ticket-git-facts.sh`
  mà không có `TICKET_PREFIX` rồi dán nhãn "LUÔN dùng dạng này", nằm tám dòng phía trên câu nói
  rằng biến đó là bắt buộc, tức một lệnh mà chính script sẽ từ chối. Đã sửa 2026-08-20; một ghi
  chú trước đó đổ lỗi cho một project đi mượn vì đã chép lại ví dụ hỏng thì bản thân nó cũng sai,
  và đã được đính chính ngay trong cùng mục đó.
  <!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Mọi lượt chạy đều nói ra `TICKET_PREFIX` một cách tường minh thay vì lùi về một phỏng đoán.
- Ticket id từ tracker được kéo về trước khi `ticket-git-facts.sh` chạy, không phải sau.
- Cả bốn lớp lệch đều được báo, kể cả `none` cho những lớp rỗng. Một lớp không được báo đọc ra y
  hệt một lớp không được kiểm.
- Một ticket đang bay khoẻ mạnh (có commit chưa merge, có branch sống, có worktree) không bao giờ
  bị gắn cờ là lệch.
- Không có gì được ghi vào tracker như hệ quả của chính lượt chạy này; mọi bản vá là một hành động
  riêng, làm sau, do Thomas làm tay.
<!-- source: harness/.agents/skills/reconcile-tracker/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

`dispatch-ticket` claim một ticket rồi giao cho Builder → bước merge chạy lại frontier và ghi
ngược cái gì đã đổi → `reconcile-tracker` kiểm, ngay sau cú merge đó và lần nữa lúc đầu phiên, xem
cú ghi ngược có thật sự xảy ra không. Tracker nào đang được đọc (`github-issue-tracker`,
`jira-issue-tracker`, hay `linear-issue-tracker`) cấp phần CÁCH LÀM cho đúng một sản phẩm cụ thể;
`reconcile-tracker` là lượt kiểm chạy y như nhau bất kể cái nào đang dùng. Chỗ nào nó tìm ra
phantom-done hay một claim cũ, chỗ đó thành bản vá của chính Thomas, làm tay, nằm ngoài lượt chạy
của skill.
