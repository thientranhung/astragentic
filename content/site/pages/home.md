# `/` — Trang chủ

Ngôn ngữ: **tiếng Anh là bản chính**, tiếng Việt là bản song song, theo đúng cách `README.md`
và `README.vn.md` đang làm.

Mục đích: đưa người đọc từ *"tôi từng gặp chuyện này"* tới *"tôi hiểu hình dạng lời giải"*
trong dưới 90 giây, rồi thả họ vào một trong bốn trang sâu. Trang chủ **không** giải thích
đầy đủ bất cứ thứ gì — mỗi khối kết bằng một đường dẫn đi tiếp.

Bảy khối. Không CTA nào trước khối 7.

---

## Khối 1 — Hero

- **Eyebrow:** `ORCHESTRATION LAYER FOR CODING AGENTS`
- **Headline:** **Several coding agents. One codebase. No collisions.**
  - `No collisions` tô `--pass`. Đây là lần duy nhất accent xuất hiện ở màn hình đầu.
- **Body:** Astragentic is the layer under your agents: isolation, dispatch, review, and a record of everything that ran.
- **Component:** căn giữa, cột 620px. Không ảnh, không nút, không logo hoạt hoạ.

Không có nút "Get started" ở đây. Người đọc chưa có lý do bấm, và pi.dev cũng không đặt nút ở
màn đầu — chỗ đó là một khối cài đặt tĩnh, đọc được, không đòi hỏi gì.

**Bản VN:** *Nhiều agent. Một codebase. Không va nhau.*

---

## Khối 2 — Chỗ nó vỡ

- **Eyebrow:** `THE FAILURE MODE`
- **Headline:** **One checkout, two agents, one lost afternoon.**
- **Body:** Two agents share a checkout. One moves `HEAD` while the other is mid-edit. A reviewer switches branch under the builder. Nothing errors — the work is just gone.
- **Component:** Defect card đơn, mã `AST-016`. Đây là lần đầu `--defect` xuất hiện trên site.
- **Kết:** `See what else breaks →` `/why`

Đây là **khối duy nhất** trên trang chủ được nói về nỗi đau. Một ví dụ, cụ thể, có mã.
Danh sách đầy đủ nằm ở `/why`. Trang chủ không được biến thành bản kê nỗi sợ.

---

## Khối 3 — Làn song song

Khối trung tâm. Đây là **một hiệu ứng chuyển động duy nhất** của toàn site.

- **Eyebrow:** `ISOLATION`
- **Headline:** **One ticket, one worktree, one pane.**
- **Body:** Every Builder gets its own branch and its own checkout. Concurrency stops being a race — git decides the claim, and the tracker records who holds it.
- **Component:** Lane diagram, phá khung ra 1100px.

**Spec sơ đồ.** Bốn làn dọc, cách nhau đều, mỗi làn rộng như nhau — không làn nào nổi hơn
làn nào, vì bình đẳng chính là ý. Mỗi làn mang một mã ticket mono (`TRA-139`, `TRA-142`,
`TRA-125`, `TRA-087`). Mỗi làn có một chấm nhỏ chạy dọc qua bốn chặng có nhãn:
`claim → build → review → merge`. Bốn chấm **lệch pha nhau**, không bao giờ ngang hàng.
Các làn **không có đường nối ngang** — đó là điểm chính của cả hình: chúng không chạm nhau.
Chu kỳ 12s, `ease-in-out`, dừng hẳn khi `prefers-reduced-motion: reduce` và giữ trạng thái
tĩnh ở bốn vị trí lệch nhau.

Texture nền của site cũng là làn dọc, nên hình này đọc như phần nền bỗng sống dậy.

---

## Khối 4 — Bốn cơ chế

- **Eyebrow:** `WHAT IT DOES`
- **Headline:** **Four mechanisms, each leaving a trace.**
- **Component:** Compare grid 4 cột. Mỗi cột: tên mono, một câu, một Receipt thật.

| | Isolation | Dispatch | Review | Provenance |
|---|---|---|---|---|
| Một câu | One worktree per ticket | The tracker answers what is ready | Two axes, one pass, then a second vendor | Every commit says which pass ran |
| Receipt | ảnh workspace 4 pane | ảnh frontier query | trích arm report thật | trích `git log` có dòng `Pass:` |

Receipt là **artifact thật chụp từ project đang chạy**, không phải hình minh hoạ. Khối này
không có chữ nào thừa: mỗi cột một câu, phần còn lại là bằng chứng.

- **Kết:** `How it fits together →` `/architecture`

---

## Khối 5 — Ba con số

- **Eyebrow:** `MEASURED`
- **Component:** Stat trio (mượn từ aihero.dev).

| Số | Nhãn | Nguồn |
|---|---|---|
| **136** | `FAILURE MODES, LOGGED` | `harness/.agents/memory/recurring-failure-modes.md` |
| **5–14 → 1** | `REVIEW ROUNDS` | `docs/adr/0001` |
| **3** | `RUNTIMES` | Claude Code · Codex · OpenCode |

Con số giữa là con số mạnh nhất trên site, vì nó là một **thay đổi đo được**, không phải một
lời khoe. Ghi đúng dạng "từ 5–14 xuống 1", không rút gọn thành "1".

- **Kết:** `Read the ledger →` `/evidence`

---

## Khối 6 — Nó không phải cái gì

Khối làm site đáng tin hơn mọi khối còn lại cộng lại. pi.dev có đúng khối này
(*"What we didn't build"*), và họ đặt nó gần cuối — cùng vị trí.

- **Eyebrow:** `WHAT THIS IS NOT`
- **Headline:** **Four things Astragentic does not do.**
- **Component:** danh sách 4 dòng, mono cho vế đầu, serif cho vế giải thích. Không icon.

| Không phải | Vì |
|---|---|
| **Not a model, not an agent CLI** | It runs on Claude Code, Codex and OpenCode. |
| **Not the engineering method** | The method is rented from `mattpocock-skills`. Astragentic orchestrates it. |
| **Not usable without a tracker** | GitHub, Jira or Linear. The tracker is the coordination substrate, not a nice-to-have. |
| **Not proven end to end** | Its checks prove the tooling is correct. Nothing yet proves the whole loop. |

Dòng thứ tư là câu tự viết của `RELEASE-NOTES.md` 2.7.12. Đưa nó lên trang chủ chứ không
giấu xuống `/evidence` là nước đi mạnh: một trang giới thiệu tự nêu giới hạn của mình đáng tin
hơn mọi lời quảng cáo quanh nó.

- **Kết:** `Where it sits on the map →` `/compare`

---

## Khối 7 — Đường vào

Chỗ **duy nhất** có CTA, và nó nhỏ.

- **Eyebrow:** `GETTING IN`
- **Body:** Four commands and one agent-run installer. It needs Claude Code, git worktrees, herdr, and the `mattpocock-skills` plugin.
- **Component:** một khối `--paper-sunk` chứa lệnh, một `[ COPY ]` kiểu pi.dev, hai link chữ:
  `Install guide →` `/install` và `GitHub ↗`.

Không nút to, không màu nền, không "Start building today". Anh đã nói cài đặt đơn giản và
không phải điểm bán — khối này chỉ cần *có mặt*, không cần *thuyết phục*.

---

## Ngân sách chữ

| Khối | Trần |
|---|---|
| 1 Hero | 30 từ |
| 2 Chỗ nó vỡ | 45 |
| 3 Làn song song | 40 |
| 4 Bốn cơ chế | 40 (4 câu) |
| 5 Ba con số | 0 — chỉ số và nhãn |
| 6 Không phải cái gì | 60 |
| 7 Đường vào | 35 |

**Tổng dưới 250 từ.** Nếu một khối vượt trần, cắt chữ chứ không nới trần — phần bị cắt gần
như luôn thuộc về một trang sâu hơn.

---

## Việc còn phải làm trước khi dựng

Bốn Receipt ở khối 4 là **artifact thật**, chưa có cái nào. Phải chụp từ một project đang chạy
trước khi trang này dựng được: ảnh workspace nhiều pane, ảnh frontier query, một arm report,
một đoạn `git log` có dòng `Pass:` đúng dạng. Không có chúng thì khối 4 rỗng, và thay bằng
hình minh hoạ là phá đúng luật số 2 của site.
