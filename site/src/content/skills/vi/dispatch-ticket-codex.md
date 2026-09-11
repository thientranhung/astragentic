---
title: dispatch-ticket-codex
oneLiner: "Launch một pane Codex từ profile cục bộ của chủ máy, sau khi kiểm profile khớp dòng cấu hình."
group: adapter
order: 2
runtimes: [codex]
source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`dispatch-ticket-codex` là nửa Codex của `dispatch-ticket`. Skill dùng chung giữ:

- **Định danh và chốt input.**
- **Luật worktree.**
- **Khuôn brief, cách gửi và cách canh.**
- **Simplify và dọn dẹp.**

Adapter này thêm đúng ba thứ: bảng lệnh launch cho các dòng Codex, bước kiểm profile trước khi
dispatch, và những sự thật đã đo được về cách Codex tự báo trạng thái của nó. Đây là adapter mỏng
nhất trong ba adapter runtime, và mỏng là có chủ đích. Với Codex, skill dùng chung đã sở hữu sẵn
phần gửi brief và phần canh; điều này được kiểm lại chứ không phải giả định, trong một đợt quét tìm
hướng dẫn cũ còn sót.
<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md, RELEASE-NOTES.md -->

Điểm khác ở đây là chỗ cấu hình nằm. Trên Claude, model và effort đi theo CLI; trên Codex thì
không:

- **Profile cục bộ theo máy.** File đứng sau `codex --profile <role>` nằm dưới
  `${CODEX_HOME:-$HOME/.codex}/`.
- **Effort là một trường TOML** (`model_reasoning_effort`), vì Codex không có cờ `--effort`.
- **`--yolo` đã cũ từ v0.147.0**, thay bằng `--dangerously-bypass-approvals-and-sandbox`.

Nên bước kiểm trước dispatch không phải nghi thức: đó là chỗ duy nhất lựa chọn runtime của chủ máy
và dòng trong `orchestrator.md` được đem ra đối chiếu.
<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Khi nào Thomas gọi nó

| Tình huống trước mặt bạn | Gọi cái nào |
|---|---|
| Một ticket đã claim, và `orchestrator.md` ghi agent ở role này chạy trên Codex | `dispatch-ticket` + `dispatch-ticket-codex` |
| Một pane Builder, Shaper hoặc QA trên Codex | `codex --profile <role> --dangerously-bypass-approvals-and-sandbox` |
| Một dòng `rin` ghi Codex | Dừng lại. Session gốc Codex không host được gate (`codex-claude-arm`) |
| Profile thiếu hoặc đã lệch khỏi template | Đưa chủ máy đúng lệnh copy và diff; không bao giờ tự tạo trong im lặng |
| Một file `.codex/agents/*.toml` trông như đáp án | Không phải. Đó là subagent spawn được, không phải pane của một role |

<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Cần sẵn gì

- **Profile cục bộ theo máy có tồn tại** tại `${CODEX_HOME:-$HOME/.codex}/<role>.config.toml`.
  Harness ship sẵn template thuộc quyền chủ máy ở `.codex/profiles/<role>.config.toml`, và
  template đó là nguồn đúng cho một lần launch pane.
- **Profile khớp template của nó**, hoặc độ lệch được báo cho chủ máy chứ không tự sửa lặng lẽ.
- **Model và effort trong TOML khớp dòng `orchestrator.md`.** Hai chỗ, một đáp án, và không còn
  gì khác đem chúng ra so.
- **cwd của pane là worktree**, theo gate cwd bắt buộc trong giao thức dùng chung.

## Nó để lại gì

| Kết quả | Nơi nó nằm lại |
|---|---|
| Lần launch | `herdr agent start "<role>-<ticket-id>" --kind codex`, kèm cờ profile |
| Danh tính role, model và effort | File TOML cục bộ theo máy, không phải CLI |
| Một phát hiện lệch | Một báo cáo cho chủ máy, kèm lệnh copy và diff, trước mọi lần dispatch |
| Mọi thứ còn lại, gồm brief, watch, phán quyết và dọn dẹp | Giao thức dùng chung `dispatch-ticket` |

<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Lỗi đã biết

Ledger không có entry nào ghi tên file skill này. Hai entry dưới đây gắn với
`harness/.codex/profiles/*.config.toml`, chính các template mà bước kiểm trước dispatch của skill
này đọc, và cả hai đều `promoted`.

- **Profile ship kèm sẵn model id trùng khớp.** Gói này từng ship `model = "gpt-5.1-codex"` trong cả bốn profile Codex. Nó không
  resolve trên bất kỳ tài khoản nào, và nó không fail lúc cài, lúc adapt, hay ở bất kỳ lần chạy
  doctor nào, vì template và profile chép từ nó khớp nhau hoàn hảo. Nó fail ở cú gọi cross-vendor
  đầu tiên, tức cuối phase, và trông y như provider đang sập. Đã sửa: không ship id nào,
  `model = ""` kèm một comment nói id thật lấy từ đâu, và một doctor báo MISS khi trường rỗng.
- **Một file scaffold bị ghi đè.** Một file được gọi là "của chủ máy" mà vẫn nằm trong payload thì có hai nhà, và
  bản được ship thắng. Đã sửa: profile là scaffold, chỉ ghi khi vắng và không bao giờ bị đè. Đó
  là lý do skill này báo lệch thay vì tự sửa.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Profile được đọc từ `${CODEX_HOME:-$HOME/.codex}/`, và việc nó vắng mặt làm dừng lần dispatch
  chứ không kích hoạt một cú copy lặng lẽ.
- Lệnh `diff -q` với template đã ship có chạy, và mọi độ lệch đều tới tay chủ máy bằng lời.
- Lệnh launch mang `--dangerously-bypass-approvals-and-sandbox`, không bao giờ mang `--yolo`
  đã nghỉ hưu.
- Không có effort nào truyền qua CLI, vì Codex không có cờ cho nó.
- Không Builder nào bị định tuyến qua subagent `.codex/agents/*.toml`, vì nó dùng chung topology
  của session cha và không được cấp worktree.

<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

`dispatch-ticket` claim ticket rồi dựng worktree, tab và pane → `dispatch-ticket-codex` kiểm
profile và launch runtime → giao thức dùng chung giao brief, arm cái watch và đọc phán quyết
→ trên session gốc Codex, lượt cross-vendor là `codex-claude-arm`, còn gate vẫn ở lại trên session
gốc Claude. Hai skill song song với nó là `dispatch-ticket-claude` và `dispatch-ticket-opencode`.
