# D05 · Bối cảnh ứng dụng



| | |
|---|---|
| Mã đề | **D05** |
| Tên đề | Bộ đếm Gray 8-bit |
| Nhóm đề | D · Bộ đếm và chia tần |
| Độ khó | Trung bình |
| Loại mạch | **Tuần tự** |
| Quy mô ước lượng (Charter) | ~170–240 cell · 1×1 tile |
| Nguồn gốc | Project Charter — D05, mục 1 |

---

## 1. Mục tiêu và bối cảnh ứng dụng

Trích nguyên văn Charter mục 1:

> Phân tích khối số “Bộ đếm Gray 8-bit” ở mức khối. Bối cảnh ứng dụng: Khối đếm vị trí trong bộ mã hoá góc quay tuyệt đối: mã Gray để đọc sai một bit cũng chỉ lệch một nấc.

## 2. Vị trí khối D05 trong hệ thống

```
   ┌──────────────┐      ┌──────────────────────────────┐      ┌──────────────┐
   │  Nguồn tín   │─────▶│      ►►► KHỐI D05 ◄◄◄        │─────▶│  Tầng tiêu   │
   │  hiệu / dữ   │      │  Bộ đếm Gray 8-bit            │      │  thụ kết quả │
   │  liệu vào    │      │  Loại mạch: Tuần tự          │      │              │
   └──────────────┘      └──────────────────────────────┘      └──────────────┘
```

> Sơ đồ chi tiết có chú thích: `03_ARCHITECTURE/system_diagram.md`.

## 3. Phân loại analog / digital / mixed

| Khối | Phân loại | Ghi chú |
|---|---|---|
| Cảm biến / nguồn tín hiệu vật lý (nếu có) | Analog | Đại lượng liên tục |
| Chuyển đổi ADC/DAC (nếu có) | Mixed-signal | Ranh giới analog–số |
| **D05 — Bộ đếm Gray 8-bit** | **Digital, tuần tự** | Có ô nhớ, hoạt động theo cạnh clock |
| Tầng xử lý phía sau | Digital | Tiêu thụ kết quả của D05 |

Bằng chứng cho dòng phân loại của D05: tổng hợp thật cho **8 flip-flop**
(`06_GDSII/synthesis/synth_stat.txt`).

---

**Truy vết:** yêu cầu sinh từ tài liệu này được đánh số `REQ-D05-0xx` trong
`01_REQUIREMENT/requirements.md`, và truy vết đến bằng chứng trong `07_TRACEABILITY/RTM.csv`.

*Phiên bản: v1.0 · Ngày: 2026-09-24*
