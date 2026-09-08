local def = ::AutopilotExpert;
local mod = def.mh;

mod.hook("scripts/states/tactical_state", function (q) {
    // Belt and braces with player.onCombatFinished: reset per-battle flags when the battle ends.
    q.onBattleEnded = @(__original) function () {
        def.resetBattleState();
        __original();
    }
})
