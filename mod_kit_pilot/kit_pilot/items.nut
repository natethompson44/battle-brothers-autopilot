// What is in the stash and what it is worth to a given bro. Weapons and shields are ranked by
// their crown value, which tracks tier closely enough across vanilla and Legends and needs no
// per-item table; armor by its armor rating against the fatigue it costs.
local def = ::KitPilot;

def.stash <- function () {
    return ::World.Assets.getStash();
};

def.stashItems <- function () {
    local out = [];
    foreach (it in def.stash().getItems()) {
        if (it != null) out.push(it);
    }
    return out;
};

// 1.0 for a pristine item, down to 0.7 for a broken one. Broken gear still counts: repair fixes it.
def.condFactor <- function (_item) {
    if (!("getConditionMax" in _item) || !("getCondition" in _item)) return 1.0;
    local max = _item.getConditionMax();
    if (max <= 0) return 1.0;
    return 0.7 + 0.3 * ::Math.minf(1.0, _item.getCondition() * 1.0 / max);
};

def.isNamed <- function (_item) {
    local IT = ::Const.Items.ItemType;
    return _item != null && (_item.isItemType(IT.Named) || (("Legendary" in IT) && _item.isItemType(IT.Legendary)));
};

def.isMeleeWeapon <- function (_item) {
    local IT = ::Const.Items.ItemType;
    if (!_item.isItemType(IT.Weapon) || _item.isItemType(IT.RangedWeapon) || _item.isItemType(IT.Ammo)) return false;
    if (("Tool" in IT) && _item.isItemType(IT.Tool)) return false;
    if (_item.getSlotType() != ::Const.ItemSlot.Mainhand) return false;
    local name = def.weaponTypeName(_item);
    return name != "MagicStaff" && name != "Musical";
};

def.isRangedWeapon <- function (_item) {
    local IT = ::Const.Items.ItemType;
    if (!_item.isItemType(IT.Weapon) || !_item.isItemType(IT.RangedWeapon) || _item.isItemType(IT.Ammo)) return false;
    if (_item.getSlotType() != ::Const.ItemSlot.Mainhand) return false;
    local name = def.weaponTypeName(_item);
    return name != "MagicStaff" && name != "Musical" && name != "Staff" && name != "Polearm" && name != "Throwing";
};

def.isTwoHanded <- function (_item) {
    return _item.isItemType(::Const.Items.ItemType.TwoHanded);
};

// Does this weapon belong in the hands of this role?
def.weaponFits <- function (_role, _item) {
    local R = def.Role;
    switch (_role) {
        case R.Tank:
        case R.Duelist:
            return def.isMeleeWeapon(_item) && !def.isTwoHanded(_item);
        case R.Striker:
            return def.isMeleeWeapon(_item) && def.isTwoHanded(_item) && !def.isPolearmItem(_item);
        case R.Polearm:
            return def.isMeleeWeapon(_item) && def.isTwoHanded(_item) && def.isPolearmItem(_item);
        case R.Archer:
            return def.isRangedWeapon(_item);
    }
    return false;
};

def.weaponScore <- function (_bro, _info, _item) {
    local v = _item.getValue() * def.condFactor(_item);
    local name = def.weaponTypeName(_item);
    if (name != null && (name in def.MasteryPerk) && _bro.getSkills().hasSkill(def.MasteryPerk[name])) v *= 1.35;
    if (name != null && name == _info.weapon) v *= 1.1;   // stick with what he knows
    return v;
};

def.isShield <- function (_item) {
    return _item.isItemType(::Const.Items.ItemType.Shield) && _item.getSlotType() == ::Const.ItemSlot.Offhand;
};

def.shieldScore <- function (_item) {
    local md = ("MeleeDefense" in _item.m) ? _item.m.MeleeDefense : 0;
    local rd = ("RangedDefense" in _item.m) ? _item.m.RangedDefense : 0;
    return (md + 0.5 * rd) * def.condFactor(_item) + _item.getValue() / 2000.0;
};

def.isBodyArmor <- function (_item) {
    return _item.isItemType(::Const.Items.ItemType.Armor) && _item.getSlotType() == ::Const.ItemSlot.Body;
};

def.isHelmet <- function (_item) {
    return _item.isItemType(::Const.Items.ItemType.Helmet) && _item.getSlotType() == ::Const.ItemSlot.Head;
};

def.armorValue <- function (_item) {
    if (_item == null) return 0;
    return ("getArmorMax" in _item) ? _item.getArmorMax() : _item.getConditionMax();
};

// Fatigue an item costs, as a positive number. Brawny takes 30% off armor and helmets.
def.penalty <- function (_info, _item) {
    if (_item == null || !("getStaminaModifier" in _item)) return 0.0;
    local p = -1.0 * _item.getStaminaModifier();
    if (p <= 0) return 0.0;
    if (_info != null && _info.brawny && (def.isBodyArmor(_item) || def.isHelmet(_item))) p *= 0.7;
    return p;
};

def.isQuiver <- function (_item) {
    return _item.isItemType(::Const.Items.ItemType.Ammo) && _item.getSlotType() == ::Const.ItemSlot.Ammo;
};

def.ammoFits <- function (_weapon, _ammo) {
    if (_weapon == null || _ammo == null) return false;
    if (!("getAmmoType" in _weapon) || !("getAmmoType" in _ammo)) return false;
    return def.isQuiver(_ammo) && _weapon.getAmmoType() == _ammo.getAmmoType();
};

def.ammoLeft <- function (_item) {
    return ("getAmmo" in _item) ? _item.getAmmo() : 0;
};

def.describe <- function (_item) {
    return _item == null ? "nothing" : _item.getName();
};
