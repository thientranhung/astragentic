# Loop snippets

Mở ra, copy nguyên một khối, dán vào tab `thomas`.

Đơn vị interval: `s` `m` `h` `d` (vd `30m`). Sàn cứng 60 giây — `15s` bị làm tròn lên `1m`.
Bỏ interval → Claude tự chọn nhịp (nếu tài khoản có bật); bỏ cả interval lẫn prompt → mặc định `10m`.

---

## Thomas — giữ nhịp, tự nhặt ticket mới

```
/loop 30m Thomas: các agent vẫn đang hoạt động chứ? Đảm bảo monitor và watching vẫn tốt. Hết ticket thì chủ động pick ticket mới và làm tiếp. Chỉ dừng khi không còn ticket nào nhặt được VÀ không còn pane nào chạy VÀ không còn gì chờ merge.
```

Nhịp dày hơn thì đổi `30m` → `5m`. Dưới `5m` phần lớn tick sẽ không có gì đổi mà vẫn tốn
nguyên một lượt model; pane chết đã có `herdr-watchdog.sh` bắt ở nhịp 300s.

Ở chế độ cron, Thomas không tự dừng được — muốn nó dừng thật thì thêm vào cuối:
"Khi đủ điều kiện dừng thì xoá cron job này và báo anh một dòng."
