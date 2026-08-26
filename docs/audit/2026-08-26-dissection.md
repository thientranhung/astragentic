# Astragentic — bảng giải phẫu, 2026-08-26

Phiên hội chẩn trên `main` @ `a573803` (2.6.1). Mọi dòng dưới đây đã được kiểm bằng lệnh
hoặc bằng `file:line` trong repo. Chưa sửa gì.

Cột **Hạng**: `P0` = đang gây lỗi tái phát đo được · `P1` = có bằng chứng hỏng, chưa gây đau
hằng ngày · `P2` = nợ cấu trúc.
Cột **Cách chữa**: `HOOK` = rời prompt sang cơ chế · `MOVE` = cắt-dán về đúng chỗ, không thêm chữ
· `CUT` = xoá · `DEFINE` = viết ra thứ đang không tồn tại · `FIX` = sửa nội dung.

---

## A. Context và độ bền — vì sao Thomas quên

| # | Phát hiện | Bằng chứng | Hạng | Cách chữa |
|---|---|---|---|---|
| A1 | Cả 5 role contract nạp bằng `Read` → vào lịch sử hội thoại → **compaction nuốt trước tiên**. Tầng bền nhất (thân `.claude/agents/<role>.md`) chỉ giữ ~120 từ định danh | `.claude/agents/thomas.md` thân = *"Read `.agents/roles/thomas.md` now"* | **P0** | MOVE |
| A2 | AST-024 chữa role-bleed bằng cách đẩy contract xuống load-on-demand. Nhưng bleed đến từ `.claude/rules/` (tầng **toàn cục**); thân agent definition là tầng **riêng từng agent**, không thể rò | AST-024 `Bound:` `.claude/rules/role-thomas.md` (file nay không còn) | **P0** | MOVE |
| ~~A3~~ | ~~*đang ĐỎ*~~ — **RÚT LẠI, xem §Đính chính.** HEAD ship **xanh** (thomas 1942/1970, builder 1469/1500); đỏ là do sửa đổi chưa commit trong working tree | đo trên cây sạch tại HEAD | ~~P0~~ → **P2** | — |
| A3″ | `docs-staleness-audit.sh:25` đặt `ROOT="."` theo CWD, trong khi `ledger-index.sh:13-23` tự định vị bằng `BASH_SOURCE` **kèm chú thích về đúng lỗi này**. Hai script được bảo chạy *"in the same breath"* mà phân giải root khác luật — chính lỗi này làm phép đo đầu tiên của cuộc audit sai | `docs-staleness-audit.sh:25` | P1 | FIX |
| A4 | `INDEX.md` stale so với ledger | cùng lệnh trên, mục 5 | P1 | FIX |
| A5 | Không contract/skill nào chạy `docs-staleness-audit.sh` hay `check-reachability.sh`. Inbound chỉ có README + `ADAPT-HARNESS.md:314` (chạy 1 lần lúc adapt) | grep toàn payload | **P0** | HOOK |
| A6 | **73/134 entry ledger (54%) không được gì trích dẫn** *(sửa từ 87/65% — xem §Đính chính)* | `INDEX.md` cột `Cited by`, trừ 14 entry có trích trong `scripts/` | P1 | CUT |
| A9 | `ledger-index.sh` `CITE_DIRS` thiếu `scripts/` → mọi entry có phòng thủ bằng script đọc ra là uncited. **Lỗi đo, không phải nợ nội dung**, và nó làm sai chính bảng mục lục mọi role được dạy đọc | `ledger-index.sh` CITE_DIRS | **P0** | FIX |
| A7 | Kích thước entry lạm phát ~15×: AST-001…009 tb **21 từ** → nhóm AST-070s tb **519 từ**. Mỗi `grep -A40` mang về ~20–25% là rule | AST-133 = 350 từ cho rule 3 câu; AST-055 = 305 từ cho rule 1 câu | P1 | CUT |
| A8 | `.agents/skills/` và `.claude/skills/` là 18 file nhân đôi, đồng bộ **bằng tay**. Đã drift: `codex-arm/SKILL.md` bản `.claude` mất khối 13 dòng "On a non-Claude root" + cảnh báo treo. Không file nào tuyên bố hai bản được phép khác nhau | `diff -rq` | P1 | DEFINE |

---

## B. Rule không có răng

Ba rule bị vi phạm nhiều nhất trong ledger là đúng ba rule không có cơ chế nào.

| # | Phát hiện | Bằng chứng | Hạng | Cách chữa |
|---|---|---|---|---|
| B1 | `thomas.md:212` in đậm *"REQUIRED — `dispatch-ticket` **refuses** to dispatch without it"*. Cơ chế thật là một lệnh `echo` | `dispatch-ticket/SKILL.md:108-112` | **P0** | HOOK |
| B2 | Gate milestone của Rin kích hoạt bằng *"Thomas nói một câu"* mà không gì phát ra câu đó. Đo được **6 ngày / 107 merge / 33 ticket / 0 vòng Rin**. Cách chữa hiện tại: *"More than 10 merges is a STOP"* — chữa câu-nói bằng câu-nói, không có bộ đếm | `thomas.md:126-132` | **P0** | HOOK |
| B3 | Dòng `Ledger:` ở merge commit — **30/31 merge thiếu**. Người duy nhất bắt được là Rin, mà Rin chỉ chạy khi milestone được tuyên bố → vòng tròn | `thomas.md:133-135`, `rin.md:54-56` | **P0** | HOOK |
| B4 | *"Count the working panes after every merge, every handback and every report, and top up to the target"*. Đo được **2/4 slot rảnh với 12 ticket claimable, mọi bước đều làm đúng**. Rule phải tự viết câu phản bác bản năng model: *"Reporting is not a stopping point"* | `thomas.md:59-71` (AST-131) | **P0** | HOOK (`Stop`) |
| B5 | `.git/hooks/` **trống, không có pre-commit**. Nhưng `thomas.md:195` nói `check-payload-drift.sh` chạy ở pre-commit | `ls .git/hooks/` → 0 file non-sample | P1 | HOOK |
| B6 | Hook `WorktreeRemove` đăng ký nhưng nằm im. **Sự kiện có thật**, nhưng chỉ bắn cho worktree do Claude Code quản lý (session exit, subagent kết thúc, xoá background session). Thomas tạo/gỡ bằng Bash thuần → không bao giờ bắn. Entry đang bảo quản nó chờ *"ngày nó thức dậy"* | `settings.json`, AST-102:2339-2380 | **P0** | HOOK (chuyển sang `PostToolUse`) |

---

## C. Nhóm lỗi git — 33 entry, 9 cơ chế

Nhóm tái phát nhiều nhất được bảo vệ tệ nhất. Nhóm **duy nhất** không tái phát là nhóm **duy nhất** có script.

| Cơ chế | Số entry | Phòng thủ | Loại |
|---|---|---|---|
| Worktree lifecycle (ghost registration, path tái dùng, tài nguyên sống sót) | **7** | hook nằm im + văn xuôi | ✗ |
| Marker ↔ head ở merge | **7** | `check-simplify-markers.sh` | **SCRIPT ✓** |
| Isolation là thuộc tính của PATH không phải session | 5 | văn xuôi | ✗ |
| Fire point sai checkout / range 0 commit | 4 | văn xuôi | ✗ |
| Tracked-content-only | 4 | văn xuôi | ✗ |
| Stale claim / branch không dọn | 3 | script **không có khoảnh khắc bắn** | ✗ |
| Removal huỷ việc chưa commit | 2 | văn xuôi | ✗ |
| Branch sống lâu | 2 | văn xuôi | ✗ |
| Hai ticket không thứ tự đụng nhau ở merge | 1 | write-set (trong sổ không tồn tại) | ✗ |

| # | Phát hiện | Bằng chứng | Hạng | Cách chữa |
|---|---|---|---|---|
| C1 | Bản vá AST-096 (prune trước add · không nuốt output · assert HEAD) landed ở `codex-arm` + `review-with-rin` và **chưa bao giờ lan tới đường dispatch ticket** | `dispatch-ticket/SKILL.md:159-161` vẫn `list`/`add`/`list`, không prune | **P0** | FIX |
| C2 | `thomas.md:87` bảo kẻ thua claim race *"remove any worktree **directory** your attempt created"* — đúng động từ AST-096 cấm (để lại `.git/worktrees/<name>/`, lần `add` sau từ chối trong im lặng) | `thomas.md:87` vs AST-096:2082 | **P0** | FIX |
| C3 | Thứ tự cleanup sai hai chỗ: `prune` đặt **sau** `remove` (cần trước lần `add` kế), và việc kill broker/container **phải đi trước** removal vì sau đó `--cwd` không còn khớp — không được nhắc ở đây | `CLEANUP.md:113-115` vs AST-100:2314 | **P0** | FIX |
| C4 | `CLEANUP.md` chứa **0 lần** chữ "broker", trong khi `thomas.md:230` bắt buộc dọn tay mỗi lần gỡ worktree. Rule đúng, nằm trong mục **§Watchdog** | grep `broker` `CLEANUP.md` = 0 | **P0** | MOVE |
| C5 | Branch `trim-proportionality`: **0 commit chưa merge**, đứng im từ 2026-08-20. `CLEANUP.md:114` chưa từng chạy, không gì nhận ra | `git rev-list --count main..trim-proportionality` = 0 | P1 | HOOK (`Stop`) |
| C6 | `git branch -d` sau squash merge sẽ từ chối. `-D` được dành riêng cho abandonment có owner duyệt → người gặp từ chối hợp lệ **không có lối đi hợp lệ** và sẽ với tay sang `-D` | `CLEANUP.md:118` | P1 | FIX |
| C7 | Không có post-condition: không gì list lại worktree/branch sau khi gỡ, dù `:119` định nghĩa hoàn tất theo cách đó | `CLEANUP.md:119` | P1 | FIX |

---

## D. Thứ được tham chiếu nhưng không tồn tại

| # | Phát hiện | Bằng chứng | Hạng | Cách chữa |
|---|---|---|---|---|
| D1 | **"The dispatch record"** — `thomas.md:4` gọi là durable state ngang tracker/frontier; `:89` bắt ghi 7 trường vào đó; `linear-issue-tracker:83` ghi Builder identity vào đó; `dispatch-ticket:293` bắt **đọc ngược write-set của mọi ticket sống** ra từ đó để biết hai ticket có đụng nhau không. **Không path, không schema, không field.** Toàn bộ tính an toàn concurrency treo lên nó | grep toàn payload: 4 lần dùng, 0 lần định nghĩa | **P0** | DEFINE |
| D2 | `mkdir -p <gate-history-dir>` — lệnh chạy thật với placeholder chưa thay. Kho lưu "vì sao ta merge SHA này" không có địa chỉ | `review-with-rin/SKILL.md:154-155` | P1 | DEFINE |
| D3 | `SPEC:107` bắt *"Apply `writing-for-agents` from the plugin to **every document produced**"*. Skill này xuất hiện đúng 2 chỗ trong repo: dòng SPEC đó, và một **hằng số dự phòng bên trong chính checker**. Luật chi phối mọi tài liệu của package không có nhà | `check-reachability.sh:175` | **P0** | MOVE (1 dòng vào `builder.md:17`) |

---

## E. Vi phạm "one home per rule" của chính SPEC

`SPEC:117` — *"One home per rule. Everywhere else links. The prior package restated its gate law
in five places and they drifted apart."* Cái giá đã trả: 5 release liên tiếp chỉ để lan một bản
vá (`3650528` → `c969653` → `463c68c` → `ecb9013` → `50f294f`).

| # | Phát hiện | Bằng chứng | Hạng |
|---|---|---|---|
| E1 | Luật two-pass arm chép gần nguyên văn ở hai nơi | `builder.md:109-119` + `rin.md:113-120` | P1 |
| E2 | *"X advises, Thomas classifies"* xuất hiện 4 lần | `rin.md:69`, `review-with-rin:193`, `qa.md:132`, `dispatch-qa-walk:56` | P2 |
| E3 | Một diff bị review **3 lần bằng cùng nhạc cụ**: Builder chạy 2 trục `code-review` → Builder bắn arm → Rin chạy `mode=code-review` mà `rin.md:37` thừa nhận 2 trục đó là "hình dạng tự nhiên" | | P1 |
| E4 | Marker được xác minh **4 lần** | `builder.md:168`, `CLEANUP.md:67`, `thomas.md:177`, `rin.md:51` | P2 |
| E5 | 3 lần tracker-consistency ở cùng một khoảnh khắc | `thomas.md:199-205`, `reconcile-tracker:17`, `github-issue-tracker:126` | P2 |

---

## F. Đường nối với `mattpocock-skills`

Plugin có 35 skill (20 user-only, 15 model-invocable). Harness nhắc tên 11.
**Chỉ 1 skill được contract thật sự kích hoạt** (`code-review`, `builder.md:30`, vì nó là hàng
trong bảng "Phases you own" có cột *Ends when*). 9 cái còn lại nằm dưới câu *"the craft layer is
model-invoked and **needs no wiring**"* — 10 danh từ, 0 động từ.

| # | Phát hiện | Bằng chứng | Hạng | Cách chữa |
|---|---|---|---|---|
| F1 | `to-spec` **publish spec lên tracker kèm nhãn `ready-for-agent`** ngay khi đóng — trước khi `arm: spec` chạy. Tồn tại cửa sổ một spec chưa review đeo đúng nhãn "agent được phép vồ", và frontier query đọc chính tracker đó | `to-spec/SKILL.md:19` vs `shaper.md:37-52`, `thomas.md:36` | **P0** | FIX |
| F2 | `builder.md:29` ghi `implement` kết thúc *"khi acceptance criteria pass"*. `implement/SKILL.md` dài 15 dòng và **không có khái niệm acceptance criteria** | `implement/SKILL.md` toàn văn | P1 | FIX |
| F3 | `implement` bảo agent *"Use **/tdd**"* và *"use **/code-review**"* — dạng địa chỉ con người gõ. `implement` là `disable-model-invocation: true`, luôn chạy bởi agent không có bàn phím. **Đây là AST-051 nằm bên trong plugin**; `check-reachability.sh` check 6 không quét tới đó | `implement/SKILL.md`, AST-051 | P1 | FIX (ghi rõ trong brief) |
| F4 | `code-review` không có điểm neo: "the increment" không phải git ref, và `code-review:19` bảo *"nếu chưa cho ref thì hỏi"* — hỏi vào một pane không có ai. Brief đã mang sẵn `Base:` | `dispatch-ticket:281` | P1 | FIX (2 chữ) |
| F5 | `legacy-testing:62` leo thang seam lớn lên Shaper. `shaper.md` Load table **không có hàng `legacy-testing`** → handback rơi vào hư không | `shaper.md:13-19` | P1 | FIX |
| F6 | Rin `mode=code-review` dùng **đúng lệnh diff ba chấm** như plugin `code-review`, nhưng không mang baseline smell của Fowler → **gate milestone mù hơn gate per-ticket** | `review-with-rin:22-24` vs `code-review:21,45-56` | P1 | FIX |
| F7 | `improve-codebase-architecture` chỉ được nhắc như "thứ mà `untangle` không phải". Repo **có** module boundary hiện không có đường đi tới nó | `untangle/SKILL.md:3,8` | P2 | MOVE (1 hàng `shaper.md:17`) |

**Không phải trùng lặp — đã kiểm:** `untangle` và `legacy-testing` tự khai là lớp con của
`improve-codebase-architecture` và `tdd`, và khai đúng. `batch-triage` cũng vậy với `triage`.
Giữ cả ba.

**Bác bỏ, đã cân nhắc:** `handoff`/`claude-handoff` (lưu tmpdir; `builder.md:191` đã có rule
tốt hơn — *"evidence travels as files and commits"*), `grill-me` (thân nó chỉ là "chạy
`/grilling`"), `wait-what` (owner gõ *vào* agent, không role nào gọi được), `teach`.

---

## G. Điểm mù của bộ tự kiểm

| # | Phát hiện | Bằng chứng | Hạng |
|---|---|---|---|
| G1 | `check-reachability.sh` xanh 8/8, và tự khai check 3 *"cannot tell a skill that runs every session from one nobody has ever invoked, **and it goes green over both**"* | `check-reachability.sh:15-19` | P1 |
| G2 | Bộ kiểm chỉ quét skill **do harness sở hữu**; skill plugin chỉ được xác nhận là "tên phân giải được". **Không gì hỏi một skill plugin có được với tới hay không** | `check-reachability.sh:154,313-318` | P1 |

---

## Ba phòng thủ đề xuất — dùng cơ chế đã có thật

Schema hook đã xác minh với tài liệu chính thức: `matcher` là **chuỗi khớp TÊN TOOL**; payload
vào qua **stdin JSON** (`tool_name`, `tool_input.command`, `cwd`, `transcript_path`).
`PreToolUse` **chặn được** bằng `permissionDecision: "deny"`. `Stop` **chặn được** việc kết thúc
lượt. `PostToolUse` không chặn nhưng exit 2 hiện stderr cho Claude, và `additionalContext` bơm
được text Claude nhìn thấy.

### D1 — `PreToolUse` matcher `"Bash"`: tường lửa lệnh git
Diệt C1, C2, C3, C4 và nhóm isolation/tracked-content.
- `rm -rf` trỏ vào `.claude/worktrees/` → deny, nêu AST-096
- `git worktree add` đường dẫn tương đối, hoặc có `>/dev/null` → deny; **hook tự chạy `git worktree prune` trước khi cho qua**
- `git worktree remove <p>` → hook tự kiểm `git -C <p> status --short` và `pgrep -f <p>`; **tự kill broker + `docker stop` TRƯỚC** rồi mới cho gỡ (đúng thứ tự AST-100 cần — chính là đoạn code đang nằm chết trong hook `WorktreeRemove`)
- `git commit` khi branch hiện tại ≠ branch được giao → deny
- `git add -A` / `git add .` → deny, nêu path cần stage (AST-054 từng quét mất ~1000 file)

### D2 — `PreToolUse` trên `git merge`: gọi lại script đã có
`check-simplify-markers.sh <base> <head>` non-zero → deny, lấy chính dòng `STOP:` làm
`permissionDecisionReason`. Cộng: deny khi `git rev-list --count <base>..<head>` = 0.
Thêm `arm(ticket)` sau này tốn **một cờ**, vì `--marker` đã là data.
Kèm `additionalContext` bơm checklist merge đúng khoảnh khắc → B2, B3, B4 khỏi cần nằm trong prompt.

### D3 — `Stop`: quét dọn chặn kết thúc lượt
Chạy `ticket-git-facts.sh` (đã có, read-only, chỉ thiếu khoảnh khắc). **Chặn Thomas dừng lượt**
khi còn branch đã merge chưa xoá (C5 hôm nay) hoặc assignee không có branch.
`Stop` là sự kiện duy nhất bắn **bất kể agent có nhớ hay không** — và nó vá đúng
`thomas.md:70`, câu mà harness phải viết ra để chống bản năng mặc định của model.

**Cảnh báo:** `WorktreeCreate`/`WorktreeRemove` chỉ bắn cho worktree do Claude Code quản lý.
Đáng nối vào đúng một việc: `WorktreeCreate` assert payload đã tracked
(`test -f .agents/roles/builder.md`) trên worktree của fork/subagent — AST-036 × AST-130.
**Không** được để việc nối đó biến thành cớ tuyên bố đường dọn tay là thừa; AST-102 chính là
entry về đúng câu nói đó.

---

## Thứ KHÔNG hỏng — đừng đụng

- **Kỷ luật ledger.** Không role nào nạp sẵn 51k token; mọi Load table định tuyến qua INDEX rồi `grep` một entry. Thiết kế đúng.
- **Cold start không phình.** Thomas ~8.9k · Builder ~4.8k · Shaper ~2.5k · sàn chung ~1.16k.
- **`check-simplify-markers.sh`.** Sáu rule, kind là data, rule 5 (marker sống mới nhất **LÀ** head) bắt đúng lớp lỗi mọi kiểm-từng-trường bỏ sót. Đây là hình mẫu cho mọi gate khác.
- **Đường Codex/OpenCode.** Hết quota là chuyện thường ngày — đây là bảo hiểm đang có hiệu lực, không phải nợ.
- **Rin một vòng một milestone.** Vòng lặp bị cắt có chủ ý sau khi đo 5–14 vòng. Muốn khôi phục tranh luận thì phải có chặn cứng, không phải mở lại vòng lặp.
- **`untangle`, `legacy-testing`, `batch-triage`.** Lớp con khai báo đúng.

---

## Câu hỏi triết lý còn treo — của owner, không ai khác quyết được

Toàn bộ harness **không có cơ chế tranh luận ngang hàng**. Mọi bất đồng thoát qua hai cửa:
leo thang lên owner (`to-questionnaire`), hoặc gọi vendor khác.
`builder.md:81` — *"disagreement is a decision for the owner"*. `thomas.md:122` — *"Rin advises
and **you classify**"*. `shaper.md:51` — *"Only the **owner** may accept"*.

Harness thậm chí phải van ngược lại ở `thomas.md:235`: *"Resolve open questions rather than
routing every one to the owner — **that is the point of this harness**."* Một harness phải cầu
xin agent đừng làm phiền owner là một harness biết nó đang rò ở đâu.

Triết lý "phòng ban có tranh luận" hiện sống trong `docs/distilled/capabilities/party-mode.md`
(*"They clash, and you do NOT mediate"*) và chưa bao giờ được đưa vào `harness/`.

**Thay đổi cụ thể nếu owner muốn:** `thomas.md:120-124`, mục `## Review`. Thay *"Rin advises and
you classify"* bằng **quyền phản biện có giới hạn** — tác giả được đúng một lượt đáp lại, ghi
vào hồ sơ, và **chỉ phản biện chưa ngã ngũ mới leo lên owner**. Một cạnh Builder↔Rin ngang hàng,
giá đúng một vòng, có chặn cứng nên không tái diễn 5–14 vòng.

---

## H. Tầng issue tracker

Tầng ít được dogfood nhất trong harness: **gói này không tự nối vào tracker nào** (không có
`docs/agents/`), nên mọi tầng khác được chính repo dùng hằng ngày, riêng tầng này chỉ sống ở
project downstream.

### H0 — Ma trận phủ 5 yêu cầu × 3 adapter

Yêu cầu: `tracker-contract.md:36-42`.

| # | Yêu cầu | GitHub | Jira | Linear |
|---|---|---|---|---|
| 1 | Id ổn định trong TITLE | ✅ `github:46-64` | ⚠️ chỉ nhắc prefix `jira:125`; không format, không allocation query | ⚠️ giao cho project file; không nêu quy ước title |
| 2 | Năm trạng thái | ✅ `github:23-34` | ✅ gián tiếp `jira:26-46` | ✅ `linear:41-51` |
| 3 | **Assignee ghi + đọc lại NGUYÊN TỬ** | ❌ **hỏng, và tuyên bố ngược lại** | ❌ **vắng mặt hoàn toàn** | ❌ hỏng, **và khai thật** |
| 4 | Precondition là EDGE truy vấn được | ✅ `github:66-97` | ✅ tốt nhất — `jira:82-83` một JQL | ✅ `linear:64-72` |
| 5 | Bề mặt owner đọc được | ⚠️ tốn — board *"takes part in no query"* `github:118` | ✅ team-managed `jira:54-56` | ✅ `linear:26-28` |

| # | Phát hiện | Bằng chứng | Hạng | Cách chữa |
|---|---|---|---|---|
| H1 | **GitHub tuyên bố *"Requirement 3 is met natively"* trong khi lệnh assign duy nhất là `--add-assignee @me`** — một login cho mọi dispatcher. Cùng hoàn cảnh Linear nhưng **không có cơ chế thay thế nào được viết**, không readback rule, không release rule sửa đổi. Interlock tụt trong im lặng | `github:41` vs `github:149` | **P0** | FIX |
| H2 | **Jira: chữ `assignee` xuất hiện 0 lần trong toàn adapter.** Không claim, không release, không frontier query. `thomas.md:73-90` chạy nguyên xi mà không gì đỡ | grep `assignee` `jira-issue-tracker` = 0 | **P0** | FIX |
| H3 | `thomas.md:75` nói *"**Two independent atomic interlocks**"*. Chỉ **một** nguyên tử (`git worktree add -b`). Bước 2–3 là hai lời gọi API rời trên cả ba tracker; không adapter nào có compare-and-swap / ETag / `If-Match`. Chính `:84` đã thừa nhận race. Trên GitHub và Jira, bước 3 không "yếu" — nó là **no-op** | `thomas.md:75-85` | **P0** | FIX |
| H4 | Chuỗi nhân quả nối H1–H3 với D1 và C5: assignee không giữ được identity → identity đẩy vào **dispatch record (không tồn tại)** → release claim tụt xuống *"confirm the branch and worktree are gone"* → **không gì quét branch** → stale claim. `reconcile-tracker:83` key trên *"assignee set, no branch, no worktree"*, nên **một branch đã merge mà chưa xoá lại đọc ra là LIVE** — đúng trạng thái nó không thể gắn cờ | `linear:80-89`, `reconcile-tracker:83`, branch `trim-proportionality` | **P0** | DEFINE + HOOK |
| H5 | **Check 4 không bỏ qua `docs/agents/issue-tracker.md` — nó không bao giờ nhìn thấy.** Regex `:328` là allowlist tiền tố `(.agents\|.claude\|.opencode\|.codex\|scripts)/`. Docstring hứa *"HARD failure"*, dòng báo cáo nói *"every path referenced BY THE SCANNED FILES exists"* — **cả hai sai như đang viết**. Bộ kiểm duy nhất thật sự xét file này là `check-requirements.sh:354`, và chỉ ở mức **`warn`**, chỉ khi có tham số `<target>` | `check-reachability.sh:328`, `check-requirements.sh:344-361` | **P0** | FIX |
| H6 | `tracker-contract.md` **không nằm trong `sources` của check 4** (chỉ roles + supplements + skills) — cả `orchestrator.md` và ledger cũng vậy. Hệ quả sống: `:152` kê `tools/project-status-sync.sh --apply` trong khi script ở `.agents/skills/github-issue-tracker/`. `tools/` không tồn tại. Chú thích của chính dòng đó: *"skipping it is invisible"* | `check-reachability.sh:321-323`, `tracker-contract.md:152` | **P0** | FIX |
| H7 | Các đường dẫn khác bị allowlist che: `docs/agents/triage-labels.md` (`thomas.md:15`, `batch-triage:18`), `dispatch-ticket/WATCHING.md` | dẫn xuất từ H5 | P1 | FIX |
| H8 | `## Per tracker` (`tracker-contract.md:94-177`) = **799 từ, 32% file**, chép lại 10 sự kiện đã có trong ba adapter. Ví dụ nguyên văn: `:132` *"Hand-typed JSON escapes corrupted `Ưu tiên` into `Ư u tiên`"* ↔ `jira:93-95` cùng câu chuyện. Vi phạm `SPEC:117`, và **đã drift hai lần**: `:117-119` tự rút lại một tuyên bố board-mapping cũ, `:152` sai path trong khi adapter đúng. Mâu thuẫn với chính luận đề mở đầu file (`:7-13`) | | P1 | CUT |
| H9 | `reconcile-tracker` join bằng ticket id trong **commit subject**, và tự khai: *"a partial fix, a revert, a review-pass fold and a forward-citation all produce a hit"*. Lần chạy thật đầu tiên gắn cờ một phase ticket là "merged" dựa trên ba commit chỉ **nhắc tên** nó. Ticket chưa từng merge thì **không xuất hiện trong danh sách** | `reconcile-tracker:48-54, 92-95` | P1 | FIX |
| H10 | Không có oracle nào cho **edge sai hoặc thiếu**, dù `tracker-contract.md:216` nói *"a wrong edge is worse than a missing one"* | | P1 | DEFINE |
| H11 | **Race `ready-for-agent` (nối tiếp F1), truy tới cùng.** `thomas.md:47` định nghĩa frontier là *"every ticket whose blockers are all done and whose assignee is empty"* — **không lọc state, không lọc review**. Linear `:81` (`assignee: null`, non-terminal) → **ticket nổi lên**. GitHub `:104` tình cờ chặn được vì lọc nhãn `todo`, tức chặn bằng **lệch từ vựng nhãn**, không phải bằng gate; project tự soạn map nhãn→cột (`github:169`) nên thêm `ready-for-agent` vào đó là mất luôn lớp chặn tình cờ. **Jira không có frontier query nào** → hành vi không xác định. Không adapter, không bước `dispatch-ticket`, không dòng `thomas.md` nào ràng buộc claimability vào việc `arm: spec` đã trả về | `to-spec:19`, `thomas.md:47`, `linear:81`, `github:104` | **P0** | FIX |

### H — ba cách chữa rẻ nhất

1. **Sửa 4 dòng trong check 4.** Thêm `docs|tools` vào alternation `:328`; thêm `.agents/*.md` vào `sources` `:321-323`; in dòng scope nêu rõ phần project-side bị loại trừ. Bắt ngay H6, và làm cho màu xanh mang đúng nghĩa docstring hứa.
2. **Sửa `github:41` và chép đoạn Linear đã viết sẵn sang GitHub + Jira.** Thay *"Requirement 3 is met natively"* bằng sự thật đo được, rồi tái dùng `linear:80-89` nguyên văn (git quyết định race · để assignee y nguyên khi thua · release bằng xác nhận worktree+branch đã mất). Hạ `thomas.md:75` xuống *"một interlock nguyên tử cộng một readback mang tính tham khảo"*. **Rồi định nghĩa dispatch record** (D1) và cho nó heading `## N. Write \`path\`` để check 8 phủ được, đồng thời thêm `git branch --merged` vào lớp stale-claim của `reconcile-tracker`.
3. **Cắt `## Per tracker` xuống bảng ba dòng trỏ sang adapter.** −799 từ, −10 sự kiện trùng, bỏ luôn một tuyên bố đã rút lại và một path sai.

**Cần owner quyết, không phải sửa:** `thomas.md:47` có lẽ nên đọc là *"…and whose **state is the claimable state**"* — năm chữ đóng H11 trên cả ba tracker. Nhưng nó đổi ngữ nghĩa frontier và tương tác với `:52-54` (*"Read edges and state, never the readiness label"*), nên là quyết định của owner.

---

## ĐÍNH CHÍNH mục A6 (2026-08-26, sau khi audit tầng herdr)

A6 ghi *"87/134 entry (65%) không được contract nào trích dẫn"*. **Con số đó thổi phồng.**

`ledger-index.sh` — script sinh cột `Cited by` — quét `CITE_DIRS`:
`.agents/roles` · `.agents/skills` · `.claude/agents` · `.claude/skills` · `orchestrator.md`.
**Không có `harness/scripts/`.** Nên mọi entry có phòng thủ nằm trong một **script** đều bị
đọc là uncited.

| | |
|---|---|
| INDEX gọi là uncited | 87 |
| …thực ra có trích trong `harness/scripts/` | **14** |
| …thật sự không ai trích | **73 (54%)** |

**A6 sửa thành 73/134.** Và 14 entry kia là loại **tốt nhất** trong ledger — đã chuyển thành
code. INDEX đang dán nhãn "chết" lên đúng những entry trưởng thành nhất.

**A9 (mới, P0)** — `ledger-index.sh` `CITE_DIRS` thiếu `scripts/`. Đây là **lỗi đo, không phải
nợ nội dung**, và nó làm sai lệch chính bảng mục lục mà mọi role được dạy đọc thay cho ledger.
Cách chữa: thêm một dòng vào `CITE_DIRS`. → `FIX`

---

## I. Tầng QA walk

Role contract **duy nhất không có một trích dẫn `AST-` nào**: `qa.md` = 0, `dispatch-qa-walk` = 0
(so với `builder.md` = 8, `rin.md` = 5). Ledger có **10 entry** về lớp lỗi này và **không entry
nào sinh ra script nào bắn cho QA**.

| # | Phát hiện | Bằng chứng | Hạng | Cách chữa |
|---|---|---|---|---|
| I1 | **Ba entry là cùng một thất bại, ghi ba lần qua ba thiết kế**: AST-045 *"a browser-walking agent shipped for several releases and never ran once"* · AST-057 *"a browser walker shipped across releases that never ran once"* · AST-135 *"nine fold rounds and one merge in half a day, and **QA was never dispatched at all**"* | `:607`, `:949`, `:3482` | **P0** | HOOK |
| I2 | Trigger là câu phán đoán, **mềm hơn cả gate Rin**. Rin được cấp ngưỡng đếm được (*">10 merges is a STOP"*); QA mắc cùng bệnh, không có nhiệt kế. Điều kiện *"anything with a user-visible surface"* là phán đoán người điều phối tự đưa ra về khối lượng việc của chính mình. Merge chỉ kiểm 2 marker, không marker nào của QA | `thomas.md:137-139` vs `:126-132`, `:177-178` | **P0** | HOOK |
| I3 | **Verified-clean list không có địa chỉ** — 6 lần nhắc, 0 path. Nhưng `qa.md:127` gọi nó là *"phần duy nhất của walk có tính tích luỹ"* và `dispatch-qa-walk:54` bắt Thomas đóng gói nó vào brief. Thomas phải cung cấp một input bắt buộc mà không tài liệu nào nói nó ở đâu → walk gia tăng (**mặc định**) thoái hoá thành walk lại từ đầu | grep `verified-clean` = 8 hit, 0 path | **P0** | DEFINE |
| I4 | **Báo cáo walk không có nơi đến và không ai bắt buộc đọc.** `GATE_FILE` = 0 hit trong cả `qa.md` lẫn `dispatch-qa-walk` (`rin.md` = 2). Không có heading `## N. Write \`path\`` → check 8 mù, dù check 8 sinh ra đúng cho lỗi này | grep `GATE_FILE` | **P0** | DEFINE |
| I5 | Browser consent: `qa.md:77` nói *"required dispatch field"*, `dispatch-qa-walk:39-54` liệt kê 5 mục brief và **consent không nằm trong đó**. AST-056 nêu đích danh consent làm **ví dụ mẫu** cho việc rule phải là FIELD chứ không phải prose — và đó là cái duy nhất chưa được cấp ô | `qa.md:77` vs `dispatch-qa-walk:39-54`, AST-056:889 | P1 | FIX |
| I6 | COVERAGE GAPS là *"first-class section"* của báo cáo nhưng **không ai đọc**: `thomas.md` và `rin.md` không nhắc lần nào. **Một walk bị từ chối hoàn toàn và một walk sạch không phân biệt được ở hạ nguồn** | `qa.md:122-125` | P1 | FIX |
| I7 | **Hai skill bất đồng về tên thư mục**: `dispatch-qa-walk:14,29` nói `gate-walk-<key>`; nhưng nó uỷ thác toàn bộ cơ chế cho `review-with-rin` §2-3, nơi lệnh thật tạo `gate-<key>` | `:85` | P1 | FIX |
| I8 | **Cleanup thừa hưởng một tiền đề sai với QA.** `review-with-rin:126` dùng `git worktree remove` trần, giải thích *"Rin ghi gì trong gate worktree nên cây sạch"*. `dispatch-qa-walk:29` nói ngược: *"a running app writes caches, logs and local state"*. `remove` từ chối khi có untracked → kết quả **bình thường** của walk đọc ra như bất thường | | P1 | FIX |
| I9 | **Không có bước dừng container**, dù walk là thao tác nhiều container nhất. `codex-arm` đã bị AST-100/AST-101 ép thành ba bước có thứ tự; QA chỉ có một câu văn *"Stop the app and confirm the port is free"* — không PID, không port, không container. AST-115: một `db-down` trông có vẻ scoped đã tắt **container test dùng chung mọi Builder đang đứng lên** | `dispatch-qa-walk:61-62` vs AST-101:2334 | **P0** | FIX |

---

## J. Tầng herdr / pane / liveness — lớp lỗi lớn thứ hai

| # | Phát hiện | Bằng chứng | Hạng | Cách chữa |
|---|---|---|---|---|
| J1 | **Hai trong ba runtime có tín hiệu idle không thể báo lỗi.** opencode: idle **bịa** — `fallback_reason: default_known_agent_idle_fallback`; `agent wait --until idle` trả rc=0 trong **8ms** trên pane chưa ai đụng; manifest 3 rule so với claude 12, codex 7 | `dispatch-ticket-opencode:65-70` | **P0** | FIX |
| J2 | `TERMINAL:done` mang **năm nghĩa**: xong · PARKED · STUCK · CRASHED · PARKED vĩnh viễn | `:2148-2161` | P1 | FIX |
| J3 | **Một dòng làm mù toàn bộ watchdog.** Tra Thomas **chỉ bằng title**; không thấy → `sys.exit(0)` → mọi cảnh báo pane trong lượt poll biến mất. AST-084 đã đo Claude ghi đè title, và bản vá được áp vào `is_dispatched()` **cách đó 12 dòng** mà không áp vào đây | `herdr-watchdog.sh:453-463` | **P0** | FIX |
| J4 | **Lỗ hổng thường trực**: `STUCK` đòi **không pane nào đang chạy**. *Builder xong việc trong khi Builder khác còn chạy* → im lặng vô hạn. Với 3 Builder song song đây là **trạng thái bình thường** | `herdr-watchdog.sh:508,527` | **P0** | HOOK (`Stop`) |
| J5 | Probe watcher **fail-open**: `pgrep` ném exception → `has_w = True`. Một phép dò hỏng sẽ **trấn an** thay vì báo động | `:521-523` | **P0** | FIX (1 dòng) |
| J6 | Heartbeat watchdog — tín hiệu **duy nhất** một vòng lặp kẹt không giả được — **không có người đọc nào**. grep toàn payload chỉ ra người ghi. Đúng hình dạng AST-129 | `herdr-watchdog.sh:89,575-586` | **P0** | HOOK |
| J7 | Cổng watchdog dùng `pgrep -f` chuỗi trần — **đúng dạng nhận diện mà chính watchdog bác bỏ** (`:106-118`: `tail -f herdr-watchdog.sh` lọt qua form đó). Cổng lại **không scope theo workspace** trong khi watchdog thì có → watchdog project A thoả mãn cổng project B | `dispatch-ticket:110` vs `herdr-watchdog.sh:81-118` | **P0** | HOOK |
| J8 | Các "từ chối" khác thực ra là `echo`: cổng payload AST-036 (`dispatch-ticket:144`), adapter check (`dispatch-ticket-claude:47`, `-opencode:36`). Đối chiếu: `codex-arm:79,93,96` và `review-with-rin:72-80` dùng `exit 1` thật | | P1 | FIX |
| J9 | Template launch hardcode `--effort` trong khi `:38` nói chỉ thêm khi row có giá trị — đúng hình dạng AST-127, chưa sửa | `dispatch-ticket-claude:116,123` | P1 | FIX |
| J10 | **Trên opencode cổng AST-097 thoái hoá âm thầm**: `dispatch-ticket:376-386` đòi **cả hai** nguồn (pgrep + status line), nhưng opencode fact 5 nói transcript read trả về rỗng → còn lại `pgrep` đơn độc, đúng nguồn đã trả lời sai ngoài thực địa | | **P0** | FIX |
| J11 | Quy tắc phát hiện truncation nêu **đúng một lần** (`dispatch-ticket:418-422`) và **không nơi nào khác trích**. Trong khi quyết định PARKED/CRASHED/STUCK — từ đó dẫn tới gỡ worktree — lấy từ một lần đọc pane có thể bị cắt (`:380`) | | **P0** | MOVE |
| J12 | Họ AST-032 tái phát **sáu release**: 032 → 037 → 097 → 107 → 124 → 125. Chuỗi tự-liveness của watchdog tái phát **năm**: 072 → 075 → 076 → 077 → 078 → 079 | | — | — |

---

## K. Bộ brownfield

| # | Phát hiện | Bằng chứng | Hạng | Cách chữa |
|---|---|---|---|---|
| K1 | **SPEC hứa sáu deliverable, ship bốn.** Item 1 *Standards extraction* và item 6 *Boundary enforcement* không có skill nào | `SPEC:86-100` | P1 | FIX |
| K2 | **Chỉ `SPEC:102` cũ** *(thu hẹp từ bản gốc — xem §Đính chính)*: thì hiện tại, giọng còn sống — *"`code-scout` … **are** the reading layer"*, trong khi 1.6.1 đã xoá nó (`RELEASE-NOTES.md:3007`). `docs/adr/0001:113` chép cùng câu. **`SPEC:31` KHÔNG sai** — nó nằm dưới *"Carry over from the prior package · From `v1` branch"*, là đường dẫn nguồn ở gói cũ | `sed -n '24,32p' SPEC-1.0.0.md` | ~~P0~~ → **P1** | FIX |
| K3 | Không skill nào trong bốn có **trigger vật lý**. Hai bootstrap do owner gõ; `legacy-testing` và `untangle` kích hoạt bằng **cảm giác** | | P1 | — |
| K4 | `thomas.md:38` nói *"chạy lại khi output đi cũ"* — **không có bộ dò staleness nào**. Nhưng **quan sát được đã có sẵn và không ai dùng**: `bootstrap-glossary:59` ghi header tự mô tả `Seeded from code 2026-08-10 · 23 terms · 0 CONFIRMED · 21 UNREVIEWED · 2 AMBIGUOUS` — một ngày và bốn con số, máy đọc được, đúng lớp mà `docs-staleness-audit` axis 2 đã kiểm | | P1 | FIX |
| K5 | **`bootstrap-glossary` ghi `CONTEXT.md` sai định dạng của chính skill đọc nó.** Nó emit `### Term` + `- read from: file:12` + `- status: UNREVIEWED`; `domain-modeling/CONTEXT-FORMAT.md:10-29` đòi `## Language` + `**Term**:`, không có field status, không citation, và `domain-modeling/SKILL.md:64` nói `CONTEXT.md` phải *"totally devoid of implementation details"*. Check 7 cho qua vì nó chỉ tìm chuỗi `CONTEXT.md` ở hai đầu, **không kiểm hai đầu đồng ý về định dạng** | | **P0** | FIX |
| K6 | Nhãn `UNREVIEWED` xuất hiện **chỉ trong chính `bootstrap-glossary`**, 0 lần trong toàn plugin. **Chín skill plugin nạp `CONTEXT.md`** mà không biết field đó tồn tại → mọi skill đọc trích xuất chưa xác nhận như từ vựng đã xác nhận. Đúng thứ `bootstrap-glossary:8-11` sinh ra để ngăn | | **P0** | FIX |
| K7 | `legacy-testing:62` leo thang seam lớn lên Shaper; `shaper.md` **không có hàng**. Và chặng trung gian cũng rỗng: **chữ "seam" xuất hiện đúng một lần trong `thomas.md`**, ở `:169`, nói về spec arm | | P1 | MOVE |
| K8 | `untangle:78` ghi ra *"nơi project giữ ghi chú kiến trúc"* — **không path, không tên file, không người đọc**. Đúng hình dạng AST-071, và vô hình với check 8 chính vì không có path | | P1 | DEFINE |
| K9 | `untangle` (model-invoked) trỏ model sang `to-tickets` — mà `to-tickets` là `disable-model-invocation: true`. Đúng lỗi `thomas.md:42` nêu tên. Vô hình với check 6 vì viết bằng backtick trần | `untangle:47` | P1 | FIX |
| K10 | **Không có bằng chứng nào trong ledger hay RELEASE-NOTES rằng bất kỳ skill nào trong bốn đã từng chạy trên project thật.** RELEASE-NOTES có field report đích danh cho dispatch, arm, herdr — không có cái nào cho brownfield | | P1 | — |
| K11 | Ba khai báo seam với plugin (`untangle`↔`improve-codebase-architecture`, `legacy-testing`↔`tdd`, `batch-triage`↔`triage`) — **kiểm và đều chính xác**. Khoảng trống thật là **đường chính**: không gì định tuyến một repo *có* module boundary tới `improve-codebase-architecture` | | P2 | MOVE |

---

## ĐÍNH CHÍNH A3 và K2 (2026-08-26, sau khi audit tầng release)

### A3 — SAI như đã viết. Rút lại.

A3 ghi *"`docs-staleness-audit.sh` đang ĐỎ: thomas.md 2095/1970, builder.md 1832/1500"*.
Đo lại trên **cây sạch tại HEAD** (`git worktree add --detach /tmp/ast-clean HEAD`):

```
ok: roles/thomas.md  = 1942/1970 words
ok: roles/builder.md = 1469/1500 words
```

**2.6.1 ship XANH.** Màu đỏ tôi báo cáo đến **toàn bộ từ các sửa đổi chưa commit trong
working tree** (`git status` đầu phiên: `M roles/thomas.md`, `M roles/builder.md`, …). Tôi đã
nhầm trạng thái cây làm việc với trạng thái đã ship.

**Hệ quả với luận điểm:** lập luận của commit `54c85c2` (*"đặt tên trong README chứ không
trong contract là cố ý"*) **chưa từng bị bác bỏ** — nhịp kiểm đã giữ được ở mọi mốc release.
Luận điểm "phanh chống phình đã ngừng hoạt động" mà tôi đưa ra trong phiên hội chẩn là **sai**.

**Phần còn đúng, đã hạ hạng:**
- **A3′ (P2)** — không gì đo working tree, nên owner đang mang các sửa đổi chưa commit sẽ
  trượt gate, và không gì báo. Đây là bất tiện, không phải hỏng.
- **A3″ (P1, mới)** — `docs-staleness-audit.sh:25` đặt `ROOT="."` (theo CWD), trong khi
  `ledger-index.sh:13-23` tự định vị bằng `BASH_SOURCE` **kèm chú thích về đúng lỗi này**.
  Hai script được tài liệu bảo chạy *"in the same breath"* nhưng phân giải root theo hai luật
  khác nhau. Chính lỗi này khiến phép đo đầu tiên của cuộc audit sai. → `FIX` (copy-paste)

### K2 — SAI một nửa. Thu hẹp.

K2 ghi *"`SPEC:31` nêu hai thư mục không tồn tại"*. `SPEC:31` nằm dưới heading
**`## Carry over from the prior package`**, cột **`From v1 branch`**. Đó là đường dẫn nguồn ở
gói **v1**, vắng mặt ở đây là **đúng**. Ba mục khác cùng bảng (`codex-plan-gate/`,
`dispatch-slice/`, `docs/governance/…`) cũng vậy.

**Chỉ `SPEC:102` thật sự cũ** — thì hiện tại, giọng còn sống: *"`code-scout`, the codemaps and
the staleness audit **are** the reading layer."* `docs/adr/0001:113` chép cùng câu.
`code-scout` bị xoá ở 1.6.1 (`RELEASE-NOTES.md:3007`).

**K2 sửa thành P1**: sửa tay `SPEC:102` + `ADR 0001:113`, và ghi ở đầu SPEC rằng đây là
**build spec lịch sử**. **Không** đưa SPEC vào `sources` của check 4 — SPEC và `docs/adr/`
chỉ ở repo root, **không nằm trong payload và không được stage** (`install.sh:194-212`), nên
không agent nào trong project đã adapt đọc được. Đưa vào sẽ bắn báo động giả trên năm tham
chiếu v1 đúng để bắt một tham chiếu sai.

---

## L. Tầng release / install / adaptation

| # | Phát hiện | Bằng chứng | Hạng | Cách chữa |
|---|---|---|---|---|
| L1 | **`check-requirements.sh` không thể fail trên trục TARGET.** Đo trực tiếp: `git init` một thư mục rỗng, không có harness gì → `All required checks passed. EXIT=0`. Ba doc `docs/agents/*.md` dùng `warn()` (không set `fail=1`), không phải `miss()` | `check-requirements.sh:35-36, 354-362`; đo trên `/tmp` | **P0** | FIX |
| L2 | **Phát hiện yếu làm câm phát hiện mạnh.** Thiếu ba doc → `TARGET_READY=0` (`:360`) → **chặn luôn** phép kiểm payload-đã-commit của AST-036 ở `:373`. Cây worktree Builder không nhìn thấy contract là lỗi nặng hơn, và nó bị lỗi nhẹ hơn bịt miệng | `:360` vs `:373` | **P0** | FIX |
| L2′ | *Lưu ý phản biện:* text của `warn` ghi *"expected to be absent **before then**"* — nó là `warn` **có chủ ý** cho ca trước-adaptation. Đổi thẳng `warn`→`miss` sẽ phá ca dùng hợp lệ. Khiếm khuyết thật là **không có chế độ sau-adaptation**: một lệnh phải trả lời hai câu hỏi khác nhau với một mức nghiêm ngặt duy nhất | | — | thiết kế |
| L3 | **`check-payload-drift.sh` không ai chạy.** `.git/hooks/` = 14 file, toàn `.sample`, 0 hook sống. `grep check-payload-drift prompts/ADAPT-HARNESS.md` = **0 hit** — adaptation không cài hook, không tạo manifest, không nhắc tên script. `README.md:366` và `thomas.md:195` đều rào bằng *"where a project has installed one"*, và **không gì trong pipeline làm điều kiện đó thành đúng** | | **P0** | HOOK |
| L4 | **`applied-version` được ghi kể cả khi còn conflict.** `install.sh:332` chạy **trước** báo cáo conflict `:334`. Một lần `--apply` để lại 20 file chưa hoà giải vẫn đóng dấu `2.6.1` — mà dấu đó là trọng tài cho lần upgrade sau (`:270`) **và** là manifest quyền sở hữu của `check-reachability` (`:119`). Một lần apply hỏng đầu độc cả hai, im lặng | | **P0** | FIX |
| L5 | `.codex/profiles/*.config.toml` **không nằm trong `OWNER_PATHS`** dù `ADAPT-HARNESS.md:110-112` gọi nó là scaffold ngang `orchestrator.md`. Nó sống sót chỉ vì arbitration tình cờ rơi vào `kept`/`CONFLICT` — ngẫu nhiên, không phải khai báo | `install.sh:265` | P1 | FIX |
| L6 | **§4 chúc phúc cho trạng thái §6 bác bỏ.** `ADAPT-HARNESS.md:246-248` cho phép project gitignore `.astraler/` (*"Do not reach for `git add -f`"*). Nhưng `check-reachability.sh:115-153` glob `.astraler/releases/<v>/…`, rỗng → `fail("0")` → hard exit 1. Trên mọi bản clone mới của project như thế, gate §6 hỏng **vĩnh viễn** ở check 0 | | **P0** | FIX |
| L7 | **`ADAPT-HARNESS.md` §6 tự mâu thuẫn**: bảo chạy `bash -n` trên shell script, nhưng `check-reachability.sh` là **Python đội đuôi `.sh`** — `bash check-reachability.sh .` thoát 2 với `import: command not found`. `README.md:384` viết đúng (`python3 …`) | | P1 | FIX |
| L8 | **Không có bộ dò desync `CANDIDATE` ↔ `applied-version`.** `install.sh:236` ghi CANDIDATE mỗi lần stage; `:332` ghi applied-version chỉ khi `--apply`. Không gì so hai cái | | P1 | DEFINE |
| L9 | **Kiểm gương chỉ phủ `SKILL.md`.** `install.sh:45-59` bỏ qua các file anh em: `WATCHING.md`, `CLEANUP.md`, `project-status-sync.sh` — mà `WATCHING.md` **đang được sửa tay ở cả hai cây ngay lúc này**. `:49` `[ -f "$claude_skill" ] \|\| continue` → skill chỉ có ở một cây thì bị bỏ qua; vòng lặp không bao giờ duyệt `.claude/skills` nên skill chỉ-có-ở-`.claude` là vô hình | | **P0** | FIX |
| L10 | **Allowlist gương mục ruỗng.** `install.sh:44 DIVERGENT_ALLOWLIST="codex-arm review-with-rin"`. Drift của `codex-arm` là **hợp lệ** (bản `.claude` bỏ đúng nhánh `codex exec review` chỉ dành cho non-Claude root). Nhưng **`review-with-rin` lệch 0 dòng** — một miễn trừ chết, đang che mọi drift tương lai của cặp đó. **Đó mới là lỗ hổng, không phải `codex-arm`** | | P1 | CUT |
| L11 | `install.sh` từ chối stage khi RELEASE-NOTES sai heading (`:34`) và khi gương lệch (`:60`), nhưng **không chạy cái nào** trong `check-reachability` / `docs-staleness-audit` / `ledger-index --check` (`:203` chỉ là comment). Đây là khoảnh khắc duy nhất cadence thật sự quan trọng | | **P0** | FIX |
| L12 | `RELEASE-NOTES.md` = 34.069 từ / 219 KB / 111 heading. **Không role contract nào đọc.** Nhưng `ADAPT-HARNESS.md:13` bảo agent đọc nó **"first"**, không giới hạn phạm vi — **~50k token mỗi lần adaptation**, và một bản đầy đủ được nhân vào **mọi** `.astraler/releases/<version>/` | | P1 | FIX |

**Điểm sáng đã kiểm:** đường `install.sh --apply` là cơ chế **được thực thi bằng code**, không
phải văn xuôi — `OWNER_PATHS` (`:265`, thực thi `:288-296`) và trọng tài ba chiều với
`$PREV_DIR` (`:313-326`) fail **đóng** khi không có release trước. Đây là phần chắc chắn nhất
của pipeline. Vấn đề nằm ở **đường mặc định**, nơi toàn bộ hợp đồng được giao cho một LLM đọc
`ADAPT-HARNESS.md` và **không gì xác minh nó đã chạy hay kết quả có được tôn trọng**.
