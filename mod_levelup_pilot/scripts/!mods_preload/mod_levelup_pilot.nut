// Level-Up Pilot - spends attribute level-ups and perk points automatically. Vanilla-first; Legends optional.
// Runs on the world map (after battles and whenever the world screen is shown), never mid-fight.
// Every pick goes through the same functions the character screen uses; nothing is overwritten.
local def = ::LevelupPilot <- {
    ID = "mod_levelup_pilot"
    Name = "Level-Up Pilot"
    Version = "1.1.0"
    PicksPerLevel = 3          // attributes raised per level-up, same as the character screen
    ManualMarker = "!"         // a bro whose name ends with this is left alone
    MaxIterations = 60         // safety cap per bro per sweep
    function dbg(_msg) {
        if ("conf" in this && this.conf("debug")) ::logInfo("levelup pilot: " + _msg);
    }
}

local mod = def.mh <- ::Hooks.register(def.ID, def.Version, def.Name);
mod.require("mod_msu >= 1.6.0");

// Vanilla-first. Legends is optional: if it is present its perk trees and constants are used.
mod.queue(">mod_legends", ">mod_msu", function () {
    def.msu <- ::MSU.Class.Mod(def.ID, def.Version, def.Name);
    def.conf <- function (_name) {
        return def.msu.ModSettings.getSetting(_name).getValue();
    }

    local page = def.msu.ModSettings.addPage("Level-Up Pilot");
    page.addElement(::MSU.Class.BooleanSetting("stats", true, "Auto-assign attribute points",
        "On every level-up raise the three attributes that fit the bro's role and talent stars."));
    page.addElement(::MSU.Class.BooleanSetting("perks", true, "Auto-assign perk points",
        "Spend perk points on a role-based build: weapon mastery, armor perk, then the staples. "
        + "Perks are permanent; turn this off if you want to build bros yourself."));
    page.addElement(::MSU.Class.BooleanSetting("skipAvatar", false, "Leave my character manual",
        "Never touch the player character's level-ups or perks."));
    page.addElement(::MSU.Class.BooleanSetting("debug", false, "Debug logging",
        "Write every pick and the reason for it to log.html. A bro whose name ends with '" + def.ManualMarker
        + "' is always left alone, with or without this."));

    ::include("levelup_pilot/perkapi");
    ::include("levelup_pilot/roles");
    ::include("levelup_pilot/stats");
    ::include("levelup_pilot/perks");
    ::include("levelup_pilot/core");
    ::include("levelup_pilot/hooks");

    ::logInfo("levelup pilot: loaded " + def.Version);
})
