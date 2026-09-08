// Legends necromancy: Raise Undead on a resurrectable corpse tile, and Possession (extra AP) on a
// summoned ally that is already in the fight. Autopilot only knows the vanilla necromancer skills.
this.autopilot_expert_raise <- this.inherit("scripts/ai/tactical/behavior", {
    m = {
        Skill = null,
        TargetTile = null
    },
    function create()
    {
        this.m.ID = ::Const.AI.Behavior.ID.APX_Raise;
        this.m.Order = ::Const.AI.Behavior.Order.APX_Raise;
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

        local raise = skills.getSkillByID("actives.legend_raise_undead");
        if (raise != null && raise.isUsable() && raise.isAffordable()) {
            local range = raise.getMaxRange();
            local size = ::Tactical.getMapSize();
            for (local x = 0; x < size.X; x++) {
                for (local y = 0; y < size.Y; y++) {
                    local tile = ::Tactical.getTileSquare(x, y);
                    if (!tile.IsCorpseSpawned || !tile.IsEmpty) continue;
                    if (myTile.getDistanceTo(tile) > range) continue;
                    if (!raise.isUsableOn(tile, myTile)) continue;
                    // Raise where the new zombie can do something: near enemies, but not on top of me.
                    local near = 0, adjacentEnemies = 0;
                    foreach (e in f.enemies) {
                        local d = e.getTile().getDistanceTo(tile);
                        if (d <= 3) near++;
                        if (d == 1) adjacentEnemies++;
                    }
                    local v = 1.0 + 0.15 * near + 0.1 * adjacentEnemies;
                    if (v > bestValue) {
                        bestValue = v;
                        best = raise;
                        bestTile = tile;
                    }
                }
            }
        }

        // Summons: put the puppet on an empty tile between us and the enemy. Cheap (3-6 AP) and the
        // puppets are the whole point of a summoner, so this outranks anything else while spawns last.
        local puppetsOut = 0;
        foreach (a in f.allies) {
            if (a.getFlags().has("IsSummoned")) puppetsOut++;
        }
        foreach (id in ::AutopilotExpert.SummonSkills) {
            local spawn = skills.getSkillByID(id);
            if (spawn == null || !spawn.isUsable() || !spawn.isAffordable()) continue;
            // Each summon costs the caster hitpoints (15 for a basic zombie). Always get the first
            // puppet out; keep summoning while we stay above 30% health, or above 15% when the
            // enemy outnumbers what we have on the field.
            local hpCost = ("HPCost" in spawn.m) ? spawn.m.HPCost : 0;
            local hpAfter = _entity.getHitpoints() - hpCost;
            local floor = (f.enemies.len() > f.allies.len() + 1) ? 0.15 : 0.30;
            if (puppetsOut > 0 && hpAfter < _entity.getHitpointsMax() * floor) {
                ::AutopilotExpert.dbg(_entity.getName() + " skips " + id + ": would drop to " + hpAfter + " hp");
                continue;
            }
            local range = spawn.getMaxRange();
            local size = ::Tactical.getMapSize();
            local nearestEnemyTile = null, nearestD = 99;
            foreach (e in f.enemies) {
                local d = myTile.getDistanceTo(e.getTile());
                if (d < nearestD) {
                    nearestD = d;
                    nearestEnemyTile = e.getTile();
                }
            }
            for (local x = 0; x < size.X; x++) {
                for (local y = 0; y < size.Y; y++) {
                    local tile = ::Tactical.getTileSquare(x, y);
                    if (!tile.IsEmpty) continue;
                    if (myTile.getDistanceTo(tile) > range) continue;
                    if (!spawn.isUsableOn(tile, myTile)) continue;
                    // One carrion per summon whatever the tier, so spend each corpse on the best
                    // body the caster can afford right now.
                    local v = 1.5;
                    if (id.find("_med") != null) v *= 1.35;
                    else if (id.find("_high") != null) v *= 1.7;
                    if (nearestEnemyTile != null) {
                        // closer to the enemy than we are = in front of us
                        local dEnemy = tile.getDistanceTo(nearestEnemyTile);
                        if (dEnemy < nearestD) v += 0.3;
                        v += 0.02 * (20 - ::Math.min(20, dEnemy));
                    }
                    if (v > bestValue) {
                        bestValue = v;
                        best = spawn;
                        bestTile = tile;
                    }
                }
            }
        }

        local possess = skills.getSkillByID("actives.legend_possession");
        if (possess != null && possess.isUsable() && possess.isAffordable()) {
            local range = possess.getMaxRange();
            foreach (a in f.allies) {
                local tile = a.getTile();
                if (myTile.getDistanceTo(tile) > range) continue;
                // Extra AP is only worth 5 AP of ours if the puppet has something to hit.
                local adjacentEnemies = 0;
                foreach (e in f.enemies) {
                    if (e.getTile().getDistanceTo(tile) == 1) adjacentEnemies++;
                }
                if (adjacentEnemies == 0) continue;
                if (!possess.isUsableOn(tile, myTile)) continue;  // filters to summoned/undead allies
                // A full extra puppet turn beats one staff bash; weight it so it actually gets picked.
                local v = 1.2 + 0.3 * adjacentEnemies;
                if (v > bestValue) {
                    bestValue = v;
                    best = possess;
                    bestTile = tile;
                }
            }
        }

        if (best == null) return ::Const.AI.Behavior.Score.Zero;

        this.m.Skill = best;
        this.m.TargetTile = bestTile;
        local score = ::Const.AI.Behavior.Score.APX_Raise * this.getProperties().BehaviorMult[this.m.ID];
        score *= bestValue * this.getFatigueScoreMult(best);
        ::AutopilotExpert.dbg(_entity.getName() + " necro candidate " + best.getID() + " value=" + bestValue + " score=" + score);
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
