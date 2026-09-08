// The trait that makes Wolfeo Wolfeo: more action points than anyone else, fast, hard to hit,
// and the Blink skill. Permanent, not removable, not for hire.
this.wolfeo_trait <- this.inherit("scripts/skills/traits/character_trait", {
	m = {},
	function create()
	{
		this.character_trait.create();
		this.m.ID = "trait.wolfeo";
		this.m.Name = "Nightblade";
		this.m.Icon = "ui/traits/trait_icon_57.png";
		this.m.Description = "This one moves like a shadow and hits like a landslide. Nobody in the company can keep up, and nobody has to: he goes where the killing is and comes back.";
		this.m.Titles = [
			"the Nightblade",
			"the Shadow",
			"the Wolf"
		];
	}

	function getTooltip()
	{
		return [
			{ id = 1, type = "title", text = this.getName() },
			{ id = 2, type = "description", text = this.getDescription() },
			{ id = 10, type = "text", icon = "ui/icons/action_points.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+3[/color] Action Points" },
			{ id = 11, type = "text", icon = "ui/icons/initiative.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+30[/color] Initiative" },
			{ id = 12, type = "text", icon = "ui/icons/melee_skill.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+12[/color] Melee Skill" },
			{ id = 13, type = "text", icon = "ui/icons/melee_defense.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+10[/color] Melee Defense" },
			{ id = 14, type = "text", icon = "ui/icons/health.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+20[/color] Hitpoints" },
			{ id = 15, type = "text", icon = "ui/icons/fatigue.png", text = "[color=" + this.Const.UI.Color.PositiveValue + "]+5[/color] Fatigue Recovery per turn" },
			{ id = 16, type = "text", icon = "ui/icons/special.png", text = "Unlocks the Blink skill" }
		];
	}

	function onAdded()
	{
		if (this.getContainer().getSkillByID("actives.wolfeo_blink") == null)
		{
			this.getContainer().add(this.new("scripts/skills/actives/wolfeo_blink_skill"));
		}
	}

	function onUpdate( _properties )
	{
		_properties.ActionPoints += 3;
		_properties.Initiative += 30;
		_properties.MeleeSkill += 12;
		_properties.MeleeDefense += 10;
		_properties.RangedDefense += 5;
		_properties.Bravery += 15;
		_properties.Hitpoints += 20;
		_properties.FatigueRecoveryRate += 5;
	}
});
