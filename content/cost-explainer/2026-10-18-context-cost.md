# Vì sao một đêm tốn 15% token cả tuần — và cái trần 200k sửa được gì

Brief cho video giải thích (3–4 phút, faceless, chữ + biểu đồ). Mọi con số lấy từ transcript thật
của một Builder (ticket TRA-1136, 2026-10-17/18) và bảng giá API Sonnet 5. Tiếng Việt, giọng kỹ
thuật, không bán hàng.

## Cảnh 1 — Câu hỏi (10s)

> Từ 1 giờ sáng tới 9 giờ, 15% token của cả tuần biến mất. Không ai làm gì sai. Vậy tiền đi đâu?

## Cảnh 2 — Một lần "gọi model" là gì (30s)

Người ta tưởng Builder được gọi **một lần** khi nhận brief. Thật ra một ticket là hàng trăm lần
gọi: sau mỗi tool (đọc file, grep, sửa, chạy test) model phải đọc kết quả rồi quyết định bước kế.

```
Thomas gửi brief                       1 lần
  Builder: nghĩ → đọc file           call 1
           nghĩ → grep               call 2
           nghĩ → sửa file           call 3
           nghĩ → chạy test          call 4
           …
           nghĩ → git commit         call 1.089
```

Ticket TRA-1136: **1.089 lần gọi**.

## Cảnh 3 — Model không có trí nhớ giữa hai lần gọi (30s)

Lần gọi 301 không "nhớ" gì từ lần 300. Nó nhận lại **toàn bộ** cuộc trò chuyện làm đầu vào và đọc
từ đầu: brief, mọi file đã mở, mọi output test, mọi câu trả lời cũ.

```
khung 1M:  [ 500k nội dung ............................ còn trống 500k ]

call 300:  gửi 500k vào → đọc → trả 200 token     → tính tiền 500k input
call 301:  gửi 500k vào → đọc → trả 200 token     → tính tiền 500k input
call 302:  gửi 501k vào → …                        → tính tiền 501k input
```

Khung 1M chỉ là giới hạn của thứ được gửi vào, không phải chỗ lưu để khỏi đọc lại.

## Cảnh 4 — Context phình lên, không bao giờ hạ (40s)

Số thật, từng dòng là một lần gọi trong transcript:

```
 call   giờ      token gửi vào   output
    1  22:31          91.947      175   ← chưa làm gì: AGENTS.md, rules, hợp đồng role
   10  22:32         105.540      199
   30  22:34         144.013    1.093
   60  22:39         183.968      213
  150  22:50         297.717      174
  300  23:05         449.266      405
  600  00:15         717.315      149   ← gửi 717k để nhận 149 token
  900  00:57         206.118      313   ← Claude Code tự compact một lần, gần 1M
1.089  01:31         379.098       68
```

Biểu đồ cột: trục ngang là số lần gọi, trục dọc là context. Cột chỉ đi lên. Nhấn vào call 600.

## Cảnh 5 — Cộng lại (30s)

```
1.089 lần gọi × trung bình 480k   = 523.401.828 token phải đọc
                                     521.342.127 là cache read (đọc lại thứ đã có)
output thật (code, câu trả lời)   =     467.749 token
```

Giá Sonnet 5: cache read $0,20/M · cache write ~$4/M · output $10/M.

```
cache read    521M × $0,20  ≈ $104
cache write     2M × $4     ≈   $8
output        0,47M × $10   ≈   $5
                             ──────
một ticket                   ≈ $117   → 89% là đọc lại context
```

12 ticket chạy song song một đêm. `ccusage` đo ngày 18/10: ≈ $683 giá API, 86% là Sonnet (Builder).

## Cảnh 6 — Vì sao không ai cắt (20s)

Claude Code chỉ tự tóm tắt khi **gần đầy cửa sổ**. Cửa sổ Sonnet 5 là 1 triệu token. Nên nó cứ gửi
500k mỗi lần mà vẫn "còn chỗ". Không phải lỗi của ai; là mặc định của một cửa sổ quá rộng.

## Cảnh 7 — Trần 200k (30s)

```
call
   1  ████                      91k
  60  ████████                 200k  ← chạm trần → compact
  61  █████                    120k  (giữ: brief, đang ở bước nào, HEAD, finding chưa xử lý)
 150  ████████                 200k  ← compact
 151  █████                    120k
 …
1.089 ███████                 ~160k

tổng phải đọc ≈ 174M thay vì 523M   → cache read ≈ $35 thay vì $104
output                     không đổi
```

Hai lớp cơ chế, không phải lời dặn:
- Launcher: `claude --autocompact 200000` (cờ chính thức của Claude Code).
- Mod: pane nào kết thúc turn trên 200k thì tự compact trước turn sau, kèm chỉ dẫn giữ gì.

## Cảnh 8 — Hai thứ khác cũng đắt (20s)

- **Advisor**: mỗi lần hỏi advisor là gửi nguyên 500k sang Opus. Builder và QA mặc định bỏ advisor.
- **Tải đứng 91k** lúc chưa làm gì: 70k là file của project (AGENTS.md 51KB, rules 35KB, overlay
  14KB), harness góp ~16KB. Việc gọn lại là của project.

## Cảnh 9 — Kết (10s)

> Tiền không đi vào việc làm. Tiền đi vào đọc lại. Đặt trần cho cái phải đọc lại, phần việc giữ nguyên.

## Ghi chú cho người dựng

- Màu: một màu cho "context gửi vào", một màu nhạt hơn cho "output". Giữ hai màu suốt video.
- Cảnh 4 và 7 cùng tỉ lệ trục để thấy cột gãy xuống ở cảnh 7.
- Không dùng từ "AI thông minh"; đây là chuyện kế toán, nói như kế toán.
- Nguồn số: transcript Builder TRA-1136 (`~/.claude/projects/…builder-TRA-1136/b7106abc….jsonl`),
  `npx ccusage@latest daily --since 20261017`, bảng giá Sonnet 5 trong docs API.
