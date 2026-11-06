# Vận hành Astragentic Codex

Đây là hướng dẫn owner cho overlay Codex. Trạng thái kiểm chứng và phần chưa đạt nằm
ở [IMPLEMENTATION-STATUS.md](IMPLEMENTATION-STATUS.md). Luồng chính đã đạt bounded pilot đầu-cuối. Máy cần Python 3.9+, Git, Codex CLI; dispatch pane cần Herdr đang hoạt động.

## Cài, cập nhật, kiểm tra và gỡ

Cùng trải nghiệm với Claude: trong project đã có skill, nói với agent:

> Astragentic có bản mới rồi, kiểm tra phiên bản và cập nhật project này.

Skill chung `astragentic-update-install` kiểm tra phiên bản, stage bằng get.sh
hiện có rồi đọc `ADAPT-RUNTIME.md`. Agent tự chọn contract theo runtime của phiên
hiện tại và thực hiện setup tiếp; owner không cần flag hay prompt dài.
Nếu agent không tự chọn skill, gọi đích danh `astragentic-update-install`.
Khả năng tự chọn phụ thuộc runtime/catalog; cần phiên mới sau khi vừa cài skill.

Bản cũ chưa có skill: bootstrap một lần qua lệnh cài chung, rồi đưa dòng prompt
installer trả về vào agent. Từ bản 6.0.0:

```sh
curl -fsSL https://raw.githubusercontent.com/thientranhung/astragentic/main/get.sh | bash
```

Để thử nguồn local được owner chỉ định, từ checkout Astragentic:

```sh
bash install.sh /absolute/path/to/project
```

Entrypoint chung stage `.astraler/releases/<version>/` có cả hai adapter;
Codex chuyển tiếp nội bộ sang candidate `.astraler/codex/releases/<version>/`
và [ADAPT-HARNESS-CODEX.md](../../runtimes/codex/ADAPT-HARNESS-CODEX.md).
`--runtime codex` vẫn là chi tiết adapter cho agent/công cụ, không phải luồng cài
riêng owner cần nhớ. Runtime khác chưa có adapter thì báo thiếu, không giả làm Claude.
Đây là prompt hướng dẫn, không phải gate tự cưỡng chế.

Entrypoint apply ghi `.astraler/codex/state/installed-version` sau khi installer thành công;
`.astraler/codex/state/adapted-version` chỉ ghi sau khi hoàn tất integration ngữ nghĩa,
quyết định cần thiết đã rõ, doctor và startup dry-run đạt. Báo cáo tại
`.astraler/codex/state/adaptation-report.md` phân biệt kiểm tra đã chạy với `NOT RUN`.
Discovery và startup ở phiên mới có thể còn `NOT RUN`; adapted-version không chứng
nhận live workflow. Stamp legacy `.astraler/state/applied-version` được giữ riêng.

Các lệnh trực tiếp dưới đây phục vụ kiểm tra/cài overlay thủ công; chỉ chạy chúng
không thay thế bước adaptation project:

Chạy từ checkout nguồn Astragentic. Thay đường dẫn ví dụ bằng **Git root** của project
đích; bỏ `--apply` để xem kế hoạch trước khi ghi:

```sh
python3 runtimes/codex/install.py install --project /absolute/path/to/project
python3 runtimes/codex/install.py install --project /absolute/path/to/project --apply
python3 runtimes/codex/install.py doctor --project /absolute/path/to/project
```

Cập nhật dùng lại lệnh `install`. Installer quản lý các role, 20 skill tên `codex-*`,
helper TOML, ba tiện ích và `.codex/astragentic/skill-map.json` để tra tên skill;
manifest ở `.codex/astragentic/manifest.json`. Nó giữ
`.agents/orchestrator-for-codex.md` đã có, AGENTS.md, Claude skills và cấu hình/trust
cá nhân. File được quản lý đã sửa, bị mất hoặc trùng file không thuộc installer sẽ
làm thao tác dừng trước khi ghi. Giữ bản sửa và đối chiếu thủ công với nguồn; không
xóa manifest để vượt xung đột. Doctor chỉ kiểm tra file và model helper khớp bảng,
không chứng minh quyền truy cập model hay luồng công việc.

```sh
python3 runtimes/codex/install.py uninstall --project /absolute/path/to/project
python3 runtimes/codex/install.py uninstall --project /absolute/path/to/project --apply
```

Gỡ chỉ xóa file nguyên vẹn thuộc manifest; giữ orchestrator của owner. Báo cáo, branch,
worktree, pane và phiên Codex cần xử lý theo từng dispatch, không bị installer dọn.

## Mở đúng vai trò

Trong project đã cài:

```sh
python3 .codex/astragentic/launch.py thomas --project .
python3 .codex/astragentic/launch.py ba --project .
python3 .codex/astragentic/launch.py quick-builder --project .
```

Từ 6.0.1, launcher hỗ trợ quyền yolo do owner chủ động chọn:

```sh
python3 .codex/astragentic/launch.py thomas --project . --yolo
```

`--yolo` bỏ sandbox và yêu cầu xác nhận thực thi cho phiên mới. Bootstrap mang lựa
chọn này vào dispatch record; các tiến trình Codex mới được phép dispatch nhận
cùng flag tường minh, kể cả Builder → Junior. Không bật thì không tự thêm yolo.
Đây là quy trình agent thực hiện theo mẫu lệnh; không phải OS tự kế thừa hay
scheduler cưỡng chế. Kiểm tra argv/permission thực tế của worker trước khi khẳng
định quyền đã đúng. Quyền không mở rộng task/write-set hay bỏ gate review/QA.
Native helper/subagent dùng cơ chế quyền của Codex, không có cờ CLI riêng ở đây.

Chọn **một** trong `--yolo` và `--herdr`; launcher từ chối ghép hai chế độ. Yolo
không cần profile socket hạn chế của `--herdr`; dispatch vẫn cần Herdr đang hoạt
động và xác minh đúng workspace/pane. Không ghi config/trust cá nhân. Khi resume,
áp dụng lại mode đã ghi, ví dụ `codex --yolo resume <UUID>`; worker đang chạy không
đổi quyền chỉ vì Thomas được mở lại với flag khác.

Để Thomas điều phối qua Herdr trong phiên đã mở từ Herdr, dùng opt-in:

```sh
python3 .codex/astragentic/launch.py thomas --project . --herdr
```

`--herdr` kiểm tra `HERDR_ENV=1` và `HERDR_SOCKET_PATH` là socket tuyệt đối đang
tồn tại; thêm profile native theo từng lần launch, không ghi config/trust cá nhân.
Quyền socket cho phép API Herdr (gồm mutation), không chỉ đọc trạng thái. Xem
[profile đã đo](NATIVE-PERMISSIONS.md); không phối hợp với legacy sandbox override.
Không thêm flag thì launcher giữ nguyên quyền Codex mặc định.

Thêm `--dry-run` để xem model, effort và argv trước khi mở. Có thể chạy tương tự từ
nguồn bằng `python3 runtimes/codex/launch.py ... --project /absolute/path/to/project`;
launcher ưu tiên contract đã cài của project đích. Nếu chưa cài, launcher cảnh báo
đang dùng contract nguồn: skill/helper chưa được discover native trong project.
Cài overlay rồi mở **phiên mới** để tải catalog/helper.
Launcher đọc `--orchestrator PATH` nếu chỉ định, tiếp đến bảng project, cuối cùng
bảng nguồn. Owner sửa bảng `.agents/orchestrator-for-codex.md` khi muốn đổi model;
chạy lại install và doctor để tái tạo helper. Không tự thay model khi model bị từ chối.
Launcher kiểm tra helper đã cài có khớp bảng được chọn (kể cả `--orchestrator`);
lệch thì dừng để owner reconcile rồi install/doctor, không chạy ngầm model cũ.
Trust hoặc yêu cầu quyền là quyết định owner; installer không tự đổi.

Thomas điều phối; BA giúp làm rõ nhu cầu; Quick Builder nhận việc trực tiếp từ owner.
Quick Builder khác Builder nhận ticket nhãn quick. Sau khi tải contract, phiên chờ
owner giao việc bằng cách kết thúc lượt, không chạy vòng sleep/poll hoặc tự nhặt việc cũ.

## Giao việc, theo dõi và quyết định của owner

Thomas dùng [DISPATCH.md](../../runtimes/codex/.codex/DISPATCH.md) được cài tại
`.codex/DISPATCH.md` của project. Một record `.scratch/codex/<dispatch-id>.md` giữ
brief, base SHA, write-set, branch/worktree, Herdr workspace/tab/pane, UUID của hai
phiên, model/effort và bảng event/ACK/result. Đây là sổ điều phối Markdown; Thomas
phải đọc artifact và chạy kiểm tra project để quyết định tích hợp.

Sandbox mặc định đã từ chối socket Herdr. Profile opt-in mới đã đo native
`agent get/read/wait` thành công và [journey native](IMPLEMENTATION-STATUS.md)
đã đạt trong fixture: Thomas tự điều phối, không phải host làm thay từng bước.

1. Thomas kiểm tra tracker, dependency, quyền và capacity; mở worker bằng Git worktree
   và native `herdr agent start`. Một Thomas giữ frontier; Builder song song cần
   write-set tách biệt. Worktree mới không kế thừa overlay chưa commit của coordinator:
   cài overlay tại đó bằng installer nguồn, mang snapshot orchestrator owner sang nếu
   chưa có; config có sẵn khác snapshot cần xử lý rõ ràng, không ghi đè. Chạy doctor
   tại worktree trước khi mở worker. Junior dùng worktree của Builder với một writer
   tại một lúc.
2. Worker tự đọc `CODEX_THREAD_ID`; Thomas bind UUID với đúng pane/project. Follow-up
   dùng `codex queue --thread UUID --message ...` với event ID duy nhất. Exit 0 chỉ
   là queue chấp nhận; cần ACK và kết quả. Không gửi hai đường đồng thời hoặc fallback
   mù. Nếu queue chắc chắn thất bại trước acceptance, dùng một Herdr fallback cùng
   event theo DISPATCH; timeout/accepted/ambiguous không cho phép replay.
3. Thomas quan sát bằng `herdr agent get/read/wait`, đọc báo cáo có base/head và
   validation. Idle/done không phải verdict đạt. Worker không gọi được queue trong
   sandbox thì ghi report và in đường dẫn; Thomas tiếp tục quan sát pane.
4. Shaper dừng sau Spec. Owner release đúng revision trước test-design và Tickets;
   Spec đổi cần release mới. QA kiểm tra đúng target/plan; Thomas đối chiếu diff,
   write-set, test/review/simplify/QA của đúng HEAD trước tích hợp.

Owner cung cấp task và các quyết định thực sự: release Spec, thay model/effort,
quyền/trust, nhánh cross-vendor và các mutation cần consent. Cross-vendor phải có
reviewer provider khác hoặc owner chọn off rõ ràng; chưa cấu hình thì còn thiếu,
không được báo pass hoặc gọi Codex tự review là cross-vendor.

## Phục hồi và dọn tài nguyên

- Timeout startup/queue/wait: đọc lại **cùng pane** và record trước khi hành động.
  Không relaunch chỉ vì timeout, không retry event có outcome chưa rõ.
- Interrupt hoặc restart: kiểm tra phiên còn sống; resume đúng UUID đã ghi bằng giao
  diện `codex resume` của CLI cài trên máy, không dùng `--last`. Kiểm tra lại cwd,
  branch, checkpoint và artifact. Pending queue có thể còn đó; không phát lại task.
- Owner đã chủ động dừng: chờ owner cho tiếp tục. Recovery prompt chỉ nhắc xử lý queue
  và checkpoint đang có, không chứa bản sao operation.
- Trước cleanup: giữ report ở checkout điều phối; xác nhận worker thuộc dispatch đã
  xong; đóng đúng pane/tab đã ghi. Kiểm tra tracked, untracked và ignored trước khi
  xóa worktree; không `--force`. Branch chỉ xóa khi đã tích hợp hoặc không có việc
  riêng. Ghi rõ tài nguyên giữ lại và lý do; không clear claim khi outcome chưa rõ.

Giới hạn đã đo: queue trong sandbox vẫn không khởi tạo được embedded app server;
profile `--herdr` cho phép Thomas tự gửi fallback và quan sát worker. Host→Thomas
queue đã đưa quyết định vào lượt tiếp theo. Không coi đó là queue hai chiều hoạt động.
[Native journey](IMPLEMENTATION-STATUS.md) có ba review Astra
và QA đúng dirty artifact. Các probe cũ default sandbox/host-driven ở LIVE-NATIVE-FLOW
là lịch sử riêng, không phủ nhận profile scoped mới đã chạy.

Các kiểm tra trên là trách nhiệm điều phối, không phải custom gate cưỡng chế. Harness
không có state machine, receipt service hay verifier engine riêng. Xem bảng kiểm
chứng để biết nhánh nào mới có contract và nhánh nào đã được đo thực tế.
