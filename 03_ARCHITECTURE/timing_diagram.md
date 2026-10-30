# D05 · Giản đồ thời gian (Timing Diagram)

---

## 1. Điều phải nói trước mọi giản đồ

Waveform dưới đây dựng lại từ **chính `05_VERIFICATION/testbench/d05_core_tb.sv`** và ngữ
nghĩa của `d05_core.sv`, đối chiếu với `simulation.log` (`$finish` tại **2606**).

> ❗ Đây là mô phỏng **hành vi (behavioural, zero-delay)**. Mọi tín hiệu đổi mức **đúng tại**
> cạnh lên clock, độ trễ bằng 0. Giản đồ này **không** minh hoạ được: `clk→Q` ≈ 0,32–0,37 ns,
> độ trễ cổng, glitch, vi phạm setup/hold. Muốn thấy những thứ đó phải mô phỏng
> **gate-level** trên `06_GDSII/synthesis/netlist.v` với `.lib`/SDF — bước này **chưa chạy**.

Quy ước: chu kỳ clock = 10 ns (`always #5 clk = ~clk`), cạnh lên tại t = 5, 15, 25, …
Testbench lấy mẫu tại **cạnh lên + 1 ns** (`@(posedge clk); #1;`).

## 2. Giao dịch điển hình — reset → giữ → đếm → quay vòng

### 2.1 Pha reset và pha giữ (chu kỳ 1–5)

```
 chu kỳ      │   1     │   2     │   3     │   4     │   5     │
 t (ns)      0    5    10   15   20   25   30   35   40   45   50
             ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐
 clk    ─────┘    └────┘    └────┘    └────┘    └────┘    └────
                  ▲         ▲         ▲         ▲         ▲
                  │         │         │         │         │  ← cạnh lên
 rst_n  ─────────────────────────┐
             (=0)                └──────────────────────────── (=1 từ t=16)
                                     ▲
                                     │ rst_n lên 1 SAU cạnh lên thứ 2
 enable ──────────────────────────────────────────────────────── (=0)

 binary_state  ══0══╪════0════╪════0════╪════0════╪════0════╪══
                    ▲         ▲
                    │         └─ cạnh lên thứ 2: rst_n vẫn 0 → nạp 0 (ĐỒNG BỘ)
                    └─ cạnh lên thứ 1: rst_n=0 → nạp 0, xoá X sau bật nguồn

 gray_out      ══00═╪═══00════╪═══00════╪═══00════╪═══00════╪══  (hex)

 check()            ✓#1       ✓#2       ✓#3       ✓#4       ✓#5
                  (dòng 45)          (dòng 48)   (dòng 51)
```

**Đọc gì từ đoạn này:**
- Chu kỳ 1–2: `rst_n = 0`. Reset **đồng bộ** — `binary_state` chỉ về 0 **nhờ có cạnh lên**,
  không phải ngay khi `rst_n` xuống. Nếu bỏ hai chu kỳ này, `binary_state` giữ nguyên `8'hxx`.
- Chu kỳ 3–5: `rst_n = 1`, `enable = 0` → **giữ nguyên**. Ba chu kỳ này kiểm **INV-5**.
- `gray_out` bám theo `binary_state` **trong cùng chu kỳ**, không trễ — vì nó là tổ hợp
  (Moore, xem `fsm.md` §2).

### 2.2 Pha đếm (chu kỳ 6–13)

`enable` lên 1 tại t = 46, tức **trước** cạnh lên của chu kỳ 6.

```
 chu kỳ      │   6     │   7     │   8     │   9     │  10     │  11     │  12     │  13     │
 t (ns)      50   55   60   65   70   75   80   85   90   95  100  105  110  115  120  125
             ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐    ┌────┐
 clk    ─────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └────┘    └───
                  ▲         ▲         ▲         ▲         ▲         ▲         ▲         ▲
 enable ─────┬────────────────────────────────────────────────────────────────────────────── (=1)
             │
 B (dec)     0 ══╪═══1═════╪═══2═════╪═══3═════╪═══4═════╪═══5═════╪═══6═════╪═══7═════╪══8══
 B (bin)  00000000│00000001 │00000010 │00000011 │00000100 │00000101 │00000110 │00000111 │00001000

 gray_out(hex) 00 │   01    │   03    │   02    │   06    │   07    │   05    │   04    │  0C
 gray_out(bin)    │00000001 │00000011 │00000010 │00000110 │00000111 │00000101 │00000100 │00001100
                  └────┬────┴────┬────┴────┬────┴────┬────┴────┬────┴────┬────┴────┬────┘
 bit Gray đổi          0         1         0         2         0         1         0     3
 chuỗi carry           1         2         1         3         1         2         1     4
 (số tầng lan)

 check()          ✓#6       ✓#7       ✓#8       ✓#9      ✓#10      ✓#11      ✓#12     ✓#13
                (dòng 57)  ├──────────── dòng 59: repeat(254) ────────────────────────────▶
```

**Đọc gì từ đoạn này:**
- Hàng "bit Gray đổi" cho thấy **mỗi chu kỳ đúng một bit đổi** — INV-3 hiện ra bằng mắt.
  (Nhắc lại: testbench SystemVerilog **không kiểm** hàng này — xem `corner_cases.md` §1.)
- Hàng "chuỗi carry" chạy theo hình răng cưa 1,2,1,3,1,2,1,4… Chu kỳ 13 (`B: 7→8`) là chu
  kỳ **đắt nhất** trong 8 chu kỳ đầu: carry lan 4 tầng. Đây là loại chu kỳ kích hoạt đường
  tới hạn thật.
- Độ trễ đầu vào → đầu ra: `enable` lên 1 tại chu kỳ 6 thì `gray_out` đổi **tại chính cạnh
  lên của chu kỳ 6** — **1 chu kỳ** theo định nghĩa "mức tại cạnh `t` quyết định trạng thái
  sau cạnh `t`" (xem `functional_spec.md` §7).

### 2.3 Pha quay vòng (chu kỳ 259–261) — ca biên của toàn đề

Đếm tiếp tới `B = 255` ở chu kỳ 260, rồi quay vòng:

```
 chu kỳ         │  259    │  260    │  261    │
                ┌────┐    ┌────┐    ┌────┐
 clk       ─────┘    └────┘    └────┘    └────
                     ▲         ▲         ▲
 enable    ──────────────────────────────────── (=1)

 B (dec)     253 ═══╪══254════╪══255════╪═══0═══   ← QUAY VÒNG
 B (bin)  11111101  │11111110 │11111111 │00000000

 gray_out    83 ════╪═══81════╪═══80════╪═══00═══
 (bin)     10000011 │10000001 │10000000 │00000000
                    └────┬────┴────┬────┴───┬────┘
 bit Gray đổi            1         0        7      ← vẫn ĐÚNG MỘT bit
 chuỗi carry             1         2        9      ← DÀI NHẤT (lớp L8)
                                             ▲
                                             │ carry lan hết 8 bit rồi bị CẮT
                                             │ (không có bit 8 để nhận)

 check()             ✓#259    ✓#260     ✓#261
                                        (dòng 62 — ca quay vòng)
```

**Vì sao đây là ca đắt nhất:** ở bước `255 → 0`, mọi bit của `binary_state` đều đổi (8 bit
nhị phân đổi cùng lúc), nhưng `gray_out` **chỉ đổi bit 7** (`0x80 → 0x00`). Đúng một dòng
này tóm gọn toàn bộ giá trị của mã Gray: 8 dây đổi bên trong, 1 dây đổi ra ngoài.

## 3. Quan hệ giữa waveform và số liệu STA thật

Waveform zero-delay ở trên **giấu** các con số sau. Bảng này nối hai thế giới lại:

| Sự kiện trong waveform | Thời gian thật sau cạnh lên (STA, tt_025C_1v80) | Nguồn |
|---|---:|---|
| `binary_state[2]` xuất hiện tại `Q` | **0,37 ns** | `_59_/Q` trong `timing_report_max.txt` |
| `gray_out[1]` ổn định | **0,48 ns** | đường `_59_ → _49_ → gray_out[1]` |
| `gray_out[2]` ổn định (sâu nhất) | **0,62 ns** | đường `_59_ → _36_ → _51_ → gray_out[2]` |
| `binary_next` cho bit 6 sẵn sàng (nếu `enable` ổn định từ đầu chu kỳ) | **1,60 ns** kể từ mốc `clk`, trong đó 1,00 ns là `input_delay` giả định | đường tới hạn |
| Lề còn lại tới cạnh lên kế (chu kỳ 10 ns) | **8,28 ns** | `slack (MET)` |

### Vùng có thể glitch trên `gray_out`

Vì `gray_out` là **tổ hợp** từ `binary_state`, và 8 FF không đổi mức tuyệt đối cùng lúc
(clk→Q của từng FF khác nhau, cộng skew của cây clock chưa tồn tại), tồn tại một cửa sổ
ngắn sau mỗi cạnh lên nơi `gray_out` có thể hiện giá trị trung gian:

```
 clk    ──┐ ┌──────────────────────────────────────────
          └─┘
          │◀── 0,37 ──▶│
          │  Q của FF   │
          │            │◀─ 0,25 ─▶│
          │            │ cây XOR  │
          │◀════ vùng CÓ THỂ GLITCH: ~0 → 0,62 ns ════▶│
          │                                            │◀══ 9,38 ns ỔN ĐỊNH ══▶│
```

| Câu hỏi | Trả lời |
|---|---|
| Glitch này có làm hỏng chức năng không? | **Không**, với bên nhận đồng bộ: mẫu được lấy ở cạnh lên kế, cách đó 9,38 ns |
| Có nguy hiểm khi nào? | Khi bên nhận ở **miền clock khác** lấy mẫu trúng cửa sổ 0,62 ns này. Xác suất ≈ 0,62/10 ≈ **6 %** mỗi chu kỳ nếu hai clock không liên quan |
| Cách khử triệt để | Thanh ghi hoá `gray_out` (+8 FF) — nhưng vi phạm Charter mục 10 ("8 ô nhớ") |
| Vì sao chấp nhận được | Mã Gray bảo đảm hậu quả xấu nhất của một mẫu sai là **lệch một nấc**; đó chính là lý do tồn tại của đề này |

## 4. Bảng tổng kết các mốc chu kỳ trong lần chạy thật

| Chu kỳ | Sự kiện | Dòng testbench | `B` | `gray_out` |
|---:|---|---|---:|---|
| 1–2 | Reset tích cực | 45 | 0 | `0x00` |
| 3 | `rst_n` nhả, `enable` vẫn 0 | 48 | 0 | `0x00` |
| 4–5 | Kiểm giữ (INV-5) | 51 | 0 | `0x00` |
| 6 | Bước đếm đầu tiên | 57 | 1 | `0x01` |
| 7–260 | 254 bước liên tiếp | 59 | 2…255 | `0x03`…`0x80` |
| 261 | **Quay vòng** | 62 | 0 | `0x00` |
| — | `$display` + `$finish` tại **2606** | 65–66 | — | — |

Tổng 261 cạnh lên × 10 ns = 2610 ns; `$finish` ghi nhận tại 2606 ns (cạnh lên thứ 261 tại
t = 2605, cộng `#1` của `check()` là 2606). **Số liệu log khớp với giản đồ.**

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
