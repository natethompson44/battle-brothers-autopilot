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
| Hold the line in early rounds | on | Melee bros wait and hold formation for the first N rounds instead of charging, as long as the enemy is actually coming closer round over round and does not have more ranged units than we do. Fleeing enemies and non-combatants do not count. |
| Rounds to hold | 2 | The N above. |
| Support behaviors | on | Bandage / Field Triage / Field Treats on self and adjacent allies, Mark Target on enemies your allies are fighting, sergeant and priest auras. |
| Debug logging | off | Writes decisions to `Documents\Battle Brothers\log.html`. Combine with Autopilot's own "Verbose AI". |

Always on: the AI learns Legends skills it previously ignored (Hew, Halberd Smite, Haftstrike,
Heartseeker, Run Through, Double Swing, Cascade, Piercing Shot/Bolt, sling shots, Staffwall,
Staff Riposte, Fortify, Second Wind, disarms, Kick, Buckler Bash, Grapple, Tackle, and more).

## Blink (Company Starts' Wolfeo)

A bro with the Blink skill is treated as a raider, not a line unit: he never holds the line and
the AI plans his turn around the blink.

- **Strike**: blink next to the best target in reach and swing. If the target is too far for a
  straight blink he walks first, as long as walk + blink + swing fit his action points (seven
  tiles with 12 AP and a greatsword). Archers and wounded enemies come first. From an engaged
  position he only leaves when the new target is clearly worth it, or when three or more enemies
  are on him.
- **Retreat**: after the swing, with action points left for a blink but not for another swing,
  he blinks out if enemies are closing in and he has the fatigue to swing again next turn.
- **Approach**: when nothing is in reach this turn he walks and then blinks toward the enemy,
  landing with nobody adjacent, so he is in striking range a turn earlier than by walking.
- **Escape**: badly hurt with an enemy adjacent, he blinks to a tile with no enemy next to it,
  preferably near our own line. After an escape or a retreat he stays out for the rest of that
  turn instead of walking back in with the leftover action points.

With Debug logging on, every decision (and every reason for not blinking) is written to
`log.html` as `autopilot expert: <name> blink: ...`.

## Troubleshooting

If a bro does something dumb, turn one toggle off and play another battle. If the game logs an
error mentioning `autopilot expert`, send the relevant lines from `log.html`.
