local def = ::KitPilot;
local mod = def.mh;

mod.hook("scripts/states/world_state", function (q) {
    // Loot has just landed in the stash.
    q.onCombatFinished = @(__original) function () {
        __original();
        try {
            def.sweep("combat finished");
        } catch (e) {
            ::logError("kit pilot: " + e);
        }
    }
    // Shown again after battles, town screens (hiring, buying), events, campaign start.
    q.onShow = @(__original) function () {
        __original();
        try {
            def.sweep("world shown");
        } catch (e) {
            ::logError("kit pilot: " + e);
        }
    }
})
