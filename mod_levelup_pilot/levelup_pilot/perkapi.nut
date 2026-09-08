// One perk API for both rulesets. Vanilla: the single fixed tree in ::Const.Perks.PerkDefs and
// string IDs. Legends: per-background dynamic trees and ::Legends.Perk constants. Everything
// above this file talks in constant names ("Colossus", "SpecMace") and gets IDs back.
local def = ::LevelupPilot;

def.Perks <- {
    isLegends = ("Legends" in getroottable()) && ("Perk" in ::Legends) && ("Perks" in ::Legends)

    // Vanilla perk IDs by the same constant names Legends uses (verified against Legends' own
    // vanilla section, which preserves vanilla IDs; ShieldBash is the one Legends renames).
    VanillaIds = {
        Relentless = "perk.relentless", DevastatingStrikes = "perk.devastating_strikes", ShieldBash = "perk.shield_bash",
        FastAdaption = "perk.fast_adaption", CripplingStrikes = "perk.crippling_strikes", Colossus = "perk.colossus",
        NineLives = "perk.nine_lives", BagsAndBelts = "perk.bags_and_belts", Pathfinder = "perk.pathfinder",
        Adrenaline = "perk.adrenaline", Recover = "perk.recover", Student = "perk.student", CoupDeGrace = "perk.coup_de_grace",
        Bullseye = "perk.bullseye", Dodge = "perk.dodge", FortifiedMind = "perk.fortified_mind", HoldOut = "perk.hold_out",
        SteelBrow = "perk.steel_brow", QuickHands = "perk.quick_hands", Gifted = "perk.gifted", Backstabber = "perk.backstabber",
        Anticipation = "perk.anticipation", ShieldExpert = "perk.shield_expert", Brawny = "perk.brawny", Rotation = "perk.rotation",
        RallyTheTroops = "perk.rally_the_troops", Taunt = "perk.taunt", SpecMace = "perk.mastery.mace", SpecFlail = "perk.mastery.flail",
        SpecHammer = "perk.mastery.hammer", SpecAxe = "perk.mastery.axe", SpecCleaver = "perk.mastery.cleaver", SpecSword = "perk.mastery.sword",
        SpecDagger = "perk.mastery.dagger", SpecPolearm = "perk.mastery.polearm", SpecSpear = "perk.mastery.spear",
        SpecCrossbow = "perk.mastery.crossbow", SpecBow = "perk.mastery.bow", SpecThrowing = "perk.mastery.throwing",
        ReachAdvantage = "perk.reach_advantage", Overwhelm = "perk.overwhelm", LoneWolf = "perk.lone_wolf", Underdog = "perk.underdog",
        Footwork = "perk.footwork", Berserk = "perk.berserk", HeadHunter = "perk.head_hunter", Nimble = "perk.nimble",
        BattleForged = "perk.battle_forged", Fearsome = "perk.fearsome", Duelist = "perk.duelist", KillingFrenzy = "perk.killing_frenzy",
        Indomitable = "perk.indomitable", Steadfast = "perk.steadfast", SunderingStrikes = "perk.sundering_strikes", Stalwart = "perk.stalwart",
        BattleFlow = "perk.battle_flow", InspiringPresence = "perk.inspiring_presence", Captain = "perk.captain", BatteringRam = "perk.battering_ram"
    }

    // constant name -> perk ID string, or null if this ruleset has no such perk
    function idFor(_constName) {
        if (this.isLegends) {
            if (!(_constName in ::Legends.Perk)) return null;
            local c = ::Legends.Perk[_constName];
            if (c == null) return null;
            return ::Legends.Perks.getID(c);
        }
        return (_constName in this.VanillaIds) ? this.VanillaIds[_constName] : null;
    }

    // Rows of {ID, Const, Row} for this bro. Vanilla: everyone shares one tree.
    function treeRows(_bro) {
        local rows = [];
        if (this.isLegends) {
            local bg = _bro.getBackground();
            if (bg == null) return rows;
            foreach (r, row in bg.getPerkTree()) {
                local out = [];
                foreach (p in row) {
                    if (!("ID" in p)) continue;
                    out.push({ID = p.ID, Const = ("Const" in p) ? p.Const : p.ID, Row = ("Row" in p) ? p.Row : r});
                }
                rows.push(out);
            }
            return rows;
        }
        if (!("Perks" in ::Const) || !("PerkDefs" in ::Const.Perks)) return rows;
        local defs = ::Const.Perks.PerkDefs;
        if (typeof defs != "array") return rows;
        local reverse = {};
        foreach (k, v in this.VanillaIds) reverse[v] <- k;
        foreach (r, row in defs) {
            local out = [];
            foreach (p in row) {
                if (!("ID" in p)) continue;
                out.push({ID = p.ID, Const = (p.ID in reverse) ? reverse[p.ID] : p.ID, Row = ("Unlocks" in p) ? p.Unlocks : r});
            }
            rows.push(out);
        }
        return rows;
    }

    function inTree(_bro, _id) {
        if (this.isLegends) {
            local bg = _bro.getBackground();
            return bg != null && bg.getPerk(_id) != null;
        }
        foreach (row in this.treeRows(_bro)) {
            foreach (p in row) if (p.ID == _id) return true;
        }
        return false;
    }
}
