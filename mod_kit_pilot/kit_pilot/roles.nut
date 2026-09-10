// What a bro is, from what he holds; from his talents if he holds nothing yet.
local def = ::KitPilot;

def.Role <- {
    Tank = "tank"          // one-hander + shield
    Duelist = "duelist"    // one-hander, no shield
    Striker = "striker"    // two-hander, reach 1
    Polearm = "polearm"    // two-hander, reach 2
    Archer = "archer"      // bow / crossbow / sling / handgonne
    Thrower = "thrower"    // throwing weapons: weapons are left alone
    Banner = "banner"      // weapons are left alone
    Caster = "caster"      // weapons are left alone
};

// weapon type const name -> vanilla mastery perk id
def.MasteryPerk <- {
    Axe = "perk.mastery_axe"
    Mace = "perk.mastery_mace"
    Hammer = "perk.mastery_hammer"
    Flail = "perk.mastery_flail"
    Cleaver = "perk.mastery_cleaver"
    Sword = "perk.mastery_sword"
    Dagger = "perk.mastery_dagger"
    Polearm = "perk.mastery_polearm"
    Spear = "perk.mastery_spear"
    Crossbow = "perk.mastery_crossbow"
    Bow = "perk.mastery_bow"
    Throwing = "perk.mastery_throwing"
};

def.weaponTypeName <- function (_item) {
    if (_item == null || !("isWeaponType" in _item)) return null;
    local WT = ::Const.Items.WeaponType;
    // Order matters: a magic staff is also Staff and Polearm, a polearm may also be Spear.
    foreach (name in ["MagicStaff", "Musical", "Bow", "Crossbow", "Sling", "Throwing", "Polearm", "Staff",
                      "Spear", "Axe", "Mace", "Hammer", "Flail", "Cleaver", "Sword", "Dagger"]) {
        if (!(name in WT)) continue;
        if (_item.isWeaponType(WT[name])) return name;
    }
    return null;
}

def.isPolearmItem <- function (_item) {
    local WT = ::Const.Items.WeaponType;
    if (("Polearm" in WT) && _item.isWeaponType(WT.Polearm)) return true;
    if (("getRangeMax" in _item) && _item.getRangeMax() >= 2 && !_item.isItemType(::Const.Items.ItemType.RangedWeapon)) return true;
    return false;
}

local function stars(_bro, _attrName) {
    local A = ::Const.Attributes;
    if (!(_attrName in A)) return 0;
    local t = _bro.getTalents();
    return (A[_attrName] < t.len()) ? t[A[_attrName]] : 0;
}

// Roles whose weapons Kit Pilot does not touch. Their armor is still handled.
def.isWeaponsFixed <- function (_role) {
    return _role == def.Role.Thrower || _role == def.Role.Banner || _role == def.Role.Caster;
};

def.detectRole <- function (_bro) {
    local items = _bro.getItems();
    local skills = _bro.getSkills();
    local main = items.getItemAtSlot(::Const.ItemSlot.Mainhand);
    local off = items.getItemAtSlot(::Const.ItemSlot.Offhand);
    local IT = ::Const.Items.ItemType;

    local info = {
        role = null
        weapon = def.weaponTypeName(main)  // current weapon type name, null if unarmed
        unarmed = main == null
        nimble = skills.hasSkill("perk.nimble")
        brawny = skills.hasSkill("perk.brawny")
        level = _bro.getLevel()
    };

    local hasShield = off != null && off.isItemType(IT.Shield);
    local ranged = main != null && main.isItemType(IT.RangedWeapon);
    local isCaster = false;
    foreach (id in ["actives.legend_raise_undead", "actives.legend_possession", "actives.legend_magic_missile", "actives.raise_undead"]) {
        if (skills.hasSkill(id)) { isCaster = true; break; }
    }

    if (skills.hasSkill("actives.rally_the_troops")) info.role = def.Role.Banner;
    else if (isCaster || info.weapon == "MagicStaff" || info.weapon == "Musical") info.role = def.Role.Caster;
    else if (info.weapon == "Throwing" || (main != null && main.isItemType(IT.Ammo))) info.role = def.Role.Thrower;
    else if (ranged && info.weapon != "Staff" && info.weapon != "Polearm") info.role = def.Role.Archer;
    else if (main != null && def.isPolearmItem(main)) info.role = def.Role.Polearm;
    else if (main != null && main.isItemType(IT.TwoHanded)) info.role = def.Role.Striker;
    else if (main != null && hasShield) info.role = def.Role.Tank;
    else if (main != null) info.role = def.Role.Duelist;
    else {
        // Nothing in hand: read the man, not the kit. Ranged talent or a clear ranged skill lead
        // makes an archer; everyone else goes into the line with a shield (or a two-hander if
        // the setting says so). A shield alone still counts as "wants a shield".
        local b = _bro.getBaseProperties();
        local rangedTalent = stars(_bro, "RangedSkill") >= 2 || b.RangedSkill >= b.MeleeSkill + 5;
        if (rangedTalent) info.role = def.Role.Archer;
        else if (hasShield || !def.conf("recruitsTwoHanded")) info.role = def.Role.Tank;
        else info.role = def.Role.Striker;
    }
    return info;
}
