// Work out what a bro is from what he is holding and what he knows.
local def = ::LevelupPilot;

def.Role <- {
    Tank = "tank"          // one-hander + shield
    Duelist = "duelist"    // one-hander, no shield
    Striker = "striker"    // two-hander
    Polearm = "polearm"
    Archer = "archer"      // bow / crossbow / sling / handgonne
    Thrower = "thrower"
    Caster = "caster"      // magic staff, necromancy, summoning
    Banner = "banner"
};

// weapon type const name -> mastery perk const name
def.WeaponMastery <- {
    Axe = "SpecAxe"
    Mace = "SpecMace"
    Hammer = "SpecHammer"
    Flail = "SpecFlail"
    Cleaver = "SpecCleaver"
    Sword = "SpecSword"
    Dagger = "SpecDagger"
    Polearm = "SpecPolearm"
    Spear = "SpecSpear"
    Crossbow = "SpecCrossbow"
    Bow = "SpecBow"
    Throwing = "SpecThrowing"
    Sling = "LegendMasterySlings"
    Staff = "LegendMasteryStaves"
    MagicStaff = "LegendMasteryStaves"
    Musical = "LegendMasteryMusic"
};

def.CasterSkills <- [
    "actives.legend_raise_undead"
    "actives.legend_possession"
    "actives.legend_spawn_zombie_low"
    "actives.legend_spawn_zombie_med"
    "actives.legend_spawn_zombie_high"
    "actives.legend_spawn_skeleton_low"
    "actives.legend_spawn_skeleton_med"
    "actives.legend_spawn_skeleton_high"
    "actives.legend_magic_missile"
];

local function weaponTypeName(_item) {
    if (_item == null) return null;
    local WT = ::Const.Items.WeaponType;
    // Order matters: a magic staff is also Staff and Polearm, a polearm may also be Spear.
    foreach (name in ["MagicStaff", "Musical", "Bow", "Crossbow", "Sling", "Throwing", "Polearm", "Staff",
                      "Spear", "Axe", "Mace", "Hammer", "Flail", "Cleaver", "Sword", "Dagger"]) {
        if (!(name in WT)) continue;
        if (_item.isWeaponType(WT[name])) return name;
    }
    return null;
}

// Total fatigue penalty of body armor + helmet (negative number). Light is nimble territory.
local function armorPenalty(_bro) {
    local items = _bro.getItems();
    local total = 0;
    foreach (slot in [::Const.ItemSlot.Body, ::Const.ItemSlot.Head]) {
        local it = items.getItemAtSlot(slot);
        if (it != null && ("getStaminaModifier" in it)) total += it.getStaminaModifier();
    }
    return total;
}

def.detectRole <- function (_bro) {
    local items = _bro.getItems();
    local skills = _bro.getSkills();
    local main = items.getItemAtSlot(::Const.ItemSlot.Mainhand);
    local off = items.getItemAtSlot(::Const.ItemSlot.Offhand);
    local IT = ::Const.Items.ItemType;

    local info = {
        role = def.Role.Duelist
        weapon = weaponTypeName(main)
        mastery = null
        heavy = false
        light = false
        caster = false
        talents = _bro.getTalents()
        level = _bro.getLevel()
    };
    if (info.weapon != null && (info.weapon in def.WeaponMastery)) info.mastery = def.WeaponMastery[info.weapon];
    // Magic Staff Mastery only affects Magic Missile / Chain Lightning / Firefield / Root. A staff
    // wielder without those spells (a summoner with Staff Bash) gets nothing from it.
    if (info.mastery == "LegendMasteryStaves") {
        local hasSpell = false;
        foreach (id in ["actives.legend_magic_missile", "actives.legend_magic_chain_lightning",
                        "actives.legend_chain_lightning", "actives.legend_firefield", "actives.legend_root"]) {
            if (skills.hasSkill(id)) { hasSpell = true; break; }
        }
        if (!hasSpell) info.mastery = null;
    }
    // Scythes have their own mastery (Harvest Swathes, +15 to hit).
    if (main != null && main.getID().find("scythe") != null) info.mastery = "LegendSpecialistReaper";

    info.summoner <- false;
    foreach (id in ["actives.legend_spawn_zombie_low", "actives.legend_spawn_zombie_med", "actives.legend_spawn_zombie_high",
                    "actives.legend_spawn_skeleton_low", "actives.legend_spawn_skeleton_med", "actives.legend_spawn_skeleton_high"]) {
        if (skills.hasSkill(id)) { info.summoner = true; break; }
    }

    local penalty = armorPenalty(_bro);
    info.light = penalty >= -15;
    info.heavy = penalty <= -30;

    foreach (id in def.CasterSkills) {
        if (skills.hasSkill(id)) {
            info.caster = true;
            break;
        }
    }

    local hasShield = off != null && off.isItemType(IT.Shield);
    local ranged = main != null && main.isItemType(IT.RangedWeapon);

    if (skills.hasSkill("actives.rally_the_troops")) info.role = def.Role.Banner;
    else if (info.caster || info.weapon == "MagicStaff") info.role = def.Role.Caster;
    else if (info.weapon == "Throwing") info.role = def.Role.Thrower;
    else if (ranged && info.weapon != "Staff" && info.weapon != "Polearm") info.role = def.Role.Archer;
    else if (info.weapon == "Polearm" || info.weapon == "Staff") info.role = def.Role.Polearm;
    else if (hasShield) info.role = def.Role.Tank;
    else if (main != null && main.isItemType(IT.TwoHanded)) info.role = def.Role.Striker;
    else info.role = def.Role.Duelist;

    return info;
}
