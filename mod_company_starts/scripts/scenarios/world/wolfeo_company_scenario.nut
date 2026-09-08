// Wolfeo's Company: an elite blade with a real company behind him. Built for autonomous play:
// every companion has a clear role, matching kit and talents, a war dog, and a few levels for
// Level-Up Pilot to spend on day one.
this.wolfeo_company_scenario <- this.inherit("scripts/scenarios/world/starting_scenario", {
	m = {},
	function create()
	{
		this.m.ID = "scenario.wolfeo_company";
		this.m.Name = "Wolfeo's Company";
		this.m.Description = "[p=c][img]gfx/ui/events/event_35.png[/img][/p][p]They say Wolfeo the Nightblade was never seen entering a fight, only leaving one. He blinks through the press, opens a man like a letter, and is gone before the body falls. What they forget is the company: nine mid-grade fighters who hold the line so he has somewhere to come back to, and nine war dogs who hold it with them.\n\n[color=#bcad8c]Elite avatar:[/color] Wolfeo starts at level 8 with the Blink skill, three extra action points and the perks to use them.\n[color=#bcad8c]A real company:[/color] Two shield-bearers, two two-handers, two polearms, two archers and a bannerman, each with fitting gear, talents and a war dog.\n[color=#bcad8c]Ready on day one:[/color] Enough gold and supplies to replace a death.[/p]";
		this.m.Difficulty = 1;
		this.m.Order = 5;
		this.m.IsFixedLook = true;
		this.m.StartingBusinessReputation = 500;
		if ("StartingRosterTier" in this.m && ("Roster" in this.Const) && ("getTierForSize" in this.Const.Roster))
		{
			this.m.StartingRosterTier = this.Const.Roster.getTierForSize(12);
			this.m.RosterTierMax = this.Const.Roster.getTierForSize(20);
		}
		if ("setRosterReputationTiers" in this && ("Roster" in this.Const) && ("createReputationTiers" in this.Const.Roster))
		{
			this.setRosterReputationTiers(this.Const.Roster.createReputationTiers(this.m.StartingBusinessReputation));
		}
	}

	function onSpawnAssets()
	{
		local W = ::WolfeoStarts;
		local roster = this.World.getPlayerRoster();

		// The man himself.
		local wolfeo = W.makeBro(this, roster, "swordmaster", "Wolfeo", "the Nightblade");
		W.makeWolfeo(this, wolfeo);

		// The company.
		W.makeCompanion(this, roster, "retired_soldier", "tank", 0);
		W.makeCompanion(this, roster, "militia", "tank", 1);
		W.makeCompanion(this, roster, "sellsword", "striker", 2);
		W.makeCompanion(this, roster, "bastard", "striker", 3);
		W.makeCompanion(this, roster, "squire", "polearm", 4);
		W.makeCompanion(this, roster, "deserter", "polearm", 5);
		W.makeCompanion(this, roster, "hunter", "archer", 6);
		W.makeCompanion(this, roster, "poacher", "archer", 7);
		W.makeCompanion(this, roster, "retired_soldier", "banner", 8);

		this.World.Assets.addBusinessReputation(this.m.StartingBusinessReputation);
		this.World.Assets.m.Money = 3000;
		this.World.Assets.m.Medicine = 40;
		this.World.Assets.m.Ammo = 150;
		this.World.Assets.m.ArmorParts = 100;
		local stash = this.World.Assets.getStash();
		for (local i = 0; i < 4; i++) stash.add(this.new("scripts/items/supplies/cured_rations_item"));
		stash.add(this.new("scripts/items/supplies/smoked_ham_item"));
		stash.add(this.new("scripts/items/supplies/mead_item"));
	}

	function onSpawnPlayer()
	{
		::WolfeoStarts.spawnNearVillage(this);
	}
});
