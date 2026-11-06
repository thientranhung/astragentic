# Kiểm chứng install/update chung

## Bổ sung skill chung theo yêu cầu owner

Entrypoint mặc định nay stage `ADAPT-RUNTIME.md` cùng hai bộ contract. Skill
`astragentic-update-install` được ship byte-identical trong `.agents`/`.claude`
của scaffold và `.agents` của Codex. Owner dùng cùng câu yêu cầu kiểm tra/cập nhật;
flag runtime chỉ là chi tiết adapter agent sử dụng phía sau.

- Suite hiện tại: **30 tests PASS**, gồm common default stage không flag owner,
  chuyển từ release chung sang Codex, default apply cho fixture Claude, và gỡ
  Codex giữ bản skill chung có sẵn. Test staged-release bắt được checker chỉ đọc
  prompt ở source layout; đã thêm fallback đúng đường dẫn prompt flatten, không
  bỏ qua kiểm tra reachability.
- Native Codex prompt catalog probe: **21/21 skill**, không thiếu skill mới.
  Đây là native discovery thật trong temporary CODEX_HOME, không phải test model
  tự chọn skill; không sửa trust/config cá nhân.
- Skill validator, byte equality, reachability và docs-staleness đạt.
- Agent tự chọn skill từ câu tiếng Việt trong live Codex/Claude: **NOT RUN**.
  Claude không được khởi động; project Etsy không bị thay đổi.
- Astra review phát hiện nâng cấp skill chung cũ bị chặn bởi unowned collision.
  Đã bổ sung migration ngữ nghĩa có đối chiếu baseline, giữ mirror và ownership;
  re-review không còn finding. Test migration mô phỏng thao tác agent, chưa chứng
  minh live agent làm đúng toàn bộ quy trình.
- Kết quả phát hành 6.0.0 nằm tại [RELEASE-VALIDATION.md](RELEASE-VALIDATION.md).
  Các kết quả dưới đây ghi giai đoạn adapter trước khi
  thêm entrypoint chung; `--runtime codex` không còn là bước owner cần nhớ.

## Kiểm chứng adapter trước khi thêm skill chung

Luồng mới dùng entrypoint cũ với `--runtime codex`: stage release riêng, in prompt
`ADAPT-HARNESS-CODEX.md`, rồi agent đọc project và thực hiện setup. Default Claude
không đổi. Không bump VERSION, commit, push hoặc tạo release trong thay đổi này.

## Kiểm chứng tự động

`python3 -m unittest discover -s tests/codex -p 'test_*.py'`: 27 tests đạt.
Bốn test distribution dùng Git repository/cache/tag local trong thư mục tạm:

- Project có legacy wrapper từ HEAD và cấu hình/stamp cũ: plan không ghi,
  stage không cài runtime, prompt Codex được trả về, staged entrypoint apply,
  version/doctor chạy được; cấu hình legacy và AGENTS.md giữ nguyên.
- Bootstrap qua get.sh với tag fixture 6.0.0, tiếp tục update qua wrapper lên
  tag fixture 6.0.1; nội dung mới và installed-version khớp.
- Wrapper tùy biến bị từ chối trước khi ghi; plan cũng báo xung đột.
- Release cùng version nhưng bytes khác bị từ chối; managed-file drift giữ nguyên;
  owner orchestrator được bảo toàn qua reinstall.

Các version fixture không phải release thật. Đây là kiểm chứng shell/Python thật,
không truy cập GitHub, không chạy model, không chứng minh agent đã tự adaptation
một project thật. Live semantic adaptation theo prompt mới: **NOT RUN**.

Shell syntax, whitespace, reachability và docs-staleness checks đạt.
Legacy selftest toàn bộ: 219 pass, 1 fail tại `install.sh staging` (installer output
bị test ẩn). Chạy lại riêng đúng default installer, giữ nguyên đầy đủ staging gates
và nested selftest: exit 0, stage thành công và in prompt Claude như cũ. Lỗi lần đầu
không tái hiện ở lần chạy riêng; chưa xác định nguyên nhân và chưa chạy lại toàn bộ
suite, nên không ghi toàn bộ legacy selftest là PASS.
Astra review độc lập đã tìm thấy README trỏ tới docs không được đóng gói: đã sửa
README tự đủ nội dung. Re-review không còn blocker; góp ý plan kiểm tra wrapper
đã sửa và thêm assertion regression.

## Giới hạn và cách dùng

Hiện dùng từ checkout nguồn:

```sh
bash install.sh /absolute/path/to/project --runtime codex
```

Sau khi publish bản có thay đổi này, project cũ bootstrap bằng get.sh mới một lần
với `latest --runtime codex`; wrapper cũ không hiểu flag mới. Sau adaptation, dùng
`bash .astraler/astragentic.sh update --runtime codex`.

`installed-version` chỉ xác nhận file đã cài. Agent ghi report và `adapted-version`
sau integration/validation; chưa đo model access hay discovery thì ghi NOT RUN.
Cấu hình/trust cá nhân và legacy `.astraler/state/applied-version` không bị đổi.
