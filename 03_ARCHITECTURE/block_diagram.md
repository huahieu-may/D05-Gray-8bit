# D05 · Sơ đồ khối bên trong (Block Diagram)

---

## 1. Ba khối con, đọc trực tiếp từ `d05_core.sv`

```
        rst_n ──────────────────────────┐
                                        │ (AND vào đường D của mọi FF — reset ĐỒNG BỘ)
                                        │
   enable ──┐                           │
            │                           │
            ▼                           ▼
  ┌───────────────────────┐   ┌──────────────────────┐   ┌───────────────────────────┐
  │  ① INCREMENTER        │   │  ② THANH GHI TRẠNG   │   │  ③ BỘ MÃ HOÁ GRAY         │
  │     (tổ hợp)          │   │     THÁI (8 FF)      │   │     (tổ hợp)              │
  │                       │   │                      │   │                           │
  │  binary_next =        │   │  always_ff @(posedge)│   │  gray_out =               │
  │    enable             │──▶│    binary_state <=   │──▶│    binary_state ^         │
  │      ? binary_state+1 │   │      binary_next     │   │    (binary_state >> 1)    │
  │      : binary_state   │   │                      │   │                           │
  │                       │   │  reset đồng bộ → 0   │   │  7 cổng XOR, ĐỘ SÂU 1     │
  │  dòng 10–14           │   │  dòng 16–21          │   │  dòng 23–25               │
  └───────────────────────┘   └──────────┬───────────┘   └───────────┬───────────────┘
            ▲                            │                           │
            │                            │ binary_state[7:0]         ▼
            └────────────────────────────┘                     gray_out[7:0]
                   (vòng hồi tiếp — đây là thứ làm nó
                    trở thành mạch TUẦN TỰ)
                                                clk ──▶ ② (chỉ ② có clock)
```

Điểm cần nhớ: **vòng hồi tiếp ② → ① → ②** là bản chất tuần tự; nhánh ② → ③ là **nhánh
cụt**, không quay lại. Vì vậy chuỗi carry trong ① và cây XOR trong ③ **không bao giờ nối
tiếp nhau trong cùng một chu kỳ** — một sự thật quyết định toàn bộ phân tích thời gian
(xem `datapath.md` §4).

## 2. Bảng ánh xạ cấu trúc RTL → phần cứng sinh ra

| Dòng RTL | Cấu trúc | Phần cứng thật trong netlist | Số cell |
|---|---|---|---:|
| 10–14 `always_comb` + `+ 8'd1` | Incrementer 8-bit có enable | `and3_1`×1, `and2_0`×~4, `nand2/3/4`×3, `xnor2_1`×3, `a21oi_1`×3, `o21ai_0`×2, `mux2i_1`×1, `and3b_1`×1, `lpflow_isobufsrc_1`×1 | **≈ 19** |
| 16–21 `always_ff` | 8 thanh ghi cạnh lên | `dfxtp_1` × **8** | **8** |
| 17–18 `if (!rst_n)` | **Không sinh FF có chân reset**; `rst_n` được gộp vào logic `D` | nằm trong số 19 cell trên (`and2_0`, `o21ai_0`, `and3b_1`…) | 0 riêng |
| 23–25 `^ (>> 1)` | Cây XOR mã hoá Gray | `xor2_1`×~5, `nor2_1`×4 | **≈ 9** |
| — | Nối `gray_out[7]` | **0 cell** — FF `_64_` xuất thẳng ra cổng | **0** |
| | | **Tổng** | **40** |

Nguồn: `06_GDSII/synthesis/synth_stat.txt` và `netlist.v`. Con số từng nhóm là **ước phân
bổ khi đọc netlist**, tổng 40 là số đo thật.

## 3. Phát hiện quan trọng: Yosys đã **gộp bit 7** của hai khối

Trong RTL có hai tín hiệu 8-bit riêng: `binary_state` và `gray_out`. Trong netlist chỉ còn:

```verilog
wire \binary_state[0] ; ... wire \binary_state[6] ;   // CHỈ 0..6
output [7:0] gray_out;

sky130_fd_sc_hd__dfxtp_1 _64_ (.CLK(clk), .D(_07_), .Q(gray_out[7]));   // ← FF xuất THẲNG gray_out[7]
```

`binary_state[7]` **biến mất** khỏi netlist. Lý do: theo INV-7, `gray_out[7] = binary_state[7]`
đúng theo định nghĩa (bit MSB không qua XOR). Yosys nhận ra hai tín hiệu này là **một**, nên
đặt tên chung và tiết kiệm cả một cổng đệm. Hệ quả dây chuyền: cell `_56_` tính
`gray_out[6] = gray_out[7] ^ binary_state[6]`, tức là dùng lại chính chân ra.

> Đây là ví dụ sạch nhất trong nhóm D về việc **netlist không phải bản dịch 1–1 của RTL**.
> Khi sinh viên tìm `binary_state[7]` trong netlist mà không thấy, câu trả lời không phải
> "tool làm mất", mà là "tool đã chứng minh được hai dây này bằng nhau".

## 4. Phát hiện thứ hai: cell `lpflow_isobufsrc_1` đang làm việc của một cổng AND

```verilog
sky130_fd_sc_hd__mux2i_1 _28_ (.A0(\binary_state[1] ), .A1(gray_out[0]), .S(enable), .Y(_09_));
sky130_fd_sc_hd__lpflow_isobufsrc_1 _29_ (.A(rst_n), .SLEEP(_09_), .X(_01_));
sky130_fd_sc_hd__dfxtp_1 _58_ (.CLK(clk), .D(_01_), .Q(\binary_state[1] ));
```

`lpflow_isobufsrc` là cell **cách ly miền nguồn thấp** (power-gating isolation): `X = A & ~SLEEP`.
Yosys/abc không quan tâm tên cell mang ý nghĩa gì — nó chỉ tra bảng hàm logic và chọn cell
nào rẻ nhất về diện tích/thời gian. Ở đây hàm cần là `rst_n & ~(mux)`, và `isobufsrc` khớp.

**Đây là hành vi đúng của công cụ, không phải lỗi.** Nhưng khi làm physical design thật,
một số dòng LibreLane có danh sách `DONT_USE_CELLS` loại bỏ nhóm `lpflow_*` — khi đó số
cell và diện tích sẽ **thay đổi**, và con số 40 cell / 369,104 µm² trong hồ sơ này sẽ không
còn khớp. Phải nêu điều đó khi so sánh giữa các lần chạy.

## 5. Khối con nào nằm trên đường tới hạn?

Đối chiếu `06_GDSII/sta/timing_report_max.txt`:

```
Startpoint: enable (input port clocked by clk)
Endpoint:   _63_  (dfxtp_1)  →  chính là binary_state[6]
  enable → _30_/and3_1 → _37_/and2_0 → _45_/a21oi_1 → _46_/and3b_1 → _63_/D
  data arrival 1,60 ns · slack 8,28 ns (MET)
```

| Khối con | Có trên đường tới hạn? | Bằng chứng |
|---|:-:|---|
| ① Incrementer | ✅ **Toàn bộ 4 cell logic đều thuộc ①** | `_30_` = `enable & B[1] & B[0]`; `_37_` = `_30_ & B[3] & B[2]`; đây là chuỗi tích luỹ carry |
| ② Thanh ghi | ✅ (là **điểm cuối**) | `_63_/D` |
| ③ Mã hoá Gray | ❌ **KHÔNG** | 5 đường xấu nhất đều kết thúc ở FF, không đường nào đi qua cây XOR |

Đường reg→out đi qua ③ xấu nhất là `_59_ → _36_(and2) → _51_(nor2) → gray_out[2]`, arrival
**0,62 ns**, slack **8,38 ns** — thoải mái hơn đường tới hạn. Kết luận: **chuỗi carry của
incrementer là nút thắt, cây XOR Gray không phải**, đúng như dự đoán từ RTL.

## 6. Vì sao không có khối con thứ tư (bộ điều khiển)?

Không có FSM, không có bộ đếm phụ, không có handshake. Xem `control.md` và `fsm.md`.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
