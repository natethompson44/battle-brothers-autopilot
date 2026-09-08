local def = ::LevelupPilot;
local mod = def.mh;

// A bro gained a level. Outside battle spend it right away (training, events); inside battle
// leave it for the after-combat sweep so HP and skills don't change mid-fight.
mod.hook("scripts/entity/tactical/player", function (q) {
    q.updateLevel = @(__original) function () {
        __original();
        if (def.isInBattle()) return;
        if (!("World" in getroottable()) || ::World == null) return;
        try {
            if (this.isPlacedOnMap()) return;   // still on a tactical map for some reason
        } catch (e) {}
        if (!def.isInRoster(this)) return;
        try {
            def.process(this);
        } catch (e) {
            ::logError("levelup pilot: " + e);
        }
    }
})

mod.hook("scripts/states/world_state", function (q) {
    q.onCombatFinished = @(__original) function () {
        __original();
        def.sweep("combat finished");
    }
    // Shown again after battles, events, town screens, campaign start: catch anything pending.
    q.onShow = @(__original) function () {
        __original();
        def.sweep("world shown");
    }
})
