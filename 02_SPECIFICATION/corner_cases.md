# D05 · Ca biên và ca kiểm thử (Corner Cases)

---

## 1. Đọc testbench thật trước khi bàn ca nào thiếu

File: `05_VERIFICATION/testbench/d05_core_tb.sv` (67 dòng). Cấu trúc thực tế:

```verilog
task automatic check;                     // dòng 31–38
    @(posedge clk); #1;
    assert(gray_out === gray_ref)
        else $fatal(1, "Mismatch: got=%02h ref=%02h", gray_out, gray_ref);
endtask
```

Toàn bộ kiểm chứng của mô phỏng RTL nằm gọn trong **một** so sánh: `gray_out === gray_ref`.
`gray_ref` sinh từ `d05_reference.sv`.

> 🔎 **Phát hiện 1 — so sánh cùng huyết thống.** So `d05_reference.sv` (dòng 9–17) với
> `d05_core.sv` (dòng 10–24): cả hai đều *đếm nhị phân rồi XOR dịch phải*. Cùng thuật toán,
> cùng kiểu reset đồng bộ, cùng mã hoá. Nếu công thức Gray bị viết sai **giống nhau** ở cả
> hai file (ví dụ `<< 1` thay vì `>> 1`), testbench vẫn báo PASS. Đây là **lỗi đồng pha
> (common-mode error)** — mô hình chuẩn không thực sự độc lập.
>
> Cái cứu hồ sơ này là `reference_model.py`: nó không so hai mạch với nhau mà kiểm **tính
> chất** (song ánh, Hamming = 1). Đó mới là mô hình chuẩn độc lập thật.

> 🔎 **Phát hiện 2 — hàm đếm bit khai báo nhưng không dùng.** Dòng 22–29 định nghĩa
> `function automatic integer popcount8(...)`. Tìm toàn file: **`popcount8` không được gọi
> ở bất kỳ đâu**. Tức là tác giả đã dự định kiểm "mỗi bước chỉ đổi 1 bit" trong mô phỏng
> RTL nhưng chưa viết xong. Hệ quả: **INV-3 — đúng tính chất Charter mục 9 bắt buộc —
> chưa được kiểm trên RTL**, chỉ được kiểm trên mô hình Python.

## 2. Ca bắt buộc của Charter mục 8

| Ca | Charter yêu cầu | Lý do kỹ thuật vì sao ca này được chọn | Có trong TB SV? | Có trong Python? |
|---|---|---|---|---|
| **CC-1** | Chạy đủ 256 bước | Bộ đếm modulo-256 chỉ lộ lỗi quay vòng ở bước 255→0. Chạy 10 bước không phân biệt được bộ đếm đúng với bộ đếm bão hoà ở 255 hay bộ đếm 7-bit. 256 là **số bước tối thiểu để phủ hết không gian trạng thái**, không phải con số tuỳ tiện | ✅ dòng 57–62 | ✅ dòng 44–48 |
| **CC-2** | Mỗi bước chỉ đổi đúng 1 bit | Đây là **định nghĩa** của mã Gray, không phải hệ quả phụ. Nếu tính chất này hỏng, khối vẫn đếm đủ 256 giá trị khác nhau mà vẫn vô dụng cho ứng dụng qua hai miền clock | ❌ **KHÔNG** (xem §1, phát hiện 2) | ✅ dòng 33–37 |
| **CC-3** | Kiểm giá trị nhị phân tương đương | Bảo đảm mã Gray không chỉ "đổi 1 bit" mà còn **đúng thứ tự**. Một chuỗi Gray tuỳ ý cũng đổi 1 bit mỗi bước nhưng không tương ứng 0,1,2,3… | ❌ **không quan sát được** — xem `functional_spec.md` cảnh báo C4-3 | ✅ dòng 30 (dựng từ `gray(i)` theo `i`) |

### Vì sao CC-1 phủ đúng 256 bước — kiểm lại bằng cách đếm cạnh clock

| Đoạn TB | Số lần `check()` | Giá trị `binary_state` khi lấy mẫu |
|---|---:|---|
| dòng 45 `repeat(2) check()` | 2 | 0 (đang reset) |
| dòng 48 `check()` | 1 | 0 (`rst_n=1`, `enable=0`) |
| dòng 51 `repeat(2) check()` | 2 | 0 (giữ) |
| dòng 57 `check()` | 1 | 1 |
| dòng 59 `repeat(254) check()` | 254 | 2 … 255 |
| dòng 62 `check()` | 1 | **0 — sau quay vòng** |

Tổng 261 lần lấy mẫu, trong đó 256 lần phủ đủ `binary_state = 0…255` rồi trở về 0. Bước
quay vòng 255→0 **có** được lấy mẫu (dòng 62). Vậy CC-1 thoả về mặt **phủ trạng thái**;
cái thiếu là **nội dung kiểm** tại mỗi mẫu (chỉ so với mô hình cùng huyết thống).

## 3. Phân loại ca theo tiêu chí kỹ thuật riêng của D05 — **độ dài chuỗi carry**

Đây là tiêu chí phân loại đúng bản chất của đề, vì `d05_core` đếm nhị phân: chi phí thời
gian của một bước phụ thuộc vào **số bit 1 liên tiếp ở đuôi** của `binary_state`.

Với `B → B+1`: nếu `B` có `k` bit 1 liên tiếp ở đuôi thì carry phải lan qua `k+1` tầng, và
bit Gray đổi là **bit thứ `k`**.

| Lớp | `k` (số bit 1 ở đuôi) | Ví dụ `B` | Bit Gray đổi | Số lần xảy ra trong 256 bước | Ý nghĩa kiểm thử |
|---|---:|---|---:|---:|---|
| L0 | 0 | 0, 2, 4, … | bit 0 | **128** | Ca rẻ nhất — carry không lan |
| L1 | 1 | 1, 5, 9, … | bit 1 | **64** | |
| L2 | 2 | 3, 11, 19, … | bit 2 | **32** | |
| L3 | 3 | 7, 23, … | bit 3 | **16** | |
| L4 | 4 | 15, 47, … | bit 4 | **8** | |
| L5 | 5 | 31, 95, … | bit 5 | **4** | |
| L6 | 6 | 63, 191 | bit 6 | **2** | |
| L7 | 7 | **127** | bit 7 | **1** | **Chuỗi carry dài nhất trong vùng không quay vòng** |
| L8 | 8 | **255** | bit 7 | **1** | **Quay vòng** — carry ra khỏi 8 bit, bị cắt |

Tổng: 128+64+32+16+8+4+2+1+1 = **256** ✅

> Hai lớp L7 và L8 mỗi lớp **chỉ xảy ra 1 lần** trong toàn bộ chu kỳ. Đây chính là lý do kỹ
> thuật vì sao Charter mục 10 cảnh báo "chỉ chạy vài bước rồi kết luận": xác suất một chuỗi
> 10 bước ngẫu nhiên chạm được L7 hoặc L8 là rất nhỏ, mà hai lớp đó mới là nơi lỗi nằm.

Đối chiếu với **đường tới hạn thật** (`06_GDSII/sta/timing_report_max.txt`): chuỗi
`_30_(and3) → _37_(and2) → _45_(a21oi) → _46_(and3b) → _63_/D` chính là chuỗi tích luỹ
carry `enable & B[1] & B[0] → & B[3] & B[2] → …`. Vậy lớp L7/L8 vừa là ca **khó nhất về
chức năng**, vừa là ca **kích hoạt đường tới hạn** — một mũi tên trúng hai đích.

## 4. Ca tự xây dựng bổ sung (Charter mục 8 yêu cầu ≥ 2, có ca biên)

| Ca | Kịch bản | Vì sao cần | Trạng thái |
|---|---|---|---|
| **TC-A (ca biên)** | Dừng `enable` **ngay tại** `B = 255`, giữ 3 chu kỳ, rồi bật lại | Tách hai việc bị trộn lẫn: *quay vòng* và *đếm tiếp*. Nếu logic quay vòng bị cài nhầm vào nhánh `enable=0`, chỉ ca này lộ ra | ⬜ chưa có trong TB |
| **TC-B (ca biên)** | Xác nhận `popcount(G(t+1) ^ G(t)) == 1` cho **đủ 256 bước**, dùng chính `popcount8` đang bị bỏ quên | Đưa INV-3 từ mô hình Python vào mô phỏng RTL — đây là yêu cầu trực tiếp của Charter mục 9 | ⬜ chưa có trong TB |
| **TC-C** | Reset giữa chừng: cho `B` chạy tới ≈ 100 rồi hạ `rst_n` 1 chu kỳ | TB hiện chỉ reset ở đầu, khi `B` vốn đã là 0 → **không phân biệt được** "reset về 0" với "chưa bao giờ rời 0". Ca này mới thực sự kiểm reset | ⬜ chưa có trong TB |
| **TC-D** | `enable` đổi mức xen kẽ 1/0/1/0 suốt 20 chu kỳ | Kiểm rằng `enable` là *điều kiện đếm*, không phải *điều kiện xuất*: `gray_out` phải **đứng yên**, không được nhấp nháy | ⬜ chưa có trong TB |

### Bản vá tối thiểu để có TC-B (chưa áp dụng — chờ thầy duyệt)

```verilog
logic [7:0] gray_prev;
always_ff @(posedge clk) gray_prev <= gray_out;

// đặt trong task check(), sau dòng assert hiện có:
if (rst_n && enable)
    assert(popcount8(gray_out ^ gray_prev) == 1)
        else $fatal(1, "INV-3 violated: %02h -> %02h", gray_prev, gray_out);
```

Bản vá này **dùng lại đúng hàm `popcount8` đang có sẵn** ở dòng 22–29, không thêm cell nào
vào thiết kế (chỉ là mã kiểm thử).

## 5. Ca **KHÔNG** áp dụng cho đề này

| Ca thường gặp ở đề khác | Vì sao không áp dụng cho D05 | Bằng chứng |
|---|---|---|
| Tràn số (overflow) có cờ báo | D05 **cố ý** quay vòng, quay vòng là tính năng chứ không phải lỗi; không có cổng cờ nào | `d05_core.sv` chỉ có 1 cổng ra |
| Số âm / bù 2 | Bộ đếm vị trí góc quay là đại lượng **không dấu** | Charter mục 1 |
| Ca glitch của mạch tổ hợp | Đầu ra `gray_out` là tổ hợp nhưng nguồn của nó là FF ổn định cả chu kỳ; glitch chỉ xuất hiện trong ~0,5 ns sau cạnh lên và không được lấy mẫu ở đây | `timing_report_max.txt`: reg→out dài nhất 0,62 ns |
| Nạp giá trị đầu (load/preset) | Không có cổng `load`, không có `data_in` | Bảng cổng trong `interface.md` |
| Đếm lùi | Charter không yêu cầu; RTL chỉ có `+ 8'd1` | `d05_core.sv` dòng 13 |
| Gray rộng hơn 8 bit / Gray cân bằng | Charter mục 3 liệt kê **ngoài phạm vi** | Charter mục 3 |

## 6. Ca phải bổ sung khi chuyển sang gate-level / post-layout

| Ca | Vì sao chỉ xuất hiện ở tầng sau | Cần gì để chạy |
|---|---|---|
| Mô phỏng gate-level trên `netlist.v` với `enable` đổi ngay trước cạnh lên | Mô phỏng RTL là zero-delay, không thấy vi phạm setup. Netlist + `.lib` mới thấy | Icarus + `sky130_fd_sc_hd.v` + netlist |
| Kiểm cell `lpflow_isobufsrc_1` cư xử như AND | Yosys đã chọn **cell cách ly nguồn thấp** làm cổng AND thường (xem `block_diagram.md` §4). Ở RTL không có gì để kiểm | Mô phỏng gate-level |
| Ca X-propagation sau reset | RTL `logic` khởi tạo X; netlist `dfxtp_1` cũng khởi tạo X. Cần chứng minh **một** cạnh `rst_n=0` là đủ xoá hết X ở cả 8 FF | Gate-level sim, `+define+XPROP` |
| Hold ở góc nhanh (ff corner) | `timing_report_min.txt` hiện chỉ có góc `tt`; slack hold nhỏ nhất đo được là **0,47 ns** trên đường `_61_ → _40_ → _61_` | STA đa góc: `ss`, `ff` |
| Kiểm sau CTS: skew giữa 8 FF | Hiện `clock network delay (ideal)` = 0,00 — cây clock **chưa tồn tại** | LibreLane tới bước CTS |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
