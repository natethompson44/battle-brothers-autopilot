// Shared by the Sworn Five. Years of fighting side by side: everyone moves a beat faster and
// nobody breaks while a brother is still standing. Permanent, not removable.
this.sworn_trait <- this.inherit("scripts/skills/traits/character_trait", {
	m = {},
	function create()
	{
		this.character_trait.create();
		this.m.ID = "trait.sworn";
		this.m.Name = "Sworn";
		this.m.Icon = "ui/traits/trait_icon_44.png";
		this.m.Description = "Five who swore an oath to each other long before they swore one to any paymaster. They fight the way a hand closes: each finger knowing where the others are.";
		this.m.Titles = [];
	}

	function getTooltip()
	{
		return [
			{ id = 1, type = "title", text = this.getName() },
			{ id = 2, type = "description", text = this.getDescription() },
			{ id = 10, type = "text", icon = "ui/icons/action_points.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+2[/color] Action Points" },
			{ id = 11, type = "text", icon = "ui/icons/initiative.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+10[/color] Initiative" },
			{ id = 12, type = "text", icon = "ui/icons/bravery.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+10[/color] Resolve" },
			{ id = 13, type = "text", icon = "ui/icons/fatigue.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+3[/color] Fatigue Recovery per turn" }
		];
	}

	function onUpdate( _properties )
	{
		_properties.ActionPoints += 2;
		_properties.Initiative += 10;
		_properties.Bravery += 10;
		_properties.FatigueRecoveryRate += 3;
	}
});
