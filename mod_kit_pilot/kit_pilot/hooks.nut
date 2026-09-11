local def = ::KitPilot;
local mod = def.mh;

local KEY_K = 21;   // the game's key codes: A = 11 ... K = 21 (Autopilot New uses the same table)

// The Kit up button (ui/mods/kit_pilot.js) calls this and shows the lines it returns.
mod.hook("scripts/ui/screens/character/character_screen", function (q) {
    q.onKitPilot <- function (_data = null) {
        return def.kitUpFromScreen();
    }
})

mod.hook("scripts/states/world_state", function (q) {
    // K on the world map, character screen open or not: one sweep, then a report.
    q.onKeyInput = @(__original) function (_key) {
        if (__original(_key)) return true;
        if (_key.getKey() == KEY_K && _key.getState() == 0 && _key.getModifier() != 1) {
            try {
                def.kitUp();
            } catch (e) {
                ::logError("kit pilot: " + e);
            }
            return true;
        }
        return false;
    }

    // Optional automatic sweeps. Loot has just landed in the stash ...
    q.onCombatFinished = @(__original) function () {
        __original();
        if (!def.conf("auto")) return;
        try {
            def.sweep("combat finished");
        } catch (e) {
            ::logError("kit pilot: " + e);
        }
    }
    // ... or the map is shown again after a town screen (hiring, buying), an event, campaign start.
    q.onShow = @(__original) function () {
        __original();
        if (!def.conf("auto")) return;
        try {
            def.sweep("world shown");
        } catch (e) {
            ::logError("kit pilot: " + e);
        }
    }
})
