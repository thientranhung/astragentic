---
title: "Kỹ thuật vận hành"
description: "Bốn kỹ thuật để nhiều agent chạy song song trên một máy: runtime theo worktree, pnpm, portless, và QA walk bằng trình duyệt thật."
---

`git worktree` cô lập code. Nó không cô lập runtime, mà runtime mới là chỗ nhiều agent giẫm lên
nhau: database, `node_modules`, và cổng của frontend lẫn backend. Astragentic dựng sự song song ở
tầng điều phối; bốn kỹ thuật dưới đây là thứ máy của bạn cần có để tầng đó chạy được thật.

Bốn mục không ngang hàng. Mục đầu là kỹ thuật. Hai mục giữa là hai điều kiện khiến nó trả nổi
tiền. Mục cuối là lý do nó đáng làm.

## runtime-per-worktree

Mỗi worktree được cấp một stack container riêng, và **tên stack suy ra từ tên nhánh**. Docker
Compose tự tiền tố tên project vào container, network và volume, nên chỉ cần tên project khác
nhau là bốn thứ tách nhau cùng lúc: container, network, volume — tức database — và cổng.

Ba thứ nói ở trên được cấp như sau:

| Runtime | Cấp cho mỗi worktree | Dùng chung phần nào |
|---|---|---|
| Database | Một container Postgres riêng, volume riêng. Không phải schema riêng trên server chung. | Cụm test thì ngược lại: một container toàn máy, cô lập bên trong bằng template theo hash migration-set. |
| `node_modules` | Hai bản: bản host do `pnpm install` trong chính worktree, và bản trong container là named volume che lên bind mount. | pnpm store, build cache, module cache — khai `external: true`. |
| Cổng FE/BE | Không ai chọn cổng. Compose chỉ khai cổng trong container, Docker cấp cổng ngoài. | — |

**Luật một câu, và đây là phần đem đi chỗ khác dùng được: cô lập state khả biến, chia sẻ state
content-addressed.** Package và build artifact được đánh khoá bằng hash của chính nó, nên hai
nhánh muốn hai phiên bản sẽ nhận hai khoá khác nhau thay vì giành nhau một chỗ. Chia sẻ chúng an
toàn về mặt cấu trúc, không phải an toàn vì gặp may.

### Vì sao không phải ba phương án hiển nhiên

**Mỗi worktree tự đặt tên container và cổng trong `.env`.** Cách này biến sự cô lập thành một việc
phải nhớ làm, mà việc phải nhớ thì sẽ có người quên và triệu chứng khi quên là im lặng. Tên project
nên được suy ra:

```make
DEV_SLUG := $(shell git rev-parse --abbrev-ref HEAD | tr '[:upper:]' '[:lower:]' \
              | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$$//' | cut -c1-40)
DEV_SLUG := $(if $(filter head,$(DEV_SLUG)),$(shell git rev-parse --short HEAD),$(DEV_SLUG))
DEV_PROJECT := myapp-dev-$(DEV_SLUG)
```

Không có file env nào phải sửa khi đổi nhánh. `builder/TRA-686` thành `builder-tra-686`, còn
detached HEAD rơi về short SHA để tên vẫn ổn định cho đúng checkout đó.

**Mỗi worktree một database trên một Postgres dùng chung.** Rẻ hơn, và vẫn đúng cho cụm test.
Nhưng `CREATE DATABASE` không cô lập thứ cluster-global: role và mật khẩu. Một lệnh `ALTER ROLE` là
toàn cụm. Container riêng thì không còn lớp chung nào để giẫm.

**Một stack dev dùng chung, ai cần thì xếp hàng.** Cái giá không nằm ở chỗ chờ. Nó nằm ở chỗ người
ta sẽ không xếp hàng — người ta sẽ bỏ bước.

### Hai chi tiết cấu hình mà đa số sẽ vấp

**Compose file không được có `name:`.** Tên project là thứ cấp cho mỗi worktree bộ container,
network và volume của riêng nó, và nó phải đến từ nơi biết người gọi đang đứng ở worktree nào. Một
cái tên viết cứng trong file đưa mọi worktree về chung một project.

**`.git` trong worktree là một *file*, không phải thư mục.** Nó chứa đường dẫn tuyệt đối phía host
trỏ vào `.git/worktrees/<tên>` của checkout gốc, mà bind mount không mang theo đường dẫn đó. Bất kỳ
tooling nào gọi `git` bên trong container sẽ chết. Cách chữa là mount common git dir ở chế độ chỉ
đọc rồi trỏ `GIT_DIR` vào, và cả hai đều suy ra từ chính git:

```make
DEV_GIT_COMMON := $(shell cd "$$(git rev-parse --git-common-dir)" && pwd)
DEV_GIT_REAL   := $(shell cd "$$(git rev-parse --git-dir)" && pwd)
DEV_GIT_DIR    := $(if $(filter $(DEV_GIT_COMMON),$(DEV_GIT_REAL)),/gitcommon,/gitcommon/worktrees/$(notdir $(DEV_GIT_REAL)))
```

`--git-dir` khác `--git-common-dir` là cách git tự phân biệt checkout gốc với linked worktree. Dùng
phép so sánh đó, đừng đoán hình dạng đường dẫn.

**Đánh đổi.** Ràng buộc thật không phải đĩa mà là RAM. Đĩa thì mỗi worktree tốn khoảng 540–650 MB
volume, và phần dùng chung cho cả máy khoảng 2 GB — với ổ đĩa hôm nay thì đó không phải giới hạn.
RAM mới là giới hạn: chạy hai bộ test đầy đủ có `-race` cùng lúc có thể giết cả hai, không ai
thắng. Ai định dùng mô hình này phải trả lời trước một câu: RAM của máy chịu được bao nhiêu stack
song song. Một khoá tư vấn dạng token, `take` thì thoát khác 0 khi người khác đang giữ, là đủ để
xếp hàng đúng chỗ cần xếp.

**Chỗ rò đã biết.** Bước dọn chỉ gỡ volume khi còn container để gỡ. Một Builder lịch sự tắt stack
trước khi trả việc sẽ để lại 0 container, điều kiện sai, `down -v` bị bỏ qua, và volume mồ côi
trong khi dấu dọn vẫn ghi là sạch. Nếu bạn dựng lại mô hình này, hãy để bước dọn gỡ volume theo
**tên project** chứ đừng theo sự tồn tại của container.

**Ai không cần.** Đội một người, một nhánh tại một thời điểm: toàn bộ cơ chế này mua đúng một thứ
là tính đồng thời. Đội mà môi trường dev không chứa state khả biến cũng không cần — chỉ cần cổng
động là đủ. Và đội chạy CI trên runner sạch mỗi lần thì vấn đề này không tồn tại: nó chỉ có thật
khi nhiều bản checkout cùng sống trên một máy.

## pnpm

pnpm cài package vào một content-addressable store duy nhất rồi hardlink vào `node_modules` của
từng dự án, thay vì sao chép. Trong bối cảnh nhiều worktree, đó là thứ khiến worktree thứ N khả thi
về đĩa: N thư mục `node_modules` nhưng gần như một bản byte.

**Nói thẳng một điều.** pnpm thường không được chọn vì lý do worktree — nó có mặt từ trước khi vấn
đề nhiều worktree tồn tại. Điều đúng để nói là: thuộc tính store và hardlink của pnpm là thứ khiến
mô hình nhiều worktree trả nổi tiền đĩa. Một lợi ích được thừa hưởng, không phải một quyết định
được cân nhắc. Trình bày nó như lựa chọn có chủ đích là làm đẹp câu chuyện.

Ba tính chất, xếp theo mức liên quan tới nhiều worktree:

- **Đĩa.** npm sao chép, ba worktree là ba lần dung lượng thật. pnpm hardlink, ba checkout cùng ăn
  vào một store.
- **`node_modules` không phẳng.** pnpm không hoist, nên một package chỉ import được thứ nó khai. Với
  nhiều worktree ở nhiều commit khác nhau, điều này chặn cả một lớp lỗi "chạy ở worktree này, hỏng ở
  worktree kia" do đồ hình dependency khác nhau chứ không do code.
- **Install script tắt mặc định.** Muốn chạy thì phải khai tên, nên việc cấp phát `node_modules`
  trở nên tường minh.

**Đánh đổi.** Cái npm và yarn có mà pnpm không có là `node_modules` phẳng, vốn chịu đựng được
package khai thiếu dependency. pnpm sẽ làm lộ những package như vậy. Đó là tính năng, nhưng nó là
chi phí có thật khi bạn kéo về một dependency cũ.

**Một bẫy khi bind-mount repo vào container.** pnpm đặt store trên cùng filesystem với thư mục nó
hardlink vào. Nếu `node_modules` là named volume còn thư mục cha là bind mount thì đó là hai
filesystem, nên pnpm bỏ qua store bạn đã mount và tự dời store sang trong working tree. Kết quả đo
được: volume mount rỗng, còn vài trăm MB store rơi thẳng vào working tree của host dưới dạng thư
mục untracked. Phải che đúng đường dẫn pnpm **thật sự chọn**, không phải đường dẫn tài liệu nói.

## portless

portless là một proxy chạy nền giữ cổng 443 cho cả máy và ánh xạ tên `https://<tên>.localhost`
sang một cổng localhost. Nó thay thế cổng ghim gõ tay và việc phải nhớ số cổng.

Với nhiều worktree, nó giải quyết đúng một việc: khi Docker cấp cổng ngẫu nhiên cho mỗi stack,
phải có thứ gì đó cho con người và cho trình duyệt một **địa chỉ ổn định** trỏ vào cái cổng ngẫu
nhiên đó. Cổng động không có lớp tên là cổng không ai gõ được vào thanh địa chỉ, và một URL không
gõ được thì không có bằng chứng trình duyệt nào.

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
không thể khởi chạy *qua* portless được nữa — Docker cấp cổng trước, rồi bạn đăng ký một alias tĩnh
trỏ tên vào cổng vừa publish.

Quy ước đặt tên cho nhiều worktree gọn trong một dòng, và đáng chép lại:

```make
DEV_SITE := $(if $(filter main,$(DEV_SLUG)),myapp,myapp-$(DEV_SLUG))
```

Nhánh `main` giữ tên trần có chủ ý, còn mọi nhánh khác mang hậu tố. Người mở URL quen thuộc luôn về
main và không lạc vào stack đang dở của một Builder. Chi tiết nhỏ, nhưng nó tách địa chỉ cho con
người khỏi địa chỉ cho agent.

**Đánh đổi.** Một daemon toàn máy giữ cổng 443. Mọi thao tác vòng đời của nó cần sudo, tức cần TTY,
nên một agent chạy nền không làm được và phải nhờ người. Đó là ràng buộc vận hành thật.

**Bốn chỗ hỏng đã biết.** `502` là triệu chứng duy nhất khi cổng lệch, không có lỗi rõ ràng nào
khác — cách kiểm là đối chiếu cổng trong `portless list` với cổng framework in ra, mỗi lần. Proxy
lồng proxy cho `508 Loop Detected` trừ khi bên trong đặt `changeOrigin: true`. Route trùng tên báo
"already registered by a running process" nghĩa là tiến trình cũ còn sống, hãy dọn trước chứ đừng
vội `--force`. Và giết tiến trình cha của portless không giết dev server con, nên tiến trình mồ côi
vẫn giữ route.

**Một thứ dứt khoát không đưa qua portless: cổng CDP của trình duyệt automation.** Client CDP gọi
thẳng `http://127.0.0.1:<cổng>/json`, không đi qua proxy tên miền được. Nhầm lẫn này rất dễ xảy ra
vì cả hai đều là "cổng localhost", nhưng portless phục vụ **app của bạn**, còn cổng CDP là **debug
socket của trình duyệt**.

**Ai không cần.** Ai không thể cho một daemon giữ 443 toàn máy, và máy nhiều người dùng chung. Đội
một app một cổng thì portless là tiện nghi chứ không phải nhu cầu. Nó chỉ thành nhu cầu đúng lúc số
cổng không còn đoán trước được, tức đúng lúc bạn cấp runtime theo worktree.

## browser-qa

Một agent QA lái sản phẩm đang chạy như một người dùng — đi qua giao diện, hành trình, hợp đồng API
và dữ liệu như chúng hiện ra — thay vì đọc diff. Nó viết một file báo cáo để trạm sau đọc lại được.

Lý do phải là trình duyệt thật nằm ở hai chỗ. Có những lớp lỗi chỉ tồn tại sau khi đã dựng hình.
Và health check thường trả lời một câu hỏi dễ hơn câu hỏi cần hỏi: "tiến trình có sống không" không
phải là "người dùng có làm xong việc không".

Công cụ chia làm hai phần. Một trình duyệt thật giữ profile đăng nhập — ở đây là **OmniLogin** —
và **`agent-browser`**, một CLI lái trình duyệt đó qua CDP. Bằng chứng để lại là một file: ảnh
chụp, đường dẫn đã đi, chuỗi chữ đã thấy, kèm số cổng CDP và user agent để trạm sau biết bằng
chứng đến từ trình duyệt nào. Không phải một câu khẳng định trong pane, vì một câu khẳng định thì
trạm sau không kiểm lại được.

**Đây là mục cho thấy vì sao ba mục trên đáng làm.** Bằng chứng trình duyệt đòi mỗi người một stack
đang chạy. Nếu dựng stack còn đắt thì bước này sẽ bị bỏ, và lý do bỏ nghe rất hợp lý. Đo được một
lần, nguyên văn lời một Builder:

> no local stack was running in this worktree; standing one up is a multi-step job

Đó chính xác là chi phí mà mục đầu tiên xoá bỏ.

**Bốn chỗ hỏng, và chúng đều không hiển nhiên.** Một trình duyệt phục vụ nhiều agent thì CDP phơi ra
một tập tab dùng chung và một con trỏ tab-đang-hoạt-động cho cả tiến trình — nên đừng bao giờ mở
trang mà không nêu tab đích tường minh, và hãy kiểm quyền sở hữu tab ở mọi lệnh, kể cả lệnh chỉ
đọc. Kiểm bằng `curl` rồi hành động bằng trình duyệt thì không chứng minh được gì, vì chúng có thể
là hai trình duyệt khác nhau; phải kiểm bằng chính công cụ sắp dùng để hành động. Kết luận "công cụ
không hỗ trợ cờ này" có thể sai vì trên một máy có thể tồn tại hai bản CLI khác phiên bản và bản cũ
resolve trước trong shell — nên hãy kiểm cờ trước mỗi phiên, trên mỗi máy. Và có những cổng không
mở được: một sàn có lớp chống bot ở trước, không có tài khoản cho agent. Luật ở đây là không tìm
cách lách, vì rủi ro điều khoản rơi vào tài khoản thật của chủ dự án, và bằng chứng lấy bằng cách né
chỉ chứng minh được là mình đã né.

**Một luật đáng chép lại.** Một luật mà người vận hành cẩn thận vẫn quên trong vòng một giờ thì cần
một ô bắt buộc chặn việc khởi chạy, không phải một câu văn nằm ở chỗ khác. Ở đây nó là một trường
bắt buộc trong brief dispatch, không có dạng để trống: hoặc khai rõ ticket này cần bằng chứng trình
duyệt và phải đi qua hành trình nào, hoặc khai rõ là không cần và vì sao.

**Ai không cần.** Sản phẩm không có bề mặt người dùng. Đội đã có visual regression tự động đủ dày.
Và đội không chấp nhận được việc agent lái một session đăng nhập thật — đó là lo ngại chính đáng,
và cách đáp là mặc định chỉ đọc, cho phép ghi theo từng lần chạy, kèm một luật rõ: quy tắc là về
**dữ liệu**, không về môi trường. Dữ liệu dẫn xuất từ production vẫn là dữ liệu production, chạy ở
đâu cũng vậy.

## one-shape

Ba kỹ thuật đầu có cùng một hình dạng, và nếu trang này chỉ mang đi được một câu thì nên là câu
này: **biến một việc phải nhớ làm thành một việc được suy ra.**

Tên project suy ra từ nhánh. Cổng suy ra từ Docker. `GIT_DIR` suy ra từ git. Tên miền suy ra từ
nhánh. Không có file env nào phải sửa khi đổi nhánh, nên không có bước nào để quên.

Đó cũng là lý do bốn mục này thuộc về trang của Astragentic chứ không phải một danh sách mẹo. Điều
phối nhiều agent đặt ra một yêu cầu mà làm việc một mình không đặt ra: mọi thứ phải đúng **mà không
ai phải nhớ**, vì bên nhớ không còn là một người.
