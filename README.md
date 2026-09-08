# Battle Brothers autonomous-company mods

Two mods that make Battle Brothers play itself so you can play the captain: recruit, equip,
pick fights, and live with the outcome.

| Mod | What it does | Zip |
|---|---|---|
| **Autopilot Expert** | Companion to Suor's Autopilot New. Auto-engages the AI at battle start, role-based targeting profiles, early-round line holding, takes over summons and reinforcements, teaches the AI extra skills, support behaviors. | `mod_autopilot_expert_<version>.zip` |
| **Level-Up Pilot** | Spends attribute points and perk points automatically with role-based builds. Vanilla-first; uses Legends' perk trees when Legends is present. | `mod_levelup_pilot_<version>.zip` |

Each mod's folder has its own README with settings. Source is in the folders; the zips at the
repo root are the installable builds. Drop zips into the game's `data` folder.

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
  sets (expects the third-party zips next to this README).


