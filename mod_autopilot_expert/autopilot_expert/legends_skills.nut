// Teach the vanilla AI behaviors about Legends skills. Legends' own actives inherit from the base
// skill class and declare no AI behavior, so an autopiloted Legends bro never used them.
// Same technique Autopilot uses for Fantasy Brothers / Reforged: extend each behavior's skill list.
local def = ::AutopilotExpert;
local mod = def.mh;

local B = "scripts/ai/tactical/behaviors/";

// behavior script -> Legends skill IDs it should consider
def.LegendsSkills <- {};
def.LegendsSkills[B + "ai_attack_default"] <- [
    "actives.legend_hew"              // 2H axe overhead
    "actives.legend_halberd_smite"    // halberd, reach 2
    // legend_haftstrike deliberately left out: Legends' own AI hook excludes it because the AI
    // then wastes turns on weak haft hits.
    "actives.legend_staff_thrust"
    "actives.legend_wooden_stake_stab"
    "actives.legend_heartseeker"      // injuring thrust
    "actives.legend_ranged_flail"     // 2-tile flail
    "actives.legend_ranged_lash"
    "actives.legend_pry_armor"
    "actives.legend_choke"
    "actives.legend_scythe_cleave"    // reach 2
    "actives.legend_staff_lunge"      // 2-tile lunge, same class as vanilla lunge
    "actives.legend_into_the_fray"
    "actives.legend_slingstaff_bash"
    "actives.legend_throw_knife"      // ranged skill for a melee bro; only usable when not engaged
];
def.LegendsSkills[B + "ai_attack_split"] <- [
    "actives.legend_run_through"      // two targets in a line, like ignite firelance
];
def.LegendsSkills[B + "ai_attack_swing"] <- [
    "actives.legend_double_swing"     // 3-tile arc, same geometry as swing
];
def.LegendsSkills[B + "ai_attack_puncture"] <- [
    "actives.legend_puncture_parry_dagger"
];
// Only real disarms here. Kick / Grapple / Tackle / Buckler Bash were in this list in 1.0.x and
// the knock-out behavior rated them like stuns, so bros kicked instead of hitting. Kick now has
// its own behavior (stance breaker); the others are left to the player.
def.LegendsSkills[B + "ai_attack_knock_out"] <- [
    "actives.legend_warfork_disarm"
    "actives.legend_ninetails_disarm"
];
// Magic staff attacks: single-target ranged spells. A necromancer / warlock without these known
// to the ranged AI just walks toward the enemy all battle.
def.MagicAttacks <- [
    "actives.legend_magic_missile"
    "actives.legend_magic_chain_lightning"
    "actives.legend_chain_lightning"
    "actives.legend_magic_hailstone"
    "actives.legend_shoot_dart"
];
// legend_cascade is left out: Legends' implementation calls setBusy() on the skill container,
// which does not exist in this game version, and throws a script error every time it fires.
def.LegendsSkills[B + "ai_attack_bow"] <- [
    "actives.legend_piercing_bolt"
    "actives.legend_piercing_shot"
    "actives.legend_shoot_stone"
    "actives.legend_shoot_precise_stone"
    "actives.legend_sling_heavy_stone"
];
def.LegendsSkills[B + "ai_attack_bow"].extend(def.MagicAttacks);
// engage_ranged decides where a ranged bro walks to; it needs the same skill list to know its range.
def.LegendsSkills[B + "ai_engage_ranged"] <- clone def.MagicAttacks;
def.LegendsSkills[B + "ai_attack_handgonne"] <- [
    "actives.legend_line_them_up"
];
def.LegendsSkills[B + "ai_defend_spearwall"] <- [
    "actives.legend_staffwall"
];
def.LegendsSkills[B + "ai_defend_riposte"] <- [
    "actives.legend_staff_riposte"
];
def.LegendsSkills[B + "ai_defend_shieldwall"] <- [
    "actives.legend_fortify"
];
// Second Wind is a strictly better Recover (no turn end) and is only usable at > 50% fatigue,
// so it goes to the front of the list.
def.LegendsSkills[B + "ai_recover"] <- [
    "actives.legend_second_wind"
];

foreach (script, ids in def.LegendsSkills) {
    local isRecover = script == B + "ai_recover";
    mod.hook(script, function (q) {
        if (!q.m.contains("PossibleSkills")) {
            ::logWarning("autopilot expert: " + script + " has no PossibleSkills, skipping");
            return;
        }
        foreach (id in ids) {
            if (q.m.PossibleSkills.find(id) != null) continue;
            if (isRecover) q.m.PossibleSkills.insert(0, id);
            else q.m.PossibleSkills.push(id);
        }
    });
}

// Make sure the behavior that knows a skill is actually on the agent. Military agents carry the
// usual attack/defend set, but a bro may have been given a skill whose behavior is missing.
// MSU dedupes addBehavior by ID, so adding an existing one is harmless.
def.ensureBehaviorsForSkills <- function (_actor, _agent) {
    local skills = _actor.getSkills();
    foreach (script, ids in def.LegendsSkills) {
        foreach (id in ids) {
            if (!skills.hasSkill(id)) continue;
            _agent.addBehavior(::new(script));
            def.dbg(_actor.getName() + " has " + id + " -> ensured " + script);
            break;
        }
    }
}
