#!/bin/bash
# Steam Deck / Linux installer for the vanilla mod set.
#
# Downloads Modding Script Hooks, Modern Hooks and MSU from their GitHub releases straight into the
# game's data folder, copies our two mods from this repo, and builds stdlib and Autopilot New from
# their GitHub sources if they are not already there (they are only released on NexusMods).
#
# Usage (Desktop Mode, Konsole):
#   bash tools/deck_install.sh              # auto-detect the data folder
#   bash tools/deck_install.sh /path/to/data
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

find_data() {
    for d in \
        "$HOME/.local/share/Steam/steamapps/common/Battle Brothers/data" \
        "$HOME/.steam/steam/steamapps/common/Battle Brothers/data" \
        /run/media/*/steamapps/common/"Battle Brothers"/data \
        /run/media/deck/*/steamapps/common/"Battle Brothers"/data; do
        [ -d "$d" ] && { echo "$d"; return; }
    done
}

DATA="${1:-$(find_data)}"
[ -d "$DATA" ] || { echo "Battle Brothers data folder not found; pass it as the first argument."; exit 1; }
echo "data folder: $DATA"

# name in data folder -> GitHub release asset
declare -A GITHUB=(
    ["mod_hooks_21.1.zip"]="https://github.com/jcsato/modding_script_hooks/releases/download/v21.1/mod_hooks.zip-42-20-1-1621709174.zip"
    ["mod_modern_hooks_0.6.0.zip"]="https://github.com/MSUTeam/Modern-Hooks/releases/download/0.6.0/mod_modern_hooks-0.6.0.zip"
    ["mod_msu_1.9.0.zip"]="https://github.com/MSUTeam/MSU/releases/download/1.9.0/mod_msu-1.9.0.zip"
)
for name in "${!GITHUB[@]}"; do
    if ls "$DATA"/${name%%_[0-9]*}_*.zip >/dev/null 2>&1; then
        echo "present:    $(ls "$DATA"/${name%%_[0-9]*}_*.zip | xargs -n1 basename | tr '\n' ' ')"
    else
        echo "download:   $name"
        curl -sSL -o "$DATA/$name" "${GITHUB[$name]}"
    fi
done

for prefix in mod_autopilot_expert mod_levelup_pilot; do
    src=$(ls "$REPO"/${prefix}_*.zip 2>/dev/null | sort -V | tail -1 || true)
    [ -n "$src" ] || { echo "missing in repo: ${prefix}_*.zip"; continue; }
    rm -f "$DATA"/${prefix}_*.zip
    cp "$src" "$DATA/"
    echo "installed:  $(basename "$src")"
done

# stdlib and Autopilot New are published on NexusMods, which needs a login. Their sources are on
# GitHub under a BSD license, so if they are not in data we build the same zip the authors' Makefile
# builds: stdlib = "stdlib" + "scripts"; Autopilot New = "autopilot gfx scripts ui" from the
# autopilot/ folder of Suor's mods repo. ARCHIVE_DIR is only for offline testing.
build_from_github() {  # $1 output name, $2 repo, $3 subdir inside the repo ("" for root), rest: dirs
    local out="$1" repo="$2" sub="$3"; shift 3
    local tmp; tmp=$(mktemp -d)
    local arch="$tmp/src.zip"
    if [ -n "${ARCHIVE_DIR:-}" ]; then cp "$ARCHIVE_DIR/${repo#*/}.zip" "$arch"
    else curl -sSL -o "$arch" "https://github.com/$repo/archive/refs/heads/master.zip"; fi
    python3 - "$arch" "$DATA/$out" "$sub" "$repo" "$@" <<'PY'
import sys, zipfile
arch, out, sub, repo, dirs = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5:]
with zipfile.ZipFile(arch) as src, zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as dst:
    top = src.namelist()[0].split("/")[0]
    base = top + "/" + (sub + "/" if sub else "")
    n = 0
    for name in sorted(src.namelist()):
        if not name.startswith(base) or name.endswith("/"): continue
        rel = name[len(base):]
        if rel.split("/")[0] in dirs:
            dst.writestr(rel, src.read(name)); n += 1
    if n == 0: sys.exit("nothing packed from " + arch)
    print("built:     ", out.rsplit("/", 1)[-1], "(" + str(n) + " files from github.com/" + repo + ")")
PY
    rm -rf "$tmp"
}
ls "$DATA"/*stdlib*.zip >/dev/null 2>&1 || build_from_github mod_stdlib_2.6.zip Suor/battle-brothers-stdlib "" stdlib scripts
ls "$DATA"/mod_autopilot_new*.zip >/dev/null 2>&1 || build_from_github mod_autopilot_new_2.9.0.zip Suor/battle-brothers-mods autopilot autopilot gfx scripts ui

echo
echo "data folder now contains:"
ls -1 "$DATA"/*.zip | xargs -n1 basename
