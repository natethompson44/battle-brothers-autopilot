// Wolfeo's Hunt: the same avatar with a small, fast pack of hunters and hounds instead of a
// battle line. Harder: fewer bodies, less gold, more dogs.
this.wolfeo_hunt_scenario <- this.inherit("scripts/scenarios/world/starting_scenario", {
	m = {},
	function create()
	{
		this.m.ID = "scenario.wolfeo_hunt";
		this.m.Name = "Wolfeo's Hunt";
		this.m.Description = "[p=c][img]gfx/ui/events/event_08.png[/img][/p][p]No banner, no line. Wolfeo the Nightblade runs with four hunters and a pack of war dogs, taking the fights the big companies will not: beasts, raiders, anything that bleeds and pays.\n\n[color=#bcad8c]Elite avatar:[/color] Wolfeo starts at level 8 with the Blink skill, three extra action points and the perks to use them.\n[color=#bcad8c]A hunting pack:[/color] Two archers, a beast hunter and a houndmaster, every one of them with a war dog and the houndmaster with two.\n[color=#bcad8c]Lean purse:[/color] Enough to eat, not enough to be careless.[/p]";
		this.m.Difficulty = 3;
		this.m.Order = 6;
		this.m.IsFixedLook = true;
		this.m.StartingBusinessReputation = 250;
		if ("StartingRosterTier" in this.m && ("Roster" in this.Const) && ("getTierForSize" in this.Const.Roster))
		{
			this.m.StartingRosterTier = this.Const.Roster.getTierForSize(8);
			this.m.RosterTierMax = this.Const.Roster.getTierForSize(16);
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

		local wolfeo = W.makeBro(this, roster, "swordmaster", "Wolfeo", "the Nightblade");
		W.makeWolfeo(this, wolfeo);

		W.makeCompanion(this, roster, "hunter", "archer", 0);
		W.makeCompanion(this, roster, "poacher", "archer", 1);
		W.makeCompanion(this, roster, "beast_hunter", "tank", 2);
		local hm = W.makeCompanion(this, roster, "houndmaster", "duelist", 3);
		hm.getItems().addToBag(this.new("scripts/items/accessory/wardog_item"));

		this.World.Assets.addBusinessReputation(this.m.StartingBusinessReputation);
		this.World.Assets.m.Money = 1200;
		this.World.Assets.m.Medicine = 20;
		this.World.Assets.m.Ammo = 200;
		this.World.Assets.m.ArmorParts = 40;
		local stash = this.World.Assets.getStash();
		for (local i = 0; i < 3; i++) stash.add(this.new("scripts/items/supplies/cured_venison_item"));
	}

	function onSpawnPlayer()
	{
		::WolfeoStarts.spawnNearVillage(this);
	}
});
