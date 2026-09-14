---
title: "Kinh nghiệm chạy nhiều agent"
description: "Năm kỹ thuật để nhiều agent chạy song song trên một máy: git worktree, pnpm, portless, QA walk bằng browser thật, và runtime riêng cho mỗi worktree."
---

Astragentic dựng sự song song ở tầng điều phối: Thomas dispatch nhiều ticket, nhiều Builder cùng
thi công. Nhưng cả tầng đó đứng trên một giả định về máy của bạn — rằng ba agent chạy cùng lúc thì
không giẫm lên nhau. Máy mặc định không cho bạn điều đó.

Năm kỹ thuật dưới đây là thứ lấp khoảng cách ấy. Không cái nào do Astragentic ship; tất cả đều là
công cụ có sẵn, và mỗi mục nói rõ nó giải quyết cái đau nào.

Năm mục xếp theo mức phải hình dung. Mục đầu là nền tảng mà cả trang dựa lên. Ba mục giữa đứng
riêng được: mỗi mục một công cụ, giải quyết một cái đau cụ thể, áp dụng được ngay cả khi bạn không
làm ba mục còn lại. Mục cuối là nơi chúng ghép lại — nó là phần khó nhất, và nó chỉ có nghĩa sau
khi đã đọc bốn mục kia.

## git-worktree

**Pain point.** Bạn đang làm dở một việc thì cần xem nhanh một branch khác. Đường thường đi là
`git stash`, `git switch`, xem xong thì quay lại, `git stash pop` — và nếu hai branch khác nhau về
dependency thì cộng thêm một lượt cài lại. Nhân chuyện đó lên cho **ba agent chạy song song** thì nó
không còn là phiền phức, nó là bất khả: chỉ có một working directory, mà `HEAD` thì chỉ trỏ được vào
một chỗ.

Cách né hiển nhiên là clone repository ra ba lần. Được, nhưng bạn trả giá bằng ba bản lịch sử, ba
lần fetch, và ba nơi để remote đi lệch nhau.

**Kỹ thuật.** `git worktree` cho bạn **nhiều thư mục làm việc từ một repository**. Mỗi thư mục
checkout một branch riêng, có `HEAD` riêng và index riêng, nhưng **dùng chung một object database**.

```bash
git worktree add ../app-tra-142 -b builder/TRA-142   # thư mục mới, branch mới
git worktree list                                     # ai đang ở đâu, trên branch nào
git worktree remove ../app-tra-142                    # trả lại khi xong
```

Ba tính chất khiến nó khác hẳn việc clone nhiều lần, và đây là phần nhiều người chưa dùng sẽ thấy
bất ngờ:

- **Nó rẻ.** Worktree mới chỉ tốn phần file đang checkout, không tốn thêm một bản lịch sử. Bên trong
  `.git/worktrees/<tên>` chỉ có `HEAD`, `index`, `refs`, `logs` — **không có `objects`**. Object
  database nằm ở checkout gốc và mọi worktree đọc chung.
- **Một branch chỉ checkout được ở đúng một worktree.** Thử checkout nó ở nơi thứ hai thì git từ
  chối: `fatal: 'feature-a' is already used by worktree at ...`. Nghe như một hạn chế, nhưng với
  nhiều agent thì đây chính là thứ bạn muốn — hai Builder **không thể** cùng nhận một branch, và git
  là thứ nói không, không phải một quy ước ai đó phải nhớ.
- **Checkout gốc không bị động tới.** Bạn vẫn đứng ở `main`. Không ai `git switch` dưới chân bạn,
  không ai stash hộ bạn.

Ghép ba tính chất đó lại là được đúng thứ một team agent cần: **mỗi Builder một checkout, và trong
checkout đó nó là người ghi duy nhất.** Không ai kéo `HEAD` của ai đi.

**Đánh đổi.** Thêm một thư mục cho mỗi việc đang chạy, và một bước dọn khi xong — worktree bị xoá
tay mà không `git worktree remove` sẽ để lại đăng ký mồ côi, phải `git worktree prune` mới sạch. Và
`.git` trong worktree là một *file* chứ không phải directory, điều này sẽ quay lại cắn bạn ở mục
cuối nếu bạn đưa repo vào container.

**Và đây là giới hạn mà cả trang này nói về.** `git worktree` cô lập **cây làm việc**. Nó không cô
lập những gì cây đó khởi chạy: database, `node_modules`, port. Bốn mục còn lại là về đúng khoảng
trống đó.

## pnpm

**Pain point.** Mỗi Builder một `git worktree`, nghĩa là mỗi Builder một checkout, nghĩa là mỗi
checkout một `node_modules` đầy đủ — thêm vài trăm MB mỗi lần. Khi con số đó bắt đầu đáng kể thì
người ta làm đúng cái việc phá vỡ sự cô lập: share một `node_modules` cho nhiều worktree. Và lúc đó
worktree không còn cô lập gì nữa, vì hai branch đang đọc cùng một cây dependency.

Đáng chú ý là nó chết vì **một quyết định kinh tế**, không phải một quyết định kỹ thuật. Không ai
cân nhắc rồi kết luận share là đúng; người ta chỉ tiếc disk.

**Kỹ thuật.** [pnpm](https://pnpm.io) install package vào một content-addressable store duy nhất
rồi **hardlink** vào `node_modules` của từng project, thay vì copy. N thư mục `node_modules` nhưng
gần như một bản byte trên disk — nên câu hỏi "worktree thứ tư có đáng không" không còn được đặt ra.

**Nói thẳng một điều.** pnpm thường không được chọn vì lý do worktree — nó có mặt từ trước khi vấn
đề nhiều worktree tồn tại. Điều đúng để nói là: thuộc tính store và hardlink của pnpm là thứ khiến
mô hình nhiều worktree khả thi về chi phí. Một lợi ích được thừa hưởng, không phải một quyết định
được cân nhắc. Trình bày nó như một lựa chọn có chủ đích là mô tả sai thực tế.

Ba tính chất, xếp theo mức liên quan tới nhiều worktree:

- **Disk.** npm copy, ba worktree là ba lần dung lượng thật. pnpm hardlink, ba checkout cùng đọc
  một store.
- **`node_modules` không phẳng.** pnpm không hoist, nên một package chỉ import được thứ nó khai. Với
  nhiều worktree ở nhiều commit khác nhau, điều này chặn cả một class lỗi "chạy ở worktree này, hỏng
  ở worktree kia" do dependency graph khác nhau chứ không do code.
- **Install script tắt mặc định.** Muốn chạy thì phải khai tên, nên việc cấp phát `node_modules`
  trở nên tường minh.

**Đánh đổi.** Cái npm và yarn có mà pnpm không có là `node_modules` phẳng, vốn chịu đựng được
package khai thiếu dependency. pnpm sẽ làm lộ những package như vậy. Đó là feature, nhưng nó là chi
phí có thật khi bạn kéo về một dependency cũ.

**Một bẫy khi bind-mount repo vào container.** pnpm đặt store trên cùng filesystem với thư mục nó
hardlink vào. Nếu `node_modules` là named volume còn thư mục cha là bind mount thì đó là hai
filesystem, nên pnpm bỏ qua store bạn đã mount và tự dời store vào working tree. Kết quả đo được:
volume mount rỗng, còn vài trăm MB store rơi thẳng vào working tree của host dưới dạng thư mục
untracked. Phải shadow đúng path pnpm **thật sự chọn**, không phải path tài liệu nói.

## portless

**Pain point.** Hai dev server không dùng chung được một port. Ba worktree cùng chạy là ba port, và
ai đó phải chọn ba con số rồi ghi vào đâu đó rồi nhớ. Đó là cấu hình tay, mà cấu hình tay thì sẽ có
người quên.

Để runtime tự cấp port ngẫu nhiên thì hết va chạm, nhưng bạn nhận về một địa chỉ không ai gõ được:
không nhớ nổi, không bookmark được, không dán vào ticket được. Mà một URL không gõ được thì không
có browser evidence nào.

**Kỹ thuật.** [portless](https://portless.sh) là một proxy chạy nền giữ port 443
cho cả máy và map tên `https://<tên>.localhost` sang một port localhost. Nó thay thế port hardcode
và việc phải nhớ số port.

Với nhiều worktree, nó giải quyết đúng một việc: khi runtime cấp port ngẫu nhiên cho mỗi stack, phải
có thứ gì đó cho con người và cho browser một **địa chỉ ổn định** trỏ vào cái port ngẫu nhiên đó.

Khai báo là một file cạnh `package.json`:

```json
{
  "name": "myapp",
  "apps": {
    "apps/dashboard": { "name": "myapp" },
    "apps/server":    { "name": "api.myapp" }
  }
}
```

**Có hai chế độ dùng, và tài liệu phổ thông hay nói thiếu chế độ thứ hai.** Chế độ `run` dành cho
dev server chạy thẳng trên máy: portless khởi chạy nó và cấp `PORT` với `HOST` qua biến môi trường,
nên dev server phải đọc hai biến đó. Chế độ `alias` dành cho stack đã container hoá, và lúc đó
không thể khởi chạy *qua* portless được nữa — Docker cấp port trước, rồi bạn đăng ký một alias tĩnh
trỏ tên vào port vừa publish.

Quy ước đặt tên cho nhiều worktree gọn trong một dòng:

```make
DEV_SITE := $(if $(filter main,$(DEV_SLUG)),myapp,myapp-$(DEV_SLUG))
```

Branch `main` giữ tên trần có chủ ý, còn mọi branch khác mang hậu tố. Người mở URL quen thuộc luôn về
main và không lạc vào stack đang dở của một Builder. Chi tiết nhỏ, nhưng nó tách địa chỉ cho con
người khỏi địa chỉ cho agent.

**Đánh đổi.** Một daemon toàn máy giữ port 443. Mọi thao tác vòng đời của nó cần sudo, tức cần TTY,
nên một agent chạy nền không làm được và phải nhờ người. Đó là ràng buộc vận hành thật.

**Bốn chỗ hỏng đã biết.** `502` là triệu chứng duy nhất khi port lệch, không có lỗi rõ ràng nào
khác — cách kiểm là đối chiếu port trong `portless list` với port framework in ra, mỗi lần. Proxy
lồng proxy cho `508 Loop Detected` trừ khi bên trong đặt `changeOrigin: true`. Route trùng tên báo
"already registered by a running process" nghĩa là tiến trình cũ còn sống, hãy dọn trước chứ đừng
vội `--force`. Và giết tiến trình cha của portless không giết dev server con, nên tiến trình mồ côi
vẫn giữ route.

**Một thứ dứt khoát không đưa qua portless: port CDP của browser automation.** Client CDP gọi
thẳng `http://127.0.0.1:<port>/json`, không đi qua proxy tên miền được. Nhầm lẫn này rất dễ xảy ra
vì cả hai đều là "port localhost", nhưng portless phục vụ **app của bạn**, còn port CDP là **debug
socket của browser**.

**Ai không cần.** Ai không thể cho một daemon giữ 443 toàn máy, và máy nhiều người dùng chung. Đội
một app một port thì portless là tiện nghi chứ không phải nhu cầu. Nó chỉ thành nhu cầu đúng lúc số
port không còn đoán trước được, tức đúng lúc bạn cấp runtime theo worktree.

## browser-qa

**Pain point.** Một agent báo ticket đã xong, test xanh, diff sạch. Nhưng nút vẫn không bấm được vì
một overlay trong suốt nằm đè lên, hoặc ảnh không load vì đường dẫn chỉ sai khi render thật. Không
test nào bắt được, vì không test nào dựng hình. Và health check thì trả lời một câu hỏi dễ hơn câu
hỏi cần hỏi: "tiến trình có sống không" không phải là "người dùng có làm xong việc không".

**Kỹ thuật.** Một agent QA thao tác trên sản phẩm đang chạy như một người dùng — đi qua giao diện,
hành trình, hợp đồng API và dữ liệu như chúng hiện ra — thay vì đọc diff. Nó viết một file báo cáo
để trạm sau đọc lại được.

Công cụ chia làm hai, và **cách chia vai mới là phần quan trọng**.

### OmniLogin giữ trạng thái

**[OmniLogin](https://omnilogin.net)** là một browser giữ profile: cookie, localStorage, extension
đã cài, fingerprint, proxy. Một Chrome sạch khởi chạy mỗi lượt thì không giữ được gì trong số đó,
nên mọi hành trình đứng sau màn đăng nhập đều không đi được.

Nó phơi ra một HTTP API cục bộ để tìm profile theo tên, hỏi profile đã mở chưa, và mở nó. Khi mở,
nó trả về **port CDP thật** của lần mở đó. Port ấy **đổi theo mỗi lần mở** — nhớ số port cũ là một
lỗi, phải đọc lại từ phản hồi.

### agent-browser điều khiển

**[`agent-browser`](https://agent-browser.dev)** là một CLI kết nối vào browser
đang chạy qua CDP và điều khiển nó. Trong mô hình này nó **không bao giờ được tự khởi chạy
browser**: ngay khi nó làm thế, đó là một Chrome mới không có login nào, và mọi quan sát qua nó
đều không có giá trị.

Nên luật phân vai gọn trong một câu: **trạng thái ở OmniLogin, điều khiển ở agent-browser.** Đảo
vai, để agent-browser giữ login, là mất fingerprint và mất luôn lý do OmniLogin tồn tại.

Ba lớp tách khi nhiều agent cùng dùng một browser, và cần phân biệt rạch ròi:

- **`--session <tên>`** tách trang hiện tại và ngữ cảnh lệnh của session đó. Nó **không** tách tập tab
  của Chrome — CDP phơi một tập target cho cả tiến trình. Đừng nhầm với `--session-name`, vốn chỉ là
  khoá lưu auth-state chứ không tách gì.
- **`--pin-tab`** bind session vào đúng tab của nó. Giá trị của flag này không phải sự cô lập, mà
  là **biến một fallback im lặng thành một lỗi**: tab bị đóng thì lệnh kế tiếp báo `tab_gone`
  thay vì
  lặng lẽ trôi sang tab của người khác. Nó không làm tab của bạn riêng tư — agent khác vẫn thấy, vẫn
  thao tác, vẫn đóng được.
- **Daemon** dùng chung toàn máy và tự tắt sau một giờ không hoạt động. Mọi bước dọn worktree phải
  **không** giết nó, cùng lý do với container dùng chung: nó không quy được về worktree nào.

### Một lượt walk

```bash
# 0. Đúng binary trước đã. Thiếu flag là dừng, không phải "cẩn thận bằng kỷ luật".
agent-browser --help | grep -- --pin-tab || { echo "STOP: binary quá cũ"; exit 1; }

# 1-3. Trình duyệt còn sống không, profile đã mở chưa, và CỔNG THẬT của lần mở này là bao nhiêu.
#      Không bao giờ dùng lại số port của lần trước.

# 4. CDP có thật không, và user agent ở tầng browser là gì. Ghi lại để so ở bước 6.
curl -fsS "http://127.0.0.1:<port>/json/version"

# 5. Nối vào. `connect`, mỗi agent một --session, kèm --pin-tab.
agent-browser --session <ticket> --pin-tab connect <port>

# 6. Ba bằng chứng. Trượt một cái là dừng và huỷ mọi quan sát trước đó.
agent-browser --session <ticket> eval "navigator.userAgent + ' webdriver=' + navigator.webdriver"
#    (1) khớp UA ở bước 4   (2) không chứa Headless   (3) webdriver=false

# 7-8. Nhận tab của mình, rồi đi tới stack của chính worktree mình.
agent-browser --session <ticket> tab new
agent-browser --session <ticket> open "https://myapp-<branch>.localhost/<đường-dẫn>"

# 9-10. Đọc cây accessibility có ref, hành động lên ref, rồi đọc lại.
agent-browser --session <ticket> snapshot -i
agent-browser --session <ticket> click @ref

# 11. Khẳng định ngữ nghĩa, không phải "trang có tải".
agent-browser --session <ticket> screenshot <đường-dẫn>.png
```

**Bước 0 phải chạy trước bước 1** vì một binary sai làm mọi bước sau vô nghĩa mà không báo gì.

**Bước 6 không bỏ được kể cả khi bước 4 đã xanh**, vì hai bước hỏi hai câu khác nhau: "tôi định nối
vào đâu" và "trang thật sự đang chạy ở đâu".

**Ref hết hạn sau mỗi lần điều hướng**, kể cả chuyển trang trong SPA hay mở đóng modal. Phải chụp
lại cây accessibility, đừng dùng ref cũ.

**Một bẫy với React:** `click @ref` ở tầng CDP không kích hoạt `onClick` của React, và `fill ""`
không kích hoạt `onChange`. Click thật thì gọi `eval` để chạy `.click()` trên phần tử; xoá ô nhập
thì dùng phím, `Control+a` rồi `Delete`.

### Năm kiểu hỏng, và chỉ một kiểu không có triệu chứng

| Chết cái gì | Triệu chứng |
|---|---|
| Browser đóng hoặc đăng xuất | API cục bộ không trả lời. Dừng, và **không bao giờ chuyển sang browser khác**. |
| Profile bị đóng nhưng app còn sống | Hỏi trạng thái trả về "chưa mở". Mở lại sẽ ra port mới, phải đọc lại. |
| Daemon `agent-browser` dừng | Lệnh kế tiếp tự dựng lại. Nhưng ràng buộc tab là state của session, nên phải kiểm lại tab. |
| Tab bị người khác đóng | Lỗi `tab_gone`. Đây là kiểu hỏng **đáng giá nhất** — nó thay một thao tác âm thầm lên nhầm trang bằng một lỗi tường minh. Ràng buộc lại, đừng retry mù. |
| Attach nhầm browser | **Không có triệu chứng nào.** Lệnh chạy, trang tải, kết quả trông hợp lý. |

Bốn kiểu đầu tự báo. Kiểu thứ năm không, và toàn bộ kỷ luật ở trên tồn tại vì đúng kiểu đó. Cũng vì
nó mà kiểm bằng `curl` rồi hành động bằng browser là chứng minh không gì cả — hai lệnh có thể
đang nói chuyện với hai browser khác nhau. Phải kiểm bằng chính công cụ sắp dùng để hành động.

Và cùng lý do đó, **kết luận "công cụ không hỗ trợ flag này" có thể sai**: một máy có thể có hai bản
CLI khác phiên bản, bản cũ resolve trước trong shell. Kiểm flag trước mỗi session, trên mỗi máy.

### Bằng chứng, và một luật chung

Thứ để lại là **một file commit trên branch**: ảnh chụp, đường dẫn đã đi, chuỗi chữ đã thấy, kèm số
port CDP và user agent để trạm sau biết bằng chứng đến từ browser nào. Không phải một câu khẳng
định trong pane, vì một câu khẳng định thì trạm sau không kiểm lại được.

**Và đây là chỗ mục cuối bắt đầu cần thiết.** Browser evidence đòi mỗi người một
stack đang chạy. Nếu dựng stack còn tốn kém thì bước này sẽ bị bỏ, và lý do bỏ nghe rất hợp lý. Đo
được một lần, nguyên văn lời một Builder:

> no local stack was running in this worktree; standing one up is a multi-step job

Đó chính xác là chi phí mà mục tiếp theo xoá bỏ.

**Một luật chung.** Một luật mà người vận hành cẩn thận vẫn quên trong vòng một giờ thì cần
một ô bắt buộc chặn việc khởi chạy, không phải một câu văn nằm ở chỗ khác. Ở đây nó là một trường
bắt buộc trong brief dispatch, không có dạng để trống: hoặc khai rõ ticket này cần bằng chứng trình
duyệt và phải đi qua hành trình nào, hoặc khai rõ là không cần và vì sao.

**Ai không cần.** Sản phẩm không có bề mặt người dùng. Đội đã có visual regression tự động đủ dày.
Và đội không chấp nhận được việc agent điều khiển một session đăng nhập thật — đó là lo ngại chính
đáng, và cách đáp là mặc định chỉ đọc, cho phép ghi theo từng lần chạy, kèm một luật rõ: quy tắc
là về **dữ liệu**, không về môi trường. Dữ liệu dẫn xuất từ production vẫn là dữ liệu production,
chạy ở đâu cũng vậy.

Có những port không mở được, và không nên lách: một sàn có lớp chống bot ở trước, không có tài
khoản cho agent. Rủi ro điều khoản rơi vào tài khoản thật của chủ dự án, và bằng chứng lấy bằng
cách né chỉ chứng minh được là mình đã né.

## runtime-per-worktree

**Pain point.** Bạn dispatch hai ticket cho hai Builder, mỗi Builder một worktree. Code tách nhau
sạch sẽ — đó là việc `git worktree` làm tốt. Nhưng cả hai cùng chạy migration lên một database,
cùng bind vào một port, cùng ghi vào một `node_modules`. Builder thứ hai làm hỏng môi trường của
Builder thứ nhất mà không ai nhận được tín hiệu nào, vì không có gì báo lỗi cả: hai tiến trình
dùng chung một tài nguyên là hành vi hợp lệ.

`git worktree` cô lập **cây làm việc**. Nó không cô lập những gì cây đó khởi chạy.

**Kỹ thuật.** Cấp cho mỗi worktree một runtime riêng, và **suy tên của runtime đó ra từ tên
branch** thay vì để ai đó đặt.

Vế thứ hai mới là phần quan trọng. Cô lập bằng cách bắt mỗi người tự đặt tên và tự chọn port trong
một file config là biến sự cô lập thành **một việc phải nhớ làm** — mà việc phải nhớ thì sẽ có người
quên, và triệu chứng khi quên là im lặng. Suy ra từ branch thì không có gì để quên: đổi branch là
đổi runtime, không sửa file nào.

**Luật, và đây là phần áp dụng được ở mọi stack: cô lập state khả biến, share state
content-addressed.** Package và build artifact được key bằng hash của chính nó, nên hai branch
muốn hai version sẽ nhận hai key khác nhau thay vì tranh chấp cùng một chỗ. Share chúng an toàn về
mặt cấu trúc, không phải an toàn vì gặp may.

### Một cách hiện thực, để hình dung

Astragentic **không ship** phần này và không có ý kiến về stack của bạn. Database, container
runtime, package manager — đó là lựa chọn của dự án. Phần dưới đây là **một ví dụ** từ một dự án
dùng Docker Compose, Postgres và pnpm, để thấy nguyên tắc trên trông như thế nào khi viết ra. Dự án
của bạn dùng Podman, hay chạy Postgres trên máy, hay không có database nào — nguyên tắc không đổi,
chỉ chi tiết đổi.

Ở ví dụ đó, tên Compose project được suy ra từ branch, và Compose tự prefix tên project vào
container, network và volume — nên chỉ một cái tên khác nhau là bốn thứ tách nhau cùng lúc:

| Runtime | Cấp cho mỗi worktree | Share phần nào |
|---|---|---|
| Database | Một Postgres container riêng, volume riêng. Không phải schema riêng trên một server chung. | Cụm test thì ngược lại: một container cho cả máy, cô lập bên trong bằng template theo hash của migration set. |
| `node_modules` | Hai bản: bản host do `pnpm install` trong chính worktree, và bản trong container là named volume shadow lên bind mount. | pnpm store, build cache, module cache — khai `external: true`. |
| Port FE/BE | Không ai chọn port. Compose chỉ khai port trong container, Docker cấp port ngoài. | — |

```make
DEV_SLUG := $(shell git rev-parse --abbrev-ref HEAD | tr '[:upper:]' '[:lower:]' \
              | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$$//' | cut -c1-40)
DEV_SLUG := $(if $(filter head,$(DEV_SLUG)),$(shell git rev-parse --short HEAD),$(DEV_SLUG))
DEV_PROJECT := myapp-dev-$(DEV_SLUG)
```

`builder/TRA-686` thành `builder-tra-686`, còn detached HEAD rơi về short SHA để tên vẫn ổn định
cho đúng checkout đó.

### Hai phương án khác, và vì sao không chọn

**Một database riêng cho mỗi worktree trên một Postgres dùng chung.** Rẻ hơn, và vẫn đúng cho test
cluster. Nhưng `CREATE DATABASE` không cô lập thứ cluster-global: role và password. Một lệnh `ALTER
ROLE` là toàn cluster. Một instance riêng thì không còn lớp chung nào để giẫm lên.

**Một dev stack dùng chung, ai cần thì xếp hàng.** Cái giá không nằm ở chỗ chờ. Nó nằm ở chỗ người
ta sẽ không xếp hàng — người ta sẽ bỏ bước.

### Hai chi tiết dễ bỏ sót khi container hoá

Hai thứ này không phụ thuộc stack cụ thể; ai đưa repo vào container cũng gặp.

**Đừng đặt tên cố định cho project.** Tên project là thứ cấp cho mỗi worktree bộ tài nguyên riêng,
và nó phải đến từ nơi biết người gọi đang đứng ở worktree nào. Một cái tên hardcode trong config
đưa mọi worktree về chung một project.

**`.git` trong worktree là một *file*, không phải directory.** Nó chứa một absolute path phía host
trỏ vào `.git/worktrees/<tên>` của checkout gốc, mà bind mount không mang theo path đó. Bất kỳ
tooling nào gọi `git` bên trong container sẽ lỗi. Cách chữa là mount common git dir ở chế độ
read-only rồi trỏ `GIT_DIR` vào, và cả hai đều suy ra từ chính git:

```make
DEV_GIT_COMMON := $(shell cd "$$(git rev-parse --git-common-dir)" && pwd)
DEV_GIT_REAL   := $(shell cd "$$(git rev-parse --git-dir)" && pwd)
DEV_GIT_DIR    := $(if $(filter $(DEV_GIT_COMMON),$(DEV_GIT_REAL)),/gitcommon,/gitcommon/worktrees/$(notdir $(DEV_GIT_REAL)))
```

`--git-dir` khác `--git-common-dir` là cách git tự phân biệt checkout gốc với linked worktree. Dùng
phép so sánh đó, đừng đoán hình dạng của path.

**Đánh đổi.** Constraint thật không phải disk mà là RAM. Disk thì mỗi worktree tốn khoảng 540–650 MB
volume, phần share cho cả máy khoảng 2 GB — với ổ cứng hôm nay thì đó không phải giới hạn. RAM mới
là giới hạn: chạy hai bộ test đầy đủ có `-race` cùng lúc có thể làm cả hai cùng fail. Ai định dùng
mô hình này phải trả lời trước một câu: RAM của máy chịu được bao nhiêu stack song song. Một
advisory lock dạng token, `take` thì exit khác 0 khi người khác đang giữ, là đủ để xếp hàng đúng chỗ
cần xếp.

**Một chỗ leak đã biết.** Bước cleanup chỉ remove volume khi còn container để remove. Một Builder
lịch sự tắt stack trước khi handback sẽ để lại 0 container, điều kiện sai, `down -v` bị bỏ qua, và
volume mồ côi trong khi stamp cleanup vẫn ghi là sạch. Nếu bạn dựng lại mô hình này, hãy cho bước
cleanup remove volume theo **tên project** chứ đừng theo sự tồn tại của container.

**Ai không cần.** Team một người, một branch tại một thời điểm: toàn bộ cơ chế này mua đúng một thứ
là tính đồng thời. Team mà dev environment không chứa state khả biến cũng không cần — chỉ cần port
động là đủ. Và team chạy CI trên runner sạch mỗi lần thì vấn đề này không tồn tại: nó chỉ có thật
khi nhiều checkout cùng sống trên một máy.

## one-shape

Ba trong bốn kỹ thuật trên có cùng một hình dạng, và nếu trang này chỉ đọng lại một câu thì nên là câu
này: **biến một việc phải nhớ làm thành một việc được suy ra.**

Tên project suy ra từ branch. Port suy ra từ Docker. `GIT_DIR` suy ra từ git. Tên miền suy ra từ
branch. Không có file env nào phải sửa khi đổi branch, nên không có bước nào để quên.

Đó cũng là lý do bốn mục này thuộc về trang của Astragentic chứ không phải một danh sách mẹo. Điều
phối nhiều agent đặt ra một yêu cầu mà làm việc một mình không đặt ra: mọi thứ phải đúng **mà không
ai phải nhớ**, vì bên nhớ không còn là một người.
