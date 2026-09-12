// The Sworn Five: five friends with builds that lean on each other. Twin archers, a spear, a
// shield, and an assassin as the avatar. Everyone carries two extra action points; the assassin
// carries three.
this.sworn_five_scenario <- this.inherit("scripts/scenarios/world/starting_scenario", {
	m = {},
	function create()
	{
		this.m.ID = "scenario.sworn_five";
		this.m.Name = "The Sworn Five";
		this.m.Description = "[p=c][img]gfx/ui/events/event_76.png[/img][/p][p]Five who grew up together and never found a reason to stop. Twin archers who shoot as one, a spearman who keeps the line honest, a shield that draws every blow, and Sable, the knife nobody sees coming.\n\n[color=#bcad8c]Sworn:[/color] Every one of them has two extra action points and will not break while a brother stands.\n[color=#bcad8c]The Knife:[/color] Sable starts at level 5 with a named qatal dagger, black leather and the full assassin's kit of perks.\n[color=#bcad8c]Provisioned:[/color] Full supplies, a war bow and quiver for each twin, a named spear, and a couple of treasures to sell.[/p]";
		this.m.Difficulty = 2;
		this.m.Order = 7;
		this.m.IsFixedLook = true;
		this.m.StartingBusinessReputation <- 350;
		if ("StartingRosterTier" in this.m && ("Roster" in this.Const) && ("getTierForSize" in this.Const.Roster))
		{
			this.m.StartingRosterTier = this.Const.Roster.getTierForSize(10);
			this.m.RosterTierMax = this.Const.Roster.getTierForSize(20);
		}
		if ("setRosterReputationTiers" in this && ("Roster" in this.Const) && ("createReputationTiers" in this.Const.Roster))
		{
			this.setRosterReputationTiers(this.Const.Roster.createReputationTiers(350));
		}
	}

	function onSpawnAssets()
	{
		local W = ::WolfeoStarts;
		local roster = this.World.getPlayerRoster();
		local sworn = "scripts/skills/traits/sworn_trait";
		local desert = W.hasDesert();

		// Sable, the assassin. Named qatal dagger (named dagger without the desert content),
		// black leather, and every perk a dagger duelist wants.
		local sable = W.makeMember(this, roster, desert ? "assassin" : "killer_on_the_run", "Sable", "the Knife", {
			weapon = desert ? "scripts/items/weapons/named/named_qatal_dagger" : "scripts/items/weapons/named/named_dagger"
			body = "scripts/items/armor/named/black_leather_armor"
			head = "scripts/items/helmets/dark_cowl"
			bag = ["scripts/items/weapons/rondel_dagger"]
			talents = ["MeleeSkill", "Initiative", "MeleeDefense"]
			stars = [3, 3, 3]
			bump = {MeleeSkill = 12, MeleeDefense = 10, Initiative = 15, Hitpoints = 10, Stamina = 10}
			perks = ["perk_mastery_dagger", "perk_backstabber", "perk_dodge", "perk_nimble", "perk_duelist",
			         "perk_overwhelm", "perk_footwork", "perk_relentless", "perk_killing_frenzy"]
			level = 5
			points = 0
			traits = [sworn, "scripts/skills/traits/knife_in_the_dark_trait"]
		}, 4);
		W.makeAvatar(sable);

		// The twins: same bow, same quiver, same light armor. Wren picks the target, Rook wears
		// it down. Between them a Bullseye and an Overwhelm before Level-Up Pilot adds the rest.
		local twin = {
			weapon = "scripts/items/weapons/war_bow"
			ammo = "scripts/items/ammo/quiver_of_arrows"
			body = "scripts/items/armor/leather_lamellar"
			head = "scripts/items/helmets/hunters_hat"
			bag = ["scripts/items/weapons/shortsword"]
			talents = ["RangedSkill", "Initiative", "RangedDefense"]
			stars = [3, 2, 2]
			bump = {RangedSkill = 12, Initiative = 8, RangedDefense = 5}
			level = 4
			points = 2
			traits = [sworn, "scripts/skills/traits/loyal_trait"]
		};
		local wren = clone twin;
		wren.perks <- ["perk_mastery_bow", "perk_bullseye"];
		W.makeMember(this, roster, "hunter", "Wren", "the Elder", wren, 12);
		local rook = clone twin;
		rook.perks <- ["perk_mastery_bow", "perk_overwhelm"];
		W.makeMember(this, roster, "hunter", "Rook", "the Younger", rook, 14);

		// Halvard: the named spear, medium mail, a shield for the spearwall.
		W.makeMember(this, roster, "sellsword", "Halvard", "Longarm", {
			weapon = "scripts/items/weapons/named/named_spear"
			offhand = "scripts/items/shields/heater_shield"
			body = "scripts/items/armor/mail_hauberk"
			head = "scripts/items/helmets/nasal_helmet_with_mail"
			talents = ["MeleeSkill", "MeleeDefense", "Fatigue"]
			stars = [3, 2, 2]
			bump = {MeleeSkill = 10, MeleeDefense = 5, Stamina = 8}
			perks = ["perk_mastery_spear", "perk_fast_adaption"]
			level = 4
			points = 2
			traits = [sworn, "scripts/skills/traits/loyal_trait"]
		}, 3);

		// Bram: the wall. Full kit, decent sword, decent shield, and the perks that make enemies
		// swing at him instead of the twins.
		W.makeMember(this, roster, "retired_soldier", "Bram", "the Wall", {
			weapon = "scripts/items/weapons/arming_sword"
			offhand = "scripts/items/shields/kite_shield"
			body = "scripts/items/armor/coat_of_scales"
			head = "scripts/items/helmets/closed_flat_top_with_mail"
			talents = ["MeleeDefense", "Hitpoints", "Bravery"]
			stars = [3, 2, 2]
			bump = {MeleeDefense = 10, Hitpoints = 10, Bravery = 8, Stamina = 10}
			perks = ["perk_taunt", "perk_shield_expert", "perk_rally_the_troops"]
			level = 4
			points = 1
			traits = [sworn, "scripts/skills/traits/loyal_trait"]
		}, 5);

		if ("addBusinessReputation" in this.World.Assets) this.World.Assets.addBusinessReputation(this.m.StartingBusinessReputation);
		this.World.Assets.m.Money = 2000;
		this.World.Assets.m.Medicine = 40;
		this.World.Assets.m.Ammo = 300;
		this.World.Assets.m.ArmorParts = 120;
		local stash = this.World.Assets.getStash();
		for (local i = 0; i < 3; i++) stash.add(this.new("scripts/items/supplies/cured_venison_item"));
		stash.add(this.new("scripts/items/supplies/mead_item"));
		stash.add(this.new("scripts/items/ammo/quiver_of_arrows"));
		stash.add(this.new("scripts/items/ammo/quiver_of_arrows"));
		stash.add(this.new("scripts/items/loot/gemstones_item"));
		stash.add(this.new("scripts/items/loot/golden_chalice_item"));
	}

	function onSpawnPlayer()
	{
		::WolfeoStarts.spawnNearVillage(this, "event.sworn_five_intro");
	}
});
