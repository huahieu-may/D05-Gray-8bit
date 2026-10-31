"""Verify existing deliverables now; preserve the original history."""
import os, pathlib, subprocess, zipfile, json, re
stage = os.environ["D05_STAGE"]
lines = [f"# {stage}: kiểm tra hồ sơ D05",
 "Kiểm tra hồ sơ hiện có. M1/M2 nằm chung trong lần nhập nguồn 451df24; không tạo lại lịch sử."]
def present(name):
 p = pathlib.Path(name)
 assert p.is_file() and p.stat().st_size, f"Thiếu hoặc rỗng: {name}"
 lines.append(f"- Có: {name}")
 return p
if stage == "M1":
 for f in ["01_REQUIREMENT/requirements.md","02_SPECIFICATION/interface.md",
           "02_SPECIFICATION/functional_spec.md","03_ARCHITECTURE/block_diagram.md",
           "03_ARCHITECTURE/datapath.md","03_ARCHITECTURE/tradeoff.md"]:
  present(f)
 rtl = present("04_IMPLEMENTATION/rtl/d05_core.sv").read_text()
 assert re.search(r"module\s+d05_core\b", rtl)
 assert all(x in rtl for x in ["clk","rst_n","enable","gray_out","binary_out"])
 lines.append("- Đối chiếu tên khối và năm cổng RTL. Có tài liệu không thay thế việc đánh giá nội dung.")
elif stage == "M2":
 work = pathlib.Path("build/milestone"); work.mkdir(parents=True,exist_ok=True)
 subprocess.run(["iverilog","-g2012","-s","d05_core_tb","-o",str(work/"sim.vvp"),
                 "04_IMPLEMENTATION/rtl/d05_core.sv","05_VERIFICATION/testbench/d05_core_tb.sv"],check=True)
 r = subprocess.run(["vvp","sim.vvp"],cwd=work,capture_output=True,text=True)
 print(r.stdout)
 assert r.returncode == 0, r.stderr
 assert "D05 PASS: 578 lan kiem, 559 buoc Gray doi dung 1 bit" in r.stdout
 assert not re.search(r"FATAL|mismatch|\bFAIL\b",r.stdout,re.I)
 lines.append("- Đã thực thi 578 lượt kiểm tra và 559 bước Gray đổi đúng một bit.")
elif stage == "M4":
 base = "06_GDSII/CI_41219250115/"
 m = json.loads(present(base+"final/metrics.json").read_text())
 for k in ["magic__drc_error__count","klayout__drc_error__count","design__lvs_error__count"]:
  assert m[k] == 0
  lines.append(f"- {k}: {m[k]}")
 for k in ["design__instance__count__stdcell","design__instance__area__stdcell",
           "timing__setup__ws","timing__hold__ws","route__wirelength"]:
  lines.append(f"- {k}: {m[k]}")
 for s in ["12-openroad-staprepnr","55-openroad-stapostpnr"]:
  for f in ["max.rpt","power.rpt","clock.rpt"]:
   present(base+s+"/nom_tt_025C_1v80/"+f)
 present("07_TRACEABILITY/CI_RESULTS.md")
 lines.append("- Đọc báo cáo từ CI 41219250115 đã lưu trong repo; không tạo số liệu vật lý mới.")
elif stage == "M5":
 word = present("report/Bao_cao_D05.docx"); pdf = present("report/Bao_cao_D05.pdf")
 with zipfile.ZipFile(word) as z:
  assert z.testzip() is None
  xml = z.read("word/document.xml").decode()
  assert "24100672" in xml and "Hứa Phạm Minh Hiếu" in xml
  assert "41219250115" in z.read("word/_rels/document.xml.rels").decode()
 assert pdf.read_bytes().startswith(b"%PDF-")
 present("07_TRACEABILITY/RTM.csv")
 present("06_GDSII/CI_41219250115/final/gds/d05_core.gds")
 lines.append("- Có báo cáo, liên kết CI, bảng truy vết và GDS. Kiểm tra tệp không thay thế việc đọc, vấn đáp.")
else:
 raise SystemExit("Mốc không hợp lệ")
text = "\n".join(lines)+"\nPASS\n"
print(text)
if os.getenv("GITHUB_STEP_SUMMARY"):
 pathlib.Path(os.environ["GITHUB_STEP_SUMMARY"]).write_text(text)
