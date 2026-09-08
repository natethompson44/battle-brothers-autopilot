// Attribute level-ups. The game pre-rolls a gain for each of the eight attributes; the player
// normally picks three. We score each attribute by role weight, roll size and talent stars.
local def = ::LevelupPilot;
local R = def.Role;

// getter key = what getAttributeLevelUpValues() returns, setter key = what setAttributeLevelUpValues() reads
local Specs = [
    {name = "Hitpoints",     attr = "Hitpoints",     getKey = "hitpointsIncrease",     setKey = "hitpointsIncrease",     cur = "hitpoints",     max = "hitpointsMax",     norm = 4.0}
    {name = "Bravery",       attr = "Bravery",       getKey = "braveryIncrease",       setKey = "braveryIncrease",       cur = "bravery",       max = "braveryMax",       norm = 4.0}
    {name = "Fatigue",       attr = "Fatigue",       getKey = "fatigueIncrease",       setKey = "maxFatigueIncrease",    cur = "fatigue",       max = "fatigueMax",       norm = 4.0}
    {name = "Initiative",    attr = "Initiative",    getKey = "initiativeIncrease",    setKey = "initiativeIncrease",    cur = "initiative",    max = "initiativeMax",    norm = 5.0}
    {name = "MeleeSkill",    attr = "MeleeSkill",    getKey = "meleeSkillIncrease",    setKey = "meleeSkillIncrease",    cur = "meleeSkill",    max = "meleeSkillMax",    norm = 3.0}
    {name = "RangedSkill",   attr = "RangedSkill",   getKey = "rangeSkillIncrease",    setKey = "rangeSkillIncrease",    cur = "rangeSkill",    max = "rangeSkillMax",    norm = 3.0}
    {name = "MeleeDefense",  attr = "MeleeDefense",  getKey = "meleeDefenseIncrease",  setKey = "meleeDefenseIncrease",  cur = "meleeDefense",  max = "meleeDefenseMax",  norm = 3.0}
    {name = "RangedDefense", attr = "RangedDefense", getKey = "rangeDefenseIncrease",  setKey = "rangeDefenseIncrease",  cur = "rangeDefense",  max = "rangeDefenseMax",  norm = 3.0}
];

local Weights = {};
Weights[R.Tank]    <- {Hitpoints = 2.0, Bravery = 1.3, Fatigue = 1.6, Initiative = 0.3, MeleeSkill = 2.6, RangedSkill = 0.0, MeleeDefense = 3.0, RangedDefense = 1.0};
Weights[R.Duelist] <- {Hitpoints = 1.8, Bravery = 1.2, Fatigue = 1.8, Initiative = 0.8, MeleeSkill = 3.0, RangedSkill = 0.0, MeleeDefense = 2.2, RangedDefense = 0.8};
Weights[R.Striker] <- {Hitpoints = 2.2, Bravery = 1.3, Fatigue = 2.2, Initiative = 0.5, MeleeSkill = 3.0, RangedSkill = 0.0, MeleeDefense = 1.5, RangedDefense = 0.8};
Weights[R.Polearm] <- {Hitpoints = 1.6, Bravery = 1.2, Fatigue = 2.0, Initiative = 0.8, MeleeSkill = 3.0, RangedSkill = 0.0, MeleeDefense = 1.0, RangedDefense = 0.8};
Weights[R.Archer]  <- {Hitpoints = 1.5, Bravery = 1.0, Fatigue = 1.6, Initiative = 1.2, MeleeSkill = 0.3, RangedSkill = 3.0, MeleeDefense = 0.6, RangedDefense = 1.6};
Weights[R.Thrower] <- {Hitpoints = 1.6, Bravery = 1.0, Fatigue = 2.0, Initiative = 0.6, MeleeSkill = 1.4, RangedSkill = 2.6, MeleeDefense = 1.0, RangedDefense = 1.0};
Weights[R.Caster]  <- {Hitpoints = 2.0, Bravery = 2.6, Fatigue = 2.0, Initiative = 1.0, MeleeSkill = 0.5, RangedSkill = 0.5, MeleeDefense = 1.0, RangedDefense = 1.0};
Weights[R.Banner]  <- {Hitpoints = 2.0, Bravery = 3.0, Fatigue = 1.5, Initiative = 0.5, MeleeSkill = 1.5, RangedSkill = 0.0, MeleeDefense = 1.6, RangedDefense = 1.0};

// Spend one pending level-up. Returns false if nothing could be raised.
def.spendOneLevelUp <- function (_bro, _info) {
    local vals = _bro.getAttributeLevelUpValues();
    local weights = Weights[_info.role];
    // Summons are paid for in hitpoints, so a summoner's HP is her mana pool.
    if (("summoner" in _info) && _info.summoner) {
        weights = {Hitpoints = 3.2, Bravery = 2.0, Fatigue = 2.0, Initiative = 0.8, MeleeSkill = 0.5, RangedSkill = 0.3, MeleeDefense = 1.2, RangedDefense = 1.2};
    }
    local A = ::Const.Attributes;
    local options = [];

    foreach (s in Specs) {
        local roll = vals[s.getKey];
        if (roll <= 0) continue;
        if (vals[s.cur] + roll > vals[s.max]) continue;       // at cap
        local stars = (_info.talents != null && (A[s.attr] < _info.talents.len())) ? _info.talents[A[s.attr]] : 0;
        local w = weights[s.name];
        // Everybody needs enough resolve to not break; nudge it while it is low.
        if (s.name == "Bravery" && vals.bravery < 45) w += 1.0;
        local score = w * (roll / s.norm) * (1.0 + 0.25 * stars);
        options.push({spec = s, roll = roll, score = score, stars = stars});
    }
    if (options.len() == 0) return false;

    options.sort(@(a, b) b.score <=> a.score);
    local chosen = options.slice(0, ::Math.min(def.PicksPerLevel, options.len()));

    local v = {};
    foreach (s in Specs) v[s.setKey] <- 0;
    local text = [];
    foreach (o in chosen) {
        v[o.spec.setKey] = o.roll;
        text.push(o.spec.name + "+" + o.roll + (o.stars > 0 ? "(" + o.stars + "*)" : ""));
    }
    _bro.setAttributeLevelUpValues(v);
    local joined = "";
    foreach (i, t in text) joined += (i > 0 ? ", " : "") + t;
    def.dbg(_bro.getName() + " [" + _info.role + "] level-up: " + joined);
    return true;
}
