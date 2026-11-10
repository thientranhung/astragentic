# Goal: hoàn thiện Astragentic cho Codex

Copy phần trong khối bên dưới vào sau `/goal`. Đây là nội dung mục tiêu; không phải
khẳng định mọi bản Codex CLI đều có lệnh `/goal`.

```text
Hoàn thiện Astragentic để vận hành thực sự trên Codex CLI trong repository hiện tại.
Đọc AGENTS.md và docs/codex/README.md trước khi làm. Đối chiếu phạm vi đã duyệt tại
docs/codex/OWNER-REVIEW.md với mã và trạng thái thực tế; tài liệu cũ không chứng minh
một tính năng đã hoạt động. Owner đã duyệt triển khai toàn bộ phạm vi dưới đây.

KẾT QUẢ CẦN ĐẠT

Owner mở được Thomas, BA hoặc Quick Builder đúng vai trò. Thomas điều phối Shaper
qua Align → Spec → dừng chờ release → test-design → Tickets; dispatch Builder theo
ticket full/quick; tổ chức QA và xác minh artifact trước tích hợp. Builder có thể
dùng Junior khi cấu hình cho phép. Các role, astra-* skills và helper phải hoạt động
theo cơ chế Codex, không chỉ tồn tại dưới dạng tài liệu.

PHẠM VI

1. Có contract Codex độc lập cho Thomas, BA, Shaper, Builder, QA, Junior và owner
   Quick Builder. Phân biệt quick-labelled ticket với owner Quick Builder.
2. Hoàn thiện orchestrator-for-codex.md và nối lựa chọn model/reasoning effort đã
   duyệt vào launcher, dispatcher và helper. Đọc bảng hiện tại trong
   runtimes/codex/.agents/orchestrator-for-codex.md; không âm thầm đổi model.
3. Mapping đủ 17 skill chính trong inventory, gồm 7 astra-*; chuyển phần phụ thuộc
   runtime sang Codex. Bao gồm review, simplify, 3 helper và 2 adoption skills.
   Không expose dispatch-ticket-claude làm launcher Codex; dùng adapter Codex riêng.
4. Herdr quản lý pane, launch và trạng thái. Ưu tiên codex queue cho giao tiếp liên
   phiên: session UUID gắn đúng project/pane/role/dispatch, message ID, acknowledgement,
   handback và xử lý trùng lặp. Exit 0 của queue không chứng minh đã xử lý.
5. Hỗ trợ checkpoint, resume và phục hồi sau interrupt/restart. Kiểm tra phiên còn
   sống trước khi relaunch. Không tự đánh thức công việc owner đã chủ động dừng.
   Không gửi đồng thời queue và Herdr prompt cho cùng event; fallback phải có căn cứ.
6. Hoàn thiện context loading, install/upgrade/doctor/uninstall và coexistence với
   hệ thống Claude. Giữ cấu hình owner khi upgrade, không ghi đè skill không thuộc
   quyền quản lý của installer.
7. Có kiểm soát claim, worktree/write-set, base/head, test/review/simplify/QA evidence,
   verify trước tích hợp và cleanup không làm mất dữ liệu. Prompt nhắc quy tắc không
   được trình bày thành gate đã cưỡng chế. Trạng thái idle/done không là verdict.
8. Cross-vendor arm phải dùng reviewer khác provider hoặc cấu hình off được owner
   chọn rõ ràng; không gọi Codex tự review là cross-vendor và không tự tắt để qua gate.
9. Kiểm chứng hành trình thực tế từ khởi động → dispatch → thực thi → handback → QA
   → verify; thử cả pause/release của Shaper, hai loại quick, Junior, concurrency và
   các trường hợp thất bại quan trọng. Dùng fixture/repository thử cho thao tác có thể
   ảnh hưởng Git hoặc tracker; không thay bằng mock rồi tuyên bố end-to-end đạt.
10. Bàn giao tài liệu vận hành bằng tiếng Việt: lệnh khởi động, cách dispatch/giao tiếp,
    cách đọc trạng thái, xử lý lỗi, kết quả kiểm chứng và giới hạn còn lại.

RANH GIỚI

- Theo góp ý mới nhất của owner: hoàn thiện harness gọn dựa trên Markdown và native
  Codex/Herdr. Không xây state machine, receipt service hoặc verifier engine riêng.
  Giữ trách nhiệm kiểm tra artifact bằng công cụ project và quy trình Thomas.
  Hoàn thiện và kiểm chứng trước, rồi review chéo độc lập toàn bộ bản trước bàn giao.

- Markdown Claude chỉ dùng để nghiên cứu. Role/agent/skill Codex không được yêu cầu
  runtime đọc contract Claude. Không sửa hệ thống Claude để bù thiếu hụt Codex.
- Ưu tiên hạ tầng đã có; không xây broker, daemon, database hay dashboard mới nếu
  chưa có bằng chứng cần thiết. Không tự biến tất cả business role thành subagent.
- Không sửa cấu hình Codex cá nhân hoặc project trust của owner. Không tự mở rộng
  quyền sandbox để làm phép thử xanh.
- Không commit, release, publish, deploy hoặc gửi tin ra ngoài chỉ để hoàn tất goal.
  Thao tác thử nghiệm phải ở phạm vi đã được cho phép; không tự tạo ticket thật.
- Giữ thay đổi đang có của người khác. Không rollback phần đã duyệt vì gặp một lỗi nhỏ.

CÁCH LÀM VIỆC

- Kiểm tra hiện trạng và lập checklist triển khai có bằng chứng, rồi bắt tay thực hiện.
  Duy trì checklist để tiếp tục được qua compaction hoặc phiên mới.
- Tiếp tục tự chủ qua các mốc đã duyệt. Mốc nhỏ là cập nhật tiến độ, không phải điểm
  dừng để hỏi “anh có muốn em làm tiếp không?”. Không hỏi lại phê duyệt đã có.
- Chỉ hỏi khi thiếu quyết định thực sự của owner hoặc gặp hành động vượt quyền đã
  được cấp; tiếp tục các phần độc lập trong lúc chờ.
- Khi bị lỗi, chẩn đoán và sửa trong phạm vi; không đổi định nghĩa thành công để
  né phần khó. Không thêm tính năng ngoài mục tiêu để tạo cảm giác tiến triển.
- Báo ngắn bằng tiếng Việt: đã làm gì, bằng chứng nào, còn thiếu gì, bước tiếp theo.
  Phân biệt kiểm tra tĩnh, mock, process-boundary và live end-to-end.

ĐIỀU KIỆN HOÀN TẤT

Chỉ đánh dấu goal hoàn tất khi từng yêu cầu trên có bằng chứng tương ứng trong trạng
thái hiện tại và owner có thể làm theo hướng dẫn để vận hành hành trình đã duyệt.
File tồn tại, unit test xanh hoặc CLI có một tính năng không đủ chứng minh integration.
Nếu còn thiếu integration hoặc chưa đo hành vi bắt buộc, giữ goal active và tiếp tục.
Nếu thật sự bị chặn bởi điều kiện bên ngoài, báo chính xác blocker và phần cần owner
can thiệp; không tuyên bố xong. Kết thúc bằng báo cáo phạm vi đạt, kiểm chứng thực tế,
giới hạn và đường dẫn tài liệu bàn giao.
```
