# Battle Brothers autonomous-company mods

Two mods that make Battle Brothers play itself so you can play the captain: recruit, equip,
pick fights, and live with the outcome.

| Mod | What it does | Zip |
|---|---|---|
| **Autopilot Expert** | Companion to Suor's Autopilot New. Auto-engages the AI at battle start, role-based targeting profiles, early-round line holding, takes over summons and reinforcements, teaches the AI extra skills, support behaviors. | `mod_autopilot_expert_<version>.zip` |
| **Level-Up Pilot** | Spends attribute points and perk points automatically with role-based builds. Vanilla-first; uses Legends' perk trees when Legends is present. | `mod_levelup_pilot_<version>.zip` |

Each mod's folder has its own README with settings. Source is in the folders; the zips at the
repo root are the installable builds.

## Installing

Copy the two `mod_*.zip` files from the repo root into the game's `data` folder, as they are, next
to the required mods below. Do **not** put the GitHub "Download ZIP" of the whole repo in `data`:
it wraps everything in a `battle-brothers-autopilot-main/` folder, so the game finds no
`scripts/` at the zip root and silently ignores it.

Where `data` is:

| Platform | Path |
|---|---|
| Windows | `C:\Program Files (x86)\Steam\steamapps\common\Battle Brothers\data` |
| Steam Deck / Linux (internal drive) | `~/.local/share/Steam/steamapps/common/Battle Brothers/data` |
| Steam Deck (SD card) | `/run/media/mmcblk0p1/steamapps/common/Battle Brothers/data` |

**Steam Deck / Linux shortcut:** in Desktop Mode open Konsole in the repo folder and run
`bash tools/deck_install.sh`. It finds the data folder, downloads Modding Script Hooks, Modern Hooks
and MSU from their GitHub releases, copies our two zips, and, if stdlib or Autopilot New are not
already there, builds them from their GitHub sources (they are only released on Nexus; the sources
are BSD-licensed and the script packs exactly what the authors' Makefiles pack). Needs `curl` and
`python3`, both on SteamOS.

**"requires stdlib" with stdlib in the folder:** the stdlib 2.6 zip on Nexus only registers itself
through Modding Script Hooks (mod_hooks). With Legends installed you never notice, because Legends
bundles mod_hooks; take Legends out and every mod that requires stdlib fails with a red screen even
though stdlib is there. Either add mod_hooks (Nexus mod 42, mirrored at
https://github.com/jcsato/modding_script_hooks/releases/latest) or replace the stdlib zip with one
built from the GitHub source, which registers through Modern Hooks directly. `deck_install.sh`
does both.

A working vanilla install has all of these in `data` (versions may differ):

```
mod_hooks_21.1.zip            Modding Script Hooks
mod_modern_hooks_0.6.0.zip    Modern Hooks
mod_msu_1.9.0.zip             MSU
mod_stdlib_2.6.zip            stdlib (the Nexus file is named stdlib_2.6.zip; either name works)
mod_autopilot_new_2.9.0.zip   Autopilot New
mod_autopilot_expert_1.0.9.zip
mod_levelup_pilot_1.1.0.zip
```

If the game shows a red Modern Hooks screen mentioning `stdlib`, `mod_autopilot_new` or `mod_msu`,
one of the mods in that list is missing from `data` or is too old for the version our mods ask for.
The requirements are checked by name, so a nested zip (a zip inside the zip you downloaded) or a
zip with the mod's files under an extra top-level folder counts as missing.

The game log is `Documents\Battle Brothers\log.html` on Windows. On Steam Deck under Proton it is
`~/.local/share/Steam/steamapps/compatdata/365360/pfx/drive_c/users/steamuser/Documents/Battle Brothers/log.html`.

## Required mods (download from their authors)

Install these alongside ours. They are not included in this repo.

| Mod | Needed by | Where |
|---|---|---|
| Modding Script Hooks (mod_hooks) | stdlib | https://www.nexusmods.com/battlebrothers/mods/42 |
| Modern Hooks | everything | https://www.nexusmods.com/battlebrothers/mods/685 |
| MSU (Modding Standards & Utilities) | everything | https://www.nexusmods.com/battlebrothers/mods/479 |
| stdlib | Autopilot New, Autopilot Expert | https://www.nexusmods.com/battlebrothers/mods/676 |
| Autopilot New | Autopilot Expert | https://www.nexusmods.com/battlebrothers/mods/675 |
| Legends (optional) + Legends assets | optional for both | https://www.nexusmods.com/battlebrothers/mods/60 |

Note: with Legends installed you do not need mod_hooks separately (Legends bundles it). Without
Legends you do, or stdlib fails to register.

## Tools

- `tools/battle_report.py` - turns the game's `log.html` into a per-fight report. `--last` prints the
  most recent fight turn by turn.
- `tools/switch_mods.py vanilla|legends|status` - swaps the game's data folder between the two mod
  sets (Windows; expects the third-party zips next to this README).
- `tools/deck_install.sh [data-folder]` - Steam Deck / Linux: downloads the GitHub-hosted
  dependencies into the data folder and installs our two mods.


