# Autopilot Expert

Companion mod for Suor's **Autopilot New**. It never overwrites game files; it only hooks
Autopilot, vanilla AI behaviors, and Legends skills. Safe to add or remove mid-campaign.

## Requirements (load order is handled by Modern Hooks)

- Modern Hooks
- MSU (Mod Settings Utility) 1.6.0+
- stdlib 2.5+
- Autopilot New 2.9.0+
- Legends is optional; the Legends-specific parts simply do nothing without it.

## What it adds (all toggles under Esc → Mod Options → Autopilot Expert)

| Setting | Default | What it does |
|---|---|---|
| Auto-engage AI at battle start | on | Every battle starts on AI, no popup. Press **V** to take control back for that battle. |
| Role-based targeting profiles | on | Detects tank / two-hander / polearm / ranged / thrower / bannerman from gear and tunes focus fire, hit-chance preference, finishing wounded targets, formation, and avoiding being surrounded. |
| Hold the line in early rounds | on | Melee bros wait and hold formation for the first N rounds instead of charging, unless the enemy has more ranged units than we do. |
| Rounds to hold | 2 | The N above. |
| Support behaviors | on | Bandage / Field Triage / Field Treats on self and adjacent allies, Mark Target on enemies your allies are fighting, sergeant and priest auras. |
| Debug logging | off | Writes decisions to `Documents\Battle Brothers\log.html`. Combine with Autopilot's own "Verbose AI". |

Always on: the AI learns Legends skills it previously ignored (Hew, Halberd Smite, Haftstrike,
Heartseeker, Run Through, Double Swing, Cascade, Piercing Shot/Bolt, sling shots, Staffwall,
Staff Riposte, Fortify, Second Wind, disarms, Kick, Buckler Bash, Grapple, Tackle, and more).

## Troubleshooting

If a bro does something dumb, turn one toggle off and play another battle. If the game logs an
error mentioning `autopilot expert`, send the relevant lines from `log.html`.
