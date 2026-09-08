// Non-"player" actors on the player's side: summoned puppets, raised undead, pets, anything that
// joins mid-battle. Autopilot only implements enableAIControl/cancelAIControl on the player class,
// so these fell through to manual control with no usable UI. Give them the same treatment.
local def = ::AutopilotExpert;
local mod = def.mh;

// Agents that mean "nobody is driving this unit". Legends summons get an idle_agent.
local function isDummyAgent(_agent) {
    return _agent == null || _agent.ClassName == "player_agent" || _agent.ClassName == "idle_agent";
}

// A player-side unit the AI should take over but Autopilot's canAuto() does not recognize:
// summoned puppets, raised undead, pets, reinforcements that are not "player" objects.
def.canAutoAlly <- function (_e) {
    if (_e == null || def.isUnderAIControl(_e)) return false;
    if (!_e.isPlayerControlled()) return false;
    if (("isGuest" in _e) && _e.isGuest()) return false;
    if (("_isIgnored" in _e.m) && _e.m._isIgnored) return false;
    return isDummyAgent(_e.getAIAgent());
}

def.enableGenericAI <- function (_actor) {
    if (def.isUnderAIControl(_actor)) return;
    local current = _actor.getAIAgent();
    local hasRealAgent = !isDummyAgent(current);

    _actor.m._oldAgent <- current;
    local mode = _actor.m._autopilot <- {
        ranged = _actor.isArmedWithRangedWeapon()
        throwing = false
        generic = true
    };

    local agent;
    if (hasRealAgent) {
        // Keep the unit's own brain (zombie agent etc.), it just was never being run.
        agent = current;
    } else {
        mode.agent <- mode.ranged ? "military_ranged" : "military_melee";
        agent = ::new("scripts/ai/tactical/agents/" + mode.agent + "_agent");
        agent.addBehavior(::new("scripts/ai/tactical/behaviors/ai_disengage"));
        agent.addBehavior(::new("scripts/ai/tactical/behaviors/ai_attack_deathblow"));
    }

    // Base compileKnownAllies is a no-op for the player faction; same override Autopilot uses.
    agent.compileKnownAllies = function () {
        local instances = this.Tactical.Entities.getAllInstances();
        this.m.KnownAllies = [];
        foreach (i, faction in instances) {
            if (faction.len() == 0 || this.m.Actor.getFaction() != i && !this.m.Actor.isAlliedWith(i)) continue;
            foreach (entity in faction) {
                if (entity.isAlive() && !entity.isDying() && entity.isPlacedOnMap()) this.m.KnownAllies.push(entity);
            }
        }
    }
    if ("Retreat" in ::Const.AI.Behavior.ID) agent.removeBehavior(::Const.AI.Behavior.ID.Retreat);
    if ("TargetPriorityHittingAlliesMult" in agent.m.Properties) agent.m.Properties.TargetPriorityHittingAlliesMult = -0.8;

    if (!hasRealAgent) {
        agent.finalizeBehaviors();
        agent.setActor(_actor);
        _actor.setAIAgent(agent);
    }
    try {
        def.setupAgent(_actor, agent);
    } catch (e) {
        ::logError("autopilot expert: profile setup failed for " + _actor.getName() + ": " + e);
    }
    ::logInfo("autopilot expert: AI enabled for ally " + _actor.getName() + " (" + (hasRealAgent ? "own agent" : mode.agent) + ")");
}

def.cancelGenericAI <- function (_actor) {
    if (!def.isUnderAIControl(_actor) || !("generic" in _actor.m._autopilot)) return;
    local old = _actor.m._oldAgent;
    if (old != null && _actor.getAIAgent() != old) _actor.setAIAgent(old);
    delete _actor.m._oldAgent;
    delete _actor.m._autopilot;
}

// Enable AI on any player-side unit: Autopilot's own path for "player" objects, ours for the rest.
def.enableAnyAlly <- function (_e) {
    if (::std.Util.isKindOf(_e, "player")) _e.enableAIControl();
    else def.enableGenericAI(_e);
}

mod.hook("scripts/entity/tactical/actor", function (q) {
    q.onDeath = @(__original) function (_killer, _skill, _tile, _fatalityType) {
        if (def.isUnderAIControl(this) && ("generic" in this.m._autopilot)) def.cancelGenericAI(this);
        __original(_killer, _skill, _tile, _fatalityType);
    }
})
