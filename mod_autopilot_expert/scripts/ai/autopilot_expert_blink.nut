// Blink (Company Starts' Wolfeo). He is a raider, not a line unit: get to the enemy fast, hit the
// target that matters, and be gone before the mob closes. Five modes, picked in this order:
//
//   escape    badly hurt (or mobbed and hurting) with an enemy adjacent: blink to a tile with no
//             enemy next to it, preferably near our own line.
//   strike    blink next to a good target and hit it this turn. Walks first when that gets the
//             blink to a target it could not reach from where he stands (walk + blink + attack
//             must fit the AP). From an engaged position only when the new target is clearly
//             worth leaving the current one for, or when he is mobbed (3+ adjacent).
//   retreat   the "out" of in-and-out: attacked already, not enough AP for another swing but
//             enough for a blink, and enemies around: blink out instead of standing there.
//   approach  no target in reach this turn: walk, then blink, closing far more ground than the
//             plain engage behavior ever could, and land out of anyone's reach.
//
// Plans that include walking are executed like Autopilot's step-and-hit: travel first, blink when
// the walk ends, then hand the attack to the normal attack behaviors (he is adjacent with the AP
// for it). One strike or approach per turn; retreat and escape can follow a strike.
this.autopilot_expert_blink <- this.inherit("scripts/ai/tactical/behavior", {
    m = {
        Skill = null,
        StepTile = null,      // walk here first (null = blink from where we stand)
        TargetTile = null,    // blink destination
        Mode = null,
        Phase = 0,            // 0 = start, 1 = travelling, 2 = travel done
        BlinkedThisTurn = false,
        TurnAP = -1,
        TurnRound = -1
    },
    function create()
    {
        this.m.ID = ::Const.AI.Behavior.ID.APX_Blink;
        this.m.Order = ::Const.AI.Behavior.Order.APX_Blink;
        this.behavior.create();
    }

    function onTurnStarted()
    {
        this.m.BlinkedThisTurn = false;
        this.m.TurnAP = -1;
        this.m.TurnRound = -1;
    }

    function dbg( _entity, _msg )
    {
        ::AutopilotExpert.dbg(_entity.getName() + " blink: " + _msg);
    }

    function zero( _entity, _why )
    {
        this.dbg(_entity, "no: " + _why);
        return ::Const.AI.Behavior.Score.Zero;
    }

    // Cheapest usable melee attack, ignoring whether we can pay for it right now.
    function pickAttack( _entity )
    {
        local best = null;
        foreach (s in _entity.getSkills().m.Skills) {
            if (s == null || !s.m.IsActive || !s.m.IsAttack || !s.m.IsWeaponSkill || !s.m.IsTargeted || s.m.IsRanged) continue;
            if (!s.isUsable()) continue;
            if (best == null || s.getActionPointCost() < best.getActionPointCost()
                || (s.getActionPointCost() == best.getActionPointCost() && s.getFatigueCost() < best.getFatigueCost())) {
                best = s;
            }
        }
        return best;
    }

    // What a target is worth to a raider: wounded and ranged first, a small bonus for something
    // our own line is already fighting.
    function targetValue( _entity, _e )
    {
        local v = 1.0 - _e.getHitpointsPct();
        if (_e.isArmedWithRangedWeapon()) v += 0.8;
        if (_e.getMoraleState() == ::Const.MoraleState.Fleeing) v -= 0.3;
        v += 0.15 * ::AutopilotExpert.alliesAdjacentTo(_entity, _e);
        return v;
    }

    function stepCost( _entity )
    {
        local costs = _entity.getActionPointCosts();
        local c = 99;
        foreach (v in costs) if (v > 0 && v < c) c = v;
        return c == 99 ? 2 : c;
    }

    function buildSettings( _entity, _navigator )
    {
        local s = _navigator.createSettings();
        s.ActionPointCosts = _entity.getActionPointCosts();
        s.FatigueCosts = _entity.getFatigueCosts();
        s.FatigueCostFactor = 1.0;
        s.ActionPointCostPerLevel = _entity.getLevelActionPointCost();
        s.FatigueCostPerLevel = _entity.getLevelFatigueCost();
        s.MaxLevelDifference = _entity.getMaxTraversibleLevels();
        s.AllowZoneOfControlPassing = false;
        s.ZoneOfControlCost = ::Const.AI.Behavior.ZoneOfControlAPPenalty;
        s.AlliedFactions = _entity.getAlliedFactions();
        s.Faction = _entity.getFaction();
        return s;
    }

    // Empty tiles within _radius of _center, with how the enemy sits around each of them.
    function collectTiles( _entity, _center, _radius, _enemies )
    {
        local ret = [];
        local size = ::Tactical.getMapSize();
        local cx = _center.SquareCoords.X, cy = _center.SquareCoords.Y;
        for (local x = ::Math.max(0, cx - _radius); x <= ::Math.min(size.X - 1, cx + _radius); x++) {
            for (local y = ::Math.max(0, cy - _radius); y <= ::Math.min(size.Y - 1, cy + _radius); y++) {
                local tile = ::Tactical.getTileSquare(x, y);
                local isMine = tile.ID == _center.ID;
                if (!isMine && !tile.IsEmpty) continue;
                local d = _center.getDistanceTo(tile);
                if (d > _radius) continue;
                local info = { tile = tile, dist = d, adj = 0, near = 0, nearest = 99, target = null, targetValue = -99.0, nearestRanged = false };
                foreach (e in _enemies) {
                    local ed = e.getTile().getDistanceTo(tile);
                    if (ed == 1) {
                        info.adj++;
                        local v = this.targetValue(_entity, e);
                        if (v > info.targetValue) {
                            info.targetValue = v;
                            info.target = e;
                        }
                    }
                    if (ed <= 2) info.near++;
                    if (ed < info.nearest) {
                        info.nearest = ed;
                        info.nearestRanged = e.isArmedWithRangedWeapon();
                    }
                }
                ret.push(info);
            }
        }
        return ret;
    }

    // Value of blinking onto _t to strike. Null when it is not a strike tile.
    function strikeValue( _t )
    {
        if (_t.adj < 1 || _t.adj > 2) return null;
        // 1 + target worth, minus company: a second adjacent enemy and anything else within two.
        return 1.0 + _t.targetValue - 0.35 * (_t.adj - 1) - 0.15 * (_t.near - _t.adj);
    }

    // Value of blinking onto _t to get away: nobody adjacent, friends near, enemies far.
    function safeValue( _t, _allies )
    {
        if (_t.adj > 0) return null;
        local alliesNear = 0;
        foreach (a in _allies) if (a.getTile().getDistanceTo(_t.tile) <= 2) alliesNear++;
        local v = 1.0 + 0.2 * alliesNear + 0.1 * ::Math.min(5, _t.nearest);
        if (_t.nearest >= 3) v += 0.3;
        return v;
    }

    // Best blink from _from among _tiles, by _valueFn (returns value or null). Skips the tile
    // we stand on and anything the skill refuses.
    function bestBlink( _skill, _from, _range, _tiles, _valueFn )
    {
        local best = null, bestValue = 0.0;
        foreach (t in _tiles) {
            if (t.tile.ID == _from.ID || !t.tile.IsEmpty) continue;
            local d = _from.getDistanceTo(t.tile);
            if (d < 1 || d > _range) continue;
            local v = _valueFn(t);
            if (v == null || v <= bestValue) continue;
            if (!_skill.isUsableOn(t.tile, _from)) continue;
            bestValue = v;
            best = t;
        }
        return best == null ? null : { tile = best.tile, value = bestValue, info = best };
    }

    // Best (walk to P, blink to T) plan. Candidate P tiles are ranked by their best blink, then
    // pathed in that order until one fits the AP budget. _budget is the AP the walk may use.
    function bestPlan( _entity, _skill, _range, _myTile, _tiles, _budget, _valueFn )
    {
        local direct = this.bestBlink(_skill, _myTile, _range, _tiles, _valueFn);
        local best = direct == null ? null : { step = null, tile = direct.tile, value = direct.value, info = direct.info, cost = 0 };
        local steps = _budget / this.stepCost(_entity);
        if (steps < 1) return best;
        if (_myTile.getZoneOfControlCountOtherThan(_entity.getAlliedFactions()) > 0) return best;
        if (_entity.getCurrentProperties().IsRooted) return best;

        local allied = _entity.getAlliedFactions();
        local candidates = [];
        foreach (p in _tiles) {
            if (p.dist < 1 || p.dist > steps) continue;
            if (p.tile.IsOccupiedByActor) continue;
            if (p.tile.getZoneOfControlCountOtherThan(allied) > 0) continue;
            local b = this.bestBlink(_skill, p.tile, _range, _tiles, _valueFn);
            if (b == null) continue;
            // Walking costs a little so a direct blink wins ties.
            local v = b.value - 0.06 * p.dist;
            if (best != null && v <= best.value) continue;
            candidates.push({ step = p.tile, tile = b.tile, value = v, info = b.info, dist = p.dist });
        }
        if (candidates.len() == 0) return best;
        candidates.sort(@(a, b) a.value < b.value ? 1 : (a.value > b.value ? -1 : 0));

        local navigator = ::Tactical.getNavigator();
        local settings = this.buildSettings(_entity, navigator);
        local fat = _entity.getFatigueMax() - _entity.getFatigue();
        local tried = 0;
        foreach (c in candidates) {
            if (tried++ >= 12) break;
            if (best != null && c.value <= best.value) break;
            if (!navigator.findPath(_myTile, c.step, settings, 0)) continue;
            local cost = navigator.getCostForPath(_entity, settings, _budget, fat);
            if (!cost.IsComplete || cost.End.ID != c.step.ID) continue;
            if (cost.ActionPointsRequired > _budget) continue;
            c.cost <- cost.ActionPointsRequired;
            best = c;
            break;
        }
        return best;
    }

    function onEvaluate( _entity )
    {
        this.m.Skill = null;
        this.m.StepTile = null;
        this.m.TargetTile = null;
        this.m.Mode = null;
        this.m.Phase = 0;

        local ap = _entity.getActionPoints();
        // Fallback for the once-per-turn bookkeeping in case onTurnStarted does not reach us:
        // a new round, or a full AP bar, means a new turn.
        local round = ::AutopilotExpert.getRound();
        if (round != this.m.TurnRound || (ap >= _entity.getActionPointsMax() && this.m.TurnAP != ap)) {
            this.m.BlinkedThisTurn = false;
            this.m.TurnRound = round;
            this.m.TurnAP = ap;
        }
        if (ap < ::Const.Movement.AutoEndTurnBelowAP) return ::Const.AI.Behavior.Score.Zero;
        if (_entity.getMoraleState() == ::Const.MoraleState.Fleeing) return ::Const.AI.Behavior.Score.Zero;

        local skill = _entity.getSkills().getSkillByID("actives.wolfeo_blink");
        if (skill == null || !skill.isUsable() || !skill.isAffordable()) return ::Const.AI.Behavior.Score.Zero;

        local myTile = _entity.getTile();
        local f = ::AutopilotExpert.scan(_entity);
        if (f.enemies.len() == 0) return ::Const.AI.Behavior.Score.Zero;

        local blinkAP = skill.getActionPointCost();
        local range = skill.getMaxRange();
        local attack = this.pickAttack(_entity);
        local fatLeft = _entity.getFatigueMax() - _entity.getFatigue();
        local attackAP = attack == null ? 99 : attack.getActionPointCost();
        local attackFat = attack == null ? 0 : attack.getFatigueCost();
        local canStrike = attack != null && ap >= blinkAP + attackAP && fatLeft >= skill.getFatigueCost() + attackFat;
        local hp = _entity.getHitpointsPct();
        local stepBudget = ap - blinkAP - (attack == null ? 0 : attackAP);

        // Everything within walking + blink reach.
        local reach = range + ::Math.max(0, (ap - blinkAP) / this.stepCost(_entity));
        local tiles = this.collectTiles(_entity, myTile, reach, f.enemies);
        local here = null;
        foreach (t in tiles) if (t.tile.ID == myTile.ID) { here = t; break; }
        if (here == null) return ::Const.AI.Behavior.Score.Zero;
        local adjacent = here.adj;
        local mobbed = adjacent >= 3;

        local self = this;
        local strikeFn = function (_t) { return self.strikeValue(_t); };
        local safeFn = function (_t) { return self.safeValue(_t, f.allies); };
        local plan = null, mode = null, modeMult = 1.0;

        if (adjacent >= 1 && (hp < 0.35 || (mobbed && hp < 0.5))) {
            plan = this.bestPlan(_entity, skill, range, myTile, tiles, 0, safeFn);
            if (plan == null) return this.zero(_entity, "hurt, no safe tile in reach");
            mode = "escape";
            modeMult = 1.6;
        }
        else if (adjacent >= 1) {
            if (canStrike && !this.m.BlinkedThisTurn) {
                plan = this.bestPlan(_entity, skill, range, myTile, tiles, 0, strikeFn);
                // Leaving a fight costs the second swing we would get by staying. Only worth it
                // when the new target is clearly better, or when we are being mobbed.
                local stay = 1.0 + here.targetValue;
                if (plan != null && !mobbed && plan.value < stay + 0.5) {
                    this.dbg(_entity, "engaged, staying (blink " + plan.value + " vs stay " + stay + ")");
                    plan = null;
                }
                if (plan != null) {
                    mode = "strike";
                    modeMult = mobbed ? 1.4 : 1.2;
                }
            }
            if (plan == null && mobbed && ap >= blinkAP) {
                plan = this.bestPlan(_entity, skill, range, myTile, tiles, 0, safeFn);
                if (plan != null) {
                    mode = "escape";
                    modeMult = 1.5;
                }
            }
            if (plan == null && ap >= blinkAP && (attack == null || ap < attackAP || fatLeft < attackFat)) {
                // Swung already (or cannot swing). Get out if anyone is closing in, but keep the
                // fatigue to swing next turn.
                local threatened = here.near >= 2 || hp < 0.6;
                local recovery = _entity.getCurrentProperties().FatigueRecoveryRate;
                local fatAfter = fatLeft - skill.getFatigueCost() + recovery;
                if (!threatened) return this.zero(_entity, "spent, but nobody else is near");
                if (fatAfter < attackFat) return this.zero(_entity, "spent, too tired to blink out and still swing next turn");
                plan = this.bestPlan(_entity, skill, range, myTile, tiles, 0, safeFn);
                if (plan == null) return this.zero(_entity, "spent, no safe tile in reach");
                mode = "retreat";
                modeMult = 1.2;
            }
            if (plan == null) return ::Const.AI.Behavior.Score.Zero;
        }
        else {
            if (this.m.BlinkedThisTurn) return this.zero(_entity, "already blinked this turn");
            if (canStrike) {
                plan = this.bestPlan(_entity, skill, range, myTile, tiles, stepBudget, strikeFn);
                if (plan != null) mode = "strike";
            }
            if (plan == null && ap >= blinkAP && f.nearest > 2) {
                // Close the distance: walk what we can, then blink, landing with nobody adjacent.
                local nearestNow = f.nearest;
                local approachFn = function (_t) {
                    if (_t.adj > 0 || _t.nearest < 2) return null;
                    local closing = nearestNow - _t.nearest;
                    if (closing < 2) return null;
                    return 1.0 + 0.1 * closing + (_t.nearestRanged ? 0.2 : 0.0);
                };
                plan = this.bestPlan(_entity, skill, range, myTile, tiles, ap - blinkAP, approachFn);
                if (plan != null) {
                    mode = "approach";
                    modeMult = 0.8;
                }
            }
            if (plan == null) return this.zero(_entity, canStrike ? "no target within reach" : "not enough AP to blink and swing");
        }

        this.m.Skill = skill;
        this.m.StepTile = plan.step;
        this.m.TargetTile = plan.tile;
        this.m.Mode = mode;
        local score = ::Const.AI.Behavior.Score.APX_Blink * this.getProperties().BehaviorMult[this.m.ID];
        score *= plan.value * modeMult * this.getFatigueScoreMult(skill);
        this.dbg(_entity, mode + (plan.step != null ? " after a " + plan.step.getDistanceTo(myTile) + "-tile walk" : "")
            + ((plan.info.target != null) ? " at " + plan.info.target.getName() : "")
            + " value=" + plan.value + " score=" + score);
        return score;
    }

    function onExecute( _entity )
    {
        local navigator = ::Tactical.getNavigator();
        if (this.m.Phase == 0) {
            this.m.Phase = 2;
            if (this.m.StepTile != null && this.m.StepTile.ID != _entity.getTile().ID) {
                local settings = this.buildSettings(_entity, navigator);
                if (!navigator.findPath(_entity.getTile(), this.m.StepTile, settings, 0)) {
                    ::logWarning("autopilot expert: " + _entity.getName() + " blink: path to step tile vanished, skipping");
                    return this.clearPlan();
                }
                if ("adjustCameraToTarget" in this.getAgent()) this.getAgent().adjustCameraToTarget(this.m.StepTile);
                this.m.Phase = 1;
                return false;
            }
        }
        if (this.m.Phase == 1) {
            if (navigator.travel(_entity, _entity.getActionPoints(), _entity.getFatigueMax() - _entity.getFatigue())) return false;
            this.m.Phase = 2;
            if (_entity.getTile().ID != this.m.StepTile.ID) {
                ::logWarning("autopilot expert: " + _entity.getName() + " blink: walk ended short of the step tile, not blinking");
                return this.clearPlan();
            }
            return false;
        }

        local skill = this.m.Skill;
        local target = this.m.TargetTile;
        if (skill == null || target == null || !skill.isAffordable() || !skill.isUsableOn(target)) {
            ::logWarning("autopilot expert: " + _entity.getName() + " blink: target tile no longer usable, skipping");
            return this.clearPlan();
        }
        if (::Const.AI.VerboseMode) {
            ::logInfo("* " + _entity.getName() + ": blinks (" + this.m.Mode + ")!");
        }
        skill.use(target);
        this.m.BlinkedThisTurn = true;
        if (!_entity.isHiddenToPlayer()) {
            this.getAgent().declareAction();
        }
        return this.clearPlan();
    }

    function clearPlan()
    {
        this.m.Skill = null;
        this.m.StepTile = null;
        this.m.TargetTile = null;
        this.m.Mode = null;
        this.m.Phase = 0;
        return true;
    }
});
