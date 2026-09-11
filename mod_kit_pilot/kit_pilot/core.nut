// The sweep: veterans first, up to a few passes so what a veteran takes off can go to the next
// bro down. Every move is stash -> bro or bro -> stash; nothing is ever swapped between bros
// directly and nothing is created or destroyed.
local def = ::KitPilot;

def.Changes <- [];     // what the current sweep moved, one line each

local Upgrade = {
    weapon = 1.2     // a replacement weapon must score this much more than the worn one
    shield = 1.15
    armor = 1.15
};

def.isInBattle <- function () {
    try {
        return ::Tactical.isActive();
    } catch (e) {
        return false;
    }
};

def.shouldSkip <- function (_bro) {
    if (_bro == null) return true;
    if (("isNull" in _bro) && _bro.isNull()) return true;
    local name = _bro.getName();
    if (name != null && name.len() > 0 && name.slice(name.len() - 1) == def.ManualMarker) return true;
    if (def.conf("skipAvatar") && _bro.getSkills().hasSkill("trait.player")) return true;
    return false;
};

local function bestOf(_items, _filter, _score) {
    local best = null, bestScore = 0.0;
    foreach (it in _items) {
        if (!_filter(it)) continue;
        local s = _score(it);
        if (best == null || s > bestScore) {
            best = it;
            bestScore = s;
        }
    }
    return {item = best, score = bestScore};
}

// Take _item out of the stash and put it in _slot. Whatever was there (and, for a two-hander,
// whatever was in the offhand) goes back to the stash. Returns true when it happened.
def.swapIn <- function (_bro, _item, _slot, _why) {
    local items = _bro.getItems();
    local stash = def.stash();
    local old = items.getItemAtSlot(_slot);
    if (def.isNamed(old)) return false;

    stash.remove(_item);
    local displaced = [];
    if (old != null) {
        items.unequip(old);
        displaced.push(old);
    }
    if (_slot == ::Const.ItemSlot.Mainhand && def.isTwoHanded(_item)) {
        local off = items.getItemAtSlot(::Const.ItemSlot.Offhand);
        if (off != null) {
            items.unequip(off);
            displaced.push(off);
        }
    }
    local ok = false;
    try {
        ok = items.equip(_item);
    } catch (e) {
        ::logWarning("kit pilot: equip threw for " + _bro.getName() + " / " + _item.getName() + ": " + e);
        ok = false;
    }
    if (!ok) {
        // Put everything back the way it was.
        foreach (d in displaced) items.equip(d);
        stash.add(_item);
        def.dbg(_bro.getName() + ": could not equip " + _item.getName());
        return false;
    }
    foreach (d in displaced) {
        if (stash.add(d) == false && !items.addToBag(d)) {
            ::logWarning("kit pilot: no room in the stash or bag for " + d.getName() + " taken off " + _bro.getName());
        }
    }
    local line = _bro.getName() + ": " + def.describe(old) + " -> " + _item.getName() + " (" + _why + ")";
    def.log(line);
    def.Changes.push(line);
    return true;
};

def.fitWeapon <- function (_bro, _info) {
    local items = _bro.getItems();
    local cur = items.getItemAtSlot(::Const.ItemSlot.Mainhand);
    if (def.isNamed(cur)) return false;
    if (cur != null && !def.conf("upgrade")) return false;

    local stashItems = def.stashItems();
    local role = _info.role;
    local pick = bestOf(stashItems, @(it) def.weaponFits(role, it), @(it) def.weaponScore(_bro, _info, it));
    // Nothing of the right kind for a bare-handed recruit: anything beats fists.
    if (pick.item == null && cur == null) {
        local anyFits = (role == def.Role.Archer) ? @(it) def.isRangedWeapon(it) : @(it) def.isMeleeWeapon(it);
        pick = bestOf(stashItems, anyFits, @(it) def.weaponScore(_bro, _info, it));
    }
    if (pick.item == null) return false;
    if (cur != null) {
        local curScore = def.weaponScore(_bro, _info, cur);
        if (pick.score < curScore * Upgrade.weapon) {
            def.dbg(_bro.getName() + ": keeps " + cur.getName() + " (" + curScore + ") over " + pick.item.getName() + " (" + pick.score + ")");
            return false;
        }
    }
    local why = role + " weapon, value " + ::Math.round(pick.score);
    if (cur != null) why += " vs " + ::Math.round(def.weaponScore(_bro, _info, cur));
    return def.swapIn(_bro, pick.item, ::Const.ItemSlot.Mainhand, why);
};

def.fitShield <- function (_bro, _info) {
    local items = _bro.getItems();
    local main = items.getItemAtSlot(::Const.ItemSlot.Mainhand);
    if (main != null && def.isTwoHanded(main)) return false;
    local cur = items.getItemAtSlot(::Const.ItemSlot.Offhand);
    if (def.isNamed(cur)) return false;
    if (cur != null && !def.conf("upgrade")) return false;
    if (cur != null && !def.isShield(cur)) return false;   // a throwing weapon, a net: leave it

    local pick = bestOf(def.stashItems(), @(it) def.isShield(it), @(it) def.shieldScore(it));
    if (pick.item == null) return false;
    if (cur != null && pick.score < def.shieldScore(cur) * Upgrade.shield) return false;
    local why = "shield, defense " + ::Math.round(pick.score);
    if (cur != null) why += " vs " + ::Math.round(def.shieldScore(cur));
    return def.swapIn(_bro, pick.item, ::Const.ItemSlot.Offhand, why);
};

// Body armor, then helmet, each within the fatigue the bro has left.
def.fitArmorPiece <- function (_bro, _info, _slot) {
    local items = _bro.getItems();
    local cur = items.getItemAtSlot(_slot);
    if (def.isNamed(cur)) return false;
    if (cur != null && !def.conf("upgrade")) return false;
    local isBody = _slot == ::Const.ItemSlot.Body;
    local other = items.getItemAtSlot(isBody ? ::Const.ItemSlot.Head : ::Const.ItemSlot.Body);
    local curPen = def.penalty(_info, cur);
    local otherPen = def.penalty(_info, other);
    local fatMax = _bro.getFatigueMax();
    local minFat = def.conf("minFatigue") + (_info.role == def.Role.Archer ? 10 : 0);

    local allowed = function (it) {
        local pen = def.penalty(_info, it);
        // Nimble wants the two pieces together under 15 fatigue; everyone else keeps a floor.
        if (_info.nimble) return pen + otherPen <= 15.0;
        return fatMax + curPen - pen >= minFat;
    };
    local filter = isBody ? @(it) def.isBodyArmor(it) && allowed(it) : @(it) def.isHelmet(it) && allowed(it);
    local pick = bestOf(def.stashItems(), filter, @(it) def.armorValue(it) * 1.0);
    if (pick.item == null) return false;
    local curArmor = def.armorValue(cur);
    if (cur != null && pick.score < curArmor * Upgrade.armor) {
        def.dbg(_bro.getName() + ": keeps " + cur.getName() + " (" + curArmor + ") over " + pick.item.getName() + " (" + pick.score + ")");
        return false;
    }
    local why = (isBody ? "armor " : "helmet ") + ::Math.round(pick.score);
    if (cur != null) why += " vs " + ::Math.round(curArmor);
    why += ", keeps " + ::Math.round(fatMax + curPen - def.penalty(_info, pick.item)) + " fatigue";
    return def.swapIn(_bro, pick.item, _slot, why);
};

def.fitAmmo <- function (_bro, _info) {
    local items = _bro.getItems();
    local weapon = items.getItemAtSlot(::Const.ItemSlot.Mainhand);
    if (weapon == null || !("getAmmoType" in weapon)) return false;
    local cur = items.getItemAtSlot(::Const.ItemSlot.Ammo);
    if (cur != null && def.ammoFits(weapon, cur)) return false;
    local pick = bestOf(def.stashItems(), @(it) def.ammoFits(weapon, it), @(it) 1.0 + def.ammoLeft(it));
    if (pick.item == null) return false;
    return def.swapIn(_bro, pick.item, ::Const.ItemSlot.Ammo, "quiver");
};

// An archer with nothing to hold when the line breaks gets the cheapest spare one-hander.
def.fitSidearm <- function (_bro, _info) {
    local items = _bro.getItems();
    for (local i = 0; i < items.getUnlockedBagSlots(); i++) {
        local it = items.getItemAtBagSlot(i);
        if (it != null && def.isMeleeWeapon(it)) return false;
    }
    local best = null;
    foreach (it in def.stashItems()) {
        if (!def.isMeleeWeapon(it) || def.isTwoHanded(it) || def.isNamed(it)) continue;
        if (it.getValue() < 100) continue;
        if (best == null || it.getValue() < best.getValue()) best = it;
    }
    if (best == null) return false;
    local stash = def.stash();
    stash.remove(best);
    if (!items.addToBag(best)) {
        stash.add(best);
        return false;
    }
    local line = _bro.getName() + ": " + best.getName() + " into the bag (archer sidearm)";
    def.log(line);
    def.Changes.push(line);
    return true;
};

// One bro. Returns true if anything moved.
def.process <- function (_bro) {
    if (def.shouldSkip(_bro)) return false;
    if (_bro.getBackground() == null) return false;
    local info = def.detectRole(_bro);
    local changed = false;

    if (!def.isWeaponsFixed(info.role)) {
        if (def.fitWeapon(_bro, info)) {
            changed = true;
            info = def.detectRole(_bro);   // the weapon may have settled a recruit's role
        }
        if (info.role == def.Role.Tank && def.fitShield(_bro, info)) changed = true;
        if (info.role == def.Role.Archer) {
            if (def.fitAmmo(_bro, info)) changed = true;
            if (def.fitSidearm(_bro, info)) changed = true;
        }
    }
    if (def.fitArmorPiece(_bro, info, ::Const.ItemSlot.Body)) changed = true;
    if (def.fitArmorPiece(_bro, info, ::Const.ItemSlot.Head)) changed = true;
    return changed;
};

// Returns the list of change lines (empty when nothing moved), null when it could not run.
def.sweep <- function (_why) {
    def.Changes = [];
    if (!def.conf("equip")) return null;
    if (def.isInBattle()) return null;
    if (!("World" in getroottable()) || ::World == null) return null;
    local roster;
    try {
        roster = clone ::World.getPlayerRoster().getAll();
        def.stash();
    } catch (e) {
        return null;
    }
    roster.sort(@(a, b) b.getLevel() <=> a.getLevel());
    def.dbg("sweep (" + _why + "), " + roster.len() + " bros, " + def.stashItems().len() + " items in the stash");
    for (local pass = 0; pass < def.MaxPasses; pass++) {
        local changed = false;
        foreach (bro in roster) {
            try {
                if (def.process(bro)) changed = true;
            } catch (e) {
                ::logError("kit pilot: failed on " + bro.getName() + ": " + e);
            }
        }
        if (!changed) break;
    }
    return def.Changes;
};

// Re-open the character screen, if it is open, so it shows the new kit.
def.refreshCharacterScreen <- function () {
    try {
        local ws = ::World.State;
        local screen = ("CharacterScreen" in ws.m) ? ws.m.CharacterScreen : null;
        if (screen == null || !screen.isVisible()) return;
        if ("toggleCharacterScreen" in ws) {
            ws.toggleCharacterScreen();
            ws.toggleCharacterScreen();
        } else {
            screen.hide();
            screen.show();
        }
    } catch (e) {
        def.dbg("could not refresh the character screen: " + e);
    }
};

// The Kit up button on the character screen: one sweep, refresh, and the change lines go back
// to the screen, which shows them in its own panel.
def.kitUpFromScreen <- function () {
    local changes = null;
    try {
        changes = def.sweep("button");
    } catch (e) {
        ::logError("kit pilot: " + e);
    }
    if (changes == null) changes = [];
    def.refreshCharacterScreen();
    return changes;
};

// The K key: one sweep, refresh the character screen if it is open, then say what happened.
def.kitUp <- function () {
    local changes = def.sweep("hotkey");
    if (changes == null) return;
    def.refreshCharacterScreen();
    local text;
    if (changes.len() == 0) text = "Nothing to change: everybody has the best the stash can offer for his role.";
    else {
        text = "";
        foreach (c in changes) text += c + "\n";
    }
    def.notify("Kit Pilot: " + changes.len() + " change" + (changes.len() == 1 ? "" : "s"), text);
};

// A popup through MSU when it has one; the log always has it.
def.notify <- function (_title, _text) {
    def.log(_title);
    try {
        if (("System" in ::MSU) && ("Popups" in ::MSU.System) && ("showRawTextPopup" in ::MSU.System.Popups)) {
            ::MSU.System.Popups.showRawTextPopup(_title, _text);
            return;
        }
    } catch (e) {
        def.dbg("popup failed: " + e);
    }
    ::logInfo("kit pilot: " + _text);
};
