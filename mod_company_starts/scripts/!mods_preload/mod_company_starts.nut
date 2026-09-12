// Company Starts - custom starting scenarios built for autonomous play.
// Scenario files under scripts/scenarios/world/ are picked up by the game on their own; this file
// registers the mod and holds the shared roster-building helpers the scenarios call.
local def = ::WolfeoStarts <- {
    ID = "mod_company_starts"
    Name = "Company Starts"
    Version = "1.1.0"
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
    bro.m.HireTime = ::Time.getVirtualTimeF();
    bro.setStartValuesEx([_background + "_background"]);
    if (_name != null) bro.setName(_name);
    else bro.setName(::Const.Strings.CharacterNames[::Math.rand(0, ::Const.Strings.CharacterNames.len() - 1)]);
    if (_title != null) bro.setTitle(_title);
    return bro;
}

local function pick(_scenario, _list) {
    return _list[::Math.rand(0, _list.len() - 1)];
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
            ::World.Assets.getStash().add(old);
        }
    }
    items.equip(::new(pick(_scenario, kit.weapon)));
    if (kit.offhand.len() > 0) items.equip(::new(pick(_scenario, kit.offhand)));
    items.equip(::new(kit.body));
    items.equip(::new(kit.head));
    items.equip(::new("scripts/items/accessory/wardog_item"));
    if ("bag" in kit) foreach (b in kit.bag) items.addToBag(::new(b));

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
            ::World.Assets.getStash().add(old);
        }
    }
    items.equip(::new("scripts/items/weapons/named/named_greatsword"));
    items.equip(::new("scripts/items/armor/named/named_sellswords_armor"));
    items.equip(::new("scripts/items/helmets/closed_flat_top_with_mail"));

    _bro.getFlags().set("IsPlayerCharacter", true);
    _bro.getSkills().add(::new("scripts/skills/traits/player_character_trait"));
    _bro.getSkills().add(::new("scripts/skills/traits/wolfeo_trait"));

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
        _bro.getSkills().add(::new("scripts/skills/perks/" + p));
    }
    _bro.m.PerkPointsSpent = 11;
    _bro.setPlaceInFormation(4);
    _bro.getSkills().update();
}

// True when the Blazing Deserts content is available (assassin background, qatal dagger).
def.hasDesert <- function () {
    return ("DLC" in ::Const) && ("Desert" in ::Const.DLC) && ::Const.DLC.Desert == true;
}

// A fully specified roster member. _spec fields (all optional except talents):
//   weapon, offhand, body, head, ammo, accessory   item script paths
//   bag                                            array of item script paths
//   talents / stars                                attribute names and star counts
//   bump                                           base property increments (Stamina, not Fatigue)
//   perks                                          perk script names granted outright
//   level / points                                 level and perk points left to spend
//   traits                                         trait script paths added on top
def.makeMember <- function (_scenario, _roster, _background, _name, _title, _spec, _slot) {
    local bro = def.makeBro(_scenario, _roster, _background, _name, _title);
    local items = bro.getItems();
    foreach (slot in [::Const.ItemSlot.Mainhand, ::Const.ItemSlot.Offhand, ::Const.ItemSlot.Body, ::Const.ItemSlot.Head, ::Const.ItemSlot.Accessory, ::Const.ItemSlot.Ammo]) {
        local old = items.getItemAtSlot(slot);
        if (old != null) {
            items.unequip(old);
            ::World.Assets.getStash().add(old);
        }
    }
    foreach (k in ["weapon", "offhand", "body", "head", "ammo", "accessory"]) {
        if (k in _spec && _spec[k] != null) items.equip(::new(_spec[k]));
    }
    if ("bag" in _spec) foreach (b in _spec.bag) items.addToBag(::new(b));

    if ("bump" in _spec) {
        local b = bro.getBaseProperties();
        foreach (k, v in _spec.bump) {
            if (k in b) b[k] += v;
        }
    }
    setTalents(bro, _spec.talents, ("stars" in _spec) ? _spec.stars : [3, 2, 2]);

    local perks = ("perks" in _spec) ? _spec.perks : [];
    foreach (p in perks) bro.getSkills().add(::new("scripts/skills/perks/" + p));
    setLevel(bro, ("level" in _spec) ? _spec.level : 4, ("points" in _spec) ? _spec.points : 2);
    bro.m.PerkPointsSpent = perks.len();

    if ("traits" in _spec) foreach (t in _spec.traits) bro.getSkills().add(::new(t));
    bro.setPlaceInFormation(_slot);
    bro.getSkills().update();
    return bro;
}

// Turn a roster member into the player's avatar.
def.makeAvatar <- function (_bro) {
    _bro.getFlags().set("IsPlayerCharacter", true);
    _bro.getSkills().add(::new("scripts/skills/traits/player_character_trait"));
}

// Spawn on a road tile next to a decent village. Same approach as the stock scenarios.
def.spawnNearVillage <- function (_s, _introEvent = null) {
    local village = null;
    foreach (v in ::World.EntityManager.getSettlements()) {
        if (!v.isIsolatedFromRoads() && v.getSize() >= 2 && (!("isSouthern" in v) || !v.isSouthern())) {
            village = v;
            break;
        }
    }
    if (village == null) village = ::World.EntityManager.getSettlements()[0];
    local vt = village.getTile();
    local spawn = vt;
    for (local tries = 0; tries < 200; tries++) {
        local x = ::Math.rand(::Math.max(2, vt.SquareCoords.X - 2), ::Math.min(::Const.World.Settings.SizeX - 2, vt.SquareCoords.X + 2));
        local y = ::Math.rand(::Math.max(2, vt.SquareCoords.Y - 2), ::Math.min(::Const.World.Settings.SizeY - 2, vt.SquareCoords.Y + 2));
        if (!::World.isValidTileSquare(x, y)) continue;
        local tile = ::World.getTileSquare(x, y);
        if (tile.Type == ::Const.World.TerrainType.Ocean || tile.Type == ::Const.World.TerrainType.Shore) continue;
        if (tile.getDistanceTo(vt) == 0 || !tile.HasRoad) continue;
        spawn = tile;
        break;
    }
    ::World.State.m.Player = ::World.spawnEntity("scripts/entity/world/player_party", spawn.Coords.X, spawn.Coords.Y);
    ::World.Assets.updateLook(6);
    ::World.getCamera().setPos(::World.State.m.Player.getPos());

    // Same as the stock origins: a beat later, start the music and fire the intro event. Closing
    // the event is what hands the world clock back to the player.
    ::Time.scheduleEvent(::TimeUnit.Real, 1000, function ( _tag )
    {
        local tracks = ("CivilianTracks" in ::Const.Music) ? ::Const.Music.CivilianTracks : ::Const.Music.WorldmapTracks;
        ::Music.setTrackList(tracks, ::Const.Music.CrossFadeTime);
        if (_tag.event != null) ::World.Events.fire(_tag.event);
        else ::World.State.setPause(false);
    }, {event = _introEvent});
}
