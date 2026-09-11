---
title: codex-arm
oneLiner: "Chạy một lượt Codex trên artifact đã xong, để một vendor khác đọc diff trước khi merge."
group: gate
order: 1
runtimes: [claude, codex, opencode]
source: harness/.agents/skills/codex-arm/SKILL.md
rented: false
diagram: cross-vendor-arm
lang: vi
updated: 2026-09-04
---

## Nó làm gì

`codex-arm` là phần cơ chế gọi của cánh tay cross-vendor: lượt review bằng Codex mà Thomas, hoặc
ở phạm vi ticket là chính Builder, chạy trên một artifact đã hoàn thành trước khi nó được merge.
Nó bao gồm lệnh riêng theo runtime (`codex-companion.mjs` khi root là Claude, `codex exec review`
gọi thẳng trên Codex hay opencode), các bẫy về argv và quoting, và chỗ ghi lại phán quyết. Nó
không quyết định *khi nào* chạy. Nhịp đó, cùng với trần hai lượt, thuộc về `thomas.md` và
`builder.md`. Skill này sở hữu phần cách làm, không phải phần thời điểm.
<!-- source: harness/.agents/skills/codex-arm/SKILL.md -->

Lý do nó tồn tại: reviewer cùng vendor và reviewer khác vendor bắt được hai lớp lỗi khác nhau, vì
người viết đọc theo ticket còn cánh tay đọc theo repository. Điều này đã được đo trực tiếp.

Lượt arm theo ticket đầu tiên bắt được một cú reset có tính phá huỷ đang tự cấp quyền ra ngoài
write transaction của nó, thứ mà chính lượt mutation-testing của tác giả đã bỏ sót. Ngay lượt kế
tiếp, chạy trên bản vá cho phát hiện đó, lại bắt được một vòng deadlock thật do chính bản vá ấy
tạo ra. Bỏ qua nó là đã ship một lỗi 500 lên production, đúng trên con đường gỡ kẹt duy nhất mà
sản phẩm có.
<!-- source: harness/.agents/skills/codex-arm/SKILL.md -->

## Khi nào Thomas gọi nó

| Tình huống trước mặt bạn | Gọi cái nào |
|---|---|
| Diff của một ticket đã commit, root là Claude hoặc Builder đang tự chạy arm cho ticket của nó | `codex-arm` |
| Runtime ở root là Codex, cần một lượt Claude thay vào | `codex-claude-arm` (skill đối xứng; cánh tay luôn gọi vendor *bên kia*) |
| Một spec vừa xong, sắp cắt thành ticket | `codex-arm` ở `arm: spec`, do Thomas chạy từ base checkout |
| Một slice đang khép lại | `codex-arm` ở `arm: slice`, tương tự như trên |
| Cần chạy chính gate của Rin | Không phải skill này. Rin không tự chạy cánh tay từ bên trong lượt review của chính nó |

<!-- source: harness/.agents/skills/codex-arm/SKILL.md -->

## Cần sẵn gì

- Artifact đang được review đã commit. Cánh tay đọc một cây git, không phải working
  directory. <!-- source: harness/.agents/skills/codex-arm/SKILL.md -->
- Ở phạm vi ticket, Builder chạy nó từ worktree của chính nó, nơi `HEAD` đã trỏ đúng các commit
  đang được review. Ở phạm vi spec hoặc slice, Thomas tự resolve head từ một detached checkout tại
  SHA đó, vì riêng `--base` không nói được companion đang so với head nào.
  <!-- source: harness/.agents/skills/codex-arm/SKILL.md -->
- Phần chữ focus phải tránh mọi ký tự đặc biệt của shell hay glob, không phải tránh theo một danh
  sách cố định. Nó được truyền không quote, tách theo từ, nên một cụm viết tự nhiên như `option (a)`
  không bao giờ tới được tiến trình; glob expansion của zsh giết lệnh ngay lúc parse.
  <!-- source: harness/.agents/skills/codex-arm/SKILL.md -->
- `codex exec review` nhận `-m <model>`; `codex review` trần thì không.
  <!-- source: harness/.agents/skills/codex-arm/SKILL.md -->

## Nó để lại gì

| Kết quả | Nơi nó nằm lại |
|---|---|
| Phán quyết | Vệt quyết định merge: ngày, phán quyết, cách xử lý từng phát hiện, vendor nào đã chạy |
| Test có chạy hay không | Một dòng `Tests:`: `RAN` hoặc `NOT RUN — <lý do>` |
| Dải mà cánh tay đọc | Dòng đầu của output: số commit và số file, để một dải 0 commit không lọt qua như một lượt sạch |
| Codex không dùng được | `cross-vendor arm: NOT RUN — <lý do>`, và chỉ chủ project mới được chấp nhận nó |
| Tài nguyên của một gate worktree | Giải phóng bằng `release-worktree-resources.sh` trước khi gỡ, không bao giờ sau |

<!-- source: harness/.agents/skills/codex-arm/SKILL.md -->

## Lỗi đã biết

Lấy từ `harness/.agents/memory/recurring-failure-modes.md`. Mọi mục dưới đây đều ở trạng thái
`promoted`: đã sửa và đã nằm trong hợp đồng mà trang này mô tả.

- **AST-103**: companion resolve `HEAD` từ chính checkout nó đang chạy. Chỗ nào cái đó lệch với
  `--base` thì lượt chạy đem base branch so với chính nó và trả về sạch. Bị bắt hai lần, bởi người
  vận hành chứ không phải bởi gate. Đã sửa: in dải commit và file thành dòng output đầu tiên,
  dừng khi dải có 0 commit.
- **AST-095**: companion thoát mã 0 khi lỗi cấu hình, và cache state khoá theo workspace root. Đã
  sửa: không bao giờ rẽ nhánh theo exit code, chỉ theo nội dung file output; không bao giờ dùng
  lại một đường dẫn gate worktree.
- **AST-100**: mỗi lần gọi `codex-companion.mjs` lại sinh một tiến trình broker chạy lâu hơn cả
  lượt review, đo được 92 tiến trình mồ côi (~405 MB) trên hai project. Đã sửa: giết broker theo
  cwd thật trước khi gỡ gate worktree.
- **AST-115**: một target teardown ở cấp project bị dùng làm bước release đã dừng luôn container
  test-database dùng chung mà mọi Builder đang chạy đều phụ thuộc vào đó. Đã sửa: giới hạn release
  trong đúng worktree này, hoặc không release gì cả.
- **AST-016**: một reviewer chỉ đọc nhưng có shell vẫn dịch được `HEAD` của agent khác bằng
  `git switch`. Đã sửa, và điều này chịu lực cho `codex-claude-arm`: `claude -p` là một agent đầy
  đủ, nên cả cánh tay ở phạm vi ticket cũng có detached worktree riêng.

<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- Dòng đầu của mọi lượt arm nêu rõ số commit và số file của dải đang được review.
- Có mặt một dòng `Tests:`, ghi `RAN` hoặc nêu tên lý do không chạy.
- Vendor được ghi trong vệt merge khớp với vendor thật sự đã chạy, và không bao giờ tính một lượt
  cùng vendor thành lượt cross-vendor.
- Không gate worktree nào tồn tại lâu hơn lượt review của nó. Tài nguyên được giải phóng trước khi gỡ,
  trên mọi nhánh đường.
- Một phát hiện blocking ở lượt 1 phải có lượt 2 chạy trên bản vá, không phải một phán đoán cảm
  tính rằng có thể bỏ qua.

<!-- source: harness/.agents/skills/codex-arm/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

Vòng khép kín của một Builder chạy `implement` → review → simplify → `codex-arm` (phạm vi ticket)
→ receipt `arm(ticket):` → handback, và bước cleanup của `/skills/dispatch-ticket` kiểm receipt
đó trước khi gỡ worktree. Ở phạm vi spec và slice, Thomas chạy nó từ base checkout trước khi
thả một `shaper` đang tạm dừng hoặc trước khi khép một slice. `codex-claude-arm` là bản đối xứng
cho trường hợp root là Codex: cùng nhịp, ngược vendor. Không cái nào thay được
`/skills/review-with-rin`, vì đó mới là gate, còn đây là lượt chạy nuôi gate đó.
