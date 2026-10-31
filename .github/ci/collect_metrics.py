"""Read the exact CI run and fail on missing physical products."""
import json
import math
import pathlib
import sys
run = pathlib.Path(sys.argv[1])
out = pathlib.Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)
gds = run / "final/gds/d05_core.gds"
metrics = run / "final/metrics.json"
for p in [gds, metrics, run / "resolved.json"]:
    if not p.is_file() or not p.stat().st_size:
        raise SystemExit(f"Missing or empty required CI product: {p}")
if gds.read_bytes()[:4] != bytes.fromhex("00060002"):
    raise SystemExit("Invalid GDSII HEADER record")
m = json.loads(metrics.read_text())
cfg = json.loads((run / "resolved.json").read_text())
if cfg["DESIGN_NAME"] != "d05_core":
    raise SystemExit("Wrong physical top")
keys = [
    "design__die__area", "design__core__area",
    "design__instance__count", "design__instance__area",
    "design__instance__count__stdcell", "design__instance__area__stdcell",
    "design__instance__count__class:sequential_cell", "design__instance__area__class:sequential_cell",
    "design__instance__count__class:fill_cell", "design__instance__count__class:tap_cell",
    "design__instance__utilization__stdcell", "route__wirelength",
    "route__wirelength__max", "timing__setup__ws", "timing__hold__ws",
    "magic__drc_error__count", "klayout__drc_error__count",
    "design__lvs_error__count", "antenna__violating__nets",
    "antenna__violating__pins",
]
data = {k: m.get(k) for k in keys}
data = {k: str(v) if isinstance(v, float) and not math.isfinite(v) else v for k,v in data.items()}
(out / "metrics_summary.json").write_text(json.dumps(data, indent=2)+"\n")
(out / "metrics_summary.md").write_text(
    "# D05 CI physical metrics\n\nSource: physical_design/runs/CI/final/metrics.json\n\n"
    "| Metric | Value |\n|---|---:|\n" +
    "".join(f"| {k} | {v} |\n" for k, v in data.items()) +
    "\nAggregate setup/hold may use different PVT corners. See per-corner STA reports.\n")
print((out / "metrics_summary.md").read_text())
print(f"Verified GDS: {gds} ({gds.stat().st_size} bytes)")
