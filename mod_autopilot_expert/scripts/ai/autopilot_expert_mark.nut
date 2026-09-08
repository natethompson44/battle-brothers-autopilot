// Legends "Mark Target": 2 AP, range 4, -10 defense and extra damage taken on the target.
// Expert use: mark the enemy your allies are already fighting, preferably a wounded one.
this.autopilot_expert_mark <- this.inherit("scripts/ai/tactical/behavior", {
    m = {
        Skill = null,
        TargetTile = null
    },
    function create()
    {
        this.m.ID = ::Const.AI.Behavior.ID.APX_Mark;
        this.m.Order = ::Const.AI.Behavior.Order.APX_Mark;
        this.behavior.create();
    }

    function onEvaluate( _entity )
    {
        this.m.Skill = null;
        this.m.TargetTile = null;
        if (_entity.getActionPoints() < ::Const.Movement.AutoEndTurnBelowAP) return ::Const.AI.Behavior.Score.Zero;
        if (_entity.getMoraleState() == ::Const.MoraleState.Fleeing) return ::Const.AI.Behavior.Score.Zero;

        local skill = _entity.getSkills().getSkillByID("actives.legend_mark_target");
        if (skill == null || !skill.isUsable() || !skill.isAffordable()) return ::Const.AI.Behavior.Score.Zero;

        local myTile = _entity.getTile();
        local f = ::AutopilotExpert.scan(_entity);
        local bestTile = null, bestValue = 0.0;
        foreach (e in f.enemies) {
            local tile = e.getTile();
            local d = myTile.getDistanceTo(tile);
            if (d > 4) continue;
            if (e.getSkills().hasSkill("effects.legend_marked_target")) continue;
            if (!skill.isUsableOn(tile, myTile)) continue;
            local adj = ::AutopilotExpert.alliesAdjacentTo(_entity, e);
            if (adj == 0 && d > 2) continue;
            local v = 0.5 + 0.35 * adj + 0.5 * (1.0 - e.getHitpointsPct());
            if (v > bestValue) {
                bestValue = v;
                bestTile = tile;
            }
        }
        if (bestTile == null) return ::Const.AI.Behavior.Score.Zero;

        this.m.Skill = skill;
        this.m.TargetTile = bestTile;
        local score = ::Const.AI.Behavior.Score.APX_Mark * this.getProperties().BehaviorMult[this.m.ID];
        score *= bestValue * this.getFatigueScoreMult(skill);
        ::AutopilotExpert.dbg(_entity.getName() + " mark candidate value=" + bestValue + " score=" + score);
        return score;
    }

    function onExecute( _entity )
    {
        if (::Const.AI.VerboseMode) {
            ::logInfo("* " + _entity.getName() + ": marks a target!");
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
