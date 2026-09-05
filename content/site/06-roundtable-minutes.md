# Biên bản bàn tròn dựng lại site (2026-09-04)

Năm agent Opus theo roster BMAD: Mary (analyst), John (PM), Sally (UX), Winston (architect),
Paige (tech writer). Hai vòng. Vòng 1 mỗi người đọc nguồn rồi nêu lập trường; vòng 2 cãi nhau
qua tổng đài team-lead vì message trực tiếp chỉ tới khi người nhận rảnh. Mọi claim dưới đây đã
có ít nhất hai người kiểm độc lập trên file.

## 1. Kết luận phòng đã hội tụ

**Lỗi của đợt 1 không phải wireframe. Là phạm vi và mặt phẳng.**
- Spec `01-sitemap-and-outline.md:29` viết "sáu trang, không hơn"; build ra 26 và không ai dựng
  lại hành trình sau khi site nở gấp bốn. (John)
- Site thoả "yêu cầu 2" (mọi thứ đúng, truy được) và trượt **"yêu cầu 5"** của chính sản phẩm:
  `harness/.agents/tracker-contract.md:42` "a surface the OWNER can open and read without
  running a query", dòng 44 "Requirement 5 is the one that gets dropped". Câu "không chạm vào
  được cái gì" của chủ site là một defect report yêu cầu 5 về chính site. (Sally tìm, Mary và
  Winston kiểm)
- Site không có người kể. Voice guide khai giọng "mình, team mình, anh em"; build ra ngôi thứ
  ba tiếng Anh thiết chế. Hợp đồng build §0 tự mâu thuẫn. (John)
- Bằng chứng không thiếu, nằm sai chỗ. 11 ô Receipt `pending`: 4 lấp được từ repo, 2 phải xin
  downstream, 5 phải xoá vì luận điểm sau nó không đúng với repo package này. (Paige)

**Bằng chứng không phải cái ảnh. Bằng chứng là cái link đi được.** Chuỗi bốn mắt, tất cả trên
đĩa, không cần chạy gì: lỗi có ngày (`recurring-failure-modes.md`) → luật (`INDEX.md` cột
"Cited by") → file đang mang luật (skill page mục Known failures) → commit đóng nó (trailer
`Ledger:` trong git log). Kiểm: `AST-016` cited by `dispatch-ticket, codex-claude-arm`, có mặt
nguyên văn ở `site/src/content/skills/dispatch-ticket.md:72` và `codex-arm.md:87`. (Paige tìm,
Sally, Winston, John kiểm; John: "thứ mạnh nhất phòng ra được hôm nay")

**Con số thay cho "136".** INDEX.md: 136 dòng, **71 có "Cited by", 65 trống**. Site không khoe
136; site nói "71 trên 136 bài học đã bị buộc vào một file đang mang nó, 65 thì chưa, cái bảng
nói thẳng". Vừa bằng chứng vừa lời thú nhận. (Sally, Winston, Paige đếm độc lập)

**Vòng đời ticket không làm xương sống.** `RELEASE-NOTES.md:393`: "Nothing in it proves the
loop works. No ticket has gone through dispatch → build → code-review → simplify → arm(ticket)
→ merge with the gates firing on live work." Grep 214 commit: `Pass:` 2, `simplify(increment)`
3, branch `builder/<id>` 0. Vòng đời tụt xuống làm **trục sắp xếp**: 6 lỗi trong why.md rơi vào
claim (AST-131), build (AST-097, AST-092), arm (AST-015), merge (AST-074, AST-056); brief và
code-review không có lỗi, phải in ra như dữ kiện. (Mary đánh gãy, Winston rút và sửa)

**Lời thú nhận là climax, và nó đã là điều khoản hợp đồng** (`04-build-contract.md` §0). Build
đã tuân thủ nhưng giấu nó ở gạch đầu dòng thứ tư gần cuối trang chủ. Việc cần làm là kéo lên,
không viết thêm. (Mary)

**Nhân vật là `[ASSUMPTION]`, không phải kết luận.** Repo chỉ có dữ liệu vận hành sau khi cài
(field report etsy, inception), không có dữ liệu về người chưa cài. Hai project downstream KHÔNG
phải project của chủ site (Mary tự rút). Sally tự rút nhân vật "dev ở inception trên Linear"
(sai: là chủ project etsy trên GitHub Issues). Chỉ chủ site trả lời được. (Mary, John)

**Song ngữ: khung dịch, bằng chứng không dịch.** Mã AST, dòng ledger, trailer git, tên skill,
lệnh, trích RELEASE-NOTES giữ tiếng Anh ở cả hai bản; dịch một dòng ledger là biến receipt thành
diễn giải. Chi phí thật: bốn màn văn kể nhân đôi, không phải 26 thành 52. Tiền lệ repo:
`README.md` / `README.vn.md` → route riêng `/vi/...`, không toggle. Trang lai (văn Việt bọc
bằng chứng Anh) là bắt buộc, wireframe phải xử lý. (Sally, Winston, John, Paige)

## 2. Hành trình: bốn màn, climax ở màn 3 (Sally, phòng nhận)

1. **Nhận ra**: một defect thật, có ngày, phá khung.
2. **Hình dạng**: sáu lỗi xếp theo chặng, mỗi lỗi trỏ tới file đang mang luật.
3. **Đi xuyên qua** (climax): bảng 136 dòng, 71 có link, click một dòng là tới đúng file.
4. **Giới hạn**: "Nothing in it proves the loop works", 65 mục mồ côi, cổng vào.

Tiêu chí thành công màn đầu (John): người đọc bấm một mã AST có ngày, tới đúng file đang mang
luật đó, và không quay lại nav. Tiêu chí này giống hệt ở hai ngôn ngữ.

### Wireframe màn 1 (Sally, bản thay)

```
┌────────────────────────────────────────────────────────┐
│ ASTRAGENTIC                    VI · EN       GITHUB ↗  │
├────────────────────────────────────────────────────────┤
│  Một agent chạy ngon. Ba agent      ← serif 64px, VN   │
│  thì bắt đầu giẫm lên nhau.           hai dòng, hết    │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │ AST-016                              --defect      │ │
│ │ "Agents sharing one checkout moved HEAD under      │ │
│ │  each other."          ← nguyên văn, GIỮ TIẾNG ANH │ │
│ │                                                    │ │
│ │ Không có lỗi nào được ném ra. Việc chỉ biến mất.   │ │
│ │              INDEX.md:31 · promoted · 38 dòng      │ │
│ └────────────────────────────────────────────────────┘ │
│                        ↓                               │
└────────────────────────────────────────────────────────┘
```
Không hero khoe, không stat trio, không bảy khối. Defect card phá khung cột 620px.

### Wireframe màn 3, climax (Sally)

```
│ 71 trên 136 bài học đã bị buộc vào một file mang nó.     │
│ 65 thì chưa. Cái bảng nói thẳng.                         │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ AST-001 │ Gate wired to a fix tool, not a…  │ → 2  ▓ │ │
│ │ AST-002 │ A prose link does not guarantee…  │   —    │ │ ← trống THẬT
│ │ AST-003 │ No lessons ledger existed         │   —    │ │
│ │ AST-016 │ Agents sharing one checkout…      │ → 2  ▓ │ │ ← click
│ │ AST-028 │ Relative worktree path → worktree…│ → 4  ▓ │ │
│ │ …cuộn tiếp, không hết…                               │ │
│ └──────────────────────────────────────────────────────┘ │
│              ↓ click một dòng có mũi tên                 │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ dispatch-ticket.md · Known failures                  │ │
│ │ "AST-016 / AST-027: two root sessions sharing one    │ │
│ │  checkout silently lost commits to a…"    ← nằm ở đó │ │
│ └──────────────────────────────────────────────────────┘ │
```
Người đọc tự chứng minh, không ai chứng minh hộ.

## 3. Sitemap đề nghị (Winston, sau khi rút bản vòng đời)

```
/                  màn 1 + 2 + 3 + 4 trên một trang cuộn; climax là bảng 136
/failures          6 lỗi thật, xếp theo chặng (claim · build · arm · merge),
                   mỗi lỗi → file đang mang luật
/evidence          71 mục khép chuỗi, 65 mồ côi nói thẳng,
                   "Nothing in it proves the loop works" ở đầu trang
/architecture      5 role + 7 chặng, trang tham chiếu, giữ
/adopt             install (4 lệnh từ README:32-45) + 4 skill brownfield
/skills/<name>     giữ trang, giữ URL, bỏ khỏi nav
/dictionary/<term> giữ permalink, hiện dạng chú thích khi chạm, bỏ khỏi nav
/vi/*              mirror; artifact không dịch
```
Nav 5 mục trở lại theo `02-design-direction.md` §4. Trang chết theo Paige: `/compare` (2/2 ô
rỗng, không cứu được), skill page `bootstrap-glossary` (0 AST id).

## 4. Việc phải làm trước khi wireframe tiếp

- Bốn ô lấp ngay: `INDEX.md`, `recurring-failure-modes.md`, `README.md:32-45`, trailer
  `Ledger:` từ git log.
- Xoá 5 ô kẹt (workspace, frontier-query, arm-report ×2, plan-file), không để rỗng.
- Cắt hiệu ứng bốn làn dọc trên trang chủ: nó diễn cái vòng chưa chứng minh (Winston).
- Sửa README: badge ghi 136, bảng "At a glance" dòng 304 ghi 125; ledger thật là 136.

## 5. Câu hỏi chờ chủ site, xếp theo mức chặn

1. Người mở site lần đầu **đã chạy Astragentic chưa**, đã đau vì nhiều agent chưa? Repo không
   trả lời được, chỉ anh trả lời được. Chặn nhân vật.
2. Site kể **ngôi thứ nhất** ("tôi chọn vậy vì…") hay ngôi thứ ba? Ý định gốc là "triết lý tôi
   tạo ra". Chặn giọng.
3. **Bản tiếng Việt ngang hàng hay bản phụ?** Ngang hàng thì màn 1 viết tiếng Việt trước rồi
   dịch. Mặc định vào thấy tiếng nào? Chấp nhận route `/vi/` thay vì toggle? Chặn wireframe.
4. Cho phép kéo **"Nothing in it proves the loop works"** lên vị trí cao trên trang chủ và đầu
   `/evidence` không?
5. **Bỏ SKILLS và DICTIONARY khỏi nav** (giữ trang, giữ URL)? Sally và Winston đã đồng ý, chỉ
   chờ gật.
6. Năm ô kẹt: **xoá hẳn**, hay anh muốn **chạy một ticket thật ở downstream** để chụp bốn
   worktree sống và arm report? Ảnh board 68/71 không có trong repo; có xin được từ etsy không?
