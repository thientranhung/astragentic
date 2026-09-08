# Trang chủ: thứ tự khám phá, giao tiếp viết lại, placeholder ảnh (2026-09-08)

## 1. Thứ tự section mới (đặt mình vào người đọc đang khám phá)

1. hero: chỉ chữ (eyebrow, headline, sub, hai nút). **Sơ đồ client-studio rời khỏi hero.**
2. agents: Agent là gì (giữ nội dung, khối lệnh).
3. roles: Năm vai (5 hàng như hiện tại) + diagram `five-roles` tương tác ngay dưới.
4. team-picture (mới, id="team"): H2 **Cả đội trong một bức tranh.** Sub: "Bạn ở ngoài, Thomas ở
   cổng, issue tracker ở giữa, và mọi việc đi qua tracker." Diagram `client-studio` tương tác
   full band (chuyển từ hero xuống đây).
5. comms: viết lại theo §2.
6. tracker: giữ, thêm placeholder ảnh board (§3).
7. method: giữ.
8. why · features · lifecycle · fit · requirements · install: giữ thứ tự.
Nền xen kẽ tính lại từ đầu.

## 2. comms viết lại (nguyên văn, giữ)

Eyebrow: CÁCH CÁC AGENT NÓI CHUYỆN
H2: **Dispatch một ticket là mở một cuộc trao đổi có địa chỉ.**

P1: Thomas dispatch theo skill `dispatch-ticket`: claim ticket trên tracker trước, tạo branch
và worktree, mở một pane herdr, khởi chạy vai theo runtime đã khai, gửi brief, và lập tức đặt
watcher. Chuỗi ticket → assignee → pane → worktree → branch → PR là một-một, nên nhiều Builder
làm song song mà không giẫm lên nhau.

P2: Khi các vai cùng chạy Claude Code, kênh chính là SendMessage nguyên bản của Claude Code.
Brief và mọi trao đổi sau đó đi thẳng giữa hai session, có địa chỉ theo tên, trả lời về đúng
phiên gửi. Builder bị chặn thì hỏi; Thomas đọc câu hỏi, trả lời qua đúng kênh đó, rồi đặt
Monitor mới chờ tín hiệu làm xong. Nhờ vậy vòng dispatch, hỏi, đáp, bàn giao chạy liền mạch mà
không cần người ngồi canh.

P3: herdr là mặt phẳng nhìn thấy và là đường dự phòng. Mỗi vai một pane có tên, Thomas đọc
pane bằng `herdr agent read` khi một phiên im lặng, và dùng herdr CLI để điều Builder trên
Codex hay OpenCode, nơi SendMessage không có. Watcher theo dõi trạng thái working, blocked,
idle của từng pane.

P4: Phân loại câu hỏi là điều đưa bạn từ human-in-the-loop sang human-on-the-loop. Câu hỏi kỹ
thuật thường gặp, Thomas trả lời thay bạn từ contract, spec và tracker. Chỉ quyết định thiết
kế thật sự mới đi lên bạn qua `to-questionnaire`, dưới dạng câu hỏi trả lời được. Bạn không
đứng trong vòng lặp ở từng bước; bạn đứng trên vòng lặp và can thiệp khi có việc cần bạn.

Khối lệnh 1 (nhãn "Trả lời một Builder bị chặn, cùng Claude Code"):
```
SendMessage({ to: "builder-TRA-142", message: "<câu trả lời>" })
Monitor(...)   # chờ tín hiệu làm xong hoặc cần trao đổi
```
Khối lệnh 2 (nhãn "Điều một Builder trên Codex qua herdr"):
```
herdr agent start "builder-TRA-142" --kind codex --pane <id> -- codex --profile builder
herdr agent prompt <pane-id> "<brief>"
herdr agent read   <pane-id>
```
Hai placeholder ảnh (§3): "Một lượt SendMessage giữa Thomas và Builder" và "Workspace herdr
với năm pane đang chạy". Link: Xem skill dispatch-ticket → /skills/dispatch-ticket.

Bản Anh dịch giữ nhịp; "human-in-the-loop", "human-on-the-loop" giữ nguyên.

## 3. Placeholder ảnh thật

Component `Shot.astro`: figure viền đứt `--ink-22`, nền surface-2, tỉ lệ 16:9, giữa là nhãn
mono "ẢNH THẬT · SẼ CẬP NHẬT" và một dòng caption mô tả (theo lang). Prop `src?`: khi có ảnh
thì render `<img>` với alt = caption, bỏ viền đứt. Đặt:
- comms: 2 cái (SendMessage, herdr workspace)
- tracker: 1 cái ("Board tracker của một dự án thật, 71 ticket")
- roles: 0
Chủ site sẽ gửi ảnh sau; đường dẫn ảnh đặt `site/public/shots/<slug>.png`, nối qua prop `src`
trong landing yaml (`shots: { sendmessage, herdr, tracker }` mỗi cái {caption, src?}).

## 4. Brand bold

Thêm 'Matt Pocock' vào BRANDS trong src/lib/markup.ts (trước 'mattpocock-skills' không cần,
regex đã ưu tiên chuỗi dài nhất; thêm vào danh sách là đủ).

## 5. Kiểm

Build, detector 0, chụp /, /en, 390. Nền xen kẽ liền. Không "mình/anh em/chúng tôi".
