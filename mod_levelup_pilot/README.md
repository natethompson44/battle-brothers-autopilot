# Level-Up Pilot

Spends attribute level-ups and perk points automatically. Vanilla-first; if Legends is present its perk trees are used. Runs on the world map
after every battle and whenever the world screen is shown; never during a fight. Uses the same
game functions the character screen uses, so everything it does is exactly what you could have
clicked yourself.

## Requirements

- Modern Hooks, MSU (Mod Settings Utility) 1.6.0+
- Legends is optional

## Settings (Esc → Mod Options → Level-Up Pilot)

| Setting | Default | What it does |
|---|---|---|
| Auto-assign attribute points | on | Raises the three attributes that fit the bro's role, weighted by roll size and talent stars. Never raises a capped attribute. Nudges Resolve while it is below 45. |
| Auto-assign perk points | on | Picks perks from a role-based wish list: Student if level 3 or lower, weapon mastery for the weapon in hand, Nimble or Battle Forged by the armor worn, then the role's staples, then generic staples, then the cheapest sane perk in the tree so the next tier unlocks. |
| Leave my character manual | off | Never touches the player character. |
| Debug logging | off | Writes every pick and why to `log.html`. |

**Per-bro opt-out:** rename a bro so his name ends with `!` and he is left alone entirely.

## Roles (from what the bro is holding)

Tank (one-hander + shield), Duelist (one-hander, no shield), Striker (two-hander), Polearm,
Archer (bow, crossbow, sling, handgonne), Thrower, Caster (magic staff or necromancy/summoning),
Bannerman (has Rally the Troops). Roles are re-read each time, so changing a bro's kit changes
what he gets next.

Camp, trade, horse, profession and stealth perks are never picked automatically.
