local def = ::AutopilotExpert;
local mod = def.mh;

mod.hook("scripts/entity/tactical/player", function (q) {
    // Autopilot builds and installs the agent here; we tune it right after.
    q.enableAIControl = @(__original) function () {
        // Autopilot picks the ranged agent from isArmedWithRangedWeapon(); shadow it for a magic
        // staff with no spells so the bro gets the melee agent instead (see profiles.nut).
        local forceMelee = false;
        try { forceMelee = def.shouldForceMelee(this); } catch (e) {}
        if (forceMelee) {
            try {
                this.isArmedWithRangedWeapon <- function () { return false; };
                def.dbg(this.getName() + " has a magic staff but no spells, using melee AI");
            } catch (e) {
                forceMelee = false;
            }
        }
        try {
            __original();
        } catch (e) {
            if (forceMelee) delete this.isArmedWithRangedWeapon;
            throw e;
        }
        if (forceMelee) delete this.isArmedWithRangedWeapon;

        if (!def.isUnderAIControl(this)) return;
        local agent = this.getAIAgent();
        if (agent == null) return;
        try {
            def.setupAgent(this, agent);
        } catch (e) {
            ::logError("autopilot expert: agent setup failed for " + this.getName() + ": " + e);
        }
    }

    // Battle is over for this bro: clear our per-battle flags on the turn bar.
    q.onCombatFinished = @(__original) function () {
        __original();
        def.resetBattleState();
    }
})

def.resetBattleState <- function () {
    try {
        local tsb = ::Tactical.TurnSequenceBar;
        if (tsb == null) return;
        if ("apx_AutoStarted" in tsb.m) tsb.m.apx_AutoStarted = false;
        if ("apx_Round" in tsb.m) tsb.m.apx_Round = 0;
    } catch (e) {}
}
