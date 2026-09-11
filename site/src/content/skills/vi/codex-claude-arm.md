---
title: codex-claude-arm
oneLiner: "Chạy một lượt Claude đọc lại artifact đã xong, khi session gốc chạy trên Codex."
group: gate
order: 3
runtimes: [codex]
source: harness/.agents/skills/codex-claude-arm/SKILL.md
rented: false
diagram: cross-vendor-arm
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`codex-claude-arm` làm đúng một việc: lượt `claude -p` mà một session gốc Codex chạy trên một
artifact đã xong và đã commit. Nó lo cái worktree cách ly, danh sách công cụ chỉ đọc, thứ tự dọn
dẹp và chỗ ghi lại kết quả, không gì khác. Thời điểm chạy, và luật tối đa hai lượt, thuộc về
`thomas.md` và `rin.md`. Bản thân cái gate thuộc về `review-with-rin`. Arm luôn gọi vendor *còn
lại*, nên trên session gốc Codex nó gọi Claude.
<!-- source: harness/.agents/skills/codex-claude-arm/SKILL.md -->

Thứ cần biết trước tiên là một ranh giới, không phải một bước: **một session gốc Codex không host
được cái gate.** Gate là một pane Herdr chạy trên runtime của provider gốc, và không adapter Codex
nào host được nó, nên một dòng `rin` trong `orchestrator.md` ghi Codex là một dòng cấu hình sai.
Hãy mang nó lên hỏi chủ dự án thay vì tìm cách lách. Thứ một session gốc Codex đóng góp được là lượt
này. Điểm khác thứ hai kín đáo hơn và đắt hơn: **phạm vi ticket ở đây cố tình không đối xứng với
`codex-arm`.** Builder chạy arm Codex thì làm ngay trong worktree của chính nó, vì `codex exec review`
chỉ đọc. Builder chạy arm này thì không được, vì `claude -p` là một agent đầy đủ, có Edit và Bash.
Sao chép đường đi của Codex ở đây là trao checkout Builder đang dùng cho một reviewer biết ghi,
tức dựng lại AST-016 trên cơ chế mới nhất.
<!-- source: harness/.agents/skills/codex-claude-arm/SKILL.md -->

## Khi nào Thomas gọi nó

| Tình huống trước mặt bạn | Gọi cái nào |
|---|---|
| Session gốc là Codex, artifact đã commit và đã handback | `codex-claude-arm` |
| Session gốc là Claude, arm cần gọi sang Codex | `codex-arm` |
| Builder trên session gốc Codex vừa xong một ticket | Chính Builder chạy `arm: ticket` |
| Một spec đang tạm dừng, hoặc một slice vừa đóng, trên session gốc Codex | Thomas chạy `arm: spec` / `arm: slice` |
| Gate mốc, người review, bản báo cáo | `review-with-rin`, không bao giờ là skill này |

<!-- source: harness/.agents/skills/codex-claude-arm/SKILL.md -->

## Cần sẵn gì

- **Artifact đã xong và đã handback.** Chạy sớm là tiêu một trong hai lượt được phép vào thứ
  còn đang thay đổi.
- **Artifact đã commit**, đã chốt đúng base ref và SHA head cuối. Một phán quyết cho SHA cũ
  không cho phép merge.
- **Model id của Claude ghi tường minh.** Alias trần `sonnet` trỏ sang một model khác với
  model skill này nêu.
- **Gate không nằm trên runtime này.** Kiểm dòng `rin` không ghi Codex trước khi coi bất cứ thứ
  gì ở đây là gate.

## Nó để lại gì

| Kết quả | Nơi nó nằm lại |
|---|---|
| Checkout cách ly để review | `<repo-root>/.claude/worktrees/gate-arm-<artifact-key>`, tách khỏi `gate-<artifact-key>` của chính reviewer |
| Vật liệu đem ra review | `GATE-DIFF.patch` và `GATE-LOG.txt`, do người dispatch ghi vào trong worktree gate |
| Khoảng review, nêu ngay từ đầu | Một dòng nêu số commit và số file cho `<base>..<head-sha>` |
| Phán quyết | Ghi đúng một lần vào decision trail: vendor đã chạy, hoặc `cross-vendor arm: NOT RUN — <reason>` |
| Những phát hiện bạn xác nhận là thật | Chuyển về người sở hữu artifact: spec về Shaper đang dừng, ticket về Builder của nó |

<!-- source: harness/.agents/skills/codex-claude-arm/SKILL.md -->

## Lỗi đã biết

Lấy từ `harness/.agents/memory/recurring-failure-modes.md`. Cả ba đều đang ở trạng thái
`promoted`.

- **AST-016**: các agent dùng chung một checkout đã dời HEAD dưới chân nhau, kể cả một reviewer
  chỉ đọc lỡ `git switch` HEAD của người khác. Đã sửa: cách ly là vô điều kiện với mọi agent
  được spawn mà có thể chạy lệnh git làm đổi trạng thái. Đó là lý do `claude -p` vẫn có
  worktree detached riêng ngay cả khi Builder đang đứng sẵn trong cây được review.
- **AST-103**: arm lặng lẽ review một khoảng không có commit nào rồi trả về sạch, đo được hai
  lần trong hai ngày trên cùng một dự án, cả hai lần do người vận hành bắt chứ không phải gate.
  Đã sửa: khối setup thoát khác 0 khi `git rev-list --count` bằng 0, và dòng đầu output nêu
  khoảng review để một lượt review rỗng lộ ra ngay.
- **AST-135**: điểm chạy phải đi theo artifact. Builder giờ tự chạy `arm: ticket` từ worktree của
  chính nó, còn Thomas giữ `arm: spec` và `arm: slice`. Skill này cố tình không sao chép cú dời đó
  ở phạm vi ticket, và entry đó nói rõ vì sao.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Dòng đầu output của arm nêu số commit và số file, và số đó khác 0.
- Worktree gate tên `gate-arm-<artifact-key>`, không phải `gate-<artifact-key>` của reviewer và
  không phải một đường dẫn đã từng dùng.
- Danh sách công cụ đúng bằng `Read,Grep,Glob`, không có tiền tố `Bash(...)`, và lệnh không kèm
  `--dangerously-skip-permissions`.
- Hai file bằng chứng bị xoá trước khi `git worktree remove`, và lệnh remove chạy không kèm
  `--force`.
- Decision trail mang đúng một bản ghi arm cho artifact này, nêu vendor đã chạy hoặc lý do
  không chạy.

<!-- source: harness/.agents/skills/codex-claude-arm/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

Artifact đã commit và đã handback → `codex-claude-arm` chạy một lượt Claude qua đúng khoảng đã
chốt → bạn phân loại phát hiện nào là thật rồi chuyển về người sở hữu artifact → một phát hiện
chặn nghĩa là một bản sửa, một SHA mới và lượt 2 theo cùng hợp đồng → lối ra khác nhau theo
loại artifact, và chỉ lối ra ở ticket mới là merge. `codex-arm` là bản đối xứng của skill này
trên session gốc Claude; `review-with-rin` sở hữu cái gate mà skill này dứt khoát không phải.
