"""Deploy Voxario Guide runtime files into a local World of Warcraft AddOns folder."""
import argparse
import filecmp
import shutil
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SOURCE = REPO / "VoxarioGuide"
TARGET = Path(r"C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\VoxarioGuide")
RUNTIME_DIRS = ("Core", "Data", "Guides", "Localization", "UI")
RUNTIME_FILES = ("VoxarioGuide.toc",)

def runtime_files():
    files = []
    for name in RUNTIME_FILES:
        path = SOURCE / name
        if path.is_file(): files.append(path)
    for directory in RUNTIME_DIRS:
        root = SOURCE / directory
        if root.is_dir():
            files.extend(path for path in root.rglob("*") if path.is_file() and "__pycache__" not in path.parts and path.suffix != ".pyc")
    return files

def main():
    parser = argparse.ArgumentParser(description="Deploy Voxario Guide runtime addon files.")
    parser.add_argument("--clean", action="store_true", help="Remove only obsolete files inside managed runtime directories.")
    parser.add_argument("--target", type=Path, default=TARGET, help="Override the WoW addon destination.")
    args = parser.parse_args(); target = args.target
    if not SOURCE.is_dir(): raise SystemExit(f"Runtime source not found: {SOURCE}")
    expected = {path.relative_to(SOURCE) for path in runtime_files()}
    copied = unchanged = removed = 0
    for relative in sorted(expected):
        source, destination = SOURCE / relative, target / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists() and filecmp.cmp(source, destination, shallow=False):
            unchanged += 1
        else:
            shutil.copy2(source, destination); copied += 1; print(f"[COPY] {relative}")
    if args.clean and target.exists():
        for directory in RUNTIME_DIRS:
            managed = target / directory
            if managed.is_dir():
                for path in managed.rglob("*"):
                    if path.is_file() and path.relative_to(target) not in expected:
                        path.unlink(); removed += 1; print(f"[REMOVE] {path.relative_to(target)}")
    required = (Path("VoxarioGuide.toc"), Path("Data/Generated/Zones.lua"), Path("Data/Generated/Quests.lua"), Path("Data/Generated/NPCs.lua"), Path("Data/Generated/Items.lua"))
    for relative in required:
        source, destination = SOURCE / relative, target / relative
        if not destination.is_file(): raise SystemExit(f"Deployment failed: missing destination {relative}")
        if source.stat().st_size != destination.stat().st_size: raise SystemExit(f"Deployment failed: size mismatch {relative}")
        print(f"[VERIFY] {relative}: OK ({destination.stat().st_size} bytes)")
    source_version = next((line for line in (SOURCE / "VoxarioGuide.toc").read_text().splitlines() if line.startswith("## Version:")), None)
    target_version = next((line for line in (target / "VoxarioGuide.toc").read_text().splitlines() if line.startswith("## Version:")), None)
    if not source_version or source_version != target_version: raise SystemExit("Deployment failed: TOC version mismatch")
    print(f"[VERIFY] TOC version: {target_version}")
    print(f"[DONE] copied: {copied} | unchanged: {unchanged} | removed: {removed} | target: {target}")

if __name__ == "__main__": main()
