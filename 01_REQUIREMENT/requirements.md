# D05 · Bảng yêu cầu (Requirements)



Mọi yêu cầu đều **suy trực tiếp từ Project Charter — D05**. Cột *Nguồn* chỉ rõ mục nào
của Charter sinh ra yêu cầu đó. Không có yêu cầu nào do người soạn tự thêm.

Mức: **M** = bắt buộc · **S** = nên có · **O** = tuỳ chọn.

---

## 1. Yêu cầu chức năng và cấu trúc

| ID | Mức | Nội dung yêu cầu | Nguồn |
|---|---|---|---|
| REQ-D05-001 | M | Khối thực hiện đúng chức năng mô tả trong Charter mục 1: *Bộ đếm Gray 8-bit*. | mục 1 |
| REQ-D05-002 | M | Giao diện đúng ánh xạ chân Charter mục 4 (xem `02_SPECIFICATION/interface.md`). | mục 4 |
| REQ-D05-003 | M | Loại mạch phải đúng phân loại Charter: **Tuần tự** — có ô nhớ, đồng bộ theo clock. | mục 10 |
| REQ-D05-004 | M | Quy mô nằm trong khoảng hợp lý cho ô 1×1 tile (Charter ước lượng ~170–240 cell · 1×1 tile). | metadata |

## 2. Yêu cầu kiểm chứng

| ID | Mức | Nội dung yêu cầu | Nguồn |
|---|---|---|---|
| REQ-D05-010 | M | Chạy đủ các ca kiểm thử bắt buộc của Charter mục 8 (xem §4). | mục 8 |
| REQ-D05-011 | M | Bổ sung **ít nhất hai ca tự xây dựng**, trong đó có **ca biên**. | mục 8 |
| REQ-D05-012 | M | Mỗi khẳng định phải đi kèm **bằng chứng** và **điều kiện tạo ra bằng chứng**. | mục 6 |
| REQ-D05-013 | S | Thu một **artifact số có chú thích** và nêu điều kiện tạo ra nó. | mục 3, 5 |

## 3. Yêu cầu phân tích riêng (đặc thù của D05)

> Charter mục 9 — bắt buộc trả lời bằng số liệu của chính mình:
>
> Tính chất 'mỗi bước chỉ đổi một bit' là lý do bộ đếm Gray được dùng ở ranh giới hai miền xung nhịp. Kiểm chứng tính chất này bằng mô phỏng cho đủ 256 bước, và nêu trong báo cáo vì sao nó quan trọng.
> Bắt buộc trả lời bằng số liệu của chính mình. Mỗi đề một câu khác nhau.

| ID | Mức | Nội dung |
|---|---|---|
| REQ-D05-020 | M | Trả lời câu phân tích riêng ở trên bằng dữ liệu do chính mình sinh ra. |
| REQ-D05-021 | M | Trả lời các câu hỏi kỹ thuật Charter mục 2 (xem §5) bằng bằng chứng. |

## 4. Ca kiểm thử bắt buộc (Charter mục 8)

- Chạy đủ 256 bước, kiểm mỗi bước chỉ đổi đúng 1 bit · kiểm giá trị nhị phân tương đương
- Bổ sung ít nhất hai ca tự xây dựng, trong đó có ca biên.

Danh sách thực thi và kết quả: `05_VERIFICATION/test_matrix.csv`.

## 5. Câu hỏi kỹ thuật của Charter (mục 2)

1. **Bằng chứng nào chứng minh mỗi bước CHỈ đổi đúng một bit — chạy đủ 256 bước hay lập luận?**
2. **Giữ thanh ghi ở dạng nhị phân rồi chuyển sang Gray, hay giữ luôn dạng Gray — hai cách khác nhau bao nhiêu cell?**
3. **Vì sao mã Gray quan trọng khi tín hiệu đi qua hai miền xung nhịp (liên hệ đề J01)?**

> Sinh viên được phép thay bằng câu hỏi của mình, miễn là cụ thể và trả lời được bằng bằng
> chứng — không viết "tìm hiểu về…". *(Charter mục 2)*

Câu trả lời kèm bằng chứng: `05_VERIFICATION/verification_report.md` và `06_GDSII/physical_report.md`.

## 6. Yêu cầu bàn giao (Charter mục 5)

- Hồ sơ phân tích đủ tám thành phần, có số phiên bản và ngày sửa.
- Bảng giao diện: tên tín hiệu, chiều, độ rộng, mức tích cực, giả định.
- Một artifact số có chú thích và nêu điều kiện tạo ra nó.
- Kết luận nêu rõ đã chứng minh được gì và chưa chứng minh được gì.

## 7. Mốc thực hiện (Charter mục 7)

- M1 · T7. Chốt đề và viết charter: ứng dụng, mục tiêu, 2–3 câu hỏi kỹ thuật.
- M2 · T8–9. Bảng hành vi suy từ đặc tả; đọc RTL và waveform; lập danh sách ca kiểm thử.
- M3 · T11–12. Sơ đồ khối hỗ trợ; thu artifact số, chú thích và đối chiếu bảng hành vi.
- M4 · T13–14. Hoàn thiện bảng giao diện, RTM-lite, sơ đồ vòng đời; rà từng khẳng định.
- M5 · T15. Nộp hồ sơ và trình bày; trả lời câu phân tích riêng bằng số của chính mình.

## 8. Rủi ro chính (Charter mục 10)

> Chỗ hay tắc: Chỉ chạy vài bước rồi kết luận. Đề yêu cầu đủ 256 bước vì lỗi hay nằm ở chỗ quay vòng.
> Dấu hiệu làm đúng: 8 ô nhớ. Nếu giữ nhị phân + chuyển thì thêm một cây XOR tổ hợp.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Nguồn chuẩn: `Project_Charter_80_De.docx`, mục D05.*
