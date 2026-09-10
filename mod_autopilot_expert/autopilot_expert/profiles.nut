// Role detection and per-role agent tuning. All numbers here are agent property multipliers the
// game itself uses for every enemy type; they cannot crash anything, only change preferences.
local def = ::AutopilotExpert;
local R = def.Role;

// Shared by all roles: focus fire, prefer hits that land, finish what you started.
local Common = {
    TargetPriorityHitchanceMult = 1.0        // vanilla military ~0.5
    TargetPriorityFinishOpponentMult = 4.0   // vanilla ~3.0
    TargetPriorityHitpointsMult = 0.4        // prefer wounded, vanilla ~0.25
    TargetPriorityRandomMult = 0.0
};

local Profiles = {};
Profiles[R.Tank] <- {
    EngageFlankingMult = 0.5                 // stay in the line, don't run around
    OverallFormationMult = 1.5
    OverallDefensivenessMult = 1.5
    EngageTargetMultipleOpponentsMult = 0.5  // don't step where 2+ enemies can reach you
    EngageTargetAlreadyBeingEngagedMult = 1.25
    TargetPriorityFleeingMult = 0.6
    PreferCarefulEngage = true
};
Profiles[R.Striker] <- {
    EngageFlankingMult = 1.0
    OverallFormationMult = 1.0
    OverallDefensivenessMult = 0.8
    EngageTargetMultipleOpponentsMult = 0.5
    EngageTargetAlreadyBeingEngagedMult = 1.5   // gang up
    EngageTargetArmedWithRangedWeaponMult = 1.5 // archers die first
    TargetPriorityFinishOpponentMult = 4.5
    TargetPriorityDamageMult = 0.4
    TargetPriorityFleeingMult = 0.8
};
Profiles[R.Polearm] <- {
    OverallFormationMult = 1.5
    OverallDefensivenessMult = 1.5
    EngageTargetMultipleOpponentsMult = 0.3
    EngageTargetAlreadyBeingEngagedMult = 1.5   // hit what the front line is fighting
    TargetPriorityFleeingMult = 0.5
};
Profiles[R.Ranged] <- {
    EngageTargetArmedWithRangedWeaponMult = 2.0 // counter-battery
    OverallDefensivenessMult = 1.5
    OverallFormationMult = 1.25
    TargetPriorityFleeingMult = 0.5
};
Profiles[R.Thrower] <- {
    EngageTargetAlreadyBeingEngagedMult = 1.25
    TargetPriorityFleeingMult = 0.7
};
Profiles[R.Banner] <- {
    EngageFlankingMult = 0.3
    OverallFormationMult = 1.5
    OverallDefensivenessMult = 1.5
    EngageTargetMultipleOpponentsMult = 0.3
    TargetPriorityFleeingMult = 0.5
};

// Static behavior weight tweaks per role (multiplied into autopilot's own weights).
local BehaviorTweaks = {};
BehaviorTweaks[R.Tank] <- {Shieldwall = 1.5, Spearwall = 1.5, Riposte = 1.2};
BehaviorTweaks[R.Banner] <- {Rally = 1.5, Shieldwall = 1.3};
BehaviorTweaks[R.Polearm] <- {Spearwall = 1.3};

def.detectRole <- function (_actor) {
    local mode = _actor.m._autopilot;
    local skills = _actor.getSkills();
    if (skills.hasSkill("actives.rally_the_troops")) return R.Banner;
    if (mode.throwing) return R.Thrower;
    if (mode.ranged) return R.Ranged;
    if (_actor.getIdealRange() == 2) return R.Polearm;
    local off = _actor.getItems().getItemAtSlot(::Const.ItemSlot.Offhand);
    if (off != null && off.isItemType(::Const.Items.ItemType.Shield)) return R.Tank;
    return R.Striker;
}

local function applyProps(_props, _table, _who) {
    foreach (k, v in _table) {
        if (k in _props) _props[k] = v;
        else def.dbg(_who + ": agent has no property " + k + ", skipped");
    }
}

local function behaviorID(_name) {
    local ids = ::Const.AI.Behavior.ID;
    return (_name in ids) ? ids[_name] : null;
}

// Multiply a behavior weight. Before autopilot's first onUpdate the live array is the source of
// truth (it gets cloned into autopilot_mults); afterwards autopilot_mults is.
local function tweakBehavior(_agent, _name, _mult, _who) {
    local id = behaviorID(_name);
    if (id == null) {
        def.dbg(_who + ": no behavior named " + _name + ", skipped");
        return;
    }
    local arr = ("autopilot_mults" in _agent) ? _agent.autopilot_mults : _agent.m.Properties.BehaviorMult;
    if (id < arr.len()) arr[id] *= _mult;
}

// Called right after autopilot's enableAIControl() built the agent.
def.setupAgent <- function (_actor, _agent) {
    local role = def.detectRole(_actor);
    _actor.m._autopilot.role <- role;
    def.dbg(_actor.getName() + " role = " + role);

    if (def.conf("profiles")) {
        local props = _agent.m.Properties;
        applyProps(props, Common, _actor.getName());
        applyProps(props, Profiles[role], _actor.getName());
        if (role in BehaviorTweaks) {
            foreach (name, mult in BehaviorTweaks[role]) tweakBehavior(_agent, name, mult, _actor.getName());
        }
        _agent.apx_origPreferWait <- ("PreferWait" in props) ? props.PreferWait : null;
    }

    def.ensureBehaviorsForSkills(_actor, _agent);

    local skills = _actor.getSkills();
    local has = function (_ids) {
        foreach (id in _ids) if (skills.hasSkill(id)) return true;
        return false;
    };

    // Legends necromancy. Autopilot only wires up the vanilla necromancer skills, so a Legends
    // necromancer otherwise never raises anything. Stay back and let the puppets fight.
    if (has(def.NecroSkills) || has(def.SummonSkills)) {
        _agent.addBehavior(::new("scripts/ai/autopilot_expert_raise"));
        local protect = behaviorID("Protect");
        if (protect != null) _agent.removeBehavior(protect);
        // A necromancer's job is to stand behind the puppets, not to poke with a polearm from
        // where enemy polearms can reach her. Nearly no engaging, quick to disengage, keep distance.
        tweakBehavior(_agent, "EngageMelee", 0.1, _actor.getName());
        tweakBehavior(_agent, "AttackDefault", 0.5, _actor.getName());
        tweakBehavior(_agent, "Disengage", 3.0, _actor.getName());
        foreach (script in ["scripts/ai/tactical/behaviors/ai_engage_ranged", "scripts/ai/tactical/behaviors/ai_keep_safe"]) {
            try { _agent.addBehavior(::new(script)); } catch (e) { def.dbg("no " + script + ": " + e); }
        }
        local props = _agent.m.Properties;
        foreach (k, v in {OverallDefensivenessMult = 2.0, PreferCarefulEngage = true, EngageRangeMin = 3, EngageRangeIdeal = 4, EngageRangeMax = 6}) {
            if (k in props) props[k] = v;
        }
        _actor.m._autopilot.necro <- true;
        def.dbg(_actor.getName() + " is a necromancer / summoner");
    }

    // Musicians: the songs are the point, the lute is not a weapon.
    local mainhand = _actor.getItems().getItemAtSlot(::Const.ItemSlot.Mainhand);
    if (mainhand != null && ("Musical" in ::Const.Items.WeaponType) && mainhand.isWeaponType(::Const.Items.WeaponType.Musical)) {
        tweakBehavior(_agent, "AttackDefault", 0.4, _actor.getName());
        tweakBehavior(_agent, "APX_Aura", 1.8, _actor.getName());
        def.dbg(_actor.getName() + " is a musician");
    }

    // Everyone: Adrenaline every single turn is a fatigue sink, not a tactic.
    tweakBehavior(_agent, "Adrenaline", 0.4, _actor.getName());

    // Kick: only worth it to knock an enemy out of shieldwall / spearwall / riposte.
    if (skills.hasSkill("actives.legend_kick")) _agent.addBehavior(::new("scripts/ai/autopilot_expert_kick"));
    // Blink (Company Starts' Wolfeo): strike from range, escape when mobbed. He is not a line
    // unit, so no holding and a lot less caution about leaving the formation.
    if (skills.hasSkill("actives.wolfeo_blink")) {
        _agent.addBehavior(::new("scripts/ai/autopilot_expert_blink"));
        tweakBehavior(_agent, "Disengage", 2.0, _actor.getName());
        local props = _agent.m.Properties;
        foreach (k, v in {OverallFormationMult = 0.3, EngageFlankingMult = 2.0, TargetPriorityFinishOpponentMult = 5.0}) {
            if (k in props) props[k] = v;
        }
        _actor.m._autopilot.blinker <- true;
        def.dbg(_actor.getName() + " is a blinker");
    }

    if (def.conf("support")) {
        if (has(def.AuraSkills)) _agent.addBehavior(::new("scripts/ai/autopilot_expert_aura"));
        if (has(def.AidSkills)) _agent.addBehavior(::new("scripts/ai/autopilot_expert_aid"));
        if (skills.hasSkill("actives.legend_mark_target")) _agent.addBehavior(::new("scripts/ai/autopilot_expert_mark"));
    }

    // Dynamic part: runs after autopilot's own onUpdate wrapper every time the agent updates.
    local prevUpdate = _agent.onUpdate;
    _agent.onUpdate = function () {
        prevUpdate();
        try {
            ::AutopilotExpert.onAgentUpdate(this);
        } catch (e) {
            ::logError("autopilot expert: onAgentUpdate failed: " + e);
        }
    }
}

def.AuraSkills <- [
    "actives.legend_hold_the_line"
    "actives.legend_push_forward"
    "actives.legend_incoming"
    "actives.legend_coordinated_volleys"
    "actives.legend_guide_steps"
    "actives.legend_prayer_of_faith"
    "actives.legend_drums_of_war"
    "actives.legend_prayer_of_life"
    "actives.legend_drums_of_life"
];
def.AidSkills <- [
    "actives.legend_bandage"
    "actives.legend_field_triage"
    "actives.legend_field_treats"
];
def.NecroSkills <- [
    "actives.legend_raise_undead"
    "actives.legend_possession"
];
// Warlock summoner and friends: spawn a puppet from the stash onto an empty tile nearby.
def.SummonSkills <- [
    "actives.legend_spawn_zombie_low"
    "actives.legend_spawn_zombie_med"
    "actives.legend_spawn_zombie_high"
    "actives.legend_spawn_zombie_low_xbow"
    "actives.legend_spawn_zombie_med_xbow"
    "actives.legend_spawn_zombie_high_xbow"
    "actives.legend_spawn_skeleton_low"
    "actives.legend_spawn_skeleton_med"
    "actives.legend_spawn_skeleton_high"
    "actives.legend_spawn_skeleton_low_archer"
    "actives.legend_spawn_skeleton_med_archer"
    "actives.legend_spawn_skeleton_high_archer"
];

// A magic staff counts as a ranged weapon for the game, so Autopilot gives its wielder the ranged
// AI. Without an actual ranged spell that AI has nothing to shoot and just walks at the enemy all
// battle. Treat such a bro as a reach-2 melee fighter instead.
def.shouldForceMelee <- function (_actor) {
    local main = _actor.getItems().getItemAtSlot(::Const.ItemSlot.Mainhand);
    if (main == null || !main.isWeaponType(::Const.Items.WeaponType.MagicStaff)) return false;
    local skills = _actor.getSkills();
    foreach (id in def.MagicAttacks) {
        if (skills.hasSkill(id)) return false;
    }
    return true;
}

local HoldRoles = [R.Tank, R.Striker, R.Polearm, R.Banner];

def.onAgentUpdate <- function (_agent) {
    local actor = _agent.getActor();
    if (actor == null || !def.isUnderAIControl(actor)) return;
    local mode = actor.m._autopilot;
    if (!("role" in mode)) return;
    local role = mode.role;
    local props = _agent.m.Properties;

    // Re-apply static profile in case the vanilla onUpdate touched anything.
    if (def.conf("profiles")) {
        applyProps(props, Common, actor.getName());
        applyProps(props, Profiles[role], actor.getName());
    }

    local round = def.getRound();

    // A blinker who just blinked out of a fight stays out for the rest of that turn; otherwise
    // the engage behavior walks him straight back in with whatever AP is left.
    if (("blinker" in mode) && mode.blinker) {
        if (("apx_stayOutRound" in _agent) && _agent.apx_stayOutRound == round) {
            props.BehaviorMult[::Const.AI.Behavior.ID.EngageMelee] *= 0.05;
        }
        return;
    }

    // Early-round line holding: wait for them to come, unless they outgun us at range.
    if (!def.conf("holdline") || HoldRoles.find(role) == null) return;
    local holding = false;
    if (round <= def.conf("holdrounds")) {
        local f = def.scan(actor);
        local outgunned = f.enemyRanged >= 2 && f.enemyRanged > f.allyRanged;
        // Holding only pays if the enemy is actually coming. Compare the closest enemy distance
        // with the previous round's: closer means they are coming and we hold, otherwise we
        // advance this round and check again next round.
        if (!("apx_hold" in _agent) || _agent.apx_hold.round != round) {
            local prev = ("apx_hold" in _agent) ? _agent.apx_hold : null;
            local approaching = prev == null || f.nearest < prev.nearest;
            _agent.apx_hold <- {round = round, nearest = f.nearest, approaching = approaching};
            if (!approaching) def.dbg(actor.getName() + " enemy is not approaching, advancing this round");
        }
        holding = f.nearest > 3 && !outgunned && _agent.apx_hold.approaching;
        if (holding) {
            local id = ::Const.AI.Behavior.ID.EngageMelee;
            props.BehaviorMult[id] *= 0.2;
            def.dbg(actor.getName() + " holds the line (round " + round + ", nearest enemy " + f.nearest + ")");
        }
    }
    if ("PreferWait" in props) {
        if (holding) props.PreferWait = true;
        else if ("apx_origPreferWait" in _agent && _agent.apx_origPreferWait != null) props.PreferWait = _agent.apx_origPreferWait;
    }
}
