# D05 · Đường dữ liệu (Datapath)

---

## 1. Datapath của D05 có một vòng kín và một nhánh cụt

```
                  ┌──────────────── vòng hồi tiếp (loop) ────────────────┐
                  │                                                      │
                  ▼                                                      │
   enable ──▶ ┌─────────────┐  binary_next[7:0]  ┌──────────────┐        │
              │ INCREMENTER │ ══════8 bit═══════▶│  8 × dfxtp_1 │════════┘
   rst_n ───▶ │   +1 / giữ  │                    │binary_state  │
              └─────────────┘                    └──────┬───────┘
                                                        ║ 8 bit
                                                        ▼
                                              ┌────────────────────┐
                                              │  CÂY XOR GRAY      │ ══8══▶ gray_out[7:0]
                                              │  g = b ^ (b >> 1)  │
                                              └────────────────────┘
                                                   ▲ nhánh CỤT:
                                                   không quay về thanh ghi
```

Sự phân tách này là **toàn bộ lý do** D05 nhanh: độ trễ mỗi chu kỳ = max(vòng kín, nhánh
cụt), **không phải** tổng của hai thứ.

## 2. Bảng các đường dữ liệu

| Đường | Độ rộng | Từ | Đến | Bản chất |
|---|---:|---|---|---|
| `enable` | 1 | cổng vào | mọi tầng incrementer (fanout **3** theo STA) | Điều khiển, nhưng đi **trong** datapath như một toán hạng carry-in |
| `rst_n` | 1 | cổng vào | đường `D` của cả 8 FF | Điều khiển đồng bộ, gộp vào logic tổ hợp |
| `binary_state[7:0]` | 8 | 8 FF | incrementer (hồi tiếp) + cây XOR | **Trạng thái — biến duy nhất của khối** |
| `binary_next[7:0]` | 8 | incrementer | `D` của 8 FF | Trạng thái kế tiếp |
| chuỗi carry nội bộ `_10_,_14_,_15_,_19_` | 1 mỗi dây | tầng `i` | tầng `i+1` | **Đường nối tiếp — nguồn gốc độ trễ của vòng kín** |
| `gray_out[7:0]` | 8 | cây XOR / trực tiếp FF `_64_` | cổng ra | Kết quả |
| `gray_out[7]` | 1 | **thẳng từ FF `_64_`** | cổng ra | Độ sâu logic **0** — xem `block_diagram.md` §3 |

## 3. Đồ thị phụ thuộc

### 3.1 Vòng kín — chuỗi carry trong incrementer (đọc từ netlist)

```
  enable ──┐
  B[0] ────┤
  B[1] ────┴──▶ _30_ (and3_1)  = enable & B[1] & B[0]            ← mức 1, fanout 6
                     │
                     ├──▶ _31_ (nand2)  ─▶ _34_ (xnor2) ─▶ _35_ (and2) ─▶ D của B[3]
                     │
       B[2],B[3] ────┴──▶ _37_ (and2_0) = _30_ & (B[3]&B[2])     ← mức 2, fanout 3
                                │
                                ├──▶ _39_ (o21ai) ─▶ _40_ (a21oi) ─▶ D của B[4]
                                │
                 B[5],B[6] ─────┴──▶ _45_ (a21oi_1)              ← mức 3
                                          │
                                          ▼
                                     _46_ (and3b_1)  ← mức 4 (đồng thời AND với rst_n)
                                          │
                                          ▼
                                     D của B[6]   (FF _63_)       ← ĐIỂM CUỐI TỚI HẠN
```

Lưu ý cấu trúc: đây **không** phải ripple 8 tầng như bộ cộng. Yosys đã dựng **tích luỹ theo
cặp**: `(B1&B0)` → `& (B3&B2)` → `& (B5&B4)`. Độ sâu chỉ **4 mức** cho 8 bit thay vì 8 —
vì phép `+1` chỉ cần AND, không cần full-adder.

### 3.2 Nhánh cụt — cây XOR Gray

```
  mức 0:  binary_state[i]  (ra từ FF, đã ổn định)
  mức 1:  xor2(B[i+1], B[i]) ──▶ gray_out[i]          cho i = 0,1,3,5,6
          nor2(nor2(B[i+1],B[i]), and2(B[i+1],B[i])) ──▶ gray_out[i]   cho i = 2,4 (2 mức)
  mức 0:  gray_out[7] = Q của FF _64_                 (không có cổng nào)
```

Yosys hiện thực `gray_out[2]` và `gray_out[4]` bằng **2 cổng NOR + 1 AND** thay vì 1 XOR.
Lý do: các nút trung gian `_14_ = B[3]&B[2]` và `_19_ = B[5]&B[4]` **đã phải tồn tại** cho
chuỗi carry, nên dùng lại chúng rẻ hơn là thêm một XOR mới. Đây là **chia sẻ logic giữa hai
khối con** — thứ mà sơ đồ khối mức RTL không thể hiện được.

## 4. Độ sâu logic của từng đầu ra

| Đầu ra | Độ sâu tính từ FF (reg→out) | Arrival đo được |
|---|---:|---:|
| `gray_out[7]` | **0 cổng** | không xuất hiện trong 10 đường xấu nhất |
| `gray_out[0]` | 1 (`xor2 _25_`) | **0,49 ns** |
| `gray_out[1]` | 1 (`xor2 _49_`) | **0,48 ns** |
| `gray_out[3]` | 1 (`xor2 _52_`) | **0,48 ns** |
| `gray_out[5]`, `gray_out[6]` | 1 | không trong top-10 |
| `gray_out[2]` | 2 (`and2 _36_` → `nor2 _51_`) | **0,62 ns** ← sâu nhất nhánh cụt |
| `gray_out[4]` | 2 (`and2 _43_` → `nor2 _54_`) | **0,60 ns** |

| Đích trạng thái | Độ sâu (in→reg từ `enable`) | Arrival đo được |
|---|---:|---:|
| `binary_state[6]` (FF `_63_`) | 4 cổng | **1,60 ns** ← **tới hạn** |
| `gray_out[7]` (FF `_64_`) | 4 cổng | 1,60 ns (slack 8,29) |
| `binary_state[5]` (FF `_62_`) | 4 cổng | 1,56 ns |
| `binary_state[3]` (FF `_60_`) | 4 cổng | 1,53 ns |
| `binary_state[4]` (FF `_61_`) | 4 cổng | 1,51 ns |

## 5. Dự đoán đường tới hạn từ RTL, rồi đối chiếu STA

### 5.1 Dự đoán khi chỉ đọc RTL

Đọc `d05_core.sv` không có netlist, dự đoán hợp lý là:

> "Đường dài nhất là `binary_state[0] → carry → binary_state[7]`, tức là **reg→reg**, đi
> qua 8 tầng carry của phép `+1`. Cây XOR chỉ 1 mức nên không đáng kể."

### 5.2 STA thật nói gì

| Dự đoán | STA thật | Lệch? |
|---|---|:-:|
| Đường tới hạn nằm trong incrementer | ✅ đúng — 4/4 cell logic thuộc incrementer | ✅ |
| Cây XOR không tới hạn | ✅ đúng — reg→out xấu nhất 0,62 ns so với 1,60 ns | ✅ |
| Loại đường là **reg→reg** | ❌ **SAI** — STA báo **in→reg**, startpoint là cổng `enable` | ❌ |
| Độ sâu 8 tầng carry | ❌ **SAI** — chỉ **4 cổng** | ❌ |
| Điểm cuối là bit 7 | ❌ **SAI** — là `_63_` = `binary_state[6]` | ❌ |

### 5.3 Giải thích ba chỗ lệch

**(a) Vì sao in→reg chứ không phải reg→reg.** File SDC đặt
`set_input_delay 1.0 -clock clk [all_inputs]`. Tín hiệu `enable` do đó "xuất phát" tại
**1,00 ns**, trong khi một FF xuất phát tại `clk→Q` ≈ **0,32–0,37 ns** (đọc cột Delay của
`_59_/Q` trong report). Cùng đi qua cùng chuỗi logic, đường từ `enable` cộng thêm
≈ 0,65 ns "nợ" ngay từ vạch xuất phát. Vậy **đường tới hạn ở đây là hệ quả của một giả
định phân tích, không phải của thiết kế**. Nếu đổi `set_input_delay` về 0, đường tới hạn
sẽ chuyển thành reg→reg và slack tăng thêm ≈ 0,65 ns.

**(b) Vì sao 4 cổng chứ không phải 8 tầng.** Phép `+1` khác phép `a+b`. Carry ra khỏi tầng
`i` của phép `+1` là `enable & B[0] & B[1] & … & B[i]` — một tích AND thuần, **kết hợp
được** (associative). Công cụ vì thế dựng cây nhị phân thay vì chuỗi. Bộ cộng ripple
(đề A01) không có đặc quyền này vì carry của nó là `a&b | (a^b)&cin` — phụ thuộc lẫn nhau
theo thứ tự.

**(c) Vì sao điểm cuối là bit 6 chứ không phải bit 7.** Đường tới `D` của bit 7 là
`_47_(xnor2) → _48_(and2)` = 2 cổng sau nút `_20_`, trong khi đường tới bit 6 là
`_45_(a21oi) → _46_(and3b)` cũng 2 cổng nhưng `and3b_1` phải AND thêm `rst_n` **và** nút
`_20_`, cho arrival 1,60 ns với slack 8,28 so với 8,29 của bit 7. Chênh lệch **0,01 ns** —
nhỏ hơn sai số của bất kỳ mô hình dây nào. Bài học: khi hai đường chênh nhau ở mức phần
trăm nano-giây, **đừng rút kết luận kiến trúc từ việc đường nào "thắng"**.

## 6. Hold (min path) — số liệu thật

`06_GDSII/sta/timing_report_min.txt`, đường xấu nhất:

```
Startpoint: _61_ → _40_ (a21oi_1) → Endpoint: _61_
  data arrival 0,43 ns · library hold time -0,04 ns · slack 0,47 ns (MET)
```

Đây là **đường tự hồi tiếp ngắn nhất** của một bit trạng thái (FF quay về chính nó qua 1
cổng). Slack hold 0,47 ns là con số **trước CTS**, với `clock skew = 0`. Sau CTS, skew
thật sẽ ăn vào con số này — đây là lý do bước 10 (CTS) không thể bỏ qua.

## 7. Vì sao datapath không có thanh ghi nào khác ngoài 8 FF trạng thái

| Câu hỏi | Trả lời |
|---|---|
| Có cần thanh ghi cho `gray_out` không? | Không bắt buộc. Charter mục 10 chốt "8 ô nhớ". Thêm 8 FF cho `gray_out` sẽ thành 16 → vi phạm |
| Thêm 8 FF thì được gì? | `gray_out` trở thành đầu ra thanh ghi hoá, arrival reg→out giảm còn `clk→Q` ≈ 0,35 ns, và **không còn glitch** trên đường ra — có giá trị thật khi đi qua ranh giới clock |
| Vì sao vẫn không làm? | Ràng buộc Charter mục 10 + nhánh cụt hiện chỉ 0,62 ns, chưa phải vấn đề |
| Có pipeline không? | Không — mỗi bước đếm là một chu kỳ, không có gì để cắt |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
