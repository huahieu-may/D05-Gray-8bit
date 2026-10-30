# D05 — Bộ đếm Gray 8-bit · Ghi chú thực hiện

## 1. Bài toán này thực chất là gì

Nhìn qua tên đề, D05 trông như một bài tập mã hoá: "đếm rồi đổi sang mã Gray". Nhưng bối
cảnh Charter mục 1 mới chỉ ra bản chất: *bộ mã hoá góc quay tuyệt đối*. Đĩa mã hoá gắn trên
trục quay, cảm biến đọc vị trí, và giá trị vị trí phải đi từ miền clock của cảm biến sang
miền clock của bo điều khiển.

Vấn đề thật không nằm ở phép đếm. Phép đếm 8-bit là bài tập tuần đầu. Vấn đề nằm ở chỗ:
**khi N dây tín hiệu đi qua ranh giới hai miền xung nhịp, chúng không thể đổi mức đồng thời
tuyệt đối.** Mỗi dây có độ trễ riêng, bên nhận lấy mẫu tại một thời điểm do clock của nó
quyết định. Nếu truyền nhị phân, bước `127 → 128` làm 8 dây đổi cùng lúc, và bên nhận có
thể bắt trúng một tổ hợp trung gian bất kỳ trong 256 khả năng — kể cả `255`. Sai số không
bị chặn.

Mã Gray biến bài toán "không chặn được sai số" thành "sai số ≤ 1 nấc": mỗi bước chỉ **một**
dây đổi, nên mẫu xấu nhất là giá trị cũ hoặc giá trị mới, không có gì ở giữa. Đó là toàn bộ
lý do tồn tại của D05, và là lý do Charter mục 9 bắt kiểm tính chất đó **bằng mô phỏng đủ
256 bước** chứ không cho lập luận suông.

## 2. Bản chất kỹ thuật — cơ chế hoạt động

Có ba cơ chế chồng lên nhau, và phải tách bạch mới hiểu đúng đề.

**Cơ chế 1 — vì sao `b ^ (b >> 1)` cho ra mã đổi một bit.** Xét `b → b+1`. Gọi `k` là số
bit `1` liên tiếp ở đuôi của `b`. Phép `+1` lật `k` bit đuôi từ `1` về `0` và lật bit thứ
`k` từ `0` lên `1`. Bây giờ áp công thức `g[i] = b[i+1] ^ b[i]`: mọi cặp `(b[i+1], b[i])`
nằm hoàn toàn trong vùng đuôi vừa lật đều lật **cả hai** bit, nên XOR không đổi. Cặp nằm
hoàn toàn ngoài vùng lật cũng không đổi. **Chỉ đúng một cặp** — cặp bắc qua biên, tức
`(b[k+1], b[k])` — có đúng một vế đổi. Vậy đúng một bit Gray đổi, và nó là bit thứ `k`. Đây
là chứng minh, không phải quan sát thực nghiệm; mô phỏng 256 bước là để xác nhận rằng RTL
hiện thực đúng cái chứng minh này.

**Cơ chế 2 — vòng kín và nhánh cụt.** Đây là chỗ quyết định tốc độ. `binary_state` quay về
incrementer (**vòng kín**), còn cây XOR chỉ đi ra cổng (**nhánh cụt**). Độ trễ một chu kỳ
là **max** của hai nhánh, không phải **tổng**. Nếu thiết kế ngược lại — lưu thẳng Gray như
`d05_direct_gray.sv` — thì phép giải mã Gray (một chuỗi XOR nối tiếp 7 tầng) rơi **vào
trong** vòng kín và cộng thẳng vào đường tới hạn. Cùng 8 flip-flop, cùng chức năng, nhưng
vị trí của phép biến đổi so với vòng hồi tiếp quyết định tất cả.

**Cơ chế 3 — phép `+1` không phải phép `a+b`.** Carry ra khỏi tầng `i` của `+1` là
`enable & b[0] & b[1] & … & b[i]`, một tích AND thuần. Tích AND **kết hợp được**, nên công
cụ dựng cây thay vì chuỗi: `(b1&b0)` → `& (b3&b2)` → `& (b5&b4)`. Đo được **4 mức** cho 8
bit, không phải 8. Bộ cộng ripple của đề A01 không có đặc quyền này vì carry của nó là
`a&b | (a^b)&cin`, phụ thuộc theo thứ tự. **Đây là điểm phân biệt A01 với D05** mà sinh
viên hay nhầm: cùng gọi là "chuỗi carry" nhưng một cái `O(N)`, một cái `O(log N)`.

## 3. Đọc mã nguồn: RTL làm gì, từng dòng quan trọng

```verilog
always_comb begin                       // d05_core.sv, dòng 10–14
    binary_next = binary_state;
    if (enable)
        binary_next = binary_state + 8'd1;
end
```

Viết theo kiểu "gán mặc định rồi ghi đè". Nhờ có dòng gán mặc định, `binary_next` được gán
trên **mọi nhánh** → không sinh latch. Đây là mẫu viết đúng mà sinh viên nên bắt chước.

```verilog
always_ff @(posedge clk) begin          // dòng 16–21
    if (!rst_n)  binary_state <= 8'h00;
    else         binary_state <= binary_next;
end
```

`rst_n` **không** nằm trong danh sách nhạy → reset **đồng bộ**. Hệ quả kiểm chứng được
trong netlist: không có cell `dfrtp_1` nào; thay vào đó `rst_n` bị AND vào đường `D`, ví dụ
`and2_0 _27_ (.A(rst_n), .B(_08_), .X(_00_))`. Muốn reset bất đồng bộ phải viết
`always_ff @(posedge clk or negedge rst_n)` — khác một dòng, khác hẳn phần cứng.

```verilog
always_comb begin                       // dòng 23–25
    gray_out = binary_state ^ (binary_state >> 1);
end
```

Một dòng, 7 phép XOR, độ sâu 1. Vì biểu thức **chỉ đọc `binary_state`**, đây là máy Moore —
`gray_out` không phụ thuộc `enable`, nên không nhấp nháy theo đầu vào. Với một khối gửi tín
hiệu qua ranh giới clock, tính chất Moore không phải chi tiết trang trí mà là điều kiện cần.

## 4. Vì sao chọn kiến trúc này

Tên đề không chỉ định kiến trúc, nên cả hai cách đều hợp lệ về hình thức. Lựa chọn dựa trên
ba căn cứ đo được:

1. **Vị trí của phép biến đổi.** Kiến trúc A đặt phép mã hoá ngoài vòng hồi tiếp; kiến trúc
   B đặt phép giải mã bên trong. A thắng về đường tới hạn (§2, cơ chế 2).
2. **Charter mục 4 đòi xuất cả hai dạng.** Ánh xạ chân yêu cầu `uo_out` = Gray **và**
   `uio_out` = nhị phân tương đương. Với A, giá trị nhị phân đã có sẵn trong thanh ghi —
   xuất ra tốn **0 cell**. Với B, muốn có nhị phân phải trả tiền cho cả bộ giải mã.
3. **Ràng buộc 8 ô nhớ.** Cả A và B đều 8 FF, nên tiêu chí này không phân định — và đó
   chính là lý do phải dùng hai căn cứ trên.

## 5. Cách thực hiện — lộ trình 8 bước từ đặc tả tới GDSII

| # | Bước | Trạng thái | Bằng chứng |
|---|---|:-:|---|
| 1 | Chốt đặc tả và invariant từ Charter mục 1/4/8/9 | ✅ | `02_SPECIFICATION/functional_spec.md` |
| 2 | Viết mô hình chuẩn Python kiểm **tính chất**, không kiểm mạch | ✅ | `python_reference_run.log` — PASS |
| 3 | Viết RTL tối giản, tách 3 khối: incrementer / thanh ghi / mã hoá | ✅ | `d05_core.sv` |
| 4 | Mô phỏng RTL với testbench tự kiểm, đủ 256 bước | ✅ | `simulation.log` — PASS, `$finish` tại 2606 |
| 5 | Tổng hợp Yosys 0.33 + `sky130_fd_sc_hd`, đọc lại số cell/FF | ✅ | 40 cell · 8 FF · 369,104 µm² |
| 6 | STA với SDC có clock thật, đọc đường tới hạn | ✅ | slack 8,28 ns · WNS 0,00 |
| 7 | Ước lượng công suất, phân tách tuần tự / tổ hợp | ✅ | 3,62e-05 W · 94,6 % / 5,4 % |
| 8 | Physical design (floorplan → GDS) bằng LibreLane + sky130A | ⬜ | cần PDK; `scripts/04_run_librelane.sh` |

## 6. Số liệu thật đã đo được và cách đọc chúng

| Chỉ số | Giá trị | **Chứng minh** điều gì | **Không chứng minh** điều gì |
|---|---:|---|---|
| 40 cell | 40 | Thiết kế nhỏ hơn 4× ước lượng Charter (170–240) | Không nói gì về tốc độ |
| 8 FF | 8 | **Thoả** "dấu hiệu làm đúng" Charter mục 10 | Không chứng minh mã Gray đúng |
| 369,104 µm² | | Diện tích logic sau tổng hợp | **Không** phải diện tích die — chưa có floorplan |
| slack 8,28 ns | | Với giả định chu kỳ 10 ns, `input_delay` 1 ns, clock lý tưởng, netlist đáp ứng setup | **Không** cho phép nói "chạy được ở 100 MHz". Chưa có RC dây, chưa có CTS, một góc PVT duy nhất |
| arrival 1,60 ns | | Trong đó **1,00 ns là giả định `set_input_delay`**, chỉ 0,60 ns là logic thật | Không phải độ trễ nội tại của khối |
| WNS/TNS 0,00 | | Không đường nào âm slack | Chỉ ở góc `tt_025C_1v80` |
| 3,62e-05 W | | Ước lượng sau tổng hợp | **Không** phải công suất chip thật — chưa có clock tree, chưa có IO |
| 94,6 % tuần tự | | 8 FF ăn gần hết công suất; 1 FF ≈ 70 cell tổ hợp | Không bao gồm công suất cây clock (hàng `Clock` = 0,0 % vì cây chưa tồn tại) |
| Mô phỏng PASS | | RTL khớp `d05_reference.sv` ở 261 điểm lấy mẫu | **Không** chứng minh INV-3 — xem §9 |

## 7. Trả lời các câu hỏi kỹ thuật của Charter (mục 2)

**Câu 1 — Bằng chứng nào chứng minh mỗi bước chỉ đổi đúng một bit: chạy đủ 256 bước hay
lập luận?** Cần **cả hai, và chúng chứng minh hai thứ khác nhau**. Lập luận toán học (§2,
cơ chế 1) chứng minh *công thức* Gray có tính chất đó — đúng cho mọi `N`, không cần chạy gì.
Mô phỏng 256 bước chứng minh *RTL này* hiện thực đúng công thức đó — đây là kiểm chứng
hiện thực, không phải kiểm chứng toán học. Hiện trạng hồ sơ: lập luận có; kiểm 256 bước
**có trong `reference_model.py`** (dòng 33–37) nhưng **chưa có trong mô phỏng RTL**, vì
`popcount8` được khai báo mà không được gọi. Đây là điểm cần sửa.

**Câu 2 — Giữ nhị phân rồi chuyển, hay giữ luôn Gray, khác nhau bao nhiêu cell?** Kiến trúc
A đo được **40 cell / 8 FF / 369,104 µm²**. Kiến trúc B (`d05_direct_gray.sv`) **chưa được
tổng hợp** → ⬜ chưa có số. Chỉ được phát biểu định tính: B có cùng 8 FF nhưng thêm một bộ
giải mã Gray nối tiếp 7 tầng nằm **trong vòng hồi tiếp**, nên nhiều cell hơn và chậm hơn.
Muốn có số: chạy lại Yosys với `-top d05_direct_gray`. Chi tiết ở `tradeoff.md` §4.

**Câu 3 — Vì sao mã Gray quan trọng khi qua hai miền xung nhịp (liên hệ J01)?** Vì nó chặn
**biên độ** sai số, chứ không chặn xác suất sai. Bên nhận vẫn **bắt buộc** phải có bộ đồng
bộ 2 tầng FF (việc của đề J01) để xử lý metastability. Hai cơ chế giải quyết hai vấn đề
khác nhau: đồng bộ 2 tầng lo *tín hiệu không ổn định*; mã Gray lo *nhiều dây đổi không cùng
lúc*. Bỏ cái nào cũng hỏng.

## 8. Trả lời câu phân tích riêng (Charter mục 9)

Charter mục 9 buộc **kiểm chứng tính chất "mỗi bước chỉ đổi một bit" bằng mô phỏng cho đủ
256 bước**. Trả lời trung thực bằng số liệu:

- **Đã có:** `reference_model.py` chạy PASS, log ghi rõ *"All 256 Gray states are unique"*
  và *"All 256 cyclic adjacent transitions have Hamming distance 1"*. Đoạn mã tương ứng là
  dòng 30–37, có kiểm cả bước quay vòng `255 → 0` (`hamming(sequence[255], sequence[0]) == 1`).
- **Đã có:** mô phỏng RTL phủ đủ 256 trạng thái — đếm được **261 lần `check()`**, trong đó
  256 lần phủ `binary_state = 0…255` rồi trở về 0 (`$finish` tại 2606 ns = 261 cạnh lên × 10 ns
  + 1 ns, khớp log).
- **CHƯA có:** mô phỏng RTL **không** kiểm Hamming distance. Nó chỉ so `gray_out === gray_ref`
  với một mô hình chuẩn **cùng thuật toán**. Nếu công thức Gray sai giống nhau ở cả hai file,
  testbench vẫn PASS.

**Kết luận phải ghi vào báo cáo:** tính chất Gray đã được chứng minh trên **mô hình Python**
với đủ 256 bước, **chưa** được chứng minh trên **RTL**. Bản vá tối thiểu (4 dòng, dùng lại
`popcount8` có sẵn) nằm ở `corner_cases.md` §4 — **chưa áp dụng**, chờ duyệt.

**Vì sao tính chất này quan trọng:** ở ranh giới hai miền clock, xác suất lấy mẫu trúng lúc
tín hiệu đang đổi không thể đưa về 0. Cái có thể làm được là chặn **hậu quả**. Với nhị phân,
hậu quả xấu nhất là đọc ra một trong 256 giá trị bất kỳ; với Gray, hậu quả xấu nhất là lệch
**một nấc** — vẫn dùng được cho vòng điều khiển vị trí.

## 9. Những chỗ sinh viên hay sai và cách phát hiện

| Sai lầm | Hậu quả | Phát hiện bằng bằng chứng nào |
|---|---|---|
| Chỉ chạy 10–20 bước rồi kết luận | Bỏ lọt lỗi quay vòng và lớp carry dài. Lớp `k=7` và `k=8` **mỗi lớp chỉ xảy ra 1 lần** trong 256 bước | Đếm số lần `check()` trong log; `$finish` phải ở **2606 ns**, không phải vài trăm ns |
| Coi PASS của testbench là đã chứng minh mã Gray đúng | Lỗi đồng pha: `d05_reference.sv` và `d05_core.sv` cùng thuật toán | Mở hai file, so dòng 9–17 với dòng 10–24. Giống nhau về cấu trúc → không độc lập |
| Tưởng `popcount8` đang được dùng | Tưởng INV-3 đã kiểm trên RTL | `grep popcount8 d05_core_tb.sv` → chỉ ra **1 chỗ định nghĩa, 0 chỗ gọi** |
| Tưởng reset là bất đồng bộ | Bỏ cạnh clock trong lúc `rst_n=0` → trạng thái giữ nguyên `8'hxx` | Netlist không có cell `dfrtp_*`; `rst_n` xuất hiện làm đầu vào của `and2_0 _27_` |
| Đi tìm `binary_state[7]` trong netlist | Tưởng tool làm mất một bit | Netlist chỉ khai báo `binary_state[0..6]`; FF `_64_` xuất thẳng `gray_out[7]` vì `g[7] = b[7]` |
| Nói "khối chạy được ở 100 MHz" vì slack dương | Phát biểu vượt mức | `timing.md` §3: clock lý tưởng, chưa RC, một góc PVT, chưa CTS |
| Nhầm chuỗi carry `+1` với ripple-carry của A01 | Ước sai độ sâu (8 thay vì 4) | STA đếm được **4 cell** trên đường tới hạn, không phải 8 |
| Coi `d05_direct_gray.sv` là một phần thiết kế | Lẫn lộn số liệu | Không module nào instantiate nó; `synth_stat.txt` chỉ có `=== d05_core ===` |
| Cho rằng Charter mục 4 đã thoả | Bỏ sót cổng nhị phân bắt buộc | Danh sách cổng trong RTL chỉ có 4 tín hiệu; xem cảnh báo C4-3 |

## 10. Câu hỏi mentor nên đặt khi bảo vệ

| # | Câu hỏi | Đáp án mong đợi |
|---|---|---|
| 1 | Chỉ ra dòng RTL quyết định reset đồng bộ hay bất đồng bộ, và chỉ bằng chứng trong netlist | Dòng 16 `always_ff @(posedge clk)` — không có `negedge rst_n`. Netlist: không cell `dfrtp_*`, `rst_n` AND vào `D` (`_27_`, `_46_`…) |
| 2 | Vì sao đường tới hạn xuất phát từ `enable` chứ không từ một flip-flop? | Vì SDC đặt `set_input_delay 1.0`, `enable` xuất phát tại 1,00 ns còn FF xuất phát tại ≈0,35 ns. Là hệ quả của **giả định phân tích**, không phải của thiết kế |
| 3 | Độ sâu chuỗi carry là bao nhiêu và vì sao không phải 8? | 4 cell. Vì carry của `+1` là tích AND thuần, kết hợp được → cây thay vì chuỗi |
| 4 | Đầu ra là Mealy hay Moore, bằng chứng ở tầng nào? | Moore. RTL dòng 23–25 chỉ đọc `binary_state`; netlist: không cell lái `gray_out[*]` nào có `enable` ở đầu vào |
| 5 | Testbench đã kiểm "mỗi bước đổi 1 bit" chưa? | **Chưa.** `popcount8` khai báo ở dòng 22–29 nhưng không được gọi. Tính chất chỉ được kiểm ở `reference_model.py` |
| 6 | 94,6 % công suất nằm ở nhóm tuần tự nghĩa là gì với quyết định thiết kế? | 1 FF ≈ 70 cell tổ hợp về công suất → thêm logic rẻ, thêm FF đắt → ràng buộc "8 ô nhớ" là đúng chỗ |
| 7 | Vì sao `binary_state[7]` không có trong netlist? | Vì `gray_out[7] == binary_state[7]` theo định nghĩa; Yosys gộp hai dây làm một, FF `_64_` xuất thẳng ra cổng |
| 8 | Cell `lpflow_isobufsrc_1` ở đây làm nhiệm vụ gì? | Làm cổng AND (`X = A & ~SLEEP`). abc chọn theo hàm logic và chi phí, không theo tên cell. Nếu LibreLane cấm nhóm `lpflow_*` thì số cell sẽ đổi |
| 9 | Mã Gray có thay thế được bộ đồng bộ 2 tầng không? | **Không.** Gray chặn biên độ sai số; đồng bộ 2 tầng xử lý metastability. Hai vấn đề khác nhau |
| 10 | Charter mục 4 đã thoả chưa? | **Chưa** — thiếu cổng xuất giá trị nhị phân tương đương và thiếu vỏ Tiny Tapeout. Bản vá: thêm `output [7:0] binary_out`, tốn 0 cell |

## 11. Giới hạn: đã chứng minh được gì, chưa chứng minh được gì

**Đã chứng minh, có bằng chứng lưu trong hồ sơ:**
mô hình Python kiểm tính chất Gray cho đủ 256 bước (PASS); RTL mô phỏng khớp mô hình chuẩn
tại 261 điểm lấy mẫu, phủ đủ 256 trạng thái kể cả bước quay vòng (PASS); RTL tổng hợp được
ra 40 standard cell sky130 với đúng **8** flip-flop, thoả ràng buộc Charter mục 10; STA sau
tổng hợp không có đường nào âm slack ở góc `tt_025C_1v80` với chu kỳ giả định 10 ns; đường
tới hạn nằm trong incrementer, không nằm ở cây XOR Gray.

**Chưa chứng minh được:**
(1) tính chất "mỗi bước đổi một bit" **trên RTL** — chỉ có trên mô hình Python;
(2) giá trị nhị phân tương đương **không quan sát được từ cổng ra** → ca kiểm thử tương ứng
của Charter mục 8 chưa thực hiện được qua giao diện;
(3) hành vi ở mức gate-level — chưa mô phỏng netlist;
(4) mọi kết quả vật lý: floorplan, placement, CTS, routing, DRC, LVS, GDS đều **chưa chạy**,
nên không có diện tích die thật, không có skew thật, không có tần số tối đa thật;
(5) các góc PVT khác `tt` (`ss`, `ff`) — chưa chạy, nên chưa biết lề hold ở góc nhanh;
(6) kiến trúc thay thế B chưa có số liệu để so sánh định lượng.

**Phát biểu không được dùng:** "đã sign-off", "đã tape-out", "chạy được ở 100 MHz", "diện
tích chip là 369 µm²". Câu đúng: *"sau tổng hợp logic, với các giả định đã nêu ở
`02_SPECIFICATION/timing.md` §3, thiết kế đáp ứng setup với slack 8,28 ns."*

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
