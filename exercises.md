# Phiếu Phản Ánh — K3 Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Nguyễn Phương Nam  Mã học viên: 2A202601952

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> "chết sớm" biến một lỗi *âm thầm, tốn tiền, khó phát hiện* thành một lỗi *ồn ào, phát hiện ngay, sửa ngay* — đúng thời điểm chi phí sửa còn thấp nhất (lúc bạn còn đang theo dõi, chưa có traffic thật)

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

>
>> Dòng log JSON thu được khi gọi `/ask`:
>> `{"event": "ask_completed", "level": "info", "timestamp": "2026-08-10T05:53:58.816712+00:00", "user_id": "sv-test", "tokens_in": 3, "tokens_out": 41, "cost_usd": 2.505e-05}`
>>
>> Hai việc làm được mà `print("đã trả lời xong")` không làm được:
>>
>> 1. Lọc/tìm theo từng trường cụ thể (vd chỉ xem log của `user_id=sv-test`, hoặc log có `cost_usd` vượt một ngưỡng nào đó) — vì mỗi field là một key riêng trong object, còn `print` chỉ là chuỗi chữ không tách được.
>> 2. Cộng dồn các trường số (`cost_usd`, `tokens_in`, `tokens_out`) để tính tổng chi phí/tổng token theo user hoặc theo ngày một cách tự động — `print` không mang theo dữ liệu có kiểu để tính toán.
>>

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản                 | Dung lượng |
| -------------------- | ------------ |
| 1 stage (bản đầu) | ... MB       |
| Multi-stage          | ... MB       |

Giải thích: phần dung lượng chênh lệch đó là những gì?

>
> | Bản                 | Dung lượng |
> | -------------------- | ------------ |
> | 1 stage (bản đầu) | 1.73 GB      |
> | Multi-stage          | 270 MB       |
>
>> Phần dung lượng chênh lệch (~1.46GB) chủ yếu là base image Python đầy đủ (mang theo compiler, dev headers) và cache của `pip install` — những thứ chỉ cần lúc build, không cần lúc chạy. Ở bản multi-stage, việc cài đặt diễn ra ở stage `builder` riêng biệt; stage `runtime` chỉ copy đúng phần thư viện đã cài xong sang, bỏ lại toàn bộ compiler và cache ở stage `builder`.
>>

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> *Câu trả lời: **Thứ tự lệnh (CP2):** Sửa 1 dòng `app/main.py` rồi build lại: layer `COPY requirements.txt` + `RUN pip install`**được dùng lại từ cache** (nội dung `requirements.txt` không đổi → Docker thấy hash giống, skip chạy lại); chỉ layer `COPY . .` trở đi (copy source, tạo user...) mới  **chạy lại** . Nếu đảo ngược — `COPY . .` lên trước `pip install` — thì bất kỳ thay đổi nào trong code (kể cả sửa 1 dấu chấm phẩy) cũng làm layer `COPY` đổi hash →  **mọi layer sau nó, kể cả `pip install`, đều mất cache** , phải cài lại toàn bộ thư viện từ đầu mỗi lần build.*

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> *Câu trả lời: **Vì sao không chạy root (CP2):** Chuỗi sự kiện: lỗ hổng trong code Python (vd RCE qua thư viện lỗi) → kẻ tấn công chạy được lệnh tuỳ ý **bên trong container** → nếu container chạy bằng root, lệnh đó có toàn quyền root **trong container** → kết hợp thêm 1 lỗ hổng thoát container (container escape, vẫn thỉnh thoảng xảy ra) → thành root luôn trên  **host thật** . Lệnh `USER appuser` cắt chuỗi này ở bước đầu tiên: dù có RCE, tiến trình vẫn chỉ có quyền `appuser` — không đủ quyền để làm những việc nguy hiểm (ghi file hệ thống, cài phần mềm...) ngay cả khi chưa thoát được container.*

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> *Câu trả lời: **Đếm theo phút đồng hồ (CP3):** Nếu reset theo phút đồng hồ (giây 00), user gửi 10 request lúc **10:00:59** (tính vào phút 10:00, chưa vượt hạn mức) rồi gửi tiếp 10 request lúc **10:01:00** (bộ đếm vừa reset về 0, tính vào phút 10:01) → tổng  **20 request trong ~1-2 giây** , mà cả 2 lần đều "đúng luật" 10/phút. Đạt được bằng cách canh đúng thời điểm gửi ngay trước/sau ranh giới phút.*

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> *Câu trả lời: **Rate limit vs cost guard (CP3):** Rate limit đếm **số lượng** request/thời gian; cost guard đếm  **số tiền** . Tình huống rate limit cho qua nhưng cost guard chặn: user chỉ gửi 2 request/phút (dưới hạn mức 10) nhưng mỗi câu hỏi rất dài (50.000 token) → ngân sách tháng bay hết dù request rất ít. Ngược lại: user gửi câu hỏi ngắn, rẻ, tổng tiền vẫn trong ngân sách, nhưng gửi dồn dập 15 request/phút → rate limit chặn ở request thứ 11 dù ngân sách còn dư.*

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> *Câu trả lời: **/health gộp /ready (CP4):** Nếu `/health` cũng kiểm tra Redis: Redis mất kết nối 30s → cả 3 container cùng lúc trả `/health` = 503 (dù process Python hoàn toàn khoẻ) → orchestrator hiểu nhầm cả 3 container "chết" → **restart cả 3 cùng lúc** → trong lúc restart, không còn container nào phục vụ được, **toàn bộ service down hoàn toàn** — trong khi vấn đề thật ra chỉ là Redis, không phải app.*

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> *Câu trả lời: **Stateless (CP4):** Số liệu thật vừa chạy — 4 request liên tiếp cùng `X-User-Id`, nginx rải vào 3 container khác nhau (agent-1: 1 lần, agent-2: 1 lần, agent-3: 2 lần), nhưng `history_length` vẫn tăng đúng liền mạch:  **0 → 2 → 4 → 6** . Nếu lịch sử lưu trong `dict` Python (RAM riêng từng container) thay vì Redis: mỗi lần request rơi vào container khác, `history_length` sẽ **không tăng liên tục** — có lúc tụt về 0 hoặc lặp lại số cũ, vì container đó chưa từng thấy các lượt hỏi trước (chúng nằm trong RAM của container khác).*

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> *Câu trả lời: **Lỗi thật khi deploy (CP5):** Đây là trải nghiệm thật của chính bạn hôm nay — lỗi `uvicorn: Invalid value for '--port': '$PORT' is not a valid integer`. Nguyên nhân: `railway.toml` có `startCommand` ghi đè `CMD` trong Dockerfile, và Railway chạy `startCommand`**không qua shell** nên `$PORT` không được thay giá trị, uvicorn nhận nguyên văn chuỗi `"$PORT"`. Cách tìm ra: đọc `railway logs --deployment --latest` thấy thông báo lỗi rõ ràng. Cách sửa: xoá `startCommand` khỏi `railway.toml`, để Railway dùng `CMD` đã đúng sẵn trong Dockerfile (đã bọc `sh -c` để mở rộng biến môi trường)*
