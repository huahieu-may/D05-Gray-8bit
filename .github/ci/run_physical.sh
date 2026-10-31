#!/usr/bin/env bash
set -euo pipefail
mkdir -p build/physical
{
  printf 'Commit: '; git rev-parse HEAD
  printf 'Date UTC: '; date -u +%FT%TZ
  printf 'LibreLane source: %s\n' "$LIBRELANE_REV"
  printf 'SKY130 expected revision: %s\n' "$SKY130_PDK_VERSION"
  librelane --version
  yosys -V
  openroad -version
} | tee build/physical/tool_versions.txt
python3 - <<'PY'
import json, os, pathlib, subprocess, datetime
p = pathlib.Path("build/physical")
sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
meta = {k: os.getenv(k) for k in ["GITHUB_REPOSITORY", "GITHUB_RUN_ID", "GITHUB_RUN_ATTEMPT", "LIBRELANE_REV", "SKY130_PDK_VERSION"]}
meta.update(commit=sha, utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
            ci_url=f"https://github.com/{meta['GITHUB_REPOSITORY']}/actions/runs/{meta['GITHUB_RUN_ID']}")
(p / "provenance.json").write_text(json.dumps(meta, indent=2)+"\n")
PY
librelane --pdk-root "$PDK_ROOT" --pdk sky130A --tag CI "$CONFIG"
