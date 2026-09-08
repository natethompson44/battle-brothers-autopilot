// Legends Kick: 4 AP, no real damage, but a hit cancels the target's Shieldwall / Spearwall /
// Riposte and staggers it. Only worth using on an adjacent enemy that is actually in a stance,
// and only when an ally (or we) can then hit it. Never used as a plain attack.
this.autopilot_expert_kick <- this.inherit("scripts/ai/tactical/behavior", {
    m = {
        Skill = null,
        TargetTile = null,
        Stances = [
            "effects.shieldwall"
            "effects.spearwall"
            "effects.riposte"
            "effects.legend_staffwall"
            "effects.legend_fortify"
        ]
    },
    function create()
    {
        this.m.ID = ::Const.AI.Behavior.ID.APX_Kick;
        this.m.Order = ::Const.AI.Behavior.Order.APX_Kick;
        this.behavior.create();
    }

    function onEvaluate( _entity )
    {
        this.m.Skill = null;
        this.m.TargetTile = null;
        if (_entity.getActionPoints() < ::Const.Movement.AutoEndTurnBelowAP) return ::Const.AI.Behavior.Score.Zero;
        if (_entity.getMoraleState() == ::Const.MoraleState.Fleeing) return ::Const.AI.Behavior.Score.Zero;

        local skill = _entity.getSkills().getSkillByID("actives.legend_kick");
        if (skill == null || !skill.isUsable() || !skill.isAffordable()) return ::Const.AI.Behavior.Score.Zero;
        // Need AP left for a real attack afterwards, otherwise the kick just wastes the turn.
        if (_entity.getActionPoints() < skill.getActionPointCost() + 4) return ::Const.AI.Behavior.Score.Zero;

        local myTile = _entity.getTile();
        local f = ::AutopilotExpert.scan(_entity);
        local bestTile = null, bestValue = 0.0;
        foreach (e in f.enemies) {
            local tile = e.getTile();
            if (myTile.getDistanceTo(tile) != 1) continue;
            local inStance = false;
            foreach (id in this.m.Stances) {
                if (e.getSkills().hasSkill(id)) {
                    inStance = true;
                    break;
                }
            }
            if (!inStance) continue;
            if (e.getSkills().hasSkill("effects.staggered")) continue;
            if (!skill.isUsableOn(tile, myTile)) continue;
            local v = 1.0 + 0.3 * ::AutopilotExpert.alliesAdjacentTo(_entity, e);
            v *= skill.getHitchance(e) / 100.0;
            if (v > bestValue) {
                bestValue = v;
                bestTile = tile;
            }
        }
        if (bestTile == null) return ::Const.AI.Behavior.Score.Zero;

        this.m.Skill = skill;
        this.m.TargetTile = bestTile;
        local score = ::Const.AI.Behavior.Score.APX_Kick * this.getProperties().BehaviorMult[this.m.ID];
        score *= bestValue * this.getFatigueScoreMult(skill);
        ::AutopilotExpert.dbg(_entity.getName() + " kick candidate value=" + bestValue + " score=" + score);
        return score;
    }

    function onExecute( _entity )
    {
        if (::Const.AI.VerboseMode) {
            ::logInfo("* " + _entity.getName() + ": kicks a stance!");
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
