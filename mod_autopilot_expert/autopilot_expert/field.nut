// Battlefield awareness helpers shared by profiles and support behaviors.
local def = ::AutopilotExpert;

local function isLive(_e) {
    return _e != null && _e.isAlive() && !_e.isDying() && _e.isPlacedOnMap();
}

// Current round as counted by our turn bar hook. 99 when unknown (disables round-gated logic).
def.getRound <- function () {
    try {
        local tsb = ::Tactical.TurnSequenceBar;
        if (tsb != null && ("apx_Round" in tsb.m)) return tsb.m.apx_Round;
    } catch (e) {}
    return 99;
}

// Scan everybody on the map relative to _actor. Uses the entity manager rather than the agent's
// "known" lists so it does not depend on how those lists are wrapped.
def.scan <- function (_actor) {
    local ret = {
        nearest = 99              // distance to closest live enemy
        enemies = []              // live enemies
        enemyRanged = 0
        allies = []               // live allies, excluding _actor
        allyRanged = 0
        allyRangedWithin4 = 0
        alliesWithin4 = 0
        alliesWithin8 = 0
        adjacentAllies = []
    };
    local myTile = _actor.getTile();
    local instances = ::Tactical.Entities.getAllInstances();
    foreach (i, faction in instances) {
        if (faction.len() == 0) continue;
        local allied = _actor.getFaction() == i || _actor.isAlliedWith(i);
        foreach (e in faction) {
            if (!isLive(e) || e.getID() == _actor.getID()) continue;
            local d = myTile.getDistanceTo(e.getTile());
            local ranged = e.isArmedWithRangedWeapon();
            if (allied) {
                ret.allies.push(e);
                if (ranged) ret.allyRanged++;
                if (d <= 4) {
                    ret.alliesWithin4++;
                    if (ranged) ret.allyRangedWithin4++;
                }
                if (d <= 8) ret.alliesWithin8++;
                if (d == 1) ret.adjacentAllies.push(e);
            } else {
                ret.enemies.push(e);
                if (ranged) ret.enemyRanged++;
                if (d < ret.nearest) ret.nearest = d;
            }
        }
    }
    return ret;
}

// Number of live allies of _actor standing next to _target.
def.alliesAdjacentTo <- function (_actor, _target) {
    local n = 0;
    local tTile = _target.getTile();
    local instances = ::Tactical.Entities.getAllInstances();
    foreach (i, faction in instances) {
        if (faction.len() == 0) continue;
        if (!(_actor.getFaction() == i || _actor.isAlliedWith(i))) continue;
        foreach (e in faction) {
            if (!isLive(e)) continue;
            if (e.getTile().getDistanceTo(tTile) == 1) n++;
        }
    }
    return n;
}
