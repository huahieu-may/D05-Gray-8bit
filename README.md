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
