# 2026-10-25 — Builder đốt token ở đâu, và "lớn hay nhỏ" đo bằng gì

Câu hỏi của owner: khung cưỡng ép mọi ticket đi full quy trình; làm sao biết ticket nào lớn,
ticket nào nhỏ trong một project bất kỳ, để mỗi project tự có bản sắc.

Nguồn: transcript nizzy (`~/.claude/projects/*etsy-fulfillment-thanh*`, file có hoạt động
trong 14 ngày tính đến 2026-10-25), `scripts/usage-report.py --days 14`, git `origin/main`
của nizzy. Script đo tạm ở `/tmp/tokscan/{phase,era,sub,tail}.py` (không ship).
Giá: list price Sonnet 5 / Opus 5.5, chỉ để so tỉ lệ.

## Kết luận trước

Giả thuyết của owner đúng một nửa. Quy trình đốt token là thật, nhưng **không phải vì
ticket nhỏ bị ép đi full** — ticket nhỏ chỉ là 14% chi phí. Ba đòn bẩy theo thứ tự tiền:

| # | Đòn bẩy | Số đo | Nguồn |
|---|---|---|---|
| 1 | **Tải nền 92k token trên mọi call** | ctx@call-1 median 91.8k (min 88k) × 82,055 call Builder = 7.5B / 18.5B cache-read (41%), ≈ $1,510 / $4,717 Builder 14 ngày (32%) | phase.py cột `ctx@1`; usage-report by role |
| 2 | **Tầng review lặp trên mọi ticket** (simplify + 2 trục code-review + bug review + arm) | 29% $ transcript chính sau trần (simplify 10% đã trừ đuôi, review-std 12%, review-bug 6%, arm 1%) **+ 20% toàn bộ $ là subagent, và 100% subagent là fan-out review/simplify** (2 trục + 4 góc); simplify 594 marker / 116 merge = 5.1 lần mỗi merge, 182 (31%) ghi "no findings" | era.py phase share; sub.py; `git log --grep simplify(increment)` |
| 3 | **Ticket nhỏ trả sàn cố định** | sau trần: ≤50 dòng non-test median $18 / 290 call; 51–150: $23 / 347; 151–500: $39 / 590; >500: $58 / 831. Gấp 10 lần code = gấp 3 lần tiền. Nhóm ≤150 dòng: 37 ticket, $623 / $4,495 (14%) | era.py |

Trong cùng nhóm ≤50 dòng, giá chạy từ **$6 (TRA-1242, 8 dòng, brief có `TDD: n/a`) đến $49
(TRA-1212, 2 dòng)**. Chênh 8 lần trên cùng cỡ code: chênh lệch là quy trình, không phải code.

## Trả lời "làm sao biết lớn hay nhỏ trong project bất kỳ"

**Không đoán từ chữ của ticket; đo từ diff.** Mọi project đều có git, nên thước đo
không phụ thuộc project:

- Builder đo tại commit nội dung đầu tiên: `git diff --numstat <base>..HEAD` → số file,
  dòng non-test, đường dẫn chạm.
- **Bản sắc của project là hai thứ nó đã có sẵn**: (a) phân phối cỡ merge của chính nó
  (`git log --numstat --first-parent main` → p25/p50/p75), (b) một danh sách đường dẫn
  rủi ro (migration, route, auth, billing) ở `.astraler/project/risky-paths`. Nhỏ = dưới p25
  của project đó và không chạm đường dẫn rủi ro. Project làm CLI và project làm app sẽ ra
  ngưỡng khác nhau mà không ai phải khai.
- Thomas đo lại cùng lệnh numstat ở merge; Builder ghi `Tier:` trong handback. Không thêm
  gate, không thêm field brief.
- Slot miễn trừ đã có sẵn và gần như không dùng: `TDD: n/a` xuất hiện trong brief của
  **11 / 346** ticket nizzy từ trước tới nay, `REVIEW: n/a` **1 / 346**; trong khi gate tdd
  từ chối 43 + 11 lần trong 14 ngày. Tier treo vào slot này, không làm cơ chế mới.

Hiện nay việc chia nhỏ/lớn nằm hoàn toàn ở owner: Quick Builder mở theo lời owner, BA chỉ
cỡ **lên** (epic hay ticket), `dispatch-ticket` không cỡ **xuống**.

## Các phát hiện khác (quét thêm)

| Phát hiện | Số đo | Nguồn |
|---|---|---|
| Đuôi sau lệnh Skill cuối (chạy verify full + handback + push) | $1,312 / $7,008 transcript chính (19%), median $5.8 / ticket; $697 trong đó trước đây bị gán vào simplify | tail.py |
| Thomas không có trần | 13,208 call, median ctx 251k, $1,291 / 116 merge ≈ 114 call và $11 mỗi merge | usage-report by role |
| Gõ lại lệnh bị guard từ chối | `git add -A` 51 + 42 = 93 lần; tdd gate 43 + 11; "nothing has released this worktree" 35 | usage-report refusals |
| Rework không phải nguồn tốn | 162 / 163 ticket có đúng 1 transcript chính | sub.py |
| Tải nền chưa đo hết | file nêu tên được 137 KB ≈ 35k token (AGENTS.md 51 KB của project, overlays 34 KB, RULES 25 KB, CLAUDE.md 6 KB); ~57k còn lại (system prompt, tool schema, skill frontmatter, MCP) **chưa đo** | `wc -c` trong nizzy |

## Đề xuất (mỗi mục một số; "chưa đo" đi đo trước)

| Mục | Kỳ vọng | Số / nguồn |
|---|---|---|
| A. Đo nốt 57k tải nền, rồi cắt: mỗi 10k token bớt khỏi tải nền = 10k × 82k call × $0.2/M ≈ **$164 / 14 ngày ≈ 3.5% Builder** | lớn nhất, nhưng AGENTS.md 51 KB là của project → tham vấn nizzy, không áp | phase.py; `wc -c` |
| B. Fan-out review/simplify chạy inline (không subagent) khi diff dưới p50 của project | tối đa 20% tổng $ (phần subagent); với 31% simplify rỗng, rủi ro chất lượng thấp ở diff nhỏ | sub.py; git log |
| C. Simplify một lần cuối ticket thay vì sau mỗi fold | 5.1 marker / merge → 1–2; tiết kiệm chính xác **chưa đo** (trần: 10% transcript chính + phần fan-out của nó) | git log |
| D. Tier theo diff (mục trên), tier S = tdd + built-in code-review inline, bỏ 2 trục + 4 góc + ux khi không chạm UI | 37 ticket / 14 ngày × ~40% của $18 ≈ **$250 / 14 ngày ≈ 5%** | era.py |
| E. Kiểm đuôi 19%: Builder còn chạy full gate dù plan 2.8 đã đổi sang `Validation:` chỉ? | **chưa đo** (cần đếm lệnh test trong đuôi) | tail.py |
| F. Trần cho Thomas | 251k → 200k; $ tiết kiệm **chưa đo**; owner trước đây chỉ hỏi để biết | usage-report |

Lưu ý phương pháp: mốc "trước/sau trần" là proxy (median ctx ≥ 260k); 25 ticket không tra
được diff (`?`) nằm trong tổng nhưng không trong bucket cỡ; gán phase theo lệnh Skill gần
nhất, nên con số phase là xấp xỉ.

## 2026-10-26 — Tải nền 92k gồm gì, và một vòng Builder nạp lại dự án bao nhiêu lần

Owner hỏi theo lý thuyết nạp context của Claude Code: mỗi call gửi lại toàn bộ system prompt
và lịch sử; subagent mở session mới với system prompt riêng; mỗi `Read` nằm lại trong lịch sử
cho tới khi compact. Đo bằng hai lệnh `claude -p --model haiku` (tổng $0.02):

| Nơi đứng | Context call 1 | Nguồn |
|---|---|---|
| Thư mục trống (Claude Code + skill toàn máy + MCP + CLAUDE.md user) | 32.2k | `claude -p --output-format json`, usage |
| Thư mục gốc nizzy | 91.9k | cùng lệnh |
| **Phần của dự án nizzy** | **59.7k** mỗi call | hiệu hai dòng trên |

File đếm được: AGENTS.md 51 KB, `.claude/rules/` 35 KB, MEMORY.md 27 KB, CLAUDE.md 5.6 KB
= 119 KB; phần còn lại của 60k là listing 18 skill và agent của project, chưa tách.

Một ticket nhỏ sau trần (median 290 call chính, ~120 call subagent) gửi lại 60k đó:

| Lần nạp | Số | Nguồn |
|---|---|---|
| Mỗi call của Builder | 290 lần | era.py |
| Mỗi subagent review/simplify mở ra (6 fan-out, context call 1 median 75.8k, trong đó 60k vẫn là file dự án) | 1,615 subagent / 164 ticket ≈ 10 mỗi ticket | loads.py |
| Compaction rồi đọc lại | 271 lần / 164 ticket, median 2 | transcript `isCompactSummary` |
| Đọc lại cùng file trong một ticket | median 18 `Read` lặp, 71 KB; một file JSX đọc 117 lần trong TRA-1199 | loads.py |
| Tổng token gửi, 118 ticket sau trần | tải nền 6.11B (44%), lịch sử 7.87B (56%); riêng file dự án ≈ 4.2B ≈ 30% mọi token Builder gửi | loads.py |

Skill file nạp khi gọi nhỏ (tdd 3.6 KB, code-review 6.7 KB, codex-arm 15 KB): không phải nguồn tốn.
