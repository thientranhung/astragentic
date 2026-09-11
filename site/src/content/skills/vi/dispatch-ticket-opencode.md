---
title: dispatch-ticket-opencode
oneLiner: "Launch pane OpenCode và báo rõ bước kiểm nào của giao thức chung bị suy giảm trên runtime này."
group: adapter
order: 3
runtimes: [opencode]
source: harness/.agents/skills/dispatch-ticket-opencode/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`dispatch-ticket-opencode` là nửa OpenCode của `dispatch-ticket`. Skill dùng chung giữ phần định
danh, chốt input, luật worktree, khuôn brief, cách gửi, cách canh, simplify và dọn dẹp. Adapter
này thêm bảng lệnh launch, bước kiểm adapter và sáu sự thật đã đo được của runtime. Chỉ hai
trong sáu là tiện ích. Bốn cái còn lại là giới hạn, và tôi ghi chúng đúng như giới hạn thay vì
tìm đường đi vòng.
<!-- source: harness/.agents/skills/dispatch-ticket-opencode/SKILL.md -->

Sự thật quyết định cả trang này là **`idle` của OpenCode là một giá trị bịa.** `herdr agent
explain` báo `fallback_reason: default_known_agent_idle_fallback`, và `agent wait --until idle`
trả về rc=0 sau 8 ms trên một pane không ai đụng vào.

Manifest của OpenCode có ba luật, so với mười hai của Claude và bảy của Codex, và chỉ phủ
`blocked` với `working`. Vì vậy idle không phải thứ được phát hiện, nó là phần còn lại khi không
luật nào khớp.

- **Hệ quả thứ nhất.** Bộ chặn khởi động vẫn chạy được, còn phát hiện trạng thái kết thúc thì không.
- **Hệ quả thứ hai, đắt hơn.** Đọc transcript ở đây chỉ trả về ô nhập liệu và dòng chân trang, nên
  bước kiểm nền hai nguồn của giao thức chung co lại còn mỗi `pgrep`.

Adapter này tồn tại để báo ra sự co lại đó, thay vì để nó đi qua như một câu trả lời bình thường.
<!-- source: harness/.agents/skills/dispatch-ticket-opencode/SKILL.md -->

## Khi nào Thomas gọi nó

| Thứ đang ở trước mặt | Gọi cái này |
|---|---|
| Một ticket đã claim, và `orchestrator.md` ghi agent ở role này chạy trên OpenCode | `dispatch-ticket` + `dispatch-ticket-opencode` |
| Một pane Builder hoặc Shaper | `opencode --agent <role> -m <provider>/<model> --auto` |
| Một dòng OpenCode có ô Effort không trống | Dừng và hỏi chủ dự án, vì effort không dùng được ở đây |
| Một pane báo `idle` | Đọc artifact, vì trạng thái đó không có luật nào đứng sau |
| Một worktree sắp bị gỡ dựa trên câu trả lời một nguồn | Lấy nguồn thứ hai bằng đường khác, hoặc handback lại thay vì gỡ |

<!-- source: harness/.agents/skills/dispatch-ticket-opencode/SKILL.md -->

## Cần sẵn gì

- **Adapter của role có mặt trong worktree**: `test -f <worktree-path>/.opencode/agents/<role>.md`.
  Xác nhận nó resolve bằng `opencode debug agent <role>` chạy từ cwd của worktree, không bao giờ
  bằng `opencode agent list --pure`, vì lệnh đó không liệt kê agent cấp dự án.
- **cwd của pane là gốc worktree hoặc một thư mục con của nó**, vì OpenCode đi ngược lên từ thư
  mục làm việc để tìm `.opencode/agents/`.
- **Giá trị Model mang tiền tố provider.** Tên model trần ném `ProviderModelNotFoundError`. Nếu
  model đã là mặc định thì bỏ hẳn `-m`.
- **Ô Effort của dòng này để trống**, vì trên OpenCode effort và khả năng nhìn thấy pane loại
  trừ lẫn nhau, và khả năng nhìn thấy được ưu tiên.

## Nó để lại gì

| Chuyện gì đã xảy ra | Nó nằm lại ở đâu |
|---|---|
| Lần launch | `herdr agent start "<role>-<ticket-id>" --kind opencode`, agent được nhận diện, tiến trình xác nhận đang chạy bằng `pgrep` |
| Tư thế quyền hạn | `--auto` cộng với `permission: { "*": allow }` của chính agent, hai thứ cộng lại nghĩa là không giới hạn |
| Một bước kiểm kết thúc bị suy giảm | Một báo cáo suy giảm, viết như khi báo runtime rơi về dự phòng, không phải một phán quyết một nguồn im lặng |
| Mọi phần còn lại: brief, watch, phán quyết, dọn dẹp | Giao thức dùng chung `dispatch-ticket` |

<!-- source: harness/.agents/skills/dispatch-ticket-opencode/SKILL.md -->

## Lỗi đã biết

Lấy từ `harness/.agents/memory/recurring-failure-modes.md`. Cả hai đều `promoted`.

- **Một tín hiệu không thể fail thì không phải bằng chứng.** OpenCode cho ví dụ thuần
  nhất trong cả ledger: một `idle` bịa, và một tiến trình OpenCode đã chết vẫn trả lời
  `interactive_ready: true` suốt ít nhất một chu kỳ poll. Luật rút ra là luật chung. Chất lượng
  phát hiện trạng thái là thuộc tính riêng của từng runtime, phải kiểm chứ không được giả định,
  và ở đâu một trạng thái không có luật đứng sau thì xác minh bằng artifact là công cụ duy nhất
  còn chạy được.
- **`TERMINAL:done` bị đọc nhầm thành việc đã xong.** `TERMINAL:done` nghĩa là lượt đó đã kết thúc, không phải công việc đã xong, và
  `pgrep` chính là nguồn đã trả lời sai ngoài thực địa. Điều đó nặng ở đây hơn mọi nơi khác, vì
  nguồn transcript lẽ ra dùng để đối chứng lại không trả về gì trên OpenCode.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Adapter được xác nhận bằng `opencode debug agent <role>` từ trong worktree, không phải bằng
  một lệnh liệt kê.
- Giá trị `-m` đọc ra `<provider>/<model>`, hoặc `-m` vắng mặt vì model đã là mặc định.
- Không phán quyết nào dựa vào mỗi `idle`, và mọi lời khẳng định đã xong đều chỉ vào một artifact.
- Một bước kiểm nền một nguồn được báo là suy giảm, bằng lời, ngay lúc nó xảy ra.
- Không worktree nào bị gỡ dựa trên một câu trả lời một nguồn.

<!-- source: harness/.agents/skills/dispatch-ticket-opencode/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

`dispatch-ticket` claim ticket rồi dựng worktree, tab và pane → `dispatch-ticket-opencode` kiểm
adapter và launch runtime → giao thức dùng chung giao brief và arm cái watch, và ở đây phán
quyết của nó yếu hơn hai runtime kia → artifact, chứ không phải pane, quyết định ticket đã xong
hay chưa. Hai adapter cùng nhóm là `dispatch-ticket-claude` và `dispatch-ticket-codex`.
