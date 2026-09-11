// Kit Pilot - equips the company from the stash. The "Kit up" button on the character screen (or
// K on a keyboard) runs one sweep and shows a report of what moved to whom; optionally it also
// runs on its own after battles and town visits. Uses the same equip / unequip functions the inventory
// screen uses; nothing is created or destroyed, items only move between the stash and the bros.
local def = ::KitPilot <- {
    ID = "mod_kit_pilot"
    Name = "Kit Pilot"
    Version = "1.2.0"
    ManualMarker = "!"         // a bro whose name ends with this is left alone
    MaxPasses = 3              // sweep passes so hand-me-downs cascade to the next bro
    function dbg(_msg) {
        if ("conf" in this && this.conf("debug")) ::logInfo("kit pilot: " + _msg);
    }
    function log(_msg) {
        ::logInfo("kit pilot: " + _msg);
    }
}

local mod = def.mh <- ::Hooks.register(def.ID, def.Version, def.Name);
mod.require("mod_msu >= 1.6.0");

mod.queue(">mod_legends", ">mod_msu", function () {
    def.msu <- ::MSU.Class.Mod(def.ID, def.Version, def.Name);
    def.conf <- function (_name) {
        return def.msu.ModSettings.getSetting(_name).getValue();
    }

    local page = def.msu.ModSettings.addPage("Kit Pilot");
    page.addElement(::MSU.Class.BooleanSetting("equip", true, "Equip bros from the stash",
        "Fill empty weapon, shield, armor, helmet and quiver slots from the stash, by the bro's role. "
        + "Veterans are served first, so what they take off goes to the next bro down. "
        + "Run it with the Kit up button on the character screen (or K on a keyboard); a report then lists every change."));
    page.addElement(::MSU.Class.BooleanSetting("auto", false, "Also run automatically",
        "Run a sweep on its own after every battle and whenever the world map is shown again "
        + "(leaving a town, closing an event). Off: only when you press the button."));
    page.addElement(::MSU.Class.BooleanSetting("upgrade", true, "Upgrade worn gear",
        "Also replace a worn item with a clearly better one from the stash (about 15-20% better). "
        + "The old item goes back to the stash. Named items a bro already wears are never taken off him."));
    page.addElement(::MSU.Class.BooleanSetting("recruitsTwoHanded", false, "Unarmed recruits get a two-hander",
        "A recruit with nothing in hand normally gets a one-hander and a shield. Turn this on to hand out "
        + "two-handers instead. Recruits with ranged talent get a bow or crossbow either way."));
    page.addElement(::MSU.Class.RangeSetting("minFatigue", 50, 30, 90, 5, "Fatigue to keep after armor",
        "Armor and helmets are only put on while the bro keeps at least this much maximum fatigue. "
        + "Archers keep 10 more. Bros with Nimble stay in light armor regardless."));
    page.addElement(::MSU.Class.BooleanSetting("skipAvatar", false, "Leave my character manual",
        "Never touch the player character's equipment."));
    page.addElement(::MSU.Class.BooleanSetting("debug", false, "Debug logging",
        "Also write every sweep and every rejected candidate to log.html. Every change is always logged as "
        + "'kit pilot: <name> ...'. A bro whose name ends with '" + def.ManualMarker + "' is always left alone."));

    ::include("kit_pilot/roles");
    ::include("kit_pilot/items");
    ::include("kit_pilot/core");
    ::include("kit_pilot/hooks");
    ::Hooks.registerJS("ui/mods/kit_pilot.js");
    ::Hooks.registerCSS("ui/mods/kit_pilot.css");

    ::logInfo("kit pilot: loaded " + def.Version);
})
