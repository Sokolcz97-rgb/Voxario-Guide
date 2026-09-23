"""Offline deterministic generator for normalized Voxario JSON data."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON_ROOT = next(path.parent for path in ROOT.rglob("VoxarioGuide.toc"))
BUILD = json.loads((Path(__file__).with_name("config.json")).read_text())["foreverBuild"]
TABLES = {"zones": "Zones", "quests": "Quests", "npcs": "NPCs", "items": "Items"}

def lua(value):
    if value is None: return "nil"
    if isinstance(value, bool): return "true" if value else "false"
    if isinstance(value, (int, float)): return repr(value)
    if isinstance(value, str): return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list): return "{ " + ", ".join(lua(v) for v in value) + " }"
    return "{ " + ", ".join(f"{k} = {lua(value[k])}" for k in sorted(value)) + " }"

for name, namespace in TABLES.items():
    records = json.loads((ROOT / "tools" / "generated" / f"{name}.json").read_text())
    keyed = {int(r.get(f"{name[:-1]}ID", r.get("mapID"))): r for r in records}
    lines = ["local _, VG = ...", "", f"VG.{namespace} = {{"]
    for key in sorted(keyed):
        record = dict(keyed[key]); record.setdefault("sourceBuild", BUILD)
        lines.append(f"    [{key}] = {lua(record)},")
    lines += ["}", ""]
    destination = ADDON_ROOT / "Data" / "Generated" / f"{namespace}.lua"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text("\n".join(lines), encoding="utf-8")
    if name in ("quests", "npcs") and not keyed: raise SystemExit(f"[GENERATE] {namespace}: zero records")
    print(f"[GENERATE] {destination.relative_to(ADDON_ROOT)}: {len(keyed)} records")
