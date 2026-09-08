// Sergeant / priest / musician auras from Legends: non-targeted buffs used on self.
// Each skill's own isUsable() already refuses re-casting while its effect is active.
this.autopilot_expert_aura <- this.inherit("scripts/ai/tactical/behavior", {
    m = {
        Skill = null
    },
    function create()
    {
        this.m.ID = ::Const.AI.Behavior.ID.APX_Aura;
        this.m.Order = ::Const.AI.Behavior.Order.APX_Aura;
        this.behavior.create();
    }

    function onEvaluate( _entity )
    {
        this.m.Skill = null;
        if (_entity.getActionPoints() < ::Const.Movement.AutoEndTurnBelowAP) return ::Const.AI.Behavior.Score.Zero;
        if (_entity.getMoraleState() == ::Const.MoraleState.Fleeing) return ::Const.AI.Behavior.Score.Zero;

        local skills = _entity.getSkills();
        local usable = [];
        foreach (id in ::AutopilotExpert.AuraSkills) {
            local s = skills.getSkillByID(id);
            if (s != null && s.isUsable() && s.isAffordable()) usable.push(s);
        }
        if (usable.len() == 0) return ::Const.AI.Behavior.Score.Zero;

        local f = ::AutopilotExpert.scan(_entity);
        local round = ::AutopilotExpert.getRound();
        local best = null, bestValue = 0.0;
        foreach (s in usable) {
            local v = this.valueOf(s.getID(), _entity, f, round);
            if (v > bestValue) {
                bestValue = v;
                best = s;
            }
        }
        if (best == null) return ::Const.AI.Behavior.Score.Zero;

        this.m.Skill = best;
        local score = ::Const.AI.Behavior.Score.APX_Aura * this.getProperties().BehaviorMult[this.m.ID];
        score *= bestValue * this.getFatigueScoreMult(best);
        ::AutopilotExpert.dbg(_entity.getName() + " aura candidate " + best.getID() + " value=" + bestValue + " score=" + score);
        return score;
    }

    // How much sense a given aura makes right now. 0 = don't.
    function valueOf( _id, _entity, _f, _round )
    {
        local myTile = _entity.getTile();
        local fightClose = _f.nearest <= 6;

        switch (_id) {
            case "actives.legend_hold_the_line":
                return (fightClose && _f.alliesWithin4 >= 2) ? 1.0 + 0.1 * _f.alliesWithin4 : 0.0;

            case "actives.legend_push_forward":
                return (fightClose && _f.alliesWithin4 >= 2) ? 0.9 + 0.1 * _f.alliesWithin4 : 0.0;

            case "actives.legend_incoming":
                return (_f.enemyRanged >= 2 && _f.alliesWithin4 >= 2) ? 1.2 : 0.0;

            case "actives.legend_coordinated_volleys":
                return (_f.allyRangedWithin4 >= 2) ? 0.9 + 0.1 * _f.allyRangedWithin4 : 0.0;

            case "actives.legend_guide_steps":
                return (_round <= 2 && _f.nearest > 4 && _f.alliesWithin4 >= 3) ? 0.8 : 0.0;

            case "actives.legend_prayer_of_faith":
                return (_f.nearest <= 4 && _f.adjacentAllies.len() >= 2) ? 0.8 + 0.1 * _f.adjacentAllies.len() : 0.0;

            case "actives.legend_drums_of_war": {
                local tired = 0;
                foreach (a in _f.allies) {
                    if (a.getTile().getDistanceTo(myTile) <= 8 && a.getFatiguePct() > 0.4) tired++;
                }
                return tired >= 2 ? 0.7 + 0.1 * tired : 0.0;
            }

            case "actives.legend_prayer_of_life": {
                local wound = 0.0;
                foreach (a in _f.adjacentAllies) {
                    if (a.getHitpointsPct() < 0.7) wound += 1.0 - a.getHitpointsPct();
                }
                return wound > 0.0 ? 0.8 + wound : 0.0;
            }

            case "actives.legend_drums_of_life": {
                local wound = 0.0;
                foreach (a in _f.allies) {
                    if (a.getTile().getDistanceTo(myTile) <= 8 && a.getHitpointsPct() < 0.7) wound += 1.0 - a.getHitpointsPct();
                }
                return wound > 0.3 ? 0.8 + wound : 0.0;
            }
        }
        return 0.0;
    }

    function onExecute( _entity )
    {
        if (::Const.AI.VerboseMode) {
            ::logInfo("* " + _entity.getName() + ": uses " + this.m.Skill.getName() + "!");
        }
        this.m.Skill.use(_entity.getTile());
        if (!_entity.isHiddenToPlayer()) {
            this.getAgent().declareAction();
        }
        this.m.Skill = null;
        return true;
    }
});
