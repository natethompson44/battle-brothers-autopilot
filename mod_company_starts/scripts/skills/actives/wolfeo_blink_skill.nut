// Blink: step through shadow to any empty tile within range. No attack of opportunity, no path
// needed. Cheap enough to blink in, strike, and blink out in one turn with the Wolfeo trait.
this.wolfeo_blink_skill <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "actives.wolfeo_blink";
		this.m.Name = "Blink";
		this.m.Description = "Vanish and reappear on any free tile within reach. Does not provoke attacks of opportunity and needs no path.";
		this.m.Icon = "skills/active_60.png";
		this.m.IconDisabled = "skills/active_60_sw.png";
		this.m.SoundOnUse = [
			"sounds/enemies/vampire_takeoff_01.wav",
			"sounds/enemies/vampire_takeoff_02.wav",
			"sounds/enemies/vampire_takeoff_03.wav"
		];
		this.m.SoundOnHit = [
			"sounds/enemies/vampire_landing_01.wav",
			"sounds/enemies/vampire_landing_02.wav",
			"sounds/enemies/vampire_landing_03.wav"
		];
		this.m.Type = this.Const.SkillType.Active;
		this.m.Order = this.Const.SkillOrder.OtherTargeted;
		this.m.IsSerialized = false;
		this.m.IsActive = true;
		this.m.IsTargeted = true;
		this.m.IsTargetingActor = false;
		this.m.IsVisibleTileNeeded = false;
		this.m.IsStacking = false;
		this.m.IsAttack = false;
		this.m.IsIgnoredAsAOO = true;
		this.m.ActionPointCost = 3;
		this.m.FatigueCost = 20;
		this.m.MinRange = 1;
		this.m.MaxRange = 5;
		this.m.MaxLevelDifference = 4;
	}

	function getTooltip()
	{
		return [
			{ id = 1, type = "title", text = this.getName() },
			{ id = 2, type = "description", text = this.getDescription() },
			{ id = 3, type = "text", text = this.getCostString() },
			{ id = 4, type = "text", icon = "ui/icons/special.png", text = "Range: [color=" + this.Const.UI.Color.PositiveValue + "]" + this.m.MaxRange + "[/color] tiles" }
		];
	}

	function onVerifyTarget( _originTile, _targetTile )
	{
		if (!_targetTile.IsEmpty) return false;
		if (_targetTile.ID == _originTile.ID) return false;
		if (this.Math.abs(_targetTile.Level - _originTile.Level) > this.m.MaxLevelDifference) return false;
		return true;
	}

	function onUse( _user, _targetTile )
	{
		if (!_user.isHiddenToPlayer() || _targetTile.IsVisibleForPlayer)
		{
			this.Tactical.EventLog.log(this.Const.UI.getColorizedEntityName(_user) + " blinks");
		}
		if (_user.getTile().IsVisibleForPlayer && ("DarkflightStartParticles" in this.Const.Tactical))
		{
			foreach (p in this.Const.Tactical.DarkflightStartParticles)
			{
				this.Tactical.spawnParticleEffect(false, p.Brushes, _user.getTile(), p.Delay, p.Quantity, p.LifeTimeQuantity, p.SpawnRate, p.Stages);
			}
		}
		this.Tactical.getNavigator().teleport(_user, _targetTile, this.onTeleportDone, { Skill = this }, false);
		return true;
	}

	function onTeleportDone( _entity, _tag )
	{
		if (_entity.isHiddenToPlayer()) return;
		if (("DarkflightEndParticles" in this.Const.Tactical))
		{
			foreach (p in this.Const.Tactical.DarkflightEndParticles)
			{
				this.Tactical.spawnParticleEffect(false, p.Brushes, _entity.getTile(), p.Delay, p.Quantity, p.LifeTimeQuantity, p.SpawnRate, p.Stages);
			}
		}
		if (_entity.getTile().IsVisibleForPlayer && _tag.Skill.m.SoundOnHit.len() > 0)
		{
			this.Sound.play(_tag.Skill.m.SoundOnHit[this.Math.rand(0, _tag.Skill.m.SoundOnHit.len() - 1)], this.Const.Sound.Volume.Skill, _entity.getPos());
		}
	}
});
