local def = ::AutopilotExpert;
local mod = def.mh;

mod.hook("scripts/ui/screens/tactical/modules/turn_sequence_bar/turn_sequence_bar", function (q) {
    q.m.apx_AutoStarted <- false;
    q.m.apx_Round <- 0;

    q.initNextRound = @(__original) function () {
        __original();
        this.m.apx_Round++;
    }

    // Same thing autopilot's AI button does after its "Turn control over to the AI?" popup.
    q.apx_engageAI <- function () {
        this.cancelAutoActions(false);
        this.m.IsOnAI = true;
        this.m.JSHandle.call("showStatsPanel", false);
        local n = 0;
        foreach (e in this.m.AllEntities) {
            if (this.canAuto(e) || def.canAutoAlly(e)) {
                def.enableAnyAlly(e);
                e.getAIAgent().onTurnStarted();
                n++;
            }
        }
        ::logInfo("autopilot expert: auto-engaged AI for " + n + " units");
    }

    // While on AI, anything that joins the player's side later (summons, raised undead, pets,
    // reinforcements) gets handed over on its first turn instead of dropping to manual control.
    q.apx_engageLateAlly <- function (_e) {
        if (!this.m.IsOnAI || _e == null || def.isUnderAIControl(_e)) return;
        if (!(this.canAuto(_e) || def.canAutoAlly(_e))) return;
        try {
            def.enableAnyAlly(_e);
            _e.getAIAgent().onTurnStarted();
        } catch (err) {
            ::logError("autopilot expert: could not enable AI for " + _e.getName() + ": " + err);
        }
    }

    // V / cancel: Autopilot only restores "player" objects; restore our generic allies too.
    q.cancelAutoActions = @(__original) function (_cancelIgnorance = true) {
        __original(_cancelIgnorance);
        foreach (e in this.m.AllEntities) {
            if (def.isUnderAIControl(e) && ("generic" in e.m._autopilot)) def.cancelGenericAI(e);
        }
    }

    // First time a human-controlled bro gets the turn in a battle: hand over to the AI.
    // Mirrors the manual flow (player presses Q while a bro is active), just without the popup.
    q.onEntityEnteredFirstSlotFully = @(__original) function (_entityId) {
        __original(_entityId);
        // Once the battle is decided the bros are released by Autopilot; don't grab them again
        // while the last enemies run off the map.
        if (("IsBattleEnded" in this.m) && this.m.IsBattleEnded) return;
        local entry = this.findEntityByID(this.m.CurrentEntities, _entityId);
        if (entry == null) return;
        local e = entry.entity;
        if (this.m.apx_AutoStarted) {
            this.apx_engageLateAlly(e);
            return;
        }
        if (!def.conf("autostart")) return;
        // canAuto() below already fails if the bro is not human-controlled (i.e. AI already on).
        if (e == null || !e.isPlayerControlled() || !this.canAuto(e)) return;
        this.m.apx_AutoStarted = true;
        try {
            this.apx_engageAI();
        } catch (err) {
            ::logError("autopilot expert: auto-engage failed: " + err);
        }
    }
})
