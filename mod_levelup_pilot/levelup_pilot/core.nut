local def = ::LevelupPilot;

// Only bros actually in the company. updateLevel() also fires for tavern candidates being
// generated; those are left alone until they are hired (the world-shown sweep gets them then).
def.isInRoster <- function (_bro) {
    try {
        foreach (b in ::World.getPlayerRoster().getAll()) {
            if (b.getID() == _bro.getID()) return true;
        }
    } catch (e) {}
    return false;
}

def.shouldSkip <- function (_bro) {
    if (_bro == null) return true;
    if (("isNull" in _bro) && _bro.isNull()) return true;
    local name = _bro.getName();
    if (name != null && name.len() > 0 && name.slice(name.len() - 1) == def.ManualMarker) return true;
    if (def.conf("skipAvatar") && _bro.getSkills().hasSkill("trait.player")) return true;
    return false;
}

// Spend everything pending on one bro.
def.process <- function (_bro) {
    if (def.shouldSkip(_bro)) return;
    if (_bro.m.LevelUps <= 0 && _bro.m.PerkPoints <= 0) return;
    if (_bro.getBackground() == null) return;

    local info;
    try {
        info = def.detectRole(_bro);
    } catch (e) {
        ::logError("levelup pilot: role detection failed for " + _bro.getName() + ": " + e);
        return;
    }

    local guard = def.MaxIterations;
    // Perks first: some (Gifted) grant an extra level-up, which the stats pass then spends.
    if (def.conf("perks")) {
        while (_bro.m.PerkPoints > 0 && guard-- > 0) {
            local ok = false;
            try { ok = def.spendOnePerkPoint(_bro, info); }
            catch (e) { ::logError("levelup pilot: perk pick failed for " + _bro.getName() + ": " + e); }
            if (!ok) break;
        }
    }
    if (def.conf("stats")) {
        while (_bro.m.LevelUps > 0 && guard-- > 0) {
            local ok = false;
            try { ok = def.spendOneLevelUp(_bro, info); }
            catch (e) { ::logError("levelup pilot: level-up failed for " + _bro.getName() + ": " + e); }
            if (!ok) break;
        }
    }
}

// Everyone in the roster.
def.sweep <- function (_why) {
    if (!def.conf("stats") && !def.conf("perks")) return;
    if (!("World" in getroottable()) || ::World == null) return;
    local roster;
    try {
        roster = ::World.getPlayerRoster().getAll();
    } catch (e) {
        return;
    }
    def.dbg("sweep (" + _why + "), " + roster.len() + " bros");
    foreach (bro in roster) {
        try {
            def.process(bro);
        } catch (e) {
            ::logError("levelup pilot: failed on " + bro.getName() + ": " + e);
        }
    }
}

def.isInBattle <- function () {
    try {
        return ::Tactical.isActive();
    } catch (e) {
        return false;
    }
}
