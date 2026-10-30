# D05 · Sơ đồ hệ thống (System Diagram)

---

## 1. Bối cảnh ứng dụng — bộ mã hoá góc quay tuyệt đối

Charter mục 1: *"Khối đếm vị trí trong bộ mã hoá góc quay tuyệt đối: mã Gray để đọc sai một
bit cũng chỉ lệch một nấc."*

```
   TRỤC QUAY                    MIỀN CLOCK A (nhanh, trên trục)         MIỀN CLOCK B (chậm, bo mạch điều khiển)
   ─────────                    ═══════════════════════════════        ══════════════════════════════════════
                               ┌──────────────────────────────┐       ┌──────────────────────────────────────┐
   ┌─────────┐   xung          │                              │       │                                      │
   │ Cảm biến│   vị trí        │   ┌──────────────────────┐   │       │  ┌────────────┐    ┌──────────────┐  │
   │ Hall /  ├──────enable────▶│   │  ►► D05 ◄◄           │   │ gray  │  │ 2 tầng FF  │    │ Giải mã Gray │  │
   │ quang   │                 │   │  Bộ đếm Gray 8-bit   ├───┼──8────┼─▶│ đồng bộ hoá├───▶│  → nhị phân  ├──┐
   └─────────┘                 │   │  (khối của đề này)   │   │       │  │ (đề J01)   │    │  (cây XOR)   │  │
                               │   └──────────┬───────────┘   │       │  └────────────┘    └──────────────┘  │
   ┌─────────┐                 │              │ binary_state  │       │                                      │  │
   │ Dao động├──────clk───────▶│              │ (NỘI BỘ,      │       │   ┌───────────────────────────────┐  │  │
   │ thạch anh│                 │              │  chưa xuất ra)│       │   │ Bộ điều khiển động cơ / hiển │◀─┘  │
   └─────────┘                 │              ▼               │       │   │ thị góc tuyệt đối             │     │
                               │        (cây XOR 7 cổng)      │       │   └───────────────────────────────┘     │
   ┌─────────┐                 │                              │       │                                         │
   │ Nguồn / ├──────rst_n─────▶│                              │       └─────────────────────────────────────────┘
   │ POR     │                 └──────────────────────────────┘
   └─────────┘
                                  ▲                                        ▲
                                  │                                        │
                          8 flip-flop ở đây                    Chính chỗ này là lý do dùng Gray:
                          (ô nhớ duy nhất của khối)            dây tín hiệu đi qua ranh giới clock
```

**Vì sao mã Gray mới là câu trả lời đúng ở ranh giới này:** khi 8 dây tín hiệu đi từ miền
clock A sang miền clock B, chúng không thể đổi mức **cùng một lúc tuyệt đối** — mỗi dây có
độ trễ riêng. Nếu truyền nhị phân, bước `0111 1111 → 1000 0000` có 8 dây đổi cùng lúc; miền
B có thể lấy mẫu trúng trạng thái trung gian và đọc ra một giá trị **hoàn toàn sai**
(ví dụ `1111 1111` = 255 trong khi vị trí thật là 128). Với Gray, mỗi bước chỉ có **1 dây**
đổi, nên mẫu sai lệch nhiều nhất là **một nấc** — vẫn dùng được.

## 2. Ranh giới khối — cái gì thuộc D05, cái gì không

| Thành phần | Thuộc D05? | Ghi chú |
|---|:-:|---|
| 8 flip-flop giữ `binary_state` | ✅ | 8 × `dfxtp_1` trong netlist |
| Logic tăng 1 (incrementer) | ✅ | ~25 cell tổ hợp |
| Cây XOR mã hoá Gray | ✅ | 7 phép XOR (netlist gộp còn 6 `xor2` + 4 `nor2`) |
| Sinh `enable` từ cảm biến | ❌ | Tầng ngoài |
| Chống rung tiếp điểm, lọc nhiễu cảm biến | ❌ | Tầng ngoài |
| Bộ đồng bộ 2 tầng FF ở miền B | ❌ | **Đề J01** |
| Giải mã Gray → nhị phân ở miền B | ❌ | Tầng ngoài (cây XOR tiền tố) |
| Phát hiện chiều quay (thuận/nghịch) | ❌ | Ngoài phạm vi — D05 chỉ đếm lên |
| Xuất `binary_state` ra chân | ❌ **nhưng Charter mục 4 ĐÒI** | Xem cảnh báo C4-3 ở `functional_spec.md` |

**Nghĩa vụ hợp đồng của tầng ngoài** (đã ghi ở `interface.md` §4):

1. Giữ `rst_n = 0` qua **ít nhất một cạnh lên `clk`** (reset đồng bộ — không phải bất đồng bộ).
2. `enable` phải ổn định quanh cạnh lên, hoặc đã qua bộ đồng bộ.
3. Bên nhận ở miền B **phải** dùng đồng bộ 2 tầng; Gray làm giảm hậu quả của lấy mẫu sai,
   **không** loại bỏ metastability.

## 3. Phân loại analog / digital / mixed

**Digital thuần.** Không có thành phần analog, không có mạch lai. Bằng chứng: toàn bộ 40
cell trong `06_GDSII/synthesis/netlist.v` đều thuộc thư viện standard cell số
`sky130_fd_sc_hd`; không có macro analog, không có `Macro` trong `power_report.txt`
(hàng `Macro` = 0,0 %).

## 4. Vòng đời RTL → GDSII — trạng thái thật từng bước

```
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │  ✅ 1. Đặc tả       Charter mục 1/4/8/9 → 01_REQUIREMENT, 02_SPECIFICATION   │
   └──────────────────────────────────┬───────────────────────────────────────────┘
                                      ▼
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │  ✅ 2. Mô hình chuẩn Python      reference_model.py → PASS                    │
   │        Bằng chứng: 05_VERIFICATION/python_reference_run.log                   │
   └──────────────────────────────────┬───────────────────────────────────────────┘
                                      ▼
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │  ✅ 3. RTL           d05_core.sv  (+ d05_direct_gray.sv — đối chứng, không top)│
   └──────────────────────────────────┬───────────────────────────────────────────┘
                                      ▼
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │  ✅ 4. Mô phỏng RTL  Icarus Verilog → **PASS**                                │
   │        "D05 core verification PASS" · $finish tại 2606                        │
   │        ⚠ cảnh báo biên dịch ở d05_direct_gray.sv (module KHÔNG dùng)          │
   └──────────────────────────────────┬───────────────────────────────────────────┘
                                      ▼
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │  ✅ 5. Tổng hợp      Yosys 0.33 + sky130_fd_sc_hd → 40 cell · 8 FF · 369,104 µm²│
   └──────────────────────────────────┬───────────────────────────────────────────┘
                                      ▼
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │  ✅ 6. STA sau tổng hợp  OpenSTA 3.1.0 → PASS · slack 8,28 ns · WNS 0,00      │
   │        ⚠ clock lý tưởng, chưa có RC dây                                       │
   └──────────────────────────────────┬───────────────────────────────────────────┘
                                      ▼
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │  ✅ 7. Ước lượng công suất  3,62e-05 W (tuần tự 94,6 % · tổ hợp 5,4 %)        │
   └──────────────────────────────────┬───────────────────────────────────────────┘
                                      ▼
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │  ⬜ 8. Floorplan      ⬜ 9. Placement      ⬜ 10. CTS      ⬜ 11. Routing       │
   │  ⬜ 12. DRC           ⬜ 13. LVS           ⬜ 14. GDS                          │
   │        Cần: PDK sky130A (volare/open_pdks) + LibreLane/OpenROAD               │
   │        Lệnh có sẵn: 04_IMPLEMENTATION/scripts/04_run_librelane.sh             │
   └──────────────────────────────────┬───────────────────────────────────────────┘
                                      ▼
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │  ⬛ 15. Sign-off · tape-out · chế tạo · đo sau chế tạo                        │
   │        KHÔNG ÁP DỤNG — Charter mục 3 liệt kê ngoài phạm vi                    │
   └──────────────────────────────────────────────────────────────────────────────┘
```

Nguồn trạng thái: `06_GDSII/physical_report.md` §1 và BRIEF D05.

| Ký hiệu | Nghĩa | Số bước |
|---|---|---:|
| ✅ | đã chạy thật, có log | **7** |
| ⬜ | chưa chạy, thiếu điều kiện | **7** |
| ⬛ | không áp dụng (ngoài phạm vi Charter) | **1** |

> ❗ Vì các bước 8–14 chưa chạy, **mọi con số thời gian trong hồ sơ đều là sau-tổng-hợp,
> chưa có ký sinh dây**. Không được phát biểu "D05 chạy được ở 100 MHz".

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
