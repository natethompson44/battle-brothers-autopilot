// Company Starts - custom starting scenarios built for autonomous play.
// Scenario files under scripts/scenarios/world/ are picked up by the game on their own; this file
// registers the mod and holds the shared roster-building helpers the scenarios call.
local def = ::WolfeoStarts <- {
    ID = "mod_company_starts"
    Name = "Company Starts"
    Version = "1.0.0"
}
::Hooks.register(def.ID, def.Version, def.Name);

// weapon / offhand / body / head / talents per role. All vanilla scripts.
def.Kits <- {
    tank = {
        weapon = ["scripts/items/weapons/fighting_spear", "scripts/items/weapons/arming_sword"]
        offhand = ["scripts/items/shields/heater_shield", "scripts/items/shields/kite_shield"]
        body = "scripts/items/armor/mail_shirt"
        head = "scripts/items/helmets/nasal_helmet_with_mail"
        talents = ["MeleeDefense", "MeleeSkill", "Hitpoints"]
        bump = {MeleeDefense = 6, MeleeSkill = 4, Hitpoints = 5}
    }
    striker = {
        weapon = ["scripts/items/weapons/greatsword", "scripts/items/weapons/greataxe"]
        offhand = []
        body = "scripts/items/armor/mail_hauberk"
        head = "scripts/items/helmets/kettle_hat_with_mail"
        talents = ["MeleeSkill", "Fatigue", "Hitpoints"]
        bump = {MeleeSkill = 8, Stamina = 8, Hitpoints = 5}
    }
    polearm = {
        weapon = ["scripts/items/weapons/billhook", "scripts/items/weapons/pike"]
        offhand = []
        body = "scripts/items/armor/basic_mail_shirt"
        head = "scripts/items/helmets/flat_top_helmet"
        talents = ["MeleeSkill", "Fatigue", "Initiative"]
        bump = {MeleeSkill = 8, Stamina = 5}
    }
    archer = {
        weapon = ["scripts/items/weapons/war_bow", "scripts/items/weapons/hunting_bow"]
        offhand = []
        bag = ["scripts/items/weapons/shortsword"]
        body = "scripts/items/armor/padded_surcoat"
        head = "scripts/items/helmets/hunters_hat"
        talents = ["RangedSkill", "RangedDefense", "Initiative"]
        bump = {RangedSkill = 10, Initiative = 8}
    }
    duelist = {
        weapon = ["scripts/items/weapons/arming_sword", "scripts/items/weapons/military_cleaver"]
        offhand = []
        body = "scripts/items/armor/mail_shirt"
        head = "scripts/items/helmets/nasal_helmet"
        talents = ["MeleeSkill", "MeleeDefense", "Initiative"]
        bump = {MeleeSkill = 6, MeleeDefense = 6}
    }
    banner = {
        weapon = ["scripts/items/tools/player_banner"]
        offhand = []
        body = "scripts/items/armor/mail_hauberk"
        head = "scripts/items/helmets/kettle_hat_with_mail"
        talents = ["Bravery", "MeleeDefense", "Hitpoints"]
        bump = {Bravery = 12, MeleeDefense = 4}
    }
};

// A fresh roster member with a background, a name and a title.
def.makeBro <- function (_scenario, _roster, _background, _name = null, _title = null) {
    local bro = _roster.create("scripts/entity/tactical/player");
    bro.m.HireTime = _scenario.Time.getVirtualTimeF();
    bro.setStartValuesEx([_background + "_background"]);
    if (_name != null) bro.setName(_name);
    else bro.setName(_scenario.Const.Strings.CharacterNames[_scenario.Math.rand(0, _scenario.Const.Strings.CharacterNames.len() - 1)]);
    if (_title != null) bro.setTitle(_title);
    return bro;
}

local function pick(_scenario, _list) {
    return _list[_scenario.Math.rand(0, _list.len() - 1)];
}

local function setTalents(_bro, _names, _stars) {
    local A = ::Const.Attributes;
    _bro.m.Talents = [];
    _bro.m.Attributes = [];
    local t = _bro.getTalents();
    t.resize(A.COUNT, 0);
    foreach (i, n in _names) {
        if (n in A) t[A[n]] = _stars[i];
    }
    _bro.fillAttributeLevelUpValues(::Const.XP.MaxLevelWithPerkpoints - 1);
}

local function setLevel(_bro, _level, _perkPoints) {
    _bro.m.Level = _level;
    _bro.m.LevelUps = _level - 1;
    _bro.m.PerkPoints = _perkPoints;
    if (("LevelXP" in ::Const) && ::Const.LevelXP.len() >= _level) _bro.m.XP = ::Const.LevelXP[_level - 1];
}

// One mid-grade companion: role kit, role talents, a few levels to spend, and a war dog.
def.makeCompanion <- function (_scenario, _roster, _background, _role, _slot) {
    local bro = def.makeBro(_scenario, _roster, _background);
    local kit = def.Kits[_role];
    local items = bro.getItems();

    // A clean kit that says what he is. Whatever the background rolled goes to the stash.
    foreach (slot in [::Const.ItemSlot.Mainhand, ::Const.ItemSlot.Offhand, ::Const.ItemSlot.Body, ::Const.ItemSlot.Head, ::Const.ItemSlot.Accessory]) {
        local old = items.getItemAtSlot(slot);
        if (old != null) {
            items.unequip(old);
            _scenario.World.Assets.getStash().add(old);
        }
    }
    items.equip(_scenario.new(pick(_scenario, kit.weapon)));
    if (kit.offhand.len() > 0) items.equip(_scenario.new(pick(_scenario, kit.offhand)));
    items.equip(_scenario.new(kit.body));
    items.equip(_scenario.new(kit.head));
    items.equip(_scenario.new("scripts/items/accessory/wardog_item"));
    if ("bag" in kit) foreach (b in kit.bag) items.addToBag(_scenario.new(b));

    local b = bro.getBaseProperties();
    foreach (k, v in kit.bump) {
        if (k in b) b[k] += v;
    }
    setTalents(bro, kit.talents, [3, 2, 2]);
    setLevel(bro, 4, 3);
    bro.setPlaceInFormation(_slot);
    bro.getSkills().update();
    return bro;
}

// The avatar: swordmaster base, the Nightblade trait (Blink, +3 AP), a named greatsword,
// named armor, level 8, a full two-hander build, and every level's attributes left for the
// level-up mod to spend on day one.
def.makeWolfeo <- function (_scenario, _bro) {
    local items = _bro.getItems();
    foreach (slot in [::Const.ItemSlot.Mainhand, ::Const.ItemSlot.Offhand, ::Const.ItemSlot.Body, ::Const.ItemSlot.Head]) {
        local old = items.getItemAtSlot(slot);
        if (old != null) {
            items.unequip(old);
            _scenario.World.Assets.getStash().add(old);
        }
    }
    items.equip(_scenario.new("scripts/items/weapons/named/named_greatsword"));
    items.equip(_scenario.new("scripts/items/armor/named/named_sellswords_armor"));
    items.equip(_scenario.new("scripts/items/helmets/closed_flat_top_with_mail"));

    _bro.getFlags().set("IsPlayerCharacter", true);
    _bro.getSkills().add(_scenario.new("scripts/skills/traits/player_character_trait"));
    _bro.getSkills().add(_scenario.new("scripts/skills/traits/wolfeo_trait"));

    local b = _bro.getBaseProperties();
    b.MeleeSkill += 15;
    b.MeleeDefense += 8;
    b.Hitpoints += 15;
    b.Stamina += 20;
    b.Bravery += 10;
    b.Initiative += 10;

    setTalents(_bro, ["MeleeSkill", "MeleeDefense", "Fatigue"], [3, 3, 3]);
    setLevel(_bro, 8, 0);
    foreach (p in ["perk_colossus", "perk_reach_advantage", "perk_berserk", "perk_killing_frenzy", "perk_battle_forged",
                   "perk_mastery_sword", "perk_underdog", "perk_recover", "perk_fortified_mind", "perk_pathfinder", "perk_brawny"]) {
        _bro.getSkills().add(_scenario.new("scripts/skills/perks/" + p));
    }
    _bro.m.PerkPointsSpent = 11;
    _bro.setPlaceInFormation(4);
    _bro.getSkills().update();
}

// Spawn on a road tile next to a decent village. Same approach as the stock scenarios.
def.spawnNearVillage <- function (_s) {
    local village = null;
    foreach (v in _s.World.EntityManager.getSettlements()) {
        if (!v.isIsolatedFromRoads() && v.getSize() >= 2 && (!("isSouthern" in v) || !v.isSouthern())) {
            village = v;
            break;
        }
    }
    if (village == null) village = _s.World.EntityManager.getSettlements()[0];
    local vt = village.getTile();
    local spawn = vt;
    for (local tries = 0; tries < 200; tries++) {
        local x = _s.Math.rand(_s.Math.max(2, vt.SquareCoords.X - 2), _s.Math.min(_s.Const.World.Settings.SizeX - 2, vt.SquareCoords.X + 2));
        local y = _s.Math.rand(_s.Math.max(2, vt.SquareCoords.Y - 2), _s.Math.min(_s.Const.World.Settings.SizeY - 2, vt.SquareCoords.Y + 2));
        if (!_s.World.isValidTileSquare(x, y)) continue;
        local tile = _s.World.getTileSquare(x, y);
        if (tile.Type == _s.Const.World.TerrainType.Ocean || tile.Type == _s.Const.World.TerrainType.Shore) continue;
        if (tile.getDistanceTo(vt) == 0 || !tile.HasRoad) continue;
        spawn = tile;
        break;
    }
    _s.World.State.m.Player = _s.World.spawnEntity("scripts/entity/world/player_party", spawn.Coords.X, spawn.Coords.Y);
    _s.World.Assets.updateLook(6);
    _s.World.getCamera().setPos(_s.World.State.m.Player.getPos());
}
