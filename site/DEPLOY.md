# Deploy

Site: **https://astragentic.thisistool.com** → Cloudflare Workers static assets, worker `astragentic`,
account `Thien.tranhung@gmail.com` (cùng account với blog.thisistool.com).

Direct upload từ máy này, không nối Git. Repo là monorepo, thư mục site chỉ là một góc,
và không có gì cần build trên server của Cloudflare.

## Mỗi lần deploy

```bash
cd site
pnpm run deploy        # = astro build && wrangler deploy
```

Phải gõ `pnpm run deploy`, vì `pnpm deploy` không có `run` là lệnh built-in của pnpm.
Wrangler chỉ upload file thay đổi, thường dưới 20 giây.

## Cấu hình

- `wrangler.jsonc`: tên worker, account, custom domain (`routes`), thư mục `dist` (`assets`).
  Có `$schema` trỏ vào schema của wrangler đã cài nên editor kiểm tra được field.
- Wrangler ghim trong `devDependencies` (4.131.0). Chạy qua `pnpm exec wrangler` hoặc script,
  đừng dùng `npx wrangler` để khỏi lệch phiên bản.
- Kiểm tra trước khi deploy thật: `pnpm exec wrangler deploy --dry-run`.

## Setup một lần (đã làm 2026-09-11)

1. `pnpm exec wrangler login` (mở trình duyệt, chạy tay).
2. `pnpm run deploy` lần đầu vừa tạo worker vừa gắn custom domain. Cloudflare tự tạo DNS
   và cấp SSL, mất vài phút. Nếu máy đã lỡ resolve domain trước khi DNS có, cache macOS giữ
   kết quả "không tồn tại" một lúc; xoá bằng `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`.

## Không cần

- Không có `.env`, không R2/S3. Mọi ảnh và video nằm trong `public/`, đi cùng repo.
- Không có biến môi trường trên Cloudflare.
- Không cần GitHub Action. Nếu sau này muốn tự động, thêm một workflow chạy
  `wrangler deploy` với secret `CLOUDFLARE_API_TOKEN` và `paths: site/**`.

## Lưu ý

- Wrangler 4.x gộp Pages vào Workers. Không dùng `wrangler pages ...` nữa.
- workers.dev bị tắt khi có custom domain. Muốn có URL preview thì thêm
  `"workers_dev": true` và `"preview_urls": true` vào wrangler.jsonc.
- Mỗi file tối đa 25 MiB. Video lớn nhất hiện tại ~5 MB.
- Plugin `cloudflare@cloudflare` đã cài ở phạm vi user; skill `cloudflare:wrangler` là nơi
  tra lệnh và field cấu hình trước khi sửa.
