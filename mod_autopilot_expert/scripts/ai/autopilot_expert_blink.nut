// Blink (Company Starts' Wolfeo): two uses. Strike: when not engaged and with enough AP left to
// attack afterwards, blink next to the juiciest enemy that is not surrounded by friends. Escape:
// when badly hurt or mobbed, blink to a free tile with no enemies adjacent, near our own line.
this.autopilot_expert_blink <- this.inherit("scripts/ai/tactical/behavior", {
    m = {
        Skill = null,
        TargetTile = null,
        Mode = null
    },
    function create()
    {
        this.m.ID = ::Const.AI.Behavior.ID.APX_Blink;
        this.m.Order = ::Const.AI.Behavior.Order.APX_Blink;
        this.behavior.create();
    }

    function onEvaluate( _entity )
    {
        this.m.Skill = null;
        this.m.TargetTile = null;
        this.m.Mode = null;
        if (_entity.getActionPoints() < ::Const.Movement.AutoEndTurnBelowAP) return ::Const.AI.Behavior.Score.Zero;
        if (_entity.getMoraleState() == ::Const.MoraleState.Fleeing) return ::Const.AI.Behavior.Score.Zero;

        local skill = _entity.getSkills().getSkillByID("actives.wolfeo_blink");
        if (skill == null || !skill.isUsable() || !skill.isAffordable()) return ::Const.AI.Behavior.Score.Zero;

        local myTile = _entity.getTile();
        local f = ::AutopilotExpert.scan(_entity);
        if (f.enemies.len() == 0) return ::Const.AI.Behavior.Score.Zero;

        local adjacentEnemies = 0;
        foreach (e in f.enemies) if (e.getTile().getDistanceTo(myTile) == 1) adjacentEnemies++;
        local hp = _entity.getHitpointsPct();

        local mode = null;
        if (adjacentEnemies >= 1 && (hp < 0.35 || adjacentEnemies >= 3)) mode = "escape";
        else if (adjacentEnemies == 0 && _entity.getActionPoints() >= skill.getActionPointCost() + 4) mode = "strike";
        if (mode == null) return ::Const.AI.Behavior.Score.Zero;

        local range = skill.getMaxRange();
        local size = ::Tactical.getMapSize();
        local bestTile = null, bestValue = 0.0;
        for (local x = 0; x < size.X; x++) {
            for (local y = 0; y < size.Y; y++) {
                local tile = ::Tactical.getTileSquare(x, y);
                if (!tile.IsEmpty) continue;
                if (myTile.getDistanceTo(tile) > range) continue;
                if (!skill.isUsableOn(tile, myTile)) continue;

                local enemiesAdj = 0, nearestEnemy = 99, weakest = null;
                foreach (e in f.enemies) {
                    local d = e.getTile().getDistanceTo(tile);
                    if (d == 1) {
                        enemiesAdj++;
                        if (weakest == null || e.getHitpointsPct() < weakest.getHitpointsPct()) weakest = e;
                    }
                    if (d < nearestEnemy) nearestEnemy = d;
                }
                local alliesNear = 0;
                foreach (a in f.allies) if (a.getTile().getDistanceTo(tile) <= 2) alliesNear++;

                local v = 0.0;
                if (mode == "escape") {
                    if (enemiesAdj > 0) continue;
                    v = 1.0 + 0.2 * alliesNear + 0.1 * ::Math.min(5, nearestEnemy);
                } else {
                    if (enemiesAdj == 0 || enemiesAdj > 2) continue;
                    v = 1.0 + (1.0 - weakest.getHitpointsPct()) + 0.3 * ::AutopilotExpert.alliesAdjacentTo(_entity, weakest) - 0.35 * (enemiesAdj - 1);
                }
                if (v > bestValue) {
                    bestValue = v;
                    bestTile = tile;
                }
            }
        }
        if (bestTile == null) return ::Const.AI.Behavior.Score.Zero;

        this.m.Skill = skill;
        this.m.TargetTile = bestTile;
        this.m.Mode = mode;
        local score = ::Const.AI.Behavior.Score.APX_Blink * this.getProperties().BehaviorMult[this.m.ID];
        score *= bestValue * (mode == "escape" ? 1.6 : 1.0) * this.getFatigueScoreMult(skill);
        ::AutopilotExpert.dbg(_entity.getName() + " blink " + mode + " value=" + bestValue + " score=" + score);
        return score;
    }

    function onExecute( _entity )
    {
        if (::Const.AI.VerboseMode) {
            ::logInfo("* " + _entity.getName() + ": blinks (" + this.m.Mode + ")!");
        }
        this.m.Skill.use(this.m.TargetTile);
        if (!_entity.isHiddenToPlayer()) {
            this.getAgent().declareAction();
        }
        this.m.Skill = null;
        this.m.TargetTile = null;
        this.m.Mode = null;
        return true;
    }
});
