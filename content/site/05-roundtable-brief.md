# Bàn tròn dựng lại site Astragentic (2026-09-04)

Phòng họp theo `docs/distilled/capabilities/party-mode.md`, chế độ agent-team: mỗi persona là
một agent thật, nói chuyện trực tiếp với nhau qua SendMessage. Team-lead là người ghi biên bản,
không mediate. Chủ site (anh Thiên) là khách trong phòng, hỏi ngược được.

## Tình huống

Đợt build 1 xong: `site/` Astro, 26 trang (5 trang mặt tiền, hub `/skills`, 6 skill page,
12 dictionary, 1 essay, 8 diagram archify). Chủ site xem trên Chrome thật và nói nguyên văn:

> "thực sự là không ổn nó không chạm vào được cái gì cả. Nó rối, nó không có hành trình, nó
> không trực quan, bố cục cực kì xấu. Giờ tôi cần lên lại wireframe trước, rồi sitemap và cấu
> trúc."

Ý định gốc của chủ site, nguyên văn từ đầu phiên:

> "site giới thiệu về astragentic theo kiểu truyền tải cảm hứng và giới thiệu ... cho mọi
> người hiểu thêm về những tech stack tôi dùng và các triết lý bên trong."
> "Tôi không phải giáo sư hay thầy giáo mà dạy ai. Ý tôi muốn là mọi người hiểu được triết lý
> tôi tạo ra, vì sao tôi dùng vậy, thiết kế vậy."
> "tôi rất thích trang của https://www.aihero.dev/skills"

## Đầu ra phòng này phải chốt, theo thứ tự

1. **Người đọc là ai** (nhân vật có tên, tình huống thật) và họ làm gì khi đóng tab.
2. **Hành trình chính** của người đó qua site, có climax.
3. **Wireframe** từng màn của hành trình đó, mô tả bằng chữ hoặc ASCII, đủ để dựng.
4. **Sitemap và cấu trúc** rút ra từ wireframe, không phải ngược lại.

## Ba hướng đang cãi nhau (từ vòng session trước)

1. Mary + Sally: chọn một nhân vật chính có thật, dựng một hành trình, wireframe theo đó.
2. Winston: site là vòng đời một ticket từ claim tới merge, cuộn là đi qua các chặng;
   dictionary thành chú thích khi chạm, không phải khu riêng.
3. Paige: giữ bộ xương, thay hết ô "Not yet captured" bằng bằng chứng thật trước.

## Câu hỏi đang treo với chủ site

- Người mở site lần đầu đã chạy Astragentic chưa?
- Khi đóng tab, họ làm gì tiếp: cài, hay đi kể lại vì sao nó được thiết kế vậy?
- Có sẵn lòng bỏ hub và dictionary như khu riêng không?

## Nguồn để đọc (đọc trước khi nói, không suy diễn)

- Bản đã build, nhìn bằng mắt: `/tmp/astra-shots/o3-home.png`, `o3-architecture.png`,
  `o3-skills.png`, `o3-why.png`, `o2-dictionary-worktree.png`, `skills-dispatch-ticket.png`
- Ý đồ cũ: `content/site/01-sitemap-and-outline.md`, `02-design-direction.md`,
  `03-reference-aihero-structure.md`, `04-build-contract.md`, `content/site/pages/*.md`
- Câu chuyện và giọng: `content/vibe-engineering-story/01-outline.md`, `03-voice-guide.md`
- Sự thật về sản phẩm: `README.md`, `docs/adr/0001-*.md`, `harness/.claude/agents/*.md`,
  `harness/.agents/memory/INDEX.md` (ledger), `RELEASE-NOTES.md` (grep, đừng đọc hết)
- Người dùng thật duy nhất tới giờ: hai project downstream trong `content/site/pages/why.md`

## Luật phòng

- Nói như người thật, ngắn, có phản ứng, có cãi. Không nộp báo cáo.
- Mỗi claim về sản phẩm phải chỉ được file. Không bịa số, không bịa người dùng.
- Không dùng chữ dạy/học/tutorial cho site. Site là chủ nhân kể vì sao mình chọn vậy.
- Không kết luận hộ chủ site. Câu nào cần chủ site trả lời thì gửi cho team-lead.
- Tiếng Việt. Tên file, lệnh, thuật ngữ giữ nguyên.

## Bổ sung từ chủ site (2026-09-04, giữa phiên)

- Site làm **song ngữ tiếng Việt và tiếng Anh**. Hợp đồng build cũ (04, §0 "tiếng Anh cho site")
  không còn đúng. Wireframe và sitemap phải tính cách chuyển ngữ: route riêng (`/vi/...`) hay
  toggle, và câu chữ nào giữ nguyên (tên skill, lệnh, mã ticket, trích dẫn nguyên văn từ
  RELEASE-NOTES và ledger giữ tiếng Anh).
