# Kit Pilot

Equips the company from the stash automatically. Runs on the world map after every battle and
whenever the world screen is shown (leaving a town, closing an event, campaign start); never
during a fight. Items only move between the stash and the bros with the same equip and unequip
calls the inventory screen uses, so nothing is created, destroyed or sold.

## Requirements

- Modern Hooks, MSU (Mod Settings Utility) 1.6.0+
- Legends is optional

## Settings (Esc → Mod Options → Kit Pilot)

| Setting | Default | What it does |
|---|---|---|
| Equip bros from the stash | on | Fill empty weapon, shield, armor, helmet and quiver slots by role. Veterans (highest level) are served first, so what they take off goes down to the next bro. |
| Upgrade worn gear | on | Also replace a worn item with a clearly better one from the stash: about 20% more for weapons, 15% for shields and armor. The old item goes back to the stash. |
| Unarmed recruits get a two-hander | off | A recruit with nothing in hand gets a one-hander and a shield. On, he gets a two-hander instead. Recruits with ranged talent get a bow or crossbow either way. |
| Fatigue to keep after armor | 50 | Armor and helmets are only put on while the bro keeps at least this much maximum fatigue. Archers keep 10 more. Bros with Nimble stay under 15 fatigue of armor regardless. Brawny is accounted for. |
| Leave my character manual | off | Never touch the player character's equipment. |
| Debug logging | off | Also write every sweep and every rejected candidate to `log.html`. Every change is always logged as `kit pilot: <name>: <old> -> <new> (reason)`. |

**Per-bro opt-out:** rename a bro so his name ends with `!` and he is left alone entirely.

## Rules

- **Roles come from the weapon in hand:** one-hander + shield is a tank, one-hander alone a
  duelist, two-hander a striker, reach-2 two-hander a polearm, bow/crossbow/sling an archer.
  Bannermen, throwers and casters keep their weapons; only their armor is handled.
- **Unarmed recruits** become archers if they have two or more ranged-skill stars or clearly
  more ranged than melee skill, otherwise they go into the line (see the setting). If nothing of
  the right kind is in the stash, anything beats fists.
- **Weapons and shields** are ranked by crown value adjusted for condition. A weapon type the bro
  has the mastery perk for counts 35% more, the type he already holds 10% more, so nobody swaps a
  sword for an axe of the same tier.
- **Armor** is ranked by armor rating within the fatigue floor, body first, then helmet.
- **Archers** get a matching quiver and, if the bag has no melee weapon, the cheapest spare
  one-hander worth at least 100 crowns as a sidearm.
- **Named and legendary items** a bro already wears are never taken off him. Named items in the
  stash are handed out like anything else (they rank at the top).

## Not done (yet)

Selling. Deciding what is junk is the one call that cannot be undone, so the stash is left for you
to sell. The sweep makes that easier: after it, everything a bro could use is on a bro.
