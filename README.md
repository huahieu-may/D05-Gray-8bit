# D05 — Bộ đếm Gray 8 bit

Sinh viên: Hứa Phạm Minh Hiếu — 24100672 — K18-EEE4.

Top: d05_core. Clock 10 ns; reset đồng bộ tích cực thấp; enable cho phép đếm modulo 256.
Trạng thái là 8 bit nhị phân, đầu ra Gray = B XOR (B >> 1).

## Chạy và kiểm tra
Workflow: .github/workflows/rtl2gds.yml (D05 - RTL to GDSII).
Job 1 chạy testbench tự kiểm: 578 phép kiểm, 559 bước Gray thay đúng một bit.
Job 2 chạy LibreLane 3.0.17, sky130A / sky130_fd_sc_hd, từ chính RTL trong repo.
Cấu hình: physical_design/config.json; die 100 × 100 µm, placement target 45%.

Vào Actions, mở lượt chạy tương ứng commit. Artifacts:
- D05-simulation-results: log, waveform, phiên bản mô phỏng.
- D05-rtl2gds-results: GDS, metrics, báo cáo STA/power/DRC/LVS, log, config và provenance.

Các số đo cũ trong hồ sơ nguồn được giữ để truy vết, không thay thế kết quả CI mới.
Kết quả cuối cùng và link CI sẽ được ghi tại 07_TRACEABILITY/CI_RESULTS.md sau khi kiểm tra.
Các lần chạy vật lý trên máy cá nhân không được coi là lần chạy vật lý trên CI.

## Phạm vi
Chứng minh chức năng RTL và đọc kết quả implementation của bộ đếm.
Chưa kiểm chứng CDC/metastability hay mạch sau chế tạo.

## Kết quả CI đã xác nhận

[Cả hai job PASS – CI 41219250115](https://github.com/huahieu-may/D05-Gray-8bit/actions/runs/41219250115).

[Bảng số liệu và nguồn báo cáo](07_TRACEABILITY/CI_RESULTS.md). GDS, layout và report đối chiếu nằm trong 06_GDSII/CI_41219250115/.

## Báo cáo nộp

- [Báo cáo PDF — 15 trang](report/Bao_cao_D05.pdf)
- [Báo cáo Word](report/Bao_cao_D05.docx)

Cả hai bản dẫn đến CI 41219250115, commit tạo dữ liệu 0844411. Báo cáo phân biệt kết quả đã kiểm và các giới hạn còn mở.

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
