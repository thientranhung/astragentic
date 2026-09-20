---
title: dispatch-ticket-codex
oneLiner: "Launch một pane Codex với danh tính role nằm trên CLI, kiểm bằng chính parser của launcher."
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

Model và effort giờ đi theo CLI cho cả Codex, giống Claude. Cái khác đi là danh tính role: nó tới
dưới dạng giá trị `-c developer_instructions=...` dựng từ `.codex/profiles/<role>.md`, một file
text thuần, nằm trong repo, được git track — không phải một file TOML cục bộ dưới `$CODEX_HOME`.

- **`.codex/profiles/<role>.md` là system prompt của pane.** Text thuần, nằm trong repo, được
  git track. Nó chỉ chứa hướng dẫn — không model, không effort, không bình luận về chính nó.
- **Model và effort có đúng một nhà**: dòng codex của role đó trong `.agents/orchestrator.md`.
  Không còn chỗ nào khác có thể lệch với bảng đó.
- **`--profile` chưa bao giờ là cơ chế thật.** `codex --help` ghi rõ nó layer
  `$CODEX_HOME/<name>.config.toml` lên trên config gốc — một namespace mọi project trên máy dùng
  chung. `.codex/profiles/` trong repo chưa bao giờ được nó đọc.
- **`--yolo` đã cũ từ v0.147.0**, thay bằng `--dangerously-bypass-approvals-and-sandbox`.

Nên bước kiểm trước dispatch không phải nghi thức: nó nhờ chính parser của launcher dựng lại
prompt rồi diff với file role. Điều đó chỉ chứng minh việc giao đúng byte — không chứng minh
nội dung đúng.
<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Khi nào Thomas gọi nó

| Tình huống trước mặt bạn | Gọi cái nào |
|---|---|
| Một ticket đã claim, và `orchestrator.md` ghi agent ở role này chạy trên Codex | `dispatch-ticket` + `dispatch-ticket-codex` |
| Một pane Builder, Shaper hoặc QA trên Codex | `codex -m <model> -c model_reasoning_effort="<effort>" -c developer_instructions="$(cat .codex/profiles/<role>.md)" --dangerously-bypass-approvals-and-sandbox` |
| Một dòng `rin` ghi Codex | Dừng lại. Session gốc Codex không host được gate (`codex-claude-arm`) |
| `.codex/profiles/<role>.md` thiếu, rỗng, hoặc fail bước diff prompt-input | Dừng trước khi dispatch; một key `-c` không nhận diện được vẫn được chấp nhận trong im lặng, exit 0 |
| Một file `.codex/agents/*.toml` trông như đáp án | Không phải. Đó là subagent spawn được, không phải pane của một role |

<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Cần sẵn gì

- **`.codex/profiles/<role>.md` tồn tại và không rỗng.** Đó là system prompt của pane, được git
  track — không có bước copy theo máy nào để làm chỗ dựa.
- **Model và effort chỉ đến từ dòng codex của role đó trong `.agents/orchestrator.md`.** Một dòng
  còn ghi `<set-me>` không phải một giá trị: dừng lại và hỏi chủ máy.
- **`codex debug prompt-input` đã chạy trên file role**, và text nó dựng ra được diff khớp từng
  byte với `.codex/profiles/<role>.md`.
- **cwd của pane là worktree**, theo gate cwd bắt buộc trong giao thức dùng chung.

## Nó để lại gì

| Kết quả | Nơi nó nằm lại |
|---|---|
| Lần launch | `herdr agent start "<role>-<ticket-id>" --kind codex`, kèm nguyên dòng lệnh `-m`/`-c`/`-c` |
| Danh tính role | `.codex/profiles/<role>.md`, nằm trong repo |
| Model và effort | Dòng codex của role đó trong `.agents/orchestrator.md`, không nơi nào khác |
| Một bước kiểm giao | Output của `codex debug prompt-input` diff với file role, trước mọi lần dispatch |
| Mọi thứ còn lại, gồm brief, watch, phán quyết và dọn dẹp | Giao thức dùng chung `dispatch-ticket` |

<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Lỗi đã biết

Ledger không có entry nào ghi tên file skill này. Hai entry dưới đây gắn với cơ chế cũ
`harness/.codex/profiles/*.config.toml` — các template cục bộ theo máy mà một lần launch từng
đọc, trước khi launcher chuyển hẳn sang một dòng lệnh thuần — và cả hai đều `promoted`.

- **Profile ship kèm sẵn model id trùng khớp.** Gói này từng ship `model = "gpt-5.1-codex"` trong cả bốn profile Codex. Nó không
  resolve trên bất kỳ tài khoản nào, và nó không fail lúc cài, lúc adapt, hay ở bất kỳ lần chạy
  doctor nào, vì template và profile chép từ nó khớp nhau hoàn hảo. Nó fail ở cú gọi cross-vendor
  đầu tiên, tức cuối phase, và trông y như provider đang sập. Đã sửa tại thời điểm đó: không ship
  id nào, `model = ""` kèm một comment nói id thật lấy từ đâu, và một doctor báo MISS khi trường
  rỗng. Loại lỗi này giờ đóng theo cách khác: model và effort có đúng một nhà, dòng codex của role
  đó trong `.agents/orchestrator.md`, nên không file nào có thể ship một giá trị cạnh tranh.
- **Một file scaffold bị ghi đè.** Một file được gọi là "của chủ máy" mà vẫn nằm trong payload
  từng có hai nhà, và bản được ship thắng. Đã sửa tại thời điểm đó: profile là scaffold, chỉ ghi
  khi vắng và không bao giờ bị đè, và skill báo lệch thay vì tự sửa. Loại lỗi này giờ cũng đóng:
  `.codex/profiles/<role>.md` nằm trong repo, được git track, không còn dưới một đường dẫn
  scaffold cục bộ theo máy, nên không còn nhà thứ hai nào để mà lệch.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- File role được đọc từ `.codex/profiles/<role>.md` trong repo, và việc nó vắng mặt hoặc rỗng
  làm dừng lần dispatch trước khi launch.
- `codex debug prompt-input` dựng lại file khớp từng byte; một chỗ lệch làm dừng dispatch thay vì
  launch trên niềm tin.
- Model và effort chỉ đến từ dòng codex của role đó trong `.agents/orchestrator.md`, không bao
  giờ từ một file mà chính file role có thể lệch với nó.
- Lệnh launch mang `--dangerously-bypass-approvals-and-sandbox`, không bao giờ mang `--yolo`
  đã nghỉ hưu.
- Không Builder nào bị định tuyến qua subagent `.codex/agents/*.toml`, vì nó dùng chung topology
  của session cha và không được cấp worktree.

<!-- source: harness/.agents/skills/dispatch-ticket-codex/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

`dispatch-ticket` claim ticket rồi dựng worktree, tab và pane → `dispatch-ticket-codex` kiểm
việc giao file role rồi launch runtime → giao thức dùng chung giao brief, arm cái watch và đọc
phán quyết → trên session gốc Codex, lượt cross-vendor là `codex-claude-arm`, còn gate vẫn ở lại
trên session gốc Claude. Hai skill song song với nó là `dispatch-ticket-claude` và
`dispatch-ticket-opencode`.
