# M4 — Kết quả D05 từ GitHub Actions

- Repo: https://github.com/huahieu-may/D05-Gray-8bit
- CI: https://github.com/huahieu-may/D05-Gray-8bit/actions/runs/41220729337
- Commit tạo artifacts: cc68d112c2f57bf3adb88cf69d710f78c689b153
- Ngày chạy: 31/10/2026, bắt đầu 23:39:26 (UTC+7).
- Hai job thành công: mô phỏng 16 giây; LibreLane 146 giây.
- LibreLane 3.0.17: 64ef80802d3d189b476636d2a6b17888c03304ee.
- Yosys 0.62: 7326bb7d6641500ecb285c291a54a662cb1e76cf.
- SKY130 revision: 8afc8346a57fe1ab7934ba5a6056ea8b43078e71.

## Kết quả và nguồn

| Chỉ số | Giá trị | Nguồn trong artifact vật lý |
|---|---:|---|
| Số ô logic chung của A / B | 30 / 49 cell; 8 FF mỗi phương án | build/physical/generic/*.log |
| Số ô đã ánh xạ của A | 37 cell; 470,4512 µm² | physical_design/runs/CI/06-yosys-synthesis/reports/stat.rpt |
| Ô chuẩn sau đặt tuyến | 154; 898,362 µm² | final/metrics.json |
| Ô lấp đầy / ô tiếp xúc nguồn | 1624 / 90 | final/metrics.json |
| Biên thời gian thiết lập / giữ xấu nhất | 5,034054 / 0,119901 ns | final/metrics.json |
| Biên thời gian thiết lập tại góc TT trước / sau | 6,698303 / 6,288049 ns | 12-openroad-staprepnr và 55-openroad-stapostpnr/nom_tt_025C_1v80/max.rpt |
| Công suất tại góc TT trước / sau | 40,1606 / 110,8768 µW | power.rpt ở cùng hai thư mục |
| Chiều dài dây sau đi dây | 1291 µm | final/metrics.json |
| Magic / KLayout DRC, LVS | 0 / 0 / 0 lỗi | final/metrics.json |
| GDS | d05_core.gds, 349182 byte | final/gds/ |
| Mô phỏng | 578 kiểm, 559 bước Gray đúng 1 bit | artifact D05 - Kết quả mô phỏng/simulation.log |

Setup và hold tổng hợp không cùng góc PVT. So sánh trước/sau chỉ dùng nom_tt_025C_1v80.
Area sau layout tăng 90,96%; power TT tăng 176,08%; worst setup slack TT giảm 6,12%.
Số cell generic B tăng 63,33% so với A trong cùng lệnh/cùng phiên bản; đây không phải tỷ lệ diện tích hay power.
Số liệu vật lý CI khớp lần chạy cục bộ trước đó, nhưng nguồn nộp ở đây là artifact CI thật.

## Tải và tái lập

Các gói kết quả của hệ thống kiểm tra tự động:
- D05 - Kết quả mô phỏng (id 13049219686).
- D05 - Kết quả thiết kế vật lý (id 13049657294).

Bản sao các báo cáo chính, GDS, ảnh layout và metadata nằm tại 06_GDSII/CI_41220729337/.
Các thư mục pre/post trong bản sao vẫn giữ cấu trúc stage để truy vết.
Báo cáo Word/PDF nộp nằm trong report/ sau mốc M5.

Chạy lại bằng Actions > D05 - RTL to GDSII > Run workflow.
Cấu hình vật lý nằm tại physical_design/config.json, RTL nằm trong 04_IMPLEMENTATION/rtl/.
File .github/ci/run_physical.sh ghi tool version và metadata trước khi chạy.
File .github/ci/collect_metrics.py kiểm sản phẩm thật và in chỉ số từ final/metrics.json.

## Chẩn đoán lượt đầu

CI 41219015650, commit 7d151d5, dừng ở cú pháp lệnh:
No such option: --tag (Possible options: --pad, --run-tag, --to).
Đây là lỗi CLI trước khi khởi động flow, không phải lỗi RTL hoặc PDN.
Commit 0844411 sửa sang --run-tag CI và bổ sung log tổng hợp A/B. Lượt sau cả hai job PASS.

## Giới hạn

Chưa mô phỏng netlist sau route kèm SDF; chưa kiểm CDC với hai miền clock hay wrapper Tiny Tapeout.
Power dùng hoạt động mặc định của STA. Kết quả là bài đánh giá core trong flow và PDK đã ghi.
Các bảng 32/41 cell trong log cũ thuộc Yosys khác; không dùng để trộn vào so sánh CI 30/49.
