# D05 · Đặc tả chức năng (Functional Specification)

---

## ⚠️ CẢNH BÁO TUÂN THỦ — Charter mục 4 CHƯA THOẢ

Đọc RTL thật (`04_IMPLEMENTATION/rtl/d05_core.sv`) và đối chiếu với ánh xạ chân Charter
mục 4, phát hiện hai điểm **chưa thoả**:

| # | Charter mục 4 yêu cầu | RTL `d05_core` thật có | Trạng thái |
|---|---|---|---|
| C4-1 | `uo_out[7:0]` = mã Gray | `gray_out[7:0]` — có | ✅ THOẢ (tên khác, vai trò đúng) |
| C4-2 | `uio_in[0]` = cho phép | `enable` — có | ✅ THOẢ |
| C4-3 | **`uio_out[7:0]` = nhị phân tương đương** | **KHÔNG có cổng nào xuất `binary_state`** | ❌ **CHƯA THOẢ** |
| C4-4 | Vỏ Tiny Tapeout (`ui_in`/`uo_out`/`uio_*`, `uio_oe`) | Không có module vỏ trong hồ sơ | ❌ **CHƯA THOẢ** |

**Bằng chứng C4-3:** trong `d05_core.sv` danh sách cổng chỉ gồm `clk`, `rst_n`, `enable`,
`gray_out[7:0]`. Tín hiệu `binary_state[7:0]` được khai báo ở dòng 7 là `logic` **nội bộ**,
không nối ra ngoài. Netlist sau tổng hợp (`06_GDSII/synthesis/netlist.v`) xác nhận: chỉ có
`output [7:0] gray_out`, `binary_state[0..6]` là `wire` nội bộ.

**Hệ quả kiểm thử:** ca "kiểm giá trị nhị phân tương đương" của Charter mục 8 **không thể
quan sát từ cổng ra** của khối hiện tại; testbench muốn kiểm phải thăm dò tín hiệu nội bộ
(`dut.binary_state`) — đó là kiểm hộp trắng, không phải kiểm qua giao diện.

**Không tự sửa RTL.** Bản vá tối thiểu đề xuất (chờ thầy duyệt): thêm
`output logic [7:0] binary_out;` và `assign binary_out = binary_state;`. Chi phí: 0 cell
tổ hợp (chỉ là dây), 8 chân ra thêm → tổng 1+16 = 17 chân, vẫn nằm trong 24 chân theo đúng
ngân sách Charter mục 4 đã tính.

**Ghi chú thêm:** Charter mục 4 nêu "lỗi ánh xạ cần sửa: chân `uio[0]` bị gán vừa làm đầu
vào vừa làm đầu ra". Trong `d05_core` lỗi này **không xuất hiện** vì khối chưa có vỏ Tiny
Tapeout; nhưng khi viết vỏ, phải đánh số lại: `ui_in[0]` = cho phép, `uo_out[7:0]` = Gray,
`uio_out[7:0]` = nhị phân với `uio_oe = 8'hFF`.

---

## 1. Phát biểu hành vi (độc lập với hiện thực)

Khối D05 là một **bộ đếm modulo-256 xuất mã Gray**. Gọi `B(t)` là giá trị đếm nhị phân ở
chu kỳ `t`, `G(t)` là mã Gray xuất ra.

```
  B(t+1) = 0                       nếu rst_n = 0   tại cạnh lên thứ t+1
  B(t+1) = (B(t) + 1) mod 256      nếu rst_n = 1 và enable = 1
  B(t+1) = B(t)                    nếu rst_n = 1 và enable = 0

  G(t)   = B(t) XOR (B(t) >> 1)    — tổ hợp thuần, cùng chu kỳ
```

Phép `>> 1` là dịch phải logic, bit chèn vào vị trí 7 là `0`.

## 2. Bảng chân trị của phép mã hoá Gray (từng bit)

| Bit ra | Biểu thức | Ghi chú |
|---|---|---|
| `gray_out[7]` | `B[7]` | **Chỉ là dây** — bit cao nhất của Gray = bit cao nhất của nhị phân |
| `gray_out[6]` | `B[7] ^ B[6]` | |
| `gray_out[5]` | `B[6] ^ B[5]` | |
| `gray_out[4]` | `B[5] ^ B[4]` | |
| `gray_out[3]` | `B[4] ^ B[3]` | |
| `gray_out[2]` | `B[3] ^ B[2]` | |
| `gray_out[1]` | `B[2] ^ B[1]` | |
| `gray_out[0]` | `B[1] ^ B[0]` | |

Tổng cộng **7 cổng XOR 2 đầu vào**, độ sâu logic **1 mức**. Đây là toàn bộ chi phí của
phép mã hoá.

## 3. Bảng trạng thái rút gọn (12 bước đầu + biên quay vòng)

| `B` | Nhị phân | `G` (hex) | Gray nhị phân | Bit đổi so với bước trước |
|---:|---|---:|---|---|
| 0 | 0000 0000 | 00 | 0000 0000 | — (trạng thái reset) |
| 1 | 0000 0001 | 01 | 0000 0001 | bit 0 |
| 2 | 0000 0010 | 03 | 0000 0011 | bit 1 |
| 3 | 0000 0011 | 02 | 0000 0010 | bit 0 |
| 4 | 0000 0100 | 06 | 0000 0110 | bit 2 |
| 5 | 0000 0101 | 07 | 0000 0111 | bit 0 |
| 6 | 0000 0110 | 05 | 0000 0101 | bit 1 |
| 7 | 0000 0111 | 04 | 0000 0100 | bit 0 |
| 8 | 0000 1000 | 0C | 0000 1100 | bit 3 |
| … | … | … | … | … |
| 254 | 1111 1110 | 81 | 1000 0001 | bit 1 |
| 255 | 1111 1111 | 80 | 1000 0000 | bit 0 |
| 0 | 0000 0000 | 00 | 0000 0000 | **bit 7** — quay vòng |

Bảng này lấy từ công thức §1; ba dòng cuối được kiểm độc lập bởi
`05_VERIFICATION/golden_model/reference_model.py` dòng 37–39
(`hamming(sequence[255], sequence[0]) == 1`, `sequence[255] == 0x80`).

## 4. Ràng buộc cấu trúc bắt buộc

Tên đề chỉ nói "Bộ đếm Gray 8-bit", **không chỉ định kiến trúc**. Do đó cả hai cách hiện
thực dưới đây đều hợp lệ về mặt tên đề:

| Cách | Trạng thái lưu | Có trong hồ sơ |
|---|---|---|
| **(A) Đếm nhị phân → mã hoá Gray** | `binary_state[7:0]` | `d05_core.sv` — **đang là top** |
| (B) Lưu thẳng Gray, giải mã → +1 → mã hoá lại | `gray_out[7:0]` | `d05_direct_gray.sv` — có mặt, **không được instantiate ở đâu** |

Ràng buộc bắt buộc thật sự đến từ **Charter mục 10** ("dấu hiệu làm đúng: 8 ô nhớ"): dù
chọn cách nào, khối chỉ được có **đúng 8 flip-flop**. Đo được: **8 `dfxtp_1`**
(`06_GDSII/synthesis/synth_stat.txt`) → thoả.

> Lưu ý quan trọng khi chấm: `d05_direct_gray.sv` nằm trong thư mục RTL nhưng **không
> tham gia** vào top, không được tổng hợp, và Icarus đã cảnh báo về nó
> (`05_VERIFICATION/iverilog_compile.log`). Nó là **vật liệu đối chứng**, không phải
> thiết kế nộp bài. Mọi con số cell/diện tích trong hồ sơ đều là của `d05_core`.

## 5. Tính chất bất biến (invariants) — dùng làm assertion

| # | Phát biểu | Kiểm bằng |
|---|---|---|
| **INV-1** | `gray_out == binary_state ^ (binary_state >> 1)` ở mọi thời điểm ổn định | assertion tổ hợp; hiện **chưa có** trong testbench |
| **INV-2** | Ánh xạ `B → G` là song ánh trên `{0..255}` | `reference_model.py` dòng 31: `len(set(sequence)) == 256` ✅ |
| **INV-3** | `popcount(G(t+1) ^ G(t)) == 1` với mọi `t` khi `enable=1`, **kể cả** `255→0` | `reference_model.py` dòng 33–37 ✅ · **chưa** kiểm trong mô phỏng RTL ❌ |
| **INV-4** | Sau cạnh lên có `rst_n=0`: `binary_state == 0` và `gray_out == 0x00` | testbench dòng 45–48 ✅ |
| **INV-5** | `enable == 0` ⇒ `gray_out(t+1) == gray_out(t)` | testbench dòng 51 (`repeat(2) check()`) ✅ |
| **INV-6** | Chu kỳ lặp đúng bằng 256 chu kỳ clock khi `enable` giữ mức 1 | `reference_model.py` dòng 44–48 ✅ |
| **INV-7** | `gray_out[7] == binary_state[7]` (bit MSB không qua XOR) | netlist: FF `_64_` xuất thẳng `gray_out[7]` ✅ |

> ❗ **Lỗ hổng cần nêu khi chấm:** INV-3 là **chính tính chất mà Charter mục 9 bắt buộc
> kiểm bằng mô phỏng**, nhưng testbench SystemVerilog **không kiểm nó**. Xem
> `corner_cases.md` §5 để biết chi tiết và bản vá đề xuất.

## 6. Điều kiện biên và hành vi không xác định

| Tình huống | Hành vi của `d05_core` | Có xác định không? |
|---|---|---|
| Trước cạnh lên đầu tiên (t = 0⁻) | `binary_state` = `8'hxx` trong mô phỏng | ❌ **Không xác định** — `logic` chưa khởi tạo |
| `rst_n = 0` nhưng **không có cạnh lên** | `binary_state` giữ nguyên | ✅ Xác định — reset là **đồng bộ** |
| `rst_n` và `enable` cùng tích cực | `rst_n` thắng (dòng 17 `if (!rst_n)` đứng trước) | ✅ Xác định |
| `enable` đổi mức sát cạnh lên | Vi phạm setup → giá trị chốt không xác định | ❌ Nghĩa vụ tầng ngoài |
| `B` = 255 và `enable = 1` | `B → 0`, `G: 0x80 → 0x00` (đổi bit 7) | ✅ Xác định, quay vòng |
| `enable` = X/Z | `binary_next` = X → lan vào trạng thái | ❌ Nghĩa vụ tầng ngoài |

**Về reset đồng bộ:** `always_ff @(posedge clk)` **không** có `rst_n` trong danh sách nhạy,
nên đây là reset **đồng bộ**. Bằng chứng ở netlist: không có cell `dfrtp`/`dfstp` (FF có
chân reset); thay vào đó `rst_n` được AND vào đường `D` của từng FF, ví dụ:

```verilog
sky130_fd_sc_hd__and2_0 _27_ (.A(rst_n), .B(_08_), .X(_00_));   // D của binary_state[0]
```

Hệ quả thực tế: **phải có ít nhất một cạnh lên `clk` trong lúc `rst_n = 0`** thì khối mới
về trạng thái 0. Đây là nghĩa vụ của tầng ngoài và đã ghi ở `interface.md` §4.

## 7. Độ trễ từ đầu vào tới đầu ra (mạch tuần tự)

| Đường | Độ trễ |
|---|---|
| `enable` (mức tại cạnh `t`) → `binary_state` đổi | **1 chu kỳ** (chốt tại cạnh `t`) |
| `binary_state` → `gray_out` | **0 chu kỳ** (tổ hợp thuần) |
| `enable` → `gray_out` phản ánh bước đếm mới | **1 chu kỳ** |
| `rst_n = 0` → `gray_out = 0x00` | **1 chu kỳ** (cần 1 cạnh lên) |

Không có pipeline, không có handshake, không có tín hiệu `done`/`valid`.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
