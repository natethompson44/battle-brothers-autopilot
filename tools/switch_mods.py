"""Switch the game's data folder between the vanilla mod set and the Legends mod set.

Usage:
    python tools/switch_mods.py vanilla
    python tools/switch_mods.py legends
    python tools/switch_mods.py status

Source zips are the ones in this repo; the newest version of each of our own mods is used.
Only files starting with "mod_" are touched in the data folder.
"""
import glob
import pathlib
import re
import shutil
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
DATA = pathlib.Path(r"C:\Program Files (x86)\Steam\steamapps\common\Battle Brothers\data")

# repo file (glob) -> installed name
COMMON = {
    "mod_hooks.zip-*.zip": "mod_hooks_20.1.zip",  # Adam's hooks: stdlib registers through it; Legends bundles its own copy
    "mod_modern_hooks-*.zip": "mod_modern_hooks_0.6.0.zip",
    "mod_msu *.zip": "mod_msu_1.9.0.zip",
    "stdlib_*.zip": "mod_stdlib_2.6.zip",
    "mod_autopilot_new_*.zip": "mod_autopilot_new_2.9.0.zip",
    "mod_Quickstart-*.zip": "mod_quickstart_1.0.0.zip",
}
LEGENDS = {
    "mod_legends-assets-*.zip": "mod_legends_assets_19.4.3.zip",
    "mod_legends-19*.zip": "mod_legends_19.4.22.zip",
}
OURS = ["mod_autopilot_expert", "mod_levelup_pilot"]


def newest(prefix):
    cands = sorted(REPO.glob(f"{prefix}_*.zip"), key=lambda p: [int(x) for x in re.findall(r"\d+", p.stem)])
    return cands[-1] if cands else None


def plan(profile):
    files = {}
    for pattern, name in list(COMMON.items()) + (list(LEGENDS.items()) if profile == "legends" else []):
        src = sorted(REPO.glob(pattern))
        if not src:
            print("MISSING in repo:", pattern)
            continue
        files[name] = src[-1]
    for prefix in OURS:
        z = newest(prefix)
        if z:
            files[z.name] = z
    return files


def main(argv):
    if not argv or argv[0] not in ("vanilla", "legends", "status"):
        print(__doc__)
        return
    current = sorted(p.name for p in DATA.glob("mod_*.zip"))
    print("installed now:", current)
    if argv[0] == "status":
        return
    wanted = plan(argv[0])
    for p in DATA.glob("mod_*.zip"):
        if p.name not in wanted:
            p.unlink()
            print("removed", p.name)
    for name, src in wanted.items():
        dst = DATA / name
        if not dst.exists() or dst.stat().st_size != src.stat().st_size:
            shutil.copyfile(src, dst)
            print("installed", name)
    print("installed after:", sorted(p.name for p in DATA.glob("mod_*.zip")))


if __name__ == "__main__":
    main(sys.argv[1:])
