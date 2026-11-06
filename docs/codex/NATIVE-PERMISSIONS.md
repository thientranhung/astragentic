# Quyền Herdr theo từng lần mở Codex

Launcher hỗ trợ `--herdr` từ terminal được Herdr quản lý. Nó kiểm tra `HERDR_ENV=1`
và `HERDR_SOCKET_PATH` là socket tuyệt đối đang tồn tại, rồi truyền ba cấu hình
native vào riêng phiên Codex được mở:

- `default_permissions="astragentic-local"`
- `features.network_proxy=true`
- Profile `astragentic-local` kế thừa `:workspace`, bật network proxy và allow đúng
  socket Herdr vừa kiểm tra, bằng một inline TOML value.

Không ghi config/trust cá nhân. Socket API cho phép cả đọc và mutation; đây không
phải quyền read-only. Exact-pane, write-set và quyền thực hiện task vẫn do agent
và contract kiểm tra. Không kết hợp profile với legacy sandbox override.

Đã đo trên codex-cli 0.166.0: native Herdr get/read/wait thành công trong pilot;
default sandbox trước đó từ chối socket. Pilot tích hợp sau đó dùng profile này
cho Thomas điều phối worker. External-domain denial, remote tracker access và mọi
policy layer trên máy khác chưa được kiểm chứng. Xem [trạng thái](IMPLEMENTATION-STATUS.md).

Để dùng, từ project đã setup trong terminal Herdr:

```sh
python3 .codex/astragentic/launch.py thomas --project . --herdr
```

Không thêm flag thì launcher giữ permission mặc định. Nếu API/CLI thay đổi, đọc
help của phiên bản đang cài và kiểm tra active profile trước khi kết luận quyền đã
hoạt động. Lỗi capacity/model không được giải quyết bằng cách nới quyền.
