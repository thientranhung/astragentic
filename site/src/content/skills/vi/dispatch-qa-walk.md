---
title: dispatch-qa-walk
oneLiner: "Khởi động app trong worktree riêng và để QA dùng nó như một người dùng, trước PR, merge hoặc phát hành."
group: gate
order: 2
runtimes: [claude]
source: harness/.agents/skills/dispatch-qa-walk/SKILL.md
rented: false
lang: vi
updated: 2026-09-04
---

## Nó làm gì

Skill này dispatch lượt đi bộ sản phẩm của QA: gate phán hệ thống đang chạy thay vì phán cái
diff. Nó dựa trên phần gate-file và dạng pane của `review-with-rin` chứ không chép lại, và thêm
đúng một thứ mà một lượt đi bộ cần còn các gate khác thì không: một môi trường.

Thomas tạo một gate worktree tại SHA đang review, khởi động app ở đó bằng đúng lệnh của project,
rồi đóng gói một bản brief gồm:

- **Persona và trạng thái dữ liệu.**
- **Mọi bề mặt đang hiển thị cùng một khái niệm**, không chỉ các bề mặt đã đổi.
- **Design guidelines.**
- **Đồng ý dùng trình duyệt và mọi thao tác ghi được cho phép.**
- **Danh sách verified-clean của lượt trước.**

Từ đó nó dispatch QA như một pane gate, thu báo cáo, rồi tắt app và xác nhận port đã trống trước
khi gỡ worktree.

Vấn đề nó xử lý là: đọc một cái diff và dùng một sản phẩm là hai hành vi khác nhau, và một bộ test
xanh không chứng minh được hành vi nào. Test khẳng định thứ ai đó đã nghĩ ra để khẳng định; còn
thứ đang thiếu, sai thứ tự, không đọc nổi hay không với tới được trên màn hình thật thì đúng là
thứ không ai viết assertion cho.

Khoảng trống này không phải giả định. Một phiên bản harness trước từng ship một agent đi bộ bằng
trình duyệt qua vài bản phát hành mà nó chưa chạy lần nào; một project khác ghi nhận chín vòng fold
cộng một cú merge trong nửa ngày mà QA chưa hề được dispatch. Nên skill này mang theo bộ đếm của
riêng nó: quá mười cú merge chạm vào bề mặt người dùng thấy được kể từ lượt đi bộ gần nhất là một
STOP, và "không cú nào chạm bề mặt" là câu trả lời hợp lệ, còn "chưa đếm" thì không.
<!-- source: harness/.agents/skills/dispatch-qa-walk/SKILL.md -->

## Khi nào Thomas gọi nó

| Tình huống trước mặt bạn | Gọi cái nào |
|---|---|
| Một PR hay merge chạm vào bề mặt người dùng thấy được hoặc một endpoint công khai | `dispatch-qa-walk`, độ sâu incremental |
| Một bản phát hành hoặc một slice đang khép lại | `dispatch-qa-walk`, độ sâu full |
| Quá 10 cú merge đã chạm bề mặt kể từ lượt đi bộ gần nhất | `dispatch-qa-walk`, đây là STOP, không phải chuyện cân nhắc |
| Vài ticket cùng về một PR hoặc một bản phát hành | Một lượt đi bộ tại SHA đầu của lô, phạm vi là hợp của chúng |
| Thay đổi chỉ nằm ở backend, không bề mặt nào người dùng gặp | Không phải skill này. Ghi rằng lượt đi bộ không áp dụng, rồi dừng |
<!-- source: harness/.agents/skills/dispatch-qa-walk/SKILL.md -->

## Cần sẵn gì

- Bạn là Thomas: công thức này chỉ dành cho Thomas, cùng điều kiện với `review-with-rin`.
- Project có một đường render được ghi trong tài liệu cửa ngõ của nó. Chỗ nào không có thì lượt đi
  bộ không chạy được, và chính điều đó là một phát hiện gửi chủ project.
- Đồng ý dùng trình duyệt và mọi thao tác ghi được cho phép phải được gọi tên chính xác trong bản
  dispatch. Thiếu chúng thì QA từ chối và ghi lại một COVERAGE GAP.
- Danh sách verified-clean của lượt trước, nếu có, lấy từ `.astraler/state/qa-verified-clean.md`.
  Chỗ nào không có thì QA chạy full thay vì đoán xem lượt trước đã phủ tới đâu.
<!-- source: harness/.agents/skills/dispatch-qa-walk/SKILL.md -->

## Nó để lại gì

| Kết quả | Nơi nó nằm lại |
|---|---|
| Báo cáo đi bộ đầy đủ của QA | `$GATE_FILE` → `.astraler/state/gate-history/walk-<artifact-key>-<short-sha>.md` |
| Danh sách verified-clean | `$VERIFIED_CLEAN_FILE` → `.astraler/state/qa-verified-clean.md` |
| Dấu vết rằng lượt đi bộ đã xảy ra | Một commit rỗng `qa(walk): <artifact-key> — <verdict>` tại head đã đi bộ |
| Các COVERAGE GAP mà QA từ chối khép | Thân báo cáo; Thomas phân loại chúng như mọi phát hiện khác |
| Một bất đồng về sản phẩm ở mức thiết kế | `to-questionnaire`, định tuyến lên chủ project |
<!-- source: harness/.agents/skills/dispatch-qa-walk/SKILL.md -->

## Lỗi đã biết

- **Ship xong nhưng không đấu dây với ai.** Một agent đi bộ bằng trình duyệt được ship qua vài bản phát hành mà chưa chạy lần nào;
  không hợp đồng nào sở hữu nó, không dispatcher nào gọi tên nó. Promoted, sửa bằng phần đấu dây
  (hợp đồng, dispatcher, kiểm tra reachability), không phải bằng chính cái file còn thiếu.
- **Hàng đợi của chính mình vô hình với chính mình.** Hàng đợi dispatch của chính bên kiểm chứng thì vô hình với chính nó, nên điểm chạy phải
  bám theo artifact thay vì theo lịch. Promoted, được skill này và `thomas.md` trích dẫn.
- **Dời chữ nhưng để lại tên cũ.** Khi dời phần cơ chế của lượt đi bộ ra khỏi `review-with-rin`, ba dòng cũ vẫn đi theo,
  vẫn gọi người đi bộ là "Rin" và gọi lượt đi bộ là "một mode". Promoted, chữ đã dời thì chưa về
  nhà mới cho tới khi được đọc lại trong ngữ cảnh mới.
- **Teardown lỡ tay dừng luôn container dùng chung.** Một app đang chạy rò tiến trình broker và container database
  sau mỗi lượt đi bộ; một lần teardown đặt sai phạm vi từng dừng luôn container test dùng chung mà
  mọi Builder đang chạy đều phụ thuộc vào đó. Promoted, cleanup chạy theo thứ tự: giết app, xác nhận
  port, teardown có giới hạn phạm vi, rồi mới `--force` cái worktree.
<!-- source: harness/.agents/memory/recurring-failure-modes.md -->

## Đang chạy đúng nếu

- App chạy trong worktree riêng của nó tại SHA đang review, không bao giờ trong checkout của Builder.
- Cả `$GATE_FILE` lẫn `$VERIFIED_CLEAN_FILE` đều tồn tại, không rỗng, và đã được chép vào
  `.astraler/state/` trước khi gate worktree bị gỡ.
- Bản brief gọi tên mọi bề mặt đang hiển thị khái niệm đã đổi, không chỉ những bề mặt trong diff.
- App đã bị giết và port được xác nhận trống trước khi `git worktree remove --force` chạy.
- Có một marker `qa(walk):` nằm tại head đã đi bộ, để lượt đi bộ để lại dấu vết mà cửa merge đếm được.
<!-- source: harness/.agents/skills/dispatch-qa-walk/SKILL.md -->

## Nó nằm ở đâu trong chuỗi

Một ticket đóng lại qua `/skills/dispatch-ticket`, `/skills/review-with-rin` đọc diff và kiểm xem
quy trình có để lại dấu vết không, còn `dispatch-qa-walk` là gate bên cạnh, gate không đọc gì
cả. Nó lái sản phẩm đang chạy, vì một cái diff mạch lạc và một sản phẩm mạch lạc là hai lời khẳng
định khác nhau. Phát hiện từ cả hai cửa đi cùng một đường: `qa` khuyến nghị, Thomas phân loại,
Builder sửa, và một quyết định sản phẩm thật sự thì lên chủ project. Lượt đi bộ chạy bên trong một
`/dictionary/gate` và một `/dictionary/worktree` mà nó force-remove lúc cleanup, đó chính là lý do
danh sách verified-clean phải được ghi ra ngoài worktree đó trước.
<!-- source: harness/.agents/skills/dispatch-qa-walk/SKILL.md -->
