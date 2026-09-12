// The assassin's edge. On top of the Sworn bonus this is the fastest hand in the company.
this.knife_in_the_dark_trait <- this.inherit("scripts/skills/traits/character_trait", {
	m = {},
	function create()
	{
		this.character_trait.create();
		this.m.ID = "trait.knife_in_the_dark";
		this.m.Name = "Knife in the Dark";
		this.m.Icon = "ui/traits/trait_icon_31.png";
		this.m.Description = "Nobody has seen this one draw. They have only seen the other man fall. Armor means nothing to a blade that goes where armor is not.";
		this.m.Titles = [
			"the Knife",
			"the Quiet",
			"the Shade"
		];
	}

	function getTooltip()
	{
		return [
			{ id = 1, type = "title", text = this.getName() },
			{ id = 2, type = "description", text = this.getDescription() },
			{ id = 10, type = "text", icon = "ui/icons/action_points.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+1[/color] Action Points" },
			{ id = 11, type = "text", icon = "ui/icons/initiative.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+25[/color] Initiative" },
			{ id = 12, type = "text", icon = "ui/icons/melee_skill.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+10[/color] Melee Skill" },
			{ id = 13, type = "text", icon = "ui/icons/melee_defense.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+10[/color] Melee Defense" },
			{ id = 14, type = "text", icon = "ui/icons/ranged_defense.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+10[/color] Ranged Defense" },
			{ id = 15, type = "text", icon = "ui/icons/health.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+15[/color] Hitpoints" }
		];
	}

	function onUpdate( _properties )
	{
		_properties.ActionPoints += 1;
		_properties.Initiative += 25;
		_properties.MeleeSkill += 10;
		_properties.MeleeDefense += 10;
		_properties.RangedDefense += 10;
		_properties.Hitpoints += 15;
	}
});
