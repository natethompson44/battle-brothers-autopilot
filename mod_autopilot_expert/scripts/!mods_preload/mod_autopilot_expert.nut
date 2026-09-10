// Autopilot Expert - companion mod for Suor's "Autopilot New".
// Adds: auto-engage AI at battle start, role-based targeting profiles, early-round line holding,
// Legends skill awareness for the AI, and a few support behaviors (bandage, triage, mark target,
// sergeant auras). Everything is a hook on top of autopilot; nothing overwrites game files.
local def = ::AutopilotExpert <- {
    ID = "mod_autopilot_expert"
    Name = "Autopilot Expert"
    Version = "1.2.0"
    Role = {
        Tank = "tank"
        Striker = "striker"
        Polearm = "polearm"
        Ranged = "ranged"
        Thrower = "thrower"
        Banner = "banner"
    }
    function isUnderAIControl(_actor) {
        return _actor != null && ("_autopilot" in _actor.m);
    }
    function dbg(_msg) {
        if (::Const.AI.VerboseMode || ("conf" in this && this.conf("debug"))) ::logInfo("autopilot expert: " + _msg);
    }
}

local mod = def.mh <- ::Hooks.register(def.ID, def.Version, def.Name);
mod.require("mod_autopilot_new >= 2.9.0", "mod_msu >= 1.6.0", "stdlib >= 2.5");

// Must run after autopilot (we wrap its functions) and after Legends (so its skills/effects exist).
mod.queue(">mod_autopilot_new", ">mod_legends", ">mod_msu", function () {
    def.msu <- ::MSU.Class.Mod(def.ID, def.Version, def.Name);
    def.conf <- function (_name) {
        return def.msu.ModSettings.getSetting(_name).getValue();
    }

    local page = def.msu.ModSettings.addPage("Autopilot Expert");

    page.addElement(::MSU.Class.BooleanSetting("autostart", true, "Auto-engage AI at battle start",
        "Hand every eligible bro to the AI as soon as the first player turn of a battle begins, "
        + "without the confirmation popup. Press V (cancel) at any time to take control back for the rest of that battle."));

    page.addElement(::MSU.Class.SettingsDivider("tacticsDiv"));
    page.addElement(::MSU.Class.SettingsTitle("tacticsTitle", "Tactics"));

    page.addElement(::MSU.Class.BooleanSetting("profiles", true, "Role-based targeting profiles",
        "Detect each bro's role from gear (shield tank, two-hander, polearm, ranged, thrower, bannerman) and tune "
        + "target priority and engagement: focus fire, prefer high hit chance, finish wounded targets, "
        + "hold formation, avoid getting surrounded."));
    page.addElement(::MSU.Class.BooleanSetting("holdline", true, "Hold the line in early rounds",
        "For the first rounds melee bros wait and hold formation instead of charging, unless the enemy "
        + "outguns us at range. Spearwall / shieldwall are favored while holding."));
    page.addElement(::MSU.Class.RangeSetting("holdrounds", 2, 0, 5, 1, "Rounds to hold",
        "How many rounds the line is held before the AI is allowed to advance freely."));

    page.addElement(::MSU.Class.SettingsDivider("supportDiv"));
    page.addElement(::MSU.Class.SettingsTitle("supportTitle", "Support"));

    page.addElement(::MSU.Class.BooleanSetting("support", true, "Support behaviors",
        "Let the AI use Legends support skills: Bandage / Field Triage / Field Treats on self and adjacent allies, "
        + "Mark Target on enemies your allies are fighting, and sergeant auras (Hold the Line, Push Forward, "
        + "Incoming, Coordinated Volleys, Guide Steps, Prayers, Drums)."));
    page.addElement(::MSU.Class.BooleanSetting("debug", false, "Debug logging",
        "Write role/profile decisions and support-skill choices to log.html."));

    // Register our behavior IDs (needs MSU). Scores are relative to a plain attack so the
    // weighted pick prefers a real attack when one is available.
    local attack = ::Const.AI.Behavior.Score.Attack;
    ::MSU.AI.addBehavior("APX_Aura", "APX.Aura", 42, attack * 0.9);
    ::MSU.AI.addBehavior("APX_Aid", "APX.Aid", 43, attack * 1.3);
    ::MSU.AI.addBehavior("APX_Mark", "APX.Mark", 44, attack * 0.7);
    ::MSU.AI.addBehavior("APX_Raise", "APX.Raise", 45, attack * 1.6);
    ::MSU.AI.addBehavior("APX_Kick", "APX.Kick", 46, attack * 1.2);
    ::MSU.AI.addBehavior("APX_Blink", "APX.Blink", 47, attack * 1.5);

    ::include("autopilot_expert/field");
    ::include("autopilot_expert/legends_skills");
    ::include("autopilot_expert/profiles");
    ::include("autopilot_expert/hooks/actor");
    ::include("autopilot_expert/hooks/player");
    ::include("autopilot_expert/hooks/turn_sequence_bar");
    ::include("autopilot_expert/hooks/tactical_state");

    ::logInfo("autopilot expert: loaded " + def.Version);
})
