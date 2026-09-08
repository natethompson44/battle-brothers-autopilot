// Perk points. Each role has an ordered wish list of Legends perk constants; the first one that
// is in this bro's tree and unlockable right now wins. If nothing on the list is available, a
// generic staple is taken; if even that fails, the cheapest sane perk in the tree, so the next
// tier keeps unlocking. Profession / trade / horse perks are never picked automatically.
local def = ::LevelupPilot;
local R = def.Role;

local Builds = {};
Builds[R.Tank] <- [
    "ShieldExpert" "Colossus" "Rotation" "Underdog" "Recover" "Backstabber" "Indomitable"
    "Brawny" "LegendShieldsUp" "Anticipation" "FortifiedMind" "LegendComposure" "Taunt"
    "SteelBrow" "HoldOut" "Steadfast" "Pathfinder" "LegendSpecialistShieldSkill" "Adrenaline"
];
Builds[R.Duelist] <- [
    "Duelist" "Colossus" "Backstabber" "Recover" "Underdog" "Dodge" "Footwork" "Overwhelm"
    "Berserk" "KillingFrenzy" "Anticipation" "FortifiedMind" "SteelBrow" "Pathfinder" "Adrenaline"
    "LegendBalance" "LegendMuscularity"
];
Builds[R.Striker] <- [
    "Colossus" "ReachAdvantage" "Berserk" "KillingFrenzy" "Backstabber" "Recover" "Underdog"
    "Brawny" "FortifiedMind" "SteelBrow" "Adrenaline" "Pathfinder" "LegendMuscularity"
    "LegendBattleheart" "Fearsome" "Overwhelm" "Indomitable"
];
Builds[R.Polearm] <- [
    "ReachAdvantage" "Backstabber" "Colossus" "Recover" "Underdog" "Overwhelm" "Brawny"
    "Berserk" "KillingFrenzy" "FortifiedMind" "Pathfinder" "Anticipation" "SteelBrow"
    "LegendMuscularity" "Adrenaline" "LegendBalance"
];
Builds[R.Archer] <- [
    "Bullseye" "Anticipation" "Colossus" "Dodge" "Recover" "Backstabber" "HeadHunter" "QuickHands"
    "Overwhelm" "Pathfinder" "KillingFrenzy" "Berserk" "LegendAlert" "FortifiedMind" "BagsAndBelts"
    "Footwork" "LegendBallistics"
];
Builds[R.Thrower] <- [
    "BagsAndBelts" "QuickHands" "Colossus" "Backstabber" "Recover" "Dodge" "Overwhelm"
    "HeadHunter" "Bullseye" "Anticipation" "Pathfinder" "Underdog" "KillingFrenzy" "FortifiedMind"
    "Berserk" "Footwork"
];
Builds[R.Caster] <- [
    "LegendPossession" "LegendRaiseUndead" "LegendSpawnZombieLow" "LegendMagicMissile"
    "LegendMagicMissileMastery" "LegendSpawnZombieMed" "LegendSpawnSkeletonLow" "LegendSpawnZombieHigh"
    "LegendSpawnSkeletonMed" "LegendSpawnSkeletonHigh" "LegendChanneledPower" "LegendExtendendAura"
    "LegendReclamation" "LegendConservation" "Colossus" "FortifiedMind" "Recover" "Dodge"
    "Anticipation" "Pathfinder" "LegendComposure" "Backstabber" "HoldOut" "NineLives"
];
Builds[R.Banner] <- [
    "RallyTheTroops" "InspiringPresence" "FortifiedMind" "Colossus" "ShieldExpert" "Rotation"
    "Recover" "Underdog" "Anticipation" "HoldOut" "Steadfast" "Pathfinder" "LegendComposure"
    "Indomitable" "LegendHoldTheLine" "Captain"
];

// Background signatures: if a bro's tree contains the marker perk, these come before the role
// list. Only perks whose skills the battle AI actually uses are here; spell perks the AI cannot
// cast yet (Wither, Rust, Siphon, Miasma) are deliberately left to the generic path.
local Signatures = [
    {marker = "LegendFieldTriage", picks = [
        "LegendSpecBandage" "LegendFieldTriage" "RallyTheTroops" "LegendMedPackages" "FortifiedMind"
        "Dodge" "HoldOut" "Nimble"
    ]}
    // Summoner: summons cost 15/20/30 HP each and consume carrion (2 medicine a day to keep).
    // Nine Lives and Perfect Fit keep a sickly caster alive, Blend In keeps her un-targeted,
    // Reclamation feeds the carrion supply, and the two upgrade tiers come as their rows open.
    {marker = "LegendSpawnZombieLow", picks = [
        "LegendSpawnZombieLow" "NineLives" "FortifiedMind" "LegendPerfectFit" "LegendSpawnZombieMed"
        "LegendBlendIn" "LegendReclamation" "LegendSpawnZombieHigh" "LegendExtendendAura"
        "LegendTrueBeliever" "Recover" "Underdog"
    ]}
    {marker = "LegendSpawnSkeletonLow", picks = [
        "LegendSpawnSkeletonLow" "NineLives" "FortifiedMind" "LegendPerfectFit" "LegendSpawnSkeletonMed"
        "LegendBlendIn" "LegendReclamation" "LegendSpawnSkeletonHigh" "LegendExtendendAura"
        "LegendTrueBeliever" "Recover" "Underdog"
    ]}
    // Puppet master: possesses thralls (12 AP, +15 skill, -25% damage taken) and holds a line.
    {marker = "LegendPossession", picks = [
        "LegendPossession" "NineLives" "Recover" "LegendPerfectFit" "SteelBrow" "Backstabber" "Brawny"
        "Underdog" "BattleForged" "Taunt"
    ]}
    {marker = "LegendRaiseUndead", picks = [
        "LegendRaiseUndead" "LegendPossession" "FortifiedMind" "Recover"
    ]}
];

local function treeHas(_bro, _constName) {
    local id = def.Perks.idFor(_constName);
    return id != null && def.Perks.inTree(_bro, id);
}

// Good for anyone when the role list is exhausted or gated by tier.
local Generic = [
    "Colossus" "Recover" "Backstabber" "Underdog" "Pathfinder" "FortifiedMind" "SteelBrow" "Dodge"
    "Anticipation" "Adrenaline" "NineLives" "HoldOut" "Brawny" "QuickHands" "BagsAndBelts" "Gifted"
    "LegendComposure" "LegendBalance" "LegendPerfectFit"
];

// Never auto-pick: camp / trade / horse / profession perks. Matched as substrings of the const name.
local Avoid = [
    "Horse" "Barter" "Paymaster" "Quartermaster" "Brewing" "Cook" "Herbcraft" "Woodworking" "OreHunter"
    "Scholar" "ScrollIngredients" "Gatherer" "Peaceful" "Pacifist" "Fashionable" "SleightOfHand"
    "Swagger" "Bribe" "OffBookDeal" "DangerPay" "Teacher" "WheelMaintenance" "MasterTrainer"
    "WhipThemInShape" "Helpful" "MealPreperation" "Alcohol" "DogBreeder" "Minnesanger" "Meistersanger"
    "Hippology" "Specialist" "Packing" "Stacking" "ToolsDrawers" "ToolsSpares" "AmmoBinding" "AmmoBundles"
    "MedPackages" "MedIngredients" "Hidden" "BlendIn" "Lurker" "NightRaider" "PromisedPotential"
    "Scry" "ReadOmens" "DistantVisions" "Wind" "Climb" "Leap" "Tumble" "Backflip" "Twirl"
];

local function isAvoided(_const) {
    foreach (a in Avoid) {
        if (_const.find(a) != null) return true;
    }
    return false;
}

// Returns the perk ID string if this perk const is in the bro's tree, not owned, and unlockable now.
local function candidate(_bro, _constName) {
    local id = def.Perks.idFor(_constName);
    if (id == null) return null;
    if (_bro.getSkills().hasSkill(id)) return null;
    if (!def.Perks.inTree(_bro, id)) return null;
    if (!_bro.isPerkUnlockable(id)) return null;
    return id;
}

def.pickPerk <- function (_bro, _info) {
    local list = [];
    // Student pays for itself if taken early.
    if (_info.level <= 3) list.push("Student");
    // What this background is for comes before what he happens to be holding.
    foreach (sig in Signatures) {
        if (treeHas(_bro, sig.marker)) list.extend(sig.picks);
    }
    if (_info.mastery != null) list.push(_info.mastery);
    // Armor perk by what he actually wears.
    if (_info.heavy) list.push("BattleForged");
    else if (_info.light) list.push("Nimble");
    list.extend(Builds[_info.role]);
    if (!_info.heavy) list.push("Nimble");
    if (!_info.light) list.push("BattleForged");
    list.extend(Generic);

    foreach (name in list) {
        local id = candidate(_bro, name);
        if (id != null) return {id = id, why = name};
    }

    // Nothing from the lists: cheapest sane perk in his own tree.
    local best = null, bestRow = 99;
    foreach (row in def.Perks.treeRows(_bro)) {
        foreach (perk in row) {
            if (isAvoided(perk.Const)) continue;
            if (_bro.getSkills().hasSkill(perk.ID)) continue;
            if (!_bro.isPerkUnlockable(perk.ID)) continue;
            if (perk.Row < bestRow) {
                bestRow = perk.Row;
                best = perk;
            }
        }
    }
    if (best != null) return {id = best.ID, why = "fallback " + best.Const};
    return null;
}

def.spendOnePerkPoint <- function (_bro, _info) {
    local pick = def.pickPerk(_bro, _info);
    if (pick == null) return false;
    local ok = _bro.unlockPerk(pick.id);
    def.dbg(_bro.getName() + " [" + _info.role + "] perk: " + pick.id + " (" + pick.why + ")" + (ok ? "" : " FAILED"));
    return ok;
}
