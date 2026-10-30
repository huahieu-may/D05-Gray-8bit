# D05 · Phần điều khiển (Control)

---

## 1. D05 là mạch tuần tự, nhưng phần điều khiển của nó ở mức tối giản nhất có thể

Khối có ô nhớ (8 FF) nên **có** trạng thái, nhưng trạng thái đó **là dữ liệu**
(`binary_state` = vị trí góc quay), không phải **trạng thái điều khiển**. Không có tín hiệu
nào trong D05 quyết định "bước xử lý nào đang chạy".

Chỉ có hai tín hiệu điều khiển, cả hai đều **mức (level)**, không phải xung:

| Tín hiệu | Chiều | Tác dụng | Hiện thực trong RTL | Hiện thực trong netlist |
|---|---|---|---|---|
| `rst_n` | vào, tích cực thấp | Ép `binary_state` về `8'h00` tại cạnh lên kế tiếp | `d05_core.sv` dòng 17–18 | AND vào đường `D` của cả 8 FF (`_27_`, `_29_`, `_33_`, `_35_`, `_40_`, `_42_`, `_46_`, `_48_`) |
| `enable` | vào, tích cực cao | Cho phép đếm; `0` = giữ nguyên | dòng 12–13 | Là đầu vào của `_26_ (xor2)`, `_28_ (mux2i)`, `_30_ (and3)` — fanout **3** |

## 2. Bảng tín hiệu điều khiển và tác dụng đầy đủ

| `rst_n` | `enable` | Tại cạnh lên `clk` | `gray_out` sau đó |
|:-:|:-:|---|---|
| 0 | 0 | `binary_state ← 0` | `0x00` |
| 0 | 1 | `binary_state ← 0` (**reset thắng**) | `0x00` |
| 1 | 0 | `binary_state ← binary_state` (giữ) | không đổi |
| 1 | 1 | `binary_state ← (binary_state + 1) mod 256` | bước Gray kế tiếp |

Bằng chứng ưu tiên của `rst_n`: trong netlist, `rst_n` là toán hạng của **cổng cuối cùng**
trên mọi đường `D`. Ví dụ `_27_`:

```verilog
sky130_fd_sc_hd__and2_0 _27_ (.A(rst_n), .B(_08_), .X(_00_));   // _00_ là D của binary_state[0]
```

`rst_n = 0` ⇒ `_00_ = 0` bất kể `_08_` (vốn chứa `enable`). Ưu tiên tuyệt đối, đúng ngữ
nghĩa `if (!rst_n) … else …` của RTL.

## 3. Quan hệ điều khiển ↔ datapath

```
                 ĐIỀU KHIỂN                           DATAPATH
            ┌─────────────────┐              ┌─────────────────────────┐
  enable ──▶│  KHÔNG có FSM   │──enable──┬──▶│ incrementer: +1 hay giữ │
            │  KHÔNG có ô nhớ │          │   │                         │
  rst_n  ──▶│  điều khiển     │──rst_n───┼──▶│ AND cuối trước D của FF │
            │                 │          │   └─────────────────────────┘
            │  chỉ là 2 DÂY   │          │
            └─────────────────┘          └──▶ (enable ĐỒNG THỜI là toán hạng
                  0 cell                       carry-in của tầng 0 — xem dưới)
```

Điểm đặc biệt đáng dạy: trong D05, `enable` **không** được hiện thực như một mux chọn giữa
`binary_state` và `binary_state+1`. Yosys đã nhận ra rằng `+1` khi `enable=1` và `+0` khi
`enable=0` chính là **phép cộng với carry-in = `enable`**. Bằng chứng ở cell đầu tiên của
chuỗi:

```verilog
sky130_fd_sc_hd__xor2_1 _26_ (.A(enable), .B(\binary_state[0] ), .X(_08_));   // b0 XOR enable
sky130_fd_sc_hd__and3_1 _30_ (.A(enable), .B(\binary_state[1] ), .C(\binary_state[0] ), .X(_10_));
```

`_08_ = B[0] ^ enable` — đúng là tổng của một half-adder với carry-in `enable`. Vậy
**tín hiệu điều khiển đã hoà tan vào datapath**, không còn ranh giới vật lý giữa hai phần.
Đây cũng là lý do `enable` trở thành startpoint của đường tới hạn (xem `datapath.md` §5).

Một điều khiển được hiện thực bằng mux riêng sẽ tốn thêm 8 cell `mux2` và làm sâu thêm 1
mức logic. Netlist chỉ dùng **1** `mux2i_1` (cho bit 1) — còn lại đều hoà tan.

## 4. Những thứ điều khiển mà D05 **không** có, và ai chịu trách nhiệm

| Cơ chế | Có trong D05? | Ai lo |
|---|:-:|---|
| FSM / thanh ghi trạng thái điều khiển | ❌ | Không cần — xem `fsm.md` |
| `start` / `done` / `busy` | ❌ | Tầng ngoài: khối chạy liên tục, không có "giao dịch" |
| `valid` / `ready` (handshake) | ❌ | Tầng ngoài. Bên nhận ở miền clock B tự quyết định khi nào đọc |
| Nạp giá trị đầu (`load`) | ❌ | Không có trong Charter |
| Đếm lùi, đổi chiều | ❌ | Ngoài phạm vi |
| Bộ chia tần sinh `enable` | ❌ | Tầng ngoài (cảm biến sinh xung) |
| Đồng bộ hoá `enable` từ miền khác | ❌ | **Tầng ngoài — bắt buộc.** Nếu `enable` đến từ miền clock khác mà không qua 2 tầng FF, khối có thể đếm nhảy bước |

## 5. Nghĩa vụ hợp đồng của tầng ngoài — phát biểu chặt

| # | Nghĩa vụ | Hậu quả nếu vi phạm |
|---|---|---|
| OB-1 | Giữ `rst_n = 0` qua **ít nhất 1 cạnh lên `clk`** | Trạng thái giữ nguyên giá trị X sau khi bật nguồn; `gray_out` = X |
| OB-2 | `enable` ổn định quanh cạnh lên (`setup`/`hold`) | FF chốt giá trị metastable → `binary_state` có thể nhảy sang một giá trị bất kỳ, phá vỡ INV-3 |
| OB-3 | Bên nhận ở miền clock khác **vẫn phải** đồng bộ 2 tầng | Gray giảm hậu quả đọc sai còn 1 nấc, **không** loại bỏ metastability |
| OB-4 | Nếu cần đọc giá trị nhị phân, tầng ngoài phải tự giải mã Gray | D05 hiện **không xuất** `binary_state` — xem cảnh báo C4-3 ở `functional_spec.md` |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
