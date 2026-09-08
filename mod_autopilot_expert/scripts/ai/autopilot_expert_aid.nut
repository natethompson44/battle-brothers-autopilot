// First aid from Legends: Bandage (self or adjacent, stops bleeding / fresh cut injuries),
// Field Triage (heal adjacent ally, costs medicine), Field Treats (morale, costs food).
// Target validity is delegated to each skill's own isUsableOn(), which runs its onVerifyTarget().
this.autopilot_expert_aid <- this.inherit("scripts/ai/tactical/behavior", {
    m = {
        Skill = null,
        TargetTile = null
    },
    function create()
    {
        this.m.ID = ::Const.AI.Behavior.ID.APX_Aid;
        this.m.Order = ::Const.AI.Behavior.Order.APX_Aid;
        this.behavior.create();
    }

    function onEvaluate( _entity )
    {
        this.m.Skill = null;
        this.m.TargetTile = null;
        if (_entity.getActionPoints() < ::Const.Movement.AutoEndTurnBelowAP) return ::Const.AI.Behavior.Score.Zero;
        if (_entity.getMoraleState() == ::Const.MoraleState.Fleeing) return ::Const.AI.Behavior.Score.Zero;

        local skills = _entity.getSkills();
        local myTile = _entity.getTile();
        local f = ::AutopilotExpert.scan(_entity);
        local best = null, bestTile = null, bestValue = 0.0;

        local bandage = skills.getSkillByID("actives.legend_bandage");
        if (bandage != null && bandage.isUsable() && bandage.isAffordable()) {
            local candidates = [_entity];
            candidates.extend(f.adjacentAllies);
            foreach (t in candidates) {
                local tile = t.getTile();
                if (!bandage.isUsableOn(tile, myTile)) continue;
                local v = 1.2 + (1.0 - t.getHitpointsPct()) * 2.0;
                if (v > bestValue) {
                    bestValue = v;
                    best = bandage;
                    bestTile = tile;
                }
            }
        }

        local triage = skills.getSkillByID("actives.legend_field_triage");
        if (triage != null && triage.isUsable() && triage.isAffordable()) {
            foreach (t in f.adjacentAllies) {
                if (t.getHitpointsPct() >= 0.6) continue;
                local tile = t.getTile();
                if (!triage.isUsableOn(tile, myTile)) continue;
                local v = 0.8 + (1.0 - t.getHitpointsPct()) * 2.0;
                if (v > bestValue) {
                    bestValue = v;
                    best = triage;
                    bestTile = tile;
                }
            }
        }

        local treats = skills.getSkillByID("actives.legend_field_treats");
        if (treats != null && treats.isUsable() && treats.isAffordable()) {
            foreach (t in f.adjacentAllies) {
                if (t.getMoraleState() >= ::Const.MoraleState.Steady) continue;
                local tile = t.getTile();
                if (!treats.isUsableOn(tile, myTile)) continue;
                local v = 0.9;
                if (v > bestValue) {
                    bestValue = v;
                    best = treats;
                    bestTile = tile;
                }
            }
        }

        if (best == null) return ::Const.AI.Behavior.Score.Zero;

        this.m.Skill = best;
        this.m.TargetTile = bestTile;
        local score = ::Const.AI.Behavior.Score.APX_Aid * this.getProperties().BehaviorMult[this.m.ID];
        score *= bestValue * this.getFatigueScoreMult(best);
        ::AutopilotExpert.dbg(_entity.getName() + " aid candidate " + best.getID() + " value=" + bestValue + " score=" + score);
        return score;
    }

    function onExecute( _entity )
    {
        if (::Const.AI.VerboseMode) {
            ::logInfo("* " + _entity.getName() + ": uses " + this.m.Skill.getName() + "!");
        }
        this.m.Skill.use(this.m.TargetTile);
        if (!_entity.isHiddenToPlayer()) {
            this.getAgent().declareAction();
        }
        this.m.Skill = null;
        this.m.TargetTile = null;
        return true;
    }
});
