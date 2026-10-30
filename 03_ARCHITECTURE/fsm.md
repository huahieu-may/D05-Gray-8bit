# D05 · Máy trạng thái (FSM)

---

## 1. D05 **có** máy trạng thái — và đó là một máy trạng thái rất đặc biệt

Nhiều người phản xạ "bộ đếm thì không có FSM". Sai. Theo định nghĩa, một máy trạng thái hữu
hạn gồm: tập trạng thái hữu hạn, hàm chuyển trạng thái, hàm ra. D05 có đủ cả ba:

| Thành phần FSM | D05 có gì | Bằng chứng trong RTL |
|---|---|---|
| Tập trạng thái `S` | `{0, 1, …, 255}` — **256 trạng thái** | `logic [7:0] binary_state;` dòng 7 |
| Trạng thái đầu | `S₀ = 0` | dòng 17–18 `if (!rst_n) binary_state <= 8'h00;` |
| Hàm chuyển `δ(s, enable)` | `δ(s,1) = (s+1) mod 256`, `δ(s,0) = s` | dòng 10–14 |
| Hàm ra `λ(s)` | `λ(s) = s ^ (s >> 1)` | dòng 23–25 |
| Thanh ghi trạng thái | 8 × `dfxtp_1` | `netlist.v`, cell `_57_`…`_64_` |

Cái làm nó khác một FSM điều khiển thông thường: **hàm chuyển có cấu trúc số học đều đặn**,
nên nó được hiện thực bằng một incrementer chứ không bằng bảng tra trạng thái. Đây gọi là
**counter-style FSM** (đối lập với **randomly-encoded FSM**).

## 2. Mealy hay Moore — kết luận và bằng chứng

**Moore.** Bằng chứng trực tiếp từ RTL:

```verilog
always_comb begin
    gray_out = binary_state ^ (binary_state >> 1);     // dòng 23–25
end
```

Khối `always_comb` sinh đầu ra **chỉ đọc `binary_state`**. Không có `enable`, không có
`rst_n` trong biểu thức. Vậy `λ` là hàm của trạng thái, không phải của (trạng thái, đầu vào)
→ định nghĩa Moore.

**Bằng chứng thứ hai, từ netlist** — mạnh hơn vì nó chứng minh công cụ cũng "đồng ý":
tìm mọi cell lái `gray_out[*]`:

| Cổng ra | Cell lái | Đầu vào của cell |
|---|---|---|
| `gray_out[0]` | `_25_ xor2_1` | `binary_state[1]`, `binary_state[0]` |
| `gray_out[1]` | `_49_ xor2_1` | `binary_state[2]`, `binary_state[1]` |
| `gray_out[2]` | `_51_ nor2_1` | `_14_`, `_23_` (đều chỉ từ `binary_state`) |
| `gray_out[3]` | `_52_ xor2_1` | `binary_state[4]`, `binary_state[3]` |
| `gray_out[4]` | `_54_ nor2_1` | `_19_`, `_24_` (đều chỉ từ `binary_state`) |
| `gray_out[5]` | `_55_ xor2_1` | `binary_state[6]`, `binary_state[5]` |
| `gray_out[6]` | `_56_ xor2_1` | `gray_out[7]`, `binary_state[6]` |
| `gray_out[7]` | `_64_ dfxtp_1` | **trực tiếp Q của FF** |

**Không một cell nào có `enable` hay `rst_n` ở đầu vào.** Moore được xác nhận ở cả hai tầng.

> Hệ quả thực tế của Moore: `gray_out` **không glitch theo `enable`**. Nếu `enable` nhiễu
> giữa chu kỳ, đầu ra vẫn đứng yên. Với một khối phải gửi tín hiệu qua ranh giới hai miền
> clock, đây không phải chi tiết trang trí — nó là điều kiện cần.

## 3. Sơ đồ trạng thái (ASCII)

Vẽ đủ 256 nút là vô nghĩa. Dưới đây là cấu trúc thật — **một vòng tròn đơn (single cycle),
không có nhánh, không có trạng thái chết**:

```
                    enable=0 ⟳          enable=0 ⟳          enable=0 ⟳
                       ╭─╮                 ╭─╮                 ╭─╮
                       │ │                 │ │                 │ │
        rst_n=0        ▼ │      en=1       ▼ │      en=1       ▼ │
   ══════════════▶ ┌────────┐ ────────▶ ┌────────┐ ────────▶ ┌────────┐ ──▶ …
   (từ MỌI trạng    │ S=0    │           │ S=1    │           │ S=2    │
    thái, tại cạnh  │ G=0x00 │           │ G=0x01 │           │ G=0x03 │
    lên clk)        └────────┘           └────────┘           └────────┘
                       ▲                                           │
                       │                                           ▼
                       │                                          …
                       │
                       │                 ┌────────┐   en=1   ┌────────┐
                       └─────────────────│ S=255  │◀─────────│ S=254  │
                          en=1           │ G=0x80 │          │ G=0x81 │
                        (QUAY VÒNG:      └────────┘          └────────┘
                         đổi bit 7)
```

Đặc điểm đồ thị:
- **Mỗi nút có đúng 2 cung ra**: tự lặp (`enable=0`) và tiến một bước (`enable=1`).
- **Mỗi nút có đúng 1 cung vào** từ vòng đếm, cộng cung reset từ mọi nơi.
- Đồ thị **liên thông mạnh**: từ bất kỳ trạng thái nào cũng tới được mọi trạng thái khác
  (nhiều nhất 255 bước). **Không có trạng thái hấp thụ (absorbing state), không có bẫy.**

## 4. Bảng chuyển trạng thái

Dạng tổng quát (đúng cho cả 256 hàng):

| Trạng thái hiện tại `S` | `rst_n` | `enable` | Trạng thái kế `S'` | Đầu ra `G = λ(S)` | Bit Gray đổi khi `S→S'` |
|---|:-:|:-:|---|---|---|
| bất kỳ | 0 | × | `0` | `λ(S)` (Moore: theo `S` **hiện tại**) | — |
| `s` | 1 | 0 | `s` | `λ(s)` | không đổi |
| `s` (`s ≠ 255`) | 1 | 1 | `s+1` | `λ(s)` | bit thứ `k`, với `k` = số bit 1 liên tiếp ở đuôi của `s` |
| `255` | 1 | 1 | `0` | `0x80` | **bit 7** |

Bảng liệt kê các hàng **đặc trưng** (phần còn lại suy theo quy luật trên — xem
`corner_cases.md` §3 cho thống kê đầy đủ 9 lớp):

| `S` | `rst_n` | `enable` | `S'` | `G` hiện tại | `G` kế | Bit đổi |
|---:|:-:|:-:|---:|---|---|---:|
| 0 | 1 | 1 | 1 | `0x00` | `0x01` | 0 |
| 1 | 1 | 1 | 2 | `0x01` | `0x03` | 1 |
| 3 | 1 | 1 | 4 | `0x02` | `0x06` | 2 |
| 7 | 1 | 1 | 8 | `0x04` | `0x0C` | 3 |
| 15 | 1 | 1 | 16 | `0x08` | `0x18` | 4 |
| 31 | 1 | 1 | 32 | `0x10` | `0x30` | 5 |
| 63 | 1 | 1 | 64 | `0x20` | `0x60` | 6 |
| **127** | 1 | 1 | 128 | `0x40` | `0xC0` | **7** |
| 128 | 1 | 1 | 129 | `0xC0` | `0xC1` | 0 |
| 254 | 1 | 1 | 255 | `0x81` | `0x80` | 0 |
| **255** | 1 | 1 | **0** | `0x80` | `0x00` | **7** — quay vòng |
| 100 | 1 | 0 | 100 | `0x56` | `0x56` | — (giữ) |
| 100 | 0 | × | 0 | `0x56` | `0x00` | 3 bit (reset **không** giữ tính chất Gray) |

> ⚠️ Hàng cuối đáng lưu ý khi bảo vệ: **reset không phải một "bước Gray"**. Từ `S=100`
> (`G=0x56`) về `S=0` (`G=0x00`) đổi 4 bit cùng lúc. INV-3 chỉ phát biểu cho các bước có
> `enable=1` và `rst_n=1`. Nếu một bên nhận ở miền clock khác đang lấy mẫu đúng lúc reset,
> nó **vẫn có thể đọc sai nhiều nấc**. Kết luận: reset phải được coi là sự kiện toàn hệ
> thống, không được hạ `rst_n` riêng cho D05 trong lúc chạy.

## 5. Mã hoá trạng thái

| Phương án | Số FF | D05 dùng? | Bằng chứng |
|---|---:|:-:|---|
| **Nhị phân tuần tự** (binary) | **8** | ✅ | `binary_state[7:0]`, 8 × `dfxtp_1` |
| Gray (lưu thẳng mã Gray) | 8 | ❌ (có file đối chứng `d05_direct_gray.sv`, không dùng) | Module không được instantiate |
| One-hot | 256 | ❌ | Sẽ vi phạm Charter mục 10 ("8 ô nhớ") gấp 32 lần |

Yosys **không** áp dụng `fsm_detect`/`fsm_encode` cho D05 — vì `binary_state` tham gia phép
cộng, nó được nhận diện là **thanh ghi dữ liệu**, không phải thanh ghi trạng thái điều
khiển. Bằng chứng: netlist giữ nguyên tên `binary_state[0..6]` với cấu trúc incrementer,
không có bảng tra trạng thái nào.

Điểm thú vị: **đầu ra của FSM này lại là mã Gray của trạng thái**. Tức là D05 dùng mã hoá
trạng thái nhị phân *bên trong* và mã hoá Gray *bên ngoài* — đúng chiến lược mà Charter mục
2 câu 2 đang hỏi. Chi phí của việc chuyển đổi này đo được: **≈ 9 cell** (6 `xor2` + 4 `nor2`,
trừ phần dùng chung với chuỗi carry) trên tổng 40 cell, tức **≈ 22 %** diện tích logic.

## 6. Xử lý trạng thái bất hợp lệ

**D05 không có trạng thái bất hợp lệ.** Không gian mã hoá là `2⁸ = 256` giá trị và tập
trạng thái hợp lệ cũng đúng 256 → **ánh xạ phủ kín, không dư mã nào**.

| Hệ quả | Giải thích |
|---|---|
| Không cần nhánh `default` | Trong RTL không có `case`, không có `default` cần bổ sung |
| Không thể bị **lock-up** | Mọi giá trị 8 bit đều nằm trên vòng đếm; sau nhiều nhất 255 bước là trở lại đúng pha |
| Nhưng **không tự sửa sai** | Nếu một FF bị lật do nhiễu, `binary_state` nhảy sang một trạng thái **hợp lệ nhưng sai vị trí**. Hệ thống không có cách nào phát hiện — khối không có bit chẵn lẻ, không có CRC |
| So với one-hot | FSM one-hot **có** trạng thái bất hợp lệ (248 trong 256), nên phát hiện được lỗi, nhưng tốn 256 FF |

**Khi nào cần xử lý trạng thái bất hợp lệ?** Nếu đề mở rộng sang "Gray cân bằng" hoặc đếm
modulo khác luỹ thừa 2 (ví dụ modulo-100 cho bộ mã hoá 100 nấc), lúc đó `2⁸ > 100` sẽ sinh
156 mã dư và **bắt buộc** phải có nhánh phục hồi:

```verilog
// CHỈ là minh hoạ cho trường hợp modulo-100, KHÔNG áp dụng cho D05 hiện tại
else if (binary_state >= 8'd100) binary_state <= 8'd0;   // khôi phục an toàn
```

Charter mục 3 liệt "Gray cân bằng" vào **ngoài phạm vi**, nên đoạn trên chỉ để trả lời khi
bảo vệ, không được đưa vào RTL nộp bài.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
