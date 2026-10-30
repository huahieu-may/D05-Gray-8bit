# D05 · Đánh đổi kiến trúc (Trade-off Analysis)

---

## 1. Câu hỏi trung tâm

> **Charter mục 2, câu 2:** *"Giữ thanh ghi ở dạng nhị phân rồi chuyển sang Gray, hay giữ
> luôn dạng Gray — hai cách khác nhau bao nhiêu cell?"*

Hồ sơ có sẵn **cả hai** bản RTL, nên câu này trả lời được bằng cấu trúc; nhưng **chỉ một
bản được tổng hợp**, nên phần con số phải trung thực về chỗ nào có và chỗ nào chưa.

## 2. Số liệu thật của kiến trúc đã chọn

Kiến trúc A = "đếm nhị phân rồi mã hoá Gray" (`d05_core.sv`), Yosys 0.33 + `sky130_fd_sc_hd`,
góc `tt_025C_1v80`:

| Chỉ số | Giá trị đo được | Nguồn |
|---|---:|---|
| Tổng số cell | **40** | `synth_stat.txt` |
| Flip-flop | **8** | `synth_stat.txt` |
| Diện tích | **369,104 µm²** | `synth_stat.txt` |
| Độ sâu đường tới hạn | **4 cell logic** | `timing_report_max.txt` |
| Data arrival / Slack | **1,60 ns / 8,28 ns** | `timing_report_max.txt` |
| WNS / TNS | **0,00 / 0,00** | `wns.txt`, `tns.txt` |
| Công suất tổng | **3,62e-05 W** | `power_report.txt` |
| Tỉ lệ tuần tự / tổ hợp | **94,6 % / 5,4 %** | `power_report.txt` |
| Ước lượng Charter | ~170–240 cell · 1×1 tile | Charter metadata |

Kết quả thật (**40 cell**) **nhỏ hơn 4 lần** ước lượng Charter. Lý do hợp lý: abc đã gộp
logic vào cell phức hợp (`a21oi`, `o21ai`, `and3b`, `nand4`, `mux2i`) thay vì dùng cổng cơ
bản rời, và phép `+1` rẻ hơn phép `a+b` nhiều.

## 3. Con số quan trọng nhất của cả tài liệu: **1 flip-flop ≈ 70 cell tổ hợp về công suất**

Từ `power_report.txt`:

| Nhóm | Tổng công suất | Số cell | Công suất trung bình mỗi cell |
|---|---:|---:|---:|
| Sequential (8 × `dfxtp_1`) | 3,43e-05 W | 8 | **≈ 4,29e-06 W** |
| Combinational (32 cell còn lại) | 1,96e-06 W | 32 | **≈ 6,1e-08 W** |
| | | **Tỉ lệ** | **≈ 70 ×** |

Đây là số liệu đo được, không phải quy tắc chung của ngành. Nhưng với D05 nó dẫn thẳng tới
kết luận thiết kế:

> **Trong đề này, thêm logic tổ hợp gần như miễn phí; thêm flip-flop thì đắt.**
> Vì vậy Charter mục 10 chốt "8 ô nhớ" là một ràng buộc **đúng chỗ**, không phải hình thức.

## 4. So bốn kiến trúc bộ đếm Gray 8-bit

| # | Kiến trúc | Ô nhớ | Đường tới hạn (reg→reg) | Độ phức tạp | Khi nào nên dùng |
|---|---|---:|---|---|---|
| **A** | **Đếm nhị phân → XOR mã hoá** (đang dùng) | **8** | chuỗi carry `+1` = cây AND **4 mức** (đo được) | Rất thấp — 12 dòng RTL | Mặc định. Khi cần **cả hai** dạng nhị phân và Gray |
| B | Lưu thẳng Gray: giải mã → `+1` → mã hoá lại (`d05_direct_gray.sv`) | 8 | **giải mã Gray là chuỗi nối tiếp 7 mức XOR** + chuỗi carry + mã hoá 1 mức → dài hơn A đáng kể | Thấp | Khi tuyệt đối không được lộ giá trị nhị phân ra ngoài |
| C | Bộ đếm Gray dùng T-flip-flop + cây parity | 8 | cây parity `log₂8 = 3` mức + logic chọn bit | **Cao** — dễ sai ở bit cuối và ở bước quay vòng | Khi cần tối ưu công suất chuyển mạch tối đa |
| D | A + thanh ghi hoá đầu ra (+8 FF) | **16** | như A, nhưng reg→out chỉ còn `clk→Q` | Thấp | Khi `gray_out` đi qua ranh giới clock và **không được glitch** |

### 4.1 Vì sao B chậm hơn A — lập luận từ chính mã nguồn

```verilog
// d05_direct_gray.sv, dòng 17–19
binary_value[7] = gray_out[7];
for (i = 6; i >= 0; i = i - 1)
    binary_value[i] = binary_value[i+1] ^ gray_out[i];   // ← PHỤ THUỘC NỐI TIẾP
```

`binary_value[i]` cần `binary_value[i+1]` **đã ổn định**. Đó là một chuỗi XOR nối tiếp
**7 tầng**, chạy từ bit 7 xuống bit 0. Sau đó mới tới chuỗi carry của `+1`, rồi mới tới
1 tầng mã hoá lại. Tức là đường reg→reg của B ≈ **7 (giải mã) + chuỗi carry + 1 (mã hoá)**,
trong khi A chỉ có **chuỗi carry**.

Nói cách khác: **A đã trả phí mã hoá ở nhánh cụt (ngoài vòng hồi tiếp), B trả phí ở trong
vòng hồi tiếp.** Đây mới là điểm phân biệt thật, không phải số cell.

> Lưu ý: cây XOR tiền tố (Kogge–Stone) có thể rút giải mã Gray xuống `log₂8 = 3` mức. Bản
> `d05_direct_gray.sv` **không** dùng cách đó — nó viết vòng lặp nối tiếp. Yosys/abc **có
> thể** tự làm phẳng một phần, nhưng ta chưa có bằng chứng vì chưa tổng hợp module này.

### 4.2 Trả lời câu Charter mục 2, câu 2 — trung thực về chỗ chưa có số

| Hạng mục | Kiến trúc A | Kiến trúc B |
|---|---:|---|
| Số cell **đo được** | **40** | ⬜ **chưa chạy** |
| Flip-flop | **8** | 8 (suy từ RTL: chỉ có `gray_out` là `always_ff`) |
| Diện tích | **369,104 µm²** | ⬜ chưa chạy |
| Slack | **8,28 ns** | ⬜ chưa chạy |

**Cần gì để có số cho B:** chạy `yosys` với `-top d05_direct_gray` trên
`04_IMPLEMENTATION/rtl/d05_direct_gray.sv`, script mẫu đã có sẵn tại
`04_IMPLEMENTATION/scripts/02_run_synth.sh` (chỉ cần đổi biến top). **Không được suy đoán
con số.** Dự đoán *định tính* duy nhất được phép phát biểu: B có cùng 8 FF nhưng **nhiều
cell tổ hợp hơn và đường tới hạn dài hơn**, vì nó làm thêm một phép giải mã mà A không cần.

**Ghi chú cản trở:** Icarus Verilog đã từ chối phân tích đầy đủ module B —
`iverilog_compile.log` ghi:

```
d05_direct_gray.sv:16: sorry: constant selects in always_* processes are not currently
supported (all bits will be included).
```

Đây là **giới hạn công cụ**, không phải lỗi thiết kế: Icarus không hỗ trợ chỉ số hằng trong
`always_*` nên mở rộng toàn bộ độ nhạy. Vì B không phải top và không được instantiate,
cảnh báo này **không ảnh hưởng** kết quả PASS của mô phỏng. Yosys không có giới hạn đó,
nên vẫn tổng hợp được B nếu muốn.

## 5. Đánh đổi thứ hai: có nên thanh ghi hoá `gray_out` không? (kiến trúc D)

| Tiêu chí | A (hiện tại) | D (A + 8 FF ra) |
|---|---|---|
| Ô nhớ | 8 | **16** — vi phạm Charter mục 10 |
| Công suất ước tính | 3,62e-05 W đo được | tăng ≈ 8 × 4,29e-06 ≈ **+3,4e-05 W**, tức **gần gấp đôi** |
| Cửa sổ glitch trên `gray_out` | **0,62 ns** mỗi chu kỳ | ≈ 0 (chỉ còn chuyển mạch sạch của FF) |
| Độ trễ từ trạng thái tới cổng ra | 0 chu kỳ | **1 chu kỳ** |
| Diện tích | 369,104 µm² | tăng đáng kể (8 `dfxtp_1` là cell lớn nhất trong thiết kế) |

Phép tính "gần gấp đôi công suất" ở trên dùng **đơn giá đo được** ở §3 nhân với 8 FF —
đây là **ngoại suy có cơ sở**, không phải số đo. Nếu cần con số chắc chắn, phải sửa RTL,
tổng hợp lại và đọc `power_report.txt` mới.

Kết luận: **D không được phép trong đề này** (Charter mục 10 chốt 8 ô nhớ), và đó là quyết
định hợp lý — vì mã Gray đã làm cho glitch trở nên chịu đựng được.

## 6. Ràng buộc phạm vi — những kiến trúc chỉ được so trên giấy

| Kiến trúc | Charter mục 3 xếp loại | Được làm gì |
|---|---|---|
| Gray rộng hơn 8 bit | **Ngoài phạm vi** | Chỉ thảo luận. Ghi chú đúng: chi phí mã hoá là `N-1` cổng XOR, tăng **tuyến tính**; đường tới hạn của incrementer tăng theo `log N` |
| Gray cân bằng (balanced Gray code) | **Ngoài phạm vi** | Chỉ thảo luận. Nó cân bằng tần suất chuyển mạch giữa các bit — với D05, bit 0 đổi 128 lần/chu kỳ còn bit 7 chỉ đổi 2 lần (xem `corner_cases.md` §3) |
| Giải mã tuyệt đối nhiều vòng | **Ngoài phạm vi** | Chỉ thảo luận |
| Tự tối ưu netlist bằng tay | **Ngoài phạm vi** (áp dụng cho mọi đề) | Không được sửa `netlist.v` |
| Physical design, sign-off, tape-out | **Ngoài phạm vi** | Không được phát biểu "đã sign-off" |

## 7. Những đánh đổi **KHÔNG được phép** trong đề này

| Đánh đổi | Vì sao cấm | Điều khoản |
|---|---|---|
| Thêm flip-flop để làm sạch đầu ra | Vi phạm "dấu hiệu làm đúng: 8 ô nhớ" | Charter mục 10 |
| Đổi sang bộ đếm nhị phân thuần, bỏ mã hoá Gray | Phá huỷ INV-3 — lý do tồn tại của đề | Charter mục 1, 9 |
| Rút ngắn mô phỏng xuống vài chục bước cho nhanh | Bỏ mất lớp L7/L8 (mỗi lớp chỉ xảy ra 1 lần trong 256 bước) | Charter mục 8, 10 |
| Sửa `netlist.v` bằng tay để giảm cell | Tự tối ưu netlist nằm ngoài phạm vi | Charter mục 3 |
| Thay `d05_direct_gray` làm top để "đúng tên đề hơn" | Tên đề không chỉ định kiến trúc; đổi top làm vô hiệu toàn bộ số liệu đã chạy | Charter mục 3 + tính nhất quán hồ sơ |
| Bỏ cảnh báo C4-3 (thiếu cổng nhị phân) và coi như đã thoả | Charter mục 4 đòi `uio_out[7:0]` = nhị phân tương đương | Charter mục 4 |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
