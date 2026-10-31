# Lịch sử thực hiện D05

Lịch sử commit được giữ nguyên, không tạo lại các mốc đã qua.
- 451df24 (30/10/2026): đưa hồ sơ đặc tả, RTL và testbench đã thực hiện lên repo. M1 và M2 nằm trong cùng lần nhập nguồn.
- 8d925df (31/10/2026): bổ sung CI mô phỏng RTL.
- M3 (bổ sung hiện tại): đưa cấu hình vật lý và workflow LibreLane lên CI; kiểm tra GDS và lưu artifacts.
- M4 (7ec3ff7): ghi số liệu CI 41219250115, GDS và báo cáo STA/power/DRC/LVS thật.
- M5: cập nhật báo cáo Word/PDF 15 trang, link CI đầy đủ, kết quả A/B 30/49 và ảnh KLayout render từ artifact. File tại report/.

Tên mốc mô tả công việc trong commit thực tế, không giả lập lịch sử hoàn thành từ trước.

- Việt hóa tên quy trình, hai công việc và các bước tại cc68d11; lượt kiểm tra 41220729337 thành công. Cập nhật tên và đường dẫn trong báo cáo, giữ nguyên lịch sử cũ.

- Tên mốc được ghi bằng tiếng Việt ở tiêu đề lượt kiểm tra. M1/M2 kiểm tra lại hồ sơ có sẵn; lịch sử nhập nguồn vẫn giữ nguyên.

## Các mốc M1–M5

Tên quy trình và các bước thực thi giữ cách đặt tên ban đầu. Tiêu đề các lượt kiểm tra mốc dùng tiếng Việt.

| Mốc | Nội dung | Lượt kiểm tra |
|---|---|---|
| M1 | Đặc tả và kiến trúc D05 | [Đạt](https://github.com/huahieu-may/D05-Gray-8bit/actions/runs/41222097324) |
| M2 | RTL và kiểm chứng chức năng D05 | [Đạt](https://github.com/huahieu-may/D05-Gray-8bit/actions/runs/41222099472) |
| M3 | Chạy flow RTL-to-GDSII trên GitHub Actions | [Đạt](https://github.com/huahieu-may/D05-Gray-8bit/actions/runs/41222101747) |
| M4 | Phân tích tổng hợp, thời gian, công suất, DRC và LVS | [Đạt](https://github.com/huahieu-may/D05-Gray-8bit/actions/runs/41222183467) |
| M5 | Báo cáo và bằng chứng D05 | [Đạt](https://github.com/huahieu-may/D05-Gray-8bit/actions/runs/41222185991) |

M1 và M2 nằm chung trong lần nhập nguồn 451df24. Các lượt M1/M2 ở đây kiểm tra lại hồ sơ có sẵn, không phải lịch sử được tạo lại. M4 đọc các báo cáo đã lưu từ CI 41219250115; M5 kiểm tra các tệp báo cáo và bằng chứng. M3 thực sự chạy lại đầy đủ mô phỏng và LibreLane.
