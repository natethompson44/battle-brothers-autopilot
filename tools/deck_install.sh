#!/bin/bash
# Steam Deck / Linux installer for the vanilla mod set.
#
# Downloads the dependencies that are mirrored on GitHub straight into the game's data folder and
# copies our two mods from this repo. stdlib and Autopilot New are only distributed on NexusMods,
# so the script tells you when those still need to be added by hand.
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

echo
missing=0
ls "$DATA"/*stdlib*.zip >/dev/null 2>&1 || { echo "STILL NEEDED: stdlib 2.5+  https://www.nexusmods.com/battlebrothers/mods/676"; missing=1; }
ls "$DATA"/mod_autopilot_new*.zip >/dev/null 2>&1 || { echo "STILL NEEDED: Autopilot New 2.9.0+  https://www.nexusmods.com/battlebrothers/mods/675"; missing=1; }
[ $missing = 0 ] && echo "all required mods present"
echo
echo "data folder now contains:"
ls -1 "$DATA"/*.zip | xargs -n1 basename
